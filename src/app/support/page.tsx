import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Support | RGS Tools',
}

export default function SupportPage() {
  return (
    <main className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-2xl mx-auto bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">RGS Tools Support</h1>
        <p className="text-gray-600 leading-relaxed mb-4">
          Need help? Email us and we will get back to you.
        </p>

        <div className="bg-green-50 border-l-4 border-green-600 rounded-lg px-4 py-3 text-sm font-semibold text-gray-800 mb-6">
          support@rgstools.app
        </div>

        <p className="text-gray-600 mb-2">Please include:</p>
        <ul className="list-disc pl-5 space-y-1 text-gray-600 leading-relaxed">
          <li>Your account email</li>
          <li>A short description of the issue</li>
          <li>Screenshots (if possible)</li>
        </ul>
      </div>
    </main>
  )
}
