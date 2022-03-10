-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_AutoPostRecordedTime
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ts_AutoPostRecordedTime]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure ts_AutoPostRecordedTime.'
	Drop procedure [dbo].[ts_AutoPostRecordedTime]
End
Print '**** Creating Stored Procedure ts_AutoPostRecordedTime...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.ts_AutoPostRecordedTime
	@pnSelectEntityNo		int	= NULL,		-- If NULL, process all entities
	@pnSelectOfficeID		int	= NULL,		-- If NULL, process all offices
	@pnPostToEntityNo		int	= NULL		-- If NULL, post to HomeNameNo

AS
-- PROCEDURE :	ts_AutoPostRecordedTime
-- VERSION :	5
-- SCOPE:		CPA Inprotech - Time & Billing
-- DESCRIPTION:	Select all unposted time entries from Inprotech's DIARY table and post 
--				them to WIP using the standard Inprotech procedure ts_PostTimeBatch.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Number		Version	Change
-- ------------	-------	----------- -------	----------------------------------------------------------- 
-- 20 Jan 2008	IPsIT	RFC7847		1		Procedure created
-- 08 May 2008	IPsIT	RFC7847		2		Ignore continued item
-- 02 Apr 2009	MF		RFC7847		3		Reviewed by CPASS and 
-- 08 Apr 2013	AT		RFC13375	4		Fixed reference to office table type.
-- 30 Apr 2013	AT		RFC13375	5		Removed Case/ProfitCentre Office/Entity considerations. Get default entity based on rules in ac_ListEntities.

---------------------------------------------------------------------------------------------------

-----	Declare local variables
Declare	@nErrorCode			int,
	@nRowsSelected			int,
	@nRowsPosted			int,
	@nRowsRejected			int,
	@nUserIdentityID		int,
	@sTempTableName			nvarchar(128),
	@sSQL					nvarchar(4000)
	
Declare @nHomeNameNo int

---------------------------------------------------------------------------------------------------
-----	Initialise
---------------------------------------------------------------------------------------------------
-----	Initialize local variables
	Set	NOCOUNT ON
	Set	@nErrorCode    = 0
	Set	@nRowsSelected = 0
	Set	@nRowsPosted   = 0
	Set	@nRowsRejected = 0

-----	Determine user's identity, if possible
	Select	@nUserIdentityID = ui.IDENTITYID
	from	USERIDENTITY ui
	where	ui.LOGINID = dbo.fn_GetUser()

-----	Validate parameters - selection of entity
	If	@pnSelectEntityNo is not NULL
		If	not exists
			(select	1
			from	SPECIALNAME
			where	NAMENO     = @pnSelectEntityNo
			and	ENTITYFLAG = 1)
			Begin
				Raiserror ('Value ''%i'' for parameter @pnSelectEntityNo is not valid',16,1,@pnSelectEntityNo)
				Return	-1
			End

-----	Validate parameters - selection of office
	If	@pnSelectOfficeID is not NULL
		If	not exists
			(select	1
			from	OFFICE
			where	OFFICEID = @pnSelectOfficeID)
			Begin
				Raiserror ('Value ''%i'' for parameter @pnSelectOfficeID is not valid',16,1,@pnSelectOfficeID)
				Return	-1
			End

-----	Validate parameters - posting to entity
	If	@pnPostToEntityNo is not NULL
		If	not exists
			(select	1
			from	SPECIALNAME
			where	NAMENO     = @pnPostToEntityNo
			and	ENTITYFLAG = 1)
			Begin
				Raiserror ('Value ''%i'' for parameter @pnPostToEntityNo is not valid',16,1,@pnPostToEntityNo)
				Return	-1
			End

-----	If no value specified for PostToEntityNo then post to HomeNameNo
	If	@pnPostToEntityNo is NULL
		Select	@pnPostToEntityNo = sn.NAMENO
		from	SITECONTROL sc
		inner	join	SPECIALNAME sn
			on	sn.NAMENO     = sc.COLINTEGER
			and	sn.ENTITYFLAG = 1
		where	CONTROLID = 'HOMENAMENO'
If	@nErrorCode = 0
Begin
	Set	@sSQL = 'Select @nHomeNameNo = COLINTEGER FROM SITECONTROL where CONTROLID = ''HOMENAMENO'''

	Exec	@nErrorCode = sp_executesql @sSQL,
			N'@nHomeNameNo	int			OUTPUT',
			  @nHomeNameNo = @nHomeNameNo OUTPUT
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
		POSTTOENTITYNO  = @xnPostToEntityNo
	into	' + @sTempTableName + '
	from	DIARY d
	join	NAME n on n.NAMENO = d.EMPLOYEENO
	join	EMPLOYEE e on	e.EMPLOYEENO = d.EMPLOYEENO
	left	join (	SELECT ta.GENERICKEY, ofcTA.OFFICEID, snTA.NAMENO as OFFICEENTITY
					from TABLEATTRIBUTES ta
					join OFFICE ofcTA on (ofcTA.OFFICEID = ta.TABLECODE)
					left join SPECIALNAME snTA on (snTA.NAMENO = ofcTA.ORGNAMENO)
					where ta.PARENTTABLE = ''NAME''
					and	ta.TABLETYPE   = 44) as STAFFOFFICE 
			on (STAFFOFFICE.GENERICKEY = cast(d.EMPLOYEENO as nvarchar))
	where	d.ISTIMER   = 0
	and	d.TRANSNO   is NULL
	and	d.TOTALTIME is not NULL
	and	d.WIPENTITYNO is NULL
	and	(@xnSelectEntityNo is NULL or @xnSelectEntityNo = COALESCE(e.DEFAULTENTITYNO,STAFFOFFICE.OFFICEENTITY,@nHomeNameNo))
	and	(@xnSelectOfficeID is NULL or @xnSelectOfficeID = STAFFOFFICE.OFFICEID)
	order	by d.EMPLOYEENO, d.ENTRYNO'
	
	Exec	@nErrorCode = sp_executesql @sSQL,
		N'@xnSelectEntityNo	int,
		  @xnSelectOfficeID	int,
		  @xnPostToEntityNo	int,
		  @nHomeNameNo	int',
		  @xnSelectEntityNo	= @pnSelectEntityNo,
		  @xnSelectOfficeID	= @pnSelectOfficeID,
		  @xnPostToEntityNo	= @pnPostToEntityNo,
		  @nHomeNameNo = @nHomeNameNo
		  
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
		@pnEntityKey		= @pnPostToEntityNo,
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
go

grant execute on dbo.ts_AutoPostRecordedTime to public
go
