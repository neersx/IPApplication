/****************************************************************************/
/*** DR-70294 Add column SEARCHRESULTS.CITY ***/
/****************************************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SEARCHRESULTS' AND COLUMN_NAME = 'CITY')
    BEGIN
	PRINT '**** DR-70294 Adding column SEARCHRESULTS.CITY'
	ALTER TABLE SEARCHRESULTS ADD CITY nvarchar(30) NULL
	PRINT '**** DR-70294 Column SEARCHRESULTS.CITY added'
END
ELSE
    BEGIN
	PRINT '**** DR-70294 Column SEARCHRESULTS.CITY exists already'
END
GO

/****************************************************************************/
/*** DR-70294 Add column SEARCHRESULTS.PUBLISHER ***/
/****************************************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'SEARCHRESULTS' AND COLUMN_NAME = 'PUBLISHER')
    BEGIN
	PRINT '**** DR-70294 Adding column SEARCHRESULTS.PUBLISHER'
	ALTER TABLE SEARCHRESULTS ADD PUBLISHER nvarchar(max) NULL
	PRINT '**** DR-70294 Column SEARCHRESULTS.PUBLISHER added'
END
ELSE
    BEGIN
	PRINT '**** DR-70294 Column SEARCHRESULTS.PUBLISHER exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('SEARCHRESULTS') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'SEARCHRESULTS'
END
GO