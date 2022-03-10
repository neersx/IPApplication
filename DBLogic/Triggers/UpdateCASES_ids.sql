if exists (select * from sysobjects where type='TR' and name = 'UpdateCASES_ids')
begin
	PRINT 'Refreshing trigger UpdateCASES_ids...'
	DROP TRIGGER UpdateCASES_ids
end
go

Create trigger UpdateCASES_ids on CASES for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCASES_ids    
-- VERSION:	6
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 03 Apr 2011	MF	10431	2	Use the PRIORARTFLAG to determine the Cases to link.
-- 03 May 2011	MF	10548	3	Insert the CASESEARCHRESULT row even if the Case is already
--					linked to the Prior Art as a related Case.
-- 15 Jun 2015	MF	45361	4	If the Status of the case is changing from one that did not
--					require Prior Art to be reported to one that does require
--					Prior Art, then trigger the distribution of Prior Art.
-- 04 Aug 2017	MF	72112	5	Change the call to start Policing asynchronously to use ipu_ScheduleAsyncCommand.
-- 17 Jul 2019	MF	DR-50254 6	A Case that is having its FAMILY updated, is to also receive all the Prior Art associated with 
--					any Case that is a member of the same family if the Site Control "Prior Art To Case Family"
--					is set to true.  Also, any Prior Art associated with the Case being updated is to flow to
--					other members of the same family. 
--					If the Site Control is false then continue to only link Prior Art that has explicitly been 
--					linked to a Family.

Begin
------------------------------------
-- Process any changes to the Family
-- or the StatusCode of the Case.
------------------------------------
If    ( Update(FAMILY) OR Update(STATUSCODE) )
and NOT Update(LOGDATETIMESTAMP)
Begin
	If exists (select 1 from SITECONTROL where CONTROLID='Prior Art To Case Family' and COLBOOLEAN=1)
	Begin
		-------------------------------------------------------
		-- If the FAMILY of the Case has been updated, then
		-- any Prior Art that is associated with any Case that
		-- has the same FAMILY is to be attached to this Case.
		-------------------------------------------------------
		Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP, CASEFIRSTLINKEDTO)
		Select distinct FS.FAMILYPRIORARTID, i.CASEID, CS1.PRIORARTID, NULL, getdate(), 0, 0
		from inserted i
		join deleted d			on (d.CASEID=i.CASEID)
		join CASES C			on (C.FAMILY=i.FAMILY)		-- Get all Cases that belong to the same Family
		join CASESEARCHRESULT CS1	on (CS1.CASEID=C.CASEID)	-- Get all prior art associated with that Case
		left join CASESEARCHRESULT CS2	on (CS2.CASEID=i.CASEID
						and CS2.PRIORARTID=CS1.PRIORARTID)
		left join FAMILYSEARCHRESULT FS on (FS.FAMILY=i.FAMILY
						and FS.PRIORARTID=CS1.PRIORARTID)
				---------------------------------------------
				-- Only interested in Cases flagged to report
				---------------------------------------------
		     join COUNTRY CN	on (CN.COUNTRYCODE=i.COUNTRYCODE)
		left join STATUS ST	on (ST.STATUSCODE =i.STATUSCODE)

		where i.FAMILY <> isnull(d.FAMILY,'')				-- Family has a value that has changed
		and CS2.CASEID is null						-- The prior art does not already exist against the Case
		and CN.PRIORARTFLAG = 1
		and(ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

		
		-------------------------------------------------------
		-- Also, any Prior Art associated to the Case just 
		-- updated, is to be shared with all other Cases that 
		-- are members of the same family.
		-------------------------------------------------------		
		Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP, CASEFIRSTLINKEDTO)
		select distinct NULL, C.CASEID, CS1.PRIORARTID, NULL, getdate(), 0, 0
		from inserted i
		join deleted d			on (d.CASEID=i.CASEID)
		join CASESEARCHRESULT CS1	on (CS1.CASEID=i.CASEID)
		join CASES C			on (C.FAMILY=i.FAMILY)
		left join CASESEARCHRESULT CS2	on (CS2.CASEID=C.CASEID
						and CS2.PRIORARTID=CS1.PRIORARTID)
				---------------------------------------------
				-- Only interested in Cases flagged to report
				---------------------------------------------
		     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
		left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)

		Where i.FAMILY <> isnull(d.FAMILY,'')
		and CS2.CASEID is null					-- The prior art does not already exist against the Case
		and CN.PRIORARTFLAG = 1
		and(ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
	End

	Else If exists(Select 1 from FAMILYSEARCHRESULT)
	Begin
		-------------------------------------------------------
		-- Cases may be inserted that are linked to a Family.
		-- If the Family is associated with a Search Result
		-- (Source Document or Prior Art) then the Case should
		-- be linked to the Prior Art.
		-------------------------------------------------------
		Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP, CASEFIRSTLINKEDTO)
		Select distinct F.FAMILYPRIORARTID, i.CASEID, F.PRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0, 0
		From inserted i
		join deleted d		on (d.CASEID=i.CASEID)
		join FAMILYSEARCHRESULT F
					on (F.FAMILY=i.FAMILY)
		join SEARCHRESULTS S	on (S.PRIORARTID=F.PRIORARTID)
		left join TABLECODES T	on (T.TABLECODE=S.SOURCE)
				---------------------------------------------
				-- If the Case already has been linked to the
				-- search result as a result of some other
				-- relationship, then use the existing Status
				---------------------------------------------
		left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
				from CASESEARCHRESULT
				group by CASEID, PRIORARTID) CS1
					on (CS1.CASEID=i.CASEID
					and CS1.PRIORARTID=F.PRIORARTID)
				---------------------------------------------
				-- Do not insert the row if it already exists
				---------------------------------------------
		left join CASESEARCHRESULT CS2 
					on (CS2.FAMILYPRIORARTID=F.FAMILYPRIORARTID
					and CS2.CASEID=i.CASEID
					and CS2.PRIORARTID=F.PRIORARTID
					and isnull(CS2.ISCASERELATIONSHIP,0)=0)
				---------------------------------------------
				-- Only interested in Cases flagged to report
				---------------------------------------------
		     join COUNTRY CN	on (CN.COUNTRYCODE=i.COUNTRYCODE)
		left join STATUS ST	on (ST.STATUSCODE =i.STATUSCODE)
		where (d.FAMILY<>i.FAMILY or (d.FAMILY is null and i.FAMILY is not null))
		and (T.BOOLEANFLAG=1 OR isnull(S.ISSOURCEDOCUMENT,0)=0)
		and  CS2.CASEID is null
		and   CN.PRIORARTFLAG=1
		and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

		-------------------------------------------------------
		-- Case linked to a Family associated with Source Doc.
		-- A Source Document may bundle together any number of
		-- cited Search Results (prior art). When a Family is
		-- associated with a Source Document it should create
		-- links for Cases belonging to the Family to each
		-- Search Result linked to the Source Document.
		-- If a Case is inserted with such a Family then the
		-- Case must be linked to all of the cited Prior Art.
		-- NOTE: The Source Document itself has already 
		--       been linked directly to the Case in the
		--       previous Insert.
		-------------------------------------------------------
		Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP, CASEFIRSTLINKEDTO)
		Select distinct F.FAMILYPRIORARTID, i.CASEID, R.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0, 0
		From inserted i
		join FAMILYSEARCHRESULT F
					on (F.FAMILY=i.FAMILY)
		join SEARCHRESULTS S	on (S.PRIORARTID=F.PRIORARTID)
				---------------------------------------------
				-- Find prior art cited in Source Document
				---------------------------------------------
		join REPORTCITATIONS R	on (R.SEARCHREPORTID=S.PRIORARTID)
				---------------------------------------------
				---------------------------------------------
				-- If the Case already has been linked to the
				-- search result as a result of some other
				-- relationship, then use the existing Status
				---------------------------------------------
		left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
				from CASESEARCHRESULT
				group by CASEID, PRIORARTID) CS1
					on (CS1.CASEID=i.CASEID
					and CS1.PRIORARTID=R.CITEDPRIORARTID)
				---------------------------------------------
				-- Do not insert the row if it already exists
				---------------------------------------------
		left join CASESEARCHRESULT CS2 
					on (CS2.FAMILYPRIORARTID=F.FAMILYPRIORARTID
					and CS2.CASEID=i.CASEID
					and CS2.PRIORARTID=R.CITEDPRIORARTID
					and isnull(CS2.ISCASERELATIONSHIP,0)=0)
				---------------------------------------------
				-- Only interested in Cases flagged to report
				---------------------------------------------
		     join COUNTRY CN	on (CN.COUNTRYCODE=i.COUNTRYCODE)
		left join STATUS ST	on (ST.STATUSCODE =i.STATUSCODE)
		where S.ISSOURCEDOCUMENT=1
		and  CS2.CASEID is null
		and   CN.PRIORARTFLAG=1
		and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

		-------------------------------------------------------
		-- If the FAMILY against a CASE has been updated then
		-- that Case needs to be removed from PriorArt that
		-- was associated with the Family.
		-------------------------------------------------------
		-- NOTE : The removal of the old CASESEARCHRESULT is
		--        after the new changes have been applied.
		--        This is so we can use the existing Status 
		--        if the Case ends up being associated with the
		--        same Prior Art but from the perspective of a
		--        different Family.
		-------------------------------------------------------                                            
		Delete CSR
		from deleted d
		join inserted i		on (i.CASEID=d.CASEID)
		join FAMILYSEARCHRESULT F
					on (F.FAMILY=d.FAMILY)
		join CASESEARCHRESULT CSR
					on (CSR.FAMILYPRIORARTID=F.FAMILYPRIORARTID
					and CSR.CASEID=d.CASEID)
		Where (i.FAMILY<>d.FAMILY or (i.FAMILY is null and d.FAMILY is not null))
End
End
------------------------------------
-- If the Status is changing to one
-- that now requires Prior Art then
-- we need to consider the Prior Art
-- currently linked to cases in the 
-- extended related case family.
------------------------------------
If      Update(STATUSCODE)
and NOT Update(LOGDATETIMESTAMP)
and exists(Select 1 from CASESEARCHRESULT)
Begin
	-------------------------------------------------------
	-- For each Case whose Status is changing from one that
	-- previously did not require Prior Art to a status 
	-- that now does require Prior Art, then a Policing 
	-- request will be inserted to perform the copying of
	-- prior art.
	-------------------------------------------------------

	declare @tblPolicing table
		(	CASEID		int		not null,
			SEQUENCENO	int		identity(1,1)
		)

	declare @nRowCount		int
	declare @nErrorCode		int

	Set @nRowCount = 0
	Set @nErrorCode= 0
	
	insert into @tblPolicing(CASEID)
	select distinct i.CASEID
	from inserted i
	left join STATUS S1 on (S1.STATUSCODE=i.STATUSCODE)
	join deleted d	    on (d.CASEID=i.CASEID)
	join STATUS S2      on (S2.STATUSCODE=d.STATUSCODE
			    and S2.PRIORARTFLAG=0)	-- Prior Art previously was not required
	where isnull(S1.PRIORARTFLAG,1)=1		-- Prior Art is required			

	Select @nRowCount=@@Rowcount,
	       @nErrorCode=@@ERROR	

	--------------------------------------------
	-- Insert the POLICING rows
	--------------------------------------------
	If  @nRowCount>0
	and @nErrorCode=0
	Begin
		declare @nIdentityId		int
		declare @nSessionTransNo	int
		declare @nEDEBatchNo		int
		declare @nBatchNo		int
		declare	@nObject		int
		declare	@bObjectExist		bit
		declare	@sCommand		varchar(255)
		declare @dtCurrentDate		datetime
		
		set @dtCurrentDate=GETDATE()
		
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
						
		------------------------------------------------------
		-- Get the Batch Number to use for Police Immediately.
		-- BatchNumber is relatively shortlived so reset it
		-- by incrementing the maximum BatchNo on the Policing
		-- table.
		------------------------------------------------------
		If @nErrorCode=0
		Begin
			Update LASTINTERNALCODE
			set INTERNALSEQUENCE=P.BATCHNO+1,
			    @nBatchNo       =P.BATCHNO+1
			from LASTINTERNALCODE L
			cross join (select max(isnull(BATCHNO,0)) as BATCHNO
				    from POLICING with(NOLOCK)) P
			where TABLENAME='POLICINGBATCH'

			Select @nRowCount =@@Rowcount,
			       @nErrorCode=@@ERROR

			If  @nRowCount=0
			and @nErrorCode=0
			Begin
				Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
				values ('POLICINGBATCH', 0)
				
				set @nBatchNo=0
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
				BATCHNO,
				IDENTITYID
			)
			Select	
				@dtCurrentDate,
				P.SEQUENCENO,
				dbo.fn_DateToString(@dtCurrentDate,'CLEAN-DATETIME') + cast(P.SEQUENCENO as nvarchar),
				1,
				1,
				P.CASEID,
				SYSTEM_USER,
				9,			-- Type of Request to distribute Prior Art
				@nBatchNo,
				@nIdentityId
			From @tblPolicing P
			join CASES C on (C.CASEID=P.CASEID)

			Select @nRowCount =@@Rowcount,
			       @nErrorCode=@@ERROR
		End
	End
	
	If @nRowCount>0
	and @nErrorCode=0
	Begin
		-----------------------------------------
		-- If POLICING rows have been inserted
		-- then build command line to run 
		-- ipu_Policing asynchronously.
		-----------------------------------------
		Set @sCommand = 'dbo.ipu_Policing '

		Set @sCommand = @sCommand 
				+ 'null,'				-- @pdtPolicingDateEntered
				+ 'null,'				-- @pnPolicingSeqNo
				+ 'null,'				-- @pnDebugFlag
				+ convert(varchar,@nBatchNo) + ','	-- @pnBatchNo
				+ ''''','				-- @psDelayLength

		If @nIdentityId is null
			Set @sCommand = @sCommand + 'null,'
		else
			Set @sCommand = @sCommand + convert(varchar,@nIdentityId) + ','
			

		Set @sCommand = @sCommand + 'null,'			-- @psPolicingMessageTable
				+ '1,'					-- @pnAsynchronousFlag

		If @nSessionTransNo is null
		or @nSessionTransNo = 0
			Set @sCommand = @sCommand + 'null,'		-- @pnSessionTransNo
		else
			Set @sCommand = @sCommand + convert(varchar,@nSessionTransNo) + ','

		If @nEDEBatchNo is null
		or @nEDEBatchNo = 0
			Set @sCommand = @sCommand + 'null'		-- @pnEDEBatchNo
		else
			Set @sCommand = @sCommand + convert(varchar,@nEDEBatchNo)
		
		---------------------------------------------------------------
		-- Run the command asynchronously using Servie Broker (rfc-39102)
		--------------------------------------------------------------- 
		exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand
	End
End

End -- End trigger
go
