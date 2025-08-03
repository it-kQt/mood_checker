﻿plugins {
	id("com.android.application")
	id("kotlin-android")
	id("dev.flutter.flutter-gradle-plugin")
}

android {
	namespace = "com.example.it_kqt_mood"
	compileSdk = 35
	defaultConfig {
    applicationId = "com.example.it_kqt_mood"
    minSdk = 21
    targetSdk = 35
    versionCode = 1
    versionName = "1.0"
}

buildTypes {
    release {
        // Для отладки: минификация и удаление ресурсов выключены
        isMinifyEnabled = false
        isShrinkResources = false
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
    debug {
        // Явно выключим на всякий случай и для debug
        isMinifyEnabled = false
        isShrinkResources = false
    }
}

compileOptions {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

kotlinOptions {
    jvmTarget = "17"
}
}

dependencies {
implementation("org.jetbrains.kotlin:kotlin-stdlib")
}