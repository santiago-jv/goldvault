-- =============================================================================
-- VaultARQ — Esquema Relacional Escalable (Supabase / PostgreSQL)
-- Ejecuta este script completo en el SQL Editor de tu proyecto de Supabase.
-- =============================================================================

-- 1. ESPACIOS (spaces)
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

-- 2. METAS DE AHORRO (goals)
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

-- 3. MOVIMIENTOS (movements)
CREATE TABLE IF NOT EXISTS public.movements (
  user_id       uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  id            text        NOT NULL,
  space_id      text        NOT NULL,
  date          text        NOT NULL, -- Formato ISO YYYY-MM-DD
  type          text        NOT NULL CHECK (type IN ('expense', 'saving', 'income')),
  desc_txt      text        NULL,     -- Nota: mapeado a/desde 'desc' si se requiere, más columna "desc" directa:
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

-- Asegurar que la columna "desc" exista si la tabla ya había sido creada sin ella
ALTER TABLE public.movements ADD COLUMN IF NOT EXISTS "desc" text NULL;

-- 4. PERFILES DE USUARIO (profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
  user_id      uuid        PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text        NULL,
  avatar       text        NULL,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- 5. REPORTES Y FEEDBACK (reports)
CREATE TABLE IF NOT EXISTS public.reports (
  id          bigserial   PRIMARY KEY,
  user_id     uuid        NULL REFERENCES auth.users(id) ON DELETE SET NULL,
  email       text        NULL,
  kind        text        NOT NULL DEFAULT 'bug' CHECK (kind IN ('bug', 'idea')),
  message     text        NOT NULL,
  app_version text        NULL,
  user_agent  text        NULL,
  context     jsonb        NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- =============================================================================
-- ÍNDICES PARA ESCALABILIDAD Y CONSULTAS RÁPIDAS
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_movements_user_space_date ON public.movements (user_id, space_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_movements_user_goal       ON public.movements (user_id, goal_id) WHERE goal_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_goals_user_space          ON public.goals     (user_id, space_id);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) — Cada usuario solo ve y modifica sus propios datos
-- =============================================================================
ALTER TABLE public.spaces    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports   ENABLE ROW LEVEL SECURITY;

-- Políticas para spaces
DROP POLICY IF EXISTS "spaces_owner_all" ON public.spaces;
CREATE POLICY "spaces_owner_all" ON public.spaces
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Políticas para goals
DROP POLICY IF EXISTS "goals_owner_all" ON public.goals;
CREATE POLICY "goals_owner_all" ON public.goals
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Políticas para movements
DROP POLICY IF EXISTS "movements_owner_all" ON public.movements;
CREATE POLICY "movements_owner_all" ON public.movements
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Políticas para profiles
DROP POLICY IF EXISTS "profiles_owner_all" ON public.profiles;
CREATE POLICY "profiles_owner_all" ON public.profiles
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Políticas para reports (cualquier usuario autenticado o anónimo puede enviar un reporte)
DROP POLICY IF EXISTS "reports_insert_any" ON public.reports;
CREATE POLICY "reports_insert_any" ON public.reports
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "reports_select_own" ON public.reports;
CREATE POLICY "reports_select_own" ON public.reports
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
