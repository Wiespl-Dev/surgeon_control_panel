package com.example.surgeon_control_panel

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import android.os.Handler
import android.os.Looper

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_launcher_channel"
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchAppAndEnterPip" -> {
                    val packageName = call.arguments as String
                    launchAppAndEnterPip(packageName, result)
                }
                "enterPipMode" -> {
                    val pipSuccess = enterPipMode()
                    result.success(pipSuccess)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun launchAppAndEnterPip(packageName: String, result: MethodChannel.Result) {
        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                // Launch the app first
                startActivity(intent)
                
                // Wait a moment for the app to start, then enter PiP mode
                handler.postDelayed({
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        enterPipMode()
                    }
                    result.success(true)
                }, 300) // 300ms delay to ensure DroidRender starts
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.success(false)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun enterPipMode(): Boolean {
        return try {
            val rational = Rational(16, 9) // 16:9 aspect ratio
            val params = android.app.PictureInPictureParams.Builder()
                .setAspectRatio(rational)
                .build()
            enterPictureInPictureMode(params)
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // Automatically enter PiP when user leaves the app
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPipMode()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: android.content.res.Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // Handle PiP mode changes here if needed
    }
}