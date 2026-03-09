import Link from 'next/link'

export default function NotFound() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-foreground">404</h1>
        <p className="text-muted-foreground mt-2">Page not found</p>
        <Link href="/dashboard" className="text-primary text-sm hover:underline mt-4 inline-block">
          Back to Dashboard
        </Link>
      </div>
    </div>
  )
}
