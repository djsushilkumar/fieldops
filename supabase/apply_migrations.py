import sys
import os
import psycopg2
import urllib.request
import json

def run_migration_postgres(password: str, host: str = "db.yntpxattrcrshrzptkhs.supabase.co", port: int = 5432, dbname: str = "postgres", user: str = "postgres"):
    schema_path = os.path.join(os.path.dirname(__file__), "complete_schema.sql")
    if not os.path.exists(schema_path):
        print(f"Error: Schema file not found at {schema_path}")
        return False

    with open(schema_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    print(f"Connecting to PostgreSQL database at {host}:{port}...")
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
        cursor = conn.cursor()
        print("Connected! Executing complete_schema.sql migrations...")
        cursor.execute(sql_content)
        print("All migrations and RLS policies executed successfully!")

        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            ORDER BY table_name;
        """)
        tables = [row[0] for row in cursor.fetchall()]
        print(f"Verified {len(tables)} tables created in public schema:")
        for t in tables:
            print(f" - {t}")

        cursor.close()
        conn.close()
        return True
    except Exception as e:
        print(f"Database error: {e}")
        return False

def run_migration_api(token: str, project_ref: str = "yntpxattrcrshrzptkhs"):
    schema_path = os.path.join(os.path.dirname(__file__), "complete_schema.sql")
    with open(schema_path, "r", encoding="utf-8") as f:
        sql_content = f.read()

    url = f"https://api.supabase.com/v1/projects/{project_ref}/database/query"
    req = urllib.request.Request(
        url,
        data=json.dumps({"query": sql_content}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        },
        method="POST"
    )
    print(f"Executing complete_schema.sql via Supabase Management API...")
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            res = response.read().decode("utf-8")
            print("Migrations executed successfully via API!")
            return True
    except Exception as e:
        print(f"API execution error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        val = os.environ.get("SUPABASE_DB_PASSWORD") or os.environ.get("SUPABASE_ACCESS_TOKEN")
        if not val:
            print("Usage: python3 supabase/apply_migrations.py <db_password_or_token>")
            sys.exit(1)
    else:
        val = sys.argv[1]

    if val.startswith("sbp_"):
        success = run_migration_api(val)
    else:
        success = run_migration_postgres(val)

    sys.exit(0 if success else 1)
