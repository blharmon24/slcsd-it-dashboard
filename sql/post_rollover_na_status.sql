-- Post-Rollover Tasks: add tri-state cell support (done / N/A / blank)
-- Run once in the Supabase SQL editor.
--
-- Adds a `status` column to post_rollover_completions:
--   'done' = checked complete, 'na' = not applicable for that school, NULL = blank
-- `completed` stays TRUE for BOTH 'done' and 'na' so the column done-count treats
-- an N/A the same as a check (N/A schools count as resolved). See CLAUDE.md.

alter table post_rollover_completions
  add column if not exists status text;

-- Backfill existing check-offs: every completed row is a 'done'
update post_rollover_completions
  set status = 'done'
  where completed = true and status is null;
