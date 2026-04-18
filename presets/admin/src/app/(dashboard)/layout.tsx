import Link from "next/link"

/**
 * Admin layout stub: persistent sidebar.
 * Customize section items and role filtering for your org.
 */
const SECTIONS = [
  {
    heading: "Operaciones",
    items: [
      { href: "/supervisor", label: "Supervisor" },
      { href: "/agent", label: "Agente" },
    ],
  },
  {
    heading: "Plataforma",
    items: [
      { href: "/platform/users", label: "Usuarios" },
      { href: "/platform/companies", label: "Empresas" },
      { href: "/platform/analytics", label: "Analitica" },
    ],
  },
]

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <aside
        aria-label="Navegacion lateral"
        className="w-64 shrink-0 border-r bg-gray-50 px-4 py-6"
      >
        <Link href="/" className="block font-semibold mb-6">
          __APP_TITLE__
        </Link>
        <nav className="flex flex-col gap-6">
          {SECTIONS.map((section) => (
            <div key={section.heading}>
              <h3 className="text-xs uppercase tracking-wide text-gray-500 mb-2">
                {section.heading}
              </h3>
              <ul className="flex flex-col gap-1">
                {section.items.map((item) => (
                  <li key={item.href}>
                    <Link
                      href={item.href}
                      className="block rounded px-2 py-1 text-sm text-gray-700 hover:bg-gray-100"
                    >
                      {item.label}
                    </Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>
      </aside>
      <main className="flex-1 px-6 py-6">{children}</main>
    </div>
  )
}
