# Windows AI server setup

## 1. Install the prerequisites

Install Python 3.11 (64-bit), the current NVIDIA driver and [Ollama for Windows](https://ollama.com/download/windows). In PowerShell:

```powershell
cd D:\Derive\DeriveMath\AIBackend
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
ollama pull qwen3:4b
```

Ollama selects supported NVIDIA acceleration automatically. Confirm that inference is using the GPU while a model is running:

```powershell
ollama run qwen3:4b "Reply with: ready"
ollama ps
nvidia-smi
```

Only one language model is configured and `keep_alive` is five minutes, which is suitable for an 8 GB RTX 2070 Super. If memory is tight, choose a smaller quantisation listed by `ollama show qwen3:4b` or set `DERIVE_OLLAMA_MODEL` to a smaller installed model.

## 2. Configure and run Derive

Generate a token, keep it private, and start the API:

```powershell
$env:DERIVE_PAIRING_TOKEN = -join ((1..48) | ForEach-Object { 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[(Get-Random -Maximum 62)] })
$env:DERIVE_OLLAMA_MODEL = "qwen3:4b"
.\start.ps1
```

Keep Ollama on its default localhost address. Only FastAPI listens on the LAN. Do not port-forward port 8000 on your router.

Test locally in a second PowerShell window:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/health
$headers = @{ Authorization = "Bearer $env:DERIVE_PAIRING_TOKEN" }
$body = @{ steps = @("2x + 6 = 18", "2x = 12", "x = 6") } | ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:8000/api/verify -Method Post -Headers $headers -ContentType application/json -Body $body
```

Allow inbound TCP 8000 only on the Windows **Private** network when Windows Firewall prompts. For a manual rule, run an elevated terminal and scope the rule to your local subnet rather than all remote addresses.

Find the PC's address with `ipconfig`; use the IPv4 address belonging to the same Wi-Fi/LAN as the iPad. A DHCP reservation in the router prevents it changing.

## 3. Optional mathematical handwriting OCR

The base server intentionally does not download a large second model. Manual correction works without it. To enable the pix2tex adapter:

```powershell
pip install -r requirements-ocr.txt
```

The first OCR request may download model weights. [pix2tex is MIT-licensed](https://github.com/lukas-blecher/LaTeX-OCR/blob/main/setup.py), uses PyTorch and selects CUDA when available. It is an initial local model, not a guarantee of accuracy for free-form multi-line working; every result is marked `needs_review: true`. Keep the manual correction step.

## 4. Tests

```powershell
pip install -r requirements-dev.txt
python -m pytest
```

## HTTPS

Plain HTTP is acceptable only for development on a trusted private home network. For a durable setup, create a locally trusted certificate for the PC's hostname with a tool such as `mkcert`, install its local CA profile on the iPad, enable full trust under Certificate Trust Settings, and run Uvicorn with `--ssl-keyfile` and `--ssl-certfile`. Then enable HTTPS in Derive. Never disable certificate validation in the app.
