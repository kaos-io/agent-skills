#!/usr/bin/env bash
# Walks the repository tree, collects all manifest.json files,
# validates them, checks for duplicates, and generates index.json.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$REPO_ROOT/index.json"

# Collect manifest.json files only from known artifact directories
MANIFESTS=""
for dir in agents plugins prompts; do
  if [ -d "$REPO_ROOT/$dir" ]; then
    FOUND=$(find "$REPO_ROOT/$dir" -name "manifest.json" -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.claude-plugin/*" | sort)
    MANIFESTS="$MANIFESTS $FOUND"
  fi
done
MANIFESTS=$(echo "$MANIFESTS" | xargs)

if [ -z "$MANIFESTS" ]; then
  echo "No manifest.json files found."
  exit 0
fi

# Validate each manifest
ERRORS=0
for manifest in $MANIFESTS; do
  # Check required fields exist
  for field in name type version entry description; do
    if ! jq -e ".$field" "$manifest" > /dev/null 2>&1; then
      echo "ERROR: $manifest missing required field '$field'"
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Validate type is one of the allowed values
  TYPE=$(jq -r '.type' "$manifest" 2>/dev/null || echo "")
  if [[ "$TYPE" != "skill" && "$TYPE" != "agent" && "$TYPE" != "prompt" ]]; then
    echo "ERROR: $manifest has invalid type '$TYPE' (must be skill, agent, or prompt)"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate version is semver
  VERSION=$(jq -r '.version' "$manifest" 2>/dev/null || echo "")
  if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "ERROR: $manifest has invalid version '$VERSION' (must be MAJOR.MINOR.PATCH)"
    ERRORS=$((ERRORS + 1))
  fi

  # Validate entry file exists
  ENTRY=$(jq -r '.entry' "$manifest" 2>/dev/null || echo "")
  if [ -n "$ENTRY" ] && ! [ -f "$(dirname "$manifest")/$ENTRY" ]; then
    echo "ERROR: $manifest references missing entry file '$ENTRY'"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "Found $ERRORS validation error(s). Fix them before generating index.json."
  exit 1
fi

# Build artifacts array
ARTIFACTS="[]"
SEEN_NAMES=""
for manifest in $MANIFESTS; do
  ABS_DIR="$(cd "$(dirname "$manifest")" && pwd)"
  REL_PATH="${ABS_DIR#"$REPO_ROOT"/}"
  NAME=$(jq -r '.name' "$manifest")

  # Check for duplicate names
  if echo "$SEEN_NAMES" | grep -qw "$NAME"; then
    echo "ERROR: Duplicate artifact name '$NAME' in $manifest"
    echo "       Each artifact must have a unique name across the registry."
    exit 1
  fi
  SEEN_NAMES="$SEEN_NAMES $NAME"

  ARTIFACT=$(jq --arg path "$REL_PATH" '{
    name: .name,
    type: .type,
    version: .version,
    path: $path,
    entry: .entry,
    description: .description,
    tags: (.tags // []),
    produces: (.produces // {}),
    consumes: (.consumes // {}),
    dependencies: (.dependencies // {})
  }' "$manifest")
  ARTIFACTS=$(echo "$ARTIFACTS" | jq --argjson a "$ARTIFACT" '. + [$a]')
done

GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
  --arg name "kaos-agent-skills" \
  --arg desc "Official agentic artifact registry for the KAOS platform." \
  --arg ts "$GENERATED_AT" \
  --argjson artifacts "$ARTIFACTS" \
  '{
    name: $name,
    description: $desc,
    generated_at: $ts,
    artifacts: $artifacts
  }' > "$INDEX_FILE"

echo "Generated $INDEX_FILE with $(echo "$ARTIFACTS" | jq length) artifact(s)."
