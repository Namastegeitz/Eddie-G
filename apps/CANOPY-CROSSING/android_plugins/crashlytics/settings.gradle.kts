// The Firebase Crashlytics plugin for Canopy Crossing's Android build.
// Build: gradle -p apps/CANOPY-CROSSING/android_plugins/crashlytics :plugin:assembleRelease
// (tools/build_crashlytics.sh does this and copies the .aar into addons/).
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.library") version "8.13.2"
        id("org.jetbrains.kotlin.android") version "2.1.21"
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "CanopyCrashlytics"
include(":plugin")
