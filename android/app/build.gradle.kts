import java.util.Properties
import java.io.FileInputStream
import org.jetbrains.kotlin.gradle.dsl.JvmTarget // 👈 این خط برای تنظیمات جدید کاتلین اضافه شده

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // id("kotlin-android") // 👈 این خط حذف شد (چون AGP 9 خودش کاتلین را دارد)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "ir.amirali.balebot" 
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // 👈 بخش kotlinOptions از اینجا حذف شد

    defaultConfig {
        applicationId = "ir.amirali.balebot" 
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode()
        versionName = flutter.versionName()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

// 👈 این بلوک جدید جایگزین kotlinOptions قدیمی شده است
kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_1_8)
    }
}

flutter {
    source = "../.."
}