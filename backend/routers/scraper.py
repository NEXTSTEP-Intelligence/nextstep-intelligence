from fastapi import APIRouter
from services.scraper_service import run_scraper
router = APIRouter(prefix="/scraper", tags=["scraper"])

@router.post("/run")
async def trigger_scraper():
    result = await run_scraper()
    return {"status": "done", "new_leads": result}
