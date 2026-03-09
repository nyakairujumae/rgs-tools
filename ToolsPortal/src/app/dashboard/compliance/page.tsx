'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { deleteCertification } from '@/lib/supabase/actions'
import { StatusBadge } from '@/components/shared/status-badge'
import { AddCertificationDialog } from '@/components/compliance/add-certification-dialog'
import { EditCertificationDialog } from '@/components/compliance/edit-certification-dialog'
import { formatDate, cn } from '@/lib/utils'
import {
  Loader2,
  AlertTriangle,
  CheckCircle,
  XCircle,
  ShieldOff,
  Plus,
  Search,
  X,
  Pencil,
  Trash2,
} from 'lucide-react'
import type { Certification, Tool } from '@/lib/types/database'

export default function CompliancePage() {
  const [certs, setCerts] = useState<Certification[]>([])
  const [tools, setTools] = useState<Tool[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState('all')
  const [search, setSearch] = useState('')
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [editCert, setEditCert] = useState<Certification | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<Certification | null>(null)
  const [deleting, setDeleting] = useState(false)

  const fetchData = async () => {
    const supabase = createClient()
    const [{ data: certData }, { data: toolData }] = await Promise.all([
      supabase.from('certifications').select('*').order('expiry_date', { ascending: true }),
      supabase.from('tools').select('*').order('name'),
    ])
    setCerts(certData || [])
    setTools(toolData || [])
    setLoading(false)
  }

  useEffect(() => {
    fetchData()

    const supabase = createClient()
    const channel = supabase
      .channel('compliance-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'certifications' }, () => fetchData())
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const counts = useMemo(() => ({
    all: certs.length,
    Valid: certs.filter((c) => c.status === 'Valid').length,
    'Expiring Soon': certs.filter((c) => c.status === 'Expiring Soon').length,
    Expired: certs.filter((c) => c.status === 'Expired').length,
    Revoked: certs.filter((c) => c.status === 'Revoked').length,
  }), [certs])

  const filtered = useMemo(() => {
    let result = tab === 'all' ? certs : certs.filter((c) => c.status === tab)
    if (search) {
      const q = search.toLowerCase()
      result = result.filter((c) =>
        c.tool_name.toLowerCase().includes(q) ||
        c.certification_number?.toLowerCase().includes(q) ||
        c.issuing_authority?.toLowerCase().includes(q) ||
        c.certification_type?.toLowerCase().includes(q)
      )
    }
    return result
  }, [certs, tab, search])

  const handleDelete = async () => {
    if (!deleteConfirm) return
    setDeleting(true)
    const success = await deleteCertification(deleteConfirm.id)
    if (success) {
      setCerts((prev) => prev.filter((c) => c.id !== deleteConfirm.id))
    }
    setDeleting(false)
    setDeleteConfirm(null)
  }

  if (loading) {
    return <div className="flex items-center justify-center h-full"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Compliance</h1>
          <p className="text-sm text-muted-foreground">{certs.length} certifications tracked</p>
        </div>
        <button
          onClick={() => setShowAddDialog(true)}
          className="flex items-center gap-2 px-4 h-9 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add Certification
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
            <CheckCircle className="w-5 h-5 text-emerald-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Valid}</p>
            <p className="text-xs text-muted-foreground">Valid</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts['Expiring Soon']}</p>
            <p className="text-xs text-muted-foreground">Expiring Soon</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-red-500/10 flex items-center justify-center">
            <XCircle className="w-5 h-5 text-red-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Expired}</p>
            <p className="text-xs text-muted-foreground">Expired</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-neutral-500/10 flex items-center justify-center">
            <ShieldOff className="w-5 h-5 text-neutral-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Revoked}</p>
            <p className="text-xs text-muted-foreground">Revoked</p>
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search certifications..."
            className="w-full h-9 pl-9 pr-8 rounded-lg border border-input bg-transparent text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-border">
        {(['all', 'Valid', 'Expiring Soon', 'Expired', 'Revoked'] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={cn(
              'px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
              tab === t ? 'border-primary text-foreground' : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            {t === 'all' ? 'All' : t}
            <span className="ml-1.5 text-xs bg-muted px-1.5 py-0.5 rounded-full">{counts[t as keyof typeof counts] ?? 0}</span>
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Tool</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Number</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Authority</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Issue Date</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Expiry Date</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr><td colSpan={8} className="py-12 text-center text-muted-foreground">
                {search ? 'No certifications match your search' : 'No certifications'}
              </td></tr>
            ) : (
              filtered.map((c) => (
                <tr key={c.id} className="hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-medium">{c.tool_name}</td>
                  <td className="px-4 py-3 text-muted-foreground">{c.certification_type}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{c.certification_number}</td>
                  <td className="px-4 py-3 text-muted-foreground">{c.issuing_authority}</td>
                  <td className="px-4 py-3 text-muted-foreground">{formatDate(c.issue_date)}</td>
                  <td className="px-4 py-3 text-muted-foreground">{formatDate(c.expiry_date)}</td>
                  <td className="px-4 py-3"><StatusBadge status={c.status} /></td>
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => setEditCert(c)}
                        className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground hover:text-foreground"
                        title="Edit"
                      >
                        <Pencil className="w-3.5 h-3.5" />
                      </button>
                      <button
                        onClick={() => setDeleteConfirm(c)}
                        className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-destructive/10 transition-colors text-muted-foreground hover:text-destructive"
                        title="Delete"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Add Certification Dialog */}
      <AddCertificationDialog
        open={showAddDialog}
        tools={tools}
        onClose={() => setShowAddDialog(false)}
        onSuccess={(cert) => {
          setCerts((prev) => [cert, ...prev])
          setShowAddDialog(false)
        }}
      />

      {/* Edit Certification Dialog */}
      {editCert && (
        <EditCertificationDialog
          certification={editCert}
          open={!!editCert}
          onClose={() => setEditCert(null)}
          onSuccess={(updated) => {
            setCerts((prev) => prev.map((c) => c.id === updated.id ? updated : c))
            setEditCert(null)
          }}
        />
      )}

      {/* Delete Confirmation */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Delete Certification</h3>
            <p className="text-sm text-muted-foreground mt-2">
              Are you sure you want to delete certificate
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
