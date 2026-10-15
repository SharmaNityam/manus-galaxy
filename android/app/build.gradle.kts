import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releasePropertiesFile = rootProject.file("key.properties")
val releaseProperties = Properties().apply {
    if (releasePropertiesFile.exists()) {
        releasePropertiesFile.inputStream().use(::load)
    }
}
val releaseStoreFile = releaseProperties.getProperty("storeFile")
val releaseAlias = releaseProperties.getProperty("keyAlias")
val releaseStorePassword = releaseProperties.getProperty("storePassword")
val releaseKeyPassword = releaseProperties.getProperty("keyPassword")
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

if (releaseTaskRequested && listOf(
        releaseStoreFile,
        releaseAlias,
        releaseStorePassword,
        releaseKeyPassword,
    ).any { it.isNullOrBlank() }
) {
    throw GradleException(
        "Release signing is not configured. Add android/key.properties and a private keystore; see README.md."
    )
}

android {
    namespace = "com.galaxyai.manusgalaxy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.galaxyai.manusgalaxy"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!releaseStoreFile.isNullOrBlank()) {
                storeFile = rootProject.file(releaseStoreFile)
                keyAlias = releaseAlias
                storePassword = releaseStorePassword
                this.keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
