-- Create the support_tickets table to power the Agent Queue Engine
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'bot' CHECK (status IN ('bot', 'pending_human', 'active', 'resolved')),
  assigned_admin_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT support_tickets_pkey PRIMARY KEY (id)
);

-- Update support_tickets modification timestamp automatically
CREATE OR REPLACE FUNCTION update_support_tickets_modtime()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_support_tickets_modtime ON public.support_tickets;
CREATE TRIGGER update_support_tickets_modtime
BEFORE UPDATE ON public.support_tickets
FOR EACH ROW
EXECUTE FUNCTION update_support_tickets_modtime();

-- Add ticket_id to direct_messages for support conversation routing
ALTER TABLE public.direct_messages
  ADD COLUMN IF NOT EXISTS ticket_id uuid REFERENCES public.support_tickets(id) ON DELETE CASCADE;

-- Enable RLS for support tickets and allow users to manage their own tickets
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own tickets" ON public.support_tickets;
CREATE POLICY "Users can view their own tickets" ON public.support_tickets
  FOR SELECT
  USING (auth.uid() = user_id OR EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'moderator')
  ));

DROP POLICY IF EXISTS "Users can create their own tickets" ON public.support_tickets;
CREATE POLICY "Users can create their own tickets" ON public.support_tickets
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'moderator')
  ));

DROP POLICY IF EXISTS "Users can update their own tickets (e.g. status to pending_human)" ON public.support_tickets;
CREATE POLICY "Users can update their own tickets (e.g. status to pending_human)" ON public.support_tickets
  FOR UPDATE
  USING (auth.uid() = user_id OR EXISTS (
      SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'moderator')
  ));
