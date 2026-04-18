import { create } from "zustand"

export interface ConsumerProfile {
  id: string
  email: string
  fullName: string
  avatarUrl: string | null
}

export type ThemePreference = "light" | "dark" | "system"

export interface ConsumerAuthState {
  userId: string | null
  profile: ConsumerProfile | null
  theme: ThemePreference
  language: string
  loading: boolean
  setUser: (userId: string, profile: ConsumerProfile) => void
  setTheme: (theme: ThemePreference) => void
  setLanguage: (language: string) => void
  clear: () => void
  setLoading: (loading: boolean) => void
}

export const useAuthStore = create<ConsumerAuthState>((set) => ({
  userId: null,
  profile: null,
  theme: "system",
  language: "es",
  loading: false,
  setUser: (userId, profile) => set({ userId, profile }),
  setTheme: (theme) => set({ theme }),
  setLanguage: (language) => set({ language }),
  clear: () => set({ userId: null, profile: null }),
  setLoading: (loading) => set({ loading }),
}))
