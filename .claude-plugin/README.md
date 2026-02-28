# n8n-mcp-skills Plugin Configuration

This directory contains the Claude Code plugin configuration for the n8n-mcp-skills package.

## Files

### `marketplace.json`
Defines the plugin distribution metadata following Anthropic's marketplace schema. Includes:
- **12 skills** (7 core + 5 advanced)
- **Activation triggers** in description fields
- **Cross-skill integration** references
- **Anthropic-compatible** format

**Skills Included**:
1. **Core Skills** (Original 7)
   - `n8n-expression-syntax` - Expression patterns
   - `n8n-mcp-tools-expert` - MCP server usage
   - `n8n-workflow-patterns` - Architectural patterns
   - `n8n-validation-expert` - Error resolution
   - `n8n-node-configuration` - Node setup
   - `n8n-code-javascript` - JavaScript implementation
   - `n8n-code-python` - Python implementation

2. **Advanced Skills** (New)
   - `n8n-workflow-debugging` - Failure diagnosis
   - `n8n-advanced-patterns` - Enterprise patterns
   - `n8n-performance-optimization` - Speed optimization
   - `n8n-ai-agents` - AI agent architecture
   - `n8n-webhook-advanced` - Webhook security

### `plugin.json`
Lightweight plugin manifest for Claude Code and Claude.ai integration. Contains:
- Plugin name and version
- Author information
- Keywords for discovery
- Engine requirements

## Installation Methods

### 1. Claude Code (Recommended)
```bash
/plugin install czlonkowski/n8n-skills
```

### 2. Manual Installation
```bash
# Copy skills to Claude Code directory
cp -r ../skills/* ~/.claude/skills/

# Restart Claude Code
```

### 3. Claude.ai Web
1. Download each skill folder individually
2. Zip each folder: `skill-name.zip`
3. Go to Settings → Capabilities → Skills
4. Upload each zip file

### 4. Claude Desktop Config
Add to `~/.claude/profiles/default/claude_desktop_config.json`:
```json
{
  "plugins": {
    "n8n-mcp-skills": {
      "path": "/path/to/n8n-skills"
    }
  }
}
```

## Schema Compliance

✅ **Anthropic Standards**:
- Follows `marketplace.schema.json` format
- YAML frontmatter in each SKILL.md file
- Kebab-case naming convention
- Comprehensive activation triggers

✅ **Enhanced Features**:
- 12 skills (exceeds baseline requirement)
- 100+ code examples
- 50+ guide files
- Cross-skill integration
- Enterprise-grade documentation

## Version History

- **2.0.0** - Expanded to 12 skills (7 core + 5 advanced)
- **1.1.0** - Enhanced documentation
- **1.0.0** - Initial release (7 core skills)

## License

MIT License - See LICENSE file in repository root

## Support

For detailed skill information, see:
- `../SKILLS_OVERVIEW.md` - Complete skill reference
- `../INSTALLATION_INSTRUCTIONS.md` - Installation guide
- `../skills/[skill-name]/SKILL.md` - Individual skill documentation

---

**Conceived by** Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)

Part of the [n8n-mcp](https://github.com/czlonkowski/n8n-mcp) project.
