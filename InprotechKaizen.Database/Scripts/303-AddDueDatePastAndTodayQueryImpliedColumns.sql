    /**********************************************************************************************************/
    /*** DR-67749 Add column to show that today is due date - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9716)
        	BEGIN
         	 PRINT '**** DR-67749 Adding data IMPLIEDDATAID = 9716'
		        INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		        SELECT 9716, NULL, N'IsDueDateToday', N'Column to show due date is today', 970
        	 PRINT '**** DR-67749 Data successfully added to QUERYIMPLIEDDATA table.'
		     PRINT ''
         	END
    ELSE
         PRINT '**** DR-67749 IMPLIEDDATAID = 9716 already exists'
         PRINT ''
    go

   	/**********************************************************************************************************/
    /*** DR-67749 Add column to show that today is due date - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9716 AND SEQUENCENO = 1)
        BEGIN
         	PRINT '**** DR-67749 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9716 AND SEQUENCENO = 1'
		       INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		       VALUES (9716, 1, N'IsDueDateToday', 0, N'IsDueDateToday', N'ipw_TaskPlanner')
        	PRINT '**** DR-67749 Data successfully added to QUERYIMPLIEDITEM table.'
		    PRINT ''
         END
    ELSE
         PRINT '**** DR-67749 QUERYIMPLIEDITEM IMPLIEDDATAID = 9716 AND SEQUENCENO = 1 already exists'
         PRINT ''
    go

    /**********************************************************************************************************/
    /*** DR-67749 Add column to show that due date is past - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9717)
        	BEGIN
         	 PRINT '**** DR-67749 Adding data IMPLIEDDATAID = 9717'
		        INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		        SELECT 9717, NULL, N'IsDueDatePast', N'Column to show due date is past', 970
        	 PRINT '**** DR-67749 Data successfully added to QUERYIMPLIEDDATA table.'
		     PRINT ''
         	END
    ELSE
         PRINT '**** DR-67749 IMPLIEDDATAID = 9717 already exists'
         PRINT ''
    go

   	/**********************************************************************************************************/
    /*** DR-67749 AddOverDueDateColumn - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9717 AND SEQUENCENO = 1)
        BEGIN
         	PRINT '**** DR-67749 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9717 AND SEQUENCENO = 1'
		       INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		       VALUES (9717, 1, N'IsDueDatePast', 0, N'IsDueDatePast', N'ipw_TaskPlanner')
        	PRINT '**** DR-67749 Data successfully added to QUERYIMPLIEDITEM table.'
		    PRINT ''
         END
    ELSE
         PRINT '**** DR-67749 QUERYIMPLIEDITEM IMPLIEDDATAID = 9717 AND SEQUENCENO = 1 already exists'
         PRINT ''
    go