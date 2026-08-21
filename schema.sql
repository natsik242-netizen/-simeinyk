
-- СІМЕЙНИК: базова схема Supabase
-- Запустіть цей файл в Supabase -> SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  created_at timestamptz default now()
);

create table if not exists public.families (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

create table if not exists public.family_members (
  family_id uuid not null references public.families(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz default now(),
  primary key (family_id,user_id)
);

create table if not exists public.family_invites (
  id uuid primary key default gen_random_uuid(),
  family_id uuid not null references public.families(id) on delete cascade,
  code text not null unique,
  created_by uuid not null references auth.users(id) on delete cascade,
  expires_at timestamptz default (now() + interval '30 days'),
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;
alter table public.families enable row level security;
alter table public.family_members enable row level security;
alter table public.family_invites enable row level security;

drop policy if exists "profile self select" on public.profiles;
create policy "profile self select" on public.profiles for select using (auth.uid() = id);

drop policy if exists "profile self insert" on public.profiles;
create policy "profile self insert" on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "profile self update" on public.profiles;
create policy "profile self update" on public.profiles for update using (auth.uid() = id);

drop policy if exists "family members can view families" on public.families;
create policy "family members can view families" on public.families
for select using (
  exists(select 1 from public.family_members fm where fm.family_id=families.id and fm.user_id=auth.uid())
);

drop policy if exists "members see memberships" on public.family_members;
create policy "members see memberships" on public.family_members
for select using (
  exists(select 1 from public.family_members me where me.family_id=family_members.family_id and me.user_id=auth.uid())
);

create or replace view public.my_families
with (security_invoker=true)
as
select f.id,f.name,f.created_at,fm.role
from public.families f
join public.family_members fm on fm.family_id=f.id
where fm.user_id=auth.uid();

create or replace view public.family_members_public
with (security_invoker=true)
as
select fm.family_id,fm.user_id,fm.role,p.display_name,p.email
from public.family_members fm
left join public.profiles p on p.id=fm.user_id;

grant select on public.my_families to authenticated;
grant select on public.family_members_public to authenticated;

create or replace function public.create_family(p_name text)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  insert into public.families(name,created_by) values(trim(p_name),auth.uid()) returning id into v_id;
  insert into public.family_members(family_id,user_id,role) values(v_id,auth.uid(),'owner');
  return v_id;
end;
$$;
grant execute on function public.create_family(text) to authenticated;

create or replace function public.create_family_invite(p_family_id uuid)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare v_code text;
begin
  if not exists(
    select 1 from public.family_members
    where family_id=p_family_id and user_id=auth.uid() and role in ('owner','admin')
  ) then raise exception 'No permission'; end if;

  v_code := encode(gen_random_bytes(12),'hex');
  insert into public.family_invites(family_id,code,created_by)
  values(p_family_id,v_code,auth.uid());
  return v_code;
end;
$$;
grant execute on function public.create_family_invite(uuid) to authenticated;

create or replace function public.join_family_by_code(p_code text)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare v_family uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;

  select family_id into v_family
  from public.family_invites
  where code=p_code and expires_at>now()
  order by created_at desc
  limit 1;

  if v_family is null then return false; end if;

  insert into public.family_members(family_id,user_id,role)
  values(v_family,auth.uid(),'member')
  on conflict do nothing;

  return true;
end;
$$;
grant execute on function public.join_family_by_code(text) to authenticated;
