/** DR-52801 Adding column GLOBALCASECHANGERESULTS.CASENAMEREFERENCEUPDATED	**/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLOBALCASECHANGERESULTS'AND COLUMN_NAME = 'CASENAMEREFERENCEUPDATED')
	BEGIN
	PRINT '**** DR-52801 Adding column GLOBALCASECHANGERESULTS.CASENAMEREFERENCEUPDATED'
	ALTER TABLE GLOBALCASECHANGERESULTS ADD CASENAMEREFERENCEUPDATED bit NOT NULL DEFAULT 0
	PRINT '**** DR-52801 Column GLOBALCASECHANGERESULTS.CASENAMEREFERENCEUPDATED added'
END
ELSE
	BEGIN
	PRINT '**** DR-52801 Column GLOBALCASECHANGERESULTS.CASENAMEREFERENCEUPDATED exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('GLOBALCASECHANGERESULTS') = 0
BEGIN
EXEC ipu_UtilGenerateAuditTriggers 'GLOBALCASECHANGERESULTS'
END
GO