export const metadata = {
  title: 'Support | RGS Tools',
}

export default function SupportPage() {
  return (
    <div style={{
      margin: 0,
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
      background: '#f5f7fa',
      color: '#111827',
      minHeight: '100vh',
    }}>
      <div style={{
        maxWidth: 760,
        margin: '48px auto',
        padding: '32px 28px',
        background: '#ffffff',
        borderRadius: 14,
        boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
      }}>
        <h1 style={{ margin: '0 0 8px', fontSize: 28 }}>RGS Tools Support</h1>
        <p style={{ lineHeight: 1.7, color: '#374151' }}>Need help? Email us and we will get back to you.</p>

        <div style={{
          marginTop: 16,
          padding: '12px 14px',
          background: '#f0fdf4',
          borderLeft: '4px solid #10b981',
          borderRadius: 8,
          fontSize: 14,
          color: '#374151',
        }}>
          <strong>support@rgstools.app</strong>
        </div>

        <p style={{ lineHeight: 1.7, color: '#374151' }}>Please include:</p>
        <ul style={{ paddingLeft: 20 }}>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>Your account email</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>A short description of the issue</li>
          <li style={{ lineHeight: 1.7, color: '#374151' }}>Screenshots (if possible)</li>
        </ul>
      </div>
    </div>
  )
}
