-- criando procedimento para deixar tudo salvo e de rápido execução
CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	
	PRINT '>> Truncasting Table: silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	PRINT '>> Inserting Data Into: silver.crm_cust_info';
	INSERT INTO silver.crm_cust_info(
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
	TRIM(cst_firstname) as cst_firstname ,
	TRIM(cst_lastname) as cst_lastname,
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
	ELSE 'n/a' END as cst_marital_status
	,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	ELSE 'n/a' END as cst_gndr,
	cst_create_date
	FROM (SELECT  -- Aqui é o filtro inicial da primary key não ter duplicatas e nem vazios
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
	)t WHERE flag_last = 1

	-- ###########################################################################################
	-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ANOTHER TABLE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	-- ###########################################################################################

	PRINT '>> Truncasting Table: silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	PRINT '>> Inserting Data Into: silver.crm_prd_info';
	INSERT INTO silver.crm_prd_info(
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
	REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
	SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key,
	prd_nm,
	ISNULL(prd_cost, 0) prd_cost,
	CASE WHEN UPPER(TRIM(prd_line))='M' THEN 'Mountain'
	WHEN UPPER(TRIM(prd_line))='R' THEN 'Road'
	WHEN UPPER(TRIM(prd_line))='S' THEN 'Other Sales'
	WHEN UPPER(TRIM(prd_line))='T' THEN 'Touring'
	ELSE 'N/A' END as prd_line,
	prd_start_dt,
	LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) AS prd_end_dt
	FROM bronze.crm_prd_info

	-- ###########################################################################################
	-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ANOTHER TABLE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	-- ###########################################################################################

	PRINT '>> Truncasting Table: silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	PRINT '>> Inserting Data Into: silver.crm_sales_details'
	INSERT INTO silver.crm_sales_details(
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
	CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt)!=8 THEN NULL
		ELSE CAST(CAST(sls_order_dt as VARCHAR) as DATE) -- No SQL não dá pra converter INT pra Date direto... tem que converter pra VARCHAR antes, e só depois pra data
	END as sls_order_dt,
	CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt)!=8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt as VARCHAR) as DATE)
		END as sls_ship_dt,
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt)!=8 THEN NULL
		ELSE CAST(CAST(sls_due_dt as VARCHAR) as DATE)
		END as sls_due_dt,
	CASE WHEN sls_sales IS NULL AND sls_price>0 OR sls_sales<=0 AND sls_price>0 OR sls_sales!=sls_quantity*sls_price AND sls_price>0 THEN sls_quantity*sls_price
	WHEN sls_sales IS NULL AND sls_price<0 OR sls_sales<=0 AND sls_price<0 OR sls_sales!=sls_quantity*sls_price AND sls_price<0 THEN sls_quantity*sls_price*(-1)
		ELSE sls_sales END as sls_sales,
	sls_quantity,
	CASE WHEN sls_price IS NULL OR sls_price=0 THEN sls_sales/sls_quantity
	WHEN sls_price < 0 THEN ABS(sls_price)  
		ELSE sls_price END as sls_price
	FROM bronze.crm_sales_details

	-- ###########################################################################################
	-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ANOTHER TABLE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	-- ###########################################################################################

	PRINT '>> Truncasting Table: silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	PRINT '>> Inserting Data Into: silver.erp_cust_az12';
	INSERT INTO silver.erp_cust_az12(
	cid,
	bdate,
	gen)
	SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
		ELSE cid END as cid,
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate END as bdate,
	CASE WHEN TRIM(UPPER(gen))='M' THEN 'Male'
		WHEN TRIM(UPPER(gen))='F' THEN 'Female'
		WHEN gen = '' OR gen IS NULL THEN 'N/A'
		ELSE gen END as gen
	FROM bronze.erp_cust_az12

	-- ###########################################################################################
	-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ANOTHER TABLE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	-- ###########################################################################################

	PRINT '>> Truncasting Table: silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
	PRINT '>> Inserting Data Into: silver.erp_loc_a101';
	INSERT INTO silver.erp_loc_a101 (cid,cntry)
	SELECT
	REPLACE(cid,'-','') cid,
	CASE 
		WHEN cntry IN ('USA','US') THEN 'United States'
		WHEN cntry = 'DE' THEN 'Germany'
		WHEN cntry = '' OR cntry IS NULL THEN 'N/A'
		ELSE cntry END as cntry
	FROM bronze.erp_loc_a101

	-- ###########################################################################################
	-- @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ANOTHER TABLE @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	-- ###########################################################################################

	PRINT '>> Truncasting Table: silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2';
	INSERT INTO silver.erp_px_cat_g1v2 (id,
	cat,
	subcat,
	maintenance)
	SELECT
	id,
	cat,
	subcat,
	maintenance
	FROM bronze.erp_px_cat_g1v2

END

EXEC silver.load_silver
