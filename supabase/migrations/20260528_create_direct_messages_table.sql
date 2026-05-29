-- Create direct messages table for collector-user conversations
CREATE TABLE IF NOT EXISTS public.direct_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id uuid NOT NULL,
    receiver_id uuid NOT NULL,
    sender_name text NOT NULL,
    receiver_name text NOT NULL,
    content text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    is_read boolean NOT NULL DEFAULT FALSE
);

ALTER TABLE public.direct_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated users to select their own conversations"
    ON public.direct_messages
    FOR SELECT
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Allow authenticated users to insert for themselves"
    ON public.direct_messages
    FOR INSERT
    WITH CHECK (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Allow authenticated users to update their own messages"
    ON public.direct_messages
    FOR UPDATE
    USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
