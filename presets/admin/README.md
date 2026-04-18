# Admin preset

Overlay on top of the core template for **back-office dashboards** (multi-role, sidebar-driven, internal users).

## What this preset adds / replaces

| File | Action | Purpose |
|---|---|---|
| `src/app/(dashboard)/layout.tsx` | Adds | Sidebar layout with collapsible nav; expects `useAuthStore` to expose `role` and optional `agent` |
| `src/app/robots.ts` | Replaces core | `Disallow: /` — admin is never indexed |
| `src/lib/stores/auth-store.ts` | Replaces core | Zustand store with `role: 'admin'\|'supervisor'\|'agent'` + `agent: AgentInfo \| null` |
| `globals.css.extra` | Appended | No dark-mode vars; single internal theme |
| `package.json.extra` | Merged | `recharts` for admin charts (optional) |

## What stays from the core

Everything in `src/lib/supabase/`, `src/lib/env.ts`, `src/lib/hooks/`, `proxy.ts`, all UI primitives, tests scaffolding, ESLint + Prettier + SPEC checks.

## Initialization

```bash
bash /path/to/init-web-stack.sh web --preset=admin
```

The init script copies the core template first, then overlays this preset on top.
