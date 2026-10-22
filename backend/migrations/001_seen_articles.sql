-- Husker hvilke artikler scraperen allerede har analyseret (også de irrelevante),
-- så de ikke sendes til AI'en igen ved hver kørsel.
-- Køres én gang i Supabase: SQL Editor -> New query -> indsæt -> Run.

create table if not exists public.seen_articles (
  url text primary key,
  created_at timestamptz not null default now()
);

create index if not exists seen_articles_created_at_idx
  on public.seen_articles (created_at);

alter table public.seen_articles enable row level security;

-- Nyere Supabase-projekter giver ikke automatisk rollen "anon" adgang til tabeller
-- oprettet via SQL Editor, så rettighederne skal gives eksplicit.
grant select, insert, delete on public.seen_articles to anon;

-- Backend'en bruger i dag en Publishable key (rollen "anon"), så den skal have
-- adgang her. Skifter backend'en senere til en Secret key (som går uden om RLS),
-- kan de tre politikker herunder slettes, så tabellen er helt lukket udefra.
create policy "backend kan laese seen_articles"
  on public.seen_articles for select to anon using (true);

create policy "backend kan skrive seen_articles"
  on public.seen_articles for insert to anon with check (true);

create policy "backend kan rydde seen_articles"
  on public.seen_articles for delete to anon using (true);
