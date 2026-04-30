'use client'
type Props = { activeModule: string; setActiveModule: (m: string) => void }
export default function Sidebar({ activeModule, setActiveModule }: Props) {
  const btn = (label: string, value: string, color?: string, small?: boolean) => {
    const active = activeModule === value
    return (
      <button onClick={() => setActiveModule(value)} style={{ width: '100%', textAlign: 'left', padding: small ? '6px 14px' : '7px 14px', borderRadius: 8, fontSize: small ? 12 : 13, border: 'none', background: active ? 'var(--ink)' : 'transparent', color: active ? '#fff' : color || 'var(--ink-3)', fontWeight: active ? 500 : 400, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 9 }}>
        {color && !active && <span style={{ width: 8, height: 8, borderRadius: '50%', background: color, flexShrink: 0, display: 'inline-block' }} />}
        {label}
      </button>
    )
  }
  return (
    <aside style={{ background: 'var(--surface)', padding: '22px 10px', display: 'flex', flexDirection: 'column', gap: 2, borderRight: '1px solid var(--divider)', minHeight: '100vh' }}>
      <div style={{ padding: '4px 14px 20px', marginBottom: 4 }}>
        <div style={{ fontSize: 10, letterSpacing: '0.12em', color: 'var(--ink-3)', textTransform: 'uppercase', marginBottom: 4 }}>NEXTSTEP</div>
        <div style={{ fontSize: 17, fontWeight: 700, color: 'var(--ink)', letterSpacing: '-0.02em' }}>Intelligence</div>
        <div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 1 }}>Scout NS · v0.1</div>
      </div>
      <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Overblik</div>
      {btn('Alle moduler', 'alle')}
      <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Moduler</div>
        {btn('Public Affairs', 'pa', 'var(--pa)')}
        {btn('Velfærd', 'vel', 'var(--vel)')}
        <button style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', fontStyle: 'italic', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 9 }}>
          <span style={{ width: 8, height: 8, borderRadius: '50%', border: '1px dashed #ccc', flexShrink: 0, display: 'inline-block' }} />+ Nyt modul
        </button>
      </div>
      <div style={{ marginTop: 14, paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Sektorer</div>
        {['Sundhed','Fødevarer','Energi & forsyning','Klima','Kommuner'].map(s => (
          <button key={s} style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', cursor: 'pointer' }}>{s}</button>
        ))}
        <button style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-2)', cursor: 'pointer' }}>+ Tilføj sektor</button>
      </div>
      <div style={{ marginTop: 'auto', paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        {['Rapport-arkiv','Indstillinger'].map(s => (
          <button key={s} style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', cursor: 'pointer' }}>{s}</button>
        ))}
        <button style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-2)', fontWeight: 500, cursor: 'pointer' }}>Afventer godkendelse (1)</button>
      </div>
    </aside>
  )
}
