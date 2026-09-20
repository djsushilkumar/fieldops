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
