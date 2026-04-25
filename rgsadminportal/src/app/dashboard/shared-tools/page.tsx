'use client'

import { useEffect, useState, useMemo } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { cn, formatAED } from '@/lib/utils'
import { StatusBadge } from '@/components/shared/status-badge'
import { FilterSelect } from '@/components/shared/filter-select'
import Image from 'next/image'
import {
  Search,
  X,
  Loader2,
  Camera,
  UserPlus,
  ArrowLeftRight,
  KeyRound,
  MoreHorizontal,
  Eye,
  Share2,
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
  List,
  LayoutGrid,
  Pencil,
  Trash2,
  Package,
} from 'lucide-react'
import { deleteTool as deleteToolAction } from '@/lib/supabase/actions'
import { AssignToolDialog } from '@/components/tools/assign-tool-dialog'
import { ReassignToolDialog } from '@/components/tools/reassign-tool-dialog'
import { ReturnToolDialog } from '@/components/tools/return-tool-dialog'
import { EditToolDialog } from '@/components/tools/edit-tool-dialog'
import type { Tool, Technician } from '@/lib/types/database'

type SortField = 'name' | 'category' | 'brand' | 'serial_number' | 'status' | 'condition' | 'current_value'
type SortDir = 'asc' | 'desc'

export default function SharedToolsPage() {
  const [tools, setTools] = useState<Tool[]>([])
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [categoryFilter, setCategoryFilter] = useState<string>('all')
  const [sortField, setSortField] = useState<SortField>('name')
  const [sortDir, setSortDir] = useState<SortDir>('asc')
  const [actionMenuId, setActionMenuId] = useState<string | null>(null)
  const [viewMode, setViewMode] = useState<'table' | 'grid'>('table')
  const [assignTool, setAssignTool] = useState<Tool | null>(null)
  const [reassignTool, setReassignTool] = useState<Tool | null>(null)
  const [returnTool, setReturnTool] = useState<Tool | null>(null)
  const [editTool, setEditTool] = useState<Tool | null>(null)
  const [deleteConfirm, setDeleteConfirm] = useState<Tool | null>(null)
  const [deleting, setDeleting] = useState(false)

  useEffect(() => {
    const supabase = createClient()

    const fetchData = async () => {
      const [toolsRes, techRes] = await Promise.all([
        supabase.from('tools').select('*').eq('tool_type', 'shared').order('name'),
        supabase.from('technicians').select('*'),
      ])
      if (toolsRes.data) setTools(toolsRes.data)
      if (techRes.data) setTechnicians(techRes.data)
      setLoading(false)
    }
    fetchData()

    const channel = supabase
      .channel('shared-tools-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tools' }, () => fetchData())
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [])

  const getTechName = (userId?: string) => {
    if (!userId) return '-'
    const tech = technicians.find((t) => t.user_id === userId || t.id === userId)
    return tech?.name || '-'
  }

  const categories = useMemo(() => {
    const fromDb = [...new Set(tools.map((t) => t.category).filter(Boolean))].sort()
    return fromDb
  }, [tools])

  const filtered = useMemo(() => {
    let result = tools

    if (search) {
      const q = search.toLowerCase()
      result = result.filter(
        (t) =>
          t.name.toLowerCase().includes(q) ||
          t.category?.toLowerCase().includes(q) ||
          t.brand?.toLowerCase().includes(q) ||
          t.serial_number?.toLowerCase().includes(q) ||
          t.model?.toLowerCase().includes(q)
      )
    }

    if (statusFilter !== 'all') result = result.filter((t) => t.status === statusFilter)
    if (categoryFilter !== 'all') result = result.filter((t) => t.category === categoryFilter)

    result = [...result].sort((a, b) => {
      let aVal = a[sortField] ?? ''
      let bVal = b[sortField] ?? ''

      if (sortField === 'current_value') {
        aVal = a.current_value ?? a.purchase_price ?? 0
        bVal = b.current_value ?? b.purchase_price ?? 0
        return sortDir === 'asc' ? (aVal as number) - (bVal as number) : (bVal as number) - (aVal as number)
      }

      const strA = String(aVal).toLowerCase()
      const strB = String(bVal).toLowerCase()
      return sortDir === 'asc' ? strA.localeCompare(strB) : strB.localeCompare(strA)
    })

    return result
  }, [tools, search, statusFilter, categoryFilter, sortField, sortDir])

  const toggleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDir('asc')
    }
  }

  const handleToolUpdated = (updated: Tool) => {
    if (updated.tool_type !== 'shared') {
      setTools((prev) => prev.filter((t) => t.id !== updated.id))
    } else {
      setTools((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
    }
  }

  const toggleToolType = async (tool: Tool) => {
    const supabase = createClient()
    const newType = tool.tool_type === 'shared' ? 'inventory' : 'shared'
    const { error } = await supabase
      .from('tools')
      .update({ tool_type: newType, updated_at: new Date().toISOString() })
      .eq('id', tool.id)
    if (!error) {
      await supabase.from('tool_history').insert({
        tool_id: tool.id,
        tool_name: tool.name,
        action: newType === 'shared' ? 'Marked as Shared' : 'Marked as Inventory',
        description: `${tool.name} converted to ${newType} tool`,
        old_value: tool.tool_type,
        new_value: newType,
        performed_by: 'Admin',
        performed_by_role: 'admin',
        timestamp: new Date().toISOString(),
      })
      setTools((prev) => prev.filter((t) => t.id !== tool.id))
    }
    setActionMenuId(null)
  }

  const handleDelete = async () => {
    if (!deleteConfirm) return
    setDeleting(true)
    const ok = await deleteToolAction(deleteConfirm.id)
    if (ok) setTools((prev) => prev.filter((t) => t.id !== deleteConfirm.id))
    setDeleting(false)
    setDeleteConfirm(null)
  }

  const SortIcon = ({ field }: { field: SortField }) => {
    if (sortField !== field) return <ChevronsUpDown className="w-3.5 h-3.5 text-muted-foreground/50" />
    return sortDir === 'asc' ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />
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
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-semibold tracking-tight">Shared Tools</h1>
          <p className="text-sm text-muted-foreground">{tools.length} shared tools</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => { setSearch(e.target.value) }}
            placeholder="Search shared tools..."
            className="w-full h-9 pl-9 pr-8 rounded-lg border border-input bg-background text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        <FilterSelect
          value={statusFilter}
          onChange={setStatusFilter}
          options={[
            { value: 'all', label: 'All Status' },
            { value: 'Available', label: 'Available' },
            { value: 'In Use', label: 'In Use' },
            { value: 'Assigned', label: 'Assigned' },
            { value: 'Maintenance', label: 'Maintenance' },
            { value: 'Retired', label: 'Retired' },
          ]}
        />

        <FilterSelect
          value={categoryFilter}
          onChange={setCategoryFilter}
          options={[
            { value: 'all', label: 'All Categories' },
            ...categories.map((c) => ({ value: c, label: c })),
          ]}
        />

        {(search || statusFilter !== 'all' || categoryFilter !== 'all') && (
          <button
            onClick={() => { setSearch(''); setStatusFilter('all'); setCategoryFilter('all') }}
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Clear
          </button>
        )}

        <div className="ml-auto flex items-center gap-1 bg-muted rounded-lg p-0.5">
          <button
            onClick={() => setViewMode('table')}
            className={cn(
              'flex items-center justify-center w-8 h-8 rounded-md transition-colors',
              viewMode === 'table' ? 'bg-background shadow-sm text-foreground' : 'text-muted-foreground hover:text-foreground'
            )}
            title="Table view"
          >
            <List className="w-4 h-4" />
          </button>
          <button
            onClick={() => setViewMode('grid')}
            className={cn(
              'flex items-center justify-center w-8 h-8 rounded-md transition-colors',
              viewMode === 'grid' ? 'bg-background shadow-sm text-foreground' : 'text-muted-foreground hover:text-foreground'
            )}
            title="Grid view"
          >
            <LayoutGrid className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {filtered.length === 0 ? (
            <div className="col-span-full py-12 text-center text-muted-foreground">
              {search || statusFilter !== 'all' || categoryFilter !== 'all'
                ? 'No tools match your filters'
                : 'No shared tools'}
            </div>
          ) : (
            filtered.map((tool) => (
              <Link
                key={tool.id}
                href={`/dashboard/tools/${tool.id}`}
                className="bg-card border border-border rounded-xl overflow-hidden hover:border-primary/30 hover:shadow-md transition-all group"
              >
                <div className="aspect-square bg-muted/30 flex items-center justify-center overflow-hidden">
                  {tool.image_path ? (
                    <Image
                      src={tool.image_path}
                      alt={tool.name}
                      width={200}
                      height={200}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                    />
                  ) : (
                    <Camera className="w-8 h-8 text-muted-foreground/20" />
                  )}
                </div>
                <div className="p-3 space-y-1.5">
                  <h3 className="font-medium text-sm truncate">{tool.name}</h3>
                  <p className="text-xs text-muted-foreground truncate">{tool.category}</p>
                  <StatusBadge status={tool.status} />
                </div>
              </Link>
            ))
          )}
        </div>
      )}

      {/* Table View */}
      {viewMode === 'table' && (
        <div className="bg-card border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border bg-muted/50">
                  {[
                    { field: 'name' as SortField, label: 'Name' },
                    { field: 'category' as SortField, label: 'Category' },
                    { field: 'brand' as SortField, label: 'Brand' },
                    { field: 'serial_number' as SortField, label: 'Serial #' },
                    { field: 'status' as SortField, label: 'Status' },
                    { field: 'condition' as SortField, label: 'Condition' },
                    { field: 'current_value' as SortField, label: 'Value' },
                  ].map(({ field, label }) => (
                    <th key={field} className="px-4 py-3 text-left">
                      <button
                        onClick={() => toggleSort(field)}
                        className="flex items-center gap-1 font-medium text-muted-foreground hover:text-foreground"
                      >
                        {label}
                        <SortIcon field={field} />
                      </button>
                    </th>
                  ))}
                  <th className="px-4 py-3 text-left font-medium text-muted-foreground">Assigned To</th>
                  <th className="w-10 px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={9} className="py-12 text-center text-muted-foreground">
                      {search || statusFilter !== 'all' || categoryFilter !== 'all'
                        ? 'No tools match your filters'
                        : 'No shared tools'}
                    </td>
                  </tr>
                ) : (
                  filtered.map((tool) => (
                    <tr key={tool.id} className="hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-lg overflow-hidden flex-shrink-0">
                            {tool.image_path ? (
                              <Image
                                src={tool.image_path}
                                alt={tool.name}
                                width={36}
                                height={36}
                                className="w-full h-full object-cover"
                              />
                            ) : (
                              <div className="w-full h-full bg-muted/30 flex items-center justify-center">
                                <Camera className="w-4 h-4 text-muted-foreground/30" />
                              </div>
                            )}
                          </div>
                          <div>
                            <Link href={`/dashboard/tools/${tool.id}`} className="font-medium hover:text-primary transition-colors">
                              {tool.name}
                            </Link>
                            <div className="flex items-center gap-1 mt-0.5">
                              <Share2 className="w-2.5 h-2.5 text-violet-500" />
                              <span className="text-[10px] text-violet-600 font-medium">Shared</span>
                            </div>
                            {tool.model && (
                              <p className="text-xs text-muted-foreground">{tool.model}</p>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{tool.category}</td>
                      <td className="px-4 py-3 text-muted-foreground">{tool.brand || '-'}</td>
                      <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{tool.serial_number || '-'}</td>
                      <td className="px-4 py-3"><StatusBadge status={tool.status} /></td>
                      <td className="px-4 py-3 text-muted-foreground">{tool.condition}</td>
                      <td className="px-4 py-3 text-muted-foreground">{formatAED(tool.current_value || tool.purchase_price)}</td>
                      <td className="px-4 py-3 text-muted-foreground">{getTechName(tool.assigned_to)}</td>
                      <td className="px-4 py-3 relative">
                        <button
                          onClick={() => setActionMenuId(actionMenuId === tool.id ? null : tool.id)}
                          className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-accent transition-colors"
                        >
                          <MoreHorizontal className="w-4 h-4 text-muted-foreground" />
                        </button>
                        {actionMenuId === tool.id && (
                          <div className="absolute right-4 top-full z-50 w-44 bg-popover border border-border rounded-lg shadow-lg py-1">
                            <Link
                              href={`/dashboard/tools/${tool.id}`}
                              className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full"
                            >
                              <Eye className="w-3.5 h-3.5" /> View
                            </Link>
                            <button
                              onClick={() => { setEditTool(tool); setActionMenuId(null) }}
                              className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                            >
                              <Pencil className="w-3.5 h-3.5" /> Edit
                            </button>
                            <button
                              onClick={() => { setAssignTool(tool); setActionMenuId(null) }}
                              className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                            >
                              <UserPlus className="w-3.5 h-3.5" /> Assign
                            </button>
                            <button
                              onClick={() => toggleToolType(tool)}
                              className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                            >
                              <Package className="w-3.5 h-3.5" /> Make Inventory
                            </button>
                            {tool.assigned_to && (
                              <>
                                <button
                                  onClick={() => { setReassignTool(tool); setActionMenuId(null) }}
                                  className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                                >
                                  <ArrowLeftRight className="w-3.5 h-3.5" /> Reassign
                                </button>
                                <button
                                  onClick={() => { setReturnTool(tool); setActionMenuId(null) }}
                                  className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                                >
                                  <KeyRound className="w-3.5 h-3.5" /> Return
                                </button>
                              </>
                            )}
                            <div className="border-t border-border my-1" />
                            <button
                              onClick={() => { setDeleteConfirm(tool); setActionMenuId(null) }}
                              className="flex items-center gap-2 px-3 py-2 text-sm text-destructive hover:bg-destructive/10 transition-colors w-full text-left"
                            >
                              <Trash2 className="w-3.5 h-3.5" /> Delete
                            </button>
                          </div>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Close action menus when clicking outside */}
      {actionMenuId && (
        <div className="fixed inset-0 z-40" onClick={() => setActionMenuId(null)} />
      )}

      {/* Edit dialog */}
      {editTool && (
        <EditToolDialog
          tool={editTool}
          open={!!editTool}
          onClose={() => setEditTool(null)}
          onSuccess={(updated) => {
            handleToolUpdated(updated)
            setEditTool(null)
          }}
        />
      )}

      {/* Delete confirmation */}
      {deleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Delete Tool</h3>
            <p className="text-sm text-muted-foreground mt-2">
              Are you sure you want to delete <strong>{deleteConfirm.name}</strong>? This action cannot be undone.
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

      {/* Dialogs */}
      {assignTool && (
        <AssignToolDialog
          tool={assignTool}
          open={!!assignTool}
          onClose={() => setAssignTool(null)}
          onSuccess={(updated) => { handleToolUpdated(updated); setAssignTool(null) }}
        />
      )}
      {reassignTool && (
        <ReassignToolDialog
          tool={reassignTool}
          open={!!reassignTool}
          onClose={() => setReassignTool(null)}
          onSuccess={(updated) => { handleToolUpdated(updated); setReassignTool(null) }}
        />
      )}
      {returnTool && (
        <ReturnToolDialog
          tool={returnTool}
          open={!!returnTool}
          onClose={() => setReturnTool(null)}
          onSuccess={(updated) => { handleToolUpdated(updated); setReturnTool(null) }}
        />
      )}
    </div>
  )
}
