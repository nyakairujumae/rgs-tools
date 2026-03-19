import Link from 'next/link'
import Image from 'next/image'
import {
  Wrench,
  Shield,
  BarChart3,
  Users,
  QrCode,
  Bell,
  CheckCircle,
  ArrowRight,
  Zap,
  Globe,
} from 'lucide-react'

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white text-foreground overflow-hidden">
      {/* ── Nav ── */}
      <nav className="fixed top-0 inset-x-0 z-50 bg-white/80 backdrop-blur-xl border-b border-border">
        <div className="max-w-7xl mx-auto flex items-center justify-between px-6 h-16">
          <Link href="/" className="flex items-center gap-2.5">
            <Image src="/icon.png" alt="Logo" width={32} height={32} className="rounded-lg" />
            <span className="font-semibold text-lg tracking-tight">ToolsPortal</span>
          </Link>
          <div className="hidden md:flex items-center gap-8 text-sm text-muted-foreground">
            <a href="#features" className="hover:text-foreground transition-colors">Features</a>
            <a href="#how-it-works" className="hover:text-foreground transition-colors">How it works</a>
            <a href="#industries" className="hover:text-foreground transition-colors">Industries</a>
            <Link href="/pricing" className="hover:text-foreground transition-colors">Pricing</Link>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/login" className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors">
              Sign in
            </Link>
            <Link
              href="/signup"
              className="text-sm font-medium bg-primary text-white px-4 py-2 rounded-lg hover:bg-primary/90 transition-colors"
            >
              Get started free
            </Link>
          </div>
        </div>
      </nav>

      {/* ── Hero ── */}
      <section className="relative pt-32 pb-20 md:pt-40 md:pb-32 px-6">
        {/* Background grid */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#f0f0f0_1px,transparent_1px),linear-gradient(to_bottom,#f0f0f0_1px,transparent_1px)] bg-[size:4rem_4rem] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)]" />

        <div className="relative max-w-7xl mx-auto">
          <div className="max-w-3xl">
            <div className="inline-flex items-center gap-2 bg-primary/5 border border-primary/20 rounded-full px-4 py-1.5 text-sm text-primary font-medium mb-8 animate-fade-in">
              <Zap className="w-3.5 h-3.5" />
              Trusted by field teams across the Middle East
            </div>
            <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-[1.1] animate-fade-in-up">
              Track every tool.
              <br />
              <span className="text-primary">Empower every team.</span>
            </h1>
            <p className="mt-6 text-lg md:text-xl text-muted-foreground max-w-xl leading-relaxed animate-fade-in-up animation-delay-100">
              Assign, track, and manage every tool — from warehouse to field.
            </p>
            <div className="mt-10 flex flex-col sm:flex-row gap-4 animate-fade-in-up animation-delay-200">
              <Link
                href="/signup"
                className="inline-flex items-center justify-center gap-2 bg-primary text-white font-semibold px-8 py-3.5 rounded-xl hover:bg-primary/90 transition-all text-base shadow-lg shadow-[#047857]/20"
              >
                Start free trial
                <ArrowRight className="w-4 h-4" />
              </Link>
              <a
                href="#how-it-works"
                className="inline-flex items-center justify-center gap-2 bg-secondary text-secondary-foreground font-semibold px-8 py-3.5 rounded-xl hover:bg-secondary/80 transition-all text-base"
              >
                See how it works
              </a>
            </div>
            <div className="mt-10 flex items-center gap-6 text-sm text-muted-foreground animate-fade-in-up animation-delay-300">
              <span className="flex items-center gap-1.5"><CheckCircle className="w-4 h-4 text-primary" /> Free 14-day trial</span>
              <span className="flex items-center gap-1.5"><CheckCircle className="w-4 h-4 text-primary" /> No credit card</span>
              <span className="flex items-center gap-1.5"><CheckCircle className="w-4 h-4 text-primary" /> Setup in 5 min</span>
            </div>
          </div>

          {/* Floating dashboard preview */}
          <div className="hidden lg:block absolute top-8 right-0 w-[520px] animate-float">
            <div className="bg-white rounded-2xl border border-border shadow-2xl shadow-black/5 p-6 rotate-[-2deg]">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                  <span className="text-primary font-bold text-sm">JD</span>
                </div>
                <div>
                  <div className="text-sm font-semibold">Good morning, John!</div>
                  <div className="text-xs text-muted-foreground">Manage your tools and electricians</div>
                </div>
                <div className="ml-auto px-2.5 py-1 bg-primary/10 rounded-full text-[10px] font-semibold text-primary">Admin</div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                {[
                  { label: 'Total Tools', value: '247', color: 'text-blue-600' },
                  { label: 'Technicians', value: '32', color: 'text-emerald-600' },
                  { label: 'Total Value', value: 'AED 1.2M', color: 'text-amber-600' },
                  { label: 'Maintenance', value: '5', color: 'text-red-500' },
                ].map((card) => (
                  <div key={card.label} className="border border-border rounded-xl p-3">
                    <div className="text-[10px] font-medium text-muted-foreground">{card.label}</div>
                    <div className={`text-xl font-bold mt-1 ${card.color}`}>{card.value}</div>
                  </div>
                ))}
              </div>
            </div>

            {/* Floating notification */}
            <div className="absolute -left-16 bottom-8 bg-white rounded-xl border border-border shadow-xl p-4 w-64 animate-float-delayed">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-full bg-amber-50 flex items-center justify-center shrink-0">
                  <Bell className="w-4 h-4 text-amber-500" />
                </div>
                <div>
                  <div className="text-xs font-semibold">Calibration Due</div>
                  <div className="text-[10px] text-muted-foreground">Fluke T6-1000 — 2 days left</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Social proof ── */}
      <section className="py-12 border-y border-border bg-muted/30">
        <div className="max-w-7xl mx-auto px-6">
          <p className="text-center text-xs font-medium text-muted-foreground uppercase tracking-widest mb-8">
            Built for teams managing 50 to 5,000+ tools
          </p>
          <div className="flex items-center justify-center gap-12 md:gap-20 opacity-40">
            {['HVAC', 'Electrical', 'Facilities', 'Construction', 'MEP'].map((industry) => (
              <span key={industry} className="text-lg md:text-xl font-bold tracking-tight text-foreground">{industry}</span>
            ))}
          </div>
        </div>
      </section>

      {/* ── Image showcase ── */}
      <section className="py-16 md:py-24 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="grid md:grid-cols-3 gap-4 md:gap-6">
            <div className="relative rounded-2xl overflow-hidden aspect-[4/3] md:aspect-auto md:row-span-2">
              <img
                src="https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800&q=80"
                alt="Engineer checking equipment on site"
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent" />
              <div className="absolute bottom-6 left-6 right-6 text-white">
                <p className="text-sm font-semibold">Field-ready</p>
              </div>
            </div>
            <div className="relative rounded-2xl overflow-hidden aspect-[4/3]">
              <img
                src="https://images.unsplash.com/photo-1504917595217-d4dc5ebb6681?w=800&q=80"
                alt="Organized tools on workbench"
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent" />
              <div className="absolute bottom-4 left-4 text-white">
                <p className="text-sm font-semibold">Track every asset</p>
              </div>
            </div>
            <div className="relative rounded-2xl overflow-hidden aspect-[4/3]">
              <img
                src="https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=800&q=80"
                alt="Technician using tablet on site"
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent" />
              <div className="absolute bottom-4 left-4 text-white">
                <p className="text-sm font-semibold">Real-time updates</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Features ── */}
      <section id="features" className="py-20 md:py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="max-w-2xl mb-16">
            <p className="text-sm font-semibold text-primary uppercase tracking-wider mb-3">Features</p>
            <h2 className="text-3xl md:text-4xl font-bold tracking-tight">
              Everything you need at scale
            </h2>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: QrCode,
                title: 'QR Check-in / Check-out',
                description: 'Scan to assign or return tools instantly. Full custody history.',
                color: 'text-blue-600 bg-blue-50',
              },
              {
                icon: Users,
                title: 'Team Management',
                description: 'Invite by email or CSV. Track who has what, where.',
                color: 'text-emerald-600 bg-emerald-50',
              },
              {
                icon: Shield,
                title: 'Compliance & Calibration',
                description: 'Auto-alerts for calibration, certifications, and inspections.',
                color: 'text-violet-600 bg-violet-50',
              },
              {
                icon: BarChart3,
                title: 'Reports & Analytics',
                description: 'Utilization, costs, and maintenance — export to PDF or CSV.',
                color: 'text-amber-600 bg-amber-50',
              },
              {
                icon: Bell,
                title: 'Real-time Notifications',
                description: 'Push alerts for requests, approvals, and overdue returns.',
                color: 'text-red-500 bg-red-50',
              },
              {
                icon: Globe,
                title: 'Multi-language',
                description: 'English, Arabic, Spanish, and French built-in.',
                color: 'text-sky-600 bg-sky-50',
              },
            ].map((feature) => (
              <div
                key={feature.title}
                className="group p-6 rounded-2xl border border-border bg-white hover:border-primary/20 hover:shadow-lg hover:shadow-[#047857]/5 transition-all duration-300"
              >
                <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${feature.color} mb-5`}>
                  <feature.icon className="w-5 h-5" />
                </div>
                <h3 className="font-semibold text-lg mb-2">{feature.title}</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── How it works ── */}
      <section id="how-it-works" className="py-20 md:py-32 px-6 bg-muted/30">
        <div className="max-w-7xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <p className="text-sm font-semibold text-primary uppercase tracking-wider mb-3">How it works</p>
            <h2 className="text-3xl md:text-4xl font-bold tracking-tight">
              Up and running in minutes
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-8 md:gap-12">
            {[
              {
                step: '01',
                title: 'Create your workspace',
                description: 'Sign up, pick your industry — we configure the rest.',
              },
              {
                step: '02',
                title: 'Add your team & tools',
                description: 'Invite by email or CSV. Add tools or import inventory.',
              },
              {
                step: '03',
                title: 'Assign, track, report',
                description: 'Your team checks in/out via mobile. You get real-time visibility.',
              },
            ].map((item) => (
              <div key={item.step} className="relative">
                <div className="text-6xl font-black text-primary/10 mb-4">{item.step}</div>
                <h3 className="font-semibold text-xl mb-3">{item.title}</h3>
                <p className="text-muted-foreground leading-relaxed">{item.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Industries ── */}
      <section id="industries" className="py-20 md:py-32 px-6">
        <div className="max-w-7xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <p className="text-sm font-semibold text-primary uppercase tracking-wider mb-3">Industries</p>
            <h2 className="text-3xl md:text-4xl font-bold tracking-tight">
              Configured for your industry
            </h2>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {[
              { name: 'HVAC', label: 'Technicians', emoji: '\u{1F321}\u{FE0F}' },
              { name: 'Electrical', label: 'Electricians', emoji: '\u{26A1}' },
              { name: 'Facilities', label: 'Operatives', emoji: '\u{1F3E2}' },
              { name: 'Construction', label: 'Site Workers', emoji: '\u{1F3D7}\u{FE0F}' },
              { name: 'General', label: 'Workers', emoji: '\u{1F527}' },
            ].map((industry) => (
              <div
                key={industry.name}
                className="p-6 rounded-2xl border border-border bg-white text-center hover:border-primary/30 hover:shadow-md transition-all"
              >
                <div className="text-3xl mb-3">{industry.emoji}</div>
                <div className="font-semibold">{industry.name}</div>
                <div className="text-xs text-muted-foreground mt-1">{industry.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Stats ── */}
      <section className="py-20 px-6 bg-foreground text-white">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-12 text-center">
            {[
              { value: '99.9%', label: 'Uptime SLA' },
              { value: '<2s', label: 'Average load time' },
              { value: '4', label: 'Languages supported' },
              { value: '24/7', label: 'Support availability' },
            ].map((stat) => (
              <div key={stat.label}>
                <div className="text-3xl md:text-4xl font-bold">{stat.value}</div>
                <div className="text-sm text-white/60 mt-2">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Testimonial ── */}
      <section className="py-20 md:py-32 px-6">
        <div className="max-w-3xl mx-auto text-center">
          <div className="inline-flex items-center gap-1 mb-8">
            {Array.from({ length: 5 }).map((_, i) => (
              <svg key={i} className="w-5 h-5 text-amber-400 fill-current" viewBox="0 0 20 20">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
            ))}
          </div>
          <blockquote className="text-xl md:text-2xl font-medium leading-relaxed">
            &ldquo;From spreadsheets to full visibility in under a week. Calibration alerts alone saved us from two compliance violations.&rdquo;
          </blockquote>
          <div className="mt-8">
            <div className="font-semibold">Operations Manager</div>
            <div className="text-sm text-muted-foreground">MEP Contractor, Dubai</div>
          </div>
        </div>
      </section>

      {/* ── CTA ── */}
      <section className="py-20 md:py-32 px-6 bg-primary">
        <div className="max-w-3xl mx-auto text-center text-white">
          <h2 className="text-3xl md:text-4xl font-bold tracking-tight">
            Ready to take control of your tools?
          </h2>
          <p className="mt-4 text-lg text-white/80">
            Start your free 14-day trial. No credit card required.
          </p>
          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/signup"
              className="inline-flex items-center gap-2 bg-white text-primary font-semibold px-8 py-3.5 rounded-xl hover:bg-white/90 transition-all text-base"
            >
              Start free trial
              <ArrowRight className="w-4 h-4" />
            </Link>
            <a
              href="#features"
              className="inline-flex items-center gap-2 border-2 border-white/30 text-white font-semibold px-8 py-3.5 rounded-xl hover:border-white/60 transition-all text-base"
            >
              Explore features
            </a>
          </div>
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="py-12 px-6 border-t border-border">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2.5">
            <Image src="/icon.png" alt="Logo" width={28} height={28} className="rounded-lg" />
            <span className="font-semibold">ToolsPortal</span>
          </div>
          <div className="flex items-center gap-6 text-sm text-muted-foreground">
            <Link href="/privacy" className="hover:text-foreground transition-colors">Privacy</Link>
            <Link href="/support" className="hover:text-foreground transition-colors">Support</Link>
            <Link href="/pricing" className="hover:text-foreground transition-colors">Pricing</Link>
          </div>
          <div className="text-sm text-muted-foreground">
            &copy; {new Date().getFullYear()} ToolsPortal. All rights reserved.
          </div>
        </div>
      </footer>
    </div>
  )
}
