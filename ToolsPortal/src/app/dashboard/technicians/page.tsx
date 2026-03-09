'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { deleteTechnician, updateTechnician } from '@/lib/supabase/actions'
import { useOrgContext } from '@/contexts/organization-context'
import { StatusBadge } from '@/components/shared/status-badge'
import {
  Search,
  Plus,
  Loader2,
  X,
  Mail,
  Phone,
  Pencil,
  Trash2,
} from 'lucide-react'
import { AddTechnicianDialog } from '@/components/technicians/add-technician-dialog'
import type { Technician } from '@/lib/types/database'

export default function TechniciansPage() {
  const { workerLabel, workerLabelPlural, departments } = useOrgContext()
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [tools, setTools] = useState<{ id: string; assigned_to: string | null }[]>([])
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [editTech, setEditTech] = useState<Technician | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<Technician | null>(null)
  const [deleting, setDeleting] = useState(false)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  useEffect(() => {
    const fetchData = async () => {
      const supabase = createClient()
      const [{ data: techData }, { data: toolData }] = await Promise.all([
        supabase.from('technicians').select('*').order('name'),
        supabase.from('tools').select('id, assigned_to'),
      ])
      setTechnicians(techData || [])
      setTools(toolData || [])
      setLoading(false)
    }
    fetchData()
  }, [])

  const toolCountMap = useMemo(() => {
    const map: Record<string, number> = {}
    tools.forEach((t) => {
      if (t.assigned_to) {
        map[t.assigned_to] = (map[t.assigned_to] || 0) + 1
      }
    })
    return map
  }, [tools])

  const filtered = useMemo(() => {
    let result = technicians
    if (search) {
      const q = search.toLowerCase()
      result = result.filter(
        (t) =>
          t.name.toLowerCase().includes(q) ||
          t.email?.toLowerCase().includes(q) ||
          t.employee_id?.toLowerCase().includes(q) ||
          t.department?.toLowerCase().includes(q)
      )
    }
    if (statusFilter !== 'all') {
      result = result.filter((t) => t.status === statusFilter)
    }
    return result
  }, [technicians, search, statusFilter])

  const handleDelete = async () => {
    if (!deleteConfirm) return
    setDeleting(true)
    const success = await deleteTechnician(deleteConfirm.id)
    if (success) {
      setTechnicians((prev) => prev.filter((t) => t.id !== deleteConfirm.id))
    }
    setDeleting(false)
    setDeleteConfirm(null)
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">{workerLabelPlural}</h1>
          <p className="text-sm text-muted-foreground">{technicians.length} {technicians.length === 1 ? workerLabel.toLowerCase() : workerLabelPlural.toLowerCase()}</p>
        </div>
        <button
          onClick={() => setShowAddDialog(true)}
          className="flex items-center gap-2 px-4 h-9 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add {workerLabel}
        </button>
      </div>

      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={`Search ${workerLabelPlural.toLowerCase()}...`}
            className="w-full h-9 pl-9 pr-8 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
        <div className="relative">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer"
          >
            <option value="all">All Status</option>
            <option value="Active">Active</option>
            <option value="Inactive">Inactive</option>
          </select>
          <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
        </div>
      </div>

      <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {filtered.map((tech) => (
          <div key={tech.id} className="bg-card border border-border rounded-xl p-4 hover:border-primary/30 transition-colors">
            <div className="flex items-start gap-3">
              <div className="w-10 h-10 rounded-full bg-primary/10 text-primary flex items-center justify-center font-semibold shrink-0">
                {tech.name.charAt(0).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-medium truncate">{tech.name}</p>
                <p className="text-xs text-muted-foreground">{tech.department || 'No department'}</p>
              </div>
              <StatusBadge status={tech.status} />
            </div>
            <div className="mt-3 space-y-1.5 text-sm text-muted-foreground">
              {tech.email && (
                <div className="flex items-center gap-2">
                  <Mail className="w-3.5 h-3.5" />
                  <span className="truncate text-xs">{tech.email}</span>
                </div>
              )}
              {tech.phone && (
                <div className="flex items-center gap-2">
                  <Phone className="w-3.5 h-3.5" />
                  <span className="text-xs">{tech.phone}</span>
                </div>
              )}
            </div>
            <div className="mt-3 pt-3 border-t border-border flex items-center justify-between text-xs">
              <span className="text-muted-foreground">
                {toolCountMap[tech.user_id || ''] || 0} tools assigned
              </span>
              <div className="flex items-center gap-1">
                <button
                  onClick={() => setEditTech(tech)}
                  className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground hover:text-foreground"
                  title="Edit"
                >
                  <Pencil className="w-3 h-3" />
                </button>
                <button
                  onClick={() => setDeleteConfirm(tech)}
                  className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-destructive/10 transition-colors text-muted-foreground hover:text-destructive"
                  title="Delete"
                >
                  <Trash2 className="w-3 h-3" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filtered.length === 0 && (
        <div className="py-12 text-center text-muted-foreground text-sm">
          {search ? `No ${workerLabelPlural.toLowerCase()} match your search` : `No ${workerLabelPlural.toLowerCase()} yet`}
        </div>
      )}

      {/* Add dialog */}
      <AddTechnicianDialog
        open={showAddDialog}
        onClose={() => setShowAddDialog(false)}
        onSuccess={(tech) => {
          setTechnicians((prev) => [tech, ...prev])
          setShowAddDialog(false)
        }}
      />

      {/* Edit dialog */}
      {editTech && (
        <EditTechnicianDialog
          tech={editTech}
          workerLabel={workerLabel}
          departments={departments}
          onClose={() => setEditTech(null)}
          onSuccess={(updated) => {
            setTechnicians((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
            setEditTech(null)
          }}
        />
      )}

      {/* Delete confirmation */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Delete {workerLabel}</h3>
            <p className="text-sm text-muted-foreground mt-2">
              Are you sure you want to delete <strong>{deleteConfirm.name}</strong>?
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

// ── Inline Edit Technician Dialog ──

function EditTechnicianDialog({
  tech,
  workerLabel,
  departments,
  onClose,
  onSuccess,
}: {
  tech: Technician
  workerLabel: string
  departments: string[]
  onClose: () => void
  onSuccess: (tech: Technician) => void
}) {
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState({
    name: tech.name,
    employee_id: tech.employee_id || '',
    phone: tech.phone || '',
    email: tech.email || '',
    department: tech.department || '',
    status: tech.status || 'Active',
  })

  const updateField = (field: string, value: string) => {
    setForm((prev) => ({ ...prev, [field]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!form.name.trim()) return
    setSaving(true)

    const result = await updateTechnician(tech.id, {
      name: form.name.trim(),
      employee_id: form.employee_id.trim() || undefined,
      phone: form.phone.trim() || undefined,
      email: form.email.trim() || undefined,
      department: form.department.trim() || undefined,
      status: form.status as 'Active' | 'Inactive',
    })

    setSaving(false)
    if (result) onSuccess(result)
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[480px] overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">Edit {workerLabel}</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1.5">Full Name *</label>
            <input type="text" value={form.name} onChange={(e) => updateField('name', e.target.value)} required className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm focus:outline-none focus:ring-2 focus:ring-ring" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Employee ID</label>
              <input type="text" value={form.employee_id} onChange={(e) => updateField('employee_id', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Department</label>
              {departments.length > 0 ? (
                <div className="relative">
                  <select value={form.department} onChange={(e) => updateField('department', e.target.value)} className="w-full h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer">
                    <option value="">Select department...</option>
                    {departments.map((d) => <option key={d} value={d}>{d}</option>)}
                  </select>
                  <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
                </div>
              ) : (
                <input type="text" value={form.department} onChange={(e) => updateField('department', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
              )}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1.5">Email</label>
              <input type="email" value={form.email} onChange={(e) => updateField('email', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1.5">Phone</label>
              <input type="tel" value={form.phone} onChange={(e) => updateField('phone', e.target.value)} className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-1.5">Status</label>
            <div className="relative">
              <select value={form.status} onChange={(e) => updateField('status', e.target.value)} className="w-full h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer">
                <option value="Active">Active</option>
                <option value="Inactive">Inactive</option>
              </select>
              <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
            </div>
          </div>
        </form>

        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button type="button" onClick={onClose} className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors">Cancel</button>
          <button onClick={handleSubmit} disabled={saving || !form.name.trim()} className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2">
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  )
}
