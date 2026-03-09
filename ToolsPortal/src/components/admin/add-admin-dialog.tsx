'use client'

import { useState } from 'react'
import { X, Loader2 } from 'lucide-react'
import { inviteAdmin, updateAdmin } from '@/lib/supabase/actions'
import type { User, AdminPosition } from '@/lib/types/database'

interface AddAdminDialogProps {
  open: boolean
  admin: User | null  // null = create mode, non-null = edit mode
  positions: AdminPosition[]
  onClose: () => void
  onSuccess: (admin: User) => void
}

export function AddAdminDialog({ open, admin, positions, onClose, onSuccess }: AddAdminDialogProps) {
  const isEdit = !!admin
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [form, setForm] = useState({
    full_name: admin?.full_name || '',
    email: admin?.email || '',
    position_id: admin?.position_id || positions[0]?.id || '',
    status: (admin as unknown as Record<string, string>)?.status || 'Active',
  })

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
    setError('')
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.full_name.trim() || !form.email.trim() || !form.position_id) return

    setSaving(true)
    setError('')
    setSuccess('')

    if (isEdit) {
      const ok = await updateAdmin(admin!.id, form.full_name.trim(), form.status, form.position_id)
      setSaving(false)
      if (ok) {
        onSuccess({
          ...admin!,
          full_name: form.full_name.trim(),
          position_id: form.position_id,
        })
      } else {
        setError('Failed to update admin. Please try again.')
      }
    } else {
      const result = await inviteAdmin(form.email.trim(), form.full_name.trim(), form.position_id)
      setSaving(false)
      if (result.error) {
        if (result.error.toLowerCase().includes('already') || result.error.toLowerCase().includes('exists')) {
          setError('This email already has an admin account. Ask them to sign in or reset their password.')
        } else {
          setError(result.error)
        }
      } else {
        setSuccess(`An invite email has been sent to ${form.email}`)
        setTimeout(() => {
          onSuccess({
            id: result.userId || '',
            email: form.email.trim(),
            full_name: form.full_name.trim(),
            role: 'admin',
            position_id: form.position_id,
            created_at: new Date().toISOString(),
          })
        }, 1500)
      }
    }
  }

  if (!open) return null

  const inputClass = 'w-full h-9 px-3 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring'
  const selectClass = 'w-full h-9 px-3 rounded-lg bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring appearance-none cursor-pointer'

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[500px] shadow-xl mx-4">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">{isEdit ? 'Edit Admin' : 'Add New Admin'}</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          {error && (
            <div className="bg-destructive/10 text-destructive rounded-lg px-3 py-2 text-sm">
              {error}
            </div>
          )}
          {success && (
            <div className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 rounded-lg px-3 py-2 text-sm">
              {success}
            </div>
          )}

          {/* Full Name */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Full Name *</label>
            <input
              type="text"
              value={form.full_name}
              onChange={(e) => updateField('full_name', e.target.value)}
              placeholder="e.g. John Doe"
              required
              className={inputClass}
            />
          </div>

          {/* Email */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Email Address *</label>
            <input
              type="email"
              value={form.email}
              onChange={(e) => updateField('email', e.target.value)}
              placeholder="e.g. admin@company.com"
              required
              disabled={isEdit}
              className={`${inputClass} ${isEdit ? 'opacity-50 cursor-not-allowed' : ''}`}
            />
            {isEdit && (
              <p className="text-xs text-muted-foreground mt-1">Email cannot be changed</p>
            )}
          </div>

          {/* Position */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Position *</label>
            <div className="relative">
              <select
                value={form.position_id}
                onChange={(e) => updateField('position_id', e.target.value)}
                required
                className={selectClass}
              >
                <option value="" disabled>Select a position</option>
                {positions.map((pos) => (
                  <option key={pos.id} value={pos.id}>{pos.name}</option>
                ))}
              </select>
              <svg className="absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground pointer-events-none" viewBox="0 0 16 16" fill="none"><path d="M4 6l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
          </div>

          {/* Status */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Status</label>
            <div className="relative">
              <select
                value={form.status}
                onChange={(e) => updateField('status', e.target.value)}
                className={selectClass}
              >
                <option value="Active">Active</option>
                <option value="Inactive">Inactive</option>
              </select>
              <svg className="absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground pointer-events-none" viewBox="0 0 16 16" fill="none"><path d="M4 6l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
          </div>
        </form>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button
            type="button"
            onClick={onClose}
            className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleSubmit}
            disabled={saving || !form.full_name.trim() || !form.email.trim() || !form.position_id || !!success}
            className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
          >
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            {saving ? (isEdit ? 'Saving...' : 'Inviting...') : (isEdit ? 'Save Changes' : 'Add Admin')}
          </button>
        </div>
      </div>
    </div>
  )
}
