#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.2.1 – Klientlinse..."

# Opret Klientlinse endpoint i backend
cat > backend/routers/klientlinse.py << 'ENDOFFILE'
from fastapi import APIRouter
from services.db_service import get_leads
from services.klientlinse_service import analyze_client_perspective

router = APIRouter(prefix="/klientlinse", tags=["klientlinse"])

@router.post("/analyze")
async def analyze(body: dict):
    client_name = body.get("client_name", "").strip()
    if not client_name:
        return {"leads": []}
    
    leads = await get_leads(limit=20, sort="score")
    if not leads:
        return {"leads": []}
    
    result = await analyze_client_perspective(client_name, leads)
    return {"leads": result, "client_name": client_name}
ENDOFFILE
echo "✓ routers/klientlinse.py"

# Opret klientlinse service
cat > backend/services/klientlinse_service.py << 'ENDOFFILE'
import anthropic
import json
import os

def get_client():
    return anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def analyze_client_perspective(client_name: str, leads: list) -> list:
    client = get_client()
    
    leads_text = "\n".join([
        f"ID: {l.get('id')}\nTitel: {l.get('title')}\nResumé: {l.get('summary', '')[:200]}\nSektor: {l.get('sector')}\nScore: {l.get('score')}\nVej ind: {l.get('opener')}"
        for l in leads
    ])
    
    prompt = f"""Du er strategisk rådgiver hos NEXTSTEP A/S. En kollega vil se alle aktuelle leads fra {client_name}'s perspektiv.

Analyser hvert lead og vurder:
1. Hvor relevant er dette lead specifikt for {client_name}?
2. Hvad er den bedste indgangsvinkel for {client_name} i denne situation?

AKTUELLE LEADS:
{leads_text}

Svar KUN med JSON array – ét objekt per lead i samme rækkefølge:
[
  {{
    "id": "lead-id",
    "client_score": 0-100,
    "client_opener": "specifik indgangsvinkel for {client_name}",
    "client_relevance": "én sætning om hvorfor dette er relevant for {client_name}"
  }}
]"""

    try:
        response = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=2000,
            messages=[{"role": "user", "content": prompt}]
        )
        text = response.content[0].text.strip()
        if "```" in text:
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        
        analysis = json.loads(text)
        analysis_map = {a["id"]: a for a in analysis}
        
        result = []
        for lead in leads:
            lead_id = lead.get("id")
            if lead_id in analysis_map:
                a = analysis_map[lead_id]
                lead_copy = dict(lead)
                lead_copy["client_score"] = a.get("client_score", lead.get("score", 0))
                lead_copy["client_opener"] = a.get("client_opener", lead.get("opener", ""))
                lead_copy["client_relevance"] = a.get("client_relevance", "")
                result.append(lead_copy)
            else:
                result.append(lead)
        
        result.sort(key=lambda x: x.get("client_score", 0), reverse=True)
        return result
        
    except Exception as e:
        print(f"Klientlinse fejl: {e}")
        return leads
ENDOFFILE
echo "✓ services/klientlinse_service.py"

# Tilføj klientlinse router til main.py
python3.12 - << 'PYEOF'
path = '/Users/rmk/nextstep-intelligence/backend/main.py'
content = open(path).read()
content = content.replace(
    'from routers import leads, scraper, reports, settings',
    'from routers import leads, scraper, reports, settings, klientlinse'
)
content = content.replace(
    'app.include_router(settings.router)',
    'app.include_router(settings.router)\napp.include_router(klientlinse.router)'
)
open(path, 'w').write(content)
print('✓ main.py – klientlinse router')
PYEOF

# Opret KlientlinseBar komponent
cat > frontend/components/KlientlinseBar.tsx << 'ENDOFFILE'
'use client'
import { useState, useEffect } from 'react'
import { Lead } from '@/app/dashboard/page'

type Props = {
  onActivate: (clientName: string, leads: Lead[]) => void
  onDeactivate: () => void
}

export default function KlientlinseBar({ onActivate, onDeactivate }: Props) {
  const [clientName, setClientName] = useState('')
  const [active, setActive] = useState(false)
  const [activeClient, setActiveClient] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const saved = localStorage.getItem('klientlinse_client')
    if (saved) {
      setActiveClient(saved)
      setClientName(saved)
      setActive(true)
    }
  }, [])

  const handleActivate = async () => {
    if (!clientName.trim()) return
    setLoading(true)
    try {
      const res = await fetch('/api/klientlinse/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ client_name: clientName }),
      })
      const data = await res.json()
      setActive(true)
      setActiveClient(clientName)
      localStorage.setItem('klientlinse_client', clientName)
      onActivate(clientName, data.leads || [])
    } catch {
      console.error('Klientlinse fejl')
    } finally {
      setLoading(false)
    }
  }

  const handleDeactivate = () => {
    setActive(false)
    setActiveClient('')
    setClientName('')
    localStorage.removeItem('klientlinse_client')
    onDeactivate()
  }

  return (
    <div style={{
      background: active ? '#0d1b2e' : 'var(--surface)',
      border: active ? '1px solid rgba(184,150,62,0.3)' : '1px solid rgba(0,0,0,0.08)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 16px',
      marginBottom: 16,
      transition: 'all 0.2s',
    }}>
      {active ? (
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 10 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ fontSize: 14 }}>🔍</span>
            <div>
              <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.4)', letterSpacing: '0.08em', textTransform: 'uppercase' }}>Klientlinse aktiv</div>
              <div style={{ fontSize: 14, fontWeight: 600, color: '#e8d08a' }}>{activeClient}</div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.3)', fontStyle: 'italic' }}>Leads er re-rangeret fra {activeClient}s perspektiv</span>
            <button onClick={handleDeactivate} style={{ fontSize: 11, padding: '5px 12px', borderRadius: 6, border: '1px solid rgba(255,255,255,0.15)', background: 'transparent', color: 'rgba(255,255,255,0.5)', cursor: 'pointer' }}>
              Nulstil
            </button>
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <span style={{ fontSize: 11, fontWeight: 500, color: 'var(--ink-2)', whiteSpace: 'nowrap' }}>Klientlinse</span>
          <input
            type="text"
            placeholder="Skriv et firmanavn, fx Green Therma..."
            value={clientName}
            onChange={e => setClientName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleActivate()}
            style={{ flex: 1, minWidth: 200, padding: '7px 12px', fontSize: 12, borderRadius: 6, border: '1px solid rgba(0,0,0,0.1)', background: 'var(--bg)', color: 'var(--ink)', outline: 'none' }}
          />
          <button
            onClick={handleActivate}
            disabled={loading || !clientName.trim()}
            style={{ fontSize: 12, fontWeight: 500, padding: '7px 16px', borderRadius: 6, border: 'none', background: clientName.trim() ? '#0d1b2e' : 'rgba(0,0,0,0.06)', color: clientName.trim() ? '#e8d08a' : 'var(--ink-3)', cursor: clientName.trim() ? 'pointer' : 'default', whiteSpace: 'nowrap' }}
          >
            {loading ? 'Analyserer...' : 'Tag deres briller på →'}
          </button>
        </div>
      )}
    </div>
  )
}
ENDOFFILE
echo "✓ KlientlinseBar.tsx"

# Opdater dashboard til at inkludere KlientlinseBar
python3.12 - << 'PYEOF'
path = '/Users/rmk/nextstep-intelligence/frontend/app/dashboard/page.tsx'
content = open(path).read()

# Tilføj client_score og client_opener til Lead type
content = content.replace(
    '  entity?: string',
    '  entity?: string\n  client_score?: number\n  client_opener?: string\n  client_relevance?: string'
)

# Tilføj import af KlientlinseBar
content = content.replace(
    "import ReviewBanner from '@/components/ReviewBanner'",
    "import ReviewBanner from '@/components/ReviewBanner'\nimport KlientlinseBar from '@/components/KlientlinseBar'"
)

# Tilføj klientlinse state
content = content.replace(
    "  const [activeDays, setActiveDays] = useState(7)",
    "  const [activeDays, setActiveDays] = useState(7)\n  const [clientLeads, setClientLeads] = useState<Lead[] | null>(null)\n  const [clientName, setClientName] = useState('')"
)

# Indsæt KlientlinseBar i JSX efter ReviewBanner
content = content.replace(
    "          <ReviewBanner />",
    "          <ReviewBanner />\n          <KlientlinseBar\n            onActivate={(name, leads) => { setClientName(name); setClientLeads(leads) }}\n            onDeactivate={() => { setClientName(''); setClientLeads(null) }}\n          />"
)

# Brug clientLeads hvis aktiv
content = content.replace(
    "  const filtered = leads.filter(l => {",
    "  const displayLeads = clientLeads || leads\n  const filtered = displayLeads.filter(l => {"
)

open(path, 'w').write(content)
print('✓ dashboard/page.tsx – KlientlinseBar integreret')
PYEOF

echo ""
echo "✅ v0.2.1 klar!"
