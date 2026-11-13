package com.talawat.talawat

import android.os.StatFs
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.talawat.talawat/storage",
        ).setMethodCallHandler { call, result ->
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("BAD_PATH", "path is required", null)
                return@setMethodCallHandler
            }
            try {
                val stat = StatFs(path)
                when (call.method) {
                    "getFreeSpace" -> result.success(stat.availableBytes)
                    "getTotalSpace" -> result.success(stat.totalBytes)
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("STATFS_FAILED", e.message, null)
            }
        }
    }
}
