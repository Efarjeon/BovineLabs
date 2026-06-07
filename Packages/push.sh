#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/Packages"
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# ── Helpers ──

info()  { echo "  $*"; }
ok()    { echo "  ✅ $*"; }
warn()  { echo "  ⚠️  $*"; }
header(){ echo ""; echo "── $* ──"; }

has_changes() {
    local dir="$1"
    cd "$dir"
    # Check working tree, staged, and untracked
    ! git diff --quiet 2>/dev/null || \
    ! git diff --cached --quiet 2>/dev/null || \
    [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]
}

commit_and_push() {
    local dir="$1"
    local label="$2"
    cd "$dir"

    if ! has_changes "$dir"; then
        ok "$label — clean"
        return 0
    fi

    # Stage all changes
    git add -A

    # Show what's being committed
    info "Changes in $label:"
    git status --short
    echo ""

    # Commit with timestamp
    git commit -m "chore: auto-update [${DATETIME}]"

    # Push
    if git push origin 2>&1; then
        ok "$label — pushed"
        return 0
    else
        warn "$label — push failed"
        return 1
    fi
}

# ── Collect submodules ──

# Get list of submodule paths from .gitmodules (if it exists)
SUBMODULE_PATHS=()
if [ -f "$REPO_ROOT/.gitmodules" ]; then
    while IFS= read -r path; do
        [ -n "$path" ] && SUBMODULE_PATHS+=("$REPO_ROOT/$path")
    done < <(git -C "$REPO_ROOT" config --file "$REPO_ROOT/.gitmodules" --get-regexp path 2>/dev/null | awk '{print $2}')
fi

# ── Phase 1: Commit and push dirty submodules ──

if [ ${#SUBMODULE_PATHS[@]} -gt 0 ]; then
    header "Phase 1: Submodules"

    ANY_SUBMODULE_PUSHED=false
    ANY_SUBMODULE_FAILED=false

    for submod in "${SUBMODULE_PATHS[@]}"; do
        if [ ! -d "$submod/.git" ] && [ ! -f "$submod/.git" ]; then
            warn "$(basename "$submod") — not a git repo, skipping"
            continue
        fi

        label="$(basename "$submod")"

        if ! has_changes "$submod"; then
            ok "$label — clean"
            continue
        fi

        # has_changes was true, but git add -A + re-check handles
        # stale staged files that resolve to nothing (e.g. moved then deleted).
        cd "$submod"
        git add -A 2>/dev/null || true
        if git diff --cached --quiet 2>/dev/null && git diff --quiet 2>/dev/null && \
           [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
            ok "$label — clean (staged resolved)"
            continue
        fi

        if commit_and_push "$submod" "$label"; then
            ANY_SUBMODULE_PUSHED=true
        else
            ANY_SUBMODULE_FAILED=true
        fi
    done

    if [ "$ANY_SUBMODULE_FAILED" = true ]; then
        echo ""
        warn "Some submodules failed to push. Parent repo will NOT be committed."
        exit 1
    fi
fi

# ── Phase 2: Commit and push parent repo ──

header "Phase 2: Parent repo"
cd "$PACKAGES_DIR"

if ! has_changes "$PACKAGES_DIR"; then
    # Even if working tree looks clean, submodule pointer bumps show as staged
    # after submodule pushes. Do a second check.
    git add -A 2>/dev/null || true
    if git diff --cached --quiet 2>/dev/null && git diff --quiet 2>/dev/null && \
       [ -z "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
        ok "Parent repo — clean, nothing to commit."
        exit 0
    fi
fi

# Stage all (including updated submodule pointers)
git add -A

echo "📦 Changes to commit:"
git status --short
echo ""

git commit -m "chore: auto-update all packages [${DATETIME}]"

if git push origin 2>&1; then
    ok "Parent repo — pushed"
else
    warn "Parent repo — push failed"
    exit 1
fi

echo ""
ok "Done!"
