#!/usr/bin/env bash
# Codemagic `xcode-project use-profiles` rewrites extension paths to bundle-id
# folder names that do not exist, and may reset signing to Automatic.
set -euo pipefail

PBXPROJ="${1:-ios/Runner.xcodeproj/project.pbxproj}"

if [[ ! -f "$PBXPROJ" ]]; then
  echo "Missing $PBXPROJ" >&2
  exit 1
fi

python3 - "$PBXPROJ" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

replacements = [
    (
        "com.xrecorder.screenVideo.com.xrecorder.screenVideo.BroadcastExtension",
        "com.xrecorder.screenVideo.BroadcastExtension",
    ),
    (
        "com.xrecorder.screenVideo.com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI",
        "com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI",
    ),
    (
        "com.xrecorder.screenVideo.com.xrecorder.screenVideo.BroadcastExtensionSetupUI",
        "com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI",
    ),
    (
        "PRODUCT_BUNDLE_IDENTIFIER = com.xrecorder.screenVideo.BroadcastExtensionSetupUI;",
        "PRODUCT_BUNDLE_IDENTIFIER = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI;",
    ),
    (
        "com.xrecorder.screenVideo.BroadcastExtension/com.xrecorder.screenVideo.BroadcastExtensionDebug.entitlements",
        "BroadcastUploadExtension/BroadcastUploadExtensionDebug.entitlements",
    ),
    (
        "com.xrecorder.screenVideo.BroadcastExtension/com.xrecorder.screenVideo.BroadcastExtension.entitlements",
        "BroadcastUploadExtension/BroadcastUploadExtension.entitlements",
    ),
    (
        "com.xrecorder.screenVideo.BroadcastExtensionSetupUI/com.xrecorder.screenVideo.BroadcastExtensionSetupUI.entitlements",
        "BroadcastUploadExtensionSetupUI/BroadcastUploadExtensionSetupUI.entitlements",
    ),
    (
        "com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI/com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI.entitlements",
        "BroadcastUploadExtensionSetupUI/BroadcastUploadExtensionSetupUI.entitlements",
    ),
    (
        "INFOPLIST_FILE = com.xrecorder.screenVideo.BroadcastExtension/Info.plist",
        "INFOPLIST_FILE = BroadcastUploadExtension/Info.plist",
    ),
    (
        "INFOPLIST_FILE = com.xrecorder.screenVideo.BroadcastExtensionSetupUI/Info.plist",
        "INFOPLIST_FILE = BroadcastUploadExtensionSetupUI/Info.plist",
    ),
    (
        "INFOPLIST_FILE = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI/Info.plist",
        "INFOPLIST_FILE = BroadcastUploadExtensionSetupUI/Info.plist",
    ),
    (
        "path = com.xrecorder.screenVideo.BroadcastExtension;",
        "path = BroadcastUploadExtension;",
    ),
    (
        "path = com.xrecorder.screenVideo.BroadcastExtensionSetupUI;",
        "path = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "path = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI;",
        "path = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "path = com.xrecorder.screenVideo.BroadcastExtension.appex",
        "path = BroadcastUploadExtension.appex",
    ),
    (
        "path = com.xrecorder.screenVideo.BroadcastExtensionSetupUI.appex",
        "path = BroadcastUploadExtensionSetupUI.appex",
    ),
    (
        "path = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI.appex",
        "path = BroadcastUploadExtensionSetupUI.appex",
    ),
    (
        "name = com.xrecorder.screenVideo.BroadcastExtension;",
        "name = BroadcastUploadExtension;",
    ),
    (
        "productName = com.xrecorder.screenVideo.BroadcastExtension;",
        "productName = BroadcastUploadExtension;",
    ),
    (
        "remoteInfo = com.xrecorder.screenVideo.BroadcastExtension;",
        "remoteInfo = BroadcastUploadExtension;",
    ),
    (
        "name = com.xrecorder.screenVideo.BroadcastExtensionSetupUI;",
        "name = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "name = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI;",
        "name = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "productName = com.xrecorder.screenVideo.BroadcastExtensionSetupUI;",
        "productName = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "productName = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI;",
        "productName = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "remoteInfo = com.xrecorder.screenVideo.BroadcastExtensionSetupUI;",
        "remoteInfo = BroadcastUploadExtensionSetupUI;",
    ),
    (
        "remoteInfo = com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI;",
        "remoteInfo = BroadcastUploadExtensionSetupUI;",
    ),
    (
        'PBXNativeTarget "com.xrecorder.screenVideo.BroadcastExtension"',
        'PBXNativeTarget "BroadcastUploadExtension"',
    ),
    (
        'PBXNativeTarget "com.xrecorder.screenVideo.BroadcastExtensionSetupUI"',
        'PBXNativeTarget "BroadcastUploadExtensionSetupUI"',
    ),
    (
        'PBXNativeTarget "com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI"',
        'PBXNativeTarget "BroadcastUploadExtensionSetupUI"',
    ),
    (
        "/* com.xrecorder.screenVideo.BroadcastExtension.appex",
        "/* BroadcastUploadExtension.appex",
    ),
    (
        "/* com.xrecorder.screenVideo.BroadcastExtensionSetupUI.appex",
        "/* BroadcastUploadExtensionSetupUI.appex",
    ),
    (
        "/* com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI.appex",
        "/* BroadcastUploadExtensionSetupUI.appex",
    ),
    (
        "/* com.xrecorder.screenVideo.BroadcastExtension */",
        "/* BroadcastUploadExtension */",
    ),
    (
        "/* com.xrecorder.screenVideo.BroadcastExtensionSetupUI */",
        "/* BroadcastUploadExtensionSetupUI */",
    ),
    (
        "/* com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI */",
        "/* BroadcastUploadExtensionSetupUI */",
    ),
]

for old, new in replacements:
    text = text.replace(old, new)

team_match = re.search(r"DEVELOPMENT_TEAM = ([A-Z0-9]+);", text)
development_team = team_match.group(1) if team_match else "49B45VHG69"

SIGNING_BY_BUNDLE = {
    "com.xrecorder.screenVideo": {
        "PROVISIONING_PROFILE_SPECIFIER": "provisioning_xrecorder",
    },
    "com.xrecorder.screenVideo.BroadcastExtension": {
        "PROVISIONING_PROFILE_SPECIFIER": "xrecorder_broadcast_extension",
    },
    "com.xrecorder.screenVideo.BroadcastUploadExtensionSetupUI": {
        "PROVISIONING_PROFILE_SPECIFIER": "xrecorder_broadcast_setup_ui",
    },
}

SIGNING_KEYS = {
    "CODE_SIGN_STYLE": "Manual",
    "DEVELOPMENT_TEAM": development_team,
    "CODE_SIGN_IDENTITY": '"Apple Distribution"',
    "CODE_SIGN_IDENTITY[sdk=iphoneos*]": '"Apple Distribution"',
}


def upsert_setting(block: str, key: str, value: str) -> str:
    pattern = re.compile(rf"^\t\t\t\t{re.escape(key)} = .*?;\n", re.MULTILINE)
    line = f"\t\t\t\t{key} = {value};\n"
    if pattern.search(block):
        return pattern.sub(line, block, count=1)
    return block.replace("\t\t\tbuildSettings = {\n", f"\t\t\tbuildSettings = {{\n{line}", 1)


def patch_release_profile_signing(source: str) -> str:
    blocks = re.split(r"(?=\n\t\t[A-F0-9]+ /\* (?:Release|Profile) \*/ = \{)", source)
    patched = [blocks[0]]
    for block in blocks[1:]:
        if "name = Release;" not in block and "name = Profile;" not in block:
            patched.append(block)
            continue
        bundle_match = re.search(
            r"PRODUCT_BUNDLE_IDENTIFIER = (com\.xrecorder\.screenVideo(?:\.[A-Za-z]+)?);",
            block,
        )
        if not bundle_match:
            patched.append(block)
            continue
        bundle_id = bundle_match.group(1)
        signing = SIGNING_BY_BUNDLE.get(bundle_id)
        if not signing:
            patched.append(block)
            continue
        for key, value in SIGNING_KEYS.items():
            block = upsert_setting(block, key, value)
        for key, value in signing.items():
            block = upsert_setting(
                block,
                key,
                f'"{value}"' if key == "PROVISIONING_PROFILE_SPECIFIER" else value,
            )
        patched.append(block)
    return "".join(patched)


text = patch_release_profile_signing(text)
path.write_text(text)
print(f"Patched extension paths and Release/Profile signing in {path}")
PY

INFO_PLIST="ios/Runner/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  /usr/libexec/PlistBuddy -c "Set :ReplayKitBroadcastExtensionBundleId com.xrecorder.screenVideo.BroadcastExtension" "$INFO_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :ReplayKitBroadcastExtensionBundleId string com.xrecorder.screenVideo.BroadcastExtension" "$INFO_PLIST"
  echo "Set ReplayKitBroadcastExtensionBundleId in $INFO_PLIST"
fi
