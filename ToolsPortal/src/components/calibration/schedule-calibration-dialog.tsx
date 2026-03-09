'use client'

import { useState, useEffect } from 'react'
import { X, Loader2 } from 'lucide-react'
import { scheduleCalibration } from '@/lib/supabase/actions'
import type { Tool, MaintenanceSchedule } from '@/lib/types/database'

const PRIORITIES = ['Low', 'Medium', 'High', 'Critical']

interface ScheduleCalibrationDialogProps {
  open: boolean
  tools: Tool[]
  preselectedTool: Tool | null
  onClose: () => void
  onSuccess: (schedule: MaintenanceSchedule) => void
}

export function ScheduleCalibrationDialog({ open, tools, preselectedTool, onClose, onSuccess }: ScheduleCalibrationDialogProps) {
  const [saving, setSaving] = useState(false)

  const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

  const [form, setForm] = useState({
    tool_id: '',
    scheduled_date: nextWeek,
    interval_days: '90',
    priority: 'High',
    assigned_to: '',
    estimated_cost: '',
    notes: '',
  })

  useEffect(() => {
    if (open) {
      setForm({
        tool_id: preselectedTool?.id || '',
        scheduled_date: nextWeek,
        interval_days: '90',
        priority: 'High',
        assigned_to: '',
        estimated_cost: '',
        notes: '',
      })
    }
  }, [open, preselectedTool, nextWeek])

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const selectedTool = tools.find((t) => t.id === form.tool_id)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.tool_id || !form.scheduled_date) return
    setSaving(true)

    const schedule = await scheduleCalibration({
      tool_id: form.tool_id,
      tool_name: selectedTool?.name || '',
      scheduled_date: form.scheduled_date,
      interval_days: parseInt(form.interval_days) || 90,
      priority: form.priority,
      assigned_to: form.assigned_to.trim() || undefined,
      estimated_cost: form.estimated_cost ? parseFloat(form.estimated_cost) : undefined,
      notes: form.notes.trim() || undefined,
    })

    setSaving(false)
    if (schedule) onSuccess(schedule)
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[520px] mx-4 shadow-xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-4 border-b border-border">
          <h2 className="text-lg font-semibold">Schedule Calibration</h2>
          <button onClick={onClose} className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground">
            <X className="w-4 h-4" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-4 space-y-4">
          {/* Tool selection */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Tool *</label>
            <div className="relative mt-1">
              <select
                value={form.tool_id}
                onChange={(e) => updateField('tool_id', e.target.value)}
                required
                className="w-full h-10 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer focus:outline-none focus:ring-2 focus:ring-ring"
              >
                <option value="">Select a tool...</option>
                {tools.map((t) => (
                  <option key={t.id} value={t.id}>{t.name} {t.serial_number ? `(${t.serial_number})` : ''}</option>
                ))}
              </select>
              <svg className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
            </div>
          </div>

          {/* Scheduled date + Interval */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-sm font-medium text-muted-foreground">Scheduled Date *</label>
              <input
                type="date"
                value={form.scheduled_date}
                onChange={(e) => updateField('scheduled_date', e.target.value)}
                required
                className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-muted-foreground">Interval (days)</label>
              <input
                type="number"
                value={form.interval_days}
                onChange={(e) => updateField('interval_days', e.target.value)}
                min="1"
                className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
          </div>

          {/* Priority */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Priority</label>
            <div className="relative mt-1">
              <select
                value={form.priority}
                onChange={(e) => updateField('priority', e.target.value)}
                className="w-full h-10 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer focus:outline-none focus:ring-2 focus:ring-ring"
              >
                {PRIORITIES.map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
              <svg className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
            </div>
          </div>

          {/* Assigned to */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Assigned To</label>
            <input
              type="text"
              value={form.assigned_to}
              onChange={(e) => updateField('assigned_to', e.target.value)}
              placeholder="Optional — technician or lab name"
              className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Estimated cost */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Estimated Cost (AED)</label>
            <input
              type="number"
              value={form.estimated_cost}
              onChange={(e) => updateField('estimated_cost', e.target.value)}
              min="0"
              step="0.01"
              placeholder="Optional"
              className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Notes */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Notes</label>
            <textarea
              value={form.notes}
              onChange={(e) => updateField('notes', e.target.value)}
              rows={2}
              placeholder="Optional"
              className="w-full px-3 py-2 mt-1 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring resize-none"
            />
          </div>

          {/* Actions */}
          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving || !form.tool_id || !form.scheduled_date}
              className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
            >
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              {saving ? 'Scheduling...' : 'Schedule Calibration'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
