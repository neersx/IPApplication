/** DR-76940 - Add ImportanceLevelkey as Reference column for ImportanceDescription  **/

Declare @nDataitemId int
select @nDataitemId =DATAITEMID from QUERYDATAITEM  
	where PROCEDUREITEMID = 'ImportanceDescription' and PROCEDURENAME = 'ipw_TaskPlanner'	

if not exists(select 1 from QUERYIMPLIEDDATA where DATAITEMID = @nDataitemId and TYPE='Reference')
begin	
	Declare @nIMPLIEDDATAID int
	select @nIMPLIEDDATAID = MAX(IMPLIEDDATAID) + 1 from QUERYIMPLIEDDATA

	PRINT '**** DR-76940 Adding data QUERYIMPLIEDDATA for DATAITEMID = '+ cast(@nDataitemId as nvarchar) 
	INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, CONTEXTID, DATAITEMID, TYPE, NOTES)
		VALUES(@nIMPLIEDDATAID, 970, @nDataitemId, 'Reference', 'Link to importance level key')

	PRINT '**** DR-76940 Data successfully added to QUERYIMPLIEDDATA table.'

	PRINT '**** DR-76940 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = '+ cast(@nIMPLIEDDATAID as nvarchar) +' AND SEQUENCENO = 1'
	
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (@nIMPLIEDDATAID, 1, N'ImportanceLevelKey', 0, N'ImportanceLevelKey', N'ipw_TaskPlanner')
	
	PRINT '**** DR-76940 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''

	PRINT '**** DR-76940 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = '+ cast(@nIMPLIEDDATAID as nvarchar) +' AND SEQUENCENO = 2'
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (@nIMPLIEDDATAID, 2, N'ImportanceDescription', 0, NULL, N'ipw_TaskPlanner')
        PRINT '**** DR-76940 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''

end
 go
