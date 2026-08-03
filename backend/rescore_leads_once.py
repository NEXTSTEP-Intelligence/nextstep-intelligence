"""
Engangs-oprydning: genscorer eksisterende leads (< 30 dage) fra bunden via AI'en,
for at fjerne bias fra den nu fjernede rank-baserede score-spredning (44-83 bånd).

Opdaterer KUN 'score'-feltet. Ingen leads slettes eller ændres på anden vis.

Kør: .venv/bin/python3 rescore_leads_once.py
"""
from dotenv import load_dotenv
load_dotenv()

import json
import os
from datetime import datetime, timedelta, timezone
import anthropic
from services.db_service import get_client

BATCH_SIZE = 15
DAYS = 30

SCORING_RUBRIC = """NEXTSTEP arbejder primært med SMV'er (10-500 ansatte) der IKKE har intern PA- eller kommunikationskapacitet. Store virksomheder som Novo Nordisk, FLSmidth, Mærsk, DSV og andre med egne kommunikations- eller PA-afdelinger scorer LAVT – de har ikke brug for os.

90-100: Ekstraordinært lead. SMV (10-500 ansatte) UDEN intern PA-kapabilitet, akut politisk pres eller lovgivning på vej, klart handlingsvindue NU og identificerbar beslutningstager.
75-89: Stærkt lead. Relevant SMV eller brancheorganisation med konkret politisk situation der kræver handling inden for 1-3 måneder.
60-74: Godt lead. Relevant emne og aktør men handlingsvinduet er uklart eller aktøren er svær at identificere præcist.
41-59: Svagt lead. Relevant emne men stor virksomhed med intern PA, for generisk situation eller ingen klar indgang for NEXTSTEP.
0-40: Ikke relevant – store virksomheder med intern PA, rent nyhedsstof uden handlingsvindue, eller emner uden for NEXTSTEPs sektorer.

KRITISK VIGTIGT FOR SCORING: Hvert lead skal have sin helt egen unikke score. Vej hvert lead på dets egne specifikke meritter: styrken af det politiske handlingsvindue, aktørens størrelse og PA-kapacitet, timing og konkrethed. En forskel på bare 1-2 point er bedre end identiske scores."""


def build_prompt(batch: list) -> str:
    leads_text = ""
    for i, lead in enumerate(batch):
        leads_text += f"""
LEAD {i + 1}:
Titel: {lead.get('title', '')}
Situation: {lead.get('summary', '')}
Sektor: {lead.get('sector', '')}
Modul: {lead.get('module', '')}
Aktør: {lead.get('entity', '')}
Størrelse: {lead.get('size_info') or 'ukendt'}
"""

    return f"""Du er en strategisk analytiker for NEXTSTEP A/S – et dansk strategi- og innovationshus med speciale i Public Affairs og velfærdsforbedringer.

Nedenfor er {len(batch)} eksisterende leads. Din opgave er at RE-SCORE dem fra bunden ud fra deres reelle indhold. IGNORER at de tidligere har haft en score – den var upålidelig og skal ikke påvirke din vurdering.

{leads_text}

Før du scorer, skal du rangordne alle leads fra bedst til dårligst. Spredningen SKAL være mindst 25 points fra højeste til laveste, medmindre alle leads reelt er lige stærke. Max 2 leads må have samme score i hele batchen.

{SCORING_RUBRIC}

Svar KUN med et JSON-array, ét objekt per lead i samme rækkefølge som ovenfor:
[
  {{"lead_nr": 1, "score": 0-100}}
]"""


def rescore_all_leads():
    client = get_client()
    if not client:
        print("INGEN DB-FORBINDELSE - tjek SUPABASE_URL/SUPABASE_KEY i .env")
        return

    since = (datetime.now(timezone.utc) - timedelta(days=DAYS)).isoformat()
    result = (
        client.table("leads")
        .select("id,title,summary,sector,module,entity,size_info,score,created_at")
        .gte("created_at", since)
        .execute()
    )
    leads = result.data or []
    print(f"Fandt {len(leads)} leads under {DAYS} dage til re-scoring.\n")

    if not leads:
        return

    ai = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
    total_updated = 0
    total_failed = 0

    for batch_start in range(0, len(leads), BATCH_SIZE):
        batch = leads[batch_start:batch_start + BATCH_SIZE]
        batch_no = batch_start // BATCH_SIZE + 1
        print(f"--- Batch {batch_no} ({len(batch)} leads) ---")

        try:
            response = ai.messages.create(
                model="claude-sonnet-4-6",
                max_tokens=1000,
                messages=[{"role": "user", "content": build_prompt(batch)}],
            )
            text = response.content[0].text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
            text = text.rstrip("`").strip()
            results = json.loads(text)

            for item in results:
                nr = item.get("lead_nr", 1) - 1
                if not (0 <= nr < len(batch)):
                    continue
                lead = batch[nr]
                new_score = item.get("score")
                if new_score is None:
                    continue
                old_score = lead.get("score")
                client.table("leads").update({"score": new_score}).eq("id", lead["id"]).execute()
                total_updated += 1
                print(f"  {old_score:>3} -> {new_score:>3}  {lead.get('title', '')[:70]}")
        except Exception as e:
            total_failed += len(batch)
            print(f"  FEJL i batch {batch_no}: {e}")

    print(f"\nFærdig. {total_updated} leads re-scoret, {total_failed} fejlede (uændrede).")


if __name__ == "__main__":
    rescore_all_leads()
