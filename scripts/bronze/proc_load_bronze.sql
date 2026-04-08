-- criando procedimento para deixar tudo salvo e de rápido execução
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @start_wholetable_time DATETIME, @end_wholetable_time DATETIME;
	BEGIN TRY   -- Testar se dá erro no procedimento

		SET @start_wholetable_time = GETDATE()

		PRINT '=================================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '=================================================================';

		PRINT '------------------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_cust_info  -- DEIXAR A TABELA VAZIA ANTES DE CARREGAR OS DADOS (JÁ TAVA, MAS POR PRECAUÇÃO)

		BULK INSERT bronze.crm_cust_info
		FROM 'C:\Users\thais\OneDrive\Documentos\SQL Cursos\SQL data warehouse project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		-- deve-se pegar integralmente o caminho do arquivo, lembrar de add no fim o nome do arquivo, que não vem junto automaticamente
		WITH(
			FIRSTROW = 2,  -- Pra dizer que a 1 linha da tabela é a 2 linha do arquivo, pois a 1º é só os nome das colunas
			FIELDTERMINATOR = ',',  -- dizer o delimitador de cada celula
			TABLOCK  -- alguma coisa pra melhorar a performance, deve ser desnecessário
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_prd_info

		BULK INSERT bronze.crm_prd_info
		FROM 'C:\Users\thais\OneDrive\Documentos\SQL Cursos\SQL data warehouse project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
	
		WITH(
			FIRSTROW = 2,  
			FIELDTERMINATOR = ',',  
			TABLOCK  
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.crm_sales_details

		BULK INSERT bronze.crm_sales_details
		FROM 'C:\Users\thais\OneDrive\Documentos\SQL Cursos\SQL data warehouse project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
	
		WITH(
			FIRSTROW = 2,  
			FIELDTERMINATOR = ',',  
			TABLOCK  
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------------------------------';

		PRINT '------------------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_cust_az12

		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\Users\thais\OneDrive\Documentos\SQL Cursos\SQL data warehouse project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
	
		WITH(
			FIRSTROW = 2,  
			FIELDTERMINATOR = ',', 
			TABLOCK  
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_loc_a101

		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\Users\thais\OneDrive\Documentos\SQL Cursos\SQL data warehouse project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
	
		WITH(
			FIRSTROW = 2,  
			FIELDTERMINATOR = ',',  
			TABLOCK  
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------------------------------';

		SET @start_time = GETDATE();
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\Users\thais\OneDrive\Documentos\SQL Cursos\SQL data warehouse project\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
	
		WITH(
			FIRSTROW = 2,  
			FIELDTERMINATOR = ',', 
			TABLOCK  
		);
		SET @end_time = GETDATE();

		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-----------------------------------------------------------';

		SET @end_wholetable_time = GETDATE()

		PRINT '**************************';
		PRINT 'Total Duration of all the tables loads: ' + CAST(DATEDIFF(second,@start_wholetable_time,@end_wholetable_time) AS NVARCHAR) + ' seconds';

	END TRY

	BEGIN CATCH   -- Se for identificado erro, vai executar isso
			PRINT '=================================================================';
			PRINT 'ERROR OCURRED DURING LOADING BRONZE LAYER';
			PRINT 'Error Message' + ERROR_MESSAGE();
			PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
			PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
			PRINT '=================================================================';
	END CATCH
END

EXEC bronze.load_bronze
