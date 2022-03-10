﻿If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASERELATION' AND COLUMN_NAME = 'NOTES')
	BEGIN		 
		ALTER TABLE CASERELATION ADD NOTES nvarchar(max) 		
 	END
GO
IF dbo.fn_IsAuditSchemaConsistent('CASERELATION') = 0
BEGIN
exec ipu_UtilGenerateAuditTriggers 'CASERELATION'
END
GO