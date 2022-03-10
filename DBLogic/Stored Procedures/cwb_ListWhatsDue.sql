-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cwb_ListWhatsDue
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListWhatsDue]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListWhatsDue.'
	Drop procedure [dbo].[cwb_ListWhatsDue]
	Print '**** Creating Stored Procedure dbo.cwb_ListWhatsDue...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListWhatsDue
(
	@pnRowCount		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pnPeriod		smallint	= 1,		
	@psPeriodType		nvarchar(1)	= 'M',
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	cwb_ListWhatsDue
-- VERSION:	24
-- DESCRIPTION:	Returns details of the Events the user is allowed to see that are due.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 27 Aug 2003  MF		1	Procedure created
-- 28 Aug 2003	MF		2	Assume that all only external users access this stored procedure
-- 02 Sep 2003	JEK		3	Adjust column names to match dataset.
-- 12 Sep 2003	MF		4	Modify the Select for Cases because the "Your Ref" is now returned
--					by fn_FilterUserCases
-- 07-Oct-2003	MF	RFC519	5	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 19-Feb-2004	TM	RFC976	6	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Mar-2004	TM	RFC1032	7	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 11-May-2004	TM	RFC941	8	Implement new parameters @pnPeriod and @psPeriodType to control 
--					the upper limit on the date range. Default them to 1 month.
--					Use the new Client Due Dates: Overdue Days site control to control 
--					the lower limit on the date range if the value is not null.
-- 09 Sep 2004	JEK	RFC886	9	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 Sep 2004 	TM	RFC886	10	Implement translation.
-- 29 Sep 2004	MF	RFC1846	11	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 30 Nov 2004	TM	RFC1544	12	Add new EventProfileKey and RowKey columns.
-- 15 May 2005	JEK	RFC2508	13	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 08 Feb 2006	TM	RFC3429	14	Return the EventText column in the CaseEvent result set if 
--					Client Event Text site control is set to TRUE
-- 24 Oct 2006	SW	RFC2229	15	Do not return dead case
-- 18 Dec 2006	JEK	RFC2982	16	Implement new Instruction Definition rules.
-- 13 May 2008	MF	RFC6611	17	Improve performance by getting site control before the main SELECT so 
--					that the LEFT JOIN can be avoided. Particularly bad within the EXISTS clause. 
-- 14 Jan 2010	MF	RFC8754	18	Performance problem. Loads available Events into a temporary table and then 
--					use the temporary table in the main select.
-- 17 Sep 2010	MF	RFC9777	19	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 12 Nov 2010	LP	RFC9945	20	Concatentate EVENTCONTROL.CRITERIANO to make RowKey unique. 
-- 24 Oct 2011	ASH	R11460  21	Cast integer columns as varchar(11) data type.
-- 15 Apr 2013	DV	R13270	22	Increase the length of nvarchar to 11 when casting or declaring integer
-- 27 Mar 2014	MF	R32793	23	Ensure CONTROLLINGACTION is considered for Events to be displayed.
-- 12 Jun 2015	vql	R47548	24	Include country description in result set


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Create table #TEMPEVENTS (
	EVENTNO			int		not null PRIMARY KEY,
	EVENTDESCRIPTION	nvarchar(100)	collate database_default null,
	DEFINITION		nvarchar(254)	collate database_default null,
	CONTROLLINGACTION	nvarchar(2)	collate database_default null
	)

Declare @ErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare	@sToDate		nchar(8)
Declare @sFromDate		nchar(8)
Declare @sRenewalAction		nvarchar(2)
Declare @bClientEventText	bit

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@ErrorCode      = 0
Set 	@pnRowCount	= 0

-- Calculate the ending date

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sToDate=
		CASE @psPeriodType
			WHEN('D') THEN convert(varchar, dateadd(day,   @pnPeriod, getdate()),112)
			WHEN('W') THEN convert(varchar, dateadd(week,  @pnPeriod, getdate()),112)
			WHEN('M') THEN convert(varchar, dateadd(month, @pnPeriod, getdate()),112)
			WHEN('Y') THEN convert(varchar, dateadd(year,  @pnPeriod, getdate()),112)
		END"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sToDate	nchar(8)	OUTPUT,
				  @psPeriodType	nchar(1),
				  @pnPeriod	smallint',
				  @sToDate   	=@sToDate	OUTPUT,
				  @psPeriodType	=@psPeriodType,
				  @pnPeriod    	=@pnPeriod
End

-- Get the lower limit of the range reported from the Client Due Dates: Overdue Days site control.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFromDate = convert(varchar, dateadd(day, -1*SC.COLINTEGER , getdate()),112)
	from SITECONTROL SC
	where SC.CONTROLID = 'Client Due Dates: Overdue Days'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sFromDate	nchar(8)	OUTPUT',
				  @sFromDate	= @sFromDate	OUTPUT
End

-- Get the SiteControl that determines if EventText is to be returned
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bClientEventText = SC.COLBOOLEAN
	from SITECONTROL SC
	where SC.CONTROLID = 'Client Event Text'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bClientEventText		bit	OUTPUT',
				  @bClientEventText=@bClientEventText	OUTPUT
End

-- Get the SiteControl that indicates the Action controlling Next Renewal Date
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sRenewalAction = SC.COLCHARACTER
	from SITECONTROL SC
	where SC.CONTROLID = 'Main Renewal Action'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sRenewalAction	nvarchar(2)	OUTPUT',
				  @sRenewalAction=@sRenewalAction	OUTPUT
End

If @ErrorCode=0
Begin
	--------------------------------------------------------
	-- The filtered events are being loaded into a temporary
	-- table as a performance enhancement step.
	-- When the user defined function was imbedded into the
	-- main SQL there was significant problems that I could
	-- not resolve.
	--------------------------------------------------------
	Set @sSQLString="
	insert into #TEMPEVENTS(EVENTNO,EVENTDESCRIPTION,DEFINITION,CONTROLLINGACTION)
	select EVENTNO, EVENTDESCRIPTION,DEFINITION,CONTROLLINGACTION
	from dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture, 1,@pbCalledFromCentura) "
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @sLookupCulture	= @sLookupCulture,
				  @pbCalledFromCentura	= @pbCalledFromCentura
End

-- Get the Events that are current due as long as:
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	distinct
		C.CASEID 		as CaseKey,
		C.CURRENTOFFICIALNO 	as CurrentOfficialNumber,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CO',@sLookupCulture,@pbCalledFromCentura)+" as Country,
		FC.CLIENTREFERENCENO 	as 'YourReference',
		C.IRN 			as 'OurReference',
		"+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+
				      "	as Title,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
			 E.EVENTDESCRIPTION) 
					as EventDescription,
		E.DEFINITION 		as EventDefinition,
		CE.EVENTDUEDATE 	as EventDueDate,
		CASE WHEN D.CASEID IS NOT NULL THEN 1 ELSE 0 END AS HasInstructions,
		CASE 	WHEN @bClientEventText = 1
			THEN CASE WHEN CE.LONGFLAG = 1 THEN convert(nvarchar(4000), CE.EVENTLONGTEXT) ELSE CE.EVENTTEXT END
		END			as EventText,
		'C'+'^'+ 	
		cast(C.CASEID as varchar(11))+ '^'+ 
		cast(CE.EVENTNO	as varchar(11))+ '^'+ 
		cast(CE.CYCLE as varchar(10))+ '^'+
		cast(EC.CRITERIANO as varchar(11))
 					as RowKey
	from dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FC
	join CASES C			on (C.CASEID=FC.CASEID)
	join CASEEVENT CE		on (CE.CASEID=C.CASEID
					and CE.OCCURREDFLAG=0)
	join COUNTRY CO			on (CO.COUNTRYCODE = C.COUNTRYCODE)
	join #TEMPEVENTS E		on (E.EVENTNO=CE.EVENTNO)
	left join OPENACTION OX		on (OX.CASEID=C.CASEID
					and OX.ACTION=E.CONTROLLINGACTION)
	left join STATUS S		on (C.STATUSCODE = S.STATUSCODE)
	left join PROPERTY P		on (P.CASEID = C.CASEID)
	left join STATUS S2		on (P.RENEWALSTATUS = S2.STATUSCODE)
	left join EVENTCONTROL EC	on (EC.EVENTNO=CE.EVENTNO
					and EC.CRITERIANO=isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))
	LEFT JOIN (SELECT DISTINCT C.CASEID, D.DUEEVENTNO AS EVENTNO
		   FROM CASES C
		   CROSS JOIN INSTRUCTIONDEFINITION D
		   LEFT JOIN CASEEVENT P	on (P.CASEID=C.CASEID
						and P.EVENTNO=D.PREREQUISITEEVENTNO)
		   -- Available for due events
		   WHERE D.AVAILABILITYFLAGS&4=4
		   AND	 D.DUEEVENTNO IS NOT NULL
		   -- Either the instruction has no prerequisite event
		   -- or the prerequisite event exists
		   AND 	(D.PREREQUISITEEVENTNO IS NULL OR
		         P.EVENTNO IS NOT NULL
			)
		   ) D			on (D.CASEID=CE.CASEID
					and D.EVENTNO=CE.EVENTNO)
	Where (CE.OCCURREDFLAG=0 OR CE.OCCURREDFLAG is null)
	and (ISNULL(S.LIVEFLAG, 1) <> 0 and ISNULL(S2.LIVEFLAG, 1) <> 0)"
	
	-- Client Due Dates: Overdue Days site control is used to control 
	-- the lower limit on the date range if the value is not null.
	If @sFromDate is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + 
		"	and    CE.EVENTDUEDATE >= @sFromDate"  
	End
	
	Set @sSQLString = @sSQLString + char(10) + 
	"	and    CE.EVENTDUEDATE <= @sToDate	
	-- The CaseEvent must be attached to a live OPENACTION
	-- for the Event to be considered as a due date.
	and exists
	(select 1 
	 from OPENACTION OA
	 join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
				and EC.EVENTNO   =CE.EVENTNO)
	 join ACTIONS AN	on (AN.ACTION    =OA.ACTION)
	 where OA.CASEID=CE.CASEID
	 and   OA.ACTION=isnull(E.CONTROLLINGACTION,OA.ACTION) -- RFC32793
	 and   OA.POLICEEVENTS=1
	 and ((AN.NUMCYCLESALLOWED > 1  and OA.CYCLE=CE.CYCLE) or AN.NUMCYCLESALLOWED = 1)"+char(10)+
	
	CASE WHEN(@sRenewalAction is not null)
		THEN "	 and ((OA.ACTION=@sRenewalAction and EC.EVENTNO=-11) or EC.EVENTNO<>-11))"
		ELSE "	 )"
	END + "
	order by CE.EVENTDUEDATE, C.IRN, 6"

	exec sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit,
				  @sToDate		nchar(8),
				  @sFromDate		nchar(8),
				  @bClientEventText	bit,
				  @sRenewalAction	nvarchar(2)',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @sLookupCulture	= @sLookupCulture,
				  @pbCalledFromCentura	= @pbCalledFromCentura,
				  @sToDate		= @sToDate,
				  @sFromDate		= @sFromDate,
				  @bClientEventText	= @bClientEventText,
				  @sRenewalAction	= @sRenewalAction

	Set @pnRowCount=@@Rowcount
End


Return @ErrorCode
GO

Grant execute on dbo.cwb_ListWhatsDue to public
GO
