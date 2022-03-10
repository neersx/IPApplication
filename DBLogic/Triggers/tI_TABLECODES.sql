/**********************************************************************************************************/
/*** Creation of trigger tI_TABLECODES 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tI_TABLECODES')
begin
	PRINT 'Refreshing trigger tI_TABLECODES...'
	DROP TRIGGER tI_TABLECODES
end
go

CREATE TRIGGER tI_TABLECODES on TABLECODES for INSERT NOT FOR REPLICATION as
-- TRIGGER :	tI_TABLECODES
-- VERSION :	1
-- DESCRIPTION:	Whenever a TableCode is added with a TableType value of -500, automatically 
--		insert a row into the QUERYCOLUMN and QUERYCONTEXTCOLUMN tables.
--  Name Type to Topic Control and marked this topic as hidden
--		
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 Jun 2010	MF	RFC7008	1	Trigger Created

Begin	
	Declare	@nErrorCode	int
	Declare @nRowCount	int

	INSERT INTO QUERYCOLUMN(COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT distinct i.DESCRIPTION, i.DESCRIPTION, NULL, DI.DATAITEMID
	From inserted i
	join QUERYDATAITEM DI	on (DI.PROCEDUREITEMID = 'BillMapping'
				and DI.PROCEDURENAME   = N'xml_GetDebitNoteMappedCodes')
	left join QUERYCOLUMN C	on (C.COLUMNLABEL=i.DESCRIPTION
				and C.DATAITEMID =DI.DATAITEMID)
	where i.TABLETYPE=-500
	and C.COLUMNID is null

	Select @nRowCount =@@Rowcount,
	       @nErrorCode=@@Error
	
	If @nRowCount>0
	and @nErrorCode=0
	Begin
		------------------------------------------
		-- Now make the created column available
		-- within the desired context by inserting
		-- a row into QUERYCONTEXTCOLUMN.
		------------------------------------------
		INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		SELECT 460,C.COLUMNID, NULL, NULL, 0, 0
		From inserted i
		join QUERYDATAITEM DI	on (DI.PROCEDUREITEMID = 'BillMapping'
					and DI.PROCEDURENAME   = N'xml_GetDebitNoteMappedCodes')
		join QUERYCOLUMN C	on (C.COLUMNLABEL=i.DESCRIPTION
					and C.DATAITEMID=DI.DATAITEMID)
		left join QUERYCONTEXTCOLUMN CC
					on (CC.CONTEXTID=460
					and CC.COLUMNID=C.COLUMNID)
		where i.TABLETYPE=-500
		and CC.COLUMNID is null
	End
End
go
