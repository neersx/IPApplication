
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_AutoPostRecordedTimeByCaseEntity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ts_AutoPostRecordedTimeByCaseEntity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure ts_AutoPostRecordedTimeByCaseEntity.'
	Drop procedure [dbo].[ts_AutoPostRecordedTimeByCaseEntity]
End
Print '**** Creating Stored Procedure ts_AutoPostRecordedTimeByCaseEntity...'
Print ''
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[ts_AutoPostRecordedTimeByCaseEntity]
	@pnEntityNo		int


AS
-- PROCEDURE :	ts_AutoPostRecordedTimeByCaseEntity
-- VERSION :	1
-- SCOPE:	CPA Inprotech - Time & Billing
-- DESCRIPTION:	Select all unposted time entries for Cases that belong to the Office of the provided Entity
--		from Inprotech's DIARY table and post them to WIP using the standard Inprotech procedure ts_PostTimeBatch.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	    Version	Change
-- ------------	-------	----------- -------	----------------------------------------------------------- 
-- 11 Apr 2016	MAF	58026		1	Procedure created

Set	NOCOUNT ON

-----	Declare local variables
Declare	@nErrorCode			int,
	@nRowsSelected			int,
	@nRowsPosted			int,
	@nRowsRejected			int,
	@nUserIdentityID		int,
	@sTempTableName			nvarchar(128),
	@sSQL				nvarchar(max)
	
Declare @nHomeNameNo int

---------------------------------------------------------------------------------------------------
-----	Initialise
---------------------------------------------------------------------------------------------------
	Set	@nErrorCode    = 0
	Set	@nRowsSelected = 0
	Set	@nRowsPosted   = 0
	Set	@nRowsRejected = 0

-----	Determine user's identity, if possible
	Select	@nUserIdentityID = ui.IDENTITYID
	from	USERIDENTITY ui
	where	ui.LOGINID = dbo.fn_GetUser()

-----	Validate parameters - selection of entity
	If	not exists
		(select	1
		from	SPECIALNAME
		where	NAMENO     = @pnEntityNo
		and	ENTITYFLAG = 1)
		Begin
			Raiserror ('Value ''%i'' for parameter @pnEntityNo is not valid',16,1,@pnEntityNo)
			Return	-1
		End


---------------------------------------------------------------------------------------------------
-----	Post time into WIP using standard Inprotech procedure ts_PostTimeBatch
---------------------------------------------------------------------------------------------------
-----	Generate a unique name for a (necessarily) global temporary table
	Set	@sTempTableName = '##TempUnpostedTime_' + RIGHT('00000'+CAST(@@spid as varchar),5)

-----	Select all entries available for posting into a global temporary table
If	@nErrorCode = 0
Begin
-----	Prepare statement
	Set	@sSQL =
'	Select	distinct
		EMPLOYEENO      = d.EMPLOYEENO,
		ENTRYNO         = d.ENTRYNO,
		POSTTOENTITYNO  = @xnEntityNo
	into	' + @sTempTableName + '
	from	DIARY d
	join	NAME n on n.NAMENO = d.EMPLOYEENO
	join	CASES c on	c.CASEID = d.CASEID
	join	OFFICE o on o.OFFICEID = c.OFFICEID
	where	d.ISTIMER   = 0
	and	d.TRANSNO   is NULL
	and	d.TOTALTIME is not NULL
	and	d.WIPENTITYNO is NULL
	and	o.ORGNAMENO = @xnEntityNo
	order	by d.EMPLOYEENO, d.ENTRYNO'
	
	Exec	@nErrorCode = sp_executesql @sSQL,
		N'@xnEntityNo	int',
		  @xnEntityNo	= @pnEntityNo
		  
	Set @nRowsSelected = @@ROWCOUNT
-----	Display number of entries that passed selection
	If	@nErrorCode = 0
		Raiserror ('%i time entries selected for posting',0,1,@nRowsSelected) with nowait
End


-----	Call standard Inprotech procedure to post eligible entries
If	@nErrorCode    = 0
and	@nRowsSelected > 0
Begin
	Set	@sSQL = 'from ' + @sTempTableName + ' xd where 1=1'
	Exec	@nErrorCode = dbo.ts_PostTimeBatch
		@pnRowsPosted		= @nRowsPosted		OUTPUT,
		@pnUserIdentityId	= 0,
		@pnEntityKey		= @pnEntityNo,
		@psWhereClause		= @sSQL
-----	Display number of entries that were posted
	If	@nErrorCode = 0
		Raiserror ('%i time entries succesfully posted',0,1,@nRowsPosted) with nowait
End


-----	Raise warning message if not all rows were posted
If	@nErrorCode     = 0
and	@nRowsSelected <> @nRowsPosted
Begin
	Set	@nRowsRejected = @nRowsSelected - @nRowsPosted
	Raiserror ('%i time entries were selected but NOT posted',0,1,@nRowsRejected) with nowait
End

-----	Drop the temporary table after use
If	@nErrorCode = 0
Begin
	Set	@sSQL = 'Drop table ' + @sTempTableName
	Exec	@nErrorCode = sp_executesql @sSQL
End



---------------------------------------------------------------------------------------------------
-----	Finalise
---------------------------------------------------------------------------------------------------
If	@nErrorCode <> 0 
	Begin
		Raiserror ('Procedure failed; check messages', 16, 1)
		Return -1
	End

RETURN @nErrorCode

GO

grant execute on ts_AutoPostRecordedTimeByCaseEntity to public