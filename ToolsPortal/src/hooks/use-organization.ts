'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import type { Organization } from '@/lib/types/database'

export interface OrgState {
  org: Organization | null
  workerLabel: string
  workerLabelPlural: string
  departments: string[]
  toolCategories: string[]
  /** Uppercase short prefix derived from org name for tool ID generation (e.g. "Linkin" → "LNK") */
  idPrefix: string
  loading: boolean
}

/**
 * Derive a short uppercase prefix from an org name.
 * e.g. "Linkin" → "LNK", "Royal Gulf Services" → "RGS", "Acme Corp" → "ACM"
 */
function derivePrefix(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean)
  if (words.length === 1) {
    // Single word: take first 3 consonants or just first 3 chars
    return words[0].replace(/[aeiou]/gi, '').slice(0, 3).toUpperCase().padEnd(3, words[0].toUpperCase()[0]) || words[0].slice(0, 3).toUpperCase()
  }
  // Multi-word: first letter of each word (up to 4)
  return words.slice(0, 4).map((w) => w[0]).join('').toUpperCase()
}

const defaultState: OrgState = {
  org: null,
  workerLabel: 'Technician',
  workerLabelPlural: 'Technicians',
  departments: [],
  toolCategories: [],
  idPrefix: 'TOOL',
  loading: true,
}

// Module-level cache so org loads once per session
let orgCache: OrgState | null = null

export function useOrganization(organizationId?: string | null): OrgState {
  const [state, setState] = useState<OrgState>(() => orgCache ?? defaultState)

  const load = useCallback(async (orgId: string) => {
    const supabase = createClient()

    try {
      const [orgRes, deptsRes, catsRes] = await Promise.all([
        supabase
          .from('organizations')
          .select('id, name, slug, logo_url, address, phone, website, industry, worker_label, worker_label_plural, setup_completed_at, created_at')
          .eq('id', orgId)
          .single(),
        supabase
          .from('organization_departments')
          .select('name')
          .eq('organization_id', orgId)
          .order('sort_order', { ascending: true }),
        supabase
          .from('organization_tool_categories')
          .select('name')
          .eq('organization_id', orgId)
          .order('sort_order', { ascending: true }),
      ])

      const org = orgRes.data as Organization | null
      const departments = (deptsRes.data ?? []).map((d: { name: string }) => d.name)
      const toolCategories = (catsRes.data ?? []).map((c: { name: string }) => c.name)

      const next: OrgState = {
        org,
        workerLabel: org?.worker_label || 'Technician',
        workerLabelPlural: org?.worker_label_plural || 'Technicians',
        departments,
        toolCategories,
        idPrefix: org?.name ? derivePrefix(org.name) : 'TOOL',
        loading: false,
      }

      orgCache = next
      setState(next)
    } catch {
      // Fall back to defaults — don't block the UI
      const fallback: OrgState = { ...defaultState, loading: false }
      orgCache = fallback
      setState(fallback)
    }
  }, [])

  useEffect(() => {
    if (!organizationId) {
      setState({ ...defaultState, loading: false })
      return
    }
    // If we already have it cached for this org, use it
    if (orgCache && orgCache.org?.id === organizationId) {
      setState(orgCache)
      return
    }
    load(organizationId)
  }, [organizationId, load])

  return state
}

/** Call this on logout to clear the org cache */
export function clearOrganizationCache() {
  orgCache = null
}
