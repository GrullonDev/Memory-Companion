import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release: android/key.properties (no se sube al repositorio) con
// storeFile, storePassword, keyAlias y keyPassword. Sin ese archivo, el
// release se firma con la clave de debug para que `flutter run --release`
// siga funcionando en local, pero ese APK no se puede publicar.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.grullondev.memory_arcade"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.grullondev.memory_arcade"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    // Desarrollo y producción son apps distintas: el build de debug y el de
    // profile llevan el sufijo `.dev` y el nombre "Memory Arcade Dev", así
    // que se instalan una al lado de la otra y cada una guarda sus propios
    // datos locales y su propia sesión. Firebase las distingue por el
    // paquete: google-services.json tiene que incluir las dos apps.
    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Memory Arcade Dev"
        }
        getByName("profile") {
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Memory Arcade Dev"
        }
        release {
            manifestPlaceholders["appName"] = "Memory Arcade"
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
