package com.psq.siqi

import android.app.ActivityManager
import android.content.Context
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
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "processorCount" to Runtime.getRuntime().availableProcessors(),
            "isLowRamDevice" to manager.isLowRamDevice,
            "supportedAbis" to Build.SUPPORTED_ABIS.toList()
        )
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

    companion object {
        private const val PLATFORM_CHANNEL = "com.psq.siqi/platform"
    }
}
