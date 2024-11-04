### console
sudo apt install pre-commit
pre-commit run

### .pre-commit-config.yaml
- ruff (https://github.com/astral-sh/ruff) - fastest formatter for Python (ruff, autoflake, flake8, Pyflakes, pycodestyle, pylint)
- mypy (https://github.com/python/mypy) - static type checker for Python
```yaml
exclude: (docker|kubernetes|examples|tests)

default_language_version:
  python: python3.12

repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.7.2
    hooks:
      - id: ruff-format
      - id: ruff
        args: [ --fix ]
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.2
    hooks:
      - id: mypy
        additional_dependencies:
          - pydantic
          - types-ujson
          - types-python-dateutil
          - types-requests
          - types-redis
          - types-PyYAML
          - types-cachetools
```
