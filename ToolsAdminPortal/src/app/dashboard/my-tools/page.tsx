'use client'

import { useEffect, useState, useMemo } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/use-auth'
import { cn, formatAED } from '@/lib/utils'
import { StatusBadge } from '@/components/shared/status-badge'
import Image from 'next/image'
import {
  Search,
  Plus,
  ChevronDown,
  ChevronUp,
  ChevronsUpDown,
  MoreHorizontal,
  Trash2,
  Pencil,
  Eye,
  Loader2,
  X,
  LayoutGrid,
  List,
  Camera,
  KeyRound,
} from 'lucide-react'
import { deleteTool as deleteToolAction } from '@/lib/supabase/actions'
import { AddToolDialog } from '@/components/tools/add-tool-dialog'
import { EditToolDialog } from '@/components/tools/edit-tool-dialog'
import { ReturnToolDialog } from '@/components/tools/return-tool-dialog'
import type { Tool } from '@/lib/types/database'

type SortField = 'name' | 'category' | 'brand' | 'serial_number' | 'status' | 'condition' | 'current_value'
type SortDir = 'asc' | 'desc'

export default function MyToolsPage() {
  const { user, profile } = useAuth()
  const [tools, setTools] = useState<Tool[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [sortField, setSortField] = useState<SortField>('name')
  const [sortDir, setSortDir] = useState<SortDir>('asc')
  const [actionMenuId, setActionMenuId] = useState<string | null>(null)
  const [viewMode, setViewMode] = useState<'table' | 'grid'>('table')
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [editTool, setEditTool] = useState<Tool | null>(null)
  const [returnToolTarget, setReturnToolTarget] = useState<Tool | null>(null)

  useEffect(() => {
    if (!user?.id) return
    const supabase = createClient()

    const fetchData = async () => {
      const { data } = await supabase
        .from('tools')
        .select('*')
        .eq('assigned_to', user.id)
        .order('name')
      if (data) setTools(data)
      setLoading(false)
    }
    fetchData()

    const channel = supabase
      .channel('my-tools-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tools' }, fetchData)
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [user?.id])

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

    if (statusFilter !== 'all') {
      result = result.filter((t) => t.status === statusFilter)
    }

    return [...result].sort((a, b) => {
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
  }, [tools, search, statusFilter, sortField, sortDir])

  const toggleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDir(sortDir === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDir('asc')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this tool?')) return
    const success = await deleteToolAction(id)
    if (success) setTools((prev) => prev.filter((t) => t.id !== id))
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
          <div className="flex items-center gap-2">
            <KeyRound className="w-5 h-5 text-primary" />
            <h1 className="text-xl font-semibold tracking-tight">My Tools</h1>
          </div>
          <p className="text-sm text-muted-foreground mt-0.5">
            Tools assigned to {profile?.full_name || 'you'} · {tools.length} total
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
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search my tools..."
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
          onChange={(e) => setStatusFilter(e.target.value)}
          className="h-9 px-3 rounded-lg bg-transparent text-sm text-muted-foreground hover:text-foreground focus:outline-none cursor-pointer appearance-none pr-7 bg-[url('data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23737373%22%20stroke-width%3D%222%22%3E%3Cpath%20d%3D%22M6%209l6%206%206-6%22%2F%3E%3C%2Fsvg%3E')] bg-[length:12px] bg-[right_8px_center] bg-no-repeat"
        >
          <option value="all">All Status</option>
          <option value="Available">Available</option>
          <option value="In Use">In Use</option>
          <option value="Maintenance">Maintenance</option>
          <option value="Retired">Retired</option>
        </select>

        {(search || statusFilter !== 'all') && (
          <button
            onClick={() => { setSearch(''); setStatusFilter('all') }}
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
              {search || statusFilter !== 'all' ? 'No tools match your filters' : 'No tools assigned to you yet'}
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
                    <Image src={tool.image_path} alt={tool.name} width={200} height={200} className="w-full h-full object-cover group-hover:scale-105 transition-transform" />
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
                  <th className="w-10 px-4 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filtered.length === 0 ? (
                  <tr>
                    <td colSpan={8} className="py-12 text-center text-muted-foreground">
                      {search || statusFilter !== 'all' ? 'No tools match your filters' : 'No tools assigned to you yet'}
                    </td>
                  </tr>
                ) : (
                  filtered.map((tool) => (
                    <tr key={tool.id} className="hover:bg-muted/30 transition-colors">
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-lg overflow-hidden flex-shrink-0">
                            {tool.image_path ? (
                              <Image src={tool.image_path} alt={tool.name} width={36} height={36} className="w-full h-full object-cover" />
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
                            {tool.model && <p className="text-xs text-muted-foreground">{tool.model}</p>}
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">{tool.category}</td>
                      <td className="px-4 py-3 text-muted-foreground">{tool.brand || '-'}</td>
                      <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{tool.serial_number || '-'}</td>
                      <td className="px-4 py-3"><StatusBadge status={tool.status} /></td>
                      <td className="px-4 py-3 text-muted-foreground">{tool.condition}</td>
                      <td className="px-4 py-3 text-muted-foreground">{formatAED(tool.current_value || tool.purchase_price)}</td>
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
                              onClick={() => { setReturnToolTarget(tool); setActionMenuId(null) }}
                              className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                            >
                              <KeyRound className="w-3.5 h-3.5" /> Return
                            </button>
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
        assignedTo={user?.id}
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

      {returnToolTarget && (
        <ReturnToolDialog
          tool={returnToolTarget}
          open={!!returnToolTarget}
          onClose={() => setReturnToolTarget(null)}
          onSuccess={(updated) => {
            // Tool returned — remove from my tools list since it's no longer assigned to us
            setTools((prev) => prev.filter((t) => t.id !== updated.id))
            setReturnToolTarget(null)
          }}
        />
      )}
    </div>
  )
}
