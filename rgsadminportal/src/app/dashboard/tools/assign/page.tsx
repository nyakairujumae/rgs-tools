'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatusBadge } from '@/components/shared/status-badge'
import { AssignToolDialog } from '@/components/tools/assign-tool-dialog'
import { Search, ArrowLeftRight, Loader2 } from 'lucide-react'
import type { Tool } from '@/lib/types/database'

const STATUS_FILTERS = [
  'all',
  'Available',
  'In Use',
  'Assigned',
  'Maintenance',
  'Retired',
] as const

type StatusFilter = (typeof STATUS_FILTERS)[number]

export default function AssignToolPage() {
  const [tools, setTools] = useState<Tool[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all')
  const [assignTarget, setAssignTarget] = useState<Tool | null>(null)

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('tools')
        .select('*')
        .order('name')
      setTools(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const filtered = useMemo(() => {
    return tools.filter((t) => {
      const matchSearch =
        !search ||
        t.name.toLowerCase().includes(search.toLowerCase()) ||
        t.serial_number?.toLowerCase().includes(search.toLowerCase()) ||
        t.category?.toLowerCase().includes(search.toLowerCase())
      const matchStatus = statusFilter === 'all' || t.status === statusFilter
      return matchSearch && matchStatus
    })
  }, [tools, search, statusFilter])

  const handleAssignSuccess = (updatedTool: Tool) => {
    setTools((prev) => prev.map((t) => (t.id === updatedTool.id ? updatedTool : t)))
    setAssignTarget(null)
  }

  return (
    <div className="p-4 sm:p-6 max-w-[1200px] mx-auto space-y-5">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Assign Tool</h1>
        <p className="text-sm text-muted-foreground">
          Browse all tools, then assign available ones or reassign tools that are already in use.
        </p>
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative w-full sm:flex-1 sm:min-w-[200px] sm:max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search tools..."
            className="w-full h-9 pl-9 pr-3 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
        <div className="overflow-x-auto">
        <div className="flex items-center rounded-lg border border-input overflow-hidden text-sm min-w-max">
          {STATUS_FILTERS.map((s) => (
            <button
              key={s}
              onClick={() => setStatusFilter(s)}
              className={`px-3 h-9 font-medium transition-colors ${
                statusFilter === s
                  ? 'bg-primary text-primary-foreground'
                  : 'text-muted-foreground hover:bg-accent hover:text-foreground'
              }`}
            >
              {s === 'all' ? 'All' : s}
            </button>
          ))}
        </div>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="py-20 text-center text-sm text-muted-foreground">No tools found</div>
      ) : (
        <>
          <div className="sm:hidden space-y-2">
            {filtered.map((tool) => (
              <div key={tool.id} className="rounded-xl border border-border p-3 space-y-2">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <p className="font-medium truncate">{tool.name}</p>
                    <p className="text-xs text-muted-foreground truncate">{tool.category || '—'}</p>
                  </div>
                  <StatusBadge status={tool.status} />
                </div>
                <p className="text-xs text-muted-foreground font-mono truncate">{tool.serial_number || '—'}</p>
                <button
                  onClick={() => setAssignTarget(tool)}
                  className="w-full inline-flex items-center justify-center gap-1.5 text-xs px-3 py-2 rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 transition-colors font-medium"
                >
                  <ArrowLeftRight className="w-3.5 h-3.5" />
                  {tool.assigned_to ? 'Reassign' : 'Assign'}
                </button>
              </div>
            ))}
          </div>
          <div className="hidden sm:block rounded-xl border border-border overflow-hidden">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/40">
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Tool</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Category</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Serial No.</th>
                <th className="text-left px-4 py-3 font-medium text-muted-foreground">Status</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {filtered.map((tool) => (
                <tr key={tool.id} className="hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-medium">{tool.name}</td>
                  <td className="px-4 py-3 text-muted-foreground">{tool.category || '—'}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{tool.serial_number || '—'}</td>
                  <td className="px-4 py-3">
                    <StatusBadge status={tool.status} />
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => setAssignTarget(tool)}
                      className="inline-flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 transition-colors font-medium"
                    >
                      <ArrowLeftRight className="w-3.5 h-3.5" />
                      {tool.assigned_to ? 'Reassign' : 'Assign'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        </>
      )}

      {assignTarget && (
        <AssignToolDialog
          tool={assignTarget}
          open={true}
          onClose={() => setAssignTarget(null)}
          onSuccess={handleAssignSuccess}
        />
      )}
    </div>
  )
}
