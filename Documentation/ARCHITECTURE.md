# Architecture

## Data flow

`PencilKit canvas → local atomic JSON/PencilKit data → optional selected maths → authenticated FastAPI → SymPy → optional Ollama explanation`

The notebook path never depends on the network. `NotebookStore` owns folders, notebooks, pages and original `PKDrawing.dataRepresentation()` bytes. A 400 ms debounce coalesces edits; scene transitions force a save. `Data.write(..., .atomic)` prevents a partial file replacing the last good library.

## Native app

- SwiftUI provides the split-view library, tabs, editor, graphing and settings.
- `PKCanvasView` handles low-latency Apple Pencil input locally.
- PDFKit displays imported worksheet pages; export flattens the source page and annotations.
- The pairing token is stored as a this-device-only Keychain item. Host and port are non-secret preferences.
- URLSession requests are asynchronous and never run on the drawing callback.

The current library is a single atomic file. That is the smallest reliable format for a personal notebook collection; move to one package per notebook if real-world libraries make save latency measurable.

## Backend

- FastAPI validates typed request and response bodies.
- Bearer authentication uses constant-time token comparison.
- SymPy parses and compares expressions. For one-variable real equations it compares solution sets, which detects lost and extraneous solutions. Results are `correct`, `incorrect`, or `warning`; unsupported transformations are never guessed.
- Ollama binds to localhost. FastAPI is the only LAN-facing service and feeds deterministic verification into tutor prompts.
- pix2tex is isolated behind an optional import so the main server does not carry a second large model by default.

## Trust boundary

The iPad sends only explicitly submitted maths, not notebooks or individual strokes. LAN HTTP is documented as development-only. Production-like use requires a certificate trusted by the iPad; certificate validation is never bypassed.
