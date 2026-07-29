/*===============================================================================
    SILVER LAYER ETL PROCESS
    ===============================================================================
    Purpose:
    Transform raw data from the Bronze layer into clean, standardized, and
    validated data for the Silver layer.

    ETL Steps:
    1. Truncate the target table.
    2. Load transformed data from the Bronze layer.
    3. Apply data cleaning and business rules.
    4. Store clean, consistent data in the Silver layer.

    Benefits:
    • Remove duplicate records
    • Standardize data formats
    • Handle missing and invalid values
    • Improve data quality
    • Prepare data for the Gold Layer
================================================================================*/

USE DataWarehouse;
GO
exec silver.load_silver;

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '===============================================================================';
        PRINT 'Loading Silver Layer';
        PRINT '===============================================================================';

        PRINT '------------------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '------------------------------------------------';

        /*===============================================================================
            TABLE: silver.crm_cust_info
            SOURCE: bronze.crm_cust_info

            Purpose:
            Clean and standardize customer master data.

            Transformations:
            • Keep only the latest customer record
            • Remove duplicate customers
            • Remove leading/trailing spaces
            • Standardize marital status
            • Standardize gender
            • Exclude records with NULL customer IDs
        ================================================================================*/
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Loading Data: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info
        (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname),
            TRIM(cst_lastname),

            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'N/A'
            END,

            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'N/A'
            END,

            cst_create_date

        FROM
        (
            SELECT *,
                   ROW_NUMBER() OVER
                   (
                        PARTITION BY cst_id
                        ORDER BY cst_create_date DESC
                   ) AS last_flag
            FROM bronze.crm_cust_info
        ) t
        WHERE last_flag = 1
        AND cst_id IS NOT NULL;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        /*===============================================================================
            TABLE: silver.crm_prd_info
            SOURCE: bronze.crm_prd_info

            Purpose:
            Clean and standardize product information.

            Transformations:
            • Extract Category ID
            • Extract Product Key
            • Replace NULL product cost with 0
            • Standardize Product Line
            • Convert dates
            • Calculate Product End Date
        ================================================================================*/
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Loading Data: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info
        (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            prd_id,

            REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,

            SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,

            prd_nm,

            ISNULL(prd_cost,0) AS prd_cost,

            CASE
                WHEN UPPER(TRIM(prd_line))='M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line))='R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
                WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
                ELSE 'N/A'
            END,

            CAST(prd_start_dt AS DATE),

            CAST(
                LEAD(prd_start_dt)
                OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1
                AS DATE
            )

        FROM bronze.crm_prd_info;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        /*===============================================================================
            TABLE: silver.crm_sales_details
            SOURCE: bronze.crm_sales_details

            Purpose:
            Clean sales transaction data.

            Transformations:
            • Validate Order Date
            • Validate Ship Date
            • Validate Due Date
            • Correct Sales Amount
            • Correct Product Price
        ================================================================================*/
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Loading Data: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details
        (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT

            sls_ord_num,
            sls_prd_key,
            sls_cust_id,

            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) <> 8
                THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END,

            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) <> 8
                THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END,

            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) <> 8
                THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END,

            CASE
                WHEN sls_sales IS NULL
                     OR sls_sales <= 0
                     OR sls_sales <> sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END,

            sls_quantity,

            CASE
                WHEN sls_price IS NULL
                     OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity,0)
                ELSE sls_price
            END

        FROM bronze.crm_sales_details;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        PRINT '------------------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '------------------------------------------------';

        /*===============================================================================
            TABLE: silver.erp_cust_az12
            SOURCE: bronze.erp_cust_az12

            Purpose:
            Clean ERP customer information.

            Transformations:
            • Remove NAS prefix
            • Validate Birth Date
            • Standardize Gender
        ================================================================================*/
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Loading Data: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12
        (
            cid,
            bdate,
            gen
        )
        SELECT

            CASE
                WHEN cid LIKE 'NAS%'
                THEN SUBSTRING(cid,4,LEN(cid))
                ELSE cid
            END,

            CASE
                WHEN bdate > GETDATE()
                THEN NULL
                ELSE bdate
            END,

            CASE
                WHEN UPPER(TRIM(gen)) IN ('M','MALE')
                THEN 'Male'

                WHEN UPPER(TRIM(gen)) IN ('F','FEMALE')
                THEN 'Female'

                ELSE 'N/A'
            END

        FROM bronze.erp_cust_az12;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        /*===============================================================================
            TABLE: silver.erp_px_cat_g1v2
            SOURCE: bronze.erp_px_cat_g1v2

            Purpose:
            Load ERP Product Category data.

            Transformations:
            • No transformation required
        ================================================================================*/
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Loading Data: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2
        (
            id,
            cat,
            maintenance
        )
        SELECT
            id,
            cat,
            maintenance

        FROM bronze.erp_px_cat_g1v2;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        /*===============================================================================
            TABLE: silver.erp_loc_a101
            SOURCE: bronze.erp_loc_a101

            Purpose:
            Clean customer location data.

            Transformations:
            • Remove hyphens from Customer ID
            • Remove spaces
            • Standardize Country Names
            • Replace NULL or Blank Country with N/A
        ================================================================================*/
        SET @start_time = GETDATE();
        PRINT '>> Truncating Table: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Loading Data: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101
        (
            cid,
            cntry
        )
        SELECT

            REPLACE(TRIM(cid),'-','') AS cid,

            CASE
                WHEN UPPER(TRIM(cntry)) = 'DE'
                    THEN 'Germany'

                WHEN UPPER(TRIM(cntry)) IN ('US','USA')
                    THEN 'United States'

                WHEN TRIM(cntry) = ''
                     OR cntry IS NULL
                    THEN 'N/A'

                ELSE cntry
            END

        FROM bronze.erp_loc_a101;
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> -------------';

        SET @batch_end_time = GETDATE();
        PRINT '===============================================================================';
        PRINT 'Silver Layer ETL Completed Successfully';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '===============================================================================';

    END TRY
    BEGIN CATCH
        PRINT '===============================================================================';
        PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '===============================================================================';
    END CATCH
END
GO
