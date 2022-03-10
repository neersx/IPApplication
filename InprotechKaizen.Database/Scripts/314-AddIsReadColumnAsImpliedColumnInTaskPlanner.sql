 	/*** DR-68342 Add IsRead implied columns in taskplanner - Query Implied Data						***/

	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9718)
        	BEGIN
         	 PRINT '**** DR-68342 Adding data IMPLIEDDATAID = 9718'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 VALUES (9718, NULL, N'Reference',  N'Column required identify read reminders', 970)
        	 PRINT '**** DR-68342 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-68342 IMPLIEDDATAID = 9718 already exists'
         	PRINT ''
    	go

    /*** DR-68342 Add IsRead implied columns in taskplanner - Query Implied Item						***/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9718 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-68342 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9718 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9718, 1, N'IsRead', 0, N'IsRead', N'ipw_TaskPlanner')
        	 PRINT '**** DR-68342 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-68342 QUERYIMPLIEDITEM IMPLIEDDATAID = 9718 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go

