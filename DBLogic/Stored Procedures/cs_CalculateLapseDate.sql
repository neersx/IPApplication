-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CalculateLapseDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_CalculateLapseDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_CalculateLapseDate.'
	drop procedure dbo.cs_CalculateLapseDate
end
print '**** Creating procedure dbo.cs_CalculateLapseDate...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_CalculateLapseDate
	@pdtLapseDate			datetime	output, -- the calculated lapse date
	@psCaseType			nchar(1)	= null,	-- User entered CaseType
	@psCountryCode			nvarchar(3)	= null, -- User entered Country
	@psPropertyType			nchar(1)	= null, -- User entered Property Type
	@psCaseCategory			nvarchar(2)	= null, -- User entered Category
	@psSubType			nvarchar(2)	= null, -- User entered Sub Type
	@pnCycle			tinyint		= null, -- Explicit annuity to use
	@pnLapseEventNo			int,			-- Eventno
	@pdtRenewalDate			datetime		-- Renewal Date for which lapse date is to be calculated
	
AS
-- PROCEDURE :	cs_CalculateLapseDate
-- VERSION :	5
-- DESCRIPTION:	Returns a calculated lapsed date for a virtual case defined by passed characteristics
--		and a Renewal Date from which the lapse date will calculate.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 20 Nov 2006	MF	12361	1	Procedure created
-- 01 Jul 2010	MF	18758	2	Increase the column size of Instruction Type to allow for expanded list.
-- 27 Jan 2015	MF	43780	03	New columns for #TEMPCASEEVENT - RECALCEVENTDATE, SUPPRESSCALCULATION and DELETEDPREVIOUSLY
-- 10 Jul 2017	MF	71922	04	New column  for #TEMPCASEEVENT - RENEWALSTATUS
-- 19 May 2020	DL	DR-58943	5		Ability to enter up to 3 characters for Number type code via client server	

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
	@nCriteriaNo		int,
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

If @ErrorCode=0
Begin
	----------------------------------------------
	-- Get the CRITERIANO that holds the rules for
	-- calculating the Lapse Date
	----------------------------------------------
	

	Set @sSQLString="
	SELECT 
	@nCriteriaNo   =
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
				and DD.EVENTNO=@pnLapseEventNo
				and DD.FROMEVENT=-11
				and DD.COMPARISON is null)
	WHERE	C.RULEINUSE		= 1  	
	AND	C.PURPOSECODE		= 'E'
	AND (	C.CASETYPE	      in (@psCaseType,CT.ACTUALCASETYPE) or C.CASETYPE	is NULL )
	AND (	C.PROPERTYTYPE 		= @psPropertyType 	OR C.PROPERTYTYPE 	IS NULL ) 
	AND (	C.COUNTRYCODE 		= @psCountryCode 	OR C.COUNTRYCODE 	IS NULL ) 
	AND (	C.CASECATEGORY 		= @psCaseCategory 	OR C.CASECATEGORY 	IS NULL ) 
	AND (	C.SUBTYPE 		= @psSubType		OR C.SUBTYPE 		IS NULL ) 
	AND (	C.DATEOFACT 	       <= getdate()		OR C.DATEOFACT 		IS NULL )"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriteriaNo		int		OUTPUT,
				  @psCaseType		nchar(1),
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @psCaseCategory	nvarchar(2),
				  @psSubType		nvarchar(2),
				  @pnLapseEventNo	int',
				  @nCriteriaNo		=@nCriteriaNo	OUTPUT,
				  @psCaseType		=@psCaseType,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyType,
				  @psCaseCategory	=@psCaseCategory,
				  @psSubType		=@psSubType,
				  @pnLapseEventNo	=@pnLapseEventNo
End

If @nCriteriaNo is not null
and @ErrorCode=0
Begin
	-- Load the temporary table required by the procedure 
	-- to perform the calculations
	-- NOTE : A dummy CASEID is being used (the largest negative integer)

	Set @sSQLString="
	insert into #TEMPOPENACTION (CASEID, ACTION, CYCLE, CRITERIANO, POLICEEVENTS, COUNTRYCODE, NEWCRITERIANO)
	select -2147483648, ACTION, 1, CRITERIANO, 1, @psCountryCode, CRITERIANO
	from CRITERIA
	where CRITERIANO=@nCriteriaNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psCountryCode	nvarchar(3),
				  @nCriteriaNo		int',
				  @psCountryCode=@psCountryCode,
				  @nCriteriaNo  =@nCriteriaNo

	If @ErrorCode=0
	Begin
		-- Load a #TEMPCASEEVENT row for the Event that is to be calculated
		Set @sSQLString="
		insert into #TEMPCASEEVENT (CASEID,EVENTNO,CYCLE,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
					    STATE,ADJUSTMENT,WHICHDUEDATE,COMPAREBOOLEAN,SAVEDUEDATE,
					    COUNTRYCODE,NEWEVENTDATE,NEWEVENTDUEDATE,LOOPCOUNT,UPDATEFROMPARENT,
					    CRITERIANO,ACTION, RECALCEVENTDATE)
		select	-2147483648,EC.EVENTNO,isnull(@pnCycle,1),0,C.ACTION,C.CRITERIANO,
			'C',EC.ADJUSTMENT,EC.WHICHDUEDATE,EC.COMPAREBOOLEAN,EC.SAVEDUEDATE,
			@psCountryCode,NULL,NULL,0,0,
			C.CRITERIANO,C.ACTION, EC.RECALCEVENTDATE
		from CRITERIA C
		join EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO
					and EC.EVENTNO=@pnLapseEventNo)
		where C.CRITERIANO=@nCriteriaNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@psCountryCode	nvarchar(3),
				  @nCriteriaNo		int,
				  @pnLapseEventNo	int,
				  @pnCycle		tinyint',
				  @psCountryCode =@psCountryCode,
				  @nCriteriaNo   =@nCriteriaNo,
				  @pnLapseEventNo=@pnLapseEventNo,
				  @pnCycle       =@pnCycle
	End

	If @ErrorCode=0
	Begin
		-- Load a #TEMPCASEEVENT row with details of the governing Event used in the calculation.
		-- The assumption is that the Lapsed Date must be calculated from the Renewal Date (-11)
		-- as this is the only date that is being manually supplied.
		Set @sSQLString="
		insert into #TEMPCASEEVENT (CASEID,EVENTNO,CYCLE,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,
					    STATE,
					    NEWEVENTDATE,NEWEVENTDUEDATE,LOOPCOUNT,UPDATEFROMPARENT,
					    CRITERIANO,ACTION)
		select	-2147483648,-11,isnull(@pnCycle,1),
			CASE WHEN(@pdtRenewalDate<=(getdate()-1)) THEN 1 ELSE 0 END,
			C.ACTION,C.CRITERIANO,
			'R1',
			CASE WHEN(@pdtRenewalDate<=(getdate()-1)) THEN @pdtRenewalDate END,
			@pdtRenewalDate,0,0,
			C.CRITERIANO,C.ACTION
		from CRITERIA C
		where C.CRITERIANO=@nCriteriaNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCriteriaNo		int,
				  @pdtRenewalDate	datetime,
				  @pnCycle		tinyint',
				  @nCriteriaNo   =@nCriteriaNo,
				  @pdtRenewalDate=@pdtRenewalDate,
				  @pnCycle       =@pnCycle
	End

	-- Now call the Policing procedure that calculates due dates

	If @ErrorCode=0
	Begin	
		Set @pdtUntilDate=getdate()

		Exec @ErrorCode=ip_PoliceCalculateDueDate
				@pnCountStateC			=@pnCountStateC		OUTPUT,
				@pnCountStateI			=@pnCountStateI		OUTPUT,
				@pnCountStateR			=@pnCountStateR		OUTPUT,
				@pnCountStateRX			=@pnCountStateRX	OUTPUT,
				@pnCountStateD			=@pnCountStateD		OUTPUT,
				@nCountParentUpdate		=@nCountParentUpdate	OUTPUT,
				@pnCurrentStateC		=1,
				@pnCurrentStateI		=0,
				@pnCurrentStateR		=0,
				@pnCurrentStateD		=0,
				@nCurrentParentUpdate		=0,
				@pdtUntilDate			=@pdtUntilDate,
			 	@pnDebugFlag			=0
	End

	If @ErrorCode=0
	Begin
		--------------------------------------------------
		-- Now extract the result from the temporary table
		--------------------------------------------------
		Set @sSQLString="
		Select @pdtLapseDate=NEWEVENTDUEDATE
		From #TEMPCASEEVENT
		where EVENTNO=@pnLapseEventNo"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pdtLapseDate		datetime	OUTPUT,
					  @pnLapseEventNo	int',
					  @pdtLapseDate  =@pdtLapseDate		OUTPUT,
					  @pnLapseEventNo=@pnLapseEventNo
	End
End

RETURN @ErrorCode
go

grant execute on dbo.cs_CalculateLapseDate  to public
go

