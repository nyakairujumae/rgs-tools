'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/use-auth'
import { formatAED, timeAgo } from '@/lib/utils'
import { StatusBadge, PriorityBadge } from '@/components/shared/status-badge'
import {
  Wrench,
  CheckCircle,
  AlertTriangle,
  Clock,
  Users,
  Shield,
  ClipboardList,
  TrendingUp,
  Plus,
  UserPlus,
  FileText,
  ArrowRight,
  Loader2,
  Package,
} from 'lucide-react'
import type { Tool, ToolIssue, ApprovalWorkflow, MaintenanceSchedule, Certification, ToolHistory, PendingUserApproval } from '@/lib/types/database'

interface DashboardData {
  tools: Tool[]
  issues: ToolIssue[]
  approvals: ApprovalWorkflow[]
  maintenance: MaintenanceSchedule[]
  certifications: Certification[]
  recentHistory: ToolHistory[]
  pendingUsers: PendingUserApproval[]
}

export default function DashboardPage() {
  const { profile } = useAuth()
  const [data, setData] = useState<DashboardData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const supabase = createClient()

    const fetchData = async () => {
      try {
        // Fetch each independently so one failure doesn't block all
        const safeQuery = async <T,>(query: PromiseLike<{ data: T | null; error: any }>): Promise<T | null> => {
          try {
            const { data, error } = await query
            if (error) console.warn('Query error:', error.message)
            return data
          } catch (e) {
            console.warn('Query failed:', e)
            return null
          }
        }

        const [tools, issues, approvals, maintenance, certifications, recentHistory, pendingUsers] = await Promise.all([
          safeQuery(supabase.from('tools').select('*')),
          safeQuery(supabase.from('tool_issues').select('*')),
          safeQuery(supabase.from('approval_workflows').select('*')),
          safeQuery(supabase.from('maintenance_schedules').select('*')),
          safeQuery(supabase.from('certifications').select('*')),
          safeQuery(supabase.from('tool_history').select('*').order('timestamp', { ascending: false }).limit(10)),
          safeQuery(supabase.from('pending_user_approvals').select('*').eq('status', 'pending')),
        ])

        setData({
          tools: (tools as any) || [],
          issues: (issues as any) || [],
          approvals: (approvals as any) || [],
          maintenance: (maintenance as any) || [],
          certifications: (certifications as any) || [],
          recentHistory: (recentHistory as any) || [],
          pendingUsers: (pendingUsers as any) || [],
        })
      } catch (e) {
        console.error('Dashboard fetch error:', e)
        setData({
          tools: [],
          issues: [],
          approvals: [],
          maintenance: [],
          certifications: [],
          recentHistory: [],
          pendingUsers: [],
        })
      }
      setLoading(false)
    }

    fetchData()

    // Real-time subscriptions so changes from mobile/other sources appear
    const channel = supabase
      .channel('dashboard-realtime')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tools' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tool_history' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'tool_issues' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'approval_workflows' }, () => fetchData())
      .on('postgres_changes', { event: '*', schema: 'public', table: 'pending_user_approvals' }, () => fetchData())
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
      </div>
    )
  }

  if (!data) return null

  const totalTools = data.tools.length
  const availableTools = data.tools.filter((t) => t.status === 'Available').length
  const inUseTools = data.tools.filter((t) => t.status === 'In Use').length
  const maintenanceTools = data.tools.filter((t) => t.status === 'Maintenance').length
  const totalValue = data.tools.reduce((sum, t) => sum + (t.current_value || t.purchase_price || 0), 0)

  const openIssues = data.issues.filter((i) => i.status === 'Open').length
  const criticalIssues = data.issues.filter((i) => i.priority === 'Critical' && i.status !== 'Closed').length
  const pendingApprovals = data.approvals.filter((a) => a.status === 'Pending').length
  const overdueMaintenances = data.maintenance.filter((m) => m.status === 'Overdue').length
  const expiringCerts = data.certifications.filter((c) => c.status === 'Expiring Soon' || c.status === 'Expired').length

  const greeting = () => {
    const hour = new Date().getHours()
    if (hour < 12) return 'Good morning'
    if (hour < 17) return 'Good afternoon'
    return 'Good evening'
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">
          {greeting()}, {profile?.full_name?.split(' ')[0] || 'Admin'}
        </h1>
        <p className="text-muted-foreground text-sm mt-1">
          Here&apos;s what&apos;s happening with your tools today
        </p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          label="Total Tools"
          value={totalTools}
          subtitle={formatAED(totalValue)}
          icon={<Wrench className="w-5 h-5" />}
          iconColor="text-blue-500 bg-blue-500/10"
          href="/dashboard/tools"
        />
        <KPICard
          label="Available"
          value={availableTools}
          subtitle={`${totalTools > 0 ? Math.round((availableTools / totalTools) * 100) : 0}% of total`}
          icon={<CheckCircle className="w-5 h-5" />}
          iconColor="text-emerald-500 bg-emerald-500/10"
          href="/dashboard/tools"
        />
        <KPICard
          label="In Use"
          value={inUseTools}
          subtitle={`${maintenanceTools} in maintenance`}
          icon={<Package className="w-5 h-5" />}
          iconColor="text-violet-500 bg-violet-500/10"
          href="/dashboard/tools"
        />
        <KPICard
          label="Open Issues"
          value={openIssues}
          subtitle={criticalIssues > 0 ? `${criticalIssues} critical` : 'No critical issues'}
          icon={<AlertTriangle className="w-5 h-5" />}
          iconColor={criticalIssues > 0 ? 'text-red-500 bg-red-500/10' : 'text-amber-500 bg-amber-500/10'}
          href="/dashboard/issues"
        />
      </div>

      {/* Secondary KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <KPICard
          label="Pending Approvals"
          value={pendingApprovals}
          subtitle={`${data.pendingUsers.length} user registrations`}
          icon={<Clock className="w-5 h-5" />}
          iconColor="text-amber-500 bg-amber-500/10"
          href="/dashboard/approvals"
          small
        />
        <KPICard
          label="Overdue Maintenance"
          value={overdueMaintenances}
          subtitle={`${data.maintenance.filter((m) => m.status === 'Scheduled').length} scheduled`}
          icon={<ClipboardList className="w-5 h-5" />}
          iconColor={overdueMaintenances > 0 ? 'text-red-500 bg-red-500/10' : 'text-blue-500 bg-blue-500/10'}
          href="/dashboard/maintenance"
          small
        />
        <KPICard
          label="Compliance Alerts"
          value={expiringCerts}
          subtitle={`${data.certifications.filter((c) => c.status === 'Valid').length} valid certs`}
          icon={<Shield className="w-5 h-5" />}
          iconColor={expiringCerts > 0 ? 'text-amber-500 bg-amber-500/10' : 'text-emerald-500 bg-emerald-500/10'}
          href="/dashboard/compliance"
          small
        />
        <KPICard
          label="Asset Value"
          value={formatAED(totalValue)}
          subtitle={`Across ${totalTools} tools`}
          icon={<TrendingUp className="w-5 h-5" />}
          iconColor="text-emerald-500 bg-emerald-500/10"
          href="/dashboard/reports"
          small
          isText
        />
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <QuickAction href="/dashboard/tools" icon={<Plus className="w-4 h-4" />} label="Add Tool" />
        <QuickAction href="/dashboard/technicians" icon={<UserPlus className="w-4 h-4" />} label="Add Technician" />
        <QuickAction href="/dashboard/reports" icon={<FileText className="w-4 h-4" />} label="Generate Report" />
        <QuickAction href="/dashboard/approvals" icon={<CheckCircle className="w-4 h-4" />} label="Review Approvals" />
      </div>

      {/* Bottom Row */}
      <div className="grid lg:grid-cols-2 gap-6">
        {/* Recent Activity */}
        <div className="bg-card border border-border rounded-xl">
          <div className="flex items-center justify-between px-5 py-4 border-b border-border">
            <h2 className="text-sm font-semibold">Recent Activity</h2>
            <Link href="/dashboard/history" className="text-xs text-primary hover:underline flex items-center gap-1">
              View All <ArrowRight className="w-3 h-3" />
            </Link>
          </div>
          <div className="divide-y divide-border">
            {data.recentHistory.length === 0 ? (
              <div className="py-8 text-center text-sm text-muted-foreground">
                No recent activity
              </div>
            ) : (
              data.recentHistory.slice(0, 6).map((h) => (
                <div key={h.id} className="px-5 py-3 flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-muted flex items-center justify-center shrink-0 mt-0.5">
                    <Wrench className="w-3.5 h-3.5 text-muted-foreground" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm">
                      <span className="font-medium">{h.action}</span>
                      {' '}
                      <span className="text-muted-foreground">{h.tool_name}</span>
                    </p>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {h.description}
                    </p>
                  </div>
                  <span className="text-xs text-muted-foreground whitespace-nowrap">
                    {timeAgo(h.timestamp)}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Needs Attention */}
        <div className="bg-card border border-border rounded-xl">
          <div className="px-5 py-4 border-b border-border">
            <h2 className="text-sm font-semibold">Needs Attention</h2>
          </div>
          <div className="divide-y divide-border">
            {/* Critical Issues */}
            {data.issues
              .filter((i) => (i.priority === 'Critical' || i.priority === 'High') && i.status !== 'Closed')
              .slice(0, 3)
              .map((issue) => (
                <div key={issue.id} className="px-5 py-3 flex items-center gap-3">
                  <AlertTriangle className="w-4 h-4 text-red-500 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{issue.tool_name}</p>
                    <p className="text-xs text-muted-foreground">{issue.issue_type} - {issue.description.slice(0, 60)}</p>
                  </div>
                  <PriorityBadge priority={issue.priority} />
                </div>
              ))}

            {/* Pending User Approvals */}
            {data.pendingUsers.slice(0, 2).map((user) => (
              <div key={user.id} className="px-5 py-3 flex items-center gap-3">
                <Users className="w-4 h-4 text-amber-500 shrink-0" />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium truncate">{user.full_name}</p>
                  <p className="text-xs text-muted-foreground">Pending registration approval</p>
                </div>
                <StatusBadge status="Pending" />
              </div>
            ))}

            {/* Overdue Maintenance */}
            {data.maintenance
              .filter((m) => m.status === 'Overdue')
              .slice(0, 2)
              .map((m) => (
                <div key={m.id} className="px-5 py-3 flex items-center gap-3">
                  <ClipboardList className="w-4 h-4 text-red-500 shrink-0" />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{m.tool_name}</p>
                    <p className="text-xs text-muted-foreground">{m.maintenance_type} overdue</p>
                  </div>
                  <StatusBadge status="Overdue" />
                </div>
              ))}

            {criticalIssues === 0 && overdueMaintenances === 0 && data.pendingUsers.length === 0 && (
              <div className="py-8 text-center">
                <CheckCircle className="w-8 h-8 text-emerald-500 mx-auto mb-2" />
                <p className="text-sm font-medium">All good!</p>
                <p className="text-xs text-muted-foreground mt-1">No items need attention</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

// ── Sub-components ──

function KPICard({
  label,
  value,
  subtitle,
  icon,
  iconColor,
  href,
  small,
  isText,
}: {
  label: string
  value: number | string
  subtitle: string
  icon: React.ReactNode
  iconColor: string
  href: string
  small?: boolean
  isText?: boolean
}) {
  return (
    <Link
      href={href}
      className="bg-card border border-border rounded-xl p-4 hover:border-primary/30 transition-colors group"
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium text-muted-foreground uppercase tracking-wider">
            {label}
          </p>
          <p className={`font-semibold mt-1 ${small ? 'text-xl' : 'text-2xl'} ${isText ? 'text-lg' : ''}`}>
            {value}
          </p>
          <p className="text-xs text-muted-foreground mt-1">{subtitle}</p>
        </div>
        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${iconColor}`}>
          {icon}
        </div>
      </div>
    </Link>
  )
}

function QuickAction({ href, icon, label }: { href: string; icon: React.ReactNode; label: string }) {
  return (
    <Link
      href={href}
      className="flex items-center gap-2 px-4 py-2.5 bg-card border border-border rounded-lg hover:border-primary/30 hover:bg-accent/50 transition-colors text-sm font-medium"
    >
      <span className="text-primary">{icon}</span>
      {label}
    </Link>
  )
}
