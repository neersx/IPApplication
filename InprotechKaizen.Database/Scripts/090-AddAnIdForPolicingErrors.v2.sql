/**********************************************************************************************************/	
/*** RFC58753 Add column POLICINGERRORS.POLICINGERRORSID																***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'POLICINGERRORS' AND COLUMN_NAME = 'POLICINGERRORSID')
	BEGIN		
		PRINT '**** R9733 Adding column POLICINGERRORS.POLICINGERRORSID' 
		ALTER TABLE POLICINGERRORS ADD POLICINGERRORSID int IDENTITY (1,1)  NOT FOR REPLICATION 		
		PRINT '**** R9733 Column POLICINGERRORS.POLICINGERRORSID added' 
 	END
ELSE
	BEGIN
		PRINT '**** R9733 Column POLICINGERRORS.POLICINGERRORSID exists already' 
	END
GO
IF dbo.fn_IsAuditSchemaConsistent('POLICINGERRORS') = 0
BEGIN
	exec ipu_UtilGenerateAuditTriggers 'POLICINGERRORS'
END
GO