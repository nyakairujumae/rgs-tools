export const metadata = {
  title: 'Privacy Policy | RGS Tools',
}

export default function PrivacyPage() {
  return (
    <div style={{
      margin: 0,
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
      background: '#f5f7fa',
      color: '#111827',
      minHeight: '100vh',
    }}>
      <div style={{
        maxWidth: 860,
        margin: '48px auto',
        padding: '32px 28px',
        background: '#ffffff',
        borderRadius: 14,
        boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
      }}>
        <h1 style={{ margin: '0 0 8px', fontSize: 30 }}>Privacy Policy</h1>
        <div style={{ color: '#6b7280', marginBottom: 24, fontSize: 14 }}>Last updated: 1st January 2026</div>

        <p>RGS Tools (&quot;we&quot;, &quot;our&quot;, &quot;us&quot;) respects your privacy. This policy explains what data we collect, why we collect it, and how it is used.</p>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>Information We Collect</h2>
        <ul style={{ paddingLeft: 20 }}>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>Account details: name, email, role/position, department.</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>App usage data: actions inside the app (tools assigned, approvals, reports).</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>Device data: basic device identifiers used for authentication and notifications.</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>Images: photos of tools or technician profiles uploaded by admins.</li>
        </ul>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>How We Use Data</h2>
        <ul style={{ paddingLeft: 20 }}>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>To create and manage user accounts.</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>To manage tools, assignments, approvals, and reports.</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>To send notifications related to requests and approvals.</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>To improve app reliability and security.</li>
        </ul>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>Data Storage</h2>
        <p style={{ lineHeight: 1.7, color: '#374151' }}>Data is stored securely in Supabase infrastructure. Images are stored in secure storage buckets.</p>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>Data Sharing</h2>
        <p style={{ lineHeight: 1.7, color: '#374151' }}>We do not sell or rent your data. Data is only shared with service providers required to run the app (for example, Supabase and Firebase).</p>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>User Rights</h2>
        <p style={{ lineHeight: 1.7, color: '#374151' }}>You can request access, correction, or deletion of your account data. You can request export of your data by contacting support.</p>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>Security</h2>
        <p style={{ lineHeight: 1.7, color: '#374151' }}>We apply standard security measures to protect your data, including authentication, access controls, and encrypted connections.</p>

        <h2 style={{ fontSize: 18, marginTop: 24 }}>{"Children's Privacy"}</h2>
        <p style={{ lineHeight: 1.7, color: '#374151' }}>RGS Tools is not intended for children under 13.</p>

        <div style={{
          marginTop: 24,
          padding: '12px 14px',
          background: '#f0fdf4',
          borderLeft: '4px solid #10b981',
          borderRadius: 8,
          fontSize: 14,
          color: '#374151',
        }}>
          Contact us at <strong>support@rgstools.app</strong> for privacy questions.
        </div>
      </div>
    </div>
  )
}
