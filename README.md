# n8n-skills

**Expert Claude Code skills for building flawless n8n workflows using the n8n-mcp MCP server**

[![skills.sh](https://skills.sh/b/czlonkowski/n8n-skills)](https://skills.sh/czlonkowski/n8n-skills)
[![GitHub stars](https://img.shields.io/github/stars/czlonkowski/n8n-skills?style=social)](https://github.com/czlonkowski/n8n-skills)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![n8n-mcp](https://img.shields.io/badge/n8n--mcp-compatible-green.svg)](https://github.com/czlonkowski/n8n-mcp)

## Watch the Introduction Video

[![n8n Skills Introduction](skills.png)](https://youtu.be/e6VvRqmUY2Y?si=6Igply3cadjO6Xx0)

---

## 🎯 What is this?

This repository contains **14 complementary Claude Code skills** — plus an always-on router skill and a hooks enforcement layer — that teach AI assistants how to build production-ready n8n workflows using the [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) MCP server, and how to deploy the self-hosted n8n that runs them.

### Why These Skills Exist

Building n8n workflows programmatically can be challenging. Common issues include:
- Using MCP tools incorrectly or inefficiently
- Getting stuck in validation error loops
- Not knowing which workflow patterns to use
- Misconfiguring nodes and their dependencies

These skills solve these problems by teaching Claude:
- ✅ Correct n8n expression syntax ({{}} patterns)
- ✅ How to use n8n-mcp tools effectively
- ✅ Proven workflow patterns from real-world usage
- ✅ Validation error interpretation and fixing
- ✅ Operation-aware node configuration

---

## 📚 The 14 Skills

### 1. **n8n Expression Syntax**
Teaches correct n8n expression syntax and common patterns.

**Activates when**: Writing expressions, using {{}} syntax, accessing $json/$node variables, troubleshooting expression errors.

**Key Features**:
- Core variables ($json, $node, $now, $env)
- **Critical gotcha**: Webhook data is under `$json.body`
- Common mistakes catalog with fixes
- When NOT to use expressions (Code nodes!)

### 2. **n8n MCP Tools Expert** (HIGHEST PRIORITY)
Expert guide for using n8n-mcp MCP tools effectively.

**Activates when**: Searching for nodes, validating configurations, accessing templates, managing workflows.

**Key Features**:
- Tool selection guide (which tool for which task)
- nodeType format differences (nodes-base.* vs n8n-nodes-base.*)
- Validation profiles (minimal/runtime/ai-friendly/strict)
- Smart parameters (branch="true" for IF nodes)
- Auto-sanitization system explained

**Most Important**: Teaches correct MCP tool usage patterns and parameter formats

### 3. **n8n Workflow Patterns**
Build workflows using 5 proven architectural patterns.

**Activates when**: Creating workflows, connecting nodes, designing automation.

**Key Features**:
- 5 proven patterns (webhook processing, HTTP API, database, AI, scheduled)
- Workflow creation checklist
- Real examples from 2,653+ n8n templates
- Connection best practices
- Pattern selection guide

### 4. **n8n Validation Expert**
Interpret validation errors and guide fixing.

**Activates when**: Validation fails, debugging workflow errors, handling false positives.

**Key Features**:
- Validation loop workflow
- Real error catalog
- Auto-sanitization behavior explained
- False positives guide
- Profile selection for different stages

### 5. **n8n Node Configuration**
Operation-aware node configuration guidance.

**Activates when**: Configuring nodes, understanding property dependencies, setting up AI workflows.

**Key Features**:
- Property dependency rules (e.g., sendBody → contentType)
- Operation-specific requirements
- AI connection types (8 types for AI Agent workflows)
- Common configuration patterns

### 6. **n8n Code JavaScript**
Write effective JavaScript code in n8n Code nodes.

**Activates when**: Writing JavaScript in Code nodes, troubleshooting Code node errors, making HTTP requests with `this.helpers` (the `$helpers` global), working with dates.

**Key Features**:
- Data access patterns ($input.all(), $input.first(), $input.item)
- **Critical gotcha**: Webhook data under `$json.body`
- Correct return format: `[{json: {...}}]`
- Built-in functions (`this.helpers.httpRequest()` — the bare `$helpers` global is undefined in the task-runner sandbox; prefer the HTTP Request node for non-trivial/authenticated calls — DateTime, $jmespath())
- Top 5 error patterns with solutions (covering 62%+ of failures)
- 10 production-tested patterns

### 7. **n8n Code Python**
Write Python code in n8n Code nodes with proper limitations awareness.

**Activates when**: Writing Python in Code nodes, need to know Python limitations, working with standard library.

**Key Features**:
- **Important**: Use JavaScript for 95% of use cases
- Python data access (_input, _json, _node)
- **Critical limitation**: No external libraries (requests, pandas, numpy)
- Standard library reference (json, datetime, re, etc.)
- Workarounds for missing libraries
- Common Python patterns for n8n

### 8. **n8n Code Tool**
Write code for the AI-agent-callable Custom Code Tool (`@n8n/n8n-nodes-langchain.toolCode`) — a different node from the regular Code node with a different contract.

**Activates when**: Building a Code Tool attached to an AI Agent, troubleshooting "Wrong output type returned" or "No execution data available" errors, deciding between unstructured `query` parsing and `specifyInputSchema`.

**Key Features**:
- **Critical distinction**: Code Tool ≠ Code node (different node type, different return format, different sandbox)
- **Return format**: a **string** (use `JSON.stringify()` for structured output) — NOT `[{json:{...}}]`
- **Input binding**: `query` (JS) / `_query` (Python) — `$fromAI()` does NOT work here
- Unstructured vs structured input modes (`specifyInputSchema` → DynamicStructuredTool)
- Sandbox limits: no `$input`, `$helpers`, `$json`, `$getWorkflowStaticData`, no state across calls
- Three signature error strings with causes and fixes
- When to use Code Tool vs `toolWorkflow` vs HTTP Request Tool

### 9. **n8n Error Handling**
Make failures loud, structured, and recoverable.

**Activates when**: Building webhook/API or unattended workflows, wiring error outputs, setting retries, designing 4xx/5xx responses, or chasing silent failures.

**Key Features**:
- Per-node error output: the two-step `onError: continueErrorOutput` + wire `main[1]` trap
- `retryOnFail` self-healing for flaky network calls
- 4xx/5xx response-shape mapping (and the `responseCode`-defaults-to-200 gotcha)
- Error Trigger workflows for unattended runs

### 10. **n8n Binary & Data**
Handle files, images, and binary data correctly.

**Activates when**: Working with files, images, PDFs, attachments, uploads/downloads, vision input, or passing a file to/from an AI agent tool.

**Key Features**:
- `$binary` vs `$json` — file contents never live in `$json`
- Keeping binary alive across JSON transforms with Merge
- The agent-tool binary boundary (pre-stage to storage, pass keys/URLs)
- CDN/URL requirement for showing images in chat surfaces

### 11. **n8n Sub-workflows**
Build reusable, composable sub-workflows.

**Activates when**: Extracting shared logic, building multi-step or reused workflows, or any workflow over ~10 nodes.

**Key Features**:
- Execute Workflow Trigger with "Define Below" typed inputs (not passthrough)
- `mode: all` vs `each` and `waitForSubWorkflow` (the only true parallelization)
- Verb-first prefix naming for discovery (MCP can't filter by tags)
- Stateless vs stateful design; N+1 split-by-input-shape

### 12. **n8n AI Agents**
Design n8n AI agents the right way.

**Activates when**: Building any `@n8n/n8n-nodes-langchain.*` node — AI Agent, LLM chain, Text Classifier — or working with tool calling, `$fromAI`, memory, structured output, RAG, or chat bots.

**Key Features**:
- Agent vs LLM Chain vs Text Classifier; the model/memory/tools/outputParser slots
- Tool names & descriptions ARE the prompt; `$fromAI` parameter anatomy
- Structured output with autoFix; memory + sessionId; human-in-the-loop review
- Chat shell+core+sub-agent topology with anti-loop filtering

### 13. **n8n Multi-Instance**
Target the right n8n instance when an account has more than one.

**Activates when**: The `n8n_instances` tool is available, the user mentions multiple instances/environments (prod vs staging, several clients), or a call returns an unexpected `NOT_FOUND` or wrong/empty data.

**Key Features**:
- `n8n_instances` `list`/`switch` shapes and the real error envelope (`UNKNOWN_INSTANCE`, `MULTI_INSTANCE_DISABLED`, …)
- Switching in its own turn; the per-session binding that persists across reconnects/deploys
- Verifying `current` before credential writes — the server fail-closes only the *ambiguous* case (`INSTANCE_AMBIGUOUS`); an explicit wrong switch still writes the secret silently
- Recovering from a misroute (NOT_FOUND ≈ wrong instance, not a deletion) and copying objects between instances

### 14. **n8n Self-Hosting** (deployment/ops)
Deploy a production self-hosted n8n end-to-end to a fresh Linux VM.

**Activates when**: Self-hosting, installing, or deploying n8n on your own server/VPS (Hetzner, DigitalOcean, EC2, bare metal) — single or queue mode — or updating/backing-up/hardening it. Not for n8n Cloud, and not for building workflows.

**Key Features**:
- Docker Compose behind **Caddy** with automatic HTTPS; asks **single vs queue mode** first
- Single (SQLite) and queue (main + Redis + Postgres + workers) templates, secret-free and domain-free
- Generates fresh secrets on the box; secure defaults (explicit encryption key, no published internal ports, telemetry off, env-access blocked, execution pruning)
- DNS/ports preflight, end-to-end verify (cert + reachability), and Day-2 (update / backup / restore)

> This is the pack's one **deployment** skill; it triggers on its own description and is not part of the workflow-building router/hooks flow.

---

## 🪝 Enforcement Layer (hooks + router)

Beyond the capability skills, the plugin ships an **always-on enforcement layer** so the right guidance surfaces at the moment of decision — not only when a query happens to match a skill description.

- **Router skill (`using-n8n-mcp-skills`)** — loaded into every session by a `SessionStart` hook. It routes you to the right skill, summarizes every n8n-mcp tool, and states the cross-cutting rules. It re-fires on resume/clear/compact so it survives context compaction.
- **PreToolUse hooks** — before high-impact n8n-mcp calls, a short reminder points at the relevant skill. Looking up a Set, Code, Merge, Loop Over Items, DateTime, Data Table, or AI Agent node via `get_node` fires a node-specific reminder (and re-fires each time, because a re-lookup usually means you're reconsidering the same decision). Calls to `n8n_instances` and `n8n_manage_credentials` fire one-shot reminders pointing at the multi-instance and credential-discipline skills.
- **PostToolUse hook** — after `validate_workflow`, it inspects the workflow's node types and routes you to the skills that own the remaining risks, with the reminder that *validation passing is necessary, not sufficient*.

Hooks run only in the **Claude Code / Codex plugin** install. On Claude.ai (individual skill uploads) the skills still activate by description — the pack degrades gracefully, just without the proactive nudges. Every hook fails open and never blocks a tool call.

---

## 🚀 Installation

### Prerequisites

1. **n8n-mcp MCP server** installed and configured ([Installation Guide](https://github.com/czlonkowski/n8n-mcp))
2. **Claude Code**, Claude.ai, or Claude API access
3. `.mcp.json` configured with n8n-mcp server

### Claude Code

**Method 1: Plugin Installation** (Recommended)
```bash
# Install directly as a Claude Code plugin
/plugin install czlonkowski/n8n-skills
```

**Method 2: Via Marketplace**
```bash
# Add as marketplace, then browse and install
/plugin marketplace add czlonkowski/n8n-skills

# Then browse available plugins
/plugin install
# Select "n8n-mcp-skills" from the list
```

**Method 3: Manual Installation**
```bash
# 1. Clone this repository
git clone https://github.com/czlonkowski/n8n-skills.git

# 2. Copy skills to your Claude Code skills directory
cp -r n8n-skills/skills/* ~/.claude/skills/

# 3. Reload Claude Code
# Skills will activate automatically
```

### Claude.ai

1. Download individual skill folders from `skills/`
2. Zip each skill folder (or grab prebuilt zips from the [latest release](https://github.com/czlonkowski/n8n-skills/releases/latest))
3. Upload via Settings → Capabilities → Skills

### API / SDK

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed instructions.

---

## 💡 Usage

Skills activate **automatically** when relevant queries are detected:

```
"How do I write n8n expressions?"
→ Activates: n8n Expression Syntax

"Find me a Slack node"
→ Activates: n8n MCP Tools Expert

"Build a webhook workflow"
→ Activates: n8n Workflow Patterns

"Why is validation failing?"
→ Activates: n8n Validation Expert

"How do I configure the HTTP Request node?"
→ Activates: n8n Node Configuration

"How do I access webhook data in a Code node?"
→ Activates: n8n Code JavaScript

"Can I use pandas in Python Code node?"
→ Activates: n8n Code Python

"Why does my Code Tool throw 'Wrong output type returned'?"
→ Activates: n8n Code Tool
```

### Skills Work Together

When you ask: **"Build and validate a webhook to Slack workflow"**

1. **n8n Workflow Patterns** identifies webhook processing pattern
2. **n8n MCP Tools Expert** searches for webhook and Slack nodes
3. **n8n Node Configuration** guides node setup
4. **n8n Code JavaScript** helps process webhook data with proper .body access
5. **n8n Expression Syntax** helps with data mapping in other nodes
6. **n8n Validation Expert** validates the final workflow

All skills compose seamlessly!

---

## 📖 Documentation

- [Installation Guide](docs/INSTALLATION.md) - Detailed installation for all platforms
- [Usage Guide](docs/USAGE.md) - How to use skills effectively
- [Development Guide](docs/DEVELOPMENT.md) - Contributing and testing
- [MCP Testing Log](docs/MCP_TESTING_LOG.md) - Real tool responses used in skills

---


## 🧪 Testing

Each skill includes 3+ evaluations for quality assurance:

```bash
# Run evaluations (if testing framework available)
npm test

# Or manually test with Claude
claude-code --skill n8n-expression-syntax "Test webhook data access"
```

---

## 🤝 Contributing

Contributions welcome! Please see [DEVELOPMENT.md](docs/DEVELOPMENT.md) for guidelines.

### Development Approach

1. **Evaluation-First**: Write test scenarios before implementation
2. **MCP-Informed**: Test tools, document real responses
3. **Iterative**: Test against evaluations, iterate until 100% pass
4. **Concise**: Keep SKILL.md under 500 lines
5. **Real Examples**: All examples from real templates/tools

---

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

**Conceived by Romuald Członkowski**
- Website: [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
- Part of the [n8n-mcp project](https://github.com/czlonkowski/n8n-mcp)

The hooks enforcement layer adapts patterns from the official [n8n Skills](https://github.com/n8n-io/skills) project (Apache-2.0), retargeted for n8n-mcp and rewritten in our own voice. See [NOTICES](NOTICES).

---

## 🔗 Related Projects

- [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) - MCP server for n8n
- [n8n](https://n8n.io/) - Workflow automation platform

---

## 📊 What's Included

- **14** complementary skills that work together
- **525+** n8n nodes supported
- **2,653+** workflow templates for examples
- **10** production-tested Code node patterns
- **Comprehensive** error catalogs and troubleshooting guides

---

**Ready to build flawless n8n workflows? Get started now!** 🚀

---

## 💼 Need it built for you?

Work with **[AiAdvisors](https://www.aiadvisors.pl/en)** — automation audits, builds, and operations by the team behind n8n-mcp and n8n-skills.
