'use client'

export default function ReviewBanner() {
  const handleApprove = async () => {
    try {
      await fetch('/api/leads/reset-stars', { method: 'POST' })
      const keys = Object.keys(localStorage).filter(k => k.startsWith('star_'))
      keys.forEach(k => localStorage.removeItem(k))
      alert('Rapport godkendt og sendt. Stjerner nulstillet til næste uge.')
    } catch {
      alert('Fejl ved godkendelse – prøv igen.')
    }
  }

  return (
    <div style={{
      background: 'var(--gold-bg)',
      border: '1px solid rgba(184,150,62,0.25)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 18px',
      display: 'flex', alignItems: 'center',
      justifyContent: 'space-between',
      gap: 14, marginBottom: 20,
    }}>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)' }}>Torsdagsrapport klar til review</div>
        <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 2 }}>
          Afventer godkendelse fra Claus eller Rasmus · Stjerner nulstilles ved godkendelse
        </div>
      </div>
      <button onClick={handleApprove} style={{
        fontSize: 12, fontWeight: 500, padding: '7px 18px',
        borderRadius: 8, border: 'none',
        background: 'var(--gold)', color: '#fff',
        cursor: 'pointer', whiteSpace: 'nowrap',
      }}>
        Se &amp; godkend
      </button>
    </div>
  )
}
