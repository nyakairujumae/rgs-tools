'use client'

import { useState, useEffect, useRef } from 'react'
import { createClient } from '@/lib/supabase/client'
import { generatePDF, generateCSV, generateExcel, type ReportType, type ReportData } from '@/lib/reports/generate-report'
import { useOrgContext } from '@/contexts/organization-context'
import { cn } from '@/lib/utils'
import {
  FileText,
  Download,
  BarChart3,
  Wrench,
  Users,
  AlertTriangle,
  DollarSign,
  Calendar,
  Loader2,
  Gauge,
  Shield,
} from 'lucide-react'
import type { Tool, ToolIssue, ToolHistory, Technician, ApprovalWorkflow, Certification, MaintenanceSchedule } from '@/lib/types/database'

const reportTypes: { id: ReportType; label: string; description: string; icon: React.ReactNode }[] = [
  { id: 'inventory', label: 'Tools Inventory', description: 'Complete inventory with status, location, condition, and value', icon: <Wrench className="w-5 h-5" /> },
  { id: 'assignments', label: 'Tool Assignments', description: 'Who has what tools, assignment dates, and locations', icon: <Users className="w-5 h-5" /> },
  { id: 'issues', label: 'Tool Issues', description: 'Open/closed issues, priorities, and resolution costs', icon: <AlertTriangle className="w-5 h-5" /> },
  { id: 'calibration', label: 'Calibration Report', description: 'Calibration certificates, expiry tracking, and scheduled calibrations', icon: <Gauge className="w-5 h-5" /> },
  { id: 'compliance', label: 'Compliance & Certification', description: 'All certifications, compliance rates, and expiring certificates', icon: <Shield className="w-5 h-5" /> },
  { id: 'financial', label: 'Financial Summary', description: 'Total tool value, expenditures, and investment overview', icon: <DollarSign className="w-5 h-5" /> },
  { id: 'comprehensive', label: 'Comprehensive Report', description: 'Full report: inventory, assignments, technicians, financials, approvals, history', icon: <BarChart3 className="w-5 h-5" /> },
  { id: 'history', label: 'Audit Trail', description: 'Complete history of all tool movements and changes', icon: <Calendar className="w-5 h-5" /> },
]

export default function ReportsPage() {
  const { org, workerLabel, workerLabelPlural } = useOrgContext()
  const [selected, setSelected] = useState<ReportType | null>(null)
  const [dateFrom, setDateFrom] = useState('')
  const [dateTo, setDateTo] = useState('')
  const [generating, setGenerating] = useState<'pdf' | 'csv' | 'excel' | null>(null)
  const [data, setData] = useState<ReportData | null>(null)
  const [loadingData, setLoadingData] = useState(false)
  const generateRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!selected) return
    if (data) return

    const fetchData = async () => {
      setLoadingData(true)
      const supabase = createClient()

      const safe = async <T,>(q: PromiseLike<{ data: T | null; error: any }>): Promise<T> => {
        try {
          const { data } = await q
          return (data || []) as T
        } catch {
          return [] as T
        }
      }

      const [tools, issues, history, technicians, approvals, certifications, maintenanceSchedules] = await Promise.all([
        safe<Tool[]>(supabase.from('tools').select('*')),
        safe<ToolIssue[]>(supabase.from('tool_issues').select('*')),
        safe<ToolHistory[]>(supabase.from('tool_history').select('*').order('timestamp', { ascending: false })),
        safe<Technician[]>(supabase.from('technicians').select('*')),
        safe<ApprovalWorkflow[]>(supabase.from('approval_workflows').select('*')),
        safe<Certification[]>(supabase.from('certifications').select('*').order('expiry_date', { ascending: true })),
        safe<MaintenanceSchedule[]>(supabase.from('maintenance_schedules').select('*').order('scheduled_date', { ascending: true })),
      ])

      setData({ tools, issues, history, technicians, approvals, certifications, maintenanceSchedules })
      setLoadingData(false)
    }

    fetchData()
  }, [selected, data])

  useEffect(() => {
    if (selected && generateRef.current) {
      setTimeout(() => {
        generateRef.current?.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
      }, 100)
    }
  }, [selected])

  const handleGenerate = async (format: 'pdf' | 'csv' | 'excel') => {
    if (!selected || !data) return
    setGenerating(format)

    await new Promise((r) => setTimeout(r, 100))

    try {
      const opts = {
        type: selected,
        dateFrom: dateFrom || undefined,
        dateTo: dateTo || undefined,
        data,
        branding: {
          orgName: org?.name,
          logoUrl: org?.logo_url,
          workerLabel,
          workerLabelPlural,
        },
      }

      if (format === 'pdf') {
        await generatePDF(opts)
      } else if (format === 'excel') {
        await generateExcel(opts)
      } else {
        generateCSV(opts)
      }
    } catch (e) {
      console.error('Report generation failed:', e)
    }

    setGenerating(null)
  }

  const selectedReport = reportTypes.find((r) => r.id === selected)

  return (
    <div className="p-4 md:p-6 max-w-[1600px] mx-auto space-y-4 md:space-y-6">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Reports</h1>
        <p className="text-sm text-muted-foreground">Generate and export reports</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4">
        {reportTypes.map((report) => (
          <button
            key={report.id}
            onClick={() => setSelected(report.id)}
            className={cn(
              'bg-card border rounded-xl p-3 md:p-5 text-left hover:border-primary/30 transition-colors',
              selected === report.id ? 'border-primary ring-1 ring-primary/20' : 'border-border'
            )}
          >
            <div className="w-8 h-8 md:w-10 md:h-10 rounded-lg bg-muted flex items-center justify-center text-muted-foreground mb-2 md:mb-3">
              {report.icon}
            </div>
            <h3 className="font-medium text-xs md:text-sm">{report.label}</h3>
            <p className="text-[10px] md:text-xs text-muted-foreground mt-1 line-clamp-2">{report.description}</p>
          </button>
        ))}
      </div>

      {selected && (
        <div ref={generateRef} className="bg-card border border-border rounded-xl p-4 md:p-6">
          <h3 className="font-semibold text-sm md:text-base mb-4">
            Generate {selectedReport?.label}
          </h3>

          {loadingData ? (
            <div className="flex items-center gap-2 text-sm text-muted-foreground py-4">
              <Loader2 className="w-4 h-4 animate-spin" />
              Loading data...
            </div>
          ) : (
            <>
              {/* Date filters */}
              <div className="grid grid-cols-2 gap-3 mb-4">
                <div>
                  <label className="block text-xs font-medium text-muted-foreground mb-1.5">From</label>
                  <input
                    type="date"
                    value={dateFrom}
                    onChange={(e) => setDateFrom(e.target.value)}
                    className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-muted-foreground mb-1.5">To</label>
                  <input
                    type="date"
                    value={dateTo}
                    onChange={(e) => setDateTo(e.target.value)}
                    className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm"
                  />
                </div>
              </div>

              {/* Generate buttons */}
              <div className="flex flex-col sm:flex-row gap-2 sm:gap-3">
                <button
                  onClick={() => handleGenerate('pdf')}
                  disabled={generating !== null}
                  className="flex items-center justify-center gap-2 h-10 sm:h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50"
                >
                  {generating === 'pdf' ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4" />}
                  Generate PDF
                </button>
                <button
                  onClick={() => handleGenerate('excel')}
                  disabled={generating !== null}
                  className="flex items-center justify-center gap-2 h-10 sm:h-9 px-4 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 transition-colors disabled:opacity-50"
                >
                  {generating === 'excel' ? <Loader2 className="w-4 h-4 animate-spin" /> : <FileText className="w-4 h-4" />}
                  Export Excel
                </button>
                <button
                  onClick={() => handleGenerate('csv')}
                  disabled={generating !== null}
                  className="flex items-center justify-center gap-2 h-10 sm:h-9 px-4 border border-input rounded-lg text-sm font-medium hover:bg-accent transition-colors disabled:opacity-50"
                >
                  {generating === 'csv' ? <Loader2 className="w-4 h-4 animate-spin" /> : <FileText className="w-4 h-4" />}
                  Export CSV
                </button>
              </div>

              {data && (
                <div className="mt-4 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                  <span>{data.tools.length} tools</span>
                  <span>{data.technicians.length} technicians</span>
                  <span>{data.issues.length} issues</span>
                  <span>{data.certifications.length} certifications</span>
                  <span>{data.maintenanceSchedules.length} schedules</span>
                  <span>{data.history.length} history records</span>
                </div>
              )}
            </>
          )}
        </div>
      )}
    </div>
  )
}
