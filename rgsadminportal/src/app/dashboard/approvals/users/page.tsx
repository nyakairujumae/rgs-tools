'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/use-auth'
import { StatusBadge } from '@/components/shared/status-badge'
import { formatDate } from '@/lib/utils'
import { Loader2, CheckCircle, XCircle, User } from 'lucide-react'
import type { PendingUserApproval } from '@/lib/types/database'

export default function UserApprovalsPage() {
  const { user } = useAuth()
  const [pending, setPending] = useState<PendingUserApproval[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('pending_user_approvals')
        .select('*')
        .order('submitted_at', { ascending: false })
      setPending(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const handleApprove = async (userId: string) => {
    const supabase = createClient()
    await supabase.rpc('approve_pending_user', {
      p_user_id: userId,
      p_approved_by: user?.id,
    })
    setPending((prev) => prev.map((p) => (p.user_id === userId ? { ...p, status: 'approved' } : p)))
  }

  if (loading) {
    return <div className="flex items-center justify-center h-full"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
  }

  const pendingUsers = pending.filter((p) => p.status === 'pending')

  return (
    <div className="p-6 max-w-[1200px] mx-auto space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">User Approvals</h1>
        <p className="text-sm text-muted-foreground">{pendingUsers.length} pending registration{pendingUsers.length !== 1 ? 's' : ''}</p>
      </div>

      <div className="space-y-3">
        {pending.length === 0 ? (
          <div className="py-12 text-center text-muted-foreground text-sm">No user registrations</div>
        ) : (
          pending.map((p) => (
            <div key={p.id} className="bg-card border border-border rounded-xl p-5 flex items-center gap-4">
              <div className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-semibold shrink-0">
                {p.full_name?.charAt(0)?.toUpperCase() || <User className="w-5 h-5" />}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-medium">{p.full_name}</span>
                  <StatusBadge status={p.status === 'pending' ? 'Pending' : p.status === 'approved' ? 'Approved' : 'Rejected'} />
                </div>
                <div className="flex items-center gap-4 mt-1 text-xs text-muted-foreground">
                  <span>{p.email}</span>
                  {p.department && <span>{p.department}</span>}
                  {p.submitted_at && <span>Submitted {formatDate(p.submitted_at)}</span>}
                </div>
              </div>
              {p.status === 'pending' && (
                <div className="flex items-center gap-2 shrink-0">
                  <button
                    onClick={() => handleApprove(p.user_id)}
                    className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg bg-emerald-500 text-white hover:bg-emerald-600 transition-colors"
                  >
                    <CheckCircle className="w-3.5 h-3.5" /> Approve
                  </button>
                  <button className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors">
                    <XCircle className="w-3.5 h-3.5" /> Reject
                  </button>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}
