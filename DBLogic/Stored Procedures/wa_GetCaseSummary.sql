-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_GetCaseSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_GetCaseSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_GetCaseSummary'
	drop procedure [dbo].[wa_GetCaseSummary]
	print '**** Creating procedure dbo.wa_GetCaseSummary...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF    
go

CREATE PROCEDURE [dbo].[wa_GetCaseSummary]
	@pnCaseId	int
AS

-- PROCEDURE :	wa_GetCaseSummary
-- VERSION :	13
-- DESCRIPTION:	Return details of a specific Case for the CaseId passed as a parameter.
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	AWF			Procedure created	
-- 31/07/2001	MF			Only display details if the user has the correct access rights
-- 03/08/2001	MF			Make the the access rights check a stored procedure
-- 20/08/2001	MF			Return the next due date as well as the Next Renewal Date as 
--					NEXTEVENTDUEDATE, NEXTEVENT, RENEWALDATE, RENEWALEVENT
-- 23/08/2001	MF			Add a new column called LIVEORDEAD to return 'Pending'; 'Registered' or 'Dead'.
--					Return either the INTERNALDESC or EXTERNALDESC depending on the User as CASESTATUS
--					Return the renewal status as RENEWALSTATUS
-- 04/10/2001	MF			Remove the CASEIMAGE table from list of joins and include it as a subselect for the
--					IMAGEDETAIL table. This was causing an E_Fail error for SQLServer 7 which does not
--					occur when you reduce the number of joins.
-- 19/02/2002	MF	7411		An error is occurring when run on SQLServer 2000 because an ANSI Warning is being returned.
--					Suppressing ANSI_Warnings with a SET statement has been avoided as this causes the procedure
--					to be recompiled on each execution.  The code to get the Next Renewal Date was modified.
-- 31/03/2003	JB	6649		Bringing back IMAGEDATA using wa_GetCaseImage now
-- 23/06/2003	MF	8925		Use the new stored procedure to get the current Next Renewal Date.  Also improve
--					the performance of the the SQL in general.
-- 15 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	11	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 05 Jul 2013	vql	R13629	12	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
	-- disable row counts
-- 14 Nov 2018  AV  75198/DR-45358	13   Date conversion errors when creating cases and opening names in Chinese DB

	set nocount on
	
	declare @ErrorCode		int

	declare @dtLastEvent		datetime
	declare @dtNextEvent		datetime
	declare @dtRenewalEvent		datetime
	declare @dtNextRenewalDate	datetime
	declare	@dtCPARenewalDate	datetime
	declare @dtEarliestPriority	datetime

	declare	@sLastEventDesc 	nvarchar(50)
	declare	@sNextEventDesc 	nvarchar(50)
	declare	@sRenewalDesc		nvarchar(50)
	declare	@sPriorityNumber	nvarchar(50)
	declare	@sPriorityCountry	nvarchar(50)

	declare	@bExternalUser		tinyint		-- Set to 1 if the User is external

	-- Check that external users have access to see the details of the case.

	Execute @ErrorCode=wa_CheckSecurityForCase @pnCaseId, @bExternalUser OUTPUT

	If @ErrorCode=0
	Begin
		select	top 1
			@dtLastEvent = CE.EVENTDATE,
			@sLastEventDesc = isnull(EC.EVENTDESCRIPTION,E.EVENTDESCRIPTION)
		FROM 	OPENACTION OA
			join CASEEVENT CE	  	on (CE.CASEID=OA.CASEID
					 		and CE.EVENTNO=OA.LASTEVENT)
			left join EVENTCONTROL EC 	on (EC.CRITERIANO=CE.CREATEDBYCRITERIA
					 		and EC.EVENTNO=CE.EVENTNO)
			left join EVENTS E	  	on (E.EVENTNO=CE.EVENTNO)
		where	OA.CASEID=@pnCaseId
		and	CE.EVENTDATE is not null
		order by CE.EVENTDATE desc

		select @ErrorCode=@@Error
	End

	-- Get the next due date for the events that the user is allowed to see

	If @ErrorCode=0
	Begin
		select	TOP 1 	@dtNextEvent   = CE.EVENTDUEDATE,
				@sNextEventDesc=EC.EVENTDESCRIPTION
		From   (select min(EVENTDUEDATE) as EVENTDUEDATE, CE.CASEID, EC.IMPORTANCELEVEL
			from OPENACTION OA
			join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO)
			join CASEEVENT CE	on (CE.EVENTNO=EC.EVENTNO)
			where OA.POLICEEVENTS=1
			and CE.OCCURREDFLAG=0
			and CE.EVENTDUEDATE>convert(nvarchar,getdate(),112)
			group by CE.CASEID, EC.IMPORTANCELEVEL) DD
		join OPENACTION OA	on (OA.CASEID=DD.CASEID
					and OA.POLICEEVENTS=1)
		join EVENTCONTROL EC 	on (EC.CRITERIANO=OA.CRITERIANO)
		join CASEEVENT CE	on (CE.CASEID=OA.CASEID
					and CE.EVENTNO=EC.EVENTNO
					and CE.OCCURREDFLAG=0
					and CE.EVENTDUEDATE=DD.EVENTDUEDATE)
		left join SITECONTROL S1 on (S1.CONTROLID='Client Importance')
		left join SITECONTROL S2 on (S2.CONTROLID='Events Displayed')
		where	DD.CASEID=@pnCaseId
		and	DD.IMPORTANCELEVEL>= 	CASE WHEN(@bExternalUser=1)
							Then isnull(S1.COLINTEGER,0)
							Else isnull(S2.COLINTEGER,0)
						End
		order by 2

		select @ErrorCode=@@Error
	End

 
	-- Get the Renewal Date and description of the event
 
	If @ErrorCode=0
	Begin
		exec @ErrorCode=dbo.cs_GetNextRenewalDate
					@pnCaseKey=@pnCaseId,
					@pbCallFromCentura=0,
					@pdtNextRenewalDate=@dtNextRenewalDate output,
					@pdtCPARenewalDate =@dtCPARenewalDate  output
 
		If @ErrorCode=0
		Begin
			If @dtCPARenewalDate is not null
			Begin
				Set @dtRenewalEvent=@dtCPARenewalDate
				Set @sRenewalDesc='CPA Renewal Date'
			End
			Else Begin
				Set @dtRenewalEvent=@dtNextRenewalDate
				Set @sRenewalDesc='Next Renewal Date'
			End
		End
	End

	-- Get the priority details.  This is being done outside of the main 
	-- select to give better performance.
 
	If @ErrorCode=0
	Begin
		Select  @dtEarliestPriority=isnull(CE1.EVENTDATE, RC.PRIORITYDATE),
			@sPriorityNumber   =isnull(O.OFFICIALNUMBER, RC.OFFICIALNUMBER),
			@sPriorityCountry  =CO1.COUNTRY
		From SITECONTROL SC
		join RELATEDCASE RC  	on (RC.CASEID=@pnCaseId
					and RC.RELATIONSHIP=SC.COLCHARACTER)
		join CASERELATION CR  	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
		left join CASEEVENT CE1	on (CE1.CASEID=RC.RELATEDCASEID
					and CE1.EVENTNO=isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
					and CE1.CYCLE=1)
		left join CASES C1  	on (C1.CASEID=RC.RELATEDCASEID)
		left join COUNTRY CO1	on (CO1.COUNTRYCODE=isnull(C1.COUNTRYCODE, RC.COUNTRYCODE))
		left join (select max(NUMBERTYPE) NUMBERTYPE, CASEID
			   from OFFICIALNUMBERS
			   where ISCURRENT=1
			   group by CASEID) O1	on (O1.CASEID=RC.RELATEDCASEID)
		left join OFFICIALNUMBERS O 	on (O.CASEID=RC.RELATEDCASEID
						and O.ISCURRENT=1
						and O.NUMBERTYPE=O1.NUMBERTYPE)
		where SC.CONTROLID='Earliest Priority'
 
		Set @ErrorCode=@@Error
 
	End
 
 	If @ErrorCode=0
	Begin
 
		SELECT
		C.CASEID,
		C.IRN,
		C.TITLE,
		CASE WHEN(S.LIVEFLAG=0 or RS.LIVEFLAG=0)Then 'Dead'
		     WHEN(S.REGISTEREDFLAG=1)  Then 'Registered'
		     Else 'Pending'
		END as LIVEORDEAD, 
		CASE WHEN (@bExternalUser=1)THEN  S.EXTERNALDESC ELSE  S.INTERNALDESC END as CASESTATUS,
		CASE WHEN (@bExternalUser=1)THEN RS.EXTERNALDESC ELSE RS.INTERNALDESC END as RENEWALSTATUS,
		CO.COUNTRYADJECTIVE+ ' ' + PT.PROPERTYNAME + ' - ' + CT.CASETYPEDESC as COUNTRYPROPERTY,
		CC.CASECATEGORYDESC,
		V.SUBTYPEDESC,
		VB.BASISDESCRIPTION,
		TM.DESCRIPTION as TYPEOFMARK,
		TF.DESCRIPTION as FILELOCATION,
		C.FAMILY,
		C.INTCLASSES,
		C.LOCALCLASSES,
		C.NOINSERIES,
		C.LOCALCLIENTFLAG,
		@dtLastEvent as LASTEVENTDATE,
		@sLastEventDesc as LASTEVENT,
		@dtNextEvent as NEXTEVENTDUEDATE,
		@sNextEventDesc as NEXTEVENT,
		@dtRenewalEvent as RENEWALDATE,
		@sRenewalDesc  as RENEWALEVENT,
		@dtEarliestPriority as EARLIESTPRIORITY,
		@sPriorityNumber    as PRIORITYNUMBER,
		@sPriorityCountry   as PRIORITYCOUNTRY,
		-- 6649 we need this in XSL file to only call DisplayImage if there is an image:
		case when exists(select * from CASEIMAGE CI where CI.CASEID=C.CASEID) then 1 else null end AS IMAGEEXISTS,
		O2.OFFICIALNUMBER,
		N.DESCRIPTION
		from CASES C 
		left join PROPERTY P   on P.CASEID = C.CASEID
		     join VALIDPROPERTY PT  on (PT.PROPERTYTYPE = C.PROPERTYTYPE
		    			    and PT.COUNTRYCODE = (select min(PT1.COUNTRYCODE)
								  from VALIDPROPERTY PT1
								  where PT1.PROPERTYTYPE=C.PROPERTYTYPE
								  and   PT1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		left join STATUS S	on S.STATUSCODE = C.STATUSCODE
		left join STATUS RS	on RS.STATUSCODE= P.RENEWALSTATUS
		     join COUNTRY CO	on CO.COUNTRYCODE = C.COUNTRYCODE
		     join CASETYPE CT	on CT.CASETYPE = C.CASETYPE
		left join VALIDCATEGORY CC 	on (CC.CASETYPE = C.CASETYPE
						and CC.PROPERTYTYPE = C.PROPERTYTYPE
						and CC.CASECATEGORY = C.CASECATEGORY
						and CC.COUNTRYCODE = (  select min(CC1.COUNTRYCODE)
									from VALIDCATEGORY CC1
									where CC1.CASETYPE     =C.CASETYPE
 									and   CC1.PROPERTYTYPE =C.PROPERTYTYPE
									and   CC1.CASECATEGORY =C.CASECATEGORY
									and   CC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
		left join VALIDSUBTYPE V	on (V.SUBTYPE = C.SUBTYPE
						and V.PROPERTYTYPE = C.PROPERTYTYPE
						and V.COUNTRYCODE = (	select min(COUNTRYCODE)
									from VALIDSUBTYPE V1
									where  V1.SUBTYPE      = C.SUBTYPE
									and  V1.PROPERTYTYPE = C.PROPERTYTYPE
									and  V1.CASETYPE     = C.CASETYPE
									and  V1.CASECATEGORY = C.CASECATEGORY
									and  V1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
						and V.CASETYPE = C.CASETYPE
						and V.CASECATEGORY = C.CASECATEGORY
		left join VALIDBASIS VB  	on (VB.PROPERTYTYPE = C.PROPERTYTYPE
						and VB.COUNTRYCODE = (	select min(COUNTRYCODE)
									from VALIDBASIS V1
									where  V1.PROPERTYTYPE = C.PROPERTYTYPE
									and  V1.BASIS        = P.BASIS
									and  V1.COUNTRYCODE  in (C.COUNTRYCODE, 'ZZZ')))
						and VB.BASIS = P.BASIS
		left join TABLECODES TM	on TM.TABLECODE = C.TYPEOFMARK
		left join TABLECODES TF	on TF.TABLECODE = (	Select CL.FILELOCATION
								FROM CASELOCATION CL
								where CL.CASEID = C.CASEID
								and CL.WHENMOVED = (select max(CL.WHENMOVED)
								FROM CASELOCATION CL
								where CL.CASEID = C.CASEID))
		left join (	select max(NUMBERTYPE) as NUMBERTYPE, CASEID
				from OFFICIALNUMBERS
				where NUMBERTYPE in ('R','P','C','A','0')
					group by CASEID) O3	on (O3.CASEID=C.CASEID)
		left join OFFICIALNUMBERS O2 	on (O2.CASEID=C.CASEID
						and O2.OFFICIALNUMBER=C.CURRENTOFFICIALNO
						and O2.NUMBERTYPE=O3.NUMBERTYPE)
		left join NUMBERTYPES N on N.NUMBERTYPE=O2.NUMBERTYPE
		-- 6649 left join IMAGEDETAIL I  on (I.IMAGEID=( select min(CI.IMAGEID)
		-- 6649      from CASEIMAGE CI
		-- 6649      where CI.CASEID=C.CASEID))
		where C.CASEID = @pnCaseId
 
		Select @ErrorCode=@@Error
	End

	return @ErrorCode
go 

grant execute on [dbo].[wa_GetCaseSummary] to public
go
