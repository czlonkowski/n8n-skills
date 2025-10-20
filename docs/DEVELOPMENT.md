# Development Guide

Guidelines for contributing to n8n-skills and developing new skills.

---

## Development Philosophy

### 1. Evaluation-Driven Development (EDD)

Write tests **before** writing skills!

**Process**:
```
1. Create 3+ evaluation scenarios
2. Test baseline (without skill)
3. Write minimal SKILL.md
4. Test against evaluations
5. Iterate until 100% pass
6. Add reference files as needed
```

**Why**: Ensures skills solve real problems and can be tested objectively.

### 2. MCP-Informed Content

All content based on **real MCP tool responses**, not assumptions.

**Process**:
```
1. Test MCP tools thoroughly
2. Document actual responses
3. Use real examples in skills
4. Verify all code snippets work
```

**See**: [MCP_TESTING_LOG.md](MCP_TESTING_LOG.md) for reference data.

### 3. Keep Skills Concise

**Guideline**: SKILL.md should be under 500 lines

**Why**: Longer skills are harder to maintain and slower to load.

**Solution**: Split complex content into reference files:
- SKILL.md: Core concepts and quick reference
- REFERENCE_*.md: Detailed information
- EXAMPLES.md: Working examples

### 4. Real Examples Only

**Never** invent examples. Always use:
- Real templates from n8n-mcp
- Actual MCP tool responses
- Verified node configurations

---

## Repository Structure

```
n8n-skills/
├── skills/                    # Skill implementations
│   ├── n8n-expression-syntax/
│   │   ├── SKILL.md          # Main skill content (< 500 lines)
│   │   ├── COMMON_MISTAKES.md
│   │   ├── EXAMPLES.md
│   │   └── README.md         # Skill metadata
│   └── ...
├── evaluations/               # Test scenarios
│   ├── expression-syntax/
│   │   ├── eval-001-*.json
│   │   └── ...
│   └── ...
├── docs/                      # Documentation
│   ├── INSTALLATION.md
│   ├── USAGE.md
│   ├── DEVELOPMENT.md (this file)
│   └── MCP_TESTING_LOG.md    # Real MCP responses
├── README.md                  # Project overview
├── LICENSE                    # MIT License
└── .gitignore
```

---

## Creating a New Skill

### Step 1: Define Scope

**Questions to answer**:
- What problem does this skill solve?
- When should it activate?
- What MCP tools will it teach?
- What are 3 key examples?

**Document in**: `skills/[skill-name]/README.md`

### Step 2: Create Evaluations

**Create**: `evaluations/[skill-name]/eval-001-description.json`

**Format**:
```json
{
  "id": "skill-001",
  "skills": ["skill-name"],
  "query": "User question or scenario",
  "expected_behavior": [
    "Skill should identify X",
    "Skill should provide Y guidance",
    "Skill should reference Z content"
  ],
  "baseline_without_skill": {
    "likely_response": "Generic answer",
    "expected_quality": "Low"
  },
  "with_skill_expected": {
    "response_quality": "High",
    "uses_skill_content": true,
    "provides_correct_guidance": true
  }
}
```

**Create at least 3 evaluations** covering:
1. Basic usage
2. Common mistake
3. Advanced scenario

### Step 3: Test MCP Tools

**Document tool responses** in `docs/MCP_TESTING_LOG.md`:

```markdown
## [Your Skill Name] - MCP Testing

### Tool: tool_name

**Test**:
```javascript
tool_name({param: "value"})
```

**Response**:
```json
{actual response}
```

**Key Insights**:
- Finding 1
- Finding 2
```

### Step 4: Write SKILL.md

**Required frontmatter**:
```markdown
---
name: Skill Name
description: When to use this skill. Use when [trigger conditions].
---
```

**Recommended structure**:
```markdown
# Skill Name

## Quick Reference
[Table or list of most common patterns]

## Core Concepts
[Essential knowledge]

## Common Patterns
[Real examples with code]

## Common Mistakes
[Errors and fixes]

## Advanced Topics
[Link to reference files]

## Related Skills
[Cross-references]
```

**Guidelines**:
- Under 500 lines for SKILL.md
- Use real examples from MCP testing
- Include quick fixes table
- Link to reference files
- Cross-reference other skills

### Step 5: Add Reference Files

Create as needed:
- `COMMON_MISTAKES.md` - Error catalog
- `EXAMPLES.md` - Working examples
- `PATTERNS.md` - Common patterns
- `ADVANCED.md` - Deep dive topics

**Each file**:
- Should be focused on one topic
- Under 200 lines
- Real examples only
- Cross-linked from SKILL.md

### Step 6: Test Against Evaluations

**Process**:
1. Run evaluation scenarios with Claude
2. Check if expected behaviors occur
3. Document results
4. Iterate SKILL.md if needed
5. Repeat until 100% pass

**Success criteria**:
- All evaluations pass
- Skill activates correctly
- Content is accurate
- Examples work

### Step 7: Document Metadata

**Create**: `skills/[skill-name]/README.md`

```markdown
# Skill Name

**Purpose**: One-sentence description

**Activates on**: keyword1, keyword2, keyword3

**File Count**: X files, ~Y lines

**Dependencies**:
- n8n-mcp tools: tool1, tool2
- Other skills: skill1, skill2

**Coverage**:
- Topic 1
- Topic 2
- Topic 3

**Evaluations**: X scenarios (X% pass rate)

**Last Updated**: YYYY-MM-DD
```

---

## Evaluation Guidelines

### Good Evaluations

**Characteristics**:
- Specific, measurable expected behavior
- Based on real user queries
- Cover common and edge cases
- Include baseline comparison

**Example**:
```json
{
  "id": "expr-001",
  "query": "Why is {{$json.email}} undefined in my webhook workflow?",
  "expected_behavior": [
    "Identifies webhook data structure issue",
    "Explains data is under $json.body",
    "Provides corrected expression: {{$json.body.email}}",
    "References webhook structure documentation"
  ]
}
```

### Bad Evaluations

**Avoid**:
- Vague expected behaviors
- Unrealistic scenarios
- No baseline comparison
- Too simple or too complex

---

## Testing

### Manual Testing

```
1. Start Claude Code
2. Load skill
3. Ask evaluation query
4. Verify expected behaviors
5. Document results
```

### Automated Testing

*Coming soon: Evaluation framework*

---

## MCP Tool Testing Guidelines

### Before Writing Skills

**Test these tools**:
```javascript
// Node discovery
search_nodes({query: "keyword"})
list_nodes({category: "trigger"})
get_node_essentials({nodeType: "nodes-base.webhook"})

// Validation
validate_node_minimal({nodeType: "nodes-base.slack", config: {}})
validate_node_operation({nodeType: "nodes-base.slack", config: {...}, profile: "runtime"})

// Templates
search_templates({query: "webhook"})
get_template({templateId: 2947, mode: "structure"})

// Workflow management (if API available)
n8n_create_workflow({...})
n8n_update_partial_workflow({...})
n8n_validate_workflow({...})
```

### Document Findings

**In MCP_TESTING_LOG.md**:
- Actual responses
- Performance (timing)
- Gotchas discovered
- Format differences
- Error messages

### Use Real Data

**Extract from tools**:
- Node structures
- Template examples
- Validation errors
- Property dependencies

**Use in skills**:
- Real node configurations
- Actual error messages
- Working template IDs
- Proven patterns

---

## Code Standards

### Markdown

**Formatting**:
```markdown
# H1 - Skill Title
## H2 - Major Sections
### H3 - Subsections

**Bold** for emphasis
`code` for inline code
\`\`\`language for code blocks
```

**Code blocks**:
```javascript
// Always specify language
// Include comments
// Use real, working examples
```

### JSON (Evaluations)

**Format**:
```json
{
  "id": "kebab-case-id",
  "skills": ["exact-skill-name"],
  "query": "Natural user question",
  "expected_behavior": [
    "Specific measurable behavior"
  ]
}
```

---

## Git Workflow

### Branching

```bash
# Feature branch
git checkout -b skill/skill-name

# Bug fix
git checkout -b fix/issue-description
```

### Commits

**Format**:
```
type(scope): brief description

Longer description if needed.

Refs: #issue-number
```

**Types**:
- `feat`: New skill or feature
- `fix`: Bug fix
- `docs`: Documentation
- `test`: Evaluations
- `refactor`: Code improvement

**Examples**:
```
feat(expression-syntax): add webhook data structure guide
fix(mcp-tools): correct nodeType format examples
docs(usage): add cross-skill composition examples
test(validation): add auto-sanitization evaluation
```

### Pull Requests

**Include**:
- Description of changes
- Evaluation results (if new skill)
- MCP testing performed
- Documentation updated

**Template**:
```markdown
## Description
[What changed and why]

## Evaluations
- [ ] eval-001: PASS
- [ ] eval-002: PASS
- [ ] eval-003: PASS

## MCP Testing
- Tested tools: [list]
- New findings: [list]

## Documentation
- [ ] SKILL.md updated
- [ ] README.md updated
- [ ] MCP_TESTING_LOG.md updated

## Checklist
- [ ] SKILL.md under 500 lines
- [ ] Real examples only
- [ ] All evaluations pass
- [ ] Cross-references added
```

---

## File Naming Conventions

### Skills

```
skills/skill-name/
  SKILL.md              # Main content
  COMMON_MISTAKES.md    # Error catalog
  EXAMPLES.md           # Working examples
  README.md             # Metadata
  [optional files].md   # Additional references
```

### Evaluations

```
evaluations/skill-name/
  eval-001-short-description.json
  eval-002-short-description.json
  eval-003-short-description.json
```

**Naming**: `eval-NNN-kebab-case-description.json`

---

## Documentation Standards

### SKILL.md Frontmatter

**Required**:
```yaml
---
name: Exact Skill Name
description: When this skill activates. Use when [triggers]. Include specific keywords.
---
```

### Cross-References

**Link to**:
- Related skills
- Reference files
- MCP tool documentation
- Real templates

**Format**:
```markdown
See [n8n MCP Tools Expert](../n8n-mcp-tools-expert/SKILL.md)
See [COMMON_MISTAKES.md](COMMON_MISTAKES.md)
See template #2947 for example
```

---

## Quality Checklist

Before submitting a skill:

### Content Quality
- [ ] All examples tested with real MCP tools
- [ ] No invented/fake examples
- [ ] SKILL.md under 500 lines
- [ ] Clear, actionable guidance
- [ ] Real error messages included

### Testing
- [ ] 3+ evaluations created
- [ ] All evaluations pass
- [ ] Baseline comparison documented
- [ ] Cross-skill integration tested

### Documentation
- [ ] Frontmatter correct
- [ ] README.md metadata complete
- [ ] MCP_TESTING_LOG.md updated
- [ ] Cross-references added
- [ ] Examples documented

### Code Standards
- [ ] Markdown properly formatted
- [ ] Code blocks have language specified
- [ ] Consistent naming conventions
- [ ] Proper git commits

---

## Common Pitfalls

### ❌ Don't

- Invent examples or data
- Exceed 500 lines in SKILL.md
- Skip MCP tool testing
- Write skills without evaluations
- Use generic error messages
- Assume tool behavior

### ✅ Do

- Test tools and document responses
- Use real templates and configurations
- Write evaluations first
- Keep skills concise
- Cross-reference related skills
- Verify all code works

---

## Release Process

### Version Numbering

**Format**: `MAJOR.MINOR.PATCH`

- **MAJOR**: New skills added
- **MINOR**: Skill improvements
- **PATCH**: Bug fixes, typos

### Changelog

Update `CHANGELOG.md`:
```markdown
## [1.1.0] - 2025-10-20

### Added
- New skill: n8n Expression Syntax
- 3 evaluations for expression syntax

### Changed
- Improved MCP Tools Expert validation guidance

### Fixed
- Corrected nodeType format in examples
```

---

## Support

### Getting Help

- **Issues**: https://github.com/czlonkowski/n8n-skills/issues
- **Discussions**: https://github.com/czlonkowski/n8n-skills/discussions
- **n8n-mcp**: https://github.com/romualdczlonkowski/n8n-mcp

### Reporting Bugs

**Include**:
- Skill name and version
- Evaluation that fails
- Expected vs actual behavior
- MCP tool versions

---

## License

All contributions must be compatible with MIT License.

---

**Happy developing!** 🚀

---

Conceived by Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
