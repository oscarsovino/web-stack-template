import { create } from "zustand"

export interface AgentInfo {
  id: string
  companyId: string
  agentRole: "admin" | "supervisor" | "agent"
}

export interface AdminAuthState {
  userId: string | null
  email: string | null
  role: "admin" | "supervisor" | "agent" | null
  agent: AgentInfo | null
  loading: boolean
  setUser: (userId: string, email: string, role: AdminAuthState["role"]) => void
  setAgent: (agent: AgentInfo | null) => void
  clear: () => void
  setLoading: (loading: boolean) => void
}

export const useAuthStore = create<AdminAuthState>((set) => ({
  userId: null,
  email: null,
  role: null,
  agent: null,
  loading: false,
  setUser: (userId, email, role) => set({ userId, email, role }),
  setAgent: (agent) => set({ agent }),
  clear: () => set({ userId: null, email: null, role: null, agent: null }),
  setLoading: (loading) => set({ loading }),
}))
