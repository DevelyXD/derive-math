from typing import Literal

from pydantic import BaseModel, Field


class RecognitionRequest(BaseModel):
    image_base64: str | None = Field(default=None, max_length=15_000_000)
    manual_expression: str | None = Field(default=None, max_length=2_000)


class RecognitionResponse(BaseModel):
    expression: str
    latex: str
    confidence: float = Field(ge=0, le=1)
    source: Literal["manual", "pix2tex"]
    needs_review: bool


class VerifyRequest(BaseModel):
    steps: list[str] = Field(min_length=1, max_length=50)


class StepResult(BaseModel):
    index: int
    expression: str
    status: Literal["correct", "incorrect", "warning"]
    explanation: str


class VerifyResponse(BaseModel):
    results: list[StepResult]


TutorAction = Literal[
    "hint", "explain_mistake", "next_step", "explain_concept"
]


class ExplainRequest(BaseModel):
    question: str = Field(max_length=4_000)
    working: list[str] = Field(default_factory=list, max_length=50)
    verification: list[StepResult] = Field(default_factory=list)
    action: TutorAction = "hint"
    level: str = "VCE"


class GenerateRequest(BaseModel):
    topic: str = Field(max_length=200)
    level: str = "VCE"
    cas_mode: Literal["cas", "non-cas", "either"] = "either"


class TextResponse(BaseModel):
    text: str
    model: str


class HealthResponse(BaseModel):
    status: str
    ollama: bool
    recognition: str
    model: str
