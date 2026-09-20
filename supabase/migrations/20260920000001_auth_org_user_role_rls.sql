-- Supabase Migration: Initial Multi-Tenant Schema, Auth, Organization, User, Role & RLS
-- Migration: 20260920000001_auth_org_user_role_rls.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. ORGANIZATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    currency TEXT NOT NULL DEFAULT 'USD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- 2. USERS (Profiles tied to auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'manager', 'employee')),
    avatar_url TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_org ON public.users(organization_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- ============================================================================
-- 3. HELPER FUNCTIONS FOR ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Function to get the organization_id of the currently authenticated user
CREATE OR REPLACE FUNCTION public.current_user_org_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT organization_id FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

-- Function to get the role of the currently authenticated user
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

-- Function to check if the current user is an Admin or Owner
CREATE OR REPLACE FUNCTION public.is_org_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role IN ('owner', 'admin')
    );
$$;

-- Function to check if the current user is a Manager or Admin/Owner
CREATE OR REPLACE FUNCTION public.is_org_manager()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users
        WHERE id = auth.uid() AND role IN ('owner', 'admin', 'manager')
    );
$$;

-- ============================================================================
-- 4. ROW LEVEL SECURITY POLICIES: ORGANIZATIONS
-- ============================================================================
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own organization"
    ON public.organizations
    FOR SELECT
    TO authenticated
    USING (id = public.current_user_org_id());

CREATE POLICY "Admins can update their own organization"
    ON public.organizations
    FOR UPDATE
    TO authenticated
    USING (id = public.current_user_org_id() AND public.is_org_admin())
    WITH CHECK (id = public.current_user_org_id() AND public.is_org_admin());

-- ============================================================================
-- 5. ROW LEVEL SECURITY POLICIES: USERS
-- ============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view members of their organization"
    ON public.users
    FOR SELECT
    TO authenticated
    USING (organization_id = public.current_user_org_id());

CREATE POLICY "Admins can insert members into their organization"
    ON public.users
    FOR INSERT
    TO authenticated
    WITH CHECK (
        organization_id = public.current_user_org_id()
        AND public.is_org_admin()
    );

CREATE POLICY "Admins can update members in their organization"
    ON public.users
    FOR UPDATE
    TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND public.is_org_admin()
    )
    WITH CHECK (
        organization_id = public.current_user_org_id()
        AND public.is_org_admin()
    );

CREATE POLICY "Employees can update their own personal profile"
    ON public.users
    FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (
        id = auth.uid()
        AND organization_id = public.current_user_org_id()
        -- Prevent role elevation by non-admins
        AND role = (SELECT role FROM public.users WHERE id = auth.uid())
    );

CREATE POLICY "Admins can delete members in their organization"
    ON public.users
    FOR DELETE
    TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND public.is_org_admin()
        AND id <> auth.uid() -- Prevent admin from deleting themselves
    );

-- ============================================================================
-- 6. AUTOMATIC PROFILE TRIGGER ON SIGNUP
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org_id UUID;
    v_role TEXT;
    v_name TEXT;
BEGIN
    -- Extract metadata supplied during registration
    v_org_id := (NEW.raw_user_meta_data->>'organization_id')::UUID;
    v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'employee');
    v_name := COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));

    -- If no org_id is provided, create a default organization for the new account (owner role)
    IF v_org_id IS NULL THEN
        INSERT INTO public.organizations (name)
        VALUES (COALESCE(NEW.raw_user_meta_data->>'organization_name', v_name || '''s Organization'))
        RETURNING id INTO v_org_id;
        v_role := 'owner';
    END IF;

    INSERT INTO public.users (
        id,
        organization_id,
        name,
        email,
        phone,
        role,
        avatar_url,
        status
    )
    VALUES (
        NEW.id,
        v_org_id,
        v_name,
        NEW.email,
        NEW.raw_user_meta_data->>'phone',
        v_role,
        NEW.raw_user_meta_data->>'avatar_url',
        'active'
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 7. AUDIT TRIGGER FOR UPDATED_AT
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_organizations_updated_at ON public.organizations;
CREATE TRIGGER set_organizations_updated_at
    BEFORE UPDATE ON public.organizations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS set_users_updated_at ON public.users;
CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
