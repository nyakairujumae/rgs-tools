package com.rgs.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val documentsChannel = "com.rgs.app/documents_path"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, documentsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getDocumentsPath") {
                    val filesDir = applicationContext.filesDir?.absolutePath
                    if (filesDir != null && filesDir.isNotEmpty()) {
                        result.success(filesDir)
                    } else {
                        result.error(
                            "no_path",
                            "Unable to determine app documents directory",
                            null
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
