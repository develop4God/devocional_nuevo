// INICIO DE LOS IMPORTS AÑADIDOS/CORREGIDOS
import java.util.Properties

// FIN DE LOS IMPORTS (eliminado FileInputStream no usado)

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// INICIO DEL BLOQUE DE CARGA DE PROPIEDADES
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
    ndkVersion = "28.2.13676358" // Actualizado para compatibilidad con integration_test

    compileOptions {
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
        multiDexEnabled = true
    }

    signingConfigs {


        if (
            System.getenv("KEYSTORE_PATH") != null ||
            keystoreProperties.getProperty("storeFile") != null
        ) {
            create("release") {
                storeFile = file(
                    System.getenv("KEYSTORE_PATH") ?: keystoreProperties.getProperty("storeFile")
                )
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                    ?: keystoreProperties.getProperty("storePassword")
                keyAlias = System.getenv("KEY_ALIAS") ?: keystoreProperties.getProperty("keyAlias")
                keyPassword =
                    System.getenv("KEY_PASSWORD") ?: keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    // ✅ CORRECCIÓN: Usar lint en lugar de lintOptions
    lint {
        abortOnError = false
        checkReleaseBuilds = false
        baseline = file("lint-baseline.xml")
        // ✅ CORRECCIÓN: Usar nueva sintaxis para disable
        disable += listOf("InvalidPackage", "PrivateApi")
    }

    buildTypes {
        release {
            if (signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")

            ndk {
                abiFilters.addAll(listOf("arm64-v8a"))
            }
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
        }
    }

    // ✅ CORRECCIÓN: Usar packaging en lugar de packagingOptions
    packaging {
        resources {
            excludes.addAll(
                listOf(
                    "META-INF/DEPENDENCIES",
                    "META-INF/LICENSE",
                    "META-INF/LICENSE.txt",
                    "META-INF/license.txt",
                    "META-INF/NOTICE",
                    "META-INF/NOTICE.txt",
                    "META-INF/notice.txt",
                    "META-INF/ASL2.0",
                    "META-INF/*.kotlin_module"
                )
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.window:window:1.5.0")
    implementation("androidx.window:window-java:1.5.0")
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}
