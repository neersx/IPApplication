---------------------------------------------------------------------------------------------
-- Creation of dbo.ts_ListTimesheetData
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListTimesheetData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListTimesheetData.'
	drop procedure [dbo].[ts_ListTimesheetData]
	Print '**** Creating Stored Procedure dbo.ts_ListTimesheetData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ListTimesheetData
(	
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@pnStaffKey		int		= null, -- The key of the staff member the time belongs to. If not supplied, the name key of the @pnUserIdentityId will be used.
	@pdtFromDate		datetime	= null,	-- The from date for the time entries required.
	@pdtToDate		datetime	= null,	-- The to date for the time entries required.
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ts_ListTimesheetData
-- VERSION:	36
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates the TimesheetData dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 Mar 2005  TM	RFC2379	1	Procedure created
-- 14 Mar 2005	TM	RFC2379	2	The Product data should only be populated if Product Recorded 
--					on WIP site control is turned on.
-- 14 Mar 2005	TM	RFC2379	3	Add new WIP and DisplayNameKey columns.
-- 12 May 2005	TM	RFC2379	4	Add new DaySummary datatable.
-- 12 May 2005	TM	RFC2379	5	Avoid 'divide by zero' exception and set ChargeablePercent to null if required.	
-- 15 May 2005	JEK	RFC2508	6	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 30 May 2005	TM	RFC2646	7	Modify the denominator for the DaySummary.ChargeablePercent calculation. It should   
--					divide by the total number of minutes in a working day. If the Standard Daily 
--					Hours site control is null, use a default value of 8.
-- 20 Jun 2005	JEK	RFC1100	8	Change for use with Timesheet web part only; i.e. no maintenance.
-- 06 Jul 2005	JEK	RFC1100	9	Exclude timer rows.
-- 11 Jul 2005	TM	RFC2834	10	Correct IsIncomplete extraction logic.
-- 25 Nov 2005	LP	RFC1017	11	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 15 Dec 2008	MF	17136	12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 23 Feb 2010	MS	RFC7268	13	Condition for ChargeOutRate added for IsComplete field.
-- 17 Jun 2010	SF	RFC5040	14	Add Units, Values and Discount in the result set
-- 21 Jun 2010	SF	RFC5040 15	Add TimeCarriedForward and ParentEntryNo in the result set
-- 30 Jun 2010	SF	RFC5040	16	Add Foreign Value and Foreign Currency Value and Case Title
-- 08 Jul 2010	SF	RFC5040	17	Return DaySummary.Entry as date rather than string
-- 25 Aug 2010	SF	RFC9717	18	Add additional columns for in-line editing purposes
-- 20 Sep 2010	SF	RFC9309	19 	Add LastModifiedColumn, Units Per Hour, Exchange Rate
--								Remove IsTimer filter
-- 07 Mar 2011	SF	RFC9871	20	Add additional columns for in-line editing purposes.
-- 28 Apr 2011	SF	R10350	21	Return ChargeableUnits and NonChargeableUnits
-- 14 May 2011	SF	R100558 22	Return TimerRunning result set
-- 02 Feb 2012	SF	R11777	23	Indicate the name running the timer if LOGIDENTITYID <> @pnUserIdentityId
-- 27 Apr 2012	KR	R11414	24	Modified the IsComplete Logic
-- 01 May 2012	KR	R12236	25	Total on 'Timesheet List View' and Total on 'Day Summary' do not match
-- 18 Jul 2012	vql	ST67	26	Return the CreatedOn column.
-- 19 Jul 2012	SF 	R12056	27	Retrieve top 20 recent cases
-- 11 Dec 2012	KR	R13022	28	Remove CreatedOn column from summary data.
-- 17 Apr 2013	KR	R13348	29	Removed the fix I did for version 25 and added two extra columns to handle issue reported R12236
-- 05 Jul 2013	vql	R13629	30	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	31	Adjust formatted names logic (DR-15543).
-- 11 Nov 2015	vql	R54969	32	Error received by some timekeepers when using time entry, DR-16275. (Remove duplicates from recent cases result set)
-- 14 Dec 2015	MF	R56301	33	Rework of RFC54969 as SQLServer ran extrememly slow when DISTINCT clause added and executed using sp_executesql. Recoded
--					to simplify query so DISTINCT is no longer required.
-- 19 Jan 2016	MF	R56301	34	Rework of RFC54969 as SQLServer ran extrememly slow when DISTINCT clause added and executed using sp_executesql. Recoded
--					to simplify query so DISTINCT is no longer required.
-- 06 Apr 2016	LP	R39349	35	Return IsLocked and IsBilled flags for Posted Items.
-- 14 Nov 2018  AV  75198/DR-45358	36   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sSQLString		nvarchar(max)

Declare @sCurrentUserName	nvarchar(254)
Declare @sCurrentUserCode	nvarchar(10)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint

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
		D.PARENTENTRYNO as 'ParentEntryNo',
		D.STARTTIME		as 'StartDateTime',
		D.FINISHTIME		as 'FinishDateTime',
		N.NAMENO		as 'DisplayNameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as 'Name',
		N.NAMECODE		as 'NameCode',
		C.CASEID		as 'CaseKey',
		C.IRN			as 'CaseReference',
		"+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+"
					as 'CaseShortTitle',		
		W.WIPCODE		as 'ActivityKey',
		"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+"
					as 'Activity',	
		D.EXCHRATE		as 'ExchangeRate',
		D.CHARGEOUTRATE 	as 'ChargeOutRate',						
		D.COSTCALCULATION1 	as 'CostCalculation1',
		D.COSTCALCULATION2 	as 'CostCalculation2',
		D.TOTALTIME as 'TotalTime',
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then D.TOTALTIME Else Convert(char(16),D.TOTALTIME, 121) End	as 'RoundedTotalTime',
		D.TOTALUNITS		as 'TotalUnits', 
		D.TIMEVALUE		as 'TimeValue',  
		D.DISCOUNTVALUE	as 'DiscountValue',
		D.FOREIGNVALUE	as 'ForeignValue',
		D.FOREIGNCURRENCY	as 'ForeignCurrencyCode',
		D.FOREIGNDISCOUNT 	as 'ForeignDiscountValue',
		CU.DECIMALPLACES as 'ForeignCurrencyDecimalPlaces',
		D.TIMECARRIEDFORWARD as 'TimeCarriedForward',
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then D.TIMECARRIEDFORWARD Else Convert(char(16),D.TIMECARRIEDFORWARD, 121) End as 'RoundedTimeCarriedForward',
		D.UNITSPERHOUR		as 'UnitsPerHour',
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
			     D.TOTALTIME is null and D1.PARENTENTRYNO = D.ENTRYNO
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)	
		END			as 'IsContinued',
		CASE WHEN (isnull(SC.COLBOOLEAN, 0) = 1 OR D.NAMENO is null) and
			D.CASEID is null OR D.ACTIVITY is null or (( D.TOTALTIME is null or D.TOTALUNITS is null or D.TOTALUNITS = 0 or D.TIMEVALUE is null ) AND (D1.PARENTENTRYNO is null or D.ENTRYNO != D1.PARENTENTRYNO))
			OR (D.CHARGEOUTRATE is null and isnull(SR.COLBOOLEAN,0) = 1)
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END			as 'IsIncomplete',
		D.WIPENTITYNO		as 'EntityNo',
		D.TRANSNO		as 'TransNo',
		D.WIPSEQNO		as 'WipSeqNo',
		Cast(D.ISTIMER as bit)		as 'IsTimer',
		D.MARGINNO		as 'MarginNo',
		CL.FILELOCATION				as 'FileLocationKey',
				"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'FLD',@sLookupCulture,@pbCalledFromCentura)			
								+"			as 'FileLocation',
		D.LOGDATETIMESTAMP	as 'LogDateTimeStamp',
		CASE WHEN D.ISTIMER = 1 and UI.IDENTITYID <> @pnUserIdentityId THEN N1.NAMENO ELSE NULL END as 'TimerOwnedByNameKey',
		CASE WHEN D.ISTIMER = 1 and UI.IDENTITYID <> @pnUserIdentityId THEN 
			dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null)
		 ELSE NULL
		 END as 'TimerOwnedByDisplayName',
		 D.CREATEDON as 'CreatedOn',
		 CASE WHEN WP.TRANSNO IS NOT NULL THEN CAST(1 as bit) END as 'IsLocked',
		 CASE WHEN WH.TRANSNO IS NOT NULL and D.TRANSNO IS NOT NULL THEN CAST(1 as bit) END as 'IsBilled'
	from 	DIARY D			
	left join DIARY D1		on (D1.PARENTENTRYNO = D.ENTRYNO and D1.EMPLOYEENO = D.EMPLOYEENO)	
	left join CASES C		on (C.CASEID = D.CASEID)
	left join CASENAME CN		on (CN.CASEID = C.CASEID
					and CN.NAMETYPE = 'I'
					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))	" + CHAR(10)						
	-- For time recorded against a case, the name of the instructor for the case (CaseKey) 
	-- is shown for information purposes.  Information is obtained from CaseName and Name.
	-- For time recorded directory against a name (instead of a case), the NameKey is obtained 
	-- from Diary.NameNo and the associated information from Name.
	-- Note: Look at the Diary.CaseId first even if the Diary.Name exists as well as the Diary.CaseId
	+
	"
	left join NAME N 		on (N.NAMENO = ISNULL(CN.NAMENO, D.NAMENO))
	left join WIPTEMPLATE W 	on (W.WIPCODE = D.ACTIVITY)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'CASEONLY_TIME')
	left join SITECONTROL SR 	on (SR.CONTROLID = 'Rate mandatory on time items')
	left join TABLECODES TC		on (TC.TABLECODE = D.PRODUCTCODE)
	left join SITECONTROL SCP	on (SCP.CONTROLID = 'Product Recorded on WIP')
	left join NARRATIVE NRT		on (NRT.NARRATIVENO = D.NARRATIVENO)
	left join USERIDENTITY UI	on (UI.IDENTITYID = D.LOGIDENTITYID)
	left join NAME N1		on (UI.NAMENO = N1.NAMENO)
	left join CURRENCY CU		on (CU.CURRENCY = D.FOREIGNCURRENCY)
	left join SITECONTROL SC1 	on SC1.CONTROLID = 'Consider Secs in Units Calc.'"+CHAR(10)+
	-- find the most recent CASE LOCATION for the current case.
		"		
		left join (	select	CASEID, 
					MAX( convert(nvarchar(24),WHENMOVED, 21)+cast(CASEID as nvarchar(12)) ) as [DATE]
					from CASELOCATION CLMAX
					group by CASEID	
					) LASTMODIFIED	on (LASTMODIFIED.CASEID = C.CASEID)
		left join	CASELOCATION CL		on (CL.CASEID = C.CASEID
										and ( (convert(nvarchar(24),CL.WHENMOVED, 21)+cast(CL.CASEID as nvarchar(12))) = LASTMODIFIED.[DATE]
															or LASTMODIFIED.[DATE] is null ))
		left join	TABLECODES FLD on (FLD.TABLECODE = CL.FILELOCATION)
	left join WORKINPROGRESS WP on (WP.ENTITYNO = D.WIPENTITYNO 
					and WP.TRANSNO = D.TRANSNO
					and WP.STATUS = 2 
					and D.TRANSNO IS NOT NULL)
	left join WORKHISTORY WH on (WH.ENTITYNO = D.WIPENTITYNO
					and WH.TRANSNO = D.TRANSNO
					and WH.TRANSTYPE = 510)
	where 	D.EMPLOYEENO = @pnStaffKey"+char(10)+
	CASE	WHEN @pdtFromDate is not null or @pdtToDate is not null
		 		  	-- Use the fn_ConstructOperator to set the @pdtFromDate 
					-- to the earliest possible time (i.e. '00:00:00.000')
					-- and the @pdtToDate to the latest possible time (i.e. '23:59:59.997')
		THEN "and D.STARTTIME "+dbo.fn_ConstructOperator(7,
								 'DT',
								 convert(nvarchar,@pdtFromDate,112), 
								 convert(nvarchar,@pdtToDate,  112),
								 @pbCalledFromCentura)									
	END


	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pnUserIdentityId	int,
			  @pdtFromDate		datetime,
			  @pdtToDate		datetime',
			  @pnStaffKey		= @pnStaffKey,
			  @pnUserIdentityId	= @pnUserIdentityId,
			  @pdtFromDate		= @pdtFromDate,
			  @pdtToDate		= @pdtToDate 

	Set @pnRowCount=@@Rowcount
End

-- Populate the DaySummary result set
If  @nErrorCode = 0
Begin	

	Set @sSQLString = "
	Select  D.EMPLOYEENO		as 'StaffKey',
		dbo.fn_DateOnly(D.STARTTIME) as 'EntryDate',
		cast(SUM(
		isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0) + 
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then cast(isnull(DATEPART(SECOND, D.TOTALTIME),0) as decimal(10,4))/60 Else 0 End
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)  + 
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then cast(isnull(DATEPART(SECOND, D.TIMECARRIEDFORWARD),0) as decimal(10,4))/60 Else 0 End
		) as int)			as 'MinutesWorked',
		cast(round(SUM( CASE WHEN D.TIMEVALUE > 0 THEN
		isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0) + 
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then cast(isnull(DATEPART(SECOND, D.TOTALTIME),0) as decimal(10,4))/60 Else 0 End
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)  + 
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then cast(isnull(DATEPART(SECOND, D.TIMECARRIEDFORWARD),0) as decimal(10,4))/60 Else 0 End
		END),0) as int)			as 'ChargeableMinutes',
		SUM(CASE
             WHEN D.TIMEVALUE > 0 THEN TOTALUNITS
           END)			as 'ChargeableUnits',
		cast (round(SUM( CASE WHEN D.TIMEVALUE = 0 or D.TIMEVALUE is null THEN
		isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)  + 
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then cast(isnull(DATEPART(SECOND, D.TOTALTIME),0) as decimal(10,4))/60 Else 0 End
		+
		isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0) + 
		Case When (isnull(SC1.COLBOOLEAN,0) = 1)
		Then cast(isnull(DATEPART(SECOND, D.TIMECARRIEDFORWARD),0) as decimal(10,4))/60 Else 0 End
		END) , 0)	as int)		as 'NonChargeableMinutes',
		SUM(CASE
             WHEN D.TIMEVALUE = 0 THEN TOTALUNITS
           END)			as 'NonChargeableUnits',
		SUM(D.TIMEVALUE)	as 'LocalValue',	
		convert(int,round(
			     CASE WHEN SUM(
					  isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0) +
					  Case When (isnull(SC1.COLBOOLEAN,0) = 1)
					  Then isnull(DATEPART(SECOND, D.TOTALTIME),0)/60 Else 0 End
					  +
					  isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0) +
					  Case When (isnull(SC1.COLBOOLEAN,0) = 1)
					  Then isnull(DATEPART(SECOND, D.TIMECARRIEDFORWARD),0)/60 Else 0 End
			  		  ) = 0
			     -- Avoid 'divide by zero' exception and set ChargeablePercent to null.
			     THEN null
			     ELSE CAST(
				  SUM( CASE WHEN D.TIMEVALUE > 0 THEN
				  isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0) + 
				  Case When (isnull(SC1.COLBOOLEAN,0) = 1)
				  Then isnull(DATEPART(SECOND, D.TOTALTIME),0)/60 Else 0 End
				  +
				  isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)+ 
				  Case When (isnull(SC1.COLBOOLEAN,0) = 1)
				  Then isnull(DATEPART(SECOND, D.TIMECARRIEDFORWARD),0)/60 Else 0 End
				  END) AS FLOAT)
				  /
				  CAST(ISNULL((SC.COLDECIMAL*60), (8.00*60)) AS FLOAT)*100
			     END
				  ,0)) as 'ChargeablePercent'
	from 	DIARY D			
	left join SITECONTROL SC 	on SC.CONTROLID = 'Standard Daily Hours'
	left join SITECONTROL SC1 	on SC1.CONTROLID = 'Consider Secs in Units Calc.'
	where 	D.EMPLOYEENO = @pnStaffKey"+char(10)+
	CASE	WHEN @pdtFromDate is not null or @pdtToDate is not null
		 		  	-- Use the fn_ConstructOperator to set the @pdtFromDate 
					-- to the earliest possible time (i.e. '00:00:00.000')
					-- and the @pdtToDate to the latest possible time (i.e. '23:59:59.997')
		THEN "and D.STARTTIME "+dbo.fn_ConstructOperator(7,
								 'DT',
								 convert(nvarchar,@pdtFromDate,112), 
								 convert(nvarchar,@pdtToDate,  112),
								 @pbCalledFromCentura)									
	END+char(10)+
	"group by D.EMPLOYEENO, dbo.fn_DateOnly(D.STARTTIME), SC.COLDECIMAL
	order by 'EntryDate'"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pdtFromDate		datetime,
			  @pdtToDate		datetime',
			  @pnStaffKey		= @pnStaffKey,
			  @pdtFromDate		= @pdtFromDate,
			  @pdtToDate		= @pdtToDate 

	Set @pnRowCount=@@Rowcount
End

-- timer	
If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  D.EMPLOYEENO			as 'StaffKey',
		dbo.fn_DateOnly(D.STARTTIME)	as 'EntryDate',
		D.ENTRYNO			as 'EntryNo'
	from 	DIARY D		
	where 	D.EMPLOYEENO = @pnStaffKey 
	and	D.ISTIMER = 1"
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int',
			  @pnStaffKey		= @pnStaffKey
End

-- recent cases
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select C.CASEID		as 'CaseKey',
			C.IRN			as 'CaseReference',
			"+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+"
					as 'CaseShortTitle',
			RECENT.FINISHTIME 	as 'LastUsed'
		from (	select	top 20 CASEID, 
			MAX( FINISHTIME ) as FINISHTIME
			from DIARY DMAX
			where DMAX.EMPLOYEENO = @pnStaffKey 
			and (FINISHTIME <= @pdtToDate or @pdtToDate is null)
			group by CASEID	
			order by FINISHTIME desc) RECENT
		join CASES C on (C.CASEID = RECENT.CASEID)"
		
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnStaffKey		int,
			  @pdtToDate		datetime',
			  @pnStaffKey		= @pnStaffKey,
			  @pdtToDate		= @pdtToDate 
End

Return @nErrorCode
GO

Grant exec on dbo.ts_ListTimesheetData to public
GO