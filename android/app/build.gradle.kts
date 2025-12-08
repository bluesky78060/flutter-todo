import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Load local properties (for API keys)
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "kr.bluesky.dodo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "kr.bluesky.dodo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Google Maps API Key from local.properties
        val mapsApiKey = localProperties.getProperty("MAPS_API_KEY") ?: "YOUR_GOOGLE_MAPS_API_KEY_HERE"
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey

        // Naver Maps Client ID from local.properties
        val naverClientId = localProperties.getProperty("NAVER_CLIENT_ID") ?: ""
        manifestPlaceholders["NAVER_CLIENT_ID"] = naverClientId
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }

            // 코드 최적화 활성화
            isMinifyEnabled = true
            // 리소스 최적화 활성화
            isShrinkResources = true

            // ProGuard 규칙 파일
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // 네이티브 디버그 심볼 비활성화 (Apple Silicon strip 문제)
            // Flutter 3.38에서 내부 strip 프로세스가 실패하므로 완전히 제거
            // ndk { debugSymbolLevel = "none" }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Kotlin Coroutines for background widget operations
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
