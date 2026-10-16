import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Réglages de signature de publication.
//
// `android/key.properties` n'est jamais versionné : il est écrit à la main
// sur la machine qui publie, ou par l'intégration continue à partir des
// secrets du dépôt. Absent, la compilation retombe sur la clé de débogage,
// afin que `flutter run --release` fonctionne sur un dépôt fraîchement
// cloné — mais un tel paquet n'est pas publiable, et la tâche
// `verifierSignature` ci-dessous le dit plutôt que de le laisser passer.
val proprietesSignature = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.exists()) {
        fichier.inputStream().use { load(it) }
    }
}
val signatureDePublication = proprietesSignature.containsKey("storeFile")

android {
    namespace = "com.techlyb.eureka"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.techlyb.eureka"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signatureDePublication) {
            create("release") {
                storeFile = rootProject.file(proprietesSignature["storeFile"] as String)
                storePassword = proprietesSignature["storePassword"] as String
                keyAlias = proprietesSignature["keyAlias"] as String
                keyPassword = proprietesSignature["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signatureDePublication) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // R8 n'est pas activé. La part Java de l'application tient en
            // une poignée de classes — tout le reste est du Dart, déjà
            // élagué par Flutter — et l'obfuscation casse régulièrement des
            // greffons sans que rien ne le signale avant l'exécution sur un
            // vrai appareil. Le gain de taille ne vaut pas ce risque ici.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// Échoue si l'on s'apprête à publier un paquet signé avec la clé de
// débogage. Google Play le refuserait de toute façon, mais dix minutes plus
// tard et avec un message qui ne nomme pas la cause.
tasks.register("verifierSignature") {
    doLast {
        if (!signatureDePublication) {
            throw GradleException(
                "android/key.properties est absent : le paquet serait signé " +
                    "avec la clé de débogage, que Google Play refuse. " +
                    "Voir docs/ANDROID.md.",
            )
        }
        println("Signature de publication : clé « ${proprietesSignature["keyAlias"]} ».")
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
