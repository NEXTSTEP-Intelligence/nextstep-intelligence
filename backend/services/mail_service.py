import os
import httpx
from services.db_service import get_leads, reset_all_stars

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
FROM_EMAIL = "scout@nextstep.one"
PLATFORM_URL = "https://nextstep-intelligence-production-54dc.up.railway.app"

APPROVERS = [
    {"email": "rmk@nextstep.one", "name": "Rasmus"},
    {"email": "cb@nextstep.one", "name": "Claus"},
]

RECIPIENTS = [
    {"email": "rmk@nextstep.one", "name": "Rasmus"},
    {"email": "cb@nextstep.one", "name": "Claus"},
    {"email": "ms@nextstep.one", "name": "Malin"},
    {"email": "kgj@nextstep.one", "name": "Kasper"},
    {"email": "mh@nextstep.one", "name": "Mikkel"},
    {"email": "ml@nextstep.one", "name": "Morten"},
]

MODULE_STYLES = {
    "public_affairs": {"label": "Public Affairs", "bg": "#1a1a1a", "color": "#ffffff"},
    "velfaerd":       {"label": "Velfærd",         "bg": "#edf5f1", "color": "#2a7d5f"},
}


async def send_email(to: list, subject: str, html: str) -> bool:
    if not RESEND_API_KEY:
        print("RESEND_API_KEY mangler")
        return False
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.post(
                "https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {RESEND_API_KEY}", "Content-Type": "application/json"},
                json={"from": f"Scout NS <{FROM_EMAIL}>", "to": to, "subject": subject, "html": html}
            )
        if res.status_code == 200:
            print(f"Mail sendt til {to}")
            return True
        print(f"Resend fejl {res.status_code}: {res.text}")
        return False
    except Exception as e:
        print(f"Mail fejl: {e}")
        return False


def lead_row(lead: dict, is_starred: bool = False) -> str:
    module = lead.get("module", "public_affairs")
    style = MODULE_STYLES.get(module, MODULE_STYLES["public_affairs"])
    score = lead.get("score", 0)
    sector = lead.get("sector", "")
    source = lead.get("source", "")
    published = lead.get("published_at", "")
    title = lead.get("title", "")
    opener = lead.get("opener", "")
    if len(opener) > 130:
        opener = opener[:130] + "..."

    score_color = "#b8963e" if score >= 70 else "#0d1b2e"
    star_badge = '<span style="background:#fff8e6;color:#b8963e;font-size:10px;font-weight:700;padding:2px 7px;border-radius:20px;border:1px solid rgba(184,150,62,0.3);">★ Teamprioritet</span>' if is_starred else ""
    border_color = "#b8963e" if is_starred else "#e8e5e0"
    bg = "#fffdf7" if is_starred else "#ffffff"

    return f"""
    <tr>
      <td style="padding:0 0 12px 0;">
        <table width="100%" cellpadding="0" cellspacing="0" style="background:{bg};border:1px solid {border_color};border-radius:10px;overflow:hidden;">
          <tr>
            <td style="width:4px;background:{'#b8963e' if is_starred else ('#1a1a1a' if module == 'public_affairs' else '#2a7d5f')};border-radius:10px 0 0 10px;">&nbsp;</td>
            <td style="padding:14px 16px 14px 14px;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td>
                    <span style="background:{style['bg']};color:{style['color']};font-size:9px;font-weight:700;padding:2px 8px;border-radius:20px;text-transform:uppercase;letter-spacing:0.04em;">{style['label']}</span>
                    &nbsp;
                    <span style="font-size:10px;color:#999;">{sector}</span>
                    &nbsp;·&nbsp;
                    <span style="font-size:10px;color:#bbb;">{source}</span>
                    &nbsp;·&nbsp;
                    <span style="font-size:10px;color:#bbb;">{published}</span>
                    {"&nbsp;&nbsp;" + star_badge if is_starred else ""}
                  </td>
                  <td style="text-align:right;vertical-align:top;">
                    <span style="font-size:22px;font-weight:800;color:{score_color};letter-spacing:-0.02em;line-height:1;">{score}</span>
                  </td>
                </tr>
                <tr>
                  <td colspan="2" style="padding-top:6px;">
                    <div style="font-size:14px;font-weight:700;color:#0d1b2e;line-height:1.35;margin-bottom:8px;">{title}</div>
                    <div style="font-size:12px;color:#555;line-height:1.6;border-left:3px solid #e8d08a;padding-left:10px;">
                      <span style="color:#b8963e;font-weight:600;">Vej ind:</span> {opener}
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    """


def build_approval_email(name: str, day_label: str, week: int, lead_count: int) -> str:
    approve_url = f"{PLATFORM_URL}/rapport?godkend=1"
    return f"""<!DOCTYPE html>
<html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f2f0eb;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0"><tr><td style="padding:32px 16px;">
<table width="600" align="center" cellpadding="0" cellspacing="0" style="max-width:600px;">
  <tr><td style="background:linear-gradient(135deg,#0d1b2e 0%,#1a2f4a 100%);border-radius:12px 12px 0 0;padding:28px 32px;">
    <div style="font-size:9px;letter-spacing:0.16em;color:rgba(255,255,255,0.4);text-transform:uppercase;margin-bottom:6px;">NEXTSTEP · Scout NS</div>
    <div style="font-size:22px;font-weight:700;color:white;letter-spacing:-0.02em;">{day_label} · Uge {week} · 2026</div>
    <div style="font-size:12px;color:rgba(255,255,255,0.4);margin-top:4px;">Politisk Radar klar til godkendelse</div>
  </td></tr>
  <tr><td style="background:white;border-radius:0 0 12px 12px;padding:28px 32px;">
    <p style="font-size:15px;color:#1a1a1a;margin:0 0 8px;font-weight:600;">Hej {name},</p>
    <p style="font-size:14px;color:#555;line-height:1.7;margin:0 0 24px;">Scout NS har identificeret <strong style="color:#0d1b2e;">{lead_count} leads</strong> denne uge. Rapporten afventer din godkendelse inden den sendes til teamet.</p>
    <a href="{approve_url}" style="display:inline-block;background:#b8963e;color:white;font-size:13px;font-weight:600;padding:12px 24px;border-radius:8px;text-decoration:none;">Gennemse og godkend rapport →</a>
    <p style="font-size:11px;color:#bbb;margin:24px 0 0;padding-top:16px;border-top:1px solid #f0ede8;">Scout NS · NEXTSTEP Public Affairs Intelligence ©</p>
  </td></tr>
</table>
</td></tr></table>
</body></html>"""


def build_report_email(name: str, day_label: str, week: int, leads: list) -> str:
    starred = [l for l in leads if (l.get("stars") or 0) > 0]
    starred.sort(key=lambda x: x.get("stars", 0), reverse=True)
    top = [l for l in leads if (l.get("stars") or 0) == 0][:6]

    starred_rows = "".join(lead_row(l, is_starred=True) for l in starred)
    top_rows = "".join(lead_row(l, is_starred=False) for l in top)

    starred_section = f"""
    <tr><td style="padding:0 0 16px 0;">
      <table width="100%" cellpadding="0" cellspacing="0">
        <tr><td style="padding:0 0 12px 0;">
          <table width="100%" cellpadding="0" cellspacing="0"><tr>
            <td style="height:1px;background:#f0ede8;"></td>
            <td style="white-space:nowrap;padding:0 12px;font-size:9px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;color:#b8963e;">★ Teamets prioriteter</td>
            <td style="height:1px;background:#f0ede8;"></td>
          </tr></table>
        </td></tr>
        {starred_rows}
      </table>
    </td></tr>
    """ if starred else ""

    top_label = "Øvrige aktuelle leads" if starred else "Aktuelle top-leads"

    return f"""<!DOCTYPE html>
<html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#f2f0eb;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
<table width="100%" cellpadding="0" cellspacing="0"><tr><td style="padding:32px 16px;">
<table width="620" align="center" cellpadding="0" cellspacing="0" style="max-width:620px;">

  <!-- Header -->
  <tr><td style="background:linear-gradient(135deg,#0d1b2e 0%,#1a2f4a 100%);border-radius:12px 12px 0 0;padding:28px 32px;">
    <table width="100%" cellpadding="0" cellspacing="0"><tr>
      <td>
        <div style="font-size:9px;letter-spacing:0.16em;color:rgba(255,255,255,0.4);text-transform:uppercase;margin-bottom:4px;">NEXTSTEP · POLITISK RADAR · FORTROLIG</div>
        <div style="font-size:22px;font-weight:700;color:white;letter-spacing:-0.02em;">{day_label} · Uge {week} · 2026</div>
        <div style="font-size:11px;color:rgba(255,255,255,0.35);margin-top:4px;">Scout NS · AI-assisteret nyhedsanalyse</div>
      </td>
      <td style="text-align:right;vertical-align:middle;">
        <div style="font-size:44px;font-weight:800;color:white;letter-spacing:-0.03em;line-height:1;">{len(leads)}</div>
        <div style="font-size:10px;color:rgba(255,255,255,0.4);margin-top:2px;">leads identificeret</div>
        {"<div style='font-size:10px;color:#b8963e;font-weight:600;margin-top:6px;'>★ " + str(len(starred)) + " teamprioritet" + ("er" if len(starred) != 1 else "") + "</div>" if starred else ""}
      </td>
    </tr></table>
  </td></tr>

  <!-- Body -->
  <tr><td style="background:white;border-radius:0 0 12px 12px;padding:28px 32px;">
    <p style="font-size:15px;color:#1a1a1a;margin:0 0 20px;font-weight:600;">Hej {name},</p>

    <table width="100%" cellpadding="0" cellspacing="0">
      {starred_section}
      <tr><td style="padding:0 0 16px 0;">
        <table width="100%" cellpadding="0" cellspacing="0"><tr>
          <td style="height:1px;background:#f0ede8;"></td>
          <td style="white-space:nowrap;padding:0 12px;font-size:9px;font-weight:700;letter-spacing:0.14em;text-transform:uppercase;color:#aaa;">{top_label}</td>
          <td style="height:1px;background:#f0ede8;"></td>
        </tr></table>
      </td></tr>
      {top_rows}
    </table>

    <p style="font-size:11px;color:#bbb;margin:8px 0 0;padding-top:16px;border-top:1px solid #f0ede8;">
      NEXTSTEP Public Affairs Intelligence © · Scout NS · Fortroligt internt dokument
    </p>
  </td></tr>

</table>
</td></tr></table>
</body></html>"""


async def send_approval_request() -> bool:
    from datetime import datetime
    now = datetime.now()
    week = int(now.strftime("%V"))
    day_names = {0:"Mandag",1:"Tirsdag",2:"Onsdag",3:"Torsdag",4:"Fredag",5:"Lørdag",6:"Søndag"}
    day_label = day_names.get(now.weekday(), "")
    leads = await get_leads(limit=20, sort="score", days=7)

    success = True
    for approver in APPROVERS:
        html = build_approval_email(approver["name"], day_label, week, len(leads))
        ok = await send_email(
            to=[approver["email"]],
            subject=f"Scout NS · {day_label} Uge {week} · Afventer godkendelse",
            html=html
        )
        if not ok:
            success = False
    return success


async def send_report_to_team() -> bool:
    from datetime import datetime
    now = datetime.now()
    week = int(now.strftime("%V"))
    day_names = {0:"Mandag",1:"Tirsdag",2:"Onsdag",3:"Torsdag",4:"Fredag",5:"Lørdag",6:"Søndag"}
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
