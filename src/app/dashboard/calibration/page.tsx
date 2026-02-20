'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { deleteCalibrationRecord } from '@/lib/supabase/actions'
import { StatusBadge } from '@/components/shared/status-badge'
import { formatDate, cn } from '@/lib/utils'
import {
  Loader2,
  Search,
  X,
  Plus,
  CheckCircle,
  AlertTriangle,
  XCircle,
  CircleDashed,
  Pencil,
  Trash2,
  CalendarPlus,
  FileCheck,
} from 'lucide-react'
import { RecordCalibrationDialog } from '@/components/calibration/record-calibration-dialog'
import { ScheduleCalibrationDialog } from '@/components/calibration/schedule-calibration-dialog'
import type { Tool, Certification, MaintenanceSchedule } from '@/lib/types/database'

type CalibrationStatus = 'Calibrated' | 'Due Soon' | 'Overdue' | 'Not Calibrated'

interface ToolCalibration {
  tool: Tool
  latestCert: Certification | null
  nextSchedule: MaintenanceSchedule | null
  status: CalibrationStatus
  daysUntilExpiry: number | null
}

export default function CalibrationPage() {
  const [tools, setTools] = useState<Tool[]>([])
  const [certs, setCerts] = useState<Certification[]>([])
  const [schedules, setSchedules] = useState<MaintenanceSchedule[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [tab, setTab] = useState<'all' | CalibrationStatus | 'Scheduled'>('all')
  const [showRecordDialog, setShowRecordDialog] = useState(false)
  const [showScheduleDialog, setShowScheduleDialog] = useState(false)
  const [preselectedTool, setPreselectedTool] = useState<Tool | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<Certification | null>(null)
  const [deleting, setDeleting] = useState(false)

  const fetchData = async () => {
    const supabase = createClient()
    const [{ data: toolData }, { data: certData }, { data: schedData }] = await Promise.all([
      supabase.from('tools').select('*').order('name'),
      supabase.from('certifications').select('*').eq('certification_type', 'Calibration Certificate').order('expiry_date', { ascending: false }),
      supabase.from('maintenance_schedules').select('*').eq('maintenance_type', 'Calibration').order('scheduled_date', { ascending: true }),
    ])
    setTools(toolData || [])
    setCerts(certData || [])
    setSchedules(schedData || [])
    setLoading(false)
  }

  useEffect(() => {
    fetchData()

    const supabase = createClient()
    const channel = supabase
      .channel('calibration-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'certifications' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'maintenance_schedules' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tools' }, () => fetchData())
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const toolCalibrations = useMemo((): ToolCalibration[] => {
    const now = new Date()
    return tools.map((tool) => {
      const toolCerts = certs.filter((c) => c.tool_id === tool.id)
      const latestCert = toolCerts[0] || null
      const toolSchedules = schedules.filter((s) => s.tool_id === tool.id && s.status !== 'Completed' && s.status !== 'Cancelled')
      const nextSchedule = toolSchedules[0] || null

      let status: CalibrationStatus = 'Not Calibrated'
      let daysUntilExpiry: number | null = null

      if (latestCert) {
        const expiry = new Date(latestCert.expiry_date)
        daysUntilExpiry = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
        if (daysUntilExpiry < 0) {
          status = 'Overdue'
        } else if (daysUntilExpiry <= 30) {
          status = 'Due Soon'
        } else {
          status = 'Calibrated'
        }
      }

      return { tool, latestCert, nextSchedule, status, daysUntilExpiry }
    })
  }, [tools, certs, schedules])

  const counts = useMemo(() => ({
    all: toolCalibrations.length,
    Calibrated: toolCalibrations.filter((t) => t.status === 'Calibrated').length,
    'Due Soon': toolCalibrations.filter((t) => t.status === 'Due Soon').length,
    Overdue: toolCalibrations.filter((t) => t.status === 'Overdue').length,
    'Not Calibrated': toolCalibrations.filter((t) => t.status === 'Not Calibrated').length,
    Scheduled: schedules.filter((s) => s.status === 'Scheduled').length,
  }), [toolCalibrations, schedules])

  const filtered = useMemo(() => {
    let result = toolCalibrations

    if (tab === 'Scheduled') {
      const scheduledToolIds = new Set(schedules.filter((s) => s.status === 'Scheduled').map((s) => s.tool_id))
      result = result.filter((t) => scheduledToolIds.has(t.tool.id))
    } else if (tab !== 'all') {
      result = result.filter((t) => t.status === tab)
    }

    if (search) {
      const q = search.toLowerCase()
      result = result.filter((t) =>
        t.tool.name.toLowerCase().includes(q) ||
        t.tool.category?.toLowerCase().includes(q) ||
        t.tool.serial_number?.toLowerCase().includes(q) ||
        t.latestCert?.certification_number?.toLowerCase().includes(q)
      )
    }

    return result
  }, [toolCalibrations, tab, search, schedules])

  const handleDelete = async () => {
    if (!deleteConfirm) return
    setDeleting(true)
    const success = await deleteCalibrationRecord(deleteConfirm.id)
    if (success) {
      setCerts((prev) => prev.filter((c) => c.id !== deleteConfirm.id))
    }
    setDeleting(false)
    setDeleteConfirm(null)
  }

  const openRecordForTool = (tool: Tool) => {
    setPreselectedTool(tool)
    setShowRecordDialog(true)
  }

  const openScheduleForTool = (tool: Tool) => {
    setPreselectedTool(tool)
    setShowScheduleDialog(true)
  }

  if (loading) {
    return <div className="flex items-center justify-center h-full"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Calibration Tracking</h1>
          <p className="text-sm text-muted-foreground">
            {counts.Overdue > 0 ? `${counts.Overdue} overdue` : 'All calibrations up to date'} — {tools.length} tools
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => { setPreselectedTool(null); setShowScheduleDialog(true) }}
            className="flex items-center gap-2 px-4 h-9 border border-input rounded-lg text-sm font-medium hover:bg-accent transition-colors"
          >
            <CalendarPlus className="w-4 h-4" />
            Schedule
          </button>
          <button
            onClick={() => { setPreselectedTool(null); setShowRecordDialog(true) }}
            className="flex items-center gap-2 px-4 h-9 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors"
          >
            <Plus className="w-4 h-4" />
            Record Calibration
          </button>
        </div>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
            <CheckCircle className="w-5 h-5 text-emerald-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Calibrated}</p>
            <p className="text-xs text-muted-foreground">Calibrated</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts['Due Soon']}</p>
            <p className="text-xs text-muted-foreground">Due Soon</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-red-500/10 flex items-center justify-center">
            <XCircle className="w-5 h-5 text-red-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Overdue}</p>
            <p className="text-xs text-muted-foreground">Overdue</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
            <CircleDashed className="w-5 h-5 text-muted-foreground" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts['Not Calibrated']}</p>
            <p className="text-xs text-muted-foreground">Not Calibrated</p>
          </div>
        </div>
      </div>

      {/* Search + Tabs */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search tools..."
            className="w-full h-9 pl-9 pr-8 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </div>

      <div className="flex items-center gap-1 border-b border-border">
        {(['all', 'Calibrated', 'Due Soon', 'Overdue', 'Not Calibrated', 'Scheduled'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              'px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
              tab === t ? 'border-primary text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            {t === 'all' ? 'All Tools' : t}
            <span className="ml-1.5 text-xs bg-muted px-1.5 py-0.5 rounded-full">{counts[t as keyof typeof counts] ?? 0}</span>
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-xl">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Tool</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Category</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Serial #</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Last Calibrated</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Expires</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Certificate</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr><td colSpan={8} className="py-12 text-center text-muted-foreground">
                {search ? 'No tools match your search' : 'No tools found'}
              </td></tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.tool.id} className="hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-medium">{item.tool.name}</td>
                  <td className="px-4 py-3 text-muted-foreground">{item.tool.category}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{item.tool.serial_number || '-'}</td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {item.latestCert ? formatDate(item.latestCert.issue_date) : '-'}
                  </td>
                  <td className="px-4 py-3 text-muted-foreground">
                    {item.latestCert ? (
                      <span className={cn(
                        item.daysUntilExpiry !== null && item.daysUntilExpiry < 0 && 'text-red-500',
                        item.daysUntilExpiry !== null && item.daysUntilExpiry >= 0 && item.daysUntilExpiry <= 30 && 'text-amber-500',
                      )}>
                        {formatDate(item.latestCert.expiry_date)}
                        {item.daysUntilExpiry !== null && (
                          <span className="text-xs ml-1">
                            ({item.daysUntilExpiry < 0 ? `${Math.abs(item.daysUntilExpiry)}d overdue` : `${item.daysUntilExpiry}d left`})
                          </span>
                        )}
                      </span>
                    ) : '-'}
                  </td>
                  <td className="px-4 py-3">
                    <CalibrationStatusBadge status={item.status} />
                  </td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">
                    {item.latestCert?.certification_number || '-'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => openRecordForTool(item.tool)}
                        className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground hover:text-foreground"
                        title="Record Calibration"
                      >
                        <FileCheck className="w-3.5 h-3.5" />
                      </button>
                      <button
                        onClick={() => openScheduleForTool(item.tool)}
                        className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground hover:text-foreground"
                        title="Schedule Calibration"
                      >
                        <CalendarPlus className="w-3.5 h-3.5" />
                      </button>
                      {item.latestCert && (
                        <button
                          onClick={() => setDeleteConfirm(item.latestCert)}
                          className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-destructive/10 transition-colors text-muted-foreground hover:text-destructive"
                          title="Delete Certificate"
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Record Calibration Dialog */}
      <RecordCalibrationDialog
        open={showRecordDialog}
        tools={tools}
        preselectedTool={preselectedTool}
        onClose={() => { setShowRecordDialog(false); setPreselectedTool(null) }}
        onSuccess={(cert) => {
          setCerts((prev) => [cert, ...prev])
          setShowRecordDialog(false)
          setPreselectedTool(null)
        }}
      />

      {/* Schedule Calibration Dialog */}
      <ScheduleCalibrationDialog
        open={showScheduleDialog}
        tools={tools}
        preselectedTool={preselectedTool}
        onClose={() => { setShowScheduleDialog(false); setPreselectedTool(null) }}
        onSuccess={(sched) => {
          setSchedules((prev) => [sched, ...prev])
          setShowScheduleDialog(false)
          setPreselectedTool(null)
        }}
      />

      {/* Delete Confirmation */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Delete Calibration Record</h3>
            <p className="text-sm text-muted-foreground mt-2">
              Are you sure you want to delete the calibration certificate
              <strong> {deleteConfirm.certification_number}</strong> for <strong>{deleteConfirm.tool_name}</strong>?
              This action cannot be undone.
            </p>
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setDeleteConfirm(null)}
                className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleDelete}
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
    </div>
  )
}

// ── Calibration Status Badge ──

function CalibrationStatusBadge({ status }: { status: CalibrationStatus }) {
  const colors: Record<CalibrationStatus, string> = {
    'Calibrated': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'Due Soon': 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    'Overdue': 'bg-red-500/15 text-red-700 dark:text-red-400',
    'Not Calibrated': 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400',
  }

  return (
    <span className={cn('inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium', colors[status])}>
      {status}
    </span>
  )
}
