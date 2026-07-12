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
    val configureAndroid = Action<Project> {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val packaging = android.javaClass.getMethod("getPackaging").invoke(android)
                val jniLibs = packaging.javaClass.getMethod("getJniLibs").invoke(packaging)
                val doNotStrip = jniLibs.javaClass.getMethod("getDoNotStrip").invoke(jniLibs)
                val addMethod = doNotStrip.javaClass.methods.firstOrNull { it.name == "add" && it.parameterCount == 1 }
                addMethod?.invoke(doNotStrip, "**/*.so")
            } catch (e: Exception) {
                try {
                    val packagingOptions = android.javaClass.getMethod("getPackagingOptions").invoke(android)
                    val doNotStrip = packagingOptions.javaClass.getMethod("getDoNotStrip").invoke(packagingOptions) as java.util.Set<String>
                    doNotStrip.add("**/*.so")
                } catch (e2: Exception) {
                    // ignore
                }
            }
        }
    }
    
    if (project.state.executed) {
        configureAndroid.execute(project)
    } else {
        project.afterEvaluate {
            configureAndroid.execute(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
