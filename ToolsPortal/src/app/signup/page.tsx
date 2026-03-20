'use client'

import { useState, useRef, useEffect, Suspense } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import Link from 'next/link'
import Image from 'next/image'
import { createClient } from '@/lib/supabase/client'
import { Eye, EyeOff, AlertCircle, Loader2, ChevronLeft, ArrowLeft, Upload, ImageIcon, Mail, UserPlus, Plus, CheckCircle2, FileSpreadsheet } from 'lucide-react'
import { inviteAdmin, addTechnician, fetchAdminPositions } from '@/lib/supabase/actions'
import type { AdminPosition } from '@/lib/types/database'

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
  fullName: string; email: string; password: string
  companyName: string; companySlug: string
  industry: string; workerLabel: string; workerLabelPlural: string
}

interface InvitedAdmin { email: string; name: string; positionId: string; status: 'pending' | 'sent' | 'error'; error?: string }
interface AddedMember { name: string; email: string; status: 'pending' | 'saved' | 'error'; error?: string }

// Steps: 1=Account, 2=Company, 3=Industry, 4=Team label, 5=Logo, 6=Invite admins, 7=Add members
const TOTAL_STEPS = 7

export default function SignupPageWrapper() {
  return <Suspense><SignupPage /></Suspense>
}

function SignupPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  // oauth=1 means user already has an auth account (came via Google/Apple), skip step 1
  const isOAuth = searchParams.get('oauth') === '1'
  const [step, setStep] = useState(isOAuth ? 2 : 1)

  useEffect(() => {
    if (isOAuth) setStep(2)
  }, [isOAuth])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [oauthLoading, setOauthLoading] = useState<'google' | 'apple' | null>(null)
  const [orgId, setOrgId] = useState<string | null>(null)

  const handleOAuth = async (provider: 'google' | 'apple') => {
    setOauthLoading(provider)
    const supabase = createClient()
    const { error } = await supabase.auth.signInWithOAuth({
      provider,
      options: { redirectTo: `${window.location.origin}/auth/callback` },
    })
    if (error) { setError(error.message); setOauthLoading(null) }
  }

  const [form, setForm] = useState<FormState>({
    fullName: '', email: '', password: '',
    companyName: '', companySlug: '',
    industry: '', workerLabel: 'Technician', workerLabelPlural: 'Technicians',
  })

  // Step 5 — logo
  const [logoFile, setLogoFile] = useState<File | null>(null)
  const [logoPreview, setLogoPreview] = useState<string | null>(null)
  const [logoUploading, setLogoUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const csvInputRef = useRef<HTMLInputElement>(null)
  const [csvPreview, setCsvPreview] = useState<{ name: string; email: string }[]>([])
  const [csvImporting, setCsvImporting] = useState(false)

  // Step 6 — invite admins
  const [positions, setPositions] = useState<AdminPosition[]>([])
  const [adminEmail, setAdminEmail] = useState('')
  const [adminName, setAdminName] = useState('')
  const [adminPositionId, setAdminPositionId] = useState('')
  const [invitedAdmins, setInvitedAdmins] = useState<InvitedAdmin[]>([])
  const [inviting, setInviting] = useState(false)

  // Step 7 — add team members
  const [memberName, setMemberName] = useState('')
  const [memberEmail, setMemberEmail] = useState('')
  const [addedMembers, setAddedMembers] = useState<AddedMember[]>([])
  const [addingMember, setAddingMember] = useState(false)

  const set = (field: keyof FormState, value: string) => setForm((prev) => ({ ...prev, [field]: value }))

  const selectIndustry = (preset: typeof INDUSTRY_PRESETS[number]) => {
    setForm((prev) => ({ ...prev, industry: preset.key, workerLabel: preset.workerLabel, workerLabelPlural: preset.workerLabelPlural }))
  }

  const canAdvance = (): boolean => {
    if (step === 1) return form.fullName.trim().length > 0 && form.email.trim().length > 0 && form.password.length >= 8
    if (step === 2) return form.companyName.trim().length > 0 && form.companySlug.trim().length > 0
    if (step === 3) return form.industry.length > 0
    if (step === 4) return form.workerLabel.trim().length > 0 && form.workerLabelPlural.trim().length > 0
    return true // steps 5-7 are optional
  }

  // ── Create account + org (step 4 → 5) ────────────────────────────────────
  const handleCreateAccount = async () => {
    setError('')
    setLoading(true)
    const supabase = createClient()
    try {
      // Skip sign-up if user authenticated via Google/Apple (account already exists)
      if (!isOAuth) {
        const { error: signUpError } = await supabase.auth.signUp({
          email: form.email.trim(),
          password: form.password,
          options: { data: { full_name: form.fullName.trim() } },
        })
        if (signUpError) { setError(signUpError.message); setLoading(false); return }
      }

      const { data, error: rpcError } = await supabase.rpc('create_organization_and_assign_user', {
        p_name: form.companyName.trim(),
        p_slug: form.companySlug.trim(),
        p_industry: form.industry,
        p_worker_label: form.workerLabel.trim(),
        p_worker_label_plural: form.workerLabelPlural.trim(),
      })
      if (rpcError) { setError(rpcError.message); setLoading(false); return }

      let createdOrgId: string | null = data?.org_id ?? null
      if (!createdOrgId) {
        const { data: { user } } = await supabase.auth.getUser()
        if (user) {
          const { data: profile } = await supabase.from('users').select('organization_id').eq('id', user.id).single()
          createdOrgId = profile?.organization_id ?? null
        }
      }
      setOrgId(createdOrgId)

      fetchAdminPositions().then((p) => {
        setPositions(p)
        if (p.length > 0) setAdminPositionId(p[0].id)
      })

      setStep(5)
    } catch {
      setError('Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const advance = () => {
    setError('')
    if (step === 4) { handleCreateAccount(); return }
    setStep((s) => s + 1)
  }

  const back = () => {
    setError('')
    if (step >= 5) return // can't go back after account created
    setStep((s) => s - 1)
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  const handleLogoChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setLogoFile(file)
    setLogoPreview(URL.createObjectURL(file))
  }

  const uploadLogoAndAdvance = async () => {
    if (!logoFile || !orgId) { setStep(6); return }
    setLogoUploading(true)
    try {
      const supabase = createClient()
      const ext = logoFile.name.split('.').pop()
      const path = `${orgId}/logo.${ext}`
      const { error: uploadError } = await supabase.storage.from('organization-logos').upload(path, logoFile, { upsert: true })
      if (uploadError) { setError(uploadError.message); return }
      const { data: { publicUrl } } = supabase.storage.from('organization-logos').getPublicUrl(path)
      await supabase.from('organizations').update({ logo_url: publicUrl }).eq('id', orgId)
      setStep(6)
    } finally {
      setLogoUploading(false)
    }
  }

  // ── Invite admin ──────────────────────────────────────────────────────────
  const handleInviteAdmin = async () => {
    if (!adminEmail.trim() || !adminName.trim()) return
    setInviting(true)
    const entry: InvitedAdmin = { email: adminEmail.trim(), name: adminName.trim(), positionId: adminPositionId, status: 'pending' }
    setInvitedAdmins((prev) => [...prev, entry])
    setAdminEmail(''); setAdminName('')
    const result = await inviteAdmin(entry.email, entry.name, entry.positionId)
    setInvitedAdmins((prev) => prev.map((a) => a.email === entry.email ? { ...a, status: result.error ? 'error' : 'sent', error: result.error } : a))
    setInviting(false)
  }

  // ── Add team member ───────────────────────────────────────────────────────
  const handleAddMember = async () => {
    if (!memberName.trim()) return
    setAddingMember(true)
    const entry: AddedMember = { name: memberName.trim(), email: memberEmail.trim(), status: 'pending' }
    setAddedMembers((prev) => [...prev, entry])
    setMemberName(''); setMemberEmail('')
    const result = await addTechnician({ name: entry.name, email: entry.email || undefined, status: 'Active' })
    setAddedMembers((prev) => prev.map((m) => m.name === entry.name && m.email === entry.email
      ? { ...m, status: result ? 'saved' : 'error', error: result ? undefined : 'Failed to add' } : m))
    setAddingMember(false)
  }

  // ── CSV import ────────────────────────────────────────────────────────────
  const handleCsvChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (ev) => {
      const text = ev.target?.result as string
      const lines = text.split('\n').map((l) => l.trim()).filter(Boolean)
      // Skip header row if it contains "name"
      const start = lines[0]?.toLowerCase().includes('name') ? 1 : 0
      const parsed = lines.slice(start).map((line) => {
        const [name, email] = line.split(',').map((s) => s.trim().replace(/^"|"$/g, ''))
        return { name: name || '', email: email || '' }
      }).filter((r) => r.name)
      setCsvPreview(parsed)
    }
    reader.readAsText(file)
    e.target.value = ''
  }

  const importCsvMembers = async () => {
    if (csvPreview.length === 0) return
    setCsvImporting(true)
    const toImport = [...csvPreview]
    setCsvPreview([])
    for (const member of toImport) {
      const entry: AddedMember = { name: member.name, email: member.email, status: 'pending' }
      setAddedMembers((prev) => [...prev, entry])
      const result = await addTechnician({ name: member.name, email: member.email || undefined, status: 'Active' })
      setAddedMembers((prev) => prev.map((m) =>
        m.name === member.name && m.email === member.email
          ? { ...m, status: result ? 'saved' : 'error', error: result ? undefined : 'Failed' }
          : m
      ))
    }
    setCsvImporting(false)
  }

  const finish = () => router.push('/dashboard')

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4">
      <div className="w-full max-w-[460px]">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          {step < 5 ? (
            <Link href="/" className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors">
              <ArrowLeft className="w-4 h-4" />
              Back
            </Link>
          ) : <div className="w-16" />}
          <div className="flex items-center gap-2.5">
            {logoPreview ? (
              <img src={logoPreview} alt="Logo" className="max-h-[32px] max-w-[120px] object-contain" />
            ) : (
              <Image src="/icon.png" alt="Logo" width={32} height={32} className="rounded-xl" />
            )}
            {!logoPreview && (
              <span className="font-black text-[15px] tracking-tight leading-none">
                {form.companyName || 'Tools Admin Portal'}
              </span>
            )}
          </div>
          <div className="w-16" />
        </div>

        {/* Progress */}
        <div className="flex items-center gap-1.5 mb-6">
          {Array.from({ length: TOTAL_STEPS }).map((_, i) => (
            <div key={i} className={`h-1 flex-1 rounded-full transition-colors ${i + 1 <= step ? 'bg-primary' : 'bg-border'}`} />
          ))}
        </div>

        {/* Card */}
        <div className="bg-card border border-border rounded-xl p-8">
          <p className="text-xs text-muted-foreground mb-1">Step {step} of {TOTAL_STEPS}</p>

          {/* ── Step 1: Account ───────────────────────────────────────── */}
          {step === 1 && (
            <>
              <h1 className="text-lg font-semibold mb-5">Create your account</h1>
              <div className="space-y-2 mb-5">
                <button type="button" onClick={() => handleOAuth('google')} disabled={!!oauthLoading}
                  className="w-full h-10 flex items-center justify-center gap-2.5 border border-border rounded-lg text-sm font-medium hover:bg-muted/50 transition-colors disabled:opacity-50">
                  {oauthLoading === 'google' ? <Loader2 className="w-4 h-4 animate-spin" /> : (
                    <svg className="w-4 h-4" viewBox="0 0 24 24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/></svg>
                  )}
                  Continue with Google
                </button>
                <button type="button" onClick={() => handleOAuth('apple')} disabled={!!oauthLoading}
                  className="w-full h-10 flex items-center justify-center gap-2.5 border border-border rounded-lg text-sm font-medium hover:bg-muted/50 transition-colors disabled:opacity-50">
                  {oauthLoading === 'apple' ? <Loader2 className="w-4 h-4 animate-spin" /> : (
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                  )}
                  Continue with Apple
                </button>
              </div>
              <div className="flex items-center gap-3 mb-5">
                <div className="flex-1 h-px bg-border" />
                <span className="text-xs text-muted-foreground">or</span>
                <div className="flex-1 h-px bg-border" />
              </div>
              <div className="space-y-4">
                <Field label="Full name">
                  <input type="text" value={form.fullName} onChange={(e) => set('fullName', e.target.value)} placeholder="Jane Smith" autoFocus className={inputClass} />
                </Field>
                <Field label="Work email">
                  <input type="email" value={form.email} onChange={(e) => set('email', e.target.value)} placeholder="jane@company.com" className={inputClass} />
                </Field>
                <Field label="Password">
                  <div className="relative">
                    <input type={showPassword ? 'text' : 'password'} value={form.password} onChange={(e) => set('password', e.target.value)} placeholder="At least 8 characters" className={`${inputClass} pr-10`} />
                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground">
                      {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                </Field>
              </div>
            </>
          )}

          {/* ── Step 2: Company ───────────────────────────────────────── */}
          {step === 2 && (
            <>
              <h1 className="text-lg font-semibold mb-5">Your company</h1>
              <div className="space-y-4">
                <Field label="Company name">
                  <input type="text" value={form.companyName} onChange={(e) => { set('companyName', e.target.value); set('companySlug', toSlug(e.target.value)) }} placeholder="Acme Services Ltd" autoFocus className={inputClass} />
                </Field>
                <Field label="URL slug" hint="Used in your portal URL — auto-generated, you can edit it.">
                  <div className="flex rounded-lg border border-input overflow-hidden focus-within:ring-2 focus-within:ring-ring focus-within:ring-offset-1">
                    <span className="flex items-center px-3 bg-muted text-muted-foreground text-sm border-r border-input select-none whitespace-nowrap">portal/</span>
                    <input type="text" value={form.companySlug} onChange={(e) => set('companySlug', toSlug(e.target.value))} placeholder="acme-services" className="flex-1 h-10 px-3 bg-background text-sm focus:outline-none" />
                  </div>
                </Field>
              </div>
            </>
          )}

          {/* ── Step 3: Industry ──────────────────────────────────────── */}
          {step === 3 && (
            <>
              <h1 className="text-lg font-semibold mb-1">Your industry</h1>
              <p className="text-sm text-muted-foreground mb-5">We&apos;ll pre-fill your departments and tool categories based on this.</p>
              <div className="grid grid-cols-1 gap-2">
                {INDUSTRY_PRESETS.map((preset) => (
                  <button key={preset.key} type="button" onClick={() => selectIndustry(preset)}
                    className={`flex items-center justify-between px-4 py-3 rounded-lg border text-sm font-medium transition-colors text-left ${form.industry === preset.key ? 'border-primary bg-primary/10 text-primary' : 'border-border hover:border-primary/50 hover:bg-muted/50'}`}>
                    <span>{preset.label}</span>
                    <span className="text-xs text-muted-foreground font-normal">Team member: {preset.workerLabel}</span>
                  </button>
                ))}
              </div>
            </>
          )}

          {/* ── Step 4: Team label ────────────────────────────────────── */}
          {step === 4 && (
            <>
              <h1 className="text-lg font-semibold mb-1">What do you call your team members?</h1>
              <p className="text-sm text-muted-foreground mb-5">Pre-filled from your industry — change it if you prefer.</p>
              <div className="space-y-4">
                <Field label="Singular (e.g. Technician)">
                  <input type="text" value={form.workerLabel} onChange={(e) => set('workerLabel', e.target.value)} placeholder="Technician" autoFocus className={inputClass} />
                </Field>
                <Field label="Plural (e.g. Technicians)">
                  <input type="text" value={form.workerLabelPlural} onChange={(e) => set('workerLabelPlural', e.target.value)} placeholder="Technicians" className={inputClass} />
                </Field>
              </div>
            </>
          )}

          {/* ── Step 5: Logo ──────────────────────────────────────────── */}
          {step === 5 && (
            <>
              <h1 className="text-lg font-semibold mb-1">Add your company logo</h1>
              <p className="text-sm text-muted-foreground mb-5">Shows in the sidebar and mobile app. You can skip this and add it later.</p>
              <input ref={fileInputRef} type="file" accept="image/png,image/jpeg,image/svg+xml,image/webp" onChange={handleLogoChange} className="hidden" />
              <div className="flex flex-col items-center gap-4">
                <button type="button" onClick={() => fileInputRef.current?.click()}
                  className="w-full max-w-xs h-24 rounded-2xl border-2 border-dashed border-border hover:border-primary/50 transition-colors flex items-center justify-center overflow-hidden bg-muted/30 group px-4">
                  {logoPreview ? (
                    <img src={logoPreview} alt="Logo preview" className="max-h-16 max-w-full object-contain" />
                  ) : (
                    <div className="flex flex-col items-center gap-1 text-muted-foreground group-hover:text-primary transition-colors">
                      <ImageIcon className="w-8 h-8" />
                      <span className="text-xs">Upload</span>
                    </div>
                  )}
                </button>
                <button type="button" onClick={() => fileInputRef.current?.click()} className="flex items-center gap-2 text-sm text-primary font-medium hover:underline">
                  <Upload className="w-4 h-4" />
                  {logoPreview ? 'Change logo' : 'Choose file'}
                </button>
                <p className="text-xs text-muted-foreground">PNG, JPG, SVG or WebP — max 2MB</p>
              </div>
            </>
          )}

          {/* ── Step 6: Invite admins ─────────────────────────────────── */}
          {step === 6 && (
            <>
              <div className="flex items-center gap-2 mb-1">
                <UserPlus className="w-4 h-4 text-primary" />
                <h1 className="text-lg font-semibold">Invite admins</h1>
              </div>
              <p className="text-sm text-muted-foreground mb-5">Add people who will manage this portal. They&apos;ll receive an email invite.</p>
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
                <button type="button" onClick={handleInviteAdmin} disabled={inviting || !adminEmail.trim() || !adminName.trim()}
                  className="w-full h-10 flex items-center justify-center gap-2 border border-primary text-primary rounded-lg text-sm font-medium hover:bg-primary/10 transition-colors disabled:opacity-50">
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

          {/* ── Step 7: Add team members ──────────────────────────────── */}
          {step === 7 && (
            <>
              <div className="flex items-center gap-2 mb-1">
                <Plus className="w-4 h-4 text-primary" />
                <h1 className="text-lg font-semibold">Add {form.workerLabelPlural || 'team members'}</h1>
              </div>
              <p className="text-sm text-muted-foreground mb-5">Add your first team members now, or skip and do it later.</p>
              <div className="space-y-3 mb-4">
                <input type="text" value={memberName} onChange={(e) => setMemberName(e.target.value)} placeholder="Full name (required)" className={inputClass} />
                <input type="email" value={memberEmail} onChange={(e) => setMemberEmail(e.target.value)} placeholder="Email (optional)" className={inputClass} onKeyDown={(e) => e.key === 'Enter' && handleAddMember()} />
                <button type="button" onClick={handleAddMember} disabled={addingMember || !memberName.trim()}
                  className="w-full h-10 flex items-center justify-center gap-2 border border-primary text-primary rounded-lg text-sm font-medium hover:bg-primary/10 transition-colors disabled:opacity-50">
                  {addingMember ? <Loader2 className="w-4 h-4 animate-spin" /> : <Plus className="w-4 h-4" />}
                  Add {form.workerLabel || 'member'}
                </button>

                {/* CSV import */}
                <input ref={csvInputRef} type="file" accept=".csv,text/csv" onChange={handleCsvChange} className="hidden" />
                <button type="button" onClick={() => csvInputRef.current?.click()}
                  className="w-full h-10 flex items-center justify-center gap-2 border border-dashed border-border text-muted-foreground rounded-lg text-sm hover:border-primary/50 hover:text-primary transition-colors">
                  <FileSpreadsheet className="w-4 h-4" />
                  Import from CSV
                </button>
                <p className="text-xs text-muted-foreground text-center">CSV format: name, email (one per row)</p>
              </div>

              {/* CSV preview */}
              {csvPreview.length > 0 && (
                <div className="mb-4 border border-border rounded-lg overflow-hidden">
                  <div className="flex items-center justify-between px-3 py-2 bg-muted/50 border-b border-border">
                    <span className="text-sm font-medium">{csvPreview.length} members to import</span>
                    <button type="button" onClick={importCsvMembers} disabled={csvImporting}
                      className="flex items-center gap-1.5 text-xs font-medium text-primary hover:underline disabled:opacity-50">
                      {csvImporting ? <Loader2 className="w-3 h-3 animate-spin" /> : <CheckCircle2 className="w-3 h-3" />}
                      Confirm import
                    </button>
                  </div>
                  <div className="max-h-40 overflow-y-auto divide-y divide-border">
                    {csvPreview.map((m, i) => (
                      <div key={i} className="flex items-center gap-2 px-3 py-2 text-sm">
                        <span className="font-medium flex-1 truncate">{m.name}</span>
                        {m.email && <span className="text-xs text-muted-foreground truncate">{m.email}</span>}
                      </div>
                    ))}
                  </div>
                </div>
              )}
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
              <button type="button" onClick={back} disabled={loading}
                className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors disabled:opacity-50">
                <ChevronLeft className="w-4 h-4" />
                Back
              </button>
            )}

            {step >= 5 && (
              <button type="button"
                onClick={step === 5 ? () => setStep(6) : step === 6 ? () => setStep(7) : finish}
                className="text-sm text-muted-foreground hover:text-foreground transition-colors">
                Skip for now
              </button>
            )}

            <button
              type="button"
              onClick={step === 5 ? uploadLogoAndAdvance : step === 7 ? finish : advance}
              disabled={!canAdvance() || loading || logoUploading}
              className="ml-auto flex items-center justify-center gap-2 bg-primary text-primary-foreground px-5 py-2.5 rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed min-w-[100px]"
            >
              {loading || logoUploading ? (
                <><Loader2 className="w-4 h-4 animate-spin" /> {logoUploading ? 'Uploading...' : 'Setting up...'}</>
              ) : step === 4 ? 'Create account'
                : step === 7 ? 'Go to dashboard'
                : step === 5 && logoFile ? 'Upload & continue'
                : 'Continue'}
            </button>
          </div>
        </div>

        {step < 5 && (
          <p className="text-center text-xs text-muted-foreground mt-5">
            Already have an account?{' '}
            <Link href="/login" className="text-primary hover:underline">Sign in</Link>
          </p>
        )}
      </div>
    </div>
  )
}

const inputClass = 'w-full h-10 px-3 rounded-lg border border-input bg-background text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-1'

function Field({ label, hint, children }: { label: string; hint?: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-sm font-medium mb-1.5">{label}</label>
      {children}
      {hint && <p className="text-xs text-muted-foreground mt-1">{hint}</p>}
    </div>
  )
}
