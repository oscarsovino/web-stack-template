export default function Loading() {
  return (
    <div
      role="status"
      aria-live="polite"
      aria-busy="true"
      className="flex flex-col gap-3 py-16 px-4 max-w-2xl mx-auto"
    >
      <span className="sr-only">Cargando</span>
      <div className="h-6 w-1/3 rounded-md bg-gray-200 animate-pulse" />
      <div className="h-4 w-2/3 rounded-md bg-gray-200 animate-pulse" />
      <div className="h-4 w-1/2 rounded-md bg-gray-200 animate-pulse" />
    </div>
  )
}
