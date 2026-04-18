import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const VALID_ENV = {
  NEXT_PUBLIC_SUPABASE_URL: "https://project.supabase.co",
  NEXT_PUBLIC_SUPABASE_ANON_KEY: "test-anon-key",
  NEXT_PUBLIC_APP_URL: "http://localhost:3000",
}

describe("env validation", () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.unstubAllEnvs()
  })

  it("parses valid environment variables", async () => {
    for (const [key, value] of Object.entries(VALID_ENV)) {
      vi.stubEnv(key, value)
    }

    const mod = await import("@/lib/env")
    expect(mod.env.NEXT_PUBLIC_SUPABASE_URL).toBe(VALID_ENV.NEXT_PUBLIC_SUPABASE_URL)
    expect(mod.env.NEXT_PUBLIC_SUPABASE_ANON_KEY).toBe(VALID_ENV.NEXT_PUBLIC_SUPABASE_ANON_KEY)
    expect(mod.env.NEXT_PUBLIC_APP_URL).toBe(VALID_ENV.NEXT_PUBLIC_APP_URL)
  })

  it("throws when a required variable is missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", VALID_ENV.NEXT_PUBLIC_SUPABASE_URL)
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", "")
    vi.stubEnv("NEXT_PUBLIC_APP_URL", VALID_ENV.NEXT_PUBLIC_APP_URL)

    await expect(() => import("@/lib/env")).rejects.toThrow(/Invalid environment variables/)
  })

  it("throws when a URL is malformed", async () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "not-a-url")
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", VALID_ENV.NEXT_PUBLIC_SUPABASE_ANON_KEY)
    vi.stubEnv("NEXT_PUBLIC_APP_URL", VALID_ENV.NEXT_PUBLIC_APP_URL)

    await expect(() => import("@/lib/env")).rejects.toThrow(/NEXT_PUBLIC_SUPABASE_URL/)
  })
})
