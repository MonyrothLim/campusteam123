-- Run this in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.organizers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 1 and 120),
  description text not null default '',
  capacity integer not null check (capacity > 0 and capacity <= 10000),
  team_count integer not null default 2 check (team_count between 2 and 4),
  is_open boolean not null default true,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);
create table if not exists public.registrations (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games(id) on delete cascade,
  student_name text not null check (char_length(trim(student_name)) between 1 and 100),
  major text not null check (char_length(trim(major)) between 1 and 100),
  student_email text,
  created_at timestamptz not null default now()
);
create index if not exists registrations_game_id_idx on public.registrations(game_id);
alter table public.games enable row level security;
alter table public.organizers enable row level security;
alter table public.registrations enable row level security;

-- Public can read only the fields needed to find open registrations.
drop policy if exists "Anyone can view open games" on public.games;
create policy "Anyone can view open games" on public.games for select using (is_open = true or exists (select 1 from public.organizers o where o.user_id = auth.uid()));
drop policy if exists "Organizer can manage games" on public.games;
create policy "Organizer can manage games" on public.games for all to authenticated using (exists(select 1 from public.organizers o where o.user_id=auth.uid())) with check (exists(select 1 from public.organizers o where o.user_id=auth.uid()));
drop policy if exists "Organizer can view registrations" on public.registrations;
create policy "Organizer can view registrations" on public.registrations for select to authenticated using (exists(select 1 from public.organizers o where o.user_id=auth.uid()));
drop policy if exists "Organizer can delete registrations" on public.registrations;
create policy "Organizer can delete registrations" on public.registrations for delete to authenticated using (exists(select 1 from public.organizers o where o.user_id=auth.uid()));
drop policy if exists "Organizer records visible to self" on public.organizers;
create policy "Organizer records visible to self" on public.organizers for select to authenticated using (user_id=auth.uid());

-- Atomic registration: two students cannot take the final spot simultaneously.
create or replace function public.register_student(game_id uuid, student_name text, major text, student_email text default null)
returns void language plpgsql security definer set search_path = public as $$
declare g public.games%rowtype; current_count integer;
begin
  select * into g from public.games where id = register_student.game_id for update;
  if not found or not g.is_open then raise exception 'REGISTRATION_CLOSED'; end if;
  select count(*) into current_count from public.registrations r where r.game_id = g.id;
  if current_count >= g.capacity then
    update public.games set is_open = false where id = g.id;
    raise exception 'REGISTRATION_FULL';
  end if;
  if student_email is not null and exists(select 1 from public.registrations r where r.game_id=g.id and lower(r.student_email)=lower(register_student.student_email)) then
    raise exception 'DUPLICATE_EMAIL';
  end if;
  insert into public.registrations(game_id,student_name,major,student_email)
  values(g.id,trim(register_student.student_name),trim(register_student.major),nullif(trim(register_student.student_email),''));
  select count(*) into current_count from public.registrations r where r.game_id = g.id;
  if current_count >= g.capacity then update public.games set is_open = false where id = g.id; end if;
end; $$;
revoke all on function public.register_student(uuid,text,text,text) from public;
grant execute on function public.register_student(uuid,text,text,text) to anon, authenticated;
grant select on public.games to anon, authenticated;
grant select, insert, update, delete on public.games to authenticated;
grant select, delete on public.registrations to authenticated;
grant select on public.organizers to authenticated;
