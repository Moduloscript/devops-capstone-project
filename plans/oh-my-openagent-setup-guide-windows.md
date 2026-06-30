# Oh-My-OpenAgent Setup Guide for Windows

> **Your System:** Windows 11, OpenCode v1.17.11, Bun 1.3.5, Node v25.2.0, Git 2.51.0
> **Goal:** Install and configure Oh-My-OpenAgent (Ultimate Edition) for professional agentic coding

---

## Table of Contents

1. [Prerequisites Check](#1-prerequisites-check)
2. [Installation](#2-installation)
3. [Configuration](#3-configuration)
4. [Understanding the Setup](#4-understanding-the-setup)
5. [Basic Usage Examples](#5-basic-usage-examples)
6. [Real-World Coding Tasks](#6-real-world-coding-tasks)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Prerequisites Check

Your system already has everything needed:

| Tool         | Status       | Version          |
| ------------ | ------------ | ---------------- |
| **OpenCode** | ✅ Installed | v1.17.11         |
| **Bun**      | ✅ Installed | 1.3.5            |
| **Node.js**  | ✅ Installed | v25.2.0          |
| **Git**      | ✅ Installed | 2.51.0.windows.1 |
| **npx**      | ✅ Installed | 11.6.2           |

**Current OpenCode config** (`%USERPROFILE%\.config\opencode\opencode.jsonc`):

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
}
```

---

## 2. Installation

### Step 1: Install Oh-My-OpenAgent (Ultimate Edition)

Open **Command Prompt** or **PowerShell** and run:

```cmd
bunx oh-my-openagent install
```

> **Note:** The package is also published as `oh-my-opencode` during the rename transition. Both names work.

**What happens during install:**

1. A TUI (Terminal UI) walks you through the setup
2. You select your LLM providers (Anthropic, OpenAI, Google Gemini, etc.)
3. The installer registers the plugin in OpenCode's config
4. It configures agent-to-model mappings
5. It sets up provider authentication

### Step 2: What the Installer Will Ask

The installer will prompt you for:

| Prompt                | What to Choose                                                        |
| --------------------- | --------------------------------------------------------------------- |
| **Platform**          | Select `opencode` (Ultimate Edition)                                  |
| **LLM Providers**     | Select the ones you have API keys for (ChatGPT, Claude, Gemini, etc.) |
| **Model Preferences** | Defaults are fine — the harness auto-selects the best model per task  |
| **Authentication**    | Enter API keys for each provider                                      |

### Step 3: Verify Installation

After installation, check that the plugin is registered:

```cmd
type %USERPROFILE%\.config\opencode\opencode.json
```

You should see `"oh-my-openagent"` (or `"oh-my-opencode"`) in the `plugin` array.

---

## 3. Configuration

### 3.1 Basic Config File

Create or edit `%USERPROFILE%\.config\opencode\oh-my-openagent.jsonc`:

```jsonc
{
  "$schema": "https://omo.dev/schemas/config.json",
  "team_mode": {
    "enabled": false,
    "max_parallel_members": 4,
    "tmux_visualization": true,
  },
  "agents": {
    "sisyphus": {
      "model": "claude-opus-4-7",
      "temperature": 0.3,
    },
    "hephaestus": {
      "model": "gpt-5.5",
      "temperature": 0.2,
    },
    "prometheus": {
      "model": "claude-opus-4-7",
      "temperature": 0.4,
    },
  },
  "features": {
    "hashline_edits": true,
    "todo_enforcer": true,
    "comment_checker": true,
    "ralph_loop": true,
  },
}
```

### 3.2 Project-Level Config

For this project (`devops-capstone-project`), create `.opencode/oh-my-openagent.jsonc`:

```jsonc
{
  "team_mode": {
    "enabled": true,
    "max_parallel_members": 4,
  },
  "agents": {
    "sisyphus": {
      "model": "claude-opus-4-7",
    },
    "hephaestus": {
      "model": "gpt-5.5",
    },
  },
  "features": {
    "hashline_edits": true,
    "todo_enforcer": true,
    "comment_checker": true,
  },
  "rules_injection": {
    "enabled": true,
    "files": ["AGENTS.md", "CLAUDE.md"],
  },
}
```

### 3.3 Enable Team Mode (For Large Projects)

When you need parallel agents working simultaneously:

```jsonc
{
  "team_mode": {
    "enabled": true,
    "max_parallel_members": 4,
    "tmux_visualization": true,
  },
}
```

Restart OpenCode after enabling. The `team_*` tool family unlocks:

- `team_create` — Create a new team member
- `team_send_message` — Communicate between members
- `team_task_create` — Assign tasks to members
- `team_status` — Check team progress

---

## 4. Understanding the Setup

### What You Just Installed

```
OpenCode (v1.17.11)          ← The base AI coding agent
    └── Oh-My-OpenAgent      ← The harness plugin (what you installed)
        ├── Sisyphus         ← Orchestrator agent (plans & delegates)
        ├── Hephaestus       ← Deep worker agent (autonomous execution)
        ├── Prometheus       ← Strategic planner (interviews & plans)
        ├── Team Mode        ← Up to 8 parallel agents
        ├── Hashline Edits   ← Content-validated file edits
        ├── Built-in MCPs    ← Exa, Context7, Grep.app
        ├── LSP Integration  ← IDE-level code intelligence
        └── 54+ Hooks        ← Lifecycle hooks for customization
```

### How the Agents Work Together

```
You: "Add a new API endpoint for user authentication"

1. Prometheus (Planner)
   → Interviews you: "What auth method? JWT or OAuth?
      What fields? What error responses?"
   → Creates a detailed plan

2. Sisyphus (Orchestrator)
   → Takes the plan
   → Delegates to Hephaestus: "Create the auth route"
   → Delegates to another agent: "Write tests"
   → Monitors progress

3. Hephaestus (Worker)
   → Explores the codebase
   → Reads existing route patterns
   → Implements the endpoint
   → Verifies it works

4. Sisyphus
   → Checks todos are complete
   → Reports: "Done. Endpoint created at /api/auth/login"
```

---

## 5. Basic Usage Examples

### Example 1: Simple Task (Single File Change)

**Your prompt:**

```
ultrawork

Fix the typo in the README.md — "devops" should be "DevOps" throughout.
```

**What happens:**

1. OmO detects this is a `quick` category task (single file)
2. Routes to the appropriate model
3. Uses hashline edits to make precise changes
4. Verifies the changes
5. Reports completion

### Example 2: Medium Task (Multi-File Change)

**Your prompt:**

```
ultrawork

Add input validation to the Flask routes in service/routes.py.
All POST endpoints should validate required fields before processing.
Create validation functions in a new file service/validators.py.
```

**What happens:**

1. **Prometheus** interviews you: "What fields need validation? What error format?"
2. Creates a plan: `Create validators.py → Update routes.py → Write tests`
3. **Sisyphus** delegates to **Hephaestus**
4. **Hephaestus** explores the codebase, reads existing routes, creates the validator
5. **Todo Enforcer** ensures nothing is missed
6. **Comment Checker** cleans up any AI-generated comments

### Example 3: Large Task (Team Mode)

**Your prompt:**

```
ultrawork

I need to add a PostgreSQL database integration to this Flask project.
- Create database models in service/models.py
- Add database config in service/config.py
- Create migration scripts
- Update the Dockerfile to include PostgreSQL dependencies
- Write integration tests
```

**What happens:**

1. **Prometheus** interviews you about schema, connection details, migration strategy
2. Creates a comprehensive plan with milestones
3. **Team Mode** activates — up to 4 agents work in parallel:
   - Agent 1: Updates `service/models.py`
   - Agent 2: Updates `service/config.py`
   - Agent 3: Creates migration scripts
   - Agent 4: Updates Dockerfile
4. **Sisyphus** coordinates and merges results
5. **Todo Enforcer** verifies all tasks complete
6. Final review and report

---

## 6. Real-World Coding Tasks

### Task 1: Debug a Failing Test

**Situation:** A test in `tests/test_routes.py` is failing.

**Your prompt:**

```
ultrawork

Run the tests and fix any failures in tests/test_routes.py.
Analyze the root cause before making changes.
```

**What OmO does:**

1. Runs `pytest tests/test_routes.py -v` to see failures
2. Reads the failing test and the route it tests
3. Analyzes root cause (e.g., missing mock, wrong assertion, logic bug)
4. Fixes the issue
5. Re-runs tests to verify
6. Reports what was wrong and what was fixed

### Task 2: Refactor a Module

**Your prompt:**

```
ultrawork

Refactor service/common/error_handlers.py to use a more structured
error handling pattern. All errors should return JSON with
{ "error": string, "code": int, "details": object? }.
Update all routes that use the old error handlers.
```

**What OmO does:**

1. Reads the current `error_handlers.py`
2. Reads all routes that import/use error handlers
3. Designs the new error structure
4. Refactors `error_handlers.py`
5. Updates all route files
6. Runs tests to verify nothing broke
7. Reports all changed files

### Task 3: Add a New Feature

**Your prompt:**

```
ultrawork

Add a health check endpoint GET /health that returns:
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "ISO timestamp",
  "dependencies": {
    "database": "connected|disconnected"
  }
}
```

**What OmO does:**

1. Reads the existing route patterns in `service/routes.py`
2. Creates the health check endpoint
3. Adds a database connectivity check
4. Registers the route in the app factory
5. Adds a test in `tests/test_routes.py`
6. Runs tests to verify
7. Reports completion

### Task 4: Full Project Analysis with `/init-deep`

**Your prompt:**

```
/init-deep
```

**What OmO does:**

1. Scans the entire project structure
2. Generates hierarchical `AGENTS.md` files:
   ```
   devops-capstone-project/
   ├── AGENTS.md              ← Project-wide context
   ├── service/
   │   ├── AGENTS.md          ← Service-specific context
   │   └── common/
   │       └── AGENTS.md      ← Common module context
   ├── tests/
   │   └── AGENTS.md          ← Test-specific context
   └── deploy/
       └── AGENTS.md          ← Deployment context
   ```
3. Each file describes what that directory contains, key patterns, and conventions
4. Agents auto-read the relevant context when working in those directories

### Task 5: Security Audit with Team Mode

**Your prompt:**

```
ultrawork

Run a security audit on this project. Check for:
- Hardcoded secrets
- SQL injection vulnerabilities
- Insecure dependencies
- Missing authentication
```

**What OmO does (with Team Mode):**

1. **Prometheus** plans the audit scope
2. **Team Mode** activates:
   - Agent 1: Scans for hardcoded secrets (API keys, tokens)
   - Agent 2: Reviews SQL queries for injection risks
   - Agent 3: Checks `requirements.txt` for vulnerable packages
   - Agent 4: Reviews authentication logic
3. All 4 agents work in parallel
4. Results are compiled into a security report
5. Fixes are applied automatically

---

## 7. Troubleshooting

### Problem: Plugin not loading

```cmd
# Check if plugin is registered
type %USERPROFILE%\.config\opencode\opencode.json

# Run the doctor command
bunx oh-my-opencode doctor
```

### Problem: Installation fails on Windows

```cmd
# Ensure Bun is in PATH
where bun

# Try with npx instead
npx oh-my-openagent install

# Or use the legacy package name
bunx oh-my-opencode install
```

### Problem: Agent not using Team Mode

Check your config:

```cmd
# Verify Team Mode is enabled
type .opencode\oh-my-openagent.jsonc
```

Ensure `team_mode.enabled` is `true`, then restart OpenCode.

### Problem: Hashline edits not working

```cmd
# Check if hashline feature is enabled
type %USERPROFILE%\.config\opencode\oh-my-openagent.jsonc
```

Ensure `features.hashline_edits` is `true`.

### Problem: Uninstall

```cmd
# Remove plugin from OpenCode config
# Edit %USERPROFILE%\.config\opencode\opencode.json and remove the plugin entry

# Remove config files
del %USERPROFILE%\.config\opencode\oh-my-openagent.jsonc
del %USERPROFILE%\.config\opencode\oh-my-opencode.jsonc
```

---

## Quick Reference Card

| Command                        | What It Does                           |
| ------------------------------ | -------------------------------------- |
| `bunx oh-my-openagent install` | Install Ultimate Edition               |
| `ultrawork` or `ulw`           | Start an ultrawork session             |
| `/ulw-loop`                    | Self-referential loop until 100% done  |
| `/init-deep`                   | Generate hierarchical AGENTS.md files  |
| `/start-work`                  | Call Prometheus for strategic planning |
| `bunx oh-my-opencode doctor`   | Run diagnostics                        |
| `hyperplan`                    | 5 hostile agents critique your plan    |
| `security-research`            | 3 hunters + 2 PoC engineers audit code |

### Your First Session

```cmd
# 1. Open OpenCode in your project directory
cd C:\Users\T490\Documents\modulo-vault\devops-capstone-project
opencode

# 2. Type this to start:
ultrawork

# 3. Then describe your task:
Analyze this project structure and tell me what it does.
```

---

## Summary

| Step | Action                      | Command                        |
| ---- | --------------------------- | ------------------------------ |
| 1    | Install OmO                 | `bunx oh-my-openagent install` |
| 2    | Configure                   | Edit `oh-my-openagent.jsonc`   |
| 3    | Run `/init-deep`            | Type `/init-deep` in OpenCode  |
| 4    | Start coding                | Type `ultrawork` + your task   |
| 5    | Enable Team Mode (optional) | Set `team_mode.enabled: true`  |

**Key takeaway:** After installation, you only need to type `ultrawork` followed by your task description. The harness handles everything else — model selection, agent delegation, parallel execution, edit validation, and task completion verification.
