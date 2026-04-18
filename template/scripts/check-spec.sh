#!/usr/bin/env bash
# SPEC conformance checks that ESLint cannot express cleanly at the file level.
# Keep this short and auditable; defer rule-level checks to ESLint.

set -euo pipefail

errors=0
root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

# 1. Next.js middleware.ts at the routing entry point is forbidden.
#    Next 16 uses src/proxy.ts. Helpers deeper in src (e.g. lib/supabase/middleware.ts) are fine.
for candidate in middleware.ts src/middleware.ts; do
    if [ -f "$candidate" ]; then
        echo "error: $candidate found. Next 16 requires src/proxy.ts instead. (SPEC §4.2)"
        errors=$((errors + 1))
    fi
done

# 2. process.env.NEXT_PUBLIC_* direct reads outside lib/env.ts are forbidden.
#    Import from @/lib/env so validation stays in one place.
if grep -rnE 'process\.env\.NEXT_PUBLIC_' src \
       --include='*.ts' \
       --include='*.tsx' \
       | grep -v 'src/lib/env.ts' >&2; then
    echo "error: direct process.env.NEXT_PUBLIC_* access outside src/lib/env.ts. Import from @/lib/env instead. (SPEC §8.1)"
    errors=$((errors + 1))
fi

# 3. Authenticated route groups must not force-static.
#    Routes under (app)/, (dashboard)/, (user)/ read user-scoped data; caching them
#    statically would serve one user's HTML to another. Default is force-dynamic
#    (set at the layout level); this check catches accidental overrides.
for group in '(app)' '(dashboard)' '(user)'; do
    # shellcheck disable=SC2086 -- globbing is intentional
    offenders=$(grep -rnE '(export const dynamic\s*=\s*["'\'']force-static["'\'']|export const dynamic\s*=\s*["'\'']static["'\''])' \
                   "src/app/$group" 2>/dev/null || true)
    if [ -n "$offenders" ]; then
        echo "$offenders"
        echo "error: force-static is forbidden under src/app/$group (authenticated routes). Remove the override or move the route out of the group. (SPEC §12)"
        errors=$((errors + 1))
    fi
done

if [ "$errors" -gt 0 ]; then
    exit 1
fi

echo "check-spec: OK"
