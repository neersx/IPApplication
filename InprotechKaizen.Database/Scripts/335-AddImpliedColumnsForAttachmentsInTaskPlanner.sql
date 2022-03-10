/**********************************************************************************************************/
    /*** DR-72653 Ability to view attachments specific to a case event in the task planner - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9719)
        	BEGIN
         	 PRINT '**** DR-72653 Adding data IMPLIEDDATAID = 9719'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9719, NULL, N'Reference', N'Column required for attachments indication', 970
        	 PRINT '**** DR-72653 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72653 IMPLIEDDATAID = 9719 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-72653 Ability to view attachments specific to a case event in the task planner - Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9719 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-72653 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9719 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9719, 1, N'AttachmentCount', 0, N'AttachmentCount', N'ipw_TaskPlanner')
        	 PRINT '**** DR-72653 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72653 QUERYIMPLIEDITEM IMPLIEDDATAID = 9719 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go

    /**********************************************************************************************************/
    /*** DR-72663 Ability to add or edit attachment from the task planner - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9720)
        	BEGIN
         	 PRINT '**** DR-72663 Adding data IMPLIEDDATAID = 9720'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9720, NULL, N'Reference', N'Reference to Event Cycle.', 970
        	 PRINT '**** DR-72663 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72663 IMPLIEDDATAID = 9720 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-72663 Ability to add or edit attachment from the task planner - Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9720 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-72663 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9720 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9720, 1, N'EventCycle', 0, N'EventCycle', N'ipw_TaskPlanner')
        	 PRINT '**** DR-72663 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72663 QUERYIMPLIEDITEM IMPLIEDDATAID = 9720 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go



	/**********************************************************************************************************/
    /*** DR-72663 Ability to add or edit attachment from the task planner - Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9721)
        	BEGIN
         	 PRINT '**** DR-72663 Adding data IMPLIEDDATAID = 9721'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9721, NULL, N'Reference', N'Reference to Event Action Key.', 970
        	 PRINT '**** DR-72663 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72663 IMPLIEDDATAID = 9721 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-72663 Ability to add or edit attachment from the task planner - Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9721 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-72663 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9721 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9721, 1, N'ActionKey', 0, N'ActionKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-72663 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-72663 QUERYIMPLIEDITEM IMPLIEDDATAID = 9721 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go

    /**********************************************************************************************************/
    /*** DR-77055 Error on hovering over Attachments icon - Add EventKey to Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9725)
        BEGIN
         	 PRINT '**** DR-77055 Adding data IMPLIEDDATAID = 9725'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9725, NULL, N'Reference', N'Reference to Event Key.', 970
        	 PRINT '**** DR-77055 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-77055 IMPLIEDDATAID = 9725 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-77055 Error on hovering over Attachments icon - Add EventKey to Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9725 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-77055 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9725 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9725, 1, N'EventKey', 0, N'EventKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-77055 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '****  DR-77055 QUERYIMPLIEDITEM IMPLIEDDATAID = 9725 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go

    /**********************************************************************************************************/
    /*** DR-77055 Error on hovering over Attachments icon - Add EventKey to Query Implied Data												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9726)
        BEGIN
         	 PRINT '**** DR-77055 Adding data IMPLIEDDATAID = 9726'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9726, NULL, N'Reference', N'Reference to Case Key.', 970
        	 PRINT '**** DR-77055 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-77055 IMPLIEDDATAID = 9726 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-77055 Error on hovering over Attachments icon - Add EventKey to Query Implied Item												***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9726 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-77055 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9726 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9726, 1, N'CaseKey', 0, N'CaseKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-77055 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '****  DR-77055 QUERYIMPLIEDITEM IMPLIEDDATAID = 9726 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go