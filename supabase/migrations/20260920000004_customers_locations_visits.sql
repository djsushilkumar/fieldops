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
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_log_visit_activity ON public.visits;
CREATE TRIGGER trg_log_visit_activity
    AFTER INSERT OR UPDATE ON public.visits
    FOR EACH ROW
    EXECUTE FUNCTION public.log_visit_activity();
