if exists (select * from sysobjects where type='TR' and name = 'InsertCASESEARCHRESULT_ids')
begin
	PRINT 'Refreshing trigger InsertCASESEARCHRESULT_ids...'
	DROP TRIGGER InsertCASESEARCHRESULT_ids
end
go

Create trigger InsertCASESEARCHRESULT_ids on CASESEARCHRESULT for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASESEARCHRESULT_ids
-- VERSION:	15
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 17 Mar 2011	MF	10361	2	Also a small performance improvement.
-- 03 Apr 2011	MF	10431	3	Use the PRIORARTFLAG to determine the Cases to link.
-- 05 May 2011	MF	10578	4	Do not trigger an Event to update and police if the
--					Prior Art was first linked to the Case.  This is because
--					the IP Office has already notified you of the Prior Art
--					so there is no need to trigger an Information Disclosure
--					Statement (IDS) to inform the IP Office of the Prior Art.
-- 23 Aug 2011	MF	11202	5	Get the IDENTITYID for the POLICING row.
--					If Police Immediately is required then start Policing running
--					asynchronously.
-- 13 May 2013	MF	13484	6	Prior Art Received and Prior Art Report Issued should only generate 
--					new CaseEvent rows for SEARCHRESULTs that are tagged as Source documents.
-- 13 Mar 2014	MF	32391	7	Ensure a different cycle is used for each CASEEVENT that has a different date.
-- 18 Aug 2014	MF	38511	8	Option to force CaseEvent even if the prior art was first linked to the Case. Check 
--					site control or flag against Prior Art Source.
-- 20 Aug 2014	MF	38496	9	Client/Server is not setting the ISSOURCEDOCUMENT flag so need to test for the existence
--					of either of the ISSUEDDATE or RECEIVEDDATE as well.
-- 11 Sep 2017	MF	72037	10	Performance issue on table variable for RelatedCases.  Changed to a temporary table.
-- 27 Mar 2018	MF	73696	11	When two cases were related to each other at the same time, and the Status of at least one of those
--					cases was such that Prior Art was no longer being associated (PRIORARTFLAG=0), then the full set of 
--					prior art for the new extended network of Cases was not flowing to all cases.
-- 10 Oct 2018	MF	DR-44783 12	Ensure that when Events are being generated from the Prior Art to the case, that we only do this for
--					Cases derived from related cases when the Prior Art against the Case is not the Case the prior art 
--					was first linked to. Those cases would have already determined if CaseEvents are required when the
--					prior art was first linked to the case.
-- 17 Jul 2019	MF	DR-50254 13	When the Site Control 'Prior Art To Case Family' is set to TRUE then any Prior Art being linked to 
--					a Case, is also required to flow that prior art through to any other members of the same Family whose
--					Country and Status allows for prior art.
-- 20 Aug 2019	MF	DR-51192 14	Correct collation problem on temporary table.
-- 25 Nov 2019	MF	DR-54470 15	When multiple cycles for the same EVENTNO were being generated, only one of those cycles was being policed.
-- 
	-------------------------------------------------------
	-- For each Case that is being linked to Prior Art, we
	-- need to find every other Case that is related either
	-- directly or indirectly via RELATEDCASE, and also
	-- link those Cases to the Prior Art.
	-------------------------------------------------------

	create table #TEMPRELATEDCASES
		(	MAINCASEID	int		not null,
			RELATEDCASEID	int		not null,
			DEPTH		int		not null,
			FAMILY		nvarchar(50)	collate database_default NULL
		)

	declare @tblCaseEvent table
		(	CASEID		int		not null,
			EVENTNO		int		not null,
			CYCLE		int		null,
			EVENTDATE	datetime	not null,
			SEQUENCENO	int		identity(1,1)
		)

	declare @nRowCount		int
	declare @nRowTotal		int
	declare	@nDepth			int
	declare @nCycle			int
	declare	@nCaseId		int
	declare	@nEventNo		int
	declare @nIdentityId		int
	declare @nPoliceBatchNo		int
	declare @dtEventDate		datetime
	declare	@bFamilyFlag		bit

	Set @nRowCount	=0
	Set @nRowTotal	=0
	Set @bFamilyFlag=0
	Set @nDepth	=1

	-------------------------------------------------
	-- If the Site Control 'Prior Art To Case Family'
	-- is TRUE then the Prior Art just added needs to
	-- flow through to all Cases with the same Family
	-- and any other Families of related cases.
	-------------------------------------------------
	Select @bFamilyFlag=isnull(COLBOOLEAN,0)
	from SITECONTROL
	where CONTROLID='Prior Art To Case Family'

	--If @bFamilyFlag=1
	--Begin
	--	Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	--	Select distinct FS.FAMILYPRIORARTID, C2.CASEID, i.PRIORARTID, NULL, getdate(), 0
	--	from inserted i
	--	join CASES C1			on (C1.CASEID=i.CASEID)		-- Get the Case to find the Family
	--	join CASES C2			on (C2.FAMILY=C1.FAMILY		-- Then gets Cases for that Family
	--					and C2.CASEID<>C1.CASEID)

	--	left join CASESEARCHRESULT CS2	on (CS2.CASEID=C2.CASEID
	--					and CS2.PRIORARTID=i.PRIORARTID)

	--	left join FAMILYSEARCHRESULT FS on (FS.FAMILY=C1.FAMILY
	--					and FS.PRIORARTID=i.PRIORARTID)
	--			---------------------------------------------
	--			-- Only interested in Cases flagged to report
	--			---------------------------------------------
	--	     join COUNTRY CN	on (CN.COUNTRYCODE=C2.COUNTRYCODE)
	--	left join STATUS ST	on (ST.STATUSCODE =C2.STATUSCODE)

	--	where CS2.CASEID is null						-- The prior art does not already exist against the Case
	--	and CN.PRIORARTFLAG = 1
	--	and(ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
	--End
	--------------------------------------------
	-- Only rows being loaded that do not have
	-- the ISCASERELATIONSHIP flag set to 1 are
	-- to trigger the inclusion of related cases
	-- and Case Event insertion.
	-- This is because when a CASESEARCHRESULT
	-- row is deleted it the delete trigger will
	-- remove and reinsert CASESEARCHRESULT rows
	-- that do not need to be processed here.
	--------------------------------------------
	insert into #TEMPRELATEDCASES(MAINCASEID,RELATEDCASEID,DEPTH, FAMILY)
	select i.CASEID, i.CASEID, @nDepth, C.FAMILY
	from inserted i
	left join CASES C on (C.CASEID=i.CASEID
			  and @bFamilyFlag=1)

	-- We also need to share prior art stored
	-- against Cases that are in the same 
	-- Case Family
	UNION
	select C2.CASEID, C2.CASEID, @nDepth, NULL
	from inserted i
	join CASES C1			on (C1.CASEID=i.CASEID)		-- Get the Case to find the Family
	join CASES C2			on (C2.FAMILY=C1.FAMILY		-- Then gets Cases for that Family
					and C2.CASEID<>C1.CASEID)

	join CASESEARCHRESULT CS2	on (CS2.CASEID=C2.CASEID
					and CS2.PRIORARTID=i.PRIORARTID)

	left join FAMILYSEARCHRESULT FS on (FS.FAMILY=C1.FAMILY
					and FS.PRIORARTID=i.PRIORARTID)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
		join COUNTRY CN	on (CN.COUNTRYCODE=C2.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C2.STATUSCODE)

	where @bFamilyFlag=1
	and CN.PRIORARTFLAG = 1
	and(ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)


	set @nRowCount=@@Rowcount
	Set @nRowTotal=@nRowTotal+@nRowCount

	--------------------------------------------
	-- Now loop through each row just added and 
	-- get all of the cases related in any way.
	--------------------------------------------
	While @nRowCount>0
	Begin
		;
		With FamilyUsed(FAMILY)
		as (Select distinct FAMILY
		    from #TEMPRELATEDCASES)
		insert into #TEMPRELATEDCASES(MAINCASEID, RELATEDCASEID, DEPTH, FAMILY)
		select T.MAINCASEID, R.RELATEDCASEID, @nDepth+1, CASE WHEN(F.FAMILY is null) THEN C.FAMILY ELSE NULL END
		from #TEMPRELATEDCASES T
		join RELATEDCASE R	on (R.CASEID=T.RELATEDCASEID)
		join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
					and CR.PRIORARTFLAG=1)
		left join #TEMPRELATEDCASES T1
					on (T1.MAINCASEID   =T.MAINCASEID
					and T1.RELATEDCASEID=R.RELATEDCASEID)
		left join CASES C	on (C.CASEID=R.RELATEDCASEID
					and @bFamilyFlag=1)
		--------------------------------------------
		-- Check if FAMILY has already been included
		--------------------------------------------
		left join FamilyUsed F on (F.FAMILY=C.FAMILY)
		where T.DEPTH=@nDepth
		and T1.MAINCASEID is null
		and R.RELATEDCASEID is not null

		UNION
		select T.MAINCASEID, R.CASEID, @nDepth+1, CASE WHEN(F.FAMILY is null) THEN C.FAMILY ELSE NULL END
		from #TEMPRELATEDCASES T
		join RELATEDCASE R	on (R.RELATEDCASEID=T.RELATEDCASEID)
		join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
					and CR.PRIORARTFLAG=1)
		left join #TEMPRELATEDCASES T1
					on (T1.MAINCASEID   =T.MAINCASEID
					and T1.RELATEDCASEID=R.CASEID)
		left join CASES C	on (C.CASEID=R.CASEID
					and @bFamilyFlag=1)
		--------------------------------------------
		-- Check if FAMILY has already been included
		--------------------------------------------
		left join FamilyUsed F on (F.FAMILY=C.FAMILY)
		where T.DEPTH=@nDepth
		and T1.MAINCASEID is null
		
		-------------------------------------
		-- Get all of the CASES with the same
		-- FAMILY of the current level.
		-- NOTE: We will only have a FAMILY 
		-- value in #TEMPRELATEDCASES when 
		-- @bFamilyFlag = 1.
		-------------------------------------
		UNION
		select T.MAINCASEID, C2.CASEID, @nDepth+1, NULL
		from #TEMPRELATEDCASES T
		join CASES C2			on (C2.FAMILY=T.FAMILY		-- Gets Cases for that Family
						and C2.CASEID not in (T.RELATEDCASEID, T.MAINCASEID))
				---------------------------------------------
				-- Only interested in Cases flagged to report
				---------------------------------------------
			join COUNTRY CN	on (CN.COUNTRYCODE=C2.COUNTRYCODE)
		left join STATUS ST	on (ST.STATUSCODE =C2.STATUSCODE)

		where  T.DEPTH=@nDepth
		and CN.PRIORARTFLAG = 1
		and(ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

		Set @nRowCount=@@ROWCOUNT
		Set @nRowTotal=@nRowTotal+@nRowCount

		set @nDepth=@nDepth+1
	End

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
		select distinct i.FAMILYPRIORARTID,T.RELATEDCASEID,i.PRIORARTID,CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END,i.UPDATEDDATE,0,i.CASELISTPRIORARTID,i.NAMEPRIORARTID,1
		from inserted i
		join #TEMPRELATEDCASES T	on (T.MAINCASEID=i.CASEID
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
					and CS1.PRIORARTID=i.PRIORARTID)
				---------------------------------------------
				-- Do not insert the row if it already exists
				---------------------------------------------
		left join CASESEARCHRESULT CS
					on (CS.CASEID    =T.RELATEDCASEID
					and CS.PRIORARTID=i.PRIORARTID
					and(CS.FAMILYPRIORARTID  =i.FAMILYPRIORARTID   or (CS.FAMILYPRIORARTID   is null and i.FAMILYPRIORARTID   is null))
					and(CS.CASELISTPRIORARTID=i.CASELISTPRIORARTID or (CS.CASELISTPRIORARTID is null and i.CASELISTPRIORARTID is null))
					and(CS.NAMEPRIORARTID    =i.NAMEPRIORARTID     or (CS.NAMEPRIORARTID     is null and i.NAMEPRIORARTID     is null)) )
				---------------------------------------------
				-- Only interested in Cases flagged to report
				---------------------------------------------
		     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
		left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
		where CS.CASEID is null
		and   CN.PRIORARTFLAG=1
		and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
	
		---------------------------------------------
		-- For each Case linked to Prior Art we will
		-- insert a CASEEVENT that is mapped via a
		-- Site Control to an EventNo.
		---------------------------------------------
		-- Do not insert a CaseEvent for the Caseid,
		-- EventNo that matches an existing date.
		--
		-- Increment the cycle if the Event has been
		-- previously entered with a different date.
		---------------------------------------------

		Insert into @tblCaseEvent (CASEID, EVENTNO, EVENTDATE, CYCLE) 
		select  T3.CASEID, T3.EVENTNO, T3.EVENTDATE, isnull(CE1.CYCLE,0)+1
		from (	Select DISTINCT
			T2.CASEID,
			T1.COLINTEGER AS EVENTNO, 
			case	when T1.CONTROLID ='Prior Art Received'		then T2.RECEIVEDDATE
				when T1.CONTROLID ='Prior Art Report Issued'	then T2.ISSUEDDATE 
			end as EVENTDATE
				-----------------------------------------------
				-- Get the EventNo that the dates are mapped to
				-----------------------------------------------
			from SITECONTROL T1
			cross join
			     (	select	i.CASEID,
					coalesce(SR.ISSUEDDATE,  PA.ISSUEDDATE  ) as ISSUEDDATE, 
					coalesce(SR.RECEIVEDDATE,PA.RECEIVEDDATE) as RECEIVEDDATE
				from inserted i
				join SEARCHRESULTS PA	on (PA.PRIORARTID=i.PRIORARTID)
				left join SITECONTROL S on (S.CONTROLID='Ignore Case First Linked To')
				left join TABLECODES TC on (TC.TABLECODE=PA.SOURCE)
				left join REPORTCITATIONS RC
							on (RC.CITEDPRIORARTID=i.PRIORARTID)
				left join SEARCHRESULTS SR	
							on (SR.PRIORARTID=RC.SEARCHREPORTID)
				where (isnull(i.CASEFIRSTLINKEDTO,0)=0 OR S.COLBOOLEAN=1 OR TC.BOOLEANFLAG=1)	-- RFC10578 & RFC38511
				and (PA.ISSOURCEDOCUMENT=1 or PA.ISSUEDDATE is not null or PA.RECEIVEDDATE is not null)	-- RFC13484 & RFC38496
				UNION
				select	R.RELATEDCASEID, 
					coalesce(SR.ISSUEDDATE,  PA.ISSUEDDATE  ) as ISSUEDDATE, 
					coalesce(SR.RECEIVEDDATE,PA.RECEIVEDDATE) as RECEIVEDDATE
				from inserted i
				join SEARCHRESULTS PA	on (PA.PRIORARTID=i.PRIORARTID
							and(PA.ISSOURCEDOCUMENT=1 or PA.ISSUEDDATE is not null or PA.RECEIVEDDATE is not null))	-- RFC13484 & RFC38496
				join #TEMPRELATEDCASES R	
							on (R.MAINCASEID=i.CASEID
							and R.DEPTH>1)
				join CASESEARCHRESULT CS		-- DR-44783
							on (CS.CASEID=R.RELATEDCASEID
							and CS.PRIORARTID=i.PRIORARTID
							and CS.CASEFIRSTLINKEDTO=0)
				left join REPORTCITATIONS RC
							on (RC.CITEDPRIORARTID=i.PRIORARTID)
				left join SEARCHRESULTS SR	
							on (SR.PRIORARTID=RC.SEARCHREPORTID) ) AS T2
			Where T1.CONTROLID  in ('Prior Art Received', 
						'Prior Art Report Issued')
			and   T1.COLINTEGER is not null  ) as T3
			--------------------------------------------------------
			-- Get the current highest cycle for any of the Events 
			-- that might be inserted as we will generate the next
			-- cycle for all Events for the Case.
			--------------------------------------------------------
		left join (select CASEID, max(CYCLE) as CYCLE
			   from CASEEVENT CE
			   join SITECONTROL SC	on (SC.CONTROLID in ('Prior Art Received','Prior Art Report Issued')
						and SC.COLINTEGER=CE.EVENTNO)
			   group by CASEID) CE1
					on (CE1.CASEID=T3.CASEID)
			--------------------------------------------------------
			-- No CASEEVENT row will be inserted if there is already
			-- a matching row with the identical Event Date
			--------------------------------------------------------
		left join CASEEVENT CE2	on (CE2.CASEID   =T3.CASEID
					and CE2.EVENTNO  =T3.EVENTNO
					and CE2.EVENTDATE=T3.EVENTDATE)
		where T3.EVENTDATE is not null 
		and T3.EVENTNO is not null
		and CE2.CASEID is null -- The CaseEvent for the same date must not already exist
		order by 1,2,3

		------------------------------------------------------
		-- If multiple rows exist for CASEEVENT with different
		-- event dates then increment the cycle
		------------------------------------------------------
		Update @tblCaseEvent
		Set	@nCycle=CASE WHEN(@nCaseId=CASEID and @nEventNo=EVENTNO and @dtEventDate<>EVENTDATE)
					THEN @nCycle+1
					ELSE CYCLE
				END,
			@nCaseId    =CASEID,
			@nEventNo   =EVENTNO,
			@dtEventDate=EVENTDATE,
			CYCLE       =@nCycle


		--------------------------------------------------------
		-- RFC32391
		-- Each of the generated Case Event rows will now be
		-- inserted into the CASEEVENT table with the next 
		-- available Cycle.
		--------------------------------------------------------
		Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
		select distinct CASEID, EVENTNO, CYCLE, EVENTDATE, 1
		from @tblCaseEvent

		Set @nRowTotal=@@ROWCOUNT

		If @nRowTotal>0
		Begin
			--------------------------------------------------------
			-- Get the IdentityId of the connected user to include
			-- in the Policing rows to be inserted.
			--------------------------------------------------------
			select	@nIdentityId = cast(substring(context_info,1,4)  as int)
			from master.dbo.sysprocesses
			where spid=@@SPID
			and(substring(context_info,1, 4)<>0x0000000)

			If exists(Select 1 from SITECONTROL WITH(NOLOCK) where CONTROLID='Police Immediately' and COLBOOLEAN=1)
			Begin		
				------------------------------------------------------
				-- Get the Batchnumber to use for Police Immediately.
				-- BatchNumber is relatively shortlived so reset it
				-- by incrementing the maximum BatchNo on the Policing
				-- table.
				------------------------------------------------------
				Update LASTINTERNALCODE
				set INTERNALSEQUENCE=P.BATCHNO+1,
				    @nPoliceBatchNo =P.BATCHNO+1
				from LASTINTERNALCODE L
				cross join (select max(isnull(BATCHNO,0)) as BATCHNO
					    from POLICING with(NOLOCK)) P
				where TABLENAME='POLICINGBATCH'

				Set @nRowTotal=@@Rowcount

				If @nRowTotal=0
				Begin
					Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
					values ('POLICINGBATCH', 0)
					
					set @nPoliceBatchNo=0
				End
			End

			--------------------------------------------------------
			-- Create a Policing row to be processed by the Policing
			-- Server in background for each CaseEvent row inserted.
			--------------------------------------------------------
			Insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, BATCHNO, SQLUSER, IDENTITYID)
			select 	getdate(), T1.SEQUENCENO, convert(varchar, getdate(), 121)+' '+convert(varchar, T1.SEQUENCENO), 
				1, 
				CASE WHEN(@nPoliceBatchNo is not null) THEN 1 ELSE 0 END, 
				T1.EVENTNO, T1.CASEID, T1.CYCLE, 3, @nPoliceBatchNo, SYSTEM_USER, @nIdentityId 
			from @tblCaseEvent T1
			left join @tblCaseEvent T2	on (T2.CASEID =T1.CASEID
							and T2.EVENTNO=T1.EVENTNO
							and T2.CYCLE  =T1.CYCLE
							and T2.SEQUENCENO<T1.SEQUENCENO)
			where T2.CASEID is null

			If @nPoliceBatchNo is not null
			Begin
				--------------------------------------------------------
				-- If Policing is to be run immediately then the batchno
				-- used on the Policing rows will be passed to Policing
				-- to be run asynchronously.
				--------------------------------------------------------
				exec dbo.ipu_Policing_async
							@pnBatchNo=@nPoliceBatchNo,
							@pnUserIdentityId=@nIdentityId
			End
		End
	End
End -- End of trigger
go
