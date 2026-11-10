"""Contract validation: compares API responses with the JSON Schemas in contracts/."""

import json
from pathlib import Path

from jsonschema import Draft7Validator, FormatChecker
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT7
from robot.api.deco import keyword, library

CONTRACTS_DIR = Path(__file__).resolve().parents[1] / "contracts"


def _load_registry():
    schemas = {}
    for file in sorted(CONTRACTS_DIR.glob("*.schema.json")):
        schema = json.loads(file.read_text(encoding="utf-8"))
        # Each <name>.schema.json is registered by its $id, which is the contract name itself.
        schemas[schema["$id"]] = schema
    registry = Registry().with_resources(
        (name, Resource.from_contents(schema, default_specification=DRAFT7)) for name, schema in schemas.items()
    )
    return schemas, registry


def _field_path(path) -> str:
    """["0", "products", 1, "name"] becomes "[0].products[1].name"."""
    text = "".join(f"[{part}]" if isinstance(part, int) else f".{part}" for part in path)
    return text.lstrip(".") or "(root)"


def _describe(error) -> str:
    path = list(error.absolute_path)
    if error.validator == "additionalProperties":
        extras = [name for name in error.instance if name not in error.schema.get("properties", {})]
        return "; ".join(f"{_field_path(path + [name])}: field not allowed by the contract" for name in extras)
    if error.validator == "required":
        missing = error.message.split("'")[1]
        return f"{_field_path(path + [missing])}: required field is missing"
    if error.validator == "type":
        return f"{_field_path(path)}: must be of type {error.validator_value}"
    if error.validator == "enum":
        return f"{_field_path(path)}: value is not one of {json.dumps(error.validator_value)}"
    if error.validator == "const":
        return f"{_field_path(path)}: must be {json.dumps(error.validator_value)}"
    return f"{_field_path(path)}: {error.message}"


@library(scope="GLOBAL")
class ContractValidator:
    def __init__(self):
        self._schemas, self._registry = _load_registry()

    @keyword
    def contract_violations(self, contract: str, body) -> list:
        """Returns the list of violations. An empty list means the body follows the contract."""
        if contract not in self._schemas:
            raise AssertionError(f'Unknown contract: "{contract}". See the contracts/ folder.')
        validator = Draft7Validator(self._schemas[contract], registry=self._registry, format_checker=FormatChecker())
        errors = sorted(validator.iter_errors(body), key=lambda error: list(error.absolute_path))
        return [_describe(error) for error in errors]

    @keyword
    def body_should_follow_contract(self, contract: str, body) -> None:
        violations = self.contract_violations(contract, body)
        if violations:
            details = "\n".join(f"- {violation}" for violation in violations)
            raise AssertionError(f'The response does not follow the "{contract}" contract:\n{details}')
