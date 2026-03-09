import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'npgwikkvtxebzwtpzwgx.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },
  webpack: (config) => {
    // jspdf optionally depends on canvg (for SVG rendering) which has deep deps we don't need
    config.resolve.alias = {
      ...config.resolve.alias,
      canvg: false,
    }
    return config
  },
}

export default nextConfig
