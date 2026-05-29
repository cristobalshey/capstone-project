-- 1. Create a storage bucket for announcement images (optional, but good to have)
insert into storage.buckets (id, name, public) 
values ('announcements', 'announcements', true) 
on conflict (id) do nothing;

create policy "Anyone can read announcement images"
  on storage.objects for select
  using ( bucket_id = 'announcements' );

create policy "Admins can insert announcement images"
  on storage.objects for insert
  with check (
    bucket_id = 'announcements' 
    and auth.role() = 'authenticated'
    and exists (
      select 1 from public.profiles 
      where profiles.id = auth.uid() and profiles.role = 'admin'
    )
  );

-- 2. Create the community_posts table
CREATE TABLE IF NOT EXISTS public.community_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id),
    full_name TEXT NOT NULL,
    content TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

-- 3. Policies for community_posts
-- Everyone can read posts
CREATE POLICY "Everyone can view community posts" ON public.community_posts
    FOR SELECT USING (true);

-- Admins can insert posts
CREATE POLICY "Admins can insert community posts" ON public.community_posts
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Admins can delete posts
CREATE POLICY "Admins can delete community posts" ON public.community_posts
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
