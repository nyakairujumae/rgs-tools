'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatusBadge, PriorityBadge } from '@/components/shared/status-badge'
import { formatDate, formatAED, cn } from '@/lib/utils'
import { Loader2, Calendar, Wrench } from 'lucide-react'
import type { MaintenanceSchedule } from '@/lib/types/database'

export default function MaintenancePage() {
  const [schedules, setSchedules] = useState<MaintenanceSchedule[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState('all')

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('maintenance_schedules')
        .select('*')
        .order('scheduled_date', { ascending: true })
      setSchedules(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const counts = useMemo(() => ({
    all: schedules.length,
    Overdue: schedules.filter((s) => s.status === 'Overdue').length,
    Scheduled: schedules.filter((s) => s.status === 'Scheduled').length,
    'In Progress': schedules.filter((s) => s.status === 'In Progress').length,
    Completed: schedules.filter((s) => s.status === 'Completed').length,
  }), [schedules])

  const filtered = tab === 'all' ? schedules : schedules.filter((s) => s.status === tab)

  if (loading) {
    return <div className="flex items-center justify-center h-full"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Maintenance</h1>
        <p className="text-sm text-muted-foreground">{counts.Overdue > 0 ? `${counts.Overdue} overdue` : 'All up to date'}</p>
      </div>

      <div className="flex items-center gap-1 border-b border-border">
        {(['all', 'Overdue', 'Scheduled', 'In Progress', 'Completed'] as const).map((t) => (
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

      <div className="bg-card border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Tool</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Scheduled</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Priority</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Assigned To</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Est. Cost</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr><td colSpan={7} className="py-12 text-center text-muted-foreground">No maintenance schedules</td></tr>
            ) : (
              filtered.map((s) => (
                <tr key={s.id} className="hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-medium">{s.tool_name}</td>
                  <td className="px-4 py-3 text-muted-foreground">{s.maintenance_type}</td>
                  <td className="px-4 py-3 text-muted-foreground">{formatDate(s.scheduled_date)}</td>
                  <td className="px-4 py-3"><StatusBadge status={s.status} /></td>
                  <td className="px-4 py-3"><PriorityBadge priority={s.priority} /></td>
                  <td className="px-4 py-3 text-muted-foreground">{s.assigned_to || '-'}</td>
                  <td className="px-4 py-3 text-muted-foreground">{s.estimated_cost ? formatAED(s.estimated_cost) : '-'}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
