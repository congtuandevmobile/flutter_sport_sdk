import org.jetbrains.kotlin.gradle.plugin.mpp.apple.XCFramework

plugins {
    kotlin("multiplatform") version "2.2.20"
}

group = "io.github.congtuandevmobile.sensor"
version = "0.0.1"

kotlin {
    // Pure Kotlin: no platform API, no third-party library. Android compiles src/commonMain directly into the
    // plugin that uses it; iOS gets the framework below.
    jvm() // fast unit tests on the development machine

    val xcf = XCFramework("SensorCore")
    listOf(iosArm64(), iosSimulatorArm64(), iosX64()).forEach { target ->
        target.binaries.framework {
            baseName = "SensorCore"
            isStatic = true
            xcf.add(this)
        }
    }

    sourceSets {
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
    }
}
