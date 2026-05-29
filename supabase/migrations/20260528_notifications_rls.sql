-- Migration: Enable RLS on notifications and allow collectors to send them
-- Paste into: Supabase Dashboard → SQL Editor → New Query

-- Enable Row Level Security on notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policy: Allow users to read notifications addressed to them or global notifications
CREATE POLICY "Users can read their own or global notifications" ON public.notifications
FOR SELECT
USING (
  user_id IS NULL OR user_id = auth.uid()
);

-- Policy: Allow collectors and admins to insert notifications for users and broadcasts
CREATE POLICY "Collectors and admins can insert notifications" ON public.notifications
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role IN ('collector', 'admin')
  )
);

-- Optional policy: Allow users to insert their own notifications if needed
CREATE POLICY "Users can insert their own notifications" ON public.notifications
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Optional policy: Allow users to read their own notifications via SELECT, already covered above

-- Optional policy: Allow admins to read all notifications
CREATE POLICY "Admins can read all notifications" ON public.notifications
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);
