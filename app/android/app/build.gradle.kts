import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// A chave de assinatura da release (issue #112, decisão 11 da E6) nunca entra
// no repositório: `android/key.properties` aponta para ela e é ignorado pelo
// git. Na CI de release, a Action escreve esse arquivo a partir dos segredos;
// na máquina do autor, ele aponta para a cópia privada. Ver
// docs/06-app/release-e-distribuicao.md.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

android {
    namespace = "br.dev.rds.mae"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // O ota_update (a atualização pelo próprio aplicativo, issue #113)
        // usa APIs novas do Java e exige que o app as traduza para os
        // Androids mais antigos.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "br.dev.rds.mae"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sem `key.properties`, a release cai na chave de depuração, para
            // que `flutter run --release` funcione em qualquer máquina. Esse
            // APK nunca chega às merendeiras: a Action de release confere o
            // certificado antes de publicar e recusa o de depuração.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
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

dependencies {
    // A mesma versão que o ota_update declara.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
