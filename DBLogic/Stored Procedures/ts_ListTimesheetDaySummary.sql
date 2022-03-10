---------------------------------------------------------------------------------------------
-- Creation of dbo.ts_ListTimesheetDaySummary
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListTimesheetDaySummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListTimesheetDaySummary.'
	drop procedure [dbo].[ts_ListTimesheetDaySummary]
	Print '**** Creating Stored Procedure dbo.ts_ListTimesheetDaySummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ListTimesheetDaySummary
(	
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnStaffKey		int		= null, -- The key of the staff member the time belongs to. If not supplied, the name key of the @pnUserIdentityId will be used.
	@pdtDate		datetime	= null,	-- The from date for the time entries required.	
	@pnEntryNo              int             = null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ts_ListTimesheetDaySummary
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the TimesheetData dataset for Day Summary.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 25 Jun 2010	MS	RFC7962	1	Procedure Created
-- 13 Sep 2011	ASH	R11175	2	Maintain Narrative Text in foreign languages.
-- 27 Apr 2012	KR	R11414	3	Modified the IsComplete Logic
-- 05 Jul 2013	vql	R13629	4	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(4000)

Declare @sCurrentUserName	nvarchar(254)
Declare @sCurrentUserCode	nvarchar(10)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @dDate			dateTime
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


If @nErrorCode = 0 and @pnEntryNo is not null
Begin 
    Set @sSQLString = "Select @dDate = STARTTIME
                        FROM DIARY
                        WHERE ENTRYNO = @pnEntryNo"
    
    exec @nErrorCode = sp_executesql @sSQLString,
            N'@dDate        DATETIME    output,
            @pnEntryNo      int',
            @dDate          = @dDate    output,
            @pnEntryNo      = @pnEntryNo
End

-- Populate the Time result set
If  @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  D.EMPLOYEENO		as 'StaffKey',
		D.ENTRYNO		as 'EntryNo',
		D.PARENTENTRYNO		as 'ParentEntryNo',
		CASE WHEN datepart(hour,STARTTIME) = 0 and datepart(minute,STARTTIME) = 0 and datepart(second,STARTTIME) = 0
			THEN NULL
		ELSE D.STARTTIME	
		END			as 'StartDateTime',
		CASE WHEN datepart(hour,FINISHTIME) = 0 and datepart(minute,FINISHTIME) = 0 and datepart(second,FINISHTIME) = 0
			THEN NULL
		ELSE D.FINISHTIME
		END			as 'FinishDateTime',
		N.NAMENO		as 'DisplayNameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as 'Name',
		N.NAMECODE		as 'NameCode',
		C.CASEID		as 'CaseKey',
		C.IRN			as 'CaseReference',
		W.WIPCODE		as 'ActivityKey',
		"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+"
					as 'Activity',		
		D.TOTALTIME		as 'TotalTime',
		D.TOTALUNITS		as 'TotalUnits', 
		D.TIMEVALUE		as 'LocalValue',  
		D.DISCOUNTVALUE		as 'Discount',
		D.TIMECARRIEDFORWARD	as 'TimeCarriedForward',
		D.ISTIMER		as 'IsTimer',
		(isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0))
					as 'AccumulatedMinutes',
		D.FOREIGNVALUE		as 'ForeignValue',
		D.FOREIGNCURRENCY	as 'ForeignCurrencyCode',
		CAST(D.EMPLOYEENO as nvarchar) + '^' + Cast(D.ENTRYNO as nvarchar) as 'RowKey',
		ISNULL("+ dbo.fn_SqlTranslatedColumn('DIARY',null,'LONGNARRATIVE','D',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('DIARY','SHORTNARRATIVE',null,'D',@sLookupCulture,@pbCalledFromCentura)+")
					as 'Narrative',
		CASE 	WHEN D.TRANSNO is not null
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END 			as 'IsPosted',
		CASE	WHEN D.STARTTIME is not null and
			     D.FINISHTIME is not null and
			     D.TOTALTIME is null 
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)	
		END			as 'IsContinued',
		CASE WHEN (isnull(SC.COLBOOLEAN, 0) = 1 OR D.NAMENO is null) and
			D.CASEID is null OR D.ACTIVITY is null or (( D.TOTALTIME is null or D.TOTALUNITS is null or D.TOTALUNITS = 0 or D.TIMEVALUE is null ) AND (D1.PARENTENTRYNO is null or D.ENTRYNO != D1.PARENTENTRYNO))
			OR (D.CHARGEOUTRATE is null and isnull(SR.COLBOOLEAN,0) = 1)
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END			as 'IsIncomplete',	 
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
	left join SITECONTROL SC 	on (SC.CONTROLID = 'CASEONLY_TIME')
	left join SITECONTROL SR 	on (SR.CONTROLID = 'Rate mandatory on time items')
	where 	D.EMPLOYEENO = @pnStaffKey"+char(10)+
	CASE	WHEN @pdtDate is not null
		 		  	-- Use the fn_ConstructOperator to set the @pdtFromDate 
					-- to the earliest possible time (i.e. '00:00:00.000')
					-- and the @pdtToDate to the latest possible time (i.e. '23:59:59.997')
		THEN "and D.STARTTIME "+dbo.fn_ConstructOperator(7,
								 'DT',
								 convert(nvarchar,@pdtDate,112), 
								 convert(nvarchar,@pdtDate,  112),
								 @pbCalledFromCentura)	
		WHEN @dDate is not null
		THEN "and D.STARTTIME "+dbo.fn_ConstructOperator(7,
								 'DT',
								 convert(nvarchar,@dDate,112), 
								 convert(nvarchar,@dDate,112),
								 @pbCalledFromCentura)		
	END+char(10)+	
	"order by 'StartDateTime' desc"									

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pdtDate		datetime',
			  @pnStaffKey		= @pnStaffKey,
			  @pdtDate		= @pdtDate

	Set @pnRowCount=@@Rowcount
End

-- Populate the DaySummary result set
If  @nErrorCode = 0
Begin	

	Set @sSQLString = "
	Select  D.EMPLOYEENO		as 'StaffKey',
		convert(char(10),convert(datetime,D.STARTTIME,120),120)
					as 'EntryDate',
		SUM(
		isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
		)			as 'MinutesWorked',
		SUM( CASE WHEN D.TIMEVALUE > 0 THEN
		isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
		ELSE 0
		END) 			as 'ChargeableMinutes',
		SUM( CASE WHEN D.TIMEVALUE = 0 or D.TIMEVALUE is null THEN
		isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
		ELSE 0
		END) 			as 'NonChargeableMinutes',
		SUM(D.TIMEVALUE)	as 'LocalValue',	
		convert(int,round(
			     CASE WHEN SUM(
					  isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
					  +
					  isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
			  		  ) = 0
			     -- Avoid 'divide by zero' exception and set ChargeablePercent to null.
			     THEN null
			     ELSE CAST(
				  SUM( CASE WHEN D.TIMEVALUE > 0 THEN
				  isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				  +
				  isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
				  END) AS FLOAT)
				  /
				  CAST(ISNULL((SC.COLDECIMAL*60), (8.00*60)) AS FLOAT)*100
			     END
				  ,0)) as 'ChargeablePercent',	
		SUM(isnull(D.TOTALUNITS, 0)) as 'TotalUnits',
		SUM(isnull(D.DISCOUNTVALUE, 0)) as 'TotalDiscount',
		SUM(isnull(D.FOREIGNVALUE, 0)) as 'ForeignValue',
		CAST(D.EMPLOYEENO as nvarchar) + '^' + Cast(convert(char(10),convert(datetime,D.STARTTIME,120),120) as nvarchar) as 'RowKey'	
	from 	DIARY D			
	left join SITECONTROL SC 	on SC.CONTROLID = 'Standard Daily Hours'
	where 	D.EMPLOYEENO = @pnStaffKey
	and	D.ISTIMER = 0"+char(10)+
	CASE	WHEN @pdtDate is not null
		 		  	-- Use the fn_ConstructOperator to set the @pdtFromDate 
					-- to the earliest possible time (i.e. '00:00:00.000')
					-- and the @pdtToDate to the latest possible time (i.e. '23:59:59.997')
		THEN "and D.STARTTIME "+dbo.fn_ConstructOperator(7,
								 'DT',
								 convert(nvarchar,@pdtDate,112), 
								 convert(nvarchar,@pdtDate,  112),
								 @pbCalledFromCentura)	
		WHEN @dDate is not null
		THEN "and D.STARTTIME "+dbo.fn_ConstructOperator(7,
								 'DT',
								 convert(nvarchar,@dDate,112), 
								 convert(nvarchar,@dDate,112),
								 @pbCalledFromCentura)									
	END+char(10)+	
	"group by D.EMPLOYEENO, convert(char(10),convert(datetime,D.STARTTIME,120),120), SC.COLDECIMAL
	order by 'EntryDate'"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pdtDate		datetime',
			  @pnStaffKey		= @pnStaffKey,
			  @pdtDate		= @pdtDate

	Set @pnRowCount=@@Rowcount
End
	

Return @nErrorCode
GO

Grant exec on dbo.ts_ListTimesheetDaySummary to public
GO
