'use client'

import { createContext, useContext } from 'react'
import type { OrgState } from '@/hooks/use-organization'

const defaultOrgState: OrgState = {
  org: null,
  workerLabel: 'Technician',
  workerLabelPlural: 'Technicians',
  departments: [],
  toolCategories: [],
  idPrefix: 'TOOL',
  loading: true,
}

export const OrganizationContext = createContext<OrgState>(defaultOrgState)

export function useOrgContext(): OrgState {
  return useContext(OrganizationContext)
}
