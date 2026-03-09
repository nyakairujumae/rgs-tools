'use client'

import { useParams, useRouter } from 'next/navigation'
import { ArrowLeft } from 'lucide-react'

export default function TechnicianDetailPage() {
  const { id } = useParams()
  const router = useRouter()

  return (
    <div className="p-6 max-w-[1200px] mx-auto">
      <button
        onClick={() => router.back()}
        className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors mb-4"
      >
        <ArrowLeft className="w-4 h-4" /> Back to technicians
      </button>
      <h1 className="text-xl font-semibold">Technician Detail</h1>
      <p className="text-sm text-muted-foreground mt-1">ID: {id}</p>
    </div>
  )
}
