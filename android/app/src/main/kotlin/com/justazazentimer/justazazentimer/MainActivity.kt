package com.justazazentimer.justazazentimer

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.justazazentimer/dnd"
    private var previousInterruptionFilter: Int? = null
    private var dndEnabledByApp = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager

            if (notificationManager == null) {
                result.error("UNAVAILABLE", "NotificationManager is unavailable", null)
                return@setMethodCallHandler
            }

            when (call.method) {
                "isDndPermissionGranted" -> {
                    result.success(notificationManager.isNotificationPolicyAccessGranted)
                }
                "openDndSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "enableDnd" -> {
                    try {
                        if (notificationManager.isNotificationPolicyAccessGranted) {
                            if (!dndEnabledByApp) {
                                previousInterruptionFilter = notificationManager.currentInterruptionFilter
                            }
                            // INTERRUPTION_FILTER_ALARMS permits our timer alarm while silencing calls and notifications
                            notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
                            dndEnabledByApp = true
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("DND_ERROR", e.message, null)
                    }
                }
                "disableDnd" -> {
                    try {
                        if (notificationManager.isNotificationPolicyAccessGranted && dndEnabledByApp) {
                            val filterToRestore = previousInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                            notificationManager.setInterruptionFilter(filterToRestore)
                            dndEnabledByApp = false
                            previousInterruptionFilter = null
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        result.error("DND_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (dndEnabledByApp) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (notificationManager?.isNotificationPolicyAccessGranted == true) {
                val filterToRestore = previousInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                notificationManager.setInterruptionFilter(filterToRestore)
            }
            dndEnabledByApp = false
        }
        super.onDestroy()
    }
}
