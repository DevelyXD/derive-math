# Derive

Derive is a native iPad mathematics notebook backed by an optional local Windows AI service. Notes, PDFs and PencilKit stroke data live on the iPad. SymPy verifies mathematics deterministically; Ollama supplies explanations and original practice questions.

## What works in this increment

- Native iPadOS 17 SwiftUI/PencilKit notebook, Apple Pencil drawing, tools, undo/redo and zoom
- Local atomic autosave, page templates, folders, recent ordering and restorable notebook tabs
- PDF import, annotation and flattened PDF export
- Pairing token in Keychain and configurable LAN server connection
- Typed/manual-correction maths workflow with deterministic step verification
- Ollama tutor actions using `qwen3:4b` by default
- Native multi-function graphing for arithmetic, powers, parentheses and common functions
- Optional pix2tex math OCR adapter; it reports review-required and never pretends OCR is installed

## Start here

1. Follow [Windows setup](Documentation/WINDOWS_SETUP.md).
2. Run `python -m pytest` in `AIBackend`.
3. Follow [Windows-only IPA build and installation](Documentation/GITHUB_ACTIONS_IPA.md).
4. Enter the PC address, port and pairing token in the app's AI Server settings.

The native app is compiled on a GitHub-hosted macOS runner, downloaded as an unsigned IPA, and signed locally with Sideloadly on Windows. Apple credentials never enter GitHub Actions.

## Repository layout

- `AIBackend/` — FastAPI, SymPy verification, Ollama and optional OCR
- `iPadApp/` — native SwiftUI app and Xcode project
- `Documentation/` — architecture, setup and troubleshooting

## Current boundary

Manual expression entry and correction are complete. Image-to-LaTeX uses optional pix2tex when installed, but the iPad selection/cropping UI is not yet connected to `/api/recognize`. Automatic pause-based checking, richer graph analysis and full VCE content organisation are later increments; no placeholder UI claims they work.
