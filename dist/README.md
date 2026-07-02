# n8n-mcp Skills - Distribution Packages

This folder contains distribution packages for different Claude platforms.

## Available Packages

### For Claude.ai / Claude Desktop (Individual Skills)

Upload each skill separately via Settings > Capabilities > Skills (bottom of page):

- `n8n-expression-syntax-v1.21.1.zip` - n8n expression syntax and common patterns
- `n8n-mcp-tools-expert-v1.21.1.zip` - Expert guide for using n8n-mcp tools (recommended to install first)
- `n8n-workflow-patterns-v1.21.1.zip` - Proven workflow architectural patterns
- `n8n-validation-expert-v1.21.1.zip` - Validation error interpretation and fixing
- `n8n-node-configuration-v1.21.1.zip` - Operation-aware node configuration
- `n8n-code-javascript-v1.21.1.zip` - JavaScript in n8n Code nodes
- `n8n-code-python-v1.21.1.zip` - Python in n8n Code nodes
- `n8n-code-tool-v1.21.1.zip` - Code for the AI-agent Custom Code Tool
- `n8n-error-handling-v1.21.1.zip` - Production error handling (per-node error outputs, retries, Error Trigger)
- `n8n-binary-and-data-v1.21.1.zip` - Binary and file data handling
- `n8n-subworkflows-v1.21.1.zip` - Reusable, composable sub-workflows
- `n8n-agents-v1.21.1.zip` - AI agent design (Agent vs chain vs classifier, tools, memory)
- `n8n-multi-instance-v1.21.1.zip` - Targeting the right n8n instance on multi-instance accounts (switch/verify, credential safety)
- `n8n-self-hosting-v1.21.1.zip` - Deploy self-hosted n8n to a VM (Docker Compose + Caddy auto-TLS, single or queue mode, Day-2)
- `using-n8n-mcp-skills-v1.21.1.zip` - Always-on router skill (best in the Claude Code bundle, where the SessionStart hook loads it automatically)

**Installation:**
1. Go to Settings > Capabilities > Skills (bottom of page)
2. Click "Upload Skill"
3. Select one of the skill zip files above
4. Repeat for each skill you want to install

### Complete Bundle (Claude Code only)

- **`n8n-mcp-skills-v1.21.1.zip`** - All 14 skills + the always-on router and the hooks enforcement layer, in one package

> **This bundle is NOT compatible with Claude.ai or Claude Desktop.** It uses a nested `skills/` directory structure required by Claude Code plugins, and ships hooks that only run under the Claude Code / Codex plugin install. For Claude.ai/Desktop, use the individual skill zips above.

**Installation:**
```bash
# Claude Code plugin installation
/plugin install czlonkowski/n8n-skills

# Or install from local file
/plugin install /path/to/n8n-mcp-skills-v1.21.1.zip
```

## Which Package Should I Use?

| Platform | Package | What You Get |
|----------|---------|--------------|
| **Claude.ai / Desktop** | Individual zips | Upload each skill separately (the router/hooks layer won't run) |
| **Claude Code** | Complete bundle OR individual zips | All 14 skills + router + hooks enforcement layer |
| **Claude API** | Complete bundle | All 14 skills (extract the `skills/` folder) |

---

## Files in This Directory

```
dist/
├── n8n-agents-v1.21.1.zip
├── n8n-binary-and-data-v1.21.1.zip
├── n8n-code-javascript-v1.21.1.zip
├── n8n-code-python-v1.21.1.zip
├── n8n-code-tool-v1.21.1.zip
├── n8n-error-handling-v1.21.1.zip
├── n8n-expression-syntax-v1.21.1.zip
├── n8n-mcp-skills-v1.21.1.zip             Claude Code only (bundle)
├── n8n-mcp-tools-expert-v1.21.1.zip
├── n8n-multi-instance-v1.21.1.zip
├── n8n-node-configuration-v1.21.1.zip
├── n8n-self-hosting-v1.21.1.zip
├── n8n-subworkflows-v1.21.1.zip
├── n8n-validation-expert-v1.21.1.zip
├── n8n-workflow-patterns-v1.21.1.zip
├── using-n8n-mcp-skills-v1.21.1.zip
└── README.md                              (this file)
```

---

## What's Included in Each Package

### Individual Skill Packages (Claude.ai / Desktop / Code)

Each zip contains a skill folder at the root with:
```
<skill-name>/
├── SKILL.md              # Main skill instructions with YAML frontmatter
├── [Reference files]     # Additional documentation and guides
└── README.md             # Skill metadata and statistics
```

### Bundle Package (Claude Code only)

```
.claude-plugin/
  ├── plugin.json      # Claude Code plugin metadata
  └── marketplace.json # Marketplace listing metadata
hooks/                 # SessionStart / PreToolUse / PostToolUse enforcement layer
README.md              # Project overview and documentation
LICENSE                # MIT License
NOTICES                # Attribution for adapted material
NOTICES-APACHE-2.0.txt # Apache-2.0 attribution
skills/                # All 14 skills + the router, in subfolders
  ├── n8n-expression-syntax/
  ├── n8n-mcp-tools-expert/
  ├── n8n-workflow-patterns/
  ├── n8n-validation-expert/
  ├── n8n-node-configuration/
  ├── n8n-code-javascript/
  ├── n8n-code-python/
  ├── n8n-code-tool/
  ├── n8n-error-handling/
  ├── n8n-binary-and-data/
  ├── n8n-subworkflows/
  ├── n8n-agents/
  ├── n8n-multi-instance/
  ├── n8n-self-hosting/
  └── using-n8n-mcp-skills/
```

## Verification

After installation, test skills by asking:

```
"How do I write n8n expressions?"
  -> Should activate: n8n Expression Syntax

"Find me a Slack node"
  -> Should activate: n8n MCP Tools Expert

"Build a webhook workflow"
  -> Should activate: n8n Workflow Patterns

"How do I access webhook data in a Code node?"
  -> Should activate: n8n Code JavaScript

"Can I use pandas in Python Code node?"
  -> Should activate: n8n Code Python
```

## Requirements

- **n8n-mcp MCP server** installed and configured ([Installation Guide](https://github.com/czlonkowski/n8n-mcp))
- **Claude Pro, Max, Team, or Enterprise** plan (for Claude.ai skills)
- **.mcp.json** configured with n8n-mcp server

## Documentation

For detailed installation instructions, see:
- Main README: `../README.md`
- Installation Guide: `../docs/INSTALLATION.md`
- Usage Guide: `../docs/USAGE.md`

## Troubleshooting

**Claude.ai Error: "Zip must contain exactly one SKILL.md file"**
- Use the individual skill zips, not the bundle
- Each skill must be uploaded separately

**Claude Code: Skills not activating**
- Verify skills are in `~/.claude/skills/` directory
- Check that n8n-mcp MCP server is running
- Reload Claude Code

**Skills not triggering**
- Skills activate based on keywords in your queries
- Try more specific questions matching skill descriptions
- Check that SKILL.md files have correct frontmatter

## License

MIT License - see `../LICENSE` file

## Credits

Conceived by Romuald Czlonkowski - https://www.aiadvisors.pl/en

Part of the [n8n-mcp project](https://github.com/czlonkowski/n8n-mcp).
