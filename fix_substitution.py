import os
path = 'android/build.gradle.kts'
if os.path.exists(path):
    with open(path, 'r') as f: content = f.read()
    
    # Global version substitution logic
    logic = """
configurations.all {
    resolutionStrategy {
        eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                useVersion("8.1.0")
            }
        }
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
            android.buildToolsVersion("34.0.0")
            android.compileSdkVersion(34)
        }
    }
}
"""
    if "resolutionStrategy" not in content:
        with open(path, 'a') as f: f.write(logic)
        print("SUCCESS: Version substitution injected.")
else:
    print("ERROR: Root build.gradle.kts not found.")
