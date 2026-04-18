#!/bin/bash
# Web Stack Template Initializer v1.3
# Usage: bash <(curl -s https://raw.githubusercontent.com/oscarsovino/web-stack-template/main/init-web-stack.sh)
# Or from cloned repo: ./init-web-stack.sh [target-dir]

set -e

# Require Node 22.x so the generated project matches the pinned engines field
if command -v node >/dev/null 2>&1; then
    NODE_MAJOR=$(node -p "process.versions.node.split('.')[0]")
    if [ "$NODE_MAJOR" != "22" ]; then
        echo "Error: Node 22.x required (found $(node --version))."
        echo "Install via nvm: nvm install 22 && nvm use 22"
        exit 1
    fi
else
    echo "Error: node not found in PATH."
    exit 1
fi

PROJECT_DIR=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_DIR")
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_START="<!-- WEB-STACK-START -->"
MARKER_END="<!-- WEB-STACK-END -->"

# Target directory for web app (default: web/)
WEB_DIR="${1:-web}"

# Copy template contents into $WEB_DIR excluding dev artifacts.
# Uses tar to preserve dotfiles and skip node_modules / build outputs.
copy_template_clean() {
    (cd "$TEMPLATE_DIR/template" && tar \
        --exclude=node_modules \
        --exclude=.next \
        --exclude=out \
        --exclude=coverage \
        --exclude=playwright-report \
        --exclude=test-results \
        --exclude=blob-report \
        --exclude=tsconfig.tsbuildinfo \
        --exclude=next-env.d.ts \
        --exclude=.DS_Store \
        -cf - .) | (cd "$WEB_DIR" && tar -xf -)
}

echo "Web Stack Template v1.3 (reproducibility)"
echo "Project: $PROJECT_NAME"
echo "Target:  $WEB_DIR/"
echo ""

# ============================================================
# STEP 1: Copy template files
# ============================================================

if [ -d "$WEB_DIR/src" ]; then
    echo "Directory $WEB_DIR/src already exists."
    echo ""
    echo "Options:"
    echo "  [m] Merge — copy missing files only (safe)"
    echo "  [r] Replace — overwrite everything (destructive)"
    echo "  [s] Skip — don't touch $WEB_DIR/"
    echo ""
    read -p "Choose [m/r/s]: " -n 1 -r
    echo ""
    case $REPLY in
        m|M)
            echo "Merging template files..."
            # Copy only files that don't exist
            find "$TEMPLATE_DIR/template" -type f | while read -r src; do
                rel="${src#$TEMPLATE_DIR/template/}"
                dest="$WEB_DIR/$rel"
                if [ ! -f "$dest" ]; then
                    mkdir -p "$(dirname "$dest")"
                    cp "$src" "$dest"
                    echo "  [NEW] $rel"
                fi
            done
            ;;
        r|R)
            echo "Replacing $WEB_DIR/ with template..."
            # Preserve node_modules and .next
            if [ -d "$WEB_DIR/node_modules" ]; then
                mv "$WEB_DIR/node_modules" "/tmp/web-stack-nm-$$"
            fi
            if [ -d "$WEB_DIR/.next" ]; then
                mv "$WEB_DIR/.next" "/tmp/web-stack-next-$$"
            fi
            rm -rf "$WEB_DIR/src" "$WEB_DIR/tests" "$WEB_DIR/public"
            copy_template_clean
            if [ -d "/tmp/web-stack-nm-$$" ]; then
                mv "/tmp/web-stack-nm-$$" "$WEB_DIR/node_modules"
            fi
            if [ -d "/tmp/web-stack-next-$$" ]; then
                mv "/tmp/web-stack-next-$$" "$WEB_DIR/.next"
            fi
            ;;
        *)
            echo "Skipped file copy."
            ;;
    esac
else
    echo "Creating $WEB_DIR/ from template..."
    mkdir -p "$WEB_DIR"
    copy_template_clean
    echo "Done."
fi

# ============================================================
# STEP 2: Replace placeholders
# ============================================================

echo ""
echo "Configuring project..."

# Ask for app name
read -p "App title [My App]: " APP_TITLE
APP_TITLE="${APP_TITLE:-My App}"

read -p "App description [A web application]: " APP_DESC
APP_DESC="${APP_DESC:-A web application}"

# Slugify project name for package.json
PKG_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

# Replace placeholders
find "$WEB_DIR/src" -type f -name "*.tsx" -o -name "*.ts" | while read -r f; do
    sed -i "s/__APP_TITLE__/$APP_TITLE/g" "$f"
    sed -i "s/__APP_DESCRIPTION__/$APP_DESC/g" "$f"
done

sed -i "s/__PROJECT_NAME__/$PKG_NAME/g" "$WEB_DIR/package.json"
if [ -f "$WEB_DIR/package-lock.json" ]; then
    sed -i "s/__PROJECT_NAME__/$PKG_NAME/g" "$WEB_DIR/package-lock.json"
fi

echo "Configured: $APP_TITLE ($PKG_NAME)"

# ============================================================
# STEP 3: Inject CLAUDE.md block
# ============================================================

echo ""
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"

inject_claude_block() {
    local SOURCE_BLOCK="$TEMPLATE_DIR/web-claude.md"

    if [ ! -f "$SOURCE_BLOCK" ]; then
        echo "web-claude.md not found in template. Skipping CLAUDE.md injection."
        return
    fi

    local NEW_BLOCK
    NEW_BLOCK=$(cat "$SOURCE_BLOCK")

    if [ ! -f "$CLAUDE_MD" ]; then
        echo "No CLAUDE.md found. Creating with web stack block..."
        echo "$NEW_BLOCK" > "$CLAUDE_MD"
        echo "[CREATED] CLAUDE.md with web stack rules"
        return
    fi

    if grep -q "$MARKER_START" "$CLAUDE_MD" 2>/dev/null; then
        local CURRENT_BLOCK
        CURRENT_BLOCK=$(sed -n "/$MARKER_START/,/$MARKER_END/p" "$CLAUDE_MD")

        if [ "$CURRENT_BLOCK" = "$NEW_BLOCK" ]; then
            echo "CLAUDE.md web stack block is up to date."
            return
        fi

        echo "Updating web stack block in CLAUDE.md..."
        local TEMP_FILE
        TEMP_FILE=$(mktemp)
        sed -n "1,/$MARKER_START/p" "$CLAUDE_MD" | head -n -1 > "$TEMP_FILE"
        cat "$SOURCE_BLOCK" >> "$TEMP_FILE"
        sed -n "/$MARKER_END/,\$p" "$CLAUDE_MD" | tail -n +2 >> "$TEMP_FILE"
        mv "$TEMP_FILE" "$CLAUDE_MD"
        echo "[UPDATED] web stack block in CLAUDE.md"
    else
        echo "Appending web stack block to CLAUDE.md..."
        echo "" >> "$CLAUDE_MD"
        cat "$SOURCE_BLOCK" >> "$CLAUDE_MD"
        echo "[APPENDED] web stack block to CLAUDE.md"
    fi
}

inject_claude_block

# ============================================================
# STEP 4: Install dependencies
# ============================================================

echo ""
read -p "Install npm dependencies now? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$WEB_DIR"
    if [ -f "package-lock.json" ]; then
        npm ci
    else
        npm install
    fi
    npx playwright install chromium 2>/dev/null || true
    cd "$PROJECT_DIR"
    echo "Dependencies installed."
else
    echo "Skipped. Run 'cd $WEB_DIR && npm ci' when ready."
fi

# ============================================================
# STEP 5: Summary
# ============================================================

echo ""
echo "Web Stack Template v1.0 initialized in $WEB_DIR/"
echo ""
echo "Stack:"
echo "  Next.js 16 + React 19 + TypeScript strict"
echo "  Tailwind CSS v4 + shadcn/ui pattern"
echo "  TanStack Query v5 + Zustand v5"
echo "  React Hook Form v7 + Zod v4"
echo "  Supabase SSR + Lucide React"
echo "  Vitest + Playwright + Testing Library"
echo ""
echo "Included:"
echo "  12 UI components (Button, Badge, Card, Table, Dialog, etc.)"
echo "  Service query hooks (useServiceQuery, useServiceMutation)"
echo "  Auth store (Zustand)"
echo "  Supabase clients (browser, server, middleware)"
echo "  Route protection (proxy.ts)"
echo "  Design tokens (CSS variables)"
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env.local and fill in Supabase credentials"
echo "  2. Customize design tokens in src/app/globals.css"
echo "  3. Add your routes and services"
echo "  4. Run: cd $WEB_DIR && npm run dev"
echo ""
echo "Spec: https://github.com/oscarsovino/web-stack-template/blob/main/SPEC.md"
