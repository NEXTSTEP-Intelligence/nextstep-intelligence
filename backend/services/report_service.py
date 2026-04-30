import os
import anthropic
from services.db_service import get_leads

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def generate_report(period: str = "week") -> str:
    leads = await get_leads(limit=10)
    if not leads:
        return "no_leads"
    leads_text = "\n\n".join([
        f"LEAD {i+1}: {l.get('title')}\nModul: {l.get('module')}\nScore: {l.get('score')}\nÅbner: {l.get('opener')}"
        for i, l in enumerate(leads)
    ])
    prompt = f"""Skriv en kort professionel mandagsrapport på dansk for NEXTSTEP A/S baseret på ugens leads.
Tone: direkte, handlingsorienteret. Start med 3-4 sætningers opsummering, list derefter de vigtigste leads med anbefalet handling.

LEADS:
{leads_text}"""

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )
    report_id = f"report_{period}_{os.urandom(4).hex()}"
    print(f"Rapport genereret: {report_id}")
    return report_id
