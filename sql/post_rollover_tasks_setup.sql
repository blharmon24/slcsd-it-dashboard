-- ============================================================================
--  Post-Rollover Tasks — one-time Supabase setup
--  Run this ONCE in the Supabase SQL editor. After it runs, tasks/assignees/
--  check-offs are all managed from the dashboard (no further SQL needed).
-- ============================================================================

-- 1. Task definitions (year-agnostic; add/remove from the dashboard) --------
create table if not exists post_rollover_tasks (
  id          uuid primary key default gen_random_uuid(),
  label       text not null,
  sort_order  int  not null default 0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 2. Per-task, per-year assignee (VG / BH / JF / SQ) -----------------------
create table if not exists post_rollover_assignees (
  id             uuid primary key default gen_random_uuid(),
  task_id        uuid not null references post_rollover_tasks(id) on delete cascade,
  academic_year  int  not null,
  assignee       text,
  unique (task_id, academic_year)
);

-- 3. Per-task, per-school, per-year check-off ------------------------------
create table if not exists post_rollover_completions (
  id                uuid primary key default gen_random_uuid(),
  task_id           uuid not null references post_rollover_tasks(id) on delete cascade,
  school_name       text not null,
  academic_year     int  not null,
  completed         boolean not null default false,
  completed_at      timestamptz,
  completed_by      uuid references auth.users(id),
  completed_by_name text,
  unique (task_id, school_name, academic_year)
);

-- RLS: any authenticated user can read/write -------------------------------
alter table post_rollover_tasks       enable row level security;
alter table post_rollover_assignees   enable row level security;
alter table post_rollover_completions enable row level security;

create policy "pro_tasks_auth"       on post_rollover_tasks       for all to authenticated using (true) with check (true);
create policy "pro_assignees_auth"   on post_rollover_assignees   for all to authenticated using (true) with check (true);
create policy "pro_completions_auth" on post_rollover_completions for all to authenticated using (true) with check (true);

-- Data API grants (required for tables created after 2026-05-30) -----------
grant select, insert, update, delete on post_rollover_tasks       to authenticated;
grant select, insert, update, delete on post_rollover_assignees   to authenticated;
grant select, insert, update, delete on post_rollover_completions to authenticated;

-- 4. Seed the 34 task columns (verbatim from the Matrix spreadsheet) -------
insert into post_rollover_tasks (label, sort_order) values
  ('Years & Terms (School Management>Scheduling>Years and Terms)', 1),
  ('Verify Student Enrollments - Next School Indicator, Pre-Registered', 2),
  ('Periods (School Management>Scheduling>Periods)', 3),
  ('?Period Display ( Start>School>Scheduling - Preferences) Period then Day', 4),
  ('Cycle Days (School Management>Scheduling>Cycle Days)', 5),
  ('?Course Catalog - Course Availability', 6),
  ('Attendance Codes (School Management>Attendance>Attendance Codes)', 7),
  ('Attendance Code Categories (School Management>Attendance>Attendance Code Categories)', 8),
  ('Attendance Conversions (School Management>Attendance>Attendance Conversions)', 9),
  ('Code-To-Day Attendance Conversion (School Management>Attendance>Attendance Conversions (FTE))', 10),
  ('FTEs (Schol Management>Attendance>Full-Time Equivelencies)', 11),
  ('Attendance Preferences (School Management>Attendance>Attendance Preferences)', 12),
  ('School Enrollment Audit (Data & Reporting>Reports>System Reports>School Enrollment Audit)', 13),
  ('Section Enrollment Audit (Data & Reporting>Reports>System Reports>Section Enrollment Audit)', 14),
  ('Sections - Close Section at Max (DDA)', 15),
  ('Close Secions At Max Enrollment (School Management>SchedulingSchedule Preference)', 16),
  ('?Section Term / Credit', 17),
  ('Bell Schedule (Start Page>School>Bell Schedule)', 18),
  ('Calendar (Start Page>School>Calendar Setup - Copy Calendar)', 19),
  ('180 Days Check', 20),
  ('Report Segments (System Management>Reports>Reporting Segments)', 21),
  ('Final Grade Setup (School Management>Academics>Create Final Grade and Reorting Term (Copy))', 22),
  ('Current Grade Display (School Management>Academics>Set Current Grade Display)', 23),
  ('GPA Student Screens (School Management>Academics>GPA>GPA Info for Student Screens)(Shouldn''t need to be touched)', 24),
  ('Student Counselor Assignment', 25),
  ('High School Student - Graduation Plan Selection', 26),
  ('Count Mutli-Period Meeting Attend once per day (School Management>Display Preferences>Quick Lookup Display Preferences)', 27),
  ('Home Release Sections Exclude From Storing Final Grades', 28),
  ('Release Time Sections Exclude From Storing Final Grades', 29),
  ('Record Attendance Once for All Meetings (DDA -> Sections -> Attendance_Type_Code = 0)', 30),
  ('Final Grade Entry Options', 31),
  ('Clear Activities', 32),
  ('Setup BIC Mapping System Management>Set Attendance and Breakfast period for school & Map attendance Codes to Breakfast Attendance Codes', 33),
  ('Clear out Locker and advance Sequence', 34);
