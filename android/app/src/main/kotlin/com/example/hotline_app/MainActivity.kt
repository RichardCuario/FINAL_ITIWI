package com.ecoimpact.itiwi

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val navigationChannel = "com.ecoimpact.itiwi/navigation"
    private val mediaChannel = "com.ecoimpact.itiwi/verification_media"
    private val mediaRequestCode = 4217
    private val mediaPermissions = arrayOf(Manifest.permission.CAMERA, Manifest.permission.RECORD_AUDIO)
    private var pendingMediaResult: MethodChannel.Result? = null
    private var appUpdates: AppUpdates? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        appUpdates = AppUpdates(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, navigationChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "backgroundApp") {
                    moveTaskToBack(true)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "requestMediaPermissions") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val missing = mediaPermissions.filter {
                    ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
                }
                if (missing.isEmpty()) {
                    result.success(true)
                } else if (pendingMediaResult != null) {
                    result.error("permission_in_progress", "A media permission request is already open.", null)
                } else {
                    pendingMediaResult = result
                    ActivityCompat.requestPermissions(this, missing.toTypedArray(), mediaRequestCode)
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == mediaRequestCode) {
            val granted = mediaPermissions.all {
                ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
            }
            pendingMediaResult?.success(granted)
            pendingMediaResult = null
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, navigationChannel)
            .setMethodCallHandler(null)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaChannel)
            .setMethodCallHandler(null)
        pendingMediaResult = null
        appUpdates?.close()
        appUpdates = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
