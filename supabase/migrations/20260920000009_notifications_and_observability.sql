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
