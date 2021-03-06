PRINT '***************************************************************'
PRINT '**** Refreshing STAR Preparation Stored Procedure ************'
PRINT '***************************************************************'
PRINT ''

-----------------------------------------------------------------------
-- cpa_ReportSTARPreparation		v 11
-----------------------------------------------------------------------

if exists (select * from sysobjects where id = object_id(N'[dbo].cpa_ReportSTARPreparation') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_ReportSTARPreparation.'
	drop procedure dbo.cpa_ReportSTARPreparation
end
print '**** Creating procedure dbo.cpa_ReportSTARPreparation...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_ReportSTARPreparation
as
-- PROCEDURE :	cpa_ReportSTARPreparation
-- VERSION :	11
-- DESCRIPTION:	Prepares a set of tables for use by CPA STAR (Portfolio Status Audit Report). 
--
--				*** Uses instruction check code copied from cpa_InsertCasesToSend as at v22 ***
--
--				Populates CPASTAR_MATCHEDPORTFOLIO, CPASTAR_LIVEINPROTECHONLY
--				Only run while following instructions in the document 'STAR Instructions.doc'
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who			Version	Description
-- ---------------------------------------------------------------------- 
-- 25/06/2008	AvdA		1		Procedure Created.
-- 25/06/2008	AvdA		2		Include CPAAccount.
-- 25/07/2008	AvdA		3		Remove cases with StopPayReason from Inprotech Only.
-- 31/07/2008   AvdA		4		Put cases with StopPayReason back - breakdown in report.
-- 06/08/2008	AvdA		5		Include category in Inprotech Only.
-- 04/12/2008	AvdA		6		Include FileNumber and ClientsReference in particular
--									 so that this can be provided in the CASECODE update file.
-- 14/01/2009	AvdA		7		SQA 17295 (remove left join for performance gain) 
--									applied to cpa_InsertCasesToSend and here in copied section.
-- 13/02/2009	AvdA		8		Bug in code populating Inprotech Only table using 
--									wrong site control switch for CASEID instead of IRN.
-- 23/02/2009	AvdA		9		SQA 17295 (further change in copied section to 
--									remain in sync with cpa_InsertCasesToSend.
-- 04/03/2009	AvdA		10		Add PortfolioCrossCheck preparation.
-- 19/06/2009	AvdA		11		Include SI for all cases. 


set nocount on
set concat_null_yields_null off

Create table #TEMPCPACANDIDATES
		(	CASEID			int 	null,
			NAMENO			int 	null,
			STOPPAYREASON		char(1)	collate database_default null
		)
		
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
			
Create table #TEMPINSTRUCTIONS 
		(	INSTRUCTIONCODE		smallint not null,
			INSTRUCTIONTYPE		char(1)      collate database_default null, 
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
-- Use table construction from cpa_InsertCPAComplete
Create table #TEMPDATATOSEND 
		(
			CASEID			int,
			NAMENO			int,
			INSTRUCTIONCODE		smallint
		)
-- Add a table to record instruction code and whether it would allow a case to be sent
Create table #TEMPCASEINSTRUCTIONS
		(	CASEID			int		not null,
			INSTRUCTIONCODE		int,
			DESCRIPTION nvarchar(50),
			INSTRUCTIONSENDFLAG	bit
		)

declare	@ErrorCode		int
declare @TranCountStart		int
declare	@sSQLString		nvarchar(4000)
declare	@sSQLString1	nvarchar(4000)
declare @sInstructionTypes	nvarchar(200)	-- List of instruction type used by CPA Interface
declare	@sInstructionType	nchar(1)
declare @sNameTypes		nvarchar(200)	-- List of NameTypes from which Standing Instructions are found

declare @sCPAUseCaseidAsCaseCode	bit
declare @sCPAUseClientCaseCode		bit
declare @nHomeNameNo		int
declare @nCPAStartEventNo	int
declare @nCPAStopEventNo	int

declare @sApplicationNumberType	 nvarchar(20)
declare @sRegistrationNumberType nvarchar(20)
declare @nApplicationEventNo	int
declare @nRegistrationEventNo	int
declare @sFileNumberType		nvarchar(3)

Set	@ErrorCode=0
Set @TranCountStart=0
Begin
	-- Collect basic site control settings.
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Select	@sFileNumberType  = S4.COLCHARACTER,
				@sCPAUseCaseidAsCaseCode  = isnull(S3.COLBOOLEAN,0),
				@sCPAUseClientCaseCode  = isnull(S2.COLBOOLEAN,0),
				@nHomeNameNo =S1.COLINTEGER
		from SITECONTROL S1
		left join SITECONTROL S4 on (upper(S4.CONTROLID)='CPA FILE NUMBER TYPE')
		left join SITECONTROL S3 on (upper(S3.CONTROLID)='CPA USE CASEID AS CASE CODE')
		left join SITECONTROL S2 on (upper(S2.CONTROLID)='CPA-USE CLIENTCASECODE')
		where upper(S1.CONTROLID)='HOMENAMENO'"

		exec sp_executesql @sSQLString,
					N'@sFileNumberType		nvarchar(3)		OUTPUT,
					  @sCPAUseCaseidAsCaseCode		bit	OUTPUT,
					  @sCPAUseClientCaseCode		bit	OUTPUT,
					  @nHomeNameNo	int	OUTPUT',
					  @sFileNumberType	  =@sFileNumberType		OUTPUT,
					  @sCPAUseCaseidAsCaseCode =@sCPAUseCaseidAsCaseCode	OUTPUT,
					  @sCPAUseClientCaseCode =@sCPAUseClientCaseCode	OUTPUT,
					  @nHomeNameNo=@nHomeNameNo	OUTPUT
	End
	-- Also collect the site specific events and number types.
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Select @nCPAStartEventNo = S1.COLINTEGER,
			   @nCPAStopEventNo = S2.COLINTEGER,
			   @sApplicationNumberType = dbo.fn_WrapQuotes('6,'+isnull(S3.COLCHARACTER,'A'),1,0),
			   @sRegistrationNumberType = dbo.fn_WrapQuotes('9,'+isnull(S4.COLCHARACTER,'R'),1,0),
			   @nApplicationEventNo = S5.COLINTEGER,
			   @nRegistrationEventNo = S6.COLINTEGER
		from SITECONTROL S1
		left join SITECONTROL S6 on (upper(S6.CONTROLID)='CPA DATE-REGISTRATN')
		left join SITECONTROL S5 on (upper(S5.CONTROLID)='CPA DATE-FILING')
		left join SITECONTROL S4 on (upper(S4.CONTROLID)='CPA NUMBER-REGISTRATION')
		left join SITECONTROL S3 on (upper(S3.CONTROLID)='CPA NUMBER-APPLICATION')
		left join SITECONTROL S2 on (upper(S2.CONTROLID)='CPA DATE-STOP')
		where upper(S1.CONTROLID)='CPA DATE-START'"

		exec sp_executesql @sSQLString,
					N'@nCPAStartEventNo int	OUTPUT,
					  @nCPAStopEventNo int	OUTPUT,
					  @sApplicationNumberType	nvarchar(20)	OUTPUT,
					  @sRegistrationNumberType	nvarchar(20)	OUTPUT,
					  @nApplicationEventNo		int	OUTPUT,
					  @nRegistrationEventNo		int	OUTPUT',
					  @nCPAStartEventNo	=@nCPAStartEventNo		OUTPUT,
					  @nCPAStopEventNo	=@nCPAStopEventNo		OUTPUT,
					  @sApplicationNumberType	=@sApplicationNumberType	OUTPUT,
					  @sRegistrationNumberType	=@sRegistrationNumberType	OUTPUT,
					  @nApplicationEventNo	=@nApplicationEventNo	OUTPUT,
					  @nRegistrationEventNo	=@nRegistrationEventNo	OUTPUT
	End

	-- Collect renewals standing instruction for all cases
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPCPACANDIDATES (CASEID)
		select  CASEID
		from CASES"
		
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Get the standing instruction codes that indicate CPA are to perform the processing 
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
							THEN @sInstructionTypes+','''+EC.INSTRUCTIONTYPE+''''
							ELSE ''''+EC.INSTRUCTIONTYPE+'''' 
					  END
		from (	select distinct INSTRUCTIONTYPE
			from #TEMPINSTRUCTIONS
			where INSTRUCTIONTYPE is not null) EC"

		Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sInstructionTypes	nvarchar(200)	output',
					  @sInstructionTypes=@sInstructionTypes	output
	End
	
	-- SQA 17295 starts here
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
	
	------------------------------------------------------------------------------
	-- Performance improvement by loading  a temporaty table with the required
	-- CaseNames and then back filling with the Home NameNo if required NameType 
	-- is missing.
	------------------------------------------------------------------------------
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
	
	------------------------------------------------------------------------------------
	-- Backfill any CaseNames with the HomeNameNo if there is no NameType against the Case
	-- This is so we can use a JOIN rather than a LEFT JOIN in the main SELECT for getting
	-- the standing instructions as the LEFT JOIN was creating performance problems.
	------------------------------------------------------------------------------------
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

	-----------------------------------------------------------------------------------
	-- Now get the Standing Instruction for each required instruction type.
	-----------------------------------------------------------------------------------
	-- Now populate #TEMPCPAINSTRUCTIONS with all potential instruction codes of this
	-- instruction type for the cases being considered. 
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
		 		CASE WHEN(NI.NAMENO		= convert(int,substring(X1.NAMENO,7,12)))
										 THEN '1' ELSE '0' END +
				CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.NAMENO)          +
				convert(nchar(11),NI.INTERNALSEQUENCE)+
				substring(X1.NAMENO,7,11),'')),6,33) as COMPOSITECODE
			From		#TEMPCPACANDIDATES TC
			join		CASES C	on (C.CASEID=TC.CASEID)
			join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE in ("+@sInstructionTypes+"))
			join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
--			left --	Remove this left join and leave a simple join.
--					This works on the assumption that we expect a CASENAME row to exist for the given NameType associated with the InstructionType.
			join	(select CASEID, NAMETYPE, min(replicate('0',6-len(SEQUENCE))+convert(varchar, SEQUENCE)+convert(varchar,NAMENO)) as NAMENO
					 from CASENAME
					 where (EXPIRYDATE is null or EXPIRYDATE>getdate())
					 group by CASEID, NAMETYPE) X1	on (X1.CASEID=C.CASEID
									and X1.NAMETYPE=T.NAMETYPE)
			left join	(select CASEID, NAMETYPE, min(replicate('0',6-len(SEQUENCE))+convert(varchar, SEQUENCE)+convert(varchar,NAMENO)) as NAMENO
					 from CASENAME
					 where (EXPIRYDATE is null or EXPIRYDATE>getdate())
					 group by CASEID, NAMETYPE) X2	on (X2.CASEID=C.CASEID
									and X2.NAMETYPE=T.RESTRICTEDBYTYPE)
			join		NAMEINSTRUCTIONS NI  on ((NI.NAMENO=convert(int,substring(X1.NAMENO,7,11))
									 			 OR NI.NAMENO=@nHomeNameNo)
								 and (NI.CASEID=C.CASEID 		 OR NI.CASEID 		is NULL) 
								 and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
								 and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
								 and (NI.RESTRICTEDTONAME=convert(int,substring(X2.NAMENO,7,11))
												 OR NI.RESTRICTEDTONAME is NULL) )
			where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
			group by C.CASEID, T.INSTRUCTIONTYPE) CI
		join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(CI.COMPOSITECODE,1, 11))
					and  NI.INTERNALSEQUENCE=convert(int, substring(CI.COMPOSITECODE,12,11)))"

		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameNo		int',
					@nHomeNameNo
	End

	-- Insert a Case into the #TEMPDATATOSEND if there is an appropriate Standing Instruction
    -- We are selecting the lowest instructioncode (to reduce set to one value) that is 
	-- valid for the case and which is one of the CPA instructioncodes in #TEMPINSTRUCTIONS.
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPDATATOSEND (CASEID, INSTRUCTIONCODE)
		select distinct T.CASEID, TI.INSTRUCTIONCODE
		from #TEMPCPACANDIDATES T
		left join #TEMPCPAINSTRUCTIONS TI on (TI.CASEID=T.CASEID
						   and TI.INSTRUCTIONCODE=(select min(TI1.INSTRUCTIONCODE)
									   from #TEMPCPAINSTRUCTIONS TI1
									   join #TEMPINSTRUCTIONS I on (I.INSTRUCTIONCODE=TI1.INSTRUCTIONCODE)
									   where TI1.CASEID=TI.CASEID))
		where TI.INSTRUCTIONCODE is not null"
		
		Execute @ErrorCode=sp_executesql @sSQLString
	End

	-- Flagged cases which are not listed in #TEMPDATATOSEND are cases which do 
	-- not have a valid Standing Instruction for sending to CPA.
	-- These will be considered as NOT Flagged when preparing the STAR
	-- Record the SI for each case and whether it will allow the case to be sent 

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPCASEINSTRUCTIONS (CASEID, INSTRUCTIONCODE, 
		DESCRIPTION, INSTRUCTIONSENDFLAG)
		select distinct CC.CASEID, CC.INSTRUCTIONCODE, 
		I.DESCRIPTION, (case when T.CASEID is not null then 1 else 0 end)
		from #TEMPCPAINSTRUCTIONS CC
		left join #TEMPDATATOSEND T on T.CASEID = CC.CASEID
		left join INSTRUCTIONS I on (I.INSTRUCTIONCODE = CC.INSTRUCTIONCODE)"
		
		Execute @ErrorCode=sp_executesql @sSQLString
	End

	-------- Create table of Inprotech Only records (only contains live records) -------------------
	If exists(select * from sysobjects where name = 'CPASTAR_LIVEINPROTECHONLY')
	and @ErrorCode=0
	Begin
		Set @sSQLString="drop table CPASTAR_LIVEINPROTECHONLY"
		Execute @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		create table CPASTAR_LIVEINPROTECHONLY
		(PropertyName nvarchar (50),
		RenewalStatus nvarchar(100),
		InprotechStatus nvarchar(100),
		StartPayDate datetime,
		StopPayDate datetime,
		StopPayReason nvarchar(20),
		IRN nvarchar(50),
		FileNumber nvarchar(15),
		CountryCode nvarchar(3),
		Category nvarchar(50), 
		ApplicationNo nvarchar(40), 
		RegistrationNo nvarchar(40), 
		ApplicationDate datetime,
		RegistrationDate datetime,
		Owner nvarchar(254),
		Instructor nvarchar(254),
		Office nvarchar(80),
		ClientsReference nvarchar(35),
		TitleStarts nvarchar(35),
		Instruction nvarchar(50),
		CASEID int, 
		BATCHNO int,
		BATCHDATE datetime,
		INSTRUCTIONSENDFLAG bit default 0,
		TEMPID  integer identity(1,1))"
		
		Execute @ErrorCode=sp_executesql @sSQLString
	End

-------- Add Inprotech Only records (no match found on CPA)---------
	If @ErrorCode=0
	Begin
		Set @sSQLString="	
		insert into CPASTAR_LIVEINPROTECHONLY
		select distinct T.PROPERTYNAME,	SR.INTERNALDESC, S.INTERNALDESC,
			isnull(ST.EVENTDATE, ST.EVENTDUEDATE), isnull(SP.EVENTDATE, SP.EVENTDUEDATE), 
			case C.STOPPAYREASON when 'A' then 'Abandoned'
			when 'C' then 'Other Channels'
			when 'U' then 'Unspecified'
			else C.STOPPAYREASON end ,
			C.IRN, null, -- FileNumber will be updated as an extra step later
			C.COUNTRYCODE, CC.CASECATEGORYDESC, ONA.OFFICIALNUMBER, ONR.OFFICIALNUMBER,
			CEA.EVENTDATE, CER.EVENTDATE, NP.NAME, isnull( NR.NAME, N.NAME), O.DESCRIPTION,
			CASE WHEN(C.PROPERTYTYPE='T') THEN left(CIN.REFERENCENO,35)
			ELSE left(isnull(CIN.REFERENCENO, replace(replace(C.TITLE,char(13)+char(10),' '),char(9),' ')),35) END, 
			rtrim(substring(C.TITLE,1,35)), CI.DESCRIPTION,
			C.CASEID, CS.BATCHNO, CS.BATCHDATE, CI.INSTRUCTIONSENDFLAG"
		-- Single string would be truncated
		Set @sSQLString1="
		from	CASES C
		left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID = C.CASEID)
		left join CPAPORTFOLIO CPA on (CPA.CASEID = C.CASEID)
		--	left join CPAPORTFOLIO CPAPRO on (CPAPRO.PROPOSEDIRN  = (case when "+cast(@sCPAUseClientCaseCode as varchar)+" = 1
		left join CPAPORTFOLIO CPAPRO on (CPAPRO.PROPOSEDIRN  = (case when "+cast(@sCPAUseCaseidAsCaseCode as varchar)+" = 1

													then cast (C.CASEID as varchar(15))
													else C.IRN end))
		left join PROPERTYTYPE T on (T.PROPERTYTYPE = C.PROPERTYTYPE)
		left join STATUS S on (S.STATUSCODE = C.STATUSCODE)
		left join PROPERTY P       on (P.CASEID=C.CASEID)
		left join STATUS SR        on (SR.STATUSCODE=P.RENEWALSTATUS)
		left join OFFICIALNUMBERS ONA	on (ONA.CASEID=C.CASEID
					and ONA.NUMBERTYPE=(select min(A6.NUMBERTYPE)
								from OFFICIALNUMBERS A6
								where A6.CASEID=ONA.CASEID
								and   A6.NUMBERTYPE in ("+@sApplicationNumberType+"))
					and ONA.ISCURRENT=1
					and ONA.OFFICIALNUMBER=(select max(A1.OFFICIALNUMBER)
								from OFFICIALNUMBERS A1
								where A1.CASEID=ONA.CASEID
								and   A1.NUMBERTYPE=ONA.NUMBERTYPE	
								and   A1.ISCURRENT=1))
		left join OFFICIALNUMBERS ONR	on (ONR.CASEID=C.CASEID
					and ONR.NUMBERTYPE=(select min(R9.NUMBERTYPE)
								from OFFICIALNUMBERS R9
								where R9.CASEID=ONR.CASEID
								and   R9.NUMBERTYPE in ("+@sRegistrationNumberType+"))
					and ONR.ISCURRENT=1
					and ONR.OFFICIALNUMBER=(select max(R1.OFFICIALNUMBER)
								from OFFICIALNUMBERS R1
								where R1.CASEID=ONR.CASEID
								and   R1.NUMBERTYPE=ONR.NUMBERTYPE	
								and   R1.ISCURRENT=1))
		left join CASEEVENT CER on (CER.CASEID = C.CASEID
					   and CER.EVENTNO = "+cast(@nRegistrationEventNo as varchar)+" )
		left join CASEEVENT CEA on (CEA.CASEID = C.CASEID
					   and CEA.EVENTNO = "+cast(@nApplicationEventNo as varchar)+" )
		left join CASENAME CN on (CN.CASEID = C.CASEID
					and   CN.NAMETYPE = 'I' 
					and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		left join NAME N on N.NAMENO = CN.NAMENO
		left join CASENAME CNR on (CNR.CASEID = C.CASEID
					and   CNR.NAMETYPE = 'R' 
					and  (CNR.EXPIRYDATE is null or CNR.EXPIRYDATE>getdate()))
		left join NAME NR on NR.NAMENO = CNR.NAMENO
		left join CASENAME CNP on (CNP.CASEID = C.CASEID
					and (CNP.NAMETYPE = 'O')
					and CNP.SEQUENCE = (select min (SEQUENCE) 
							   from CASENAME CNP2
							   where CNP2.CASEID = CNP.CASEID
								   and CNP2.NAMETYPE = CNP.NAMETYPE))
		left join NAME NP on NP.NAMENO = CNP.NAMENO
		left join CASEEVENT ST     on (ST.CASEID=C.CASEID
		 			   and ST.EVENTNO=  "+cast(@nCPAStartEventNo as varchar)+")
		left join CASEEVENT SP     on (SP.CASEID=C.CASEID
		 			   and SP.EVENTNO= "+cast(@nCPAStopEventNo as varchar)+")
		left join CPASEND CS	on (CS.CASEID=C.CASEID 
					and CS.BATCHNO = (select max(CS1.BATCHNO) 
							from CPASEND CS1 
							where CS1.CASEID=C.CASEID))
		left join OFFICE O	on (O.OFFICEID = C.OFFICEID)
		left join CASECATEGORY CC on (CC.CASETYPE = C.CASETYPE
					and CC.CASECATEGORY = C.CASECATEGORY)
		left join CASENAME CIN		on (CIN.CASEID=C.CASEID
					and CIN.EXPIRYDATE is null
					and CIN.NAMETYPE=(select max(CIN1.NAMETYPE)
							 from CASENAME CIN1
							 where CIN1.CASEID=C.CASEID
							 and CIN1.EXPIRYDATE is null
							 and CIN1.NAMETYPE in ('R','I')))
		where  C.REPORTTOTHIRDPARTY=1
		and isnull(S.LIVEFLAG,1)=1
		and isnull(SR.LIVEFLAG,1)=1
		--and C.STOPPAYREASON is null -- include cases to be cleaned up breakdown in report
		and (CPA.PORTFOLIONO is null
		and CPAPRO.PORTFOLIONO is null)"

		Exec (@sSQLString+@sSQLString1)
		Select	@ErrorCode=@@Error
	End


	-------- Create table of CPA records (matched and not matched)---------
	If exists(select * from sysobjects where name = 'CPASTAR_MATCHEDPORTFOLIO')
	and @ErrorCode=0
	Begin
		Set @sSQLString="drop table CPASTAR_MATCHEDPORTFOLIO"
		Execute @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString=" 
		create table CPASTAR_MATCHEDPORTFOLIO
		(PropertyType nvarchar (30),
		Responsibility nvarchar(20),
		CPAStatus nvarchar (20),
		CPAEventStatus nvarchar (20),
		InprotechLiveFlag nvarchar (30),
		InprotechSendFlag nvarchar (20),
		RenewalStatus nvarchar(100),
		InprotechStatus nvarchar(100),
		StartPayDate datetime,
		StopPayDate datetime,
		StopPayReason nvarchar(20),
		IRN nvarchar(50),
		PROPOSEDIRN nvarchar(30),
		CASECODE nvarchar(30),
		FileNumber nvarchar(15),
		CPATypeCode nvarchar(10),
		CPATypeName nvarchar(20),
		CPACountryCode nvarchar(10), 
		CPAApplicationNo nvarchar(20), 
		CPARegistrationNo nvarchar(20), 
		CPAApplicationDate nvarchar(20),
		CPAGrantDate datetime,
		CPAProprietor nvarchar(120),
		Owner nvarchar(254),
		Instructor nvarchar(254),
		CPAAccount int,
		Office nvarchar(80),
		ClientsReference nvarchar(35),
		CPAClientRef nvarchar(35),
		Instruction nvarchar(50),
		PORTFOLIONO int, 
		IPRURN nvarchar(10),
		CASEID int, 
		BATCHNO int,
		BATCHDATE datetime,
		MULTILIVEFLAG int default 0,
		MATCHTYPE nvarchar(20),
		TEMPID  integer identity(1,1))"
		
		Execute @ErrorCode=sp_executesql @sSQLString
	End

	----------------------- Add records matched by CASEID -------------------------------
	-- By definition if there is a CASEID there is a match of the IRN (or CASEID) 
	-- with the AGENTCASECODE (or CLIENTCASECODE) because this is checked 
	-- and populated when the portfolio is loaded
	If @ErrorCode=0
	Begin
		Set @sSQLString="	
		insert into CPASTAR_MATCHEDPORTFOLIO
		select distinct case when (CPA.TYPECODE in ('10','15','20','82','2Y','3Y','5Y','A3','AC','AD','AG',
					'AH','AI','AO','AP','AR','AS','AU','AV','BB','BF','BS','CH','CI','CL','CP',
					'CR','CS','CT','CU','CY','DG','DO','DP','DR','DV','E4','EA','EG','EI','EK',
					'EL','EM','EN','EP','ER','ES','EU','EX','EZ','FD','FF','FN','FO','FP','GE',
					'GF','GL','GN','GP','GR','GV','GZ','HA','HE','HG','HL','HN','HP','HR','HU',
					'IO','IP','IR','IS','JA','JB','JC','JD','JP','JW','JX','JY','JZ','KM','KN',
					'KS','KT','KU','LE','LG','LI','LJ','LL','LN','LR','LS','LU','LV','LX','ML',
					'MT','N2','N8','NG','NJ','NO','NP','NS','NW','NX','NY','OE','OG','OL','OM',
					'OP','OR','P-','P#','P1','P3','PA','PB','PC','PD','PE','PF','PG','PH','PI',
					'PJ','PK','PL','PM','PN','PO','PP','PQ','PR','PS','PT','PV','PW','PX','PY',
					'PZ','QE','QL','QS','RE','RO','RP','RR','RS','RX','RY','RZ','S1','S2','S3',
					'S9','SA','SB','SC','SE','SF','SG','SH','SI','SJ','SK','SO','SP','SQ','SR',
					'SU','SV','SW','SX','SY','SZ','TD','TE','TL','TP','TY','U1','U2','U3','U4',
					'UE','UF','UG','UJ','UK','UL','UM','UN','UP','UT','UU','UV','UW','UX','UZ',
					'VA','VB','VC','VF','VP','VQ','VR','VT','VZ','WA','WG','WL','WO','WS','XC',
					'ZB','ZE','ZL','ZN','ZP','ZU','ZZ'))
				then 'Patents'
				when (CPA.TYPECODE in ('2A','3A','4A','5A','3C','1T','2T','3T','4T','6Y',
					'A1','A2','A5','A6','AF','AL','AM','AN','AT','CE','CM','CN','CO','D1','DF',
					'DI','DU','EV','FI','FR','HT','IC','IM','IN','J5','JF','JR','L2','LC','LO',
					'MG','MP','NF','OU','OV','OX','PU','RA','RN','RT','RU','S5','SS','ST','T1',
					'T2','T3','T4','T5','T6','T7','TA','TC','TF','TI','TK','TM','TR','TS','TT',
					'TU','TX','XX','ZA'))
				then 'Trademarks'
				when (CPA.TYPECODE in ('1D','A9','AQ','D0','D2','D3','D4','D5','D6','D7','D8','D9',
					'DA','DB','DC','DD','DE','DH','DJ','DK','DL','DM','DN','DQ','DS','DT','DW',
					'DX','DY','DZ','FL','GA','GD','GM','GX','HD','KD','MD','MJ','OD','RD','SD',
					'SL','SM','SN','XD','Z1','Z2','Z3','Z4','ZD'))
				then 'Designs'
				else CPA.TYPECODE + ' '+ CPA.TYPENAME+' '+IPCOUNTRYCODE end, 
		 case when (RESPONSIBLEPARTY='A') then 'Agent responsible'
				when (RESPONSIBLEPARTY='C') then 'Client responsible'
				else 'Unclear' end,
		 case when (STATUSINDICATOR ='L') then 'Live at CPA'
				when (STATUSINDICATOR='D') then 'Dead at CPA'
				when (STATUSINDICATOR='T') then 'Transferred'
				else 'Unclear' end,
		case when CE.EVENTCODE='LV' then 'Live'
			when CE.EVENTCODE='PY' then 'Pay (Live)'
			when CE.EVENTCODE='AB' then 'Abandoned'
			when CE.EVENTCODE='CH' then 'Channels'
			when CE.EVENTCODE='EX' then 'Expired'
			when CE.EVENTCODE='LP' then 'Lapsed'
			when CE.EVENTCODE='RM' then 'Remove'
			else 'Unclear' end,
		case when (isnull(S.LIVEFLAG,1)=0 or isnull(SR.LIVEFLAG,1)=0) then 'Dead(or Dead Renewal)'
				else 'Live on Inprotech' end,
		case when (REPORTTOTHIRDPARTY=1 and CI.INSTRUCTIONSENDFLAG=1) then 'Flagged'
			else 'Not flagged' end,
		 SR.INTERNALDESC,  S.INTERNALDESC,
		isnull(ST.EVENTDATE, ST.EVENTDUEDATE), isnull(SP.EVENTDATE, SP.EVENTDUEDATE), 
		case C.STOPPAYREASON when 'A' then 'Abandoned'
		when 'C' then 'Other Channels'
		when 'U' then 'Unspecified'
		else C.STOPPAYREASON end,
		C.IRN, CPA.PROPOSEDIRN, 
		--case when @sCPAUseClientCaseCode = 1
		case when "+cast(@sCPAUseClientCaseCode as varchar)+" = 1
		then CPA.CLIENTCASECODE else CPA.AGENTCASECODE end,
		null, 
		-- FileNumber will be updated as an extra step later
		CPA.TYPECODE, CPA.TYPENAME, CPA.IPCOUNTRYCODE, 
		CPA.APPLICATIONNO, CPA.REGISTRATIONNO, 
		CPA.APPLICATIONDATE, CPA.GRANTDATE,
		CPA.PROPRIETOR, NP.NAME, isnull( NR.NAME, N.NAME), 
		CPA.CLIENTNO, O.DESCRIPTION, "
		-- Single string would be truncated
		Set @sSQLString1="	
		CASE WHEN(C.PROPERTYTYPE='T') THEN left(CIN.REFERENCENO,35)
		ELSE left(isnull(CIN.REFERENCENO, replace(replace(C.TITLE,char(13)+char(10),' '),char(9),' ')),35) END, 
		case when (patindex('%:%',CPA.CLIENTREF))>=1 
		then rtrim( substring (CPA.CLIENTREF, 1, (patindex('%:%',CPA.CLIENTREF)-1)))
		else ltrim( CPA.CLIENTREF) end, CI.DESCRIPTION, 
		CPA.PORTFOLIONO, CPA.IPRURN,
		C.CASEID, CS.BATCHNO, CS.BATCHDATE, 0, 'IRN'
		from CPAPORTFOLIO CPA
		join CASES C on C.CASEID = CPA.CASEID
		left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID = C.CASEID)
		left join STATUS S on (S.STATUSCODE = C.STATUSCODE)
		left join PROPERTY P on (P.CASEID=C.CASEID)
		left join STATUS SR on (SR.STATUSCODE=P.RENEWALSTATUS)
		left join CPAEVENT CE on (CE.IPRURN = CPA.IPRURN
		--			find the most recent status
					 and CE.BATCHNO = (select max (BATCHNO)
							from CPAEVENT 
							where IPRURN = CE.IPRURN
							and EVENTCODE in ('LV','PY','AB','CH','EX','LP','RM'))
					 and CE.EVENTCODE in ('LV','PY','AB','CH','EX','LP','RM'))
		left join CASENAME CN on (CN.CASEID = C.CASEID
					and   CN.NAMETYPE = 'I' 
					and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		left join NAME N on N.NAMENO = CN.NAMENO
		left join CASENAME CNR on (CNR.CASEID = C.CASEID
					and   CNR.NAMETYPE = 'R' 
					and  (CNR.EXPIRYDATE is null or CNR.EXPIRYDATE>getdate()))
		left join NAME NR on NR.NAMENO = CNR.NAMENO
		left join CASENAME CNP on (CNP.CASEID = C.CASEID
					and (CNP.NAMETYPE = 'O')
					and CNP.SEQUENCE = (select min (SEQUENCE) 
							   from CASENAME CNP2
							   where CNP2.CASEID = CNP.CASEID
								   and CNP2.NAMETYPE = CNP.NAMETYPE))
		left join NAME NP on NP.NAMENO = CNP.NAMENO
		left join CASEEVENT ST     on (ST.CASEID=C.CASEID
		 			   --and ST.EVENTNO= @nCPAStartEventNo)
						and ST.EVENTNO= "+cast(@nCPAStartEventNo as varchar)+")
		left join CASEEVENT SP     on (SP.CASEID=C.CASEID
		 			   --and SP.EVENTNO= @nCPAStopEventNo)
						and ST.EVENTNO= "+cast(@nCPAStopEventNo as varchar)+")
		left join CPASEND CS	on (CS.CASEID=C.CASEID 
					and CS.BATCHNO = (select max(CS1.BATCHNO) 
							from CPASEND CS1 
							where CS1.CASEID=C.CASEID))
		left join OFFICE O	on (O.OFFICEID = C.OFFICEID)
		left join CASENAME CIN		on (CIN.CASEID=C.CASEID
					and CIN.EXPIRYDATE is null
					and CIN.NAMETYPE=(select max(CIN1.NAMETYPE)
							 from CASENAME CIN1
							 where CIN1.CASEID=C.CASEID
							 and CIN1.EXPIRYDATE is null
							 and CIN1.NAMETYPE in ('R','I')))"

		Exec (@sSQLString+@sSQLString1)
		Select	@ErrorCode=@@Error
	End

	----------------------- Add records matched by PROPOSEDIRN -------------------------------
	-- This column should have been previously populated by running the IRN matching 
	If @ErrorCode=0
	Begin
		Set @sSQLString=" 
		insert into CPASTAR_MATCHEDPORTFOLIO
		select distinct case when (CPA.TYPECODE in ('10','15','20','82','2Y','3Y','5Y','A3','AC','AD','AG',
					'AH','AI','AO','AP','AR','AS','AU','AV','BB','BF','BS','CH','CI','CL','CP',
					'CR','CS','CT','CU','CY','DG','DO','DP','DR','DV','E4','EA','EG','EI','EK',
					'EL','EM','EN','EP','ER','ES','EU','EX','EZ','FD','FF','FN','FO','FP','GE',
					'GF','GL','GN','GP','GR','GV','GZ','HA','HE','HG','HL','HN','HP','HR','HU',
					'IO','IP','IR','IS','JA','JB','JC','JD','JP','JW','JX','JY','JZ','KM','KN',
					'KS','KT','KU','LE','LG','LI','LJ','LL','LN','LR','LS','LU','LV','LX','ML',
					'MT','N2','N8','NG','NJ','NO','NP','NS','NW','NX','NY','OE','OG','OL','OM',
					'OP','OR','P-','P#','P1','P3','PA','PB','PC','PD','PE','PF','PG','PH','PI',
					'PJ','PK','PL','PM','PN','PO','PP','PQ','PR','PS','PT','PV','PW','PX','PY',
					'PZ','QE','QL','QS','RE','RO','RP','RR','RS','RX','RY','RZ','S1','S2','S3',
					'S9','SA','SB','SC','SE','SF','SG','SH','SI','SJ','SK','SO','SP','SQ','SR',
					'SU','SV','SW','SX','SY','SZ','TD','TE','TL','TP','TY','U1','U2','U3','U4',
					'UE','UF','UG','UJ','UK','UL','UM','UN','UP','UT','UU','UV','UW','UX','UZ',
					'VA','VB','VC','VF','VP','VQ','VR','VT','VZ','WA','WG','WL','WO','WS','XC',
					'ZB','ZE','ZL','ZN','ZP','ZU','ZZ'))
				then 'Patents'
				when (CPA.TYPECODE in ('2A','3A','4A','5A','3C','1T','2T','3T','4T','6Y',
					'A1','A2','A5','A6','AF','AL','AM','AN','AT','CE','CM','CN','CO','D1','DF',
					'DI','DU','EV','FI','FR','HT','IC','IM','IN','J5','JF','JR','L2','LC','LO',
					'MG','MP','NF','OU','OV','OX','PU','RA','RN','RT','RU','S5','SS','ST','T1',
					'T2','T3','T4','T5','T6','T7','TA','TC','TF','TI','TK','TM','TR','TS','TT',
					'TU','TX','XX','ZA'))
				then 'Trademarks'
				when (CPA.TYPECODE in ('1D','A9','AQ','D0','D2','D3','D4','D5','D6','D7','D8','D9',
					'DA','DB','DC','DD','DE','DH','DJ','DK','DL','DM','DN','DQ','DS','DT','DW',
					'DX','DY','DZ','FL','GA','GD','GM','GX','HD','KD','MD','MJ','OD','RD','SD',
					'SL','SM','SN','XD','Z1','Z2','Z3','Z4','ZD'))
				then 'Designs'
				else CPA.TYPECODE + ' '+ CPA.TYPENAME+' '+IPCOUNTRYCODE end, 
		 case when (RESPONSIBLEPARTY='A') then 'Agent responsible'
				when (RESPONSIBLEPARTY='C') then 'Client responsible'
				else 'Unclear' end,
		 case when (STATUSINDICATOR ='L') then 'Live at CPA'
				when (STATUSINDICATOR='D') then 'Dead at CPA'
				when (STATUSINDICATOR='T') then 'Transferred'
				else 'Unclear' end,
		case when CE.EVENTCODE='LV' then 'Live'
			when CE.EVENTCODE='PY' then 'Pay (Live)'
			when CE.EVENTCODE='AB' then 'Abandoned'
			when CE.EVENTCODE='CH' then 'Channels'
			when CE.EVENTCODE='EX' then 'Expired'
			when CE.EVENTCODE='LP' then 'Lapsed'
			when CE.EVENTCODE='RM' then 'Remove'
			else 'Unclear' end,
		case when (isnull(S.LIVEFLAG,1)=0 or isnull(SR.LIVEFLAG,1)=0) then 'Dead(or Dead Renewal)'
				else 'Live on Inprotech' end,
		case when (REPORTTOTHIRDPARTY=1 and CI.INSTRUCTIONSENDFLAG=1) then 'Flagged'
			else 'Not flagged' end,
		 SR.INTERNALDESC,  S.INTERNALDESC,
		isnull(ST.EVENTDATE,ST.EVENTDUEDATE), isnull(SP.EVENTDATE, SP.EVENTDUEDATE), 
		case C.STOPPAYREASON when 'A' then 'Abandoned'
		when 'C' then 'Other Channels'
		when 'U' then 'Unspecified'
		else C.STOPPAYREASON end,
		C.IRN, CPA.PROPOSEDIRN, 
		--case when @sCPAUseClientCaseCode = 1
		case when "+cast(@sCPAUseClientCaseCode as varchar)+" = 1
		then CPA.CLIENTCASECODE else CPA.AGENTCASECODE end,
		null, -- FileNumber will be updated as an extra step later
		CPA.TYPECODE, CPA.TYPENAME, CPA.IPCOUNTRYCODE, 
		CPA.APPLICATIONNO, CPA.REGISTRATIONNO, 
		CPA.APPLICATIONDATE, CPA.GRANTDATE,
		CPA.PROPRIETOR, NP.NAME, isnull( NR.NAME, N.NAME), 
		CPA.CLIENTNO, O.DESCRIPTION,  "
		-- Single string would be truncated
		Set @sSQLString1="	
		CASE WHEN(C.PROPERTYTYPE='T') THEN left(CIN.REFERENCENO,35)
		ELSE left(isnull(CIN.REFERENCENO, replace(replace(C.TITLE,char(13)+char(10),' '),char(9),' ')),35) END, 
		case when (patindex('%:%',CPA.CLIENTREF))>=1 
		then rtrim( substring (CPA.CLIENTREF, 1, (patindex('%:%',CPA.CLIENTREF)-1)))
		else ltrim( CPA.CLIENTREF) end,CI.DESCRIPTION,
		CPA.PORTFOLIONO, CPA.IPRURN, 
		C.CASEID, CS.BATCHNO, CS.BATCHDATE, 0, 'Number'
		from CPAPORTFOLIO CPA
		--join CASES C on (case when @sCPAUseCaseidAsCaseCode = 1
		join CASES C on (case when "+cast(@sCPAUseCaseidAsCaseCode as varchar)+" = 1
							then cast (C.CASEID as varchar(15))
							else C.IRN end = CPA.PROPOSEDIRN)
		left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID = C.CASEID)
		left join STATUS S on S.STATUSCODE = C.STATUSCODE
		left join PROPERTY P       on (P.CASEID=C.CASEID)
		left join STATUS SR        on (SR.STATUSCODE=P.RENEWALSTATUS)
		left join CPAEVENT CE on (CE.IPRURN = CPA.IPRURN
		--			find the most recent status
					 and CE.BATCHNO = (select max (BATCHNO)
							from CPAEVENT 
							where IPRURN = CE.IPRURN
							and EVENTCODE in ('LV','PY','AB','CH','EX','LP','RM'))
					 and CE.EVENTCODE in ('LV','PY','AB','CH','EX','LP','RM'))
		left join CASENAME CN on (CN.CASEID = C.CASEID
					and   CN.NAMETYPE = 'I' 
					and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		left join NAME N on N.NAMENO = CN.NAMENO
		left join CASENAME CNR on (CNR.CASEID = C.CASEID
					and   CNR.NAMETYPE = 'R' 
				and  (CNR.EXPIRYDATE is null or CNR.EXPIRYDATE>getdate()))
		left join NAME NR on NR.NAMENO = CNR.NAMENO
		left join CASENAME CNP on (CNP.CASEID = C.CASEID
					and (CNP.NAMETYPE = 'O')
					and CNP.SEQUENCE = (select min (SEQUENCE) 
							   from CASENAME CNP2
							   where CNP2.CASEID = CNP.CASEID
								   and CNP2.NAMETYPE = CNP.NAMETYPE))
		left join NAME NP on NP.NAMENO = CNP.NAMENO
		left join CASEEVENT ST     on (ST.CASEID=C.CASEID
		 			   --and ST.EVENTNO= @nCPAStartEventNo)
						and ST.EVENTNO= "+cast(@nCPAStartEventNo as varchar)+")
		left join CASEEVENT SP     on (SP.CASEID=C.CASEID
		 			   --and SP.EVENTNO= @nCPAStopEventNo)
						and ST.EVENTNO= "+cast(@nCPAStopEventNo as varchar)+")
		left join CPASEND CS	on (CS.CASEID=C.CASEID 
					and CS.BATCHNO = (select max(CS1.BATCHNO) 
							from CPASEND CS1 
							where CS1.CASEID=C.CASEID))
		left join OFFICE O	on (O.OFFICEID = C.OFFICEID)
		left join CASENAME CIN		on (CIN.CASEID=C.CASEID
					and CIN.EXPIRYDATE is null
					and CIN.NAMETYPE=(select max(CIN1.NAMETYPE)
							 from CASENAME CIN1
							 where CIN1.CASEID=C.CASEID
							 and CIN1.EXPIRYDATE is null
							 and CIN1.NAMETYPE in ('R','I')))
		where CPA.CASEID is null"

		Exec (@sSQLString+@sSQLString1)
		Select	@ErrorCode=@@Error
	End	
	---------------- Add non-matched CPA records (neither CASEID nor PROPOSEDIRN) ----------------------------------------
	If @ErrorCode=0
	Begin
		Set @sSQLString=" 
		insert into CPASTAR_MATCHEDPORTFOLIO
		(PropertyType,
		Responsibility,
		CPAStatus,
		CPAEventStatus,
		CASECODE,
		CPATypeCode,
		CPATypeName,
		CPACountryCode, 
		CPAApplicationNo, 
		CPARegistrationNo, 
		CPAApplicationDate,
		CPAGrantDate,
		CPAProprietor,
		CPAAccount,
		CPAClientRef,
		PORTFOLIONO, 
		IPRURN)
		select distinct case when (CPA.TYPECODE in ('10','15','20','82','2Y','3Y','5Y','A3','AC','AD','AG',
					'AH','AI','AO','AP','AR','AS','AU','AV','BB','BF','BS','CH','CI','CL','CP',
					'CR','CS','CT','CU','CY','DG','DO','DP','DR','DV','E4','EA','EG','EI','EK',
					'EL','EM','EN','EP','ER','ES','EU','EX','EZ','FD','FF','FN','FO','FP','GE',
					'GF','GL','GN','GP','GR','GV','GZ','HA','HE','HG','HL','HN','HP','HR','HU',
					'IO','IP','IR','IS','JA','JB','JC','JD','JP','JW','JX','JY','JZ','KM','KN',
					'KS','KT','KU','LE','LG','LI','LJ','LL','LN','LR','LS','LU','LV','LX','ML',
					'MT','N2','N8','NG','NJ','NO','NP','NS','NW','NX','NY','OE','OG','OL','OM',
					'OP','OR','P-','P#','P1','P3','PA','PB','PC','PD','PE','PF','PG','PH','PI',
					'PJ','PK','PL','PM','PN','PO','PP','PQ','PR','PS','PT','PV','PW','PX','PY',
					'PZ','QE','QL','QS','RE','RO','RP','RR','RS','RX','RY','RZ','S1','S2','S3',
					'S9','SA','SB','SC','SE','SF','SG','SH','SI','SJ','SK','SO','SP','SQ','SR',
					'SU','SV','SW','SX','SY','SZ','TD','TE','TL','TP','TY','U1','U2','U3','U4',
					'UE','UF','UG','UJ','UK','UL','UM','UN','UP','UT','UU','UV','UW','UX','UZ',
					'VA','VB','VC','VF','VP','VQ','VR','VT','VZ','WA','WG','WL','WO','WS','XC',
					'ZB','ZE','ZL','ZN','ZP','ZU','ZZ'))
				then 'Patents'
				when (CPA.TYPECODE in ('2A','3A','4A','5A','3C','1T','2T','3T','4T','6Y',
					'A1','A2','A5','A6','AF','AL','AM','AN','AT','CE','CM','CN','CO','D1','DF',
					'DI','DU','EV','FI','FR','HT','IC','IM','IN','J5','JF','JR','L2','LC','LO',
					'MG','MP','NF','OU','OV','OX','PU','RA','RN','RT','RU','S5','SS','ST','T1',
					'T2','T3','T4','T5','T6','T7','TA','TC','TF','TI','TK','TM','TR','TS','TT',
					'TU','TX','XX','ZA'))
				then 'Trademarks'
				when (CPA.TYPECODE in ('1D','A9','AQ','D0','D2','D3','D4','D5','D6','D7','D8','D9',
					'DA','DB','DC','DD','DE','DH','DJ','DK','DL','DM','DN','DQ','DS','DT','DW',
					'DX','DY','DZ','FL','GA','GD','GM','GX','HD','KD','MD','MJ','OD','RD','SD',
					'SL','SM','SN','XD','Z1','Z2','Z3','Z4','ZD'))
				then 'Designs'
				else CPA.TYPECODE + ' '+ CPA.TYPENAME+' '+IPCOUNTRYCODE end, 
		 case when (RESPONSIBLEPARTY='A') then 'Agent responsible'
				when (RESPONSIBLEPARTY='C') then 'Client responsible'
				else 'Unclear' end ,
		 case when (STATUSINDICATOR ='L') then 'Live at CPA'
				when (STATUSINDICATOR='D') then 'Dead at CPA'
				when (STATUSINDICATOR='T') then 'Transferred'
				else 'Unclear' end,
		case when CE.EVENTCODE='LV' then 'Live'
			when CE.EVENTCODE='PY' then 'Pay (Live)'
			when CE.EVENTCODE='AB' then 'Abandoned'
			when CE.EVENTCODE='CH' then 'Channels'
			when CE.EVENTCODE='EX' then 'Expired'
			when CE.EVENTCODE='LP' then 'Lapsed'
			when CE.EVENTCODE='RM' then 'Remove'
			else 'Unclear' end,
		--case when @sCPAUseClientCaseCode = 1
		case when "+cast(@sCPAUseClientCaseCode as varchar)+" = 1
		then CPA.CLIENTCASECODE else CPA.AGENTCASECODE end,
		CPA.TYPECODE , CPA.TYPENAME , CPA.IPCOUNTRYCODE, 
		CPA.APPLICATIONNO, CPA.REGISTRATIONNO, 
		CPA.APPLICATIONDATE, CPA.GRANTDATE,
		CPA.PROPRIETOR, CPA.CLIENTNO,
		case when (patindex('%:%',CPA.CLIENTREF))>=1 
		then rtrim( substring (CPA.CLIENTREF, 1, (patindex('%:%',CPA.CLIENTREF)-1)))
		else ltrim( CPA.CLIENTREF) end,
		CPA.PORTFOLIONO, CPA.IPRURN"
		-- Single string would be truncated
		Set @sSQLString1="	
		from CPAPORTFOLIO CPA
		left join CASES C on C.CASEID = CPA.CASEID
		--left join CASES CP on (case when @sCPAUseCaseidAsCaseCode = 1
		left join CASES CP on (case when "+cast(@sCPAUseCaseidAsCaseCode as varchar)+" = 1
							then cast (CP.CASEID as varchar(15))
							else CP.IRN end = CPA.PROPOSEDIRN)
		left join CPAEVENT CE on (CE.IPRURN = CPA.IPRURN
		--			find the most recent status
					 and CE.BATCHNO = (select max (BATCHNO)
							from CPAEVENT 
							where IPRURN = CE.IPRURN
							and EVENTCODE in ('LV','PY','AB','CH','EX','LP','RM'))
					 and CE.EVENTCODE in ('LV','PY','AB','CH','EX','LP','RM'))
		where coalesce (C.IRN, CP.IRN) is null"

		Exec (@sSQLString+@sSQLString1)
		Select	@ErrorCode=@@Error
	End	

-------- Update the FileNumber for all CPASTAR_LIVEINPROTECHONLY records (using method from cpa_InsertCPAComplete)---------
If @ErrorCode=0
Begin
	If @sFileNumberType='IRN'
	begin
		-- SQA13731 Save the IRN in the FileNumber field if option set to do so.
		Set @sSQLString="
		Update CPASTAR
		Set FileNumber=left(C.IRN,15)
		From CPASTAR_LIVEINPROTECHONLY CPASTAR
		join CASES C		on (C.CASEID=CPASTAR.CASEID)"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end
	Else If @sFileNumberType='CAT'
	begin
		-- SQA10482 Get the Case Category description and save it in the FileNumber column
		--	    if a specific Number Type has not been defined as a Site Control.
		Set @sSQLString="
		Update CPASTAR
		Set FileNumber=left(VC.CASECATEGORYDESC,15)
		From CPASTAR_LIVEINPROTECHONLY CPASTAR
		join CASES C		on (C.CASEID=CPASTAR.CASEID)
		join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=C.PROPERTYTYPE
					and VC.CASETYPE=C.CASETYPE
					and VC.CASECATEGORY=C.CASECATEGORY
					and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)
							    from VALIDCATEGORY VC1
							    where VC1.PROPERTYTYPE=C.PROPERTYTYPE
							    and VC1.CASETYPE=C.CASETYPE
							    and VC1.CASECATEGORY=C.CASECATEGORY
							    and VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end

	-- If this site has specified a particular Number Type to use for the File Number
	-- then extract this into the FileNumber field
	Else If @sFileNumberType is not null
	Begin
		Set @sSQLString="
		Update CPASTAR
		Set FileNumber=left(O.OFFICIALNUMBER,15)
		From CPASTAR_LIVEINPROTECHONLY CPASTAR
		join OFFICIALNUMBERS O	on (O.CASEID=CPASTAR.CASEID
					and O.NUMBERTYPE=@sFileNumberType
					and O.ISCURRENT=1
					and O.OFFICIALNUMBER=(	select max(O1.OFFICIALNUMBER)
								from OFFICIALNUMBERS O1
								where O1.CASEID=O.CASEID
								and   O1.NUMBERTYPE=O.NUMBERTYPE	
								and   O1.ISCURRENT=1))"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sFileNumberType	nchar(1)',
						  @sFileNumberType=@sFileNumberType
	End
End
-------- Update the FileNumber for CPASTAR_MATCHEDPORTFOLIO records (using method from cpa_InsertCPAComplete)---------
If @ErrorCode=0
Begin
	If @sFileNumberType='IRN'
	begin
		-- SQA13731 Save the IRN in the FileNumber field if option set to do so.
		Set @sSQLString="
		Update CPASTAR
		Set FileNumber=left(C.IRN,15)
		From CPASTAR_MATCHEDPORTFOLIO CPASTAR
		join CASES C		on (C.CASEID=CPASTAR.CASEID)"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end
	Else If @sFileNumberType='CAT'
	begin
		-- SQA10482 Get the Case Category description and save it in the FileNumber column
		--	    if a specific Number Type has not been defined as a Site Control.
		Set @sSQLString="
		Update CPASTAR
		Set FileNumber=left(VC.CASECATEGORYDESC,15)
		From CPASTAR_MATCHEDPORTFOLIO CPASTAR
		join CASES C		on (C.CASEID=CPASTAR.CASEID)
		join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=C.PROPERTYTYPE
					and VC.CASETYPE=C.CASETYPE
					and VC.CASECATEGORY=C.CASECATEGORY
					and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)
							    from VALIDCATEGORY VC1
							    where VC1.PROPERTYTYPE=C.PROPERTYTYPE
							    and VC1.CASETYPE=C.CASETYPE
							    and VC1.CASECATEGORY=C.CASECATEGORY
							    and VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end

	-- If this site has specified a particular Number Type to use for the File Number
	-- then extract this into the FileNumber field
	Else If @sFileNumberType is not null
	Begin
		Set @sSQLString="
		Update CPASTAR
		Set FileNumber=left(O.OFFICIALNUMBER,15)
		From CPASTAR_MATCHEDPORTFOLIO CPASTAR
		join OFFICIALNUMBERS O	on (O.CASEID=CPASTAR.CASEID
					and O.NUMBERTYPE=@sFileNumberType
					and O.ISCURRENT=1
					and O.OFFICIALNUMBER=(	select max(O1.OFFICIALNUMBER)
								from OFFICIALNUMBERS O1
								where O1.CASEID=O.CASEID
								and   O1.NUMBERTYPE=O.NUMBERTYPE	
								and   O1.ISCURRENT=1))"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sFileNumberType	nchar(1)',
						  @sFileNumberType=@sFileNumberType
	End
End

	----------------------- Clean up matches ----------------------------------------
	-- Removes those showing no match which also match on file number (this may happen 
	-- because of indirect joins acting on duplicate records). 
	-- The file number match has been removed but keep this cleanup as a precaution.
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		delete from CPASTAR_MATCHEDPORTFOLIO
		where TEMPID in
		(
		select V.TEMPID from CPASTAR_MATCHEDPORTFOLIO V
		join CPASTAR_MATCHEDPORTFOLIO V2 on (V2.IPRURN = V.IPRURN
					and V2.PORTFOLIONO = V.PORTFOLIONO
					and V2.CASEID is not null)
		where V.CASEID is null
		)"
		Execute @ErrorCode=sp_executesql @sSQLString
	End
	
	-- Flag CPA Dead Cases joined to an Inprotech case if
	-- there is a live CPA case also joined to the same Inprotech case
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		update CPASTAR_MATCHEDPORTFOLIO
		set MATCHTYPE = 'Obsolete'  -- not live and at least one other live
		where TEMPID in
		(
		select distinct MP.TEMPID
		from CPASTAR_MATCHEDPORTFOLIO MP
		join CPASTAR_MATCHEDPORTFOLIO MPL on (MP.CASEID = MPL.CASEID
					 and MP.IPRURN <> MPL.IPRURN)
		join CPAPORTFOLIO V on (V.IPRURN = MP.IPRURN)
		join CPAPORTFOLIO VL on (VL.IPRURN = MPL.IPRURN)
		where V.STATUSINDICATOR  <> 'L' and VL.STATUSINDICATOR  = 'L'
		)"
		Execute @ErrorCode=sp_executesql @sSQLString
	End

	-- Flag multiple CPA Live Cases joined to one Inprotech case
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		update CPASTAR_MATCHEDPORTFOLIO
		set MULTILIVEFLAG = 1 -- live and at least one other live
		where TEMPID in
		(
		select distinct MP.TEMPID
		from CPASTAR_MATCHEDPORTFOLIO MP
		join CPASTAR_MATCHEDPORTFOLIO MPL on (MP.CASEID = MPL.CASEID
					 and MP.IPRURN <> MPL.IPRURN)
		join CPAPORTFOLIO V on (V.IPRURN = MP.IPRURN)
		join CPAPORTFOLIO VL on (VL.IPRURN = MPL.IPRURN)
		where V.STATUSINDICATOR = 'L' and VL.STATUSINDICATOR = 'L'
		)"
		Execute @ErrorCode=sp_executesql @sSQLString
	End

-- final end
End
Return @ErrorCode

go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cpa_ReportSTARPreparation to public
go

PRINT ''
PRINT '************************************************************************'
PRINT '****** STAR Preparation Stored Procedure successfully refreshed *******'
PRINT '************************************************************************'
PRINT ''