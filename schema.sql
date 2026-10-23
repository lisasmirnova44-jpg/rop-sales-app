-- РОП · Центр управления продажами
-- ВНИМАНИЕ: схема ниже рассчитана на общий доступ БЕЗ входа в систему.
-- Это НЕ безопасно для персональных данных, клиентских контактов, коммерческих секретов или конфиденциальных комментариев.
-- Используйте только обезличенные коды (СД-001, ПР-01) и данные, которые можно показывать и менять любому человеку с URL.
-- Для реальной эксплуатации с клиентскими данными настройте Supabase Auth и закрытые RLS-политики.

create extension if not exists pgcrypto;

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) <= 240),
  area text not null default 'Продажи' check (area in ('Продажи','CRM','Команда','Аналитика','Планёрки','Развитие процессов')),
  priority text not null default 'P2' check (priority in ('P1','P2','P3')),
  due date,
  minutes integer not null default 30 check (minutes between 0 and 1440),
  status text not null default 'open' check (status in ('open','done')),
  owner text not null default 'РОП' check (char_length(owner) <= 100),
  result text not null default '' check (char_length(result) <= 1000),
  reason text not null default '' check (char_length(reason) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deals (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (char_length(code) <= 80),
  seller text not null default '' check (char_length(seller) <= 80),
  stage text not null default 'Новый запрос' check (char_length(stage) <= 120),
  amount numeric(14,2) not null default 0 check (amount >= 0),
  status text not null default 'active' check (status in ('active','won','lost')),
  risk boolean not null default false,
  last_contact date,
  next_step text not null default '' check (char_length(next_step) <= 1000),
  next_date date,
  notes text not null default '' check (char_length(notes) <= 2000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.team (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (char_length(code) <= 80),
  plan numeric(14,2) not null default 0 check (plan >= 0),
  fact numeric(14,2) not null default 0 check (fact >= 0),
  conversion numeric(5,2) not null default 0 check (conversion between 0 and 100),
  focus text not null default '' check (char_length(focus) <= 500),
  action text not null default '' check (char_length(action) <= 1000),
  status text not null default 'В работе' check (status in ('В работе','Нужно внимание','Стабильно')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists tasks_updated_at on public.tasks;
create trigger tasks_updated_at before update on public.tasks for each row execute function public.set_updated_at();
drop trigger if exists deals_updated_at on public.deals;
create trigger deals_updated_at before update on public.deals for each row execute function public.set_updated_at();
drop trigger if exists team_updated_at on public.team;
create trigger team_updated_at before update on public.team for each row execute function public.set_updated_at();

alter table public.tasks enable row level security;
alter table public.deals enable row level security;
alter table public.team enable row level security;

-- ПУБЛИЧНЫЕ политики: любой посетитель с anon key может читать/добавлять/изменять/удалять строки.
-- Это позволяет общей ссылке работать без входа, но означает, что данные НЕ конфиденциальны.
drop policy if exists "public shared access tasks" on public.tasks;
create policy "public shared access tasks" on public.tasks
for all to anon, authenticated
using (true) with check (true);

drop policy if exists "public shared access deals" on public.deals;
create policy "public shared access deals" on public.deals
for all to anon, authenticated
using (true) with check (true);

drop policy if exists "public shared access team" on public.team;
create policy "public shared access team" on public.team
for all to anon, authenticated
using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.tasks to anon, authenticated;
grant select, insert, update, delete on public.deals to anon, authenticated;
grant select, insert, update, delete on public.team to anon, authenticated;

-- Не храните здесь реальные имена/телефоны/адреса клиентов, документы, пароли,
-- данные о платежах или чувствительные сведения о сотрудниках.
-- Для закрытого варианта: удалите публичные политики, используйте Supabase Auth,
-- а доступ задайте через роли и проверки пользователя на стороне базы.
