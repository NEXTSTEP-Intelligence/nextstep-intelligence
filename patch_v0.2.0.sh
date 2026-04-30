#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.2.0 – Situationsbaserede leads med entity matching..."

# Opdater db_service med entity matching og update funktioner
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/services/db_service.py'
content = open(path).read()

addition = '''
async def find_existing_lead(entity: str, days: int = 30) -> dict | None:
    client = get_client()
    if not client or not entity:
        return None
    try:
        from datetime import datetime, timedelta, timezone
        since = (datetime.now(timezone.utc) - timedelta(days=days)).isoformat()
        result = client.table(\"leads\").select(\"*\") \\\\
            .ilike(\"entity\", f\"%{entity}%\") \\\\
            .gte(\"created_at\", since) \\\\
            .order(\"score\", desc=True) \\\\
            .limit(1) \\\\
            .execute()
        return result.data[0] if result.data else None
    except Exception as e:
        print(f\"Find entity fejl: {e}\")
        return None

async def update_lead(lead_id: str, updates: dict) -> bool:
    client = get_client()
    if not client:
        return False
    try:
        from datetime import datetime, timezone
        updates[\"updated_at\"] = datetime.now(timezone.utc).isoformat()
        client.table(\"leads\").update(updates).eq(\"id\", lead_id).execute()
        return True
    except Exception as e:
        print(f\"Update lead fejl: {e}\")
        return False
'''

open(path, 'w').write(content + addition)
print('✓ db_service.py – entity matching')
"

# Opdater scraper_service med situationsbaseret logik
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/backend/services/scraper_service.py'
content = open(path).read()

# Opdater analyze_article prompt til at inkludere entity felt
content = content.replace(
    '\"score\": 0-100 (41-60=svagt lead, 61-80=godt lead, 81-100=stærkt lead. Returner kun relevant=true hvis score er over 40),',
    '\"score\": 0-100 (41-60=svagt lead, 61-80=godt lead, 81-100=stærkt lead. Returner kun relevant=true hvis score er over 40),\n  \"entity\": \"primær virksomhed eller organisation nævnt i artiklen (kun ét navn, det vigtigste)\","
)

# Opdater run_scraper til at bruge entity matching
old_save = '''    for article in all_articles:
        lead = await analyze_article(article)
        if lead:
            await save_lead(lead)
            new_leads += 1'''

new_save = '''    for article in all_articles:
        lead = await analyze_article(article)
        if lead:
            entity = lead.get(\"entity\", \"\")
            existing = await find_existing_lead(entity) if entity else None
            if existing:
                # Opdater eksisterende lead
                new_score = max(existing.get(\"score\", 0), lead.get(\"score\", 0))
                update_count = (existing.get(\"update_count\") or 0) + 1
                await update_lead(existing[\"id\"], {
                    \"score\": new_score,
                    \"update_count\": update_count,
                    \"summary\": lead.get(\"summary\", existing.get(\"summary\", \"\")),
                    \"opener\": lead.get(\"opener\", existing.get(\"opener\", \"\")),
                })
                print(f\"Opdateret eksisterende lead: {entity} (opdatering #{update_count})\")
            else:
                await save_lead(lead)
                new_leads += 1'''

content = content.replace(old_save, new_save)

# Tilføj import af find_existing_lead og update_lead
content = content.replace(
    'from services.db_service import save_lead, article_exists',
    'from services.db_service import save_lead, article_exists, find_existing_lead, update_lead'
)

open(path, 'w').write(content)
print('✓ scraper_service.py – situationsbaseret logik')
"

# Opdater LeadCard til at vise opdaterings-badge
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/components/LeadCard.tsx'
content = open(path).read()

# Tilføj update_count til visningen i collapsed view
old = \"          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)', letterSpacing: '-0.01em', lineHeight: 1.4 }}>{lead.title}</div>\"
new = \"\"\"          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--ink)', letterSpacing: '-0.01em', lineHeight: 1.4 }}>
            {lead.title}
            {(lead.update_count || 0) > 0 && (
              <span style={{ marginLeft: 8, fontSize: 10, fontWeight: 600, padding: '2px 7px', borderRadius: 20, background: '#e6f1fb', color: '#185fa5', verticalAlign: 'middle' }}>
                ↻ {lead.update_count} opdatering{lead.update_count !== 1 ? 'er' : ''}
              </span>
            )}
          </div>\"\"\"
content = content.replace(old, new)
open(path, 'w').write(content)
print('✓ LeadCard.tsx – opdaterings-badge')
"

# Tilføj update_count til Lead type
python3.12 -c "
path = '/Users/rmk/nextstep-intelligence/frontend/app/dashboard/page.tsx'
content = open(path).read()
content = content.replace(
    '  stars: number',
    '  stars: number\n  update_count?: number\n  entity?: string'
)
open(path, 'w').write(content)
print('✓ dashboard/page.tsx – Lead type opdateret')
"

echo ""
echo "✅ v0.2.0 klar!"
