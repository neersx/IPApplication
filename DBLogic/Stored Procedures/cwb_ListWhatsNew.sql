-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cwb_ListWhatsNew
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListWhatsNew]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListWhatsNew.'
	Drop procedure [dbo].[cwb_ListWhatsNew]
	Print '**** Creating Stored Procedure dbo.cwb_ListWhatsNew...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListWhatsNew
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPeriod		smallint	= null,		
	@psPeriodType		nvarchar(1)	= null, 
	@pnRowCountCases	int		= null output, 
	@pnRowCountEvents	int		= null output,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	cwb_ListWhatsNew
-- VERSION:	17
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Events that have occurred recently

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 29 Aug 2003  MF		1	Procedure created
-- 12 Sep 2003	MF		2	Modify the Select for Cases because the "Your Ref" is now returned
--					by fn_FilterUserCases
-- 09-Oct-2003	MF	RFC519	3	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 13-Oct-2003	TM	RFC396	4	Case Advanced Search. Replace join to the NUMBERTYPES table with 
--					the join to the new fn_FilterUserNumberTypes. 
-- 30-Oct-2003	TM	RFC336	5	Change the result set returned by cwb_ListWhatsNew to use CurrentOfficialNumber
--					instead of CurrentOfficialNo so that it matches the dataset defined.
-- 19-Feb-2004	TM	RFC976	6	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Mar-2004	TM	RFC1032	7	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 01-Sep-2004	TM	RFC1732	8	Return a single Event and Official Number combination. Choose the number 
--					type and official number that match the following criteria: 1) Official 
--					number exists, 2) Number type with minimum DisplayPriority.
-- 02 Sep 2004	TM	RFC1732	9	Implement Mike's feedback.
-- 09 Sep 2004	JEK	RFC886	10	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 15 Sep 2004 	TM	RFC886	11	Implement translation.
-- 15 May 2005	JEK	RFC2508	12	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 08 Feb 2005	TM	RFC2429	13	Return the EventText column in the Event result set if 
--					Client Event Text site control is set to TRUE
-- 11 Dec 2008	MF	17136	14	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 Feb 2010	MF	RFC8846	15	Performance problem. Loads available Events and CASEVENTS into temporary tables and then 
--					use the temporary tables in the main select.
-- 17 Sep 2010	MF	RFC9777	16	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 07 Sep 2018	AV	74738	17	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Create table #TEMPEVENTS (
	EVENTNO			int		not null PRIMARY KEY,
	EVENTDESCRIPTION	nvarchar(100)	collate database_default null,
	DEFINITION		nvarchar(254)	collate database_default null,
	CONTROLLINGACTION	nvarchar(2)	collate database_default null
	)

Create table #TEMPCASEEVENTS (
	CASEID			int		not null,
	EVENTNO			int		not null,
	CYCLE			int		not null,
	CLIENTREFERENCENO	nvarchar(100)	collate database_default null
	)

Declare @ErrorCode 		int

Declare @sSQLString		nvarchar(4000)
Declare	@sFromDate		nchar(11)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@ErrorCode=0
Set 	@pnRowCountCases=0
Set 	@pnRowCountEvents=0

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

If @ErrorCode=0
Begin
	--------------------------------------------------------
	-- The filtered CaseEvents are being loaded into a temporary
	-- table as a performance enhancement step.
	-- When the user defined function was imbedded into the
	-- main SQL there was significant problems that I could
	-- not resolve.
	--------------------------------------------------------
	Set @sSQLString="
	insert into #TEMPCASEEVENTS (CASEID,EVENTNO,CYCLE,CLIENTREFERENCENO)
	select CE.CASEID, CE.EVENTNO, CE.CYCLE, FC.CLIENTREFERENCENO
	from dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FC
	join CASEEVENT CE	on (CE.CASEID=FC.CASEID)
	join #TEMPEVENTS E	on (E.EVENTNO=CE.EVENTNO)
	where CE.EVENTDATE between @sFromDate and getdate()"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sFromDate		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @sFromDate		= @sFromDate
End

-- A separate result set is required for the Cases that have events within the date
-- range as well as a separate result set to the actual Events themselves.
-- I have elected to write two separate queries rather than load a table variable
-- with a single result and then SELECTing from the table variable.  By not using a 
-- table variable I can then use sp_executesql which is a more efficient method of
-- executing SQL that contains variables.

-- Get the Cases that have Events that have occurred within the date range as long as :
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	distinct
		C.CASEID 	as CaseKey,
		C.CURRENTOFFICIALNO	
				as CurrentOfficialNumber,
		CE.CLIENTREFERENCENO
				as YourReference,
		C.IRN 		as OurReference,
		"+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+
			      " as Title,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+
			      "	as StatusSummary,
		"+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+
			      " as CaseStatusDescription,
		"+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)+
			      " as RenewalStatusDescription,
		"+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+
			      " as PropertyTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+
			      " as CountryName
	from #TEMPCASEEVENTS CE
	     join CASES C		on (C.CASEID=CE.CASEID)
	     join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	     join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=C.PROPERTYTYPE
					and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
							    from VALIDPROPERTY VP1
							    where VP1.PROPERTYTYPE=VP.PROPERTYTYPE
							    and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
	left join PROPERTY P		on (P.CASEID=C.CASEID)
	left join STATUS S		on (S.STATUSCODE=C.STATUSCODE)
	left join STATUS R		on (R.STATUSCODE=P.RENEWALSTATUS)
	left join TABLECODES TC		on (TC.TABLECODE=CASE WHEN(S.LIVEFLAG=0 OR R.LIVEFLAG=0)
									THEN 7603	-- Dead
							      WHEN(S.REGISTEREDFLAG=1)
									THEN 7602	-- Registered
									ELSE 7601	-- Pending
							 END)
	order by C.IRN"

	exec sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit',
				  @pnUserIdentityId=@pnUserIdentityId,
				  @sLookupCulture   	=@sLookupCulture,
				  @pbCalledFromCentura 	=@pbCalledFromCentura

	Set @pnRowCountCases=@@Rowcount
End

-- Now return the actual Case Event details of Events that have occurred
-- within the date range and where :
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	CE.CASEID 	as CaseKey,
		CE.EVENTNO	as EventKey,
		CE.CYCLE	as Cycle,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
			 E.EVENTDESCRIPTION) 
				as EventDescription,
		E.DEFINITION 	as EventDefinition,
		CE.EVENTDATE 	as EventDate,
		CASE 	WHEN SC.COLBOOLEAN = 1
			THEN CASE WHEN CE.LONGFLAG = 1 THEN CE.EVENTLONGTEXT ELSE CE.EVENTTEXT END
		END		as EventText,
		ltrim(substring(NT.OFFICIALNUMBERSTRING,51,50))
				as NumberTypeDescription,
		ltrim(substring(NT.OFFICIALNUMBERSTRING,11,40))
				as OfficialNumber
	from #TEMPCASEEVENTS T
	     join CASEEVENT CE		on (CE.CASEID =T.CASEID
					and CE.EVENTNO=T.EVENTNO
					and CE.CYCLE  =T.CYCLE)
	     join #TEMPEVENTS E		on (E.EVENTNO=CE.EVENTNO)
	left join OPENACTION OX		on (OX.CASEID=T.CASEID
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
						on (NT.CASEID=CE.CASEID
						and NT.RELATEDEVENTNO=E.EVENTNO)
	order by CE.CASEID, CE.EVENTDATE desc, isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION)"

	exec sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit,
				  @sFromDate		nchar(11)',
				  @pnUserIdentityId=@pnUserIdentityId,
				  @sLookupCulture   	=@sLookupCulture,
				  @pbCalledFromCentura 	=@pbCalledFromCentura,
				  @sFromDate       	=@sFromDate

	Set @pnRowCountEvents=@@Rowcount
End

Return @ErrorCode
GO

Grant execute on dbo.cwb_ListWhatsNew to public
GO
