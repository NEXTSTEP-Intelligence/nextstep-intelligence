import os
import httpx
from services.db_service import get_leads, reset_all_stars

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
FROM_EMAIL = "scout@nextstep.one"
PLATFORM_URL = "https://nextstep-intelligence-production-54dc.up.railway.app"

# Godkendere – modtager godkendelsesmail
APPROVERS = [
    {"email": "rmk@nextstep.one", "name": "Rasmus"},
    {"email": "cb@nextstep.one", "name": "Claus"},
]

# Alle modtagere af den færdige rapport
RECIPIENTS = [
    {"email": "rmk@nextstep.one", "name": "Rasmus"},
    {"email": "cb@nextstep.one", "name": "Claus"},
    {"email": "ms@nextstep.one", "name": "Malin"},
    {"email": "kgj@nextstep.one", "name": "Kasper"},
    {"email": "mh@nextstep.one", "name": "Mikkel"},
    {"email": "ml@nextstep.one", "name": "Morten"},
]


async def send_email(to: list, subject: str, html: str) -> bool:
    """Send email via Resend API."""
    if not RESEND_API_KEY:
        print("RESEND_API_KEY mangler – mail ikke sendt")
        return False
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(
                "https://api.resend.com/emails",
                headers={
                    "Authorization": f"Bearer {RESEND_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "from": f"Scout NS <{FROM_EMAIL}>",
                    "to": to,
                    "subject": subject,
                    "html": html,
                }
            )
        if res.status_code == 200:
            print(f"Mail sendt til {to}")
            return True
        else:
            print(f"Resend fejl {res.status_code}: {res.text}")
            return False
    except Exception as e:
        print(f"Mail fejl: {e}")
        return False


def build_approval_email(name: str, day_label: str, week: int, lead_count: int) -> str:
    """HTML-mail til godkendere med link til rapport."""
    approve_url = f"{PLATFORM_URL}/rapport?godkend=1"
    return f"""
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; background: #f2f0eb; padding: 32px 24px;">
      <div style="background: linear-gradient(135deg, #0d1b2e 0%, #1a2f4a 100%); border-radius: 12px 12px 0 0; padding: 28px 32px;">
        <div style="font-size: 10px; letter-spacing: 0.14em; color: rgba(255,255,255,0.4); text-transform: uppercase; margin-bottom: 6px;">NEXTSTEP · Scout NS</div>
        <div style="font-size: 22px; font-weight: 700; color: white; letter-spacing: -0.02em;">{day_label} · Uge {week} · 2026</div>
        <div style="font-size: 12px; color: rgba(255,255,255,0.4); margin-top: 4px;">Politisk Radar klar til godkendelse</div>
      </div>
      <div style="background: white; border-radius: 0 0 12px 12px; padding: 28px 32px;">
        <p style="font-size: 15px; color: #1a1a1a; margin: 0 0 8px;">Hej {name},</p>
        <p style="font-size: 14px; color: #444; line-height: 1.6; margin: 0 0 20px;">
          Scout NS har identificeret <strong>{lead_count} leads</strong> denne uge. Rapporten er klar og afventer din godkendelse inden den sendes til teamet.
        </p>
        <a href="{approve_url}" style="display: inline-block; background: #b8963e; color: white; font-size: 14px; font-weight: 600; padding: 12px 24px; border-radius: 8px; text-decoration: none; margin-bottom: 20px;">
          Gennemse og godkend rapport →
        </a>
        <p style="font-size: 12px; color: #999; margin: 0; border-top: 1px solid #f0ede8; padding-top: 16px;">
          Scout NS · NEXTSTEP Public Affairs Intelligence © · Rapporten sendes kun når du godkender den.
        </p>
      </div>
    </div>
    """


def build_report_email(name: str, day_label: str, week: int, leads: list) -> str:
    """HTML rapport-mail til hele teamet."""
    
    starred = [l for l in leads if (l.get("stars") or 0) > 0]
    starred.sort(key=lambda x: x.get("stars", 0), reverse=True)
    top_leads = [l for l in leads if (l.get("stars") or 0) == 0][:6]
    display_leads = (starred + top_leads)[:8]

    leads_html = ""
    for lead in display_leads:
        module = lead.get("module", "public_affairs")
        module_label = "Public Affairs" if module == "public_affairs" else "Velfærd"
        module_color = "#1a1a1a" if module == "public_affairs" else "#2a7d5f"
        score = lead.get("score", 0)
        stars = lead.get("stars", 0)
        star_html = f'<span style="color: #b8963e; font-weight: 700; font-size: 11px;">★ {stars}</span>' if stars else ""
        opener = lead.get("opener", "")
        if len(opener) > 120:
            opener = opener[:120] + "..."
        summary = lead.get("summary", "")
        if len(summary) > 140:
            summary = summary[:140] + "..."

        leads_html += f"""
        <div style="padding: 14px 0; border-bottom: 1px solid #f5f3f0;">
          <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 6px; flex-wrap: wrap;">
            <span style="font-size: 9px; font-weight: 700; padding: 2px 7px; border-radius: 20px; background: {module_color}; color: white;">{module_label}</span>
            <span style="font-size: 9px; color: #aaa;">{lead.get('sector', '')} · {lead.get('source', '')} · {lead.get('published_at', '')}</span>
            {star_html}
          </div>
          <div style="font-size: 13px; font-weight: 700; color: #0d1b2e; margin-bottom: 5px; line-height: 1.35;">{lead.get('title', '')}</div>
          <div style="font-size: 12px; color: #666; line-height: 1.6; margin-bottom: 6px;">{summary}</div>
          <div style="font-size: 11px; color: #333; border-left: 2px solid #e8d08a; padding-left: 8px;">
            <span style="color: #b8963e; font-weight: 600;">Vej ind:</span> {opener}
          </div>
          <div style="font-size: 20px; font-weight: 800; color: #0d1b2e; text-align: right; margin-top: -32px;">{score}</div>
        </div>
        """

    return f"""
    <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; background: #f2f0eb; padding: 32px 24px;">
      <div style="background: linear-gradient(135deg, #0d1b2e 0%, #1a2f4a 100%); border-radius: 12px 12px 0 0; padding: 28px 32px;">
        <div style="font-size: 10px; letter-spacing: 0.14em; color: rgba(255,255,255,0.4); text-transform: uppercase; margin-bottom: 6px;">NEXTSTEP · Politisk Radar · Fortrolig</div>
        <div style="font-size: 22px; font-weight: 700; color: white; letter-spacing: -0.02em;">{day_label} · Uge {week} · 2026</div>
        <div style="font-size: 12px; color: rgba(255,255,255,0.4); margin-top: 4px;">Scout NS · AI-assisteret nyhedsanalyse · {len(leads)} leads identificeret</div>
      </div>
      <div style="background: white; border-radius: 0 0 12px 12px; padding: 28px 32px;">
        <p style="font-size: 15px; color: #1a1a1a; margin: 0 0 6px;">Hej {name},</p>
        <p style="font-size: 14px; color: #444; line-height: 1.6; margin: 0 0 20px;">
          Her er ugens politiske radar fra Scout NS. <strong>{len(leads)} leads</strong> er identificeret og scoret.
        </p>
        <div style="margin-bottom: 20px;">
          {leads_html}
        </div>
        <a href="{PLATFORM_URL}/dashboard" style="display: inline-block; background: #0d1b2e; color: #e8d08a; font-size: 13px; font-weight: 600; padding: 10px 20px; border-radius: 8px; text-decoration: none;">
          Se alle leads på platformen →
        </a>
        <p style="font-size: 11px; color: #bbb; margin: 20px 0 0; border-top: 1px solid #f0ede8; padding-top: 16px;">
          NEXTSTEP Public Affairs Intelligence © · Scout NS · Fortroligt internt dokument
        </p>
      </div>
    </div>
    """


async def send_approval_request() -> bool:
    """Send godkendelses-mail til Claus og Rasmus."""
    from datetime import datetime
    now = datetime.now()
    
    # Beregn uge-nummer
    import time
    week = int(now.strftime("%V"))
    day_names = {0: "Mandag", 1: "Tirsdag", 2: "Onsdag", 3: "Torsdag", 4: "Fredag", 5: "Lørdag", 6: "Søndag"}
    day_label = day_names.get(now.weekday(), "")
    
    leads = await get_leads(limit=20, sort="score", days=7)
    lead_count = len(leads)

    success = True
    for approver in APPROVERS:
        html = build_approval_email(approver["name"], day_label, week, lead_count)
        ok = await send_email(
            to=[approver["email"]],
            subject=f"Scout NS · {day_label} Uge {week} · Afventer godkendelse",
            html=html
        )
        if not ok:
            success = False
    return success


async def send_report_to_team() -> bool:
    """Send rapport-mail til hele teamet og reset stjerner."""
    from datetime import datetime
    now = datetime.now()
    week = int(now.strftime("%V"))
    day_names = {0: "Mandag", 1: "Tirsdag", 2: "Onsdag", 3: "Torsdag", 4: "Fredag", 5: "Lørdag", 6: "Søndag"}
    day_label = day_names.get(now.weekday(), "")

    leads = await get_leads(limit=20, sort="score", days=7)

    success = True
    for recipient in RECIPIENTS:
        html = build_report_email(recipient["name"], day_label, week, leads)
        ok = await send_email(
            to=[recipient["email"]],
            subject=f"Scout NS · Politisk Radar · {day_label} Uge {week}",
            html=html
        )
        if not ok:
            success = False

    if success:
        await reset_all_stars()
        print("Rapport sendt og stjerner nulstillet")

    return success
