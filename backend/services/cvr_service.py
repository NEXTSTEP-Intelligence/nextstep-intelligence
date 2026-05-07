import httpx
import os

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
        # Erhvervsstyrelsens officielle CVR API – ingen nøgle, ingen IP-whitelist
        async with httpx.AsyncClient(timeout=8.0) as client:
            res = await client.post(
                "https://api.cvr.dk/cvr-permanent/elasticsearch/cvr-v2/_doc/_search",
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
                json={
                    "query": {
                        "multi_match": {
                            "query": entity,
                            "fields": ["Vrvirksomhed.virksomhedMetadata.nyesteNavn.navn"],
                            "operator": "and"
                        }
                    },
                    "size": 1
                }
            )

        print(f"CVR status {res.status_code} for {entity}, body: {res.text[:300]}")

        if res.status_code != 200:
            return {"verified": False, "size_info": "", "skip": False, "public": False}

        data = res.json()
        hits = data.get("hits", {}).get("hits", [])
        if not hits:
            return {"verified": False, "size_info": "", "skip": False, "public": False}

        virk = hits[0].get("_source", {}).get("Vrvirksomhed", {})

        # Hent ansatte fra nyesteAarsbeskaeftigelse
        ansatte = 0
        metadata = virk.get("virksomhedMetadata", {})
        besk = metadata.get("nyesteAarsbeskaeftigelse", {})
        if besk:
            ansatte = besk.get("antalAnsatte", 0) or 0

        # Fallback: aarsbeskaeftigelse array
        if not ansatte:
            besk_list = virk.get("aarsbeskaeftigelse", [])
            if besk_list:
                latest = sorted(besk_list, key=lambda x: x.get("aar", 0), reverse=True)
                if latest:
                    ansatte = latest[0].get("antalAnsatte", 0) or 0

        print(f"CVR: {entity} → {ansatte} ansatte")

        # SMV-fokus: 10-500 ansatte er relevante
        is_smv = 10 <= ansatte <= 500

        return {
            "verified": is_smv,
            "size_info": f"{ansatte} ansatte" if ansatte else "",
            "skip": ansatte > 500,  # Spring over hvis stor virksomhed med intern PA
            "public": False,
            "cvr_verified": ansatte >= 10,
            "ansatte": ansatte,
        }

    except Exception as e:
        print(f"CVR fejl for {entity}: {e}")
        return {"verified": False, "size_info": "", "skip": False, "public": False}
