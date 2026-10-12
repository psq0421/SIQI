package com.psq.siqi

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.ActivityNotFoundException
import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.StatFs
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.regex.Pattern
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingCameraResult: MethodChannel.Result? = null
    private var pendingCameraPath: String? = null

    companion object {
        init { System.loadLibrary("siqi_platform") }
        @JvmStatic private external fun setCpuAffinityNative(mask: Long): Boolean
        private const val PLATFORM_CHANNEL = "com.psq.siqi/platform"
        private const val CAMERA_REQUEST_CODE = 1158
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PLATFORM_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "networkStatus" -> result.success(networkStatus())
                "memoryStatus" -> result.success(memoryStatus())
                "storageStatus" -> {
                    val path = call.argument<String>("path") ?: filesDir.absolutePath
                    result.success(storageStatus(path))
                }
                "runtimeInfo" -> result.success(runtimeInfo())
                "setCpuAffinity" -> {
                    val cores = call.argument<List<Number>>("cores") ?: emptyList()
                    val mask = cores.fold(0L) { value, core ->
                        val index = core.toInt()
                        if (index in 0..62) value or (1L shl index) else value
                    }
                    result.success(mask != 0L && setCpuAffinityNative(mask))
                }
                "configureInferenceScratch" -> {
                    val modelBytes = call.argument<Number>("modelBytes")?.toLong() ?: 0L
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val soc = if (Build.VERSION.SDK_INT >= 31) Build.SOC_MODEL else ""
                    val supported = soc.equals("SM8475", ignoreCase = true)
                    val directory = File(cacheDir, "inference-scratch")
                    val enough = StatFs(cacheDir.absolutePath).availableBytes > modelBytes + 1024L * 1024 * 1024
                    val ready = enabled && supported && enough && (directory.exists() || directory.mkdirs())
                    try {
                        android.system.Os.setenv("SIQI_REPACK_CACHE_DIR", if (ready) directory.absolutePath else "", true)
                        result.success(ready)
                    } catch (_: Exception) { result.success(false) }
                }
                "processStats" -> Thread {
                    try {
                        val stats = processStats(call.argument<Boolean>("includePss") ?: false)
                        runOnUiThread { result.success(stats) }
                    } catch (error: Exception) {
                        runOnUiThread { result.error("stats-unavailable", error.message, null) }
                    }
                }.start()
                "captureWithSystemCamera" -> captureWithSystemCamera(result)
                "openFile" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.success(false)
                    } else {
                        result.success(openFile(path))
                    }
                }
                "normalizeImage" -> {
                    val source = call.argument<String>("source")
                    val target = call.argument<String>("target")
                    val maxEdge = call.argument<Int>("maxEdge") ?: 1024
                    if (source == null || target == null) {
                        result.error("invalid-image-path", null, null)
                    } else {
                        try {
                            result.success(normalizeImage(source, target, maxEdge))
                        } catch (error: Exception) {
                            result.error("image-decode-failed", error.message, null)
                        }
                    }
                }
                "decodeAudioToWav" -> {
                    val source = call.argument<String>("source")
                    val target = call.argument<String>("target")
                    val maximumDurationMs =
                        call.argument<Number>("maximumDurationMs")?.toLong() ?: 10_800_000L
                    if (source == null || target == null) {
                        result.error("invalid-audio-path", null, null)
                    } else {
                        Thread {
                            try {
                                val decoded = decodeAudioToWav(
                                    source,
                                    target,
                                    maximumDurationMs
                                )
                                runOnUiThread { result.success(decoded) }
                            } catch (error: Exception) {
                                runOnUiThread {
                                    result.error("audio-decode-failed", error.message, null)
                                }
                            }
                        }.start()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun networkStatus(): Map<String, Boolean> {
        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val capabilities = manager.getNetworkCapabilities(manager.activeNetwork)
        return mapOf(
            "connected" to (capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true),
            "onWifi" to (capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true)
        )
    }

    private fun memoryStatus(): Map<String, Long> {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(memoryInfo)
        return mapOf(
            "availableBytes" to memoryInfo.availMem,
            "totalBytes" to memoryInfo.totalMem,
            "lowMemoryThresholdBytes" to memoryInfo.threshold
        )
    }

    private fun storageStatus(path: String): Map<String, Long> {
        var candidate = java.io.File(path)
        while (!candidate.exists() && candidate.parentFile != null) {
            candidate = candidate.parentFile!!
        }
        val stat = StatFs(candidate.absolutePath)
        return mapOf(
            "availableBytes" to stat.availableBytes,
            "totalBytes" to stat.totalBytes
        )
    }

    private fun runtimeInfo(): Map<String, Any> {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val swaps = readSwaps()
        val zramTotal = readLongFile("/sys/block/zram0/disksize")
        val zramUsed = readLongFile("/sys/block/zram0/mem_used_total")
        val cpuInfo = cpuTopology()
        val cpuText = try { File("/proc/cpuinfo").readText() } catch (_: Exception) { "" }
        val architecture = Regex("CPU architecture\\s*:\\s*(\\d+)").find(cpuText)?.groupValues?.getOrNull(1)?.toIntOrNull() ?: 0
        val soc = if (Build.VERSION.SDK_INT >= 31) Build.SOC_MODEL else ""
        // Android kernels commonly report `CPU architecture: 8` even for
        // Armv9 implementations. CPU part IDs and SVE2 are therefore used as
        // conservative capability evidence; this is a candidate flag, not a
        // claim that an NPU delegate is active.
        val hasArmV9Part = cpuInfo.any { (it["part"] as? String)?.lowercase() in setOf(
            "0xd46", "0xd47", "0xd48", "0xd4d", "0xd4f", "0xd80", "0xd81"
        ) }
        val armV9 = architecture >= 9 || hasArmV9Part || cpuText.contains("sve2", ignoreCase = true)
        val hexagonDevice = File("/sys/class/misc").listFiles()?.any {
            it.name.contains("hexagon", true) || it.name.contains("adspr", true) || it.name.contains("cdsp", true)
        } == true
        val npuRuntime = listOf(
            "/vendor/lib64/libQnnHtp.so",
            "/vendor/lib64/libQnnHtpV73.so",
            "/vendor/lib64/libhexagon_nn_skel.so",
            "/system/lib64/libQnnHtp.so",
        ).any { File(it).exists() }
        val eliteFamily = soc.uppercase().let {
            it.startsWith("SM8750") || it.startsWith("SM8850") ||
                it.startsWith("SM8950") || it.startsWith("SM8970")
        }
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "processorCount" to Runtime.getRuntime().availableProcessors(),
            "isLowRamDevice" to manager.isLowRamDevice,
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
            "zramTotalBytes" to zramTotal,
            "zramUsedBytes" to zramUsed,
            "swapTotalBytes" to swaps.first,
            "swapFreeBytes" to swaps.second,
            "socModel" to soc,
            "armVersion" to architecture,
            "armV9Candidate" to armV9,
            "hexagonDevice" to hexagonDevice,
            "hexagonNpuRuntime" to npuRuntime,
            // QNN HTP/Hexagon NN libraries are stronger evidence than the
            // often-hidden /sys/class entry on vendor Android builds.
            "npuOptimizationEligible" to (armV9 && npuRuntime),
            "npuOptimizationProfile" to when {
                armV9 && eliteFamily && npuRuntime -> "qualcomm-hexagon-elite"
                armV9 && npuRuntime -> "qualcomm-hexagon-armv9"
                else -> "unverified"
            },
            "cpuCores" to cpuInfo
        )
    }

    private fun cpuTopology(): List<Map<String, Any>> {
        val text = try { File("/proc/cpuinfo").readText() } catch (_: Exception) { "" }
        val parts = mutableMapOf<Int, String>()
        for (block in text.split(Regex("\\n\\s*\\n"))) {
            val id = Regex("processor\\s*:\\s*(\\d+)").find(block)?.groupValues?.getOrNull(1)?.toIntOrNull() ?: continue
            val part = Regex("CPU part\\s*:\\s*(0x[0-9a-fA-F]+)").find(block)?.groupValues?.getOrNull(1) ?: ""
            parts[id] = part
        }
        val root = File("/sys/devices/system/cpu")
        return root.listFiles()?.mapNotNull { dir ->
            val match = Regex("cpu(\\d+)").matchEntire(dir.name) ?: return@mapNotNull null
            val id = match.groupValues[1].toIntOrNull() ?: return@mapNotNull null
            val khz = readLongFile(File(dir, "cpufreq/cpuinfo_max_freq").absolutePath)
            mapOf<String, Any>(
                "id" to id,
                "maxFrequencyHz" to khz * 1000L,
                "part" to (parts[id] ?: ""),
                "architecture" to cpuPartName(parts[id] ?: "")
            )
        }?.sortedBy { it["id"] as Int } ?: emptyList()
    }

    private fun cpuPartName(part: String): String = when (part.lowercase()) {
        "0xd05" -> "Cortex-A55"
        "0xd0b" -> "Cortex-A76"
        "0xd41" -> "Cortex-A78"
        "0xd44" -> "Cortex-X1"
        "0xd46" -> "Cortex-A510"
        "0xd47" -> "Cortex-A710"
        "0xd48" -> "Cortex-X2"
        "0xd4d" -> "Cortex-A720"
        "0xd4f" -> "Cortex-X3"
        "0xd80" -> "Cortex-X4"
        "0xd81" -> "Cortex-X925"
        else -> if (part.isBlank()) "Unknown ARM core" else "ARM part $part"
    }

    /** Lightweight, privacy-safe counters used by the Beta3 benchmark screen.
     * No prompts, API keys, or file contents are included. */
    private fun processStats(includePss: Boolean): Map<String, Any> {
        var rss = 0L
        var pss = 0L
        var swapPss = 0L
        var minorFaults = 0L
        var majorFaults = 0L
        try {
            File("/proc/self/status").forEachLine { line ->
                when {
                    line.startsWith("VmRSS:") -> rss = line.filter { it.isDigit() }.toLongOrNull()?.times(1024) ?: 0L
                    line.startsWith("VmPSS:") -> pss = line.filter { it.isDigit() }.toLongOrNull()?.times(1024) ?: 0L
                }
            }
            val stat = File("/proc/self/stat").readText().substringAfterLast(") ").trim().split(Regex("\\s+"))
            if (stat.size > 9) {
                minorFaults = stat[7].toLongOrNull() ?: 0L
                majorFaults = stat[9].toLongOrNull() ?: 0L
            }
            // Walking a multi-GB mapping for PSS is expensive. The pressure
            // watchdog only needs RSS/thermal; research sampling opts in.
            if (includePss) {
                val debugMemory = android.os.Debug.MemoryInfo()
                android.os.Debug.getMemoryInfo(debugMemory)
                pss = debugMemory.totalPss.toLong() * 1024
                swapPss = debugMemory.totalSwappablePss.toLong() * 1024
            }
        } catch (_: Exception) {
            // Some Android builds restrict procfs fields; return best effort.
        }
        val battery = try {
            val intent = registerReceiver(null, android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
            val level = intent?.getIntExtra(android.os.BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = intent?.getIntExtra(android.os.BatteryManager.EXTRA_SCALE, 100) ?: 100
            if (level >= 0 && scale > 0) ((level.toDouble() / scale) * 100).toLong() else -1L
        } catch (_: Exception) { -1L }
        val batteryIntent = registerReceiver(null, android.content.IntentFilter(android.content.Intent.ACTION_BATTERY_CHANGED))
        val power = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return mapOf(
            "rssBytes" to rss,
            "pssBytes" to pss,
            "swapPssBytes" to swapPss,
            "minorFaults" to minorFaults,
            "majorFaults" to majorFaults,
            "batteryPercent" to battery,
            "batteryTemperatureDeciC" to (batteryIntent?.getIntExtra(android.os.BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1),
            "thermalStatus" to power.currentThermalStatus,
            "timestampMs" to System.currentTimeMillis()
        )
    }

    private fun readLongFile(path: String): Long {
        return try { File(path).readText().trim().toLongOrNull() ?: 0L } catch (_: Exception) { 0L }
    }

    private fun readSwaps(): Pair<Long, Long> {
        return try {
            // /proc/swaps is frequently blocked by Android SELinux even when
            // /proc/meminfo is readable. Do not silently report zero swap.
            val meminfo = File("/proc/meminfo").readLines()
            fun value(key: String): Long = meminfo.firstOrNull { it.startsWith("$key:") }
                ?.substringAfter(":")?.trim()?.substringBefore(" ")?.toLongOrNull()?.times(1024) ?: 0L
            val swapTotal = value("SwapTotal")
            if (swapTotal > 0) return swapTotal to value("SwapFree")
            val lines = File("/proc/swaps").readLines().drop(1)
            var total = 0L
            var used = 0L
            for (line in lines) {
                val columns = line.trim().split(Regex("\\s+"))
                if (columns.size >= 4) {
                    total += columns[2].toLongOrNull() ?: 0L
                    used += columns[3].toLongOrNull() ?: 0L
                }
            }
            total to (total - used).coerceAtLeast(0L)
        } catch (_: Exception) { 0L to 0L }
    }

    private fun openFile(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists() || !file.isFile) return false
            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            val extension = file.extension.lowercase()
            val mime = when (extension) {
                "zip" -> "application/zip"
                "tgz", "gz" -> "application/gzip"
                "json" -> "application/json"
                else -> "application/octet-stream"
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent.resolveActivity(packageManager) == null) return false
            startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }

    private fun captureWithSystemCamera(result: MethodChannel.Result) {
        if (pendingCameraResult != null) {
            result.error("camera-busy", "A camera capture is already running", null)
            return
        }
        val directory = File(cacheDir, "camera").apply { mkdirs() }
        val target = File(directory, "capture-${System.currentTimeMillis()}.jpg")
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", target)
        val intent = Intent(android.provider.MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(android.provider.MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            setPackage("com.android.camera")
        }
        pendingCameraResult = result
        pendingCameraPath = target.absolutePath
        try {
            startActivityForResult(intent, CAMERA_REQUEST_CODE)
        } catch (_: ActivityNotFoundException) {
            intent.setPackage(null)
            try { startActivityForResult(intent, CAMERA_REQUEST_CODE) }
            catch (error: Exception) {
                pendingCameraResult = null
                pendingCameraPath = null
                result.error("camera-unavailable", error.message, null)
            }
        } catch (_: SecurityException) {
            intent.setPackage(null)
            try { startActivityForResult(intent, CAMERA_REQUEST_CODE) }
            catch (error: Exception) {
                pendingCameraResult = null
                pendingCameraPath = null
                result.error("camera-unavailable", error.message, null)
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CAMERA_REQUEST_CODE) return
        val callback = pendingCameraResult
        val path = pendingCameraPath
        pendingCameraResult = null
        pendingCameraPath = null
        if (callback == null) return
        if (resultCode == RESULT_OK && path != null && File(path).exists()) callback.success(path)
        else callback.success(null)
    }

    private fun normalizeImage(sourcePath: String, targetPath: String, maxEdge: Int): String {
        val source = ImageDecoder.createSource(File(sourcePath))
        val decoded = ImageDecoder.decodeBitmap(source) { decoder, info, _ ->
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            val width = info.size.width
            val height = info.size.height
            val longest = maxOf(width, height)
            if (longest > maxEdge) {
                val scale = maxEdge.toDouble() / longest.toDouble()
                decoder.setTargetSize(
                    (width * scale).toInt().coerceAtLeast(1),
                    (height * scale).toInt().coerceAtLeast(1)
                )
            }
        }
        val target = File(targetPath)
        target.parentFile?.mkdirs()
        FileOutputStream(target).use { stream ->
            if (!decoded.compress(Bitmap.CompressFormat.PNG, 92, stream)) {
                throw IllegalStateException("PNG encoder rejected image")
            }
        }
        decoded.recycle()
        return target.absolutePath
    }

    private fun decodeAudioToWav(
        sourcePath: String,
        targetPath: String,
        maximumDurationMs: Long
    ): String {
        val extractor = MediaExtractor()
        var codec: MediaCodec? = null
        try {
            extractor.setDataSource(sourcePath)
            var trackIndex = -1
            var inputFormat: MediaFormat? = null
            for (index in 0 until extractor.trackCount) {
                val candidate = extractor.getTrackFormat(index)
                val mime = candidate.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("audio/")) {
                    trackIndex = index
                    inputFormat = candidate
                    break
                }
            }
            if (trackIndex < 0 || inputFormat == null) {
                throw IllegalArgumentException("No decodable audio track")
            }
            val selectedFormat = inputFormat
                ?: throw IllegalArgumentException("No decodable audio track")
            val durationUs = if (selectedFormat.containsKey(MediaFormat.KEY_DURATION)) {
                selectedFormat.getLong(MediaFormat.KEY_DURATION)
            } else {
                -1L
            }
            if (durationUs > maximumDurationMs * 1000L) {
                throw IllegalArgumentException("Audio exceeds 180 minutes")
            }
            val mime = selectedFormat.getString(MediaFormat.KEY_MIME)
                ?: throw IllegalArgumentException("Audio MIME is missing")
            extractor.selectTrack(trackIndex)
            val decoder = MediaCodec.createDecoderByType(mime)
            codec = decoder
            decoder.configure(selectedFormat, null, null, 0)
            decoder.start()

            val target = File(targetPath)
            target.parentFile?.mkdirs()
            val output = RandomAccessFile(target, "rw")
            output.setLength(0)
            output.write(ByteArray(44))

            var sampleRate = selectedFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channelCount = selectedFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            var pcmEncoding = AudioFormat.ENCODING_PCM_16BIT
            var inputEnded = false
            var outputEnded = false
            var pcmBytes = 0L
            val info = MediaCodec.BufferInfo()
            try {
                while (!outputEnded) {
                    if (!inputEnded) {
                        val inputIndex = decoder.dequeueInputBuffer(10_000)
                        if (inputIndex >= 0) {
                            val inputBuffer = decoder.getInputBuffer(inputIndex)
                                ?: throw IllegalStateException("Missing codec input buffer")
                            val size = extractor.readSampleData(inputBuffer, 0)
                            if (size < 0) {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM
                                )
                                inputEnded = true
                            } else {
                                decoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    size,
                                    extractor.sampleTime,
                                    0
                                )
                                extractor.advance()
                            }
                        }
                    }

                    when (val outputIndex = decoder.dequeueOutputBuffer(info, 10_000)) {
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val format = decoder.outputFormat
                            sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                            channelCount = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                            pcmEncoding = if (format.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                                format.getInteger(MediaFormat.KEY_PCM_ENCODING)
                            } else {
                                AudioFormat.ENCODING_PCM_16BIT
                            }
                        }
                        MediaCodec.INFO_TRY_AGAIN_LATER,
                        MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> Unit
                        else -> if (outputIndex >= 0) {
                            if (info.presentationTimeUs > maximumDurationMs * 1000L) {
                                throw IllegalArgumentException("Audio exceeds 180 minutes")
                            }
                            val buffer = decoder.getOutputBuffer(outputIndex)
                            if (buffer != null && info.size > 0) {
                                buffer.position(info.offset)
                                buffer.limit(info.offset + info.size)
                                buffer.order(ByteOrder.LITTLE_ENDIAN)
                                val bytesPerSample = when (pcmEncoding) {
                                    AudioFormat.ENCODING_PCM_FLOAT -> 4
                                    AudioFormat.ENCODING_PCM_16BIT -> 2
                                    else -> throw IllegalArgumentException(
                                        "Unsupported PCM encoding: $pcmEncoding"
                                    )
                                }
                                val frameCount = info.size / (bytesPerSample * channelCount)
                                val monoBytes = ByteBuffer.allocate(frameCount * 2)
                                    .order(ByteOrder.LITTLE_ENDIAN)
                                repeat(frameCount) {
                                    var mixed = 0.0
                                    repeat(channelCount) {
                                        mixed += if (pcmEncoding == AudioFormat.ENCODING_PCM_FLOAT) {
                                            buffer.float.toDouble().coerceIn(-1.0, 1.0)
                                        } else {
                                            buffer.short.toDouble() / 32768.0
                                        }
                                    }
                                    val mono = (mixed / channelCount).coerceIn(-1.0, 1.0)
                                    monoBytes.putShort((mono * 32767.0).toInt().toShort())
                                }
                                output.write(monoBytes.array())
                                pcmBytes += monoBytes.capacity().toLong()
                            }
                            outputEnded = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            decoder.releaseOutputBuffer(outputIndex, false)
                        }
                    }
                }
                writeWavHeader(output, pcmBytes, sampleRate)
            } finally {
                output.close()
            }
            return target.absolutePath
        } finally {
            try {
                codec?.stop()
            } catch (_: Exception) {
            }
            codec?.release()
            extractor.release()
        }
    }

    private fun writeWavHeader(file: RandomAccessFile, pcmBytes: Long, sampleRate: Int) {
        if (pcmBytes > 0xfffffff0L) {
            throw IllegalArgumentException("Decoded WAV exceeds RIFF size limit")
        }
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray(Charsets.US_ASCII))
        header.putInt((36L + pcmBytes).toInt())
        header.put("WAVE".toByteArray(Charsets.US_ASCII))
        header.put("fmt ".toByteArray(Charsets.US_ASCII))
        header.putInt(16)
        header.putShort(1.toShort())
        header.putShort(1.toShort())
        header.putInt(sampleRate)
        header.putInt(sampleRate * 2)
        header.putShort(2.toShort())
        header.putShort(16.toShort())
        header.put("data".toByteArray(Charsets.US_ASCII))
        header.putInt(pcmBytes.toInt())
        file.seek(0)
        file.write(header.array())
    }

}
