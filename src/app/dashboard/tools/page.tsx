'use client'

import { useEffect, useState, useMemo } from 'react'
import { useAuth } from '@/hooks/use-auth'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { cn, formatAED, formatDate } from '@/lib/utils'
import { StatusBadge } from '@/components/shared/status-badge'
import Image from 'next/image'
import {
  Search,
  Plus,
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
  MoreHorizontal,
  Download,
  Trash2,
  Pencil,
  Eye,
  UserPlus,
  Loader2,
  X,
  LayoutGrid,
  List,
  Camera,
  Share2,
  ArrowLeftRight,
  KeyRound,
  Package,
} from 'lucide-react'
import { deleteTool as deleteToolAction } from '@/lib/supabase/actions'
import { AddToolDialog } from '@/components/tools/add-tool-dialog'
import { EditToolDialog } from '@/components/tools/edit-tool-dialog'
import { AssignToolDialog } from '@/components/tools/assign-tool-dialog'
import { ReassignToolDialog } from '@/components/tools/reassign-tool-dialog'
import { ReturnToolDialog } from '@/components/tools/return-tool-dialog'
import type { Tool, Technician } from '@/lib/types/database'

type SortField = 'name' | 'category' | 'brand' | 'serial_number' | 'status' | 'condition' | 'current_value'
type SortDir = 'asc' | 'desc'

export default function ToolsPage() {
  const { user } = useAuth()
  const [tools, setTools] = useState<Tool[]>([])
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [loading, setLoading] = useState(true)
  const [viewMyTools, setViewMyTools] = useState(false)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [categoryFilter, setCategoryFilter] = useState<string>('all')
  const [sortField, setSortField] = useState<SortField>('name')
  const [sortDir, setSortDir] = useState<SortDir>('asc')
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [actionMenuId, setActionMenuId] = useState<string | null>(null)
  const [viewMode, setViewMode] = useState<'table' | 'grid'>('table')
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [editTool, setEditTool] = useState<Tool | null>(null)
  const [assignToolTarget, setAssignToolTarget] = useState<Tool | null>(null)
  const [reassignToolTarget, setReassignToolTarget] = useState<Tool | null>(null)
  const [returnToolTarget, setReturnToolTarget] = useState<Tool | null>(null)
  const [showBulkDelete, setShowBulkDelete] = useState(false)
  const [bulkDeleting, setBulkDeleting] = useState(false)

  useEffect(() => {
    const supabase = createClient()
    const fetchData = async () => {
      const [toolsRes, techRes] = await Promise.all([
        supabase.from('tools').select('*').order('name'),
        supabase.from('technicians').select('*'),
      ])
      if (toolsRes.data) setTools(toolsRes.data)
      if (techRes.data) setTechnicians(techRes.data)
      setLoading(false)
    }
    fetchData()

    // Real-time: refresh when tools change from any source (mobile, other admins)
    const channel = supabase
      .channel('tools-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tools' }, () => fetchData())
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  const getTechName = (userId?: string) => {
    if (!userId) return '-'
    const tech = technicians.find((t) => t.user_id === userId || t.id === userId)
    return tech?.name || '-'
  }

  // Derived data - combine known categories with any from the database
  const categories = useMemo(() => {
    const known = [
      'Hand Tools', 'Power Tools', 'Testing Equipment', 'Safety Equipment',
      'Measuring Tools', 'Cutting Tools', 'Fastening Tools', 'Electrical Tools',
      'Plumbing Tools', 'Carpentry Tools', 'Automotive Tools', 'Garden Tools', 'Other',
    ]
    const fromDb = tools.map((t) => t.category).filter(Boolean)
    return [...new Set([...known, ...fromDb])].sort()
  }, [tools])

  const filtered = useMemo(() => {
    let result = tools

    if (viewMyTools && user?.id) {
      result = result.filter((t) => t.assigned_to === user.id)
    }

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

    if (statusFilter !== 'all') {
      result = result.filter((t) => t.status === statusFilter)
    }

    if (categoryFilter !== 'all') {
      result = result.filter((t) => t.category === categoryFilter)
    }

    // Sort
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
  }, [tools, search, statusFilter, categoryFilter, sortField, sortDir, viewMyTools, user])

  const toggleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDir('asc')
    }
  }

  const toggleSelect = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const toggleSelectAll = () => {
    if (selectedIds.size === filtered.length) {
      setSelectedIds(new Set())
    } else {
      setSelectedIds(new Set(filtered.map((t) => t.id)))
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this tool?')) return
    const success = await deleteToolAction(id)
    if (success) {
      setTools((prev) => prev.filter((t) => t.id !== id))
    }
    setActionMenuId(null)
  }

  const openBulkAssign = () => {
    if (selectedIds.size === 0) return
    const firstId = Array.from(selectedIds)[0]
    const tool = tools.find((t) => t.id === firstId)
    if (tool) {
      setAssignToolTarget(tool)
    }
  }

  const handleBulkDeleteConfirm = async () => {
    if (selectedIds.size === 0) {
      setShowBulkDelete(false)
      return
    }

    setBulkDeleting(true)
    const supabase = createClient()
    const ids = Array.from(selectedIds)

    const { error } = await supabase
      .from('tools')
      .delete()
      .in('id', ids)

    if (!error) {
      setTools((prev) => prev.filter((t) => !selectedIds.has(t.id)))
      setSelectedIds(new Set())
    } else {
      console.error('Failed to delete tools:', error)
    }

    setBulkDeleting(false)
    setShowBulkDelete(false)
  }

  const toggleToolType = async (tool: Tool) => {
    const supabase = createClient()
    const newType = tool.tool_type === 'shared' ? 'inventory' : 'shared'
    const { error } = await supabase
      .from('tools')
      .update({ tool_type: newType, updated_at: new Date().toISOString() })
      .eq('id', tool.id)
    if (!error) {
      setTools((prev) =>
        prev.map((t) => (t.id === tool.id ? { ...t, tool_type: newType } : t))
      )
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
    }
    setActionMenuId(null)
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
          <h1 className="text-xl font-semibold tracking-tight">Tools</h1>
          <p className="text-sm text-muted-foreground">
            {viewMyTools ? `${filtered.length} of ${tools.length} tools` : `${tools.length} tools in inventory`}
          </p>
        </div>
        <button
          onClick={() => setShowAddDialog(true)}
          className="flex items-center gap-2 px-4 h-9 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Add Tool
        </button>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => { setSearch(e.target.value) }}
            placeholder="Search tools..."
            className="w-full h-9 pl-9 pr-8 rounded-lg border border-input bg-background text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>

        <select
          value={statusFilter}
          onChange={(e) => { setStatusFilter(e.target.value) }}
          className="h-9 px-3 rounded-lg bg-transparent text-sm text-muted-foreground hover:text-foreground focus:outline-none cursor-pointer appearance-none pr-7 bg-[url('data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23737373%22%20stroke-width%3D%222%22%3E%3Cpath%20d%3D%22M6%209l6%206%206-6%22%2F%3E%3C%2Fsvg%3E')] bg-[length:12px] bg-[right_8px_center] bg-no-repeat"
        >
          <option value="all">All Status</option>
          <option value="Available">Available</option>
          <option value="In Use">In Use</option>
          <option value="Assigned">Assigned</option>
          <option value="Maintenance">Maintenance</option>
          <option value="Retired">Retired</option>
        </select>

        <select
          value={categoryFilter}
          onChange={(e) => { setCategoryFilter(e.target.value) }}
          className="h-9 px-3 rounded-lg bg-transparent text-sm text-muted-foreground hover:text-foreground focus:outline-none cursor-pointer appearance-none pr-7 bg-[url('data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23737373%22%20stroke-width%3D%222%22%3E%3Cpath%20d%3D%22M6%209l6%206%206-6%22%2F%3E%3C%2Fsvg%3E')] bg-[length:12px] bg-[right_8px_center] bg-no-repeat"
        >
          <option value="all">All Categories</option>
          {categories.map((c) => (
            <option key={c} value={c}>{c}</option>
          ))}
        </select>

        {(search || statusFilter !== 'all' || categoryFilter !== 'all') && (
          <button
            onClick={() => { setSearch(''); setStatusFilter('all'); setCategoryFilter('all') }}
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Clear
          </button>
        )}

        <button
          onClick={() => setViewMyTools((v) => !v)}
          className={cn(
            'flex items-center gap-1.5 h-9 px-3 rounded-lg text-sm font-medium border transition-colors',
            viewMyTools
              ? 'bg-primary text-primary-foreground border-primary'
              : 'border-input text-muted-foreground hover:text-foreground'
          )}
          title="Show only tools you added"
        >
          <KeyRound className="w-3.5 h-3.5" />
          My Tools
        </button>

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

      {/* Bulk Actions */}
      {selectedIds.size > 0 && (
        <div className="flex items-center gap-3 bg-primary/5 border border-primary/20 rounded-lg px-4 py-2">
          <span className="text-sm font-medium">{selectedIds.size} selected</span>
          <div className="h-4 w-px bg-border" />
          <button
            onClick={openBulkAssign}
            className="text-sm text-muted-foreground hover:text-foreground flex items-center gap-1.5"
          >
            <UserPlus className="w-3.5 h-3.5" /> Assign
          </button>
          <button className="text-sm text-muted-foreground hover:text-foreground flex items-center gap-1.5">
            <Download className="w-3.5 h-3.5" /> Export
          </button>
          <button
            onClick={() => setShowBulkDelete(true)}
            className="text-sm text-destructive hover:text-destructive/80 flex items-center gap-1.5"
          >
            <Trash2 className="w-3.5 h-3.5" /> Delete
          </button>
          <button
            onClick={() => setSelectedIds(new Set())}
            className="ml-auto text-sm text-muted-foreground hover:text-foreground"
          >
            Clear selection
          </button>
        </div>
      )}

      {/* Grid View */}
      {viewMode === 'grid' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {filtered.length === 0 ? (
            <div className="col-span-full py-12 text-center text-muted-foreground">
              {search || statusFilter !== 'all' || categoryFilter !== 'all'
                ? 'No tools match your filters'
                : 'No tools in inventory'}
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

      {/* Table */}
      {viewMode === 'table' && (
      <div className="bg-card border border-border rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/50">
                <th className="w-10 px-4 py-3">
                  <input
                    type="checkbox"
                    checked={filtered.length > 0 && selectedIds.size === filtered.length}
                    onChange={toggleSelectAll}
                    className="rounded border-input accent-primary"
                  />
                </th>
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
                  <td colSpan={10} className="py-12 text-center text-muted-foreground">
                    {search || statusFilter !== 'all' || categoryFilter !== 'all'
                      ? 'No tools match your filters'
                      : 'No tools in inventory'}
                  </td>
                </tr>
              ) : (
                filtered.map((tool) => (
                  <tr
                    key={tool.id}
                    className={cn(
                      'hover:bg-muted/30 transition-colors',
                      selectedIds.has(tool.id) && 'bg-primary/5'
                    )}
                  >
                    <td className="px-4 py-3">
                      <input
                        type="checkbox"
                        checked={selectedIds.has(tool.id)}
                        onChange={() => toggleSelect(tool.id)}
                        className="rounded border-input accent-primary"
                      />
                    </td>
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
                          {tool.tool_type === 'shared' && (
                            <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 bg-violet-500/10 text-violet-600 text-[10px] font-medium rounded">
                              <Share2 className="w-2.5 h-2.5" /> Shared
                            </span>
                          )}
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
                        <div className="absolute right-4 top-full z-50 w-40 bg-popover border border-border rounded-lg shadow-lg py-1">
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
                            onClick={() => { setAssignToolTarget(tool); setActionMenuId(null) }}
                            className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                          >
                            <UserPlus className="w-3.5 h-3.5" /> Assign
                          </button>
                          <button
                            onClick={() => toggleToolType(tool)}
                            className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                          >
                            {tool.tool_type === 'shared'
                              ? <><Package className="w-3.5 h-3.5" /> Make Inventory</>
                              : <><Share2 className="w-3.5 h-3.5" /> Make Shared</>
                            }
                          </button>
                          {tool.assigned_to && (
                            <>
                              <button
                                onClick={() => { setReassignToolTarget(tool); setActionMenuId(null) }}
                                className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                              >
                                <ArrowLeftRight className="w-3.5 h-3.5" /> Reassign
                              </button>
                              <button
                                onClick={() => { setReturnToolTarget(tool); setActionMenuId(null) }}
                                className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                              >
                                <KeyRound className="w-3.5 h-3.5" /> Return
                              </button>
                            </>
                          )}
                          <div className="border-t border-border my-1" />
                          <button
                            onClick={() => handleDelete(tool.id)}
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


      {/* Dialogs */}
      <AddToolDialog
        open={showAddDialog}
        onClose={() => setShowAddDialog(false)}
        onSuccess={(tool) => {
          setTools((prev) => [tool, ...prev])
          setShowAddDialog(false)
        }}
        assignedTo={viewMyTools && user ? user.id : undefined}
      />

      {editTool && (
        <EditToolDialog
          tool={editTool}
          open={!!editTool}
          onClose={() => setEditTool(null)}
          onSuccess={(updated) => {
            setTools((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
            setEditTool(null)
          }}
        />
      )}

      {assignToolTarget && (
        <AssignToolDialog
          tool={assignToolTarget}
          open={!!assignToolTarget}
          onClose={() => setAssignToolTarget(null)}
          onSuccess={(updated) => {
            setTools((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
            setAssignToolTarget(null)
          }}
        />
      )}

      {reassignToolTarget && (
        <ReassignToolDialog
          tool={reassignToolTarget}
          open={!!reassignToolTarget}
          onClose={() => setReassignToolTarget(null)}
          onSuccess={(updated) => {
            setTools((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
            setReassignToolTarget(null)
          }}
        />
      )}

      {returnToolTarget && (
        <ReturnToolDialog
          tool={returnToolTarget}
          open={!!returnToolTarget}
          onClose={() => setReturnToolTarget(null)}
          onSuccess={(updated) => {
            setTools((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
            setReturnToolTarget(null)
          }}
        />
      )}

      {/* Bulk delete confirmation */}
      {showBulkDelete && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-card border border-border rounded-xl p-6 max-w-[400px] w-full mx-4 shadow-xl">
            <h3 className="text-lg font-semibold">Delete Tools</h3>
            <p className="text-sm text-muted-foreground mt-2">
              {selectedIds.size === 1
                ? 'Are you sure you want to delete this tool? This action cannot be undone.'
                : `Are you sure you want to delete ${selectedIds.size} tools? This action cannot be undone.`}
            </p>
            <div className="flex justify-end gap-3 mt-6">
              <button
                onClick={() => setShowBulkDelete(false)}
                className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleBulkDeleteConfirm}
                disabled={bulkDeleting}
                className="h-9 px-4 bg-destructive text-destructive-foreground rounded-lg text-sm font-medium hover:bg-destructive/90 disabled:opacity-50 transition-colors flex items-center gap-2"
              >
                {bulkDeleting && <Loader2 className="w-4 h-4 animate-spin" />}
                {bulkDeleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
