-- Create the support_tickets table to handle the Agent Queue Engine
CREATE TABLE public.support_tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'bot' CHECK (status IN ('bot', 'pending_human', 'active', 'resolved')),
  assigned_admin_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT support_tickets_pkey PRIMARY KEY (id)
);

-- Add updated_at trigger for support_tickets
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_support_tickets_modtime
BEFORE UPDATE ON public.support_tickets
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- Alter the existing direct_messages table to add a ticket_id
ALTER TABLE public.direct_messages
ADD COLUMN ticket_id uuid REFERENCES public.support_tickets(id) ON DELETE CASCADE;

-- Add RLS policies for support_tickets (Optional, depending on your current setup)
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own tickets" ON public.support_tickets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own tickets" ON public.support_tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tickets (e.g. status to pending_human)" ON public.support_tickets
  FOR UPDATE USING (auth.uid() = user_id);

-- Note: You should add policies for Admins to view all tickets and update them.
-- Assuming admins have a specific role or are checked via another table.
