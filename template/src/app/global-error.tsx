"use client"

import { useEffect } from "react"

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error("[global error]", error)
  }, [error])

  return (
    <html lang="es">
      <body className="flex min-h-screen items-center justify-center">
        <div role="alert" aria-live="assertive" className="text-center">
          <h2 className="text-2xl font-bold mb-4">Algo salio mal</h2>
          <p className="text-gray-600 mb-4">
            La pagina no pudo cargarse. Intenta de nuevo; si persiste, reporta el problema.
          </p>
          <button
            type="button"
            onClick={reset}
            className="px-4 py-2 bg-accent text-white rounded-lg hover:bg-accent-hover focus-visible:outline-2 focus-visible:outline-accent"
          >
            Reintentar
          </button>
        </div>
      </body>
    </html>
  )
}
