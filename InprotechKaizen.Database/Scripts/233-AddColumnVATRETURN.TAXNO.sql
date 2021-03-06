/*** DR-50882 Add column VATRETURN.TAXNO	***/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'VATRETURN' AND COLUMN_NAME = 'TAXNO')
BEGIN
  PRINT '**** DR-50882 Adding column VATRETURN.TAXNO'
  ALTER TABLE VATRETURN ADD TAXNO nvarchar(254)  NULL
  PRINT '**** DR-50882 Column VATRETURN.TAXNO added' 
END
ELSE
BEGIN
  PRINT '**** DR-50882 Column VATRETURN.TAXNO exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('VATRETURN') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'VATRETURN'
END
GO