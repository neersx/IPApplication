-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_Policing_async
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_Policing_async]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_Policing_async.'
	drop procedure dbo.ipu_Policing_async
end
print '**** Creating procedure dbo.ipu_Policing_async...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ipu_Policing_async
			@pdtPolicingDateEntered		datetime	= null,
			@pnPolicingSeqNo		int 		= null, 
			@pnDebugFlag			tinyint		= 0,		
			@pnBatchNo			int		= null,
			@psDelayLength			varchar(9)	= null,--time(hhh:mm:ss) to wait before checking for more Policing requests
			@pnUserIdentityId		int		= null,
			@psPolicingMessageTable		nvarchar(128)	= null,
			@pbGetTransactionNo		bit		= 0,
			@pbCalledFromCentura		tinyint		= 0
			
as
-- PROCEDURE :	ipu_Policing_async
-- VERSION :	16
-- DESCRIPTION:	A wrapper procedure to execute ipu_Policing asynchronously.
-- CALLED BY :	
-- COPYRIGHT :	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27/04/2007	JS	14638	1	Procedure created
-- 03/09/2007	DL	15188	2	Pass a async flag, user id and transaction no to ipu_Policing.
-- 07 Nov 2007	MF	15552	3	Allow an asynchronous version of Police Continuously to operate.
--					This will check if there are unprocessed Policing requests on the
--					queue after a user supplied delay interval.  If there are then
--					a new Policing thread will be started process all of those requests.
-- 07 Feb 2008	MF	15188	4	Revisit to also extract the BatchNo associated with the SPID and then
--					pass this into ipu_Policing
-- 15 Feb 2008	MF	15972	5	Determine if any Policing requests are pending since the previous
--					asynchronous Policing job was started by checking the PENDING column
--					on the POLICING table.
-- 16 May 2008	MF	15972	6	Revisit to remove debug code.
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Nov 2008	MF	17165	8	Check if Policing has a limited number of rows to process and if so 
--					only set the Pending flag for that number of rows. This will ensure
--					that Policing attempts to process all outstanding requests.  Also
--					limit the number of Policing processes allowed to run at the one time.
-- 02 Jul 2009	MF	17844	9	Use BEGIN TRY and BEGIN CATCH to catch deadlock errors (1205) so multiple 
--					attempts can be made to update the POLICING table.
-- 23 Sep 2011	MF	19915	10	If multiple policing threads are being run, a second thread should not pick up a Case that is already 
--					being processed by an earlier thread. This test needs to be included at the point where the POLCIING row
--					is updated to PENDING=1
-- 28 May 2013	DL	10030	11	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 14 Oct 2014	DL	R39102	12	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 25 Jun 2015	DL	48851	13	Return error code if calling from Centura
-- 16 Apr 2018	SF	73564	14 	Notify others that a managed scheduled dispatcher of policing processes is currently active 
-- 14 Nov 2018  AV	DR-45358 15	Date conversion errors when creating cases and opening names in Chinese DB
-- 12 Jun 2019	MF	DR-49537 15	Increase the number of retry attempts and the wait time when the process is the victim of a deadlock error.  Also lower the deadlock priority to 
--					make this process the preferred victim.
set nocount on
set DEADLOCK_PRIORITY -1

declare @TranCountStart		int
declare	@nErrorCode		int
declare	@nObject		int
declare	@nSessionTransNo	int
declare @nEDEBatchNo		int
declare @nRowsToGet		int
declare @nMaxPolicingAllowed	int
declare	@nRowsToProcess		int
declare @nRetry			smallint
declare	@nAnsynchronousFlag	tinyint
declare	@nObjectExist		tinyint
declare	@bContinue		bit
declare @sTimeStamp		nvarchar(24)
declare	@sCommand		varchar(255)
declare	@sSQLString		nvarchar(4000)

set @nErrorCode = 0
set @nAnsynchronousFlag = 1
 
-------------------------
-- Get the current userid 
-------------------------
If @pnUserIdentityId is null or @pnUserIdentityId=''
Begin
	Set @sSQLString="
	Select @pnUserIdentityId=min(IDENTITYID)
	from USERIDENTITY
	where LOGINID=substring(SYSTEM_USER,1,50)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnUserIdentityId		int	OUTPUT',
			  @pnUserIdentityId=@pnUserIdentityId	OUTPUT
End

----------------------------------------
-- Check if Policing is set to process
-- a limited number of Policing requests
----------------------------------------
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nRowsToGet=isnull(S.COLINTEGER,0)
	from SITECONTROL S
	where S.CONTROLID='Policing Rows To Get'"

	Execute @nErrorCode=sp_executesql @sSQLString, 
					N'@nRowsToGet		int	OUTPUT',
					  @nRowsToGet=@nRowsToGet 	OUTPUT
End

----------------------------------------
-- Check if there is a limit on the 
-- number of concurrent Policing threads
----------------------------------------
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nMaxPolicingAllowed=isnull(S.COLINTEGER,0)
	from SITECONTROL S
	where S.CONTROLID='Maximum Concurrent Policing'"

	Execute @nErrorCode=sp_executesql @sSQLString, 
					N'@nMaxPolicingAllowed		int		OUTPUT',
					  @nMaxPolicingAllowed=@nMaxPolicingAllowed	OUTPUT
End

-----------------------------
-- Get transaction number and 
-- Batch No from context_info
-----------------------------
If @nErrorCode = 0
Begin
	Set @nSessionTransNo = null
	Set @nEDEBatchNo     = null

	Set @sSQLString="
	Select	@nSessionTransNo=cast(substring(context_info,5,4) as int),
		@nEDEBatchNo    =cast(substring(context_info,9,4) as int)
	from master.dbo.sysprocesses
	where spid=@@SPID
	and(substring(context_info,5,4)<>0x0000000
	 OR substring(context_info,9,4)<>0x0000000)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nSessionTransNo		int	OUTPUT,
			  @nEDEBatchNo			int	OUTPUT',
			  @nSessionTransNo=@nSessionTransNo	OUTPUT,
			  @nEDEBatchNo=@nEDEBatchNo		OUTPUT
End

-----------------------------------------
-- Build command line to run ipu_Policing 
-- using Service Broker (rfc-39102) 
-----------------------------------------
If @nErrorCode = 0
Begin
	Set @sCommand = 'dbo.ipu_Policing '

	If @pdtPolicingDateEntered is null
		Set @sCommand = @sCommand + 'null,'
	else
		Set @sCommand = @sCommand + "'" + convert(varchar,@pdtPolicingDateEntered,121) + "',"

	If @pnPolicingSeqNo is null
		Set @sCommand = @sCommand + 'null,'
	else
		Set @sCommand = @sCommand + convert(varchar,@pnPolicingSeqNo) + ','

	-- Not point passing @pnDebugFlag as Policing running asynchronously has 
	-- no where to display the debug messages
--	If @pnDebugFlag is null
		Set @sCommand = @sCommand + 'null,'
--	else
--		Set @sCommand = @sCommand + convert(varchar,@pnDebugFlag) + ','

	If @pnBatchNo is null
		Set @sCommand = @sCommand + 'null,'
	else
		Set @sCommand = @sCommand + convert(varchar,@pnBatchNo) + ','

	--------------------------------------------
	-- Do not pass the Delay Length parameter
	-- to Policing.  The parameter will be used
	-- within this procedure to loop through and
	-- create multiple Policing threads
	--------------------------------------------
	--If @psDelayLength is null
		Set @sCommand = @sCommand + "'',"

	If @pnUserIdentityId is null
		Set @sCommand = @sCommand + 'null,'
	else
		Set @sCommand = @sCommand + convert(varchar,@pnUserIdentityId) + ','

	If @psPolicingMessageTable is null
		Set @sCommand = @sCommand + 'null,'
	else
		Set @sCommand = @sCommand + "'" + @psPolicingMessageTable + "'," 

	Set @sCommand = @sCommand + convert(varchar,@nAnsynchronousFlag) + ','

	If @nSessionTransNo is null
	or @nSessionTransNo = 0
		Set @sCommand = @sCommand + 'null,'
	else
		Set @sCommand = @sCommand + convert(varchar,@nSessionTransNo) + ','

	If @nEDEBatchNo is null
	or @nEDEBatchNo = 0
		Set @sCommand = @sCommand + 'null'
	else
		Set @sCommand = @sCommand + convert(varchar,@nEDEBatchNo)

End

-- Let others know that a process that dispatches child policing processes is currently active, 
-- and will track the dispatcher rather than the actual dispatched Policing process
-- For example: if this dispatcher has dispatched 10 ipu_Policing processes, and one of them is 5 hours long and this dispatcher is killed
-- Policing Dashboard will indicate that there are no policing dispatcher processes available, 
-- because the one running for 5 hours will only be concentrating in finishing its own assigned batch.  
If @nErrorCode=0
and isnull(@psDelayLength,'')<>''
and not exists(select 1 from tempdb.INFORMATION_SCHEMA.TABLES where TABLE_NAME like dbo.fn_PolicingContinuouslyTrackingTable(@@spid))
begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

		set @sSQLString = 'create table ' + dbo.fn_PolicingContinuouslyTrackingTable(@@spid) + '(spid int)'
		exec @nErrorCode = sp_executesql @sSQLString

	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
end

-- Check to see if there are any unprocessed rows in Policing
-- if it is being run continuously
If @nErrorCode=0
and isnull(@psDelayLength,'')<>''
Begin
	Set @nRetry=5
	While @nRetry>0
	and @nErrorCode=0
	Begin
		BEGIN TRY
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION

			Set @nRowsToProcess=0

			If isnull(@nRowsToGet,0)=0
			Begin
				Set @sSQLString="
				Update P
				Set PENDING=1
				from POLICING P
				where P.SYSGENERATEDFLAG=1
				and  (P.BATCHNO=@pnBatchNo OR @pnBatchNo is null)
				and  (P.ONHOLDFLAG=0 or P.ONHOLDFLAG is null or P.BATCHNO=@pnBatchNo)
				and  isnull(P.PENDING,0)=0
				-- SQA19915
				-- if there are requests for the same Case that have already
				-- commenced processing then wait until those requests have been
				-- completed or placed on hold. This is to stop multiple requests 
				-- from the same user being split across multiple Policing threads
				and not exists
					(select 1 from POLICING P3
					 where P3.CASEID=P.CASEID
					 and P3.SYSGENERATEDFLAG>0
					 and P3.SPIDINPROGRESS is not null  -- indicates it has been started on a different process
					 and P3.ONHOLDFLAG<>9)
				
				Set @nRowsToProcess=@@Rowcount"
			End
			Else Begin
				-----------------------------------------
				-- If Policing has a limit on the number
				-- of requests to process, then just mark
				-- that limited number of rows as Pending
				-----------------------------------------
				Set @sSQLString="
				Update P
				Set PENDING=1
				from (	select TOP "+cast(@nRowsToGet as varchar)+" DATEENTERED, POLICINGSEQNO
					from POLICING
					where SYSGENERATEDFLAG=1
					and  (BATCHNO=@pnBatchNo OR @pnBatchNo is null)
					and  (ONHOLDFLAG=0 or ONHOLDFLAG is null or BATCHNO=@pnBatchNo)
					and  isnull(PENDING,0)=0
					order by DATEENTERED, POLICINGSEQNO) P1
				join POLICING P	on (P.DATEENTERED=P1.DATEENTERED
						and P.POLICINGSEQNO=P1.POLICINGSEQNO)
				where isnull(P.PENDING,0)=0
				-- SQA19915
				-- if there are requests for the same Case that have already
				-- commenced processing then wait until those requests have been
				-- completed or placed on hold. This is to stop multiple requests 
				-- from the same user being split across multiple Policing threads
				and not exists
					(select 1 from POLICING P3
					 where P3.CASEID=P.CASEID
					 and P3.SYSGENERATEDFLAG>0
					 and P3.SPIDINPROGRESS is not null  -- indicates it has been started on a different process
					 and P3.ONHOLDFLAG<>9)
				
				Set @nRowsToProcess=@@Rowcount"
			End
			
			Execute @nErrorCode=sp_executesql @sSQLString, 
							N'@pnBatchNo		int,
							  @nRowsToProcess	int		OUTPUT',
							  @pnBatchNo     =@pnBatchNo,
							  @nRowsToProcess=@nRowsToProcess	OUTPUT

			-- Commit or Rollback the transaction

			If @@TranCount > @TranCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
		
			-- Terminate the WHILE loop
			Set @nRetry=-1
		END TRY

		---------------------------------
		-- D E A D L O C K   V I C T I M   
		--       P R O C E S S I N G
		---------------------------------
		BEGIN CATCH
			------------------------------------------
			-- If the process has been made the victim
			-- of a deadlock (error 1205), then allow 
			-- another attempt to apply the updates 
			-- to the database up to a retry limit.
			------------------------------------------
			If ERROR_NUMBER()=1205
				Set @nRetry=@nRetry-1
			Else
				Set @nRetry=-1
				
			-- Wait 5 seconds before attempting to
			-- retry the update.
			If @nRetry>0
				WAITFOR DELAY '00:00:05'
			else
				Set @nErrorCode=ERROR_NUMBER()
				
			If XACT_STATE()<>0
				Rollback Transaction
		END CATCH
	End -- While loop
End
------------------------------------------------
-- Loop continuously while a Site Control is set
-- and when this procedure has been started with
-- and explicit delay parameter to indicate when 
-- the Policing table is to be checked.
------------------------------------------------
set @bContinue=1

While @bContinue=1
and   @nErrorCode=0
Begin
	If @nRowsToProcess>0
	or isnull(@psDelayLength,'')='' -- NOT BEING RUN in Continous mode
	Begin
	
		----------------------------------------------------------
		-- Check to see if Policing is already processing the 
		-- maximum number of requests.  This is defined by the 
		-- number or rows Policing may process at once multipled
		-- by the number of processors (or threads) allowed.
		-- This provides a safeguard for when an extremely large
		-- batch of Policing requests hit the queue (e.g. a change
		-- of standing instruction against a client with a large 
		-- number of Cases).
		-- If Policing is fully utilised then this procedure will
		-- wait until it detects an opportunity is available to
		-- start another Policing process.
		----------------------------------------------------------

		While (	select count(*) 
			from POLICING
			with (NOLOCK)
			where SYSGENERATEDFLAG=1
			and   PENDING=1) >= @nMaxPolicingAllowed
		and @nErrorCode=0
		and @nMaxPolicingAllowed>0
		and @bContinue=1
		Begin		
			WAITFOR DELAY @psDelayLength	--  before checking count again.
			
			Set @sSQLString="
			Select @bContinue=S.COLBOOLEAN
			from SITECONTROL S
			where S.CONTROLID='Police Continuously'"
		
			Execute @nErrorCode=sp_executesql @sSQLString, 
							N'@bContinue		bit	OUTPUT',
							  @bContinue=@bContinue 	OUTPUT
		End
		
		If @nErrorCode=0
		Begin
			---------------------------------------------------------------
			-- Run the command asynchronously using Servie Broker (rfc-39102)
			--------------------------------------------------------------- 
			exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
		End

		-- If no DelayLength parameter has been
		-- passed then continuous processing is
		-- not required
		If isnull(@psDelayLength,'')=''
			Set @bContinue=0
	
		If @pnDebugFlag > 0
		Begin
			set @sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ipu_Policing_async %s',0,1,@sTimeStamp,@sCommand ) with NOWAIT
		End
	End

	-----------------------------------------------------------------------
	-- Check to see if the Site Control to allow continuous Policing is on.  
	-- This must be checked on each cycle so that the user may modify the 
	-- SiteControl to gracefully stop this procedure from executing.
	-----------------------------------------------------------------------

	If @nErrorCode=0
	and @bContinue=1
	Begin
		Set @sSQLString="
		Select @bContinue=S.COLBOOLEAN
		from SITECONTROL S
		where S.CONTROLID='Police Continuously'"
	
		Execute @nErrorCode=sp_executesql @sSQLString, 
						N'@bContinue		bit	OUTPUT',
						  @bContinue=@bContinue 	OUTPUT
	End

	If @nErrorCode=0
	and @bContinue=1
	Begin
		-- Wait a specified time before checking if there are any new 
		-- unprocessed Policing requests which will cause another
		-- Policing thread to be spawned.

		WAITFOR DELAY @psDelayLength

		Set @nRetry=5
		While @nRetry>0
		and @nErrorCode=0
		Begin
			BEGIN TRY

				-- Now check to see if there are any unprocessed rows in Policing
				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION

				Set @nRowsToProcess=0

				If isnull(@nRowsToGet,0)=0
				Begin
					Set @sSQLString="
					Update P
					Set PENDING=1
					from POLICING P
					where P.SYSGENERATEDFLAG=1
					and  (P.BATCHNO=@pnBatchNo OR @pnBatchNo is null)
					and  (P.ONHOLDFLAG=0 or P.ONHOLDFLAG is null or P.BATCHNO=@pnBatchNo)
					and  isnull(P.PENDING,0)=0
					-- SQA19915
					-- if there are requests for the same Case that have already
					-- commenced processing then wait until those requests have been
					-- completed or placed on hold. This is to stop multiple requests 
					-- from the same user being split across multiple Policing threads
					and not exists
						(select 1 from POLICING P3
						 where P3.CASEID=P.CASEID
						 and P3.SYSGENERATEDFLAG>0
						 and P3.SPIDINPROGRESS is not null  -- indicates it has been started on a different process
						 and P3.ONHOLDFLAG<>9)
				
					Set @nRowsToProcess=@@Rowcount"
				End
				Else Begin
					-----------------------------------------
					-- If Policing has a limit on the number
					-- of requests to process, then just mark
					-- that limited number of rows as Pending
					-----------------------------------------
					Set @sSQLString="
					Update P
					Set PENDING=1
					from (	select TOP "+cast(@nRowsToGet as varchar)+" DATEENTERED, POLICINGSEQNO
						from POLICING
						where SYSGENERATEDFLAG=1
						and  (BATCHNO=@pnBatchNo OR @pnBatchNo is null)
						and  (ONHOLDFLAG=0 or ONHOLDFLAG is null or BATCHNO=@pnBatchNo)
						and  isnull(PENDING,0)=0
						order by DATEENTERED, POLICINGSEQNO) P1
					join POLICING P	on (P.DATEENTERED=P1.DATEENTERED
							and P.POLICINGSEQNO=P1.POLICINGSEQNO)
					where isnull(P.PENDING,0)=0
					-- SQA19915
					-- if there are requests for the same Case that have already
					-- commenced processing then wait until those requests have been
					-- completed or placed on hold. This is to stop multiple requests 
					-- from the same user being split across multiple Policing threads
					and not exists
						(select 1 from POLICING P3
						 where P3.CASEID=P.CASEID
						 and P3.SYSGENERATEDFLAG>0
						 and P3.SPIDINPROGRESS is not null  -- indicates it has been started on a different process
						 and P3.ONHOLDFLAG<>9)
				
					Set @nRowsToProcess=@@Rowcount"
				End
				
				Execute @nErrorCode=sp_executesql @sSQLString, 
								N'@pnBatchNo		int,
								  @nRowsToProcess	int		OUTPUT',
								  @pnBatchNo     =@pnBatchNo,
								  @nRowsToProcess=@nRowsToProcess	OUTPUT

				-- Commit or Rollback the transaction

				If @@TranCount > @TranCountStart
				Begin
					If @nErrorCode = 0
						COMMIT TRANSACTION
					Else
						ROLLBACK TRANSACTION
				End
		
				-- Terminate the WHILE loop
				Set @nRetry=-1
			END TRY

			---------------------------------
			-- D E A D L O C K   V I C T I M   
			--       P R O C E S S I N G
			---------------------------------
			BEGIN CATCH
				------------------------------------------
				-- If the process has been made the victim
				-- of a deadlock (error 1205), then allow 
				-- another attempt to apply the updates 
				-- to the database up to a retry limit.
				------------------------------------------
				If ERROR_NUMBER()=1205
					Set @nRetry=@nRetry-1
				Else
					Set @nRetry=-1
					
				-- Wait 5 seconds before attempting to
				-- retry the update.
				If @nRetry>0
					WAITFOR DELAY '00:00:05'
				else
					Set @nErrorCode=ERROR_NUMBER()
					
				If XACT_STATE()<>0
					Rollback Transaction
			END CATCH
		End -- While loop
	End
End

If @pbCalledFromCentura = 1
	select @nErrorCode
	
return @nErrorCode
go

grant execute on dbo.ipu_Policing_async to public
go
