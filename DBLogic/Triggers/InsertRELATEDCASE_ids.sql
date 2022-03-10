if exists (select * from sysobjects where type='TR' and name = 'InsertRELATEDCASE_ids  ')
begin
	PRINT 'Refreshing trigger InsertRELATEDCASE_ids  ...'
	DROP TRIGGER InsertRELATEDCASE_ids  
end
go

Create trigger InsertRELATEDCASE_ids   on RELATEDCASE for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertRELATEDCASE_ids    
-- VERSION:	9
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 03 Apr 2011	MF	10431	2	Use the PRIORARTFLAG to determine the Cases to link.
-- 10 May 2011	MF	10600	3	The CASERFIRSTLINKEDTO should be set off.
-- 06 Mar 2015	MF	45361	4	A new related case may not directly be able to received prior art
--					or push prior art to the directly related case. In that situation it
--					needs to traverse the entire related case tree and find at least one
--					prior art that can be pushed into another Case in that tree.  This will
--					then trigger all of the associated prior art to be disseminated correctly.
-- 14 Mar 2015	MF	45361	5	Rework to improve performance for large families with large amount of prior art.
-- 11 Jun 2015	MF	45361	6	Further rework to cater for extremely large volume of prior art distribution by
--					pushing the changes into Policing so it can be run asynchronously.
-- 11 Nov 2015	MF	54110	7	Policing should only be started asynchronously if the firm default is to Police Immediately.
--					This is because when Police Continuously or the Policing Server are running on a fast refresh
--					rate, we have found that deadlock errors can occur.
-- 18 Nov 2015	DV	55289	8	Calculate the sequence from the max value in the POLICING table for avoiding duplicate 
--					keys being inserted.
-- 25 Feb 2016	DL	57674	9	Remove launching of policing asynchronously as it can cause deadlock.  
--					Start policing Continuously if it has not started and submit policing request to this queue.

	If  exists (select 1 from STATUS       where PRIORARTFLAG=1)
	and exists (select 1 from COUNTRY      where PRIORARTFLAG=1)
	and exists (select 1 from CASERELATION where PRIORARTFLAG=1)
	Begin
		---------------------------------------------------------------
		-- If rows exist in CASESEARCHRESULT with CASETYPE/PROPERTYTYPE
		-- that match on any CASE in the modified RELATEDCASE row
		-- and the PRIORARTFLAG is turned on for at least one row in 
		-- each of the STATUS, COUNTRY and CASERELATION tables then we
		-- need to consider the extended set of related Cases to ensure 
		-- all Prior Art is distributed across all of those
		-- Cases where Prior Art is reportable.
		---------------------------------------------------------------	
		If  exists (select 1
			    from (SELECT distinct C1.CASETYPE, C1.PROPERTYTYPE 
				  from inserted i 
				  join CASES C1 on (C1.CASEID=i.CASEID)) X
			    join (SELECT distinct C2.CASETYPE, C2.PROPERTYTYPE
				  from CASESEARCHRESULT CS
				  join CASES C2 on (C2.CASEID=CS.CASEID)) Y on (Y.CASETYPE    =X.CASETYPE
									    and Y.PROPERTYTYPE=X.PROPERTYTYPE))
		Begin	
			-------------------------------------------------------
			-- For each Case whose Related Case is being updated 
			-- a POLICING row will be inserted for the same BATCHNO
			-- and Policing will then be started asynchronously to
			-- process that batch.
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
				declare @bPoliceImmediately	bit
				declare	@sCommand		varchar(255)
				declare @dtCurrentDate		datetime
				declare @nPolicingSeq		int
				
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
				-- running simutaneously and the Prior Art requests are 
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
						BATCHNO,
						IDENTITYID
					)
					Select	
						@dtCurrentDate,
						P.SEQUENCENO+@nPolicingSeq,
						dbo.fn_DateToString(@dtCurrentDate,'CLEAN-DATETIME') + cast(P.SEQUENCENO+@nPolicingSeq as nvarchar),
						1,
						0,			-- un-hold the request to allow policing continous to pick up
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
		End
	End
End
go
