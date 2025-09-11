plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Import for Properties class
import java.util.Properties

android {
    namespace = "com.stockira"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.stockira"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Secure API Key configuration with proper imports
        val localProperties = Properties()
        val localPropertiesFile = rootProject.file("../local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { localProperties.load(it) }
        }
        
        // Get Google Maps API key from local.properties or use fallback
        val googleMapsApiKey = localProperties.getProperty("GOOGLE_MAPS_API_KEY_ANDROID") 
            ?: "AIzaSyAC-5pPVZot30WENTHNSntNsFfqMbjQFjw" // Fallback
            
        // Get Google Maps Map ID from local.properties or use fallback
        val googleMapsMapId = localProperties.getProperty("GOOGLE_MAPS_MAP_ID_ANDROID") 
            ?: "71ed63eff6a1ac4fe8b35b3d" // Fallback
            
        // Add as manifest placeholders
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
        manifestPlaceholders["GOOGLE_MAPS_MAP_ID"] = googleMapsMapId
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
