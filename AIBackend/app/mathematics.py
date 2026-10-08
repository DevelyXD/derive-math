from dataclasses import dataclass
import re

import sympy as sp
from sympy.parsing.sympy_parser import (
    convert_xor,
    implicit_multiplication_application,
    parse_expr,
    standard_transformations,
)

from .schemas import StepResult


TRANSFORMS = standard_transformations + (
    convert_xor,
    implicit_multiplication_application,
)
LOCALS = {
    "sin": sp.sin,
    "cos": sp.cos,
    "tan": sp.tan,
    "log": sp.log,
    "ln": sp.log,
    "sqrt": sp.sqrt,
    "pi": sp.pi,
    "e": sp.E,
}
SAFE_GLOBALS = {
    "__builtins__": {},
    "Symbol": sp.Symbol,
    "Integer": sp.Integer,
    "Float": sp.Float,
    "Rational": sp.Rational,
    "factorial": sp.factorial,
}
SAFE_INPUT = re.compile(r"^[0-9A-Za-z+\-*/^().,\s]+$")


@dataclass
class ParsedLine:
    raw: str
    lhs: sp.Expr
    rhs: sp.Expr | None

    @property
    def symbols(self) -> set[sp.Symbol]:
        symbols = set(self.lhs.free_symbols)
        if self.rhs is not None:
            symbols |= self.rhs.free_symbols
        return symbols


def _parse_part(value: str) -> sp.Expr:
    value = value.strip()
    if not value or not SAFE_INPUT.fullmatch(value):
        raise ValueError("Expression contains unsupported characters")
    return parse_expr(
        value,
        local_dict=LOCALS,
        global_dict=SAFE_GLOBALS,
        transformations=TRANSFORMS,
        evaluate=True,
    )


def parse_line(value: str) -> ParsedLine:
    if value.count("=") > 1:
        raise ValueError("Use one equals sign per line")
    if "=" in value:
        left, right = value.split("=", 1)
        return ParsedLine(value, _parse_part(left), _parse_part(right))
    return ParsedLine(value, _parse_part(value), None)


def _truth(line: ParsedLine) -> bool | None:
    if line.rhs is None or line.symbols:
        return None
    return bool(sp.simplify(line.lhs - line.rhs) == 0)


def _solution_set(line: ParsedLine, symbol: sp.Symbol) -> sp.Set | None:
    if line.rhs is None:
        return None
    try:
        return sp.solveset(line.lhs - line.rhs, symbol, domain=sp.S.Reals)
    except (NotImplementedError, ValueError, TypeError):
        return None


def compare(previous: ParsedLine, current: ParsedLine) -> tuple[str, str]:
    symbols = previous.symbols | current.symbols
    current_truth = _truth(current)
    if current_truth is False:
        return "incorrect", "The equality on this line is false."

    if previous.rhs is None and current.rhs is None:
        if sp.simplify(previous.lhs - current.lhs) == 0:
            return "correct", "Equivalent expression."
        return "incorrect", "This expression is not equivalent to the previous line."

    if previous.rhs is None or current.rhs is None:
        return "warning", "Cannot compare an expression with an equation reliably."

    if len(symbols) == 1:
        symbol = next(iter(symbols))
        old_set = _solution_set(previous, symbol)
        new_set = _solution_set(current, symbol)
        if old_set is not None and new_set is not None:
            if old_set == new_set:
                return "correct", "Equivalent equation with the same real solutions."
            try:
                if new_set.is_subset(old_set) is True:
                    return "incorrect", "This step loses one or more valid solutions."
                if old_set.is_subset(new_set) is True:
                    return "incorrect", "This step introduces one or more extraneous solutions."
            except (TypeError, NotImplementedError):
                pass
            return "incorrect", "The solution set changed in this step."

    old_difference = sp.simplify(previous.lhs - previous.rhs)
    new_difference = sp.simplify(current.lhs - current.rhs)
    if sp.simplify(old_difference - new_difference) == 0:
        return "correct", "Equivalent equation."
    return "warning", "SymPy could not prove that this transformation preserves all solutions."


def verify_steps(values: list[str]) -> list[StepResult]:
    results: list[StepResult] = []
    parsed: list[ParsedLine | None] = []
    for index, value in enumerate(values):
        try:
            line = parse_line(value)
            parsed.append(line)
        except Exception as exc:
            parsed.append(None)
            results.append(
                StepResult(index=index, expression=value, status="warning", explanation=f"Could not parse: {exc}")
            )
            continue

        if index == 0:
            truth = _truth(line)
            status = "incorrect" if truth is False else "warning"
            explanation = "The equality is false." if truth is False else "Starting expression recorded."
        elif parsed[index - 1] is None:
            status, explanation = "warning", "Previous line could not be parsed."
        else:
            status, explanation = compare(parsed[index - 1], line)
        results.append(StepResult(index=index, expression=value, status=status, explanation=explanation))
    return results
