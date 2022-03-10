-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_ListPortfolioProblems
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_ListPortfolioProblems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ListPortfolioProblems.'
	drop procedure dbo.cpa_ListPortfolioProblems
end
print '**** Creating procedure dbo.cpa_ListPortfolioProblems...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cpa_ListPortfolioProblems
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psPropertyType			nvarchar(2)	= null,	-- Include/Exclude based on next parameter
	@pbPropertyTypeExcluded		tinyint		= 0,
	@pbNoMatchingCase		tinyint		= 0,
	@pbCPAReportIsOff		tinyint		= 0,
	@pbWrongStandingInstruction	tinyint		= 0,
	@pbMissingStatus		tinyint		= 0,	
	@psOfficeCPACode		nvarchar(3)	=null,
	@pbCaseNotOnPortfolio		tinyint		= 0

	
AS
-- PROCEDURE :	cpa_ListPortfolioProblems
-- VERSION :	9
-- DESCRIPTION:	Compare the most recent CPA Portfolio against the Inprotech database and report
--		any problems
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21/06/2002	MF			Procedure created
-- 26/02/2003	MF	8459		Change reference from CPADATARECEIVED to CPAPORTFOLIO
-- 05 Aug 2004	AB	8035		Add collate database_default to temp table definitions
-- 30 Mar 2005	MF	10481	4	An option now exists to allow the CASEID to be recorded in the CPA database
--					instead of the IRN which may exceed the 15 character CPA limit.  This change will
--					consider this Site Control and join on CASEID when appropriate.
-- 09 May 2005	MF	10731	5	Allow cases to be filtered by Office User Code.
-- 05 Jan 2006	MF	12178	6	Extend the report to include an option to report the Cases that appear 
--					to be valid to report to CPA but are not on the current Portfolio.
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Jul 2010	MF	18758	8	Increase the column size of Instruction Type to allow for expanded list.
-- 05 Dec 2011	LP	R11070	9	Default standing instruction from Office Entity, if available, before falling back to HomeName


set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

create table #TEMPINSTRUCTIONS 
		(	INSTRUCTIONCODE		smallint not null,
			INSTRUCTIONTYPE		nvarchar(3)  collate database_default null, 
			NAMETYPE		varchar(3)   collate database_default null, 
			RESTRICTEDBYTYPE	varchar(3)   collate database_default null
		)


create table #TEMPCASEINSTRUCTIONS 
		(	CASEID			int	 not null,
			INSTRUCTIONCODE		smallint not null
		)

create table #TEMPGETINSTRUCTIONS 
		(	CASEID			int	 not null	PRIMARY KEY,
			NOTONPORTFOLIO		bit	 not null,
			OFFICEID		int,
			OFFICENAMENO		int
		)

DECLARE	@ErrorCode		int,
	@nHomeNameno		int,
	@bCaseIdFlag		bit,
	@sInstructions		nchar(9),
	@sInstructionType	nvarchar(3),
	@sInstNameType		nvarchar(3),
	@sRestrictedByType	nvarchar(3),
	@sSQL1			nvarchar(1000),
	@sSQL2			nvarchar(1000),
	@sSQL3			nvarchar(1000),
	@sSQL4			nvarchar(1000),
	@sSQL5			nvarchar(1000),
	@sSQLString		nvarchar(4000),
	@sWhere			nvarchar(1000),
	@sOfficeJoin		nvarchar(100),
	@sOrderBy		nvarchar(100)

set @ErrorCode=0

-- Get the SiteControl to see if the CASEID is being used as an alternative to
-- the IRN as a unique identifier of the Case.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bCaseIdFlag=S.COLBOOLEAN
	from SITECONTROL S
	where S.CONTROLID='CPA Use CaseId as Case Code'"

	exec sp_executesql @sSQLString,
				N'@bCaseIdFlag		bit	OUTPUT',
				  @bCaseIdFlag=@bCaseIdFlag	OUTPUT
End

-- Construct the WHERE clause

if @psPropertyType is not null
begin
	if @pbPropertyTypeExcluded = 1
		set @sWhere = char(10)+"Where C.PROPERTYTYPE <> '"+@psPropertyType+"'"
	else
		set @sWhere = char(10)+"Where C.PROPERTYTYPE =  '"+@psPropertyType+"'"

end
else begin
	set @sWhere = char(10)+"Where C.CASEID=C.CASEID"
end

If @psOfficeCPACode is not null
Begin
	Set @sWhere=@sWhere+char(10)+"and OFC.CPACODE='"+@psOfficeCPACode+"'"

	Set @sOfficeJoin="join OFFICE OFC on (OFC.OFFICEID=C.OFFICEID)"
End

-- If Cases that appear to be reportable to CPA and are not on the Portfolio 
-- then they will initially be extracted into a temporary table.  This is because we need to
-- also extract the Standing Instruction associated with the Case as this is also used to 
-- determine if the Case is reportable.
If @pbCaseNotOnPortfolio=1
begin
	Set @sSQLString="
	insert into #TEMPGETINSTRUCTIONS(CASEID, NOTONPORTFOLIO, OFFICEID, OFFICENAMENO)
	select distinct C.CASEID, 1, C.OFFICEID, O.ORGNAMENO
	from CASES C
	left join STATUS S         on (S.STATUSCODE=C.STATUSCODE)
	left join PROPERTY P       on (P.CASEID=C.CASEID)
	left join STATUS S1        on (S1.STATUSCODE=P.RENEWALSTATUS)
	left join CPAPORTFOLIO CPA on (CPA.AGENTCASECODE=C.IRN)
	left join SITECONTROL SC   on (SC.CONTROLID='CPA Date-Start')
	left join SITECONTROL SC1  on (SC1.CONTROLID='CPA Date-Expiry')
	left join CASEEVENT ST     on (ST.CASEID=C.CASEID
			 	   and ST.EVENTNO=SC.COLINTEGER
				   and ST.CYCLE=1)
	left join CASEEVENT CE     on (CE.CASEID=C.CASEID
				   and CE.EVENTNO=isnull(SC1.COLINTEGER,-12))
	left join OFFICE O	   on (O.OFFICEID = C.OFFICEID)"+char(10)
	+char(9)+@sOfficeJoin+char(10)
	+char(9)+@sWhere+"
	and  C.REPORTTOTHIRDPARTY=1
	and  C.STOPPAYREASON is null
	and  isnull(S.LIVEFLAG,1)=1
	and  isnull(S1.LIVEFLAG,1)=1
	-- Either no expiry date or it is in the future
	and (CE.CASEID is null OR isnull(CE.EVENTDATE,CE.EVENTDUEDATE)>getdate())
	-- New cases for CPA will not already exist in CPAPORTFOLIO or if the
	-- case on the Portfolio is not live then the CPA Start Pay date to be
	-- reported must be greater than or equal to the 1st January for the 
	-- year of the Portfolio
	and (CPA.AGENTCASECODE is null
	 OR (CPA.STATUSINDICATOR<>'L' AND
	     isnull(ST.EVENTDATE,ST.EVENTDUEDATE)>=
	     cast('01/01/'
		 +cast(YEAR(CPA.DATEOFPORTFOLIOLST) as nvarchar) as datetime)))"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Load the live cases on the Portfolio into a temporary table so we can
-- extract the standing instruction.  This is required if incorrect standing
-- instructions are being reported on.
If @pbWrongStandingInstruction=1
begin
	Set @sSQLString="
	insert into #TEMPGETINSTRUCTIONS(CASEID, NOTONPORTFOLIO)
	select distinct C.CASEID, 0
	from CASES C
	join CPAPORTFOLIO CPA on (CPA.AGENTCASECODE=C.IRN
			      and CPA.STATUSINDICATOR='L')
	left join #TEMPGETINSTRUCTIONS T on (T.CASEID=C.CASEID)"+char(10)
	+char(9)+@sOfficeJoin+char(10)
	+char(9)+@sWhere+"
	and  T.CASEID is null"

	exec @ErrorCode=sp_executesql @sSQLString
end

-- If Cases on the Portfolio are to be reported if they do not have an appropriate Standing Instruction
-- or if reporting on Cases missing from the Portfolio is required
-- then first determine what Standing Instructions are required.

if @pbWrongStandingInstruction=1
or @pbCaseNotOnPortfolio=1
begin
	Set @sSQLString="
	insert into #TEMPINSTRUCTIONS (INSTRUCTIONCODE, INSTRUCTIONTYPE, NAMETYPE, RESTRICTEDBYTYPE)
	select distinct I.INSTRUCTIONCODE, I.INSTRUCTIONTYPE, T. NAMETYPE, T.RESTRICTEDBYTYPE
	from EVENTCONTROL EC
	join INSTRUCTIONS I	on (I.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
	join INSTRUCTIONFLAG F	on (F.INSTRUCTIONCODE=I.INSTRUCTIONCODE
				and F.FLAGNUMBER     =EC.FLAGNUMBER)
	join INSTRUCTIONTYPE T	on (T.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
	where EC.SETTHIRDPARTYON=1"

	exec @ErrorCode=sp_executesql @sSQLString

	-- Get the Home NameNo

	If @ErrorCode = 0
	Begin
		Select @nHomeNameno=S.COLINTEGER
		from	SITECONTROL S
		where	S.CONTROLID='HOMENAMENO'

		Select @ErrorCode=@@Error
	End

	-- Extract the possible set of Instruction Types that may be required.

	If @ErrorCode = 0
	Begin
		select @sInstructions =
			min(	convert(nchar(3), isnull(I.INSTRUCTIONTYPE, space(3)))+ 
				convert(nchar(3), isnull(I.NAMETYPE, space(3)))+ 
				convert(nchar(3), isnull(I.RESTRICTEDBYTYPE, space(3))))
		from #TEMPINSTRUCTIONS I

		Select @ErrorCode=@@Error
	End

	--RFC11070: Get office details for cases
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Insert into #TEMPCASEOFFICE
		select C.CASEID, C.OFFICEID, O.ORGNAMENO
		from #TEMPGETINSTRUCTIONS T
		join CASES C on (C.CASEID = T.CASEID)
		left join OFFICE O on (O.OFFICEID = C.OFFICEID)"
		
		exec @ErrorCode=sp_executesql @sSQLString	
	End

	-- Loop through each required InstructionType and get the best one for each case to be processed.

	WHILE @sInstructions is not null
	 and  @ErrorCode=0
	BEGIN

		set @sInstructionType	= substring(@sInstructions, 1,3)
		set @sInstNameType	= substring(@sInstructions, 4,3)
		set @sRestrictedByType	= substring(@sInstructions, 7,3)

		-- For performance reasons if there is no RestrictedByType against the particular 
		-- Instruction code being extracted then use simplified version of the Select that gets
		-- the Standing Instruction as it will perform much faster

		IF @sRestrictedByType is NULL 
		OR @sRestrictedByType=space(3)
		BEGIN
			set @sSQLString="
			insert into #TEMPCASEINSTRUCTIONS(CASEID,INSTRUCTIONCODE)
			SELECT	CI.CASEID, CI.COMPOSITECODE
				FROM
						-- To determine the best InstructionCode a weighting is	
						-- given based on the existence of characteristics	
						-- found in the NAMEINSTRUCTIONS row.  The MAX function 
						-- returns the highest weighting to which the required	
						-- INSTRUCTIONCODE has been concatenated.		
				(SELECT C.CASEID, substring(max (
					CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
				 	CASE WHEN(NI.NAMENO		= CN.NAMENO) THEN '1' ELSE '0' END +
				 	CASE WHEN(NI.NAMENO = T.OFFICENAMENO) THEN '1' ELSE '0' END + 
					CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +					
					convert(nvarchar(5),NI.INSTRUCTIONCODE)),6,5) as COMPOSITECODE
				FROM	CASES C
				join	#TEMPGETINSTRUCTIONS T on (T.CASEID = C.CASEID)	
				join	INSTRUCTIONS	  I on (I.INSTRUCTIONTYPE = @sInstructionType)
				left join	CASENAME 	 CN  on ( CN.CASEID=C.CASEID and CN.NAMETYPE=@sInstNameType)
				join		NAMEINSTRUCTIONS NI  on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
								     and (NI.NAMENO=CN.NAMENO 		 OR NI.NAMENO=@nHomeNameno OR NI.NAMENO = T.OFFICENAMENO)
								     and (NI.CASEID=C.CASEID 		 OR NI.CASEID 		is NULL) 
								     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
								     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
				)			
				group by C.CASEID, I.INSTRUCTIONTYPE) CI"
		END
		ELSE BEGIN
			set @sSQLString="
			insert into #TEMPCASEINSTRUCTIONS(CASEID,INSTRUCTIONCODE)
			SELECT	CI.CASEID, CI.COMPOSITECODE
				FROM
						-- To determine the best InstructionCode a weighting is	
						-- given based on the existence of characteristics	
						-- found in the NAMEINSTRUCTIONS row.  The MAX function 
						-- returns the highest weighting to which the required	
						-- INSTRUCTIONCODE has been concatenated.		

				(SELECT C.CASEID as CASEID, substring(max (
					CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
				 	CASE WHEN(NI.NAMENO		= CN.NAMENO) THEN '1' ELSE '0' END +
					CASE WHEN(NI.NAMENO	      = T.OFFICENAMENO) THEN '1' ELSE '0' END + 
					CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
					CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
					convert(nvarchar(5),NI.INSTRUCTIONCODE)),7,5) as COMPOSITECODE
				FROM CASES C
				join #TEMPGETINSTRUCTIONS T on (T.CASEID=C.CASEID)	
				join INSTRUCTIONS	  I on (I.INSTRUCTIONTYPE = @sInstructionType)
				left join	CASENAME 	 CN  on ( CN.CASEID=C.CASEID and CN.NAMETYPE=@sInstNameType)
				left join 	CASENAME	 CN1 on ( CN1.CASEID=C.CASEID 
								     and  CN1.NAMETYPE=@sRestrictedByType
								     and  CN1.SEQUENCE=(select min(SEQUENCE)
											from CASENAME CN2
											where CN2.CASEID  =C.CASEID
											and   CN2.NAMETYPE=CN1.NAMETYPE
											and   CN2.EXPIRYDATE is null))
				join		NAMEINSTRUCTIONS NI  on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
								     and (NI.NAMENO=CN.NAMENO 		 OR NI.NAMENO=@nHomeNameno OR NI.NAMENO=T.OFFICENAMENO)
								     and (NI.CASEID=C.CASEID 		 OR NI.CASEID 		is NULL) 
								     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
								     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
								     and (NI.RESTRICTEDTONAME=CN1.NAMENO OR NI.RESTRICTEDTONAME is NULL) )
				group by C.CASEID, I.INSTRUCTIONTYPE) CI"
		END

		Set @sSQLString=@sSQLString

		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameno		int,
					@sInstructionType	nvarchar(3),
					@sInstNameType		nvarchar(3),
					@sRestrictedByType	nvarchar(3)',
					@nHomeNameno,
					@sInstructionType,
					@sInstNameType,
					@sRestrictedByType


		If @ErrorCode=0
		Begin
			select @sInstructions =
				min(	
				convert(nchar(3), isnull(I.INSTRUCTIONTYPE, space(3)))+
				convert(nchar(3), isnull(I.NAMETYPE, space(3)))+ 
				convert(nchar(3), isnull(I.RESTRICTEDBYTYPE, space(3))))
			from #TEMPINSTRUCTIONS I
			where  (convert(nchar(3), isnull(I.INSTRUCTIONTYPE, space(3)))+
				convert(nchar(3), isnull(I.NAMETYPE, space(3)))+ 
				convert(nchar(3), isnull(I.RESTRICTEDBYTYPE, space(3))))
				> @sInstructions

			Select @ErrorCode=@@Error
		End
	END -- End of WHILE loop
End

-- Remove any Cases that are not on the Portfolio that do not have a Standing Instruction
-- that indicates that the Case should be with CPA.  These Cases are not supposed to be on 
-- the Portfolio so therefore do not need to be reported.

If @pbCaseNotOnPortfolio=1
and @ErrorCode=0
begin
	Set @sSQLString="
	delete #TEMPGETINSTRUCTIONS
	from #TEMPGETINSTRUCTIONS T
	Where T.NOTONPORTFOLIO=1
	and not exists
	(Select * from #TEMPCASEINSTRUCTIONS TC
	 join #TEMPINSTRUCTIONS TI on TI.INSTRUCTIONCODE=TC.INSTRUCTIONCODE
	 where TC.CASEID=T.CASEID)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @pbWrongStandingInstruction=1
begin
	If @ErrorCode=0
	begin
		set @sSQL1=
		         "select distinct 1 as ErrorType,"+ 
		char(10)+"	 C.IRN, "+ 
		char(10)+"	 NULL as CPAAgentCaseCode,"+ 
		char(10)+"	 C.CURRENTOFFICIALNO as OfficialNo,"+ 
		char(10)+"	 S.INTERNALDESC as CaseStatus,"+ 
		char(10)+"	 R.INTERNALDESC as RenewalStatus"+
		char(10)+"from CASES C"+
		char(10)+@sOfficeJoin+
		char(10)+"left join STATUS S    on (S.STATUSCODE=C.STATUSCODE)"+
		char(10)+"join CPAPORTFOLIO CPA on (CPA.CASEID=C.CASEID"+
		char(10)+"                      and CPA.STATUSINDICATOR = 'L')" + 
		char(10)+"join PROPERTY P       on (P.CASEID=C.CASEID)"+
		char(10)+"left join STATUS R    on (R.STATUSCODE=P.RENEWALSTATUS)"+
		@sWhere + 
		char(10)+"and not exists"+
		char(10)+"(select * "+
		char(10)+" from #TEMPCASEINSTRUCTIONS TC"+
		char(10)+" join #TEMPINSTRUCTIONS TI on (TI.INSTRUCTIONCODE=TC.INSTRUCTIONCODE)"+
		char(10)+" where TC.CASEID=C.CASEID)"
	end	
end

-- Report Cases on the current CPA Portfolio where the Case is not flagged as CPA Reportable

If @pbCPAReportIsOff = 1
begin
	If @pbWrongStandingInstruction=1
		set @sSQL2="select 2, C.IRN, NULL, C.CURRENTOFFICIALNO, S.INTERNALDESC, R.INTERNALDESC"
	else
		set @sSQL2=      "select distinct 2 as ErrorType,"+ 
			char(10)+"	 C.IRN, "+ 
			char(10)+"	 NULL as CPAAgentCaseCode,"+ 
			char(10)+"	 C.CURRENTOFFICIALNO as OfficialNo,"+ 
			char(10)+"	 S.INTERNALDESC as CaseStatus,"+ 
			char(10)+"	 R.INTERNALDESC as RenewalStatus"

	set @sSQL2=@sSQL2+
	char(10)+"from CASES C"+
	char(10)+@sOfficeJoin+
	char(10)+"left join STATUS S       on (S.STATUSCODE=C.STATUSCODE)"+
	char(10)+"join CPAPORTFOLIO CPA on (CPA.CASEID=C.CASEID"+
	char(10)+"                      and CPA.STATUSINDICATOR = 'L')" + 
	char(10)+"join PROPERTY P          on (P.CASEID=C.CASEID)"+
	char(10)+"left join STATUS R       on (R.STATUSCODE=P.RENEWALSTATUS)"+
	@sWhere +
	char(10)+"and (C.REPORTTOTHIRDPARTY=0 OR C.REPORTTOTHIRDPARTY is null)"
End

-- Report Cases on the current CPA Portfolio that do not match a Case on InProma

If @pbNoMatchingCase =1
begin

	
	If @pbWrongStandingInstruction=1
	or @pbCPAReportIsOff=1
		set @sSQL3="select distinct 3, NULL, CPA.AGENTCASECODE, isnull(CPA.REGISTRATIONNO, isnull(CPA.PUBLICATIONNO, CPA.APPLICATIONNO)), NULL, NULL"
	else
		set @sSQL3=      "select 3 as ErrorType,"+ 
			char(10)+"	 NULL as IRN, "+ 
			char(10)+"	 CPA.AGENTCASECODE as CPAAgentCaseCode,"+ 
			char(10)+"	 isnull(CPA.REGISTRATIONNO, isnull(CPA.PUBLICATIONNO, CPA.APPLICATIONNO)) as OfficialNo,"+ 
			char(10)+"	 NULL as CaseStatus,"+ 
			char(10)+"	 NULL as RenewalStatus"

	set @sSQL3=@sSQL3+
	char(10)+"from CPAPORTFOLIO CPA"+
	char(10)+"left join CASES C on (CPA.AGENTCASECODE="+CASE WHEN(@bCaseIdFlag=1) THEN "CAST(C.CASEID as varchar(15)))" ELSE "C.IRN)" END+
	char(10)+"Where CPA.STATUSINDICATOR = 'L'"+
	char(10)+"and C.CASEID is null "
End

-- Report Cases on the current CPA Portfolio where the Case does not have a Status

If @pbMissingStatus = 1
begin
	-- Note that filtering by Office or Property Type will not apply against this option as the
	-- filtering works from the Cases row associated with the Portfolio and this exception is 
	-- reporting Portfolio entries where there is no Case found.
	If @pbWrongStandingInstruction=1
	or @pbCPAReportIsOff=1
	or @pbNoMatchingCase=1
		set @sSQL4="select 4, C.IRN, NULL, C.CURRENTOFFICIALNO, S.INTERNALDESC, R.INTERNALDESC"
	else
		set @sSQL4=      "select distinct 4 as ErrorType,"+ 
			char(10)+"	 C.IRN, "+ 
			char(10)+"	 NULL as CPAAgentCaseCode,"+ 
			char(10)+"	 C.CURRENTOFFICIALNO as OfficialNo,"+ 
			char(10)+"	 S.INTERNALDESC as CaseStatus,"+ 
			char(10)+"	 R.INTERNALDESC as RenewalStatus"

	set @sSQL4=@sSQL4+
	char(10)+"from CASES C"+
	char(10)+@sOfficeJoin+
	char(10)+"left join STATUS S       on (S.STATUSCODE=C.STATUSCODE)"+
	char(10)+"join CPAPORTFOLIO CPA on (CPA.CASEID=C.CASEID"+
	char(10)+"                      and CPA.STATUSINDICATOR = 'L')" + 
	char(10)+"join PROPERTY P          on (P.CASEID=C.CASEID)"+
	char(10)+"left join STATUS R       on (R.STATUSCODE=P.RENEWALSTATUS)"+
	@sWhere +
	char(10)+"and S.STATUSCODE is null "
End

-- Report Cases that appear valid to report to CPA but are not on the CPA Portfolio

If @pbCaseNotOnPortfolio = 1
begin
	If @pbWrongStandingInstruction=1
	or @pbCPAReportIsOff=1
	or @pbNoMatchingCase=1
	or @pbMissingStatus =1
		set @sSQL5="select 5, C.IRN, NULL, C.CURRENTOFFICIALNO, S.INTERNALDESC, R.INTERNALDESC"
	else
		set @sSQL5=      "select distinct 5 as ErrorType,"+ 
			char(10)+"	 C.IRN, "+ 
			char(10)+"	 NULL as CPAAgentCaseCode,"+ 
			char(10)+"	 C.CURRENTOFFICIALNO as OfficialNo,"+ 
			char(10)+"	 S.INTERNALDESC as CaseStatus,"+ 
			char(10)+"	 R.INTERNALDESC as RenewalStatus"

	set @sSQL5=@sSQL5+
	char(10)+"from CASES C"+
	char(10)+"left join STATUS S       on (S.STATUSCODE=C.STATUSCODE)"+
	char(10)+"join #TEMPGETINSTRUCTIONS T on (T.CASEID=C.CASEID)"+
	char(10)+"join PROPERTY P          on (P.CASEID=C.CASEID)"+
	char(10)+"left join STATUS R       on (R.STATUSCODE=P.RENEWALSTATUS)"+
	char(10)+"where T.NOTONPORTFOLIO=1"
End


-- Now that the individual queries have been constructed they are to be combined using UNION.

If @sSQL1 is not null
begin
	set @sSQLString=@sSQL1

	if @sSQL2 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL2
	end

	if @sSQL3 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL3
	end

	if @sSQL4 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL4
	end

	if @sSQL5 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL5
	end
end
else if @sSQL2 is not null
begin
	set @sSQLString=@sSQL2

	if @sSQL3 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL3
	end

	if @sSQL4 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL4
	end

	if @sSQL5 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL5
	end
end
else if @sSQL3 is not null
begin
	set @sSQLString=@sSQL3

	if @sSQL4 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL4
	end

	if @sSQL5 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL5
	end
end
else if @sSQL4 is not null
begin
	set @sSQLString=@sSQL4

	if @sSQL5 is not null
	begin
		set @sSQLString=@sSQLString+char(10)+"UNION ALL"+char(10)+@sSQL5
	end
end
else begin
	set @sSQLString=@sSQL5
End

set @sOrderBy="order by 1, 2, 3, 4"

exec (@sSQLString+@sOrderBy)
select  @pnRowCount=@@Rowcount,
	@ErrorCode=@@Error

RETURN @ErrorCode
go

grant execute on dbo.cpa_ListPortfolioProblems  to public
go
