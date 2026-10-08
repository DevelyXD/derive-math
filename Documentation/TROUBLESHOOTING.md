# Troubleshooting

## Test Connection says Disconnected

- Open `http://PC-IP:8000/health` from Safari on the iPad. If it cannot open, check the PC address, Private network profile, firewall scope and Wi-Fi client isolation.
- Confirm `start.ps1` is listening on `0.0.0.0`, not only `127.0.0.1`.
- The health endpoint does not need a token. A 401 from `/api/*` means the app and server tokens differ.
- If the PC address changes after reboot, reserve it in the router.

## Ollama unavailable

Run `ollama list`, then `ollama pull qwen3:4b`. Confirm `http://127.0.0.1:11434/api/tags` works on the PC. Do not change Ollama to listen on the LAN.

## Verification returns a warning

A warning means SymPy could not prove the transformation, not that the step is correct. Correct OCR or typed syntax first. Use `*` for explicit multiplication when input is ambiguous and keep one equality per line.

## OCR returns 503

Manual entry remains available. Activate the same virtual environment used by the server and install `requirements-ocr.txt`; restart the server afterward.

## Xcode signing fails

Select a development team, use a unique bundle identifier, unlock the iPad and accept its trust prompt. If a free personal-team profile expired, connect the device and run the project from Xcode again.

## A notebook did not restore

Derive saves after a short debounce and whenever it leaves the active scene. Confirm the device has storage available. The library resides in the app's Application Support container and is removed if the app itself is deleted; export important notebooks as PDFs or include the app in an encrypted device backup.
