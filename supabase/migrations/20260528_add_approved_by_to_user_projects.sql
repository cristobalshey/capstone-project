-- Migration: Add approved_by to user_projects so approver id is stored

ALTER TABLE public.user_projects
ADD COLUMN IF NOT EXISTS approved_by uuid NULL;

ALTER TABLE public.user_projects
ADD CONSTRAINT user_projects_approved_by_fkey
FOREIGN KEY (approved_by) REFERENCES auth.users (id) ON DELETE SET NULL;
