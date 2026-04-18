import { create } from "zustand"

interface AuthState {
  userId: string | null
  email: string | null
  fullName: string | null
  avatarUrl: string | null
  roles: string[]
  isAdmin: boolean
  isLoading: boolean
  isAuthenticated: boolean
  setUser: (
    userId: string,
    email: string,
    fullName: string | null,
    avatarUrl?: string | null,
  ) => void
  setRoles: (roles: string[]) => void
  hasRole: (role: string) => boolean
  clear: () => void
  setLoading: (loading: boolean) => void
}

export const useAuthStore = create<AuthState>((set, get) => ({
  userId: null,
  email: null,
  fullName: null,
  avatarUrl: null,
  roles: [],
  isAdmin: false,
  isLoading: true,
  isAuthenticated: false,
  setUser: (userId, email, fullName, avatarUrl = null) =>
    set({ userId, email, fullName, avatarUrl, isAuthenticated: true }),
  setRoles: (roles) => set({ roles, isAdmin: roles.includes("admin") }),
  hasRole: (role) => get().roles.includes(role),
  clear: () =>
    set({
      userId: null,
      email: null,
      fullName: null,
      avatarUrl: null,
      roles: [],
      isAdmin: false,
      isAuthenticated: false,
    }),
  setLoading: (isLoading) => set({ isLoading }),
}))
