import snowflake.connector
import os
import sys
import argparse
from pathlib import Path

def get_connection():
    return snowflake.connector.connect(
        account=os.environ['SNOWFLAKE_ACCOUNT'],
        user=os.environ['SNOWFLAKE_USER'],
        password=os.environ['SNOWFLAKE_PASSWORD'],
        role=os.environ.get('SNOWFLAKE_ROLE', 'ACCOUNTADMIN'),
        warehouse=os.environ.get('SNOWFLAKE_WAREHOUSE', 'COMPUTE_WH')
    )

def execute_sql_file(conn, filepath):
    print(f"Executing: {filepath}")
    with open(filepath, 'r') as f:
        sql_content = f.read()
    
    statements = [s.strip() for s in sql_content.split(';') if s.strip()]
    
    cursor = conn.cursor()
    try:
        for stmt in statements:
            if stmt and not stmt.startswith('--'):
                print(f"  Running statement...")
                cursor.execute(stmt)
        print(f"✅ Successfully executed: {filepath}")
        return True
    except Exception as e:
        print(f"❌ Error in {filepath}: {str(e)}")
        return False
    finally:
        cursor.close()

def deploy_all(conn, env='prod'):
    deploy_order = [
        'SNOWFLAKE SQL/account_admin/account_setup.sql',
        'SNOWFLAKE SQL/warehouses/warehouse_setup.sql',
        'SNOWFLAKE SQL/databases/database_setup.sql',
        'SNOWFLAKE SQL/rbac/rbac_roles.sql',
        'SNOWFLAKE SQL/governance/masking_policies.sql',
        'SNOWFLAKE SQL/medallion/bronze_layer.sql',
        'SNOWFLAKE SQL/ai_ready/ai_feature_views.sql',
        'SNOWFLAKE SQL/monitoring/monitoring_queries.sql',
        'SNOWFLAKE SQL/ai_ready/alerts/alert_tasks.sql',
        'SNOWFLAKE SQL/audit/audit_queries.sql',
        'SNOWFLAKE SQL/ci_cd/ci_cd_framework.sql',
        'SNOWFLAKE SQL/verification/validation_checks.sql',
    ]
    
    success_count = 0
    fail_count = 0
    
    for script in deploy_order:
        if Path(script).exists():
            if execute_sql_file(conn, script):
                success_count += 1
            else:
                fail_count += 1
        else:
            print(f"⚠️ Script not found: {script}")
    
    print(f"\n📊 Deployment Summary: {success_count} succeeded, {fail_count} failed")
    return fail_count == 0

def main():
    parser = argparse.ArgumentParser(description='Deploy Snowflake SQL scripts')
    parser.add_argument('--env', default='prod', help='Environment (dev/prod)')
    parser.add_argument('--script', help='Single script to deploy')
    args = parser.parse_args()
    
    conn = get_connection()
    
    try:
        if args.script:
            success = execute_sql_file(conn, args.script)
        else:
            success = deploy_all(conn, args.env)
        
        sys.exit(0 if success else 1)
    finally:
        conn.close()

if __name__ == '__main__':
    main()
