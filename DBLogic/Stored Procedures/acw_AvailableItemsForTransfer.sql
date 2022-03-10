-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_AvailableItemsForTransfer
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_AvailableItemsForTransfer]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_AvailableItemsForTransfer.'
	Drop procedure [dbo].[acw_AvailableItemsForTransfer]
End
Print '**** Creating Stored Procedure dbo.acw_AvailableItemsForTransfer...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE dbo.acw_AvailableItemsForTransfer
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int		= null,
	@psFromActivityKey		nvarchar(12)	= null,
	@psToActivityKey		nvarchar(12)	= null,
	@pbCalledFromCentura	        bit		= 0
)
as
-- PROCEDURE:	acw_AvailableItemsForTransfer
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the items available in the Case Wip Transfer window.
--				On the window, all unlocked wip and unposted time are available for transfer.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	--------------------------------------- 
-- 08 Jul 2013	SF	DR-133	1	Procedure created
-- 09 Jul 2013	SF	DR-136	2	Added Activity Filtering
-- 09 Jul 2013	vql	DR-136	3	Added LogDateTimeStamp in result set	
-- 28 Jan 2014	MS	R30326	4	Added NarrativeKey, DebitNoteText in resultset
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).
-- 17 Sep 2018  MS      DR43058 6       Added EntityName in the resultset

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare	@nErrorCode				int
Declare	@sLookupCulture			nvarchar(10)
Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @nTimeValue				decimal(9,2)
Declare @sFilterCategory		nvarchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	
							@psCurrencyCode			= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 		= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 		= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode=0
and @psToActivityKey is not null
and @psToActivityKey != ''
Begin
	
	Select @sFilterCategory = WTYP.CATEGORYCODE
	from WIPTYPE WTYP
	join WIPTEMPLATE WTEM on (WTYP.WIPTYPEID = WTEM.WIPTYPEID)
	where WTEM.WIPCODE = @psToActivityKey
	 
End

-- Get timevalue of the case
If @nErrorCode=0
Begin

	select	@nTimeValue = SUM(TIMEVALUE)                           
	from	DIARY 
	where   CASEID = @pnCaseKey
	and		(WIPENTITYNO is NULL OR WIPENTITYNO = 0)  
	and		(TRANSNO is NULL OR TRANSNO = 0)  
	and		ISTIMER = 0   
	and		TIMEVALUE IS NOT NULL

End

-- Case Info result set
If @nErrorCode = 0
Begin
	
	Select	"1"						as RowKey,
			@pnCaseKey				as CaseKey,
			CN.NAMENO				as StaffKey,
			N.NAMECODE				as StaffCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as StaffName,
			@sLocalCurrencyCode			as LocalCurrencyCode,
			@nLocalDecimalPlaces			as LocalDecimalPlaces,
			@nTimeValue				as UnpostedTimeValue		
	from CASES C
	join CASENAME CN on (	CN.CASEID = C.CASEID 
						and CN.NAMETYPE = 'EMP' 
						and CN.SEQUENCE = 0 
						and (CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()))
	join NAME N on (CN.NAMENO = N.NAMENO)
	where C.CASEID = @pnCaseKey
	
End

-- WIP result set
If @nErrorCode = 0
Begin
	
	Select	CAST(WIP.ENTITYNO as varchar(12)) + '^' +
			CAST(WIP.TRANSNO as varchar(12)) + '^' +
			CAST(WIP.WIPSEQNO as varchar(12)) as RowKey, 
			WIP.CASEID 				as CaseKey,
			WIP.ENTITYNO			as EntityKey,
			WIP.TRANSNO				as TransKey,
			WIP.WIPSEQNO			as WipSeqNo,
			WIP.TRANSDATE			as TransDate,
			WIP.WIPCODE				as WipCode,
			dbo.fn_GetTranslation(WT.[DESCRIPTION],null,WT.DESCRIPTION_TID,@sLookupCulture) as 'Description',
			WIP.BALANCE				as LocalAmount,
			WIP.FOREIGNBALANCE		as ForeignAmount,
			WIP.FOREIGNCURRENCY		as ForeignCurrency,
			WIP.FOREIGNVALUE		as ForeignValue,
			STAFFNAME.NAMENO		as StaffKey,
			dbo.fn_FormatNameUsingNameNo(STAFFNAME.NAMENO, null)
									as StaffName,
			STAFFNAME.NAMECODE		as StaffCode,
			WIP.LOGDATETIMESTAMP		as LogDateTimeStamp,
			WIP.NARRATIVENO			as NarrativeKey,
			ISNULL(WIP.LONGNARRATIVE, WIP.SHORTNARRATIVE)
							as DebitNoteText,
                        EN.NAME                         as EntityName
	from	WORKINPROGRESS WIP
	inner join WIPTEMPLATE WT on (WIP.WIPCODE = WT.WIPCODE)
	join	WIPTYPE WTYPE on (WTYPE.WIPTYPEID = WT.WIPTYPEID)
	left join NAME STAFFNAME on ( WIP.EMPLOYEENO = STAFFNAME.NAMENO )
        left join NAME EN on (EN.NAMENO = WIP.ENTITYNO)
	where	WIP.CASEID = @pnCaseKey and @pnCaseKey is not null
	and		WIP.WIPCODE = case when @psFromActivityKey = '' or @psFromActivityKey is null THEN WIP.WIPCODE else @psFromActivityKey end
	and		WTYPE.CATEGORYCODE = case when @sFilterCategory IS null then WTYPE.CATEGORYCODE ELSE @sFilterCategory end
	and		WIP.STATUS = 1
	order  by WIP.TRANSDATE, 'Description', WIP.FOREIGNVALUE
	
End

Return @nErrorCode
GO

Grant execute on dbo.acw_AvailableItemsForTransfer to public
GO
