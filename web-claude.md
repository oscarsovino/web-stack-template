<!-- WEB-STACK-START -->
## Web Standard Stack (mandatory for all web apps)

> This block is maintained by web-stack-template.
> Updated via `init-web-stack.sh` without touching content outside markers.
> Source: https://github.com/oscarsovino/web-stack-template

Any new web application in this project MUST use the following standardized stack:
- **Framework:** Next.js 16 + React 19 + TypeScript strict
- **Styling:** Tailwind CSS v4 + shadcn/ui pattern (`cva` + `cn()` + `tailwind-merge`)
- **Components:** `web/src/components/ui/` — shared component library (Button, Badge, Card, Table, Dialog, Input, etc.)
- **Server state:** TanStack Query v5 (`useServiceQuery`, `useServiceMutation`)
- **Client state:** Zustand v5
- **Forms:** React Hook Form v7 + Zod v4
- **Auth:** Supabase SSR (`@supabase/ssr`)
- **Testing:** Vitest + Playwright + Testing Library
- **Icons:** Lucide React
- **Service pattern:** Service objects with async methods, no ORM, no FK JOINs to `auth.users`
- **Middleware:** `proxy.ts` (Next.js 16 pattern, NOT `middleware.ts`)

Do NOT introduce alternative frameworks, state managers, CSS approaches, or component libraries without explicit approval.

### Web Stack Rules for AI Agents
1. Components use `cva` + `cn()` pattern — never inline Tailwind without variants
2. `proxy.ts` for middleware, NOT `middleware.ts`
3. No FK JOINs to `auth.users` — use separate queries to `profiles` table
4. Services are plain objects with async methods — no classes, no ORM
5. Zustand for client state, TanStack Query for server state — never mix
6. Design tokens via CSS variables in `globals.css` + `@theme inline`
7. TypeScript strict: no `@ts-ignore`, no `any`
8. Vitest for unit/integration, Playwright for E2E

### Web Stack Spec
Full specification: https://github.com/oscarsovino/web-stack-template/blob/main/SPEC.md
<!-- WEB-STACK-END -->
