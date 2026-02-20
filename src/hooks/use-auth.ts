'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { User, AdminPosition } from '@/lib/types/database'
import type { User as SupabaseUser } from '@supabase/supabase-js'

interface AuthState {
  user: SupabaseUser | null
  profile: User | null
  position: AdminPosition | null
  loading: boolean
}

export function useAuth() {
  const [state, setState] = useState<AuthState>({
    user: null,
    profile: null,
    position: null,
    loading: true,
  })

  const supabase = createClient()

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

  useEffect(() => {
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser()

      if (user) {
        const { data: profile } = await supabase
          .from('users')
          .select('*')
          .eq('id', user.id)
          .single()

        const position = await fetchPosition(profile?.position_id)
        setState({ user, profile, position, loading: false })
      } else {
        setState({ user: null, profile: null, position: null, loading: false })
      }
    }

    getUser()

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (_event, session) => {
        if (session?.user) {
          const { data: profile } = await supabase
            .from('users')
            .select('*')
            .eq('id', session.user.id)
            .single()

          const position = await fetchPosition(profile?.position_id)
          setState({ user: session.user, profile, position, loading: false })
        } else {
          setState({ user: null, profile: null, position: null, loading: false })
        }
      }
    )

    return () => subscription.unsubscribe()
  }, [])

  const signOut = async () => {
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
