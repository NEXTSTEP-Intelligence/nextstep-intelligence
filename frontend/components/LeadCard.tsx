import { Lead } from '@/app/dashboard/page'
type Props = { lead: Lead }
const MC = {
  public_affairs: { border: 'var(--pa)', chip: '#1a1a1a', chipText: '#f5f0e8', score: 'var(--pa)', sbg: '#f5f3ef', slabel: '#666', dot: '#1a1a1a' },
  velfaerd: { border: 'var(--vel)', chip: 'var(--vel-bg)', chipText: 'var(--vel)', score: 'var(--vel)', sbg: 'var(--vel-bg)', slabel: 'var(--vel)', dot: 'var(--vel)' },
}
const OC: Record<string, {bg:string;color:string}> = {
  Alliance: { bg: '#f9f3e8', color: '#b8963e' },
  Camp: { bg: '#ede8f5', color: '#5c3d99' },
  'Entreprenør': { bg: '#fdeee8', color: '#a0430a' },
}
export default function LeadCard({ lead }: Props) {
  const mc = MC[lead.module]
  const oc = OC[lead.opgave_type] || { bg: '#f0f0f0', color: '#666' }
  const moduleLabel = lead.module === 'public_affairs' ? 'Public Affairs' : 'Velfærd'
  const Dot = ({ color }: { color: string }) => <span style={{ width: 4, height: 4, borderRadius: '50%', background: color, flexShrink: 0, marginTop: 6, display: 'inline-block' }} />
  return (
    <div style={{ background: 'var(--surface)', borderRadius: 'var(--radius-lg)', padding: '1.2rem 1.35rem', marginBottom: 10, border: '1px solid rgba(0,0,0,0.06)', borderLeftWidth: 3, borderLeftColor: mc.border }}>
      <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 20, background: mc.chip, color: mc.chipText }}>{moduleLabel}</span>
            <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 20, background: oc.bg, color: oc.color }}>{lead.opgave_type}</span>
            <span style={{ fontSize: 11, fontWeight: 500, padding: '3px 10px', borderRadius: 20, background: 'rgba(0,0,0,0.05)', color: 'var(--ink-2)' }}>{lead.sector}</span>
            <span style={{ fontSize: 11, color: 'var(--ink-3)' }}>{lead.source} · {lead.published_at}</span>
          </div>
          <h2 style={{ fontSize: 14, fontWeight: 600, color: 'var(--ink)', marginBottom: 5, letterSpacing: '-0.01em', lineHeight: 1.4 }}>{lead.title}</h2>
          <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6, marginBottom: 11 }}>{lead.summary}</p>
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
              <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>Guldkatalog:{' '}
                {lead.gold_matches.map((m, i) => <span key={i}><span style={{ color: 'var(--gold)', fontWeight: 500 }}>{m.title} ({m.pct}%)</span>{i < lead.gold_matches.length - 1 ? ' · ' : ''}</span>)}
              </div>
            )}
            <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>Åbner: <span style={{ color: 'var(--ink)', fontWeight: 500 }}>{lead.opener}</span></div>
          </div>
        </div>
        <div style={{ textAlign: 'right', flexShrink: 0, minWidth: 64 }}>
          <div style={{ fontSize: 10, color: 'var(--ink-3)', marginBottom: 4, textTransform: 'uppercase', letterSpacing: '0.07em' }}>Score</div>
          <div style={{ fontSize: 28, fontWeight: 700, color: mc.score, letterSpacing: '-0.03em' }}>{lead.score}</div>
          <div style={{ fontSize: 10, color: 'var(--ink-3)', marginTop: 5, lineHeight: 1.6 }}>{lead.size_info}<br />{lead.cvr_verified ? 'CVR ✓' : ''}</div>
        </div>
      </div>
    </div>
  )
}
