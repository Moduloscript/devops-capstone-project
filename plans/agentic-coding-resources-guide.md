# Agentic Coding Resources Guide

> Concise reference for setting up OpenCode with a professional harness for large code projects.

---

## 1. OpenCode — The Foundation

| Detail | Value |
|---|---|
| **GitHub** | 160K stars, 900 contributors |
| **Usage** | 7.5M monthly developers |
| **Install** | `curl -fsSL https://opencode.ai/install \| bash` |
| **Interfaces** | Terminal, Desktop app (beta), IDE extension |
| **LLM Support** | 75+ providers (ChatGPT Plus/Pro, GitHub Copilot, etc.) |
| **Key Features** | LSP (30+ languages), multi-session, share links, Zen optimized models |
| **Privacy** | Does not store code or context data |

---

## 2. Oh-My-OpenAgent — The Harness (Most Important)

| Detail | Value |
|---|---|
| **GitHub** | 63.8K stars, v4.13.0, 290 contributors |
| **Purpose** | Plugin that supercharges OpenCode with professional agentic workflows |
| **Editions** | **Ultimate** (OpenCode) → `bunx oh-my-openagent install` |
| | **Light** (Codex CLI) → `npx lazycodex-ai install` |
| **Config** | `.opencode/oh-my-openagent.jsonc` |

### Core Features

| Feature | Description |
|---|---|
| **Team Mode** | Up to 8 parallel agent members with tmux visualization |
| **Ultrawork (ulw)** | Custom workflow loop with hash-anchored edits (LINE#ID content hash validates changes, eliminates stale-line errors) |
| **Discipline Agents** | **Sisyphus** — orchestrator (routes tasks) |
| | **Hephaestus** — deep worker (complex multi-file changes) |
| | **Prometheus** — strategic planner (designs architecture before coding) |
| **Agent Categories** | `visual-engineering` (frontend/UI), `deep` (autonomous research), `quick` (single-file), `ultrabrain` (hard logic) |
| **Built-in MCPs** | Exa (web search), Context7 (code context), Grep.app (code search) |
| **Key Features** | IntentGate, Ralph Loop, Todo Enforcer, Comment Checker, Rules Injection, AST-Grep, LSP integration, Background Agents, `/init-deep` |

### Team Mode Config Example

```jsonc
// .opencode/oh-my-openagent.jsonc
{
  "team_mode": {
    "enabled": true,
    "max_parallel_members": 4,
    "tmux_visualization": true
  }
}
```

---

## 3. Claude Code Ultimate Guide — The Learning Resource

| Detail | Value |
|---|---|
| **GitHub** | 5.2K stars, 430K+ lines |
| **Author** | Florian Bruniaux |
| **Website** | [cc.bruniaux.com](https://cc.bruniaux.com) |

### What's Inside

| Component | Count |
|---|---|
| Documentation | 24K+ lines |
| Templates | 181 ready-to-use patterns |
| Quiz Questions | 271 |
| Mermaid Diagrams | 48 |
| Hooks | 38 types |
| Skills | 74 |
| Agents | 23 |

### Learning Paths

| Path | Steps |
|---|---|
| Junior | 7 steps |
| Senior | 6 steps |
| Power User | 8 steps |
| PM | 5 steps |
| DevOps/SRE | 5 steps |
| Product Designer | 5 steps |

### Security Database

- **28 CVE-mapped vulnerabilities**
- **655 malicious skills catalogued**

### MCP Server

```json
{
  "mcpServers": {
    "claude-code-guide": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "claude-code-ultimate-guide-mcp"]
    }
  }
}
```

### Plugin Marketplace

```
claude plugin marketplace add FlorianBruniaux/claude-code-plugins
```

---

## 4. Agentic Coding Rulebook — Universal Standard

| Detail | Value |
|---|---|
| **GitHub** | [obviousworks/agentic-coding-rulebook](https://github.com/obviousworks/agentic-coding-rulebook) |
| **Backed By** | OpenAI, Google, Anthropic, Cursor, Sourcegraph |
| **Tool-Agnostic** | Windsurf, Cursor, GitHub Copilot, Claude Code, Aider, Zed |

### Core Principles

| Principle | Abbr | Meaning |
|---|---|---|
| Simplicity First | SF | Keep it simple |
| Readability Priority | RP | Code is read more than written |
| Dependency Minimalism | DM | Fewer dependencies = fewer problems |
| Security First | SecF | Security by design |
| Test-Driven Thinking | TDT | Tests before code |
| Token Efficiency | TE | Optimize for LLM context limits |

### Quick Start

```bash
cp agent_template.md AGENTS.md
ln -s AGENTS.md .cursorrules
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md .windsurfrules
```

### Config File Mapping

| Tool | Config File |
|---|---|
| Windsurf | `.windsurfrules` |
| Cursor | `.cursorrules` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Claude Code | `CLAUDE.md` |
| Aider | `AGENTS.md` |
| Zed | `AGENTS.md` |

---

## 5. Agentic Coding Handbook — Beginner's Practical Guide

| Detail | Value |
|---|---|
| **URL** | [tweag.github.io/agentic-coding-handbook](https://tweag.github.io/agentic-coding-handbook) |
| **Author** | Tweag (software consultancy) |
| **Evidence** | AI-assisted teams delivered **45% faster** in real experiment |

### Sections

1. **Getting Started** — Setup and installation
2. **Core Workflows** — How to structure AI-assisted development
3. **Prompt Engineering** — Writing effective prompts
4. **Tools & Setup** — Cursor and GitHub Copilot Agent
5. **Examples & Templates** — Ready-to-use patterns

---

## 6. OpenDev (arXiv Paper) — Deep Architecture Reference

| Detail | Value |
|---|---|
| **Paper** | [arxiv.org/html/2603.05344v1](https://arxiv.org/html/2603.05344v1) |
| **Title** | "Building AI Coding Agents for the Terminal: Scaffolding, Harness, Context Engineering, and Lessons Learned" |
| **Author** | Nghi D. Q. Bui |
| **GitHub** | [github.com/opendev-to/opendev](https://github.com/opendev-to/opendev) |

### Architecture (4 Layers)

| Layer | Purpose |
|---|---|
| Entry & UI | User interface and session management |
| Agent | Core reasoning loop with 5 model roles |
| Tool & Context | 35 built-in tools, context management |
| Persistence | Memory and state storage |

### 5 Model Roles

| Role | Function | Fallback Chain |
|---|---|---|
| Action | Code generation | GPT-4 → Claude → Gemini |
| Thinking | Planning and reasoning | Claude → GPT-4 |
| Critique | Self-review of outputs | Claude Haiku → GPT-4o Mini |
| Vision | Screenshot analysis | GPT-4o → Claude |
| Compact | Context compression | GPT-4o Mini → Claude Haiku |

### 35 Built-in Tools (12 Categories)

| Category | Count | Examples |
|---|---|---|
| File Operations | 5 | read, write, edit, search, diff |
| Process | 4 | run command, terminal, background |
| Web | 4 | fetch, search, scrape |
| Symbols/LSP | 6 | goto-def, references, hover, completion |
| Visual | 2 | screenshot, screenshot-explanation |
| PDF | 1 | pdf-to-markdown |
| Notebooks | 1 | jupyter-execute |
| Task Management | 4 | todo, checklist, progress |
| User Input | 1 | ask-user |
| Discovery | 1 | list-files |
| Batch | 1 | batch-execute |
| Subagents | 2 | delegate, research |
| Skills | 1 | load-skill |
| Planning | 1 | create-plan |
| Completion | 1 | finish |

### Adaptive Context Compaction (5 Stages)

| Threshold | Action |
|---|---|
| 70% | Warning — notify user |
| 80% | Mask observations (keep only summaries) |
| 85% | Fast pruning — remove low-value content |
| 90% | Aggressive masking — keep only essentials |
| 99% | Full LLM compaction — rewrite entire context |

### Dual-Memory Architecture

| Memory Type | What It Stores | When It Updates |
|---|---|---|
| **Episodic** | Compressed long-range context (LLM summary) | Every 5 messages |
| **Working** | Last 6 exchanges verbatim | Every message |

### 8 Subagent Types

1. **Code-Explorer** — Navigate and understand codebases
2. **Planner** — Design implementation plans
3. **PR-Reviewer** — Review pull requests
4. **Security-Reviewer** — Audit for vulnerabilities
5. **Web-Clone** — Clone web pages for reference
6. **Web-Generator** — Generate web pages
7. **Project-Init** — Initialize new projects
8. **Ask-User** — Request user input

### 9-Pass Fuzzy Matching Chain (for edits)

1. Simple match
2. Line-trimmed
3. Block-anchor
4. Whitespace-normalized
5. Indentation-flexible
6. Escape-normalized
7. Trimmed-boundary
8. Context-aware
9. Multi-occurrence

### Safety (5 Layers)

| Layer | Description |
|---|---|
| Prompt-Level Guardrails | System prompt restrictions |
| Schema-Level Tool Restrictions | Tool parameter validation |
| Runtime Approval System | User confirmation for dangerous ops |
| Tool-Level Validation | Input/output sanitization |
| Lifecycle Hooks | Pre/post execution checks |

### 24 System Reminders (6 Categories)

| Category | Count | Purpose |
|---|---|---|
| Phase Control | 4 | Guide agent through workflow phases |
| Task Lifecycle | 5 | Track task progress |
| Todo Enforcement | 2 | Ensure todos are maintained |
| Error Recovery | 8 | Handle failures gracefully |
| Behavioral | 5 | Maintain agent behavior standards |
| JSON Retry | 2 | Handle malformed JSON responses |

---

## 7. DEV Article (No Longer Available)

- **URL:** `dev.to/chand1012/the-best-way-to-do-agentic-development-in-2026-1m5n`
- **Status:** 404 — content removed
- **Previously covered:** Progression from Claude Code → OpenCode + Oh-My-OpenCode → Conductor + Claude Code + Plugins
- **Recommended stack (from memory):** Claude Code + Superpowers + Context7 + Tavily + Conductor

---

## Quick Start — Recommended Setup

```bash
# Step 1: Install OpenCode
curl -fsSL https://opencode.ai/install | bash

# Step 2: Install Oh-My-OpenAgent (Ultimate Edition)
bunx oh-my-openagent install

# Step 3: Configure Team Mode
# Edit .opencode/oh-my-openagent.jsonc

# Step 4: Add AGENTS.md for project rules
cp agent_template.md AGENTS.md
ln -s AGENTS.md CLAUDE.md

# Step 5: Learn the workflows
# Visit: https://tweag.github.io/agentic-coding-handbook
# Visit: https://github.com/FlorianBruniaux/claude-code-ultimate-guide
```

---

## Resource Priority Matrix

| Priority | Resource | Why |
|---|---|---|
| **1** | Oh-My-OpenAgent | Directly answers "detailed harness" — Team Mode, ultrawork, Discipline Agents |
| **2** | OpenCode Official | The foundation tool |
| **3** | Claude Code Ultimate Guide | Best learning resource (181 templates, learning paths) |
| **4** | Agentic Coding Rulebook | Universal standard for project config |
| **5** | OpenDev Paper | Deep architecture understanding for advanced users |
| **6** | Agentic Coding Handbook | Beginner-friendly practical intro |
| **7** | DEV Article | No longer available (legacy reference) |
