/**********************************************************************************************************/
    /*** DR-64447 Add Last Updated EventNote TimeStamp - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9712)
        	BEGIN
         	 PRINT '**** DR-64447 Adding data IMPLIEDDATAID = 9712'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9712, NULL, N'Reference', N'Column required for getting event notes updated Date time', 970
        	 PRINT '**** DR-64447 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-64447 IMPLIEDDATAID = 9712 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-64447 Add Last Updated EventNote TimeStamp - Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9712 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-64447 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9712 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9712, 1, N'LastUpdatedEventNoteTimeStamp', 0, N'LastUpdatedEventNoteTimeStamp', N'ipw_TaskPlanner')
        	 PRINT '**** DR-64447 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-64447 QUERYIMPLIEDITEM IMPLIEDDATAID = 9712 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go