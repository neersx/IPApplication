/****************************************************************************/
/************** DR-76633 Add column DIARY.TIMERSTARTED **********************/
/****************************************************************************/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DIARY' AND COLUMN_NAME = 'TIMERSTARTED')
BEGIN
	PRINT '**** DR-76633 Adding column DIARY.TIMERSTARTED'
	ALTER TABLE DIARY ADD TIMERSTARTED datetime NULL
	PRINT '**** DR-76633 Column DIARY.TIMERSTARTED added'
	PRINT ''
END
ELSE
    BEGIN
	PRINT '**** DR-76633 Column DIARY.TIMERSTARTED already exists'
	PRINT ''
END
GO

IF dbo.fn_IsAuditSchemaConsistent('DIARY') = 0
BEGIN
    EXEC ipu_UtilGenerateAuditTriggers 'DIARY'
END
GO