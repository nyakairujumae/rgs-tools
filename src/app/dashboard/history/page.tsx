'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { formatDateTime, cn } from '@/lib/utils'
import { Loader2, Search, X, Clock, ArrowRight } from 'lucide-react'
import type { ToolHistory } from '@/lib/types/database'

export default function HistoryPage() {
  const [history, setHistory] = useState<ToolHistory[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [actionFilter, setActionFilter] = useState('all')

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('tool_history')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(200)
      setHistory(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const actions = useMemo(() => [...new Set(history.map((h) => h.action))].sort(), [history])

  const filtered = useMemo(() => {
    let result = history
    if (actionFilter !== 'all') result = result.filter((h) => h.action === actionFilter)
    if (search) {
      const q = search.toLowerCase()
      result = result.filter(
        (h) =>
          h.tool_name.toLowerCase().includes(q) ||
          h.description.toLowerCase().includes(q) ||
          h.performed_by?.toLowerCase().includes(q)
      )
    }
    return result
  }, [history, actionFilter, search])

  if (loading) {
    return <div className="flex items-center justify-center h-full"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Audit Trail</h1>
        <p className="text-sm text-muted-foreground">Complete history of all tool actions</p>
      </div>

      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search history..."
            className="w-full h-9 pl-9 pr-8 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground">
              <X className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
        <div className="relative">
          <select
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            className="h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer"
          >
            <option value="all">All Actions</option>
            {actions.map((a) => <option key={a} value={a}>{a}</option>)}
          </select>
          <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
        </div>
      </div>

      <div className="bg-card border border-border rounded-xl">
        <div className="divide-y divide-border">
          {filtered.length === 0 ? (
            <div className="py-12 text-center text-muted-foreground text-sm">No history found</div>
          ) : (
            filtered.map((h) => (
              <div key={h.id} className="px-5 py-3 flex items-start gap-3 hover:bg-muted/30 transition-colors">
                <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center shrink-0 mt-0.5">
                  <Clock className="w-3.5 h-3.5 text-muted-foreground" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{h.action}</span>
                    <span className="text-xs bg-muted px-2 py-0.5 rounded">{h.tool_name}</span>
                  </div>
                  <p className="text-xs text-muted-foreground mt-0.5">{h.description}</p>
                  {(h.old_value || h.new_value) && (
                    <div className="flex items-center gap-1.5 mt-1 text-xs">
                      {h.old_value && <span className="text-red-400 line-through">{h.old_value}</span>}
                      {h.old_value && h.new_value && <ArrowRight className="w-3 h-3 text-muted-foreground" />}
                      {h.new_value && <span className="text-emerald-400">{h.new_value}</span>}
                    </div>
                  )}
                  <div className="flex items-center gap-3 mt-1 text-xs text-muted-foreground">
                    {h.performed_by && <span>by {h.performed_by}</span>}
                    <span>{formatDateTime(h.timestamp)}</span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
