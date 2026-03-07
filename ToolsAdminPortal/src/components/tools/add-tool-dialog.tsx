'use client'

import { useState, useRef } from 'react'
import { X, Loader2, Camera, RefreshCw, Plus } from 'lucide-react'
import { addTool, uploadToolImage } from '@/lib/supabase/actions'
import { useAuth } from '@/hooks/use-auth'
import { useOrgContext } from '@/contexts/organization-context'
import Image from 'next/image'
import type { Tool } from '@/lib/types/database'

function capitalizeFirst(value: string) {
  if (!value) return value
  return value.charAt(0).toUpperCase() + value.slice(1)
}

const CONDITIONS = ['Excellent', 'Good', 'Fair', 'Poor']

// Matches Flutter app's ToolIdGenerator — prefix comes from org (e.g. LNK, RGS, TOOL)
function randomHex(len: number) {
  return Array.from({ length: len }, () => Math.floor(Math.random() * 16).toString(16)).join('').toUpperCase()
}

function generateSerialNumber(prefix: string) {
  const year = new Date().getFullYear()
  return `${prefix}-${year}-${randomHex(6)}`
}

function generateModelNumber(prefix: string) {
  return `${prefix}-MDL-${randomHex(4)}`
}

interface AddToolDialogProps {
  open: boolean
  onClose: () => void
  onSuccess: (tool: Tool) => void
  /** When set, the tool is assigned to this user on creation (e.g. admin adding from My Tools) */
  assignedTo?: string
}

export function AddToolDialog({ open, onClose, onSuccess, assignedTo }: AddToolDialogProps) {
  const { profile } = useAuth()
  const { toolCategories, idPrefix } = useOrgContext()
  const categories = toolCategories.length > 0 ? toolCategories : ['General', 'Other']
  const [saving, setSaving] = useState(false)
  const [imageFiles, setImageFiles] = useState<{ file: File; preview: string }[]>([])
  const fileInputRef = useRef<HTMLInputElement>(null)
  const [form, setForm] = useState({
    name: '',
    category: '',
    brand: '',
    model: '',
    serial_number: '',
    purchase_date: '',
    purchase_price: '',
    current_value: '',
    condition: 'Good',
    location: '',
    notes: '',
  })

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || [])
    files.forEach((file) => {
      const reader = new FileReader()
      reader.onloadend = () => {
        setImageFiles((prev) => [...prev, { file, preview: reader.result as string }])
      }
      reader.readAsDataURL(file)
    })
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const removeImage = (index: number) => {
    setImageFiles((prev) => prev.filter((_, i) => i !== index))
  }

  const handleGenerateSerial = () => {
    updateField('serial_number', generateSerialNumber(idPrefix))
  }

  const handleGenerateModel = () => {
    updateField('model', generateModelNumber(idPrefix))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return

    setSaving(true)

    let imagePath: string | null = null
    if (imageFiles.length > 0) {
      // Upload all images, first one becomes main image_path
      const uploads = await Promise.all(imageFiles.map((img) => uploadToolImage(img.file)))
      imagePath = uploads[0] || null
    }

    const result = await addTool(
      {
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
        status: 'Available',
        tool_type: 'inventory',
        image_path: imagePath || undefined,
        notes: form.notes.trim() || undefined,
        ...(assignedTo && { assigned_to: assignedTo }),
      },
      profile?.full_name || 'Admin'
    )

    setSaving(false)

    if (result) {
      onSuccess(result)
      setForm({
        name: '',
        category: '',
        brand: '',
        model: '',
        serial_number: '',
        purchase_date: '',
        purchase_price: '',
        current_value: '',
        condition: 'Good',
        location: '',
        notes: '',
      })
      setImageFiles([])
    }
  }

  if (!open) return null

  const inputClass = 'w-full h-9 px-3 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring'
  const selectClass = 'w-full h-9 px-3 rounded-lg bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring appearance-none cursor-pointer'

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[600px] max-h-[80vh] overflow-hidden shadow-xl">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">Add New Tool</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 overflow-y-auto max-h-[calc(80vh-130px)] space-y-4">
          {/* Image Upload - Prominent at top */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Tool Photos</label>
            <div className="flex gap-3 flex-wrap">
              {imageFiles.map((img, i) => (
                <div key={i} className="relative w-24 h-24 rounded-xl overflow-hidden border border-border group">
                  <Image src={img.preview} alt={`Photo ${i + 1}`} fill className="object-cover" />
                  {i === 0 && (
                    <span className="absolute top-1 left-1 bg-primary text-primary-foreground text-[10px] px-1.5 py-0.5 rounded-md font-medium">Main</span>
                  )}
                  <button
                    type="button"
                    onClick={() => removeImage(i)}
                    className="absolute top-1 right-1 w-5 h-5 bg-black/60 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <X className="w-3 h-3 text-white" />
                  </button>
                </div>
              ))}
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="w-24 h-24 rounded-xl border-2 border-dashed border-input bg-muted/30 flex flex-col items-center justify-center gap-1 cursor-pointer hover:bg-muted/50 transition-colors"
              >
                {imageFiles.length === 0 ? (
                  <>
                    <Camera className="w-6 h-6 text-muted-foreground/50" />
                    <span className="text-[10px] text-muted-foreground">Add Photo</span>
                  </>
                ) : (
                  <>
                    <Plus className="w-5 h-5 text-muted-foreground/50" />
                    <span className="text-[10px] text-muted-foreground">More</span>
                  </>
                )}
              </button>
            </div>
            <p className="text-xs text-muted-foreground mt-1.5">First photo is used as the main image. Add multiple to document condition.</p>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              multiple
              onChange={handleImageChange}
              className="hidden"
            />
          </div>

          {/* Name (required) */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Name *</label>
            <input
              type="text"
              value={form.name}
              onChange={(e) => updateField('name', capitalizeFirst(e.target.value))}
              placeholder="e.g. Digital Multimeter"
              required
              className={inputClass}
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            {/* Category */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Category *</label>
              <div className="relative">
                <select
                  value={form.category}
                  onChange={(e) => updateField('category', e.target.value)}
                  className={selectClass}
                >
                  {!form.category && <option value="">Select category...</option>}
                  {categories.map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
                <svg className="absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground pointer-events-none" viewBox="0 0 16 16" fill="none"><path d="M4 6l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </div>
            </div>

            {/* Condition */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Condition</label>
              <div className="relative">
                <select
                  value={form.condition}
                  onChange={(e) => updateField('condition', e.target.value)}
                  className={selectClass}
                >
                  {CONDITIONS.map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
                <svg className="absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground pointer-events-none" viewBox="0 0 16 16" fill="none"><path d="M4 6l4 4 4-4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            {/* Brand */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Brand</label>
              <input
                type="text"
                value={form.brand}
                onChange={(e) => updateField('brand', e.target.value)}
                placeholder="e.g. Fluke"
                className={inputClass}
              />
            </div>

            {/* Model with generate button */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Model</label>
              <div className="flex gap-1.5">
                <input
                  type="text"
                  value={form.model}
                  onChange={(e) => updateField('model', e.target.value)}
                  placeholder="e.g. 87V"
                  className={inputClass}
                />
                <button
                  type="button"
                  onClick={handleGenerateModel}
                  title="Generate model number"
                  className="shrink-0 w-9 h-9 flex items-center justify-center rounded-lg border border-input hover:bg-accent transition-colors"
                >
                  <RefreshCw className="w-3.5 h-3.5 text-muted-foreground" />
                </button>
              </div>
            </div>
          </div>

          {/* Serial Number with generate button */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Serial Number</label>
            <div className="flex gap-1.5">
              <input
                type="text"
                value={form.serial_number}
                onChange={(e) => updateField('serial_number', e.target.value)}
                placeholder="Unique serial number"
                className={inputClass}
              />
              <button
                type="button"
                onClick={handleGenerateSerial}
                title="Generate serial number"
                className="shrink-0 w-9 h-9 flex items-center justify-center rounded-lg border border-input hover:bg-accent transition-colors"
              >
                <RefreshCw className="w-3.5 h-3.5 text-muted-foreground" />
              </button>
            </div>
            <p className="text-xs text-muted-foreground mt-1">Use the generate button if the tool has no serial number</p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            {/* Purchase Price */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Purchase Price</label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={form.purchase_price}
                onChange={(e) => updateField('purchase_price', e.target.value)}
                placeholder="0.00"
                className={inputClass}
              />
            </div>

            {/* Current Value */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Current Value</label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={form.current_value}
                onChange={(e) => updateField('current_value', e.target.value)}
                placeholder="0.00"
                className={inputClass}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            {/* Purchase Date */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Purchase Date</label>
              <input
                type="date"
                value={form.purchase_date}
                onChange={(e) => updateField('purchase_date', e.target.value)}
                className={inputClass}
              />
            </div>

            {/* Location */}
            <div>
              <label className="block text-sm font-medium mb-1.5">Location</label>
              <input
                type="text"
                value={form.location}
                onChange={(e) => updateField('location', e.target.value)}
                placeholder="e.g. Warehouse A"
                className={inputClass}
              />
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium mb-1.5">Notes</label>
            <textarea
              value={form.notes}
              onChange={(e) => updateField('notes', e.target.value)}
              placeholder="Additional notes..."
              rows={3}
              className="w-full px-3 py-2 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
            />
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
            disabled={saving || !form.name.trim()}
            className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
          >
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            {saving ? 'Adding...' : 'Add Tool'}
          </button>
        </div>
      </div>
    </div>
  )
}
