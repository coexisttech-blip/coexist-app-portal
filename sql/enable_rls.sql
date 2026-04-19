-- =============================================
-- CO2 Exist — Enable RLS on all public tables
-- Run in: Supabase Dashboard → SQL Editor
-- Date: 2026-04-15
-- =============================================

-- =============================================
-- PART 1: Tables that ALREADY have policies
-- Just need RLS turned on to activate them
-- =============================================

ALTER TABLE public.actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carbon_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rewards_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.waste_pickups ENABLE ROW LEVEL SECURITY;

-- =============================================
-- PART 2: Tables with NO policies — need RLS
-- enabled + policies created
-- =============================================

-- badge_rewards (read-only reference table)
ALTER TABLE public.badge_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view badge rewards"
  ON public.badge_rewards FOR SELECT
  USING (auth.role() = 'authenticated');

-- user_badge_rewards
ALTER TABLE public.user_badge_rewards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own badge rewards"
  ON public.user_badge_rewards FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own badge rewards"
  ON public.user_badge_rewards FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- waste_pickup_email_queue (internal/system table — no public access)
ALTER TABLE public.waste_pickup_email_queue ENABLE ROW LEVEL SECURITY;
-- No policies = only service_role can access (admin portal / edge functions)

-- waste_pickup_redemptions (contains sensitive account_number)
ALTER TABLE public.waste_pickup_redemptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own redemptions"
  ON public.waste_pickup_redemptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own redemptions"
  ON public.waste_pickup_redemptions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- =============================================
-- PART 3: Fix exposed view
-- admin_eco_tip_consultations exposes auth.users
-- and uses SECURITY DEFINER
-- =============================================

-- Option A: Drop the view if it's not needed by the app
-- DROP VIEW IF EXISTS public.admin_eco_tip_consultations;

-- Option B: Recreate as SECURITY INVOKER (uncomment if you need the view)
-- ALTER VIEW public.admin_eco_tip_consultations SET (security_invoker = on);

-- =============================================
-- DONE — Verify with:
-- SELECT tablename, rowsecurity FROM pg_tables
-- WHERE schemaname = 'public' ORDER BY tablename;
-- =============================================
