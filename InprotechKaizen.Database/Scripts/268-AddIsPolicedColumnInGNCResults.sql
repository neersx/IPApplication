/** RFC11355 Add column GLOBALCASECHANGERESULTS.ISPOLICED		**/
If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLOBALCASECHANGERESULTS' AND COLUMN_NAME = 'ISPOLICED')
BEGIN
	
    Declare @sql nvarchar(max)
    SET @Sql = 'PRINT ''**** RFC11355 Adding column GLOBALCASECHANGERESULTS.ISPOLICED''
    ALTER TABLE GLOBALCASECHANGERESULTS ADD ISPOLICED bit  NULL
    PRINT ''**** RFC11355 Column GLOBALCASECHANGERESULTS.ISPOLICED added'''
    exec sp_executesql @Sql	 
END
ELSE
    BEGIN
    PRINT '**** RFC11355 Column GLOBALCASECHANGERESULTS.ISPOLICED exists already'
END

IF dbo.fn_IsAuditSchemaConsistent('GLOBALCASECHANGERESULTS') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'GLOBALCASECHANGERESULTS'
END
GO