if exists (select * from sysobjects where type='TR' and name = 'tU_TABLECODES')
begin
	PRINT 'Refreshing trigger tU_TABLECODES...'
	DROP TRIGGER tU_TABLECODES
end
go
	
CREATE TRIGGER tU_TABLECODES ON TABLECODES FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	tU_TABLECODES 
-- VERSION :	1
-- DESCRIPTION:	This trigger updates the corresponding QUERYCOLUMN rows when a 
--		TABLECODES row has its DESCRIPTION modified and TABLETYPE=-500

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 	
-- 08 Jun 2010	MF	RFC7008	1	Trigger created 	


If NOT UPDATE(LOGDATETIMESTAMP)
BEGIN
	IF UPDATE(DESCRIPTION) 
	BEGIN 
		Declare	@nErrorCode	int
		Declare @nRowCount	int
		------------------------------------------
		-- Update the existing QUERYCOLUMN row 
		-- linked to the TABLECODE row if the
		-- Description has changed and another
		-- TABLECODE row with the same description
		-- does not exist. 
		------------------------------------------
		Update QUERYCOLUMN
		set COLUMNLABEL=i.DESCRIPTION,
		    DESCRIPTION=i.DESCRIPTION
		from QUERYCOLUMN C
		join deleted d		on (d.DESCRIPTION=C.COLUMNLABEL)
		join inserted i		on (i.TABLECODE  =d.TABLECODE
					and i.DESCRIPTION<>d.DESCRIPTION)
		join QUERYDATAITEM DI	on (DI.DATAITEMID      = C.DATAITEMID
					and DI.PROCEDUREITEMID = 'BillMapping'
					and DI.PROCEDURENAME   = N'xml_GetDebitNoteMappedCodes')
		left join TABLECODES TC	on (TC.TABLETYPE=d.TABLETYPE
					and TC.DESCRIPTION=d.DESCRIPTION
					and TC.TABLECODE <>d.TABLECODE)
		where d.TABLETYPE=-500
		and  TC.TABLECODE is null

		------------------------------------------
		-- Insert a QUERYCOLUMN row to match the
		-- modified TABLECODES row if a row with
		-- the same description does not exist. 
		------------------------------------------
		INSERT INTO QUERYCOLUMN(COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		SELECT i.DESCRIPTION, i.DESCRIPTION, NULL, DI.DATAITEMID
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
			-- Now make the QUERYCOLUMN available
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
	END
END
go
