-- ============================================================================
--  Manage admins — promote / demote users. Run blocks in the Supabase SQL
--  editor as needed. A user must already exist in auth.users (i.e. have logged
--  in once, or been created under Authentication -> Users) before you can set
--  their role here. Everyone defaults to 'staff' until promoted.
-- ============================================================================

-- ── PROMOTE to admin (edit the emails) ──────────────────────────────────────
insert into public.user_roles (user_id, role)
select id, 'admin' from auth.users
where lower(email) in (
  lower('coworker1@example.com'),
  lower('coworker2@example.com')
)
on conflict (user_id) do update set role = 'admin';

-- ── DEMOTE back to staff (edit the emails) ──────────────────────────────────
-- update public.user_roles set role = 'staff'
-- where user_id in (
--   select id from auth.users where lower(email) in (
--     lower('coworker1@example.com'),
--     lower('coworker2@example.com')
--   )
-- );

-- ── VERIFY current roles ────────────────────────────────────────────────────
select u.email, r.role
from public.user_roles r join auth.users u on u.id = r.user_id
order by r.role, u.email;
