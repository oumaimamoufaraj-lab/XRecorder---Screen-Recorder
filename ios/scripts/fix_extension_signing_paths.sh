#!/usr/bin/env bash
# Codemagic `xcode-project use-profiles` rewrites extension paths to bundle-id
# folder names that do not exist. Restore real source/entitlements paths only.
set -euo pipefail

PBXPROJ="${1:-ios/Runner.xcodeproj/project.pbxproj}"

if [[ ! -f "$PBXPROJ" ]]; then
  echo "Missing $PBXPROJ" >&2
  exit 1
fi

python3 - "$PBXPROJ" <<'PY'
from pathlib import Path
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

path.write_text(text)
print(f"Patched extension paths in {path}")
PY

INFO_PLIST="ios/Runner/Info.plist"
if [[ -f "$INFO_PLIST" ]]; then
  /usr/libexec/PlistBuddy -c "Set :ReplayKitBroadcastExtensionBundleId com.xrecorder.screenVideo.BroadcastExtension" "$INFO_PLIST" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :ReplayKitBroadcastExtensionBundleId string com.xrecorder.screenVideo.BroadcastExtension" "$INFO_PLIST"
  echo "Set ReplayKitBroadcastExtensionBundleId in $INFO_PLIST"
fi
