﻿/** DR-51020 Adding column GLOBALCASECHANGERESULTS.PROFITCENTRECODEUPDATED	**/
If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLOBALCASECHANGERESULTS'AND COLUMN_NAME = 'PROFITCENTRECODEUPDATED')
	BEGIN
	PRINT '**** DR-51020 Adding column GLOBALCASECHANGERESULTS.PROFITCENTRECODEUPDATED'
	ALTER TABLE GLOBALCASECHANGERESULTS ADD PROFITCENTRECODEUPDATED bit NOT NULL DEFAULT 0
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.PROFITCENTRECODEUPDATED added'
END
ELSE
	BEGIN
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.PROFITCENTRECODEUPDATED exists already'
END
GO

/** DR-51020 Adding column GLOBALCASECHANGERESULTS.PURCHASEORDERNOUPDATED	**/
If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLOBALCASECHANGERESULTS'AND COLUMN_NAME = 'PURCHASEORDERNOUPDATED')
	BEGIN
	PRINT '**** DR-51020 Adding column GLOBALCASECHANGERESULTS.PURCHASEORDERNOUPDATED'
	ALTER TABLE GLOBALCASECHANGERESULTS ADD PURCHASEORDERNOUPDATED bit NOT NULL DEFAULT 0
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.PURCHASEORDERNOUPDATED added'
END
ELSE
	BEGIN
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.PURCHASEORDERNOUPDATED exists already'
END
GO

/** DR-51020 Adding column GLOBALCASECHANGERESULTS.TYPEOFMARKUPDATED	**/
If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLOBALCASECHANGERESULTS'AND COLUMN_NAME = 'TYPEOFMARKUPDATED')
	BEGIN
	PRINT '**** DR-51020 Adding column GLOBALCASECHANGERESULTS.TYPEOFMARKUPDATED'
	ALTER TABLE GLOBALCASECHANGERESULTS ADD TYPEOFMARKUPDATED bit NOT NULL DEFAULT 0
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.TYPEOFMARKUPDATED added'
END
ELSE
	BEGIN
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.TYPEOFMARKUPDATED exists already'
END
GO

/** DR-51020 Adding column GLOBALCASECHANGERESULTS.ENTITYSIZEUPDATED	**/
If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GLOBALCASECHANGERESULTS'AND COLUMN_NAME = 'ENTITYSIZEUPDATED')
	BEGIN
	PRINT '**** DR-51020 Adding column GLOBALCASECHANGERESULTS.ENTITYSIZEUPDATED'
	ALTER TABLE GLOBALCASECHANGERESULTS ADD ENTITYSIZEUPDATED bit NOT NULL DEFAULT 0
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.ENTITYSIZEUPDATED added'
END
ELSE
	BEGIN
	PRINT '**** DR-51020 Column GLOBALCASECHANGERESULTS.ENTITYSIZEUPDATED exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('GLOBALCASECHANGERESULTS') = 0
BEGIN
	EXEC ipu_UtilGenerateAuditTriggers 'GLOBALCASECHANGERESULTS'
END
GO