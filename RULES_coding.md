# Coding Rules and Development Guidelines

This document defines mandatory coding standards for all local projects. The goal is maintainability, scalability, readability, and production-grade structure even in experimental environments.

---

# Core Principles

All code must be:

* readable
* modular
* testable
* documented
* scalable
* predictable

Write code as if another senior developer will maintain it tomorrow.
Always create or update the implementationplan.md first before implementing.
Always update documentation *.md as needed.
Add the following author name = "Inventions4All - github:TWeb79"

---

# Naming Conventions

## Project Naming

Format:

```
NN project-name
```

Example:

```
23 project-x
```

Folder format:

```
23-project-x/
```

---

## Python Naming

Follow PEP8 strictly.

Examples:

```
file_name.py
function_name()
ClassName
VARIABLE_NAME
```

Avoid:

```
mixedCase
random_short_names
x1_tmp_final2
```

Names must describe intent.

Example:

```
calculate_invoice_total()
load_prompt_registry()
create_database_session()
```

---

## JavaScript Naming

Use:

```
camelCase for variables/functions
PascalCase for classes
kebab-case for filenames
```

Example:

```
fetchUserData()
PromptManager
prompt-service.js
```

---

## CSS Naming

Use structured class naming.

Recommended:

```
component-name__element--modifier
```

Example:

```
dashboard-card__title
button--primary
navbar__logo
```

Avoid inline styling.

---

# File Size Limits

Maintain small, readable modules.

Guidelines:

```
ideal file size: <= 200 lines
maximum file size: 500 lines
```

If a file exceeds limits:

Split into:

```
logic
routes
services
utils
models
components
```

Example:

```
api/
services/
models/
utils/
routes/
```

Large files are considered technical debt.

---

# Modular Frontend Structure

Separate responsibilities.

Required structure:

```
js/
css/
components/
```

Rules:

```
no inline JavaScript
no inline CSS
no mixed HTML/logic files
```

Example:

```
index.html
js/dashboard.js
css/dashboard.css
```

---

# Backend Structure (FastAPI Projects)

Recommended layout:

```
api/
models/
services/
routes/
core/
config/
```

Example:

```
routes/
    prompts.py

services/
    prompt_loader.py
```

Routes must never contain business logic.

Business logic belongs in:

```
services/
```

---

# Testing Requirements

Every project must include automated tests.

Allowed frameworks:

```
pytest (preferred)
unittest (acceptable)
```

Minimum expectations:

```
test_services.py
test_routes.py
```

Example:

```
tests/
    test_api.py
    test_services.py
```

Tests must run locally before commits.

---

# Code Comments (Senior-Level Standard)

Write comments explaining intent — not obvious syntax.

Avoid:

```
# increment i
```

Prefer:

```
# Increment retry counter to prevent infinite loop on failed API responses
```

Document:

```
assumptions
side-effects
edge cases
performance decisions
architecture tradeoffs
```

Functions must include docstrings.

Example:

```
"""
Loads prompt configuration from YAML registry.

Raises:
    FileNotFoundError
    ValidationError
"""
```

---

# Documentation Requirements

Each project must contain:

```
README.md
ARCHITECTURE.md
RULES_coding.md
```

---

# README.md Requirements

Must include:

```
project purpose
service ports
startup instructions
dependencies
API endpoints
example requests
```

README must allow a developer to run the project within minutes.

---

# ARCHITECTURE.md Requirements

Must describe:

```
system structure
module responsibilities
data flow
external dependencies
service boundaries
```

Keep diagrams simple when possible.

Example:

```
Dashboard -> FastAPI -> Service Layer -> Database
```

Architecture documentation must stay up to date.

---

# Maintainability Rules

Always:

```
refactor duplicated logic
remove dead code
keep imports clean
avoid hidden dependencies
```

Never:

```
commit experimental debug code
leave TODO blocks unresolved long-term
push broken tests
```

---

# Dependency Management

Each project must include:

```
requirements.txt
```

Optional:

```
pyproject.toml
```

Pin versions when stability matters.

Example:

```
fastapi==0.115.*
```

---

# Logging Standards

Use structured logging.

Example:

```
logger.info("Prompt registry loaded", extra={"project_id": 23})
```

Avoid print() in production code.

---

# Testing Standards

Code must be tested, follow the following steps:
1. investigate the project and code
2. describe the functionality of the project to know the sequence of tasks
3. create a test plan based on all features in the code
4. follow the test plan
5. update the test plan and add a oneliner comment per task

---


# Final Rule

Code must be tested, run and understandable without verbal explanation.

If documentation is required to understand basic flow:

Refactor the code.
