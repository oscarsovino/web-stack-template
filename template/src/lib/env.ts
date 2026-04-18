import { z } from "zod"

/**
 * Validated environment variables.
 *
 * NEXT_PUBLIC_* values are inlined by Next.js at build time, so each variable
 * must be referenced explicitly (not via a `...process.env` spread) for the
 * client bundle to receive the real value. Do not refactor this to loop over
 * `process.env` without also touching the Next.js config.
 */
const envSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  NEXT_PUBLIC_APP_URL: z.string().url(),
})

const parsed = envSchema.safeParse({
  NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
  NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
})

if (!parsed.success) {
  const fieldErrors = parsed.error.flatten().fieldErrors
  const summary = Object.entries(fieldErrors)
    .map(([name, errors]) => `  ${name}: ${(errors ?? []).join(", ")}`)
    .join("\n")
  throw new Error(
    `Invalid environment variables. Check .env.local against .env.example.\n${summary}`,
  )
}

export const env = parsed.data
export type Env = typeof env
