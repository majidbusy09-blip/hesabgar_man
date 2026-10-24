#!/usr/bin/env python3
"""Robustly patch Flutter android/app/build.gradle(.kts) for release signing."""
from pathlib import Path
import re
import sys


def brace_match(text: str, open_idx: int) -> int:
    """Return index after matching closing brace for '{' at open_idx."""
    depth = 0
    i = open_idx
    while i < len(text):
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    return -1


def patch_kts(path: Path) -> None:
    text = path.read_text()

    # --- imports ---
    for imp in (
        "import java.util.Properties",
        "import java.io.FileInputStream",
    ):
        if imp not in text:
            text = imp + "\n" + text

    # --- keystore properties loader (once) ---
    props_block = """
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
"""
    if "keystoreProperties" not in text:
        # insert just before first "android {"
        idx = text.find("android {")
        if idx < 0:
            raise SystemExit("android { not found in " + str(path))
        text = text[:idx] + props_block + "\n" + text[idx:]

    # --- signingConfigs block ---
    signing_block = """
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
"""
    if "create(\"release\")" not in text and "create('release')" not in text:
        idx = text.find("android {")
        if idx < 0:
            raise SystemExit("android { not found")
        # insert right after "android {"
        insert_at = idx + len("android {")
        text = text[:insert_at] + signing_block + text[insert_at:]

    # --- point release buildType to release signing ---
    # Prefer replacing debug signingConfig if present
    text2 = re.sub(
        r'signingConfig\s*=\s*signingConfigs\.getByName\(\s*["\']debug["\']\s*\)',
        'signingConfig = signingConfigs.getByName("release")',
        text,
    )
    if text2 != text:
        text = text2
    elif 'signingConfigs.getByName("release")' not in text:
        # inject into first release { under buildTypes
        m = re.search(r"buildTypes\s*\{", text)
        if m:
            # find release { after buildTypes
            sub = text[m.end() :]
            rm = re.search(r"release\s*\{", sub)
            if rm:
                abs_pos = m.end() + rm.end()
                text = (
                    text[:abs_pos]
                    + '\n            signingConfig = signingConfigs.getByName("release")'
                    + text[abs_pos:]
                )
        else:
            # last resort: first release {
            text = text.replace(
                "release {",
                'release {\n            signingConfig = signingConfigs.getByName("release")',
                1,
            )

    path.write_text(text)
    print("Patched KTS OK:", path)
    # sanity check
    if 'getByName("release")' in text and "create(\"release\")" not in text:
        print("WARNING: release referenced but not created")


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
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
"""
        text = text.replace("android {", "android {" + signing, 1)
    text = re.sub(
        r"signingConfig\s+signingConfigs\.debug",
        "signingConfig signingConfigs.release",
        text,
    )
    if "signingConfig signingConfigs.release" not in text:
        text = text.replace(
            "release {",
            "release {\n            signingConfig signingConfigs.release",
            1,
        )
    path.write_text(text)
    print("Patched Groovy OK:", path)


def main() -> int:
    kts = Path("android/app/build.gradle.kts")
    groovy = Path("android/app/build.gradle")
    if kts.exists():
        patch_kts(kts)
        print("--- result preview ---")
        print(kts.read_text()[:2500])
        return 0
    if groovy.exists():
        patch_groovy(groovy)
        return 0
    print("No gradle file found", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
