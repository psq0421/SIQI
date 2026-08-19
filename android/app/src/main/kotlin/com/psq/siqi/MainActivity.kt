package com.psq.siqi

import android.app.ActivityManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
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

    companion object {
        private const val PLATFORM_CHANNEL = "com.psq.siqi/platform"
    }
}
