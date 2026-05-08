-- =============================================
-- CO2 Exist — Admin-only write access for waste_categories
-- Run in: Supabase Dashboard → SQL Editor (staging)
-- Date: 2026-05-08
--
-- Why: The portal could not toggle is_active on waste_categories.
-- PostgREST returned HTTP 200 with [] because RLS was enabled
-- with no UPDATE policy. We add INSERT/UPDATE/DELETE policies
-- restricted to admin users (public.users.role ilike 'admin').
--
-- Scope: this Supabase project hosts BOTH the mobile app
-- (289 'user' rows) AND the admin portal. A blanket
-- TO authenticated policy would let any mobile-app user
-- mutate categories — so we gate on the role column instead.
-- =============================================

-- Helper: is_admin() returns true when the calling user has
-- role 'admin' (case-insensitive) in public.users.
-- SECURITY DEFINER so the policy can read public.users without
-- being blocked by RLS on that table.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users
    WHERE id = auth.uid()
      AND lower(role) = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

-- waste_categories: admins only for writes
DROP POLICY IF EXISTS "Authenticated can update waste_categories" ON public.waste_categories;
DROP POLICY IF EXISTS "Authenticated can insert waste_categories" ON public.waste_categories;
DROP POLICY IF EXISTS "Authenticated can delete waste_categories" ON public.waste_categories;
DROP POLICY IF EXISTS "Admins can update waste_categories"        ON public.waste_categories;
DROP POLICY IF EXISTS "Admins can insert waste_categories"        ON public.waste_categories;
DROP POLICY IF EXISTS "Admins can delete waste_categories"        ON public.waste_categories;

CREATE POLICY "Admins can update waste_categories"
  ON public.waste_categories FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can insert waste_categories"
  ON public.waste_categories FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can delete waste_categories"
  ON public.waste_categories FOR DELETE
  TO authenticated
  USING (public.is_admin());

-- waste_category_rates: admins only for writes
DROP POLICY IF EXISTS "Authenticated can update waste_category_rates" ON public.waste_category_rates;
DROP POLICY IF EXISTS "Authenticated can insert waste_category_rates" ON public.waste_category_rates;
DROP POLICY IF EXISTS "Admins can update waste_category_rates"        ON public.waste_category_rates;
DROP POLICY IF EXISTS "Admins can insert waste_category_rates"        ON public.waste_category_rates;

CREATE POLICY "Admins can update waste_category_rates"
  ON public.waste_category_rates FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "Admins can insert waste_category_rates"
  ON public.waste_category_rates FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin());

-- =============================================
-- Promote portal test account to admin so the new policies
-- actually grant access when logged in as this user.
-- =============================================
UPDATE public.users
   SET role = 'admin'
 WHERE email = 'devang@matchpointgps.com';

-- =============================================
-- Verify with:
--   SELECT polname, polcmd, polroles::regrole[]
--   FROM pg_policy
--   WHERE polrelid IN ('public.waste_categories'::regclass,
--                      'public.waste_category_rates'::regclass);
--
--   SELECT email, role FROM public.users
--    WHERE email = 'devang@matchpointgps.com';
--
-- Confirm caller is admin (run while logged into Studio as
-- a postgres/service role — will return false because auth.uid()
-- is null in that context; test from the portal instead):
--   SELECT public.is_admin();
-- =============================================
