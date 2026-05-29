-- ============================================================
-- Migration: Add assigned_area column to profiles table
-- Date: 2026-05-27
-- Purpose: Store the assigned barangay/area for moderators and
--          waste collectors. Residents and admins will simply
--          have NULL in this column — no data is lost or broken.
-- ============================================================

-- Add column only if it doesn't already exist (safe to re-run)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS assigned_area TEXT DEFAULT NULL;

-- Optional: add a comment to document intent
COMMENT ON COLUMN public.profiles.assigned_area IS
  'Barangay/zone area assigned to moderators and waste collectors. NULL for residents and admins.';
