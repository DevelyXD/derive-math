import hmac

import httpx
from fastapi import Depends, FastAPI, Header, HTTPException

from . import ollama
from .config import settings
from .mathematics import verify_steps
from .recognition import recognize
from .schemas import (
    ExplainRequest,
    GenerateRequest,
    HealthResponse,
    RecognitionRequest,
    RecognitionResponse,
    TextResponse,
    VerifyRequest,
    VerifyResponse,
)

app = FastAPI(title="Derive AI Backend", version="0.1.0")


def require_token(authorization: str | None = Header(default=None)) -> None:
    expected = f"Bearer {settings.pairing_token}"
    if not authorization or not hmac.compare_digest(authorization, expected):
        raise HTTPException(status_code=401, detail="Invalid pairing token")


@app.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(
        status="ok",
        ollama=await ollama.available(),
        recognition="pix2tex optional; manual fallback always available",
        model=settings.ollama_model,
    )


@app.get("/api/models", dependencies=[Depends(require_token)])
async def list_models() -> dict[str, list[str]]:
    try:
        return {"models": await ollama.models()}
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=503, detail="Ollama is unavailable") from exc


@app.post("/api/recognize", response_model=RecognitionResponse, dependencies=[Depends(require_token)])
async def recognize_expression(request: RecognitionRequest) -> RecognitionResponse:
    try:
        return recognize(request.manual_expression, request.image_base64)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc


@app.post("/api/verify", response_model=VerifyResponse, dependencies=[Depends(require_token)])
async def verify(request: VerifyRequest) -> VerifyResponse:
    return VerifyResponse(results=verify_steps(request.steps))


@app.post("/api/explain", response_model=TextResponse, dependencies=[Depends(require_token)])
async def explain(request: ExplainRequest) -> TextResponse:
    evidence = "\n".join(
        f"{item.expression}: {item.status} — {item.explanation}" for item in request.verification
    ) or "No deterministic verification was supplied. Do not claim correctness."
    prompt = (
        f"Student level: {request.level}\nAction: {request.action}\nQuestion: {request.question}\n"
        f"Working: {request.working}\nSymPy verification (authoritative):\n{evidence}"
    )
    try:
        text = await ollama.generate(
            prompt,
            "You are a concise VCE maths tutor. Respect the SymPy results. Use short LaTeX where helpful. "
            "Never present generated content as official VCAA material.",
        )
        return TextResponse(text=text, model=settings.ollama_model)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=503, detail="Ollama is unavailable") from exc


@app.post("/api/generate", response_model=TextResponse, dependencies=[Depends(require_token)])
async def generate_question(request: GenerateRequest) -> TextResponse:
    prompt = (
        f"Create one original {request.level} {request.topic} practice question. "
        f"Mode: {request.cas_mode}. Include a separate answer and compact worked solution."
    )
    try:
        text = await ollama.generate(
            prompt,
            "You write original Australian mathematics practice. Never imply it is official VCAA material.",
        )
        return TextResponse(text=text, model=settings.ollama_model)
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=503, detail="Ollama is unavailable") from exc
