# n8n-mcp Skills - Distribution Packages

This folder contains distribution packages for different Claude platforms.

## 📦 Available Packages

### For Claude.ai Users (Individual Skills)

Upload each skill separately via Settings → Features → Skills:

- `n8n-expression-syntax-v1.0.0.zip` - n8n expression syntax and common patterns
- `n8n-mcp-tools-expert-v1.0.0.zip` - Expert guide for using n8n-mcp tools (recommended to install first)
- `n8n-workflow-patterns-v1.0.0.zip` - 5 proven workflow architectural patterns
- `n8n-validation-expert-v1.0.0.zip` - Validation error interpretation and fixing
- `n8n-node-configuration-v1.0.0.zip` - Operation-aware node configuration

**Installation:**
1. Go to Settings → Features → Skills
2. Click "Upload Skill"
3. Select one of the skill zip files above
4. Repeat for each skill you want to install

**Note:** Each skill can be installed independently. Install all 5 for the complete experience!

### For Claude Code Users (Bundle)

- `n8n-mcp-skills-claude-code-v1.0.0.zip` - Complete bundle with all 5 skills

**Installation:**

Option 1 - Manual Installation:
```bash
# 1. Download the bundle
# 2. Extract the zip file
unzip n8n-mcp-skills-claude-code-v1.0.0.zip

# 3. Copy skills to your Claude Code skills directory
cp -r skills/* ~/.claude/skills/

# 4. Reload Claude Code
```

Option 2 - Plugin Installation (if supported):
```bash
# Install as a Claude Code plugin
claude-code install n8n-mcp-skills-claude-code-v1.0.0.zip
```

## 🎯 Which Package Should I Use?

| Platform | Package | Skills |
|----------|---------|--------|
| **Claude.ai** | Individual zips | Upload each skill separately (5 uploads) |
| **Claude Code** | Bundle zip | Install all 5 skills at once |
| **Claude API** | Bundle zip | Extract and use skills/ folder |

## 📋 What's Included in Each Package

### Individual Skill Packages (Claude.ai)

Each zip contains:
```
SKILL.md              # Main skill instructions with YAML frontmatter
[Reference files]     # Additional documentation and guides
README.md             # Skill metadata and statistics
```

### Bundle Package (Claude Code)

```
plugin.json           # Claude Code plugin metadata
README.md             # Project overview and documentation
LICENSE               # MIT License
skills/               # All 5 skills in subfolders
  ├── n8n-expression-syntax/
  ├── n8n-mcp-tools-expert/
  ├── n8n-workflow-patterns/
  ├── n8n-validation-expert/
  └── n8n-node-configuration/
```

## ✅ Verification

After installation, test skills by asking:

```
"How do I write n8n expressions?"
→ Should activate: n8n Expression Syntax

"Find me a Slack node"
→ Should activate: n8n MCP Tools Expert

"Build a webhook workflow"
→ Should activate: n8n Workflow Patterns
```

## 🔧 Requirements

- **n8n-mcp MCP server** installed and configured ([Installation Guide](https://github.com/czlonkowski/n8n-mcp))
- **Claude Pro, Max, Team, or Enterprise** plan (for Claude.ai skills)
- **.mcp.json** configured with n8n-mcp server

## 📖 Documentation

For detailed installation instructions, see:
- Main README: `../README.md`
- Installation Guide: `../docs/INSTALLATION.md`
- Usage Guide: `../docs/USAGE.md`

## 🐛 Troubleshooting

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

## 📝 License

MIT License - see `../LICENSE` file

## 🙏 Credits

Conceived by Romuald Członkowski - https://www.aiadvisors.pl/en

Part of the [n8n-mcp project](https://github.com/czlonkowski/n8n-mcp).
