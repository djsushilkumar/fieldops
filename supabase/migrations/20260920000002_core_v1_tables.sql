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
