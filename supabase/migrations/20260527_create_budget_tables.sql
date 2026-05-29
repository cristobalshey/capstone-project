-- ================================================================
--  Migration: Budget Management Tables
--  Paste into: Supabase Dashboard → SQL Editor → New Query
-- ================================================================

-- Budget Categories (one row per category the admin creates)
CREATE TABLE IF NOT EXISTS public.budget_categories (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  category    text        NOT NULL,
  "limit"     numeric(14,2) NOT NULL DEFAULT 0,
  spent       numeric(14,2) NOT NULL DEFAULT 0,
  created_at  timestamptz DEFAULT now()
);

-- Budget Transactions (one row per allocation or expense logged)
CREATE TABLE IF NOT EXISTS public.budget_transactions (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  category_id uuid        REFERENCES public.budget_categories(id) ON DELETE CASCADE,
  category    text        NOT NULL,
  type        text        NOT NULL,   -- 'Initial Allocation' | 'Expense Added'
  amount      numeric(14,2) NOT NULL,
  created_at  timestamptz DEFAULT now()
);

-- Enable Row Level Security (allow admin anon key to read/write)
ALTER TABLE public.budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_transactions ENABLE ROW LEVEL SECURITY;

-- Open policies (adjust to your auth setup as needed)
CREATE POLICY "Allow all for budget_categories" ON public.budget_categories FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for budget_transactions" ON public.budget_transactions FOR ALL USING (true) WITH CHECK (true);
