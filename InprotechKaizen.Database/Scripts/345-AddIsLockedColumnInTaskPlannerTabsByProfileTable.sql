/****************************************************************************/
/******** DR-76096 Add column TASKPLANNERTABSBYPROFILE.ISLOCKED *************/
/****************************************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TASKPLANNERTABSBYPROFILE' AND COLUMN_NAME = 'ISLOCKED')
    BEGIN
	PRINT '**** DR-76096 Adding column TASKPLANNERTABSBYPROFILE.ISLOCKED'
	ALTER TABLE TASKPLANNERTABSBYPROFILE ADD ISLOCKED bit NOT NULL DEFAULT 0
	PRINT '**** DR-76096 Column TASKPLANNERTABSBYPROFILE.ISLOCKED added'
	PRINT ''
END
ELSE
    BEGIN
	PRINT '**** DR-76096 Column TASKPLANNERTABSBYPROFILE.ISLOCKED exists already'
	PRINT ''
END
GO

IF dbo.fn_IsAuditSchemaConsistent('TASKPLANNERTABSBYPROFILE') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'TASKPLANNERTABSBYPROFILE'
END
GO