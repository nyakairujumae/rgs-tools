'use client'

import { useEffect, useState, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/hooks/use-auth'
import { useOrgContext } from '@/contexts/organization-context'
import { createClient } from '@/lib/supabase/client'
import { initializePaddle, type Paddle } from '@paddle/paddle-js'
import {
  CreditCard, CheckCircle, AlertCircle, Clock, Loader2, ExternalLink, Zap
} from 'lucide-react'
import { PLANS } from '@/lib/plans'

interface SubStatus {
  has_access: boolean
  reason: string
  plan: string
  status: string
  trial_ends_at: string | null
  subscription_ends_at: string | null
}

function daysLeft(dateStr: string | null): number {
  if (!dateStr) return 0
  const diff = new Date(dateStr).getTime() - Date.now()
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)))
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return '—'
  return new Date(dateStr).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
}

export default function BillingPage() {
  const { profile } = useAuth()
  const orgState = useOrgContext()
  const router = useRouter()
  const [subStatus, setSubStatus] = useState<SubStatus | null>(null)
  const [paddle, setPaddle] = useState<Paddle | null>(null)
  const [loadingPlan, setLoadingPlan] = useState<string | null>(null)
  const [error, setError] = useState('')

  // Load Paddle.js
  useEffect(() => {
    if (!process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN) return
    initializePaddle({
      environment: (process.env.NEXT_PUBLIC_PADDLE_ENV as 'sandbox' | 'production') ?? 'sandbox',
      token: process.env.NEXT_PUBLIC_PADDLE_CLIENT_TOKEN,
    }).then((p) => p && setPaddle(p))
  }, [])

  const loadSubStatus = useCallback(async () => {
    if (!profile?.organization_id) return
    const supabase = createClient()
    const { data } = await supabase.rpc('get_subscription_status', {
      p_org_id: profile.organization_id,
    })
    if (data) setSubStatus(data as SubStatus)
  }, [profile?.organization_id])

  useEffect(() => {
    loadSubStatus()
  }, [loadSubStatus])

  const handleSubscribe = async (priceId: string, planKey: string) => {
    if (!paddle || !profile?.organization_id) return
    setError('')
    setLoadingPlan(planKey)

    try {
      const res = await fetch('/api/paddle/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ priceId, orgId: profile.organization_id }),
      })
      const { transactionId, error: apiError } = await res.json()
      if (apiError) { setError(apiError); setLoadingPlan(null); return }

      paddle.Checkout.open({
        transactionId,
        settings: {
          successUrl: `${window.location.origin}/dashboard/billing?success=1`,
        },
      })
    } catch {
      setError('Could not open checkout. Please try again.')
    } finally {
      setLoadingPlan(null)
    }
  }

  const isTrialing = subStatus?.status === 'trialing'
  const isActive = subStatus?.status === 'active'
  const isCancelled = subStatus?.status === 'cancelled'
  const isPastDue = subStatus?.status === 'past_due'
  const trialDays = daysLeft(subStatus?.trial_ends_at ?? null)

  return (
    <div className="max-w-3xl mx-auto px-6 py-8 space-y-8">
      <div>
        <h1 className="text-xl font-semibold">Billing</h1>
        <p className="text-sm text-muted-foreground mt-1">Manage your subscription and plan.</p>
      </div>

      {/* Current status card */}
      {subStatus ? (
        <div className="bg-card border border-border rounded-xl p-6">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-xs text-muted-foreground uppercase tracking-wide mb-1">Current plan</p>
              <p className="text-lg font-semibold capitalize">
                {subStatus.plan === 'none' ? 'No plan' : subStatus.plan}
              </p>
            </div>
            <StatusBadge status={subStatus.status} />
          </div>

          <div className="mt-4 pt-4 border-t border-border grid sm:grid-cols-2 gap-4 text-sm">
            {isTrialing && (
              <div className="flex items-center gap-2 text-muted-foreground">
                <Clock className="w-4 h-4 text-primary" />
                <span>Trial ends in <strong className="text-foreground">{trialDays} day{trialDays !== 1 ? 's' : ''}</strong> ({formatDate(subStatus.trial_ends_at)})</span>
              </div>
            )}
            {isActive && subStatus.subscription_ends_at && (
              <div className="flex items-center gap-2 text-muted-foreground">
                <CheckCircle className="w-4 h-4 text-primary" />
                <span>Renews on <strong className="text-foreground">{formatDate(subStatus.subscription_ends_at)}</strong></span>
              </div>
            )}
            {isCancelled && subStatus.subscription_ends_at && (
              <div className="flex items-center gap-2 text-muted-foreground">
                <AlertCircle className="w-4 h-4 text-destructive" />
                <span>Access until <strong className="text-foreground">{formatDate(subStatus.subscription_ends_at)}</strong></span>
              </div>
            )}
            {isPastDue && (
              <div className="flex items-center gap-2 text-destructive">
                <AlertCircle className="w-4 h-4" />
                <span>Payment failed — please update your payment method.</span>
              </div>
            )}
          </div>
        </div>
      ) : (
        <div className="bg-card border border-border rounded-xl p-6 flex items-center gap-3">
          <Loader2 className="w-4 h-4 animate-spin text-muted-foreground" />
          <span className="text-sm text-muted-foreground">Loading billing info...</span>
        </div>
      )}

      {/* Plan picker — show if trialing, cancelled, past_due, or no plan */}
      {subStatus && !isActive && (
        <>
          <div>
            <h2 className="text-base font-semibold mb-1">
              {isTrialing ? 'Choose a plan before your trial ends' : 'Pick a plan to continue'}
            </h2>
            <p className="text-sm text-muted-foreground">
              Cancel anytime. Prices shown in USD — AED option available at checkout.
            </p>
          </div>

          {error && (
            <div className="flex items-center gap-2 bg-destructive/10 text-destructive rounded-lg p-3 text-sm">
              <AlertCircle className="w-4 h-4 shrink-0" />
              {error}
            </div>
          )}

          <div className="grid sm:grid-cols-2 gap-4">
            {PLANS.map((plan) => {
              const monthlyPriceId = plan.key === 'starter'
                ? process.env.NEXT_PUBLIC_PADDLE_PRICE_STARTER_MONTHLY!
                : process.env.NEXT_PUBLIC_PADDLE_PRICE_PRO_MONTHLY!
              const isCurrentPlan = subStatus.plan === plan.key && isActive

              return (
                <div
                  key={plan.key}
                  className={`bg-card border rounded-xl p-5 flex flex-col ${
                    plan.highlight ? 'border-primary' : 'border-border'
                  }`}
                >
                  {plan.highlight && (
                    <span className="inline-flex items-center gap-1 text-xs text-primary font-medium mb-3">
                      <Zap className="w-3 h-3" /> Most popular
                    </span>
                  )}
                  <p className="font-semibold mb-0.5">{plan.name}</p>
                  <p className="text-2xl font-bold mb-0.5">${plan.monthlyUsd}<span className="text-sm font-normal text-muted-foreground">/mo</span></p>
                  <p className="text-xs text-muted-foreground mb-5">AED {plan.monthlyAed}/mo</p>

                  <button
                    onClick={() => handleSubscribe(monthlyPriceId, plan.key)}
                    disabled={!!loadingPlan || isCurrentPlan || !paddle}
                    className={`mt-auto w-full py-2.5 rounded-lg text-sm font-medium transition-colors flex items-center justify-center gap-2 ${
                      plan.highlight
                        ? 'bg-primary text-primary-foreground hover:bg-primary/90 disabled:opacity-50'
                        : 'bg-secondary text-secondary-foreground border border-border hover:bg-secondary/80 disabled:opacity-50'
                    }`}
                  >
                    {loadingPlan === plan.key ? (
                      <><Loader2 className="w-4 h-4 animate-spin" /> Opening checkout...</>
                    ) : isCurrentPlan ? (
                      'Current plan'
                    ) : (
                      `Subscribe to ${plan.name}`
                    )}
                  </button>
                </div>
              )
            })}
          </div>
        </>
      )}

      {/* Active subscription — manage via Paddle portal */}
      {isActive && (
        <div className="bg-card border border-border rounded-xl p-6">
          <h2 className="text-sm font-semibold mb-1">Manage subscription</h2>
          <p className="text-sm text-muted-foreground mb-4">
            Update payment method, view invoices, or cancel your subscription.
          </p>
          <a
            href="https://customer.paddle.com"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-sm text-primary hover:underline"
          >
            Open billing portal
            <ExternalLink className="w-3.5 h-3.5" />
          </a>
        </div>
      )}

      <p className="text-xs text-muted-foreground">
        Payments are processed securely by Paddle. Need help?{' '}
        <a href="/support" className="text-primary hover:underline">Contact support</a>
      </p>
    </div>
  )
}

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, { label: string; class: string }> = {
    trialing:  { label: 'Trial', class: 'bg-primary/10 text-primary' },
    active:    { label: 'Active', class: 'bg-green-500/10 text-green-600 dark:text-green-400' },
    cancelled: { label: 'Cancelled', class: 'bg-muted text-muted-foreground' },
    past_due:  { label: 'Past due', class: 'bg-destructive/10 text-destructive' },
    paused:    { label: 'Paused', class: 'bg-muted text-muted-foreground' },
  }
  const style = map[status] ?? { label: status, class: 'bg-muted text-muted-foreground' }
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${style.class}`}>
      <CreditCard className="w-3 h-3" />
      {style.label}
    </span>
  )
}
