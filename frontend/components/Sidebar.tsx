'use client'
import { useState } from 'react'

type Props = { activeModule: string; setActiveModule: (m: string) => void }

export default function Sidebar({ activeModule, setActiveModule }: Props) {
  const [mobileOpen, setMobileOpen] = useState(false)

  const btn = (label: string, value: string, color?: string, small?: boolean) => {
    const active = activeModule === value
    return (
      <button onClick={() => { setActiveModule(value); setMobileOpen(false) }} style={{
        width: '100%', textAlign: 'left', padding: small ? '6px 14px' : '7px 14px',
        borderRadius: 8, fontSize: small ? 12 : 13, border: 'none',
        background: active ? 'var(--ink)' : 'transparent',
        color: active ? '#fff' : color || 'var(--ink-3)',
        fontWeight: active ? 500 : 400, cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 9,
      }}>
        {color && !active && <span style={{ width: 8, height: 8, borderRadius: '50%', background: color, flexShrink: 0, display: 'inline-block' }} />}
        {label}
      </button>
    )
  }

  const navContent = (
    <>
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
        <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Sektorer & Fokus</div>
        {[
          { label: 'BESKÆFTIGELSE', sub: '' },
          { label: 'BY OG BOLIG', sub: 'Urban Rigger · Trivsel' },
          { label: 'ENERGI', sub: 'Fjernvarme · Geotermi · Vand' },
          { label: 'FØDEVARER', sub: 'Økologi · Skolemad' },
          { label: 'KLIMA', sub: 'Fiskeri' },
          { label: 'SIKKERHED', sub: 'Beredskab · Arktis' },
          { label: 'SUNDHED', sub: 'Ældre · Psykiatri · Trivsel · Arktis' },
        ].map(s => (
          <button key={s.label} onClick={() => { const key = s.label.toLowerCase().replace(/ /g, '_'); setActiveModule(activeModule === key ? 'alle' : key) }} style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: activeModule === s.label.toLowerCase().replace(/ /g, '_') ? 'var(--ink)' : 'transparent', color: activeModule === s.label.toLowerCase().replace(/ /g, '_') ? '#fff' : 'var(--ink-3)', cursor: 'pointer', lineHeight: 1.4 }}>
            <div style={{ fontWeight: 500 }}>{s.label}</div>
            {s.sub && <div style={{ fontSize: 10, opacity: 0.7 }}>{s.sub}</div>}
          </button>
        ))}
      </div>
      <div style={{ marginTop: 'auto', paddingTop: 12, borderTop: '1px solid var(--divider)' }}>
        {['Rapport-arkiv', 'Indstillinger'].map(s => (
          <button key={s} style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', cursor: 'pointer' }}>{s}</button>
        ))}
        <button style={{ width: '100%', textAlign: 'left', padding: '7px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-2)', fontWeight: 500, cursor: 'pointer' }}>Afventer godkendelse (1)</button>
      </div>
    </>
  )

  return (
    <>
      <div className="ns-mobile-bar">
        <div>
          <div style={{ fontSize: 9, letterSpacing: '0.12em', color: 'var(--ink-3)', textTransform: 'uppercase' }}>NEXTSTEP</div>
          <div style={{ fontSize: 15, fontWeight: 700, color: 'var(--ink)', letterSpacing: '-0.02em' }}>Intelligence</div>
        </div>
        <button onClick={() => setMobileOpen(!mobileOpen)} style={{ border: 'none', background: 'none', cursor: 'pointer', fontSize: 22, color: 'var(--ink)', padding: '4px 8px' }}>
          {mobileOpen ? '✕' : '☰'}
        </button>
      </div>

      {mobileOpen && (
        <div className="ns-mobile-drawer">
          {navContent}
        </div>
      )}

      <aside className="ns-desktop-sidebar">
        {navContent}
      </aside>

      <style>{`
        .ns-mobile-bar {
          display: none;
          position: fixed; top: 0; left: 0; right: 0; z-index: 100;
          background: var(--surface); border-bottom: 1px solid var(--divider);
          padding: 12px 16px; align-items: center; justify-content: space-between;
        }
        .ns-mobile-drawer {
          position: fixed; top: 52px; left: 0; right: 0; bottom: 0; z-index: 99;
          background: var(--surface); padding: 16px 10px; overflow-y: auto;
          display: flex; flex-direction: column; gap: 2px;
        }
        .ns-desktop-sidebar {
          background: var(--surface); padding: 22px 10px;
          display: flex; flex-direction: column; gap: 2px;
          border-right: 1px solid var(--divider); min-height: 100vh;
        }
        @media (max-width: 768px) {
          .ns-mobile-bar { display: flex !important; }
          .ns-desktop-sidebar { display: none !important; }
        }
      `}</style>
    </>
  )
}
