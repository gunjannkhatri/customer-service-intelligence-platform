-- =============================================
-- FILE: 01_create_schemas.sql
-- PURPOSE: Create the 3 layer schemas
-- RUN THIS FIRST before any other SQL file
-- =============================================

-- Drop schemas if rebuilding from scratch
-- (Comment these out if running for first time)
-- DROP SCHEMA IF EXISTS gold;
-- DROP SCHEMA IF EXISTS silver;
-- DROP SCHEMA IF EXISTS bronze;
-- DROP SCHEMA IF EXISTS config;

-- Create schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

-- Config schema for pipeline metadata
CREATE SCHEMA config;
GO

PRINT 'All schemas created successfully';