from fastapi import APIRouter
from services.db_service import get_leads
router = APIRouter(prefix="/leads", tags=["leads"])

@router.get("")
async def list_leads(module: str = None, limit: int = 20):
    leads = await get_leads(module=module, limit=limit)
    return {"leads": leads}
