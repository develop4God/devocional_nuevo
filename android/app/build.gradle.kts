// INICIO DE LOS IMPORTS AÑADIDOS/CORREGIDOS
import java.io.FileInputStream
import java.util.Properties
// FIN DE LOS IMPORTS AÑADIDOS/CORREGIDOS

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// INICIO DEL BLOQUE DE CARGA DE PROPIEDADES (igual que antes, pero ahora los imports lo hacen funcionar)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use {
        keystoreProperties.load(it)
    }
}
// FIN DEL BLOQUE DE CARGA DE PROPIEDADES

android {
    namespace = "com.develop4god.devocional_nuevo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // ✅ CAMBIO 1: Agregar esta línea
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.develop4god.devocional_nuevo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // ✅ CAMBIO 2: Agregar esta línea si no está
        multiDexEnabled = true
    }

    // INICIO DEL BLOQUE DE CONFIGURACIÓN DE FIRMA (igual que antes)
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("KEYSTORE_PATH") ?: keystoreProperties.getProperty("storeFile"))
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: keystoreProperties.getProperty("storePassword")
            keyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
            keyPassword = System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
        }
    }
    // FIN DEL BLOQUE DE CONFIGURACIÓN DE FIRMA

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
        debug {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }
}

// ✅ CAMBIO 3: Agregar esta sección de dependencies

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Flutter embedding v2 dependencies
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    
    // Excluir WorkManager
    implementation("androidx.work:work-runtime:2.7.0") {
        exclude(group = "androidx.work", module = "work-runtime")
    }
    
    // Configuración para workmanager
    implementation("androidx.work:work-runtime-ktx:2.7.0")
    
    // Firebase dependencies
    implementation(platform("com.google.firebase:firebase-bom:33.16.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}