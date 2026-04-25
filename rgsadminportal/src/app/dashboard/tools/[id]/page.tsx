'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { formatAED, formatDate, timeAgo } from '@/lib/utils'
import { StatusBadge } from '@/components/shared/status-badge'
import { useBreadcrumbLabel } from '@/components/layout/breadcrumb-context'
import {
  ArrowLeft,
  Wrench,
  MapPin,
  Calendar,
  DollarSign,
  User,
  Tag,
  Hash,
  Loader2,
  Clock,
  Pencil,
  Trash2,
} from 'lucide-react'
import { deleteTool as deleteToolAction } from '@/lib/supabase/actions'
import { EditToolDialog } from '@/components/tools/edit-tool-dialog'
import type { Tool, ToolHistory } from '@/lib/types/database'

const HISTORY_PREVIEW = 4

function HistoryCard({ history }: { history: ToolHistory[] }) {
  const [expanded, setExpanded] = useState(false)
  const visible = expanded ? history : history.slice(0, HISTORY_PREVIEW)

  return (
    <div className="bg-card border border-border rounded-xl">
      <div className="px-5 py-4 border-b border-border">
        <h2 className="text-sm font-semibold">History</h2>
      </div>
      <div className="divide-y divide-border">
        {history.length === 0 ? (
          <div className="py-8 text-center text-sm text-muted-foreground">No history recorded</div>
        ) : (
          visible.map((h) => (
            <div key={h.id} className="px-5 py-3">
              <div className="flex items-center gap-2">
                <Clock className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
                <span className="text-sm font-medium">{h.action}</span>
                <span className="text-xs text-muted-foreground ml-auto whitespace-nowrap">{timeAgo(h.timestamp)}</span>
              </div>
              <p className="text-xs text-muted-foreground mt-1 pl-5">{h.description}</p>
              {h.performed_by && (
                <p className="text-xs text-muted-foreground pl-5">by {h.performed_by}</p>
              )}
            </div>
          ))
        )}
      </div>
      {history.length > HISTORY_PREVIEW && (
        <button
          onClick={() => setExpanded((e) => !e)}
          className="w-full px-5 py-3 text-xs text-muted-foreground hover:text-foreground border-t border-border transition-colors text-center"
        >
          {expanded ? 'Show less' : `Show ${history.length - HISTORY_PREVIEW} more`}
        </button>
      )}
    </div>
  )
}

export default function ToolDetailPage() {
  const { id } = useParams()
  const router = useRouter()
  const setBreadcrumbLabel = useBreadcrumbLabel()?.setLabel
  const [tool, setTool] = useState<Tool | null>(null)
  const [history, setHistory] = useState<ToolHistory[]>([])
  const [assignedToName, setAssignedToName] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [lightbox, setLightbox] = useState(false)
  const [showEdit, setShowEdit] = useState(false)
  const [deleteConfirm, setDeleteConfirm] = useState(false)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const [{ data: toolData }, { data: historyData }] = await Promise.all([
        supabase.from('tools').select('*').eq('id', id).single(),
        supabase.from('tool_history').select('*').eq('tool_id', id).order('timestamp', { ascending: false }).limit(20),
      ])
      setTool(toolData)
      setHistory(historyData || [])
      if (toolData?.assigned_to) {
        const [techRes, userRes] = await Promise.all([
          supabase.from('technicians').select('name').or(`user_id.eq.${toolData.assigned_to},id.eq.${toolData.assigned_to}`).limit(1).maybeSingle(),
          supabase.from('users').select('full_name').eq('id', toolData.assigned_to).maybeSingle(),
        ])
        setAssignedToName(techRes.data?.name ?? userRes.data?.full_name ?? null)
      } else {
        setAssignedToName(null)
      }
      setLoading(false)
    }
    fetch()
  }, [id])

  // Show tool name in breadcrumb instead of raw ID
  useEffect(() => {
    if (tool?.name) setBreadcrumbLabel?.(tool.name)
    return () => { setBreadcrumbLabel?.(null) }
  }, [tool?.name, setBreadcrumbLabel])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
      </div>
    )
  }

  if (!tool) {
    return (
      <div className="p-6 text-center">
        <p className="text-muted-foreground">Tool not found</p>
        <Link href="/dashboard/tools" className="text-primary text-sm hover:underline mt-2 inline-block">
          Back to tools
        </Link>
      </div>
    )
  }

  const details = [
    { icon: <Tag className="w-4 h-4" />, label: 'Category', value: tool.category },
    { icon: <Wrench className="w-4 h-4" />, label: 'Brand', value: tool.brand || '-' },
    { icon: <Hash className="w-4 h-4" />, label: 'Model', value: tool.model || '-' },
    { icon: <Hash className="w-4 h-4" />, label: 'Serial #', value: tool.serial_number || '-' },
    { icon: <MapPin className="w-4 h-4" />, label: 'Location', value: tool.location || '-' },
    { icon: <User className="w-4 h-4" />, label: 'Assigned To', value: assignedToName ?? (tool.assigned_to ? '—' : 'Unassigned') },
    { icon: <Calendar className="w-4 h-4" />, label: 'Purchase Date', value: formatDate(tool.purchase_date) },
    { icon: <DollarSign className="w-4 h-4" />, label: 'Purchase Price', value: formatAED(tool.purchase_price) },
    { icon: <DollarSign className="w-4 h-4" />, label: 'Current Value', value: formatAED(tool.current_value) },
  ]

  return (
    <div className="p-6 max-w-[1200px] mx-auto space-y-6">
      {/* Back */}
      <button
        onClick={() => router.back()}
        className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="w-4 h-4" /> Back to tools
      </button>

      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">{tool.name}</h1>
          <div className="flex items-center gap-3 mt-2">
            <StatusBadge status={tool.status} />
            <span className="text-sm text-muted-foreground">Condition: {tool.condition}</span>
            <span className="text-sm text-muted-foreground">Type: {tool.tool_type}</span>
          </div>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <button
            onClick={() => setShowEdit(true)}
            className="flex items-center gap-2 h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors"
          >
            <Pencil className="w-4 h-4" /> Edit
          </button>
          <button
            onClick={() => setDeleteConfirm(true)}
            className="flex items-center gap-2 h-9 px-4 rounded-lg border border-destructive/40 text-destructive text-sm font-medium hover:bg-destructive/10 transition-colors"
          >
            <Trash2 className="w-4 h-4" /> Delete
          </button>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6 lg:items-start">
        {/* Left column: image + details */}
        <div className="lg:col-span-2 flex flex-col gap-6">
          {/* Details */}
          <div className="bg-card border border-border rounded-xl">
            <div className="px-5 py-4 border-b border-border flex items-center justify-between gap-4">
              <h2 className="text-sm font-semibold">Details</h2>
              {tool.image_path && (
                <button
                  onClick={() => setLightbox(true)}
                  className="w-16 h-16 rounded-lg overflow-hidden border border-border shrink-0 hover:opacity-80 transition-opacity"
                >
                  <Image
                    src={tool.image_path}
                    alt={tool.name}
                    width={64}
                    height={64}
                    className="w-full h-full object-cover"
                  />
                </button>
              )}
            </div>
            <div className="p-5 grid sm:grid-cols-2 gap-4">
              {details.map((d) => (
                <div key={d.label} className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-lg bg-muted flex items-center justify-center text-muted-foreground shrink-0">
                    {d.icon}
                  </div>
                  <div>
                    <p className="text-xs text-muted-foreground">{d.label}</p>
                    <p className="text-sm font-medium mt-0.5">{d.value}</p>
                  </div>
                </div>
              ))}
            </div>
            {tool.notes && (
              <div className="px-5 pb-5">
                <p className="text-xs text-muted-foreground mb-1">Notes</p>
                <p className="text-sm bg-muted/50 rounded-lg p-3">{tool.notes}</p>
              </div>
            )}
          </div>
        </div>

        {/* History — natural height, scrollable when content grows */}
        <HistoryCard history={history} />
      </div>

      {/* Edit dialog */}
      {showEdit && (
        <EditToolDialog
          tool={tool}
          open={showEdit}
          onClose={() => setShowEdit(false)}
          onSuccess={(updated) => {
            setTool(updated)
            setShowEdit(false)
          }}
        />
      )}

      {/* Delete confirmation */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Delete Tool</h3>
            <p className="text-sm text-muted-foreground mt-2">
              Are you sure you want to delete <strong>{tool.name}</strong>? This action cannot be undone.
            </p>
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setDeleteConfirm(false)}
                className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={async () => {
                  setDeleting(true)
                  const ok = await deleteToolAction(tool.id)
                  setDeleting(false)
                  if (ok) router.push('/dashboard/tools')
                }}
                disabled={deleting}
                className="h-9 px-4 bg-destructive text-destructive-foreground rounded-lg text-sm font-medium hover:bg-destructive/90 disabled:opacity-50 transition-colors flex items-center gap-2"
              >
                {deleting && <Loader2 className="w-4 h-4 animate-spin" />}
                {deleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Image lightbox */}
      {lightbox && tool.image_path && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 p-4"
          onClick={() => setLightbox(false)}
        >
          <div className="relative max-w-3xl w-full max-h-[90vh]" onClick={(e) => e.stopPropagation()}>
            <Image
              src={tool.image_path}
              alt={tool.name}
              width={1200}
              height={900}
              className="w-full h-auto max-h-[90vh] object-contain rounded-xl"
            />
            <button
              onClick={() => setLightbox(false)}
              className="absolute top-3 right-3 w-8 h-8 flex items-center justify-center rounded-full bg-black/60 text-white hover:bg-black/80 transition-colors text-lg leading-none"
            >
              ×
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
