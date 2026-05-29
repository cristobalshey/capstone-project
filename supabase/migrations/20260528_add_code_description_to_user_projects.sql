-- Migration: Add code and description columns to user_projects
-- Paste into: Supabase Dashboard → SQL Editor → New Query

ALTER TABLE public.user_projects
  ADD COLUMN IF NOT EXISTS code text;

ALTER TABLE public.user_projects
  ADD COLUMN IF NOT EXISTS description text;

-- Optional index for lookups by code
CREATE INDEX IF NOT EXISTS idx_user_projects_code ON public.user_projects USING btree (code);
