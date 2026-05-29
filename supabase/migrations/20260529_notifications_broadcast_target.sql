-- Migration: Create/extend notifications table and allow staff/all broadcasts for collectors

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid not null default gen_random_uuid(),
  user_id uuid null,
  title text not null,
  description text not null,
  type text not null,
  created_at timestamp with time zone not null default timezone('utc'::text, now()),
  broadcast_target text null,
  constraint notifications_pkey primary key (id),
  constraint notifications_user_id_fkey foreign key (user_id) references public.profiles (id) on delete cascade
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS broadcast_target text;

DROP POLICY IF EXISTS "Users can read their own or global notifications" ON public.notifications;
DROP POLICY IF EXISTS "Admins can read all notifications" ON public.notifications;

CREATE POLICY "Users can read notifications addressed to them, all broadcasts, or staff broadcasts" ON public.notifications
FOR SELECT
USING (
  user_id = auth.uid()
  OR (
    user_id IS NULL
    AND (
      broadcast_target = 'all'
      OR (
        broadcast_target = 'staff'
        AND EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.role IN ('collector', 'admin', 'moderator')
        )
      )
    )
  )
);

CREATE POLICY "Admins can read all notifications" ON public.notifications
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);
