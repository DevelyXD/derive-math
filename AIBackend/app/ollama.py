import httpx

from .config import settings


async def available() -> bool:
    try:
        async with httpx.AsyncClient(timeout=2) as client:
            return (await client.get(f"{settings.ollama_url}/api/tags")).is_success
    except httpx.HTTPError:
        return False


async def models() -> list[str]:
    async with httpx.AsyncClient(timeout=5) as client:
        response = await client.get(f"{settings.ollama_url}/api/tags")
        response.raise_for_status()
        return [item["name"] for item in response.json().get("models", [])]


async def generate(prompt: str, system: str) -> str:
    payload = {
        "model": settings.ollama_model,
        "prompt": prompt,
        "system": system,
        "stream": False,
        "options": {"temperature": 0.25, "num_ctx": 4096},
        "keep_alive": "5m",
    }
    async with httpx.AsyncClient(timeout=settings.request_timeout) as client:
        response = await client.post(f"{settings.ollama_url}/api/generate", json=payload)
        response.raise_for_status()
        return response.json()["response"].strip()
