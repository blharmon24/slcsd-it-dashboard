-- ============================================================================
--  RBAC — STEP B: lock all tracker tables to ADMIN ONLY
--  Run this ONCE in the Supabase SQL editor, AFTER user_roles_setup.sql
--  (Step A) and after you've confirmed your account resolves as 'admin'.
--
--  What it does, for every table listed below:
--    1. Ensures row level security is enabled
--    2. DROPS all existing policies (removes the old "any authenticated user"
--       read/write access)
--    3. Adds a single policy allowing ALL commands only when public.is_admin()
--    4. Re-affirms the Data API grants (RLS is what actually gates rows)
--
--  NOT touched on purpose:
--    - work_queue_items : stays user-scoped (auth.uid() = user_id) — see bottom
--    - user_roles       : keeps its "read own role" policy from Step A
--
--  Safe to re-run. Tables that don't exist are skipped with a notice.
--
--  >>> Staff users need NO table access: the only page they can see is
--      CardToUTA, which is 100% client-side and touches no database table. <<<
-- ============================================================================

do $$
declare
  t      text;
  pol    record;
  tables text[] := array[
    -- Grade storing
    'grade_store_records', 'checklist_completions', 'term_dates',
    -- Schedule build
    'schedule_build_records', 'sb_checklist_completions',
    -- CTC export
    'ctc_export_config', 'ctc_master_schedule',
    -- Rollover
    'rollover_config', 'rollover_records',
    'rollover_district_completions', 'rollover_school_completions',
    'rollover_district_notes', 'rollover_school_notes',
    'rollover_task_order', 'rollover_custom_tasks',
    'rollover_field_tasks', 'rollover_field_completions',
    -- Post-rollover grid
    'post_rollover_tasks', 'post_rollover_assignees', 'post_rollover_completions',
    -- K-6 clean status
    'k6_clean_status',
    -- Master data (skipped automatically if not present)
    'schools', 'terms'
  ];
begin
  foreach t in array tables loop
    if to_regclass('public.' || t) is null then
      raise notice 'skipping %.% (table does not exist)', 'public', t;
      continue;
    end if;

    -- 1. Ensure RLS is on
    execute format('alter table public.%I enable row level security', t);

    -- 2. Drop every existing policy on the table
    for pol in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = t
    loop
      execute format('drop policy if exists %I on public.%I', pol.policyname, t);
    end loop;

    -- 3. Admin-only policy for all commands
    execute format(
      'create policy %I on public.%I for all to authenticated ' ||
      'using (public.is_admin()) with check (public.is_admin())',
      t || '_admin_only', t
    );

    -- 4. Re-affirm Data API grants (RLS still governs which rows are visible)
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);

    raise notice 'locked %.% to admin-only', 'public', t;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
--  work_queue_items stays user-scoped: each user reads/writes only their own
--  rows. If you ever need to reset it to the intended policy, uncomment:
-- ---------------------------------------------------------------------------
-- alter table public.work_queue_items enable row level security;
-- drop policy if exists "wqi_own" on public.work_queue_items;
-- create policy "wqi_own" on public.work_queue_items for all to authenticated
--   using (auth.uid() = user_id) with check (auth.uid() = user_id);
-- grant select, insert, update, delete on public.work_queue_items to authenticated;

-- ============================================================================
--  VERIFY — every listed table should now show exactly one policy named
--  '<table>_admin_only'. work_queue_items and user_roles keep their own.
-- ============================================================================
select tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
order by tablename, policyname;
