-- ================================================================
--  Migration: Create projects table and link user_projects.project_id
--  Paste into: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

CREATE TABLE IF NOT EXISTS public.projects (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text NOT NULL,
  title text NOT NULL,
  description text NULL,
  waste_type text NULL,
  target_weight numeric(10, 2) NULL,
  points integer NOT NULL DEFAULT 0,
  code text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  status text NULL DEFAULT 'active'::text,
  created_by uuid NULL,
  created_at timestamptz NULL DEFAULT now(),
  questions jsonb NULL,
  CONSTRAINT projects_pkey PRIMARY KEY (id),
  CONSTRAINT projects_code_key UNIQUE (code),
  CONSTRAINT projects_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users (id),
  CONSTRAINT projects_type_check CHECK (
    type = ANY (ARRAY['Mission'::text, 'Quiz'::text, 'Game'::text])
  )
);

CREATE INDEX IF NOT EXISTS idx_projects_type ON public.projects USING btree (type);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects USING btree (status);

-- Ensure user_projects has a project_id column and foreign key
ALTER TABLE public.user_projects
  ADD COLUMN IF NOT EXISTS project_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'user_projects'
      AND tc.constraint_type = 'FOREIGN KEY'
      AND kcu.column_name = 'project_id'
  ) THEN
    ALTER TABLE public.user_projects
      ADD CONSTRAINT user_projects_project_id_fkey FOREIGN KEY (project_id)
      REFERENCES public.projects(id);
  END IF;
END $$;
