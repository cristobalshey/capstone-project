-- ================================================================
--  Migration: Add allowed status values for user_projects
--  Paste into: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.user_projects'::regclass
      AND conname = 'user_projects_status_check'
  ) THEN
    ALTER TABLE public.user_projects
      ADD CONSTRAINT user_projects_status_check
      CHECK (status IN (
        'pending',
        'accepted',
        'otw',
        'here',
        'approved',
        'completed',
        'rejected'
      ));
  END IF;
END $$;
