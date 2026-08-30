import com.android.build.gradle.LibraryExtension
import com.android.build.gradle.AppExtension
import org.gradle.kotlin.dsl.configure
import org.gradle.api.file.Directory // Importar Directory para resolver el error si no está

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.3")
        // ¡Añade esta línea para el plugin de Crashlytics!
        classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9") // Asegúrate de usar la versión más reciente
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    // Force enabling buildConfig for Android library and application modules
    plugins.withId("com.android.library") {
        configure<com.android.build.gradle.LibraryExtension> {
            val ns = namespace
            if (ns == null || ns.isBlank()) {
                namespace = "com.develop4god.automatic.${project.name.replace('-', '_')}"
            }
            buildFeatures.buildConfig = true
        }
    }
    plugins.withId("com.android.application") {
        configure<com.android.build.gradle.AppExtension> {
            val ns = namespace
            if (ns == null || ns.isBlank()) {
                namespace = "com.develop4god.${project.name.replace('-', '_')}"
            }
            buildFeatures.buildConfig = true
        }
    }
}