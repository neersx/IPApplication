-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetStandingInstructionsBulk
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetStandingInstructionsBulk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetStandingInstructionsBulk.'
	drop procedure dbo.cs_GetStandingInstructionsBulk
end
print '**** Creating procedure dbo.cs_GetStandingInstructionsBulk...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure [dbo].[cs_GetStandingInstructionsBulk] 
			@psInstructionTypes	nvarchar(max),	-- comma separated list of Instruction Type to be extracted
			@psCaseTableName	nvarchar(60)	-- name of table with CASEIDs to have their Instructions returned
as
-- PROCEDURE :	cs_GetStandingInstructionsBulk
-- VERSION :	15
-- DESCRIPTION:	A procedure to load a temporary table with the standing instructions
--		for all cases in another temporary table.
--		See also ip_PoliceGetStandingInstructions from which this procedure
--		was copied.
--
--		Input table (named in parameter @psCaseTableName) must have columns:
--			CASEID
--			SEQUENCENO (if SiteControl 'Polilcing Case Instructions' > 0 )
--
--		Output loaded into an already defined table with at least the
--		following data structure:
--		Create table #TEMPCASEINSTRUCTIONS (
--					CASEID			int		NOT NULL,
--					INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL, 
--					INSTRUCTIONCODE		smallint	NOT NULL)

-- MODIFICATION
-- Date		Who	SQA	Version	Change
-- ====         ===	=== 	=======	==========================================
-- 12 Feb 2007	MF			Procedure created
-- 25 Jan 2008	MF	15867	2	Logic error when sitecontrol 'Polilcing Case Instructions' is set to 0.
-- 10 Jul 2008	vql	16677	3	Variables not initialise correctly. EDE Input Amend report Issues.
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Dec 2009  AvdA	18297	5	Allow null CASEIDs (convenient in context of 18297) but only process non-null CASEIDs to avoid error.
-- 11 Mar 2010  AvdA	18536	6	Fix above change to avoid error.
-- 18 Mar 2010	MF	18556	7	ErrorCode was not being tested before execution of a statement which was allowing it to be reset to 0.
-- 19 May 2010	MF	18756	8	Performance improvement by separating the best fit on Names directly linked to Case from the default
--					instructions held against the Home Name.
-- 01 Jul 2010	MF	18758	9	Increase the column size of Instruction Type to allow for expanded list.
-- 05 Dec 2011	LP	R11070	10	Default standing instruction from Office Entity before falling back to HomeName
-- 01 Feb 2012	MF	R11870	11	RFC11070 failed testing.
-- 04 Apr 2016	MF	R59927	12	Use the first Name against a Case for a given NameType when determining standing instructions.
-- 20 Jul 2018	AvB	74627	13	Increase length of parameter @psInstructionTypes.
-- 07 Sep 2018	AV	74738	14	Set isolation level to read uncommited.
-- 26 Mar 2020	DL	DR-58353 15 Performance enhancement: Unable to create a batch via the CPA Interface Not Responding

set nocount on
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE		@ErrorCode		int,
		@nRowCount		int,
		@nHomeNameNo		int,
		@sNameTypes		nvarchar(200),
		@sSQLString		nvarchar(max)

--RFC11070: temp table to store office details for case
CREATE TABLE	#TEMPCASEOFFICE (
			CASEID		int,
			OFFICEID	int,
			OFFICENAMENO	int
		)
		
-- Temp table to store the first Name for a given NameType as this
-- will be used in the determination of Standing Instruction
CREATE TABLE 	#TEMPCASENAME (
		CASEID			int		NOT NULL,
		NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
		NAMENO			int		NOT NULL
		)
			
CREATE CLUSTERED INDEX XIE1TEMPCASENAME ON #TEMPCASENAME (
	        CASEID,
		NAMETYPE,
		NAMENO
	 	)

-- DR-58353 Performance enhancement: Unable to create a batch via the CPA Interface Not Responding
CREATE TABLE #TEMPNAMEINSTRUCTIONS(
	NAMENO int,
	CASEID int,
	PROPERTYTYPE nchar(1) collate database_default,
	COUNTRYCODE nvarchar(3) collate database_default,
	INTERNALSEQUENCE int,
	RESTRICTEDTONAME int,
	INSTRUCTIONCODE smallint
) 
		
-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0
Set @nRowCount=0

-- Get the Home NameNo and the WorkDaysFlag 
-- for the Home Country.

If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select  @nHomeNameNo =S1.COLINTEGER
	from SITECONTROL S1
	where S1.CONTROLID='HOMENAMENO'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo		int		OUTPUT',
				  @nHomeNameNo 		=@nHomeNameNo	OUTPUT
End

--RFC11070: Get office details for cases
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Insert into #TEMPCASEOFFICE
	select C.CASEID, C.OFFICEID, O.ORGNAMENO
	from "+@psCaseTableName+" T
	join CASES C on (C.CASEID = T.CASEID)
	left join OFFICE O on (O.OFFICEID = C.OFFICEID)"
	
	exec @ErrorCode=sp_executesql @sSQLString	
End

-- DR-58353 Performance enhancement: Get name instructions for the home name.  
If @ErrorCode = 0
Begin
	insert into #TEMPNAMEINSTRUCTIONS
	select NAMENO, CASEID, PROPERTYTYPE, COUNTRYCODE, INTERNALSEQUENCE, RESTRICTEDTONAME, INSTRUCTIONCODE
	from  NAMEINSTRUCTIONS NI 
	where NI.NAMENO = @nHomeNameNo
End

If  @ErrorCode=0
and @psInstructionTypes is not null
Begin
	-- Get the list of NameTypes that can be used
	-- for determining standing instructions
	-- This is being used as a performance technique
	Set @sSQLString="
	Select @sNameTypes=CASE WHEN(@sNameTypes is not null) 
						THEN @sNameTypes+','''+I.NAMETYPE+''''
						ELSE ''''+I.NAMETYPE+'''' 
			   END
	from (	select NAMETYPE as NAMETYPE
		from INSTRUCTIONTYPE
		where NAMETYPE is not null
		and INSTRUCTIONTYPE "+dbo.fn_ConstructOperator(0,'CS',@psInstructionTypes, null,0)+"
		UNION
		select RESTRICTEDBYTYPE
		from INSTRUCTIONTYPE
		where RESTRICTEDBYTYPE is not null
		and INSTRUCTIONTYPE "+dbo.fn_ConstructOperator(0,'CS',@psInstructionTypes, null,0)+") I"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sNameTypes	nvarchar(200)	output',
				  @sNameTypes=@sNameTypes	output
End

If @ErrorCode=0
and @sNameTypes is not null
Begin
	-- Need to load the required CASENAMEs into a
	-- temporary table for performance reasons.
	Set @sSQLString="
	insert into #TEMPCASENAME(CASEID,NAMETYPE,NAMENO)
	select CN.CASEID, CN.NAMETYPE, CN.NAMENO
	from CASENAME CN
	join (select CN.CASEID, CN.NAMETYPE, min(CN.SEQUENCE) as SEQUENCE
		from "+@psCaseTableName+" T
		join  CASENAME CN on (CN.CASEID=T.CASEID)
		where CN.NAMETYPE in ("+@sNameTypes+")
		and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		group by CN.CASEID, CN.NAMETYPE) CN1
			on (CN1.CASEID=CN.CASEID
			and CN1.NAMETYPE=CN.NAMETYPE
			and CN1.SEQUENCE=CN.SEQUENCE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Get the best InstructionType for each Case
If  @ErrorCode=0
and @psInstructionTypes is not null
BEGIN
	set @sSQLString="
	insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, INSTRUCTIONCODE)
	SELECT	CI.CASEID, CI.INSTRUCTIONTYPE,NI.INSTRUCTIONCODE

		-- To determine the best InstructionCode a weighting is	
		-- given based on the existence of characteristics	
		-- found in the NAMEINSTRUCTIONS row.  The MAX function 
		-- returns the highest weighting to which the required	
		-- INSTRUCTIONCODE has been concatenated.
	FROM	(SELECT C.CASEID, T.INSTRUCTIONTYPE,
			substring(max (isnull(
			CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
			convert(nchar(11),NI.NAMENO)          +
			convert(nchar(11),NI.INTERNALSEQUENCE)+
			convert(nchar(11),X1.NAMENO),'')),5,33) as COMPOSITECODE
		FROM		"+@psCaseTableName+" C
		join		CASES CS	     on (CS.CASEID=C.CASEID)
		join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE "+dbo.fn_ConstructOperator(0,'CS',@psInstructionTypes, null,0)+")
		join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
		join		#TEMPCASENAME X1     on (X1.CASEID=C.CASEID
						     and X1.NAMETYPE=T.NAMETYPE)
		left join	#TEMPCASENAME X2     on (X2.CASEID=C.CASEID
						     and X2.NAMETYPE=T.RESTRICTEDBYTYPE)
		join		NAMEINSTRUCTIONS NI  on ((NI.NAMENO=X1.NAMENO)
						     and (NI.CASEID=C.CASEID 		  OR NI.CASEID 		is NULL) 
						     and (NI.PROPERTYTYPE=CS.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
						     and (NI.COUNTRYCODE=CS.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
						     and (NI.RESTRICTEDTONAME=X2.NAMENO   OR NI.RESTRICTEDTONAME is NULL) )
		where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
		group by C.CASEID, T.INSTRUCTIONTYPE) CI
	join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(CI.COMPOSITECODE,1, 11))
				and  NI.INTERNALSEQUENCE=convert(int, substring(CI.COMPOSITECODE,12,11)))"

	Execute @ErrorCode = sp_executesql @sSQLString
	
	Set @nRowCount=@@Rowcount

	If @ErrorCode=0
	Begin
		-- RFC11070: Greater weighting applied on ORGNAMENO against OFFICE of the Case
		-- This is achieved by left join to #TEMPCASEOFFICE
		set @sSQLString="
		insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, INSTRUCTIONCODE)
		SELECT	CI.CASEID, CI.INSTRUCTIONTYPE,NI.INSTRUCTIONCODE
	
			-- To determine the best InstructionCode a weighting is	
			-- given based on the existence of characteristics	
			-- found in the NAMEINSTRUCTIONS row.  The MAX function 
			-- returns the highest weighting to which the required	
			-- INSTRUCTIONCODE has been concatenated.
		FROM	(SELECT C.CASEID, T.INSTRUCTIONTYPE,
				substring(max (isnull(
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.NAMENO)          +
				convert(nchar(11),NI.INTERNALSEQUENCE),'')),3,22) as COMPOSITECODE
			FROM		"+@psCaseTableName+"	  C
			join		CASES CS	     on (CS.CASEID=C.CASEID)
			join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE "+dbo.fn_ConstructOperator(0,'CS',@psInstructionTypes, null,0)+")
			join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
			join		#TEMPCASEOFFICE	CO on (CO.CASEID = C.CASEID)
			join		NAMEINSTRUCTIONS NI  on  (NI.NAMENO=CO.OFFICENAMENO
							     and (NI.CASEID is NULL) 
							     and (NI.PROPERTYTYPE=CS.PROPERTYTYPE OR NI.PROPERTYTYPE is NULL)
							     and (NI.COUNTRYCODE=CS.COUNTRYCODE   OR NI.COUNTRYCODE  is NULL)
							     and (NI.RESTRICTEDTONAME is NULL) )
			where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
			group by C.CASEID, T.INSTRUCTIONTYPE) CI
		join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(CI.COMPOSITECODE,1, 11))
					and  NI.INTERNALSEQUENCE=convert(int, substring(CI.COMPOSITECODE,12,11)))
		left join #TEMPCASEINSTRUCTIONS TCI on (TCI.CASEID=CI.CASEID
						    and TCI.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE)
		where TCI.CASEID is null"

		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameNo		int',
					@nHomeNameNo
		
		Set @nRowCount=@nRowCount+@@Rowcount
	End

	-- DR-58353 Use temp table #TEMPNAMEINSTRUCTIONS instead of derived table
	If  @ErrorCode=0
	Begin
		set @sSQLString="
		insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, INSTRUCTIONCODE)
		SELECT	CI.CASEID, CI.INSTRUCTIONTYPE,NI.INSTRUCTIONCODE

			-- To determine the best InstructionCode a weighting is	
			-- given based on the existence of characteristics	
			-- found in the NAMEINSTRUCTIONS row.  The MAX function 
			-- returns the highest weighting to which the required	
			-- INSTRUCTIONCODE has been concatenated.
		FROM	(SELECT C.CASEID, T.INSTRUCTIONTYPE,
				substring(max (isnull(
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.NAMENO)          +
				convert(nchar(11),NI.INTERNALSEQUENCE),'')),3,22) as COMPOSITECODE
			FROM		"+@psCaseTableName+" C
			join		CASES CS	     on (CS.CASEID=C.CASEID)
			join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE "+dbo.fn_ConstructOperator(0,'CS',@psInstructionTypes, null,0)+")
			join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
			join		#TEMPNAMEINSTRUCTIONS NI  on ((NI.NAMENO=@nHomeNameNo)
							     and (NI.CASEID is NULL) 
							     and (NI.PROPERTYTYPE=CS.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
							     and (NI.COUNTRYCODE=CS.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
							     and (NI.RESTRICTEDTONAME is NULL) )
			where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
			group by C.CASEID, T.INSTRUCTIONTYPE) CI
		join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(CI.COMPOSITECODE,1, 11))
					and  NI.INTERNALSEQUENCE=convert(int, substring(CI.COMPOSITECODE,12,11)))
		left join #TEMPCASEINSTRUCTIONS TCI	on (TCI.CASEID=CI.CASEID
							and TCI.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE)
		where TCI.CASEID is null"

		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameNo		int',
					@nHomeNameNo
		
		Set @nRowCount=@@Rowcount
	End
END

return @ErrorCode
go

grant execute on dbo.cs_GetStandingInstructionsBulk  to public
go
