-- ================================================================
--  Migration: Award profile points when user_projects becomes completed/approved
--  Paste into: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

-- Updated trigger function: award points when a row is inserted/updated
-- Also handle cases where points are updated after status is already completed/approved
DO $$
BEGIN
  -- Create or replace function to handle awarding
  CREATE OR REPLACE FUNCTION public.user_projects_award_points_on_completion()
  RETURNS trigger LANGUAGE plpgsql AS $$
  DECLARE
    delta_points bigint := 0;
  BEGIN
    IF NEW.user_id IS NULL THEN
      RETURN NEW;
    END IF;

    -- Handle INSERT: if inserted already completed/approved, award points
    IF TG_OP = 'INSERT' THEN
      IF NEW.status IN ('completed', 'approved') THEN
        UPDATE public.profiles
        SET points = COALESCE(points, 0) + ROUND(COALESCE(NEW.points, 0))::bigint
        WHERE id = NEW.user_id;
      END IF;
      RETURN NEW;
    END IF;

    -- Handle UPDATE
    IF TG_OP = 'UPDATE' THEN
      -- Case A: status transitioned into completed/approved
      IF COALESCE(OLD.status, '') NOT IN ('completed', 'approved')
         AND NEW.status IN ('completed', 'approved') THEN
        UPDATE public.profiles
        SET points = COALESCE(points, 0) + ROUND(COALESCE(NEW.points, 0))::bigint
        WHERE id = NEW.user_id;
      END IF;

      -- Case B: status already completed/approved but points increased later
      IF OLD.status IN ('completed', 'approved') AND NEW.status IN ('completed', 'approved') THEN
        delta_points := ROUND(COALESCE(NEW.points, 0) - COALESCE(OLD.points, 0))::bigint;
        IF delta_points > 0 THEN
          UPDATE public.profiles
          SET points = COALESCE(points, 0) + delta_points
          WHERE id = NEW.user_id;
        END IF;
      END IF;

      RETURN NEW;
    END IF;

    RETURN NEW;
  END;
  $$;

  -- Ensure trigger exists (replace existing trigger)
  IF EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public'
      AND c.relname = 'user_projects'
      AND t.tgname = 'trigger_user_projects_award_points'
  ) THEN
    PERFORM pg_trigger_depth('trigger_user_projects_award_points');
    DROP TRIGGER IF EXISTS trigger_user_projects_award_points ON public.user_projects;
  END IF;

  CREATE TRIGGER trigger_user_projects_award_points
  AFTER INSERT OR UPDATE ON public.user_projects
  FOR EACH ROW
  EXECUTE FUNCTION public.user_projects_award_points_on_completion();
END $$;

