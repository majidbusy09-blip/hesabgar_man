#!/usr/bin/env python3
"""Patch android/app/build.gradle(.kts) for release signing."""
from pathlib import Path
import re
import sys

def patch_kts(path: Path) -> None:
    text = path.read_text()

    # Ensure imports
    imports = [
        "import java.util.Properties",
        "import java.io.FileInputStream",
    ]
    for imp in imports:
        if imp not in text:
            # after plugins block or at top
            if "plugins {" in text:
                # insert after plugins block closing
                m = re.search(r"plugins\s*\{[^}]*\}", text, re.DOTALL)
                if m:
                    pos = m.end()
                    text = text[:pos] + "\n\n" + imp + text[pos:]
                else:
                    text = imp + "\n" + text
            else:
                text = imp + "\n" + text

    if "keystoreProperties" not in text:
        block = """
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
"""
        # place before android {
        if "android {" in text:
            text = text.replace("android {", block + "\nandroid {", 1)
        else:
            text = block + "\n" + text

    if "signingConfigs" not in text:
        signing = """
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
"""
        text = text.replace("android {", "android {" + signing, 1)

    # Attach signingConfig to release buildType
    if 'signingConfig = signingConfigs.getByName("release")' not in text:
        # match release { inside buildTypes
        text = re.sub(
            r'(buildTypes\s*\{[^}]*?release\s*\{)',
            r'\1\n            signingConfig = signingConfigs.getByName("release")',
            text,
            count=1,
            flags=re.DOTALL,
        )
        # fallback simpler
        if 'signingConfig = signingConfigs.getByName("release")' not in text:
            text = text.replace(
                "release {",
                'release {\n            signingConfig = signingConfigs.getByName("release")',
                1,
            )

    path.write_text(text)
    print(f"Patched KTS: {path}")


def patch_groovy(path: Path) -> None:
    text = path.read_text()
    if "keystoreProperties" not in text:
        header = """def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

"""
        text = header + text
    if "signingConfigs" not in text:
        signing = """
    signingConfigs {
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }
"""
        text = text.replace("android {", "android {" + signing, 1)
    if "signingConfig signingConfigs.release" not in text:
        text = text.replace(
            "release {",
            "release {\n            signingConfig signingConfigs.release",
            1,
        )
    path.write_text(text)
    print(f"Patched Groovy: {path}")


def main() -> int:
    kts = Path("android/app/build.gradle.kts")
    groovy = Path("android/app/build.gradle")
    if kts.exists():
        patch_kts(kts)
        return 0
    if groovy.exists():
        patch_groovy(groovy)
        return 0
    print("No gradle file found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
