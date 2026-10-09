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
        versionCode = 1
        versionName = "1.2.2"

        // Google's own test identifiers until the real AdMob Android app and rewarded unit exist. Supply the real
        // ones with -PADMOB_APP_ID=... -PADMOB_REWARDED_UNIT_ID=... (or in ~/.gradle/gradle.properties).
        val appId = (project.findProperty("ADMOB_APP_ID") as String?) ?: "ca-app-pub-3940256099942544~3347511713"
        manifestPlaceholders["admobAppId"] = appId
    }

    buildTypes {
        debug {
            buildConfigField("String", "REWARDED_UNIT_ID", "\"ca-app-pub-3940256099942544/5224354917\"")
        }
        release {
            val unit = (project.findProperty("ADMOB_REWARDED_UNIT_ID") as String?) ?: "ca-app-pub-3940256099942544/5224354917"
            buildConfigField("String", "REWARDED_UNIT_ID", "\"$unit\"")
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
