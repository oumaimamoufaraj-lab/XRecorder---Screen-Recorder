# App Store resubmission — Guideline 4.3(a)

Use this when submitting **NowRecorder · Privacy Recorder** v1.1 after the 4.3(a) rejection.

---

## What changed since rejection

- **Privacy-first product:** Shield Studio with on-device OCR scan (emails/phones), manual blur regions, Privacy Score, safe redacted export, and Safe Share confirmation — not a generic record-and-share app.
- **Custom UI:** Vault layout (Home, Capture, Clips, Shield, Menu) designed around the record → review → share workflow.
- **No ads:** All advertising and consent flows removed.
- **Respectful permissions:** Photos access is requested only when the user opens Clips or starts recording — not on launch.

---

## App Review notes (paste into App Store Connect)

```
Thank you for reviewing NowRecorder · Privacy Recorder.

This app is NOT a generic screen recorder. It is a privacy-first recorder with a built-in Shield workflow for reviewing and redacting sensitive content before sharing.

HOW TO TEST THE DIFFERENTIATING FEATURES (2–3 minutes):

1. Open the app and complete onboarding (3 screens — the third explains Shield / Privacy Studio).
2. Tap Capture (center red button) → Start Recording → use Apple’s broadcast picker to record briefly (physical iPhone required).
3. Open the Clips tab → allow Photos if prompted → open a recording.
4. Tap Shield Studio (or open the Shield tab → Protect on a clip).
5. Tap Scan — on-device OCR finds emails/phone numbers and shows a Privacy Score.
6. Add blur regions on sensitive areas, then use Safe Export to save a redacted copy to Photos.
7. Use Safe Share — the app shows the Privacy Score and warns before sharing.

All processing (OCR, blur metadata, export) runs ON-DEVICE. No account, no cloud upload of video content.

Version 1.1 removes ads entirely and adds the Shield privacy workflow described above.

Please contact us via the in-app support link if anything is unclear.
```

---

## Subtitle (30 characters max)

```
Blur & scan before you share
```

Alternative: `Record. Shield. Share safely.` (29 chars)

---

## Promotional text (170 characters max)

```
Record your screen, then scan for emails and phones, blur sensitive areas, and export a safe copy — all on your iPhone. No account. No cloud. No ads.
```

---

## Description (App Store)

```
NowRecorder is a privacy-first screen recorder. Capture your screen, then use Shield to review and redact sensitive information before you share — all on your device.

WHY NOWRECORDER IS DIFFERENT
• Shield Studio — scan recordings for emails and phone numbers with on-device OCR
• Privacy Score — see what was detected before you share
• Manual blur — mark regions to hide names, numbers, or anything on screen
• Safe Export — save a redacted copy to Photos using on-device processing
• Safe Share — confirmation dialog with privacy status before sharing

RECORD WITH CONFIDENCE
• Full-device recording via Apple’s broadcast picker (ReplayKit)
• Optional microphone audio
• Clips library with search and sort
• Everything stays in your Photos library until you choose to share

PRIVATE BY DESIGN
• No account required
• No cloud upload of your recordings
• Photos permission only when you open Clips or record
• No advertisements

Perfect for tutorials, support videos, and any recording you need to share without leaking personal data.
```

---

## Keywords (100 characters max, comma-separated, no spaces after commas)

```
screen recorder,privacy,blur,redact,OCR,ReplayKit,shield,safe share,export,video
```

---

## Screenshot order (recommended)

1. **Home** — Capture + Shield cards, tagline visible  
2. **Shield Studio** — video with blur regions + Privacy Score  
3. **Scan results** — findings list / score after OCR  
4. **Clips grid** — library with privacy status badges  
5. **Capture** — record screen (broadcast picker context)  
6. **Safe Share dialog** — privacy confirmation before share  

Avoid leading with a generic “big red record button” only.

---

## App Privacy (App Store Connect)

Declare as applicable:

- **Photos** — save and list recordings  
- **Microphone** — optional during broadcast  
- **No tracking** (ads removed)  
- **Data not collected** for video content (on-device processing)

---

## Before you upload

- [ ] Test on a **physical iPhone** (ReplayKit does not work in Simulator)  
- [ ] Clean install: confirm **no Photos prompt on Home launch**  
- [ ] Run `flutter build ipa` / Codemagic after `pod install` (ad SDKs removed)  
- [ ] Update Google Sites privacy/support pages to say **NowRecorder · Privacy Recorder** (URLs can stay; page titles should match)  
- [ ] Increment build number in `pubspec.yaml` for each upload (current: **1.1.0+5**)

---

## If rejected again

Reply in Resolution Center with the **Shield Studio walkthrough** above and offer a short screen recording demonstrating scan → blur → safe export.
