'use client'

import { useEffect, useState, useMemo } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatusBadge } from '@/components/shared/status-badge'
import { formatDate, cn } from '@/lib/utils'
import { Loader2, Shield, AlertTriangle, CheckCircle, XCircle } from 'lucide-react'
import type { Certification } from '@/lib/types/database'

export default function CompliancePage() {
  const [certs, setCerts] = useState<Certification[]>([])
  const [loading, setLoading] = useState(true)
  const [tab, setTab] = useState('all')

  useEffect(() => {
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase.from('certifications').select('*').order('expiry_date', { ascending: true })
      setCerts(data || [])
      setLoading(false)
    }
    fetch()
  }, [])

  const counts = useMemo(() => ({
    all: certs.length,
    Valid: certs.filter((c) => c.status === 'Valid').length,
    'Expiring Soon': certs.filter((c) => c.status === 'Expiring Soon').length,
    Expired: certs.filter((c) => c.status === 'Expired').length,
  }), [certs])

  const filtered = tab === 'all' ? certs : certs.filter((c) => c.status === tab)

  if (loading) {
    return <div className="flex items-center justify-center h-full"><Loader2 className="w-6 h-6 animate-spin text-muted-foreground" /></div>
  }

  return (
    <div className="p-6 max-w-[1600px] mx-auto space-y-4">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Compliance</h1>
        <p className="text-sm text-muted-foreground">{certs.length} certifications tracked</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-emerald-500/10 flex items-center justify-center">
            <CheckCircle className="w-5 h-5 text-emerald-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Valid}</p>
            <p className="text-xs text-muted-foreground">Valid</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-amber-500/10 flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts['Expiring Soon']}</p>
            <p className="text-xs text-muted-foreground">Expiring Soon</p>
          </div>
        </div>
        <div className="bg-card border border-border rounded-xl p-4 flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-red-500/10 flex items-center justify-center">
            <XCircle className="w-5 h-5 text-red-500" />
          </div>
          <div>
            <p className="text-2xl font-semibold">{counts.Expired}</p>
            <p className="text-xs text-muted-foreground">Expired</p>
          </div>
        </div>
      </div>

      <div className="bg-card border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border bg-muted/50">
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Tool</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Type</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Number</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Authority</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Issue Date</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Expiry Date</th>
              <th className="px-4 py-3 text-left font-medium text-muted-foreground">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {filtered.length === 0 ? (
              <tr><td colSpan={7} className="py-12 text-center text-muted-foreground">No certifications</td></tr>
            ) : (
              filtered.map((c) => (
                <tr key={c.id} className="hover:bg-muted/30 transition-colors">
                  <td className="px-4 py-3 font-medium">{c.tool_name}</td>
                  <td className="px-4 py-3 text-muted-foreground">{c.certification_type}</td>
                  <td className="px-4 py-3 text-muted-foreground font-mono text-xs">{c.certification_number}</td>
                  <td className="px-4 py-3 text-muted-foreground">{c.issuing_authority}</td>
                  <td className="px-4 py-3 text-muted-foreground">{formatDate(c.issue_date)}</td>
                  <td className="px-4 py-3 text-muted-foreground">{formatDate(c.expiry_date)}</td>
                  <td className="px-4 py-3"><StatusBadge status={c.status} /></td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
