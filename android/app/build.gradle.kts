plugins {
    id("com.android.application")
}

// versionCode must grow with every upload to Play (max 2100000000).
// versionName is what people see.
val fVersionCode = (project.findProperty("FORK_VERSION_CODE") as String? ?: "1").toInt()
val fVersionName = project.findProperty("FORK_VERSION_NAME") as String? ?: "0.1.0"

android {
    namespace = "app.fork.editor"
    compileSdk = 36

    defaultConfig {
        applicationId = "app.fork.editor"
        minSdk = 26
        targetSdk = 36          // Play requires 36 for new apps from 31 Aug 2026
        versionCode = fVersionCode
        versionName = fVersionName
        ndk { abiFilters += listOf("arm64-v8a") }
    }

    // The upload key. Play re-signs the app with its own key (Play App
    // Signing), so this key only proves the upload is yours. Keep the
    // keystore and its passwords out of git.
    signingConfigs {
        create("upload") {
            val ks = System.getenv("FORK_KEYSTORE")
            if (ks != null) {
                storeFile = file(ks)
                storePassword = System.getenv("FORK_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("FORK_KEY_ALIAS")
                keyPassword = System.getenv("FORK_KEY_PASSWORD") ?: System.getenv("FORK_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false   // there is no Java/Kotlin code to shrink
            if (System.getenv("FORK_KEYSTORE") != null) {
                signingConfig = signingConfigs.getByName("upload")
            }
        }
    }

    packaging {
        jniLibs {
            // Keep the .so files uncompressed and page-aligned; with AGP
            // 8.5.1+ this gives the 16 KB zip alignment Play checks.
            useLegacyPackaging = false
        }
    }
}
