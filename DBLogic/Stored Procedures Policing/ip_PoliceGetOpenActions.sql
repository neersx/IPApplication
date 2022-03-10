-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetOpenActions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetOpenActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetOpenActions.'
	drop procedure dbo.ip_PoliceGetOpenActions
end
print '**** Creating procedure dbo.ip_PoliceGetOpenActions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetOpenActions 
			@pnRowCount		int	OUTPUT,
			@pnDebugFlag		tinyint,
			@psIRN			nvarchar(30),
			@psOfficeId		nvarchar(254),
			@psPropertyType		nchar(1),
			@psCountryCode		nvarchar(3),
			@pdtDateOfAct		datetime,
			@psAction		nvarchar(2),
			@pnEventNo		int,
			@psNameType		nvarchar(3),
			@pnNameNo		int,
			@psCaseType		nchar(1),
			@psCaseCategory		nvarchar(2),
			@psSubtype		nvarchar(2),
			@pnExcludeProperty	decimal(1,0),
			@pnExcludeCountry	decimal(1,0),
			@pnExcludeAction	decimal(1,0),
			@pnCaseid		int,
			@pnTypeOfRequest	smallint,
			@pnCriteriaFlag		decimal(1,0),
			@pnDueDateFlag		decimal(1,0),
			@pnCalcReminderFlag	decimal(1,0),
			@pbRecalcEventDate	bit,
			@pnUserIdentityId	int		= null,
			@psSqlUser		nvarchar(30)	= null
as
-- PROCEDURE :	ip_PoliceGetOpenActions
-- VERSION :	21
-- DESCRIPTION:	A procedure to load the temporary tables #TEMPCASES & #TEMPOPENACTION with those rows to be be policed
-- CALLED BY :	ipu_PoliceRecalc

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created	
-- 19/09/2001	MF	7062		Need to pass the @pnCalcReminderFlag to the ipb_PoliceGetAction procedure
-- 18/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 12/02/2002	MF	7404		When an Event is being recalculated ensure that the cycle of the event is
--					appropriate for the open action it belongs to.
-- 22/07/2002	MF	7750		Increase IRN to 30 characters
-- 25 JUL 2003	MF	8260	10	Get details required for Patent Term Adjustment calculation
-- 07 Jul 2005	MF	11011	11	Increase CaseCategory column size to NVARCHAR(2)
-- 09 Jan 2006	MF	11971	12	A new option allows for Events that have already occurred to be recalculated
-- 10 Aug 2007	MF	12548	13	Load #TEMPCASES.OFFICEID
-- 24 May 2007	MF	14812	14	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	15	Reserve word [STATE]
-- 07 Nov 2007	MF	15187	14	Provide the ability filter by one or more offices.
-- 09 Nov 2007	MF	15518	16	During performance improvements also discovered #TEMPCASES was not having
--					USERID and IDENTITYID set.
-- 04 Dec 2007	MF	15652	17	Ensure that nulls in IPODELAY and/or APPLICANTDELAY are changed to zero.
-- 20 Mar 2008	MF	14297	18	Allow the user id to be passed from the original Policing request record.
-- 01 Jul 2011	MF	10929	19	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 24 Feb 2012	MF	R11985	20	Provide the ability for a unicode value to be used as the NameType.
-- 14 Nov 2018  AV  75198/DR-45358	21   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

DECLARE		@ErrorCode		int,
		@nOpenActionCount	int,
		@sInsertString		nvarchar(4000),
		@sWhereClause		nvarchar(2000)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode   = 0
Set @sWhereClause=null

-- Load #TEMPCASES with the details of the Cases to be recalculated. 

-- Construct the SQL to load the TEMPCASES table based on the parameters passed to this procedure

set @sInsertString = "
	insert #TEMPCASES (CASEID, STATUSCODE, RENEWALSTATUS, REPORTTOTHIRDPARTY, PREDECESSORID, ACTION,  
			   EVENTNO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE,
			   BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE,RENEWALTYPE, INSTRUCTIONSLOADED,
			   IPODELAY,APPLICANTDELAY,OFFICEID,USERID,IDENTITYID,CASELOGSTAMP,PROPERTYLOGSTAMP)

	select	distinct C.CASEID, C.STATUSCODE, P.RENEWALSTATUS, REPORTTOTHIRDPARTY,C.PREDECESSORID, null, 
			 null, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE,
			 P.BASIS, P.REGISTEREDUSERS, C.LOCALCLIENTFLAG, P.EXAMTYPE, P.RENEWALTYPE, 0,isnull(C.IPODELAY,0),
			 isnull(C.APPLICANTDELAY,0),C.OFFICEID,"+
			 CASE WHEN(@psSqlUser is null) THEN 'SYSTEM_USER,' ELSE "'"+@psSqlUser+"'," END+
			 CASE WHEN(@pnUserIdentityId is null) THEN 'NULL' ELSE convert(varchar,@pnUserIdentityId) END+",C.LOGDATETIMESTAMP,P.LOGDATETIMESTAMP
	from CASES C
	left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
	left join PROPERTY P    on (P.CASEID=C.CASEID)"

-- Build the WHERE clause based on the parameters passed to the procedure
-- If IRN or CASEID is passed then no additional parameters need to be looked at.

if @psIRN is not null
begin
	set @sWhereClause="	where C.IRN='"+@psIRN+"'"
end
else if @pnCaseid is not null
begin
	set @sWhereClause="	where C.CASEID="+convert(nvarchar,@pnCaseid)
end
else begin
	if @psOfficeId is not null
	begin
		if @sWhereClause is null
			set @sWhereClause="	where C.OFFICEID in ("+@psOfficeId+")"
		else
			set @sWhereClause=@sWhereClause+char(10)+"	and C.OFFICEID in ("+@psOfficeId+")"
	end

	if @psPropertyType is not null
	begin
		if @pnExcludeProperty=1
		begin
			if @sWhereClause is null
				set @sWhereClause="	where (C.PROPERTYTYPE is null OR C.PROPERTYTYPE<>'"+@psPropertyType+"')"
			else
				set @sWhereClause=@sWhereClause+char(10)+"	and (C.PROPERTYTYPE is null OR C.PROPERTYTYPE<>'"+@psPropertyType+"')"
		End
		else begin
			if @sWhereClause is null
				set @sWhereClause="	where C.PROPERTYTYPE='"+@psPropertyType+"'"
			else
				set @sWhereClause=@sWhereClause+char(10)+"	and C.PROPERTYTYPE='"+@psPropertyType+"'"
		End
	end
	
	if @psCountryCode is not null
	begin
		if @pnExcludeCountry=1
		begin
			if @sWhereClause is null
				set @sWhereClause="	where (C.COUNTRYCODE is null OR C.COUNTRYCODE<>'"+@psCountryCode+"')"
			else
				set @sWhereClause=@sWhereClause+char(10)+"	and (C.COUNTRYCODE is null OR C.COUNTRYCODE<>'"+@psCountryCode+"')"
		End
		else begin
			if @sWhereClause is null
				set @sWhereClause="	where C.COUNTRYCODE='"+@psCountryCode+"'"
			else
				set @sWhereClause=@sWhereClause+char(10)+"	and C.COUNTRYCODE='"+@psCountryCode+"'"
		End
	end

	if @psCaseType is not null
	begin
		if @sWhereClause is null
			set @sWhereClause="	where C.CASETYPE='"+@psCaseType+"'"
		else
			set @sWhereClause=@sWhereClause+char(10)+"	and C.CASETYPE='"+@psCaseType+"'"
	end

	if @psCaseCategory is not null
	begin
		if @sWhereClause is null
			set @sWhereClause="	where C.CASECATEGORY='"+@psCaseCategory+"'"
		else
			set @sWhereClause=@sWhereClause+char(10)+"	and C.CASECATEGORY='"+@psCaseCategory+"'"
	end
	
	if @psSubtype is not null
	begin
		if @sWhereClause is null
			set @sWhereClause="	where C.SUBTYPE='"+@psSubtype+"'"
		else
			set @sWhereClause=@sWhereClause+char(10)+"	and C.SUBTYPE='"+@psSubtype+"'"
	end
	
	--  If NAMENO or NAMETYPE are passed then a JOIN on the CASENAME table is required

	if @pnNameNo   is not null
	or @psNameType is not null
	begin
		set @sInsertString = @sInsertString+char(10)+"	     join CASENAME CN   on (CN.CASEID=C.CASEID"
	
		if @pnNameNo is not null
		begin
			set @sInsertString=@sInsertString+" and CN.NAMENO="+convert(nvarchar,@pnNameNo)
		end
	
		if @psNameType is not null
		begin
			set @sInsertString=@sInsertString+" and CN.NAMETYPE=N'"+@psNameType+"'"	-- RFC11985
		end
		
		set @sInsertString = @sInsertString+")"
	
	end
end

if @sWhereClause is null
	set @sWhereClause="	where (S.STATUSCODE is null or S.POLICERENEWALS+S.POLICEEXAM+S.POLICEOTHERACTIONS>0)"
else
	set @sWhereClause=@sWhereClause+char(10)+"	and (S.STATUSCODE is null or S.POLICERENEWALS+S.POLICEEXAM+S.POLICEOTHERACTIONS>0)"

-- If Policing is to be run for a specific EVENTNO then only bring back Cases where there exists an OpenAction
-- that has an associated EventControl for the Event and the Event has not already occurred for the Case.

if @pnEventNo is not NULL
begin
	set @sWhereClause=@sWhereClause	+char(10)+"	and exists"
					+char(10)+"	(select * from OPENACTION OA1"
					+char(10)+"	      join EVENTCONTROL EC	on (EC.CRITERIANO=OA1.CRITERIANO)"
					+char(10)+"	      join ACTIONS A		on (A.ACTION     =OA1.ACTION)"
					+char(10)+"	 left join CASEEVENT CE		on (CE.CASEID    =OA1.CASEID"
					+char(10)+"	 				and CE.EVENTNO   =EC.EVENTNO"
					+char(10)+"	 				and CE.CYCLE     =CASE WHEN (A.NUMCYCLESALLOWED>1) THEN OA1.CYCLE ELSE CE.CYCLE END)"
					+char(10)+"	 where OA1.CASEID=C.CASEID"
					+char(10)+"	 and   OA1.POLICEEVENTS=1"
					+char(10)+"	 and   EC.EVENTNO="+convert(nvarchar,@pnEventNo)

	If @pbRecalcEventDate=1
	begin
		Set @sWhereClause=@sWhereClause+char(10)+"	 and  (EC.RECALCEVENTDATE=1 or isnull(CE.OCCURREDFLAG,0)=0)"
	end
	else begin
		Set @sWhereClause=@sWhereClause+char(10)+"	 and   isnull(CE.OCCURREDFLAG,0)=0"
	end

	if  @psAction is not null
	begin
		if @pnExcludeAction=1
		begin
			set @sWhereClause=@sWhereClause
					+char(10)+"	 and   OA1.ACTION<>'"+@psAction+"')"
		end
		else begin
			set @sWhereClause=@sWhereClause
					+char(10)+"	 and   OA1.ACTION='"+@psAction+"')"
		end
	end
	else begin
		set @sWhereClause=@sWhereClause+")"
	end
	
end
else if @psAction is null
begin
	-- Only bring back cases that have an OpenAction row eligible for Policing

	set @sWhereClause=@sWhereClause+char(10)+"	and exists (select * from OPENACTION OA where OA.CASEID=C.CASEID and OA.POLICEEVENTS=1)"
end
else begin
	if @pnExcludeAction=1
	begin
		set @sWhereClause=@sWhereClause+char(10)+"	and exists (select * from OPENACTION OA where OA.CASEID=C.CASEID and OA.POLICEEVENTS=1 and OA.ACTION<>'"+@psAction+"'"
	End
	else begin
		set @sWhereClause=@sWhereClause+char(10)+"	and exists (select * from OPENACTION OA where OA.CASEID=C.CASEID and OA.POLICEEVENTS=1 and OA.ACTION='"+@psAction+"'"
	End

	if @pdtDateOfAct is null
	begin
		set @sWhereClause=@sWhereClause+")"
	end
	else begin
		set @sWhereClause=@sWhereClause+" and OA.DATEFORACT='"+convert(nvarchar,@pdtDateOfAct,112)+"')"
	end
end

-- Append the WHERE clause to the rest of the INSERT statement.

If @sWhereClause is not null
begin
	set @sInsertString = @sInsertString + nchar(10)+ @sWhereClause
end

-- Now execute the dynamically created Insert.

If @ErrorCode=0
begin
	Execute @ErrorCode = sp_executesql @sInsertString
	Set @pnRowCount=@@Rowcount
end
If @ErrorCode=0
and @pnRowCount>0
Begin
	Execute @ErrorCode=ip_PoliceGetEventsForTempTable @pnDebugFlag
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetOpenActions',0,1,@sTimeStamp ) with NOWAIT
End

-- Load #TEMPOPENACTION with the details of the Actions to be processed. 
If  @ErrorCode=0
Begin
	execute @ErrorCode = ip_PoliceGetActions	@nOpenActionCount OUTPUT,
							@pnDebugFlag,
							@pdtDateOfAct,
							@psAction,
							@pnEventNo,
							@pnExcludeAction,
							@pnCriteriaFlag,
							@pnDueDateFlag,
							@pnCalcReminderFlag
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetOpenActions  to public
go
