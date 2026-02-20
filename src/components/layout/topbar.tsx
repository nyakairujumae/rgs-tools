'use client'

import { useState, useEffect, useRef } from 'react'
import { usePathname } from 'next/navigation'
import { Bell, X } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { cn, timeAgo } from '@/lib/utils'
import type { AdminNotification } from '@/lib/types/database'

const routeLabels: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/dashboard/tools': 'Tools',
  '/dashboard/technicians': 'Technicians',
  '/dashboard/issues': 'Issues',
  '/dashboard/approvals': 'Approvals',
  '/dashboard/approvals/users': 'User Approvals',
  '/dashboard/maintenance': 'Maintenance',
  '/dashboard/compliance': 'Compliance',
  '/dashboard/reports': 'Reports',
  '/dashboard/history': 'History',
  '/dashboard/settings': 'Settings',
}

export function Topbar() {
  const pathname = usePathname()
  const [notifications, setNotifications] = useState<AdminNotification[]>([])
  const [showNotifications, setShowNotifications] = useState(false)
  const dropdownRef = useRef<HTMLDivElement>(null)

  const unreadCount = notifications.filter((n) => !n.is_read).length

  // Build breadcrumbs
  const segments = pathname.split('/').filter(Boolean)
  const breadcrumbs = segments.map((_, i) => {
    const path = '/' + segments.slice(0, i + 1).join('/')
    return { label: routeLabels[path] || segments[i], path }
  }).filter((b) => b.label !== 'dashboard' || b.path === '/dashboard')

  // Fetch notifications
  useEffect(() => {
    const supabase = createClient()
    const fetchNotifications = async () => {
      const { data } = await supabase
        .from('admin_notifications')
        .select('*')
        .order('timestamp', { ascending: false })
        .limit(20)

      if (data) setNotifications(data)
    }

    fetchNotifications()

    // Real-time subscription
    const channel = supabase
      .channel('admin-notifications')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'admin_notifications' },
        (payload) => {
          setNotifications((prev) => [payload.new as AdminNotification, ...prev])
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [])

  // Close dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setShowNotifications(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const markAsRead = async (id: string) => {
    const supabase = createClient()
    await supabase.from('admin_notifications').update({ is_read: true }).eq('id', id)
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
    )
  }

  const markAllRead = async () => {
    const supabase = createClient()
    const unreadIds = notifications.filter((n) => !n.is_read).map((n) => n.id)
    if (unreadIds.length === 0) return
    await supabase
      .from('admin_notifications')
      .update({ is_read: true })
      .in('id', unreadIds)
    setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })))
  }

  return (
    <header className="h-14 border-b border-border bg-card flex items-center justify-between px-6 shrink-0">
      {/* Breadcrumbs */}
      <nav className="flex items-center gap-1.5 text-sm">
        {breadcrumbs.map((crumb, i) => (
          <span key={crumb.path} className="flex items-center gap-1.5">
            {i > 0 && <span className="text-muted-foreground">/</span>}
            <span
              className={cn(
                i === breadcrumbs.length - 1
                  ? 'font-medium text-foreground'
                  : 'text-muted-foreground'
              )}
            >
              {crumb.label}
            </span>
          </span>
        ))}
      </nav>

      {/* Actions */}
      <div className="flex items-center gap-2" ref={dropdownRef}>
        <button
          onClick={() => setShowNotifications(!showNotifications)}
          className="relative w-9 h-9 flex items-center justify-center rounded-lg hover:bg-accent transition-colors"
        >
          <Bell className="w-[18px] h-[18px] text-muted-foreground" />
          {unreadCount > 0 && (
            <span className="absolute top-1 right-1 w-4 h-4 bg-destructive text-destructive-foreground text-[10px] font-bold rounded-full flex items-center justify-center">
              {unreadCount > 9 ? '9+' : unreadCount}
            </span>
          )}
        </button>

        {/* Notifications dropdown */}
        {showNotifications && (
          <div className="absolute right-6 top-14 w-[380px] bg-popover border border-border rounded-xl shadow-lg z-50 overflow-hidden">
            <div className="flex items-center justify-between px-4 py-3 border-b border-border">
              <span className="text-sm font-semibold">Notifications</span>
              <div className="flex items-center gap-2">
                {unreadCount > 0 && (
                  <button
                    onClick={markAllRead}
                    className="text-xs text-primary hover:underline"
                  >
                    Mark all read
                  </button>
                )}
                <button
                  onClick={() => setShowNotifications(false)}
                  className="text-muted-foreground hover:text-foreground"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
            <div className="max-h-[400px] overflow-y-auto">
              {notifications.length === 0 ? (
                <div className="py-8 text-center text-sm text-muted-foreground">
                  No notifications
                </div>
              ) : (
                notifications.map((n) => (
                  <button
                    key={n.id}
                    onClick={() => markAsRead(n.id)}
                    className={cn(
                      'w-full text-left px-4 py-3 border-b border-border last:border-0 hover:bg-accent/50 transition-colors',
                      !n.is_read && 'bg-primary/5'
                    )}
                  >
                    <div className="flex items-start gap-2">
                      {!n.is_read && (
                        <div className="w-2 h-2 rounded-full bg-primary mt-1.5 shrink-0" />
                      )}
                      <div className={cn(!n.is_read ? '' : 'pl-4')}>
                        <p className="text-sm font-medium">{n.title}</p>
                        <p className="text-xs text-muted-foreground mt-0.5 line-clamp-2">
                          {n.message}
                        </p>
                        <p className="text-xs text-muted-foreground mt-1">
                          {timeAgo(n.timestamp)}
                        </p>
                      </div>
                    </div>
                  </button>
                ))
              )}
            </div>
          </div>
        )}
      </div>
    </header>
  )
}
