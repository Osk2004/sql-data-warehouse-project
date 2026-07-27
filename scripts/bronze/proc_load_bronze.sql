--exec bronze.load_bronze
--drop PROCEDURE bronze.load_bronze

use DataWarehouse;
GO
CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    DECLARE @start_time DATETIME,
            @end_time   DATETIME;

    BEGIN TRY

        PRINT '=====================================================';
        PRINT '        STARTING BRONZE LAYER DATA LOADING';
        PRINT '=====================================================';
set @start_time=GETDATE();
    /*=========================================================
        STEP 1 : LOAD CRM CUSTOMER INFORMATION
    =========================================================*/

        PRINT '';
        PRINT 'Loading CRM Customer Information...';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_cust_info;

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\Mohit kulthe\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'CRM Customer Information Loaded Successfully.';
        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';


    /*=========================================================
        STEP 2 : LOAD CRM PRODUCT INFORMATION
    =========================================================*/

        PRINT '';
        PRINT 'Loading CRM Product Information...';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_prd_info;

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\Mohit kulthe\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'CRM Product Information Loaded Successfully.';
        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';


    /*=========================================================
        STEP 3 : LOAD CRM SALES DETAILS
    =========================================================*/

        PRINT '';
        PRINT 'Loading CRM Sales Details...';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_sales_details;

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\Mohit kulthe\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'CRM Sales Details Loaded Successfully.';
        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';


    /*=========================================================
        STEP 4 : LOAD ERP CUSTOMER INFORMATION
    =========================================================*/

        PRINT '';
        PRINT 'Loading ERP Customer Information...';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_cust_az12;

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\Mohit kulthe\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'ERP Customer Information Loaded Successfully.';
        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';


    /*=========================================================
        STEP 5 : LOAD ERP LOCATION INFORMATION
    =========================================================*/

        PRINT '';
        PRINT 'Loading ERP Location Information...';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_loc_a101;

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\Mohit kulthe\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'ERP Location Information Loaded Successfully.';
        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';


    /*=========================================================
        STEP 6 : LOAD ERP PRODUCT CATEGORY INFORMATION
    =========================================================*/

        PRINT '';
        PRINT 'Loading ERP Product Category Information...';

        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\Mohit kulthe\Downloads\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH
        (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT 'ERP Product Category Information Loaded Successfully.';
        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';

        PRINT '';
        PRINT '=====================================================';
        PRINT 'BRONZE LAYER DATA LOADING COMPLETED SUCCESSFULLY';
        PRINT '=====================================================';
        set @end_time=GETDATE();

        PRINT 'Load Duration : '
            + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR(10))
            + ' Seconds';

    END TRY

    BEGIN CATCH

        PRINT '';
        PRINT '=====================================================';
        PRINT 'ERROR OCCURRED DURING BRONZE DATA LOADING';
        PRINT '=====================================================';
        PRINT 'Error Message : ' + ERROR_MESSAGE();
        PRINT 'Error Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR(10));
        PRINT 'Error State   : ' + CAST(ERROR_STATE() AS NVARCHAR(10));
        PRINT '=====================================================';

    END CATCH

END;
GO
