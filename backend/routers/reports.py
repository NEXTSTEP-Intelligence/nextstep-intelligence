from fastapi import APIRouter
from services.report_service import generate_report
router = APIRouter(prefix="/reports", tags=["reports"])

@router.post("/generate")
async def trigger_report(period: str = "week"):
    result = await generate_report(period=period)
    return {"status": "generated", "report_id": result}
