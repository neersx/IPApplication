    /**********************************************************************************************************/
    /***  DR-66895 Add default data to TASKPLANNERTAB table											***/
	/**********************************************************************************************************/
	IF exists(SELECT * FROM QUERY WHERE IDENTITYID IS NULL AND CONTEXTID = 970)
       BEGIN
         PRINT '**** DR-66895 Add default data to TASKPLANNERTAB table'

		IF NOT EXISTS(SELECT * FROM TASKPLANNERTAB WHERE IDENTITYID IS NULL AND QUERYID = -31)
			BEGIN
				PRINT '**** DR-66895 Add default data to TASKPLANNERTAB table for QUERYID = -31'
				 INSERT INTO TASKPLANNERTAB(QUERYID, IDENTITYID, TABSEQUENCE)
				 SELECT QUERYID, IDENTITYID, 1
				 FROM QUERY WHERE IDENTITYID IS NULL AND CONTEXTID = 970 AND QUERYID = -31
				 PRINT '**** DR-66895 Data successfully added to TASKPLANNERTAB table for QUERYID = -31.'
				 PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-66895 Data to TASKPLANNERTAB table for QUERYID = -31 already exists'
			END

		IF NOT EXISTS(SELECT * FROM TASKPLANNERTAB WHERE IDENTITYID IS NULL AND QUERYID = -29)
			BEGIN
				PRINT '**** DR-66895 Add default data to TASKPLANNERTAB table for QUERYID = -29'
				 INSERT INTO TASKPLANNERTAB(QUERYID, IDENTITYID, TABSEQUENCE)
				 SELECT QUERYID, IDENTITYID, 2
				 FROM QUERY WHERE IDENTITYID IS NULL AND CONTEXTID = 970 AND QUERYID = -29
				 PRINT '**** DR-66895 Data successfully added to TASKPLANNERTAB table for QUERYID = -29.'
				 PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-66895 Data to TASKPLANNERTAB table for QUERYID = -29 already exists'
			END 

		IF NOT EXISTS(SELECT * FROM TASKPLANNERTAB WHERE IDENTITYID IS NULL AND QUERYID = -28)
			BEGIN
			   PRINT '**** DR-66895 Add default data to TASKPLANNERTAB table for QUERYID = -28'
				INSERT INTO TASKPLANNERTAB(QUERYID, IDENTITYID, TABSEQUENCE)
				SELECT QUERYID, IDENTITYID, 3
				FROM QUERY WHERE IDENTITYID IS NULL AND CONTEXTID = 970 AND QUERYID = -28
				PRINT '**** DR-66895 Data successfully added to TASKPLANNERTAB table for QUERYID = -28.'
				 PRINT ''
			END
		ELSE
			BEGIN
				PRINT '**** DR-66895 Data to TASKPLANNERTAB table for QUERYID = -28 already exists'
			END
    	 
      END
    	ELSE
         	PRINT '**** DR-66895 TASKPLANNERTAB Default value already exists'
         	PRINT ''
    GO
