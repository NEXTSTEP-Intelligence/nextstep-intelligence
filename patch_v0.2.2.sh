#!/bin/bash
cd ~/nextstep-intelligence
echo "v0.2.2 – CVR-integration + ensartet score-farve i rapport..."

# Opret CVR service
cat > backend/services/cvr_service.py << 'ENDOFFILE'
import httpx
import os

CVR_API = "https://api.cvr.dev/api/elastic/vrvirksomhed/_search"
CVR_TOKEN = os.getenv("CVR_API_TOKEN", "")

PUBLIC_KEYWORDS = [
    "kommune", "region", "ministeriet", "styrelsen", "rådet",
    "nævnet", "forbundet", "foreningen", "fonden", "instituttet",
    "hospitalet", "universitetet", "skolen", "kommunal", "offentlig",
    "kl ", "danske regioner", "folketing", "regering"
]

async def lookup_cvr(entity: str) -> dict:
    if not entity:
        return {"verified": False, "size_info": "", "skip": False, "public": False}

    entity_lower = entity.lower()
    for keyword in PUBLIC_KEYWORDS:
        if keyword in entity_lower:
            return {
                "verified": False,
                "size_info": "Offentlig instans",
                "skip": False,
                "public": True,
                "cvr_verified": False,
            }

    try:
        query = {
            "query": {
                "bool": {
                    "must": [
                        {"match": {"Vrvirksomhed.virksomhedMetadata.nyesteNavn.navn": entity}},
                        {"term": {"Vrvirksomhed.livsforloeb.periode.gyldigTil": "9999-12-31"}}
                    ]
                }
            },
            "size": 1,
            "_source": [
                "Vrvirksomhed.virksomhedMetadata.nyesteNavn.navn",
                "Vrvirksomhed.virksomhedMetadata.nyesteAarsbeskaeftigelse.antalAnsatte",
                "Vrvirksomhed.virksomhedMetadata.nyesteBeliggenhedsadresse.kommune.kommuneNavn",
            ]
        }

        headers = {"Authorization": f"Bearer {CVR_TOKEN}"} if CVR_TOKEN else {}

        async with httpx.AsyncClient(timeout=5.0) as client:
            res = await client.post(CVR_API, json=query, headers=headers)
            data = res.json()

        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            return {"verified": False, "size_info": "", "skip": False, "public": False}

        source = hits[0].get("_source", {}).get("Vrvirksomhed", {})
        meta = source.get("virksomhedMetadata", {})
        ansatte = meta.get("nyesteAarsbeskaeftigelse", {}).get("antalAnsatte", 0) or 0

        if ansatte < 50:
            return {"verified": False, "size_info": f"{ansatte} ansatte", "skip": True, "public": False}

        return {
            "verified": True,
            "size_info": f"{ansatte} ansatte",
            "skip": False,
            "public": False,
            "cvr_verified": True,
        }

    except Exception as e:
        print(f"CVR fejl for {entity}: {e}")
        return {"verified": False, "size_info": "", "skip": False, "public": False}
ENDOFFILE
echo "✓ cvr_service.py"

# Opdater scraper_service til at bruge CVR
python3.12 - << 'PYEOF'
path = '/Users/rmk/nextstep-intelligence/backend/services/scraper_service.py'
content = open(path).read()

content = content.replace(
    'from services.db_service import save_lead, article_exists, find_existing_lead, update_lead',
    'from services.db_service import save_lead, article_exists, find_existing_lead, update_lead\nfrom services.cvr_service import lookup_cvr'
)

old = '''            if existing:
                # Opdater eksisterende lead
                new_score = max(existing.get("score", 0), lead.get("score", 0))
                update_count = (existing.get("update_count") or 0) + 1
                await update_lead(existing["id"], {
                    "score": new_score,
                    "update_count": update_count,
                    "summary": lead.get("summary", existing.get("summary", "")),
                    "opener": lead.get("opener", existing.get("opener", "")),
                })
                print(f"Opdateret eksisterende lead: {entity} (opdatering #{update_count})")
            else:
                await save_lead(lead)
                new_leads += 1'''

new = '''            if existing:
                new_score = max(existing.get("score", 0), lead.get("score", 0))
                update_count = (existing.get("update_count") or 0) + 1
                await update_lead(existing["id"], {
                    "score": new_score,
                    "update_count": update_count,
                    "summary": lead.get("summary", existing.get("summary", "")),
                    "opener": lead.get("opener", existing.get("opener", "")),
                })
                print(f"Opdateret: {entity} (#{update_count})")
            else:
                # CVR-tjek
                cvr = await lookup_cvr(entity)
                if cvr.get("skip"):
                    print(f"Spring over (for lille): {entity} – {cvr.get('size_info')}")
                    continue
                lead["cvr_verified"] = cvr.get("cvr_verified", False)
                lead["size_info"] = cvr.get("size_info", lead.get("size_info", ""))
                if cvr.get("public"):
                    lead["size_info"] = "Offentlig instans"
                await save_lead(lead)
                new_leads += 1'''

content = content.replace(old, new)
open(path, 'w').write(content)
print('✓ scraper_service.py – CVR integration')
PYEOF

# Fix score-farve i rapport til altid at være mørk/neutral
python3.12 - << 'PYEOF'
path = '/Users/rmk/nextstep-intelligence/frontend/app/rapport/page.tsx'
content = open(path).read()
content = content.replace(
    'fontSize: 22, fontWeight: 800, color: mc.color',
    'fontSize: 22, fontWeight: 800, color: \'#0d1b2e\''
)
open(path, 'w').write(content)
print('✓ rapport/page.tsx – ensartet score-farve')
PYEOF

echo ""
echo "✅ v0.2.2 klar!"
echo ""
echo "Tilføj evt. CVR_API_TOKEN til Railway environment variables for højere rate limits."
