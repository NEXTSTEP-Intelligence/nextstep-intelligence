#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.4 – Stjernemarkeringer..."

cat > frontend/components/StarButton.tsx << 'ENDOFFILE'
'use client'
import { useState } from 'react'

type Props = {
  leadId: string
  initialStars: number
  onStarred?: (stars: number) => void
}

export default function StarButton({ leadId, initialStars, onStarred }: Props) {
  const [stars, setStars] = useState(initialStars || 0)
  const [loading, setLoading] = useState(false)
  const [starred, setStarred] = useState(false)

  const handleStar = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (loading) return
    setLoading(true)
    try {
      const res = await fetch(`/api/leads/${leadId}/star`, { method: 'POST' })
      const data = await res.json()
      setStars(data.stars)
      setStarred(true)
      onStarred?.(data.stars)
      setTimeout(() => setStarred(false), 1500)
    } catch {
      console.error('Star fejl')
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleStar}
      disabled={loading}
      title="Stjernemarkér dette lead"
      style={{
        border: 'none',
        background: 'none',
        cursor: loading ? 'default' : 'pointer',
        display: 'flex',
        alignItems: 'center',
        gap: 4,
        padding: '4px 6px',
        borderRadius: 6,
        transition: 'background 0.15s',
        color: stars > 0 ? '#b8963e' : 'var(--ink-3)',
      }}
    >
      <span style={{ fontSize: 16, transition: 'transform 0.2s', transform: starred ? 'scale(1.4)' : 'scale(1)' }}>
        {stars > 0 ? '★' : '☆'}
      </span>
      {stars > 0 && (
        <span style={{ fontSize: 11, fontWeight: 600, color: '#b8963e' }}>{stars}</span>
      )}
    </button>
  )
}
ENDOFFILE
echo "✓ StarButton.tsx"

# Opdater LeadCard til at inkludere StarButton
cat > frontend/components/LeadCard.tsx << 'ENDOFFILE'
'use client'
import { useState } from 'react'
import { Lead } from '@/app/dashboard/page'
import StarButton from './StarButton'

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
      {isHot && (
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
          <StarButton leadId={lead.id} initialStars={stars} onStarred={setStars} />
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
echo "✓ LeadCard.tsx – med stjerner"

# Opdater Lead type i dashboard
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/app/dashboard/page.tsx'
content = open(path).read()
new = content.replace('  opener: string\n}', '  opener: string\n  stars: number\n}')
open(path, 'w').write(new)
print('✓ Lead type opdateret med stars felt')
"

# Tilføj star endpoint i backend
cat > backend/routers/leads.py << 'ENDOFFILE'
from fastapi import APIRouter
from services.db_service import get_leads, increment_stars

router = APIRouter(prefix="/leads", tags=["leads"])

@router.get("")
async def list_leads(module: str = None, limit: int = 20):
    leads = await get_leads(module=module, limit=limit)
    return {"leads": leads}

@router.post("/{lead_id}/star")
async def star_lead(lead_id: str):
    stars = await increment_stars(lead_id)
    return {"stars": stars}
ENDOFFILE
echo "✓ backend/routers/leads.py – star endpoint"

# Tilføj increment_stars i db_service
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/services/db_service.py'
content = open(path).read()
addition = '''
async def increment_stars(lead_id: str) -> int:
    client = get_client()
    if not client:
        return 0
    try:
        result = client.table(\"leads\").select(\"stars\").eq(\"id\", lead_id).execute()
        current = result.data[0].get(\"stars\", 0) if result.data else 0
        new_stars = current + 1
        client.table(\"leads\").update({\"stars\": new_stars}).eq(\"id\", lead_id).execute()
        return new_stars
    except Exception as e:
        print(f\"Star fejl: {e}\")
        return 0
'''
open(path, 'w').write(content + addition)
print('✓ db_service.py – increment_stars')
"

echo ""
echo "✅ v0.1.4 stjernemarkeringer klar!"
