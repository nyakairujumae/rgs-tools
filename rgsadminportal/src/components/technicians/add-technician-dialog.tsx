'use client'

import { useState } from 'react'
import { X, Loader2, CheckCircle2 } from 'lucide-react'
import { addTechnician } from '@/lib/supabase/actions'
import type { Technician } from '@/lib/types/database'

interface AddTechnicianDialogProps {
  open: boolean
  onClose: () => void
  onSuccess: (tech: Technician) => void
}

export function AddTechnicianDialog({ open, onClose, onSuccess }: AddTechnicianDialogProps) {
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<{ tech: Technician; email: string } | null>(null)
  const [form, setForm] = useState({
    name: '',
    employee_id: '',
    phone: '',
    email: '',
    department: '',
    hire_date: '',
  })

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const handleClose = () => {
    setSuccess(null)
    setError(null)
    onClose()
  }

  const handleDone = () => {
    if (success) {
      onSuccess(success.tech)
      setSuccess(null)
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return
    setSaving(true)
    setError(null)

    const result = await addTechnician({
      name: form.name.trim(),
      employee_id: form.employee_id.trim() || undefined,
      phone: form.phone.trim() || undefined,
      email: form.email.trim() || undefined,
      department: form.department.trim() || undefined,
      hire_date: form.hire_date || undefined,
      status: 'Active',
    })

    setSaving(false)

    if (result) {
      setSuccess({ tech: result, email: form.email.trim() })
      setForm({ name: '', employee_id: '', phone: '', email: '', department: '', hire_date: '' })
    } else {
      setError('Failed to add technician. Please check the details and try again.')
    }
  }

  if (!open) return null

  if (success) {
    return (
      <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
        <div className="bg-card border border-border rounded-xl w-full max-w-[480px] overflow-hidden shadow-xl">
          <div className="flex items-center justify-between px-6 py-4 border-b border-border">
            <h2 className="text-lg font-semibold">Technician Added</h2>
            <button onClick={handleClose} className="text-muted-foreground hover:text-foreground">
              <X className="w-5 h-5" />
            </button>
          </div>
          <div className="p-8 flex flex-col items-center text-center gap-3">
            <CheckCircle2 className="w-12 h-12 text-green-500" />
            <p className="font-medium">{success.tech.name} has been added.</p>
            {success.email ? (
              <p className="text-sm text-muted-foreground">
                An invite email was sent to <strong>{success.email}</strong>. They can use it to set their password and access the app.
              </p>
            ) : (
              <p className="text-sm text-muted-foreground">
                No email was provided, so no invite was sent. You can edit the technician later to add their email.
              </p>
            )}
          </div>
          <div className="flex justify-center px-6 py-4 border-t border-border">
            <button
              onClick={handleDone}
              className="h-9 px-6 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors"
            >
              Done
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[480px] overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">Add Technician</h2>
          <button onClick={handleClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5">Full Name *</label>
            <input type="text" value={form.name} onChange={(e) => updateField('name', e.target.value)} required placeholder="e.g. Ahmed Hassan" className="w-full h-9 px-3 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Employee ID</label>
              <input type="text" value={form.employee_id} onChange={(e) => updateField('employee_id', e.target.value)} placeholder="e.g. EMP-001" className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Department</label>
              <input type="text" value={form.department} onChange={(e) => updateField('department', e.target.value)} placeholder="e.g. HVAC" className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Email</label>
              <input type="email" value={form.email} onChange={(e) => updateField('email', e.target.value)} placeholder="ahmed@company.com" className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Phone</label>
              <input type="tel" value={form.phone} onChange={(e) => updateField('phone', e.target.value)} placeholder="+971 XX XXX XXXX" className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5">Hire Date</label>
            <input type="date" value={form.hire_date} onChange={(e) => updateField('hire_date', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
          </div>
        </form>

        {error && (
          <div className="px-6 pb-2 text-sm text-destructive">{error}</div>
        )}
        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button type="button" onClick={handleClose} className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors">Cancel</button>
          <button onClick={handleSubmit} disabled={saving || !form.name.trim()} className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2">
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            {saving ? 'Adding...' : 'Add Technician'}
          </button>
        </div>
      </div>
    </div>
  )
}
