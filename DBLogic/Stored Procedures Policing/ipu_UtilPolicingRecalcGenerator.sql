-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilPolicingRecalcGenerator
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_UtilPolicingRecalcGenerator]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_UtilPolicingRecalcGenerator.'
	drop procedure dbo.ipu_UtilPolicingRecalcGenerator
end
print '**** Creating procedure dbo.ipu_UtilPolicingRecalcGenerator...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ipu_UtilPolicingRecalcGenerator
			@pnBatchSize		int		=5000,	-- Number of Cases to be processed in one batch
			@pnProcessors		tinyint		=2,	-- Number of parallel policing processors allowed
			@psAction		nvarchar(2)	='AS',	-- Action to be recalculated
			@pnDebugFlag		tinyint		=1,	-- 1 to display progress
			@pnMaxWait		tinyint		=60	-- Maximum number of 1 minute delays. To avoid endless loop.

as
-- PROCEDURE :	ipu_UtilPolicingRecalcGenerator
-- VERSION :	4
-- DESCRIPTION:	A wrapper procedure to execute ipu_Policing asynchronously for 
--		a generated set of Policing Requests.  Useful for controlling a
--		a large amount of Policing particularly where multiple processors
--		can be taken advantage of for efficient througput.

-->>>>>>>>>>>	NOTE:	The code that loads #TempCasesToPolice may be modified
-->>>>>>>>>>>		to match specific user requirements.

-- COPYRIGHT :	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date			Who	Change	Version	Description
-- -----------	---	------	-------	----------------------------------------------- 
-- 16 May 2008	MF	16424	1	Procedure created
-- 28 May 2013	DL	10030	2	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 14 Oct 2014	DL	R39102	3	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 14 Nov 2018  AV  75198/DR-45358	4   Date conversion errors when creating cases and opening names in Chinese DB


set nocount on

create table #TempCasesToPolice (
		CASEID		int	NOT NULL,
		SEQUENCE	int	identity(1,1)
		)

declare @TranCountStart		int
declare	@nErrorCode		int
declare	@nObject		int
declare	@nObjectExist		tinyint
declare @sTimeStamp		nvarchar(24)
declare	@sCommand		varchar(255)
declare	@sMsg			varchar(255)
declare	@sSQLString		nvarchar(4000)

declare @nPolicingQueue		int		-- Number of Cases currently in Policing Queue
declare @nCasesToPolice		int		-- Total number of Cases that require Policing
declare @nRowsProcessed		int		-- Number of Cases sent to Policing so far
declare @nLoopCount		tinyint		-- Number of times allowed to check number of rows Policing is processing

---------------------------------------
-- Lower the locking level.
-- This will not impact exclusive locks
-- such as Inserts and Updates.
---------------------------------------
set transaction isolation level read uncommitted

-- Initialise variables
set @nErrorCode	= 0

-----------------------------------------
-- Build command line to run ipu_Policing 
-- using Service Broker (rfc39102)
-----------------------------------------
If @nErrorCode = 0
Begin
	Select @sCommand = 'dbo.ipu_Policing @pnAsynchronousFlag=1,@pnBatchSize='+cast(@pnBatchSize as varchar)
End

If @nErrorCode=0
Begin
	-------------------------------------
	-- Load the Cases to be recalculated
	-- into a table variable in the order
	-- in which the recalculations is to
	-- occur.
	-------------------------------------

	-------------------------------------------
	------ NOTE NOTE NOTE NOTE NOTE NOTE ------
	------ This statement may be changed ------
	------ to match a specific set of    ------
	------ user requirements.            ------
	-------------------------------------------
	Set @sSQLString="
	Insert into #TempCasesToPolice(CASEID)
	select OA.CASEID
	from OPENACTION OA
	join CASES C		on (C.CASEID=OA.CASEID)
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	where OA.POLICEEVENTS=1
	and OA.ACTION=@psAction
	and isnull(S.LIVEFLAG,1)=1	-- Restrict to live Cases
	Order by OA.CASEID"

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@psAction	nvarchar(2)',
				  @psAction=@psAction

	Set @nCasesToPolice=@@Rowcount
End

------------------------------
-- Loop until all of the Cases
-- have been sent to Policing
------------------------------
Set @nRowsProcessed=0

While @nCasesToPolice>@nRowsProcessed
  and @nErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	------------------------------------------------
	-- Load POLICING rows from the next set of Cases 
	-- to be Policed, not exceeding the batch size.
	------------------------------------------------
	Set @sSQLString="
	Insert into POLICING(	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, PENDING,
				CASEID, ACTION, TYPEOFREQUEST, SQLUSER)
	Select	TOP "+cast(@pnBatchSize as varchar)+"
		getdate(), T.SEQUENCE, 'Recalc of Case: '+C.IRN, 1, 0, 1,
		C.CASEID, @psAction, 1, SYSTEM_USER
	from #TempCasesToPolice T
	join CASES C on (C.CASEID=T.CASEID)
	where T.SEQUENCE>@nRowsProcessed
	order by T.SEQUENCE"

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nRowsProcessed	int		output,
				  @psAction		nvarchar(2)',
				  @nRowsProcessed=@nRowsProcessed	output,
				  @psAction      =@psAction

	Set @nRowsProcessed=@nRowsProcessed+@pnBatchSize

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

	If @nErrorCode=0
	Begin
		---------------------------------------------------------------
		-- Run the command asynchronously using Servie Broker (rfc-39102)
		--------------------------------------------------------------- 
		exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
	End

	If @pnDebugFlag > 0
	Begin
		set @sTimeStamp=convert(nvarchar,getdate(),126)
		set @sMsg='- Policing Requests Sent '+cast(@nRowsProcessed as varchar)
		RAISERROR ('%s ipu_UtilPolicingRecalcGenerator %s',0,1,@sTimeStamp,@sMsg ) with NOWAIT
	End

	------------------------------------------------------
	-- Now check that the number of rows in POLICING
	-- has not exceeded the number of available processors
	-- multiplied by the batch size
	------------------------------------------------------
	Set @nLoopCount=0

	While (	select count(*) 
		from POLICING
		where SYSGENERATEDFLAG=1) > (@pnBatchSize*@pnProcessors)
	and @nErrorCode=0
	Begin
		Set @nLoopCount=@nLoopCount+1

		If @nLoopCount>@pnMaxWait
		Begin
			----------------------
			-- Waited too long.
			-- Terminate the loop.
			----------------------
			Set @nErrorCode=-1

			If @pnDebugFlag > 0
			Begin
				set @sTimeStamp=convert(nvarchar,getdate(),126)
				set @sMsg='*** Terminated because Policing Processors unavailable after long wait ***'
				RAISERROR ('%s ipu_UtilPolicingRecalcGenerator %s',0,1,@sTimeStamp,@sMsg ) with NOWAIT
			End
		End
			------------------------------------------
			-- Policing already has a full complement
			-- of requests for the available number of
			-- processors.  Wait until processors free
			-- up before inserting additional Policing
			-- requests.
			------------------------------------------
		Else Begin
			WAITFOR DELAY '00:01'	-- 1 minute wait before checking count again.
		End
	End

	-------------------------------------------------------
	-- Now check that the number of rows in POLICING
	-- that have not started processing does not exceed the
	-- maximum batch size. Pause to give Policing a chance
	-- to start processing the current batches.
	-------------------------------------------------------
	Set @nLoopCount=0

	While (	select count(*) 
		from POLICING
		where SYSGENERATEDFLAG=1
		and ONHOLDFLAG=0) > @pnBatchSize
	and @nErrorCode=0
	Begin
		Set @nLoopCount=@nLoopCount+1

		If @nLoopCount>@pnMaxWait
		Begin
			----------------------
			-- Waited too long.
			-- Terminate the loop.
			----------------------
			Set @nErrorCode=-1

			If @pnDebugFlag > 0
			Begin
				set @sTimeStamp=convert(nvarchar,getdate(),126)
				set @sMsg='*** Terminated because Policing not processing requests ***'
				RAISERROR ('%s ipu_UtilPolicingRecalcGenerator %s',0,1,@sTimeStamp,@sMsg ) with NOWAIT
			End
		End
			------------------------------------------
			-- Policing has not updated the ONHOLDFLAG 
			-- on the existing requests in POLICING.
			-- This indicates that processing of these
			-- requests has not commenced.
			------------------------------------------
		Else Begin
			WAITFOR DELAY '00:00:15'	-- 15 second wait before checking count again.
		End
	End
End

drop table #TempCasesToPolice

return @nErrorCode
go

grant execute on dbo.ipu_UtilPolicingRecalcGenerator to public
go
