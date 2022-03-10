if exists (select * from sysobjects where type='TR' and name = 'DeleteCASESEARCHRESULT_ids')
begin
	PRINT 'Refreshing trigger DeleteCASESEARCHRESULT_ids...'
	DROP TRIGGER DeleteCASESEARCHRESULT_ids
end
go

Create trigger DeleteCASESEARCHRESULT_ids on CASESEARCHRESULT FOR DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteCASESEARCHRESULT_ids
-- VERSION:	4
-- DESCRIPTION:	The deletion of rows from CASESEARCHRESULT table 
--		should remove any Cases that were added as a result
--		the insertion of Case(s) being removed.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Mar 2011	MF	10361 	1	Created
-- 03 Apr 2011	MF	10431	2	Use the PRIORARTFLAG to determine the Cases to link.
-- 03 May 2011	MF	10548	3	Delete related Cases attached to the prior art only if  
--					there is a full match on FAMILYPRIORARTID, CASELISTPRIORARTID
--					and NAMEPRIORARTID
-- 27 Mar 2018	MF	73696	4	When two cases were related to each other at the same time, and the Status of at least one of those
--					cases was such that Prior Art was no longer being associated (PRIORARTFLAG=0), then the full set of 
--					prior art for the new extended network of Cases was not flowing to all cases.

	------------------------------------------------
	-- Only remove Cases created from a relationship
	-- where the the Case does not have a Status.
	-- Those that do have a status but have now lost
	-- the Case that caused its insertion are to be
	-- updated to indicate that it is no longer from
	-- a relationship.
	------------------------------------------------

	------------------------------------------------
	-- A Case that was added as a result of being
	-- related to another Case that is now being 
	-- deleted, could in fact have also been related
	-- to other Cases that are still associated to
	-- the prior art. These Case should therefore
	-- not be removed.
	-- To achieve this:
	-- 1. Remove all of the Cases with no Status
	--    where ISCASERELATIONSHIP=1
	--    allow these Cases to be managed directly.
	-- 2. Now reinsert related Cases for any 
	--    Case that is still associated with the
	--    Prior Art.
	-- 3. Those Cases with ISCASERELATIONSHIP=1
	--    that do have a Status are to be updated
	--    to set ISCASERELATIONSHIP=0. This will
	------------------------------------------------
	-------------------------------------------------------
	-- For each Case that is being linked to Prior Art, we
	-- need to find every other Case that is related either
	-- directly or indirectly via RELATEDCASE, and also
	-- link those Cases to the Prior Art.
	-------------------------------------------------------

	declare @tblRelatedCases table
		(	MAINCASEID	int		not null,
			RELATEDCASEID	int		not null,
			DEPTH		int		not null
		)

	declare @nRowCount		int
	declare @nRowTotal		int
	declare	@nDepth			int
	declare @nCycle			int
	declare	@nCaseId		int
	declare	@nEventNo		int

	Set @nRowCount=0
	Set @nRowTotal=0
	Set @nDepth   =1

	------------------------------------------------
	-- 1. Remove all of the Cases with no Status
	--    where ISCASERELATIONSHIP=1.
	--
	--    NOTE: This delete will not cause this 
	--          trigger to fire again as the option
	--          for RECURSIVE_TRIGGERS is off.
	------------------------------------------------
	Delete CSR
	from deleted d
	join CASESEARCHRESULT CSR	on ( CSR.PRIORARTID=d.PRIORARTID
					and (CSR.FAMILYPRIORARTID  = d.FAMILYPRIORARTID   or (CSR.FAMILYPRIORARTID   is null and d.FAMILYPRIORARTID   is null))
					and (CSR.CASELISTPRIORARTID= d.CASELISTPRIORARTID or (CSR.CASELISTPRIORARTID is null and d.CASELISTPRIORARTID is null))
					and (CSR.NAMEPRIORARTID    = d.NAMEPRIORARTID     or (CSR.NAMEPRIORARTID     is null and d.NAMEPRIORARTID     is null))
					and  CSR.STATUS             is null
					and  CSR.ISCASERELATIONSHIP = 1)
	where isnull(d.ISCASERELATIONSHIP,0)=0	-- The row deleted must not be a related case.

	set @nRowCount=@@Rowcount
	------------------------------------------------
	-- Futher processing is only required if there
	-- have been related case rows removed
	------------------------------------------------
	If @nRowCount>0
	Begin
		------------------------------------------------
		-- 2. Now reinsert related Cases for any 
		--    Case that is still associated with the
		--    Prior Art.
		------------------------------------------------

		insert into @tblRelatedCases(MAINCASEID,RELATEDCASEID,DEPTH)
		select distinct CSR.CASEID, CSR.CASEID, @nDepth
		from deleted d
		join CASESEARCHRESULT CSR on (CSR.PRIORARTID=d.PRIORARTID)
		where isnull(CSR.ISCASERELATIONSHIP,0)=0
	
		set @nRowCount=@@Rowcount

		--------------------------------------------
		-- Loop through each Case associated with
		-- the prior art and get all of the cases 
		-- related in any way.
		--------------------------------------------
		While @nRowCount>0
		Begin
			insert into @tblRelatedCases(MAINCASEID, RELATEDCASEID,DEPTH)
			select T.MAINCASEID, R.RELATEDCASEID, @nDepth+1
			from @tblRelatedCases T
			join RELATEDCASE R	on (R.CASEID=T.RELATEDCASEID)
			join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
						and(CR.PRIORARTFLAG=1))
			left join @tblRelatedCases T1
						on (T1.MAINCASEID   =T.MAINCASEID
						and T1.RELATEDCASEID=R.RELATEDCASEID)
			where T.DEPTH=@nDepth
			and T1.MAINCASEID is null
			and R.RELATEDCASEID is not null
			UNION
			select T.MAINCASEID, R.CASEID, @nDepth+1
			from @tblRelatedCases T
			join RELATEDCASE R	on (R.RELATEDCASEID=T.RELATEDCASEID)
			join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
						and(CR.PRIORARTFLAG=1))
			left join @tblRelatedCases T1
						on (T1.MAINCASEID   =T.MAINCASEID
						and T1.RELATEDCASEID=R.CASEID)
			where T.DEPTH=@nDepth
			and T1.MAINCASEID is null

			Set @nRowCount=@@ROWCOUNT
			Set @nRowTotal=@nRowTotal+@nRowCount

			set @nDepth=@nDepth+1
		End

		------------------------------------------------
		-- 3. Those Cases with ISCASERELATIONSHIP=1
		--    that do have a Status are to be updated
		--    to set ISCASERELATIONSHIP=0. This will
		--    allow these Cases to be managed directly.
		--
		--    NOTE: These cases were excluded from 
		--          triggering their related cases as
		--          this might reintroduce Cases that
		--          should be deleted due to their 
		--          association with the orginal Cases
		--          removed from the prior art. If they
		--          were meant to be retained then their
		--          Status should have been set.
		------------------------------------------------
		Update CSR
		set ISCASERELATIONSHIP=0
		from deleted d
		join CASESEARCHRESULT CSR on (CSR.PRIORARTID=d.PRIORARTID)
		where CSR.STATUS is not null
		and CSR.ISCASERELATIONSHIP=1

		---------------------------------------------
		-- Now each of the Related Cases found are to 
		-- be linked to the Prior Art associated with
		-- the Main Case.
		---------------------------------------------
		-- NOTE : Inserting into CASESEARCHRESULTS
		--        will not cause this trigger to fire
		--        as the database option for
		--        RECURSIVE_TRIGGERS is off.
		---------------------------------------------
		If @nRowTotal>0
		Begin
			Insert into CASESEARCHRESULT(FAMILYPRIORARTID,CASEID,PRIORARTID,STATUS,UPDATEDDATE,CASEFIRSTLINKEDTO,CASELISTPRIORARTID,NAMEPRIORARTID,ISCASERELATIONSHIP)
			select distinct CSR.FAMILYPRIORARTID,T.RELATEDCASEID,CSR.PRIORARTID,CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END,CSR.UPDATEDDATE,0,CSR.CASELISTPRIORARTID,CSR.NAMEPRIORARTID,1
			from deleted d
			join CASESEARCHRESULT CSR
						on (CSR.PRIORARTID=d.PRIORARTID
						and isnull(CSR.ISCASERELATIONSHIP,0)=0)
			join @tblRelatedCases T	on (T.MAINCASEID=CSR.CASEID
						and T.DEPTH>1)
			join CASES C		on (C.CASEID=T.RELATEDCASEID)
					---------------------------------------------
					-- If the Case already has been linked to the
					-- search result as a result of some other
					-- relationship, then use the existing Status
					---------------------------------------------
			left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
					from CASESEARCHRESULT
					group by CASEID, PRIORARTID) CS1
						on (CS1.CASEID=T.RELATEDCASEID
						and CS1.PRIORARTID=CSR.PRIORARTID)
					---------------------------------------------
					-- Do not insert the row if it already exists
					---------------------------------------------
			left join CASESEARCHRESULT CS
						on (CS.CASEID    =T.RELATEDCASEID
						and CS.PRIORARTID=CSR.PRIORARTID
						and(CS.FAMILYPRIORARTID  =CSR.FAMILYPRIORARTID   or (CS.FAMILYPRIORARTID   is null and CSR.FAMILYPRIORARTID   is null))
						and(CS.CASELISTPRIORARTID=CSR.CASELISTPRIORARTID or (CS.CASELISTPRIORARTID is null and CSR.CASELISTPRIORARTID is null))
						and(CS.NAMEPRIORARTID    =CSR.NAMEPRIORARTID     or (CS.NAMEPRIORARTID     is null and CSR.NAMEPRIORARTID     is null)) )
					---------------------------------------------
					-- Only interested in Cases flagged to report
					---------------------------------------------
			     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
			left join STATUS ST	on (ST.STATUSCODE=C.STATUSCODE)
			where CS.CASEID is null
			and   CN.PRIORARTFLAG=1
			and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
		End

	End -- @nRowCount>0
End
go
