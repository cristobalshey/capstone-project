-- Create enum type for project categories
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'project_type') THEN
    CREATE TYPE project_type AS ENUM ('mission', 'quiz', 'manual', 'mini_game');
  END IF;
END $$;

-- Ensure the column exists and uses the enum
ALTER TABLE public.user_projects
  ADD COLUMN IF NOT EXISTS type project_type NOT NULL DEFAULT 'mission';

-- If the column already existed as text, convert it
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='user_projects' AND column_name='type' AND data_type='text') THEN
    ALTER TABLE public.user_projects
      ALTER COLUMN type TYPE project_type USING type::project_type;
  END IF;
END $$;

-- Set default and not null constraint (already set in ADD COLUMN)
ALTER TABLE public.user_projects ALTER COLUMN type SET NOT NULL;
