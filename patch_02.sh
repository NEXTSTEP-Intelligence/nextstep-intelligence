#!/bin/bash
cd ~/nextstep-intelligence
echo "Opdaterer LeadCard og Sidebar..."

cat > frontend/components/LeadCard.tsx << 'ENDOFFILE'
'use client'
import { useState } from 'react'
import { Lead } from '@/app/dashboard/page'

type Props = { lead: Lead }

const MC = {
  public_affairs: { border: 'var(--pa)', chip: '#1a1a1a', chipText: '#f5f0e8', score: 'var(--pa)', sbg: '#f5f3ef', slabel: '#666', dot: '#1a1a1a' },
  velfaerd: { border: 'var(--vel)', chip: 'var(--vel-bg)', chipText: 'var(--vel)', score: 'var(--vel)', sbg: 'var(--vel-bg)', slabel: 'var(--vel)', dot: 'var(--vel)' },
}
const OC: Record<string, { bg: string; color: string }> = {
  Alliance: { bg: '#f9f3e8', color: '#b8963e' },
  Camp: { bg: '#ede8f5', color: '#5c3d99' },
  'Entreprenør': { bg: '#fdeee8', color: '#a0430a' },
}

export default function LeadCard({ lead }: Props) {
  const [expanded, setExpanded] = useState(false)
  const mc = MC[lead.module]
  const oc = OC[lead.opgave_type] || { bg: '#f0f0f0', color: '#666' }
  const moduleLabel = lead.module === 'public_affairs' ? 'Public Affairs' : 'Velfærd'
  const Dot = ({ color }: { color: string }) => (
    <span style={{ width: 4, height: 4, borderRadius: '50%', background: color, flexShrink: 0, marginTop: 6, display: 'inline-block' }} />
  )

  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-lg)', marginBottom: 8, border: '1px solid rgba(0,0,0,0.06)', borderLeftWidth: 3, borderLeftColor: mc.border, overflow: 'hidden' }}>
      <div onClick={() => setExpanded(!expanded)} style={{ padding: '14px 16px', cursor: 'pointer', display: 'flex', gap: 12, alignItems: 'flex-start' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', alignItems: 'center', marginBottom: 6 }}>
            <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 20, background: mc.chip, color: mc.chipText }}>{moduleLabel}</span>
            <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 20, background: oc.bg, color: oc.color }}>{lead.opgave_type}</span>
            <span style={{ fontSize: 10, fontWeight: 500, padding: '2px 8px', borderRadius: 20, background: 'rgba(0,0,0,0.05)', color: 'var(--ink-2)' }}>{lead.sector}</span>
            {lead.url ? (
              <a href={lead.url} target="_blank" rel="noopener noreferrer" onClick={e => e.stopPropagation()} style={{ fontSize: 10, color: 'var(--ink-3)', textDecoration: 'none', borderBottom: '1px solid rgba(0,0,0,0.15)' }}>
                {lead.source} · {lead.published_at} ↗
              </a>
            ) : (
              <span style={{ fontSize: 10, color: 'var(--ink-3)' }}>{lead.source} · {lead.published_at}</span>
            )}
          </div>
          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)', letterSpacing: '-0.01em', lineHeight: 1.4 }}>{lead.title}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexShrink: 0 }}>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 10, color: 'var(--ink-3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>Score</div>
            <div style={{ fontSize: 22, fontWeight: 700, color: mc.score, letterSpacing: '-0.02em', lineHeight: 1.1 }}>{lead.score}</div>
          </div>
          <div style={{ fontSize: 14, color: 'var(--ink-3)', transition: 'transform 0.2s', transform: expanded ? 'rotate(180deg)' : 'rotate(0deg)' }}>↓</div>
        </div>
      </div>

      {expanded && (
        <div style={{ padding: '0 16px 16px', borderTop: '1px solid rgba(0,0,0,0.05)' }}>
          <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6, margin: '12px 0' }}>{lead.summary}</p>

          <div style={{ background: mc.sbg, borderRadius: 10, padding: '10px 13px', marginBottom: 10 }}>
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: mc.slabel, marginBottom: 7 }}>Centrale interessenter</div>
            {lead.stakeholders.map((s, i) => (
              <div key={i} style={{ display: 'flex', gap: 7, fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5, padding: '2px 0' }}>
                <Dot color={mc.dot} /><span><strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{s.name}</strong> — {s.role}</span>
              </div>
            ))}
          </div>

          {lead.potential_partners.length > 0 && (
            <div style={{ background: 'rgba(184,150,62,0.07)', borderRadius: 10, padding: '10px 13px', marginBottom: 10 }}>
              <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: 'var(--gold)', marginBottom: 7 }}>Potentielle medspillere</div>
              {lead.potential_partners.map((p, i) => (
                <div key={i} style={{ display: 'flex', gap: 7, fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5, padding: '2px 0' }}>
                  <Dot color="var(--gold)" /><span><strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{p.name}</strong> — {p.role}</span>
                </div>
              ))}
            </div>
          )}

          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 14, alignItems: 'center' }}>
            {lead.gold_matches.length > 0 && (
              <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>
                Guldkatalog:{' '}
                {lead.gold_matches.map((m, i) => (
                  <span key={i}><span style={{ color: 'var(--gold)', fontWeight: 500 }}>{m.title} ({m.pct}%)</span>{i < lead.gold_matches.length - 1 ? ' · ' : ''}</span>
                ))}
              </div>
            )}
            <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>Vej ind: <span style={{ color: 'var(--ink)', fontWeight: 500 }}>{lead.opener}</span></div>
            <div style={{ fontSize: 10, color: 'var(--ink-3)', marginLeft: 'auto' }}>{lead.size_info}{lead.cvr_verified ? ' · CVR ✓' : ''}</div>
          </div>
        </div>
      )}
    </div>
  )
}
ENDOFFILE
echo "✓ LeadCard.tsx – expandable"

cat > frontend/components/Sidebar.tsx << 'ENDOFFILE'
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
        <div style={{ fontSize: 10, letterSpacing: '0.09em', color: 'var(--ink-3)', textTransform: 'uppercase', padding: '0 14px', marginBottom: 3 }}>Sektorer</div>
        {['Sundhed', 'Fødevarer', 'Energi & forsyning', 'Klima', 'Kommuner'].map(s => (
          <button key={s} style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-3)', cursor: 'pointer' }}>{s}</button>
        ))}
        <button style={{ width: '100%', textAlign: 'left', padding: '6px 14px', borderRadius: 8, fontSize: 12, border: 'none', background: 'transparent', color: 'var(--ink-2)', cursor: 'pointer' }}>+ Tilføj sektor</button>
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
ENDOFFILE
echo "✓ Sidebar.tsx – mobilvenlig"

echo ""
echo "✅ Færdig!"
