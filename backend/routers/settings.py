from fastapi import APIRouter
from services.db_service import get_report_emails, save_report_emails

router = APIRouter(prefix="/settings", tags=["settings"])

@router.get("/emails")
async def get_emails():
    emails = await get_report_emails()
    return {"emails": emails}

@router.post("/emails")
async def update_emails(body: dict):
    emails = body.get("emails", [])
    await save_report_emails(emails)
    return {"status": "ok", "emails": emails}
