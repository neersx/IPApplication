-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_InsertCasesToSend
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_InsertCasesToSend]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_InsertCasesToSend.'
	drop procedure dbo.cpa_InsertCasesToSend
end
print '**** Creating procedure dbo.cpa_InsertCasesToSend...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_InsertCasesToSend 
		@pnCaseId 		int		=null, 
		@psPropertyType		nvarchar(2)	=null,
		@pbNotProperty		bit		=0,
		@pbNewCases		bit		=0,
		@pbChangedCases		bit		=0,
		@pbCheckInstruction	bit		=1,
		@psOfficeCPACode	nvarchar(3)	=null
as
-- PROCEDURE :	cpa_InsertCasesToSend
-- VERSION :	31
-- DESCRIPTION:	Determine what cases are to be sent to CPA.
--		The standing instructions for the cases will be determined so that
--		only those cases with the appropriate standing instructions as 
-- 		listed in a SiteControl will be sent to CPA.
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20/03/2002	MF			Procedure Created
-- 24/09/2002	MF			When CPASEND is empty then initialise the Cases to send from the current
--					CPAPortfolio of live cases.  This will initialise the database to match 
-- 					the Cases that CPA are already aware of.
-- 25/09/2002	MF			Make certain that CPAPortfolio has a StatusIndicator = 'L' when initialising
--					for the Cases to send to CPA
-- 04/02/2003	MF	8436		Add a new option to make the checking of Standing Instructions an option.
-- 21/02/2003	MF	8442		Change column name from StatusFlag to StatusIndicator
-- 04/07/2003	MF	8953		Changed cases with a Stop Pay Reason should only be reported if the Case is
--					either not showing on the Portfolio or has a Live status.  Changed cases without
--					a Stop Pay Reason should only be reported if they are currently live.
-- 11 Jul 2003	MF	8953		Revisit this modificiation due to failure in testing.
-- 17 Jul 2003	MF	8994	6	A New Case is determined by the fact that it is not on the CPA Portfolio already.
-- 11 Feb 2004	MF	9688	7	Do not send a new Case if its Expiry Date is already in the past.
-- 28 Apr 2004	MF	9968	8	Allow Cases that are currently marked as dead on the CPA Portfolio to be sent
--					to CPA if they are live on Inpro and have a CPA Start Pay date that is greater 
--					than or equal to the date the last batch was sent to CPA.
-- 05 Aug 2004	AB	8035	9	Add collate database_default to temp table definitions
-- 04 Jan 2005	MF	10829	10	Cases with no Status are to be considered as Live when extracting.
-- 07 Feb 2005	MF	10978	11	Get the Expiry EventNo from the SiteControl "CPA DATE-EXPIRY"
-- 06 May 2005	MF	10731	12	Allow cases to be extracted by Office User Code.
-- 11 May 2005	MF	10731	13	Revisit because of case sensitive problem
-- 17 May 2005	MF	11384	14	Do not insist on  Start Pay Date being after the Portfolio date when
--					new Cases are being extracted.
-- 15 Jun 2005	MF	10731	15	Revisit to change Office User Code to Office CPA Code.
-- 04 Jan 2006	MF	12173	16	A Case that exists on the CPA Portfolio is to be treated as an amended Case
--					even if there is no record of the Case having actually been sent from Inprotech.
-- 23 Jan 2006	MF	12173	17	Revisit.  Remove check that Case is responsibility of the Agent.
-- 28 Jul 2006	MF	13099	18	A case may be reported to CPA as a result of the IRN being changed.  These Cases
--					should be reported as an amend so check for the existence by using the CASEID
--					which will not have changed.
-- 08 Nov 2006	MF	13777	19	If the Case is live on the Portfolio however it has a Stop Pay Reason on the
--					Inprotech database then it must be reported irrespective of its standing 
--					instruction or report to third party flag.
-- 09 Nov 2006	MF	13777	19a	Revisit. Remove ansi warning.
-- 10 Nov 2006	MF	13777	20	Further feedback. Allow for the possibility of multiple entries for the one
--					case existing in the portfolio.  If any of these entries are not live then 
--					assume that CPA have correctly updated the case and do not report the stop 
--					pay reason.
-- 13 Dec 2006	MF	14014	21	Initialisation batch should match against the loaded CPA Portfolio using the
--					CaseId rather than the IRN so as to be consistent with other parts of the
--					interface.
-- 28 Mar 2007	MF	14630	22	Conversion error on datetime field occurring when CPAPORTFOLIO is empty.  Need
--					to handle the possibility of null in CPAPORTFOLIO.DATEOFPORTFOLIOLST
-- 11 Dec 2008	MF	17136	23	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 15 Jan 2009	MF	17295	24	Improve CPA Interface performance for large batches by modifying the LEFT JOIN on the
--					derived table when extracting Standing Instructions. This works on the assumption that the
--					NameType associated with the Instruction must exist.
-- 17 Feb 2009	MF	17405	25	Extract of Cases by Office is extracting Cases into CPASEND that are not limited to the selected office.
-- 23 Feb 2009	MF	17295	26	Revisit. Load #TEMPCASENAME with CaseNames to use and back fill using HOMENAMENO if no
--					name for a given NameType exists.
-- 18 Dec 2009	AvdA	17347	27	If site control CPA Consider All CPA Cases is set on then consider all cases 
--									with REPORTTOTHIRDPARTY on (or with a new STOPPAYREASON) rather than those in CPAUPDATE only.
-- 18 Dec 2009	AvdA	18297	28	Implement new cs_GetStandingInstructionsBulk to improve extract performance
-- 18 Mar 2010	MF	19556	29	Change the way in which cs_GetStandingInstructionsBulk is executed so that the ErrorCode returned is passed in @ErrorCode
-- 01 Jul 2010	MF	18758	30	Increase the column size of Instruction Type to allow for expanded list.
-- 30 Mar 2012	AvdA 20480	31	Remove filter on Initialisation process.

set nocount on
set concat_null_yields_null off

Create table #TEMPCPACANDIDATES
		(	CASEID			int 	null,
			NAMENO			int 	null,
			STOPPAYREASON		char(1)	collate database_default null
		)
-- 18297 new table required
Create table #TEMPCASEINSTRUCTIONS (
			CASEID			int		NOT NULL,
			INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL, 
			INSTRUCTIONCODE		smallint	NOT NULL)

/* 18297 no longer required

Create table #TEMPCASENAME (
			CASEID			int		NOT NULL,
			NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
			NAMENO			int		NOT NULL
			)
			
Create index XIE1TEMPCASENAME ON #TEMPCASENAME (
			CASEID,
			NAMETYPE,
			NAMENO
	 		)
*/ --18297
Create table #TEMPINSTRUCTIONS 
		(	INSTRUCTIONCODE		smallint not null,
			INSTRUCTIONTYPE		nvarchar(3)  collate database_default null, 
			NAMETYPE		varchar(3)   collate database_default null, 
			RESTRICTEDBYTYPE	varchar(3)   collate database_default null
		)
			
-- Note this additional temporary table is required to get the Renewal Instruction
-- for the case.  This is because of a SQL restriction that does not allow an Update
-- that includes an aggregate statement

Create table #TEMPCPAINSTRUCTIONS
		(	CASEID			int		null,
			NAMENO			int		null,
			INSTRUCTIONCODE		int		null
		)

declare	@ErrorCode		int
declare @TranCountStart		int
declare	@sSQLString		nvarchar(4000)
declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(4000)	-- the SQL to filter
declare	@nHomeNameNo		int
declare @sInstructionTypes	nvarchar(200)	-- List of instruction type used by CPA Interface
declare @sNameTypes		nvarchar(200)	-- List of NameTypes from which Standing Instructions are found

declare	@sInstructions		nchar(7)
declare	@sInstructionType	nchar(1)
declare	@sInstNameType		nvarchar(3)
declare	@sRestrictedByType	nvarchar(3)
declare @bCasesSent		bit
declare @bPortfolioExists	bit
declare @bConsiderAllCPACases bit -- SQA17347

Set	@ErrorCode=0
Set 	@TranCountStart=0

If @ErrorCode=0
Begin
	set @sSQLString="
	Select	@bConsiderAllCPACases  =S.COLBOOLEAN -- SQA17347
	from	  SITECONTROL S
	where S.CONTROLID='CPA Consider All CPA Cases'
	"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@bConsiderAllCPACases		bit			OUTPUT',
					  @bConsiderAllCPACases	  =@bConsiderAllCPACases	OUTPUT
End

-- Get the Names that are to be explicitly reported to CPA
If @bConsiderAllCPACases <> 1
and @ErrorCode=0
-- 17347 Name collection not necessary if considering all Cases as Names will be collected from Case records
Begin
	-- Retro option using triggers and CPAUPDATE
	If @psOfficeCPACode is null
	Begin
		Set @sSQLString="
		insert into #TEMPCPACANDIDATES(NAMENO)
		select distinct NAMEID 
		from   CPAUPDATE
		where  NAMEID is not null"
	End
	Else Begin
		Set @sSQLString="
		insert into #TEMPCPACANDIDATES(NAMENO)
		select distinct CPA.NAMEID 
		from   CPAUPDATE CPA
		where exists
		(select 1 from CASENAME CN
		 join CASES C	on (C.CASEID=CN.CASEID)
		 join OFFICE O	on (O.OFFICEID=C.OFFICEID)
		 where CN.NAMENO=CPA.NAMEID
		 and CN.NAMETYPE in ('I','R','D','Z','O','DIV')
		 and O.CPACODE=@psOfficeCPACode)"
	End
	
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@psOfficeCPACode	nvarchar(3)',
				  @psOfficeCPACode=@psOfficeCPACode
End

-- If new cases are to be extracted then construct the SQL to load the Cases.

If  @pbNewCases=1
and @ErrorCode =0
Begin
	-- Determine if Cases have been extracted before
	Set @sSQLString="
	Select @bCasesSent=1 
	from CPASEND CPA"

	If @psOfficeCPACode is not null
	Begin
		Set @sSQLString=@sSQLString+"
		join CASES C  on (C.CASEID=CPA.CASEID)
		join OFFICE O on (O.OFFICEID=C.OFFICEID)
		where O.CPACODE=@psOfficeCPACode"
	End

	Set @bCasesSent=0
	Set @bPortfolioExists=0

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bCasesSent		bit 	OUTPUT,
				  @psOfficeCPACode	nvarchar(3)',
				  @bCasesSent=@bCasesSent	OUTPUT,
				  @psOfficeCPACode=@psOfficeCPACode

	-- Determine if there are Cases in the Portfolio already
	If @bCasesSent=0
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		Select @bPortfolioExists=1
		from CPAPORTFOLIO CPA"
	
		If @psOfficeCPACode is not null
		Begin
			Set @sSQLString=@sSQLString+"
			join CASES C  on (C.CASEID=CPA.CASEID)
			join OFFICE O on (O.OFFICEID=C.OFFICEID)
			where O.CPACODE=@psOfficeCPACode"
		End
	
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@bPortfolioExists	bit 		OUTPUT,
					  @psOfficeCPACode	nvarchar(3)',
					  @bPortfolioExists=@bPortfolioExists	OUTPUT,
					  @psOfficeCPACode=@psOfficeCPACode
	End


	-- If nothing exists in the CPASEND table but there is data in the CPAPORTFOLIO
	-- then this indicates that CPA already has a relationship with the client and 
	-- new interface has just been turned on.  
	-- To initialise the database the system will report Cases that CPA is already
	-- aware of.  The batch produced will not need to be sent to CPA.

	If  @bCasesSent=0
	and @bPortfolioExists=1
	and @ErrorCode=0
	Begin
		Set @sSQLString="insert into #TEMPCPACANDIDATES (CASEID)"
			       +"select distinct C.CASEID"
	
		Set @sFrom=	"from CPAPORTFOLIO CPA"+char(10)+
				"join CASES C on (C.CASEID=CPA.CASEID)"

		If @psOfficeCPACode is not null
		Begin
			Set @sFrom=@sFrom+char(10)+
				"join OFFICE O on (O.OFFICEID=C.OFFICEID"+char(10)+
				"              and O.CPACODE=@psOfficeCPACode)"
		End

		-- 20480 remove this cpa portfolio condition
		--      safer to consider all existing matching cases where currently 
		--		live and reportable on Inprotech for the initialisation batch
		--Set @sWhere=	"where CPA.STATUSINDICATOR='L'"
	
		Set @sSQLString=@sSQLString+char(10)+@sFrom -- 20480 +char(10)+@sWhere

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOfficeCPACode	nvarchar(3)',
					  @psOfficeCPACode=@psOfficeCPACode
	End
		Else Begin
		Set @sSQLString="insert into #TEMPCPACANDIDATES (CASEID, STOPPAYREASON)"
			       +"select distinct C.CASEID, C.STOPPAYREASON"
	
		Set @sFrom=	"from CASES C
				left join STATUS S         on (S.STATUSCODE=C.STATUSCODE)
				left join PROPERTY P       on (P.CASEID=C.CASEID)
				left join STATUS S1        on (S1.STATUSCODE=P.RENEWALSTATUS)
				left join CPAPORTFOLIO CPA on (CPA.CASEID=C.CASEID)
				left join CPAPORTFOLIO CPD on (CPD.CASEID=C.CASEID
							   and CPD.STATUSINDICATOR<>'L')
				left join SITECONTROL SC   on ( SC.CONTROLID='CPA Date-Start')
				left join SITECONTROL SC1  on (SC1.CONTROLID='CPA Date-Expiry')
				left join CASEEVENT ST     on (ST.CASEID=C.CASEID
						 	   and ST.EVENTNO=SC.COLINTEGER
							   and ST.CYCLE=1)
				left join CASEEVENT CE     on (CE.CASEID=C.CASEID
							   and CE.EVENTNO=isnull(SC1.COLINTEGER,-12))"
	
		Set @sWhere=	"where
				   -- report the Case if it is live on the portfolio but there
				   -- is a stop pay reason on Inprotech.  Also check that the
				   -- same case does not have a second entry on the portfolio
				   -- that is not live.
				   ((CPA.STATUSINDICATOR='L' and C.STOPPAYREASON is not null and CPD.CASEID is null)
				   -- otherwise report live reportable that are not live on 
				   -- on the portfolio
				OR ( 	     C.REPORTTOTHIRDPARTY=1
					and  C.STOPPAYREASON is null
					and  isnull(S.LIVEFLAG,1)=1
					and  isnull(S1.LIVEFLAG,1)=1
					-- Either no expiry date or it is in the future
					and (CE.CASEID is null OR isnull(CE.EVENTDATE,CE.EVENTDUEDATE)>getdate())
					-- New cases for CPA will not already exist in CPAPORTFOLIO or if the
					-- case on the Portfolio is not live then the CPA Start Pay date to be
					-- reported must be greater than or equal to the 1st January for the 
					-- year of the Portfolio
					and (CPA.CASEID is null
					 OR (CPA.STATUSINDICATOR<>'L' AND
					     isnull(ST.EVENTDATE,ST.EVENTDUEDATE)>=
					     cast('01/01/'
						 +cast(YEAR(isnull(CPA.DATEOFPORTFOLIOLST,'01/01/2999')) as nvarchar) as datetime)))))"
	
		If  @pnCaseId is not null
			Set @sWhere=@sWhere+char(10)+"and C.CASEID="+convert(varchar,@pnCaseId)
		Else
		If  @pbNotProperty=1
		and @psPropertyType is not null
			Set @sWhere=@sWhere+char(10)+"and C.PROPERTYTYPE<>'"+@psPropertyType+"'"
		Else 
		If @psPropertyType is not null
			Set @sWhere=@sWhere+char(10)+"and C.PROPERTYTYPE='"+@psPropertyType+"'"
		
		If @psOfficeCPACode is not null
		Begin
			Set @sFrom=@sFrom+"
				join OFFICE O              on (O.OFFICEID=C.OFFICEID)"

			Set @sWhere=@sWhere+"
				and O.CPACODE=@psOfficeCPACode"
		End

		Set @sSQLString=@sSQLString+char(10)+@sFrom+char(10)+@sWhere

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOfficeCPACode	nvarchar(3)',
					  @psOfficeCPACode=@psOfficeCPACode
	End
End

-- Load cases that have changed

If  @pbChangedCases=1
and @ErrorCode=0
Begin
	Set @sSQLString="insert into #TEMPCPACANDIDATES (CASEID, STOPPAYREASON)"
		       +"select distinct C.CASEID, C.STOPPAYREASON"

	If @bConsiderAllCPACases = 1
		Set @sFrom=	"from CASES C"
	Else
		Set @sFrom=	"from CPAUPDATE U
			join CASES C		on (C.CASEID=U.CASEID)"

	Set @sFrom=	@sFrom + "
			left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
			left join PROPERTY P    on (P.CASEID=C.CASEID)
			left join STATUS S1	on (S1.STATUSCODE=P.RENEWALSTATUS)
			left join CPAPORTFOLIO PT on(PT.CASEID=C.CASEID)
			left join CPASEND CPA	on (CPA.CASEID=C.CASEID 
						and BATCHNO = (	select max(BATCHNO) 
								from CPASEND CPA1 
								where CPA1.CASEID=C.CASEID))"

	-- Unless there is a Stop Pay Reason the Case must have the ReportToThirdParty flag
	-- turned on and have a live status if it is to be reported to CPA.  If the Stop Pay Reason 
	-- exists then only extract the case if the Case is either currently on the live portfolio
	-- or is not currently showing on the portfolio at this time.
	Set @sWhere=	"where ((C.STOPPAYREASON is not null and isnull(PT.STATUSINDICATOR,'L')='L')"+char(10)+
			"   OR  (C.REPORTTOTHIRDPARTY=1 AND isnull(S.LIVEFLAG,1)=1 AND isnull(S1.LIVEFLAG,1)=1 ))"
	-- SQA12173
	-- The Case may be sent to CPA if it has previously been sent and appears in the CPASEND table or if it
	-- exists in the CPAPORTFOLIO as a Live, Agent responsible Case but does not exist in the CPASEND table.  
	-- This latter situation indicates that the Case has managed to get onto the CPA Portfolio in some way 
	-- other than via the CPA Interface.
	-- SQA17347 
	-- If the previously sent row contained the same stoppayreason don't bother considering again.
	Set @sWhere=@sWhere+char(10)+"and ( (CPA.CASEID is not null and 
		( C.STOPPAYREASON IS NULL OR (C.STOPPAYREASON <> CPA.STOPPAYINGREASON) 
			OR (C.STOPPAYREASON IS NOT NULL and CPA.STOPPAYINGREASON IS NULL)))
		OR  (CPA.CASEID is null and isnull(PT.STATUSINDICATOR,'L')='L' and PT.AGENTCASECODE is not null))"
	If  @pnCaseId is not null
		Set @sWhere=@sWhere+char(10)+"and C.CASEID="+convert(varchar,@pnCaseId)
	Else If  @pbNotProperty=1
	and @psPropertyType is not null
		Set @sWhere=@sWhere+char(10)+"and C.PROPERTYTYPE<>'"+@psPropertyType+"'"
	Else If @psPropertyType is not null
		Set @sWhere=@sWhere+char(10)+"and C.PROPERTYTYPE='"+@psPropertyType+"'"
		
	If @psOfficeCPACode is not null
	Begin
		Set @sFrom=@sFrom+"
			join OFFICE O              on (O.OFFICEID=C.OFFICEID)"

		Set @sWhere=@sWhere+"
			and O.CPACODE=@psOfficeCPACode"
	End

	Set @sSQLString=@sSQLString+char(10)+@sFrom+char(10)+@sWhere

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@psOfficeCPACode	nvarchar(3)',
				  @psOfficeCPACode=@psOfficeCPACode

End

-- Get the standing instruction codes that indicate CPA are to perform the processing 
-- Do this only if an explicit check of Standing Instructions is required.

If @pbCheckInstruction=1
Begin	
	If  @ErrorCode=0
	Begin
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
	End

	-- Get the list of InstructionTypes whose standing instructions are to be extracted
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Select @sInstructionTypes=CASE WHEN(@sInstructionTypes is not null) 
							THEN @sInstructionTypes+','+EC.INSTRUCTIONTYPE
							ELSE EC.INSTRUCTIONTYPE
					  END
		from (	select distinct INSTRUCTIONTYPE
			from #TEMPINSTRUCTIONS
			where INSTRUCTIONTYPE is not null) EC"

		Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sInstructionTypes	nvarchar(200)	output',
					  @sInstructionTypes=@sInstructionTypes	output
	End

	-- 18297 Now use cs_GetStandingInstructionsBulk to improve efficiency and ensure consistency
	If @ErrorCode=0
	Begin
		exec @ErrorCode=cs_GetStandingInstructionsBulk
					@psInstructionTypes=@sInstructionTypes,
					@psCaseTableName   = N'#TEMPCPACANDIDATES'
	End	

	/*  18297 Remove previous code
	-- Get the Home NameNo
	
	If @ErrorCode = 0
	Begin
		Select @nHomeNameNo=S.COLINTEGER
		from	SITECONTROL S
		where	S.CONTROLID='HOMENAMENO'
	
		Set @ErrorCode=@@Error
	End

	------------------------------------------------
	-- Get the list of NameTypes that can be used
	-- for determining standing instructions
	-- This is being used as a performance technique
	------------------------------------------------
	If  @ErrorCode=0
	and @sInstructionTypes is not null
	Begin
		Set @sSQLString="
		Select @sNameTypes=CASE WHEN(@sNameTypes is not null) 
							THEN @sNameTypes+','''+I.NAMETYPE+''''
							ELSE ''''+I.NAMETYPE+'''' 
				   END
		from (	select NAMETYPE as NAMETYPE
			from INSTRUCTIONTYPE
			where NAMETYPE is not null
			and INSTRUCTIONTYPE in ("+@sInstructionTypes+")
			UNION
			select RESTRICTEDBYTYPE
			from INSTRUCTIONTYPE
			where RESTRICTEDBYTYPE is not null
			and INSTRUCTIONTYPE in ("+@sInstructionTypes+")) I"

		Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sNameTypes	nvarchar(200)	output',
					  @sNameTypes=@sNameTypes	output
	End
	
	---------------------------------------
	-- Performance improvement by loading 
	-- a temporary table with the required
	-- CaseNames and then back filling with
	-- the Home NameNo if required NameType 
	-- is missing.
	---------------------------------------
	If @ErrorCode=0
	and @sNameTypes is not null
	Begin
		Set @sSQLString="
		insert into #TEMPCASENAME(CASEID,NAMETYPE,NAMENO)
		select CN.CASEID, CN.NAMETYPE, CN.NAMENO
		from #TEMPCPACANDIDATES T
		join CASENAME CN on (CN.CASEID=T.CASEID)
		where CN.NAMETYPE in ("+@sNameTypes+")
		and CN.SEQUENCE=(select min(CN1.SEQUENCE)
				 from CASENAME CN1
				 where CN1.CASEID=CN.CASEID
				 and CN1.NAMETYPE=CN.NAMETYPE
				 and(CN1.EXPIRYDATE is NULL or CN1.EXPIRYDATE>getdate()))"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	---------------------------------------------
	-- Backfill any CaseNames with the HomeNameNo
	-- if there is no NameType against the Case
	-- This is so we can use a JOIN rather than
	-- a LEFT JOIN in the main SELECT for getting
	-- the standing instructions as the LEFT JOIN
	-- was creating performance problems.
	---------------------------------------------
	If  @ErrorCode=0
	and @nHomeNameNo is not null
	AND @sNameTypes  is not null
	Begin
		Set @sSQLString="
		insert into #TEMPCASENAME
		select T.CASEID, NT.NAMETYPE, @nHomeNameNo
		from #TEMPCPACANDIDATES T
		join NAMETYPE NT on (NT.NAMETYPE in ("+@sNameTypes+"))
		left join #TEMPCASENAME CN on (CN.CASEID=T.CASEID
					   and CN.NAMETYPE=NT.NAMETYPE)
		where CN.CASEID is null
		and T.CASEID is not null"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nHomeNameNo	int',
					  @nHomeNameNo=@nHomeNameNo
	End

	--------------------------------------------
	-- Now get the Standing Instruction for each
	-- required instruction type.
	--------------------------------------------
	If  @ErrorCode=0
	and @sInstructionTypes is not null
	Begin
		set @sSQLString="
		insert into #TEMPCPAINSTRUCTIONS(CASEID, INSTRUCTIONCODE)
		SELECT	CI.CASEID, NI.INSTRUCTIONCODE
	
			-- To determine the best InstructionCode a weighting is	
			-- given based on the existence of characteristics	
			-- found in the NAMEINSTRUCTIONS row.  The MAX function 
			-- returns the highest weighting to which the required	
			-- INSTRUCTIONCODE has been concatenated.
		FROM	(SELECT C.CASEID, T.INSTRUCTIONTYPE,
				substring(max (isnull(
				CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
			 	CASE WHEN(NI.NAMENO		= X1.NAMENO) THEN '1' ELSE '0' END +
				CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.NAMENO)          +
				convert(nchar(11),NI.INTERNALSEQUENCE)+
				convert(nchar(11),X1.NAMENO),'')),6,33) as COMPOSITECODE
			From		#TEMPCPACANDIDATES TC
			join		CASES C	on (C.CASEID=TC.CASEID)
			join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE in ("+@sInstructionTypes+"))
			join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
			-- SQA17295 modify the following from LEFT JOIN to a JOIN
			join		#TEMPCASENAME X1     on (X1.CASEID=C.CASEID
							     and X1.NAMETYPE=T.NAMETYPE)
			left join	#TEMPCASENAME X2     on (X2.CASEID=C.CASEID
							     and X2.NAMETYPE=T.RESTRICTEDBYTYPE)
			join		NAMEINSTRUCTIONS NI  on ((NI.NAMENO=X1.NAMENO		 OR NI.NAMENO=@nHomeNameNo)
							     and (NI.CASEID=C.CASEID 		 OR NI.CASEID 		is NULL) 
							     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
							     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
							     and (NI.RESTRICTEDTONAME=X2.NAMENO	 OR NI.RESTRICTEDTONAME is NULL) )
			where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
			group by C.CASEID, T.INSTRUCTIONTYPE) CI
		join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(CI.COMPOSITECODE,1, 11))
					and  NI.INTERNALSEQUENCE=convert(int, substring(CI.COMPOSITECODE,12,11)))"
	
		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameNo		int',
					@nHomeNameNo
	
		-- Also get the Standing Instructions for any Names that have been
		-- flagged to be reported to CPA
	
		If @ErrorCode=0
		Begin
			set @sSQLString="
			insert into #TEMPCPAINSTRUCTIONS(NAMENO, INSTRUCTIONCODE)
			SELECT	NI.NAMENO, NI.INSTRUCTIONCODE
				-- To determine the best InstructionCode a weighting is	
				-- given based on the existence of characteristics	
				-- found in the NAMEINSTRUCTIONS row.  Preference is  
				-- given to instructions held against the candidate Name
				-- rather than the Home Name.
			FROM	(SELECT TC.NAMENO, T.INSTRUCTIONTYPE,
					substring(max (isnull(
				 	CASE WHEN(NI.NAMENO = @nHomeNameNo) THEN '0' ELSE '1' END+
					convert(nvarchar(5),NI.INSTRUCTIONCODE),'')),2,5) as INSTRUCTIONCODE
				From #TEMPCPACANDIDATES TC
				join INSTRUCTIONTYPE T	 on ( T.INSTRUCTIONTYPE in ("+@sInstructionTypes+"))
				join INSTRUCTIONS I	 on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
				join NAMEINSTRUCTIONS NI on ((NI.NAMENO=TC.NAMENO OR NI.NAMENO=@nHomeNameNo)
							 and  NI.CASEID       is NULL 
							 and  NI.PROPERTYTYPE is NULL
							 and  NI.COUNTRYCODE  is NULL)
				where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
				and TC.NAMENO is not null
				and TC.CASEID is null
				group by TC.NAMENO, T.INSTRUCTIONTYPE) NI"
	
			Execute @ErrorCode = sp_executesql @sSQLString, 
						N'@nHomeNameNo		int',
						@nHomeNameNo
	
		End
	END
	*/ -- 18297 End of removed code - replaced by cs_GetStandingInstructionsBulk

	-- Insert the Cases into the #TEMPDATATOSEND if there is an appropriate Standing Instruction or if 
	-- the STOPPAYREASON is not null
	
	If @ErrorCode=0
	Begin
		-- 18297 Collect from #TEMPCASEINSTRUCTIONS instead of #TEMPCPAINSTRUCTIONS

		Set @sSQLString="
		insert into #TEMPDATATOSEND (CASEID, NAMENO, INSTRUCTIONCODE)
		select distinct T.CASEID, T.NAMENO, TI.INSTRUCTIONCODE
		from #TEMPCPACANDIDATES T
		left join #TEMPCASEINSTRUCTIONS TI on (TI.CASEID=T.CASEID
						   and TI.INSTRUCTIONCODE=(select min(TI1.INSTRUCTIONCODE)
									   from #TEMPCASEINSTRUCTIONS TI1
									   join #TEMPINSTRUCTIONS I on (I.INSTRUCTIONCODE=TI1.INSTRUCTIONCODE)
									   where TI1.CASEID=TI.CASEID))
		where T.STOPPAYREASON is not null
		or TI.INSTRUCTIONCODE is not null
		or T.NAMENO           is not null"
		
		Execute @ErrorCode=sp_executesql @sSQLString
	End
End	/* End of Check Instruction section */
Else Begin
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPDATATOSEND (CASEID, NAMENO)
		select distinct T.CASEID, T.NAMENO
		from #TEMPCPACANDIDATES T"
		
		Execute @ErrorCode=sp_executesql @sSQLString
	End
End	
-- SQA13292
-- Construct the DELETE from the CPAUPDATE table if the 
-- appropriate Site Control is turned on.
If exists(select 1 from SITECONTROL where CONTROLID='CPA Clear Batch' and COLBOOLEAN=1)
and(@pbChangedCases=1 or @pbNewCases=1)
-- 17347 CPAUPDATE delete not necessary if considering all Cases 
and @bConsiderAllCPACases <> 1
and @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPCPAUPDATETODELETE(NAMEID,CASEID)
	Select U.NAMEID, U.CASEID
	from CPAUPDATE U
	left join CASES C  on (C.CASEID=U.CASEID)
	left join OFFICE O on (O.OFFICEID=C.OFFICEID)
	left join CPASEND S on (S.CASEID=U.CASEID)"

	Set @sWhere="	Where 1=1"

	If @pnCaseId is not null
		Set @sWhere=@sWhere+char(10)+"	U.CASEID=@pnCaseId"

	If @psPropertyType is not null
	Begin
		If @pbNotProperty=1
			Set @sWhere=@sWhere+char(10)+"	and (C.PROPERTYTYPE is null OR C.PROPERTYTYPE<>@psPropertyType)"
		Else
			Set @sWhere=@sWhere+char(10)+"	and (C.PROPERTYTYPE is null OR C.PROPERTYTYPE=@psPropertyType)"
	End

	If @psOfficeCPACode is not null
		Set @sWhere=@sWhere+char(10)+"	and (O.OFFICEID is null OR O.CPACODE=@psOfficeCPACode)"

	-- If both NewCases and ChangedCases are flagged then no additional filter
	-- is required as all rows are to be removed.  Only build filter if one flag is on.
	If  @pbNewCases=1
	and @pbChangedCases=0
		Set @sWhere=@sWhere+char(10)+"	and (U.CASEID is null or S.CASEID is not null)"
	Else 
	If  @pbChangedCases=1
	and @pbNewCases=0
		Set @sWhere=@sWhere+char(10)+"	and (U.CASEID is null or S.CASEID is null)"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @psPropertyType	nvarchar(2),
				  @psOfficeCPACode	nvarchar(3)',
				  @pnCaseId       =@pnCaseId,
				  @psPropertyType =@psPropertyType,
				  @psOfficeCPACode=@psOfficeCPACode
End

Return @ErrorCode
go

grant execute on dbo.cpa_InsertCasesToSend to public
go