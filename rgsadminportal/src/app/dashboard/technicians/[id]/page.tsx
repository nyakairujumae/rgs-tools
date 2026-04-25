'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { formatAED } from '@/lib/utils'
import { StatusBadge } from '@/components/shared/status-badge'
import {
  ArrowLeft,
  Mail,
  Phone,
  Building2,
  Hash,
  Camera,
  Loader2,
  Wrench,
  Calendar,
  Package,
} from 'lucide-react'
import type { Technician, Tool } from '@/lib/types/database'

export default function TechnicianDetailPage() {
  const { id } = useParams()
  const router = useRouter()
  const [technician, setTechnician] = useState<Technician | null>(null)
  const [tools, setTools] = useState<Tool[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const load = async () => {
      const supabase = createClient()

      const { data: techData } = await supabase
        .from('technicians')
        .select('*')
        .eq('id', id)
        .single()

      if (!techData) {
        setLoading(false)
        return
      }

      setTechnician(techData)

      // Tools can be assigned by user_id OR by technician record id
      const assignedIds = [techData.user_id, techData.id].filter((v): v is string => !!v)
      if (assignedIds.length > 0) {
        const { data: toolsData } = await supabase
          .from('tools')
          .select('*')
          .in('assigned_to', assignedIds)
          .order('name')
        setTools(toolsData || [])
      }

      setLoading(false)
    }
    load()
  }, [id])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
      </div>
    )
  }

  if (!technician) {
    return (
      <div className="p-6 text-center">
        <p className="text-muted-foreground">Technician not found</p>
        <Link href="/dashboard/technicians" className="text-primary text-sm hover:underline mt-2 inline-block">
          Back to technicians
        </Link>
      </div>
    )
  }

  return (
    <div className="p-6 max-w-[1200px] mx-auto space-y-6">
      {/* Back */}
      <button
        onClick={() => router.back()}
        className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
      >
        <ArrowLeft className="w-4 h-4" /> Back to technicians
      </button>

      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 rounded-full bg-primary/10 text-primary flex items-center justify-center text-2xl font-semibold shrink-0">
          {technician.name.charAt(0).toUpperCase()}
        </div>
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">{technician.name}</h1>
          <div className="flex items-center gap-3 mt-1">
            <StatusBadge status={technician.status} />
            {technician.department && (
              <span className="text-sm text-muted-foreground">{technician.department}</span>
            )}
          </div>
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-6 lg:items-start">
        {/* Technician info */}
        <div className="bg-card border border-border rounded-xl">
          <div className="px-5 py-4 border-b border-border">
            <h2 className="text-sm font-semibold">Details</h2>
          </div>
          <div className="p-5 space-y-4">
            {[
              { icon: <Mail className="w-4 h-4" />, label: 'Email', value: technician.email || '-' },
              { icon: <Phone className="w-4 h-4" />, label: 'Phone', value: technician.phone || '-' },
              { icon: <Building2 className="w-4 h-4" />, label: 'Department', value: technician.department || '-' },
              { icon: <Hash className="w-4 h-4" />, label: 'Employee ID', value: technician.employee_id || '-' },
              { icon: <Calendar className="w-4 h-4" />, label: 'Hire Date', value: technician.hire_date ? new Date(technician.hire_date).toLocaleDateString() : '-' },
              { icon: <Wrench className="w-4 h-4" />, label: 'Tools Assigned', value: String(tools.length) },
            ].map((row) => (
              <div key={row.label} className="flex items-start gap-3">
                <div className="w-8 h-8 rounded-lg bg-muted flex items-center justify-center text-muted-foreground shrink-0">
                  {row.icon}
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">{row.label}</p>
                  <p className="text-sm font-medium mt-0.5">{row.value}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Assigned tools */}
        <div className="lg:col-span-2 bg-card border border-border rounded-xl">
          <div className="px-5 py-4 border-b border-border flex items-center justify-between">
            <h2 className="text-sm font-semibold">Assigned Tools</h2>
            <span className="text-xs text-muted-foreground">{tools.length} {tools.length === 1 ? 'tool' : 'tools'}</span>
          </div>

          {tools.length === 0 ? (
            <div className="py-12 text-center text-sm text-muted-foreground">
              <Package className="w-8 h-8 mx-auto mb-2 opacity-30" />
              No tools assigned to this technician
            </div>
          ) : (
            <div className="divide-y divide-border">
              {tools.map((tool) => (
                <Link
                  key={tool.id}
                  href={`/dashboard/tools/${tool.id}`}
                  className="flex items-center gap-4 px-5 py-3 hover:bg-muted/30 transition-colors"
                >
                  {/* Thumbnail */}
                  <div className="w-10 h-10 rounded-lg overflow-hidden shrink-0">
                    {tool.image_path ? (
                      <Image
                        src={tool.image_path}
                        alt={tool.name}
                        width={40}
                        height={40}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full bg-muted/40 flex items-center justify-center">
                        <Camera className="w-4 h-4 text-muted-foreground/30" />
                      </div>
                    )}
                  </div>

                  {/* Name + category */}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{tool.name}</p>
                    <p className="text-xs text-muted-foreground truncate">{tool.category}{tool.brand ? ` · ${tool.brand}` : ''}</p>
                  </div>

                  {/* Serial */}
                  {tool.serial_number && (
                    <span className="text-xs text-muted-foreground font-mono hidden sm:block shrink-0">{tool.serial_number}</span>
                  )}

                  {/* Value */}
                  {(tool.current_value || tool.purchase_price) && (
                    <span className="text-xs text-muted-foreground hidden md:block shrink-0">
                      {formatAED(tool.current_value || tool.purchase_price)}
                    </span>
                  )}

                  {/* Status */}
                  <div className="shrink-0">
                    <StatusBadge status={tool.status} />
                  </div>
                </Link>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
