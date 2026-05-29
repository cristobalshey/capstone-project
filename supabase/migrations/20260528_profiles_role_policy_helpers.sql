-- Migration: Add helper for profile role checks and remove subselect recursion in RLS policies

CREATE OR REPLACE FUNCTION public.profile_has_role(user_id uuid, role text)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS(
    SELECT 1
    FROM public.profiles
    WHERE id = $1 AND role = $2
  );
$$;

-- Profiles policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin or owner can manage profiles" ON public.profiles;
CREATE POLICY "Admin or owner can manage profiles" ON public.profiles
FOR ALL
USING (
  auth.uid() = id
  OR public.profile_has_role(auth.uid(), 'admin')
  OR current_user = 'postgres'
)
WITH CHECK (
  auth.uid() = id
  OR public.profile_has_role(auth.uid(), 'admin')
  OR current_user = 'postgres'
);

DROP POLICY IF EXISTS "Collectors can update profiles" ON public.profiles;
CREATE POLICY "Collectors can update profiles" ON public.profiles
FOR UPDATE
USING (
  public.profile_has_role(auth.uid(), 'collector')
  OR current_user = 'postgres'
)
WITH CHECK (
  public.profile_has_role(auth.uid(), 'collector')
  OR current_user = 'postgres'
);

-- Notifications policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Collectors and admins can insert notifications" ON public.notifications;
CREATE POLICY "Collectors and admins can insert notifications" ON public.notifications
FOR INSERT
WITH CHECK (
  public.profile_has_role(auth.uid(), 'collector')
  OR public.profile_has_role(auth.uid(), 'admin')
);

DROP POLICY IF EXISTS "Admins can read all notifications" ON public.notifications;
CREATE POLICY "Admins can read all notifications" ON public.notifications
FOR SELECT
USING (
  public.profile_has_role(auth.uid(), 'admin')
);

-- User projects policies for collectors/admins
ALTER TABLE public.user_projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Collectors can read all user_projects" ON public.user_projects;
CREATE POLICY "Collectors can read all user_projects" ON public.user_projects
FOR SELECT
USING (
  public.profile_has_role(auth.uid(), 'collector')
  OR public.profile_has_role(auth.uid(), 'admin')
);

DROP POLICY IF EXISTS "Admins can read all user_projects" ON public.user_projects;
CREATE POLICY "Admins can read all user_projects" ON public.user_projects
FOR SELECT
USING (
  public.profile_has_role(auth.uid(), 'admin')
);

DROP POLICY IF EXISTS "Collectors can update project status" ON public.user_projects;
CREATE POLICY "Collectors can update project status" ON public.user_projects
FOR UPDATE
USING (
  public.profile_has_role(auth.uid(), 'collector')
  OR public.profile_has_role(auth.uid(), 'admin')
)
WITH CHECK (
  public.profile_has_role(auth.uid(), 'collector')
  OR public.profile_has_role(auth.uid(), 'admin')
);
