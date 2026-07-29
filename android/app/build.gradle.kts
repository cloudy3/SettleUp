import org.jetbrains.kotlin.gradle.dsl.JvmTarget

import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Workaround: KGP 2.x task not registered due to Flutter plugin interference during AS sync
tasks.register("prepareKotlinBuildScriptModel") {}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.jf.settleup"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.jf.settleup"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Only declare the release signing config when key.properties is present.
    // Without this guard a fresh clone or CI checkout fails during Gradle
    // *configuration* — even for a debug build — because the property reads
    // below cast null to String.
    if (hasReleaseSigning) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                // Falls back to the debug keys so `flutter build --release` still
                // produces a runnable artifact. Not publishable to Play.
                logger.warn("key.properties not found — signing release with debug keys.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // Version-aligns the Firebase artifacts pulled in transitively by the
    // FlutterFire plugins. firebase-analytics is deliberately not declared: the
    // app has no firebase_analytics Dart dependency, and pulling it in merges
    // AD_ID / ACCESS_ADSERVICES_* permissions into the manifest, which forces an
    // advertising-ID declaration in Play Console Data Safety for an unused feature.
    implementation(platform("com.google.firebase:firebase-bom:34.16.0"))
    // Required by the Theme.MaterialComponents parents in res/values/styles.xml.
    implementation("com.google.android.material:material:1.14.0")
}

flutter {
    source = "../.."
}
