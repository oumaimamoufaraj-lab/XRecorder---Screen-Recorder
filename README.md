# ShieldRec - Screen Recorder

Privacy-first screen recorder for iOS and Android.

Record your screen on-device with no account required. Before sharing, use **Shield Studio** to scan for sensitive text, add blur regions, and export a safe copy — all processing stays on your device.

## Features

- **Capture** — ReplayKit full-device recording with optional microphone audio
- **Clips** — grid library with search, sort, and privacy status badges
- **Shield Studio** — on-device OCR scan (emails/phones), Privacy Score, manual blur regions
- **Safe Export** — redacted video export to Photos via on-device FFmpeg
- **Safe Share** — confirmation with privacy status before sharing
- **Video Info** — inspect resolution, duration, and format
- No ads · No cloud upload · Photos access on Home, Clips, or when you record

## App Store resubmission

See [docs/app_store_resubmission.md](docs/app_store_resubmission.md) for review notes, description copy, and screenshot guidance (Guideline 4.3(a)).

## Development

```bash
flutter pub get
flutter run
```

iOS full-device recording requires a physical iPhone (not Simulator).
