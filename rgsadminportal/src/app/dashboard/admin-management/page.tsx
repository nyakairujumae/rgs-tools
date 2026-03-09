'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/use-auth'
import { fetchAdmins, fetchAdminPositions, deleteAdmin } from '@/lib/supabase/actions'
import { AddAdminDialog } from '@/components/admin/add-admin-dialog'
import { Loader2, Plus, Pencil, Trash2, ShieldCheck } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { User, AdminPosition } from '@/lib/types/database'

export default function AdminManagementPage() {
  const { hasPermission, isSuperAdmin, loading: authLoading } = useAuth()
  const [admins, setAdmins] = useState<User[]>([])
  const [positions, setPositions] = useState<AdminPosition[]>([])
  const [loading, setLoading] = useState(true)
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [editAdmin, setEditAdmin] = useState<User | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<User | null>(null)
  const [deleting, setDeleting] = useState(false)

  const canManage = hasPermission('can_manage_admins')

  useEffect(() => {
    const supabase = createClient()
    const load = async () => {
      const [adminsData, positionsData] = await Promise.all([
        fetchAdmins(),
        fetchAdminPositions(),
      ])
      setAdmins(adminsData)
      setPositions(positionsData)
      setLoading(false)
    }
    load()

    // Real-time: refresh when users table changes (admin added/edited from mobile)
    const channel = supabase
      .channel('admins-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'users' }, () => load())
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  const getPositionName = (positionId?: string) => {
    if (!positionId) return 'No Position'
    const pos = positions.find((p) => p.id === positionId)
    return pos?.name || 'Unknown'
  }

  const handleDelete = async () => {
    if (!deleteConfirm) return
    setDeleting(true)
    const success = await deleteAdmin(deleteConfirm.id)
    if (success) {
      setAdmins((prev) => prev.filter((a) => a.id !== deleteConfirm.id))
    }
    setDeleting(false)
    setDeleteConfirm(null)
  }

  const handleAdminSaved = (admin: User) => {
    setAdmins((prev) => {
      const exists = prev.find((a) => a.id === admin.id)
      if (exists) {
        return prev.map((a) => (a.id === admin.id ? { ...a, ...admin } : a))
      }
      return [admin, ...prev]
    })
    setShowAddDialog(false)
    setEditAdmin(null)
  }

  if (authLoading || loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
      </div>
    )
  }

  if (!canManage) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3 text-muted-foreground">
        <ShieldCheck className="w-12 h-12" />
        <p className="text-lg font-medium">Access Restricted</p>
        <p className="text-sm">You don&apos;t have permission to manage administrators.</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Admin Management</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Manage administrator accounts and positions
          </p>
        </div>
        <button
          onClick={() => setShowAddDialog(true)}
          className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Admin
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-card border border-border rounded-xl p-4">
          <p className="text-sm text-muted-foreground">Total Admins</p>
          <p className="text-2xl font-semibold mt-1">{admins.length}</p>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <p className="text-sm text-muted-foreground">Active</p>
          <p className="text-2xl font-semibold mt-1 text-emerald-600">
            {admins.filter((a) => (a as unknown as Record<string, string>).status === 'Active' || !(a as unknown as Record<string, string>).status).length}
          </p>
        </div>
        <div className="bg-card border border-border rounded-xl p-4">
          <p className="text-sm text-muted-foreground">Positions</p>
          <p className="text-2xl font-semibold mt-1">{positions.length}</p>
        </div>
      </div>

      {/* Table */}
      <div className="bg-card border border-border rounded-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Name</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Email</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Position</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Status</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Joined</th>
                <th className="w-20 px-4 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {admins.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center py-12 text-muted-foreground">
                    No administrators found
                  </td>
                </tr>
              ) : (
                admins.map((admin) => {
                  const status = (admin as unknown as Record<string, string>).status || 'Active'
                  const posName = getPositionName(admin.position_id)
                  return (
                    <tr key={admin.id} className="border-b border-border last:border-0 hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-primary/15 text-primary flex items-center justify-center text-sm font-semibold shrink-0">
                            {admin.full_name?.charAt(0)?.toUpperCase() || 'A'}
                          </div>
                          <span className="font-medium">{admin.full_name}</span>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{admin.email}</td>
                      <td className="px-4 py-3">
                        <span className={cn(
                          'inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium',
                          posName.toLowerCase().includes('super') ? 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-400' : 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
                        )}>
                          {posName}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className={cn(
                          'inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium',
                          status === 'Active' ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400' : 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400'
                        )}>
                          {status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {admin.created_at ? new Date(admin.created_at).toLocaleDateString() : '-'}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => setEditAdmin(admin)}
                            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground hover:text-foreground"
                            title="Edit"
                          >
                            <Pencil className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => setDeleteConfirm(admin)}
                            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-destructive/10 transition-colors text-muted-foreground hover:text-destructive"
                            title="Remove"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Delete confirmation dialog */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Remove Admin</h3>
            <p className="text-sm text-muted-foreground mt-2">
              Are you sure you want to remove <strong>{deleteConfirm.full_name}</strong>?
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
                {deleting ? 'Removing...' : 'Remove'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add/Edit dialog */}
      {(showAddDialog || editAdmin) && (
        <AddAdminDialog
          open={true}
          admin={editAdmin}
          positions={positions}
          onClose={() => {
            setShowAddDialog(false)
            setEditAdmin(null)
          }}
          onSuccess={handleAdminSaved}
        />
      )}
    </div>
  )
}
