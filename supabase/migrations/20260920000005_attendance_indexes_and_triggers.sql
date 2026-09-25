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
