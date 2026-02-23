'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { cn, formatDate } from '@/lib/utils'
import { StatusBadge } from '@/components/shared/status-badge'
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
} from 'lucide-react'
import { AssignToolDialog } from '@/components/tools/assign-tool-dialog'
import { ReassignToolDialog } from '@/components/tools/reassign-tool-dialog'
import { ReturnToolDialog } from '@/components/tools/return-tool-dialog'
import type { Tool, Technician } from '@/lib/types/database'

export default function SharedToolsPage() {
  const [tools, setTools] = useState<Tool[]>([])
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [categoryFilter, setCategoryFilter] = useState<string>('all')
  const [actionMenuId, setActionMenuId] = useState<string | null>(null)
  const [assignTool, setAssignTool] = useState<Tool | null>(null)
  const [reassignTool, setReassignTool] = useState<Tool | null>(null)
  const [returnTool, setReturnTool] = useState<Tool | null>(null)

  useEffect(() => {
    const supabase = createClient()
    let debounceTimer: NodeJS.Timeout | null = null

    const debouncedFetch = () => {
      if (debounceTimer) clearTimeout(debounceTimer)
      debounceTimer = setTimeout(() => fetchData(), 1000)
    }

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
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tools' }, debouncedFetch)
      .subscribe()

    return () => {
      if (debounceTimer) clearTimeout(debounceTimer)
      supabase.removeChannel(channel)
    }
  }, [])

  const getTechName = (userId?: string) => {
    if (!userId) return null
    const tech = technicians.find((t) => t.user_id === userId || t.id === userId)
    return tech?.name || null
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
          t.brand?.toLowerCase().includes(q)
      )
    }

    if (statusFilter !== 'all') {
      result = result.filter((t) => t.status === statusFilter)
    }

    if (categoryFilter !== 'all') {
      result = result.filter((t) => t.category === categoryFilter)
    }

    return result
  }, [tools, search, statusFilter, categoryFilter])

  const counts = useMemo(() => ({
    total: tools.length,
    available: tools.filter((t) => t.status === 'Available').length,
    inUse: tools.filter((t) => t.status === 'In Use').length,
    maintenance: tools.filter((t) => t.status === 'Maintenance').length,
  }), [tools])

  const handleToolUpdated = (updated: Tool) => {
    if (updated.tool_type !== 'shared') {
      setTools((prev) => prev.filter((t) => t.id !== updated.id))
    } else {
      setTools((prev) => prev.map((t) => (t.id === updated.id ? updated : t)))
    }
  }

  if (loading) {
    return (
      <div className="p-4 md:p-6 max-w-[1600px] mx-auto space-y-4 animate-pulse">
        <div className="h-7 w-48 bg-muted rounded" />
        <div className="h-4 w-64 bg-muted rounded" />
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-20 bg-card border border-border rounded-xl" />
          ))}
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4 mt-4">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="bg-card border border-border rounded-xl">
              <div className="aspect-square bg-muted rounded-t-xl" />
              <div className="p-3 space-y-2">
                <div className="h-4 w-24 bg-muted rounded" />
                <div className="h-3 w-16 bg-muted rounded" />
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  return (
    <div className="p-4 md:p-6 max-w-[1600px] mx-auto space-y-4">
      {/* Header */}
      <div>
        <div className="flex items-center gap-2">
          <Share2 className="w-5 h-5 text-primary" />
          <h1 className="text-xl font-semibold tracking-tight">Shared Tools</h1>
        </div>
        <p className="text-sm text-muted-foreground mt-1">
          Access and monitor tools that are shared across teams
        </p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className="bg-card border border-border rounded-xl p-3">
          <p className="text-xs text-muted-foreground font-medium uppercase tracking-wider">Total Shared</p>
          <p className="text-2xl font-semibold mt-1">{counts.total}</p>
        </div>
        <div className="bg-card border border-border rounded-xl p-3">
          <p className="text-xs text-muted-foreground font-medium uppercase tracking-wider">Available</p>
          <p className="text-2xl font-semibold mt-1 text-emerald-600">{counts.available}</p>
        </div>
        <div className="bg-card border border-border rounded-xl p-3">
          <p className="text-xs text-muted-foreground font-medium uppercase tracking-wider">In Use</p>
          <p className="text-2xl font-semibold mt-1 text-blue-600">{counts.inUse}</p>
        </div>
        <div className="bg-card border border-border rounded-xl p-3">
          <p className="text-xs text-muted-foreground font-medium uppercase tracking-wider">Maintenance</p>
          <p className="text-2xl font-semibold mt-1 text-amber-600">{counts.maintenance}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3 flex-wrap">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search shared tools..."
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
          className="h-9 px-3 rounded-lg border border-input bg-background text-sm focus:outline-none cursor-pointer"
        >
          <option value="all">All Status</option>
          <option value="Available">Available</option>
          <option value="In Use">In Use</option>
          <option value="Maintenance">Maintenance</option>
          <option value="Retired">Retired</option>
        </select>

        {categories.length > 0 && (
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="h-9 px-3 rounded-lg border border-input bg-background text-sm focus:outline-none cursor-pointer"
          >
            <option value="all">All Categories</option>
            {categories.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        )}

        {(search || statusFilter !== 'all' || categoryFilter !== 'all') && (
          <button
            onClick={() => { setSearch(''); setStatusFilter('all'); setCategoryFilter('all') }}
            className="text-sm text-muted-foreground hover:text-foreground transition-colors"
          >
            Clear
          </button>
        )}
      </div>

      {/* Grid */}
      {filtered.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-16 text-center">
          <Share2 className="w-12 h-12 text-muted-foreground/30 mb-4" />
          <h3 className="text-lg font-medium">
            {search || statusFilter !== 'all' || categoryFilter !== 'all'
              ? 'No Tools Found'
              : 'No Shared Tools'}
          </h3>
          <p className="text-sm text-muted-foreground mt-1 max-w-sm">
            {search || statusFilter !== 'all' || categoryFilter !== 'all'
              ? 'Try adjusting your filters or search terms'
              : 'Go to Tools and mark tools as "Shared" so they appear here'}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {filtered.map((tool) => {
            const holder = getTechName(tool.assigned_to)
            return (
              <div
                key={tool.id}
                className="bg-card border border-border rounded-xl overflow-hidden hover:border-primary/30 hover:shadow-md transition-all group relative"
              >
                {/* Image */}
                <div className="aspect-square bg-muted/30 flex items-center justify-center overflow-hidden relative">
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
                  {/* Action menu button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation()
                      setActionMenuId(actionMenuId === tool.id ? null : tool.id)
                    }}
                    className="absolute top-2 right-2 w-7 h-7 flex items-center justify-center rounded-full bg-black/40 text-white opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <MoreHorizontal className="w-4 h-4" />
                  </button>
                  {/* Action menu dropdown */}
                  {actionMenuId === tool.id && (
                    <div
                      className="absolute top-10 right-2 z-50 w-44 bg-popover border border-border rounded-lg shadow-lg py-1"
                      onClick={(e) => e.stopPropagation()}
                    >
                      {tool.status === 'Available' && (
                        <button
                          onClick={() => { setAssignTool(tool); setActionMenuId(null) }}
                          className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                        >
                          <UserPlus className="w-3.5 h-3.5" /> Assign
                        </button>
                      )}
                      {tool.status === 'In Use' && (
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
                      <a
                        href={`/dashboard/tools/${tool.id}`}
                        className="flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent transition-colors w-full text-left"
                      >
                        <Eye className="w-3.5 h-3.5" /> View Details
                      </a>
                    </div>
                  )}
                </div>

                {/* Info */}
                <div className="p-3 space-y-1.5">
                  <h3 className="font-medium text-sm truncate">{tool.name}</h3>
                  <p className="text-xs text-muted-foreground truncate">{tool.category}</p>
                  <div className="flex items-center justify-between gap-2">
                    <StatusBadge status={tool.status} />
                    {holder && (
                      <span className="text-[10px] text-muted-foreground truncate max-w-[80px]" title={holder}>
                        {holder}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Close action menus when clicking outside */}
      {actionMenuId && (
        <div className="fixed inset-0 z-40" onClick={() => setActionMenuId(null)} />
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
