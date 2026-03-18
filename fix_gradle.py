import re
path = 'android/app/build.gradle.kts'
with open(path, 'r') as f: c = f.read()

# Force the SDK versions in the android block
c = re.sub(r'compileSdk = .*', 'compileSdk = 34', c)
c = re.sub(r'targetSdk = .*', 'targetSdk = 34', c)

# Inject the subprojects override at the end of the file
override = """
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
if "subprojects" not in c:
    c += override

with open(path, 'w') as f: f.write(c)
