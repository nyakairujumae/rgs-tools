'use client'

import { useEffect, useState, useMemo, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatusBadge, PriorityBadge } from '@/components/shared/status-badge'
import { formatDate, timeAgo, cn } from '@/lib/utils'
import { useAuth } from '@/hooks/use-auth'
import {
  Loader2,
  CheckCircle,
  XCircle,
  Clock,
  Search,
  X,
  Plus,
  ChevronDown,
  AlertTriangle,
  Wrench,
  Package,
  ArrowLeftRight,
  Trash2,
  RefreshCw,
} from 'lucide-react'
import type { ApprovalWorkflow } from '@/lib/types/database'

const REQUEST_TYPES = [
  'All',
  'Tool Assignment',
  'Tool Purchase',
  'Tool Disposal',
  'Maintenance',
  'Transfer',
  'Repair',
  'Calibration',
  'Certification',
] as const

const STATUS_FILTERS = ['All', 'Pending', 'Approved', 'Rejected', 'Overdue'] as const

const PRIORITIES = ['Low', 'Medium', 'High', 'Critical'] as const

type StatusFilter = (typeof STATUS_FILTERS)[number]
type RequestType = (typeof REQUEST_TYPES)[number]

function getTypeColor(type: string) {
  switch (type) {
    case 'Tool Assignment': return 'text-blue-500 bg-blue-500/10'
    case 'Tool Purchase': return 'text-emerald-500 bg-emerald-500/10'
    case 'Tool Disposal': return 'text-red-500 bg-red-500/10'
    case 'Maintenance': return 'text-amber-500 bg-amber-500/10'
    case 'Transfer': return 'text-violet-500 bg-violet-500/10'
    case 'Repair': return 'text-orange-500 bg-orange-500/10'
    case 'Calibration': return 'text-cyan-500 bg-cyan-500/10'
    case 'Certification': return 'text-indigo-500 bg-indigo-500/10'
    default: return 'text-muted-foreground bg-muted'
  }
}

function getTypeIcon(type: string) {
  switch (type) {
    case 'Tool Assignment': return <ArrowLeftRight className="w-4 h-4" />
    case 'Tool Purchase': return <Package className="w-4 h-4" />
    case 'Tool Disposal': return <Trash2 className="w-4 h-4" />
    case 'Maintenance': return <Wrench className="w-4 h-4" />
    case 'Transfer': return <RefreshCw className="w-4 h-4" />
    default: return <Clock className="w-4 h-4" />
  }
}

function isOverdue(wf: ApprovalWorkflow) {
  if (wf.status !== 'Pending') return false
  if (!wf.due_date) return false
  return new Date(wf.due_date) < new Date()
}

export default function RequestsPage() {
  const { user } = useAuth()
  const [workflows, setWorkflows] = useState<ApprovalWorkflow[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('All')
  const [typeFilter, setTypeFilter] = useState<RequestType>('All')
  const [search, setSearch] = useState('')
  const [rejectId, setRejectId] = useState<string | null>(null)
  const [rejectReason, setRejectReason] = useState('')
  const [detailWorkflow, setDetailWorkflow] = useState<ApprovalWorkflow | null>(null)
  const [showNewRequest, setShowNewRequest] = useState(false)

  const fetchData = useCallback(async () => {
    const supabase = createClient()
    const { data } = await supabase
      .from('approval_workflows')
      .select('*')
      .order('request_date', { ascending: false })
    setWorkflows(data || [])
    setLoading(false)
  }, [])

  useEffect(() => {
    fetchData()
    const supabase = createClient()
    const channel = supabase
      .channel('requests-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'approval_workflows' }, fetchData)
      .subscribe()
    return () => { supabase.removeChannel(channel) }
  }, [fetchData])

  const counts = useMemo(() => ({
    All: workflows.length,
    Pending: workflows.filter((w) => w.status === 'Pending').length,
    Approved: workflows.filter((w) => w.status === 'Approved').length,
    Rejected: workflows.filter((w) => w.status === 'Rejected').length,
    Overdue: workflows.filter(isOverdue).length,
  }), [workflows])

  const filtered = useMemo(() => {
    let list = [...workflows]
    if (statusFilter === 'Overdue') {
      list = list.filter(isOverdue)
    } else if (statusFilter !== 'All') {
      list = list.filter((w) => w.status === statusFilter)
    }
    if (typeFilter !== 'All') {
      list = list.filter((w) => w.request_type === typeFilter)
    }
    if (search.trim()) {
      const q = search.toLowerCase()
      list = list.filter((w) =>
        [w.title, w.description, w.requester_name, w.request_type].join(' ').toLowerCase().includes(q)
      )
    }
    return list
  }, [workflows, statusFilter, typeFilter, search])

  const handleApprove = async (id: string) => {
    const { approveWorkflow } = await import('@/lib/supabase/actions')
    const success = await approveWorkflow(id, user?.id || '', '')
    if (success) {
      setWorkflows((prev) =>
        prev.map((w) => (w.id === id ? { ...w, status: 'Approved' as const } : w))
      )
      if (detailWorkflow?.id === id) {
        setDetailWorkflow((d) => d ? { ...d, status: 'Approved' as const } : d)
      }
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
      if (detailWorkflow?.id === id) {
        setDetailWorkflow((d) => d ? { ...d, status: 'Rejected' as const, rejection_reason: rejectReason } : d)
      }
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
    <div className="p-4 md:p-6 max-w-[1200px] mx-auto space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Requests</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {counts.Pending} pending request{counts.Pending !== 1 ? 's' : ''}
          </p>
        </div>
        <button
          onClick={() => setShowNewRequest(true)}
          className="flex items-center gap-1.5 text-sm px-4 py-2 rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 transition-colors font-medium"
        >
          <Plus className="w-4 h-4" /> New Request
        </button>
      </div>

      {/* Search */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search requests..."
          className="w-full pl-9 pr-9 py-2 text-sm rounded-lg border border-input bg-background focus:outline-none focus:ring-2 focus:ring-ring"
        />
        {search && (
          <button
            onClick={() => setSearch('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Status Tabs */}
      <div className="flex items-center gap-1 border-b border-border overflow-x-auto">
        {STATUS_FILTERS.map((s) => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={cn(
              'px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors whitespace-nowrap',
              statusFilter === s
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            {s}
            <span className="ml-1.5 text-xs bg-muted px-1.5 py-0.5 rounded-full">
              {counts[s]}
            </span>
          </button>
        ))}
      </div>

      {/* Type Filter Chips */}
      <div className="flex items-center gap-2 flex-wrap">
        {REQUEST_TYPES.map((t) => (
          <button
            key={t}
            onClick={() => setTypeFilter(t)}
            className={cn(
              'px-3 py-1.5 text-xs font-medium rounded-full border transition-colors',
              typeFilter === t
                ? 'bg-primary text-primary-foreground border-primary'
                : 'bg-background text-muted-foreground border-input hover:text-foreground hover:border-foreground/30'
            )}
          >
            {t}
          </button>
        ))}
      </div>

      {/* Cards */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="py-16 text-center">
            <Clock className="w-12 h-12 text-muted-foreground/30 mx-auto mb-3" />
            <p className="text-sm font-medium text-muted-foreground">
              No {statusFilter !== 'All' ? statusFilter.toLowerCase() : ''} requests
              {typeFilter !== 'All' ? ` for ${typeFilter}` : ''}
            </p>
          </div>
        ) : (
          filtered.map((wf) => (
            <RequestCard
              key={wf.id}
              wf={wf}
              rejectId={rejectId}
              rejectReason={rejectReason}
              onView={() => setDetailWorkflow(wf)}
              onApprove={handleApprove}
              onRejectToggle={(id) => { setRejectId(rejectId === id ? null : id); setRejectReason('') }}
              onRejectReasonChange={setRejectReason}
              onRejectConfirm={handleReject}
              onRejectCancel={() => { setRejectId(null); setRejectReason('') }}
            />
          ))
        )}
      </div>

      {/* Detail Modal */}
      {detailWorkflow && (
        <DetailModal
          wf={detailWorkflow}
          onClose={() => { setDetailWorkflow(null); setRejectId(null); setRejectReason('') }}
          onApprove={handleApprove}
          rejectId={rejectId}
          rejectReason={rejectReason}
          onRejectToggle={(id) => { setRejectId(rejectId === id ? null : id); setRejectReason('') }}
          onRejectReasonChange={setRejectReason}
          onRejectConfirm={handleReject}
          onRejectCancel={() => { setRejectId(null); setRejectReason('') }}
        />
      )}

      {/* New Request Modal */}
      {showNewRequest && (
        <NewRequestModal
          userId={user?.id || ''}
          userName={user?.email || ''}
          onClose={() => setShowNewRequest(false)}
          onCreated={(wf) => {
            setWorkflows((prev) => [wf, ...prev])
            setShowNewRequest(false)
          }}
        />
      )}
    </div>
  )
}

// ── Request Card ──

interface CardProps {
  wf: ApprovalWorkflow
  rejectId: string | null
  rejectReason: string
  onView: () => void
  onApprove: (id: string) => void
  onRejectToggle: (id: string) => void
  onRejectReasonChange: (v: string) => void
  onRejectConfirm: (id: string) => void
  onRejectCancel: () => void
}

function RequestCard({ wf, rejectId, rejectReason, onView, onApprove, onRejectToggle, onRejectReasonChange, onRejectConfirm, onRejectCancel }: CardProps) {
  const initial = wf.title?.trim()[0]?.toUpperCase() || '?'
  const typeColor = getTypeColor(wf.request_type)
  const overdue = isOverdue(wf)

  return (
    <div
      className="bg-card border border-border rounded-xl p-4 md:p-5 hover:border-primary/20 transition-colors cursor-pointer"
      onClick={onView}
    >
      <div className="flex items-start gap-4">
        {/* Icon avatar */}
        <div className={cn('w-11 h-11 rounded-xl flex items-center justify-center shrink-0 text-lg font-semibold', typeColor)}>
          {initial}
        </div>

        <div className="flex-1 min-w-0">
          {/* Title row */}
          <div className="flex items-start gap-2 flex-wrap">
            <span className="font-semibold text-sm leading-snug">{wf.title}</span>
            {overdue && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-red-500/10 text-red-500 font-medium flex items-center gap-1">
                <AlertTriangle className="w-3 h-3" /> Overdue
              </span>
            )}
          </div>

          {/* Subtitle */}
          <p className="text-xs text-muted-foreground mt-0.5">
            {wf.request_type} • {wf.requester_role || 'Technician'}
          </p>

          {/* Chips */}
          <div className="flex items-center gap-2 flex-wrap mt-2">
            <span className={cn('text-xs px-2 py-0.5 rounded-full font-medium', typeColor)}>
              {wf.request_type}
            </span>
            <PriorityBadge priority={wf.priority} />
            <StatusBadge status={wf.status} />
          </div>

          {/* Description */}
          {wf.description && (
            <p className="text-xs text-muted-foreground mt-2 line-clamp-2">{wf.description}</p>
          )}

          {/* Meta */}
          <p className="text-xs text-muted-foreground mt-2">
            Requested by {wf.requester_name} · {timeAgo(wf.request_date)}
            {wf.due_date && ` · Due ${formatDate(wf.due_date)}`}
          </p>

          {wf.rejection_reason && (
            <div className="mt-2 px-3 py-2 rounded-lg bg-red-500/8 border border-red-500/20 text-xs text-red-600">
              <span className="font-medium">Rejection reason:</span> {wf.rejection_reason}
            </div>
          )}
        </div>

        {/* Action buttons */}
        {wf.status === 'Pending' && (
          <div
            className="flex items-center gap-2 shrink-0"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => onApprove(wf.id)}
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg bg-emerald-500 text-white hover:bg-emerald-600 transition-colors"
            >
              <CheckCircle className="w-3.5 h-3.5" /> Approve
            </button>
            <button
              onClick={() => onRejectToggle(wf.id)}
              className="flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors"
            >
              <XCircle className="w-3.5 h-3.5" /> Reject
            </button>
          </div>
        )}
      </div>

      {/* Inline reject form */}
      {rejectId === wf.id && (
        <div
          className="mt-3 pt-3 border-t border-border"
          onClick={(e) => e.stopPropagation()}
        >
          <textarea
            value={rejectReason}
            onChange={(e) => onRejectReasonChange(e.target.value)}
            placeholder="Reason for rejection..."
            className="w-full h-20 p-3 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
            autoFocus
          />
          <div className="flex justify-end gap-2 mt-2">
            <button
              onClick={onRejectCancel}
              className="text-xs px-3 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={() => onRejectConfirm(wf.id)}
              disabled={!rejectReason.trim()}
              className="text-xs px-3 py-1.5 rounded-lg bg-destructive text-destructive-foreground hover:bg-destructive/90 disabled:opacity-50 transition-colors"
            >
              Confirm Reject
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

// ── Detail Modal ──

interface DetailModalProps {
  wf: ApprovalWorkflow
  onClose: () => void
  onApprove: (id: string) => void
  rejectId: string | null
  rejectReason: string
  onRejectToggle: (id: string) => void
  onRejectReasonChange: (v: string) => void
  onRejectConfirm: (id: string) => void
  onRejectCancel: () => void
}

function DetailModal({ wf, onClose, onApprove, rejectId, rejectReason, onRejectToggle, onRejectReasonChange, onRejectConfirm, onRejectCancel }: DetailModalProps) {
  const typeColor = getTypeColor(wf.request_type)
  const overdue = isOverdue(wf)

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-card border border-border rounded-2xl w-full max-w-lg max-h-[85vh] overflow-y-auto shadow-2xl">
        {/* Header */}
        <div className="flex items-start gap-3 p-5 border-b border-border">
          <div className={cn('w-11 h-11 rounded-xl flex items-center justify-center shrink-0 text-lg font-semibold', typeColor)}>
            {wf.title?.[0]?.toUpperCase() || '?'}
          </div>
          <div className="flex-1 min-w-0">
            <h2 className="font-semibold text-base leading-snug">{wf.title}</h2>
            <p className="text-xs text-muted-foreground mt-0.5">
              {wf.request_type} • {wf.requester_role || 'Technician'}
            </p>
          </div>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground shrink-0 ml-2">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-5 space-y-4">
          {/* Chips */}
          <div className="flex items-center gap-2 flex-wrap">
            <span className={cn('text-xs px-2 py-0.5 rounded-full font-medium', typeColor)}>
              {wf.request_type}
            </span>
            <PriorityBadge priority={wf.priority} />
            <StatusBadge status={wf.status} />
            {overdue && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-red-500/10 text-red-500 font-medium flex items-center gap-1">
                <AlertTriangle className="w-3 h-3" /> Overdue
              </span>
            )}
          </div>

          {/* Description */}
          {wf.description && (
            <p className="text-sm text-muted-foreground leading-relaxed">{wf.description}</p>
          )}

          {/* Details grid */}
          <div className="space-y-2 text-sm">
            <DetailRow label="Requester" value={wf.requester_name} />
            <DetailRow label="Role" value={wf.requester_role} />
            <DetailRow label="Requested" value={wf.request_date ? formatDate(wf.request_date) : undefined} />
            {wf.due_date && <DetailRow label="Due Date" value={formatDate(wf.due_date)} />}
            {wf.location && <DetailRow label="Location" value={wf.location} />}
            {wf.approved_date && <DetailRow label="Approved Date" value={formatDate(wf.approved_date)} />}
            {wf.approved_by && <DetailRow label="Approved By" value={wf.approved_by} />}
            {wf.rejected_date && <DetailRow label="Rejected Date" value={formatDate(wf.rejected_date)} />}
            {wf.rejected_by && <DetailRow label="Rejected By" value={wf.rejected_by} />}
          </div>

          {/* Rejection reason */}
          {wf.rejection_reason && (
            <div className="px-3 py-2 rounded-lg bg-red-500/8 border border-red-500/20 text-xs text-red-600">
              <span className="font-medium">Rejection reason:</span> {wf.rejection_reason}
            </div>
          )}

          {/* Comments */}
          {wf.comments && (
            <div className="px-3 py-2 rounded-lg bg-muted text-xs">
              <span className="font-medium">Comments:</span> {wf.comments}
            </div>
          )}
        </div>

        {/* Actions */}
        {wf.status === 'Pending' && (
          <div className="p-5 pt-0 space-y-3">
            {rejectId === wf.id ? (
              <>
                <textarea
                  value={rejectReason}
                  onChange={(e) => onRejectReasonChange(e.target.value)}
                  placeholder="Reason for rejection..."
                  className="w-full h-20 p-3 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
                  autoFocus
                />
                <div className="flex gap-2">
                  <button
                    onClick={onRejectCancel}
                    className="flex-1 text-sm py-2 rounded-lg border border-input hover:bg-accent transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => onRejectConfirm(wf.id)}
                    disabled={!rejectReason.trim()}
                    className="flex-1 text-sm py-2 rounded-lg bg-destructive text-destructive-foreground hover:bg-destructive/90 disabled:opacity-50 transition-colors"
                  >
                    Confirm Reject
                  </button>
                </div>
              </>
            ) : (
              <div className="flex gap-2">
                <button
                  onClick={() => onApprove(wf.id)}
                  className="flex-1 flex items-center justify-center gap-1.5 text-sm py-2.5 rounded-xl bg-emerald-500 text-white hover:bg-emerald-600 transition-colors font-medium"
                >
                  <CheckCircle className="w-4 h-4" /> Approve
                </button>
                <button
                  onClick={() => onRejectToggle(wf.id)}
                  className="flex-1 flex items-center justify-center gap-1.5 text-sm py-2.5 rounded-xl border border-destructive text-destructive hover:bg-destructive/10 transition-colors font-medium"
                >
                  <XCircle className="w-4 h-4" /> Reject
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

// ── Detail Row ──

function DetailRow({ label, value }: { label: string; value?: string | null }) {
  if (!value) return null
  return (
    <div className="flex gap-3">
      <span className="text-muted-foreground w-28 shrink-0 text-xs pt-0.5">{label}</span>
      <span className="text-sm">{value}</span>
    </div>
  )
}

// ── New Request Modal ──

interface NewRequestModalProps {
  userId: string
  userName: string
  onClose: () => void
  onCreated: (wf: ApprovalWorkflow) => void
}

const NEW_REQUEST_TYPES = REQUEST_TYPES.filter((t) => t !== 'All') as string[]

function NewRequestModal({ userId, userName, onClose, onCreated }: NewRequestModalProps) {
  const [requestType, setRequestType] = useState(NEW_REQUEST_TYPES[0])
  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<string>('Medium')
  const [dueDate, setDueDate] = useState('')
  const [location, setLocation] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) { setError('Please enter a request title'); return }
    setSubmitting(true)
    setError('')
    try {
      const supabase = createClient()
      const payload = {
        title: title.trim(),
        description: description.trim(),
        request_type: requestType,
        priority,
        status: 'Pending',
        requester_id: userId,
        requester_name: userName,
        requester_role: 'Admin',
        request_date: new Date().toISOString(),
        due_date: dueDate || null,
        location: location.trim() || null,
      }
      const { data, error: err } = await supabase
        .from('approval_workflows')
        .insert(payload)
        .select()
        .single()
      if (err) throw err
      onCreated(data as ApprovalWorkflow)
    } catch (err: any) {
      setError(err.message || 'Failed to create request')
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-card border border-border rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto shadow-2xl">
        <div className="flex items-center justify-between p-5 border-b border-border">
          <h2 className="font-semibold text-base">New Request</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-5 space-y-4">
          {/* Request Type */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-muted-foreground">Request Type</label>
            <div className="relative">
              <select
                value={requestType}
                onChange={(e) => setRequestType(e.target.value)}
                className="w-full appearance-none px-3 py-2 text-sm rounded-lg border border-input bg-background focus:outline-none focus:ring-2 focus:ring-ring pr-8"
              >
                {NEW_REQUEST_TYPES.map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
              <ChevronDown className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" />
            </div>
          </div>

          {/* Title */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-muted-foreground">Title <span className="text-destructive">*</span></label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Enter request title..."
              className="w-full px-3 py-2 text-sm rounded-lg border border-input bg-background focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Description */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-muted-foreground">Description</label>
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe the request..."
              rows={3}
              className="w-full px-3 py-2 text-sm rounded-lg border border-input bg-background resize-none focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Priority */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-muted-foreground">Priority</label>
            <div className="flex gap-2 flex-wrap">
              {PRIORITIES.map((p) => (
                <button
                  key={p}
                  type="button"
                  onClick={() => setPriority(p)}
                  className={cn(
                    'px-3 py-1.5 text-xs font-medium rounded-full border transition-colors',
                    priority === p
                      ? p === 'Critical' || p === 'High'
                        ? 'bg-red-500 text-white border-red-500'
                        : p === 'Medium'
                        ? 'bg-amber-500 text-white border-amber-500'
                        : 'bg-emerald-500 text-white border-emerald-500'
                      : 'bg-background text-muted-foreground border-input hover:border-foreground/30'
                  )}
                >
                  {p}
                </button>
              ))}
            </div>
          </div>

          {/* Due Date */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-muted-foreground">Due Date (optional)</label>
            <input
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              className="w-full px-3 py-2 text-sm rounded-lg border border-input bg-background focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Location */}
          <div className="space-y-1.5">
            <label className="text-xs font-medium text-muted-foreground">Location (optional)</label>
            <input
              type="text"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              placeholder="Site or location..."
              className="w-full px-3 py-2 text-sm rounded-lg border border-input bg-background focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {error && (
            <p className="text-xs text-destructive">{error}</p>
          )}

          <div className="flex gap-2 pt-1">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 text-sm py-2.5 rounded-xl border border-input hover:bg-accent transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="flex-1 text-sm py-2.5 rounded-xl bg-primary text-primary-foreground hover:bg-primary/90 disabled:opacity-50 transition-colors font-medium flex items-center justify-center gap-2"
            >
              {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
              Submit Request
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
