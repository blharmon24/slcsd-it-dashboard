-- ============================================================================
--  User Roles (RBAC) — STEP A: table, helper, and admin seed
--  Run this ONCE in the Supabase SQL editor.
--
--  This is the FOUNDATION for restricting pages. After you run it and confirm
--  your account resolves as 'admin' (verification query at the bottom), we then
--  (Step B) lock the tracker tables to admin-only and add the sidebar gating.
--
--  >>> IMPORTANT: set ADMIN_EMAIL below to the email you LOG INTO THE DASHBOARD
--      with (not necessarily your personal email). Everyone else defaults to
--      'staff'. You can re-run the seed at any time to add/relabel admins.
-- ============================================================================

-- 1. Roles table (one row per user) ----------------------------------------
create table if not exists public.user_roles (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  role        text not null default 'staff' check (role in ('admin', 'staff')),
  created_at  timestamptz not null default now()
);

-- 2. RLS: a user may read ONLY their own role row.
--    There is intentionally NO insert/update policy for authenticated users,
--    so roles can only be changed here in the SQL editor (service role).
--    This prevents a staff user from promoting themselves to admin.
alter table public.user_roles enable row level security;

drop policy if exists "user_roles_read_own" on public.user_roles;
create policy "user_roles_read_own"
  on public.user_roles for select to authenticated
  using (auth.uid() = user_id);

-- Data API grant (required for tables created after 2026-05-30).
-- SELECT only — no write access for authenticated users.
grant select on public.user_roles to authenticated;

-- 3. is_admin() helper — used by Step B's RLS policies.
--    SECURITY DEFINER so it can read user_roles without tripping RLS recursion.
create or replace function public.is_admin()
  returns boolean
  language sql
  security definer
  stable
  set search_path = public
as $$
  select exists (
    select 1 from public.user_roles
    where user_id = auth.uid() and role = 'admin'
  );
$$;

grant execute on function public.is_admin() to authenticated;

-- 4. Seed YOUR account as admin -------------------------------------------
--    >>> EDIT this email to match your dashboard login <<<
insert into public.user_roles (user_id, role)
select id, 'admin'
from auth.users
where lower(email) = lower('blharmon@gmail.com')   -- <-- ADMIN_EMAIL
on conflict (user_id) do update set role = 'admin';

-- ============================================================================
--  VERIFY — run this after the insert. You should see your email with 'admin'.
--  If it returns 0 rows, the ADMIN_EMAIL above did not match any auth.users
--  row (check exactly which email you sign in with) and re-run section 4.
-- ============================================================================
select u.email, r.role, r.created_at
from public.user_roles r
join auth.users u on u.id = r.user_id
order by r.role, u.email;
