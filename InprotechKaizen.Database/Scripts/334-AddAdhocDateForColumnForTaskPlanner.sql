    /**********************************************************************************************************/
    /*** DR-73645 Add Ad Hoc Date For column - Query Data Item							***/
	/**********************************************************************************************************/
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'AdHocDateFor' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-73645 Adding data QUERYDATAITEM.PROCEDUREITEMID = AdHocDateFor'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'AdHocDateFor', NULL, N'A', 0, 0, N'The name responsible for Ad Hoc', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-73645 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-73645 QUERYDATAITEM.PROCEDUREITEMID = AdHocDateFor already exists'
         	PRINT ''
    go

    /**********************************************************************************************************/
    /*** DR-73645 Add Ad Hoc Date For column - Query Column							***/
	/**********************************************************************************************************/
     SET IDENTITY_INSERT QUERYCOLUMN ON
	 go

     Declare @nColumnId int 
     Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
     If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
     JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
     WHERE DI.PROCEDUREITEMID = N'AdHocDateFor'
		     AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	    BEGIN
         	     PRINT '**** DR-73645 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		     INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		     SELECT cast(@nColumnId as nvarchar), N'Ad Hoc Date For', N'This column will display the name saved against each Ad Hoc Date as the Ad Hoc Responsible Name', NULL, DI.DATAITEMID
		     FROM QUERYDATAITEM DI
		     WHERE DI.PROCEDUREITEMID = N'AdHocDateFor'
		     AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	     PRINT '**** DR-73645 Data successfully added to QUERYCOLUMN table.'
		     PRINT ''
         	    END
    	    ELSE
         	    PRINT '**** DR-73645 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	    PRINT ''
     go

	 SET IDENTITY_INSERT QUERYCOLUMN OFF
	 go

    /**********************************************************************************************************/
    /*** DR-73645 Add Ad Hoc Date For column - Query Context Column						***/
	/**********************************************************************************************************/
    Declare @nColumnId int 
    Select @nColumnId = QC.ColumnID from 
    QUERYCOLUMN QC 
    join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
    WHERE DI.PROCEDUREITEMID = N'AdHocDateFor'
    AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	    If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	    BEGIN
         	     PRINT '**** DR-73645 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		     INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		     VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	     PRINT '**** DR-73645 Data successfully added to QUERYCONTEXTCOLUMN table.'
		     PRINT ''
         	    END
    	    ELSE
         	    PRINT '**** DR-73645 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	    PRINT ''
    go
