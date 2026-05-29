-- Migration: Allow admin and profile owners to manage profiles with RLS

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin or owner can manage profiles" ON public.profiles
FOR ALL
USING (
  auth.uid() = id
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
)
WITH CHECK (
  auth.uid() = id
  OR EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  )
);
