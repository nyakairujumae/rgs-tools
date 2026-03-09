import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatAED(amount: number | undefined | null): string {
  if (amount == null) return 'AED 0.00'
  return `AED ${amount.toLocaleString('en-AE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
}

export function formatDate(dateStr: string | undefined | null): string {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

export function formatDateTime(dateStr: string | undefined | null): string {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

export function timeAgo(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (seconds < 60) return 'Just now'
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`
  if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`
  return formatDate(dateStr)
}

export function getStatusColor(status: string): string {
  const map: Record<string, string> = {
    'Available': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'In Use': 'bg-blue-500/15 text-blue-700 dark:text-blue-400',
    'Maintenance': 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    'Retired': 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400',
    'Open': 'bg-red-500/15 text-red-700 dark:text-red-400',
    'In Progress': 'bg-blue-500/15 text-blue-700 dark:text-blue-400',
    'Resolved': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'Closed': 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400',
    'Pending': 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    'Approved': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'Rejected': 'bg-red-500/15 text-red-700 dark:text-red-400',
    'Cancelled': 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400',
    'Scheduled': 'bg-blue-500/15 text-blue-700 dark:text-blue-400',
    'Completed': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'Overdue': 'bg-red-500/15 text-red-700 dark:text-red-400',
    'Valid': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'Expired': 'bg-red-500/15 text-red-700 dark:text-red-400',
    'Expiring Soon': 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    'Active': 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-400',
    'Inactive': 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400',
  }
  return map[status] || 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400'
}

export function getPriorityColor(priority: string): string {
  const map: Record<string, string> = {
    'Low': 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400',
    'Medium': 'bg-blue-500/15 text-blue-700 dark:text-blue-400',
    'High': 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    'Critical': 'bg-red-500/15 text-red-700 dark:text-red-400',
  }
  return map[priority] || 'bg-neutral-500/15 text-neutral-700 dark:text-neutral-400'
}
