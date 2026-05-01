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
        ansatte = virk.get("antalAnsatte") or virk.get("employees") or 0

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
