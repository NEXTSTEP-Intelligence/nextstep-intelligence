from fastapi import APIRouter
from services.mail_service import send_approval_request, send_report_to_team

router = APIRouter(prefix="/mail", tags=["mail"])

@router.post("/send-approval")
async def trigger_approval():
    """Send godkendelses-mail til Claus og Rasmus."""
    ok = await send_approval_request()
    return {"status": "sent" if ok else "error"}

@router.post("/godkend-og-send")
async def godkend_og_send():
    """Godkend rapport og send til hele teamet + reset stjerner."""
    ok = await send_report_to_team()
    return {"status": "sent" if ok else "error"}
