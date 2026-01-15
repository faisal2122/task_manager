plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.task_manager"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "27.0.12077973" // Match your NDK version

    defaultConfig {
        applicationId = "com.example.task_manager"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false

            // Disable stripping of debug symbols
            ndk {
                debugSymbolLevel = "none"
            }

            // Legacy JNI packaging fixes CI builds
            packaging {
                jniLibs {
                    useLegacyPackaging = true
                }
            }
        }

        getByName("debug") {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}
