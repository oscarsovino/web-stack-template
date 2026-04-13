# Web Standard Stack — Especificacion Tecnica

> Version: 1.2.0
> Fecha: 2026-04-13
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

### 4.6 Server Actions (React 19)

Server Actions (`"use server"`) son el patron preferido para mutaciones desde Server y Client Components.

**Reglas de seguridad obligatorias:**

1. **Auth en TODA mutacion:** Toda server action que modifica datos DEBE llamar a la funcion de auth del proyecto (ej. `getCurrentUserOrThrow()`) y usar el ID retornado en el query. Nunca confiar solo en RLS — defense in depth.

```ts
"use server"
export async function updateItemAction(itemId: string, data: {...}) {
  const userId = await getCurrentUserOrThrow()  // OBLIGATORIO
  const { error } = await supabase
    .from("items")
    .update(data)
    .eq("id", itemId)
    .eq("user_id", userId)  // OBLIGATORIO — ownership check
  // ...
}
```

2. **Validacion con Zod en el entry point:** Validar shape, tipos, y limites antes de tocar la DB. UUID format, string maxlength, enum narrowing.

3. **Sanitizar errores al cliente:** Nunca retornar `error.message` de Supabase al cliente — puede leakear nombres de tablas, constraints, o schema. Retornar mensajes genericos y logear el detalle con `console.error`.

```ts
// MAL:  return { ok: false, error: error.message }
// BIEN: console.error("[action] failed", error)
//       return { ok: false, error: "Error al guardar" }
```

4. **No `dangerouslySetInnerHTML` con contenido de DB:** Nunca renderizar HTML crudo que venga de base de datos. Usar text rendering seguro o un sanitizer (DOMPurify) si se necesita markup.

### 4.7 Query Safety

- **`.limit()` obligatorio** en toda query de lista. Default: `.limit(200)`. Queries sin limite pueden traer miles de filas en produccion.
- Queries acotadas por ID (`.eq("id", x).single()`) no necesitan limit.
- Queries con filtro de fecha (ej. "hoy") son aceptables sin limit si el rango es acotado.

### 4.8 Optimistic Updates

Para UI que necesita respuesta inmediata (chat, toggles, drag):

1. Actualizar el estado local inmediatamente (optimista)
2. Ejecutar el server action en `startTransition`
3. **Si falla: rollback** — revertir el estado local y mostrar feedback de error
4. Nunca dejar un update optimista sin handler de error

```ts
const handleSend = () => {
  const optimistic = { id: `temp-${Date.now()}`, ...data }
  setItems(prev => [...prev, optimistic])  // optimista

  startTransition(async () => {
    const res = await createItemAction(data)
    if (!res.ok) {
      setItems(prev => prev.filter(i => i.id !== optimistic.id))  // rollback
      setError("No se pudo guardar")
    }
  })
}
```

### 4.9 AI/Copilot Features

Si la app incluye sugerencias generadas por IA o copilot:

1. **Disclaimer visible:** Toda seccion con sugerencias de IA debe tener un texto permanente tipo "Sugerencias — no sustituyen el juicio profesional".
2. **Framing no prescriptivo:** Usar "considera", "podria", "sugiere" — nunca "debes", "tienes que".
3. **Human-in-the-loop:** Toda accion derivada de una sugerencia requiere aceptacion explicita del usuario.

### 4.10 SVG Export to PNG

Si la app exporta contenido que mezcla HTML + SVG (canvas, graficos, diagramas) a PNG via `html-to-image` o similares:

**Regla critica:** todo atributo SVG que afecte el rasterizado DEBE ir como atributo inline del elemento React, NO solo como regla CSS. Las librerias serializan via `foreignObject` con `getComputedStyle`, pero pierden los defaults SVG y los `text-anchor`/`dominant-baseline` no siempre se respetan.

**Checklist obligatorio en elementos SVG que vayan a exportarse:**

- `<path>` → `fill="none"` inline (sin esto, Bezier curves se rellenan de negro)
- `<path>` stroke → color literal inline (no `var(--...)` que no resuelve)
- `<rect>` → `fill` y `stroke` literales inline
- `<text>` → `textAnchor`, `dominantBaseline`, `fontSize`, `fontWeight` como props, no solo CSS
- `<marker>` → `markerUnits="userSpaceOnUse"` (sin esto escalan con stroke-width y colapsan)

**Patron de export function:**

```ts
export async function exportAsPng(el: HTMLElement, filename: string) {
  // Guardar estado
  const orig = { transform: el.style.transform, transition: el.style.transition }
  try {
    // 1. Agregar clase .exporting que neutraliza efectos en TODOS los descendientes
    //    (box-shadow, filter, backdrop-filter se vuelven bloques negros)
    el.classList.add("exporting")
    el.style.transition = "none"
    // 2. Reset transform para capturar tamano natural, no el zoom/pan actual
    el.style.transform = "translate(0px, 0px) scale(1)"
    await new Promise(r => requestAnimationFrame(() => r(null)))

    const dataUrl = await toPng(el, {
      pixelRatio: 2,
      backgroundColor: "#ffffff",
      cacheBust: true,
      style: { filter: "none", boxShadow: "none", transform: "none" },
      filter: (node) => {
        // Excluir elementos UI no relevantes (hit-areas invisibles, overlays, etc.)
        const el = node as Element
        if (!el.classList) return true
        return !["hit-area", "overlay-ui"].some(c => el.classList.contains(c))
      },
    })
    // trigger download...
  } finally {
    el.classList.remove("exporting")
    Object.assign(el.style, orig)
  }
}
```

**CSS para neutralizar efectos en descendientes:**

```css
.exporting,
.exporting *,
.exporting *::before,
.exporting *::after {
  box-shadow: none !important;
  filter: none !important;
  backdrop-filter: none !important;
  text-shadow: none !important;
}
```

**Anti-patrones que causan bloques negros en PNG:**

- `stroke="transparent"` en paths de hit-area → se renderiza NEGRO opaco. Excluir del filter.
- `paint-order: stroke fill` con halo blanco → interpretado como stroke negro. Usar `<rect>` de fondo.
- `box-shadow` en nodos → bloques negros. Usar clase `.exporting`.

**Si html-to-image falla estructuralmente**, considerar `html2canvas-pro` (no usa `foreignObject`, compatible con Tailwind v4 `oklch`).

### 4.11 Audit Logging Utility

Para apps con datos sensibles (salud, financieros, legal) crear `lib/audit.ts` con una utility never-throw que loguea accesos y mutaciones criticas a una tabla `audit_logs`:

```ts
// lib/audit.ts
export type AuditAction = "session.create" | "payment.register" | ...
export async function auditLog(params: {
  userId: string
  action: AuditAction
  resourceType: string
  resourceId: string
  details?: Record<string, unknown>
}): Promise<void> {
  try {
    const supabase = await createServerSupabaseClient()
    await supabase.from("audit_logs").insert({ ... })
  } catch (err) {
    // Audit logging NUNCA debe romper el flujo principal
    console.error("[audit] log failed", err)
  }
}
```

**Reglas:**
- Tabla `audit_logs` append-only con `REVOKE UPDATE, DELETE`
- RLS `for insert with check (user_id = current_user_id())`
- Indexes en `user_id`, `action`, `created_at desc`
- Para mayor garantia: hash chain (cada row incluye hash del row previo) + backup WORM externo
- Llamar desde server actions criticos DESPUES de la mutacion exitosa
- Nunca logear prompts/responses completos sin evaluar PHI retention policy

### 4.12 CSV Export via Route Handler

Patron consistente para exportar reportes a CSV:

```ts
// app/api/<domain>/export/route.ts
export async function GET(req: NextRequest) {
  try {
    const userId = await getCurrentUserOrThrow()
    const { searchParams } = new URL(req.url)
    const type = searchParams.get("type") ?? "default"
    const from = searchParams.get("from") ?? undefined
    const to = searchParams.get("to") ?? undefined

    const rows = await fetchRows(userId, { type, from, to })
    const csv = buildCSV([HEADER, ...rows])

    return new NextResponse(csv, {
      status: 200,
      headers: {
        "Content-Type": "text/csv; charset=utf-8",
        "Content-Disposition": `attachment; filename="${type}-${from ?? "all"}.csv"`,
      },
    })
  } catch (err) {
    console.error("[export] failed", err)
    return NextResponse.json({ error: "Export failed" }, { status: 500 })
  }
}

function escapeCSV(v: unknown): string {
  if (v == null) return ""
  const s = String(v)
  if (/[",\n;]/.test(s)) return `"${s.replace(/"/g, '""')}"`
  return s
}
function buildCSV(rows: string[][]): string {
  return rows.map(r => r.map(escapeCSV).join(",")).join("\n")
}
```

**Reglas:**
- El route handler enforcea auth (no delegar a middleware solamente)
- Pre-calcular dimensiones en JS (no depender de formato Excel-specific)
- Escape correcto de comillas, comas, saltos de linea, punto y coma
- UTF-8 con BOM si target de Excel en Windows: `"\uFEFF" + csv`
- Dar nombre de archivo descriptivo con fechas en el filename

### 4.13 Service Types con Joins

Cuando un service retorna entidades enriquecidas con data de otras tablas, definir interfaces explicitas `XxxWith<Y>` que extiendan la entidad base:

```ts
// services/invoices-service.ts
export interface InvoiceWithPatient extends Invoice {
  patient: { id: string; full_name: string } | null
  items_count: number
  paid_amount: number
}

export interface InvoiceDetail extends Invoice {
  patient: { id: string; full_name: string } | null
  items: InvoiceItem[]
  payments: Array<{ id: string; amount: number; paid_at: string }>
}

export const invoicesService = {
  async list(userId: string): Promise<InvoiceWithPatient[]> { ... },
  async getById(userId: string, id: string): Promise<InvoiceDetail | null> { ... },
}
```

**Reglas:**
- Tipos especificos por vista/uso (list vs detail), no uno genirico con opcionales
- Exportar desde `services/index.ts`
- Evitar `XxxWith` dentro de componentes UI — pasarlo via props tipadas
- Supabase TS a veces infiere joins como arrays — castear via `unknown as ExpectedType` con comentario

### 4.14 Empty State Handling

Toda vista de lista, tabla o grafico DEBE manejar explicitamente el caso sin datos con un componente `.empty-state` o similar:

```tsx
{rows.length === 0 ? (
  <div className="empty-state">
    <Icon style={{ opacity: 0.4 }} />
    <div>No hay registros para los filtros seleccionados.</div>
    <Link href="/new">Crear el primero</Link>
  </div>
) : (
  <Table data={rows} />
)}
```

Tambien para charts con toda la data en cero y para endpoints que retornan `[]`.

### 4.15 Red Team Review Iterativo

Para features con alta sensibilidad (PHI, dinero, IA) aplicar Red Team en **dos rondas minimas**:

**Ronda 1 (sobre el diseno):** antes de escribir codigo, documentar en ADR y lanzar 3 ejes paralelos (seguridad, arquitectura, dominio/clinico/legal). Los blockers se incorporan al ADR antes de F0.

**Ronda 2 (sobre los guardrails):** despues de disenar las mitigaciones, lanzar Red Team otra vez para atacar cada guardrail especificamente. Suele descubrir que los guardrails son performativos (regex bypasseable, hash chain no tamper-evident, etc.).

Sin la segunda ronda, se implementan mitigaciones que dan falsa sensacion de seguridad. Con la segunda ronda se descubren problemas estructurales que requieren rediseno (ej. reemplazar hash chain interno por notarizacion externa).

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
- [ ] Server actions: auth + ownership en TODA mutacion
- [ ] Server actions: errores sanitizados (no leakear schema)
- [ ] Server actions: validacion Zod en el entry point
- [ ] Queries de lista con `.limit()`
- [ ] No `dangerouslySetInnerHTML` con contenido de DB
- [ ] Optimistic updates con rollback en caso de error
- [ ] AI features con disclaimer visible y framing no prescriptivo
- [ ] Export SVG/PNG: atributos SVG inline (fill, stroke, textAnchor), no solo CSS
- [ ] Audit log para mutaciones criticas (append-only, never-throw)
- [ ] CSV export via Route Handler con auth enforced
- [ ] Service types con joins via interfaces `XxxWith<Y>` explicitas
- [ ] Empty state handling en toda lista/tabla/chart
- [ ] Red Team en 2 rondas para features criticas (diseno + guardrails)
