from fastapi import APIRouter
from services.db_service import get_leads
from services.klientlinse_service import analyze_client_perspective

router = APIRouter(prefix="/klientlinse", tags=["klientlinse"])

@router.post("/analyze")
async def analyze(body: dict):
    client_name = body.get("client_name", "").strip()
    if not client_name:
        return {"leads": []}
    
    leads = await get_leads(limit=20, sort="score", days=7)
    if not leads:
        return {"leads": []}
    
    result = await analyze_client_perspective(client_name, leads)
    return {"leads": result, "client_name": client_name}
