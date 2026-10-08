# Build and install Derive using only Windows and an iPad

GitHub Actions supplies the temporary Mac needed for compilation. It does not receive an Apple ID, certificate, provisioning profile, pairing token or notebook. The workflow creates an unsigned IPA; Sideloadly signs it locally on Windows with your Apple account.

## One-time GitHub setup

1. Sign in to GitHub and create a new **private** repository named `derive-math`. Create it empty: do not add a README, `.gitignore` or licence on GitHub.
2. Open PowerShell and run the following, replacing `YOUR_USERNAME`:

```powershell
cd D:\Derive\DeriveMath
git init
git branch -M main
git add .
git status --short
git commit -m "Add Derive native iPad app and cloud build"
git remote add origin https://github.com/YOUR_USERNAME/derive-math.git
git push -u origin main
```

Git Credential Manager may open a browser to authenticate. Do not put a GitHub token, Apple password or pairing token in a file or command.

Before committing, `git status --short` must not show `.env`, `library.json`, a notebook/export folder, `.p12`, `.pfx`, `.cer`, `.mobileprovision` or `.ipa`. `.gitignore` blocks these common private files, and the cloud job rejects them if they are tracked.

## Build the IPA

Every push to `main` starts `.github/workflows/build-ios.yml`. To start it manually:

1. Open the repository on GitHub.
2. Select **Actions** → **Build unsigned iPad IPA**.
3. Select **Run workflow** → **Run workflow**.
4. Wait for both **Test Windows AI backend** and **Compile native iPad app** to turn green.

The macOS job regenerates `DeriveMath.xcodeproj` from `iPadApp/project.yml`, compiles the real SwiftUI/PencilKit app with `CODE_SIGNING_ALLOWED=NO`, checks that its bundle ID is `au.com.derive.math`, packages `Payload/DeriveMath.app` as an IPA, and uploads a SHA-256 checksum. No signing secret is required.

The build has not succeeded merely because the workflow file exists. A green **Compile native iPad app** job is the proof that Swift compilation and IPA packaging passed. If it fails, download the `DeriveMath-build-log-*` artifact and fix the reported Swift/Xcode error before installing anything.

## Download the IPA

1. Open the successful workflow run.
2. Scroll to **Artifacts** and download `DeriveMath-unsigned-RUN_NUMBER`.
3. Extract the downloaded ZIP on Windows.
4. Keep `DeriveMath-unsigned.ipa`; optionally verify its checksum:

```powershell
Get-FileHash .\DeriveMath-unsigned.ipa -Algorithm SHA256
Get-Content .\DeriveMath-unsigned.ipa.sha256
```

The hash values must match.

## Sign and install with Sideloadly on Windows

1. Download Sideloadly only from <https://sideloadly.io/>. Its current Windows instructions require the web-download versions of iTunes and iCloud rather than the Microsoft Store editions.
2. Connect the iPad by USB, unlock it, tap **Trust**, and select it in Sideloadly.
3. Drag `DeriveMath-unsigned.ipa` into Sideloadly.
4. Enter your Apple ID in Sideloadly. If two-factor authentication or Apple asks for an app-specific password, follow the prompt from Apple/Sideloadly. Never add these credentials to GitHub.
5. Leave **Change Bundle ID** and app duplication options disabled. Use the same Apple ID for every reinstall so the signed application identity remains consistent.
6. Click **Start** and complete the Apple authentication prompt.
7. If iPadOS asks, enable **Developer Mode** under **Settings → Privacy & Security**, restart, and confirm it. Trust the developer profile under **Settings → General → VPN & Device Management** if that option appears.
8. Open Derive and enter only the local PC address and pairing token in its on-device AI Server settings.

Sideloadly supports free Apple IDs, but the resulting free-account signature is valid for seven days. Its auto-refresh feature can re-sign periodically while the PC and iPad can communicate.

## Updating without losing notebooks

`au.com.derive.math` is fixed in both the XcodeGen project and the workflow validation step. For an update:

1. Push the new source and download the newly successful IPA artifact.
2. Do **not** delete Derive from the iPad.
3. Install the new IPA over the existing app using the same Sideloadly settings and the same Apple ID.
4. Confirm your notebooks before discarding any exported backup.

When iPadOS recognises the same signed application identity, an in-place update retains its Application Support container, including `library.json` and PencilKit data. Sideloading tools or expired profiles can still fail in ways outside the app's control, so export important notebooks before every update. Deleting the app removes its local container.

## Future code changes

Edit on Windows, run the backend tests, then push:

```powershell
cd D:\Derive\DeriveMath\AIBackend
python -m pytest -q
cd ..
git add .
git commit -m "Describe the update"
git push
```

The Windows Ollama/FastAPI/SymPy server is unchanged and remains on your RTX 2070 Super PC. Never commit `AIBackend/.env`; configure `DERIVE_PAIRING_TOKEN` only in the PC environment.
