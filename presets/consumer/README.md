# Consumer preset

Overlay on top of the core template for **consumer-facing apps** (public users, SEO-critical, light/dark, i18n from day one).

## What this preset adds / replaces

| File | Action | Purpose |
|---|---|---|
| `src/app/(app)/layout.tsx` | Adds | Responsive navbar (bottom tabs on mobile, top nav on desktop); declares `dynamic = 'force-dynamic'` so authenticated RSCs never serve cached HTML across users |
| `src/app/robots.ts` | Replaces core | `Allow: /` (public site) |
| `src/lib/stores/auth-store.ts` | Replaces core | Zustand store with `profile`, `theme`, `language` (no role matrix) |
| `src/lib/theme/theme-provider.tsx` | Adds | Reads preference from localStorage, writes `data-theme` on `<html>`, listens to `prefers-color-scheme` |
| `src/lib/theme/use-theme.ts` | Adds | Hook: `setTheme('light' \| 'dark' \| 'system')` |
| `src/lib/i18n/config.ts` | Adds | i18next init with inline minimal resources; swap the `resources` object for an import from `@aldia/shared-i18n` when in a monorepo |
| `src/lib/i18n/provider.tsx` | Adds | `I18nProvider` wrapper for client components |
| `public/manifest.json` | Adds | PWA manifest placeholder — fill in name, icons, theme_color |
| `globals.css.extra` | Appended | `:root` light vars + `:root[data-theme="dark"]` dark vars. Works with `@aldia/shared-tokens` if consuming from a workspace |
| `package.json.extra` | Merged | `i18next@23` + `react-i18next@15` (same majors as mobile apps built with Ignite/Expo) |

## What stays from the core

Everything in `src/lib/supabase/`, `src/lib/env.ts`, `src/lib/hooks/`, `proxy.ts`, all UI primitives, tests scaffolding, ESLint + Prettier + SPEC checks.

## Why i18next, not next-intl

Mobile apps in this stack use `i18next` + `react-i18next` with placeholders like `%{var}` and `{{var}}`. Shipping the same libs on web keeps a single source of translations across both clients and avoids a semantic rewrite into ICU. The trade-off is that translated text is client-rendered (no RSC streaming of translations); we accept that in exchange for shared content.

## Wiring into a monorepo

If the project is an npm workspace with `@aldia/shared-*` packages, update the generated project's `next.config.ts` to transpile them:

```ts
const nextConfig: NextConfig = {
  transpilePackages: [
    "@aldia/shared-types",
    "@aldia/shared-schemas",
    "@aldia/shared-i18n",
    "@aldia/shared-tokens",
    "@aldia/shared-constants",
  ],
  // ...
}
```

Then inside `src/lib/i18n/config.ts` replace the inline `resources` / `DEFAULT_LANGUAGE` / `FALLBACK_LANGUAGE` with an import from `@aldia/shared-i18n`, and inside `src/app/globals.css` replace the literal CSS vars with the output of `toCssVariables()` from `@aldia/shared-tokens`. Everything else (auth store, theme provider, layout) works as-is.

## Authenticated routes

The consumer preset places authenticated UI under `src/app/(app)/`. The layout there forces dynamic rendering for the whole subtree. `scripts/check-spec.sh` fails if any file in `(app)/`, `(dashboard)/`, or `(user)/` declares `dynamic = 'force-static'`, so the rule can't be silently overridden per-route. If a route genuinely needs to be static, move it out of the authenticated group.

## Initialization

```bash
bash /path/to/init-web-stack.sh web-app --preset=consumer
```

The init script copies the core template first, then overlays this preset on top.
