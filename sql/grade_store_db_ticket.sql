-- Storing Grades: helpdesk ticket # for the "send report cards to DB team" task
-- Run once in the Supabase SQL editor.
--
-- One ticket per term per academic year, shared by ALL schools (e.g. 2026 T1 has a
-- single ticket the DB team references for every school's report cards).

create table if not exists public.grade_store_term_tickets (
  id            uuid primary key default gen_random_uuid(),
  academic_year int  not null,
  term_label    text not null,
  ticket_number text,
  updated_at    timestamptz default now(),
  updated_by    uuid references auth.users,
  unique (academic_year, term_label)
);

-- Admin-only, matching the other tracker tables (see rls_admin_lockdown.sql)
alter table public.grade_store_term_tickets enable row level security;
drop policy if exists grade_store_term_tickets_admin_only on public.grade_store_term_tickets;
create policy grade_store_term_tickets_admin_only on public.grade_store_term_tickets
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- New tables need explicit Data API grants
grant select, insert, update, delete on public.grade_store_term_tickets to authenticated;
