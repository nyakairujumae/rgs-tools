'use client'

import { useState, useEffect } from 'react'
import { X, Loader2, Search } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { assignTool, unassignTool } from '@/lib/supabase/actions'
import { useAuth } from '@/hooks/use-auth'
import type { Tool, Technician } from '@/lib/types/database'

interface AssignToolDialogProps {
  tool: Tool
  open: boolean
  onClose: () => void
  onSuccess: (updatedTool: Tool) => void
}

export function AssignToolDialog({ tool, open, onClose, onSuccess }: AssignToolDialogProps) {
  const { profile } = useAuth()
  const [technicians, setTechnicians] = useState<Technician[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')
  const [selectedTechId, setSelectedTechId] = useState<string | null>(null)

  useEffect(() => {
    if (!open) return
    const fetch = async () => {
      const supabase = createClient()
      const { data } = await supabase
        .from('technicians')
        .select('*')
        .eq('status', 'Active')
        .order('name')
      setTechnicians(data || [])
      setLoading(false)
    }
    fetch()
  }, [open])

  const filtered = search
    ? technicians.filter(
        (t) =>
          t.name.toLowerCase().includes(search.toLowerCase()) ||
          t.email?.toLowerCase().includes(search.toLowerCase()) ||
          t.employee_id?.toLowerCase().includes(search.toLowerCase())
      )
    : technicians

  const handleAssign = async () => {
    if (!selectedTechId) return
    setSaving(true)

    const tech = technicians.find((t) => t.id === selectedTechId)
    if (!tech) return

    const userId = tech.user_id || tech.id
    const success = await assignTool(
      tool.id,
      tool.name,
      userId,
      tech.name,
      profile?.full_name || 'Admin'
    )

    setSaving(false)

    if (success) {
      onSuccess({ ...tool, status: 'In Use', assigned_to: userId })
    }
  }

  const handleUnassign = async () => {
    setSaving(true)
    const success = await unassignTool(tool.id, tool.name, profile?.full_name || 'Admin')
    setSaving(false)

    if (success) {
      onSuccess({ ...tool, status: 'Available', assigned_to: undefined })
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[480px] max-h-[70vh] overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">
            {tool.assigned_to ? 'Reassign' : 'Assign'} Tool
          </h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-4">
          {/* Current assignment */}
          <div className="bg-muted/50 rounded-lg p-3 mb-4">
            <p className="text-sm font-medium">{tool.name}</p>
            <p className="text-xs text-muted-foreground mt-0.5">
              {tool.assigned_to ? `Currently assigned` : 'Not assigned'}
            </p>
          </div>

          {/* Unassign button if currently assigned */}
          {tool.assigned_to && (
            <button
              onClick={handleUnassign}
              disabled={saving}
              className="w-full mb-4 h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors flex items-center justify-center gap-2"
            >
              {saving ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
              Return to Inventory
            </button>
          )}

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
          <div className="max-h-[300px] overflow-y-auto space-y-1">
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
        </div>

        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button type="button" onClick={onClose} className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors">
            Cancel
          </button>
          <button
            onClick={handleAssign}
            disabled={saving || !selectedTechId}
            className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors flex items-center gap-2"
          >
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            Assign
          </button>
        </div>
      </div>
    </div>
  )
}
