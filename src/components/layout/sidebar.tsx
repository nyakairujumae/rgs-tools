'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { usePathname, useSearchParams } from 'next/navigation'
import { cn } from '@/lib/utils'
import Image from 'next/image'
import {
  LayoutDashboard,
  Wrench,
  Users,
  AlertTriangle,
  CheckSquare,
  Settings as SettingsIcon,
  ClipboardList,
  Shield,
  Gauge,
  FileText,
  History,
  UserCog,
  ChevronLeft,
  ChevronRight,
  Moon,
  Sun,
  LogOut,
  X,
  Share2,
  UserCheck,
  ArrowLeftRight,
  Package,
} from 'lucide-react'
import { useAuth } from '@/hooks/use-auth'

interface NavItem {
  label: string
  href: string
  icon: React.ReactNode
  badge?: number
}

const navItems: NavItem[] = [
  { label: 'Dashboard', href: '/dashboard', icon: <LayoutDashboard className="w-5 h-5" /> },
  { label: 'Tools', href: '/dashboard/tools', icon: <Wrench className="w-5 h-5" /> },
  { label: 'My Tools', href: '/dashboard/my-tools', icon: <Package className="w-5 h-5" /> },
  { label: 'Assign Tool', href: '/dashboard/tools/assign', icon: <ArrowLeftRight className="w-5 h-5" /> },
  { label: 'Shared Tools', href: '/dashboard/shared-tools', icon: <Share2 className="w-5 h-5" /> },
  { label: 'Technicians', href: '/dashboard/technicians', icon: <Users className="w-5 h-5" /> },
  { label: 'Issues', href: '/dashboard/issues', icon: <AlertTriangle className="w-5 h-5" /> },
  { label: 'Approvals', href: '/dashboard/approvals', icon: <CheckSquare className="w-5 h-5" /> },
  { label: 'Authorize Users', href: '/dashboard/approvals/users', icon: <UserCheck className="w-5 h-5" /> },
  { label: 'Maintenance', href: '/dashboard/maintenance', icon: <ClipboardList className="w-5 h-5" /> },
  { label: 'Compliance', href: '/dashboard/compliance', icon: <Shield className="w-5 h-5" /> },
  { label: 'Calibration', href: '/dashboard/calibration', icon: <Gauge className="w-5 h-5" /> },
  { label: 'Reports', href: '/dashboard/reports', icon: <FileText className="w-5 h-5" /> },
  { label: 'History', href: '/dashboard/history', icon: <History className="w-5 h-5" /> },
]

const adminOnlyItems: NavItem[] = [
  { label: 'Admin Management', href: '/dashboard/admin-management', icon: <UserCog className="w-5 h-5" /> },
]

const bottomItems: NavItem[] = [
  { label: 'Settings', href: '/dashboard/settings', icon: <SettingsIcon className="w-5 h-5" /> },
]

interface SidebarProps {
  mobileOpen: boolean
  onMobileClose: () => void
}

export function Sidebar({ mobileOpen, onMobileClose }: SidebarProps) {
  const [collapsed, setCollapsed] = useState(false)
  const [darkMode, setDarkMode] = useState(true)
  const pathname = usePathname()
  const { profile, signOut, hasPermission } = useAuth()
  const canManageAdmins = hasPermission('can_manage_admins')

  useEffect(() => {
    if (mobileOpen) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => { document.body.style.overflow = '' }
  }, [mobileOpen])

  const toggleTheme = () => {
    setDarkMode(!darkMode)
    document.documentElement.classList.toggle('dark')
  }

  const isActive = (href: string) => {
    if (href === '/dashboard') return pathname === '/dashboard'
    if (href === '/dashboard/tools') return pathname === '/dashboard/tools' || (pathname.startsWith('/dashboard/tools/') && !pathname.startsWith('/dashboard/tools/assign'))
    if (href === '/dashboard/my-tools') return pathname.startsWith('/dashboard/my-tools')
    if (href === '/dashboard/approvals') return pathname === '/dashboard/approvals'
    return pathname.startsWith(href)
  }

  const sidebarContent = (
    <>
      {/* Header */}
      <div className={cn(
        'h-16 flex items-center border-b border-sidebar-border px-4 shrink-0',
        collapsed ? 'justify-center' : 'gap-3'
      )}>
        <Image src="/icon.png" alt="RGS Tools" width={32} height={32} className="w-8 h-8 rounded-lg shrink-0" />
        {!collapsed && (
          <span className="font-semibold text-foreground tracking-tight">RGS Tools</span>
        )}
        {/* Mobile close button */}
        <button
          onClick={onMobileClose}
          className="ml-auto w-8 h-8 flex items-center justify-center rounded-lg hover:bg-accent transition-colors text-muted-foreground md:hidden"
        >
          <X className="w-5 h-5" />
        </button>
      </div>

      {/* Nav */}
      <nav className="flex-1 py-3 px-2 space-y-0.5 overflow-y-auto">
        {[...navItems, ...(canManageAdmins ? adminOnlyItems : [])].map((item) => (
          <Link
            key={item.href}
            href={item.href}
            onClick={onMobileClose}
            className={cn(
              'flex items-center gap-3 px-3 h-10 rounded-lg text-sm font-medium transition-colors',
              collapsed && 'justify-center px-0 md:justify-center md:px-0',
              isActive(item.href)
                ? 'bg-sidebar-active text-sidebar-active-foreground'
                : 'text-sidebar-foreground hover:bg-accent hover:text-foreground'
            )}
            title={collapsed ? item.label : undefined}
          >
            {item.icon}
            {(!collapsed || mobileOpen) && <span className={cn(collapsed && 'md:hidden')}>{item.label}</span>}
            {(!collapsed || mobileOpen) && item.badge != null && item.badge > 0 && (
              <span className={cn('ml-auto bg-destructive text-destructive-foreground text-xs font-medium px-1.5 py-0.5 rounded-full min-w-[20px] text-center', collapsed && 'md:hidden')}>
                {item.badge}
              </span>
            )}
          </Link>
        ))}
      </nav>

      {/* Bottom */}
      <div className="border-t border-sidebar-border p-2 space-y-0.5 shrink-0">
        {bottomItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            onClick={onMobileClose}
            className={cn(
              'flex items-center gap-3 px-3 h-10 rounded-lg text-sm font-medium transition-colors',
              collapsed && 'justify-center px-0',
              isActive(item.href)
                ? 'bg-sidebar-active text-sidebar-active-foreground'
                : 'text-sidebar-foreground hover:bg-accent hover:text-foreground'
            )}
            title={collapsed ? item.label : undefined}
          >
            {item.icon}
            {!collapsed && <span>{item.label}</span>}
          </Link>
        ))}

        {/* Theme toggle */}
        <button
          onClick={toggleTheme}
          className={cn(
            'flex items-center gap-3 px-3 h-10 rounded-lg text-sm font-medium transition-colors w-full text-sidebar-foreground hover:bg-accent hover:text-foreground',
            collapsed && 'justify-center px-0'
          )}
          title={collapsed ? 'Toggle theme' : undefined}
        >
          {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
          {!collapsed && <span>{darkMode ? 'Light Mode' : 'Dark Mode'}</span>}
        </button>

        {/* Collapse toggle - desktop only */}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className={cn(
            'hidden md:flex items-center gap-3 px-3 h-10 rounded-lg text-sm font-medium transition-colors w-full text-sidebar-foreground hover:bg-accent hover:text-foreground',
            collapsed && 'justify-center px-0'
          )}
        >
          {collapsed ? <ChevronRight className="w-5 h-5" /> : <ChevronLeft className="w-5 h-5" />}
          {!collapsed && <span>Collapse</span>}
        </button>

        {/* User */}
        <div className={cn(
          'flex items-center gap-3 px-3 py-2 mt-1',
          collapsed && 'justify-center px-0'
        )}>
          <div className="w-8 h-8 rounded-full bg-primary/20 text-primary flex items-center justify-center text-sm font-semibold shrink-0">
            {profile?.full_name?.charAt(0)?.toUpperCase() || 'A'}
          </div>
          {!collapsed && (
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-foreground truncate">
                {profile?.full_name || 'Admin'}
              </p>
              <p className="text-xs text-muted-foreground truncate">
                {profile?.email || ''}
              </p>
            </div>
          )}
          {!collapsed && (
            <button
              onClick={signOut}
              className="text-muted-foreground hover:text-foreground transition-colors"
              title="Sign out"
            >
              <LogOut className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>
    </>
  )

  return (
    <>
      {/* Desktop sidebar */}
      <aside
        className={cn(
          'hidden md:flex h-screen flex-col bg-sidebar border-r border-sidebar-border transition-all duration-200 ease-in-out shrink-0',
          collapsed ? 'w-[64px]' : 'w-[260px]'
        )}
      >
        {sidebarContent}
      </aside>

      {/* Mobile overlay */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <div className="absolute inset-0 bg-black/50" onClick={onMobileClose} />
          <aside className="absolute left-0 top-0 h-full w-[280px] flex flex-col bg-sidebar border-r border-sidebar-border shadow-xl animate-in slide-in-from-left duration-200">
            {sidebarContent}
          </aside>
        </div>
      )}
    </>
  )
}
