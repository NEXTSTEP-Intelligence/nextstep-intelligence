from fastapi import APIRouter
from services.mail_service import send_approval_request, send_report_to_team, send_email, build_report_email, build_approval_email
from services.db_service import get_leads

router = APIRouter(prefix="/mail", tags=["mail"])

@router.post("/send-approval")
async def trigger_approval():
    ok = await send_approval_request()
    return {"status": "sent" if ok else "error"}

@router.post("/godkend-og-send")
async def godkend_og_send():
    ok = await send_report_to_team()
    return {"status": "sent" if ok else "error"}

@router.post("/test-rapport")
async def test_rapport():
    """Send test rapport-mail kun til rmk@nextstep.one"""
    from datetime import datetime
    now = datetime.now()
    week = int(now.strftime("%V"))
    day_names = {0:"Mandag",1:"Tirsdag",2:"Onsdag",3:"Torsdag",4:"Fredag",5:"Lørdag",6:"Søndag"}
    day_label = day_names.get(now.weekday(), "")
    leads = await get_leads(limit=20, sort="score", days=7)
    html = build_report_email("Rasmus", day_label, week, leads)
    ok = await send_email(
        to=["rmk@nextstep.one"],
        subject=f"[TEST] Scout NS · Politisk Radar · {day_label} Uge {week}",
        html=html
    )
    return {"status": "sent" if ok else "error"}

@router.post("/test-godkendelse")
async def test_godkendelse():
    """Send test godkendelses-mail kun til rmk@nextstep.one"""
    from datetime import datetime
    now = datetime.now()
    week = int(now.strftime("%V"))
    day_names = {0:"Mandag",1:"Tirsdag",2:"Onsdag",3:"Torsdag",4:"Fredag",5:"Lørdag",6:"Søndag"}
    day_label = day_names.get(now.weekday(), "")
    leads = await get_leads(limit=20, sort="score", days=7)
    html = build_approval_email("Rasmus", day_label, week, len(leads))
    ok = await send_email(
        to=["rmk@nextstep.one"],
        subject=f"[TEST] Scout NS · {day_label} Uge {week} · Afventer godkendelse",
        html=html
    )
    return {"status": "sent" if ok else "error"}
