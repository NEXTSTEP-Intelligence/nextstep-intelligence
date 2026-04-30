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
