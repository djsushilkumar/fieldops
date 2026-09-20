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
    p.full_name AS technician_name,
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
LEFT JOIN public.profiles p ON p.id = t.assigned_to
LEFT JOIN public.visits v ON v.user_id = t.assigned_to AND v.organization_id = t.organization_id
LEFT JOIN public.attendance a ON a.user_id = t.assigned_to AND a.organization_id = t.organization_id
WHERE t.assigned_to IS NOT NULL
GROUP BY t.organization_id, t.assigned_to, p.full_name;

COMMENT ON VIEW public.v_technician_performance_summary IS 'Real-time performance rollup for field technicians including completion rates, visit counts, and logged hours.';
