import os

path = 'android/build.gradle.kts'
if os.path.exists(path):
    with open(path, 'r') as f:
        content = f.read()
    
    # This force-alignment logic hijacks every sub-plugin's internal request
    force_logic = """
allprojects {
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                useVersion("8.1.0")
            }
        }
    }
}

subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.apply {
            compileSdkVersion(34)
            buildToolsVersion("34.0.0")
        }
    }
}
"""
    if "subprojects" not in content:
        with open(path, 'a') as f:
            f.write(force_logic)
        print("SUCCESS: Root .kts force-alignment injected.")
    else:
        print("LOG: Logic already exists.")
else:
    print("ERROR: Root build.gradle.kts not found.")
