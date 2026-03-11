import Link from 'next/link'
import Image from 'next/image'
import {
  Wrench,
  Users,
  BarChart3,
  CheckCircle,
  ArrowRight,
  Shield,
  Zap,
  Globe,
} from 'lucide-react'

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-background text-foreground">
      {/* Nav */}
      <header className="border-b border-border bg-card/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <Image src="/icon.png" alt="Logo" width={28} height={28} className="rounded-lg" />
            <span className="font-semibold text-sm tracking-tight">Tools Admin Portal</span>
          </div>
          <div className="flex items-center gap-3">
            <Link
              href="/login"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              Sign in
            </Link>
            <Link
              href="/signup"
              className="text-sm bg-primary text-primary-foreground px-4 py-2 rounded-lg hover:bg-primary/90 transition-colors font-medium"
            >
              Start free trial
            </Link>
          </div>
        </div>
      </header>

      {/* Hero */}
      <section className="max-w-6xl mx-auto px-4 pt-24 pb-20 text-center">
        <div className="inline-flex items-center gap-2 bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full mb-6">
          <Zap className="w-3.5 h-3.5" />
          Multi-tenant tools management platform
        </div>
        <h1 className="text-4xl sm:text-5xl font-bold tracking-tight mb-5 max-w-2xl mx-auto leading-tight">
          Manage your team&apos;s tools with complete control
        </h1>
        <p className="text-muted-foreground text-lg max-w-xl mx-auto mb-10 leading-relaxed">
          Track equipment, manage field teams, and stay on top of compliance — all from one
          dashboard built for your industry.
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/pricing"
            className="inline-flex items-center justify-center gap-2 bg-primary text-primary-foreground px-6 py-3 rounded-lg font-medium hover:bg-primary/90 transition-colors text-sm"
          >
            See pricing
            <ArrowRight className="w-4 h-4" />
          </Link>
          <Link
            href="/login"
            className="inline-flex items-center justify-center gap-2 bg-secondary text-secondary-foreground px-6 py-3 rounded-lg font-medium hover:bg-secondary/80 transition-colors text-sm border border-border"
          >
            Sign in to your account
          </Link>
        </div>
      </section>

      {/* Feature highlights */}
      <section className="max-w-6xl mx-auto px-4 pb-20">
        <div className="grid md:grid-cols-3 gap-5">
          <FeatureCard
            icon={<Wrench className="w-5 h-5" />}
            title="Tool tracking"
            description="Know exactly where every tool is, who has it, and when it was last serviced. Full assignment history included."
          />
          <FeatureCard
            icon={<Users className="w-5 h-5" />}
            title="Team management"
            description="Add technicians, assign roles, manage positions, and control access — all scoped to your organisation."
          />
          <FeatureCard
            icon={<BarChart3 className="w-5 h-5" />}
            title="Reports & exports"
            description="Generate PDF and Excel reports on tool usage, compliance status, and team assignments in seconds."
          />
        </div>
      </section>

      {/* How it works */}
      <section className="border-t border-border bg-card/40">
        <div className="max-w-6xl mx-auto px-4 py-20">
          <div className="text-center mb-12">
            <h2 className="text-2xl font-bold tracking-tight mb-2">Up and running in minutes</h2>
            <p className="text-muted-foreground text-sm">No IT team required. Set up your company and start tracking.</p>
          </div>
          <div className="grid md:grid-cols-4 gap-6">
            {[
              { step: '1', title: 'Create account', desc: 'Sign up with your name and email.' },
              { step: '2', title: 'Set up company', desc: 'Add your company name and choose your industry.' },
              { step: '3', title: 'Invite your team', desc: 'Add admins and field technicians.' },
              { step: '4', title: 'Start tracking', desc: 'Add tools and assign them to your team.' },
            ].map((item) => (
              <div key={item.step} className="flex flex-col items-center text-center">
                <div className="w-9 h-9 rounded-full bg-primary text-primary-foreground text-sm font-bold flex items-center justify-center mb-4">
                  {item.step}
                </div>
                <h3 className="font-semibold text-sm mb-1">{item.title}</h3>
                <p className="text-muted-foreground text-xs leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Trust bar */}
      <section className="max-w-6xl mx-auto px-4 py-16">
        <div className="grid sm:grid-cols-3 gap-6 text-center">
          <TrustItem icon={<Shield className="w-5 h-5" />} label="Role-based access control" />
          <TrustItem icon={<Globe className="w-5 h-5" />} label="Works on web, iOS & Android" />
          <TrustItem icon={<CheckCircle className="w-5 h-5" />} label="Calibration & compliance tracking" />
        </div>
      </section>

      {/* CTA */}
      <section className="border-t border-border bg-card/40">
        <div className="max-w-6xl mx-auto px-4 py-20 text-center">
          <h2 className="text-2xl font-bold tracking-tight mb-3">Ready to get started?</h2>
          <p className="text-muted-foreground text-sm mb-8">
            Set up your company in under 5 minutes. No credit card required.
          </p>
          <Link
            href="/signup"
            className="inline-flex items-center gap-2 bg-primary text-primary-foreground px-8 py-3 rounded-lg font-medium hover:bg-primary/90 transition-colors text-sm"
          >
            Start free trial
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border">
        <div className="max-w-6xl mx-auto px-4 py-8 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-muted-foreground">
          <div className="flex items-center gap-2">
            <Image src="/icon.png" alt="Logo" width={20} height={20} className="rounded-md opacity-60" />
            <span>Tools Admin Portal</span>
          </div>
          <div className="flex items-center gap-5">
            <Link href="/privacy" className="hover:text-foreground transition-colors">Privacy</Link>
            <Link href="/support" className="hover:text-foreground transition-colors">Support</Link>
            <Link href="/login" className="hover:text-foreground transition-colors">Sign in</Link>
          </div>
        </div>
      </footer>
    </div>
  )
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode
  title: string
  description: string
}) {
  return (
    <div className="bg-card border border-border rounded-xl p-6">
      <div className="w-9 h-9 bg-primary/10 text-primary rounded-lg flex items-center justify-center mb-4">
        {icon}
      </div>
      <h3 className="font-semibold text-sm mb-2">{title}</h3>
      <p className="text-muted-foreground text-sm leading-relaxed">{description}</p>
    </div>
  )
}

function TrustItem({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <div className="flex items-center justify-center gap-2.5 text-sm text-muted-foreground">
      <span className="text-primary">{icon}</span>
      {label}
    </div>
  )
}
