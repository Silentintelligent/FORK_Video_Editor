# Publishing FORK on Google Play

## 0. Before anything
1. Put the code in your own **public** Git repository and put its URL in
   README.md, play/PRIVACY_POLICY.md, play/STORE_LISTING.md (AGPL source offer).
2. Host `play/PRIVACY_POLICY.md` on a public web page (GitHub Pages works) —
   Play requires a privacy-policy URL.
3. Check the license of each downloaded model in `models/manifest.toml`
   (some background-removal/TTS models are non-commercial or have use
   restrictions). Remove or replace any you cannot redistribute.
4. Confirm the FFmpeg build is LGPL-only (see src/scripts/ffmpeg-mobile.sh).

## 1. Make an upload key (once; back it up safely)
    keytool -genkeypair -v -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
Never commit it. Play re-signs the app with its own key (Play App Signing).

## 2. Build the .aab
Easiest: GitHub Actions. Push to your repo, add secrets FORK_KEYSTORE
(`base64 -w0 upload.jks`), FORK_KEYSTORE_PASSWORD, FORK_KEY_ALIAS, then run
"Build Play bundle (AAB)". Download the `FORK-aab` artifact.
Or locally on Linux/macOS: `./build-aab.sh 1 0.1.0` (see header for tools).
The script fails if any .so is not 16 KB aligned.

## 3. Play Console
1. Create a developer account (US$25 once; personal accounts need ID +
   verification via the Play Console phone app).
2. Create app: name, default language, App, Free.
3. Complete: privacy policy URL, App access (all features available), Ads (No),
   Content rating questionnaire, Target audience (18+ / not for children),
   Data safety (see below), store listing + graphics.
4. Testing > Closed testing: upload `app-release.aab`, add 12+ testers, keep
   them opted in for 14 continuous days (needed for new personal accounts).
5. Dashboard > Apply for production, then create a Production release.
   Increase versionCode for every new upload.

## Data safety suggestions (verify against what you ship)
- Data collected: none; Data shared: none (processing is on-device).
- Internet access is only used to download model files.
- Also answer the AI-generated content / user-generated content questions
  honestly: voice cloning must carry a consent warning in the app.

## Known risks (read)
- API 36 behaviour changes (edge-to-edge, etc.) are untested with this UI.
- Prebuilt ONNX Runtime / sherpa-onnx / FFmpeg .so files may not be
  16 KB aligned; build-aab.sh will tell you.
- The app embeds a small dex that is loaded in memory; it ships inside the
  bundle (not downloaded), which is allowed.
- The Settings > Version page lists upstream GitHub releases; on Android
  it cannot install them (store build), but consider removing that page.
