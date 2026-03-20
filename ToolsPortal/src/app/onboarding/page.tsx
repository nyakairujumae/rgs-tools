'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter } from 'next/navigation'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import {
  AlertCircle, Loader2, ChevronLeft, Plus, CheckCircle2, Mail, UserPlus, Upload, ImageIcon
} from 'lucide-react'
import { inviteAdmin, addTechnician, fetchAdminPositions } from '@/lib/supabase/actions'
import type { AdminPosition } from '@/lib/types/database'

// ─── Industry presets ────────────────────────────────────────────────────────
const INDUSTRY_PRESETS = [
  { key: 'hvac', label: 'HVAC', workerLabel: 'Technician', workerLabelPlural: 'Technicians' },
  { key: 'electrical', label: 'Electrical', workerLabel: 'Electrician', workerLabelPlural: 'Electricians' },
  { key: 'fm', label: 'Facilities Management', workerLabel: 'Operative', workerLabelPlural: 'Operatives' },
  { key: 'construction', label: 'Construction', workerLabel: 'Site Worker', workerLabelPlural: 'Site Workers' },
  { key: 'general', label: 'General', workerLabel: 'Worker', workerLabelPlural: 'Workers' },
]

function toSlug(name: string): string {
  return name.toLowerCase().trim().replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, '-').replace(/-+/g, '-').slice(0, 50)
}

interface FormState {
  companyName: string
  companySlug: string
  industry: string
  workerLabel: string
  workerLabelPlural: string
}

interface InvitedAdmin { email: string; name: string; positionId: string; status: 'pending' | 'sent' | 'error'; error?: string }
interface AddedMember { name: string; email: string; status: 'pending' | 'saved' | 'error'; error?: string }

// Steps: 1=Company, 2=Industry, 3=Logo, 4=Team label, 5=Invite admins, 6=Add members
const TOTAL_STEPS = 6

export default function OnboardingPage() {
  const router = useRouter()
  const [step, setStep] = useState(1)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [orgReady, setOrgReady] = useState(false)
  const [orgId, setOrgId] = useState<string | null>(null)

  const [form, setForm] = useState<FormState>({
    companyName: '',
    companySlug: '',
    industry: '',
    workerLabel: 'Technician',
    workerLabelPlural: 'Technicians',
  })

  // Step 3 — logo
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [logoPreview, setLogoPreview] = useState<string | null>(null)
  const [logoUploading, setLogoUploading] = useState(false)
  const [logoUrl, setLogoUrl] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Step 5 — admins
  const [positions, setPositions] = useState<AdminPosition[]>([])
  const [adminEmail, setAdminEmail] = useState('')
  const [adminName, setAdminName] = useState('')
  const [adminPositionId, setAdminPositionId] = useState('')
  const [invitedAdmins, setInvitedAdmins] = useState<InvitedAdmin[]>([])
  const [inviting, setInviting] = useState(false)

  // Step 6 — team members
  const [memberName, setMemberName] = useState('')
  const [memberEmail, setMemberEmail] = useState('')
  const [addedMembers, setAddedMembers] = useState<AddedMember[]>([])
  const [addingMember, setAddingMember] = useState(false)

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

  // Load positions once org is ready
  useEffect(() => {
    if (orgReady) {
      fetchAdminPositions().then((p) => {
        setPositions(p)
        if (p.length > 0) setAdminPositionId(p[0].id)
      })
    }
  }, [orgReady])

  const canAdvance = (): boolean => {
    if (step === 1) return form.companyName.trim().length > 0 && form.companySlug.trim().length > 0
    if (step === 2) return form.industry.length > 0
    if (step === 3) return true // logo is optional
    if (step === 4) return form.workerLabel.trim().length > 0 && form.workerLabelPlural.trim().length > 0
    return true
  }

  // ── Handle logo file pick ─────────────────────────────────────────────────
  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setLogoFile(file)
    setLogoPreview(URL.createObjectURL(file))
  }

  // ── Upload logo to Supabase storage ──────────────────────────────────────
  const uploadLogo = async (currentOrgId: string): Promise<string | null> => {
    if (!logoFile) return null
    setLogoUploading(true)
    try {
      const supabase = createClient()
      const ext = logoFile.name.split('.').pop()
      const path = `${currentOrgId}/logo.${ext}`
      const { error: uploadError } = await supabase.storage
        .from('organization-logos')
        .upload(path, logoFile, { upsert: true })
      if (uploadError) { setError(uploadError.message); return null }
      const { data: { publicUrl } } = supabase.storage.from('organization-logos').getPublicUrl(path)
      // Save logo_url to org record
      await supabase.from('organizations').update({ logo_url: publicUrl }).eq('id', currentOrgId)
      return publicUrl
    } finally {
      setLogoUploading(false)
    }
  }

  // ── Submit org (step 4 → 5) ───────────────────────────────────────────────
  const submitOrg = async () => {
    setError('')
    setLoading(true)
    const supabase = createClient()
    try {
      const { data, error: rpcError } = await supabase.rpc('create_organization_and_assign_user', {
        p_name: form.companyName.trim(),
        p_slug: form.companySlug.trim(),
        p_industry: form.industry,
        p_worker_label: form.workerLabel.trim(),
        p_worker_label_plural: form.workerLabelPlural.trim(),
      })
      if (rpcError) { setError(rpcError.message); setLoading(false); return }

      // Get the org id from the RPC result or re-fetch
      let createdOrgId: string | null = null
      if (data?.org_id) {
        createdOrgId = data.org_id
      } else {
        const { data: { user } } = await supabase.auth.getUser()
        if (user) {
          const { data: profile } = await supabase.from('users').select('organization_id').eq('id', user.id).single()
          createdOrgId = profile?.organization_id ?? null
        }
      }

      // Upload logo if one was selected
      if (createdOrgId && logoFile) {
        const url = await uploadLogo(createdOrgId)
        if (url) setLogoUrl(url)
      }

      setOrgId(createdOrgId)
      setOrgReady(true)
      setStep(5)
    } catch {
      setError('Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const advance = () => {
    setError('')
    if (step === 4) { submitOrg(); return }
    setStep((s) => s + 1)
  }

  const back = () => {
    setError('')
    if (step === 5) return // can't go back after org submitted
    setStep((s) => s - 1)
  }

  // ── Invite admin ──────────────────────────────────────────────────────────
  const handleInviteAdmin = async () => {
    if (!adminEmail.trim() || !adminName.trim()) return
    setInviting(true)
    const entry: InvitedAdmin = { email: adminEmail.trim(), name: adminName.trim(), positionId: adminPositionId, status: 'pending' }
    setInvitedAdmins((prev) => [...prev, entry])
    setAdminEmail('')
    setAdminName('')
    const result = await inviteAdmin(entry.email, entry.name, entry.positionId)
    setInvitedAdmins((prev) =>
      prev.map((a) => a.email === entry.email ? { ...a, status: result.error ? 'error' : 'sent', error: result.error } : a)
    )
    setInviting(false)
  }

  // ── Add team member ───────────────────────────────────────────────────────
  const handleAddMember = async () => {
    if (!memberName.trim()) return
    setAddingMember(true)
    const entry: AddedMember = { name: memberName.trim(), email: memberEmail.trim(), status: 'pending' }
    setAddedMembers((prev) => [...prev, entry])
    setMemberName('')
    setMemberEmail('')
    const result = await addTechnician({ name: entry.name, email: entry.email || undefined, status: 'Active' })
    setAddedMembers((prev) =>
      prev.map((m) => m.name === entry.name && m.email === entry.email
        ? { ...m, status: result ? 'saved' : 'error', error: result ? undefined : 'Failed to add' }
        : m
      )
    )
    setAddingMember(false)
  }

  const finish = () => router.push('/dashboard')

  // The logo to show in the header: uploaded preview > default icon
  const headerLogo = logoPreview || logoUrl || null

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-[480px]">
        {/* Logo */}
        <div className="flex items-center justify-center gap-2.5 mb-8">
          {headerLogo ? (
            <img src={headerLogo} alt="Company logo" className="w-8 h-8 rounded-xl object-cover" />
          ) : (
            <Image src="/icon.png" alt="Logo" width={32} height={32} className="rounded-xl" />
          )}
          <span className="text-lg font-semibold tracking-tight">
            {form.companyName || 'Tools Admin Portal'}
          </span>
        </div>

        {/* Progress */}
        <div className="flex items-center gap-1.5 mb-6">
          {Array.from({ length: TOTAL_STEPS }).map((_, i) => (
            <div
              key={i}
              className={`h-1 flex-1 rounded-full transition-colors ${i + 1 <= step ? 'bg-primary' : 'bg-border'}`}
            />
          ))}
        </div>

        <div className="bg-card border border-border rounded-xl p-8">
          <p className="text-xs text-muted-foreground mb-1">Step {step} of {TOTAL_STEPS}</p>

          {/* ── Step 1: Company ────────────────────────────────────────── */}
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
                    onChange={(e) => { set('companyName', e.target.value); set('companySlug', toSlug(e.target.value)) }}
                    placeholder="Acme Services Ltd"
                    autoFocus
                    className={inputClass}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1.5">URL slug</label>
                  <div className="flex rounded-lg border border-input overflow-hidden focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-1">
                    <span className="flex items-center px-3 bg-muted text-muted-foreground text-sm border-r border-input select-none whitespace-nowrap">portal/</span>
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

          {/* ── Step 2: Industry ───────────────────────────────────────── */}
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
                    <span className="text-xs text-muted-foreground font-normal">Team member: {preset.workerLabel}</span>
                  </button>
                ))}
              </div>
            </>
          )}

          {/* ── Step 3: Logo ───────────────────────────────────────────── */}
          {step === 3 && (
            <>
              <h1 className="text-lg font-semibold mb-1">Add your company logo</h1>
              <p className="text-sm text-muted-foreground mb-5">
                Shows in the sidebar and mobile app. You can skip this and add it later.
              </p>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/png,image/jpeg,image/svg+xml,image/webp"
                onChange={handleLogoChange}
                className="hidden"
              />
              <div className="flex flex-col items-center gap-4">
                {/* Preview circle */}
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="w-24 h-24 rounded-2xl border-2 border-dashed border-border hover:border-primary/50 transition-colors flex items-center justify-center overflow-hidden bg-muted/30 group"
                >
                  {logoPreview ? (
                    <img src={logoPreview} alt="Logo preview" className="w-full h-full object-cover" />
                  ) : (
                    <div className="flex flex-col items-center gap-1 text-muted-foreground group-hover:text-primary transition-colors">
                      <ImageIcon className="w-8 h-8" />
                      <span className="text-xs">Upload</span>
                    </div>
                  )}
                </button>

                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="flex items-center gap-2 text-sm text-primary font-medium hover:underline"
                >
                  <Upload className="w-4 h-4" />
                  {logoPreview ? 'Change logo' : 'Choose file'}
                </button>
                <p className="text-xs text-muted-foreground">PNG, JPG, SVG or WebP — max 2MB</p>
              </div>
            </>
          )}

          {/* ── Step 4: Team label ─────────────────────────────────────── */}
          {step === 4 && (
            <>
              <h1 className="text-lg font-semibold mb-1">What do you call your team members?</h1>
              <p className="text-sm text-muted-foreground mb-5">
                Pre-filled from your industry — change it if you prefer different terminology.
              </p>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-1.5">Singular (e.g. Technician)</label>
                  <input type="text" value={form.workerLabel} onChange={(e) => set('workerLabel', e.target.value)} placeholder="Technician" autoFocus className={inputClass} />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1.5">Plural (e.g. Technicians)</label>
                  <input type="text" value={form.workerLabelPlural} onChange={(e) => set('workerLabelPlural', e.target.value)} placeholder="Technicians" className={inputClass} />
                </div>
              </div>
            </>
          )}

          {/* ── Step 5: Invite admins ──────────────────────────────────── */}
          {step === 5 && (
            <>
              <div className="flex items-center gap-2 mb-1">
                <UserPlus className="w-4 h-4 text-primary" />
                <h1 className="text-lg font-semibold">Invite admins</h1>
              </div>
              <p className="text-sm text-muted-foreground mb-5">
                Add other people who will manage this portal. They&apos;ll receive an email invite.
              </p>
              <div className="space-y-3 mb-4">
                <input type="text" value={adminName} onChange={(e) => setAdminName(e.target.value)} placeholder="Full name" className={inputClass} />
                <input type="email" value={adminEmail} onChange={(e) => setAdminEmail(e.target.value)} placeholder="Email address" className={inputClass} onKeyDown={(e) => e.key === 'Enter' && handleInviteAdmin()} />
                {positions.length > 0 && (
                  <div className="relative">
                    <select value={adminPositionId} onChange={(e) => setAdminPositionId(e.target.value)} className={`${inputClass} appearance-none pr-8`}>
                      {positions.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
                    </select>
                    <svg className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" /></svg>
                  </div>
                )}
                <button type="button" onClick={handleInviteAdmin} disabled={inviting || !adminEmail.trim() || !adminName.trim()} className="w-full h-10 flex items-center justify-center gap-2 border border-primary text-primary rounded-lg text-sm font-medium hover:bg-primary/10 transition-colors disabled:opacity-50">
                  {inviting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Mail className="w-4 h-4" />}
                  Send invite
                </button>
              </div>
              {invitedAdmins.length > 0 && (
                <div className="space-y-2">
                  {invitedAdmins.map((a, i) => (
                    <div key={i} className="flex items-center gap-2 text-sm px-3 py-2 rounded-lg bg-muted/50">
                      {a.status === 'pending' && <Loader2 className="w-4 h-4 animate-spin text-muted-foreground shrink-0" />}
                      {a.status === 'sent' && <CheckCircle2 className="w-4 h-4 text-green-500 shrink-0" />}
                      {a.status === 'error' && <AlertCircle className="w-4 h-4 text-destructive shrink-0" />}
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{a.name}</p>
                        <p className="text-xs text-muted-foreground truncate">{a.email}</p>
                        {a.status === 'error' && <p className="text-xs text-destructive">{a.error}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}

          {/* ── Step 6: Add team members ───────────────────────────────── */}
          {step === 6 && (
            <>
              <div className="flex items-center gap-2 mb-1">
                <Plus className="w-4 h-4 text-primary" />
                <h1 className="text-lg font-semibold">Add {form.workerLabelPlural || 'team members'}</h1>
              </div>
              <p className="text-sm text-muted-foreground mb-5">
                Add your first team members now, or skip and do it later from the dashboard.
              </p>
              <div className="space-y-3 mb-4">
                <input type="text" value={memberName} onChange={(e) => setMemberName(e.target.value)} placeholder="Full name (required)" className={inputClass} />
                <input type="email" value={memberEmail} onChange={(e) => setMemberEmail(e.target.value)} placeholder="Email (optional)" className={inputClass} onKeyDown={(e) => e.key === 'Enter' && handleAddMember()} />
                <button type="button" onClick={handleAddMember} disabled={addingMember || !memberName.trim()} className="w-full h-10 flex items-center justify-center gap-2 border border-primary text-primary rounded-lg text-sm font-medium hover:bg-primary/10 transition-colors disabled:opacity-50">
                  {addingMember ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                  Add {form.workerLabel || 'member'}
                </button>
              </div>
              {addedMembers.length > 0 && (
                <div className="space-y-2">
                  {addedMembers.map((m, i) => (
                    <div key={i} className="flex items-center gap-2 text-sm px-3 py-2 rounded-lg bg-muted/50">
                      {m.status === 'pending' && <Loader2 className="w-4 h-4 animate-spin text-muted-foreground shrink-0" />}
                      {m.status === 'saved' && <CheckCircle2 className="w-4 h-4 text-green-500 shrink-0" />}
                      {m.status === 'error' && <AlertCircle className="w-4 h-4 text-destructive shrink-0" />}
                      <div className="flex-1 min-w-0">
                        <p className="font-medium truncate">{m.name}</p>
                        {m.email && <p className="text-xs text-muted-foreground truncate">{m.email}</p>}
                        {m.status === 'error' && <p className="text-xs text-destructive">{m.error}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              )}
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
            {step > 1 && step < 5 && (
              <button type="button" onClick={back} disabled={loading} className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50">
                <ChevronLeft className="w-4 h-4" />
                Back
              </button>
            )}

            {(step === 5 || step === 6) && (
              <button type="button" onClick={step === 6 ? finish : () => setStep(6)} className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Skip for now
              </button>
            )}

            <button
              type="button"
              onClick={step === 6 ? finish : advance}
              disabled={!canAdvance() || loading || logoUploading}
              className="ml-auto flex items-center justify-center gap-2 bg-primary text-primary-foreground px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed min-w-[100px]"
            >
              {loading || logoUploading ? (
                <><Loader2 className="w-4 h-4 animate-spin" /> {logoUploading ? 'Uploading...' : 'Setting up...'}</>
              ) : step === 4 ? (
                'Finish setup'
              ) : step === 6 ? (
                'Go to dashboard'
              ) : (
                'Continue'
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
