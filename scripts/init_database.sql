/*===============================================================
  PROJECT      : Data Warehouse
  DATABASE     : DataWarehouse
  ARCHITECTURE : Medallion Architecture
                 Bronze → Silver → Gold
  AUTHOR       : Om Suresh Kulthe (Data Analyst)

  DESCRIPTION
  ---------------------------------------------------------------
  This script creates a Data Warehouse database using the
  Medallion Architecture. It initializes three schemas:

  • Bronze : Raw data from source systems
  • Silver : Cleaned and transformed data
  • Gold   : Business-ready data for reporting and analytics

  This serves as the foundation for ETL/ELT pipelines and
  Business Intelligence solutions.
===============================================================*/

---------------------------------------------------------------
-- Step 1 : Drop Existing Database (Optional)
---------------------------------------------------------------
DROP DATABASE IF EXISTS DataWarehouse;

---------------------------------------------------------------
-- Step 2 : Create Database
---------------------------------------------------------------
CREATE DATABASE DataWarehouse;

---------------------------------------------------------------
-- Step 3 : Select Database
---------------------------------------------------------------
USE DataWarehouse;

---------------------------------------------------------------
-- Step 4 : Create Medallion Schemas
---------------------------------------------------------------
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
