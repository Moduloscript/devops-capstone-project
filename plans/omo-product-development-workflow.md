# Oh-My-OpenAgent Product Development Workflow

**Target:** Using OmO as a framework to build active, shippable products
**Project:** devops-capstone-project (Flask Account API)
**Date:** 2026-06-29

---

## 1. The Core Concept: OmO as a Product Factory

Oh-My-OpenAgent transforms OpenCode from a single-agent coding assistant into a **multi-agent product factory**. Instead of you writing code line-by-line, you orchestrate specialized AI agents that work in parallel — like having a team of senior engineers, architects, and reviewers working simultaneously.

### The Three Disciplines (Your Core Team)

| Agent | Role | Model | What It Does |
|-------|------|-------|-------------|
| **Sisyphus** | Orchestrator | kimi-k2.6 | Breaks tasks into subtasks, delegates to other agents, tracks progress |
| **Prometheus** | Strategic Planner | glm-5.1 | Designs architecture, plans implementation, reviews designs |
| **Hephaestus** | Deep Worker | kimi-k2.6 | Executes complex implementation, writes production code |

### Support Agents

| Agent | Role | Model | What It Does |
|-------|------|-------|-------------|
| **Oracle** | Knowledge Base | glm-5.1 | Answers questions about the codebase, explains patterns |
| **Librarian** | Code Search | qwen3.5-plus | Finds relevant code, navigates the codebase |
| **Explore** | Research | qwen3.5-plus | Researches external libraries, APIs, best practices |
| **Metis** | Reviewer | glm-5.1 | Reviews code for quality, security, correctness |
| **Atlas** | Documentation | kimi-k2.6 | Generates docs, READMEs, inline comments |
| **Momus** | Critic | glm-5.1 | Finds flaws, edge cases, potential bugs |

---

## 2. The Product Development Loop

### Phase 1: Ideation & Planning (You + Prometheus)

**You describe what you want to build.** Prometheus (strategic planner) turns your idea into a concrete plan.

**How to trigger it:**
```
/ulw @prometheus I want to add a new feature: account search by email domain.
Design the architecture, routes, model changes, and test plan.
```

**What Prometheus produces:**
- Architecture diagram (text-based)
- Route design (endpoints, methods, request/response shapes)
- Model changes needed
- Test strategy
- Implementation order (what to build first)

**Output example for our project:**
```
## Plan: Account Search by Email Domain

### Routes
- GET /accounts/search?domain=gmail.com
- Returns filtered list of accounts

### Model Changes
- Add Account.find_by_domain(cls, domain) static method
- Uses SQLAlchemy: Account.query.filter(Account.email.endswith(f"@{domain}"))

### Implementation Order
1. Model method (models.py)
2. Route handler (routes.py)
3. Error handling (error_handlers.py)
4. Tests (test_routes.py)
5. Integration test
```

---

### Phase 2: Implementation (Sisyphus orchestrates Hephaestus)

**Sisyphus takes Prometheus's plan and breaks it into executable tasks, then delegates to Hephaestus (deep worker) for implementation.**

**How to trigger it:**
```
/ulw @sisyphus Implement the account search by email domain feature
following Prometheus's plan. Use Hephaestus for the actual coding.
```

**What happens:**
1. Sisyphus creates a task list:
   - [ ] Add `find_by_domain()` to `Account` model
   - [ ] Add search route to `routes.py`
   - [ ] Register error handler for search validation
   - [ ] Write tests
2. Sisyphus delegates each task to Hephaestus
3. Hephaestus implements each one, reading existing code for context
4. Sisyphus tracks completion, re-delegates if something fails

**Real example — the model change Hephaestus would write:**
```python
# service/models.py — added by Hephaestus
@classmethod
def find_by_domain(cls, domain: str) -> list:
    """Find all accounts with email addresses matching the given domain."""
    logger.info("Searching for accounts with domain: %s", domain)
    return cls.query.filter(
        cls.email.endswith(f"@{domain}")
    ).all()
```

---

### Phase 3: Review & Quality (Metis + Momus)

**After implementation, Metis reviews the code and Momus finds flaws.**

**How to trigger it:**
```
/ulw @metis @momus Review the search feature implementation.
Check for: security issues, edge cases, code quality, test coverage.
```

**What Metis checks:**
- SQL injection risks (parameterized queries — safe here)
- Input validation (domain format)
- Error handling (empty results, invalid input)
- Code style (matches project conventions)

**What Momus finds:**
- What if domain is None?
- What if domain has special characters?
- What if the email column has no index (performance)?
- What about pagination for large result sets?

---

### Phase 4: Documentation (Atlas)

**Atlas generates documentation for the new feature.**

**How to trigger it:**
```
/ulw @atlas Document the new search feature. Update AGENTS.md
with the new route and model method. Add API docs.
```

---

### Phase 5: Deployment (DevOps Mode)

**Use the DevOps mode or dedicated deployment agents to ship.**

**How to trigger it:**
```
/ulw @sisyphus Prepare the deployment for the search feature.
Update the Tekton pipeline, build the Docker image, and verify.
```

---

## 3. Real Product-Building Workflows

### Workflow A: Build a New Feature End-to-End

```
Step 1: /ulw @prometheus Design a pagination system for GET /accounts
Step 2: /ulw @sisyphus Implement pagination following Prometheus's design
Step 3: /ulw @metis @momus Review the pagination implementation
Step 4: /ulw @atlas Document the pagination API
Step 5: Run tests and verify
```

### Workflow B: Fix a Bug

```
Step 1: /ulw @librarian Find all code related to account deletion
Step 2: /ulw @prometheus Analyze the bug and design the fix
Step 3: /ulw @sisyphus Implement the fix
Step 4: /ulw @metis Verify the fix doesn't break anything
Step 5: /ulw @atlas Update changelog
```

### Workflow C: Refactor a Module

```
Step 1: /ulw @explore Research best practices for Flask route organization
Step 2: /ulw @prometheus Design the refactoring plan
Step 3: /ulw @sisyphus Execute the refactoring in stages
Step 4: /ulw @metis @momus Review each stage
Step 5: /ulw @atlas Update AGENTS.md with new structure
```

### Workflow D: Add a New Microservice

```
Step 1: /ulw @explore Research best practices for Flask microservices
Step 2: /ulw @prometheus Design the new service architecture
Step 3: /ulw @sisyphus Scaffold the new service (Dockerfile, routes, models)
Step 4: /ulw @metis Review the scaffold
Step 5: /ulw @sisyphus Implement the business logic
Step 6: /ulw @atlas Document the new service
Step 7: Deploy alongside existing service
```

---

## 4. Team Mode: Parallel Product Development

With Team Mode enabled (4 parallel agents), you can build multiple features simultaneously.

**Example: Building 3 features at once**

```
/ulw @sisyphus We need to ship 3 features for v1.1:
1. Account search by email domain
2. Pagination for GET /accounts
3. Account CSV export endpoint

Assign each to a team member and track progress.
Report back when all 3 are complete.
```

**What happens internally:**
- Sisyphus creates 3 parallel workstreams
- Each workstream gets its own agent (Hephaestus, Atlas, etc.)
- All 3 work simultaneously
- Sisyphus monitors all 3 and reports when done

---

## 5. The Ralph Loop: Self-Correcting Development

The Ralph Loop (`ralph_loop: true` in config) makes agents keep working until the task is 100% complete.

**How it works:**
1. Agent receives a task
2. Agent works on it
3. Agent self-checks: "Is this done?"
4. If not done → loop back to step 2
5. If done → report completion

**This prevents the common problem of agents stopping at 80% completion.**

---

## 6. Practical Example: Building a Real Feature

Let's trace through building **Account CSV Export** on this project:

### Step 1: Plan
```
You: /ulw @prometheus Design a CSV export endpoint for accounts.
     Requirements: GET /accounts/export returns CSV file with all accounts.
```

**Prometheus outputs:**
```
Route: GET /accounts/export
Response: Content-Type: text/csv, Content-Disposition: attachment
Implementation:
1. Add export_csv() route in routes.py
2. Use Python csv module with StringIO
3. Include all Account fields: id, name, email, address, phone, date_joined
4. Add error handling for empty database
5. Write test: TestAccountService.test_export_csv()
```

### Step 2: Implement
```
You: /ulw @sisyphus Implement the CSV export following Prometheus's plan.
```

**Sisyphus delegates to Hephaestus who writes:**
```python
# service/routes.py
@app.route("/accounts/export", methods=["GET"])
def export_accounts():
    """Export all accounts as CSV."""
    accounts = Account.all()
    if not accounts:
        return jsonify({"error": "No accounts to export"}), status.HTTP_404_NOT_FOUND

    import csv
    import io

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["id", "name", "email", "address", "phone", "date_joined"])
    for account in accounts:
        writer.writerow([
            account.id, account.name, account.email,
            account.address, account.phone, account.date_joined.isoformat()
        ])

    response = make_response(output.getvalue())
    response.headers["Content-Disposition"] = "attachment; filename=accounts.csv"
    response.headers["Content-Type"] = "text/csv"
    return response
```

### Step 3: Review
```
You: /ulw @metis @momus Review the CSV export implementation.
```

### Step 4: Test
```
You: /ulw @sisyphus Write tests for the CSV export feature.
```

### Step 5: Document
```
You: /ulw @atlas Update AGENTS.md with the new CSV export route.
```

---

## 7. Key Commands Reference

| Command | Purpose |
|---------|---------|
| `/ulw <instruction>` | Activate all OmO features (ultrawork) |
| `/ulw @sisyphus <task>` | Delegate to orchestrator |
| `/ulw @prometheus <design>` | Get architecture/design |
| `/ulw @metis <code>` | Get code review |
| `/ulw @momus <code>` | Get critical analysis |
| `/ulw @explore <question>` | Research external resources |
| `/ulw @librarian <query>` | Search codebase |
| `/ulw @atlas <feature>` | Generate documentation |
| `/ulw @oracle <question>` | Ask about codebase |
| `@sisyphus` in any message | Tag Sisyphus in a conversation |
| `@prometheus` in any message | Tag Prometheus for input |

---

## 8. Product Development Checklist

When starting a new product feature, run through this checklist:

- [ ] **Define** — What exactly are we building? (You)
- [ ] **Design** — Prometheus creates the architecture plan
- [ ] **Approve** — You review and approve the plan
- [ ] **Implement** — Sisyphus delegates to Hephaestus
- [ ] **Review** — Metis + Momus review the code
- [ ] **Fix** — Any issues found are fixed
- [ ] **Test** — Tests are written and pass
- [ ] **Document** — Atlas updates docs
- [ ] **Deploy** — Ship to production
- [ ] **Verify** — Confirm it works in production

---

## 9. Current Project State

Your project (`devops-capstone-project`) is already fully configured:

- ✅ OmO installed (v4.14.0)
- ✅ 10 agents configured with OpenCode Go models
- ✅ Team Mode enabled (4 parallel agents)
- ✅ Hashline edits enabled
- ✅ Ralph Loop enabled
- ✅ AGENTS.md generated (project + service/ + tests/)
- ✅ Plugin registered in opencode.json
- ✅ Rules injection active

**You are ready to build. Start with:**
```
/ulw @prometheus I want to add [feature X] to this Flask API. Design the plan.
```
