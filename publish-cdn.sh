#!/usr/bin/env bash
#
# CDN Assets Publisher for jsDelivr
# 
# This script publishes assets to a PUBLIC GitHub repository
# and generates jsDelivr CDN URLs.
#
# ⚠️  IMPORTANT: The target GitHub repository MUST be PUBLIC!
#     jsDelivr mirrors GitHub files through unauthenticated HTTP requests.
#     Private repositories require authentication, which jsDelivr cannot perform.
#     As a result, private repos will NOT load on jsDelivr, and URLs will fail.
#
# Usage:
#   ./publish-cdn.sh [options]
#
# Options:
#   -t, --tag VERSION    Create a git tag for versioned CDN URLs
#   -m, --message MSG    Custom commit message
#   -p, --purge          Purge jsDelivr cache after upload
#   -d, --dry-run        Show what would be done without making changes
#   -h, --help           Show this help message
#
set -euo pipefail

# =============================================================================
# Configuration - EDIT THESE VALUES
# =============================================================================
GITHUB_USER="${CDN_GITHUB_USER:-JYamazian}"
GITHUB_REPO="${CDN_GITHUB_REPO:-cdn-assets}"
GITHUB_BRANCH="${CDN_GITHUB_BRANCH:-main}"
ASSETS_DIR="${CDN_ASSETS_DIR:-./assets}"

# Optional: GitHub Personal Access Token (for private repos during push only)
# Can be set via environment variable for security
GITHUB_TOKEN="${CDN_GITHUB_TOKEN:-}"
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script variables
VERSION_TAG=""
COMMIT_MESSAGE=""
PURGE_CACHE=false
DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Functions
# =============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                    CDN Assets Publisher                           ║"
    echo "║                      via jsDelivr CDN                             ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
}

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -t, --tag VERSION    Create a git tag for versioned CDN URLs (e.g., v1.0.0)"
    echo "  -m, --message MSG    Custom commit message"
    echo "  -p, --purge          Purge jsDelivr cache after upload"
    echo "  -d, --dry-run        Show what would be done without making changes"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Environment Variables (override config):"
    echo "  CDN_GITHUB_USER      GitHub username"
    echo "  CDN_GITHUB_REPO      Repository name"
    echo "  CDN_GITHUB_BRANCH    Branch name (default: main)"
    echo "  CDN_GITHUB_TOKEN     GitHub Personal Access Token"
    echo "  CDN_ASSETS_DIR       Local assets directory"
    echo ""
    echo "Examples:"
    echo "  $0                          # Basic upload"
    echo "  $0 -t v1.0.0               # Upload with version tag"
    echo "  $0 -p                       # Upload and purge cache"
    echo "  $0 -t v1.0.0 -p -m 'Release 1.0.0'"
    exit 0
}

check_requirements() {
    print_step "Checking requirements..."
    
    local missing=()
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl (optional, for cache purging)")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing[*]}"
        exit 1
    fi
    
    print_success "All requirements met"
}

validate_config() {
    print_step "Validating configuration..."
    
    if [ "$GITHUB_USER" == "YOUR_GITHUB_USERNAME" ]; then
        print_error "Please set your GitHub username in the script or via CDN_GITHUB_USER environment variable"
        exit 1
    fi
    
    if [ ! -d "$ASSETS_DIR" ]; then
        print_error "Assets directory not found: $ASSETS_DIR"
        exit 1
    fi
    
    # Check if assets directory has files
    if [ -z "$(find "$ASSETS_DIR" -type f ! -name '.gitkeep' 2>/dev/null)" ]; then
        print_warning "No files found in assets directory (excluding .gitkeep files)"
    fi
    
    print_success "Configuration valid"
}

check_repo_visibility() {
    print_step "Checking repository visibility..."
    
    # Try to access the repo via unauthenticated request
    local api_url="https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO"
    local response
    
    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "$api_url" 2>/dev/null || echo "000")
        
        if [ "$response" == "200" ]; then
            print_success "Repository is PUBLIC - jsDelivr will work ✓"
        elif [ "$response" == "404" ]; then
            print_warning "Repository not found or is PRIVATE"
            echo ""
            echo -e "${YELLOW}┌─────────────────────────────────────────────────────────────────────┐${NC}"
            echo -e "${YELLOW}│  jsDelivr requires PUBLIC repositories!                            │${NC}"
            echo -e "${YELLOW}│                                                                     │${NC}"
            echo -e "${YELLOW}│  If your repo is private:                                          │${NC}"
            echo -e "${YELLOW}│  1. Go to: https://github.com/$GITHUB_USER/$GITHUB_REPO/settings   │${NC}"
            echo -e "${YELLOW}│  2. Scroll to 'Danger Zone'                                        │${NC}"
            echo -e "${YELLOW}│  3. Click 'Change visibility' → Make public                       │${NC}"
            echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────┘${NC}"
            echo ""
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            print_info "Could not verify repository visibility (HTTP $response)"
        fi
    else
        print_info "curl not available, skipping visibility check"
    fi
}

get_file_count() {
    find "$ASSETS_DIR" -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' '
}

get_total_size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        find "$ASSETS_DIR" -type f ! -name '.gitkeep' -exec stat -f%z {} + 2>/dev/null | awk '{s+=$1} END {print s}' || echo "0"
    else
        find "$ASSETS_DIR" -type f ! -name '.gitkeep' -exec stat --printf="%s\n" {} + 2>/dev/null | awk '{s+=$1} END {print s}' || echo "0"
    fi
}

format_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes} B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 )) KB"
    else
        echo "$(( bytes / 1048576 )) MB"
    fi
}

publish_assets() {
    print_step "Publishing assets to GitHub..."
    
    cd "$SCRIPT_DIR"
    
    # Initialize git if needed
    if [ ! -d ".git" ]; then
        print_info "Initializing git repository..."
        if [ "$DRY_RUN" = false ]; then
            git init
            git remote add origin "https://github.com/$GITHUB_USER/$GITHUB_REPO.git"
        else
            echo "[DRY-RUN] Would initialize git repository"
        fi
    fi
    
    # Check current branch
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "")
    
    if [ -z "$current_branch" ]; then
        if [ "$DRY_RUN" = false ]; then
            git checkout -b "$GITHUB_BRANCH" 2>/dev/null || git checkout "$GITHUB_BRANCH"
        fi
    elif [ "$current_branch" != "$GITHUB_BRANCH" ]; then
        if [ "$DRY_RUN" = false ]; then
            git checkout "$GITHUB_BRANCH" 2>/dev/null || git checkout -b "$GITHUB_BRANCH"
        fi
    fi
    
    # Stage all changes
    if [ "$DRY_RUN" = false ]; then
        git add -A
    else
        echo "[DRY-RUN] Would stage all changes"
    fi
    
    # Check for changes
    if git diff --cached --quiet 2>/dev/null; then
        print_info "No changes to commit"
        return 0
    fi
    
    # Commit
    local msg="${COMMIT_MESSAGE:-"update: assets $(date '+%Y-%m-%d %H:%M:%S')"}"
    if [ "$DRY_RUN" = false ]; then
        git commit -m "$msg"
    else
        echo "[DRY-RUN] Would commit with message: $msg"
    fi
    
    # Push
    print_info "Pushing to origin/$GITHUB_BRANCH..."
    if [ "$DRY_RUN" = false ]; then
        if [ -n "$GITHUB_TOKEN" ]; then
            git push "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$GITHUB_REPO.git" "$GITHUB_BRANCH"
        else
            git push origin "$GITHUB_BRANCH"
        fi
    else
        echo "[DRY-RUN] Would push to origin/$GITHUB_BRANCH"
    fi
    
    # Create tag if specified
    if [ -n "$VERSION_TAG" ]; then
        print_info "Creating tag: $VERSION_TAG"
        if [ "$DRY_RUN" = false ]; then
            git tag -a "$VERSION_TAG" -m "Release $VERSION_TAG"
            if [ -n "$GITHUB_TOKEN" ]; then
                git push "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$GITHUB_REPO.git" "$VERSION_TAG"
            else
                git push origin "$VERSION_TAG"
            fi
        else
            echo "[DRY-RUN] Would create and push tag: $VERSION_TAG"
        fi
    fi
    
    print_success "Assets published successfully!"
}

purge_cdn_cache() {
    if [ "$PURGE_CACHE" = false ]; then
        return 0
    fi
    
    print_step "Purging jsDelivr cache..."
    
    if ! command -v curl &> /dev/null; then
        print_warning "curl not found, skipping cache purge"
        return 0
    fi
    
    local purge_count=0
    local fail_count=0
    
    while IFS= read -r -d '' file; do
        local rel_path="${file#$ASSETS_DIR/}"
        local purge_url="https://purge.jsdelivr.net/gh/$GITHUB_USER/$GITHUB_REPO@$GITHUB_BRANCH/assets/$rel_path"
        
        if [ "$DRY_RUN" = false ]; then
            local response
            response=$(curl -s -o /dev/null -w "%{http_code}" "$purge_url")
            if [ "$response" == "200" ]; then
                ((purge_count++))
            else
                ((fail_count++))
            fi
        else
            echo "[DRY-RUN] Would purge: $purge_url"
            ((purge_count++))
        fi
    done < <(find "$ASSETS_DIR" -type f ! -name '.gitkeep' -print0 2>/dev/null)
    
    if [ "$fail_count" -gt 0 ]; then
        print_warning "Purged $purge_count files, $fail_count failed"
    else
        print_success "Purged $purge_count files from cache"
    fi
}

get_latest_commit() {
    git rev-parse --short HEAD 2>/dev/null || echo "unknown"
}

print_cdn_urls() {
    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}                         CDN URLs Generated                            ${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local commit_sha
    commit_sha=$(get_latest_commit)
    
    local base_url="https://cdn.jsdelivr.net/gh/$GITHUB_USER/$GITHUB_REPO"
    local file_count=0
    
    # Print file URLs
    echo -e "${BOLD}📁 Asset URLs:${NC}"
    echo ""
    
    while IFS= read -r -d '' file; do
        local rel_path="${file#$ASSETS_DIR/}"
        ((file_count++))
        
        echo -e "${CYAN}$rel_path${NC}"
        echo -e "   Branch:  ${base_url}@${GITHUB_BRANCH}/assets/$rel_path"
        if [ -n "$VERSION_TAG" ]; then
            echo -e "   Version: ${base_url}@${VERSION_TAG}/assets/$rel_path"
        fi
        echo -e "   Commit:  ${base_url}@${commit_sha}/assets/$rel_path"
        echo ""
    done < <(find "$ASSETS_DIR" -type f ! -name '.gitkeep' -print0 2>/dev/null | head -z -20)
    
    local total_files
    total_files=$(get_file_count)
    
    if [ "$total_files" -gt 20 ]; then
        echo -e "${YELLOW}... and $((total_files - 20)) more files${NC}"
        echo ""
    fi
    
    # Print summary
    echo -e "${BOLD}📊 Summary:${NC}"
    echo "   Total files: $total_files"
    echo "   Total size:  $(format_bytes "$(get_total_size)")"
    echo "   Commit:      $commit_sha"
    if [ -n "$VERSION_TAG" ]; then
        echo "   Tag:         $VERSION_TAG"
    fi
    echo ""
    
    # Print URL patterns
    echo -e "${BOLD}🔗 URL Patterns:${NC}"
    echo ""
    echo "   Latest (24h cache):"
    echo -e "   ${CYAN}${base_url}@${GITHUB_BRANCH}/assets/<path>${NC}"
    echo ""
    if [ -n "$VERSION_TAG" ]; then
        echo "   Versioned (permanent cache):"
        echo -e "   ${CYAN}${base_url}@${VERSION_TAG}/assets/<path>${NC}"
        echo ""
    fi
    echo "   Immutable (permanent cache):"
    echo -e "   ${CYAN}${base_url}@${commit_sha}/assets/<path>${NC}"
    echo ""
    
    # Auto-minification tip
    echo -e "${BOLD}💡 Tips:${NC}"
    echo "   • Add .min before extension for auto-minification (JS/CSS)"
    echo "   • Example: /app.js → /app.min.js"
    echo "   • Use commit SHA or tags for production (permanent cache)"
    echo "   • Use branch for development (24h cache)"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tag)
                VERSION_TAG="$2"
                shift 2
                ;;
            -m|--message)
                COMMIT_MESSAGE="$2"
                shift 2
                ;;
            -p|--purge)
                PURGE_CACHE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    print_banner
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}                          DRY RUN MODE                                 ${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════${NC}"
        echo ""
    fi
    
    check_requirements
    validate_config
    check_repo_visibility
    
    echo ""
    print_info "Files to publish: $(get_file_count)"
    print_info "Total size: $(format_bytes "$(get_total_size)")"
    echo ""
    
    publish_assets
    purge_cdn_cache
    print_cdn_urls
    
    print_success "Done! Your assets are now available via jsDelivr CDN."
}

main "$@"
