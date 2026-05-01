import httpx
import os

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

    if not CVR_TOKEN:
        return {"verified": False, "size_info": "", "skip": False, "public": False}

    try:
        headers = {
            "Authorization": f"Bearer {CVR_TOKEN}",
            "Accept": "application/json",
        }
        params = {"navn": entity, "land": "dk"}

        async with httpx.AsyncClient(timeout=5.0) as client:
            res = await client.get(
                "https://api.cvr.dev/api/cvr/virksomhed",
                headers=headers,
                params=params
            )

        print(f"CVR API status {res.status_code} for {entity}, content-type: {res.headers.get('content-type', 'unknown')}, body: {res.text[:200]}")
        if res.status_code != 200:
            print(f"CVR API fejl {res.status_code} for {entity}")
            return {"verified": False, "size_info": "", "skip": False, "public": False}

        data = res.json()
        items = data if isinstance(data, list) else data.get("items", [])

        if not items:
            return {"verified": False, "size_info": "", "skip": False, "public": False}

        virk = items[0]
        
        # Hent antal ansatte fra virksomhedMetadata
        ansatte = 0
        metadata = virk.get("virksomhedMetadata", {})
        if metadata:
            besk = metadata.get("nyesteAarsbeskaeftigelse", {})
            if besk:
                ansatte = besk.get("antalAnsatte", 0) or 0
        
        # Fallback: prøv aarsbeskaeftigelse array
        if not ansatte:
            besk_list = virk.get("aarsbeskaeftigelse", [])
            if besk_list:
                latest = sorted(besk_list, key=lambda x: x.get("aar", 0), reverse=True)
                if latest:
                    ansatte = latest[0].get("antalAnsatte", 0) or 0

        print(f"CVR: {entity} har {ansatte} ansatte")

        return {
            "verified": ansatte >= 50,
            "size_info": f"{ansatte} ansatte" if ansatte else "",
            "skip": False,
            "public": False,
            "cvr_verified": ansatte >= 50,
        }

    except Exception as e:
        print(f"CVR fejl for {entity}: {e}")
        return {"verified": False, "size_info": "", "skip": False, "public": False}
