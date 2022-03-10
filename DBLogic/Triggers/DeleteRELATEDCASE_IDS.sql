if exists (select * from sysobjects where type='TR' and name = 'DeleteRELATEDCASE_IDS')
begin
	PRINT 'Refreshing trigger DeleteRELATEDCASE_IDS...'
	DROP TRIGGER DeleteRELATEDCASE_IDS
end
go

CREATE TRIGGER DeleteRELATEDCASE_IDS
ON RELATEDCASE
FOR DELETE NOT FOR REPLICATION AS
Begin
-- TRIGGER:	DeleteRELATEDCASE_IDS  
-- VERSION:	1
-- DESCRIPTION:	When a RELATEDCASE row is deleted 
--		we need to attempt to reset the PRIORART that 
--		previously propagated between what was the extended
--		Case family.
--		To do this we will :
--		1. Identify the extended related case family using relationships BEFORE the deleted RelatedCase (this will move up and down the related case tree);
--		2. Now delete Prior Art against the Cases in the extended family if:
--			a. Prior Art Status on Case is NULL
--			b. CaseFirstLinkedTo is NULL or 0 (this means we are keeping Prior Art explicitly first linked to a case)
--			c. FamilyPriorArtID is null AND CaseListPriorArtID is null and NamePriorArtID is null
--			d. IsCaseRelationship=1 (we are deleting the prior art that propagated because of related cases)
--		3. Generate a Policing request to recalculate the Prior Art links (TYPEOFREQUEST=9) for both the Parent and the Child cases whose RelatedCase was just deleted.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30-Jul-2019	MF	DR-50628 1	Trigger created

	declare @nErrorCode	int
	declare	@nRowCount	int
	declare @nRowTotal	int
	declare	@nDepth		int

	-------------------------------------------------------
	-- In order to determine which Cases Prior Art we need
	-- to reset after the deletion of a Related Case, we 
	-- need to find every other case that is related either
	-- directly or indirectly via RELATEDCASE so we can 
	-- remove those linked because of a Related Case, and 
	-- then retrigger the propagation as a reset.
	-------------------------------------------------------

	create table #TEMPRELATEDCASES
		(	MAINCASEID	int		not null,
			RELATEDCASEID	int		not null,
			DEPTH		int		not null,
			SEQUENCENO	int		identity(1,1)
		)
	
	Set @nErrorCode =0		
	Set @nRowCount	=0
	Set @nRowTotal	=0
	Set @nDepth	=1

	
	--------------------------------------------------
	-- We only need to consider prior art if it exists
	-- against a Case and the flags allow for it to
	-- propagate.
	--------------------------------------------------
	If  exists (select 1 from STATUS       where PRIORARTFLAG=1)
	and exists (select 1 from COUNTRY      where PRIORARTFLAG=1)
	and exists (select 1 from CASERELATION where PRIORARTFLAG=1)
	and exists (select 1 from CASESEARCHRESULT)
	and @nErrorCode = 0
	Begin
	
		--------------------------------------------
		-- Both the parent and the child case from
		-- RelatedCase that is being deleted, needs
		-- to to be considered when getting the
		-- extended case family.
		--------------------------------------------
		insert into #TEMPRELATEDCASES(MAINCASEID,RELATEDCASEID,DEPTH)
		-- Parent Case
		select d.CASEID, d.CASEID, @nDepth
		from deleted d

		UNION
		-- Child Case
		select d.RELATEDCASEID, d.RELATEDCASEID, @nDepth
		from deleted d
		where d.RELATEDCASEID is not null

		select @nRowCount =@@ROWCOUNT,
		       @nErrorCode=@@ERROR

		--------------------------------------------
		-- Now loop through each row just added and 
		-- get all of the cases related in any way.
		--------------------------------------------
		While @nRowCount>0
		and @nErrorCode=0
		Begin
		
			insert into #TEMPRELATEDCASES(MAINCASEID, RELATEDCASEID, DEPTH)
			select T.MAINCASEID, R.RELATEDCASEID, @nDepth+1
			from #TEMPRELATEDCASES T
			join RELATEDCASE R	on (R.CASEID=T.RELATEDCASEID)
			join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
						and CR.PRIORARTFLAG=1)
			left join #TEMPRELATEDCASES T1
						on (T1.MAINCASEID   =T.MAINCASEID
						and T1.RELATEDCASEID=R.RELATEDCASEID)
			where T.DEPTH=@nDepth
			and T1.MAINCASEID is null
			and R.RELATEDCASEID is not null

			UNION
			select T.MAINCASEID, R.CASEID, @nDepth+1
			from #TEMPRELATEDCASES T
			join RELATEDCASE R	on (R.RELATEDCASEID=T.RELATEDCASEID)
			join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
						and CR.PRIORARTFLAG=1)
			left join #TEMPRELATEDCASES T1
						on (T1.MAINCASEID   =T.MAINCASEID
						and T1.RELATEDCASEID=R.CASEID)
			where T.DEPTH=@nDepth
			and T1.MAINCASEID is null

			Select @nRowCount =@@ROWCOUNT,
			       @nErrorCode=@@ERROR
			Set @nRowTotal=@nRowTotal+@nRowCount

			set @nDepth=@nDepth+1
		End
	

		If  @nRowTotal>0
		and @nErrorCode=0
		Begin
			------------------------------------------------------------------------------------------------------------------
			-- Now that we have the extended Case family we can delete the Prior Art from each member where :
			--	a. Prior Art Status on Case is NULL
			--	b. CaseFirstLinkedTo is NULL or 0 (this means we are keeping Prior Art explicitly first linked to a case)
			--	c. FamilyPriorArtID is null AND CaseListPriorArtID is null and NamePriorArtID is null
			--	d. IsCaseRelationship=1 (we are deleting the prior art that propagated because of related cases)
			------------------------------------------------------------------------------------------------------------------
			Delete CSR
			from #TEMPRELATEDCASES T
			join CASESEARCHRESULT CSR on (CSR.CASEID=T.RELATEDCASEID)
			where CSR.STATUS is null
			and isnull(CSR.CASEFIRSTLINKEDTO, 0) = 0
			and CSR.FAMILYPRIORARTID   is null
			and CSR.CASELISTPRIORARTID is null
			and CSR.NAMEPRIORARTID     is null
			and CSR.ISCASERELATIONSHIP = 1

			Select @nRowCount =@@ROWCOUNT,
			       @nErrorCode=@@ERROR
		End

		
		-------------------------------------------------------
		-- For each Case whose Related Case has been deleted,
		-- a POLICING row will be inserted for the same BATCHNO
		-- and Policing will then be started asynchronously to
		-- process that batch.
		-------------------------------------------------------
		If  @nRowCount >0
		and @nErrorCode=0
		Begin
		
			declare @nIdentityId		int
			declare @nSessionTransNo	int
			declare @nEDEBatchNo		int
			declare @nPolicingSeq		int
			declare @bPoliceImmediately	bit
			declare @dtCurrentDate		datetime
				
			set @dtCurrentDate=GETDATE()
				
			-- generate key					
			If @nErrorCode = 0
			Begin										
				Select 	@nPolicingSeq = isnull(max(POLICINGSEQNO) + 1, 0)
				from	POLICING
				where 	DATEENTERED = @dtCurrentDate
				
				If @nPolicingSeq is null
					Set @nPolicingSeq = 0

				Set @nErrorCode = @@error
			End	
				
			------------------------------------------
			-- Get the IDENTITYID of the current user.
			-- This will be used in POLICING request.
			------------------------------------------
			select	@nIdentityId    =CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4) as int) END,
				@nSessionTransNo=CASE WHEN(substring(context_info,5,4) <>0x0000000) THEN cast(substring(context_info,5,4) as int) END,
				@nEDEBatchNo    =CASE WHEN(substring(context_info,9,4) <>0x0000000) THEN cast(substring(context_info,9,4) as int) END
			from master.dbo.sysprocesses
			where spid=@@SPID
			and(substring(context_info,1,4)<>0x0000000
			OR  substring(context_info,5,4)<>0x0000000
			OR  substring(context_info,9,4)<>0x0000000)
				
			Set @nErrorCode=@@ERROR
				
			-------------------------
			-- Get the current userid 
			-------------------------
			If (@nIdentityId is null or @nIdentityId='')
			and @nErrorCode=0
			Begin
				Select @nIdentityId=min(IDENTITYID)
				from USERIDENTITY
				where LOGINID=substring(SYSTEM_USER,1,50)
					
				Set @nErrorCode=@@ERROR
			End
				
			-----------------------------------------------------
			-- If Policing Immediate is on and  Police Continuously 
			-- is NOT active then start it.
			-- We want policing request to be processed by the server 
			-- instead of separate asynchronous process to avoid dead lock.
				
			-- If Policing Immediately is off then it may imply that 
			-- the Policing Server is running.  Therefore we do not
			-- want to start the Policing Continuously. 
				
			-- The intention is to avoid Policing Server and Policing backgound 
			-- running simultaneously and the Prior Art requests are 
			-- to be policed by a separate process (i.e. not the calling program).
			-----------------------------------------------------
			If @nErrorCode=0
			Begin
				If not exists(select 1 from SITECONTROL where CONTROLID='Police Continuously' and COLBOOLEAN=1)
					and exists(select 1 from SITECONTROL where CONTROLID in ('Police Immediately', 'Police Immediate in Background') and COLBOOLEAN=1)
				Begin						
					-- start policing continuously background
					exec ipu_Policing_Start_Continuously
					Set @nErrorCode=@@ERROR
				End
			End
								
			------------------------------------------
			-- Insert the POLICING rows to trigger the
			-- prior art distribution.  The BATCHNO
			-- will have the same value for each row.
			------------------------------------------
			If @nErrorCode=0
			Begin			 
				Insert Into POLICING
				(	DATEENTERED,
					POLICINGSEQNO,
					POLICINGNAME,	
					SYSGENERATEDFLAG,
					ONHOLDFLAG,
					CASEID,
					SQLUSER,
					TYPEOFREQUEST,
					IDENTITYID
				)
				Select	
					@dtCurrentDate,
					T.SEQUENCENO+@nPolicingSeq,
					dbo.fn_DateToString(@dtCurrentDate,'CLEAN-DATETIME') + cast(T.SEQUENCENO+@nPolicingSeq as nvarchar),
					1,
					0,			-- un-hold the request to allow policing continous to pick up
					T.RELATEDCASEID,
					SYSTEM_USER,
					9,			-- Type of Request to distribute Prior Art
					@nIdentityId
				From #TEMPRELATEDCASES T
				join CASES C on (C.CASEID=T.RELATEDCASEID)
				Where T.DEPTH=1

				Select @nRowCount =@@Rowcount,
					@nErrorCode=@@ERROR
			End
		End

	End
End	
go	