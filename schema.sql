-- =============================================================================
-- GoldVault — Relational Database Schema (Supabase / PostgreSQL)
-- Run this script in the SQL Editor of your Supabase project.
-- =============================================================================

-- 1. SPACES (spaces)
CREATE TABLE IF NOT EXISTS public.spaces (
  user_id     uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  id          text        NOT NULL,
  name        text        NOT NULL,
  emoji       text        NOT NULL DEFAULT '💰',
  categories  jsonb       NOT NULL DEFAULT '[]'::jsonb,
  accounts    jsonb       NOT NULL DEFAULT '[]'::jsonb,
  sources     jsonb       NOT NULL DEFAULT '[]'::jsonb,
  frequents   jsonb       NOT NULL DEFAULT '[]'::jsonb,
  budgets     jsonb       NOT NULL DEFAULT '{}'::jsonb,
  rec_skipped jsonb       NOT NULL DEFAULT '[]'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);

-- 2. SAVINGS GOALS (goals)
CREATE TABLE IF NOT EXISTS public.goals (
  user_id     uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  id          text        NOT NULL,
  space_id    text        NOT NULL,
  name        text        NOT NULL,
  target      bigint      NOT NULL DEFAULT 0,
  achieved_at timestamptz NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id),
  CONSTRAINT goals_space_fk FOREIGN KEY (user_id, space_id)
    REFERENCES public.spaces(user_id, id) ON DELETE CASCADE
);

-- 3. MOVEMENTS (movements)
CREATE TABLE IF NOT EXISTS public.movements (
  user_id       uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  id            text        NOT NULL,
  space_id      text        NOT NULL,
  date          text        NOT NULL, -- ISO format YYYY-MM-DD
  type          text        NOT NULL CHECK (type IN ('expense', 'saving', 'income')),
  desc_txt      text        NULL,     -- Legacy fallback column; primary column is "desc"
  "desc"        text        NULL,
  amount        bigint      NOT NULL DEFAULT 0,
  category      text        NULL,
  account       text        NULL,
  status        text        NOT NULL DEFAULT 'paid' CHECK (status IN ('paid', 'pending', 'cancelled')),
  goal_id       text        NULL,
  source        text        NULL,
  orig_currency text        NULL,
  orig_amount   numeric     NULL,
  fx_rate       numeric     NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id),
  CONSTRAINT movements_space_fk FOREIGN KEY (user_id, space_id)
    REFERENCES public.spaces(user_id, id) ON DELETE CASCADE
);

-- Ensure the quoted "desc" column exists on existing deployments
ALTER TABLE public.movements ADD COLUMN IF NOT EXISTS "desc" text NULL;

-- 4. USER PROFILES (profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
  user_id      uuid        PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text        NULL,
  avatar       text        NULL,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- 5. REPORTS AND FEEDBACK (reports)
CREATE TABLE IF NOT EXISTS public.reports (
  id          bigserial   PRIMARY KEY,
  user_id     uuid        NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  email       text        NULL,
  kind        text        NOT NULL DEFAULT 'bug' CHECK (kind IN ('bug', 'idea')),
  message     text        NOT NULL,
  app_version text        NULL,
  user_agent  text        NULL,
  context     jsonb       NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- INDEXES FOR SCALABILITY AND FAST QUERIES
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_movements_user_space_date ON public.movements (user_id, space_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_movements_user_goal       ON public.movements (user_id, goal_id) WHERE goal_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_goals_user_space          ON public.goals     (user_id, space_id);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) — Users can only read and mutate their own records
-- =============================================================================
ALTER TABLE public.spaces    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports   ENABLE ROW LEVEL SECURITY;

-- Policies for spaces
DROP POLICY IF EXISTS "spaces_owner_all" ON public.spaces;
CREATE POLICY "spaces_owner_all" ON public.spaces
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for goals
DROP POLICY IF EXISTS "goals_owner_all" ON public.goals;
CREATE POLICY "goals_owner_all" ON public.goals
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for movements
DROP POLICY IF EXISTS "movements_owner_all" ON public.movements;
CREATE POLICY "movements_owner_all" ON public.movements
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for profiles
DROP POLICY IF EXISTS "profiles_owner_all" ON public.profiles;
CREATE POLICY "profiles_owner_all" ON public.profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policies for reports (any anonymous or authenticated user may submit a report)
DROP POLICY IF EXISTS "reports_insert_any" ON public.reports;
CREATE POLICY "reports_insert_any" ON public.reports
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "reports_select_own" ON public.reports;
CREATE POLICY "reports_select_own" ON public.reports
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- 6. PER-USER API KEYS FOR REST API & MCP AGENTS (api_keys)
-- Only the SHA-256 hex digest (key_hash) and non-secret prefix (key_prefix) are stored.
CREATE TABLE IF NOT EXISTS public.api_keys (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  name         text        NOT NULL,
  key_prefix   text        NOT NULL,
  key_hash     text        NOT NULL UNIQUE,
  scopes       text[]      NOT NULL DEFAULT ARRAY['read', 'write']::text[],
  expires_at   timestamptz NULL,
  revoked_at   timestamptz NULL,
  last_used_at timestamptz NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_api_keys_user_id  ON public.api_keys (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_api_keys_key_hash ON public.api_keys (key_hash);

ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "api_keys_owner_all" ON public.api_keys;
CREATE POLICY "api_keys_owner_all" ON public.api_keys
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =============================================================================
-- 7. CREDIT CARDS & PAYMENT METHOD + DOLARAPP -> MORSE / ARQ MIGRATION
-- =============================================================================
ALTER TABLE public.spaces
  ADD COLUMN IF NOT EXISTS credit_cards jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.movements
  ADD COLUMN IF NOT EXISTS payment_method text NOT NULL DEFAULT 'account';

-- Idempotent migration: normalize Dollar App / DolarApp / MORSE / Morse Mamá -> Morse and ensure ARQ exists
UPDATE public.movements
SET account = 'Morse'
WHERE account ~* '(dolar\s*app|dollar\s*app|morse)';

UPDATE public.movements
SET auto_bank = 'Morse'
WHERE auto_bank ~* '(dolar\s*app|dollar\s*app|morse)';

UPDATE public.spaces s
SET accounts = (
  SELECT jsonb_agg(DISTINCT elem)
  FROM (
    SELECT val AS elem
    FROM jsonb_array_elements_text(s.accounts) AS val
    WHERE val !~* '(dolar\s*app|dollar\s*app|morse)'
    UNION
    SELECT 'Morse'
    UNION
    SELECT 'ARQ'
  ) t
);
