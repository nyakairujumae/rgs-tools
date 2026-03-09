'use client'

import { useState } from 'react'
import { X, Loader2 } from 'lucide-react'
import { updateTool } from '@/lib/supabase/actions'
import { useAuth } from '@/hooks/use-auth'
import type { Tool } from '@/lib/types/database'

const CATEGORIES = [
  'Testing Equipment', 'HVAC Tools', 'Power Tools', 'Hand Tools',
  'Safety Equipment', 'Cleaning Equipment', 'Measuring Tools',
  'Plumbing Tools', 'Electrical Tools', 'Other',
]
const CONDITIONS = ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair']
const STATUSES = ['Available', 'In Use', 'Maintenance', 'Retired']

interface EditToolDialogProps {
  tool: Tool
  open: boolean
  onClose: () => void
  onSuccess: (tool: Tool) => void
}

export function EditToolDialog({ tool, open, onClose, onSuccess }: EditToolDialogProps) {
  const { profile } = useAuth()
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    name: tool.name,
    category: tool.category,
    brand: tool.brand || '',
    model: tool.model || '',
    serial_number: tool.serial_number || '',
    purchase_date: tool.purchase_date || '',
    purchase_price: tool.purchase_price?.toString() || '',
    current_value: tool.current_value?.toString() || '',
    condition: tool.condition,
    location: tool.location || '',
    status: tool.status,
    notes: tool.notes || '',
  })

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return
    setSaving(true)

    const updates: Partial<Tool> = {
      name: form.name.trim(),
      category: form.category,
      brand: form.brand.trim() || undefined,
      model: form.model.trim() || undefined,
      serial_number: form.serial_number.trim() || undefined,
      purchase_date: form.purchase_date || undefined,
      purchase_price: form.purchase_price ? parseFloat(form.purchase_price) : undefined,
      current_value: form.current_value ? parseFloat(form.current_value) : undefined,
      condition: form.condition,
      location: form.location.trim() || undefined,
      status: form.status as Tool['status'],
      notes: form.notes.trim() || undefined,
    }

    const result = await updateTool(tool.id, updates, tool, profile?.full_name || 'Admin')
    setSaving(false)

    if (result) {
      onSuccess(result)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[600px] max-h-[80vh] overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">Edit Tool</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 overflow-y-auto max-h-[calc(80vh-130px)] space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5">Name *</label>
            <input type="text" value={form.name} onChange={(e) => updateField('name', e.target.value)} required className="w-full h-9 px-3 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Category</label>
              <div className="relative">
                <select value={form.category} onChange={(e) => updateField('category', e.target.value)} className="w-full h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer">
                  {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
                <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Status</label>
              <div className="relative">
                <select value={form.status} onChange={(e) => updateField('status', e.target.value)} className="w-full h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer">
                  {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
                </select>
                <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Brand</label>
              <input type="text" value={form.brand} onChange={(e) => updateField('brand', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Model</label>
              <input type="text" value={form.model} onChange={(e) => updateField('model', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5">Serial Number</label>
            <input type="text" value={form.serial_number} onChange={(e) => updateField('serial_number', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Condition</label>
              <div className="relative">
                <select value={form.condition} onChange={(e) => updateField('condition', e.target.value)} className="w-full h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer">
                  {CONDITIONS.map((c) => <option key={c} value={c}>{c}</option>)}
                </select>
                <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Location</label>
              <input type="text" value={form.location} onChange={(e) => updateField('location', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Purchase Price (AED)</label>
              <input type="number" step="0.01" value={form.purchase_price} onChange={(e) => updateField('purchase_price', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Current Value (AED)</label>
              <input type="number" step="0.01" value={form.current_value} onChange={(e) => updateField('current_value', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm appearance-none" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5">Notes</label>
            <textarea value={form.notes} onChange={(e) => updateField('notes', e.target.value)} rows={3} className="w-full px-3 py-2 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring" />
          </div>
        </form>

        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button type="button" onClick={onClose} className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors">
            Cancel
          </button>
          <button onClick={handleSubmit} disabled={saving || !form.name.trim()} className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2">
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  )
}
