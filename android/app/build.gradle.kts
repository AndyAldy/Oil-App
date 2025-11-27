import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.oil_monitoring.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        
        // [WAJIB 1] Agar fitur Notifikasi (Java 8) jalan di semua HP
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Ganti ID ini sesuai package name Anda jika berbeda
        applicationId = "com.oil_monitoring.app" 
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // [WAJIB 2] Agar aplikasi tidak crash karena kegemukan kode (Firebase + Maps + Notif)
        multiDexEnabled = true 
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // isMinifyEnabled = true // Aktifkan nanti jika proguard sudah siap
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Library Desugaring (Penerjemah Java 8)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Library MultiDex (Pecah kode biar muat)
    implementation("androidx.multidex:multidex:2.0.1")
}