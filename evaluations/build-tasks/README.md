# Build-task evals

The other folders under `evaluations/` are single-turn Q&A checks. These are build tasks: an agent builds a workflow
with the pack loaded, and a script scores the workflow JSON it produced — which node types it picked, whether the
pagination option is capped, whether kept Code / HTTP Request nodes carry their `Why Code:` / `Why HTTP:` note, and
whether every node is wired to the trigger.

| Case | Expects |
|---|---|
| `build-001-computed-fields` | One Edit Fields node computes values three independent nodes read (subtotal computed once); no Code; ≤ 7 nodes |
| `build-002-xml-api` | XML node parses the response; Slack node posts; HTTP Request has a `Why HTTP:` note; no Code |
| `build-003-paginated-api` | HTTP Request pagination option with a page cap; no Code, no Loop Over Items |
| `build-004-service-node` | Slack node, no HTTP Request, no Set that only re-maps; ≤ 4 nodes |
| `build-005-recursive-tree` | **Code is right here** (arbitrary-depth recursion), with a `Why Code:` note — catches overcorrection |

## Score one workflow

```bash
python3 evaluations/build-tasks/score.py evaluations/build-tasks/cases/build-003-paginated-api.json path/to/workflow.json
```

Exit code 0 = all assertions pass, 1 = some fail, 2 = no readable workflow. Assertion types are documented at the top
of `score.py`.

## Run the suite

Every run is a real, billed agent session, so the suite is run by hand, never in CI. Each run is capped by
`--budget` (USD) and `--timeout` (seconds), and failures are recorded, not retried.

```bash
evaluations/build-tasks/run.sh                       # all cases, 3 runs each, plugin from the working tree
evaluations/build-tasks/run.sh --ref main            # the same against main, for a baseline (on a branch)
evaluations/build-tasks/run.sh --runs 1 cases/build-004-service-node.json   # one smoke run
```

Compare against a baseline on the same model: a pass rate alone says little. On a branch, `--ref main`; after a
change has merged, `--ref <the commit before it>`. Results land in `evaluations/build-tasks/results/<timestamp>/`
(gitignored): per run the prompt, the event stream (`transcript.jsonl`), stderr, the `workflow.json`, `run.json` (what
loaded, cost, permission denials) and `score.json`.

Isolation, so the two arms differ only in the plugin:

- Each agent works in a fresh temp directory outside any repository. Running inside this repo would load its own
  `CLAUDE.md`, `.claude/settings.local.json` and `.claude/skills/`, which contaminates both arms.
- The plugin loads only from `--plugin-dir`; user settings and installed plugins are skipped.
- n8n-mcp runs in docs-only mode (no instance, nothing deployed), pinned to one version per invocation: the latest on
  npm, or `N8N_MCP_VERSION=2.97.0`. Pin the same version for both arms.

A run where the plugin or n8n-mcp didn't load, Write was denied, or the session errored is reported as `INFRA` and left
out of the pass rate. Requires the Claude Code CLI (signed in), `npm`/`npx`, `python3`, `git` and `perl`.

The structural checks are a regression signal, not proof that a workflow works: they can't see whether an expression
computes the right value. Read a few `workflow.json` files when a pass rate moves.
