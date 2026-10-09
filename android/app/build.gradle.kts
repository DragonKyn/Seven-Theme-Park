plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "com.wickedstudios.wonderlot"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.wickedstudios.wonderlot"
        minSdk = 24
        targetSdk = 35
        // The store insists the code goes up on every upload; CI passes its run number.
        versionCode = (project.findProperty("VERSION_CODE") as String?)?.toIntOrNull() ?: 1
        versionName = "1.2.2"

        // Google's own test identifiers until the real AdMob Android app and rewarded unit exist. Supply the real
        // ones with -PADMOB_APP_ID=... -PADMOB_REWARDED_UNIT_ID=... (or in ~/.gradle/gradle.properties).
        val appId = (project.findProperty("ADMOB_APP_ID") as String?) ?: "ca-app-pub-3940256099942544~3347511713"
        manifestPlaceholders["admobAppId"] = appId
    }

    // Release signing comes from the environment or Gradle properties, never from a file in the repository.
    signingConfigs {
        create("release") {
            val path = System.getenv("RELEASE_STORE_FILE") ?: project.findProperty("RELEASE_STORE_FILE") as String?
            if (path != null && file(path).exists()) {
                storeFile = file(path)
                storePassword = System.getenv("RELEASE_STORE_PASSWORD") ?: project.findProperty("RELEASE_STORE_PASSWORD") as String?
                keyAlias = System.getenv("RELEASE_KEY_ALIAS") ?: project.findProperty("RELEASE_KEY_ALIAS") as String?
                keyPassword = System.getenv("RELEASE_KEY_PASSWORD") ?: project.findProperty("RELEASE_KEY_PASSWORD") as String?
            }
        }
    }

    buildTypes {
        debug {
            buildConfigField("String", "REWARDED_UNIT_ID", "\"ca-app-pub-3940256099942544/5224354917\"")
        }
        release {
            val unit = (project.findProperty("ADMOB_REWARDED_UNIT_ID") as String?) ?: "ca-app-pub-3940256099942544/5224354917"
            buildConfigField("String", "REWARDED_UNIT_ID", "\"$unit\"")
            val release = signingConfigs.getByName("release")
            if (release.storeFile != null) signingConfig = release
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    buildFeatures {
        compose = true
        buildConfig = true
    }
}

dependencies {
    implementation(project(":core"))
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.6")
    implementation("com.google.android.gms:play-services-ads:23.6.0")
    implementation("com.google.android.ump:user-messaging-platform:3.1.0")
}

// The interface reads plain, mutable game state that is not observable by Compose, and is told to
// redraw by a version number instead. With strong skipping, a composable handed the same controller
// object is skipped and never sees the change, so the menus appear dead. Turn it off.
composeCompiler {
    enableStrongSkippingMode = false
}
