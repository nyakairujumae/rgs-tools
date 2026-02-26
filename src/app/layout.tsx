import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'RGS Tools - Enterprise Management',
  description: 'Professional tool and equipment management for FM, HVAC, and cleaning companies',
  icons: {
    icon: '/icon.png',
    apple: '/icon.png',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className="antialiased">
        {children}
      </body>
    </html>
  )
}
