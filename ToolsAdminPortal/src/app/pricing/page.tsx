import Link from 'next/link'
import Image from 'next/image'
import { Check, ArrowLeft } from 'lucide-react'
import { PLANS } from '@/lib/plans'

export default function PricingPage() {
  return <PricingContent />
}

function PricingContent() {
  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* Nav */}
      <header className="border-b border-border bg-card/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <Image src="/icon.png" alt="Logo" width={24} height={24} className="rounded-md" />
            <span className="font-semibold text-sm tracking-tight">Tools Admin Portal</span>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/" className="text-sm text-muted-foreground hover:text-foreground transition-colors flex items-center gap-1">
              <ArrowLeft className="w-3.5 h-3.5" />
              Back
            </Link>
            <Link href="/login" className="text-sm text-muted-foreground hover:text-foreground transition-colors">
              Sign in
            </Link>
          </div>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-4 py-16">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-3xl font-bold tracking-tight mb-3">Simple, transparent pricing</h1>
          <p className="text-muted-foreground">
            Start with a 14-day free trial. No credit card required.
          </p>
          <div className="inline-flex items-center gap-1.5 bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full mt-4">
            14-day free trial — full Pro access, no card needed
          </div>
        </div>

        {/* Plans */}
        <div className="grid md:grid-cols-2 gap-6 max-w-3xl mx-auto">
          {PLANS.map((plan) => (
            <div
              key={plan.key}
              className={`rounded-xl border p-7 flex flex-col ${
                plan.highlight
                  ? 'border-primary bg-primary/5 relative'
                  : 'border-border bg-card'
              }`}
            >
              {plan.highlight && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-primary text-primary-foreground text-xs font-semibold px-3 py-1 rounded-full">
                  Most popular
                </div>
              )}

              <div className="mb-5">
                <h2 className="font-bold text-lg mb-1">{plan.name}</h2>
                <p className="text-muted-foreground text-sm">{plan.description}</p>
              </div>

              {/* Price */}
              <div className="mb-6">
                <div className="flex items-baseline gap-1">
                  <span className="text-3xl font-bold">${plan.monthlyUsd}</span>
                  <span className="text-muted-foreground text-sm">/month</span>
                </div>
                <p className="text-xs text-muted-foreground mt-1">
                  AED {plan.monthlyAed}/month · ${plan.annualUsd}/year (save 2 months)
                </p>
              </div>

              {/* Features */}
              <ul className="space-y-2.5 mb-8 flex-1">
                {plan.features.map((f) => (
                  <li key={f} className="flex items-start gap-2.5 text-sm">
                    <Check className="w-4 h-4 text-primary mt-0.5 shrink-0" />
                    <span>{f}</span>
                  </li>
                ))}
              </ul>

              {/* CTA */}
              <Link
                href="/signup"
                className={`w-full py-2.5 rounded-lg text-sm font-medium text-center transition-colors ${
                  plan.highlight
                    ? 'bg-primary text-primary-foreground hover:bg-primary/90'
                    : 'bg-secondary text-secondary-foreground border border-border hover:bg-secondary/80'
                }`}
              >
                {plan.ctaLabel}
              </Link>
            </div>
          ))}
        </div>

        {/* FAQ */}
        <div className="mt-16 max-w-2xl mx-auto">
          <h2 className="text-lg font-bold text-center mb-8">Common questions</h2>
          <div className="space-y-6">
            {[
              {
                q: 'Do I need a credit card to start the trial?',
                a: 'No. You get 14 days of full Pro access without entering any payment details.',
              },
              {
                q: 'Can I change plans later?',
                a: 'Yes. You can upgrade or downgrade at any time from the billing page in your dashboard.',
              },
              {
                q: 'Can I pay in AED?',
                a: 'Yes. We accept payments in AED and USD. Your card will be charged in the currency you select at checkout.',
              },
              {
                q: 'What happens when the trial ends?',
                a: 'You\'ll be asked to pick a plan. Your data is never deleted — you can subscribe at any time to regain access.',
              },
            ].map((item) => (
              <div key={item.q} className="border-b border-border pb-5">
                <p className="font-medium text-sm mb-1.5">{item.q}</p>
                <p className="text-muted-foreground text-sm">{item.a}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
