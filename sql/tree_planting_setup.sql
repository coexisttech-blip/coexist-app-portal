-- =============================================
-- CO2 Exist — Tree planting: prices table + RLS
-- Run in: Supabase Dashboard → SQL Editor (staging)
-- Date: 2026-05-08
--
-- Adds a tree_prices table mirroring waste_category_rates
-- (history-aware: only one row has is_current=true at a time).
-- Adds RLS so admins manage prices and orders, while
-- mobile users read the current price and their own orders.
--
-- Depends on public.is_admin() created by
-- waste_categories_admin_policies.sql.
-- =============================================

-- ---- tree_prices ----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tree_prices (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  price           numeric(10,2) NOT NULL CHECK (price >= 0),
  effective_from  date          NOT NULL DEFAULT current_date,
  effective_to    date,
  is_current      boolean       NOT NULL DEFAULT false,
  created_at      timestamptz   NOT NULL DEFAULT now()
);

-- Only one current price at a time
CREATE UNIQUE INDEX IF NOT EXISTS tree_prices_one_current
  ON public.tree_prices (is_current)
  WHERE is_current = true;

-- Seed with the price the mobile app currently hardcodes
INSERT INTO public.tree_prices (price, effective_from, is_current)
SELECT 200.00, current_date, true
WHERE NOT EXISTS (SELECT 1 FROM public.tree_prices WHERE is_current = true);

-- RLS: anyone authenticated can read, admins can write
ALTER TABLE public.tree_prices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated can read tree_prices" ON public.tree_prices;
CREATE POLICY "Authenticated can read tree_prices"
  ON public.tree_prices FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins can insert tree_prices" ON public.tree_prices;
CREATE POLICY "Admins can insert tree_prices"
  ON public.tree_prices FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update tree_prices" ON public.tree_prices;
CREATE POLICY "Admins can update tree_prices"
  ON public.tree_prices FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ---- tree_planting_orders -------------------------------------------------
-- RLS: users see/create/update only their own; admins see/update all
ALTER TABLE public.tree_planting_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own tree orders"        ON public.tree_planting_orders;
DROP POLICY IF EXISTS "Users can create own tree orders"      ON public.tree_planting_orders;
DROP POLICY IF EXISTS "Users can update own tree orders"      ON public.tree_planting_orders;
DROP POLICY IF EXISTS "Admins can view all tree orders"       ON public.tree_planting_orders;
DROP POLICY IF EXISTS "Admins can update any tree orders"     ON public.tree_planting_orders;

CREATE POLICY "Users can view own tree orders"
  ON public.tree_planting_orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own tree orders"
  ON public.tree_planting_orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tree orders"
  ON public.tree_planting_orders FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all tree orders"
  ON public.tree_planting_orders FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE POLICY "Admins can update any tree orders"
  ON public.tree_planting_orders FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- ---- tree_payments --------------------------------------------------------
-- Mirror of orders: own + admin
ALTER TABLE public.tree_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own tree payments"   ON public.tree_payments;
DROP POLICY IF EXISTS "Users can create own tree payments" ON public.tree_payments;
DROP POLICY IF EXISTS "Admins can view all tree payments"  ON public.tree_payments;

CREATE POLICY "Users can view own tree payments"
  ON public.tree_payments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.tree_planting_orders o
      WHERE o.id = tree_payments.order_id
        AND o.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own tree payments"
  ON public.tree_payments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tree_planting_orders o
      WHERE o.id = tree_payments.order_id
        AND o.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can view all tree payments"
  ON public.tree_payments FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- =============================================
-- Verify with:
--   SELECT * FROM public.tree_prices ORDER BY effective_from DESC;
--   SELECT polname, polcmd FROM pg_policy
--    WHERE polrelid IN ('public.tree_prices'::regclass,
--                       'public.tree_planting_orders'::regclass,
--                       'public.tree_payments'::regclass);
-- =============================================
