'use client'

import { useAuth } from '@/hooks/use-auth'
import { useOrganization } from '@/hooks/use-organization'
import { OrganizationContext } from '@/contexts/organization-context'
import { useRouter, usePathname } from 'next/navigation'
import { useEffect, useState } from 'react'
import { Sidebar } from '@/components/layout/sidebar'
import { Topbar } from '@/components/layout/topbar'
import { BreadcrumbLabelProvider } from '@/components/layout/breadcrumb-context'
import { Loader2 } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { sendCalibrationReminderPush } from '@/lib/supabase/actions'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { user, profile, loading } = useAuth()
  const orgState = useOrganization(profile?.organization_id)
  const router = useRouter()
  const pathname = usePathname()
  const [mobileOpen, setMobileOpen] = useState(false)
  const isBillingPage = pathname === '/dashboard/billing'

  useEffect(() => {
    setMobileOpen(false)
  }, [pathname])

  useEffect(() => {
    if (!loading && !user) {
      router.replace('/login')
    }
    if (!loading && profile && profile.role !== 'admin') {
      router.replace('/login?error=admin_only')
    }
    // If the user signed up but never completed company setup, send them to onboarding
    if (!loading && orgState && !orgState.loading && profile?.organization_id && orgState.org && !orgState.org.setup_completed_at) {
      router.replace('/onboarding')
    }
  }, [loading, user, profile, orgState, router])

  // Calibration reminders — fire once per day after org resolves
  useEffect(() => {
    if (!profile?.organization_id || orgState.loading) return
    sendCalibrationReminderPush(profile.organization_id)
  }, [profile?.organization_id, orgState.loading])

  // Paywall: check subscription status and redirect to billing if expired
  useEffect(() => {
    if (!profile?.organization_id || isBillingPage) return
    const check = async () => {
      const supabase = createClient()
      const { data } = await supabase.rpc('get_subscription_status', {
        p_org_id: profile.organization_id,
      })
      if (data && !data.has_access) {
        router.replace('/dashboard/billing')
      }
    }
    check()
  }, [profile?.organization_id, isBillingPage, router])

  if (loading || !user || (profile && profile.role !== 'admin')) {
    return (
      <div className="flex h-screen bg-background">
        <div className="hidden md:block w-[260px] bg-sidebar border-r border-sidebar-border animate-pulse">
          <div className="h-16 flex items-center px-4 border-b border-sidebar-border">
            <div className="h-8 w-8 bg-muted rounded-lg" />
            <div className="h-5 w-24 bg-muted rounded ml-3" />
          </div>
          <div className="p-3 space-y-1">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-9 bg-muted/50 rounded-lg" />
            ))}
          </div>
        </div>
        <div className="flex-1 flex flex-col">
          <div className="h-14 border-b border-border bg-card flex items-center px-6">
            <div className="h-4 w-24 bg-muted rounded animate-pulse" />
          </div>
          <div className="flex-1 flex items-center justify-center">
            <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
          </div>
        </div>
      </div>
    )
  }

  return (
    <OrganizationContext.Provider value={orgState}>
      <BreadcrumbLabelProvider>
        <div className="flex h-screen overflow-hidden">
          <Sidebar mobileOpen={mobileOpen} onMobileClose={() => setMobileOpen(false)} />
          <div className="flex-1 flex flex-col min-w-0">
            <Topbar onMenuToggle={() => setMobileOpen(true)} />
            <main className="flex-1 overflow-y-auto bg-background">
              {children}
            </main>
          </div>
        </div>
      </BreadcrumbLabelProvider>
    </OrganizationContext.Provider>
  )
}
