    /******************************************************************************************************/
    /*** DR-76655 Add HasInstructions - Query Implied Data						***/
	/******************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9724)
        	BEGIN
         	 PRINT '**** DR-76655 Adding data IMPLIEDDATAID = 9724'	
			 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
			 SELECT 9724, NULL, N'Reference', N'Column required to indicate instructions.', 970
        		 PRINT '**** DR-76655 Data successfully added to QUERYIMPLIEDDATA table.'
			 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-76655 IMPLIEDDATAID = 9724 already exists'
         	PRINT ''
    	go

   	/**********************************************************************************************************/
    /*** DR-76655 Add HasInstructions - Query Implied Item							***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9724 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-76655 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9724 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9724, 1, N'HasInstructions', 0, N'HasInstructions', N'ipw_TaskPlanner')
        	 PRINT '**** DR-76655 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-76655 QUERYIMPLIEDITEM IMPLIEDDATAID = 9724 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go