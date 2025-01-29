# migrate-postgres-to-mysql
Use this script to migrate Postgres to MySQL database with Data
PostgreSQL to MySQL Migration Guide
This guide provides instructions on migrating a PostgreSQL database to MySQL, including the necessary steps for exporting the schema, converting it to MySQL format, and importing data.

Prerequisites
Before starting the migration, ensure you have the following:

* PostgreSQL and MySQL installed and accessible on your system.
* PostgreSQL user credentials (pg_user, pg_db, pg_password).
* MySQL user credentials (mysql_user, mysql_db, mysql_password).

Command-line tools: pg_dump, psql, mysql, and mysqlimport should be installed and available in your environment.
Steps for Migration
1. Export PostgreSQL Schema and Data
The first step is to export the schema and data from PostgreSQL.

Using pg_dump to Export Schema and Data:
bash
```
pg_dump --username=postgres --dbname=your_postgres_db --no-owner --no-comments --no-tablespaces --format=p --file=your_postgres_db.sql
```
This command exports the database schema and data from PostgreSQL into a plain SQL file. You will modify this SQL file to make it compatible with MySQL later.

2. Convert PostgreSQL SQL Dump to MySQL-Compatible Format
Once you have the PostgreSQL SQL dump, you'll need to convert it to MySQL-compatible syntax. Here are the key changes that you will need to make manually or using a script:

Change Data Types:
```
SERIAL → INT AUTO_INCREMENT
TIMESTAMPTZ → DATETIME
TEXT → LONGTEXT
BOOLEAN → TINYINT(1)
BYTEA → BLOB
UUID → CHAR(36) or VARCHAR(36)
Remove PostgreSQL-specific syntax:
```
Remove commands like OWNER TO and CREATE SEQUENCE.
Remove PostgreSQL-specific types like SERIAL and replace them with MySQL's AUTO_INCREMENT.
Modify CREATE TABLE statements to include MySQL options:

Add ENGINE=InnoDB; at the end of CREATE TABLE statements for MySQL.
Other Changes:

Replace PUBLIC. schema references with MySQL backticks (`).
Disable any PostgreSQL-specific comments that are not valid in MySQL.
Here’s an example of how a PostgreSQL schema looks and how it should be modified:

PostgreSQL Schema (Sample):
sql
Copy
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
MySQL-Compatible Schema:
sql
Copy
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description LONGTEXT,
    price DECIMAL(10, 2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;
3. Create the MySQL Database
Ensure that the target MySQL database exists. If it doesn't, create it using the following command:

bash
Copy
mysql -u mysql_user -p -e "CREATE DATABASE IF NOT EXISTS your_mysql_db;"
4. Import the MySQL-Compatible Schema
Once the schema is converted, import it into MySQL using the following command:

bash
Copy
mysql -u mysql_user -p your_mysql_db < your_mysql_dump.sql
This command will create the tables in MySQL based on the converted schema from PostgreSQL.

5. Export Data from PostgreSQL in CSV Format
Next, you need to export the data from each table in PostgreSQL into CSV format. This will allow you to import the data into MySQL.

For each table, use the COPY command:

sql
Copy
COPY products TO '/path/to/export/products.csv' DELIMITER ',' CSV HEADER;
You can script this for all tables in the PostgreSQL database. Use the following query to get a list of all tables:

sql
Copy
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
Then, export the data from each table using the COPY command.

6. Import Data into MySQL
Once you have exported the data from PostgreSQL into CSV files, you can import each CSV file into MySQL using the LOAD DATA LOCAL INFILE command.

sql
Copy
LOAD DATA LOCAL INFILE '/path/to/export/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
Repeat this for each table, adjusting the table name and file path accordingly.

7. Adjust for Foreign Keys and Constraints
If you have foreign key constraints, make sure they are properly defined in MySQL after importing the tables. MySQL handles foreign keys differently from PostgreSQL, so you might need to adjust or recreate these constraints in MySQL.

8. Recreate Triggers, Functions, and Views (if applicable)
PostgreSQL and MySQL have different ways of handling stored procedures, functions, and triggers. If your PostgreSQL database uses any of these, you will need to:

Rewrite any stored procedures or functions in MySQL syntax.
Recreate any triggers in MySQL.
Ensure views are converted and work properly in MySQL.
9. Final Steps and Cleanup
Once the schema and data have been successfully migrated, and you've tested everything, you can clean up any exported files (e.g., CSVs, SQL dumps) if you wish.

bash
Copy
rm -rf /path/to/export/
Troubleshooting
Character Encoding: Ensure that the character encoding of both the PostgreSQL and MySQL databases match, especially if you are working with special characters. UTF-8 is commonly used.

Data Type Differences: Some data types in PostgreSQL may require more complex transformations (e.g., BYTEA, UUID). Make sure to adjust these data types manually.

Foreign Keys: MySQL enforces foreign key constraints differently than PostgreSQL, so make sure the foreign keys are properly handled and recreated.

Indexes and Performance: Ensure that indexes and constraints are properly defined in MySQL to match PostgreSQL's performance needs.

Conclusion
Migrating from PostgreSQL to MySQL involves exporting the schema and data, converting the schema to MySQL format, and then importing the data. While this process can be straightforward for simple databases, more complex schemas with foreign keys, triggers, and functions might require additional steps to properly migrate.

By following these steps, you can successfully migrate your PostgreSQL database to MySQL.
