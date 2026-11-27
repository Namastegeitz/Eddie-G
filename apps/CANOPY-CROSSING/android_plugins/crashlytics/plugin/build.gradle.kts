import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

// Versions the game's Android build also declares (addons/canopy_crashlytics/plugin.gd).
val godotVersion = "4.7.2.stable"
val firebaseBom = "35.2.0"

android {
    namespace = "com.aethertek.canopycrossing.crashlytics"
    compileSdk = 36
    defaultConfig {
        minSdk = 24
        consumerProguardFiles("consumer-rules.pro")
    }
    buildTypes {
        release { isMinifyEnabled = false }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions { jvmTarget.set(JvmTarget.JVM_17) }
}

dependencies {
    // provided at run time by the game (Godot) and by the dependencies the
    // export plugin adds to the app's Gradle build
    compileOnly("org.godotengine:godot:$godotVersion")
    compileOnly(platform("com.google.firebase:firebase-bom:$firebaseBom"))
    compileOnly("com.google.firebase:firebase-crashlytics")
}
