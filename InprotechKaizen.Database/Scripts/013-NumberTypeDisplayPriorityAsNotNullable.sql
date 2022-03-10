	/*** ST-454 change NUMBERTYPES.DISPLAYPRIORITY to not nullable column */

	If exists(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NUMBERTYPES' AND COLUMN_NAME = 'DISPLAYPRIORITY'  AND IS_NULLABLE = 'YES')
		BEGIN
		 PRINT '**** Change column NUMBERTYPES.ISSUEDBYIPOFFICE to be not nullable bit column.'
	
			/*** Only non-null issued by IP Office number types are considered when setting current official number against the case
				 Automatically assign largest display priority (i.e. less likely to be considered) ***/

			declare @currentDisplayPriority smallint
			select @currentDisplayPriority = MAX(DISPLAYPRIORITY) from NUMBERTYPES

			Update NUMBERTYPES
			Set @currentDisplayPriority=@currentDisplayPriority+1,
				DISPLAYPRIORITY=@currentDisplayPriority
			where DISPLAYPRIORITY is null
				
			ALTER TABLE [NUMBERTYPES] 
				ALTER COLUMN DISPLAYPRIORITY smallint NOT NULL 

			ALTER TABLE [NUMBERTYPES] 
				ADD DEFAULT 0 FOR DISPLAYPRIORITY			

		 PRINT '****  NUMBERTYPES.DISPLAYPRIORITY column has been changed to as non nullable.'
		 PRINT ''
 		END
	ELSE
 		PRINT '**** NUMBERTYPES.DISPLAYPRIORITY already is a non-nullable column'
 		PRINT ''
	GO
    exec ipu_UtilGenerateAuditTriggers 'NUMBERTYPES'
	GO
