allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.set(file("../build"))

subprojects {
    when (project.name) {
        // Redirect :app output so Flutter CLI finds the APK in build/app/
        "app" -> layout.buildDirectory.set(rootProject.file("../build/app"))
        // Don't touch :gradle (Flutter tools composite build)
        "gradle" -> { /* no-op */ }
        // All Flutter plugin subprojects must evaluate after :app
        else -> project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
