"use client"

import { useEffect } from "react"
import { useAuthStore, type ThemePreference } from "@/lib/stores/auth-store"

const STORAGE_KEY = "theme-preference"

function resolve(preference: ThemePreference): "light" | "dark" {
  if (preference !== "system") return preference
  if (typeof window === "undefined") return "light"
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
}

function apply(resolved: "light" | "dark") {
  if (typeof document === "undefined") return
  document.documentElement.dataset.theme = resolved
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const theme = useAuthStore((s) => s.theme)
  const setTheme = useAuthStore((s) => s.setTheme)

  useEffect(() => {
    const saved = (typeof window !== "undefined" &&
      localStorage.getItem(STORAGE_KEY)) as ThemePreference | null
    if (saved && saved !== theme) setTheme(saved)
  }, [theme, setTheme])

  useEffect(() => {
    apply(resolve(theme))
    if (typeof window !== "undefined") localStorage.setItem(STORAGE_KEY, theme)
  }, [theme])

  useEffect(() => {
    if (typeof window === "undefined" || theme !== "system") return
    const mq = window.matchMedia("(prefers-color-scheme: dark)")
    const listener = () => apply(resolve("system"))
    mq.addEventListener("change", listener)
    return () => mq.removeEventListener("change", listener)
  }, [theme])

  return <>{children}</>
}
