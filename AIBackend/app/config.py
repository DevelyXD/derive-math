from dataclasses import dataclass
import os


@dataclass(frozen=True)
class Settings:
    pairing_token: str = os.getenv("DERIVE_PAIRING_TOKEN", "change-me")
    ollama_url: str = os.getenv("DERIVE_OLLAMA_URL", "http://127.0.0.1:11434")
    ollama_model: str = os.getenv("DERIVE_OLLAMA_MODEL", "qwen3:4b")
    request_timeout: float = float(os.getenv("DERIVE_REQUEST_TIMEOUT", "90"))


settings = Settings()
