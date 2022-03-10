-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceLockCasesInProgress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceLockCasesInProgress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceLockCasesInProgress.'
	drop procedure dbo.ip_PoliceLockCasesInProgress
end
print '**** Creating procedure dbo.ip_PoliceLockCasesInProgress...'
print ''
go

set QUOTED_IDENTIFIER off
GO
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceLockCasesInProgress
			@pdtLockDateTime	datetime	OUTPUT,
			@pnDebugFlag		tinyint		= NULL,
			@pnUserIdentityId	int		= NULL,
			@psAction		nvarchar(2)	= NULL,
			@pnEventNo		int		= NULL,
			@pbRecalcFlag		bit		= 0,
			@pdtPolicingDateEntered	datetime	= NULL,
			@pnPolicingSeqNo	int		= NULL
as
-- PROCEDURE :	ip_PoliceLockCasesInProgress
-- VERSION :	6
-- DESCRIPTION:	Load a row into the POLICING table to indicate that Policing is in progress against
--		the Case. This will allow a concurrency control to take effect by enforcing a queue
--		if another user generates a Policing activity for the same Case.
--		NOTE: This queueing approach does not block other Policing Request generated batches
--		      as it only considers Policing activity being sent through to the Policing server.
--		      It does not block Police Immediately requests as the operator will see the
--		      immediate result of any calculations.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Nov 2006	MF	13724	1	Procedure created
-- 31 May 2007	MF	14812	2	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	3	Reserve word [STATE]
-- 19 Mar 2008	MF	14297	4	Where a specific Policing row has been expanded into multiple
--					individual Policing requests, the original row is to be removed
--					after the new rows have been inserted.
-- 07 Jul 2011	DL	RFC10830 5	Specify database collation default for temp table columns of type varchar, nvarchar and char
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

Declare @bTempTable	bit
Declare	@ErrorCode	int
Declare @TranCountStart	int
Declare @sSQLString	nvarchar(4000)

Create table #TEMPCASELOCK(
		DATEENTERED		datetime	not null,
		POLICINGSEQNO		int		identity(0,1),
		POLICINGNAME		nvarchar(40)	collate database_default not null,
		SYSGENERATEDFLAG	tinyint		not null,
		ONHOLDFLAG		tinyint		not null,
		ACTION			nvarchar(2)	collate database_default null,
		EVENTNO			int		null,
		CYCLE			int		null,
		CASEID			int		not null,
		TYPEOFREQUEST		tinyint		not null,
		SQLUSER			nvarchar(30)	collate database_default not null,
		IDENTITYID		int		null
		)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0

-- Ensure the appropriate level of locking is set

set transaction isolation level read committed

Set @TranCountStart = @@TranCount

BEGIN TRANSACTION

set @pdtLockDateTime=getdate()

If @pbRecalcFlag=1
and(@psAction  is not null
 or @pnEventNo is not null)
Begin
	-----------------------------------------------------
	-- A recalclation for a specific Action and/or Event
	-----------------------------------------------------
	Set @bTempTable=0

	Set @sSQLString="
	insert into POLICING(DATEENTERED,POLICINGSEQNO,POLICINGNAME,SYSGENERATEDFLAG,ONHOLDFLAG,ACTION,EVENTNO,CASEID,TYPEOFREQUEST,SQLUSER,IDENTITYID)
	select	@pdtLockDateTime,
		T.CASEID,
		left('Generated'+convert(varchar(11),T.CASEID)+convert(varchar(12),convert(decimal(11,6),@pdtLockDateTime)),40),
		1,
		1,
		@psAction,
		@pnEventNo,
		T.CASEID,
		CASE WHEN(@pnEventNo is not null) 
			THEN 6 -- Recalculate due date
			ELSE 1 -- Recalculate the entire action
		END,
		SYSTEM_USER,
		@pnUserIdentityId
	from #TEMPCASES T"
End
Else If @pbRecalcFlag=1
Begin
	--------------------------------------------------------------------------
	-- Recalculation is occurring but no specific Action or Event identified 
	-- so all Open Actions to be recalculated.
	-- Need to go via a temporary table in order to generate a sequence number
	--------------------------------------------------------------------------
	Set @bTempTable=1

	Set @sSQLString="
	insert into #TEMPCASELOCK(DATEENTERED,POLICINGNAME,SYSGENERATEDFLAG,ONHOLDFLAG,ACTION,CYCLE,CASEID,TYPEOFREQUEST,SQLUSER,IDENTITYID)
	select	distinct
		@pdtLockDateTime,
		left('Generated'+convert(varchar(11),T.CASEID)+T.ACTION+'['+convert(varchar(3),T.CYCLE)+']'+convert(varchar(12),convert(decimal(11,6),@pdtLockDateTime)),40),
		1,
		1,
		T.ACTION,
		T.CYCLE,
		T.CASEID,
		1,
		SYSTEM_USER,
		@pnUserIdentityId
	from #TEMPOPENACTION T
	Where T.[STATE]='C'"
End
Else Begin
	-----------------------------------------
	-- Recalculation of all Events identified
	-----------------------------------------

	-- Need to go via a temporary table in order 
	-- to generate a sequence number

	Set @bTempTable=1

	Set @sSQLString="
	insert into #TEMPCASELOCK(DATEENTERED,POLICINGNAME,SYSGENERATEDFLAG,ONHOLDFLAG,EVENTNO,CYCLE,CASEID,TYPEOFREQUEST,SQLUSER,IDENTITYID)
	select	distinct
		@pdtLockDateTime,
		left('Generated'+convert(varchar(11),T.CASEID)+convert(varchar(11),T.EVENTNO)+'['+convert(varchar(3),T.CYCLE)+']'+convert(varchar(12),convert(decimal(11,6),@pdtLockDateTime)),40),
		1,
		1,
		T.EVENTNO,
		T.CYCLE,
		T.CASEID,
		6,
		SYSTEM_USER,
		@pnUserIdentityId
	from #TEMPCASEEVENT T
	Where T.[STATE] in ('C','R','R1')"
End

exec @ErrorCode=sp_executesql @sSQLString,
				N'@psAction		nvarchar(2),
				  @pnEventNo		int,
				  @pdtLockDateTime	datetime,
				  @pnUserIdentityId	int',
				  @psAction		=@psAction,
				  @pnEventNo		=@pnEventNo,
				  @pdtLockDateTime	=@pdtLockDateTime,
				  @pnUserIdentityId	=@pnUserIdentityId

-- If the load went via a temporary table then load into
-- the live POLICING table now.
If  @ErrorCode=0
and @bTempTable=1
Begin
	Set @sSQLString="
	insert into POLICING(DATEENTERED,POLICINGSEQNO,POLICINGNAME,SYSGENERATEDFLAG,ONHOLDFLAG,ACTION,EVENTNO,CASEID,TYPEOFREQUEST,SQLUSER,IDENTITYID)
	select DATEENTERED,POLICINGSEQNO,POLICINGNAME,SYSGENERATEDFLAG,ONHOLDFLAG,ACTION,EVENTNO,CASEID,TYPEOFREQUEST,SQLUSER,IDENTITYID
	from #TEMPCASELOCK"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- If a specific POLICING row has been expanded out into its
-- individual Cases then that row may now be deleted.
If @ErrorCode=0
and @pdtPolicingDateEntered is not null
and @pnPolicingSeqNo is not null
Begin
	Set @sSQLString="
	Delete from POLICING
	where ONHOLDFLAG=1
	and DATEENTERED=@pdtPolicingDateEntered
	and POLICINGSEQNO=@pnPolicingSeqNo"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pdtPolicingDateEntered	datetime,
				  @pnPolicingSeqNo		int',
				  @pdtPolicingDateEntered=@pdtPolicingDateEntered,
				  @pnPolicingSeqNo=@pnPolicingSeqNo
End

-- Commit or Rollback the transaction

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-- Reduce the locking level
set transaction isolation level read uncommitted
		
If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set @sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceLockCasesInProgress',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceLockCasesInProgress  to public
go

