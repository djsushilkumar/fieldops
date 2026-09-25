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
