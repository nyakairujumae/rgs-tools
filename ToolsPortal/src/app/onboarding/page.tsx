'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { AlertCircle, Loader2, ChevronLeft } from 'lucide-react'

// ─── Industry presets ────────────────────────────────────────────────────────
const INDUSTRY_PRESETS = [
  { key: 'hvac', label: 'HVAC', workerLabel: 'Technician', workerLabelPlural: 'Technicians' },
  { key: 'electrical', label: 'Electrical', workerLabel: 'Electrician', workerLabelPlural: 'Electricians' },
  { key: 'fm', label: 'Facilities Management', workerLabel: 'Operative', workerLabelPlural: 'Operatives' },
  { key: 'construction', label: 'Construction', workerLabel: 'Site Worker', workerLabelPlural: 'Site Workers' },
  { key: 'general', label: 'General', workerLabel: 'Worker', workerLabelPlural: 'Workers' },
]

function toSlug(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 50)
}

interface FormState {
  companyName: string
  companySlug: string
  industry: string
  workerLabel: string
  workerLabelPlural: string
}

const TOTAL_STEPS = 3

export default function OnboardingPage() {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const [form, setForm] = useState<FormState>({
    companyName: '',
    companySlug: '',
    industry: '',
    workerLabel: 'Technician',
    workerLabelPlural: 'Technicians',
  })

  const set = (field: keyof FormState, value: string) =>
    setForm((prev) => ({ ...prev, [field]: value }))

  const selectIndustry = (preset: typeof INDUSTRY_PRESETS[number]) => {
    setForm((prev) => ({
      ...prev,
      industry: preset.key,
      workerLabel: preset.workerLabel,
      workerLabelPlural: preset.workerLabelPlural,
    }))
  }

  const canAdvance = (): boolean => {
    if (step === 1) return form.companyName.trim().length > 0 && form.companySlug.trim().length > 0
    if (step === 2) return form.industry.length > 0
    if (step === 3) return form.workerLabel.trim().length > 0 && form.workerLabelPlural.trim().length > 0
    return false
  }

  const handleSubmit = async () => {
    setError('')
    setLoading(true)

    const supabase = createClient()

    try {
      const { error: rpcError } = await supabase.rpc('create_organization_and_assign_user', {
        p_name: form.companyName.trim(),
        p_slug: form.companySlug.trim(),
        p_industry: form.industry,
        p_worker_label: form.workerLabel.trim(),
        p_worker_label_plural: form.workerLabelPlural.trim(),
      })

      if (rpcError) {
        setError(rpcError.message)
        setLoading(false)
        return
      }

      router.push('/dashboard')
    } catch {
      setError('Something went wrong. Please try again.')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-[460px]">
        {/* Logo */}
        <div className="flex items-center justify-center gap-2.5 mb-8">
          <Image src="/icon.png" alt="Logo" width={32} height={32} className="rounded-xl" />
          <span className="text-lg font-semibold tracking-tight">Tools Admin Portal</span>
        </div>

        {/* Progress */}
        <div className="flex items-center gap-1.5 mb-6">
          {Array.from({ length: TOTAL_STEPS }).map((_, i) => (
            <div
              key={i}
              className={`h-1 flex-1 rounded-full transition-colors ${
                i + 1 <= step ? 'bg-primary' : 'bg-border'
              }`}
            />
          ))}
        </div>

        <div className="bg-card border border-border rounded-xl p-8">
          <p className="text-xs text-muted-foreground mb-1">Step {step} of {TOTAL_STEPS}</p>

          {/* ── Step 1: Company ─────────────────────────────────────────── */}
          {step === 1 && (
            <>
              <h1 className="text-lg font-semibold mb-1">Set up your company</h1>
              <p className="text-sm text-muted-foreground mb-5">Almost there — just a few details to finish setting up.</p>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-1.5">Company name</label>
                  <input
                    type="text"
                    value={form.companyName}
                    onChange={(e) => {
                      const name = e.target.value
                      set('companyName', name)
                      set('companySlug', toSlug(name))
                    }}
                    placeholder="Acme Services Ltd"
                    autoFocus
                    className={inputClass}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1.5">URL slug</label>
                  <div className="flex rounded-lg border border-input overflow-hidden focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-1">
                    <span className="flex items-center px-3 bg-muted text-muted-foreground text-sm border-r border-input select-none whitespace-nowrap">
                      portal/
                    </span>
                    <input
                      type="text"
                      value={form.companySlug}
                      onChange={(e) => set('companySlug', toSlug(e.target.value))}
                      placeholder="acme-services"
                      className="flex-1 h-10 px-3 bg-background text-sm focus:outline-none"
                    />
                  </div>
                </div>
              </div>
            </>
          )}

          {/* ── Step 2: Industry ─────────────────────────────────────────── */}
          {step === 2 && (
            <>
              <h1 className="text-lg font-semibold mb-1">Your industry</h1>
              <p className="text-sm text-muted-foreground mb-5">
                We&apos;ll pre-fill your departments and tool categories based on this.
              </p>
              <div className="grid grid-cols-1 gap-2">
                {INDUSTRY_PRESETS.map((preset) => (
                  <button
                    key={preset.key}
                    type="button"
                    onClick={() => selectIndustry(preset)}
                    className={`flex items-center justify-between px-4 py-3 rounded-lg border text-sm font-medium transition-colors text-left ${
                      form.industry === preset.key
                        ? 'border-primary bg-primary/10 text-primary'
                        : 'border-border hover:border-primary/50 hover:bg-muted/50'
                    }`}
                  >
                    <span>{preset.label}</span>
                    <span className="text-xs text-muted-foreground font-normal">
                      Team member: {preset.workerLabel}
                    </span>
                  </button>
                ))}
              </div>
            </>
          )}

          {/* ── Step 3: Team label ───────────────────────────────────────── */}
          {step === 3 && (
            <>
              <h1 className="text-lg font-semibold mb-1">What do you call your team members?</h1>
              <p className="text-sm text-muted-foreground mb-5">
                Pre-filled from your industry — change it if you prefer different terminology.
              </p>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-1.5">Singular (e.g. Technician)</label>
                  <input
                    type="text"
                    value={form.workerLabel}
                    onChange={(e) => set('workerLabel', e.target.value)}
                    placeholder="Technician"
                    autoFocus
                    className={inputClass}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1.5">Plural (e.g. Technicians)</label>
                  <input
                    type="text"
                    value={form.workerLabelPlural}
                    onChange={(e) => set('workerLabelPlural', e.target.value)}
                    placeholder="Technicians"
                    className={inputClass}
                  />
                </div>
              </div>
            </>
          )}

          {/* Error */}
          {error && (
            <div className="flex items-start gap-2 bg-destructive/10 text-destructive rounded-lg p-3 mt-4 text-sm">
              <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Actions */}
          <div className="flex items-center gap-3 mt-6">
            {step > 1 && (
              <button
                type="button"
                onClick={() => { setError(''); setStep((s) => s - 1) }}
                disabled={loading}
                className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50"
              >
                <ChevronLeft className="w-4 h-4" />
                Back
              </button>
            )}
            <button
              type="button"
              onClick={step < TOTAL_STEPS ? () => { setError(''); setStep((s) => s + 1) } : handleSubmit}
              disabled={!canAdvance() || loading}
              className="ml-auto flex items-center justify-center gap-2 bg-primary text-primary-foreground px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed min-w-[100px]"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Setting up...
                </>
              ) : step < TOTAL_STEPS ? (
                'Continue'
              ) : (
                'Finish setup'
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

const inputClass =
  'w-full h-10 px-3 rounded-lg border border-input bg-background text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1'
