	/*** DR-79372 Title column available for Task Planner - Query Data Item							***/
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'ShortTitle' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-79372 Adding data QUERYDATAITEM.PROCEDUREITEMID = ShortTitle'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'ShortTitle', NULL, N'A', 0, 0, N'The title or mark associated with the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-79372 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-79372 QUERYDATAITEM.PROCEDUREITEMID = ShortTitle already exists'
         	PRINT ''
    	go
/*** DR-79372 Title column available for Task Planner - Query Column							***/
	SET IDENTITY_INSERT QUERYCOLUMN ON
	go

 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'ShortTitle'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-79372 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Title', N'The title or mark associated with the case.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'ShortTitle'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-79372 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-79372 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go

	SET IDENTITY_INSERT QUERYCOLUMN OFF
	go

/*** DR-79372 Title column available for Task Planner - Query Context Column						***/

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ShortTitle'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-79372 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-79372 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-79372 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go

