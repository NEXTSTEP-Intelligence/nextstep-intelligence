#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.1.6 – localStorage stjerner + nulstil ved rapport..."

cat > backend/routers/leads.py << 'ENDOFFILE'
from fastapi import APIRouter
from services.db_service import get_leads, toggle_star, reset_all_stars

router = APIRouter(prefix="/leads", tags=["leads"])

@router.get("")
async def list_leads(module: str = None, limit: int = 20, sort: str = "score"):
    leads = await get_leads(module=module, limit=limit, sort=sort)
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
echo "✓ leads.py"

cat > backend/services/db_service.py << 'ENDOFFILE'
import os
from supabase import create_client, Client

_client: Client | None = None

def get_client() -> Client:
    global _client
    if not _client:
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        if url and key:
            _client = create_client(url, key)
    return _client

async def get_leads(module: str = None, limit: int = 20, sort: str = "score") -> list:
    client = get_client()
    if not client:
        return []
    try:
        sort_column = "created_at" if sort == "date" else "stars" if sort == "stars" else "score"
        query = client.table("leads").select("*").order(sort_column, desc=True).limit(limit)
        if module:
            query = query.eq("module", module)
        return (query.execute()).data or []
    except Exception as e:
        print(f"DB fejl: {e}")
        return []

async def save_lead(lead: dict) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        client.table("leads").insert(lead).execute()
        return True
    except Exception as e:
        print(f"Gem fejl: {e}")
        return False

async def article_exists(url: str) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        result = client.table("leads").select("id").eq("url", url).execute()
        return len(result.data) > 0
    except:
        return False

async def toggle_star(lead_id: str, currently_starred: bool) -> dict:
    client = get_client()
    if not client:
        return {"stars": 0, "starred": False}
    try:
        result = client.table("leads").select("stars").eq("id", lead_id).execute()
        if not result.data:
            return {"stars": 0, "starred": False}
        current = result.data[0].get("stars", 0) or 0
        if currently_starred:
            new_stars = max(0, current - 1)
            starred = False
        else:
            new_stars = current + 1
            starred = True
        client.table("leads").update({"stars": new_stars}).eq("id", lead_id).execute()
        return {"stars": new_stars, "starred": starred}
    except Exception as e:
        print(f"Toggle star fejl: {e}")
        return {"stars": 0, "starred": False}

async def reset_all_stars() -> bool:
    client = get_client()
    if not client:
        return False
    try:
        client.table("leads").update({"stars": 0}).neq("stars", -1).execute()
        return True
    except Exception as e:
        print(f"Reset stars fejl: {e}")
        return False

async def increment_stars(lead_id: str) -> int:
    client = get_client()
    if not client:
        return 0
    try:
        result = client.table("leads").select("stars").eq("id", lead_id).execute()
        current = result.data[0].get("stars", 0) if result.data else 0
        new_stars = current + 1
        client.table("leads").update({"stars": new_stars}).eq("id", lead_id).execute()
        return new_stars
    except Exception as e:
        print(f"Star fejl: {e}")
        return 0
ENDOFFILE
echo "✓ db_service.py"

cat > frontend/components/StarButton.tsx << 'ENDOFFILE'
'use client'
import { useState, useEffect } from 'react'

type Props = {
  leadId: string
  initialStars: number
  onToggle?: (stars: number, starred: boolean) => void
}

export default function StarButton({ leadId, initialStars, onToggle }: Props) {
  const [stars, setStars] = useState(initialStars || 0)
  const [starred, setStarred] = useState(false)
  const [loading, setLoading] = useState(false)
  const [animating, setAnimating] = useState(false)

  useEffect(() => {
    const hasStarred = localStorage.getItem(`star_${leadId}`) === 'true'
    setStarred(hasStarred)
  }, [leadId])

  const handleToggle = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (loading) return
    setLoading(true)
    setAnimating(true)
    setTimeout(() => setAnimating(false), 300)
    try {
      const res = await fetch(`/api/leads/${leadId}/star`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ currently_starred: starred }),
      })
      const data = await res.json()
      setStars(data.stars)
      setStarred(data.starred)
      localStorage.setItem(`star_${leadId}`, data.starred ? 'true' : 'false')
      onToggle?.(data.stars, data.starred)
    } catch {
      console.error('Star toggle fejl')
    } finally {
      setLoading(false)
    }
  }

  return (
    <button
      onClick={handleToggle}
      disabled={loading}
      title={starred ? 'Fjern stjernemarkeringen' : 'Stjernemarkér dette lead'}
      style={{
        border: 'none',
        background: starred ? 'var(--gold-bg)' : 'transparent',
        cursor: loading ? 'default' : 'pointer',
        display: 'flex', alignItems: 'center', gap: 4,
        padding: '4px 8px', borderRadius: 6,
        transition: 'all 0.15s',
        color: starred ? '#b8963e' : 'var(--ink-3)',
      }}
    >
      <span style={{
        fontSize: 16,
        transition: 'transform 0.2s',
        transform: animating ? 'scale(1.5)' : 'scale(1)',
        display: 'inline-block',
      }}>
        {starred ? '★' : '☆'}
      </span>
      {stars > 0 && (
        <span style={{ fontSize: 11, fontWeight: 600, color: '#b8963e' }}>{stars}</span>
      )}
    </button>
  )
}
ENDOFFILE
echo "✓ StarButton.tsx"

cat > frontend/components/ReviewBanner.tsx << 'ENDOFFILE'
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
ENDOFFILE
echo "✓ ReviewBanner.tsx – nulstil stjerner ved godkendelse"

echo ""
echo "✅ v0.1.6 klar!"
