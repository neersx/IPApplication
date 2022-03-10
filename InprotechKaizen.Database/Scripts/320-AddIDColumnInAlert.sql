/*****************************************************************************************/
/*** DR-68368 Add column ALERT.ID ***/
/*****************************************************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ALERT' AND COLUMN_NAME = 'ID')
    BEGIN
	PRINT '**** DR-68368 Adding column ALERT.ID'
	ALTER TABLE ALERT ADD ID bigint IDENTITY ( 1,1 ) NOT FOR REPLICATION  NOT NULL
	PRINT '**** DR-68368 Column ALERT.ID added'
	PRINT '**** DR-68368 Rebuilding all the indexes on ALERT table'
	ALTER INDEX ALL ON ALERT REBUILD
END
ELSE
    BEGIN
	PRINT '**** DR-68368 Column ALERT.ID exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('ALERT') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'ALERT'
END
GO