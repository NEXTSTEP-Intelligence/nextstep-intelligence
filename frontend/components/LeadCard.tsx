'use client'
import { useState } from 'react'
import { Lead } from '@/app/dashboard/page'
import StarButton from './StarButton'

type Props = { lead: Lead, hideStars?: boolean }

const MC = {
  public_affairs: { border: 'var(--pa)', chip: '#1a1a1a', chipText: '#f5f0e8', score: 'var(--pa)', sbg: '#f5f3ef', slabel: '#666', dot: '#1a1a1a' },
  velfaerd: { border: 'var(--vel)', chip: 'var(--vel-bg)', chipText: 'var(--vel)', score: 'var(--vel)', sbg: 'var(--vel-bg)', slabel: 'var(--vel)', dot: 'var(--vel)' },
}
const OC: Record<string, { bg: string; color: string }> = {
  Alliance: { bg: '#f9f3e8', color: '#b8963e' },
  Camp: { bg: '#ede8f5', color: '#5c3d99' },
  'Entreprenør': { bg: '#fdeee8', color: '#a0430a' },
}

export default function LeadCard({ lead, hideStars }: Props) {
  const [expanded, setExpanded] = useState(false)
  const [stars, setStars] = useState(lead.stars || 0)
  const mc = MC[lead.module]
  const oc = OC[lead.opgave_type] || { bg: '#f0f0f0', color: '#666' }
  const moduleLabel = lead.module === 'public_affairs' ? 'Public Affairs' : 'Velfærd'
  const Dot = ({ color }: { color: string }) => (
    <span style={{ width: 4, height: 4, borderRadius: '50%', background: color, flexShrink: 0, marginTop: 6, display: 'inline-block' }} />
  )
  const isHot = stars >= 2

  return (
    <div style={{
      background: 'var(--surface)',
      borderRadius: 'var(--radius-lg)',
      marginBottom: 8,
      border: isHot ? '1px solid rgba(184,150,62,0.4)' : '1px solid rgba(0,0,0,0.06)',
      borderLeftWidth: 3,
      borderLeftColor: mc.border,
      overflow: 'hidden',
    }}>
      {isHot && !hideStars && (
        <div style={{ background: 'var(--gold-bg)', padding: '4px 16px', fontSize: 11, color: '#b8963e', fontWeight: 500 }}>
          ★ Populært lead – markeret af {stars} person{stars !== 1 ? 'er' : ''}
        </div>
      )}
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
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexShrink: 0 }}>
          {!hideStars && <StarButton leadId={lead.id} initialStars={stars} onToggle={(s) => setStars(s)} />}
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontSize: 10, color: 'var(--ink-3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>
              {lead.client_score ? 'Klient' : 'Score'}
            </div>
            <div style={{ fontSize: 22, fontWeight: 700, color: lead.client_score ? '#c47a7a' : 'var(--ink)', letterSpacing: '-0.02em', lineHeight: 1.1 }}>
              {lead.client_score ?? lead.score}
            </div>
          </div>
          <div style={{ fontSize: 14, color: 'var(--ink-3)', transition: 'transform 0.2s', transform: expanded ? 'rotate(180deg)' : 'rotate(0deg)' }}>↓</div>
        </div>
      </div>

      {expanded && (
        <div style={{ padding: '0 16px 16px', borderTop: '1px solid rgba(0,0,0,0.05)' }}>
          <p style={{ fontSize: 13, color: 'var(--ink-2)', lineHeight: 1.6, margin: '12px 0' }}>{lead.summary}</p>

          <div style={{ background: mc.sbg, borderRadius: 10, padding: '10px 13px', marginBottom: 10 }}>
            <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.09em', textTransform: 'uppercase', color: mc.slabel, marginBottom: 7 }}>Centrale interessenter</div>
            {lead.stakeholders?.map((s, i) => (
              <div key={i} style={{ display: 'flex', gap: 7, fontSize: 12, color: 'var(--ink-2)', lineHeight: 1.5, padding: '2px 0' }}>
                <Dot color={mc.dot} /><span><strong style={{ color: 'var(--ink)', fontWeight: 500 }}>{s.name}</strong> — {s.role}</span>
              </div>
            ))}
          </div>

          {lead.potential_partners?.length > 0 && (
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
            {lead.gold_matches?.length > 0 && (
              <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>
                NEXTSTEP Erfaringer:{' '}
                {lead.gold_matches.map((m, i) => {
                  const raw = typeof m === 'string' ? m : (m.title || String(m))
                  const clean = raw.replace(/Aktuel kunde – |Tidligere case – /gi, '').replace(/\.pdf|\.docx|\.pptx/gi, '').replace(/\s*\([^)]*\)\s*/g, ' ').trim()
                  return (
                    <span key={i}><span style={{ color: 'var(--gold)', fontWeight: 500 }}>{clean}</span>{i < lead.gold_matches.length - 1 ? ' · ' : ''}</span>
                  )
                })}
              </div>
            )}
            <div style={{ fontSize: 12, color: 'var(--ink-3)' }}>
            Vej ind: <span style={{ color: 'var(--ink)', fontWeight: 500 }}>
              {lead.client_opener || lead.opener}
            </span>
          </div>
          {lead.client_relevance && (
            <div style={{ fontSize: 11, color: '#b8963e', marginTop: 4, fontStyle: 'italic' }}>
              {lead.client_relevance}
            </div>
          )}
            <div style={{ fontSize: 10, color: 'var(--ink-3)', marginLeft: 'auto' }}>{lead.size_info}{lead.size_info === 'Offentlig instans' ? '' : lead.cvr_verified ? ' · CVR ✓' : ''}</div>
          </div>
        </div>
      )}
    </div>
  )
}
