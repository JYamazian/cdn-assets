#!/usr/bin/env bash
#
# Release script for CDN Assets
# Creates a new version tag and updates changelog
#
# Usage:
#   ./release.sh <version>
#   ./release.sh v1.0.1
#   ./release.sh v2.0.0 "Major release with breaking changes"
#
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

VERSION="${1:-}"
MESSAGE="${2:-Release $VERSION}"

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version required${NC}"
    echo ""
    echo "Usage: $0 <version> [message]"
    echo ""
    echo "Examples:"
    echo "  $0 v1.0.1"
    echo "  $0 v2.0.0 \"Major release\""
    echo ""
    echo "Current tags:"
    git tag -l | tail -5
    exit 1
fi

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${YELLOW}Warning: Version '$VERSION' doesn't follow semver format (vX.Y.Z)${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}You have uncommitted changes:${NC}"
    git status --short
    echo ""
    read -p "Commit these changes before release? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git add -A
        git commit -m "chore: prepare for $VERSION release"
    fi
fi

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag '$VERSION' already exists${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Creating Release                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Version:${NC} $VERSION"
echo -e "${BOLD}Message:${NC} $MESSAGE"
echo ""

# Create annotated tag
echo -e "${CYAN}▶ Creating tag...${NC}"
git tag -a "$VERSION" -m "$MESSAGE"

# Push tag
echo -e "${CYAN}▶ Pushing tag to origin...${NC}"
git push origin "$VERSION"

# Push any commits
echo -e "${CYAN}▶ Pushing commits...${NC}"
git push origin main

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Release $VERSION created successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}CDN URLs (immutable):${NC}"
echo ""
echo "  CSS:  https://cdn.jsdelivr.net/gh/JYamazian/cdn-assets@$VERSION/assets/css/example.css"
echo "  JS:   https://cdn.jsdelivr.net/gh/JYamazian/cdn-assets@$VERSION/assets/js/example.js"
echo "  Data: https://cdn.jsdelivr.net/gh/JYamazian/cdn-assets@$VERSION/assets/data/manifest.json"
echo ""
echo -e "${BOLD}GitHub Release:${NC}"
echo "  https://github.com/JYamazian/cdn-assets/releases/tag/$VERSION"
echo ""
echo -e "${YELLOW}💡 Don't forget to update CHANGELOG.md with release notes!${NC}"
