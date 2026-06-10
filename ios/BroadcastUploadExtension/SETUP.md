# ReplayKit Broadcast Extension Setup

This folder contains a scaffold for an iOS Broadcast Upload Extension.

## Important
The extension target must be added in Xcode (project settings) because `Runner.xcodeproj` still only has the `Runner` target.

## Steps (Xcode)
1. Open `ios/Runner.xcworkspace` in Xcode.
2. `File` -> `New` -> `Target...` -> choose **Broadcast Upload Extension**.
3. Name: `com.xrecorder.screenVideo.BroadcastExtension`.
4. When prompted, **Activate** the new scheme.
5. Replace generated `SampleHandler.swift` and `Info.plist` with files from this folder.
6. Set extension bundle id to: `com.xrecorder.screenVideo.BroadcastExtension`.
7. In the app target (`Runner`) Signing & Capabilities:
   - keep `Runner/Runner.entitlements` attached
   - enable App Groups and add: `group.com.xrecorder.screenvideo.shared`
8. In extension target Signing & Capabilities:
   - match team
   - enable App Groups and add the same: `group.com.xrecorder.screenvideo.shared`

## Flutter side
The Flutter app already exposes an **iOS Broadcast Picker (ReplayKit)** button on Record screen via native channel (`xrecorder/replaykit`).

The app now reads `ReplayKitBroadcastExtensionBundleId` from `Runner/Info.plist` and sets `RPSystemBroadcastPickerView.preferredExtension` automatically.
Default value is already configured as `com.xrecorder.screenVideo.BroadcastExtension`.
