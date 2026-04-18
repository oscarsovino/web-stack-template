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

# 3. Authenticated route groups must not opt into static caching.
#    Routes under (app)/, (dashboard)/, (user)/ read user-scoped data; caching
#    them statically (whether via `dynamic = "force-static"`, a `revalidate`
#    export, `unstable_cache`, or `fetch(..., { cache: "force-cache" })`) would
#    serve one user's HTML to another. Default is `force-dynamic` at the layout
#    level; these rules catch overrides and accidental static caches.
for group in '(app)' '(dashboard)' '(user)'; do
    dir="src/app/$group"
    [ -d "$dir" ] || continue

    # 3a. export const dynamic = "force-static" | "static"
    if offenders=$(grep -rnE 'export const dynamic\s*=\s*["'\''](force-static|static)["'\'']' "$dir" 2>/dev/null) && [ -n "$offenders" ]; then
        echo "$offenders"
        echo "error: force-static is forbidden under $dir (authenticated routes). Remove the override or move the route out of the group. (SPEC §12)"
        errors=$((errors + 1))
    fi

    # 3b. export const revalidate = <number>  (ISR across users)
    if offenders=$(grep -rnE 'export const revalidate\s*=\s*[0-9]' "$dir" 2>/dev/null) && [ -n "$offenders" ]; then
        echo "$offenders"
        echo "error: numeric 'export const revalidate' is forbidden under $dir — it caches the page across users. If the page can safely be shared, move it out of the authenticated group. (SPEC §12)"
        errors=$((errors + 1))
    fi

    # 3c. fetch(..., { cache: "force-cache" })
    if offenders=$(grep -rnE 'cache\s*:\s*["'\'']force-cache["'\'']' "$dir" 2>/dev/null) && [ -n "$offenders" ]; then
        echo "$offenders"
        echo "error: fetch with cache: 'force-cache' is forbidden under $dir (user-scoped data must not be shared-cached). Use cache: 'no-store' or omit. (SPEC §12)"
        errors=$((errors + 1))
    fi

    # 3d. unstable_cache usage with user-scoped callers is dangerous; flag any usage
    #     under auth groups so the author must justify or remove it.
    if offenders=$(grep -rnE '\bunstable_cache\b' "$dir" 2>/dev/null) && [ -n "$offenders" ]; then
        echo "$offenders"
        echo "error: unstable_cache is forbidden under $dir (its cache keys default to the argument tuple and do not include the user; accidental cross-user leakage). (SPEC §12)"
        errors=$((errors + 1))
    fi
done

if [ "$errors" -gt 0 ]; then
    exit 1
fi

echo "check-spec: OK"
