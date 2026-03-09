'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatusBadge, PriorityBadge } from '@/components/shared/status-badge'
import { formatDate, formatAED, timeAgo } from '@/lib/utils'
import { cn } from '@/lib/utils'
import {
  Search,
  Loader2,
  X,
  AlertTriangle,
  CheckCircle,
  Clock,
  XCircle,
} from 'lucide-react'
import type { ToolIssue } from '@/lib/types/database'

const statusTabs = [
  { value: 'all', label: 'All', icon: null },
  { value: 'Open', label: 'Open', icon: <AlertTriangle className="w-3.5 h-3.5" /> },
  { value: 'In Progress', label: 'In Progress', icon: <Clock className="w-3.5 h-3.5" /> },
  { value: 'Resolved', label: 'Resolved', icon: <CheckCircle className="w-3.5 h-3.5" /> },
  { value: 'Closed', label: 'Closed', icon: <XCircle className="w-3.5 h-3.5" /> },
]

export default function IssuesPage() {
  const [issues, setIssues] = useState<ToolIssue[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusTab, setStatusTab] = useState('all')
  const [priorityFilter, setPriorityFilter] = useState('all')

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase.from('tool_issues').select('*').order('reported_at', { ascending: false })
      setIssues(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const counts = useMemo(() => ({
    all: issues.length,
    Open: issues.filter((i) => i.status === 'Open').length,
    'In Progress': issues.filter((i) => i.status === 'In Progress').length,
    Resolved: issues.filter((i) => i.status === 'Resolved').length,
    Closed: issues.filter((i) => i.status === 'Closed').length,
  }), [issues])

  const filtered = useMemo(() => {
    let result = issues
    if (statusTab !== 'all') result = result.filter((i) => i.status === statusTab)
    if (priorityFilter !== 'all') result = result.filter((i) => i.priority === priorityFilter)
    if (search) {
      const q = search.toLowerCase()
      result = result.filter(
        (i) =>
          i.tool_name.toLowerCase().includes(q) ||
          i.description.toLowerCase().includes(q) ||
          i.reported_by.toLowerCase().includes(q)
      )
    }
    return result
  }, [issues, statusTab, priorityFilter, search])

  const updateStatus = async (id: string, newStatus: string) => {
    const { updateIssueStatus } = await import('@/lib/supabase/actions')
    const success = await updateIssueStatus(id, newStatus)
    if (success) {
      setIssues((prev) => prev.map((i) => (i.id === id ? { ...i, status: newStatus as ToolIssue['status'] } : i)))
    }
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
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Issues</h1>
        <p className="text-sm text-muted-foreground">{issues.length} reported issues</p>
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-border">
        {statusTabs.map((tab) => (
          <button
            key={tab.value}
            onClick={() => setStatusTab(tab.value)}
            className={cn(
              'flex items-center gap-1.5 px-3 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
              statusTab === tab.value
                ? 'border-primary text-foreground'
                : 'border-transparent text-muted-foreground hover:text-foreground'
            )}
          >
            {tab.icon}
            {tab.label}
            <span className="ml-1 text-xs bg-muted px-1.5 py-0.5 rounded-full">
              {counts[tab.value as keyof typeof counts]}
            </span>
          </button>
        ))}
      </div>

      {/* Filters */}
      <div className="flex items-center gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search issues..."
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
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value)}
            className="h-9 px-3 pr-8 rounded-lg border border-input bg-transparent text-sm appearance-none cursor-pointer"
          >
            <option value="all">All Priority</option>
            <option value="Critical">Critical</option>
            <option value="High">High</option>
            <option value="Medium">Medium</option>
            <option value="Low">Low</option>
          </select>
          <svg className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
        </div>
      </div>

      {/* Issue Cards */}
      <div className="space-y-3">
        {filtered.length === 0 ? (
          <div className="py-12 text-center text-muted-foreground text-sm">
            No issues found
          </div>
        ) : (
          filtered.map((issue) => (
            <div key={issue.id} className="bg-card border border-border rounded-xl p-4 hover:border-primary/20 transition-colors">
              <div className="flex items-start gap-4">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-medium">{issue.tool_name}</span>
                    <StatusBadge status={issue.status} />
                    <PriorityBadge priority={issue.priority} />
                    <span className="text-xs bg-muted px-2 py-0.5 rounded">{issue.issue_type}</span>
                  </div>
                  <p className="text-sm text-muted-foreground mt-1 line-clamp-2">{issue.description}</p>
                  <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                    <span>Reported by {issue.reported_by}</span>
                    <span>{timeAgo(issue.reported_at)}</span>
                    {issue.estimated_cost != null && <span>{formatAED(issue.estimated_cost)}</span>}
                  </div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  {issue.status === 'Open' && (
                    <button
                      onClick={() => updateStatus(issue.id, 'In Progress')}
                      className="text-xs px-2.5 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors"
                    >
                      Start
                    </button>
                  )}
                  {issue.status === 'In Progress' && (
                    <button
                      onClick={() => updateStatus(issue.id, 'Resolved')}
                      className="text-xs px-2.5 py-1.5 rounded-lg bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 hover:bg-emerald-500/20 transition-colors"
                    >
                      Resolve
                    </button>
                  )}
                  {issue.status === 'Resolved' && (
                    <button
                      onClick={() => updateStatus(issue.id, 'Closed')}
                      className="text-xs px-2.5 py-1.5 rounded-lg border border-input hover:bg-accent transition-colors"
                    >
                      Close
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
