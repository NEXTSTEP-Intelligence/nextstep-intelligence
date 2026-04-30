import anthropic
import json
import os

def get_client():
    return anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

async def analyze_client_perspective(client_name: str, leads: list) -> list:
    client = get_client()
    
    leads_text = "\n".join([
        f"ID: {l.get('id')}\nTitel: {l.get('title')}\nResumé: {l.get('summary', '')[:200]}\nSektor: {l.get('sector')}\nScore: {l.get('score')}\nVej ind: {l.get('opener')}"
        for l in leads
    ])
    
    prompt = f"""Du er strategisk rådgiver hos NEXTSTEP A/S. En kollega vil se alle aktuelle leads fra {client_name}'s perspektiv.

Analyser hvert lead og vurder:
1. Hvor relevant er dette lead specifikt for {client_name}?
2. Hvad er den bedste indgangsvinkel for {client_name} i denne situation?

AKTUELLE LEADS:
{leads_text}

Svar KUN med JSON array – ét objekt per lead i samme rækkefølge:
[
  {{
    "id": "lead-id",
    "client_score": 0-100,
    "client_opener": "specifik indgangsvinkel for {client_name}",
    "client_relevance": "én sætning om hvorfor dette er relevant for {client_name}"
  }}
]"""

    try:
        response = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=2000,
            messages=[{"role": "user", "content": prompt}]
        )
        text = response.content[0].text.strip()
        if "```" in text:
            text = text.split("```")[1]
            if text.startswith("json"):
                text = text[4:]
        
        analysis = json.loads(text)
        analysis_map = {a["id"]: a for a in analysis}
        
        result = []
        for lead in leads:
            lead_id = lead.get("id")
            if lead_id in analysis_map:
                a = analysis_map[lead_id]
                lead_copy = dict(lead)
                lead_copy["client_score"] = a.get("client_score", lead.get("score", 0))
                lead_copy["client_opener"] = a.get("client_opener", lead.get("opener", ""))
                lead_copy["client_relevance"] = a.get("client_relevance", "")
                result.append(lead_copy)
            else:
                result.append(lead)
        
        result.sort(key=lambda x: x.get("client_score", 0), reverse=True)
        return result
        
    except Exception as e:
        print(f"Klientlinse fejl: {e}")
        return leads
