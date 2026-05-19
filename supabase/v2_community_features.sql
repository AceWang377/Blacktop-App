-- Blacktop V2 community contribution layer.
-- Run in Supabase SQL Editor after the V1 courts schema is deployed.

create extension if not exists pgcrypto;

create table if not exists public.blacktop_profiles (
    user_id uuid primary key references auth.users(id) on delete cascade,
    display_name text,
    role text not null default 'user' check (role in ('user', 'admin')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.court_fact_updates (
    id uuid primary key default gen_random_uuid(),
    court_id text not null references public.courts(id) on delete cascade,
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    field_key text not null,
    suggested_value text not null,
    status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
    reviewed_by uuid references auth.users(id),
    reviewed_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint court_fact_updates_field_check check (
        field_key in (
            'dryness_after_rain',
            'has_nets',
            'has_lights',
            'rim_height',
            'rim_type',
            'court_space',
            'court_cleanliness',
            'price_type',
            'court_type',
            'has_toilets',
            'has_drinking_water',
            'has_parking'
        )
    )
);

create table if not exists public.court_fact_votes (
    id uuid primary key default gen_random_uuid(),
    court_id text not null references public.courts(id) on delete cascade,
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    field_key text not null,
    vote_value text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (court_id, user_id, field_key),
    constraint court_fact_votes_field_check check (
        field_key in (
            'dryness_after_rain',
            'has_nets',
            'has_lights',
            'rim_height',
            'rim_type',
            'court_space',
            'court_cleanliness',
            'price_type',
            'court_type',
            'has_toilets',
            'has_drinking_water',
            'has_parking'
        )
    )
);

create table if not exists public.saved_courts (
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    court_id text not null references public.courts(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, court_id)
);

create table if not exists public.court_vibe_votes (
    id uuid primary key default gen_random_uuid(),
    court_id text not null references public.courts(id) on delete cascade,
    user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
    category text not null check (category in ('usual_intensity', 'best_for', 'join_in_feel')),
    option text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (court_id, user_id, category),
    constraint court_vibe_votes_option_check check (
        option in (
            'calm',
            'balanced',
            'competitive',
            'solo_shooting',
            'casual_runs',
            'serious_pickup',
            'beginners',
            'three_on_three',
            'after_work',
            'welcoming',
            'regulars_first',
            'hard_to_join'
        )
    )
);

create index if not exists court_fact_updates_court_status_idx
    on public.court_fact_updates (court_id, status, created_at desc);

create index if not exists court_fact_updates_user_idx
    on public.court_fact_updates (user_id, created_at desc);

create index if not exists court_fact_votes_court_field_idx
    on public.court_fact_votes (court_id, field_key);

create index if not exists court_vibe_votes_court_category_idx
    on public.court_vibe_votes (court_id, category);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists set_blacktop_profiles_updated_at on public.blacktop_profiles;
create trigger set_blacktop_profiles_updated_at
before update on public.blacktop_profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_court_fact_updates_updated_at on public.court_fact_updates;
create trigger set_court_fact_updates_updated_at
before update on public.court_fact_updates
for each row execute function public.set_updated_at();

drop trigger if exists set_court_fact_votes_updated_at on public.court_fact_votes;
create trigger set_court_fact_votes_updated_at
before update on public.court_fact_votes
for each row execute function public.set_updated_at();

drop trigger if exists set_court_vibe_votes_updated_at on public.court_vibe_votes;
create trigger set_court_vibe_votes_updated_at
before update on public.court_vibe_votes
for each row execute function public.set_updated_at();

create or replace function public.is_blacktop_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1
        from public.blacktop_profiles
        where user_id = auth.uid()
          and role = 'admin'
    );
$$;

create or replace view public.court_vibe_summaries as
with category_totals as (
    select
        court_id,
        category,
        count(*)::int as category_total
    from public.court_vibe_votes
    group by court_id, category
),
option_totals as (
    select
        court_id,
        category,
        option,
        count(*)::int as vote_count
    from public.court_vibe_votes
    group by court_id, category, option
)
select
    option_totals.court_id,
    option_totals.category,
    option_totals.option,
    option_totals.vote_count,
    category_totals.category_total,
    round((option_totals.vote_count::numeric / nullif(category_totals.category_total, 0)) * 100)::int as percentage
from option_totals
join category_totals
  on category_totals.court_id = option_totals.court_id
 and category_totals.category = option_totals.category;

create or replace view public.court_fact_vote_summaries as
with field_totals as (
    select
        court_id,
        field_key,
        count(*)::int as field_total
    from public.court_fact_votes
    group by court_id, field_key
),
value_totals as (
    select
        court_id,
        field_key,
        vote_value,
        count(*)::int as vote_count
    from public.court_fact_votes
    group by court_id, field_key, vote_value
)
select
    value_totals.court_id,
    value_totals.field_key,
    value_totals.vote_value,
    value_totals.vote_count,
    field_totals.field_total,
    round((value_totals.vote_count::numeric / nullif(field_totals.field_total, 0)) * 100)::int as percentage
from value_totals
join field_totals
  on field_totals.court_id = value_totals.court_id
 and field_totals.field_key = value_totals.field_key;

alter table public.blacktop_profiles enable row level security;
alter table public.court_fact_updates enable row level security;
alter table public.court_fact_votes enable row level security;
alter table public.court_vibe_votes enable row level security;
alter table public.saved_courts enable row level security;

drop policy if exists "Profiles can read own profile" on public.blacktop_profiles;
create policy "Profiles can read own profile"
on public.blacktop_profiles
for select
to authenticated
using (auth.uid() = user_id or public.is_blacktop_admin());

drop policy if exists "Profiles can insert own profile" on public.blacktop_profiles;
create policy "Profiles can insert own profile"
on public.blacktop_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Profiles can update own profile" on public.blacktop_profiles;
create policy "Profiles can update own profile"
on public.blacktop_profiles
for update
to authenticated
using (auth.uid() = user_id or public.is_blacktop_admin())
with check (auth.uid() = user_id or public.is_blacktop_admin());

drop policy if exists "Users can insert own fact updates" on public.court_fact_updates;
create policy "Users can insert own fact updates"
on public.court_fact_updates
for insert
to authenticated
with check (auth.uid() = user_id and status = 'pending');

drop policy if exists "Users can read own fact updates" on public.court_fact_updates;
create policy "Users can read own fact updates"
on public.court_fact_updates
for select
to authenticated
using (auth.uid() = user_id or public.is_blacktop_admin());

drop policy if exists "Admins can review fact updates" on public.court_fact_updates;
create policy "Admins can review fact updates"
on public.court_fact_updates
for update
to authenticated
using (public.is_blacktop_admin())
with check (public.is_blacktop_admin());

drop policy if exists "Users can insert own fact votes" on public.court_fact_votes;
create policy "Users can insert own fact votes"
on public.court_fact_votes
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own fact votes" on public.court_fact_votes;
create policy "Users can update own fact votes"
on public.court_fact_votes
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can read own fact votes" on public.court_fact_votes;
create policy "Users can read own fact votes"
on public.court_fact_votes
for select
to authenticated
using (auth.uid() = user_id or public.is_blacktop_admin());

drop policy if exists "Users can upsert own vibe votes" on public.court_vibe_votes;
create policy "Users can upsert own vibe votes"
on public.court_vibe_votes
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own vibe votes" on public.court_vibe_votes;
create policy "Users can update own vibe votes"
on public.court_vibe_votes
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can read own vibe votes" on public.court_vibe_votes;
create policy "Users can read own vibe votes"
on public.court_vibe_votes
for select
to authenticated
using (auth.uid() = user_id or public.is_blacktop_admin());

drop policy if exists "Users can read own saved courts" on public.saved_courts;
create policy "Users can read own saved courts"
on public.saved_courts
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own saved courts" on public.saved_courts;
create policy "Users can insert own saved courts"
on public.saved_courts
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own saved courts" on public.saved_courts;
create policy "Users can delete own saved courts"
on public.saved_courts
for delete
to authenticated
using (auth.uid() = user_id);

grant select, insert, update on public.blacktop_profiles to authenticated;
grant select, insert, update on public.court_fact_updates to authenticated;
grant select, insert, update on public.court_fact_votes to authenticated;
grant select, insert, update on public.court_vibe_votes to authenticated;
grant select, insert, delete on public.saved_courts to authenticated;
grant select on public.court_vibe_summaries to anon, authenticated;
grant select on public.court_fact_vote_summaries to anon, authenticated;
