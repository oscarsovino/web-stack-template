#!/bin/bash
# Web Stack Template Initializer v1.9
# Usage: bash <(curl -s https://raw.githubusercontent.com/oscarsovino/web-stack-template/main/init-web-stack.sh) [target-dir] [--preset=admin|consumer|none]
# Or from cloned repo: ./init-web-stack.sh [target-dir] [--preset=admin|consumer|none]

set -e

# ----------------------------------------------------------
# Prerequisite checks
# ----------------------------------------------------------

# Node 22.x required so the generated project matches the pinned engines field
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

# tar is required to overlay files without leaking dev artifacts
for cmd in tar sed grep; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd not found in PATH."
        exit 1
    fi
done

PROJECT_DIR=$(pwd)
PROJECT_NAME=$(basename "$PROJECT_DIR")
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKER_START="<!-- WEB-STACK-START -->"
MARKER_END="<!-- WEB-STACK-END -->"

# Parse args: positional target dir + optional --preset flag
WEB_DIR="web"
PRESET="none"
for arg in "$@"; do
    case "$arg" in
        --preset=*) PRESET="${arg#--preset=}" ;;
        --*) echo "Unknown flag: $arg"; exit 1 ;;
        *) WEB_DIR="$arg" ;;
    esac
done

case "$PRESET" in
    admin|consumer|none) ;;
    *) echo "Error: --preset must be admin, consumer, or none (got: $PRESET)."; exit 1 ;;
esac

if [ "$PRESET" != "none" ] && [ ! -d "$TEMPLATE_DIR/presets/$PRESET" ]; then
    echo "Error: preset '$PRESET' not found at $TEMPLATE_DIR/presets/$PRESET"
    exit 1
fi

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

echo "Web Stack Template v1.9 (red-team pass 2)"
echo "Project: $PROJECT_NAME"
echo "Target:  $WEB_DIR/"
echo "Preset:  $PRESET"
echo ""

# Apply a preset overlay on top of the already-copied core template.
# - Copies files from presets/<name>/{src,public} into $WEB_DIR (tar-based, skips node_modules etc.)
# - Merges package.json.extra into $WEB_DIR/package.json via Node
# - Appends globals.css.extra to $WEB_DIR/src/app/globals.css
apply_preset() {
    local preset_name="$1"
    local preset_dir="$TEMPLATE_DIR/presets/$preset_name"

    # Overlay src/ and public/ if present
    for overlay in src public; do
        if [ -d "$preset_dir/$overlay" ]; then
            (cd "$preset_dir" && tar \
                --exclude=node_modules \
                --exclude=.next \
                --exclude=.DS_Store \
                -cf - "$overlay") | (cd "$WEB_DIR" && tar -xf -)
        fi
    done

    # Merge package.json.extra (deps + devDeps)
    if [ -f "$preset_dir/package.json.extra" ]; then
        node -e "
            const fs = require('fs');
            const base = JSON.parse(fs.readFileSync('$WEB_DIR/package.json', 'utf8'));
            const extra = JSON.parse(fs.readFileSync('$preset_dir/package.json.extra', 'utf8'));
            for (const key of Object.keys(extra)) {
                base[key] = Object.assign({}, base[key] || {}, extra[key]);
            }
            for (const deps of ['dependencies', 'devDependencies']) {
                if (base[deps]) {
                    base[deps] = Object.fromEntries(Object.entries(base[deps]).sort());
                }
            }
            fs.writeFileSync('$WEB_DIR/package.json', JSON.stringify(base, null, 2) + '\n');
        "
    fi

    # Append globals.css.extra
    if [ -f "$preset_dir/globals.css.extra" ]; then
        local globals="$WEB_DIR/src/app/globals.css"
        if [ -f "$globals" ]; then
            printf '\n' >> "$globals"
            cat "$preset_dir/globals.css.extra" >> "$globals"
        fi
    fi

    echo "Applied preset: $preset_name"
}

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
# STEP 1b: Apply preset overlay (if requested)
# ============================================================

if [ "$PRESET" != "none" ]; then
    apply_preset "$PRESET"
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

# Replace placeholders in source files (.ts/.tsx under src/)
find "$WEB_DIR/src" -type f \( -name "*.tsx" -o -name "*.ts" \) | while read -r f; do
    sed -i "s/__APP_TITLE__/$APP_TITLE/g" "$f"
    sed -i "s/__APP_DESCRIPTION__/$APP_DESC/g" "$f"
done

# Replace placeholders in public/ assets that may reference them (PWA manifest, etc.)
if [ -d "$WEB_DIR/public" ]; then
    find "$WEB_DIR/public" -type f \( -name "*.json" -o -name "*.webmanifest" -o -name "*.html" \) | while read -r f; do
        sed -i "s/__APP_TITLE__/$APP_TITLE/g" "$f"
        sed -i "s/__APP_DESCRIPTION__/$APP_DESC/g" "$f"
    done
fi

sed -i "s/__PROJECT_NAME__/$PKG_NAME/g" "$WEB_DIR/package.json"
if [ -f "$WEB_DIR/package-lock.json" ]; then
    sed -i "s/__PROJECT_NAME__/$PKG_NAME/g" "$WEB_DIR/package-lock.json"
fi

echo "Configured: $APP_TITLE ($PKG_NAME)"

# ============================================================
# STEP 2.5: Supabase credentials -> .env.local
# ============================================================

echo ""
echo "Supabase credentials (press Enter to skip any field; .env.local is created only if URL and key are provided)."
read -p "NEXT_PUBLIC_SUPABASE_URL: " SUPABASE_URL
read -p "NEXT_PUBLIC_SUPABASE_ANON_KEY: " SUPABASE_KEY
read -p "NEXT_PUBLIC_APP_URL [http://localhost:3000]: " APP_URL
APP_URL="${APP_URL:-http://localhost:3000}"

if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_KEY" ]; then
    ENV_LOCAL="$WEB_DIR/.env.local"
    if [ -f "$ENV_LOCAL" ]; then
        echo ".env.local already exists; leaving it untouched."
    else
        cat > "$ENV_LOCAL" <<ENV
NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_KEY
NEXT_PUBLIC_APP_URL=$APP_URL
ENV
        echo "[CREATED] $ENV_LOCAL"
    fi

    # Offer to generate Supabase TypeScript types if the CLI is installed.
    if command -v supabase >/dev/null 2>&1; then
        # Extract project ref from URL like https://<ref>.supabase.co
        PROJECT_REF=$(echo "$SUPABASE_URL" | sed -nE 's|https?://([^.]+)\.supabase\.co.*|\1|p')
        if [ -n "$PROJECT_REF" ]; then
            read -p "Generate Supabase types from project $PROJECT_REF? [y/N] " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                mkdir -p "$WEB_DIR/src/lib/supabase"
                if supabase gen types typescript --project-id "$PROJECT_REF" > "$WEB_DIR/src/lib/supabase/database.types.ts" 2>/dev/null; then
                    echo "[CREATED] $WEB_DIR/src/lib/supabase/database.types.ts"
                else
                    echo "Note: supabase gen types failed. Run 'supabase login' first, then: supabase gen types typescript --project-id $PROJECT_REF > $WEB_DIR/src/lib/supabase/database.types.ts"
                fi
            fi
        fi
    else
        echo "Note: 'supabase' CLI not installed. Skip type generation. To add it later: npm i -g supabase, then 'supabase login' and run 'supabase gen types typescript --project-id <ref> > $WEB_DIR/src/lib/supabase/database.types.ts'."
    fi
else
    echo "Skipped .env.local (fill in NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY manually)."
fi

# ============================================================
# STEP 2.6: Detect monorepo context
# ============================================================

if [ -f "$PROJECT_DIR/package.json" ] && node -e "const p=require('$PROJECT_DIR/package.json'); process.exit(Array.isArray(p.workspaces) || (p.workspaces && p.workspaces.packages) ? 0 : 1)" 2>/dev/null; then
    echo ""
    echo "Detected npm workspace at $PROJECT_DIR."
    if [ -d "$PROJECT_DIR/packages" ]; then
        AVAILABLE=$(ls "$PROJECT_DIR/packages" 2>/dev/null | head -10 | tr '\n' ' ')
        if [ -n "$AVAILABLE" ]; then
            echo "Available workspace packages under packages/: $AVAILABLE"
            echo "You can import from @aldia/* (or your workspace scope) inside $WEB_DIR/."
        fi
    fi
fi

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
    # If a preset added deps, the committed lockfile is stale; regenerate it.
    if [ "$PRESET" != "none" ]; then
        npm install
        echo "Note: lockfile regenerated because preset '$PRESET' added deps. Commit package-lock.json in your first PR."
    elif [ -f "package-lock.json" ]; then
        npm ci
    else
        npm install
    fi
    npx playwright install chromium 2>/dev/null || true
    cd "$PROJECT_DIR"
    echo "Dependencies installed."
else
    if [ "$PRESET" != "none" ]; then
        echo "Skipped. Run 'cd $WEB_DIR && npm install' (preset added deps, lockfile is stale)."
    else
        echo "Skipped. Run 'cd $WEB_DIR && npm ci' when ready."
    fi
fi

# ============================================================
# STEP 5: Summary
# ============================================================

echo ""
echo "Web Stack Template v1.9 initialized in $WEB_DIR/ (preset: $PRESET)"
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
if [ ! -f "$WEB_DIR/.env.local" ]; then
    echo "  1. Copy .env.example to .env.local and fill in Supabase credentials"
else
    echo "  1. Review .env.local (generated from prompts)"
fi
echo "  2. Customize design tokens in src/app/globals.css"
echo "  3. Run: cd $WEB_DIR && npm run doctor   # typecheck + format:check + lint + check-spec + test"
echo "  4. Run: cd $WEB_DIR && npm run dev"
echo ""
echo "Spec: https://github.com/oscarsovino/web-stack-template/blob/main/SPEC.md"
