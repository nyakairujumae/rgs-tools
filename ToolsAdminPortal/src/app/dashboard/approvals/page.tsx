'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatusBadge, PriorityBadge } from '@/components/shared/status-badge'
import { formatDate, timeAgo, cn } from '@/lib/utils'
import { useAuth } from '@/hooks/use-auth'
import {
  Loader2,
  CheckCircle,
  XCircle,
  Clock,
  MessageSquare,
} from 'lucide-react'
import type { ApprovalWorkflow } from '@/lib/types/database'

export default function ApprovalsPage() {
  const { user } = useAuth()
  const [workflows, setWorkflows] = useState<ApprovalWorkflow[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState<'Pending' | 'Approved' | 'Rejected' | 'all'>('Pending')
  const [rejectId, setRejectId] = useState<string | null>(null)
  const [rejectReason, setRejectReason] = useState('')

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('approval_workflows')
        .select('*')
        .order('request_date', { ascending: false })
      setWorkflows(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const counts = useMemo(() => ({
    all: workflows.length,
    Pending: workflows.filter((w) => w.status === 'Pending').length,
    Approved: workflows.filter((w) => w.status === 'Approved').length,
    Rejected: workflows.filter((w) => w.status === 'Rejected').length,
  }), [workflows])

  const filtered = tab === 'all' ? workflows : workflows.filter((w) => w.status === tab)

  const handleApprove = async (id: string) => {
    const { approveWorkflow } = await import('@/lib/supabase/actions')
    const success = await approveWorkflow(id, user?.id || '', '')
    if (success) {
      setWorkflows((prev) =>
        prev.map((w) => (w.id === id ? { ...w, status: 'Approved' as const } : w))
      )
    }
  }

  const handleReject = async (id: string) => {
    if (!rejectReason.trim()) return
    const { rejectWorkflow } = await import('@/lib/supabase/actions')
    const success = await rejectWorkflow(id, user?.id || '', rejectReason)
    if (success) {
      setWorkflows((prev) =>
        prev.map((w) => (w.id === id ? { ...w, status: 'Rejected' as const, rejection_reason: rejectReason } : w))
      )
    }
    setRejectId(null)
    setRejectReason('')
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
      </div>
    )
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Approvals</h1>
        <p className="text-sm text-muted-foreground">{counts.Pending} pending approval{counts.Pending !== 1 ? 's' : ''}</p>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-border">
        {(['Pending', 'Approved', 'Rejected', 'all'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              'px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
              tab === t
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            {t === 'all' ? 'All' : t}
            <span className="ml-1.5 text-xs bg-muted px-1.5 py-0.5 rounded-full">
              {counts[t]}
            </span>
          </button>
        ))}
      </div>

      {/* Cards */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="py-12 text-center text-muted-foreground text-sm">
            No {tab !== 'all' ? tab.toLowerCase() : ''} approvals
          </div>
        ) : (
          filtered.map((wf) => (
            <div key={wf.id} className="bg-card border border-border rounded-xl p-5 hover:border-primary/20 transition-colors">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center text-muted-foreground shrink-0">
                  {wf.status === 'Pending' ? <Clock className="w-5 h-5" /> :
                   wf.status === 'Approved' ? <CheckCircle className="w-5 h-5 text-emerald-500" /> :
                   <XCircle className="w-5 h-5 text-red-500" />}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-medium">{wf.title}</span>
                    <StatusBadge status={wf.status} />
                    <PriorityBadge priority={wf.priority} />
                    <span className="text-xs bg-muted px-2 py-0.5 rounded">{wf.request_type}</span>
                  </div>
                  <p className="text-sm text-muted-foreground mt-1">{wf.description}</p>
                  <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                    <span>By {wf.requester_name}</span>
                    <span>{timeAgo(wf.request_date)}</span>
                    {wf.due_date && <span>Due {formatDate(wf.due_date)}</span>}
                  </div>
                  {wf.rejection_reason && (
                    <p className="text-xs text-red-500 mt-2">Reason: {wf.rejection_reason}</p>
                  )}
                </div>

                {wf.status === 'Pending' && (
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => handleApprove(wf.id)}
                      className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg bg-emerald-500 text-white hover:bg-emerald-600 transition-colors"
                    >
                      <CheckCircle className="w-3.5 h-3.5" /> Approve
                    </button>
                    <button
                      onClick={() => setRejectId(rejectId === wf.id ? null : wf.id)}
                      className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors"
                    >
                      <XCircle className="w-3.5 h-3.5" /> Reject
                    </button>
                  </div>
                )}
              </div>

              {/* Reject dialog */}
              {rejectId === wf.id && (
                <div className="mt-3 pt-3 border-t border-border">
                  <textarea
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    placeholder="Reason for rejection..."
                    className="w-full h-20 p-3 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
                  />
                  <div className="flex justify-end gap-2 mt-2">
                    <button
                      onClick={() => { setRejectId(null); setRejectReason('') }}
                      className="text-xs px-3 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors"
                    >
                      Cancel
                    </button>
                    <button
                      onClick={() => handleReject(wf.id)}
                      disabled={!rejectReason.trim()}
                      className="text-xs px-3 py-1.5 rounded-lg bg-destructive text-destructive-foreground hover:bg-destructive/90 disabled:opacity-50 transition-colors"
                    >
                      Confirm Reject
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  )
}
