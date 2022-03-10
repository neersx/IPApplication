    /**********************************************************************************************************/
    /*** DR-66853 Add ShowReminderComments - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9715)
        	BEGIN
         	 PRINT '**** DR-66853 Adding data IMPLIEDDATAID = 9715'
		        INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		        SELECT 9715, NULL, N'ShowReminderComments', N'Column to display detail reminder comments section', 970
        	 PRINT '**** DR-66853 Data successfully added to QUERYIMPLIEDDATA table.'
		     PRINT ''
         	END
    ELSE
         PRINT '**** DR-66853 IMPLIEDDATAID = 9715 already exists'
         PRINT ''
    go

   	/**********************************************************************************************************/
    /*** DR-66853 Add ShowReminderComments - Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9715 AND SEQUENCENO = 1)
        BEGIN
         	PRINT '**** DR-66853 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9715 AND SEQUENCENO = 1'
		       INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		       VALUES (9715, 1, N'ShowReminderComments', 0, N'ShowReminderComments', N'ipw_TaskPlanner')
        	PRINT '**** DR-66853 Data successfully added to QUERYIMPLIEDITEM table.'
		    PRINT ''
         END
    ELSE
         PRINT '**** DR-66853 QUERYIMPLIEDITEM IMPLIEDDATAID = 9715 AND SEQUENCENO = 1 already exists'
         PRINT ''
    go