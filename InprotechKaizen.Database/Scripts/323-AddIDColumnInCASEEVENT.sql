/*****************************************************************************************/
/*** DR-73154 Add column CASEEVENT.ID ***/
/*****************************************************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CASEEVENT' AND COLUMN_NAME = 'ID')
    BEGIN
	PRINT '**** DR-73154 Adding column CASEEVENT.ID'
	ALTER TABLE CASEEVENT ADD ID bigint IDENTITY ( 1,1 ) NOT FOR REPLICATION  NOT NULL
	PRINT '**** DR-73154 Column CASEEVENT.ID added'
	PRINT '**** DR-73154 Rebuilding all the indexes on CASEEVENT table'
	ALTER INDEX ALL ON CASEEVENT REBUILD
END
ELSE
    BEGIN
	PRINT '**** DR-73154 Column CASEEVENT.ID exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('CASEEVENT') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'CASEEVENT'
END
GO