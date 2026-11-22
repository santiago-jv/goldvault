import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

fun signingProp(propKey: String, envKey: String): String? {
    val fromFile = keystoreProperties.getProperty(propKey)?.trim()
    if (!fromFile.isNullOrEmpty()) return fromFile
    val fromEnv = System.getenv(envKey)?.trim()
    if (!fromEnv.isNullOrEmpty()) return fromEnv
    return null
}

val releaseStorePath = signingProp("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword = signingProp("storePassword", "KEYSTORE_PASSWORD")
val releaseKeyAlias = signingProp("keyAlias", "KEY_ALIAS")
val releaseKeyPassword = signingProp("keyPassword", "KEY_PASSWORD")
val releaseStoreFile = releaseStorePath?.let { path ->
    val direct = file(path)
    if (direct.exists()) direct else rootProject.file(path)
}
val hasReleaseSigning = releaseStoreFile != null &&
    releaseStoreFile.exists() &&
    !releaseStorePassword.isNullOrEmpty() &&
    !releaseKeyAlias.isNullOrEmpty() &&
    !releaseKeyPassword.isNullOrEmpty()
val requireReleaseSigning = System.getenv("REQUIRE_RELEASE_SIGNING")
    ?.equals("true", ignoreCase = true) == true

android {
    namespace = "app.goldvault.goldvault"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.goldvault.goldvault"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                enableV1Signing = true
                enableV2Signing = true
                enableV3Signing = true
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else if (requireReleaseSigning) {
                throw GradleException(
                    "Release signing is required (REQUIRE_RELEASE_SIGNING=true) but keystore credentials are missing. " +
                        "Configure android/key.properties or set ANDROID_KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD."
                )
            } else {
                logger.warn(
                    "WARNING: Release keystore credentials not configured; falling back to debug signing for non-release verification build."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
