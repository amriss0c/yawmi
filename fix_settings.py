import os

path = 'android/settings.gradle.kts'
if os.path.exists(path):
    with open(path, 'r') as f:
        content = f.read()
    
    # This logic forces the dependency management at the global level
    global_force = """
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

// Force buildToolsVersion for all modules discovered in this project
gradle.beforeProject {
    project.afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            compileSdkVersion(34)
            buildToolsVersion("34.0.0")
        }
    }
}
"""
    if "dependencyResolutionManagement" not in content:
        with open(path, 'a') as f:
            f.write(global_force)
        print("SUCCESS: Global resolution strategy injected into settings.gradle.kts")
    else:
        print("LOG: Logic already present or settings managed elsewhere.")
else:
    print("ERROR: android/settings.gradle.kts not found.")
