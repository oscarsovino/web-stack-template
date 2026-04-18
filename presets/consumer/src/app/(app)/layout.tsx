import Link from "next/link"

// Authenticated consumer routes read user-scoped data; never let Next cache them
// statically across users. SPEC section 12.
export const dynamic = "force-dynamic"

/**
 * Consumer layout: bottom tabs on mobile viewport, top nav on desktop.
 * Customize tab items for your app.
 */
const NAV_ITEMS = [
  { href: "/home", label: "Inicio" },
  { href: "/empresas", label: "Empresas" },
  { href: "/pedidos", label: "Pedidos" },
  { href: "/recompensas", label: "Recompensas" },
  { href: "/perfil", label: "Perfil" },
]

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-full flex flex-col">
      <header
        aria-label="Navegacion principal"
        className="hidden sm:flex sticky top-0 z-40 items-center gap-6 border-b bg-white/80 backdrop-blur px-6 h-14"
      >
        <Link href="/home" className="font-semibold">
          __APP_TITLE__
        </Link>
        <nav className="flex items-center gap-4 text-sm">
          {NAV_ITEMS.map((item) => (
            <Link key={item.href} href={item.href} className="text-gray-600 hover:text-gray-900">
              {item.label}
            </Link>
          ))}
        </nav>
      </header>

      <main className="flex-1 px-4 pt-4 pb-24 sm:pb-8 max-w-2xl mx-auto w-full">{children}</main>

      <nav
        aria-label="Navegacion principal"
        className="sm:hidden fixed bottom-0 inset-x-0 z-40 border-t bg-white/95 backdrop-blur"
      >
        <ul className="flex justify-around items-stretch h-16">
          {NAV_ITEMS.map((item) => (
            <li key={item.href} className="flex-1">
              <Link
                href={item.href}
                className="flex flex-col items-center justify-center h-full text-xs text-gray-600 hover:text-gray-900 focus-visible:outline-2 focus-visible:outline-accent"
              >
                {item.label}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
    </div>
  )
}
