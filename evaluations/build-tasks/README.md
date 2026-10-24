# Build-task evals

The other folders under `evaluations/` are single-turn Q&A checks. These are build tasks: an agent builds a workflow
with the pack loaded, and a script scores the workflow JSON it produced — which node types it picked, whether the
pagination option is capped, whether kept Code / HTTP Request nodes carry their `Why Code:` / `Why HTTP:` note, and
whether every node is wired to the trigger.

| Case | Expects |
|---|---|
| `build-001-computed-fields` | Edit Fields computes values two nodes read; no Code; ≤ 6 nodes |
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
evaluations/build-tasks/run.sh --ref main            # the same against main, for a baseline
evaluations/build-tasks/run.sh --runs 1 cases/build-004-service-node.json   # one smoke run
```

Compare a branch against `--ref main` on the same model: a pass rate without a baseline says little. Results land in
`evaluations/build-tasks/results/<timestamp>/` (gitignored): per run the prompt, the transcript, stderr, the
`workflow.json` and `score.json`.

The runner loads the plugin only from `--plugin-dir`, skips user settings and installed plugins, and gives the agent
n8n-mcp in docs-only mode (no instance), so nothing is deployed. Requires the Claude Code CLI (signed in), `npx`,
`python3`, `git` and `perl`.

The structural checks are a regression signal, not proof that a workflow works: they can't see whether an expression
computes the right value. Read a few `workflow.json` files when a pass rate moves.
