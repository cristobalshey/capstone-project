-- ================================================================
-- Migration: Ensure projects table (with waste fields) and allow authenticated SELECT
-- Paste into: Supabase Dashboard → SQL Editor → New Query
-- Idempotent: safe to run multiple times
-- ================================================================

-- Create table if it does not exist (matches expected schema)
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

-- Ensure columns exist (for backwards compatibility)
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS waste_type text NULL,
  ADD COLUMN IF NOT EXISTS target_weight numeric(10,2) NULL;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_projects_type ON public.projects USING btree (type);
CREATE INDEX IF NOT EXISTS idx_projects_status ON public.projects USING btree (status);

-- Enable Row Level Security and allow authenticated users to read projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can read projects" ON public.projects;
CREATE POLICY "Authenticated users can read projects" ON public.projects
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Optional: allow admins to manage projects (if you use profile_has_role helper)
-- DROP POLICY IF EXISTS "Admins can manage projects" ON public.projects;
-- CREATE POLICY "Admins can manage projects" ON public.projects
--   FOR ALL
--   USING (public.profile_has_role(auth.uid(), 'admin') OR current_user = 'postgres')
--   WITH CHECK (public.profile_has_role(auth.uid(), 'admin') OR current_user = 'postgres');
