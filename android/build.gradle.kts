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
subprojects {
    val configureAndroid = {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                try {
                    val setCompileSdk = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    setCompileSdk.invoke(android, 36)
                } catch (e: NoSuchMethodException) {
                    try {
                        val compileSdkVersion = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                        compileSdkVersion.invoke(android, 36)
                    } catch (e2: Exception) {
                        println("Failed to override compileSdk for ${project.name}: ${e2.message}")
                    }
                } catch (e: Exception) {
                    println("Failed to override compileSdk for ${project.name}: ${e.message}")
                }
            }
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate {
            configureAndroid()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
