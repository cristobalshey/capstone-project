-- ================================================================
--  CREATE COLLECTOR ACCOUNT
--  Paste this into: Supabase Dashboard → SQL Editor → New Query
--  ✏️  Change the 4 values marked below, then click Run
-- ================================================================

DO $$
DECLARE
  new_user_id uuid := gen_random_uuid();
BEGIN

  -- ── STEP 1: Create the login account in Supabase Auth ──────────
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    new_user_id,
    'authenticated',
    'authenticated',
    'collector1@ecotrack.com',              -- ← CHANGE: login email
    crypt('collector123', gen_salt('bf')), -- ← CHANGE: login password
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{}',
    now(),
    now(),
    '', '', '', ''
  );

  -- ── STEP 2: Create the profile row ─────────────────────────────
  -- Columns follow your exact schema (no email, no pin_code column)
  -- status = 'verified' is required for active staff
  --   (allowed values: new | pending | verified | rejected | banned)
  INSERT INTO public.profiles (
    id,
    full_name,
    role,
    assigned_area,
    pass_code,
    status,
    deleted,
    created_at
  ) VALUES (
    new_user_id,
    'Juan Dela Cruz',       -- ← CHANGE: full name shown in admin hub
    'collector',            -- ← CHANGE: 'collector' or 'moderator'
    'Purok 1, Purok 2',     -- ← CHANGE: assigned area / zone
    'collector123',         -- ← CHANGE: store the staff pass_code value here
    'verified',             -- DO NOT CHANGE (makes account active)
    false,
    now()
  );

  RAISE NOTICE 'Done! Account created with ID: %', new_user_id;

END $$;
