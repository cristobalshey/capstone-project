-- Migration: Allow collectors and DB role to update profiles (so collectors/triggers can add points)

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: allow collectors to update profiles
DROP POLICY IF EXISTS "Collectors can update profiles" ON public.profiles;
CREATE POLICY "Collectors can update profiles" ON public.profiles
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'collector'
  )
  OR current_user = 'postgres'
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'collector'
  )
  OR current_user = 'postgres'
);

-- Optional: you may want to ensure admins and owners still have full manage rights
DROP POLICY IF EXISTS "Admin or owner can manage profiles" ON public.profiles;
CREATE POLICY "Admin or owner can manage profiles" ON public.profiles
FOR ALL
USING (
  auth.uid() = id
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
  OR current_user = 'postgres'
)
WITH CHECK (
  auth.uid() = id
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
  OR current_user = 'postgres'
);
