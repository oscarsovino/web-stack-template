"use client"

import { useEffect } from "react"

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error("[route error]", error)
  }, [error])

  return (
    <div
      role="alert"
      aria-live="assertive"
      className="flex flex-col items-center justify-center py-16 gap-4 text-center"
    >
      <h2 className="text-xl font-semibold">Algo salio mal</h2>
      <p className="text-sm text-gray-600 max-w-md">
        La pagina no pudo cargarse. Intenta de nuevo; si persiste, reporta el problema.
      </p>
      <button
        type="button"
        onClick={reset}
        className="px-4 py-2 rounded-lg bg-accent text-white hover:bg-accent-hover focus-visible:outline-2 focus-visible:outline-accent"
      >
        Reintentar
      </button>
    </div>
  )
}
