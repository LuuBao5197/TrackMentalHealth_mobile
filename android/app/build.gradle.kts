plugins {
    id("com.android.application")
    id("kotlin-android")
//    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.trackmentalhealth01"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.trackmentalhealth01"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
        
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    buildFeatures {
        buildConfig = true // Bắt buộc cho firebase_auth 4.x
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packagingOptions {
        pickFirst("**/libaosl.so")
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libjsc.so")
    }
}

flutter {
    source = "../.."
}

dependencies {
//    implementation("com.google.firebase:firebase-auth-ktx:22.1.0")
    implementation("androidx.multidex:multidex:2.0.1") // Bắt buộc nếu multiDexEnabled
    implementation("com.google.android.gms:play-services-auth:21.0.0")
}
