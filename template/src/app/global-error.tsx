"use client"

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <html>
      <body className="flex min-h-screen items-center justify-center">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Algo salio mal</h2>
          <p className="text-gray-600 mb-4">{error.message}</p>
          <button
            onClick={reset}
            className="px-4 py-2 bg-accent text-white rounded-lg hover:bg-accent-hover"
          >
            Reintentar
          </button>
        </div>
      </body>
    </html>
  )
}
