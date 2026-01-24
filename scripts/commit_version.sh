#!/bin/bash

set -e

# --- Find project root (directory containing pubspec.yaml) ---
find_project_root() {
    SEARCH_DIR="$PWD"
    while [[ "$SEARCH_DIR" != "/" ]]; do
        if [[ -f "$SEARCH_DIR/pubspec.yaml" ]]; then
            echo "$SEARCH_DIR"
            return 0
        fi
        SEARCH_DIR="$(dirname "$SEARCH_DIR")"
    done
    return 1
}

PROJECT_ROOT=$(find_project_root)
if [[ -z "$PROJECT_ROOT" ]]; then
    echo -e "\033[0;31m❌ pubspec.yaml not found in this or any parent directory\033[0m"
    exit 1
fi
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not a git repository"
    exit 1
fi

# 2. Check for uncommitted changes
if [[ -n $(git status -s) ]]; then
    print_warning "You have uncommitted changes"
    git status -s
    echo ""
    read -p "Continue anyway? [y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted"
        exit 0
    fi
fi

# 3. Check current branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    print_warning "Current branch is '$CURRENT_BRANCH' (not 'main')"
fi

# 4. Read current version from pubspec.yaml
if [[ ! -f "pubspec.yaml" ]]; then
    print_error "pubspec.yaml not found"
    exit 1
fi

VERSION_LINE=$(grep '^version:' pubspec.yaml)
if [[ -z "$VERSION_LINE" ]]; then
    print_error "Version not found in pubspec.yaml"
    exit 1
fi

VERSION=$(echo "$VERSION_LINE" | cut -d ' ' -f2)
CURRENT_VERSION_NAME=$(echo "$VERSION" | cut -d '+' -f1)
CURRENT_BUILD_NUMBER=$(echo "$VERSION" | cut -d '+' -f2)

# Parse semantic version
if [[ ! "$CURRENT_VERSION_NAME" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    print_error "Invalid version format: $CURRENT_VERSION_NAME (expected: MAJOR.MINOR.PATCH)"
    exit 1
fi

MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"

echo ""
print_info "Current version: ${BLUE}${CURRENT_VERSION_NAME}+${CURRENT_BUILD_NUMBER}${NC}"
echo ""

# 5. Select version type
echo "Select version type:"
echo "1) major - Breaking changes (${CURRENT_VERSION_NAME} → $((MAJOR + 1)).0.0)"
echo "2) minor - New features (${CURRENT_VERSION_NAME} → ${MAJOR}.$((MINOR + 1)).0)"
echo "3) patch - Bug fixes (${CURRENT_VERSION_NAME} → ${MAJOR}.${MINOR}.$((PATCH + 1)))"
echo ""

while true; do
    # shellcheck disable=SC2162
    read -p "Choice [1-3]: " CHOICE
    case $CHOICE in
        1)
            VERSION_TYPE="major"
            NEW_MAJOR=$((MAJOR + 1))
            NEW_MINOR=0
            NEW_PATCH=0
            break
            ;;
        2)
            VERSION_TYPE="minor"
            NEW_MAJOR=$MAJOR
            NEW_MINOR=$((MINOR + 1))
            NEW_PATCH=0
            break
            ;;
        3)
            VERSION_TYPE="patch"
            NEW_MAJOR=$MAJOR
            NEW_MINOR=$MINOR
            NEW_PATCH=$((PATCH + 1))
            break
            ;;
        *)
            print_error "Invalid choice. Please enter 1, 2, or 3"
            ;;
    esac
done

# 6. Calculate new version
NEW_VERSION_NAME="${NEW_MAJOR}.${NEW_MINOR}.${NEW_PATCH}"
NEW_BUILD_NUMBER=$((CURRENT_BUILD_NUMBER + 1))
NEW_FULL_VERSION="${NEW_VERSION_NAME}+${NEW_BUILD_NUMBER}"

echo ""
print_info "New version will be: ${GREEN}${NEW_FULL_VERSION}${NC}"
echo ""

# 7. Get commit message
# shellcheck disable=SC2162
read -p "Commit message: " COMMIT_MESSAGE

if [[ -z "$COMMIT_MESSAGE" ]]; then
    print_error "Commit message cannot be empty"
    exit 1
fi

# Build full commit message with prefix
FULL_COMMIT_MESSAGE="${VERSION_TYPE}: ${COMMIT_MESSAGE}"

# 8. Show preview and confirm
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Preview:"
echo "  Version:  ${CURRENT_VERSION_NAME}+${CURRENT_BUILD_NUMBER} → ${GREEN}${NEW_FULL_VERSION}${NC}"
echo "  Commit:   \"${FULL_COMMIT_MESSAGE}\""
echo "  Tag:      v${NEW_FULL_VERSION}"
echo "  Push to:  origin/${CURRENT_BRANCH}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

read -p "Proceed? [y/n]: " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Aborted"
    exit 0
fi

# 9. Update pubspec.yaml
echo ""
print_info "Updating pubspec.yaml..."
sed -i "s/^version: .*/version: $NEW_FULL_VERSION/" pubspec.yaml

# 10. Git operations
print_info "Adding changes to git..."
git add pubspec.yaml

print_info "Creating commit..."
git commit -m "$FULL_COMMIT_MESSAGE"

print_info "Creating tag..."
git tag "v$NEW_FULL_VERSION"

print_info "Pushing to origin/${CURRENT_BRANCH}..."
git push origin "$CURRENT_BRANCH"

print_info "Pushing tag..."
git push origin "v$NEW_FULL_VERSION"

# 11. Success
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Version bumped successfully!"
echo ""
echo "  Old: ${CURRENT_VERSION_NAME}+${CURRENT_BUILD_NUMBER}"
echo "  New: ${GREEN}${NEW_FULL_VERSION}${NC}"
echo "  Tag: v${NEW_FULL_VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""