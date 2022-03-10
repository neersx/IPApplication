-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCriticalDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ListCriticalDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_ListCriticalDates.'
	Drop procedure [dbo].[cs_ListCriticalDates]
	Print '**** Creating Stored Procedure dbo.cs_ListCriticalDates...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_ListCriticalDates
(
	@pnRowCount		int		= null 	output,
	@pnUserIdentityId	int,			-- Mandatory
	@pbIsExternalUser	bit		= null,	-- external user flag if already known
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,			-- Mandatory
	@pbCalledFromCentura	bit = 0
)
as
-- PROCEDURE:	cs_ListCriticalDates
-- VERSION:	39
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Events the user is allowed to see that are due.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 21 Sep 2003  MF		1	Procedure created
-- 15 Oct 2003	MF	RFC338	2	Return an empty result set if the user does not have access to the Case.
-- 03 Nov 2003	MF	RFC583	3	When Earliest Priority Event was not found then other Critical Events
--					were not being displayed.
-- 05 Nov 2003	MF	RFC338	4	Return the Official Number associated with the Event being returned.
--					Also get the Earliest Priority Date and Number from first principles
--					rather than relying on it to be in the Eventno of the current Case.
-- 18-Feb-2004	TM	RFC976	5	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 01-Feb-2004	TM	RFC1032	6	Pass @pnCaseKey as the @pnCaseKey to the fn_FilterUserCases.
-- 04-Mar-2004	TM	RFC934	7	Remove all use of fn_FilterUserEventControl.  Ensure fn_FilterUserEvents is 
--					implemented for all events returned for external users only.
-- 08-Mar-2004	TM	RFC934	8	Implement fn_FilterUserEvents for external users.
-- 27-Apr-2004	TM	RFC1222	9	Return Expiry Date as ISNULL(CE.EVENTDATE, CE.EVENTDUEDATE) for all events except
--					CPA Renewal Date, Earliest Priority Date, Last Event and Next Due Date Event. 
-- 12-May-2004	TM	RFC1356	10	Return all dates present in EventControl, whether there is data present for
--					this case or not.
-- 03-Sep-2004	TM	RFC1768	11	For external users, set the IsCPARenewalDate to false if the Clients Unaware of 
--					CPA site control is on.
-- 09 Sep 2004	JEK	RFC886	12	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 14 Sep 2004	TM	RFC886	13	Implement translation.
-- 21 Sep 2004	TM	RFC886	14	Correct the assembling of the SQL not to overflow for the external users.
-- 27 Oct 2004	MF	RFC1539	15	Return the "annuity" number of the Case.
-- 28 Jan 2005	MF	RFC2257	16	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 15 May 2005	JEK	RFC2508	17	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jan 2006 	TM	RFC3375	18	Modify the population of the @sEarliestPriorityNumber to use application number 
--					instead of current official number.
-- 10 Jan 2006	TM	RFC3375	19	If Application Number does not exists then use Current Official Number
--					to populate @sEarliestPriorityNumber.
-- 17 Jan 2006	TM	RFC3375 20	For the @sEarliestPriorityNumber, use the following code:
--					coalesce(O.OFFICIALNUMBER, C.CURRENTOFFICIALNO, RC.OFFICIALNUMBER)
-- 24 Mar 2006	SF	RFC3264	21	Add RowKey to result set.
-- 20 Jun 2005	JEK	RFC4009 22	SQL overflows for external users and culture ZH-CHS.
-- 1 Mar 2007	PY	S14425	23	Reserved word [date]
-- 10 Dec 2007	SF	RFC5708 24	Return CountryKey and EventKey, IsPriorityEvent
-- 9 Jan 2008	SF	RFC5708 25	Return OfficialNumberType
-- 11 Dec 2008	MF	17136	26	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	27	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 21 Sep 2009  LP      RFC8047 28      Pass ProfileKey as parameter to fn_GetCriteriaNo
-- 07 Jul 2010	MF	RFC8862	29	If an Event is associated with more than one Official Number then just show the Event details with the
--					first Official Number being displayed.
--					Also the Next Due Date should remove the restriction that the date must be greater than the current date.
--					Suppress the last Event updated if the user is external.
-- 12 Jul 2010	MF	RFC9026	30	Restrict the Next Event and Last Event to only events that have an importance level greater than or equal to
--					the level associated with the user.
-- 10 Sep 2010	MF	RFC9751	31	When determining the details for the Earliest Priority, we need to match on the date held against the Case 
--					that claimed priority and extend the process to consder any relationhip that updates the Earliest Priority 
--					eventno and has EarliestDateFlag set to 1.
-- 07 Jul 2011	DL	R10830	32	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 12 Aug 2011	MF	R11127	33	Critical dates list should consider Controlling Action when returning due dates and also the Next Due Date should
--					exclude Events already reported.
-- 03 Dec 2012	MF	R12997	34	If no Criteria is found for the Critical Dates then an empty result set should be returned.
-- 20 May 2014	KR	R13967	35	Added IsOccured to the select list so we can display event date and due date in separate columns
-- 24 Jul 2015	MF	R50404	36	Events and due dates should not be restricted to cycle 1. The rule should be to take the lowest cycle open due date
--					or in its absense the highest cycle event date.
-- 24 Jul 2017	MF	71997	37	Handle the possibility that more than one Number Type can point to the same EventNo. If this occurs use the NumberType
--					where there is an OfficialNumber and has the lowest DisplayPriority.
-- 07 Sep 2018	AV	74738	38	Set isolation level to read uncommited.
-- 19 May 2020	DL	DR-58943 39	Ability to enter up to 3 characters for Number type code via client server	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Create table #TEMPRESULTS (
		CaseKey			int		NOT NULL,
		EventDescription	nvarchar(100)	collate database_default NULL,
		EventDefinition		nvarchar(254)	collate database_default NULL,	
		DisplayDate		datetime	NULL,
		OfficialNumber		nvarchar(36)	collate database_default NULL,
		CountryCode		nvarchar(60)	collate database_default NULL,
		IsLastEvent		bit		NULL,
		IsNextDueEvent		bit		NULL,
		IsCPARenewalDate	bit		NULL,
		DisplaySequence		smallint	NULL,
		RenewalYear		smallint	NULL,
		RowKey			char(11)	collate database_default NULL,
		EventKey		int		NULL,
		CountryKey		nvarchar(5)	collate database_default NULL,
		IsPriorityEvent		bit		NULL,
		NumberTypeCode		nvarchar(3)	collate database_default NULL,
		Sequence		smallint	identity(1,1),
		IsOccurred		bit		NULL
		)

Declare @ErrorCode 			int

Declare @sSQLString			nvarchar(max)
Declare @sControlId			nvarchar(30)
Declare @sImportanceControlId		nvarchar(30)
Declare @sAction			nvarchar(3)
Declare @sRenewalAction			nvarchar(3)
Declare @nCriteriaNo			int
Declare @nImportanceLevel		int
Declare	@dtNextRenewalDate		datetime
Declare @dtCPARenewalDate		datetime
Declare @dtEarliestPriorityDate		datetime
Declare	@sEarliestPriorityNumber	nvarchar(36)
Declare	@sEarliestPriorityCountry	nvarchar(60)
Declare	@sEarliestPriorityCountryKey	nvarchar(3)
Declare	@nPriorityEventNo		int
Declare @nDefaultPriorityEventNo	int
Declare @nAgeOfCase			smallint
Declare @nProfileKey                    int

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@ErrorCode      = 0
Set 	@pnRowCount	= 0

-- If the IsExternalUser flag has not been passed as a parameter then determine it 
-- by looking up the USERIDENTITY table

If  @pbIsExternalUser is null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser		bit	Output,
				  @pnUserIdentityId		int',
				  @pbIsExternalUser=@pbIsExternalUser	Output,
				  @pnUserIdentityId=@pnUserIdentityId
End

-- Get the Site Control that will provide the Action that will identify the critical Events

If @ErrorCode=0
Begin
	If @pbIsExternalUser=1
	Begin
		Set @sControlId          ='Critical Dates - External'
		Set @sImportanceControlId='Client Importance'
	End
	Else Begin
		Set @sControlId          ='Critical Dates - Internal'
		Set @sImportanceControlId='Events Displayed'
	End

	Set @sSQLString="
	Select @sAction=S1.COLCHARACTER,
	       @sRenewalAction=S2.COLCHARACTER,
	       @nImportanceLevel=S3.COLINTEGER
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='Main Renewal Action')
	left join SITECONTROL S3 on (S3.CONTROLID=@sImportanceControlId)
	where S1.CONTROLID=@sControlId"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sAction		nvarchar(3)	Output,
				  @sRenewalAction	nvarchar(3)	Output,
				  @nImportanceLevel	int		Output,
				  @sControlId		nvarchar(30),
				  @sImportanceControlId	nvarchar(30)',
				  @sAction		=@sAction		Output,
				  @sRenewalAction	=@sRenewalAction	Output,
				  @nImportanceLevel	=@nImportanceLevel	Output,
				  @sControlId		=@sControlId,
				  @sImportanceControlId	=@sImportanceControlId
End

-- Get the ProfileKey for the current user
If @ErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId

        Set @ErrorCode = @@ERROR
End

-- Now get the CriteriaNo for the Action and Case

If  @ErrorCode=0
and @sAction is not null
Begin
	Select @nCriteriaNo=dbo.fn_GetCriteriaNo(@pnCaseKey, 	-- the Case
						'E', 		-- Purpose Code of the criteria
						@sAction, 	-- the Action of the Criteria
						getdate(),	-- Current date required for date of law
						@nProfileKey    -- ProfileKey of the Criteria
						)

-- If the Next Renewal Date is one of the Events that is required as a Critical Event
-- then it will be extracted separately as it has some specific processing to get it.

	If @nCriteriaNo is not null
	and exists(select 1 from EVENTCONTROL where EVENTNO=-11 and CRITERIANO=@nCriteriaNo)
	Begin
		Exec @ErrorCode=dbo.cs_GetNextRenewalDate
						@pnCaseKey=@pnCaseKey,
						@pdtNextRenewalDate=@dtNextRenewalDate 	output,
						@pdtCPARenewalDate=@dtCPARenewalDate	output
	End

-- If one of the Events is the Event used for saving the Earliest Priority then get
-- the Country and Official Number of the earliest priority

	If @ErrorCode=0
	and @nCriteriaNo is not null
	Begin
		-- get Earliest Priority info
		-- We are using the TOP 1 clause because it is theoretically possible to claim
		-- priority from more than one Case
		Set @sSQLString="
		Select  Top 1 
			@dtEarliestPriorityDate   = CE.EVENTDATE, 
			@sEarliestPriorityNumber  = coalesce(O.OFFICIALNUMBER, C.CURRENTOFFICIALNO, RC.OFFICIALNUMBER),
			@sEarliestPriorityCountry = "+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+",
			@sEarliestPriorityCountryKey = CT.COUNTRYCODE,
			@nPriorityEventNo         = EC.EVENTNO
		From SITECONTROL SC
		-- For that relationship we need to determine the EventNo
		-- that will hold the earliest priority date
		Join CASERELATION CR 		on (CR.RELATIONSHIP=SC.COLCHARACTER)
		-- Now find all of the relationships that use the same EventNo
		-- that have the Earliest Date Flag set on.
		Join CASERELATION CR1		on (CR1.EVENTNO=CR.EVENTNO
						and CR1.EARLIESTDATEFLAG=1)
		Join RELATEDCASE RC		on (RC.CASEID=@pnCaseKey
						and RC.RELATIONSHIP=CR1.RELATIONSHIP)"+	
		-- If the user is an External User then require an additional join to the Filtered Events to
		-- ensure the user has access
		CASE WHEN @pbIsExternalUser = 1 
		     THEN CHAR(10)+"	join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture,1,@pbCalledFromCentura) FE"+CHAR(10)+
				   "				on (FE.EVENTNO = CR.EVENTNO)"+CHAR(10)			   
		END+		
		-- Now ensure that the earliest priority date is one of the events
		-- included in the Critical Events criteria
		"Join EVENTCONTROL EC		on (EC.CRITERIANO=@nCriteriaNo
						and EC.EVENTNO=CR.EVENTNO)
		Join CASEEVENT CE		on (CE.CASEID=RC.CASEID
						and CE.EVENTNO=CR.EVENTNO
						and CE.CYCLE=1
						and CE.EVENTDATE is not null)
		-- Now get the date from the related Case so that we 
		-- can match against the Earliest Priority Date held in this case.
		left Join CASEEVENT CE1		on (CE1.CASEID=RC.RELATEDCASEID
						and CE1.EVENTNO=CR.FROMEVENTNO
						and CE1.CYCLE=1)
		-- If the case that priority is being claimed from is in the database then
		-- get the Official Number and Country from it.
		Left Join CASES C 		on (C.CASEID  =RC.RELATEDCASEID)
		Left Join COUNTRY CT		on (CT.COUNTRYCODE=isnull(C.COUNTRYCODE, RC.COUNTRYCODE))
		Left Join OFFICIALNUMBERS O	on (O.CASEID = RC.RELATEDCASEID
						and O.NUMBERTYPE = N'A' 
						and O.ISCURRENT = 1)
		Where SC.CONTROLID = 'Earliest Priority'
		and (CE1.EVENTDATE=CE.EVENTDATE or (CE1.EVENTDATE is null and RC.PRIORITYDATE=CE.EVENTDATE))
		order by 1,2"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtEarliestPriorityDate	datetime	Output,
					  @sEarliestPriorityNumber	nvarchar(36)	Output,
					  @sEarliestPriorityCountry	nvarchar(60)	Output,
					  @sEarliestPriorityCountryKey nvarchar(5)	Output,
					  @nPriorityEventNo		int		Output,
					  @pnUserIdentityId		int,
					  @sLookupCulture		nvarchar(10),
					  @pbCalledFromCentura		bit,				  
					  @nCriteriaNo			int,
					  @pnCaseKey			int',
					  @dtEarliestPriorityDate  =@dtEarliestPriorityDate	Output,
					  @sEarliestPriorityNumber =@sEarliestPriorityNumber	Output,
					  @sEarliestPriorityCountry=@sEarliestPriorityCountry	Output,
					  @sEarliestPriorityCountryKey = @sEarliestPriorityCountryKey Output,
					  @nPriorityEventNo        =@nPriorityEventNo		Output,
					  @pnUserIdentityId	   =@pnUserIdentityId,
					  @sLookupCulture		   =@sLookupCulture,
					  @pbCalledFromCentura	   =@pbCalledFromCentura,		  
					  @nCriteriaNo		   =@nCriteriaNo,
					  @pnCaseKey		   =@pnCaseKey
	End
	
	If @ErrorCode=0
	and @pbIsExternalUser = 0 
	Begin
		-- get default priority event no
		-- similar to the above, but to get the specific priority eventno
		-- this logic only required for internal user for maintenance purpose (see IsPriorityEvent)
		Set @sSQLString="
		Select  @nDefaultPriorityEventNo         = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
		FROM 	SITECONTROL SC 		
		Join 	CASERELATION CR on (CR.RELATIONSHIP=SC.COLCHARACTER)
		Where SC.CONTROLID = 'Earliest Priority'"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDefaultPriorityEventNo	int		Output',
					  @nDefaultPriorityEventNo =@nDefaultPriorityEventNo	Output

	End
	-- Get the age of the case (annuity) to be returned.

	If @ErrorCode=0
	Begin
		exec @ErrorCode=dbo.pt_GetAgeOfCase 
					@pnCaseId 		=@pnCaseKey, 
					@pbCalledFromCentura	=0,
					@pnAgeOfCase 		=@nAgeOfCase 	output,
					@pdtNextRenewalDate	=@dtNextRenewalDate,
					@pdtCPARenewalDate	=@dtCPARenewalDate
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		with CTE_OfficialNumberForEvent(EVENTNO, NUMBERTYPE, OFFICIALNUMBER)
		as (	select NT.RELATEDEVENTNO, NT.NUMBERTYPE, O.OFFICIALNUMBER
			from OFFICIALNUMBERS O
			join NUMBERTYPES NT on (NT.NUMBERTYPE=O.NUMBERTYPE)
			where O.ISCURRENT=1
			and O.CASEID=@pnCaseKey
			and NT.ISSUEDBYIPOFFICE=1
			and NT.RELATEDEVENTNO is not null
			and NT.DISPLAYPRIORITY=(select min(NT1.DISPLAYPRIORITY)
						from NUMBERTYPES NT1
						join OFFICIALNUMBERS O1 on (O1.NUMBERTYPE=NT1.NUMBERTYPE
									and O1.CASEID=O.CASEID
									and O1.ISCURRENT=1)
						where NT1.RELATEDEVENTNO=NT.RELATEDEVENTNO)
			)"+char(10)

		If @pbIsExternalUser=1
			Set @sSQLString=@sSQLString+"insert into #TEMPRESULTS (CaseKey,EventDescription,EventDefinition,DisplayDate,OfficialNumber,CountryCode,IsLastEvent,IsNextDueEvent,IsCPARenewalDate,DisplaySequence,RenewalYear,RowKey, IsOccurred)"
		Else
			Set @sSQLString=@sSQLString+"insert into #TEMPRESULTS (CaseKey,EventDescription,EventDefinition,DisplayDate,OfficialNumber,CountryCode,IsLastEvent,IsNextDueEvent,IsCPARenewalDate,DisplaySequence,RenewalYear,RowKey,EventKey,CountryKey,IsPriorityEvent,NumberTypeCode, IsOccurred)"

		Set @sSQLString=@sSQLString+char(10)+
		"Select
		 @pnCaseKey 	as CaseKey,"+char(10)+CHAR(9)+CHAR(9)+
		dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+" as EventDescription,"+char(10)+CHAR(9)+CHAR(9)+
		dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as EventDefinition,
		CASE When(EC.EVENTNO=-11)
			Then isnull(@dtCPARenewalDate,@dtNextRenewalDate)
		     When(EC.EVENTNO=@nPriorityEventNo)
			Then @dtEarliestPriorityDate
			Else ISNULL(CE.EVENTDATE, CE.EVENTDUEDATE)
		END		as [Date],
		CASE When(CE.EVENTNO=@nPriorityEventNo)
			Then @sEarliestPriorityNumber
			Else O.OFFICIALNUMBER
		END		as OfficialNumber,
		CASE When(CE.EVENTNO=@nPriorityEventNo)
			Then @sEarliestPriorityCountry
		END		as CountryCode,
		0		as IsLastEvent,
		0		as IsNextDueEvent,
			-- For external users, set the IsCPARenewalDate to false if  
			-- the Clients Unaware of CPA site control is on:
		CASE When(SC.COLBOOLEAN = 1 and @pbIsExternalUser = 1)
			Then 0
		     When(EC.EVENTNO=-11 and @dtCPARenewalDate is not null)
			Then 1
		     Else 0
		END		as IsCPARenewalDate,
		EC.DISPLAYSEQUENCE as DisplaySequence,
		CASE When(EC.EVENTNO=-11) THEN @nAgeOfCase END as RenewalYear,
		convert(char(11),EC.EVENTNO) as RowKey"+char(10)+
		
		case when @pbIsExternalUser = 0 then "
			,EC.EVENTNO 	as EventKey,
			CASE When(CE.EVENTNO=@nPriorityEventNo)
				Then @sEarliestPriorityCountryKey
			END		as CountryKey,
			CASE When(EC.EVENTNO=@nDefaultPriorityEventNo) Then 1 Else 0
			END		as IsPriorityEvent,
			CASE When(EC.EVENTNO=@nDefaultPriorityEventNo) Then 'A' Else O.NUMBERTYPE
			END		as NumberTypeCode"
		end +char(10)+",
		CASE When(EC.EVENTNO=-11) Then 0
		     When(EC.EVENTNO=@nPriorityEventNo) Then 1
		     Else CE.OCCURREDFLAG
		END		as [IsOccurred]
		
		from EVENTCONTROL EC"+
		
		-- If the user is an External User then require an additional join to the Filtered Events to
		-- ensure the user has access
		CASE WHEN @pbIsExternalUser = 1 
		     THEN CHAR(10)+"	join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture,1,@pbCalledFromCentura) FE"+CHAR(10)+
				   "			on (FE.EVENTNO = EC.EVENTNO)"+CHAR(10)			   
		END+"
		
		     join EVENTS E	on (E.EVENTNO=EC.EVENTNO)
		----------------------------------------------
		-- RFC50404
		-- Use lowest Due Date Cycle or if no due date 
		-- then use the highest occurred cycle
		----------------------------------------------
		left join (select CASEID, EVENTNO, min(CYCLE) as CYCLE
			   from dbo.fn_GetCaseDueDates()
			   group by CASEID, EVENTNO) DD
					on (DD.CASEID=@pnCaseKey
					and DD.EVENTNO=EC.EVENTNO)
		left join CASEEVENT CE	on (CE.CASEID=@pnCaseKey
					and CE.EVENTNO=EC.EVENTNO
					and CE.CYCLE=isnull(DD.CYCLE,(select max(CYCLE)
								      from CASEEVENT CE1
								      where CE1.CASEID =CE.CASEID
								      and   CE1.EVENTNO=CE.EVENTNO
								      and   CE1.EVENTDATE is not null) ))
		left join CTE_OfficialNumberForEvent O on (O.EVENTNO=EC.EVENTNO)
		left join SITECONTROL SC on (SC.CONTROLID='Clients Unaware of CPA')
		where EC.CRITERIANO=@nCriteriaNo"

		--------------------------------------------------------
		-- Only display the Last Event update if the user is not
		-- an external user.
		--------------------------------------------------------
		If @pbIsExternalUser=0
		Begin
			Set @sSQLString=@sSQLString+char(10)+
			"UNION ALL
			-- Last Event
			Select	LE.CASEID,"+char(10)+CHAR(9)+CHAR(9)+CHAR(9)+
				dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+CHAR(9)+CHAR(9)+CHAR(9)+
				dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+"
			convert(datetime,substring(LE.LASTEVENTDATE,24,8)),
			NULL,
			NULL,
			1,
			0,
			0,
			E.DISPLAYSEQUENCE,
			NULL,
			'L',
			E.EVENTNO,
			NULL,
			0,
			NULL,
			1
			From  (select 	CE.CASEID,
				max(convert(char(23),CE.LOGDATETIMESTAMP,121)+convert(char(8),CE.EVENTDATE,112)+convert(char(2),isnull(EC.IMPORTANCELEVEL,'0'))+convert(char(11),EC.DISPLAYSEQUENCE)+convert(char(11),EC.EVENTNO)+convert(char(11),EC.CRITERIANO))as LASTEVENTDATE
				from CASEEVENT CE
				join EVENTCONTROL EC	on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
							and EC.EVENTNO   =CE.EVENTNO)
				where CE.EVENTDATE is not null
				and   CE.EVENTNO not in (-13,-14,-16)
				and   EC.IMPORTANCELEVEL>=isnull(@nImportanceLevel,0)
				group by CE.CASEID ) LE
			Join	EVENTCONTROL E	on (E.CRITERIANO=convert(int,substring(LE.LASTEVENTDATE,56,11))
						and E.EVENTNO   =convert(int,substring(LE.LASTEVENTDATE,45,11)))
			Join	EVENTS EV	on (EV.EVENTNO  = E.EVENTNO)
			left join EVENTCONTROL EC	on (EC.CRITERIANO=@nCriteriaNo
							and EC.EVENTNO=E.EVENTNO)
			Where LE.CASEID = @pnCaseKey
			and EC.EVENTNO is null"		-- suppress this row if part of the first SELECT in the UNION
		End

		Set @sSQLString=@sSQLString+char(10)+
		"UNION ALL
		-- Next Due Date Event
		Select	DD.CASEID,"+char(10)+CHAR(9)+CHAR(9)+
			dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+CHAR(9)+CHAR(9)+
			dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'EV',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+"
		convert(datetime,substring(DD.NEXTEVENTDUEDATE,1,8)),
		NULL,
		NULL,
		0,
		1,
		0,
		E.DISPLAYSEQUENCE,
		NULL,
		'N'"+char(10)+
		
		case when @pbIsExternalUser = 0 then "
		,E.EVENTNO,
		NULL,
		0,
		NULL"
		end +char(10)+",
		0
		
		From  (select 	OA.CASEID, 
			min(convert(char(8),CE.EVENTDUEDATE,112)+convert(char(2),99-convert(int,isnull(EC.IMPORTANCELEVEL,0)))+convert(char(11),EC.DISPLAYSEQUENCE)+convert(char(11),EC.EVENTNO)+convert(char(11),EC.CRITERIANO))as NEXTEVENTDUEDATE
			from OPENACTION OA
			join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO)
			left join EVENTCONTROL EC1 on (EC1.CRITERIANO=@nCriteriaNo and EC1.EVENTNO=-11)
			join EVENTS E		on (E.EVENTNO=EC.EVENTNO)"+
			
			-- If the user is an External User then require an additional join to the Filtered Events to
			-- ensure the user has access
			CASE WHEN @pbIsExternalUser = 1 
			     THEN CHAR(10)+"	join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture,1,@pbCalledFromCentura) FE"+CHAR(10)+
					   "				on (FE.EVENTNO = EC.EVENTNO)"+CHAR(10)			   
			END+"
			
			join ACTIONS A		on (A.ACTION=OA.ACTION)
			join CASEEVENT CE	on (CE.CASEID=OA.CASEID
						and CE.EVENTNO=EC.EVENTNO
						and(A.NUMCYCLESALLOWED=1
						 or(CE.CYCLE=OA.CYCLE AND A.NUMCYCLESALLOWED>1)))
			where OA.POLICEEVENTS=1
			and OA.ACTION=isnull(E.CONTROLLINGACTION,OA.ACTION)
			-- RFC2257 Only consider the Next Renewal Date (-11) if it is attached to the
			-- specific Renewal Action defined at this site.
			and ((OA.ACTION=@sRenewalAction and CE.EVENTNO=-11 and EC1.EVENTNO is null) OR CE.EVENTNO<>-11)
			and EC.IMPORTANCELEVEL>=isnull(@nImportanceLevel,0)
			and CE.OCCURREDFLAG=0
			group by OA.CASEID ) DD
		Join	EVENTCONTROL E		on (E.CRITERIANO=convert(int,substring(DD.NEXTEVENTDUEDATE,33,11))
						and E.EVENTNO   =convert(int,substring(DD.NEXTEVENTDUEDATE,22,11)))
		Join	EVENTS EV		on (EV.EVENTNO  = E.EVENTNO)
		Where DD.CASEID = @pnCaseKey
		Order by 7,8,10"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtCPARenewalDate		datetime,
					  @dtNextRenewalDate		datetime,
					  @dtEarliestPriorityDate	datetime,
					  @nPriorityEventNo		int,
					  @sEarliestPriorityNumber	nvarchar(36),
					  @sEarliestPriorityCountry	nvarchar(60),
					  @sEarliestPriorityCountryKey nvarchar(5),
					  @nDefaultPriorityEventNo	int,
					  @pnUserIdentityId		int,				 
					  @sLookupCulture		nvarchar(10),
					  @pbCalledFromCentura		bit,				  
					  @nCriteriaNo			int,
					  @pnCaseKey			int,
					  @pbIsExternalUser		bit,
					  @nAgeOfCase			smallint,
					  @sRenewalAction		nvarchar(3),
					  @nImportanceLevel		int',
					  @dtCPARenewalDate		=@dtCPARenewalDate,
					  @dtNextRenewalDate		=@dtNextRenewalDate,
					  @dtEarliestPriorityDate	=@dtEarliestPriorityDate,
					  @nPriorityEventNo		=@nPriorityEventNo,
					  @sEarliestPriorityNumber	=@sEarliestPriorityNumber,
					  @sEarliestPriorityCountry	=@sEarliestPriorityCountry,
					  @sEarliestPriorityCountryKey = @sEarliestPriorityCountryKey,
					  @nDefaultPriorityEventNo	=@nDefaultPriorityEventNo,
					  @pnUserIdentityId		=@pnUserIdentityId,				
					  @sLookupCulture		=@sLookupCulture,
					  @pbCalledFromCentura	   	=@pbCalledFromCentura,		  
					  @nCriteriaNo			=@nCriteriaNo,
					  @pnCaseKey			=@pnCaseKey,
					  @pbIsExternalUser		=@pbIsExternalUser,
					  @nAgeOfCase			=@nAgeOfCase,
					  @sRenewalAction		=@sRenewalAction,
					  @nImportanceLevel		=@nImportanceLevel

	End
End

-----------------------------------------------------------------
-- RFC8862
-- Result set loaded into #TEMPRESULTS so that Event details
-- that have already appeared on an earlier row can be suppressed
-- from the final returned result.
-----------------------------------------------------------------
If @ErrorCode=0
Begin
	If @pbIsExternalUser=1
		Set @sSQLString="
		select	T1.CaseKey		as CaseKey,
			T1.EventDescription 	as EventDescription,
			T1.EventDefinition  	as EventDefinition,
			T1.DisplayDate      	as [Date],
			T1.OfficialNumber	as OfficialNumber,
			T1.CountryCode		as CountryCode,
			T1.IsLastEvent      	as IsLastEvent,
			T1.IsNextDueEvent   	as IsNextDueEvent,
			T1.IsCPARenewalDate 	as IsCPARenewalDate,
			T1.DisplaySequence  	as DisplaySequence,
			T1.RenewalYear      	as RenewalYear,
			T1.RowKey           	as RowKey,
			T1.IsOccurred		as IsOccurred
		from #TEMPRESULTS T1
		left join #TEMPRESULTS T2 on (T2.CaseKey =T1.CaseKey
					  and T2.EventKey=T1.EventKey
					  and T2.Sequence<T1.Sequence)
		where T2.CaseKey is null
		order by T1.Sequence"
	Else
		Set @sSQLString="
		select	T1.CaseKey		as CaseKey,
			T1.EventDescription 	as EventDescription,
			T1.EventDefinition  	as EventDefinition,
			T1.DisplayDate      	as [Date],
			T1.OfficialNumber	as OfficialNumber,
			T1.CountryCode		as CountryCode,
			T1.IsLastEvent      	as IsLastEvent,
			T1.IsNextDueEvent   	as IsNextDueEvent,
			T1.IsCPARenewalDate 	as IsCPARenewalDate,
			T1.DisplaySequence  	as DisplaySequence,
			T1.RenewalYear      	as RenewalYear,
			T1.RowKey           	as RowKey,
			T1.EventKey         	as EventKey,
			T1.CountryKey       	as CountryKey,
			T1.IsPriorityEvent  	as IsPriorityEvent,
			T1.NumberTypeCode	as NumberTypeCode,
			T1.IsOccurred		as IsOccurred
		from #TEMPRESULTS T1
		left join #TEMPRESULTS T2 on (T2.CaseKey =T1.CaseKey
					  and T2.EventKey=T1.EventKey
					  and T2.Sequence<T1.Sequence)
		where T2.CaseKey is null
		order by T1.Sequence"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@@Rowcount
End

Return @ErrorCode
GO

Grant execute on dbo.cs_ListCriticalDates to public
GO
