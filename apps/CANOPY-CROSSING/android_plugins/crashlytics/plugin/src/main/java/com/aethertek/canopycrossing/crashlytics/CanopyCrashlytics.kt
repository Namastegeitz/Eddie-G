package com.aethertek.canopycrossing.crashlytics

import android.app.Activity
import android.util.Log
import android.view.View
import com.google.firebase.FirebaseApp
import com.google.firebase.crashlytics.FirebaseCrashlytics
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Firebase Crashlytics for Canopy Crossing (autoload/crash_report.gd calls it).
 *
 * Crashes of the game itself (Kotlin/Java) and of the engine (native, through
 * firebase-crashlytics-ndk) are caught by Crashlytics on its own; the game adds
 * breadcrumbs, a few keys (version, jungle, level, view) and its script errors
 * as non-fatal reports. Nothing personal is set: no user id, name or email.
 *
 * If the app was built without a Firebase config (no google-services values),
 * Firebase doesn't start and every call here quietly does nothing.
 */
class CanopyCrashlytics(godot: Godot) : GodotPlugin(godot) {

    private var crashlytics: FirebaseCrashlytics? = null

    override fun getPluginName(): String = "CanopyCrashlytics"

    override fun onMainCreate(activity: Activity?): View? {
        try {
            val context = (activity ?: getActivity())?.applicationContext ?: return null
            if (FirebaseApp.getApps(context).isEmpty()) {
                FirebaseApp.initializeApp(context)
            }
            if (FirebaseApp.getApps(context).isNotEmpty()) {
                crashlytics = FirebaseCrashlytics.getInstance()
            } else {
                Log.i(TAG, "No Firebase config in this build: crash reports are off")
            }
        } catch (e: Throwable) {
            Log.w(TAG, "Crashlytics unavailable: ${e.message}")
            crashlytics = null
        }
        return null
    }

    /** True when Firebase started and reports can be sent. */
    @UsedByGodot
    fun isReady(): Boolean = crashlytics != null

    /** The player's choice in Settings > Send crash reports (remembered by Crashlytics). */
    @UsedByGodot
    fun setCollectionEnabled(on: Boolean) {
        crashlytics?.setCrashlyticsCollectionEnabled(on)
    }

    /** A breadcrumb: shown in the next report as what the player was doing. */
    @UsedByGodot
    fun log(message: String) {
        crashlytics?.log(message)
    }

    @UsedByGodot
    fun setKey(key: String, value: String) {
        crashlytics?.setCustomKey(key, value)
    }

    /** A handled problem or a script error, sent as a non-fatal report. */
    @UsedByGodot
    fun recordError(message: String, details: String) {
        crashlytics?.recordException(GameScriptError(message, details))
    }

    companion object {
        private const val TAG = "CanopyCrashlytics"
    }
}

/** How a script error shows up in Crashlytics: the message, then where and what led to it. */
class GameScriptError(message: String, details: String) : Exception(message + if (details.isBlank()) "" else "\n" + details)
