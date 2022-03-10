-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetCompareEventDates
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetCompareEventDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetCompareEventDates.'
	drop procedure dbo.cs_GetCompareEventDates
end
print '**** Creating procedure dbo.cs_GetCompareEventDates...'
print ''
go

set QUOTED_IDENTIFIER off
go

create procedure dbo.cs_GetCompareEventDates
	@pnRowCount			int		= null	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	-- Filter Parameters
	@psGlobalTempTable		nvarchar(32)	= null,	-- name of temporary table of CASEIDs to be reported on.
	@pnCaseId			int		= null,	-- the CaseId if only 1 Case to be validated
	@pnEventNo			int		= null,	-- Eventno if only 1 EventNo is to be validated
	@pnCycle			smallint	= null, -- Cycle of the Event being validated
	@pnCriteriaNo			int		= null,	-- the specific rule to be validated
	-- The date to be validated
	@pnEventType			tinyint		= null,	-- 1=Event Date and 2=Due Date
	@pdEnteredDate			datetime	= null,  -- a specific date entered that will be validated
	@pbCalledFromCentura		bit		= 1
	
as
-- PROCEDURE :	cs_GetCompareEventDates
-- VERSION :	5
-- DESCRIPTION:	Determines the validity of a date associated with an Event against a predefined set of rules by 
--		comparing the date against other dates held in the database.
--		The procedure is to handle the validation of a single CaseEvent prior to it being inserted as well
--		as being able to validate a set of existing CaseEvent rows for the purpose of reporting on 
--		pre-existing problems.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- USED BY : Centura and WorkBenches modules.
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Jul 2003	MF						Procedure created 
-- 20 Feb 2004	MF		9737	2		If no cycle is passed for an Event then default it to Cycle 1
-- 05 Aug 2004	AB		8035	3		Add collate database_default to temp table definitions		
-- 04 Nov 2008	SF		RFC3392	4		Return result set suitable for Clerical WorkBench
-- 4 Dec 2008	SF		RFC3392	5	Fix incorrect RFC number

set nocount on

-- Create a temporary table to hold the CaseEvent details to be validated
-- Can't use a table variable because dynamic SQL is required to load it.

create TABLE #TEMPDATESTOCHECK (
		ID			int identity (1,1) NOT NULL,
		CASEID		int		NOT NULL,
		EVENTNO		int		NOT NULL,
		CYCLE		smallint	NULL,
		DATETOCOMPARE	datetime	NULL,
		CRITERIANO	int		NOT NULL,
		DATETYPE	tinyint		NOT NULL
		)	


declare @sSQLString			nvarchar(4000)
declare @sLookupCulture	nvarchar(10)
declare @nErrorCode			int

-- Initialise the errorcode and then set it after each SQL Statement

Set @nErrorCode = 0
Set @pnRowCount = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Load the temporary table with the rows to be validated.

If  @pnCaseId      is not null
and @pnEventNo     is not null
and @pnCriteriaNo  is not null
and @pdEnteredDate is not null
and @pnEventType in (1,2)
Begin
	-- When a single Case Event is being validated then all of the details will 
	-- be provided as parameters.  This because the CASEEVENT row will not be inserted
	-- or updated until the date has been found to be valid.

	Set @sSQLString="
	insert into #TEMPDATESTOCHECK(CASEID, EVENTNO, CYCLE, CRITERIANO, DATETYPE, DATETOCOMPARE)
	select distinct @pnCaseId, @pnEventNo, isnull(@pnCycle,1), @pnCriteriaNo, @pnEventType, @pdEnteredDate
	from DATESLOGIC
	where CRITERIANO=@pnCriteriaNo
	and EVENTNO=@pnEventNo
	and DATETYPE=@pnEventType"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnEventNo		int,
				  @pnCycle		smallint,
				  @pnCriteriaNo		int,
				  @pnEventType		tinyint,
				  @pdEnteredDate	datetime',
				  @pnCaseId,
				  @pnEventNo,
				  @pnCycle,
				  @pnCriteriaNo,
				  @pnEventType,
				  @pdEnteredDate

	Set @pnRowCount=@@rowcount
End
Else If @psGlobalTempTable is not null
Begin
	-- All of the Cases in a set can be validated either for a specific EventNo or all
	-- EventNos.  The list of CaseIds are provided in a global temporary table.
	Set @sSQLString="
	insert into #TEMPDATESTOCHECK(CASEID, EVENTNO, CYCLE, CRITERIANO, DATETYPE, DATETOCOMPARE)
	select distinct CE.CASEID, CE.EVENTNO, CE.CYCLE, EC.CRITERIANO, 
		CASE WHEN CE.OCCURREDFLAG>0 THEN 1 ELSE 2 END,
		CASE WHEN CE.OCCURREDFLAG>0 THEN CE.EVENTDATE ELSE CE.EVENTDUEDATE END
	from "+@psGlobalTempTable+" T
	join OPENACTION OA	on (OA.CASEID    =T.CASEID)
	join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO)
	join CASEEVENT CE	on (CE.CASEID    =OA.CASEID
				and CE.EVENTNO   =EC.EVENTNO)
	join DATESLOGIC DL	on (DL.CRITERIANO=EC.CRITERIANO
				and DL.EVENTNO   =EC.EVENTNO
				and DL.DATETYPE  =CASE WHEN CE.OCCURREDFLAG>0 THEN 1 ELSE 2 END)
	where CE.OCCURREDFLAG<9
	and isnull(@pnEventNo, EC.EVENTNO)=EC.EVENTNO"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnEventNo		int',
				  @pnEventNo

	Set @pnRowCount=@@rowcount
End

-- Load a temporary table with the number of valid comparisons achieved
-- for each CASEID, EVENTNO and CYCLE combination.

If  @nErrorCode=0
and @pbCalledFromCentura=1
and @pnRowCount>0
Begin
	set @sSQLString=
	"select C.PROPERTYTYPE, C.COUNTRYCODE, C.IRN, EC.EVENTNO, T.CYCLE, EC.EVENTDESCRIPTION, T.DATETOCOMPARE,"+char(10)+
	"	E.EVENTDESCRIPTION as 'Comparison Event',"+char(10)+
	"	CASE DL.COMPAREDATETYPE	WHEN(1) THEN CE.EVENTDATE"+char(10)+
	"				WHEN(2) THEN CE.EVENTDUEDATE"+char(10)+
	"				WHEN(3) THEN isnull(CE.EVENTDATE,CE.EVENTDUEDATE)"+char(10)+
	"	END as 'Comparison Date',"+char(10)+
	"	DL.DISPLAYERRORFLAG, DL.ERRORMESSAGE"+char(10)+
	"from #TEMPDATESTOCHECK T"+char(10)+
	"join CASES C			on (C.CASEID=T.CASEID)"+char(10)+
	"join DATESLOGIC DL		on (DL.CRITERIANO=T.CRITERIANO"+char(10)+
	"				and DL.EVENTNO   =T.EVENTNO"+char(10)+
	"				and DL.DATETYPE  =T.DATETYPE)"+char(10)+
	"join EVENTCONTROL EC		on (EC.CRITERIANO=T.CRITERIANO"+char(10)+
	"				and EC.EVENTNO   =T.EVENTNO)"+char(10)+
	"join EVENTS E			on (E.EVENTNO=DL.COMPAREEVENT)"+char(10)+
	"left join RELATEDCASE RC	on (RC.CASEID=T.CASEID"+char(10)+
	"				and RC.RELATIONSHIP=DL.CASERELATIONSHIP)"+char(10)+
	"left join CASEEVENT CE 		on (CE.CASEID  =CASE WHEN(DL.CASERELATIONSHIP is not null) THEN RC.RELATEDCASEID ELSE T.CASEID END"+char(10)+
	"				and CE.EVENTNO =DL.COMPAREEVENT"+char(10)+
	"				and CE.CYCLE   =CASE DL.RELATIVECYCLE	WHEN(0) THEN T.CYCLE"+char(10)+
	"									WHEN(1) THEN T.CYCLE-1"+char(10)+
	"									WHEN(2) THEN T.CYCLE+1"+char(10)+
	"									WHEN(3) THEN 1"+char(10)+
	"										ELSE (select max(CYCLE)"+char(10)+
	"										      from CASEEVENT CE3"+char(10)+
	"										      where CE3.CASEID =CE.CASEID"+char(10)+
	"										      and   CE3.EVENTNO=CE.EVENTNO"+char(10)+
	"										      and ((DL.COMPAREDATETYPE=1 and  CE3.EVENTDATE is not null)"+char(10)+
	"										       or  (DL.COMPAREDATETYPE=2 and  CE3.EVENTDUEDATE is not null)"+char(10)+
	"										       or  (DL.COMPAREDATETYPE=3 and  isnull(CE3.EVENTDATE, CE3.EVENTDUEDATE) is not null)))"+char(10)+
	"					         END)"+char(10)+
		-- The WHERE clause is written as if we are looking for valid comparisons but then
		-- use the NOT to reverse the result so that we get those comparisons that fail
	"WHERE	NOT ("+char(10)+

		-- The CASEEVENT row exists unless MUSTEXIST flag is OFF 
		-- The CASEEVENT row does not have to exist if the Relative Cycle is "Previous" and
		-- the cycle of the Event being validated is 1.  This is because the Previous cycle of 
		-- cycle 1 would be 0 which is not allowed.
	"    (CE.CASEID is not null OR isnull(DL.MUSTEXIST,0)=0 OR (DL.RELATIVECYCLE=1 and T.CYCLE=1))"+char(10)+
		-- If the date that is being compared against is supposed to be a Due Date then check 
		-- that it has not Occurred
	"and (DL.COMPAREDATETYPE<>2 OR CE.OCCURREDFLAG=0)"+char(10)+
	"and ("+char(10)+
		-- The following complex WHERE clause is required to combine all of the different	
		-- combinations of COMPAREDATETYPE and OPERATOR in order to test the	
		-- correct column comparison.
	"	   (DL.COMPAREDATETYPE=1 and DL.OPERATOR='='  and T.DATETOCOMPARE =  CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='>'  and T.DATETOCOMPARE >  CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='<'  and T.DATETOCOMPARE <  CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='<=' and T.DATETOCOMPARE <= CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='>=' and T.DATETOCOMPARE >= CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='<>' and T.DATETOCOMPARE <> CE.EVENTDATE)"+char(10)+char(10)+

	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='='  and T.DATETOCOMPARE =  CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='>'  and T.DATETOCOMPARE >  CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='<'  and T.DATETOCOMPARE <  CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='<=' and T.DATETOCOMPARE <= CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='>=' and T.DATETOCOMPARE >= CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='<>' and T.DATETOCOMPARE <> CE.EVENTDUEDATE)"+char(10)++char(10)+

	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='='  and T.DATETOCOMPARE =  isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='>'  and T.DATETOCOMPARE >  isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='<'  and T.DATETOCOMPARE <  isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='<=' and T.DATETOCOMPARE <= isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='>=' and T.DATETOCOMPARE >= isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='<>' and T.DATETOCOMPARE <> isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	")) order by C.PROPERTYTYPE, C.COUNTRYCODE, C.IRN, EC.EVENTNO"

	exec @nErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@@rowcount
End

-- In centura the result is returned only when @pnRowCount > 0
-- In .Net the result is returned regardless.

If  @nErrorCode=0
and @pbCalledFromCentura=0
Begin
	-- return summary
	Set @sSQLString="
	select	1				as RowKey,
			@pnEventNo		as EventKey,
			ISNULL(
				"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)			
								+",
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
								+")						as EventDescription,    			
			@pdEnteredDate	as DateEntered,
			@pnEventType	as TypeOfDate			
	from	EVENTS E
	left join	EVENTCONTROL EC on (E.EVENTNO = EC.EVENTNO and EC.CRITERIANO = @pnCriteriaNo)
	where E.EVENTNO = @pnEventNo
	"
print @sSQLString
	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnEventNo			int,
				@pdEnteredDate		dateTime,
				@pnEventType		int,
				@pnCriteriaNo		int',
				@pnEventNo			= @pnEventNo,
				@pdEnteredDate		= @pdEnteredDate,
				@pnEventType		= @pnEventType,
				@pnCriteriaNo		= @pnCriteriaNo
			
End

If  @nErrorCode=0
and @pbCalledFromCentura=0
Begin
	set @sSQLString=
	"select cast(T.ID as nvarchar(15))	as RowKey,"+char(10)+
	"	C.PROPERTYTYPE	as PropertyTypeKey, "+char(10)+
	"	C.COUNTRYCODE		as CountryCode, "+char(10)+
	"	C.IRN				as CaseReference, "+char(10)+
	"	EC.EVENTNO			as EventKey, "+char(10)+
	"	T.CYCLE				as EventCycle, "+char(10)+
		dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura) + 
	"	as EventDescription, "+char(10)+
	"	T.DATETOCOMPARE		as DateToCompare,"+char(10)+
		dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) + 
	"	as ComparisonEvent,"+char(10)+		
	"	CASE DL.COMPAREDATETYPE	WHEN(1) THEN CE.EVENTDATE"+char(10)+
	"				WHEN(2) THEN CE.EVENTDUEDATE"+char(10)+
	"				WHEN(3) THEN isnull(CE.EVENTDATE,CE.EVENTDUEDATE)"+char(10)+
	"	END					as ComparisonDate,"+char(10)+
	"	DL.DISPLAYERRORFLAG	as DisplayErrorFlag,"+char(10)+
		dbo.fn_SqlTranslatedColumn('DATESLOGIC','ERRORMESSAGE',null,'DL',@sLookupCulture,@pbCalledFromCentura) + 
	"	as ErrorMessage"+char(10)+
	"from #TEMPDATESTOCHECK T"+char(10)+
	"join CASES C			on (C.CASEID=T.CASEID)"+char(10)+
	"join DATESLOGIC DL		on (DL.CRITERIANO=T.CRITERIANO"+char(10)+
	"				and DL.EVENTNO   =T.EVENTNO"+char(10)+
	"				and DL.DATETYPE  =T.DATETYPE)"+char(10)+
	"join EVENTCONTROL EC		on (EC.CRITERIANO=T.CRITERIANO"+char(10)+
	"				and EC.EVENTNO   =T.EVENTNO)"+char(10)+
	"join EVENTS E			on (E.EVENTNO=DL.COMPAREEVENT)"+char(10)+
	"left join RELATEDCASE RC	on (RC.CASEID=T.CASEID"+char(10)+
	"				and RC.RELATIONSHIP=DL.CASERELATIONSHIP)"+char(10)+
	"left join CASEEVENT CE 		on (CE.CASEID  =CASE WHEN(DL.CASERELATIONSHIP is not null) THEN RC.RELATEDCASEID ELSE T.CASEID END"+char(10)+
	"				and CE.EVENTNO =DL.COMPAREEVENT"+char(10)+
	"				and CE.CYCLE   =CASE DL.RELATIVECYCLE	WHEN(0) THEN T.CYCLE"+char(10)+
	"									WHEN(1) THEN T.CYCLE-1"+char(10)+
	"									WHEN(2) THEN T.CYCLE+1"+char(10)+
	"									WHEN(3) THEN 1"+char(10)+
	"										ELSE (select max(CYCLE)"+char(10)+
	"										      from CASEEVENT CE3"+char(10)+
	"										      where CE3.CASEID =CE.CASEID"+char(10)+
	"										      and   CE3.EVENTNO=CE.EVENTNO"+char(10)+
	"										      and ((DL.COMPAREDATETYPE=1 and  CE3.EVENTDATE is not null)"+char(10)+
	"										       or  (DL.COMPAREDATETYPE=2 and  CE3.EVENTDUEDATE is not null)"+char(10)+
	"										       or  (DL.COMPAREDATETYPE=3 and  isnull(CE3.EVENTDATE, CE3.EVENTDUEDATE) is not null)))"+char(10)+
	"					         END)"+char(10)+
		-- The WHERE clause is written as if we are looking for valid comparisons but then
		-- use the NOT to reverse the result so that we get those comparisons that fail
	"WHERE	NOT ("+char(10)+

		-- The CASEEVENT row exists unless MUSTEXIST flag is OFF 
		-- The CASEEVENT row does not have to exist if the Relative Cycle is "Previous" and
		-- the cycle of the Event being validated is 1.  This is because the Previous cycle of 
		-- cycle 1 would be 0 which is not allowed.
	"    (CE.CASEID is not null OR isnull(DL.MUSTEXIST,0)=0 OR (DL.RELATIVECYCLE=1 and T.CYCLE=1))"+char(10)+
		-- If the date that is being compared against is supposed to be a Due Date then check 
		-- that it has not Occurred
	"and (DL.COMPAREDATETYPE<>2 OR CE.OCCURREDFLAG=0)"+char(10)+
	"and ("+char(10)+
		-- The following complex WHERE clause is required to combine all of the different	
		-- combinations of COMPAREDATETYPE and OPERATOR in order to test the	
		-- correct column comparison.
	"	   (DL.COMPAREDATETYPE=1 and DL.OPERATOR='='  and T.DATETOCOMPARE =  CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='>'  and T.DATETOCOMPARE >  CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='<'  and T.DATETOCOMPARE <  CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='<=' and T.DATETOCOMPARE <= CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='>=' and T.DATETOCOMPARE >= CE.EVENTDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=1 and DL.OPERATOR='<>' and T.DATETOCOMPARE <> CE.EVENTDATE)"+char(10)+char(10)+

	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='='  and T.DATETOCOMPARE =  CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='>'  and T.DATETOCOMPARE >  CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='<'  and T.DATETOCOMPARE <  CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='<=' and T.DATETOCOMPARE <= CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='>=' and T.DATETOCOMPARE >= CE.EVENTDUEDATE)"+char(10)+
	"	OR (DL.COMPAREDATETYPE=2 and DL.OPERATOR='<>' and T.DATETOCOMPARE <> CE.EVENTDUEDATE)"+char(10)++char(10)+

	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='='  and T.DATETOCOMPARE =  isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='>'  and T.DATETOCOMPARE >  isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='<'  and T.DATETOCOMPARE <  isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='<=' and T.DATETOCOMPARE <= isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='>=' and T.DATETOCOMPARE >= isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	"	OR (DL.COMPAREDATETYPE=3 and DL.OPERATOR='<>' and T.DATETOCOMPARE <> isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"+char(10)+
	")) order by C.PROPERTYTYPE, C.COUNTRYCODE, C.IRN, EC.EVENTNO"

	exec @nErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@@rowcount
End

return @nErrorCode
go

grant execute on dbo.cs_GetCompareEventDates  to public
go
