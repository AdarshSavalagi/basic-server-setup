#!/bin/bash
# =============================================================================
# PostgreSQL Docker Backup Script
# =============================================================================
# Backs up all databases in a running PostgreSQL Docker container,
# stores them as compressed .sql.gz files, and purges backups older
# than RETENTION_DAYS.
#
# Cron example (runs daily at 2:00 AM):
#   0 2 * * * /home/gh-actions/pg_backup.sh >> /home/gh-actions/pg_backup.log 2>&1
# =============================================================================

# ──────────────────────────────────────────────
# CONFIGURATION  (edit these as needed)
# ──────────────────────────────────────────────
CONTAINER_NAME="postgres-db"          # Docker container name or ID
BACKUP_DIR="/home/gh-actions/pg_backups"  # Directory to store backups
RETENTION_DAYS=10                     # Delete backups older than this many days
POSTGRES_USER="postgres"              # PostgreSQL superuser inside the container
# Leave POSTGRES_PASSWORD empty if the container uses trust auth or a .pgpass file
POSTGRES_PASSWORD=""

# Databases to SKIP (space-separated). template0/template1 are always skipped.
EXCLUDE_DBS="template0 template1"

# Compress backups? (yes/no)
COMPRESS="yes"

# Timestamp format used in filenames
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DATE_LABEL=$(date +"%Y-%m-%d")
# ──────────────────────────────────────────────

# ── Helpers ───────────────────────────────────
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() { log "ERROR: $*"; exit 1; }

# ── Pre-flight checks ─────────────────────────
command -v docker &>/dev/null || fail "docker not found in PATH"

docker inspect "$CONTAINER_NAME" &>/dev/null \
  || fail "Container '$CONTAINER_NAME' does not exist"

docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME" | grep -q true \
  || fail "Container '$CONTAINER_NAME' is not running"

# ── Prepare backup directory ──────────────────
mkdir -p "$BACKUP_DIR" || fail "Cannot create backup directory: $BACKUP_DIR"

# ── Optional: pass password via env var ───────
DOCKER_ENV_ARGS=()
if [[ -n "$POSTGRES_PASSWORD" ]]; then
  DOCKER_ENV_ARGS=(-e "PGPASSWORD=$POSTGRES_PASSWORD")
fi

# ── Fetch database list ───────────────────────
log "Fetching database list from container '$CONTAINER_NAME'..."

DB_LIST=$(docker exec "${DOCKER_ENV_ARGS[@]}" "$CONTAINER_NAME" \
  psql -U "$POSTGRES_USER" -At \
  -c "SELECT datname FROM pg_database WHERE datistemplate = false;") \
  || fail "Could not connect to PostgreSQL inside the container"

if [[ -z "$DB_LIST" ]]; then
  log "No databases found. Exiting."
  exit 0
fi

# ── Backup loop ───────────────────────────────
SUCCESS_COUNT=0
FAIL_COUNT=0

for DB in $DB_LIST; do
  # Skip excluded databases
  if echo "$EXCLUDE_DBS" | grep -qw "$DB"; then
    log "Skipping excluded database: $DB"
    continue
  fi

  log "Backing up database: $DB"

  # Sub-directory per database keeps things tidy
  DB_DIR="$BACKUP_DIR/$DB"
  mkdir -p "$DB_DIR"

  BASE_FILE="$DB_DIR/${DB}_${TIMESTAMP}"

  if [[ "$COMPRESS" == "yes" ]]; then
    OUTFILE="${BASE_FILE}.sql.gz"
    docker exec "${DOCKER_ENV_ARGS[@]}" "$CONTAINER_NAME" \
      pg_dump -U "$POSTGRES_USER" --format=plain "$DB" \
      | gzip -9 > "$OUTFILE"
    DUMP_STATUS=${PIPESTATUS[0]}
  else
    OUTFILE="${BASE_FILE}.sql"
    docker exec "${DOCKER_ENV_ARGS[@]}" "$CONTAINER_NAME" \
      pg_dump -U "$POSTGRES_USER" --format=plain "$DB" \
      > "$OUTFILE"
    DUMP_STATUS=$?
  fi

  if [[ $DUMP_STATUS -eq 0 && -s "$OUTFILE" ]]; then
    SIZE=$(du -sh "$OUTFILE" | cut -f1)
    log "  ✓ Saved: $OUTFILE ($SIZE)"
    (( SUCCESS_COUNT++ ))
  else
    log "  ✗ FAILED: pg_dump returned exit code $DUMP_STATUS for '$DB'"
    rm -f "$OUTFILE"   # remove empty/partial file
    (( FAIL_COUNT++ ))
  fi
done

# ── Purge old backups ─────────────────────────
log "Purging backups older than $RETENTION_DAYS days in $BACKUP_DIR..."

DELETED=$(find "$BACKUP_DIR" \
  -type f \( -name "*.sql" -o -name "*.sql.gz" \) \
  -mtime +"$RETENTION_DAYS" \
  -print -delete 2>&1)

if [[ -n "$DELETED" ]]; then
  echo "$DELETED" | while IFS= read -r f; do
    log "  Deleted: $f"
  done
else
  log "  Nothing to purge."
fi

# Also remove empty subdirectories left behind after purge
find "$BACKUP_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null

# ── Summary ───────────────────────────────────
log "─────────────────────────────────────────"
log "Backup complete. Success: $SUCCESS_COUNT | Failed: $FAIL_COUNT"
log "Storage location: $BACKUP_DIR"
log "─────────────────────────────────────────"

[[ $FAIL_COUNT -gt 0 ]] && exit 1
exit 0
