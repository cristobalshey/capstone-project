-- Migration: Parse manual description into structured submission_data JSONB
-- This function attempts to parse descriptions like "Corrugated Cardboard · 1 kg"
-- into { type: 'Corrugated Cardboard', kg: 1.0 } and store it in user_projects.submission_data

CREATE OR REPLACE FUNCTION public.parse_manual_description()
RETURNS trigger AS $$
DECLARE
  raw text := coalesce(NEW.description, '');
  matches text[];
  mat text;
  num text;
  kg numeric;
  parsed jsonb;
BEGIN
  -- Nothing to do if description is empty
  IF raw IS NULL OR length(trim(raw)) = 0 THEN
    RETURN NEW;
  END IF;

  -- If description is already JSON with expected keys, preserve it
  BEGIN
    parsed := raw::jsonb;
    IF (parsed ? 'type') AND (parsed ? 'kg') THEN
      NEW.submission_data := parsed;
      RETURN NEW;
    END IF;
  EXCEPTION WHEN others THEN
    -- not JSON, continue to regex parsing
  END;

  -- Try match patterns like: "Name · 1 kg" or "Name - 1 kg" (with optional unit)
  matches := regexp_matches(raw, '^(.*?)\s*[·\-–:]\s*(\d+[\.,]?\d*)\s*(kg|kgs?)?\s*$', 'i');

  IF array_length(matches, 1) IS NOT NULL THEN
    mat := trim(matches[1]);
    num := matches[2];
    num := replace(num, ',', '.');
    BEGIN
      kg := num::numeric;
    EXCEPTION WHEN others THEN
      kg := NULL;
    END;
    NEW.submission_data := jsonb_build_object('type', mat, 'kg', kg);
    RETURN NEW;
  END IF;

  -- Fallback pattern: trailing number, e.g. "Cardboard 1 kg" or "Cardboard, 1"
  matches := regexp_matches(raw, '^(.*?\D)\s*[,\s]+(\d+[\.,]?\d*)\s*(kg|kgs?)?\s*$', 'i');
  IF array_length(matches, 1) IS NOT NULL THEN
    mat := trim(matches[1]);
    num := matches[2];
    num := replace(num, ',', '.');
    BEGIN
      kg := num::numeric;
    EXCEPTION WHEN others THEN
      kg := NULL;
    END;
    NEW.submission_data := jsonb_build_object('type', mat, 'kg', kg);
    RETURN NEW;
  END IF;

  -- If we couldn't parse, save the raw text under a structured field for later processing
  NEW.submission_data := jsonb_build_object('raw_description', raw);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to run BEFORE INSERT OR UPDATE so submission_data is populated
DROP TRIGGER IF EXISTS trg_parse_manual_description ON public.user_projects;
CREATE TRIGGER trg_parse_manual_description
BEFORE INSERT OR UPDATE ON public.user_projects
FOR EACH ROW
WHEN (NEW.type = 'manual' OR NEW.project_id IS NULL)
EXECUTE FUNCTION public.parse_manual_description();

-- Note: this only writes structured data into user_projects.submission_data. The
-- application code should prefer `submission_data->>'type'` and `submission_data->>'kg'`
-- when present. If you want the DB to additionally aggregate into an analytics table,
-- we can add that in a separate migration.
