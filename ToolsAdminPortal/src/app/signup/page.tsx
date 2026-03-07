'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { Eye, EyeOff, AlertCircle, Loader2, ChevronLeft } from 'lucide-react'

// ─── Industry presets (mirrors Flutter app) ────────────────────────────────
const INDUSTRY_PRESETS = [
  { key: 'hvac', label: 'HVAC', workerLabel: 'Technician', workerLabelPlural: 'Technicians' },
  { key: 'electrical', label: 'Electrical', workerLabel: 'Electrician', workerLabelPlural: 'Electricians' },
  { key: 'fm', label: 'Facilities Management', workerLabel: 'Operative', workerLabelPlural: 'Operatives' },
  { key: 'construction', label: 'Construction', workerLabel: 'Site Worker', workerLabelPlural: 'Site Workers' },
  { key: 'general', label: 'General', workerLabel: 'Worker', workerLabelPlural: 'Workers' },
]

// ─── Slug generation ────────────────────────────────────────────────────────
function toSlug(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .slice(0, 50)
}

// ─── Types ───────────────────────────────────────────────────────────────────
interface FormState {
  // Step 1
  fullName: string
  email: string
  password: string
  // Step 2
  companyName: string
  companySlug: string
  // Step 3
  industry: string
  // Step 4
  workerLabel: string
  workerLabelPlural: string
}

const TOTAL_STEPS = 4

export default function SignupPage() {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [showPassword, setShowPassword] = useState(false)

  const [form, setForm] = useState<FormState>({
    fullName: '',
    email: '',
    password: '',
    companyName: '',
    companySlug: '',
    industry: '',
    workerLabel: 'Technician',
    workerLabelPlural: 'Technicians',
  })

  const set = (field: keyof FormState, value: string) =>
    setForm((prev) => ({ ...prev, [field]: value }))

  // ── Step validation ──────────────────────────────────────────────────────
  const canAdvance = (): boolean => {
    if (step === 1) return form.fullName.trim().length > 0 && form.email.trim().length > 0 && form.password.length >= 8
    if (step === 2) return form.companyName.trim().length > 0 && form.companySlug.trim().length > 0
    if (step === 3) return form.industry.length > 0
    if (step === 4) return form.workerLabel.trim().length > 0 && form.workerLabelPlural.trim().length > 0
    return false
  }

  const advance = () => {
    setError('')
    setStep((s) => s + 1)
  }

  const back = () => {
    setError('')
    setStep((s) => s - 1)
  }

  // ── Industry selection ───────────────────────────────────────────────────
  const selectIndustry = (preset: typeof INDUSTRY_PRESETS[number]) => {
    setForm((prev) => ({
      ...prev,
      industry: preset.key,
      workerLabel: preset.workerLabel,
      workerLabelPlural: preset.workerLabelPlural,
    }))
  }

  // ── Submit ───────────────────────────────────────────────────────────────
  const handleSubmit = async () => {
    setError('')
    setLoading(true)

    const supabase = createClient()

    try {
      // 1. Create auth account
      const { error: signUpError } = await supabase.auth.signUp({
        email: form.email.trim(),
        password: form.password,
        options: {
          data: { full_name: form.fullName.trim() },
        },
      })

      if (signUpError) {
        setError(signUpError.message)
        setLoading(false)
        return
      }

      // 2. Call RPC to create org and assign user as admin
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

        {/* Card */}
        <div className="bg-card border border-border rounded-xl p-8">
          {/* Step label */}
          <p className="text-xs text-muted-foreground mb-1">Step {step} of {TOTAL_STEPS}</p>

          {/* ── Step 1: Your details ─────────────────────────────────────── */}
          {step === 1 && (
            <>
              <h1 className="text-lg font-semibold mb-5">Create your account</h1>
              <div className="space-y-4">
                <Field label="Full name">
                  <input
                    type="text"
                    value={form.fullName}
                    onChange={(e) => set('fullName', e.target.value)}
                    placeholder="Jane Smith"
                    autoFocus
                    className={inputClass}
                  />
                </Field>
                <Field label="Work email">
                  <input
                    type="email"
                    value={form.email}
                    onChange={(e) => set('email', e.target.value)}
                    placeholder="jane@company.com"
                    className={inputClass}
                  />
                </Field>
                <Field label="Password">
                  <div className="relative">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      value={form.password}
                      onChange={(e) => set('password', e.target.value)}
                      placeholder="At least 8 characters"
                      className={`${inputClass} pr-10`}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                    >
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </Field>
              </div>
            </>
          )}

          {/* ── Step 2: Company ──────────────────────────────────────────── */}
          {step === 2 && (
            <>
              <h1 className="text-lg font-semibold mb-5">Your company</h1>
              <div className="space-y-4">
                <Field label="Company name">
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
                </Field>
                <Field label="URL slug" hint="Used in your portal URL — auto-generated, you can edit it.">
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
                </Field>
              </div>
            </>
          )}

          {/* ── Step 3: Industry ─────────────────────────────────────────── */}
          {step === 3 && (
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

          {/* ── Step 4: Team label ───────────────────────────────────────── */}
          {step === 4 && (
            <>
              <h1 className="text-lg font-semibold mb-1">What do you call your team members?</h1>
              <p className="text-sm text-muted-foreground mb-5">
                Pre-filled from your industry — change it if you prefer different terminology.
              </p>
              <div className="space-y-4">
                <Field label="Singular (e.g. Technician)">
                  <input
                    type="text"
                    value={form.workerLabel}
                    onChange={(e) => set('workerLabel', e.target.value)}
                    placeholder="Technician"
                    autoFocus
                    className={inputClass}
                  />
                </Field>
                <Field label="Plural (e.g. Technicians)">
                  <input
                    type="text"
                    value={form.workerLabelPlural}
                    onChange={(e) => set('workerLabelPlural', e.target.value)}
                    placeholder="Technicians"
                    className={inputClass}
                  />
                </Field>
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
                onClick={back}
                disabled={loading}
                className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50"
              >
                <ChevronLeft className="w-4 h-4" />
                Back
              </button>
            )}
            <button
              type="button"
              onClick={step < TOTAL_STEPS ? advance : handleSubmit}
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
                'Create account'
              )}
            </button>
          </div>
        </div>

        <p className="text-center text-xs text-muted-foreground mt-5">
          Already have an account?{' '}
          <Link href="/login" className="text-primary hover:underline">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  )
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
const inputClass =
  'w-full h-10 px-3 rounded-lg border border-input bg-background text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1'

function Field({
  label,
  hint,
  children,
}: {
  label: string
  hint?: string
  children: React.ReactNode
}) {
  return (
    <div>
      <label className="block text-sm font-medium mb-1.5">{label}</label>
      {children}
      {hint && <p className="text-xs text-muted-foreground mt-1">{hint}</p>}
    </div>
  )
}
