/**********************************************************************************************************/
/*** RFC65005  Alter the data type of column REMINDEREMAILS to bit in table TELECOMMUNICATION			***/
/**********************************************************************************************************/

IF EXISTS (SELECT 1 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE 
     TABLE_NAME = 'TELECOMMUNICATION' AND 
     COLUMN_NAME = 'REMINDEREMAILS' AND
	 DATA_TYPE = 'decimal')
BEGIN
	PRINT '**** RFC65005 Alter the data type of REMINDEREMAILS column to bit in table TELECOMMUNICATION'
	ALTER TABLE TELECOMMUNICATION ALTER COLUMN REMINDEREMAILS bit	 
	PRINT '**** RFC65005 Data type of column TELECOMMUNICATION.REMINDEREMAILS successfully got altered to bit'
	PRINT ''
END
ELSE
BEGIN
	PRINT '**** RFC65005 No changes required as column TELECOMMUNICATION.REMINDEREMAILS is already a bit column.'
	PRINT ''
End
GO

IF dbo.fn_IsAuditSchemaConsistent('TELECOMMUNICATION') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'TELECOMMUNICATION'
END
GO