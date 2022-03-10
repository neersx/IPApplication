	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Type - Query Implied Data						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 73)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 73'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 73, DATAITEMID, N'Reference', N'Case Type Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CaseTypeDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 73 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Type - Query Implied Item						***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 73 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 73 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (73, 0, N'CaseTypeKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 73 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Property Type - Query Implied Data					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 74)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 74'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 74, DATAITEMID, N'Reference', N'Property Type Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'PropertyTypeDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 74 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Property Type - Query Implied Item					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 74 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 74 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (74, 0, N'PropertyTypeKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 74 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go

		
	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Country - Query Implied Data					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 75)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 75'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 75, DATAITEMID, N'Reference', N'Country Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CountryName'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 75 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Country - Query Implied Item					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 75 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 75 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (75, 0, N'CountryCode', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 75 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go
    	

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Status - Query Implied Data					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 76)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 76'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 76, DATAITEMID, N'Reference', N'Case Status Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'StatusDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 76 already exists'
         	PRINT ''
    	go


	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Status - Query Implied Item					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 76 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 76 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (76, 0, N'StatusKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 76 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go
		
	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case External Status - Query Implied Data				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 77)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 77'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 77, DATAITEMID, N'Reference', N'Case Status Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'StatusExternalDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 77 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case External Status - Query Implied Item				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 77 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 77 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (77, 0, N'StatusKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 77 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Renewal Status - Query Implied Data					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 78)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 78'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 78, DATAITEMID, N'Reference', N'Renewal Status Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'RenewalStatusDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 78 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Renewal Status - Query Implied Item				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 78 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 78 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (78, 0, N'RenewalStatusKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 78 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go

  	
	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Renewal External Status - Query Implied Data				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 79)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 79'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 79, DATAITEMID, N'Reference', N'Renewal Status Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'RenewalStatusExternalDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 79 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Renewal External Status - Query Implied Item				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 79 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 79 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (79, 0, N'RenewalStatusKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 79 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go   
		 	
    /**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Status Summary - Query Implied Data				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 80)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data IMPLIEDDATAID = 80'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 80, DATAITEMID, N'Reference', N'Status Summary Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CaseStatusSummary'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 IMPLIEDDATAID = 80 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC72084 Add key columns to Case Status Summary - Query Implied Item				***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 80 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC72084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 80 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (80, 0, N'CaseStatusSummaryKey', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC72084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72084 QUERYIMPLIEDITEM IMPLIEDDATAID = 80 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go
    	
		 	
	/**********************************************************************************************************/
	/*** RFC81084 Add key columns to Case Category - Query Implied Data					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 81)
        	BEGIN
         	 PRINT '**** RFC81084 Adding data IMPLIEDDATAID = 81'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 81, DATAITEMID, N'Reference', N'Case Category Key for column filtering', 1
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CaseCategoryDescription'
		 AND PROCEDURENAME = N'csw_ListCase'
        	 PRINT '**** RFC81084 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC81084 IMPLIEDDATAID = 81 already exists'
         	PRINT ''
    	go

	/**********************************************************************************************************/
	/*** RFC81084 Add key columns to Case Category - Query Implied Item					***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 81 AND SEQUENCENO = 0)
        	BEGIN
         	 PRINT '**** RFC81084 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 81 AND SEQUENCENO = 0'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (81, 0, N'CaseCategoryCode', 0, NULL, N'csw_ListCase')
        	 PRINT '**** RFC81084 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC81084 QUERYIMPLIEDITEM IMPLIEDDATAID = 81 AND SEQUENCENO = 0 already exists'
         	PRINT ''
    	go

