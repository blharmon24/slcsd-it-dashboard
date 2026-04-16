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

## Tech Stack
- **Frontend:** Single HTML file (`dashboard.html`) — HTML, CSS, and JavaScript
- **Backend/Database:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth (user references auth.users)
- **Version Control:** GitHub — https://github.com/blharmon24/slcsd-it-dashboard
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

## Planned Features
- **School Rollover Procedures Dashboard** — track progress and monitor the workflow
  for rolling schools over to a new academic year in PowerSchool

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
  `created_at`, `updated_at`, `updated_by` (FK auth.users)
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

---

## Important Rules
- **Do not restructure `dashboard.html`** into multiple files unless explicitly asked
- **Preserve all Supabase table names and column names exactly** — do not rename or alter schema unless asked
- **schools cascade** to grade_store_records and terms — be careful with school-level changes
- **grade_store_records cascade** to checklist_completions
- **schedule_build_records cascade** to sb_checklist_completions
- **task_key** values in checklist_completions and sb_checklist_completions are used to
  track completion state — do not change existing task_key values
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
