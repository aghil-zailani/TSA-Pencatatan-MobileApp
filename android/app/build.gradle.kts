// File: android/app/build.gradle.kts (LEVEL MODUL/APLIKASI - yang Anda tunjukkan)
plugins {
    id("com.android.application")       // Hapus 'version "8.5.1" apply false'
    id("kotlin-android")                // Cara standar untuk menerapkan plugin Kotlin Android
    // id("org.jetbrains.kotlin.android") // Ini tidak perlu jika sudah ada "kotlin-android"
    id("dev.flutter.flutter-gradle-plugin") // Plugin Flutter diterapkan di sini
}

android {
    namespace = "com.example.tunassiakanugrah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
//    compileSdkVersion 33 // Ini sudah di-comment, bagus

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.tunassiakanugrah"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}