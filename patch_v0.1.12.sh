#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.12 – 7/30 dages toggle på leads..."

# Opdater backend leads router med dato-filtrering
cat > backend/routers/leads.py << 'ENDOFFILE'
from fastapi import APIRouter
from services.db_service import get_leads, toggle_star, reset_all_stars
from datetime import datetime, timedelta

router = APIRouter(prefix="/leads", tags=["leads"])

@router.get("")
async def list_leads(module: str = None, limit: int = 20, sort: str = "score", days: int = None):
    leads = await get_leads(module=module, limit=limit, sort=sort, days=days)
    for lead in leads:
        if 'stars' not in lead:
            lead['stars'] = 0
    return {"leads": leads}

@router.post("/{lead_id}/star")
async def star_lead(lead_id: str, body: dict = {}):
    currently_starred = body.get("currently_starred", False)
    result = await toggle_star(lead_id, currently_starred)
    return result

@router.post("/reset-stars")
async def reset_stars():
    await reset_all_stars()
    return {"status": "ok"}
ENDOFFILE
echo "✓ leads.py – days parameter"

# Opdater db_service med dato-filtrering
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/services/db_service.py'
content = open(path).read()
old = '''async def get_leads(module: str = None, limit: int = 20, sort: str = \"score\") -> list:
    client = get_client()
    if not client:
        return []
    try:
        sort_column = \"created_at\" if sort == \"date\" else \"stars\" if sort == \"stars\" else \"score\"
        query = client.table(\"leads\").select(\"*\").order(sort_column, desc=True).limit(limit)
        if module:
            query = query.eq(\"module\", module)
        return (query.execute()).data or []
    except Exception as e:
        print(f\"DB fejl: {e}\")
        return []'''
new = '''async def get_leads(module: str = None, limit: int = 20, sort: str = \"score\", days: int = None) -> list:
    client = get_client()
    if not client:
        return []
    try:
        from datetime import datetime, timedelta, timezone
        sort_column = \"created_at\" if sort == \"date\" else \"stars\" if sort == \"stars\" else \"score\"
        query = client.table(\"leads\").select(\"*\").order(sort_column, desc=True).limit(limit)
        if module:
            query = query.eq(\"module\", module)
        if days:
            since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
            query = query.gte(\"created_at\", since)
        return (query.execute()).data or []
    except Exception as e:
        print(f\"DB fejl: {e}\")
        return []'''
content = content.replace(old, new)
open(path, 'w').write(content)
print('✓ db_service.py – dato-filtrering')
"

# Opdater StatsRow med toggle
cat > frontend/components/StatsRow.tsx << 'ENDOFFILE'
'use client'
import { useState } from 'react'

type Props = { total: number; pa: number; vel: number; rebizz: number; onDaysChange: (days: number) => void; activeDays: number }

export default function StatsRow({ total, pa, vel, rebizz, onDaysChange, activeDays }: Props) {
  return (
    <div style={{ marginBottom: 4 }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 10, marginBottom: 8 }}>
        {[
          { label: 'Leads', value: total, valueColor: 'var(--ink)', dark: false, bg: 'var(--surface)' },
          { label: 'Public Affairs', value: pa, valueColor: '#fff', dark: true, bg: 'var(--ink)' },
          { label: 'Velfærd', value: vel, valueColor: '#fff', dark: true, bg: 'var(--vel)' },
          { label: 'Rebizz-matches', value: rebizz, valueColor: 'var(--gold)', dark: false, bg: 'var(--surface)' },
        ].map(c => (
          <div key={c.label} style={{ background: c.bg, borderRadius: 'var(--radius-md)', padding: '13px 15px', border: c.dark ? 'none' : '1px solid rgba(0,0,0,0.06)' }}>
            <div style={{ fontSize: 11, color: c.dark ? 'rgba(255,255,255,0.45)' : 'var(--ink-3)', marginBottom: 5 }}>{c.label}</div>
            <div style={{ fontSize: 24, fontWeight: 700, color: c.valueColor }}>{c.value}</div>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <span style={{ fontSize: 11, color: 'var(--ink-3)' }}>Viser:</span>
        {[
          { days: 7, label: '7 dage' },
          { days: 30, label: '30 dage' },
        ].map(o => (
          <button key={o.days} onClick={() => onDaysChange(o.days)} style={{
            fontSize: 11, padding: '3px 10px', borderRadius: 20, cursor: 'pointer',
            border: '1px solid rgba(0,0,0,0.1)',
            background: activeDays === o.days ? 'var(--ink)' : 'transparent',
            color: activeDays === o.days ? '#fff' : 'var(--ink-2)',
          }}>
            {o.label}
          </button>
        ))}
      </div>
    </div>
  )
}
ENDOFFILE
echo "✓ StatsRow.tsx – 7/30 dages toggle"

# Opdater dashboard til at sende days parameter
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/app/dashboard/page.tsx'
content = open(path).read()

# Tilføj activeDays state
content = content.replace(
    \"const [activeModule, setActiveModule] = useState('alle')\",
    \"const [activeModule, setActiveModule] = useState('alle')\n  const [activeDays, setActiveDays] = useState(7)\"
)

# Opdater fetchLeads til at bruge days
content = content.replace(
    \"fetch(\`/api/leads?sort=\${sortBy}\`)\",
    \"fetch(\`/api/leads?sort=\${sortBy}&days=\${activeDays}\`)\"
)

# Tilføj handleDays funktion
content = content.replace(
    \"  const handleSort = (s: string) => {\",
    \"  const handleDays = (d: number) => {\n    setActiveDays(d)\n    fetch(\`/api/leads?sort=\${sort}&days=\${d}\`).then(r => r.json()).then(data => {\n      if (data.leads?.length) setLeads(data.leads)\n      else setLeads([])\n    }).catch(() => {})\n  }\n\n  const handleSort = (s: string) => {\"
)

# Opdater useEffect til at bruge activeDays
content = content.replace(
    \"    fetchLeads(sort)\",
    \"    fetchLeads(sort)\"
)

# Opdater StatsRow props
content = content.replace(
    \"<StatsRow total={leads.length} pa={pa} vel={vel} rebizz={rebizz} />\",
    \"<StatsRow total={leads.length} pa={pa} vel={vel} rebizz={rebizz} onDaysChange={handleDays} activeDays={activeDays} />\"
)

open(path, 'w').write(content)
print('✓ dashboard/page.tsx – days toggle')
"

echo ""
echo "✅ v0.1.12 klar!"
