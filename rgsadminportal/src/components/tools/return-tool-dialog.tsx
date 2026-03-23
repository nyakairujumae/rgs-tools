'use client'

import { useState, useEffect } from 'react'
import { X, Loader2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useAuth } from '@/hooks/use-auth'
import type { Tool, Technician } from '@/lib/types/database'

const CONDITIONS = ['Excellent', 'Good', 'Fair', 'Poor', 'Needs Repair'] as const

interface ReturnToolDialogProps {
  tool: Tool
  open: boolean
  onClose: () => void
  onSuccess: (updatedTool: Tool) => void
}

export function ReturnToolDialog({ tool, open, onClose, onSuccess }: ReturnToolDialogProps) {
  const { profile } = useAuth()
  const [saving, setSaving] = useState(false)
  const [condition, setCondition] = useState<string>(tool.condition || 'Good')
  const [notes, setNotes] = useState('')
  const [currentHolder, setCurrentHolder] = useState<string>('Unknown')

  useEffect(() => {
    if (!open || !tool.assigned_to) return
    const supabase = createClient()
    supabase
      .from('technicians')
      .select('name')
      .or(`user_id.eq.${tool.assigned_to},id.eq.${tool.assigned_to}`)
      .limit(1)
      .maybeSingle()
      .then(({ data }) => {
        if (data?.name) setCurrentHolder(data.name)
      })
  }, [open, tool.assigned_to])

  const handleReturn = async () => {
    setSaving(true)
    try {
      const supabase = createClient()

      const updateData: Record<string, unknown> = {
        status: 'Available',
        assigned_to: null,
        condition,
        updated_at: new Date().toISOString(),
      }

      const { error } = await supabase
        .from('tools')
        .update(updateData)
        .eq('id', tool.id)

      if (error) throw error

      try {
        await supabase
          .from('assignments')
          .update({ status: 'Returned' })
          .eq('tool_id', tool.id)
          .eq('status', 'Active')
      } catch {}

      const description = notes
        ? `${tool.name} returned by ${currentHolder}. Condition: ${condition}. Notes: ${notes}`
        : `${tool.name} returned by ${currentHolder}. Condition: ${condition}`

      await supabase.from('tool_history').insert({
        tool_id: tool.id,
        tool_name: tool.name,
        action: 'Returned',
        description,
        old_value: `Assigned to ${currentHolder}`,
        new_value: `Available (${condition})`,
        performed_by: profile?.full_name || 'Admin',
        performed_by_role: 'admin',
        timestamp: new Date().toISOString(),
      })

      onSuccess({ ...tool, status: 'Available', assigned_to: undefined, condition })
    } catch (e) {
      console.error('Return error:', e)
    } finally {
      setSaving(false)
    }
  }

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[10vh] bg-black/50">
      <div className="bg-card border border-border rounded-xl w-full max-w-[440px] overflow-hidden shadow-xl">
        <div className="flex items-center justify-between px-6 py-4 border-b border-border">
          <h2 className="text-lg font-semibold">Return Tool</h2>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-4 space-y-4">
          {/* Tool info */}
          <div className="bg-muted/50 rounded-lg p-3">
            <p className="text-sm font-medium">{tool.name}</p>
            <p className="text-xs text-muted-foreground mt-0.5">
              Currently held by {currentHolder}
            </p>
          </div>

          {/* Condition assessment */}
          <div>
            <label className="text-sm font-medium mb-2 block">Condition Assessment</label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {CONDITIONS.map((c) => (
                <button
                  key={c}
                  onClick={() => setCondition(c)}
                  className={`h-9 px-3 rounded-lg border text-sm font-medium transition-colors ${
                    condition === c
                      ? 'bg-primary/10 border-primary/30 text-primary'
                      : 'border-input hover:bg-accent'
                  }`}
                >
                  {c}
                </button>
              ))}
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="text-sm font-medium mb-1.5 block">Return Notes (Optional)</label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Any observations about the tool's condition..."
              className="w-full h-20 px-3 py-2 rounded-lg border border-input bg-background text-sm resize-none focus:outline-none focus:ring-2 focus:ring-ring"
            />
          </div>
        </div>

        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-border">
          <button type="button" onClick={onClose} className="h-9 px-4 rounded-lg border border-input text-sm font-medium hover:bg-accent transition-colors">
            Cancel
          </button>
          <button
            onClick={handleReturn}
            disabled={saving}
            className="h-9 px-4 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 disabled:opacity-50 transition-colors flex items-center gap-2"
          >
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            Return to Inventory
          </button>
        </div>
      </div>
    </div>
  )
}
