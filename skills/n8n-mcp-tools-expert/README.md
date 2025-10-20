# n8n MCP Tools Expert

Expert guide for using n8n-mcp MCP tools effectively.

---

## Purpose

Teaches how to use n8n-mcp MCP server tools correctly, fixing the 20% failure rate when using tools incorrectly.

## Activates On

- search nodes
- find node
- validate
- MCP tools
- template
- workflow
- n8n-mcp
- tool selection

## File Count

5 files, ~1,150 lines total

## Priority

**HIGHEST** - Fixes 20% MCP tool failure rate

## Dependencies

**n8n-mcp tools**: All of them! (40+ tools)

**Related skills**:
- n8n Expression Syntax (write expressions for workflows)
- n8n Workflow Patterns (use tools to build patterns)
- n8n Validation Expert (interpret validation results)
- n8n Node Configuration (configure nodes found with tools)

## Coverage

### Core Topics
- Tool selection guide (which tool for which task)
- nodeType format differences (nodes-base.* vs n8n-nodes-base.*)
- Validation profiles (minimal/runtime/ai-friendly/strict)
- Smart parameters (branch, case for multi-output nodes)
- Auto-sanitization system
- Workflow management (15 operation types)
- AI connection types (8 types)

### Tool Categories
- Node Discovery (search, list, essentials, info)
- Configuration Validation (minimal, operation, workflow)
- Workflow Management (create, update, validate)
- Template Library (search, get)
- Documentation (tools, database stats)

## Evaluations

5 scenarios (100% coverage expected):
1. **eval-001**: Tool selection (search_nodes)
2. **eval-002**: nodeType format (nodes-base.* prefix)
3. **eval-003**: Validation workflow (profiles)
4. **eval-004**: essentials vs info (5KB vs 100KB)
5. **eval-005**: Smart parameters (branch, case)

## Key Features

✅ **Data-Driven**: Based on 447,557 real MCP tool events
✅ **Telemetry Insights**: Actual usage patterns (56s between edits, 18s between search/essentials)
✅ **Critical Mistakes**: Highlights 20% failure rate issues
✅ **Smart Parameters**: Teaches semantic branch/case routing
✅ **Auto-Sanitization**: Explains automatic fixes
✅ **Comprehensive**: Covers all 40+ tools

## Files

- **SKILL.md** (480 lines) - Core tool usage guide
- **SEARCH_GUIDE.md** (220 lines) - Node discovery tools
- **VALIDATION_GUIDE.md** (250 lines) - Validation tools and profiles
- **WORKFLOW_GUIDE.md** (200 lines) - Workflow management
- **README.md** (this file) - Skill metadata

## Success Metrics

**Expected outcomes**:
- Correct nodeType formats (nodes-base.* for search)
- get_node_essentials preferred over get_node_info
- Validation profiles used correctly
- Smart parameters for IF/Switch nodes
- 20% failure rate reduced to <5%

## Critical Insights

**From MCP Testing Log**:
- search → essentials: 9,835 occurrences, 18s avg
- validate → fix: 7,841 loops, 23s thinking, 58s fixing
- update_partial: 38,287 uses, 56s between edits
- get_node_info: 20% failure rate (use essentials!)

## Last Updated

2025-10-20

---

**Part of**: n8n-skills repository
**Conceived by**: Romuald Członkowski - [www.aiadvisors.pl/en](https://www.aiadvisors.pl/en)
