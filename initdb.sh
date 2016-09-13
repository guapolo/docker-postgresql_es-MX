#!/bin/bash
set -e

# Init database
mkdir -p "$PG_DATA_DIR" && chown -R postgres "$PG_DATA_DIR"
echo "Initializing database cluster..."
gosu postgres initdb -D $PG_DATA_DIR


# Creation of postgres user, database, accepting no connections
gosu postgres pg_ctl -D "$PG_DATA_DIR" -o "-c listen_addresses=''" -w start
gosu postgres psql -c "ALTER USER $PG_USERNAME WITH SUPERUSER PASSWORD '$PG_PASSWORD';"
gosu postgres pg_ctl -D "$PG_DATA_DIR" -m fast -w stop

{ echo; echo "host all all 0.0.0.0/0 md5"; } >> "$PG_DATA_DIR/pg_hba.conf"
sedEscapedValue="$(echo "*" | sed 's/[\/&]/\\&/g')"
sed -ri "s/^#?(listen_addresses\s*=\s*)\S+/\1'$sedEscapedValue'/" "$PG_DATA_DIR/postgresql.conf"


# Add Postgres to runit
mkdir -p /etc/service/postgres
cat  > /etc/service/postgres/run <<-RUNNER
#!/bin/sh
# Use the exec command to start the app you want to run in this container.
# Don't let the app daemonize itself.
exec /sbin/setuser postgres "$PG_BIN_PATH"/postgres -D "$PG_DATA_DIR"
RUNNER
chmod 700 /etc/service/postgres/run


# Final warning
if [ "$PG_PASSWORD" = 'aSuperSecurePassword' ]; then
cat >&2 <<-'EOWARN'
    *******************************************************************
    ADVERTENCIA: usando contraseña por omisión "aSuperSecurePassword".
    *******************************************************************
EOWARN
fi
