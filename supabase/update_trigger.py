import os
import sys
import psycopg2

def update_attendance_trigger():
    password = os.environ.get("SUPABASE_DB_PASSWORD") or (sys.argv[1] if len(sys.argv) > 1 else None)
    if not password:
        print("Error: SUPABASE_DB_PASSWORD environment variable or command-line argument required.")
        print("Usage: python3 supabase/update_trigger.py <db_password>")
        sys.exit(1)

    host = os.environ.get("SUPABASE_DB_HOST", "db.yntpxattrcrshrzptkhs.supabase.co")
    port = int(os.environ.get("SUPABASE_DB_PORT", "5432"))
    dbname = os.environ.get("SUPABASE_DB_NAME", "postgres")
    user = os.environ.get("SUPABASE_DB_USER", "postgres")

    conn = None
    try:
        conn = psycopg2.connect(
            host=host,
            port=port,
            dbname=dbname,
            user=user,
            password=password,
            connect_timeout=10,
            sslmode="require"
        )
        conn.autocommit = True
        cur = conn.cursor()

        # Add details column as alias for safety
        cur.execute("ALTER TABLE public.activity_logs ADD COLUMN IF NOT EXISTS details JSONB DEFAULT '{}'::jsonb;")

        # Update function with search_path safety
        cur.execute("""
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
                        'total_minutes', NEW.total_minutes
                    )
                );
            END IF;
            RETURN NEW;
        END;
        $$;
        """)

        print("Trigger successfully updated in database!")
        cur.close()
    except Exception as e:
        print(f"Error updating trigger: {e}")
        sys.exit(1)
    finally:
        if conn is not None and not conn.closed:
            conn.close()

if __name__ == "__main__":
    update_attendance_trigger()
