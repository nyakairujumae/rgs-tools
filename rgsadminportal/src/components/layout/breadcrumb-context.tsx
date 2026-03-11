'use client'

import { createContext, useContext, useState, useCallback, type ReactNode } from 'react'

type BreadcrumbContextValue = {
  label: string | null
  setLabel: (label: string | null) => void
}

const BreadcrumbLabelContext = createContext<BreadcrumbContextValue | null>(null)

export function BreadcrumbLabelProvider({ children }: { children: ReactNode }) {
  const [label, setLabelState] = useState<string | null>(null)
  const setLabel = useCallback((l: string | null) => setLabelState(l), [])
  return (
    <BreadcrumbLabelContext.Provider value={{ label, setLabel }}>
      {children}
    </BreadcrumbLabelContext.Provider>
  )
}

export function useBreadcrumbLabel() {
  return useContext(BreadcrumbLabelContext)
}
