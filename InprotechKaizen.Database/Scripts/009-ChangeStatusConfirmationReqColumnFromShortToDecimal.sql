﻿	/*** RFC12996 - Change STATUS.CONFIRMATIONREQ column from smallint to decimal ***/
	----RFC12381 Change STATUS.CONFIRMATIONREQ column----   

	If exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'STATUS' AND COLUMN_NAME = 'CONFIRMATIONREQ' AND DATA_TYPE <> 'decimal')
		BEGIN
		 PRINT '**** RFC12996 Altering column STATUS.CONFIRMATIONREQ to be NOT NULL.'
		 ALTER TABLE STATUS ALTER COLUMN CONFIRMATIONREQ decimal(1,0) NOT NULL			
		 PRINT '**** RFC12996 STATUS.CONFIRMATIONREQ column has been Altered.'
		 PRINT ''
 		END
	ELSE
 		PRINT '**** RFC12996 STATUS.CONFIRMATIONREQ already Altered.'
 		PRINT ''
	GO
    exec ipu_UtilGenerateAuditTriggers 'STATUS'
	GO
