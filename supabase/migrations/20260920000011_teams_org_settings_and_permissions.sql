-- Supabase Migration: Teams, Organization Settings, and Custom Role Permissions
-- Migration: 20260920000011_teams_org_settings_and_permissions.sql

-- ============================================================================
-- 1. EXTEND ORGANIZATIONS TABLE
-- ============================================================================

ALTER TABLE public.organizations
    ADD COLUMN IF NOT EXISTS industry TEXT DEFAULT 'Field Services',
    ADD COLUMN IF NOT EXISTS geofence_default_radius INT DEFAULT 100,
    ADD COLUMN IF NOT EXISTS auto_checkout_hours INT DEFAULT 10,
    ADD COLUMN IF NOT EXISTS require_photo_on_completion BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS require_gps_on_checkin BOOLEAN DEFAULT true;

-- ============================================================================
-- 2. TEAMS & DISPATCH UNITS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    lead_manager_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    color_hex TEXT DEFAULT '#0288D1',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_teams_org ON public.teams(organization_id);

-- Team Members Junction Table
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_team_member UNIQUE (team_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_team_members_team ON public.team_members(team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user ON public.team_members(user_id);

-- ============================================================================
-- 3. ROLE PERMISSIONS MATRIX
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    role TEXT NOT NULL,
    can_create_tasks BOOLEAN DEFAULT true,
    can_manage_customers BOOLEAN DEFAULT true,
    can_view_all_teams BOOLEAN DEFAULT true,
    can_export_reports BOOLEAN DEFAULT true,
    can_manage_forms BOOLEAN DEFAULT false,
    can_manage_users BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_org_role UNIQUE (organization_id, role)
);

CREATE INDEX IF NOT EXISTS idx_role_permissions_org ON public.role_permissions(organization_id, role);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view teams in their organization"
    ON public.teams FOR SELECT
    USING (organization_id IN (
        SELECT organization_id FROM public.profiles WHERE id = auth.uid()
    ));

CREATE POLICY "Admins can manage teams in their organization"
    ON public.teams FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM public.profiles 
            WHERE id = auth.uid() AND role IN ('admin', 'owner')
        )
    );

CREATE POLICY "Users can view team members in their organization"
    ON public.team_members FOR SELECT
    USING (
        team_id IN (
            SELECT t.id FROM public.teams t
            JOIN public.profiles p ON p.organization_id = t.organization_id
            WHERE p.id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage team members"
    ON public.team_members FOR ALL
    USING (
        team_id IN (
            SELECT t.id FROM public.teams t
            JOIN public.profiles p ON p.organization_id = t.organization_id
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'owner')
        )
    );

CREATE POLICY "Users can view role permissions for their organization"
    ON public.role_permissions FOR SELECT
    USING (organization_id IN (
        SELECT organization_id FROM public.profiles WHERE id = auth.uid()
    ));

CREATE POLICY "Admins can update role permissions"
    ON public.role_permissions FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM public.profiles 
            WHERE id = auth.uid() AND role IN ('admin', 'owner')
        )
    );
