#!/usr/bin/env python3
"""
db.py - Execute SQL queries directly
Usage: python /app/db.py "SQL query here"

Examples:
  python /app/db.py "SELECT * FROM goals_and_tasks.tasks WHERE status = 'new'"
  python /app/db.py "UPDATE goals_and_tasks.tasks SET status = 'in_progress' WHERE id = 123"
"""

import os
import sys
import json
import time
import psycopg2

DATABASE_URL = os.environ.get("DATABASE_URL")

def log(msg):
    """Print log message with timestamp"""
    print(f"[db.py] {msg}", file=sys.stderr)

def execute(sql):
    start_total = time.time()

    if not DATABASE_URL:
        print("ERROR: DATABASE_URL not set")
        sys.exit(1)

    # Connect
    log("Connecting to database...")
    conn_start = time.time()
    try:
        conn = psycopg2.connect(DATABASE_URL, connect_timeout=10)
        log(f"Connected in {time.time() - conn_start:.2f}s")
    except Exception as e:
        log(f"Connection failed after {time.time() - conn_start:.2f}s")
        print(f"ERROR: Connection failed: {e}")
        sys.exit(1)

    cur = conn.cursor()

    try:
        # Execute query
        log(f"Executing: {sql[:100]}{'...' if len(sql) > 100 else ''}")
        exec_start = time.time()
        cur.execute(sql)
        exec_time = time.time() - exec_start
        log(f"Query executed in {exec_time:.2f}s")

        # Detect if it's a write operation (INSERT/UPDATE/DELETE/ALTER/CREATE/DROP/DO)
        sql_upper = sql.strip().upper()
        is_write = sql_upper.startswith(('INSERT', 'UPDATE', 'DELETE', 'ALTER', 'CREATE', 'DROP', 'DO'))

        # Always commit for write operations (even with RETURNING)
        if is_write:
            conn.commit()
            log(f"Committed. Rows affected: {cur.rowcount}")

        # Check if query returns data (SELECT or RETURNING)
        if cur.description:
            rows = cur.fetchall()
            colnames = [desc[0] for desc in cur.description]
            log(f"Fetched {len(rows)} rows")

            if not rows:
                print("No results")
                return

            # Print as JSON
            results = []
            for row in rows:
                row_dict = {}
                for i, col in enumerate(colnames):
                    val = row[i]
                    if val is None:
                        row_dict[col] = None
                    elif isinstance(val, (int, float, bool)):
                        row_dict[col] = val
                    else:
                        row_dict[col] = str(val)
                results.append(row_dict)

            print(json.dumps(results, indent=2, ensure_ascii=False))
        elif not is_write:
            # Non-write query with no results
            print("No results")

    except Exception as e:
        conn.rollback()
        log(f"Error: {e}")
        print(f"ERROR: {e}")
    finally:
        cur.close()
        conn.close()
        log(f"Total time: {time.time() - start_total:.2f}s")

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return

    sql = " ".join(sys.argv[1:])
    execute(sql)

if __name__ == "__main__":
    main()
