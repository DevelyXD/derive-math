import base64
import io

import sympy as sp

from .mathematics import parse_line
from .schemas import RecognitionResponse


def recognize(manual_expression: str | None, image_base64: str | None) -> RecognitionResponse:
    if manual_expression and manual_expression.strip():
        expression = manual_expression.strip()
        try:
            parsed = parse_line(expression)
            latex = sp.latex(parsed.lhs)
            if parsed.rhs is not None:
                latex += " = " + sp.latex(parsed.rhs)
        except Exception:
            latex = expression
        return RecognitionResponse(
            expression=expression,
            latex=latex,
            confidence=1,
            source="manual",
            needs_review=False,
        )

    if not image_base64:
        raise ValueError("Provide manual_expression or image_base64")

    try:
        from PIL import Image
        from pix2tex.cli import LatexOCR
    except ImportError as exc:
        raise RuntimeError(
            "Math OCR is not installed. Use manual entry or install requirements-ocr.txt."
        ) from exc

    image = Image.open(io.BytesIO(base64.b64decode(image_base64, validate=True))).convert("RGB")
    latex = LatexOCR()(image).strip()
    return RecognitionResponse(
        expression=latex,
        latex=latex,
        confidence=0.5,
        source="pix2tex",
        needs_review=True,
    )
