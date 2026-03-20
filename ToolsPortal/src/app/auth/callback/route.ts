import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')

  if (code) {
    const cookieStore = await cookies()
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        cookies: {
          getAll() { return cookieStore.getAll() },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          },
        },
      }
    )

    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      const { data: { user } } = await supabase.auth.getUser()

      if (user) {
        // Check if this user already has a profile in our users table
        const { data: profile } = await supabase
          .from('users')
          .select('role, organization_id')
          .eq('id', user.id)
          .single()

        if (!profile) {
          // New user — no account in our system yet, send to complete signup
          return NextResponse.redirect(`${origin}/signup?oauth=1`)
        }

        if (profile.role === 'admin') {
          // Existing admin — check if they've completed company setup
          if (!profile.organization_id) {
            return NextResponse.redirect(`${origin}/signup?oauth=1`)
          }
          return NextResponse.redirect(`${origin}/dashboard`)
        }

        // Technician — this portal is admin-only
        await supabase.auth.signOut()
        return NextResponse.redirect(`${origin}/login?error=admin_only`)
      }
    }
  }

  return NextResponse.redirect(`${origin}/login?error=auth_failed`)
}
