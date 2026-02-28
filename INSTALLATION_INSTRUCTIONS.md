# Installation Instructions - n8n Skills Complete Package

## 📦 What You Have

A complete package of **12 n8n Skills** (7 original + 5 new):

```
n8n-skills/
├── skills/
│   ├── n8n-expression-syntax/              [Original]
│   ├── n8n-mcp-tools-expert/               [Original]
│   ├── n8n-workflow-patterns/              [Original]
│   ├── n8n-validation-expert/              [Original]
│   ├── n8n-node-configuration/             [Original]
│   ├── n8n-code-javascript/                [Original]
│   ├── n8n-code-python/                    [Original]
│   ├── n8n-workflow-debugging/             [NEW - Debugging]
│   ├── n8n-advanced-patterns/              [NEW - Enterprise]
│   ├── n8n-performance-optimization/       [NEW - Speed]
│   ├── n8n-ai-agents/                      [NEW - AI]
│   └── n8n-webhook-advanced/               [NEW - Security]
├── SKILLS_OVERVIEW.md                      [Start here]
└── README.md                               [Project overview]
```

## 🚀 Installation Methods

### Method 1: Claude Code Plugin (Easiest)

```bash
/plugin install czlonkowski/n8n-skills
```

### Method 2: Manual Installation to Claude Code

```bash
# Copy all skills to Claude Code directory
cp -r n8n-skills/skills/* ~/.claude/skills/

# Restart Claude Code - skills will activate automatically
```

### Method 3: Claude Desktop Config

Add to `~/.claude/profiles/default/claude_desktop_config.json`:

```json
{
  "skills": {
    "n8n_skills": {
      "path": "/path/to/n8n-skills/skills"
    }
  }
}
```

### Method 4: Claude.ai Web

1. Download each skill folder individually
2. Zip each folder: `skill-name.zip`
3. Go to Settings → Capabilities → Skills
4. Upload each zip file

## 📖 Getting Started

### Quick Start (5 minutes)

1. **Read Overview**
   ```bash
   cat SKILLS_OVERVIEW.md
   ```

2. **Start with MCP Tools Expert** (Foundation)
   ```bash
   cat skills/n8n-mcp-tools-expert/SKILL.md
   ```

3. **Use in Claude**
   - Ask about n8n workflows
   - Skills activate automatically

### Learning Path

**Beginner (First Time)**:
1. Expression Syntax
2. Workflow Patterns
3. MCP Tools Expert
4. Validation Expert

**Intermediate**:
1. Workflow Debugging
2. Advanced Patterns
3. Code JavaScript

**Advanced**:
1. AI Agents
2. Performance Optimization
3. Webhook Advanced

## ✅ Verification

Skills are installed correctly if:

```bash
# Check skill files exist
ls -la ~/.claude/skills/n8n-*

# Each skill should have:
# - SKILL.md (main file)
# - README.md (overview)
# - Additional guide files
```

## 🔗 Integration Check

Skills work together seamlessly:
- ✅ MCP Tools Expert used by all
- ✅ Debugging integrates with Validation
- ✅ Advanced Patterns uses Code JavaScript
- ✅ All share best practices

## 📚 Skill Activation

Skills activate **automatically** when you ask relevant questions:

```
"How do I write n8n expressions?"
→ Activates: Expression Syntax

"Find me a Slack node"
→ Activates: MCP Tools Expert

"My workflow is failing"
→ Activates: Workflow Debugging

"How to optimize performance?"
→ Activates: Performance Optimization

"Secure my webhooks"
→ Activates: Webhook Advanced
```

## 🆘 Troubleshooting

### Skills Not Showing

```bash
# Verify they're in the right directory
ls ~/.claude/skills/ | grep n8n

# Check for typos in directory names
# Should be: n8n-workflow-debugging (not n8n_workflow_debugging)
```

### Skills Not Activating

```bash
# Restart Claude Code/Claude Desktop
# Clear cache if persistent

# Verify SKILL.md has correct frontmatter:
# ---
# name: skill-name
# description: What it does
# ---
```

### Missing Guide Files

Each skill includes:
- `SKILL.md` (Required)
- `README.md` (Overview)
- Additional guides (specific to skill)

All are already included! ✅

## 📞 Support

### For Each Skill:
- Read `SKILL.md` for comprehensive guide
- Check included markdown files for details
- Look for code examples
- Cross-references to other skills

### Resources:
- [n8n Documentation](https://docs.n8n.io)
- [n8n-mcp GitHub](https://github.com/czlonkowski/n8n-mcp)
- [n8n Community](https://community.n8n.io)

## 🎓 Using Skills Effectively

### Best Practices

1. **Start with MCP Tools Expert** - Foundation for all work
2. **Use Workflow Debugging** when stuck - Systematic approach
3. **Reference Patterns** before building - Don't reinvent
4. **Check Validation Expert** on errors - Comprehensive catalog
5. **Optimize with Performance** - Data-driven decisions

### Tips

✅ **Ask specific questions** - Activates relevant skills
✅ **Reference skill names** - "Using n8n Workflow Debugging skill..."
✅ **Provide context** - Include error messages, workflow details
✅ **Request code examples** - Skills include real-world examples
✅ **Cross-reference** - Skills link to each other

## 🎉 You're Ready!

All 12 skills are installed and ready to use:
- ✅ 7 original skills for core n8n work
- ✅ 5 new advanced skills for enterprise workflows
- ✅ 50+ comprehensive guides
- ✅ 100+ code examples
- ✅ Cross-skill integration

**Start building flawless n8n workflows!** 🚀

---

Next step: Read [SKILLS_OVERVIEW.md](SKILLS_OVERVIEW.md) for complete skill reference.
