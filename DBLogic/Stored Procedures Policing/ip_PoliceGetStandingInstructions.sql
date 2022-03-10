-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetStandingInstructions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetStandingInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetStandingInstructions.'
	drop procedure dbo.ip_PoliceGetStandingInstructions
end
print '**** Creating procedure dbo.ip_PoliceGetStandingInstructions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetStandingInstructions 
			@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PoliceGetStandingInstructions
-- VERSION :	33
-- DESCRIPTION:	A procedure to load the temporary table #TEMPCASEINSTRUCTIONS with the standing instructions
--		for all cases being police

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 13/07/2000	MF			Procedure created	 
-- 13/11/2001	MF	7190		Performance improvement by removing cursor and using sp_executesql
-- 24/06/2002	MF	7764		Ensure that more than one Standing Instruction for a Case can be saved.
-- 09/08/2002	MF	7392		Allow specific Periods of time to be saved against Standing Instructions
--					so that they may be used in Due Date calculations.
-- 28 Jul 2003	MF		10	Standardise version number
-- 25 Apr 2006	MF	12319	11	Additional columns saved in #TEMPCASEINSTRUCTIONS to allow for Adjustment
--					details to be determined from Standing Instruction.
-- 25 Aug 2006	MF	13162	12	Restructure SQL using derived table in order to remove loop at
--					increase performance.
-- 18 Oct 2006	MF	13646	13	Adjustments that have been inherited from the home name should dynamically
--					calculate the Adjustment Day, Month and Week values from an algorithm 
--					seeded from the NameNo.
-- 25 Oct 2006	MF	13645	14	Make sure that any InstructionTypes used to determine the Rates to be raised
--					for a Charge Type are also extracted.
-- 02 Nov 2006	MF	13162	15	Revisit to ensure no Aggregate Warning message appears.
-- 09 Nov 2006	MF	4662	16	Error in logic calculating default day of week.
-- 21 Nov 2006	MF	13162	17	Further performance work by utilising temporary tables.
-- 05 Feb 2007	MF	13162	18	Further performance work by changing Left Join to a JOIN
-- 12 Feb 2007	MF	14263	19	Restructure code to ensure that concatenations of NULLs do not result in a NULL
-- 15 Feb 2007	MF	14263	20	Revisit after test failure.  Remove test code.
-- 13 Mar 2007	MF	13162	21	Revisit.  Problem if Case Limit set to zero.
-- 31 May 2007	MF	14812	22	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 18 Mar 2008	MF	16118	23	Revisit of 13162 to correct typo which was setting initial batch size to 100,000
--					when it should be 10,000
-- 09 May 2008	MF	16383	24	Standing instruction against Home Name not being returned.
-- 11 Dec 2008	MF	17136	25	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26 May 2009	MF	17726	26	Improve Policing performance by speeding up extraction of CaseName into #TEMPCASENAME
-- 24 May 2010	MF	18756	27	Performance improvement by separating the best fit on Names directly linked to Case from the default
--					instructions held against the Home Name.
--					Suggestion provided by Barney Ling of Griffith Hack.
-- 01 Jul 2010	MF	18758	28	Increase the column size of Instruction Type to allow for expanded list.
-- 15 Nov 2010	MF	RFC9960 29	Remove requirement for #TEMPOPENACTION row to exist as these rows may be added later when a Status changes.
-- 17 Nov 2011	LP	R11070	30	Default instruction to ORGNAMENO of the Name's Office, before defaulting to HOMENAMENO.
-- 16 Jun 2015	MF	R48747	31	Large number of different Instruction Types resulted in a SQL Error due to variable size not being large enough.
-- 31 Jul 2018	MF	74703	32	The Restricted By Name should also be considered for Standing Instructions configured against the Office or Home Name.
-- 14 Nov 2018  AV  75198/DR-45358	33   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

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
	 	
DECLARE		@ErrorCode		int,
		@nRowCount		int,
		@nHomeNameNo		int,
		@nWorkDayFlag		int,
		@nNameNo		int,
		@nWorkDays		tinyint,
		@nAdjustDay		tinyint,
		@nAdjustMonth		tinyint,
		@nAdjustWeekDay		tinyint,
		@sInstructions		nchar(7),
		@sInstructionType	nvarchar(3),
		@sInstNameType		nvarchar(3),
		@sRestrictedByType	nvarchar(3),
		@sNameTypes		nvarchar(max),
		@sInstructionTypes	nvarchar(max),
		@sSQLString		nvarchar(max),
		@nOfficeNameNo		int

--RFC11070: temp table to store office details for case
CREATE TABLE	#TEMPCASEOFFICE (
			CASEID		int,
			OFFICEID	int,
			OFFICENAMENO	int
		)
-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0
Set @nRowCount=0
Set @nWorkDays=5

-- Get the Home NameNo and the WorkDaysFlag 
-- for the Home Country.

If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select  @nHomeNameNo =S1.COLINTEGER,
		@nWorkDayFlag=C.WORKDAYFLAG
	from SITECONTROL S1
	left join SITECONTROL S3 on (S3.CONTROLID='HOMECOUNTRY')
	left join COUNTRY C	 on (C.COUNTRYCODE=S3.COLCHARACTER
				 and C.WORKDAYFLAG>0)
	where S1.CONTROLID='HOMENAMENO'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo		int		OUTPUT,
				  @nWorkDayFlag		int		OUTPUT',
				  @nHomeNameNo 		=@nHomeNameNo	OUTPUT,
				  @nWorkDayFlag		=@nWorkDayFlag	OUTPUT
End

--RFC11070: Get office details for cases
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Insert into #TEMPCASEOFFICE
	select C.CASEID, C.OFFICEID, O.ORGNAMENO
	from #TEMPCASES T
	join CASES C on (C.CASEID = T.CASEID)
	left join OFFICE O on (O.OFFICEID = C.OFFICEID)"
	
	exec @ErrorCode=sp_executesql @sSQLString	
End


If  @ErrorCode = 0
and @nWorkDayFlag>0
Begin
	-- Count the number of work days that have been
	-- defined for the home country.
	select @nWorkDays=sum(CASE WHEN(@nWorkDayFlag&power(2,DayFlag)=power(2,DayFlag)) THEN 1 ELSE 0 END)
	from (	select 1 as DayFlag
		union all
		select 2
		union all
		select 3
		union all
		select 4
		union all
		select 5
		union all
		select 6
		union all
		select 7) WEEKDAY
End
-- Getting the list of InstructionTypes whose standing instructions are to be extracted has
-- been pulled out of the main SQL statement as a performance tuning measure
If @ErrorCode = 0
Begin
	Set @sSQLString="
	Select @sInstructionTypes=CASE WHEN(@sInstructionTypes is not null) 
						THEN @sInstructionTypes+','''+EC.INSTRUCTIONTYPE+''''
						ELSE ''''+EC.INSTRUCTIONTYPE+'''' 
				  END
	from (	select INSTRUCTIONTYPE
		from EVENTCONTROL
		where INSTRUCTIONTYPE is not null
		UNION
		select INSTRUCTIONTYPE
		from CHARGERATES
		where INSTRUCTIONTYPE is not null) EC"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sInstructionTypes	nvarchar(max)	output',
				  @sInstructionTypes=@sInstructionTypes	output
End

If  @ErrorCode=0
and @sInstructionTypes is not null
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
		and INSTRUCTIONTYPE in ("+@sInstructionTypes+")
		UNION
		select RESTRICTEDBYTYPE
		from INSTRUCTIONTYPE
		where RESTRICTEDBYTYPE is not null
		and INSTRUCTIONTYPE in ("+@sInstructionTypes+")) I"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sNameTypes	nvarchar(max)	output',
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
		from #TEMPCASES T
		join  CASENAME CN on (CN.CASEID=T.CASEID)
		where CN.NAMETYPE in ("+@sNameTypes+")
		and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		group by CN.CASEID, CN.NAMETYPE) CN1
			on (CN1.CASEID=CN.CASEID
			and CN1.NAMETYPE=CN.NAMETYPE
			and CN1.SEQUENCE=CN.SEQUENCE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Get the standing instructions for each Case.
If  @ErrorCode=0
and @sInstructionTypes is not null
BEGIN
	set @sSQLString="
	insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, COMPOSITECODE)
	SELECT	CI.CASEID, CI.INSTRUCTIONTYPE,CI.COMPOSITECODE

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
		FROM		#TEMPCASES	  C
		join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE in ("+@sInstructionTypes+"))
		join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
		join		#TEMPCASENAME X1     on (X1.CASEID=C.CASEID
						     and X1.NAMETYPE=T.NAMETYPE)
		left join	#TEMPCASENAME X2     on (X2.CASEID=C.CASEID
						     and X2.NAMETYPE=T.RESTRICTEDBYTYPE)							     
		join		NAMEINSTRUCTIONS NI  on ((NI.NAMENO=X1.NAMENO)
						     and (NI.CASEID=C.CASEID 		 OR NI.CASEID 		is NULL) 
						     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
						     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
						     and (NI.RESTRICTEDTONAME=X2.NAMENO	 OR NI.RESTRICTEDTONAME is NULL) )				
		where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
		and C.INSTRUCTIONSLOADED=0
		--RFC9960 comment out code that requires #TEMPOPENACTION
		--and exists					
		--	(select * from #TEMPOPENACTION T	
		--	 where T.CASEID=C.CASEID)
		group by C.CASEID, T.INSTRUCTIONTYPE) CI"

	Execute @ErrorCode = sp_executesql @sSQLString

	Set @nRowCount=@@Rowcount

	If @ErrorCode=0
	Begin
		-- RFC11070: Greater weighting applied on ORGNAMENO against OFFICE of the Case
		-- This is achieved by left join to #TEMPCASEOFFICE
		set @sSQLString="
		insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, COMPOSITECODE)
		SELECT	CI.CASEID, CI.INSTRUCTIONTYPE,CI.COMPOSITECODE
	
			-- To determine the best InstructionCode a weighting is	
			-- given based on the existence of characteristics	
			-- found in the NAMEINSTRUCTIONS row.  The MAX function 
			-- returns the highest weighting to which the required	
			-- INSTRUCTIONCODE has been concatenated.
		FROM	(SELECT C.CASEID, T.INSTRUCTIONTYPE,
				substring(max (isnull(
				CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.NAMENO)          +
				convert(nchar(11),NI.INTERNALSEQUENCE),'')),4,22) as COMPOSITECODE
			FROM		#TEMPCASES	  C
			join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE in ("+@sInstructionTypes+"))
			join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
			left join	#TEMPCASENAME X2     on (X2.CASEID=C.CASEID
							     and X2.NAMETYPE=T.RESTRICTEDBYTYPE)
			join		#TEMPCASEOFFICE	CO on (CO.CASEID = C.CASEID)
			join		NAMEINSTRUCTIONS NI  on ((NI.NAMENO=CO.OFFICENAMENO)
							     and (NI.CASEID is NULL) 
							     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
							     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
							     and (NI.RESTRICTEDTONAME=X2.NAMENO	 OR NI.RESTRICTEDTONAME is NULL) )
			where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
			and C.INSTRUCTIONSLOADED=0			
			group by C.CASEID, T.INSTRUCTIONTYPE) CI
		left join #TEMPCASEINSTRUCTIONS TCI 	on (TCI.CASEID=CI.CASEID
							and TCI.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE)
		where TCI.CASEID is null"

		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameNo		int',
					@nHomeNameNo
		
		Set @nRowCount=@nRowCount+@@Rowcount
	End
	
	If @ErrorCode=0
	Begin
		set @sSQLString="
		insert into #TEMPCASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, COMPOSITECODE)
		SELECT	CI.CASEID, CI.INSTRUCTIONTYPE,CI.COMPOSITECODE
	
			-- To determine the best InstructionCode a weighting is	
			-- given based on the existence of characteristics	
			-- found in the NAMEINSTRUCTIONS row.  The MAX function 
			-- returns the highest weighting to which the required	
			-- INSTRUCTIONCODE has been concatenated.
		FROM	(SELECT C.CASEID, T.INSTRUCTIONTYPE,
				substring(max (isnull(
				CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
				CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
				convert(nchar(11),NI.NAMENO)          +
				convert(nchar(11),NI.INTERNALSEQUENCE),'')),4,22) as COMPOSITECODE
			FROM		#TEMPCASES	  C
			join		INSTRUCTIONTYPE   T  on ( T.INSTRUCTIONTYPE in ("+@sInstructionTypes+"))
			join		INSTRUCTIONS	  I  on ( I.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
			left join	#TEMPCASENAME X2     on (X2.CASEID=C.CASEID
							     and X2.NAMETYPE=T.RESTRICTEDBYTYPE)
			join		NAMEINSTRUCTIONS NI  on ((NI.NAMENO=@nHomeNameNo)
							     and (NI.CASEID is NULL) 
							     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
							     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
							     and (NI.RESTRICTEDTONAME=X2.NAMENO	 OR NI.RESTRICTEDTONAME is NULL) )						
			where NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
			and C.INSTRUCTIONSLOADED=0
			--RFC9960 comment out code that requires #TEMPOPENACTION
			--and exists				
			--	(select * from #TEMPOPENACTION T
			--	 where T.CASEID=C.CASEID)
			group by C.CASEID, T.INSTRUCTIONTYPE) CI
		left join #TEMPCASEINSTRUCTIONS TCI 	on (TCI.CASEID=CI.CASEID
							and TCI.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE)
		where TCI.CASEID is null"

		Execute @ErrorCode = sp_executesql @sSQLString, 
					N'@nHomeNameNo		int',
					@nHomeNameNo
		
		Set @nRowCount=@nRowCount+@@Rowcount
	End
END

-- Use the CompositeCode saved in the #TEMPCASEINSTRUCTIONS table to extract the
-- actual InstructionCode and to also see if there are any user defined Periods 
-- relevant to the instructions.
-- Where the Name Instruction is against the Home Name, dynamically calculate the
-- appropriate adjustment using a the NameNo as a seed to the algorithm

If @ErrorCode=0
and @nRowCount>0
Begin
	set @sSQLString="
	Update #TEMPCASEINSTRUCTIONS
	set @nNameNo        =convert(int, substring(T.COMPOSITECODE,23, 11)),
	    @nAdjustDay     =CASE WHEN(NI.NAMENO=@nNameNo) THEN isnull(NI.ADJUSTDAY, 1)        ELSE abs(isnull(@nNameNo, 0)%28)+1 END,
	    @nAdjustMonth   =CASE WHEN(NI.NAMENO=@nNameNo) THEN isnull(NI.ADJUSTSTARTMONTH,12) ELSE abs(isnull(@nNameNo,11)%12)+1 END,
	    @nAdjustWeekDay =CASE WHEN(NI.NAMENO=@nNameNo) THEN isnull(NI.ADJUSTDAYOFWEEK, 3)  ELSE abs(isnull(@nNameNo,7)%@nWorkDays)+1 END,
	    INSTRUCTIONCODE =NI.INSTRUCTIONCODE,
	    PERIOD1AMT      =NI.PERIOD1AMT,
	    PERIOD1TYPE     =NI.PERIOD1TYPE,
	    PERIOD2AMT      =NI.PERIOD2AMT,
	    PERIOD2TYPE     =NI.PERIOD2TYPE,
	    PERIOD3AMT      =NI.PERIOD3AMT,
	    PERIOD3TYPE     =NI.PERIOD3TYPE,
	    ADJUSTMENT      =NI.ADJUSTMENT,
	    ADJUSTDAY       =CASE WHEN(NI.ADJUSTMENT in ('~1','~2','~3','~4','~5')) THEN @nAdjustDay END,
	    ADJUSTSTARTMONTH=CASE WHEN(NI.ADJUSTMENT='~1') THEN @nAdjustMonth
				  WHEN(NI.ADJUSTMENT='~2')
					-- Adjust half year month start to be in second half of year
					THEN CASE WHEN(@nAdjustMonth<=6) THEN NI.ADJUSTSTARTMONTH+6 ELSE @nAdjustMonth END
				  WHEN(NI.ADJUSTMENT='~3')
					-- Adjust quarterly month start to be in last quarter
					THEN CASE WHEN(@nAdjustMonth in (1,4,7)) THEN 10
						  WHEN(@nAdjustMonth in (2,5,8)) THEN 11
						  WHEN(@nAdjustMonth in (3,6,9)) THEN 12 ELSE @nAdjustMonth
					     END
				  WHEN(NI.ADJUSTMENT='~4')
					-- Adjust bimonthly to be either months 11 or 12 depending on if it is odd or even
					THEN CASE WHEN(@nAdjustMonth%2=1) THEN 11 ELSE 12 END
					ELSE 12
			     END,
	    ADJUSTDAYOFWEEK =CASE WHEN(NI.ADJUSTMENT in ('~6','~7')) THEN isnull(@nAdjustWeekDay,3) END,
	    ADJUSTTODATE    =NI.ADJUSTTODATE
	From #TEMPCASEINSTRUCTIONS T
	join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(T.COMPOSITECODE,1, 11))
				and  NI.INTERNALSEQUENCE=convert(int, substring(T.COMPOSITECODE,12,11)))"

	Execute @ErrorCode = sp_executesql @sSQLString,
					N'@nNameNo		int		OUTPUT,
					  @nAdjustDay		tinyint		OUTPUT,
					  @nAdjustMonth		tinyint		OUTPUT,
					  @nAdjustWeekDay	tinyint		OUTPUT,
					  @nWorkDays		tinyint',
					  @nNameNo       =@nNameNo		OUTPUT,
					  @nAdjustDay    =@nAdjustDay		OUTPUT,
					  @nAdjustMonth  =@nAdjustMonth		OUTPUT,
					  @nAdjustWeekDay=@nAdjustWeekDay	OUTPUT,
					  @nWorkDays 	 =@nWorkDays
End

If @ErrorCode=0
Begin
	set @sSQLString="
	Update #TEMPCASES
	set INSTRUCTIONSLOADED=1
	where INSTRUCTIONSLOADED=0"

	Execute @ErrorCode = sp_executesql @sSQLString
end

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	If @pnDebugFlag>2
	begin
		Select * from #TEMPCASEINSTRUCTIONS
	End

	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetStandingInstructions',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetStandingInstructions  to public
go
