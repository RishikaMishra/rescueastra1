
allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    configurations.all {
        resolutionStrategy {
            force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
            force("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
        }
    }
}

subprojects {
    afterEvaluate {
        if (pluginManager.hasPlugin("com.android.library")) {
            extensions.getByType(com.android.build.gradle.LibraryExtension::class.java).apply {
                if (namespace == null) {
                    namespace = "com.example.rescueastra.${project.name}"
                }
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
