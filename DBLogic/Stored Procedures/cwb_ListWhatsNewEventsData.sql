-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cwb_ListWhatsNewEventsData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListWhatsNewEventsData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListWhatsNewEventsData.'
	Drop procedure [dbo].[cwb_ListWhatsNewEventsData]
	Print '**** Creating Stored Procedure dbo.cwb_ListWhatsNewEventsData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListWhatsNewEventsData
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,
	@pnPeriod		smallint	= null,		
	@psPeriodType		nvarchar(1)	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	cwb_ListWhatsNewEventsData
-- VERSION:	8
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Events that have occurred recently for the
--		specified case.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 10 Nov 2006  AU	RFC2982	1	Procedure created
-- 22 Mar 2007  AO	RFC4876	2	Add RowKey.
-- 11 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 21 Jul 2009	MF	17748	4	Reduce locking level to ensure other activities are not blocked.
-- 17 Sep 2010	MF	RFC9777	5	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 24 Oct 2011	ASH	R11460  6	Cast integer columns as nvarchar(11) data type.
-- 02 Mar 2015	MS	R43203	7	Get case event text from EVENTTEXT table
-- 07 Sep 2018	AV	74738	8	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @ErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare	@sFromDate		nchar(11)

Declare @sLookupCulture		nvarchar(10)

-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@ErrorCode=0
Set 	@pnRowCount=0

If @pnPeriod is null
	Set @pnPeriod=1

If @psPeriodType is null
or @psPeriodType not in ('D','W','M','Y')
	Set @psPeriodType='W'

-- Calculate the starting date range

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFromDate=
		CASE @psPeriodType
			WHEN('D') THEN convert(varchar, dateadd(day,   -1*@pnPeriod, getdate()),112)
			WHEN('W') THEN convert(varchar, dateadd(week,  -1*@pnPeriod, getdate()),112)
			WHEN('M') THEN convert(varchar, dateadd(month, -1*@pnPeriod, getdate()),112)
			WHEN('Y') THEN convert(varchar, dateadd(year,  -1*@pnPeriod, getdate()),112)
		END"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sFromDate	nchar(11)	OUTPUT,
				  @psPeriodType	nchar(1),
				  @pnPeriod	smallint',
				  @sFromDate   =@sFromDate	OUTPUT,
				  @psPeriodType=@psPeriodType,
				  @pnPeriod    =@pnPeriod
End

-- Now return the actual Case Event details of Events that have occurred
-- within the date range and where :
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	cast(CE.CASEID as nvarchar(11))+ '^' + cast(CE.EVENTNO as nvarchar(11))+ '^' + cast(CE.CYCLE as nvarchar(10)) as RowKey,
		CE.CASEID 	as CaseKey,
		CE.EVENTNO	as EventKey,
		CE.CYCLE	as Cycle,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
			 E.EVENTDESCRIPTION) 
				as EventDescription,
		E.DEFINITION 	as EventDefinition,
		CE.EVENTDATE 	as EventDate,
		CASE 	WHEN SC.COLBOOLEAN = 1
			THEN "+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"
			ELSE   null
		END		as EventText,
		ltrim(substring(NT.OFFICIALNUMBERSTRING,51,50))
				as NumberTypeDescription,
		ltrim(substring(NT.OFFICIALNUMBERSTRING,11,40))
				as OfficialNumber
	from dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FC
	     join CASEEVENT CE		on (CE.CASEID=FC.CASEID
					and CE.EVENTDATE is not null
					and CE.OCCURREDFLAG between 1 and 8)
	     join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture, 1,@pbCalledFromCentura) E			
					on (E.EVENTNO=CE.EVENTNO)
	left join OPENACTION OX		on (OX.CASEID=CE.CASEID
					and OX.ACTION=E.CONTROLLINGACTION
					and OX.CYCLE=(	Select max(OX1.CYCLE)
							from OPENACTION OX1
							where OX1.CASEID=OX.CASEID
							and OX1.ACTION=OX.ACTION))
	left join EVENTCONTROL EC	on (EC.EVENTNO=CE.EVENTNO
					and EC.CRITERIANO=isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))
	left join SITECONTROL SC	on (SC.CONTROLID = 'Client Event Text')
	-- Return the Official Number that has the lowest DisplayPriority
	-- where the Event is related to the NumberType.
	left join (	select  O.CASEID, N.RELATEDEVENTNO, 
				min( cast(N.DISPLAYPRIORITY as char(10))
				    +cast(O.OFFICIALNUMBER  as char(40))
				    +     N.DESCRIPTION) as OFFICIALNUMBERSTRING
			from OFFICIALNUMBERS O 
			join fn_FilterUserNumberTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura) N
						on (N.NUMBERTYPE=O.NUMBERTYPE)
			where O.ISCURRENT=1
			and N.RELATEDEVENTNO is not null
			group by O.CASEID, N.RELATEDEVENTNO) NT 
						on (NT.CASEID=FC.CASEID
						and NT.RELATEDEVENTNO=E.EVENTNO)
	left	join (Select ET.EVENTTEXT, CET.CASEID, CET.EVENTNO, CET.CYCLE
				from EVENTTEXT ET
				Join CASEEVENTTEXT CET	on (CET.EVENTTEXTID = ET.EVENTTEXTID)
				where ET.EVENTTEXTTYPEID is null)
			as ETF on (ETF.CASEID = CE.CASEID and ETF.EVENTNO = CE.EVENTNO and ETF.CYCLE = CE.CYCLE)
	Where CE.CASEID = @pnCaseKey and (CE.EVENTDATE between @sFromDate and getdate())
	order by CE.EVENTDATE desc, isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION)"

	exec sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pnCaseKey		int,
				  @pbCalledFromCentura	bit,
				  @sFromDate		nchar(11)',
				  @pnUserIdentityId	=@pnUserIdentityId,
				  @sLookupCulture   	=@sLookupCulture,
				  @pnCaseKey		=@pnCaseKey,
				  @pbCalledFromCentura 	=@pbCalledFromCentura,
				  @sFromDate       	=@sFromDate

	Set @pnRowCount=@@Rowcount
End

Return @ErrorCode
GO

Grant execute on dbo.cwb_ListWhatsNewEventsData to public
GO
