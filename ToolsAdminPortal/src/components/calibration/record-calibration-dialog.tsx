'use client'

import { useState, useEffect } from 'react'
import { X, Loader2 } from 'lucide-react'
import { addCalibrationRecord } from '@/lib/supabase/actions'
import { useAuth } from '@/hooks/use-auth'
import type { Tool, Certification } from '@/lib/types/database'

interface RecordCalibrationDialogProps {
  open: boolean
  tools: Tool[]
  preselectedTool: Tool | null
  onClose: () => void
  onSuccess: (cert: Certification) => void
}

export function RecordCalibrationDialog({ open, tools, preselectedTool, onClose, onSuccess }: RecordCalibrationDialogProps) {
  const { profile } = useAuth()
  const [saving, setSaving] = useState(false)

  const today = new Date().toISOString().split('T')[0]
  const oneYearLater = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]

  const [form, setForm] = useState({
    tool_id: '',
    certification_number: '',
    issuing_authority: 'Dubai Municipality',
    issue_date: today,
    expiry_date: oneYearLater,
    inspector_name: '',
    notes: '',
  })

  useEffect(() => {
    if (open) {
      setForm({
        tool_id: preselectedTool?.id || '',
        certification_number: '',
        issuing_authority: 'Dubai Municipality',
        issue_date: today,
        expiry_date: oneYearLater,
        inspector_name: '',
        notes: '',
      })
    }
  }, [open, preselectedTool, today, oneYearLater])

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const selectedTool = tools.find((t) => t.id === form.tool_id)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.tool_id || !form.certification_number.trim()) return
    setSaving(true)

    const cert = await addCalibrationRecord({
      tool_id: form.tool_id,
      tool_name: selectedTool?.name || '',
      certification_number: form.certification_number.trim(),
      issuing_authority: form.issuing_authority.trim(),
      issue_date: form.issue_date,
      expiry_date: form.expiry_date,
      inspector_name: form.inspector_name.trim() || undefined,
      notes: form.notes.trim() || undefined,
    }, profile?.full_name || 'Admin')

    setSaving(false)
    if (cert) onSuccess(cert)
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[520px] mx-4 shadow-xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-4 border-b border-border">
          <h2 className="text-lg font-semibold">Record Calibration</h2>
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

          {/* Certificate number */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Certificate Number *</label>
            <input
              type="text"
              value={form.certification_number}
              onChange={(e) => updateField('certification_number', e.target.value)}
              required
              placeholder="e.g. CAL-2026-001"
              className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Issuing authority */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Issuing Authority *</label>
            <input
              type="text"
              value={form.issuing_authority}
              onChange={(e) => updateField('issuing_authority', e.target.value)}
              required
              className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Dates */}
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-sm font-medium text-muted-foreground">Issue Date *</label>
              <input
                type="date"
                value={form.issue_date}
                onChange={(e) => updateField('issue_date', e.target.value)}
                required
                className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-muted-foreground">Expiry Date *</label>
              <input
                type="date"
                value={form.expiry_date}
                onChange={(e) => updateField('expiry_date', e.target.value)}
                required
                className="w-full h-10 px-3 mt-1 rounded-lg border border-input bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring"
              />
            </div>
          </div>

          {/* Inspector */}
          <div>
            <label className="text-sm font-medium text-muted-foreground">Inspector Name</label>
            <input
              type="text"
              value={form.inspector_name}
              onChange={(e) => updateField('inspector_name', e.target.value)}
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
              disabled={saving || !form.tool_id || !form.certification_number.trim()}
              className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
            >
              {saving && <Loader2 className="w-4 h-4 animate-spin" />}
              {saving ? 'Saving...' : 'Record Calibration'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
