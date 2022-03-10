 /*** DR-66753 Added Instructor column to default TaskPlanner presentation							***/
	
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Instructor'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 6, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go