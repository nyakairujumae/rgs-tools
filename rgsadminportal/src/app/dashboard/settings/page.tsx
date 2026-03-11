'use client'

import { useAuth } from '@/hooks/use-auth'
import { User, Shield, Bell, Palette } from 'lucide-react'

export default function SettingsPage() {
  const { profile } = useAuth()

  return (
    <div className="p-6 max-w-[800px] mx-auto space-y-6">
      <div>
        <h1 className="text-xl font-semibold tracking-tight">Settings</h1>
        <p className="text-sm text-muted-foreground">Manage your account and preferences</p>
      </div>

      {/* Profile */}
      <div className="bg-card border border-border rounded-xl">
        <div className="px-5 py-4 border-b border-border flex items-center gap-2">
          <User className="w-4 h-4 text-muted-foreground" />
          <h2 className="text-sm font-semibold">Profile</h2>
        </div>
        <div className="p-5 space-y-4">
          <div className="grid sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1.5">Full Name</label>
              <input
                type="text"
                defaultValue={profile?.full_name || ''}
                className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1.5">Email</label>
              <input
                type="email"
                defaultValue={profile?.email || ''}
                disabled
                className="w-full h-9 px-3 rounded-lg border border-input bg-muted text-sm text-muted-foreground"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1.5">Phone</label>
              <input
                type="tel"
                defaultValue={profile?.phone || ''}
                className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted-foreground mb-1.5">Department</label>
              <input
                type="text"
                defaultValue={profile?.department || ''}
                className="w-full h-9 px-3 rounded-lg border border-input bg-transparent text-sm"
              />
            </div>
          </div>
          <button className="h-9 px-4 bg-primary text-primary-foreground rounded-lg text-sm font-medium hover:bg-primary/90 transition-colors">
            Save Changes
          </button>
        </div>
      </div>

      {/* Role */}
      <div className="bg-card border border-border rounded-xl">
        <div className="px-5 py-4 border-b border-border flex items-center gap-2">
          <Shield className="w-4 h-4 text-muted-foreground" />
          <h2 className="text-sm font-semibold">Role & Permissions</h2>
        </div>
        <div className="p-5">
          <div className="flex items-center gap-3">
            <span className="text-sm">Role:</span>
            <span className="text-sm font-medium capitalize bg-primary/10 text-primary px-2.5 py-0.5 rounded-md">
              {profile?.role || 'admin'}
            </span>
          </div>
          <p className="text-xs text-muted-foreground mt-2">
            Contact your system administrator to change your role or permissions.
          </p>
        </div>
      </div>
    </div>
  )
}
