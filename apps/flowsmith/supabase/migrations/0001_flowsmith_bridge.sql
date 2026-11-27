-- FLOWSMITH Bridge DB (optional). NOT applied anywhere yet.
-- The app already syncs through the Claude artifact's private db. Apply this only if you want the
-- standalone app (GitHub Pages / phone home screen) to sync songs without opening Claude, or want
-- other agents (Resonara, Mountain Lion) to read FLOWSMITH songs and lessons.
-- Every table is per user (user_id = auth.uid()) with row-level security on.

create extension if not exists pgcrypto;

-- Song folders (one row per song)
create table if not exists public.songs (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  title text not null,
  parent_id text references public.songs(id) on delete set null,
  latest_n int not null default 1,
  latest_hash text,
  score int, grade text, rating int default 0,
  tags text[] default '{}',
  preview text,
  next jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Versions = receipts: append-only, hash-chained (prev_hash -> hash, SHA-256 computed in the app)
create table if not exists public.versions (
  song_id text not null references public.songs(id) on delete cascade,
  n int not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  prompt text not null,
  lyrics text not null default '',
  chips text[] not null default '{}',
  settings jsonb not null default '{}'::jsonb,
  state jsonb not null default '{}'::jsonb,
  source text not null default 'engine',
  change_note text,
  score int, grade text,
  rating int, result_notes text, flow_link text,
  prev_hash text not null,
  hash text not null,
  created_at timestamptz not null default now(),
  primary key (song_id, n)
);

-- Sealed fields can't change after insert (rating fields can).
create or replace function public.versions_sealed() returns trigger language plpgsql as $$
begin
  if new.prompt is distinct from old.prompt or new.lyrics is distinct from old.lyrics
     or new.chips is distinct from old.chips or new.settings is distinct from old.settings
     or new.hash is distinct from old.hash or new.prev_hash is distinct from old.prev_hash
     or new.n is distinct from old.n or new.song_id is distinct from old.song_id then
    raise exception 'versions are append-only: save a new version instead';
  end if;
  return new;
end $$;
drop trigger if exists versions_sealed on public.versions;
create trigger versions_sealed before update on public.versions for each row execute function public.versions_sealed();

-- Directives (kernel): standing instructions per agent; a newer one supersedes the older.
create table if not exists public.directives (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  target_agent text not null check (target_agent in ('composer','tweaker','critic','nexter','librarian')),
  body text not null,
  version int not null default 1,
  expires_at timestamptz,
  issued_by text not null default 'user',
  status text not null default 'active' check (status in ('active','superseded','expired')),
  created_at timestamptz not null default now()
);
create or replace function public.directives_supersede() returns trigger language plpgsql as $$
begin
  update public.directives set status = 'superseded'
   where user_id = new.user_id and target_agent = new.target_agent and status = 'active' and id <> new.id;
  return new;
end $$;
drop trigger if exists directives_supersede on public.directives;
create trigger directives_supersede after insert on public.directives for each row execute function public.directives_supersede();

-- Quarantine: lessons Claude proposes from ratings land here first.
create table if not exists public.quarantine (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  proposed_by text not null default 'librarian',
  content text not null,
  source text,            -- song id / version the lesson came from
  reason text,            -- the evidence from the user's notes
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

-- Skills ledger: approved lessons, append-only.
create table if not exists public.skills_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  agent text not null default 'composer',
  skill text not null,
  evidence text,
  approved_by text not null default 'user',
  created_at timestamptz not null default now()
);
create or replace function public.append_only() returns trigger language plpgsql as $$
begin raise exception '% is append-only', tg_table_name; end $$;
drop trigger if exists skills_ledger_append_only on public.skills_ledger;
create trigger skills_ledger_append_only before update or delete on public.skills_ledger for each row execute function public.append_only();

-- Traces: one row per Claude call.
create table if not exists public.traces (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  run_id text not null,
  agent text not null,
  backend text not null,
  step int not null default 1,
  tokens_in int, tokens_out int,
  cost_usd numeric(10,5),
  latency_ms int,
  error text,
  ts timestamptz not null default now()
);
drop trigger if exists traces_append_only on public.traces;
create trigger traces_append_only before update on public.traces for each row execute function public.append_only();

create index if not exists songs_user_updated on public.songs (user_id, updated_at desc);
create index if not exists traces_user_ts on public.traces (user_id, ts desc);

-- Row-level security: each person sees and writes only their own rows.
do $$
declare t text;
begin
  foreach t in array array['songs','versions','directives','quarantine','skills_ledger','traces'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_own', t);
    execute format('create policy %I on public.%I for all using (user_id = auth.uid()) with check (user_id = auth.uid())', t || '_own', t);
  end loop;
end $$;
