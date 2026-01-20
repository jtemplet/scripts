import os
import hashlib
import sqlite3
import sys

DB_FILE = 'file_fingerprints.db'
REPORT_FILE = 'duplicate_report.txt'


def compute_sha256(filepath):
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(8192), b''):
            hasher.update(chunk)
    return hasher.hexdigest()


def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS files (
            id INTEGER PRIMARY KEY,
            path TEXT NOT NULL,
            fingerprint TEXT NOT NULL
        )
    ''')
    c.execute('CREATE INDEX IF NOT EXISTS idx_fingerprint ON files(fingerprint)')
    conn.commit()
    return conn


def find_markdown_files(root_dir):
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.lower().endswith('.md'):
                yield os.path.join(dirpath, filename)


def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <directory>")
        sys.exit(1)
    root_dir = sys.argv[1]
    conn = init_db()
    c = conn.cursor()

    # Clear previous entries
    c.execute('DELETE FROM files')
    conn.commit()

    for filepath in find_markdown_files(root_dir):
        try:
            fingerprint = compute_sha256(filepath)
            c.execute('INSERT INTO files (path, fingerprint) VALUES (?, ?)', (filepath, fingerprint))
        except Exception as e:
            print(f"Error processing {filepath}: {e}")
    conn.commit()

    # Find duplicates
    c.execute('''
        SELECT fingerprint, GROUP_CONCAT(path, '\n') as paths, COUNT(*) as cnt
        FROM files
        GROUP BY fingerprint
        HAVING cnt > 1
    ''')
    duplicates = c.fetchall()

    with open(REPORT_FILE, 'w') as report:
        if not duplicates:
            report.write('No duplicate markdown files found.\n')
        else:
            for fingerprint, paths, cnt in duplicates:
                report.write(f"Duplicate group (SHA256: {fingerprint}):\n{paths}\n\n")
    print(f"Duplicate report written to {REPORT_FILE}")
    conn.close()


if __name__ == '__main__':
    main()
