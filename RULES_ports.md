# Port Instructions for Local Development Environment

This document defines the standardized port allocation scheme for all local projects.

---

## Port Range Structure

Ports are grouped by service type:

| Port Range | Service Type              |
| ---------- | ------------------------- |
| 8000       | Global overview dashboard |
| 80xx       | Project web dashboards  + FastAPI (to prevent CORS policy issues) |
| 81xx       | FastAPI services  (optional alternative)        |
| 82xx       | Databases                 |
| 89xx       | LLM                       |


Each project is assigned a unique two-digit identifier that maps consistently across services.

Pattern:

```
Project ID: NN
Web Dashboard: 80NN
FastAPI Service: 81NN
Database: 82NN
LLM : 89NN
```

Example:

Project ID 23 → "project x"

```
8023 → Web dashboard (project x)
8123 → FastAPI service (project x)
8223 → Database (project x)
8923 → LLM (project x)
```

---

## Example Multi‑Project Allocation

### Project 23 — project x

```
8023 → Web dashboard
8123 → FastAPI service
8223 → Database
```

### Project 24 — project y

```
8024 → Web dashboard
8124 → FastAPI service
8224 → Database
```

### Project 25 — project z

```
8025 → Web dashboard
8125 → FastAPI service
8225 → Database
```

---

## Global Services

Reserved ports:

```
8000 → Overview dashboard across all applications
```

This dashboard aggregates:

* project status
* running services
* links to dashboards
* links to FastAPI docs

---

## Naming Convention

Projects follow this format:

```
NN project-name
```

Example:

```
23 project-x
24 project-y
25 project-z
```

This ensures:

* predictable routing
* consistent service discovery
* easy mental mapping
* scalable local infrastructure

---

## Recommended Folder Structure

Example:

```
23-project-x/
 ├── dashboard/
 ├── api/
 ├── database/
 └── config/
```

Optional service mapping file:

```
ports.env
```

Example:

```
PROJECT_ID=23
DASHBOARD_PORT=8023
FASTAPI_PORT=8123
DATABASE_PORT=8223
```

---

## Benefits of This System

* predictable ports
* no collisions
* easy scaling to 99 projects
* simple automation support
* clean reverse-proxy compatibility
* works well with Docker and local-only setups

---

## Future Extensions (Optional)

If additional services are needed later:

Suggested reserved ranges:

```
83xx → background workers
84xx → vector databases
85xx → experimental services
86xx → admin tools
```

---

## Project 30 Allocation

For project 30, the following ports are allocated following the 8x30 pattern:

| Port | Service Type              | Docker Service   |
| ---- | ---------------------- | ------------- |
| 8030 | Web dashboard          | brain-frontend |
| 8130 | FastAPI service       | brain-api      |
| 8230 | Database              | (reserved)    |
| 8330 | Background workers    | (reserved)    |
| 8430 | Vector database       | (reserved)    |
| 8530 | Experimental services | (reserved)    |
| 8630 | Admin tools           | (reserved)    |

Pattern: `8` + service_category + project_number

- Service category 0 = web dashboard (80xx)
- Service category 1 = FastAPI (81xx)
- Service category 2 = database (82xx)
- Service category 3 = background workers (83xx)
- Service category 4 = vector databases (84xx)
- Service category 5 = experimental (85xx)
- Service category 6 = admin tools (86xx)

---

## Project 35 Allocation

For project 35 (FaceTrack — Video Face Analysis), the following ports are allocated following the 8x35 pattern:

| Port | Service Type     | Usage                    |
| ---- | --------------- | ----------------------- |
| 8035 | Web dashboard   | FaceTrack UI (static)   |
| 8135 | FastAPI service | (reserved — not used)   |
| 8235 | Database        | (reserved — not used)   |
| 8335 | Background workers | (reserved)        |
| 8435 | Vector database | (reserved)              |
| 8535 | Experimental services | (reserved)      |
| 8635 | Admin tools     | (reserved)              |

**Note:** FaceTrack is a purely client-side static application with no backend API or database. Only port 8035 (web dashboard) is actively used if served via a local HTTP server. All other service ports are reserved for potential future extensions.

**Recommended local server command:**

```bash
# Serve on port 8035 consistently with naming convention
npx http-server . -p 8035
# or
python -m http.server 8035
```

Pattern: `8` + service_category + project_number

- Service category 0 = web dashboard (80xx)
- Service category 1 = FastAPI (81xx)
- Service category 2 = database (82xx)
- Service category 3 = background workers (83xx)
- Service category 4 = vector databases (84xx)
- Service category 5 = experimental (85xx)
- Service category 6 = admin tools (86xx)
