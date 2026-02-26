import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Privacy Policy | RGS Tools',
}

export default function PrivacyPage() {
  return (
    <main className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-3xl mx-auto bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-1">Privacy Policy</h1>
        <p className="text-sm text-gray-500 mb-6">Last updated: 1st January 2026</p>

        <p className="text-gray-600 leading-relaxed mb-6">
          RGS Tools (&ldquo;we&rdquo;, &ldquo;our&rdquo;, &ldquo;us&rdquo;) respects your privacy. This policy explains
          what data we collect, why we collect it, and how it is used.
        </p>

        <section className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">Information We Collect</h2>
          <ul className="list-disc pl-5 space-y-1 text-gray-600 leading-relaxed">
            <li>Account details: name, email, role/position, department.</li>
            <li>App usage data: actions inside the app (tools assigned, approvals, reports).</li>
            <li>Device data: basic device identifiers used for authentication and notifications.</li>
            <li>Images: photos of tools or technician profiles uploaded by admins.</li>
          </ul>
        </section>

        <section className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">How We Use Data</h2>
          <ul className="list-disc pl-5 space-y-1 text-gray-600 leading-relaxed">
            <li>To create and manage user accounts.</li>
            <li>To manage tools, assignments, approvals, and reports.</li>
            <li>To send notifications related to requests and approvals.</li>
            <li>To improve app reliability and security.</li>
          </ul>
        </section>

        <section className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">Data Storage</h2>
          <p className="text-gray-600 leading-relaxed">
            Data is stored securely in Supabase infrastructure. Images are stored in
            secure storage buckets.
          </p>
        </section>

        <section className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">Data Sharing</h2>
          <p className="text-gray-600 leading-relaxed">
            We do not sell or rent your data. Data is only shared with service providers
            required to run the app (for example, Supabase and Firebase).
          </p>
        </section>

        <section className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">User Rights</h2>
          <p className="text-gray-600 leading-relaxed">
            You can request access, correction, or deletion of your account data. You
            can request export of your data by contacting support.
          </p>
        </section>

        <section className="mb-5">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">Security</h2>
          <p className="text-gray-600 leading-relaxed">
            We apply standard security measures to protect your data, including authentication,
            access controls, and encrypted connections.
          </p>
        </section>

        <section className="mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-2">Children&apos;s Privacy</h2>
          <p className="text-gray-600 leading-relaxed">RGS Tools is not intended for children under 13.</p>
        </section>

        <div className="bg-green-50 border-l-4 border-green-600 rounded-lg px-4 py-3 text-sm text-gray-700">
          Contact us at <strong>support@rgstools.app</strong> for privacy questions.
        </div>
      </div>
    </main>
  )
}
