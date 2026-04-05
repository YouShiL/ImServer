import org.gradle.api.initialization.resolve.RepositoriesMode

val localProperties =
    java.util.Properties().apply {
        file("local.properties").inputStream().use { load(it) }
    }

val flutterSdkPath =
    requireNotNull(localProperties.getProperty("flutter.sdk")) {
        "flutter.sdk not set in local.properties"
    }

val flutterStorageBaseUrl =
    System.getenv("FLUTTER_STORAGE_BASE_URL") ?: "https://storage.googleapis.com"

val flutterEngineRealm =
    run {
        val engineRealmFile = file("$flutterSdkPath/bin/cache/engine.realm")
        val engineRealm = if (engineRealmFile.exists()) engineRealmFile.readText().trim() else ""
        if (engineRealm.isNotEmpty()) "$engineRealm/" else ""
    }

pluginManagement {
    val pluginLocalProperties =
        java.util.Properties().apply {
            file("local.properties").inputStream().use { load(it) }
        }

    val flutterSdkPath =
        requireNotNull(pluginLocalProperties.getProperty("flutter.sdk")) {
            "flutter.sdk not set in local.properties"
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "com.android.application" ->
                    useModule("com.android.tools.build:gradle:${requested.version}")
                "org.jetbrains.kotlin.android" ->
                    useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:${requested.version}")
            }
        }
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        maven(url = "$flutterStorageBaseUrl/${flutterEngineRealm}download.flutter.io") {
            content {
                includeGroup("io.flutter")
            }
        }
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
    }
}

gradle.beforeProject {
    buildscript.repositories.apply {
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    repositories.apply {
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/public")
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
