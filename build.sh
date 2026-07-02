#!/bin/bash
# Build script for n8n-skills distribution packages
# Creates zip files for both Claude.ai (individual skills) and Claude Code (bundle)

set -e

DIST_DIR="dist"
VERSION="1.21.1"

echo "🔨 Building n8n-skills distribution packages..."

# Create dist directory if it doesn't exist
mkdir -p "$DIST_DIR"

# Remove old zips
echo "🗑️  Removing old zip files..."
rm -f "$DIST_DIR"/*.zip

# Build individual skill zips (for Claude.ai)
# Structure: skill-name/SKILL.md at zip root (not nested under skills/)
echo "📦 Building individual skill zips for Claude.ai..."

SKILLS=(
    "n8n-expression-syntax"
    "n8n-mcp-tools-expert"
    "n8n-workflow-patterns"
    "n8n-validation-expert"
    "n8n-node-configuration"
    "n8n-code-javascript"
    "n8n-code-python"
    "n8n-code-tool"
    "n8n-error-handling"
    "n8n-binary-and-data"
    "n8n-subworkflows"
    "n8n-agents"
    "n8n-multi-instance"
    "n8n-self-hosting"
    "using-n8n-mcp-skills"
)

for skill in "${SKILLS[@]}"; do
    echo "   - $skill"
    (cd skills && zip -rq "../$DIST_DIR/${skill}-v${VERSION}.zip" "${skill}/" -x "*.DS_Store")
done

# Build complete bundle (for Claude Code)
echo "📦 Building complete bundle for Claude Code..."
zip -rq "$DIST_DIR/n8n-mcp-skills-v${VERSION}.zip" \
    .claude-plugin/ \
    hooks/ \
    README.md \
    LICENSE \
    NOTICES \
    NOTICES-APACHE-2.0.txt \
    skills/ \
    -x "*.DS_Store" -x "*-workspace/*" -x "*-workspace/"

# Show results
echo ""
echo "✅ Build complete! Files in $DIST_DIR/:"
echo ""
ls -lh "$DIST_DIR"/*.zip
echo ""
echo "📊 Package sizes:"
du -h "$DIST_DIR"/*.zip
