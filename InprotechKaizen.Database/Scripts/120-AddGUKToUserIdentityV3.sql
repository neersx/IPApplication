﻿/****** RFC70547 Adding column USERIDENTITY.CPAGlobalUserId ********/

If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'USERIDENTITY' AND COLUMN_NAME = 'CPAGLOBALUSERID')
	BEGIN
		PRINT 'Adding column USERIDENTITY.CPAGLOBALUSERID ...'
		ALTER TABLE USERIDENTITY ADD CPAGLOBALUSERID nvarchar(254)  NULL 		
	END
GO
 IF dbo.fn_IsAuditSchemaConsistent('USERIDENTITY') = 0
 BEGIN
	exec ipu_UtilGenerateAuditTriggers 'USERIDENTITY'
 END
GO
