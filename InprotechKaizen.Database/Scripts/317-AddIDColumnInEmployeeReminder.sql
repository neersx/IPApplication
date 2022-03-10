/** DR-68344 Add column EMPLOYEEREMINDER.ID	**/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'EMPLOYEEREMINDER' AND COLUMN_NAME = 'ID')
    BEGIN
	PRINT '**** DR-68344 Adding column EMPLOYEEREMINDER.ID'
	ALTER TABLE EMPLOYEEREMINDER ADD ID bigint IDENTITY ( 1,1 ) NOT FOR REPLICATION  NOT NULL
	PRINT '**** DR-68344 Column EMPLOYEEREMINDER.ID added'
	PRINT '**** DR-68344 Rebuilding all the indexes on EMPLOYEEREMINDER table'
	ALTER INDEX ALL ON EMPLOYEEREMINDER REBUILD
END
ELSE
    BEGIN
	PRINT '**** DR-68344 Column EMPLOYEEREMINDER.ID exists already'
END
GO


/*** DR-68344 Genarating audit triggers ***/

IF dbo.fn_IsAuditSchemaConsistent('EMPLOYEEREMINDER') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'EMPLOYEEREMINDER'
END
GO