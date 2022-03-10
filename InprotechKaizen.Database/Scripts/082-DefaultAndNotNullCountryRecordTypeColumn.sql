/*** RFC62525 Alter column COUNTRY.RECORDTYPE from null to not null with default value 0***/	
If exists (select 1 from COUNTRY where RECORDTYPE IS NULL)       
BEGIN           
	PRINT '**** RFC62525 Set default RECORDTYPE value in COUNTRY table where RECORDTYPE is null'   
		UPDATE COUNTRY SET RECORDTYPE = 0 where RECORDTYPE IS NULL
	PRINT '**** RFC62525 Data successfully Updated to Status table.'     
	PRINT ''      
END      
go

If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'COUNTRY' AND COLUMN_NAME = 'RECORDTYPE' AND IS_NULLABLE = 'YES')
	BEGIN	
		PRINT '**** RFC62525   Change column COUNTRY.RECORDTYPE to be NOT NULL.'	 
		ALTER TABLE COUNTRY ALTER COLUMN RECORDTYPE nchar(1)  NOT NULL 
		ALTER TABLE COUNTRY ADD DEFAULT 0 FOR RECORDTYPE  		

		PRINT '**** RFC62525  COUNTRY.RECORDTYPE column has been modified.'
	END
	ELSE
	BEGIN
		PRINT '**** RFC62525 COUNTRY.RECORDTYPE already NOT NULLABLE'
		PRINT ''
	END
GO

IF dbo.fn_IsAuditSchemaConsistent('COUNTRY') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'COUNTRY'
END
GO