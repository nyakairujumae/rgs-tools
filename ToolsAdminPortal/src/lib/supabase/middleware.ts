import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function updateSession(request: NextRequest) {
  // Public routes — no auth required
  const publicPaths = ['/privacy', '/support', '/signup', '/onboarding', '/pricing']
  if (
    request.nextUrl.pathname === '/' ||
    publicPaths.some((p) => request.nextUrl.pathname.startsWith(p))
  ) {
    return NextResponse.next({ request })
  }

  // If already on login page, just refresh the session and continue
  if (request.nextUrl.pathname.startsWith('/login')) {
    let supabaseResponse = NextResponse.next({ request })

    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() {
            return request.cookies.getAll()
          },
          setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
            cookiesToSet.forEach(({ name, value }) =>
              request.cookies.set(name, value)
            )
            supabaseResponse = NextResponse.next({ request })
            cookiesToSet.forEach(({ name, value, options }) =>
              supabaseResponse.cookies.set(name, value, options as any)
            )
          },
        },
      }
    )

    const { data: { session } } = await supabase.auth.getSession()
    if (session?.user) {
      const url = request.nextUrl.clone()
      url.pathname = '/dashboard'
      return NextResponse.redirect(url)
    }
    return supabaseResponse
  }

  // For ALL other routes: require authentication (reload = refresh: use session from cookies only)
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet: { name: string; value: string; options?: Record<string, unknown> }[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options as any)
          )
        },
      },
    }
  )

  // Use getSession (cookies only) so reload is treated as refresh — no network call that can fail
  const { data: { session } } = await supabase.auth.getSession()
  const user = session?.user ?? null

  if (!user) {
    const url = request.nextUrl.clone()
    url.pathname = '/login'
    return NextResponse.redirect(url)
  }

  // Dashboard routes → verify admin role; on failure (e.g. network) allow through, client will re-check
  if (request.nextUrl.pathname.startsWith('/dashboard')) {
    try {
      const { data: userData } = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single()

      if (!userData || userData.role !== 'admin') {
        const url = request.nextUrl.clone()
        url.pathname = '/login'
        url.searchParams.set('error', 'admin_only')
        return NextResponse.redirect(url)
      }
    } catch {
      // Network/DB error — allow through; dashboard layout will re-check
      return supabaseResponse
    }
  }

  return supabaseResponse
}
