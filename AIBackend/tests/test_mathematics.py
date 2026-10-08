from app.mathematics import verify_steps


def statuses(*steps: str) -> list[str]:
    return [item.status for item in verify_steps(list(steps))]


def test_valid_linear_working() -> None:
    assert statuses("2x + 6 = 18", "2x = 12", "x = 6") == ["warning", "correct", "correct"]


def test_wrong_answer_is_rejected() -> None:
    assert statuses("2x + 6 = 18", "2x = 12", "x = 8")[-1] == "incorrect"


def test_lost_quadratic_solution_is_rejected() -> None:
    result = verify_steps(["x^2 = 1", "x = 1"])[-1]
    assert result.status == "incorrect"
    assert "loses" in result.explanation


def test_equivalent_expressions() -> None:
    assert statuses("(x + 1)^2", "x^2 + 2x + 1")[-1] == "correct"


def test_parse_failure_is_warning() -> None:
    assert statuses("x =") == ["warning"]


def test_python_syntax_is_rejected() -> None:
    result = verify_steps(["__import__('os').system('whoami')"])[0]
    assert result.status == "warning"
    assert "unsupported characters" in result.explanation
