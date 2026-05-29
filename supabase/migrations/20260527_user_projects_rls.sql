-- ================================================================
--  Migration: Enable RLS on user_projects and allow collectors to read
--  Paste into: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

-- Enable Row Level Security on user_projects
ALTER TABLE public.user_projects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Allow users to see their own projects
CREATE POLICY "Users can read their own projects" ON public.user_projects
FOR SELECT
USING (auth.uid() = user_id);

-- Policy 2: Allow collectors to read all user_projects (to assign tasks)
CREATE POLICY "Collectors can read all user_projects" ON public.user_projects
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'collector'
  )
);

-- Policy 3: Allow admins to read all user_projects
CREATE POLICY "Admins can read all user_projects" ON public.user_projects
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);

-- Policy 4: Allow users to insert their own projects
CREATE POLICY "Users can insert their own projects" ON public.user_projects
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy 5: Allow users to update their own projects
CREATE POLICY "Users can update their own projects" ON public.user_projects
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy 6: Allow collectors to update project status/assignment
CREATE POLICY "Collectors can update project status" ON public.user_projects
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'collector'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'collector'
  )
);
