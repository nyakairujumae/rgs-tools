import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'RGS Tools Admin',
    short_name: 'RGS Admin',
    description: 'RGS HVAC Services Tools Management Portal',
    start_url: '/dashboard',
    display: 'standalone',
    background_color: '#000000',
    theme_color: '#059669',
    orientation: 'portrait',
    icons: [
      { src: '/icon.png', sizes: '192x192', type: 'image/png' },
      { src: '/icon.png', sizes: '512x512', type: 'image/png', purpose: 'any maskable' },
    ],
  }
}
