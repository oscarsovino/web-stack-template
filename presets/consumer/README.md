# Consumer preset

Overlay on top of the core template for **consumer-facing apps** (public users, SEO-critical, light/dark, i18n from day one).

## What this preset adds / replaces

| File | Action | Purpose |
|---|---|---|
| `src/app/(app)/layout.tsx` | Adds | Responsive navbar: bottom tabs on mobile viewport, top nav on desktop |
| `src/app/robots.ts` | Replaces core | `Allow: /` (public site) |
| `src/lib/stores/auth-store.ts` | Replaces core | Zustand store with `profile`, `theme`, `language` (no role matrix) |
| `src/lib/theme/theme-provider.tsx` | Adds | Reads preference from localStorage, writes `data-theme` on `<html>`, listens to `prefers-color-scheme` |
| `src/lib/theme/use-theme.ts` | Adds | Hook: `setTheme('light' \| 'dark' \| 'system')` |
| `public/manifest.json` | Adds | PWA manifest placeholder — fill in name, icons, theme_color |
| `globals.css.extra` | Appended | `:root` light vars + `:root[data-theme="dark"]` dark vars. Works with `@aldia/shared-tokens` if consuming from a workspace |
| `package.json.extra` | Merged | `next-intl` for RSC-safe i18n |

## What stays from the core

Everything in `src/lib/supabase/`, `src/lib/env.ts`, `src/lib/hooks/`, `proxy.ts`, all UI primitives, tests scaffolding, ESLint + Prettier + SPEC checks.

## Wiring into a monorepo

If the project is an npm workspace with `@aldia/shared-tokens`, `@aldia/shared-i18n`, `@aldia/shared-schemas`, etc., the preset's files import from those package names. Otherwise, they fall back to local paths inside `src/lib/`.

## Initialization

```bash
bash /path/to/init-web-stack.sh web-app --preset=consumer
```

The init script copies the core template first, then overlays this preset on top.
