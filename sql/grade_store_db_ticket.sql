-- Storing Grades: helpdesk ticket # for the "send report cards to DB team" task
-- Run once in the Supabase SQL editor.
--
-- Adds a `db_ticket_number` column to grade_store_records so each school/term
-- can record the internal helpdesk ticket created for the Database team.
-- Table-level grants/RLS already cover new columns; no extra GRANT needed.

alter table grade_store_records
  add column if not exists db_ticket_number text;
