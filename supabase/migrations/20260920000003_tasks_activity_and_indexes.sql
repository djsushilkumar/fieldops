-- Supabase Migration: Task Indexes & Activity Log Trigger
-- Migration: 20260920000003_tasks_activity_and_indexes.sql

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
