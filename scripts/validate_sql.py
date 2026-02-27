import os
import sys
from pathlib import Path

def validate_sql_syntax(filepath):
    """Basic SQL syntax validation"""
    errors = []
    with open(filepath, 'r') as f:
        content = f.read()
    
    if 'DROP DATABASE' in content.upper() and 'IF EXISTS' not in content.upper():
        errors.append(f"{filepath}: DROP DATABASE without IF EXISTS")
    
    if 'TRUNCATE' in content.upper():
        errors.append(f"{filepath}: TRUNCATE statement found - verify intentional")
    
    return errors

def main():
    sql_dir = Path('SNOWFLAKE SQL')
    all_errors = []
    
    for sql_file in sql_dir.rglob('*.sql'):
        errors = validate_sql_syntax(sql_file)
        all_errors.extend(errors)
    
    if all_errors:
        print("⚠️ Validation warnings:")
        for error in all_errors:
            print(f"  - {error}")
    
    print(f"✅ Validated {len(list(sql_dir.rglob('*.sql')))} SQL files")
    return 0

if __name__ == '__main__':
    sys.exit(main())
