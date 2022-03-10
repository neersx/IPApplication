-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListWhatsNewEvents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListWhatsNewEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListWhatsNewEvents.'
	Drop procedure [dbo].[csw_ListWhatsNewEvents]
	Print '**** Creating Stored Procedure dbo.csw_ListWhatsNewEvents...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListWhatsNewEvents
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,		-- Mandatory
	@pnPeriod			smallint	= null,		
	@psPeriodType		nvarchar(1)	= null, 
	@psNameTypeKey 		nvarchar(3)   	= 'EMP',	-- the name type relationships that are valid for staff.  
	@psImportanceLevel	nvarchar(2) 	= null,		-- the events with an importance level greater than or equal to the value selected. 
	@pbCalledFromCentura	bit		= 0	
)
as
-- PROCEDURE:	csw_ListWhatsNewEvents
-- VERSION:	6
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Events that have occurred recently for internal user.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 11 Jul 2007  SF	RFC4887	1	Procedure created (Moved from csw_ListWhatsNew)
-- 31 Jul 2007	vql	RFC4887	2	Clean up code.
-- 12 Dec 2008	AT	RFC7365	3	Added date to Case Type filter for license check.
-- 17 Sep 2010	MF	RFC9777	4	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 03 Mar 2015	MS	R43203	5	Return event text from EVENTTEXT table rather than CASEEVENT table
-- 07 Sep 2018	AV	74738	6	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @ErrorCode 		int

Declare @sSQLString		nvarchar(max)
Declare	@sFromDate		nchar(11)
Declare @dtToday		datetime

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @dtToday = getdate()
Set	@ErrorCode=0

Set @pnPeriod = isnull(@pnPeriod, 1)

If @psPeriodType is null
or @psPeriodType not in ('D','W','M','Y')
Begin
	Set @psPeriodType='W'
End

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

-- Return the actual Case Event details of Events that have occurred
-- within the date range and where :
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
	
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	Cast(CE.CASEID as nvarchar(15)) + '^' + Cast(CE.EVENTNO as nvarchar(15)) + '^' + Cast(CE.CYCLE as nvarchar(15)) as RowKey,
		CE.CASEID 	as CaseKey,
		CE.EVENTNO	as EventKey,
		CE.CYCLE	as Cycle,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+","+char(10)
		        +dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+") 
				as EventDescription,			 	   
		"+dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)+
			      " as EventDefinition,
		"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ETF',@sLookupCulture,@pbCalledFromCentura)+"				
				as EventText,
		CE.EVENTDATE 	as EventDate,
		ltrim(substring(NT.OFFICIALNUMBERSTRING,51,50))
				as NumberTypeDescription,
		ltrim(substring(NT.OFFICIALNUMBERSTRING,11,40))
				as OfficialNumber
	from CASES C
	     join dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura,@dtToday) FCT	
					on (FCT.CASETYPE = C.CASETYPE)
	     join CASEEVENT CE		on (CE.CASEID=C.CASEID
					and CE.EVENTDATE is not null
					and CE.OCCURREDFLAG between 1 and 8)	    
	     join EVENTS E		on (E.EVENTNO=CE.EVENTNO)
	left join OPENACTION OA		on (OA.CASEID=CE.CASEID
					and OA.ACTION=E.CONTROLLINGACTION
					and OA.CYCLE=(	select max(OA1.CYCLE)
							from OPENACTION OA1
							where OA1.CASEID=OA.CASEID
							and OA1.ACTION=OA.ACTION))
	left join EVENTCONTROL EC	on (EC.EVENTNO=CE.EVENTNO
					and EC.CRITERIANO=isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA))
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
						on (NT.CASEID=C.CASEID
						and NT.RELATEDEVENTNO=E.EVENTNO)
	left	join (Select ET.EVENTTEXT, CET.CASEID, CET.EVENTNO, CET.CYCLE
				from EVENTTEXT ET
				Join CASEEVENTTEXT CET	on (CET.EVENTTEXTID = ET.EVENTTEXTID)
				where ET.EVENTTEXTTYPEID is null)
			as ETF on (ETF.CASEID = CE.CASEID and ETF.EVENTNO = CE.EVENTNO and ETF.CYCLE = CE.CYCLE)
	Where CE.EVENTDATE between @sFromDate and getdate()
	and CE.CASEID = @pnCaseKey"+
	-- Filter my Cases for me as for an Emlpoyee (or Signatory, or other relationships configured at the site): 
	" and exists
	(Select * 
 	 from CASENAME CN
	 join USERIDENTITY UI		on (UI.NAMENO = CN.NAMENO
					and UI.IDENTITYID = @pnUserIdentityId)
 	 join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,0,@pbCalledFromCentura) FUN 
					on (FUN.NAMETYPE=CN.NAMETYPE)
	 where CN.NAMETYPE   = " + dbo.fn_WrapQuotes(@psNameTypeKey,0,0) + "
	 and  (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE > getdate())
         and   CN.CASEID = C.CASEID) " + 
        Case 
                When @psImportanceLevel is not null 
                        then         "        and ISNULL(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL) >= '"+@psImportanceLevel+"'" + char(10) 
                Else "" 
        End + 
        "        order by CaseKey, EventDate desc, EventDescription" 

	exec sp_executesql @sSQLString,
				N'@pnUserIdentityId	int,
				  @sLookupCulture	nvarchar(10),
				  @pbCalledFromCentura	bit,
				  @pnCaseKey		int,
				  @sFromDate		nchar(11),
				  @dtToday		datetime',
				  @pnUserIdentityId	= @pnUserIdentityId,
				  @sLookupCulture	= @sLookupCulture,
				  @pbCalledFromCentura	= @pbCalledFromCentura,
				  @pnCaseKey		= @pnCaseKey,
				  @sFromDate       	= @sFromDate,
				  @dtToday		= @dtToday

End

Return @ErrorCode
GO

Grant execute on dbo.csw_ListWhatsNewEvents to public
GO
