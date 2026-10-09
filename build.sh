#!/bin/bash
# Build script for n8n-skills distribution packages
# Creates zip files for both Claude.ai (individual skills) and Claude Code (bundle)

set -e

DIST_DIR="dist"

# Read the version from the manifests rather than hardcoding it here — a stale
# constant silently mislabels every zip.
read_version() {
    grep -m1 '"version"' "$1" | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
}

VERSION=$(read_version .claude-plugin/plugin.json)
AGENT_PLUGIN_VERSION=$(read_version plugin.json)

if [ -z "$VERSION" ]; then
    echo "❌ Could not read version from .claude-plugin/plugin.json"
    exit 1
fi

if [ -z "$AGENT_PLUGIN_VERSION" ]; then
    echo "❌ Could not read version from plugin.json"
    exit 1
fi

# The pack carries two manifests for two ecosystems. They describe the same
# artifact, so they must never disagree.
if [ "$VERSION" != "$AGENT_PLUGIN_VERSION" ]; then
    echo "❌ Version mismatch: .claude-plugin/plugin.json is $VERSION, plugin.json is $AGENT_PLUGIN_VERSION"
    exit 1
fi

echo "🔨 Building n8n-skills distribution packages (v${VERSION})..."

# Create dist directory if it doesn't exist
mkdir -p "$DIST_DIR"

# Remove old zips
echo "🗑️  Removing old zip files..."
rm -f "$DIST_DIR"/*.zip

# Build individual skill zips (for Claude.ai)
# Structure: skill-name/SKILL.md at zip root (not nested under skills/)
echo "📦 Building individual skill zips for Claude.ai..."

# Derive the skill list from the tree so a newly added skill cannot be silently
# left out of a release. The rule matches Agent Plugins discovery: an immediate
# child of skills/ holding a SKILL.md is one skill.
SKILLS=()
for dir in skills/*/; do
    name=$(basename "$dir")
    case "$name" in
        *-workspace) continue ;;
    esac
    [ -f "${dir}SKILL.md" ] || continue
    SKILLS+=("$name")
done

if [ ${#SKILLS[@]} -eq 0 ]; then
    echo "❌ No skills found under skills/"
    exit 1
fi

for skill in "${SKILLS[@]}"; do
    echo "   - $skill"
    (cd skills && zip -rq "../$DIST_DIR/${skill}-v${VERSION}.zip" "${skill}/" -x "*.DS_Store")
done

# Build skills-only bundle (for ChatGPT and other SKILL.md hosts)
# Structure: one skill-name.skill file per skill at zip root, no plugin
# manifests or hooks. A .skill file is the individual skill zip under another
# extension, so hosts whose upload dialog takes several files can install the
# whole pack in one go: unzip, then select every .skill file.
echo "📦 Building skills-only bundle..."
STAGE_DIR=$(mktemp -d)
trap 'rm -rf "$STAGE_DIR"' EXIT
for skill in "${SKILLS[@]}"; do
    cp "$DIST_DIR/${skill}-v${VERSION}.zip" "$STAGE_DIR/${skill}.skill"
done
cp LICENSE NOTICES NOTICES-APACHE-2.0.txt "$STAGE_DIR/"
BUNDLE="$PWD/$DIST_DIR/n8n-skills-all-v${VERSION}.zip"
(cd "$STAGE_DIR" && zip -q "$BUNDLE" *.skill LICENSE NOTICES NOTICES-APACHE-2.0.txt)

# Build complete bundle (for Claude Code)
echo "📦 Building complete bundle for Claude Code..."
zip -rq "$DIST_DIR/n8n-mcp-skills-v${VERSION}.zip" \
    .claude-plugin/ \
    plugin.json \
    mcp.json \
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
