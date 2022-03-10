    /**********************************************************************************************************/
    /*** DR-66388 Add Task Planner Row key - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9710)
        	BEGIN
         	 PRINT '**** DR-66388 Adding data IMPLIEDDATAID = 9710'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9710, NULL, N'Reference', N'Column required for getting task planner record', 970
        	 PRINT '**** DR-66388 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-66388 IMPLIEDDATAID = 9710 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-66388 Add Task Planner Row key - Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9710 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-66388 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9710 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9710, 1, N'TaskPlannerRowKey', 0, N'TaskPlannerRowKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-66388 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-66388 QUERYIMPLIEDITEM IMPLIEDDATAID = 9710 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go