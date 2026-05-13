# SLCSD IT Dashboard — Project Context for Claude

## Project Overview
A school district IT dashboard built as a single HTML file. It serves as a central hub
for tracking IT workflows, progress monitoring, checklists, and documentation across
the district. It is viewable by anyone in the organization for the tracker portions,
and managed by IT staff.

## Current Status
**Phase: Active development.**
- **Storing Grades** — PowerSchool grade storage tracker (first feature)
- **Schedule Build Tracker** — next year schedule build progress (added 2026-04-15)
- **CTC Schedule Export** — generates tab-delimited import files for CTC (added 2026-04-16)
- **School Rollover** — tracks EOY PowerSchool rollover progress per school (added 2026-04-21)
- **My Tasks** — personal per-user work queue with Urgent/Medium/Low lanes (added 2026-04-22)
- **Class Choice Processes** — client-side file processor for CTC master schedule seat sharing (added 2026-04-24)
- **CardToUTA** — client-side CSV processor converting daily card access export to UTA activation format (added 2026-05-07)
- **Password Reset Flow** — self-service forgot password link + in-page reset screen (added 2026-05-07)

## Tech Stack
- **Frontend:** Single HTML file (`dashboard.html`) — HTML, CSS, and JavaScript
- **Backend/Database:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth (user references auth.users)
- **Version Control:** GitHub — https://github.com/blharmon24/slcsd-it-dashboard
- **Live URL:** https://blharmon24.github.io/slcsd-it-dashboard/dashboard.html
- **Local Folder:** C:\ClaudeAI\IT-Dashboard
- **Dependencies (CDN):**
  - Supabase JS v2
  - JSZip v3.10.1 (used for CTC ZIP export only)

## File Structure
- Single HTML file (`dashboard.html`) — all HTML, CSS, and JavaScript in one file
- Do not split into multiple files unless explicitly asked
- GitHub repository houses the dashboard.html file

## Versioning
- Sidebar shows a version label: `v2026.04.DD.X`
- **Must be bumped on every single commit** — the user relies on it to confirm the latest
  version is deployed
- Last digit increments for multiple changes on the same date (e.g., .1, .2, .3)

## Page Persistence
- The last active page is saved to `localStorage` under key `it_dash_page`
- On login, the saved page is restored; defaults to `grade-storing` if none saved
- Valid page keys: `grade-storing`, `schedule-commit`, `my-tasks`, `cardtouta`

## Sidebar Structure (as of 2026-05-07)
**Grade Storing** (section header)
- Storing Grades → `page-grade-storing`

**Other Modules** (section header)
- PowerScheduler → `page-schedule-commit`
- CardToUTA → `page-cardtouta`

**Personal** (section header)
- My Tasks → `page-my-tasks`

Related features are grouped as tabs within a page rather than separate sidebar items:
- **Storing Grades page:** "Storing Grades" tab + "Grade Store History" tab
- **School Schedule Build Tracker page:** "Schedule Build" tab + "CTC Export" tab + "School Rollover" tab + "Class Choice Processes" tab

Active tab on the Schedule Build page persists to localStorage (`it_dash_sb_tab`).

## Audience
- **IT Staff** — manage records, complete checklists, update progress
- **General Organization Staff** — view-only access to tracker progress per school
- **Future:** May be expanded for team use beyond just the developer

---

## Feature: Storing Grades (PowerSchool Grade Storage Tracker)

### What it does
Tracks the full workflow of storing PowerSchool grades across all schools in the district.
Each school goes through a series of steps and checklist items that must be completed
to successfully store grades for a given term. The dashboard shows:
- Summary bar with four SVG doughnut charts: All Schools, High Schools, Middle Schools, Elementary
- Per-card checklist progress indicator showing tasks done / total
- Overdue highlighting (red card) when a school is still Not Started 14+ days after term end
- Auto term selection based on saved term end dates
- As-of date auto-fills to the day before the term end date

### Workflow concepts
- Each school has a `grade_store_record` per term/academic year
- Each record has associated `checklist_completions` tracking individual task steps
- `ctc_confirmed` flag indicates CTC confirmation step is done
- `completed` flag marks the entire grade store process as finished for that school/term
- Academic year is stored as a 4-digit integer (e.g., `2025`) but displayed as `25-26`

### Term end dates
- Stored in the `term_dates` table with a `schedule_type` column
- `schedule_type = 'traditional'` — T1–T4 end dates for all schools except Horizonte
- `schedule_type = 'horizonte'` — T1–T6 end dates for Horizonte specifically
- The page auto-selects the most recently ended traditional term on load
- Overdue check uses Horizonte dates for Horizonte, traditional dates for all others

---

## Feature: Schedule Build Tracker

### What it does
Tracks next year schedule build progress for high schools and middle schools.
Accessible via the "Schedule Commit" nav item in the sidebar.

### Workflow concepts
- One `schedule_build_record` per school per academic year
- Tracks the responsible person and current build status
- Status progression: Not Started → Collecting Requests → Course Preferences & Assignments
  → Building → Loading → Complete
- Each school card shows a 5-segment heat-colored progress bar (red → green)
- Summary bar shows pill counts per status (e.g., "2 Building · 4 Complete")
- Horizonte is excluded — they do not build a schedule
- East HS, Highland HS, and West HS require CTC class push confirmation before
  transitioning from Building to Loading (`ctc_push_confirmed` flag)
- When a school reaches Complete, a schedule commit checklist appears in the detail view
  (stored in `sb_checklist_completions`)
- Each school card has a `using_powerscheduler` checkbox (bool on `schedule_build_records`);
  when checked, a blue "PS Elec. Requests" badge appears on the card

---

## Feature: CTC Schedule Export

### What it does
Generates tab-delimited import files for the Career and Technical Center (CTC) from an
uploaded master schedule. Accessible via "CTC Export" in the sidebar.

### Workflow concepts
- Annual configuration (Build IDs, Catalog IDs, Term IDs) saved per year in `ctc_export_config`
- Master schedule uploaded as a tab-delimited file, stored in `ctc_master_schedule`
- Re-uploading the master schedule replaces all rows for that year (delete + re-insert)
- Generates 9 files: 3 export types × 3 schools (East HS, Highland HS, West HS)
- Export types: Pre-Schedule Constraints, Teacher Assignments, Post-Build
- "Download All 9 as ZIP" packages all files using JSZip
- Preview table highlights problem rows (missing room, missing course number, zero seats)
- Last-uploaded timestamp displayed prominently

### School IDs and teacher keys
- East HS: SchoolID `704`, TeacherID `11608`
- Highland HS: SchoolID `708`, TeacherID `11609`
- West HS: SchoolID `716`, TeacherID `11610`

### TermId pattern
- Base Term ID = year-long term (e.g., `3600`)
- Base + 1 = S1, Base + 2 = S2
- Bumps by 100 each year (3600 → 3700)

---

## Feature: School Rollover

### What it does
Tracks the annual EOY PowerSchool rollover process — both district-wide prep steps and
per-school steps. Third tab on the School Schedule Build Tracker page.

### Schools included
- **High Schools:** East HS, Highland HS, West HS
- **Middle Schools:** Northwest Middle, Hillside Middle, Glendale Middle, Clayton Middle, Bryant Middle
- **Other:** CTC, Salt Lake City Science Center
- Horizonte excluded (different rollover process)

### UX structure
- **Target date bar** — configurable rollover date with live countdown; saves to `rollover_config`
- **District-Wide Tasks card** — single checklist for tasks done once per year; inline check-off
  with who/when tracking. One task (`ro_d_clear_fields`) has an expandable sub-checklist of
  36 custom PS fields to clear (stored in `rollover_field_tasks`, add/removable)
- **School cards** (grouped High/Middle/Other) — show X/Y tasks complete + progress bar;
  click to drill into school detail view
- **School detail view** — per-school checklist with same check-off pattern
- **School switcher** — pill buttons at the top of the detail view let you jump between
  schools of the same type group without going back to the list

### Key behaviors
- Tasks support drag-and-drop reordering (HTML5) + ▲▼ buttons; order saved to DB
- Notes on tasks are **year-agnostic** (persist across years) — stored in `rollover_district_notes`
  and `rollover_school_notes`, NOT in the completion records
- Custom tasks can be added to either list (saved to `rollover_custom_tasks`)
- **Custom school tasks are group-scoped** — tasks added at a High School appear only for
  High Schools; Middle School tasks only for Middle Schools. Uses `school_group` column
  (`'high'`, `'middle'`, `'other'`). Built-in tasks (no `school_group`) apply to all.
- Any task (built-in or custom) can be removed; built-in tasks hidden via sort_order=-999
- School-specific built-in task for East HS, Highland HS, West HS only:
  `ro_s_ctc_enrollments` — "Copy Generic CTC Section enrollments to Real CTC sections"
- `getSchoolGroup(schoolName)` helper derives group from `ROLLOVER_SCHOOLS` constant

---

## Feature: My Tasks

### What it does
A personal per-user work queue with three priority lanes: Urgent, Medium, Low.
Each team member's list is completely independent — stored by `user_id`.

### UX structure
- Three color-coded lanes rendered in order: Urgent (red), Medium (amber), Low (green)
- Each lane: task list + add-task input (Enter key supported) + Add button
- Tasks can be checked off (strikethrough) or deleted (✕)
- No sharing — lists are entirely user-scoped

---

## Feature: Class Choice Processes

### What it does
A purely client-side file processor accessed via the "Class Choice Processes" tab on the
PowerScheduler page. Accepts a drag-and-drop (or click-to-browse) upload of the CTC master
schedule tab-delimited file, processes it, and generates a downloadable output file.

### Input file
Same tab-delimited master schedule file used by CTC Export, with headers:
`TeachLastName`, `Teacher ID`, `Course Number`, `Room`, `SECTION_NUMBER`, `EXPRESSION`,
`TermId`, `SCHOOLID`, `MaxCut`, `MAXENROLLMENT`, `EHS`, `HHS`, `WHS`

### Processing logic
- Reads columns: `Course Number`, `SECTION_NUMBER`, `EHS`, `HHS`, `WHS`
- Column matching is case/space/underscore-insensitive
- For each row, builds a `Shared` string mapping school IDs to seat counts:
  - EHS → 704, HHS → 708, WHS → 716
  - Schools with 0 seats are excluded from the string
  - Formatted as `"704-3, 708-2, 716-5"` with literal surrounding quotes
- No database interaction — entirely in-browser

### Output file
Downloaded as `class_choice_shared.txt`, tab-delimited, with headers:
`Course_number`, `Section_number`, `School_id`, `Shared`
- `School_id` is always hardcoded `749`
- Preview of first 5 rows shown before download

---

## Feature: CardToUTA

### What it does
A purely client-side CSV processor under "Other Modules" in the sidebar (`page-cardtouta`).
Accepts a drag-and-drop (or click-to-browse) upload of the daily card access CSV export,
transforms it into UTA activation format, and downloads the result. No data ever leaves
the browser — zero Supabase interaction.

### Input file
CSV with headers: `Campus`, `Student Id`, `User`, `Student Name`, `Grade`, `Uid`, `Timestamp`
- Column matching normalizes to lowercase with spaces stripped (`Student Id` → `studentid`)

### Processing logic
- **Col A (Reversed UID):** 2-char chunk reversal of Uid — e.g. `670A18E2` → `E2180A67`
- **Col B:** Hardcoded `Activate`
- **Col C:** Blank
- **Col D:** Hardcoded `20300630` (expiration date June 30 2030)
- **Col E:** Original Uid
- **Col F:** Student Id
- **Col G:** School number from `CTU_SCHOOL_MAP` lookup on Campus name

### School name → number map (`CTU_SCHOOL_MAP`)
```
Bryant Middle → 404, Clayton Middle → 408, East High → 704,
Glendale Middle → 412, Highland High → 708, Hillside Middle → 416,
Horizonte Instruction and Training Center → 750,
Innovations early College High → 748, Nibley Park → 224,
Northwest Middle → 440, Open Classroom → 240,
Salt Lake Center for Science Education → 300, West High → 716
```
Unknown campus names surface as an amber warning — they don't silently drop data.

### Output file
Downloaded as `SL School District_YYYYMMDD.csv` with today's date auto-filled.
No headers. Comma-delimited. Preview of first 5 rows shown before download.

---

## Feature: Password Reset Flow

### What it does
Self-service password reset accessible from the login screen. No admin action required
once configured. Uses Supabase Auth's built-in recovery email mechanism.

### UX flow
1. Login screen has a **"Forgot password?"** link below the Sign In button
2. Clicking it expands an inline email input + "Send Reset Link" button
3. `supabase.auth.resetPasswordForEmail(email, { redirectTo: window.location.origin + window.location.pathname })`
   sends the recovery email with the correct live URL as the redirect target
4. User clicks link in email → lands on a **reset screen** (separate `div#reset-screen`)
   instead of the login form
5. User enters and confirms new password → `supabase.auth.updateUser({ password })`
6. On success: user is signed out, reset screen hides, login screen shown after 2 seconds

### Key implementation details
- `isPasswordRecovery` flag is set synchronously via `window.location.hash.includes('type=recovery')`
  AND via `sb.auth.onAuthStateChange` for `PASSWORD_RECOVERY` event — prevents `getSession`
  from calling `showApp()` during a recovery redirect
- After successful reset, `sb.auth.signOut()` clears the recovery session before returning
  to the login screen
- Passwords must be ≥ 6 characters and match confirmation field

### Supabase configuration required
- **Authentication → URL Configuration → Site URL:** `https://blharmon24.github.io/slcsd-it-dashboard/dashboard.html`
- **Authentication → URL Configuration → Redirect URLs:** same URL above
- **Custom SMTP recommended** — Supabase built-in email caps at 2 reset emails/hour;
  configure a provider (Resend, SendGrid, Brevo, or district SMTP relay) under
  Project Settings → Authentication → SMTP Settings

---

## Database Schema (Supabase / PostgreSQL)

### `schools`
Master list of schools in the district.
- `id` (uuid), `name`, `school_type`, `terms` (default 4), `ctc_confirmation` (boolean),
  `graduation_plan` (boolean), `active` (boolean)
- School types: `elementary`, `middle`, `high`

### `terms`
Terms associated with schools.
- `id`, `label`, `school_id` (FK schools), `created_at`

### `grade_store_records`
One record per school per term/academic year for the grade storage process.
- `id`, `school_id` (FK schools), `school_name`, `school_type`, `term_label`,
  `academic_year`, `requested_by`, `requested_date`, `as_of_date`,
  `active_student_count`, `students_processed`, `grades_processed`,
  `ctc_confirmed` (boolean), `completed` (boolean), `created_by` (FK auth.users),
  `created_at`

### `checklist_completions`
Individual checklist task completions linked to a grade store record.
- `id`, `record_id` (FK grade_store_records), `task_key`, `completed` (boolean),
  `completed_at`, `completed_by` (FK auth.users), `completed_by_name`

### `schedule_build_records`
One record per school per academic year for the schedule build process.
- `id`, `school_name`, `school_type`, `academic_year`, `responsible_person`,
  `status` (text, default `not_started`), `ctc_push_confirmed` (boolean),
  `using_powerscheduler` (boolean), `created_at`, `updated_at`, `updated_by` (FK auth.users)
- Unique constraint on `(school_name, academic_year)`
- RLS enabled — authenticated users can read, insert, and update

### `sb_checklist_completions`
Checklist task completions for the schedule commit phase (when status = Complete).
- `id`, `record_id` (FK schedule_build_records, cascade delete), `task_key`,
  `completed` (boolean), `completed_at`, `completed_by` (FK auth.users)
- Unique constraint on `(record_id, task_key)`
- RLS enabled — authenticated users can read, insert, and update

### `ctc_export_config`
Annual configuration for CTC export generation, one row per academic year.
- `id`, `academic_year` (unique), `term_label`, `base_term_id`,
  `east_build_id`, `east_catalog_id`, `highland_build_id`, `highland_catalog_id`,
  `west_build_id`, `west_catalog_id`, `updated_at`, `updated_by` (FK auth.users)
- RLS enabled — authenticated users can read, insert, and update

### `ctc_master_schedule`
Uploaded CTC master schedule rows, one per section per year.
- `id`, `academic_year`, `teach_last_name`, `teacher_id`, `course_number`, `room`,
  `section_number`, `expression`, `term_id`, `school_id`, `max_cut`, `max_enrollment`,
  `ehs`, `hhs`, `whs`, `uploaded_at`, `uploaded_by` (FK auth.users)
- RLS enabled — authenticated users can read, insert, and delete

### `term_dates`
Term end dates per academic year, split by schedule type.
- `id`, `academic_year`, `term_label`, `schedule_type` (`traditional` or `horizonte`),
  `end_date` (date)
- Unique constraint on `(academic_year, term_label, schedule_type)`
- RLS enabled — authenticated users can read, insert, and delete

### `rollover_config`
Target rollover date per academic year.
- `id`, `academic_year` (unique), `target_date` (date), `updated_at`, `updated_by`

### `rollover_records`
One row per school per academic year for the rollover process.
- `id`, `school_name`, `school_type`, `academic_year`, `updated_by`, `created_at`

### `rollover_district_completions`
District-wide task completions per academic year.
- `id`, `task_key`, `academic_year`, `completed` (boolean), `completed_at`,
  `completed_by` (FK auth.users), `completed_by_name`
- Unique constraint on `(task_key, academic_year)`

### `rollover_school_completions`
Per-school task completions linked to a rollover record.
- `id`, `record_id` (FK rollover_records, cascade delete), `task_key`,
  `completed` (boolean), `completed_at`, `completed_by` (FK auth.users), `completed_by_name`

### `rollover_district_notes`
Year-agnostic notes for district tasks, keyed by task_key.
- `id`, `task_key` (unique), `notes`, `updated_at`, `updated_by` (FK auth.users)

### `rollover_school_notes`
Year-agnostic notes for school tasks, keyed by school + task.
- `id`, `school_name`, `task_key`, `notes`, `updated_at`, `updated_by` (FK auth.users)
- Unique constraint on `(school_name, task_key)`

### `rollover_task_order`
Custom sort order for district and school tasks.
- `id`, `task_type` (`district` or `school`), `task_key`, `sort_order` (int)
- sort_order = -999 means the task is hidden
- Unique constraint on `(task_type, task_key)`

### `rollover_custom_tasks`
User-added custom tasks for district or school checklists.
- `id`, `task_type` (`district` or `school`), `task_key`, `label`, `active` (boolean),
  `school_group` (text: `'high'`, `'middle'`, or `'other'` — null means applies to all),
  `created_at`

### `rollover_field_tasks`
The custom PS fields to clear during rollover (add/removable list).
- `id`, `label`, `sort_order` (int), `active` (boolean), `created_at`

### `rollover_field_completions`
Completion state per field per academic year.
- `id`, `field_task_id` (FK rollover_field_tasks), `academic_year`, `completed` (boolean),
  `completed_at`, `completed_by` (FK auth.users), `completed_by_name`
- Unique constraint on `(field_task_id, academic_year)`

### `work_queue_items`
Personal work queue tasks, one per user per item.
- `id` (uuid), `user_id` (FK auth.users, cascade delete), `label` (text),
  `priority` (text: `urgent` | `medium` | `low`), `completed` (boolean),
  `sort_order` (int), `created_at`
- RLS enabled — users can only read/write their own rows (`auth.uid() = user_id`)

---

## Important Rules
- **Do not restructure `dashboard.html`** into multiple files unless explicitly asked
- **Preserve all Supabase table names and column names exactly** — do not rename or alter schema unless asked
- **schools cascade** to grade_store_records and terms — be careful with school-level changes
- **grade_store_records cascade** to checklist_completions
- **schedule_build_records cascade** to sb_checklist_completions
- **rollover_records cascade** to rollover_school_completions
- **task_key** values in all checklist tables are used to track completion state —
  do not change existing task_key values
- **Rollover task notes must stay year-agnostic** — always read/write from `rollover_district_notes`
  and `rollover_school_notes`, never store notes inside the completion records
- **Do not add new libraries or dependencies** without asking first
- **The dashboard is publicly viewable** for progress tracking — do not add auth gates
  to the tracker/view portions without asking
- When adding new features, keep them within the single dashboard.html file
- When fixing bugs, make the smallest change possible — do not refactor unrelated code

## Coding Style
- Vanilla JavaScript (no React, Vue, or frameworks)
- All code stays in `dashboard.html`
- Use consistent Supabase client patterns already in the file
- Prefer `async/await` over `.then()` chains
- Code should be readable by a team — use clear comments for workflows and logic

## GitHub Workflow
- Repository: https://github.com/blharmon24/slcsd-it-dashboard
- Local git repo initialized at C:\ClaudeAI\IT-Dashboard, connected to remote via HTTPS
- GitHub credentials stored in Windows Credential Manager (no extra auth steps needed)
- Commit changes with clear, descriptive commit messages
- Always review changes before committing

---

## Collaboration Notes

These are patterns and preferences established during development — treat them as standing rules.

**Always bump the version on every commit.**
Update `<div class="sidebar-version">` in `dashboard.html` with every single commit — never skip
or batch it. Last digit increments for each change on the same date (e.g., `.1`, `.2`, `.3`).
The user relies on this to confirm the latest version is deployed.

**Tab merging pattern for related features.**
When adding a feature closely related to an existing page, default to adding it as a tab rather
than a new sidebar item. Established pattern:
1. Remove any secondary sidebar nav item
2. Add `.tab-bar` with `.tab-btn` buttons calling `switchXTab('name')`
3. Wrap each content section in `<div class="tab-content [active]" id="tab-name">`
4. Scope tab selectors to the parent page (`#page-id .tab-btn`) to avoid conflicts
5. Persist the active tab to localStorage if it has a meaningful default
User confirmed this pattern looks great; apply it by default for related features.

**Rollover task notes must persist across years.**
Notes on rollover tasks go in `rollover_district_notes` / `rollover_school_notes` — never inside
completion records. Users write standing process instructions in notes that apply every year.
