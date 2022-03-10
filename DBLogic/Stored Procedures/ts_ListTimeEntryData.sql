---------------------------------------------------------------------------------------------
-- Creation of dbo.ts_ListTimeEntryData
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListTimeEntryData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListTimeEntryData.'
	drop procedure [dbo].[ts_ListTimeEntryData]
	Print '**** Creating Stored Procedure dbo.ts_ListTimeEntryData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ListTimeEntryData
(	
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnStaffKey		int, 		-- The key of the staff member the time belongs to. If not supplied, the name key of the @pnUserIdentityId will be used.
	@pnEntryNo		int,		-- The sequence number of a particular entry for the staff member.
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ts_ListTimeEntryData
-- VERSION:	10
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the TimesheetData dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Jun 2005  JEK	RFC1100	1	Procedure created by renaming from ts_ListTimesheetData.
-- 20 Jun 2005	TM	RFC1100	2	Update the timesheet data management for the new ISTIMER column, change
--					TotalTime to ElapsedMinutes, change TimeCarriedForward to MinutesCarriedForward 
--					and implement handling of continued rows.
-- 29 Jun 2005	TM	RFC1100	3	When converting datetime values to minutes set the minutes value to null if 
--					the datetime value is null instead of setting it to 0.
-- 11 Jul 2005	TM	RFC2834	4	Correct IsIncomplete extraction logic.
-- 25 Nov 2005	LP	RFC1017	5	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 15 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26 Feb 2010	MS	RFC7268	7	Condition for ChargeOutRate added for IsInComplete field.
-- 13 Sep 2011	ASH	R11175	8	Maintain Narrative Text in foreign languages.
-- 27 Apr 2012	KR	R11414	9	Modified the IsComplete Logic

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(max)

Declare @sCurrentUserName	nvarchar(254)
Declare @sCurrentUserCode	nvarchar(10)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces 	tinyint

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      	= 0
Set 	@pnRowCount		= 0

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Populate the Header result set
If @pnStaffKey is null
Begin
	Set @sSQLString = "
	Select  @pnStaffKey 		= UI.NAMENO,
		@sCurrentUserName 	= dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
		@sCurrentUserCode	= N.NAMECODE
	from 	USERIDENTITY UI
	join    NAME N			on (N.NAMENO = UI.NAMENO)
	where 	UI.IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int			OUTPUT,
			  @sCurrentUserName	nvarchar(254)		OUTPUT,
			  @sCurrentUserCode	nvarchar(10)		OUTPUT,
			  @pnUserIdentityId	int',
			  @pnStaffKey		= @pnStaffKey		OUTPUT,
			  @sCurrentUserName	= @sCurrentUserName	OUTPUT,
			  @sCurrentUserCode	= @sCurrentUserCode	OUTPUT,
			  @pnUserIdentityId	= @pnUserIdentityId

	If  @nErrorCode = 0
	Begin	
		Select  @pnStaffKey 		as 'StaffKey',
			@sCurrentUserName	as 'StaffName',
			@sCurrentUserCode	as 'StaffCode',
			@sLocalCurrencyCode	as 'LocalCurrencyCode',
			@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
	End
End
Else Begin
	
	Set @sSQLString = "
	Select  N.NAMENO	as 'StaffKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
				as 'StaffName',
		N.NAMECODE	as 'StaffCode',
		@sLocalCurrencyCode as 'LocalCurrencyCode',
		@nLocalDecimalPlaces as 'LocalDecimalPlaces'
	from 	NAME N			
	where 	N.NAMENO = @pnStaffKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey	int,
			  @sLocalCurrencyCode	nvarchar(3),
			  @nLocalDecimalPlaces	tinyint',
			  @pnStaffKey	= @pnStaffKey,
			  @sLocalCurrencyCode	= @sLocalCurrencyCode,
			  @nLocalDecimalPlaces	= @nLocalDecimalPlaces
End

-- Populate the Time result set
If  @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  D.EMPLOYEENO		as 'StaffKey',
		D.ENTRYNO		as 'EntryNo',
		D.STARTTIME		as 'StartDateTime',
		D.FINISHTIME		as 'FinishDateTime',
		D.NAMENO 		as 'NameKey',
		N.NAMENO		as 'DisplayNameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as 'Name',
		N.NAMECODE		as 'NameCode',
		C.CASEID		as 'CaseKey',
		C.IRN			as 'CaseReference',
		W.WIPCODE		as 'ActivityKey',
		"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+"
					as 'Activity',		
		CASE WHEN D.TOTALTIME is null THEN NULL 
		     ELSE isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
		END			as 'ElapsedMinutes',
		D.TOTALUNITS		as 'TotalUnits',
		D.UNITSPERHOUR		as 'UnitsPerHour',
		D.CHARGEOUTRATE 	as 'ChargeOutRate',
		D.TIMEVALUE		as 'LocalValue',
		D.DISCOUNTVALUE 	as 'LocalDiscount',
		D.COSTCALCULATION1 	as 'CostCalculation1',
		D.COSTCALCULATION2 	as 'CostCalculation2',
		D.FOREIGNCURRENCY  	as 'ForeignCurrencyCode',
		D.EXCHRATE		as 'ExchangeRate',
		D.FOREIGNVALUE		as 'ForeignValue',
		D.FOREIGNDISCOUNT 	as 'ForeignDiscount',
		CASE WHEN D.TIMECARRIEDFORWARD is null THEN NULL
		     ELSE isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
		END		 	as 'MinutesCarriedForward',
		D.PARENTENTRYNO		as 'ParentEntryNo',
		D.NARRATIVENO		as 'NarrativeKey',
		ISNULL("+ dbo.fn_SqlTranslatedColumn('DIARY',null,'LONGNARRATIVE','D',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('DIARY','SHORTNARRATIVE',null,'D',@sLookupCulture,@pbCalledFromCentura)+")
					as 'Narrative',
		NRT.NARRATIVECODE	as 'NarrativeCode',
		"+dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',null,'NRT',@sLookupCulture,@pbCalledFromCentura)+"
				  	as 'NarrativeTitle',
		D.NOTES			as 'Notes',
		-- Product information should only be populated if the Product 
		-- Recorded on WIP site control is turned on
		CASE	WHEN SCP.COLBOOLEAN = 1
			THEN D.PRODUCTCODE	
			ELSE NULL
		END			as 'ProductKey',
		CASE	WHEN SCP.COLBOOLEAN = 1
			THEN "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+"
			ELSE NULL
		END			as 'Product',		
		CASE	WHEN SCP.COLBOOLEAN = 1
			THEN TC.USERCODE		
			ELSE NULL
		END			as 'ProductCode',
		CASE 	WHEN D.TRANSNO is not null
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END 			as 'IsPosted',
		CASE	WHEN D.STARTTIME is not null and
			     D.FINISHTIME is not null and
			     D.TOTALTIME is null and
			     D1.PARENTENTRYNO = D.ENTRYNO
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)	
		END			as 'IsContinued',		
		CASE WHEN (isnull(SC.COLBOOLEAN, 0) = 1 OR D.NAMENO is null) and
			D.CASEID is null OR D.ACTIVITY is null or (( D.TOTALTIME is null or D.TOTALUNITS is null or D.TOTALUNITS = 0 or D.TIMEVALUE is null) AND (D1.PARENTENTRYNO is null or D.ENTRYNO != D1.PARENTENTRYNO))
			OR (D.CHARGEOUTRATE is null and isnull(SCR.COLBOOLEAN,0) = 1)
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END			as 'IsIncomplete',
		D.WIPENTITYNO		as 'EntityNo',
		D.TRANSNO		as 'TransNo',
		D.WIPSEQNO		as 'WipSeqNo',
		D.ISTIMER		as 'IsTimer',
		D.MARGINNO		as 'MarginNo'
	from 	DIARY D	
	left join DIARY D1		on (D1.PARENTENTRYNO = D.ENTRYNO and D1.EMPLOYEENO = D.EMPLOYEENO)		
	left join CASES C		on (C.CASEID = D.CASEID)
	left join CASENAME CN		on (CN.CASEID = C.CASEID
					and CN.NAMETYPE = 'I'
					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))							
	-- For time recorded against a case, the name of the instructor for the case (CaseKey) 
	-- is shown for information purposes.  Information is obtained from CaseName and Name.
	-- For time recorded directory against a name (instead of a case), the NameKey is obtained 
	-- from Diary.NameNo and the associated information from Name.
	-- Note: Look at the Diary.CaseId first even if the Diary.Name exists as well as the Diary.CaseId
	left join NAME N 		on (N.NAMENO = ISNULL(CN.NAMENO, D.NAMENO))
	left join WIPTEMPLATE W 	on (W.WIPCODE = D.ACTIVITY)
	left join TABLECODES TC		on (TC.TABLECODE = D.PRODUCTCODE)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'CASEONLY_TIME')
	left join SITECONTROL SCP	on (SCP.CONTROLID = 'Product Recorded on WIP')
	left join SITECONTROL SCR 	on (SCR.CONTROLID = 'Rate mandatory on time items')
	left join NARRATIVE NRT		on (NRT.NARRATIVENO = D.NARRATIVENO)
	where 	D.EMPLOYEENO = @pnStaffKey
	and	D.ENTRYNO = @pnEntryNo"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pnEntryNo		int',
			  @pnStaffKey		= @pnStaffKey,
			  @pnEntryNo		= @pnEntryNo

	Set @pnRowCount=@@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.ts_ListTimeEntryData to public
GO
