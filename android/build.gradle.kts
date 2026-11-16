allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// CameraX 1.5.3 exposes a type annotation referencing concurrent-futures but
// declares it only at runtime. Gradle 9/JDK 21+ need it at compile time too.
// https://github.com/flutter/flutter/issues/183515
subprojects {
    if (name == "camera_android_camerax") {
        pluginManager.withPlugin("com.android.library") {
            dependencies.add("implementation", "androidx.concurrent:concurrent-futures:1.3.0")
        }
    }
}

// tflite_flutter 0.11.0 compiles Java for 1.8 but leaves Kotlin on the JDK
// default (21), which fails KGP's JVM-target validation. Align Kotlin to 1.8.
subprojects {
    if (name == "tflite_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8)
        }
        // The plugin pins compileSdk 31; its AndroidX deps need >= 34.
        val raiseCompileSdk = {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                compileSdk = 36
            }
        }
        if (state.executed) raiseCompileSdk() else afterEvaluate { raiseCompileSdk() }
    }
}

// tensorflow-lite 2.11 (pulled in by tflite_flutter) reuses the namespace
// 'org.tensorflow.lite' across 3 AARs, which current AGP rejects. LiteRT is the
// same runtime (ships libtensorflowlite_jni.so used via Dart FFI) with unique
// namespaces. The GPU delegate is not used by the app, so it is dropped.
allprojects {
    configurations.configureEach {
        exclude(group = "org.tensorflow", module = "tensorflow-lite-gpu")
        resolutionStrategy.dependencySubstitution {
            substitute(module("org.tensorflow:tensorflow-lite"))
                .using(module("com.google.ai.edge.litert:litert:1.0.1"))
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
