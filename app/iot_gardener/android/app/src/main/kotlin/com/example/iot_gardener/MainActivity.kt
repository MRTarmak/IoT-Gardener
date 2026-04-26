package com.example.iot_gardener

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "iot_gardener/wifi")
            .setMethodCallHandler { call, result ->
                if (call.method == "openWifiSettings") {
                    startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
