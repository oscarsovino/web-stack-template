"use client"

import { useAuthStore, type ThemePreference } from "@/lib/stores/auth-store"

export function useTheme() {
  const theme = useAuthStore((s) => s.theme)
  const setTheme = useAuthStore((s) => s.setTheme)
  return { theme, setTheme } as { theme: ThemePreference; setTheme: (t: ThemePreference) => void }
}
