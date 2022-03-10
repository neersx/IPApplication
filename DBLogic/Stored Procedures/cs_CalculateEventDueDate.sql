-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CalculateEventDueDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_CalculateEventDueDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_CalculateEventDueDate.'
	drop procedure dbo.cs_CalculateEventDueDate
end
print '**** Creating procedure dbo.cs_CalculateEventDueDate...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_CalculateEventDueDate
	@pdtCalculatedDate		datetime	= null output, -- the calculated lapse date
	@pnCriteriaNo			int		= null output, -- the CriteriaNo of the EventToCal
	@psCaseType			nchar(1)	= null,	-- User entered CaseType
	@psCountryCode			nvarchar(3)	= null, -- User entered Country
	@psPropertyType			nchar(1)	= null, -- User entered Property Type
	@psCaseCategory			nvarchar(2)	= null, -- User entered Category
	@psSubType			nvarchar(2)	= null, -- User entered Sub Type
	@psBasis			nvarchar(2)	= null, -- User entered Basis
	@pnCycle			tinyint		= null, -- Explicit annuity to use
	@pnCaseId			int		= null,	-- Optional CASEID if simulating date against real Case
	@pnEventToCalc			int,			-- Mandatory EventNo to be calculated
	@pnFromEventNo1			int		= null,	-- First EventNo used to trigger calculation
	@pdtFromDate1			datetime	= null,	-- First Date from which date is to be calculated
	@pnFromEventNo2			int		= null,	-- Second EventNo used to trigger calculation
	@pdtFromDate2			datetime	= null,	-- Second Date from which date is to be calculated
	@pbCriteriaOnly			bit		= 0
	
AS
-- PROCEDURE :	cs_CalculateEventDueDate
-- VERSION :	16
-- DESCRIPTION:	Returns a calculated due date for a virtual case defined by parameterised
--		characteristics and a triggering Date from which the due date will calculate.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 09 Aug 2007	MF	15103	1	Procedure created. Part of the original SQA12361 but extended.
-- 13 Aug 2007	MF	14812	2	Modify parameters in call to ip_PoliceCalculateDueDate.
-- 27 Aug 2007	MF	15276	3	Extend the calculation to allow a second governing date and also
--					allow a calculation against a live Case
-- 04 Sep 2007	MF	15276	4	Rework
-- 24 Sep 2007	MF	15384	5	Basis must be NULL when getting Criteria as no Basis is passed
--					as a parameter.
-- 07 Nov 2007	MF	15570	6	When loading #TEMPCASEEVENT with data from the CASEEVENT table,
--					do not load rows where the EVENT already has been loaded even if
--					the cycle is different.  The event to be calculated will use the
--					wrong cycle if a later cycle exists.
-- 27 Nov 2007	MF	15642	7	When determining the Criteria to use for the calculation, ensure that
--					the Action is valid for the given Country/Property Type/Case Type combination.
-- 30 Nov 2007	MF	15650	7	When calculating the date to be used to determine which fee calculation to use,
--					need to to check what EventNos can have the NRD and Payment date substituted in.
-- 05 Dec 2007	MF	15657	7	Find the Criteria that will allow the calculation of an Event so that the Action
--					can be used in the determination of a Margin.
-- 22 Jan 2008	MF	15851	8	Add the Basis as a parameter that can be passed through.
-- 26 May 2008	MF	15586	9	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 11 Dec 2008	MF	17136	10	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Jul 2010	MF	18758	11	Increase the column size of Instruction Type to allow for expanded list.
-- 18 Mar 2011	MF	10369	12	Display of fee for a case is crashing with SQL error due to missing LOADNUMBERTYPE column
-- 25 May 2012	DL	20371	13	Display of fee for a case is crashing with SQL error due to missing LOADNUMBERTYPE column
-- 27 Jan 2015	MF	43780	14	New columns for #TEMPCASEEVENT - RECALCEVENTDATE, SUPPRESSCALCULATION and DELETEDPREVIOUSLY
-- 10 Jul 2017	MF	71922	15	New column  for #TEMPCASEEVENT - RENEWALSTATUS
-- 19 May 2020	DL	DR-58943 16	Ability to enter up to 3 characters for Number type code via client server	

set nocount on

-- Create a temporary table used by the stored procedure for calculating the due date

create table #TEMPOPENACTION(
	CASEID			int		NOT NULL,
	ACTION			nvarchar(2)	collate database_default NOT NULL,
	CYCLE			smallint	NOT NULL,
	LASTEVENT		int		NULL,
	CRITERIANO		int		NULL,
	DATEFORACT		datetime	NULL,
	NEXTDUEDATE		datetime	NULL,
	POLICEEVENTS		decimal(1,0)	NULL,
	STATUSCODE		smallint	NULL,
	STATUSDESC		nvarchar(50)	collate database_default NULL,
	DATEENTERED		datetime	NULL,
	DATEUPDATED		datetime	NULL,
	CASETYPE		nchar(1)	collate database_default NULL,
	PROPERTYTYPE		nchar(1)	collate database_default NULL,
	COUNTRYCODE		nvarchar(3)	collate database_default NULL,
	CASECATEGORY		nvarchar(2)	collate database_default NULL,
	SUBTYPE			nvarchar(2)	collate database_default NULL,
	BASIS			nvarchar(2)	collate database_default NULL,
	REGISTEREDUSERS		nchar(1)	collate database_default NULL,
	LOCALCLIENTFLAG		decimal(1,0)	NULL,
	EXAMTYPE		int		NULL,
	RENEWALTYPE		int		NULL,
	CASEOFFICEID		int		NULL,
	NEWCRITERIANO		int		NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	STATE			nvarchar(2)	collate database_default NULL,	/*C-Calculate,C1-CalculationDone,E-Error	*/
	IDENTITYID		int		NULL
)

-- Create a temporary table to be used in the due date calculation

CREATE TABLE #TEMPCASEEVENT(
	CASEID			int		NOT NULL,
        DISPLAYSEQUENCE		smallint	NULL,
	EVENTNO			int		NOT NULL,
	CYCLE			smallint	NOT NULL,
	OLDEVENTDATE		datetime	NULL,
	OLDEVENTDUEDATE		datetime	NULL,
	DATEREMIND		datetime	NULL,
	DATEDUESAVED		decimal(1,0)	NULL,
	OCCURREDFLAG		decimal(1,0)	NULL,
	CREATEDBYACTION		nvarchar(2)	collate database_default NULL,
	CREATEDBYCRITERIA	int		NULL,
	ENTEREDDEADLINE		smallint	NULL,
	PERIODTYPE		nchar(1)	collate database_default NULL,
	DOCUMENTNO		smallint	NULL,
	DOCSREQUIRED		smallint	NULL,
	DOCSRECEIVED		smallint	NULL,
	USEMESSAGE2FLAG		decimal(1,0)	NULL,
	SUPPRESSREMINDERS	decimal(1,0)	NULL,
	OVERRIDELETTER		int		NULL,
	GOVERNINGEVENTNO	int		NULL,
	[STATE]			nvarchar(2)	collate database_default NOT NULL,--C=calculate;I=insert;D=delete
	ADJUSTMENT		nvarchar(4)	collate database_default NULL,	 -- any adjustment to be made to the date
	IMPORTANCELEVEL		nvarchar(2)	collate database_default NULL,
	WHICHDUEDATE		nchar(1)	collate database_default NULL,
	COMPAREBOOLEAN		decimal(1,0)	NULL,
	CHECKCOUNTRYFLAG	int		NULL,
	SAVEDUEDATE		smallint	NULL,
	STATUSCODE		smallint	NULL,
	RENEWALSTATUS		smallint	NULL,
	SPECIALFUNCTION		nchar(1)	collate database_default NULL,
	INITIALFEE		int		NULL,
	PAYFEECODE		nchar(1)	collate database_default NULL,
	CREATEACTION		nvarchar(2)	collate database_default NULL,
	STATUSDESC		nvarchar(50)	collate database_default NULL,
	CLOSEACTION		nvarchar(2)	collate database_default NULL,
	RELATIVECYCLE		smallint	NULL,
	INSTRUCTIONTYPE		nvarchar(3)	collate database_default NULL,
	FLAGNUMBER		smallint	NULL,
	SETTHIRDPARTYON		decimal(1,0)	NULL,
	COUNTRYCODE		nvarchar(3)	collate database_default NULL,
	NEWEVENTDATE		datetime	NULL,
	NEWEVENTDUEDATE		datetime	NULL,
	NEWDATEREMIND		datetime	NULL,
	USEDINCALCULATION	nchar(1)	collate database_default NULL,
	LOOPCOUNT		smallint	NULL,
	REMINDERTOSEND		smallint	NULL,
	UPDATEFROMPARENT	tinyint		NULL,
	PARENTEVENTDATE		datetime	NULL,
	USERID			nvarchar(255)	collate database_default NULL,
	EVENTUPDATEDMANUALLY	tinyint		NULL,
	CRITERIANO		int		NULL,
	ACTION			varchar(2)	collate database_default NULL,
	UNIQUEID		int		identity(10,10),
	ESTIMATEFLAG		decimal(1,0)	NULL,
	EXTENDPERIOD		smallint	NULL,
	EXTENDPERIODTYPE	nchar(1)	collate database_default NULL,
	INITIALFEE2		int		NULL,
	PAYFEECODE2		nchar(1)	collate database_default NULL,
	ESTIMATEFLAG2		decimal(1,0)	NULL,
	PTADELAY		smallint	NULL,
	IDENTITYID		int		NULL,
	SETTHIRDPARTYOFF	bit		NULL,
	CHANGENAMETYPE		nvarchar(3)	collate database_default NULL,
	COPYFROMNAMETYPE	nvarchar(3)	collate database_default NULL,
	COPYTONAMETYPE		nvarchar(3)	collate database_default NULL,
	DELCOPYFROMNAME		bit		NULL,
	DIRECTPAYFLAG		bit		NULL,
	DIRECTPAYFLAG2		bit		NULL,
	FROMCASEID		int		NULL,
	LIVEFLAG		bit		default(0),
	RESPNAMENO		int		NULL,
	RESPNAMETYPE		nvarchar(3)	collate database_default NULL,
	LOADNUMBERTYPE		nvarchar(3)	collate database_default NULL,	--SQA17773
	PARENTNUMBER		nvarchar(36)	collate database_default NULL,	--SQA17773
	RECALCEVENTDATE		bit		NULL,	-- SQA19252,	
	SUPPRESSCALCULATION	bit		NULL,	-- SQA21404
	DELETEDPREVIOUSLY	tinyint		NULL	-- RFC40815 Counter used to avoid continuously triggering an Event as deleted
	)

-- The #TEMPCASES table is required for the due date calculation
-- No data is required to be loaded

	create table #TEMPCASES (
            CASEID               int		NOT NULL,
            STATUSCODE           int            NULL,
            RENEWALSTATUS        int            NULL,
	    REPORTTOTHIRDPARTY   decimal(1,0)	NULL,
            PREDECESSORID        int            NULL,
	    ACTION		 nvarchar(2)	collate database_default NULL,
	    EVENTNO		 int		NULL,
	    CYCLE		 smallint	NULL,
            CASETYPE             nchar(1)	collate database_default NULL,
            PROPERTYTYPE         nchar(1)	collate database_default NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,
            CASECATEGORY         nvarchar(2)	collate database_default NULL,
            SUBTYPE              nvarchar(2)	collate database_default NULL,
            BASIS                nvarchar(2)	collate database_default NULL,
            REGISTEREDUSERS      nchar(1)	collate database_default NULL,
            LOCALCLIENTFLAG      decimal(1,0)	NULL,
            EXAMTYPE             int		NULL,
            RENEWALTYPE          int		NULL,
            INSTRUCTIONSLOADED   tinyint	NULL,
	    ERRORFOUND           bit            NULL,
	    RENEWALACTION	 nvarchar(2)	collate database_default NULL,
	    RENEWALEVENTNO	 int		NULL,
	    RENEWALCYCLE	 smallint	NULL,
	    RECALCULATEPTA	 bit		default(0),
	    IPODELAY 		 int		default(0),
	    APPLICANTDELAY 	 int		default(0),
            USERID               nvarchar(255)  collate database_default NULL,
	    IDENTITYID		 int		NULL,
	    CASESEQUENCENO	 int		identity(1,1),
	    OFFICEID		 int		NULL,
            OLDSTATUSCODE        int            NULL,
            OLDRENEWALSTATUS     int            NULL,
	    CASELOGSTAMP	 datetime	NULL,			--SQA20371  ( column introduced by RFC10929)
	    PROPERTYLOGSTAMP	 datetime	NULL		--SQA20371  ( column introduced by RFC10929)            
	)

-- The TEMPCASEINSTRUCTIONS table is required for the due date calculation
-- procedure.  No data needs to be loaded into it.
create table #TEMPCASEINSTRUCTIONS (
	CASEID			int		NOT NULL, 
	INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL,
	COMPOSITECODE		nchar(33) 	collate database_default NULL,	--SQA13161
	INSTRUCTIONCODE 	smallint	NULL,
	PERIOD1TYPE		nchar(1) 	collate database_default NULL,
	PERIOD1AMT		smallint	NULL,
	PERIOD2TYPE		nchar(1) 	collate database_default NULL,
	PERIOD2AMT		smallint	NULL,
	PERIOD3TYPE		nchar(1) 	collate database_default NULL,
	PERIOD3AMT		smallint	NULL,
	ADJUSTMENT		nvarchar(4)	collate database_default NULL,
	ADJUSTDAY		tinyint		NULL,
	ADJUSTSTARTMONTH	tinyint		NULL,
	ADJUSTDAYOFWEEK		tinyint		NULL,
	ADJUSTTODATE		datetime	NULL
)

Declare	@ErrorCode		int,
	@sRenewalEvents		nvarchar(254),
	@sPaymentEvents		nvarchar(254),
	@sSQLString		nvarchar(4000)

-- Parameters for ip_PoliceCalculateDueDate

Declare	@pnCountStateRX		int,
	@pnCountStateC		int,
	@pnCountStateI		int,
	@pnCountStateR		int,
	@pnCountStateD		int,
	@nCountParentUpdate	int,
	@pdtUntilDate		datetime


set @ErrorCode=0

-- Check to see if there are explict Events to check for
-- for the purpose of substituting the dates passed as parameters.
If @pdtFromDate1 is not null
and @pnFromEventNo1  is null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sRenewalEvents=S.COLCHARACTER
	from SITECONTROL S
	where S.CONTROLID='Substitute In Renewal Date'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sRenewalEvents	nvarchar(254)	OUTPUT',
					  @sRenewalEvents=@sRenewalEvents	OUTPUT
End

If @pdtFromDate2 is not null
and @pnFromEventNo2  is null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sPaymentEvents=S.COLCHARACTER
	from SITECONTROL S
	where S.CONTROLID='Substitute In Payment Date'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sPaymentEvents	nvarchar(254)	OUTPUT',
					  @sPaymentEvents=@sPaymentEvents	OUTPUT
End

If  @pnCaseId is not null
and @ErrorCode=0
Begin
	---------------------------------------
	-- If the CaseId has been supplied then 
	-- get the characteristics of the Case.
	---------------------------------------

	Set @sSQLString="
	SELECT	@psCaseType	=C.CASETYPE,
		@psCountryCode	=C.COUNTRYCODE,
		@psPropertyType	=C.PROPERTYTYPE,
		@psCaseCategory	=C.CASECATEGORY,
		@psSubType	=C.SUBTYPE,
		@psBasis	=P.BASIS
	From CASES C
	left join PROPERTY P on (P.CASEID=C.CASEID)
	Where C.CASEID=@pnCaseId"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psCaseType		nchar(1)	OUTPUT,
				  @psCountryCode	nvarchar(3)	OUTPUT,
				  @psPropertyType	nchar(1)	OUTPUT,
				  @psCaseCategory	nvarchar(2)	OUTPUT,
				  @psSubType		nvarchar(2)	OUTPUT,
				  @psBasis		nvarchar(2)	OUTPUT,
				  @pnCaseId		int',
				  @psCaseType	 =@psCaseType		OUTPUT,
				  @psCountryCode =@psCountryCode	OUTPUT,
				  @psPropertyType=@psPropertyType	OUTPUT,
				  @psCaseCategory=@psCaseCategory	OUTPUT,
				  @psSubType	 =@psSubType		OUTPUT,
				  @psBasis	 =@psBasis		OUTPUT,
				  @pnCaseId	 =@pnCaseId
End

If @ErrorCode=0
Begin
	----------------------------------------------
	-- Get the CRITERIANO that holds the rules for
	-- calculating the Due Date
	----------------------------------------------
	
	Set @sSQLString="
	SELECT 
	@pnCriteriaNo   =
	convert(int,
	substring(
	max (
	CASE WHEN (C.ACTION<>'~2')		THEN '0' ELSE '1' END +  
	CASE WHEN (C.CASETYPE IS NULL)		THEN '0' 
		ELSE CASE WHEN(C.CASETYPE=@psCaseType) 	 THEN '2' ELSE '1' END 
	END +  
	CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
	CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (C.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (C.DATEOFACT IS NULL)		THEN '0' ELSE '1' END +
	isnull(convert(varchar, DATEOFACT, 112),'00000000') +
	CASE WHEN (C.USERDEFINEDRULE is NULL
		OR C.USERDEFINEDRULE = 0)	THEN '0' ELSE '1' END +
	convert(varchar,C.CRITERIANO)), 17,20))
	FROM CRITERIA C 
	join CASETYPE CT	on (CT.CASETYPE=@psCaseType)
	join DUEDATECALC DD	on (DD.CRITERIANO=C.CRITERIANO
				and DD.EVENTNO=@pnEventToCalc
				and DD.COMPARISON is null)
	join VALIDACTION VA	on (VA.CASETYPE=CT.CASETYPE
				and VA.PROPERTYTYPE=@psPropertyType
				and VA.ACTION=C.ACTION
				and VA.COUNTRYCODE=(select min(COUNTRYCODE)
							from VALIDACTION VA1
							where VA1.CASETYPE=VA.CASETYPE
							and VA1.PROPERTYTYPE=VA.PROPERTYTYPE
							and VA1.COUNTRYCODE in (@psCountryCode,'ZZZ')))
	WHERE	C.RULEINUSE		= 1  	
	AND	C.PURPOSECODE		= 'E'
	AND (	C.CASETYPE	      in (@psCaseType,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
	AND (	C.PROPERTYTYPE 		= @psPropertyType 	OR C.PROPERTYTYPE 	IS NULL ) 
	AND (	C.COUNTRYCODE 		= @psCountryCode 	OR C.COUNTRYCODE 	IS NULL ) 
	AND (	C.CASECATEGORY 		= @psCaseCategory 	OR C.CASECATEGORY 	IS NULL ) 
	AND (	C.SUBTYPE 		= @psSubType		OR C.SUBTYPE 		IS NULL ) 
	AND (	C.BASIS 		= @psBasis		OR C.BASIS		IS NULL ) 
	AND (	C.DATEOFACT 	       <= getdate()		OR C.DATEOFACT 		IS NULL )"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCriteriaNo		int		OUTPUT,
				  @psCaseType		nchar(1),
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @psCaseCategory	nvarchar(2),
				  @psSubType		nvarchar(2),
				  @psBasis		nvarchar(2),
				  @pnEventToCalc	int',
				  @pnCriteriaNo		=@pnCriteriaNo	OUTPUT,
				  @psCaseType		=@psCaseType,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyType,
				  @psCaseCategory	=@psCaseCategory,
				  @psSubType		=@psSubType,
				  @psBasis		=@psBasis,
				  @pnEventToCalc	=@pnEventToCalc
End

If  @pnCriteriaNo is not null
and @pbCriteriaOnly=0
and @ErrorCode=0
Begin
	-- Load the temporary table required by the procedure 
	-- to perform the calculations
	-- NOTE : A dummy CASEID is being used if one is not supplied(the largest negative integer)

	Set @sSQLString="
	insert into #TEMPOPENACTION (CASEID, ACTION, CYCLE, CRITERIANO, POLICEEVENTS, COUNTRYCODE, NEWCRITERIANO)
	select isnull(@pnCaseId,-2147483648), ACTION, 1, CRITERIANO, 1, @psCountryCode, CRITERIANO
	from CRITERIA
	where CRITERIANO=@pnCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psCountryCode	nvarchar(3),
				  @pnCriteriaNo		int,
				  @pnCaseId		int',
				  @psCountryCode=@psCountryCode,
				  @pnCriteriaNo  =@pnCriteriaNo,
				  @pnCaseId	=@pnCaseId

	If @ErrorCode=0
	Begin
		-- Load a #TEMPCASEEVENT row for the Event that is to be calculated
		Set @sSQLString="
		insert into #TEMPCASEEVENT (CASEID,EVENTNO,CYCLE,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
					    STATE,ADJUSTMENT,WHICHDUEDATE,COMPAREBOOLEAN,SAVEDUEDATE,
					    COUNTRYCODE,NEWEVENTDATE,NEWEVENTDUEDATE,LOOPCOUNT,UPDATEFROMPARENT,
					    CRITERIANO,ACTION, RECALCEVENTDATE)
		select	isnull(@pnCaseId,-2147483648),EC.EVENTNO,isnull(@pnCycle,1),0,C.ACTION,C.CRITERIANO,
			'C',EC.ADJUSTMENT,EC.WHICHDUEDATE,EC.COMPAREBOOLEAN,EC.SAVEDUEDATE,
			@psCountryCode,NULL,NULL,0,0,
			C.CRITERIANO,C.ACTION, EC.RECALCEVENTDATE
		from CRITERIA C
		join EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO
					and EC.EVENTNO=@pnEventToCalc)
		where C.CRITERIANO=@pnCriteriaNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@psCountryCode	nvarchar(3),
				  @pnCriteriaNo		int,
				  @pnEventToCalc	int,
				  @pnCycle		tinyint,
				  @pnCaseId		int',
				  @psCountryCode =@psCountryCode,
				  @pnCriteriaNo   =@pnCriteriaNo,
				  @pnEventToCalc =@pnEventToCalc,
				  @pnCycle       =@pnCycle,
				  @pnCaseId	 =@pnCaseId
	End

	If  @ErrorCode=0
	and @pdtFromDate1 is not null
	and @pnFromEventNo1 is null
	Begin
		-------------------------------------------------------
		-- If the first date has been supplied but no EventNo
		-- then determine the EventNo to use from the first Due
		-- Date Calculation rule so it can be inserted into the
		-- temporary table.
		-------------------------------------------------------
		Set @sSQLString="
		Select @pnFromEventNo1=DD.FROMEVENT
		from DUEDATECALC DD
		Where DD.CRITERIANO=@pnCriteriaNo
		and DD.EVENTNO=@pnEventToCalc
		and DD.COMPARISON is null
		and DD.SEQUENCE=(select min(DD1.SEQUENCE)
				 from DUEDATECALC DD1
				 where DD1.CRITERIANO=DD.CRITERIANO
				 and DD1.EVENTNO=DD.EVENTNO
				 and DD1.COMPARISON is null"

		If @sRenewalEvents is not null
			Set @sSQLString=@sSQLString+char(10)+"
				and DD1.FROMEVENT in ("+@sRenewalEvents+")"

		Set @sSQLString=@sSQLString+")"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnFromEventNo1	int		OUTPUT,
					  @pnEventToCalc	int,
					  @pnCriteriaNo		int',
					  @pnFromEventNo1=@pnFromEventNo1	OUTPUT,
					  @pnEventToCalc =@pnEventToCalc,
					  @pnCriteriaNo   =@pnCriteriaNo
					  
	End

	If  @ErrorCode=0
	and @pdtFromDate1 is not null
	and @pnFromEventNo1 is not null
	Begin
		-- Load a #TEMPCASEEVENT row with details of the first governing Event used in the calculation.

		Set @sSQLString="
		insert into #TEMPCASEEVENT (CASEID,EVENTNO,CYCLE,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
					    STATE,
					    NEWEVENTDATE,NEWEVENTDUEDATE,LOOPCOUNT,UPDATEFROMPARENT,
					    CRITERIANO,ACTION)
		select	isnull(@pnCaseId,-2147483648),@pnFromEventNo1,isnull(@pnCycle,1),
			CASE WHEN(@pdtFromDate1<=(getdate()-1)) THEN 1 ELSE 0 END,
			C.ACTION,C.CRITERIANO,
			'R1',
			CASE WHEN(@pdtFromDate1<=(getdate()-1)) THEN @pdtFromDate1 END,
			@pdtFromDate1,0,0,
			C.CRITERIANO,C.ACTION
		from CRITERIA C
		where C.CRITERIANO=@pnCriteriaNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCriteriaNo		int,
				  @pdtFromDate1		datetime,
				  @pnCycle		tinyint,
				  @pnFromEventNo1	int,
				  @pnCaseId		int',
				  @pnCriteriaNo   =@pnCriteriaNo,
				  @pdtFromDate1  =@pdtFromDate1,
				  @pnCycle       =@pnCycle,
				  @pnFromEventNo1=@pnFromEventNo1,
				  @pnCaseId	 =@pnCaseId
	End

	If  @ErrorCode=0
	and @pdtFromDate2 is not null
	and @pnFromEventNo2 is null
	Begin
		------------------------------------------------------
		-- If a second date has been supplied but no EventNo
		-- then determine the EventNo to use from the Due Date
		-- Calculation rule so it can be inserted into the
		-- temporary table.
		------------------------------------------------------
		Set @sSQLString="
		Select @pnFromEventNo2=DD.FROMEVENT
		from DUEDATECALC DD
		Where DD.CRITERIANO=@pnCriteriaNo
		and DD.EVENTNO=@pnEventToCalc
		and DD.FROMEVENT<>isnull(@pnFromEventNo1,'')
		and DD.COMPARISON is null
		and DD.SEQUENCE=(select min(DD1.SEQUENCE)
				 from DUEDATECALC DD1
				 where DD1.CRITERIANO=DD.CRITERIANO
				 and DD1.EVENTNO=DD.EVENTNO
				 and DD1.COMPARISON is null
				 and DD1.FROMEVENT<>isnull(@pnFromEventNo1,'')"

		If @sPaymentEvents is not null
			Set @sSQLString=@sSQLString+char(10)+"
				and DD1.FROMEVENT in ("+@sPaymentEvents+")"

		Set @sSQLString=@sSQLString+")"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnFromEventNo2	int		OUTPUT,
					  @pnFromEventNo1	int,
					  @pnEventToCalc	int,
					  @pnCriteriaNo		int',
					  @pnFromEventNo2=@pnFromEventNo2	OUTPUT,
					  @pnFromEventNo1=@pnFromEventNo1,
					  @pnEventToCalc =@pnEventToCalc,
					  @pnCriteriaNo   =@pnCriteriaNo
					  
	End

	If  @ErrorCode=0
	and @pdtFromDate2 is not null
	and @pnFromEventNo2 is not null
	Begin
		-- Load a #TEMPCASEEVENT row with details of the second governing Event used in the calculation.
		Set @sSQLString="
		insert into #TEMPCASEEVENT (CASEID,EVENTNO,CYCLE,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
					    STATE,
					    NEWEVENTDATE,NEWEVENTDUEDATE,LOOPCOUNT,UPDATEFROMPARENT,
					    CRITERIANO,ACTION)
		select	isnull(@pnCaseId,-2147483648),@pnFromEventNo2,isnull(@pnCycle,1),
			CASE WHEN(@pdtFromDate2<=(getdate()-1)) THEN 1 ELSE 0 END,
			C.ACTION,C.CRITERIANO,
			'R1',
			CASE WHEN(@pdtFromDate2<=(getdate()-1)) THEN @pdtFromDate2 END,
			@pdtFromDate2,0,0,
			C.CRITERIANO,C.ACTION
		from CRITERIA C
		where C.CRITERIANO=@pnCriteriaNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCriteriaNo		int,
				  @pdtFromDate2		datetime,
				  @pnCycle		tinyint,
				  @pnFromEventNo2	int,
				  @pnCaseId		int',
				  @pnCriteriaNo   =@pnCriteriaNo,
				  @pdtFromDate2  =@pdtFromDate2,
				  @pnCycle       =@pnCycle,
				  @pnFromEventNo2=@pnFromEventNo2,
				  @pnCaseId	 =@pnCaseId
	End

	If  @pnCaseId is not null
	and @ErrorCode=0
	Begin
		-------------------------------------------
		-- Back fill the #TEMPOPENACTION table with
		-- the OPENACTION rows from the Case being
		-- processed.
		-------------------------------------------
		Set @sSQLString="
		insert into #TEMPOPENACTION (CASEID, ACTION, CYCLE, CRITERIANO, POLICEEVENTS, COUNTRYCODE, NEWCRITERIANO)
		select OA.CASEID, OA.ACTION, OA.CYCLE, OA.CRITERIANO, OA.POLICEEVENTS, @psCountryCode, OA.CRITERIANO
		from OPENACTION OA
		left join #TEMPOPENACTION T on (T.CASEID=OA.CASEID
					    and T.ACTION=OA.ACTION
					    and T.CYCLE =OA.CYCLE)
		where OA.CASEID=@pnCaseId
		and T.CASEID is null"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psCountryCode	nvarchar(3),
					  @pnCaseId		int',
					  @psCountryCode=@psCountryCode,
					  @pnCaseId	=@pnCaseId

		If @ErrorCode=0
		Begin
			-------------------------------------
			-- Backfill #TEMPCASEEVENT with the
			-- CASEEVENT rows from the Case being
			-- processed.
			-------------------------------------
			Set @sSQLString="
			insert into #TEMPCASEEVENT (CASEID,EVENTNO,CYCLE,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
						    STATE,
						    NEWEVENTDATE,NEWEVENTDUEDATE,LOOPCOUNT,UPDATEFROMPARENT,
						    ACTION,CRITERIANO)
			select	CE.CASEID,CE.EVENTNO,CE.CYCLE,CE.OCCURREDFLAG,CE.CREATEDBYACTION,CE.CREATEDBYCRITERIA,
				'R1',
				CE.EVENTDATE,CE.EVENTDUEDATE,0,0,
				CE.CREATEDBYACTION,CE.CREATEDBYCRITERIA
			from CASEEVENT CE
			-- SQA15570
			-- Note that we do not load any Events already loaded even if 
			-- the explicit cycle has not been loaded.
			left join #TEMPCASEEVENT T on (T.CASEID=CE.CASEID
						   and T.EVENTNO=CE.EVENTNO)
			where CE.CASEID=@pnCaseId
			and T.CASEID is null"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnCaseId	int',
						  @pnCaseId=@pnCaseId
		End
	End

	-- Now call the Policing procedure that calculates due dates

	If @ErrorCode=0
	Begin	
		Set @pdtUntilDate=getdate()
	
		Set @pnCountStateC	= 1
		Set @pnCountStateI	= 0
		Set @pnCountStateR	= 0
		Set @pnCountStateRX	= 0
		Set @pnCountStateD	= 0
		Set @nCountParentUpdate	= 0

		Exec @ErrorCode=ip_PoliceCalculateDueDate
				@pnCountStateC		=@pnCountStateC		OUTPUT,
				@pnCountStateI		=@pnCountStateI		OUTPUT,
				@pnCountStateR		=@pnCountStateR		OUTPUT,
				@pnCountStateRX		=@pnCountStateRX	OUTPUT,
				@pnCountStateD		=@pnCountStateD		OUTPUT,
				@nCountParentUpdate	=@nCountParentUpdate	OUTPUT,
				@pdtUntilDate		=@pdtUntilDate,
			 	@pnDebugFlag		=0
	End

	If @ErrorCode=0
	Begin
		--------------------------------------------------
		-- Now extract the result from the temporary table
		--------------------------------------------------
		Set @sSQLString="
		Select @pdtCalculatedDate=NEWEVENTDUEDATE
		From #TEMPCASEEVENT
		where EVENTNO=@pnEventToCalc"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtCalculatedDate		datetime	OUTPUT,
					  @pnEventToCalc	int',
					  @pdtCalculatedDate  =@pdtCalculatedDate		OUTPUT,
					  @pnEventToCalc=@pnEventToCalc
	End
End

RETURN @ErrorCode
go

grant execute on dbo.cs_CalculateEventDueDate  to public
go

