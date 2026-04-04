# Web Stack Template

Template estandarizado para aplicaciones web. Validado contra State of JS 2025, Stack Overflow 2025, y mejores practicas de industria 2025-2026.

## Stack

| Capa | Tecnologia | Version |
|------|-----------|---------|
| Framework | Next.js | 16.x |
| UI Library | React | 19.x |
| Language | TypeScript | 5.x (strict) |
| Styling | Tailwind CSS | v4 |
| Components | shadcn/ui pattern (cva + cn + tailwind-merge) | - |
| Server State | TanStack Query | v5 |
| Client State | Zustand | v5 |
| Forms | React Hook Form | v7 |
| Validation | Zod | v4 |
| Auth/DB | Supabase SSR | latest |
| Unit Tests | Vitest + Testing Library | latest |
| E2E Tests | Playwright | latest |
| Icons | Lucide React | latest |
| Dates | date-fns | v4 |
| Charts | Recharts | v3 (optional) |

## Quick Start

### Opcion 1: Inicializar en proyecto existente
```bash
bash <(curl -s https://raw.githubusercontent.com/oscarsovino/web-stack-template/main/init-web-stack.sh)
```

### Opcion 2: Desde clon local
```bash
git clone https://github.com/oscarsovino/web-stack-template.git
cd mi-proyecto
bash ../web-stack-template/init-web-stack.sh
```

### Opcion 3: Manual
```bash
cp -r /path/to/web-stack-template/template/* ./web/
cd web && npm install
```

## Que incluye

### Archivos de configuracion
- `next.config.ts` — Next.js 16 con Supabase image patterns
- `tsconfig.json` — strict mode, path aliases (`@/*`)
- `tailwind` via `postcss.config.mjs` + `globals.css` (design tokens como CSS variables)
- `eslint.config.mjs` — flat config, core-web-vitals + typescript
- `vitest.config.ts` — jsdom, path aliases, coverage v8
- `playwright.config.ts` — chromium, dev server auto-start

### Estructura de directorios
```
src/
  app/
    layout.tsx          # Root layout con QueryProvider + fonts
    globals.css         # Design tokens (CSS variables) + Tailwind v4
    page.tsx            # Landing page
    (auth)/             # Auth routes (login, registro, recuperar)
    (public)/           # Public routes
    (user)/             # Authenticated user routes
    dashboard/          # Admin routes
    api/                # API routes
  proxy.ts              # Next.js 16 middleware (NOT middleware.ts)
  lib/
    utils.ts            # cn(), formatDate(), formatCurrency()
    supabase/
      client.ts         # Browser Supabase client
      server.ts         # Server Supabase client
      middleware.ts      # Session refresh + route protection
    providers/
      query-provider.tsx # TanStack Query provider
      index.ts
    hooks/
      use-service-query.ts  # useServiceQuery + useServiceMutation
      index.ts
    stores/
      auth-store.ts     # Zustand auth store
    services/
      index.ts          # Barrel exports
  components/
    ui/                 # Base components (Button, Badge, Card, etc.)
      index.ts
```

### Componentes UI base
- `Button` (6 variants, 4 sizes, cva)
- `Badge` (variants: default, secondary, destructive, outline, success, warning)
- `Card` (Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter)
- `Input`, `Select`, `Textarea`, `Label`
- `Table` (Table, TableHeader, TableBody, TableRow, TableHead, TableCell)
- `Dialog` (Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter)
- `Spinner` (sm, md, lg)
- `Skeleton` (Skeleton, SkeletonCard, SkeletonTableRow, SkeletonText)

### Patrones incluidos
- **Service Layer**: objetos con metodos async, no ORM, no FK JOINs a `auth.users`
- **Query Hooks**: `useServiceQuery` / `useServiceMutation` sobre TanStack Query
- **Auth Store**: Zustand store con roles, admin check, hydration
- **Proxy Middleware**: `proxy.ts` con route protection (public/user/admin paths)
- **Design Tokens**: CSS variables en `:root` + `@theme inline` para Tailwind v4

## Decisiones arquitecturales

Ver [SPEC.md](./SPEC.md) para la especificacion completa con justificaciones.

## Reglas para AI Agents

Estas reglas se inyectan en el CLAUDE.md del proyecto via el init script:

1. No introducir frameworks, state managers, o CSS approaches alternativos sin aprobacion
2. Usar `proxy.ts` (Next.js 16), NO `middleware.ts`
3. No FK JOINs a `auth.users` — enriquecer con queries separadas a `profiles`
4. Componentes UI en `src/components/ui/` con pattern cva + cn
5. Services como objetos con metodos async, no clases, no ORM
6. Zustand para client state, TanStack Query para server state — no mezclar
7. Vitest para unit/integration, Playwright para E2E
8. TypeScript strict, no `@ts-ignore`, no `any`
