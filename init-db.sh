#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 \
     -v isg_user="${ISG_DB_USER}" \
     -v isg_password="${ISG_DB_PASSWORD}" \
     -v isg_db="${POSTGRES_DB}" \
     --username "postgres" --dbname "${POSTGRES_DB}" <<-'EOSQL'
    CREATE ROLE :"isg_user" WITH LOGIN PASSWORD :'isg_password';
    ALTER DATABASE :"isg_db" OWNER TO :"isg_user";
    ALTER SCHEMA public OWNER TO :"isg_user";
EOSQL
