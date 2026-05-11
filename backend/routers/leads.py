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

@router.post("/build-index")
async def build_index():
    """Midlertidigt endpoint til at bygge ivfflat indeks."""
    from services.db_service import get_client
    import asyncio
    client = get_client()
    try:
        client.postgrest.session.timeout = 600
        client.rpc("build_guldkatalog_index").execute()
        return {"status": "indeks bygget"}
    except Exception as e:
        return {"status": "fejl", "error": str(e)}
