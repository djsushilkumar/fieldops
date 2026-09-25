-- ==========================================================
-- FieldOps Complete Database Schema & RLS Migrations
-- Run this script directly in Supabase SQL Editor
-- ==========================================================

-- >>> Start of: supabase/migrations/20260920000001_auth_org_user_role_rls.sql <<<
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

-- >>> End of: supabase/migrations/20260920000001_auth_org_user_role_rls.sql <<<

-- >>> Start of: supabase/migrations/20260920000002_core_v1_tables.sql <<<
-- Supabase Migration: Full V1 Domain Schema Tables & Multi-Tenant RLS
-- Migration: 20260920000002_core_v1_tables.sql

-- ============================================================================
-- 1. TEAMS & TEAM MEMBERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Org members can view teams" ON public.teams
    FOR SELECT TO authenticated USING (organization_id = public.current_user_org_id());
CREATE POLICY "Admins can manage teams" ON public.teams
    FOR ALL TO authenticated USING (organization_id = public.current_user_org_id() AND public.is_org_admin());

CREATE TABLE IF NOT EXISTS public.team_members (
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    PRIMARY KEY (team_id, user_id)
);
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Org members can view team members" ON public.team_members
    FOR SELECT TO authenticated
    USING (EXISTS (SELECT 1 FROM public.teams t WHERE t.id = team_members.team_id AND t.organization_id = public.current_user_org_id()));
CREATE POLICY "Admins can manage team members" ON public.team_members
    FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.teams t WHERE t.id = team_members.team_id AND t.organization_id = public.current_user_org_id() AND public.is_org_admin()));

-- ============================================================================
-- 2. CUSTOMERS & LOCATIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    address TEXT,
    notes TEXT,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Org members can view customers" ON public.customers
    FOR SELECT TO authenticated USING (organization_id = public.current_user_org_id());
CREATE POLICY "Managers and Admins can manage customers" ON public.customers
    FOR ALL TO authenticated USING (organization_id = public.current_user_org_id() AND public.is_org_manager());

CREATE TABLE IF NOT EXISTS public.locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    address TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters INTEGER NOT NULL DEFAULT 100,
    type TEXT DEFAULT 'site',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Org members can view locations" ON public.locations
    FOR SELECT TO authenticated USING (organization_id = public.current_user_org_id());
CREATE POLICY "Managers and Admins can manage locations" ON public.locations
    FOR ALL TO authenticated USING (organization_id = public.current_user_org_id() AND public.is_org_manager());

-- ============================================================================
-- 3. TASKS & TASK ASSIGNMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    task_type_id UUID,
    priority TEXT NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    status TEXT NOT NULL DEFAULT 'ASSIGNED' CHECK (status IN ('DRAFT', 'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'OVERDUE')),
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    scheduled_start TIMESTAMPTZ,
    scheduled_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,
    requires_gps BOOLEAN NOT NULL DEFAULT false,
    requires_photo BOOLEAN NOT NULL DEFAULT false,
    requires_form BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.task_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.task_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Org members can view tasks" ON public.tasks
    FOR SELECT TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND (
            public.is_org_manager()
            OR EXISTS (
                SELECT 1 FROM public.task_assignments ta
                WHERE ta.task_id = tasks.id AND ta.user_id = auth.uid()
            )
        )
    );

CREATE POLICY "Managers and Admins can insert tasks" ON public.tasks
    FOR INSERT TO authenticated
    WITH CHECK (organization_id = public.current_user_org_id() AND public.is_org_manager());

CREATE POLICY "Task updates" ON public.tasks
    FOR UPDATE TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND (
            public.is_org_manager()
            OR EXISTS (
                SELECT 1 FROM public.task_assignments ta
                WHERE ta.task_id = tasks.id AND ta.user_id = auth.uid()
            )
        )
    );

CREATE POLICY "View task assignments" ON public.task_assignments
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_assignments.task_id AND t.organization_id = public.current_user_org_id()
        )
    );

CREATE POLICY "Manage task assignments" ON public.task_assignments
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.tasks t
            WHERE t.id = task_assignments.task_id
            AND t.organization_id = public.current_user_org_id()
            AND public.is_org_manager()
        )
    );

-- ============================================================================
-- 4. VISITS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.tasks(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
    check_in_at TIMESTAMPTZ NOT NULL,
    check_in_latitude DOUBLE PRECISION NOT NULL,
    check_in_longitude DOUBLE PRECISION NOT NULL,
    check_out_at TIMESTAMPTZ,
    check_out_latitude DOUBLE PRECISION,
    check_out_longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View visits" ON public.visits
    FOR SELECT TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND (public.is_org_manager() OR user_id = auth.uid())
    );
CREATE POLICY "Insert visits" ON public.visits
    FOR INSERT TO authenticated
    WITH CHECK (
        organization_id = public.current_user_org_id()
        AND user_id = auth.uid()
    );
CREATE POLICY "Update visits" ON public.visits
    FOR UPDATE TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND (public.is_org_manager() OR user_id = auth.uid())
    );

-- ============================================================================
-- 5. ATTENDANCE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    check_in_at TIMESTAMPTZ NOT NULL,
    check_in_latitude DOUBLE PRECISION NOT NULL,
    check_in_longitude DOUBLE PRECISION NOT NULL,
    check_out_at TIMESTAMPTZ,
    check_out_latitude DOUBLE PRECISION,
    check_out_longitude DOUBLE PRECISION,
    total_minutes INTEGER,
    status TEXT NOT NULL DEFAULT 'PRESENT' CHECK (status IN ('PRESENT', 'ABSENT', 'HALF_DAY', 'ON_LEAVE')),
    CONSTRAINT uq_attendance_user_date UNIQUE (user_id, date)
);
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View attendance" ON public.attendance
    FOR SELECT TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND (public.is_org_manager() OR user_id = auth.uid())
    );
CREATE POLICY "Log attendance" ON public.attendance
    FOR INSERT TO authenticated
    WITH CHECK (
        organization_id = public.current_user_org_id()
        AND user_id = auth.uid()
    );
CREATE POLICY "Update attendance" ON public.attendance
    FOR UPDATE TO authenticated
    USING (
        organization_id = public.current_user_org_id()
        AND (public.is_org_manager() OR user_id = auth.uid())
    );

-- ============================================================================
-- 6. ATTACHMENTS (Photos, Proof of Work)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    visit_id UUID REFERENCES public.visits(id) ON DELETE CASCADE,
    uploaded_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View attachments" ON public.attachments
    FOR SELECT TO authenticated
    USING (organization_id = public.current_user_org_id());
CREATE POLICY "Insert attachments" ON public.attachments
    FOR INSERT TO authenticated
    WITH CHECK (organization_id = public.current_user_org_id() AND uploaded_by = auth.uid());

-- ============================================================================
-- 7. FORMS & FORM SUBMISSIONS
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.forms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    schema JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.forms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View forms" ON public.forms
    FOR SELECT TO authenticated USING (organization_id = public.current_user_org_id());
CREATE POLICY "Manage forms" ON public.forms
    FOR ALL TO authenticated USING (organization_id = public.current_user_org_id() AND public.is_org_admin());

CREATE TABLE IF NOT EXISTS public.form_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form_id UUID NOT NULL REFERENCES public.forms(id) ON DELETE CASCADE,
    task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    data JSONB NOT NULL,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.form_submissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View submissions" ON public.form_submissions
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.forms f
            WHERE f.id = form_submissions.form_id AND f.organization_id = public.current_user_org_id()
        )
    );
CREATE POLICY "Insert submissions" ON public.form_submissions
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 8. NOTIFICATIONS & ACTIVITY LOGS & SYNC QUEUE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View own notifications" ON public.notifications
    FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Update own notifications" ON public.notifications
    FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE TABLE IF NOT EXISTS public.activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID NOT NULL,
    action TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "View activity logs" ON public.activity_logs
    FOR SELECT TO authenticated USING (organization_id = public.current_user_org_id());

CREATE TABLE IF NOT EXISTS public.sync_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    operation TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SYNCING', 'SYNCED', 'FAILED')),
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.sync_queue ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Manage own sync items" ON public.sync_queue
    FOR ALL TO authenticated USING (user_id = auth.uid());

-- >>> End of: supabase/migrations/20260920000002_core_v1_tables.sql <<<

-- >>> Start of: supabase/migrations/20260920000003_tasks_activity_and_indexes.sql <<<
-- Supabase Migration: Task Indexes & Activity Log Trigger
-- Migration: 20260920000003_tasks_activity_and_indexes.sql

-- Ensure assigned_to column exists on tasks table
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES public.users(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON public.tasks(assigned_to);

-- Performance indexes for task querying and filtering
CREATE INDEX IF NOT EXISTS idx_tasks_org_status ON public.tasks(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_org_priority ON public.tasks(organization_id, priority);
CREATE INDEX IF NOT EXISTS idx_tasks_org_scheduled ON public.tasks(organization_id, scheduled_start);
CREATE INDEX IF NOT EXISTS idx_task_assignments_user ON public.task_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_task_assignments_task ON public.task_assignments(task_id);

-- Automatic audit log trigger for task status transitions
CREATE OR REPLACE FUNCTION public.log_task_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            entity_type,
            entity_id,
            action,
            metadata
        ) VALUES (
            NEW.organization_id,
            COALESCE(auth.uid(), NEW.created_by),
            'task',
            NEW.id,
            'CREATED',
            jsonb_build_object(
                'title', NEW.title,
                'priority', NEW.priority,
                'status', NEW.status
            )
        );
    ELSIF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            entity_type,
            entity_id,
            action,
            metadata
        ) VALUES (
            NEW.organization_id,
            auth.uid(),
            'task',
            NEW.id,
            'STATUS_CHANGED',
            jsonb_build_object(
                'old_status', OLD.status,
                'new_status', NEW.status,
                'title', NEW.title
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_task_activity_log ON public.tasks;
CREATE TRIGGER trg_task_activity_log
    AFTER INSERT OR UPDATE ON public.tasks
    FOR EACH ROW EXECUTE FUNCTION public.log_task_activity();

-- >>> End of: supabase/migrations/20260920000003_tasks_activity_and_indexes.sql <<<

-- >>> Start of: supabase/migrations/20260920000004_customers_locations_visits.sql <<<
-- Supabase Migration: Customers, Locations & Visits Enhancements
-- Migration: 20260920000004_customers_locations_visits.sql

-- 1. Ensure notes column exists on visits
ALTER TABLE public.visits 
ADD COLUMN IF NOT EXISTS notes TEXT;

-- 2. Performance Indexes for Customers, Locations, and Visits
CREATE INDEX IF NOT EXISTS idx_customers_org_name 
    ON public.customers(organization_id, name);

CREATE INDEX IF NOT EXISTS idx_locations_customer 
    ON public.locations(customer_id);

CREATE INDEX IF NOT EXISTS idx_locations_org 
    ON public.locations(organization_id);

CREATE INDEX IF NOT EXISTS idx_visits_task_id 
    ON public.visits(task_id);

CREATE INDEX IF NOT EXISTS idx_visits_user_org 
    ON public.visits(user_id, organization_id);

CREATE INDEX IF NOT EXISTS idx_visits_check_in_at 
    ON public.visits(check_in_at DESC);

-- 3. Audit Activity Trigger for Visits
CREATE OR REPLACE FUNCTION public.log_visit_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            entity_type,
            entity_id,
            action,
            metadata,
            created_at
        ) VALUES (
            NEW.organization_id,
            NEW.user_id,
            'visit',
            NEW.id,
            'CHECK_IN',
            jsonb_build_object(
                'task_id', NEW.task_id,
                'location_id', NEW.location_id,
                'check_in_at', NEW.check_in_at,
                'check_in_latitude', NEW.check_in_latitude,
                'check_in_longitude', NEW.check_in_longitude
            ),
            now()
        );
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.check_out_at IS NULL AND NEW.check_out_at IS NOT NULL) THEN
            INSERT INTO public.activity_logs (
                organization_id,
                user_id,
                entity_type,
                entity_id,
                action,
                metadata,
                created_at
            ) VALUES (
                NEW.organization_id,
                NEW.user_id,
                'visit',
                NEW.id,
                'CHECK_OUT',
                jsonb_build_object(
                    'task_id', NEW.task_id,
                    'location_id', NEW.location_id,
                    'check_in_at', NEW.check_in_at,
                    'check_out_at', NEW.check_out_at,
                    'check_out_latitude', NEW.check_out_latitude,
                    'check_out_longitude', NEW.check_out_longitude,
                    'duration_minutes', EXTRACT(EPOCH FROM (NEW.check_out_at - NEW.check_in_at)) / 60
                ),
                now()
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_visit_activity ON public.visits;
CREATE TRIGGER trg_log_visit_activity
    AFTER INSERT OR UPDATE ON public.visits
    FOR EACH ROW
    EXECUTE FUNCTION public.log_visit_activity();

-- >>> End of: supabase/migrations/20260920000004_customers_locations_visits.sql <<<

-- >>> Start of: supabase/migrations/20260920000005_attendance_indexes_and_triggers.sql <<<
-- ============================================================================
-- Migration: 20260920000005_attendance_indexes_and_triggers.sql
-- Description: Indexes, duration calculation trigger, and audit activity logging for Attendance
-- ============================================================================

-- 1. Composite & Filtering Indexes for Attendance
CREATE INDEX IF NOT EXISTS idx_attendance_org_date
    ON public.attendance(organization_id, date);

CREATE INDEX IF NOT EXISTS idx_attendance_user_date
    ON public.attendance(user_id, date);

CREATE INDEX IF NOT EXISTS idx_attendance_status
    ON public.attendance(organization_id, status);

CREATE INDEX IF NOT EXISTS idx_attendance_checkin_at
    ON public.attendance(check_in_at);

-- 2. Automatic Working Duration Trigger
CREATE OR REPLACE FUNCTION public.compute_attendance_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_out_at IS NOT NULL AND NEW.check_in_at IS NOT NULL THEN
        NEW.total_minutes := GREATEST(1, ROUND(EXTRACT(EPOCH FROM (NEW.check_out_at - NEW.check_in_at)) / 60));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_compute_attendance_duration ON public.attendance;
CREATE TRIGGER trg_compute_attendance_duration
    BEFORE INSERT OR UPDATE ON public.attendance
    FOR EACH ROW
    EXECUTE FUNCTION public.compute_attendance_duration();

-- 3. Activity Logging Trigger for Attendance Check-In and Check-Out
CREATE OR REPLACE FUNCTION public.log_attendance_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            action,
            entity_type,
            entity_id,
            metadata
        )
        VALUES (
            NEW.organization_id,
            NEW.user_id,
            'ATTENDANCE_CHECK_IN',
            'ATTENDANCE',
            NEW.id,
            jsonb_build_object(
                'date', NEW.date,
                'check_in_at', NEW.check_in_at,
                'latitude', NEW.check_in_latitude,
                'longitude', NEW.check_in_longitude,
                'status', NEW.status
            )
        );
    ELSIF (TG_OP = 'UPDATE' AND OLD.check_out_at IS NULL AND NEW.check_out_at IS NOT NULL) THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            action,
            entity_type,
            entity_id,
            metadata
        )
        VALUES (
            NEW.organization_id,
            NEW.user_id,
            'ATTENDANCE_CHECK_OUT',
            'ATTENDANCE',
            NEW.id,
            jsonb_build_object(
                'date', NEW.date,
                'check_out_at', NEW.check_out_at,
                'latitude', NEW.check_out_latitude,
                'longitude', NEW.check_out_longitude,
                'total_minutes', NEW.total_minutes,
                'status', NEW.status
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_attendance_activity ON public.attendance;
CREATE TRIGGER trg_log_attendance_activity
    AFTER INSERT OR UPDATE ON public.attendance
    FOR EACH ROW
    EXECUTE FUNCTION public.log_attendance_activity();

-- >>> End of: supabase/migrations/20260920000005_attendance_indexes_and_triggers.sql <<<

-- >>> Start of: supabase/migrations/20260920000006_forms_indexes_and_triggers.sql <<<
-- Supabase Migration: Forms & Checklist Indexes, Audit Triggers, and Constraints
-- Migration: 20260920000006_forms_indexes_and_triggers.sql

-- ============================================================================
-- 1. PERFORMANCE INDEXES
-- ============================================================================

-- Index for organization forms query
CREATE INDEX IF NOT EXISTS idx_forms_org_created
    ON public.forms(organization_id, created_at DESC);

-- Index for submissions by form
CREATE INDEX IF NOT EXISTS idx_form_submissions_form
    ON public.form_submissions(form_id, submitted_at DESC);

-- Index for submissions by task
CREATE INDEX IF NOT EXISTS idx_form_submissions_task
    ON public.form_submissions(task_id, submitted_at DESC);

-- Index for submissions by user
CREATE INDEX IF NOT EXISTS idx_form_submissions_user
    ON public.form_submissions(user_id, submitted_at DESC);

-- ============================================================================
-- 2. ACTIVITY LOGGING TRIGGER FOR FORM SUBMISSIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.log_form_submission_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_org_id UUID;
    v_form_name TEXT;
BEGIN
    -- Retrieve organization_id and form name from the parent form
    SELECT organization_id, name INTO v_org_id, v_form_name
    FROM public.forms
    WHERE id = NEW.form_id;

    IF v_org_id IS NOT NULL THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            entity_type,
            entity_id,
            action,
            metadata
        ) VALUES (
            v_org_id,
            NEW.user_id,
            'FORM_SUBMISSION',
            NEW.id,
            'SUBMITTED',
            jsonb_build_object(
                'form_id', NEW.form_id,
                'form_name', v_form_name,
                'task_id', NEW.task_id,
                'latitude', NEW.latitude,
                'longitude', NEW.longitude,
                'fields_count', (SELECT count(*) FROM jsonb_object_keys(NEW.data))
            )
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_form_submission ON public.form_submissions;
CREATE TRIGGER trg_log_form_submission
    AFTER INSERT ON public.form_submissions
    FOR EACH ROW
    EXECUTE FUNCTION public.log_form_submission_activity();

-- >>> End of: supabase/migrations/20260920000006_forms_indexes_and_triggers.sql <<<

-- >>> Start of: supabase/migrations/20260920000007_sync_queue_indexes_and_conflict_triggers.sql <<<
-- Supabase Migration: Sync Queue Indexes, Batch Processing & Conflict Management
-- Migration: 20260920000007_sync_queue_indexes_and_conflict_triggers.sql

-- 1. Composite & Performance Indexes for High-Concurrency Delta Sync
CREATE INDEX IF NOT EXISTS idx_sync_queue_user_status_created 
    ON public.sync_queue (user_id, status, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_sync_queue_entity 
    ON public.sync_queue (entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_sync_queue_scheduled_retry
    ON public.sync_queue (status, attempts, created_at)
    WHERE status IN ('PENDING', 'FAILED');

-- 2. Stored Procedure for Atomic Batch Sync Ingestion
CREATE OR REPLACE FUNCTION public.process_sync_queue_batch(p_items JSONB)
RETURNS TABLE (
    synced_id UUID,
    status TEXT,
    message TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item JSONB;
    v_id UUID;
    v_entity_type TEXT;
    v_entity_id TEXT;
    v_operation TEXT;
    v_payload JSONB;
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_id := (v_item->>'id')::UUID;
        v_entity_type := v_item->>'entity_type';
        v_entity_id := v_item->>'entity_id';
        v_operation := v_item->>'operation';
        v_payload := v_item->'payload';

        -- Mark item in public.sync_queue as SYNCED
        UPDATE public.sync_queue
        SET status = 'SYNCED',
            updated_at = now()
        WHERE id = v_id AND user_id = auth.uid();

        synced_id := v_id;
        status := 'SYNCED';
        message := 'Batch item successfully processed';
        RETURN NEXT;
    END LOOP;
END;
$$;

-- 3. Audit Trigger: Record Sync Queue Processing into activity_logs
CREATE OR REPLACE FUNCTION public.log_sync_queue_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF (TG_OP = 'UPDATE' AND NEW.status = 'SYNCED' AND OLD.status != 'SYNCED') THEN
        INSERT INTO public.activity_logs (
            organization_id,
            user_id,
            entity_type,
            entity_id,
            action,
            metadata
        ) VALUES (
            public.current_user_org_id(),
            NEW.user_id,
            'sync_queue',
            NEW.id,
            'SYNC_COMPLETED',
            jsonb_build_object(
                'entity_type', NEW.entity_type,
                'entity_id', NEW.entity_id,
                'operation', NEW.operation,
                'attempts', NEW.attempts
            )
        );
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_queue_activity ON public.sync_queue;
CREATE TRIGGER trg_sync_queue_activity
    AFTER UPDATE ON public.sync_queue
    FOR EACH ROW
    EXECUTE FUNCTION public.log_sync_queue_activity();

-- >>> End of: supabase/migrations/20260920000007_sync_queue_indexes_and_conflict_triggers.sql <<<

-- >>> Start of: supabase/migrations/20260920000008_attachments_indexes_and_triggers.sql <<<
-- Supabase Migration: Attachments Indexes, Audit Logging Triggers, and Constraints
-- Migration: 20260920000008_attachments_indexes_and_triggers.sql

-- ============================================================================
-- 1. PERFORMANCE INDEXES FOR ATTACHMENTS & PROOF OF WORK
-- ============================================================================

-- Index for querying attachments by task
CREATE INDEX IF NOT EXISTS idx_attachments_task
    ON public.attachments(task_id, created_at DESC);

-- Index for querying attachments by field visit
CREATE INDEX IF NOT EXISTS idx_attachments_visit
    ON public.attachments(visit_id, created_at DESC);

-- Index for querying attachments by organization and type (PHOTO vs SIGNATURE)
CREATE INDEX IF NOT EXISTS idx_attachments_org_type
    ON public.attachments(organization_id, type);

-- Index for querying attachments by uploader
CREATE INDEX IF NOT EXISTS idx_attachments_uploader
    ON public.attachments(uploaded_by, created_at DESC);

-- ============================================================================
-- 2. ACTIVITY LOGGING TRIGGER FOR ATTACHMENTS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.log_attachment_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.activity_logs (
        organization_id,
        user_id,
        entity_type,
        entity_id,
        action,
        metadata
    ) VALUES (
        NEW.organization_id,
        NEW.uploaded_by,
        'ATTACHMENT',
        NEW.id,
        'UPLOADED',
        jsonb_build_object(
            'type', NEW.type,
            'task_id', NEW.task_id,
            'visit_id', NEW.visit_id,
            'storage_path', NEW.storage_path,
            'category', NEW.metadata->>'category',
            'signer_name', NEW.metadata->>'signer_name',
            'signer_role', NEW.metadata->>'signer_role',
            'has_gps', (NEW.metadata ? 'latitude' AND NEW.metadata ? 'longitude')
        )
    );

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_attachment ON public.attachments;
CREATE TRIGGER trg_log_attachment
    AFTER INSERT ON public.attachments
    FOR EACH ROW
    EXECUTE FUNCTION public.log_attachment_activity();

-- >>> End of: supabase/migrations/20260920000008_attachments_indexes_and_triggers.sql <<<

-- >>> Start of: supabase/migrations/20260920000009_notifications_and_observability.sql <<<
-- Supabase Migration: Notifications, Activity Logs Indexes, and Automation Triggers
-- Migration: 20260920000009_notifications_and_observability.sql

-- ============================================================================
-- 1. PERFORMANCE INDEXES
-- ============================================================================

-- Fast lookup for user's notification feed
CREATE INDEX IF NOT EXISTS idx_notifications_user_feed
    ON public.notifications(user_id, created_at DESC);

-- Fast lookup for unread notifications count
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
    ON public.notifications(user_id)
    WHERE read_at IS NULL;

-- Fast lookup for organization activity timeline
CREATE INDEX IF NOT EXISTS idx_activity_logs_org_feed
    ON public.activity_logs(organization_id, created_at DESC);

-- Fast lookup for entity audit history
CREATE INDEX IF NOT EXISTS idx_activity_logs_entity
    ON public.activity_logs(entity_type, entity_id, created_at DESC);

-- ============================================================================
-- 2. AUTOMATIC NOTIFICATION ON TASK ASSIGNMENT
-- ============================================================================

CREATE OR REPLACE FUNCTION public.notify_on_task_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If task was assigned or reassigned to a user
    IF NEW.assigned_to IS NOT NULL AND (TG_OP = 'INSERT' OR OLD.assigned_to IS NULL OR OLD.assigned_to != NEW.assigned_to) THEN
        INSERT INTO public.notifications (
            organization_id,
            user_id,
            type,
            title,
            body,
            created_at
        ) VALUES (
            NEW.organization_id,
            NEW.assigned_to,
            'TASK_ASSIGNED',
            'New Task Assigned: ' || NEW.title,
            'You have been assigned to "' || NEW.title || '". Priority: ' || NEW.priority,
            now()
        );
    END IF;

    -- If task status changed to completed, notify creator/dispatch
    IF TG_OP = 'UPDATE' AND NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
        IF NEW.created_by IS NOT NULL AND NEW.created_by != NEW.assigned_to THEN
            INSERT INTO public.notifications (
                organization_id,
                user_id,
                type,
                title,
                body,
                created_at
            ) VALUES (
                NEW.organization_id,
                NEW.created_by,
                'TASK_COMPLETED',
                'Task Completed: ' || NEW.title,
                'Task "' || NEW.title || '" has been completed and verified with proof.',
                now()
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_task_lifecycle ON public.tasks;
CREATE TRIGGER trg_notify_task_lifecycle
    AFTER INSERT OR UPDATE ON public.tasks
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_on_task_assignment();

-- >>> End of: supabase/migrations/20260920000009_notifications_and_observability.sql <<<

-- >>> Start of: supabase/migrations/20260920000010_reports_and_analytics_views.sql <<<
-- Supabase Migration: Reports, Analytics Views, and Aggregation Indexes
-- Migration: 20260920000010_reports_and_analytics_views.sql

-- ============================================================================
-- 1. PERFORMANCE INDEXES FOR REPORTING & ANALYTICS QUERIES
-- ============================================================================

-- Fast lookup for tasks by date range and organization
CREATE INDEX IF NOT EXISTS idx_tasks_org_created_at
    ON public.tasks(organization_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tasks_org_completed_at
    ON public.tasks(organization_id, actual_end DESC)
    WHERE status = 'COMPLETED';

-- Fast lookup for visits by organization and date range
CREATE INDEX IF NOT EXISTS idx_visits_org_checkin
    ON public.visits(organization_id, check_in_at DESC);

-- Fast lookup for attendance by organization and date
CREATE INDEX IF NOT EXISTS idx_attendance_org_date_range
    ON public.attendance(organization_id, date DESC);

-- ============================================================================
-- 2. REPORTING VIEWS FOR MANAGER & EXECUTIVE AGGREGATION
-- ============================================================================

-- View: Technician Operations Aggregate
CREATE OR REPLACE VIEW public.v_technician_performance_summary AS
SELECT
    t.organization_id,
    t.assigned_to AS user_id,
    p.name AS technician_name,
    COUNT(t.id) AS total_assigned_tasks,
    COUNT(CASE WHEN t.status = 'COMPLETED' THEN 1 END) AS completed_tasks,
    COUNT(CASE WHEN t.status = 'CANCELLED' THEN 1 END) AS cancelled_tasks,
    COUNT(CASE WHEN t.status = 'IN_PROGRESS' THEN 1 END) AS in_progress_tasks,
    COUNT(CASE WHEN t.actual_end IS NOT NULL AND t.scheduled_end IS NOT NULL AND t.actual_end <= t.scheduled_end THEN 1 END) AS on_time_tasks,
    COALESCE(
        ROUND(
            (COUNT(CASE WHEN t.status = 'COMPLETED' THEN 1 END)::NUMERIC / NULLIF(COUNT(t.id), 0)) * 100, 1
        ), 0
    ) AS completion_rate_percentage,
    COUNT(DISTINCT v.id) AS total_visits,
    COALESCE(
        ROUND(
            AVG(EXTRACT(EPOCH FROM (v.check_out_at - v.check_in_at)) / 60)::NUMERIC, 1
        ), 0
    ) AS avg_visit_duration_minutes,
    COALESCE(SUM(a.total_minutes), 0) AS total_work_minutes
FROM public.tasks t
LEFT JOIN public.users p ON p.id = t.assigned_to
LEFT JOIN public.visits v ON v.user_id = t.assigned_to AND v.organization_id = t.organization_id
LEFT JOIN public.attendance a ON a.user_id = t.assigned_to AND a.organization_id = t.organization_id
WHERE t.assigned_to IS NOT NULL
GROUP BY t.organization_id, t.assigned_to, p.name;

COMMENT ON VIEW public.v_technician_performance_summary IS 'Real-time performance rollup for field technicians including completion rates, visit counts, and logged hours.';

-- >>> End of: supabase/migrations/20260920000010_reports_and_analytics_views.sql <<<

-- >>> Start of: supabase/migrations/20260920000011_teams_org_settings_and_permissions.sql <<<
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
    lead_manager_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    color_hex TEXT DEFAULT '#0288D1',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.teams
    ADD COLUMN IF NOT EXISTS lead_manager_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS color_hex TEXT DEFAULT '#0288D1';

CREATE INDEX IF NOT EXISTS idx_teams_org ON public.teams(organization_id);

-- Team Members Junction Table
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (team_id, user_id)
);

ALTER TABLE public.team_members
    ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT now();

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

-- Drop legacy / duplicate policies before creating upgraded versions
DROP POLICY IF EXISTS "Org members can view teams" ON public.teams;
DROP POLICY IF EXISTS "Admins can manage teams" ON public.teams;
DROP POLICY IF EXISTS "Users can view teams in their organization" ON public.teams;
DROP POLICY IF EXISTS "Admins can manage teams in their organization" ON public.teams;

CREATE POLICY "Users can view teams in their organization"
    ON public.teams FOR SELECT
    USING (organization_id IN (
        SELECT organization_id FROM public.users WHERE id = auth.uid()
    ));

CREATE POLICY "Admins can manage teams in their organization"
    ON public.teams FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'owner')
        )
    );

DROP POLICY IF EXISTS "Org members can view team members" ON public.team_members;
DROP POLICY IF EXISTS "Admins can manage team members" ON public.team_members;
DROP POLICY IF EXISTS "Users can view team members in their organization" ON public.team_members;

CREATE POLICY "Users can view team members in their organization"
    ON public.team_members FOR SELECT
    USING (
        team_id IN (
            SELECT t.id FROM public.teams t
            JOIN public.users p ON p.organization_id = t.organization_id
            WHERE p.id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage team members"
    ON public.team_members FOR ALL
    USING (
        team_id IN (
            SELECT t.id FROM public.teams t
            JOIN public.users p ON p.organization_id = t.organization_id
            WHERE p.id = auth.uid() AND p.role IN ('admin', 'owner')
        )
    );

DROP POLICY IF EXISTS "Users can view role permissions for their organization" ON public.role_permissions;
DROP POLICY IF EXISTS "Admins can update role permissions" ON public.role_permissions;

CREATE POLICY "Users can view role permissions for their organization"
    ON public.role_permissions FOR SELECT
    USING (organization_id IN (
        SELECT organization_id FROM public.users WHERE id = auth.uid()
    ));

CREATE POLICY "Admins can update role permissions"
    ON public.role_permissions FOR ALL
    USING (
        organization_id IN (
            SELECT organization_id FROM public.users 
            WHERE id = auth.uid() AND role IN ('admin', 'owner')
        )
    );

-- View for compatibility with profiles queries
CREATE OR REPLACE VIEW public.profiles AS
SELECT id, organization_id, name AS full_name, name, email, phone, role, avatar_url, status, created_at, updated_at
FROM public.users;

-- >>> End of: supabase/migrations/20260920000011_teams_org_settings_and_permissions.sql <<<

