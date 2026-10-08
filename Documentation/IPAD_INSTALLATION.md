# Install on a personal iPad without owning a Mac

Use [the Windows + GitHub Actions + Sideloadly guide](GITHUB_ACTIONS_IPA.md). GitHub's macOS runner compiles the native app; Sideloadly signs and installs the unsigned IPA from Windows. No Mac or App Store publication is required.

The bundle identifier is fixed as `au.com.derive.math`. Reinstall updates with the same Apple ID and unchanged Sideloadly bundle-ID settings instead of deleting the app. A free Apple ID profile lasts seven days, so it must be refreshed or reinstalled periodically.

## Connect to the PC

1. Make sure iPad and PC are on the same trusted LAN and client isolation is disabled on the Wi-Fi network.
2. Open Derive → **AI Server**.
3. Enter the PC IPv4 address, `8000`, and exactly the token used by `DERIVE_PAIRING_TOKEN`.
4. Leave HTTPS off only for the trusted-LAN development setup, then tap **Test Connection**.
5. Accept the iPadOS local-network permission prompt.

Writing, opening, importing and exporting notebooks work without the server. Only recognition, verification and tutor actions need it.

## Native app testing checklist

- Draw rapidly with Apple Pencil while the PC server is stopped; ink must remain responsive.
- Background and relaunch the app; strokes and the last open tabs must return.
- Import a multi-page PDF, annotate it, export it, and inspect every page.
- Test pen, highlighter, eraser, lasso, undo/redo and each page template.
- Disconnect Wi-Fi during a verification request; the note must remain editable and saved.
- On both light and dark appearance, verify contrast and tool visibility.

Swift compilation is verified by the macOS GitHub Actions job. Physical Apple Pencil behaviour must still be tested on the iPad after installation.
