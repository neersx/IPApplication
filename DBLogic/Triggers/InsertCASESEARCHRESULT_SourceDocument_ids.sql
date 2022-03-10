if exists (select * from sysobjects where type='TR' and name = 'InsertCASESEARCHRESULT_SourceDocument_ids')
begin
	PRINT 'Refreshing trigger InsertCASESEARCHRESULT_SourceDocument_ids...'
	DROP TRIGGER InsertCASESEARCHRESULT_SourceDocument_ids
end
go

Create trigger InsertCASESEARCHRESULT_SourceDocument_ids on CASESEARCHRESULT for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASESEARCHRESULT_SourceDocument_ids
-- VERSION:	2
-- DESCRIPTION:	When a Case is associated with a Prior Art that is a Source Document
--		then all of the Prior Art that are linked to the Source Document need
--		to also be linked to the Case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 May 2011	MF	10572 	1	Created
-- 05 May 2011	MF	10578	2	Set the CASEFIRSTLINKEDTO for the specific Prior Art
--					to be the same as what is on the Source Document.

	declare @tblCaseSearchResult table
		(CASEID			int		not null,
		 PRIORARTID		int		not null,
		 STATUS			int		null,
		 CASEFIRSTLINKEDTO	bit		not null
		)

	Declare @nRowCount		int

	-------------------------------------------------------
	-- Case linked to Source Document
	-- A Source Document may bundle together any number of
	-- cited Search Results (prior art). When a Case is
	-- associated with a Source Document it should create
	-- links to each Prior Art linked to the Source Document.
	-------------------------------------------------------
	Insert into @tblCaseSearchResult(CASEID, PRIORARTID, STATUS, CASEFIRSTLINKEDTO)
	Select distinct i.CASEID, R.CITEDPRIORARTID, CS1.STATUS, isnull(i.CASEFIRSTLINKEDTO,0)
	From inserted i
	join SEARCHRESULTS S	on (S.PRIORARTID=i.PRIORARTID)
			---------------------------------------------
			-- Find prior art cited in Source Document
			---------------------------------------------
	join REPORTCITATIONS R	on (R.SEARCHREPORTID=S.PRIORARTID)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(STATUS) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=i.CASEID
				and CS1.PRIORARTID=R.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.CASEID=i.CASEID
				and CS2.PRIORARTID=R.CITEDPRIORARTID
				and CS2.CASELISTPRIORARTID is null
				and CS2.FAMILYPRIORARTID   is null
				and CS2.NAMEPRIORARTID     is null
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- NOTE:
			-- We do not have to check the country or the
			-- status of the Case to see if Prior Art is
			-- allowed. This is because we already know
			-- this Case has been linked to prior art as
			-- it caused this trigger to fire.
			---------------------------------------------
	where isnull(i.ISCASERELATIONSHIP,0)=0
	and S.ISSOURCEDOCUMENT=1
	and  CS2.CASEID is null

	Set @nRowCount=@@Rowcount

	if @nRowCount>0
	Begin
		-----------------------------------------------
		-- Only attempt an insert into CASESEARCHRESULT
		-- if there are definitely rows to insert.
		-- This is to avoid firing the insert trigger
		-- InsertCASESEARCHRESULT_ids unnecessarily.
		-----------------------------------------------
		Insert into CASESEARCHRESULT(CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP,CASEFIRSTLINKEDTO)
		Select CASEID, PRIORARTID, STATUS, getdate(),0,CASEFIRSTLINKEDTO
		from @tblCaseSearchResult
	End
End -- End of trigger
go
