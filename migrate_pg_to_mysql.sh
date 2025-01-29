#!/bin/bash

# Set variables for database credentials
PG_USER="postgres_user"
PG_DB="your_postgres_db"
PG_HOST="localhost"
PG_PORT="5432"
PG_PASSWORD="your_postgres_password"

MYSQL_USER="mysql_user"
MYSQL_DB="your_mysql_db"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_PASSWORD="your_mysql_password"

# Directory for exporting and processing
EXPORT_DIR="./export"
mkdir -p $EXPORT_DIR

# Set environment variables for PostgreSQL
export PGPASSWORD=$PG_PASSWORD

# 1. Export PostgreSQL schema and data to SQL
echo "Exporting PostgreSQL schema and data..."
pg_dump --username=$PG_USER --dbname=$PG_DB --no-owner --no-comments --no-tablespaces --format=p --file=$EXPORT_DIR/pg_dump.sql

# 2. Convert PostgreSQL schema to MySQL-compatible schema
echo "Converting PostgreSQL schema to MySQL format..."
sed -e 's/ SERIAL / INT AUTO_INCREMENT /g' \
    -e 's/TIMESTAMPTZ/DATETIME/g' \
    -e 's/BOOLEAN/TINYINT(1)/g' \
    -e 's/CREATE SEQUENCE.*//g' \
    -e 's/OWNER TO.*//g' \
    -e 's/PUBLIC\./\`/g' \
    -e 's/^\(CREATE TABLE.*\)/\1 ENGINE=InnoDB;/g' \
    -e 's/^\(.*COMMENT ON COLUMN.*\)/-- \1/g' \
    $EXPORT_DIR/pg_dump.sql > $EXPORT_DIR/mysql_dump.sql

# 3. Create MySQL database if it doesn't exist
echo "Creating MySQL database..."
mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST --port=$MYSQL_PORT -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"

# 4. Import MySQL schema (table structure)
echo "Importing MySQL schema..."
mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST --port=$MYSQL_PORT $MYSQL_DB < $EXPORT_DIR/mysql_dump.sql

# 5. Export data from PostgreSQL to CSV (for each table)
echo "Exporting data from PostgreSQL to CSV..."
TABLES=$(psql -U $PG_USER -d $PG_DB -h $PG_HOST -p $PG_PORT -t -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")

for table in $TABLES; do
    echo "Exporting data for table: $table"
    psql -U $PG_USER -d $PG_DB -h $PG_HOST -p $PG_PORT -c "\COPY $table TO '$EXPORT_DIR/$table.csv' DELIMITER ',' CSV HEADER;"
done

# 6. Import data into MySQL
echo "Importing data into MySQL..."

for table in $TABLES; do
    echo "Importing data for table: $table"
    mysql --user=$MYSQL_USER --password=$MYSQL_PASSWORD --host=$MYSQL_HOST --port=$MYSQL_PORT $MYSQL_DB -e "LOAD DATA LOCAL INFILE '$EXPORT_DIR/$table.csv' INTO TABLE \`$table\` FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;"
done

# Clean up exported files (optional)
echo "Cleaning up export files..."
rm -rf $EXPORT_DIR

echo "Migration complete!"
