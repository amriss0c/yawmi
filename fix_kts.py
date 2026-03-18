import os

path = 'android/build.gradle.kts'
if os.path.exists(path):
    with open(path, 'r') as f:
        content = f.read()
    
    # Force-alignment logic for Kotlin DSL
    force_logic = """
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
        print("SUCCESS: Subproject force-alignment injected into .kts")
    else:
        print("LOG: Logic already exists in .kts")
else:
    print("ERROR: android/build.gradle.kts not found.")
