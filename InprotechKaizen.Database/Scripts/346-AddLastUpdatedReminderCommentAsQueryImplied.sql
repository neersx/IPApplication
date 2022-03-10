    /******************************************************************************************************/
    /*** DR-74036 Add Last Updated Reminder Comment TimeStamp - Query Implied Data						***/
	/******************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9722)
        	BEGIN
         	 PRINT '**** DR-74036 Adding data IMPLIEDDATAID = 9722'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9722, NULL, N'Reference', N'Column required for getting reminder comments updated Date time', 970
        	 PRINT '**** DR-74036 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-74036 IMPLIEDDATAID = 9722 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-74036 Add Last Updated Reminder Comment TimeStamp - Query Implied Item							***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9722 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-74036 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9722 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9722, 1, N'LastUpdatedReminderComment', 0, N'LastUpdatedReminderComment', N'ipw_TaskPlanner')
        	 PRINT '**** DR-74036 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-74036 QUERYIMPLIEDITEM IMPLIEDDATAID = 9722 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go