-- Migration: Create notification_reads table to track per-user read receipts

CREATE TABLE IF NOT EXISTS public.notification_reads (
  notification_id uuid not null,
  user_id uuid not null,
  read_at timestamptz not null default timezone('utc'::text, now()),
  constraint notification_reads_pkey primary key (notification_id, user_id),
  constraint notification_reads_notification_fkey foreign key (notification_id) references public.notifications (id) on delete cascade,
  constraint notification_reads_user_fkey foreign key (user_id) references public.profiles (id) on delete cascade
);

ALTER TABLE public.notification_reads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their notification reads" ON public.notification_reads;
CREATE POLICY "Users can manage their notification reads" ON public.notification_reads
FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
