export default function ReviewBanner() {
  return (
    <div style={{ background: 'var(--gold-bg)', border: '1px solid rgba(184,150,62,0.25)', borderRadius: 'var(--radius-md)', padding: '12px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 14, marginBottom: 20 }}>
      <div>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)' }}>Torsdagsrapport klar til review</div>
        <div style={{ fontSize: 11, color: 'var(--ink-2)', marginTop: 2 }}>4 leads · Afventer godkendelse af Rasmus eller direktøren inden udsendelse</div>
      </div>
      <button style={{ fontSize: 12, fontWeight: 500, padding: '7px 18px', borderRadius: 8, border: 'none', background: 'var(--gold)', color: '#fff', cursor: 'pointer', whiteSpace: 'nowrap' }}>
        Se &amp; godkend
      </button>
    </div>
  )
}
