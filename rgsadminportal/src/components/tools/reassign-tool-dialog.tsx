'use client'

import { useState, useEffect } from 'react'
import { X, Loader2, Search, ArrowRight } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/use-auth'
import type { Tool, Technician } from '@/lib/types/database'

interface ReassignToolDialogProps {
  tool: Tool
  open: boolean
  onClose: () => void
  onSuccess: (updatedTool: Tool) => void
}

export function ReassignToolDialog({ tool, open, onClose, onSuccess }: ReassignToolDialogProps) {
  const { profile } = useAuth()
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')
  const [selectedTechId, setSelectedTechId] = useState<string | null>(null)
  const [notes, setNotes] = useState('')
  const [currentHolder, setCurrentHolder] = useState<string>('Unknown')

  useEffect(() => {
    if (!open) return
    const fetchData = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('technicians')
        .select('*')
        .eq('status', 'Active')
        .order('name')
      setTechnicians(data || [])

      if (tool.assigned_to) {
        const tech = (data || []).find(
          (t: Technician) => t.user_id === tool.assigned_to || t.id === tool.assigned_to
        )
        setCurrentHolder(tech?.name || 'Unknown')
      }
      setLoading(false)
    }
    fetchData()
  }, [open, tool.assigned_to])

  const filtered = search
    ? technicians.filter(
        (t) =>
          t.name.toLowerCase().includes(search.toLowerCase()) ||
          t.email?.toLowerCase().includes(search.toLowerCase()) ||
          t.employee_id?.toLowerCase().includes(search.toLowerCase())
      )
    : technicians

  const resolveUserId = async (tech: Technician): Promise<string> => {
    if (tech.user_id) return tech.user_id
    const supabase = createClient()

    if (tech.email) {
      const { data: approval } = await supabase
        .from('pending_user_approvals')
        .select('user_id')
        .eq('email', tech.email)
        .eq('status', 'approved')
        .order('submitted_at', { ascending: false })
        .limit(1)
        .maybeSingle()
      if (approval?.user_id) return approval.user_id

      const { data: user } = await supabase
        .from('users')
        .select('id')
        .ilike('email', tech.email)
        .maybeSingle()
      if (user?.id) return user.id
    }

    return tech.id
  }

  const handleReassign = async () => {
    if (!selectedTechId) return
    setSaving(true)

    try {
      const tech = technicians.find((t) => t.id === selectedTechId)
      if (!tech) return

      const userId = await resolveUserId(tech)
      const supabase = createClient()

      const { error } = await supabase
        .from('tools')
        .update({
          assigned_to: userId,
          status: 'In Use',
          updated_at: new Date().toISOString(),
        })
        .eq('id', tool.id)

      if (error) throw error

      try {
        await supabase.from('assignments').insert({
          tool_id: tool.id,
          technician_id: userId,
          assignment_type: 'Permanent',
          status: 'Active',
          assigned_date: new Date().toISOString().split('T')[0],
        })
      } catch {}

      const description = notes
        ? `${tool.name} reassigned from ${currentHolder} to ${tech.name}. Notes: ${notes}`
        : `${tool.name} reassigned from ${currentHolder} to ${tech.name}`

      await supabase.from('tool_history').insert({
        tool_id: tool.id,
        tool_name: tool.name,
        action: 'Reassigned',
        description,
        old_value: currentHolder,
        new_value: tech.name,
        performed_by: profile?.full_name || 'Admin',
        performed_by_role: 'admin',
        timestamp: new Date().toISOString(),
      })

      onSuccess({ ...tool, assigned_to: userId, status: 'In Use' })
    } catch (e) {
      console.error('Reassign error:', e)
    } finally {
      setSaving(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[480px] max-h-[75vh] overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">Reassign Tool</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-4 overflow-y-auto max-h-[calc(75vh-140px)]">
          {/* Tool info */}
          <div className="bg-muted/50 rounded-lg p-3 mb-4">
            <p className="text-sm font-medium">{tool.name}</p>
            <p className="text-xs text-muted-foreground mt-0.5">
              {tool.category} {tool.brand ? `· ${tool.brand}` : ''}
            </p>
          </div>

          {/* Current assignment */}
          <div className="bg-amber-500/10 border border-amber-500/20 rounded-lg p-3 mb-4">
            <p className="text-xs font-medium text-amber-700 dark:text-amber-400">Current Assignment</p>
            <p className="text-sm font-medium mt-0.5 flex items-center gap-2">
              {currentHolder}
              <ArrowRight className="w-3.5 h-3.5 text-muted-foreground" />
              <span className="text-muted-foreground">
                {selectedTechId
                  ? technicians.find((t) => t.id === selectedTechId)?.name
                  : 'Select new technician'}
              </span>
            </p>
          </div>

          {/* Search */}
          <div className="relative mb-3">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search technicians..."
              className="w-full h-9 pl-9 pr-3 rounded-lg border border-input bg-background text-sm focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>

          {/* Technician list */}
          <div className="max-h-[220px] overflow-y-auto space-y-1 mb-4">
            {loading ? (
              <div className="py-8 flex justify-center">
                <Loader2 className="w-5 h-5 animate-spin text-muted-foreground" />
              </div>
            ) : filtered.length === 0 ? (
              <p className="py-4 text-center text-sm text-muted-foreground">No technicians found</p>
            ) : (
              filtered.map((tech) => (
                <button
                  key={tech.id}
                  onClick={() => setSelectedTechId(tech.id === selectedTechId ? null : tech.id)}
                  className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors ${
                    selectedTechId === tech.id
                      ? 'bg-primary/10 border border-primary/30'
                      : 'hover:bg-accent border border-transparent'
                  }`}
                >
                  <div className="w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center text-sm font-semibold shrink-0">
                    {tech.name.charAt(0).toUpperCase()}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium truncate">{tech.name}</p>
                    <p className="text-xs text-muted-foreground truncate">
                      {tech.department || tech.email || 'No department'}
                    </p>
                  </div>
                </button>
              ))
            )}
          </div>

          {/* Notes */}
          <div>
            <label className="text-sm font-medium mb-1.5 block">Reassignment Notes (Optional)</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Add any notes about this reassignment..."
              className="w-full h-20 px-3 py-2 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>
        </div>

        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button type="button" onClick={onClose} className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors">
            Cancel
          </button>
          <button
            onClick={handleReassign}
            disabled={saving || !selectedTechId}
            className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
          >
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            Reassign
          </button>
        </div>
      </div>
    </div>
  )
}
