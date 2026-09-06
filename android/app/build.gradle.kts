import java.util.Properties

// Release signing material never lives in the repository. It comes from
// android/key.properties (git-ignored, for local runs) or, in CI and the
// Fastlane lanes, from the environment. Missing material is not an error at
// configure time — debug and profile builds must still work on a machine that
// has none.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

fun signingValue(key: String, env: String): String? =
    System.getenv(env) ?: keystoreProperties.getProperty(key)

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.alreuter.dokuduty"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.alreuter.dokuduty"
        // Android 8.0. Fixed by D-69 alongside the identifiers, because every
        // later change is written against this API floor.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // The three flavours install side by side: distinct applicationId, distinct
    // launcher label (D-69). The label comes from each flavour's own
    // src/<flavour>/res/values/strings.xml rather than resValue(), which AGP
    // now disables by default. Keep the values in step with FlavourConfig in
    // lib/features/platform_shell/domain/flavour.dart — flavour_test.dart and
    // the manifest check in CI are what catch a drift.
    flavorDimensions += "app"

    productFlavors {
        create("dev") {
            dimension = "app"
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".staging"
        }
        create("prod") {
            dimension = "app"
        }
    }

    signingConfigs {
        create("release") {
            val storePath = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")
            if (storePath != null) {
                storeFile = file(storePath)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug keys when no release material is present,
            // so `flutter run --release` still works on a fresh checkout. The
            // Fastlane lane fails loudly rather than shipping a debug-signed
            // build — see fastlane/Fastfile.
            signingConfig = if (signingValue("storeFile", "ANDROID_KEYSTORE_PATH") != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
