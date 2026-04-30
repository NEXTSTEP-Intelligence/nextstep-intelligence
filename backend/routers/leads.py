from fastapi import APIRouter
from services.db_service import get_leads, increment_stars

router = APIRouter(prefix="/leads", tags=["leads"])

@router.get("")
async def list_leads(module: str = None, limit: int = 20):
    leads = await get_leads(module=module, limit=limit)
    return {"leads": leads}

@router.post("/{lead_id}/star")
async def star_lead(lead_id: str):
    stars = await increment_stars(lead_id)
    return {"stars": stars}
