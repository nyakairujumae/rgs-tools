'use client'

import { useEffect, useState, useCallback, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { User, AdminPosition } from '@/lib/types/database'
import type { User as SupabaseUser } from '@supabase/supabase-js'

// Auth init timeout: if session check hangs (network, etc), stop loading and treat as logged out.
// Supabase JWT expiry is typically 1h (configurable in Supabase Dashboard > Auth > Settings).
const AUTH_INIT_TIMEOUT_MS = 10_000

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

  const loadProfile = async (user: SupabaseUser) => {
    try {
      await Promise.race([
        (async () => {
          const { data: profile } = await supabase
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single()
          const [position] = await Promise.all([
            fetchPosition(profile?.position_id),
            supabase.auth.getUser().catch(() => null),
          ])
          const next = { user, profile: profile || null, position, loading: false }
          authCache = next
          setState(next)
        })(),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error('Profile load timeout')), AUTH_INIT_TIMEOUT_MS)
        ),
      ])
    } catch {
      setLoggedOut()
    }
  }

  useEffect(() => {
    let cancelled = false

    const init = async () => {
      try {
        await Promise.race([
          (async () => {
            const { data: { session } } = await supabase.auth.getSession()
            if (cancelled) return
            if (session?.user) {
              const { data: { user } } = await supabase.auth.getUser()
              if (cancelled) return
              if (user) {
                await loadProfile(user)
              } else {
                await supabase.auth.signOut()
                setLoggedOut()
              }
            } else {
              setLoggedOut()
            }
          })(),
          new Promise<never>((_, reject) =>
            setTimeout(() => reject(new Error('Auth timeout')), AUTH_INIT_TIMEOUT_MS)
          ),
        ])
      } catch {
        if (!cancelled) setLoggedOut()
      }
    }

    init()

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (cancelled) return
        if (session?.user) {
          try {
            await loadProfile(session.user)
          } catch {
            setLoggedOut()
          }
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
