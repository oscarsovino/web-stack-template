import { createServerClient } from "@supabase/ssr"
import { NextResponse, type NextRequest } from "next/server"
import { env } from "@/lib/env"

// Customize these arrays for your app
const PUBLIC_PATHS = ["/", "/login", "/registro"]
const USER_PATHS = ["/cuenta"]
const ADMIN_PATHS = ["/dashboard"]

function matchesPrefix(pathname: string, prefixes: string[]): boolean {
  return prefixes.some((p) => pathname === p || pathname.startsWith(p + "/"))
}

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          )
        },
      },
    },
  )

  // Refresh session — MUST call getUser() to refresh tokens via cookies
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const { pathname } = request.nextUrl

  // Static assets and Next.js internals — pass through
  if (pathname.startsWith("/_next") || pathname.startsWith("/favicon") || pathname.includes(".")) {
    return supabaseResponse
  }

  // Public paths — always accessible
  if (matchesPrefix(pathname, PUBLIC_PATHS)) {
    return supabaseResponse
  }

  // API routes — pass through (they handle their own auth)
  if (pathname.startsWith("/api/")) {
    return supabaseResponse
  }

  // Protected routes — require authentication
  if (!user && (matchesPrefix(pathname, USER_PATHS) || matchesPrefix(pathname, ADMIN_PATHS))) {
    const url = request.nextUrl.clone()
    url.pathname = "/login"
    url.searchParams.set("returnTo", pathname)
    return NextResponse.redirect(url)
  }

  // Unknown routes without auth — fail-closed
  if (!user && !matchesPrefix(pathname, PUBLIC_PATHS)) {
    const url = request.nextUrl.clone()
    url.pathname = "/login"
    url.searchParams.set("returnTo", pathname)
    return NextResponse.redirect(url)
  }

  return supabaseResponse
}
