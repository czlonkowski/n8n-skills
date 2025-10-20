# Installation Guide

Complete installation instructions for n8n-skills across all platforms.

---

## Prerequisites

### 1. n8n-mcp MCP Server

You **must** have the n8n-mcp MCP server installed and configured before using these skills.

**Install n8n-mcp**:
```bash
npm install -g n8n-mcp
```

**Configure MCP server** in `.mcp.json`:
```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["n8n-mcp"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true",
        "N8N_API_URL": "https://your-n8n-instance.com",
        "N8N_API_KEY": "your-api-key-here"
      }
    }
  }
}
```

**Note**: `N8N_API_URL` and `N8N_API_KEY` are optional but enable workflow creation/management tools.

### 2. Claude Access

You need one of:
- **Claude Code** (desktop application)
- **Claude.ai** (web interface)
- **Claude API** (via SDK)

---

## Installation Methods

### Method 1: Claude Code (Recommended)

**Step 1**: Clone the repository
```bash
git clone https://github.com/czlonkowski/n8n-skills.git
cd n8n-skills
```

**Step 2**: Copy skills to Claude Code skills directory

**macOS/Linux**:
```bash
mkdir -p ~/.claude/skills
cp -r skills/* ~/.claude/skills/
```

**Windows**:
```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills"
Copy-Item -Recurse skills\* "$env:USERPROFILE\.claude\skills\"
```

**Step 3**: Verify installation
```bash
ls ~/.claude/skills/
# Should show: n8n-expression-syntax, n8n-mcp-tools-expert, etc.
```

**Step 4**: Reload Claude Code
- Restart Claude Code application
- Skills will activate automatically

---

### Method 2: Claude.ai (Web Interface)

**Step 1**: Download skill folders

Download the repository and navigate to `skills/` directory. You'll need to upload each skill individually.

**Step 2**: Zip each skill
```bash
cd skills
zip -r n8n-expression-syntax.zip n8n-expression-syntax/
zip -r n8n-mcp-tools-expert.zip n8n-mcp-tools-expert/
zip -r n8n-workflow-patterns.zip n8n-workflow-patterns/
zip -r n8n-validation-expert.zip n8n-validation-expert/
zip -r n8n-node-configuration.zip n8n-node-configuration/
```

**Step 3**: Upload to Claude.ai

1. Go to Claude.ai
2. Navigate to **Settings** → **Capabilities** → **Skills**
3. Click **Upload Skill**
4. Upload each `.zip` file individually
5. Confirm each upload

**Step 4**: Verify skills are active

In a new conversation, type:
```
"List my active skills"
```

You should see all 5 n8n skills listed.

---

### Method 3: Claude API / SDK

**Step 1**: Install via package manager

If you're building an application with Claude SDK:

```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

// Load skills from directory
const skillsDir = './skills';
const skills = loadSkillsFromDirectory(skillsDir);

const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  messages: [{
    role: 'user',
    content: 'Build a webhook to Slack workflow'
  }],
  skills: skills // Pass loaded skills
});
```

**Step 2**: Skill loading function

```typescript
import fs from 'fs';
import path from 'path';

function loadSkillsFromDirectory(dir: string) {
  const skillDirs = fs.readdirSync(dir);
  return skillDirs.map(skillName => {
    const skillPath = path.join(dir, skillName, 'SKILL.md');
    const skillContent = fs.readFileSync(skillPath, 'utf-8');

    return {
      name: skillName,
      content: skillContent
    };
  });
}
```

---

## Verification

### Test Installation

**1. Check MCP server availability**
```
Ask Claude: "Can you search for the webhook node using n8n-mcp?"
```

Expected response:
```
[Uses search_nodes tool]
Found: nodes-base.webhook (Webhook trigger node)
```

**2. Test skill activation**
```
Ask Claude: "How do I access webhook data in n8n expressions?"
```

Expected response:
```
[n8n Expression Syntax skill activates]
Webhook data is under $json.body...
```

**3. Test cross-skill composition**
```
Ask Claude: "Build and validate a webhook to Slack workflow"
```

Expected: All 5 skills should activate and work together.

---

## Troubleshooting

### Skills Not Activating

**Problem**: Skills don't activate when expected

**Solutions**:
1. Verify skills are in correct directory:
   - Claude Code: `~/.claude/skills/`
   - Check each skill has `SKILL.md` with frontmatter

2. Check SKILL.md frontmatter format:
   ```markdown
   ---
   name: n8n Expression Syntax
   description: Validate n8n expression syntax...
   ---
   ```

3. Reload Claude Code or clear cache

### MCP Tools Not Available

**Problem**: "n8n-mcp tools not available"

**Solutions**:
1. Verify `.mcp.json` is in correct location
2. Check n8n-mcp is installed: `npm list -g n8n-mcp`
3. Test MCP server: `npx n8n-mcp`
4. Restart Claude Code

### N8N API Tools Missing

**Problem**: "n8n_create_workflow not available"

**Solutions**:
1. Verify `N8N_API_URL` and `N8N_API_KEY` in `.mcp.json`
2. Test API access: `curl -H "X-N8N-API-KEY: your-key" https://your-n8n-instance/api/v1/workflows`
3. Skills will still work with read-only tools (search, validate, templates)

### Permission Issues

**Problem**: Cannot write to skills directory

**macOS/Linux**:
```bash
sudo chown -R $USER ~/.claude
chmod -R 755 ~/.claude/skills
```

**Windows**: Run PowerShell as Administrator

---

## Uninstallation

### Remove All Skills

**Claude Code**:
```bash
rm -rf ~/.claude/skills/n8n-*
```

**Claude.ai**:
1. Go to Settings → Capabilities → Skills
2. Delete each n8n skill individually

### Remove Specific Skill

```bash
rm -rf ~/.claude/skills/n8n-expression-syntax
```

---

## Updating

### Update All Skills

```bash
cd n8n-skills
git pull origin main
cp -r skills/* ~/.claude/skills/
```

### Update Single Skill

```bash
cp -r skills/n8n-expression-syntax ~/.claude/skills/
```

---

## Advanced Configuration

### Custom Skill Location

If using custom skills directory:

```bash
# Set environment variable
export CLAUDE_SKILLS_DIR="/path/to/custom/skills"

# Copy skills
cp -r skills/* $CLAUDE_SKILLS_DIR/
```

### Selective Installation

Install only specific skills:

```bash
# Only expression syntax and MCP tools expert
cp -r skills/n8n-expression-syntax ~/.claude/skills/
cp -r skills/n8n-mcp-tools-expert ~/.claude/skills/
```

---

## Next Steps

✅ Installation complete? Continue to [USAGE.md](USAGE.md) for usage examples.

---

## Support

- **Issues**: https://github.com/czlonkowski/n8n-skills/issues
- **Discussions**: https://github.com/czlonkowski/n8n-skills/discussions
- **n8n-mcp**: https://github.com/romualdczlonkowski/n8n-mcp

---

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
