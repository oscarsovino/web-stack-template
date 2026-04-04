# Web Standard Stack — Especificacion Tecnica

> Version: 1.0.0
> Fecha: 2026-04-04
> Validado contra: State of JS 2025, Stack Overflow 2025, mejores practicas 2025-2026

## 1. Objetivo

Definir un stack web estandarizado y reproducible para todas las aplicaciones web del ecosistema. Cada decision tecnologica esta documentada con su justificacion y alternativas descartadas.

## 2. Stack completo

### 2.1 Framework: Next.js 16 + React 19

**Justificacion:**
- Next.js domina el mercado de frameworks React (>60% adoption en 2025)
- App Router es el estandar, Pages Router en modo legacy
- React 19 con Server Components, use() hook, Actions
- Next.js 16 introduce `proxy.ts` como reemplazo de `middleware.ts`

**Alternativas descartadas:**
- Remix: buen DX pero menor ecosistema y comunidad
- Vite + React: sin SSR/SSG built-in, requiere mas setup
- Astro: excelente para contenido estatico, limitado para apps interactivas

### 2.2 Language: TypeScript 5.x (strict mode)

**Justificacion:**
- Strict mode obligatorio: `strict: true` en tsconfig
- Sin `@ts-ignore` nunca, `@ts-expect-error` solo con justificacion
- Path aliases: `@/*` mapea a `./src/*`
- Module resolution: `bundler` (estandar Next.js 16)

**Configuracion critica:**
```json
{
  "compilerOptions": {
    "target": "ES2017",
    "strict": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "paths": { "@/*": ["./src/*"] }
  }
}
```

### 2.3 Styling: Tailwind CSS v4 + shadcn/ui pattern

**Justificacion:**
- Tailwind CSS v4 usa `@import "tailwindcss"` (no config file)
- PostCSS via `@tailwindcss/postcss`
- Design tokens como CSS variables en `:root`
- `@theme inline` para exponer variables a Tailwind
- Componentes siguen el pattern de shadcn/ui: `cva` + `cn()` + `tailwind-merge`

**Alternativas descartadas:**
- CSS Modules: mas verbose, sin utility-first
- Styled Components / Emotion: runtime CSS-in-JS, peor performance con RSC
- shadcn/ui directo: demasiado opinionado, preferimos solo el pattern

**Pattern obligatorio para componentes:**
```tsx
import { cva, type VariantProps } from "class-variance-authority"
import { cn } from "@/lib/utils"

const buttonVariants = cva("base-classes", {
  variants: { variant: { default: "...", secondary: "..." }, size: { sm: "...", default: "..." } },
  defaultVariants: { variant: "default", size: "default" },
})

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>,
  VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => (
    <button className={cn(buttonVariants({ variant, size, className }))} ref={ref} {...props} />
  )
)
```

**Funcion `cn()` (obligatoria):**
```ts
import { clsx, type ClassValue } from "clsx"
import { twMerge } from "tailwind-merge"
export function cn(...inputs: ClassValue[]) { return twMerge(clsx(inputs)) }
```

### 2.4 Server State: TanStack Query v5

**Justificacion:**
- Estandar de facto para server state en React (>80% adoption)
- Cache automatico, deduplicacion, revalidacion
- Devtools excelentes
- Separacion clara: TanStack = server state, Zustand = client state

**Hooks estandar:**
```tsx
// useServiceQuery — wrapper estandar
function useServiceQuery<T>(queryKey: unknown[], queryFn: () => Promise<T>, options?)
// useServiceMutation — con invalidacion automatica
function useServiceMutation<TData, TVariables>(mutationFn, options?: { invalidateKeys?: unknown[][] })
```

**Configuracion del QueryClient:**
```tsx
new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,        // 1 minuto
      refetchOnWindowFocus: false,  // evitar refetch inesperados
    },
  },
})
```

### 2.5 Client State: Zustand v5

**Justificacion:**
- Minimalista, sin boilerplate (vs Redux)
- Funciona con SSR/RSC sin hydration issues
- TypeScript first-class
- Solo para estado que NO viene del servidor

**Alternativas descartadas:**
- Redux Toolkit: overkill para la mayoria de apps web
- Jotai/Recoil: atomico es bueno pero menos adoption
- Context API: performance issues con re-renders frecuentes

**Pattern obligatorio:**
```ts
import { create } from "zustand"
interface AuthState {
  userId: string | null
  // ... state + actions juntos
}
export const useAuthStore = create<AuthState>((set, get) => ({
  // state + actions
}))
```

### 2.6 Forms: React Hook Form v7 + Zod v4

**Justificacion:**
- React Hook Form: uncontrolled forms, minimo re-render
- Zod: validacion runtime + inferencia de tipos en compilacion
- `@hookform/resolvers` conecta ambos

**Pattern:**
```tsx
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { z } from "zod"

const schema = z.object({ email: z.string().email(), name: z.string().min(2) })
type FormData = z.infer<typeof schema>

const { register, handleSubmit, formState: { errors } } = useForm<FormData>({
  resolver: zodResolver(schema),
})
```

### 2.7 Auth/DB: Supabase SSR

**Justificacion:**
- `@supabase/ssr` para Next.js App Router
- Tres clientes: browser (`createBrowserClient`), server (`createServerClient` con cookies), middleware (session refresh)
- Schema personalizado via `db: { schema: "..." }`
- No FK JOINs a `auth.users` — siempre queries separadas a tabla `profiles`

**Archivos obligatorios:**
- `lib/supabase/client.ts` — browser client
- `lib/supabase/server.ts` — server client (async, usa `cookies()`)
- `lib/supabase/middleware.ts` — session refresh + route protection

### 2.8 Testing: Vitest + Playwright + Testing Library

**Justificacion:**
- Vitest: compatible con Vite, 10x mas rapido que Jest, misma API
- Testing Library: testing centrado en usuario, no en implementacion
- Playwright: E2E robusto, multi-browser, auto-waiting
- MSW: mock de APIs en tests sin tocar codigo de produccion

**Configuracion Vitest:**
```ts
defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    coverage: { provider: 'v8', reporter: ['text', 'html'] },
  },
  resolve: { alias: { '@': path.resolve(__dirname, './src') } },
})
```

**Configuracion Playwright:**
```ts
defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  webServer: { command: 'npm run dev', url: 'http://localhost:3000' },
})
```

### 2.9 Icons: Lucide React

**Justificacion:**
- Fork activo de Feather Icons con mas iconos
- Tree-shakeable (solo importas lo que usas)
- Consistente visualmente

### 2.10 Utilities

- **date-fns v4**: funciones puras, tree-shakeable, no mutable
- **Recharts v3** (opcional): graficos para dashboards
- **clsx + tailwind-merge**: composicion de clases CSS

## 3. Estructura de directorios

```
web/
  src/
    app/                          # Next.js App Router
      layout.tsx                  # Root: fonts + QueryProvider
      globals.css                 # Design tokens + Tailwind v4
      page.tsx                    # Landing
      (auth)/                     # Route group: login, registro, recuperar
        layout.tsx                # Auth layout (centered, no nav)
      (public)/                   # Route group: paginas publicas
        layout.tsx                # Public layout (header + footer)
      (user)/                     # Route group: area autenticada
        layout.tsx                # User layout (nav lateral o tabs)
      dashboard/                  # Admin area
        layout.tsx                # Admin layout (sidebar + topbar)
      api/                        # API routes (Route Handlers)
      global-error.tsx            # Error boundary global
      robots.ts                   # SEO
      sitemap.ts                  # SEO
    proxy.ts                      # Middleware (Next.js 16)
    lib/
      utils.ts                    # cn(), formatDate(), formatCurrency()
      supabase/
        client.ts                 # createBrowserClient
        server.ts                 # createServerClient
        middleware.ts              # updateSession
      providers/
        query-provider.tsx        # QueryClientProvider
        index.ts
      hooks/
        use-service-query.ts      # useServiceQuery, useServiceMutation
        index.ts
      stores/
        auth-store.ts             # Zustand: user, roles, admin
      services/
        index.ts                  # Barrel exports
        [entity]-service.ts       # Un service por entidad
    components/
      ui/                         # Componentes base (pure, reusable)
        index.ts
        button.tsx
        badge.tsx
        card.tsx
        input.tsx
        select.tsx
        textarea.tsx
        label.tsx
        table.tsx
        dialog.tsx
        spinner.tsx
        skeleton.tsx
      [domain]/                   # Componentes de dominio (opcional)
  tests/
    setup.ts                      # Vitest setup (testing-library matchers)
    unit/                         # Unit tests
    integration/                  # Integration tests
    e2e/                          # Playwright E2E tests
  public/                         # Static assets
```

## 4. Patrones obligatorios

### 4.1 Service Layer

- Un archivo por entidad: `[entity]-service.ts`
- Exporta un objeto con metodos async (no clase, no ORM)
- Cada metodo crea su propio Supabase client (`createClient()`)
- No FK JOINs a `auth.users` — enriquecer con query separada a `profiles`
- Barrel export en `services/index.ts`

### 4.2 Route Protection (proxy.ts)

- `proxy.ts` exporta `proxy()` y `config` (matcher)
- Llama a `updateSession()` de `lib/supabase/middleware.ts`
- `updateSession()` maneja: session refresh, public/user/admin routes
- Admin check via query a tabla de roles (no JWT custom claims)

### 4.3 Design Tokens

- CSS variables en `:root` (globals.css)
- `@theme inline` para exponerlas a Tailwind v4
- Temas via clases CSS (`.theme-admin`, `.theme-dark`, etc.)
- Nunca hardcodear colores en componentes

### 4.4 Layout Groups

- `(auth)` — centrado, sin navegacion
- `(public)` — header + footer, acceso libre
- `(user)` — requiere autenticacion
- `dashboard/` — requiere admin, sidebar layout

### 4.5 Error Handling

- `global-error.tsx` como boundary global
- Services lanzan errores, los consume el componente via TanStack Query `error` state
- No try/catch en componentes — dejar que Query maneje el estado

## 5. Scripts npm

```json
{
  "dev": "next dev",
  "build": "next build",
  "start": "next start",
  "lint": "eslint",
  "test": "vitest run",
  "test:watch": "vitest",
  "test:coverage": "vitest run --coverage",
  "test:e2e": "playwright test",
  "test:e2e:ui": "playwright test --ui"
}
```

## 6. Variables de entorno

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
NEXT_PUBLIC_APP_URL=http://localhost:3000
# Optional
SENTRY_ORG=
SENTRY_PROJECT=
SENTRY_AUTH_TOKEN=
```

## 7. Checklist de conformidad

- [ ] TypeScript strict, sin `@ts-ignore`
- [ ] `eslint` sin errores
- [ ] Componentes UI usan cva + cn pattern
- [ ] No colores hardcodeados — solo design tokens
- [ ] Services como objetos, no clases
- [ ] No FK JOINs a auth.users
- [ ] TanStack Query para server state, Zustand para client state
- [ ] proxy.ts (no middleware.ts)
- [ ] Tests unitarios con Vitest
- [ ] Tests E2E con Playwright
- [ ] Sin dependencias no aprobadas
