-- Migration: Create projects and user_projects tables, indexes, and triggers

-- Projects table
CREATE TABLE IF NOT EXISTS public.projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text NOT NULL,
  title text NOT NULL,
  description text NULL,
  waste_type text NULL,
  target_weight numeric(10,2) NULL,
  points integer NOT NULL DEFAULT 0,
  code text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  status text NULL DEFAULT 'active',
  created_by uuid NULL,
  created_at timestamptz NULL DEFAULT now(),
  questions jsonb NULL,
  CONSTRAINT projects_pkey PRIMARY KEY (id),
  CONSTRAINT projects_code_key UNIQUE (code),
  CONSTRAINT projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users (id),
  CONSTRAINT projects_type_check CHECK (
    type = ANY (ARRAY['Mission'::text, 'Quiz'::text, 'Game'::text])
  )
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_projects_type ON public.projects USING btree (type) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects USING btree (status) TABLESPACE pg_default;

-- User projects table
CREATE TABLE IF NOT EXISTS public.user_projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  project_id uuid NULL,
  status text NOT NULL DEFAULT 'pending',
  score numeric NULL,
  submission_date timestamptz NULL DEFAULT now(),
  submission_data jsonb NULL,
  type text NULL DEFAULT 'mission',
  points numeric NULL DEFAULT 0,
  code text NULL,
  description text NULL,
  approved_by uuid NULL,
  CONSTRAINT user_projects_pkey PRIMARY KEY (id),
  CONSTRAINT user_projects_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES profiles (id) ON DELETE SET NULL,
  CONSTRAINT user_projects_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
  CONSTRAINT user_projects_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE
) TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_user_projects_code ON public.user_projects USING btree (code) TABLESPACE pg_default;

-- Triggers (assume trigger functions already exist in earlier migrations)
DROP TRIGGER IF EXISTS tr_user_projects_award_points ON public.user_projects;
CREATE TRIGGER tr_user_projects_award_points
AFTER INSERT OR UPDATE ON public.user_projects
FOR EACH ROW
EXECUTE FUNCTION user_projects_award_points_on_completion();

DROP TRIGGER IF EXISTS trigger_record_user_activity ON public.user_projects;
CREATE TRIGGER trigger_record_user_activity
AFTER INSERT OR UPDATE ON public.user_projects
FOR EACH ROW
EXECUTE FUNCTION record_user_activity();

-- Notes:
-- 1) For manual-type entries store a human-friendly description in `description`,
--    for example: "Corrugated Cardboard · 1 kg". Application code should parse
--    `description` (or better: populate `submission_data` JSON with { type, kg })
--    to extract `waste_type` and `target_weight` when building waste distribution.
-- 2) For mission-type entries, `project_id` links to `projects` where
--    `waste_type` and `target_weight` are stored; when `status` becomes
--    'approved' or 'completed', these values should be used to aggregate waste totals.
-- 3) If you want the DB to automatically parse `description` into structured
--    columns, I can add a PL/pgSQL trigger function that extracts the values using
--    a regular expression and stores them (or inserts into an aggregate table).
