#!/bin/bash
set -e

echo "🚀 Starting cherry-pick process..."
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Verify we're in the right repo
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# 2. Verify base commit exists
if ! git cat-file -e be5958c0 2>/dev/null; then
    echo -e "${RED}❌ Error: Base commit be5958c0 not found${NC}"
    exit 1
fi

# 3. Create new branch from stable base
echo -e "${YELLOW}📍 Creating branch from be5958c0...${NC}"
git checkout be5958c0
git checkout -b feature/cherry-pick-improvements

# 4. Verify Bible assets exist
SQLITE_COUNT=$(ls assets/biblia/*.SQLite3 2>/dev/null | wc -l)
echo -e "${GREEN}✅ Found ${SQLITE_COUNT} Bible SQLite files${NC}"

if [ "$SQLITE_COUNT" -ne 9 ]; then
    echo -e "${RED}⚠️  Warning: Expected 9 SQLite files, found ${SQLITE_COUNT}${NC}"
fi

# 5. Cherry-pick commits in chronological order
echo ""
echo -e "${YELLOW}🍒 Starting cherry-picks...${NC}"
echo "=================================="

# Array of commits to cherry-pick
COMMITS=(
    # Coverage tests (High value)
    "20451b9:Add 133 high-value tests for critical services"
    "067a16b:Add 135 high-value user flow tests"
    "5ad42d8:Add 37 ThemeBloc and OnboardingBloc tests"
    "ba992da:Add 80 user flow tests for models and audio"
    "e6c84d2:Add 43 service tests for coverage"
    
    # Core fixes
    "d852126:Fix all 110 failing tests"
    "27088d3:Fix bible download mocks and streak test"
    "5077a86:Fix devotional tracking timer"
    "9f30e97:Fix misleading comment in devotional index"
    "82f20e6:Centralize stats updates and review logic"
    "0ab5632:Improve devotional recording logic"
    "5726258:Use DevocionalProvider for heard devotionals"
    "9c72849:Consolidate devotional tracking"
    
    # UI/UX improvements
    "7b47bf2:Implement UI and UX fixes from checklist"
    "c4ea708:Use existing translation keys"
    "5eea220:Update i18n key for streak display"
    "ca8c852:Refine streak badge and TTS logs"
    "3e0a626:TTS fallback improvements"
    
    # CI/CD
    "f966101:Enhance CI with google-services.json"
    "e58e13f:Enhance CI to install google-services"
    "8c4470d:Remove Non-SDK API check workflow"
    
    # Dependencies
    "426d244:Update dependencies"
)

TOTAL=${#COMMITS[@]}
CURRENT=0
FAILED=()

for commit_info in "${COMMITS[@]}"; do
    CURRENT=$((CURRENT + 1))
    COMMIT_HASH=$(echo "$commit_info" | cut -d: -f1)
    COMMIT_MSG=$(echo "$commit_info" | cut -d: -f2-)
    
    echo ""
    echo -e "${YELLOW}[$CURRENT/$TOTAL] Cherry-picking: ${COMMIT_HASH}${NC}"
    echo "    ${COMMIT_MSG}"
    
    if git cherry-pick "$COMMIT_HASH" --no-commit 2>/dev/null; then
        # Success - check for Bible-related files to exclude
        BIBLE_FILES=$(git diff --cached --name-only | grep -E "bible_version|http_client_adapter|storage_adapter|bible_versions_manager" || true)
        
        if [ -n "$BIBLE_FILES" ]; then
            echo -e "${YELLOW}    ⚠️  Found Bible-related files, excluding:${NC}"
            echo "$BIBLE_FILES" | while read -r file; do
                echo "       - $file"
                git restore --staged "$file" 2>/dev/null || true
            done
        fi
        
        # Check if there are still changes to commit
        if git diff --cached --quiet; then
            echo -e "${YELLOW}    ⏭️  No changes after filtering, skipping${NC}"
            git cherry-pick --abort 2>/dev/null || true
        else
            git commit -m "chore: $COMMIT_MSG" --no-verify
            echo -e "${GREEN}    ✅ Success${NC}"
        fi
    else
        echo -e "${RED}    ❌ Conflict detected${NC}"
        
        # Try to auto-resolve pubspec.lock conflicts
        if git diff --name-only --diff-filter=U | grep -q "pubspec.lock"; then
            echo -e "${YELLOW}    🔧 Auto-resolving pubspec.lock...${NC}"
            git checkout --theirs pubspec.lock
            git add pubspec.lock
            
            if git diff --cached --quiet; then
                echo -e "${YELLOW}    ⏭️  Only pubspec.lock conflicts, skipping${NC}"
                git cherry-pick --abort
            else
                git commit -m "chore: $COMMIT_MSG" --no-verify
                echo -e "${GREEN}    ✅ Resolved and committed${NC}"
            fi
        else
            echo -e "${RED}    ⚠️  Manual resolution required${NC}"
            FAILED+=("$COMMIT_HASH:$COMMIT_MSG")
            git cherry-pick --abort
        fi
    fi
done

# 6. Summary
echo ""
echo "=================================="
echo -e "${GREEN}🎉 Cherry-pick process complete!${NC}"
echo ""

if [ ${#FAILED[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Failed commits (requires manual cherry-pick):${NC}"
    for failed in "${FAILED[@]}"; do
        echo "   - $failed"
    done
    echo ""
fi

# 7. Verification
echo -e "${YELLOW}📊 Running verification...${NC}"
echo "=================================="

# Count commits
COMMIT_COUNT=$(git rev-list --count be5958c0..HEAD)
echo -e "${GREEN}✅ Added $COMMIT_COUNT commits${NC}"

# Verify assets still exist
FINAL_SQLITE=$(ls assets/biblia/*.SQLite3 2>/dev/null | wc -l)
echo -e "${GREEN}✅ Bible assets: $FINAL_SQLITE files${NC}"

# Check for Bible migration files (should NOT exist)
BIBLE_MIGRATION_FILES=(
    "bible_reader_core/lib/src/repositories/bible_version_repository.dart"
    "lib/blocs/bible_version/bible_version_bloc.dart"
    "lib/pages/bible_versions_manager_page.dart"
)

echo ""
echo -e "${YELLOW}🔍 Checking for Bible migration artifacts...${NC}"
ARTIFACTS_FOUND=false
for file in "${BIBLE_MIGRATION_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${RED}   ⚠️  Found: $file${NC}"
        ARTIFACTS_FOUND=true
    fi
done

if [ "$ARTIFACTS_FOUND" = false ]; then
    echo -e "${GREEN}   ✅ No Bible migration artifacts found${NC}"
fi

echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "   1. Review changes: git log --oneline be5958c0..HEAD"
echo "   2. Run tests: flutter test"
echo "   3. Run analyzer: dart analyze --fatal-infos"
echo "   4. Push branch: git push origin feature/cherry-pick-improvements"
echo "   5. Create PR: feature/cherry-pick-improvements → main"
echo ""
echo -e "${GREEN}✨ Done!${NC}"