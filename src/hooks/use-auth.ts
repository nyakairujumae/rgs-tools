'use client'

import { useEffect, useState, useCallback, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { User, AdminPosition } from '@/lib/types/database'
import type { User as SupabaseUser } from '@supabase/supabase-js'

// Match Flutter app: longer timeout so reload is treated as refresh; don't log out on transient failure.
const AUTH_INIT_TIMEOUT_MS = 30_000
const PROFILE_LOAD_TIMEOUT_MS = 5_000
const LOAD_PROFILE_RETRIES = 2

// Cache auth across layout remounts (e.g. client nav) so we don't flash full loading again.
let authCache: { user: SupabaseUser; profile: User | null; position: AdminPosition | null } | null = null

interface AuthState {
  user: SupabaseUser | null
  profile: User | null
  position: AdminPosition | null
  loading: boolean
}

export function useAuth() {
  const [state, setState] = useState<AuthState>(() => {
    if (authCache) {
      return { ...authCache, loading: false }
    }
    return { user: null, profile: null, position: null, loading: true }
  })

  const supabaseRef = useRef(createClient())
  const supabase = supabaseRef.current

  const setLoggedOut = useCallback(() => {
    authCache = null
    setState({ user: null, profile: null, position: null, loading: false })
  }, [])

  const fetchPosition = async (positionId?: string): Promise<AdminPosition | null> => {
    if (!positionId) return null
    try {
      const { data } = await supabase
        .from('admin_positions')
        .select('*, position_permissions(*)')
        .eq('id', positionId)
        .single()
      return data || null
    } catch {
      return null
    }
  }

  const loadProfile = async (user: SupabaseUser): Promise<boolean> => {
    for (let attempt = 1; attempt <= LOAD_PROFILE_RETRIES; attempt++) {
      try {
        await Promise.race([
          (async () => {
            const { data: profile } = await supabase
              .from('users')
              .select('*')
              .eq('id', user.id)
              .single()
            const position = await fetchPosition(profile?.position_id)
            const next = { user, profile: profile || null, position, loading: false }
            authCache = next
            setState(next)
          })(),
          new Promise<never>((_, reject) =>
            setTimeout(() => reject(new Error('Profile load timeout')), PROFILE_LOAD_TIMEOUT_MS)
          ),
        ])
        return true
      } catch {
        if (attempt === LOAD_PROFILE_RETRIES) return false
      }
    }
    return false
  }

  useEffect(() => {
    let cancelled = false

    const init = async () => {
      const { data: { session } } = await supabase.auth.getSession()
      if (cancelled) return
      if (!session?.user) {
        setLoggedOut()
        return
      }
      // Reload = refresh: use session from storage; only log out when there is no session
      let ok = false
      try {
        await Promise.race([
          (async () => {
            ok = await loadProfile(session.user)
          })(),
          new Promise<void>((_, reject) =>
            setTimeout(() => reject(new Error('Auth timeout')), AUTH_INIT_TIMEOUT_MS)
          ),
        ])
      } catch {
        // Timeout or throw: retry loadProfile once (don't log out on refresh failure)
        if (!cancelled) ok = await loadProfile(session.user)
      }
      // If !ok: profile load failed after retries — leave loading true (don't log out); user can refresh
    }

    init()

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (cancelled) return
        if (session?.user) {
          await loadProfile(session.user)
          // Don't log out on profile load failure — treat as refresh, keep session
        } else {
          setLoggedOut()
        }
      }
    )

    return () => {
      cancelled = true
      subscription.unsubscribe()
    }
  }, [setLoggedOut])

  const signOut = async () => {
    authCache = null
    await supabase.auth.signOut()
    window.location.href = '/login'
  }

  const positionName = state.position?.name?.toLowerCase() || ''
  const isSuperAdmin = positionName === 'super admin' || positionName === 'ceo'

  const hasPermission = useCallback((permissionName: string): boolean => {
    if (isSuperAdmin) return true
    if (!state.position?.position_permissions) return false
    return state.position.position_permissions.some(
      (p) => p.permission_name === permissionName && p.is_granted
    )
  }, [state.position, isSuperAdmin])

  return {
    ...state,
    signOut,
    isAdmin: state.profile?.role === 'admin',
    isSuperAdmin,
    hasPermission,
  }
}
