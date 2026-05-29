-- ================================================================
--  Migration: Create user_activity table for tracking activity
--  Purpose: Track daily user activity for streak calculations
--  Paste into: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

CREATE TABLE IF NOT EXISTS public.user_activity (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date date NOT NULL,
  activity_type text NOT NULL DEFAULT 'task',
  task_count integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_activity_pkey PRIMARY KEY (id),
  CONSTRAINT user_activity_unique_daily UNIQUE (user_id, activity_date)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON public.user_activity USING btree (user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_date ON public.user_activity USING btree (activity_date);

-- Enable Row Level Security
ALTER TABLE public.user_activity ENABLE ROW LEVEL SECURITY;

-- Create RLS policies - users can only see their own activity
CREATE POLICY "Users can view their own activity" ON public.user_activity 
  FOR SELECT 
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activity" ON public.user_activity 
  FOR INSERT 
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activity" ON public.user_activity 
  FOR UPDATE 
  USING (auth.uid() = user_id) 
  WITH CHECK (auth.uid() = user_id);

-- Function to automatically record activity when a user_project is created or updated
CREATE OR REPLACE FUNCTION public.record_user_activity()
RETURNS TRIGGER AS $$
BEGIN
  -- Only record for approved/completed status
  IF NEW.status IN ('approved', 'completed') THEN
    INSERT INTO public.user_activity (user_id, activity_date, task_count)
    VALUES (NEW.user_id, CURRENT_DATE, 1)
    ON CONFLICT (user_id, activity_date)
    DO UPDATE SET
      task_count = public.user_activity.task_count + EXCLUDED.task_count,
      updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically record activity
DROP TRIGGER IF EXISTS trigger_record_user_activity ON public.user_projects;
CREATE TRIGGER trigger_record_user_activity
  AFTER INSERT OR UPDATE ON public.user_projects
  FOR EACH ROW
  EXECUTE FUNCTION public.record_user_activity();
