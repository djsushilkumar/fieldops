import psycopg2

conn = psycopg2.connect(
    host="db.yntpxattrcrshrzptkhs.supabase.co",
    port=5432,
    dbname="postgres",
    user="postgres",
    password="Z9NbayLTkNZGTdOi",
    sslmode="require"
)
conn.autocommit = True
cur = conn.cursor()

# Add details column as alias for safety
cur.execute("ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS details JSONB DEFAULT '{}'::jsonb;")

# Update function
cur.execute("""
CREATE OR REPLACE FUNCTION public.log_attendance_activity()
RETURNS TRIGGER AS $$
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
                'total_minutes', NEW.total_minutes
            )
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
""")

print("Trigger successfully updated in live database!")
cur.close()
conn.close()
