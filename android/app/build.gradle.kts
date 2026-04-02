plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.zenzer0s.kite"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.zenzer0s.kite"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.clear()
            abiFilters.add("arm64-v8a")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    packaging {
        jniLibs {
            keepDebugSymbols += setOf(
                "**/libpython.zip.so",
                "**/libffmpeg.zip.so",
                "**/libaria2c.zip.so"
            )
            excludes += setOf(
                "lib/x86/**",
                "lib/x86_64/**",
                "lib/armeabi/**",
                "lib/armeabi-v7a/**"
            )
        }
    }
}

flutter {
    source = "../.."
}

tasks.register<Exec>("uploadToTelegram") {
    group = "upload"
    description = "Uploads the release APK to Telegram."
    commandLine("python3", "${project.projectDir}/../upload_to_telegram.py")
    isIgnoreExitValue = true
}

afterEvaluate {
    tasks.findByName("assembleRelease")?.finalizedBy("uploadToTelegram")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")
    implementation("io.github.junkfood02.youtubedl-android:aria2c:0.18.1")
}
