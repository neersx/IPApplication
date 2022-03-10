-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetStandingInstructions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GetStandingInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GetStandingInstructions.'
	drop procedure dbo.cs_GetStandingInstructions
end
print '**** Creating procedure dbo.cs_GetStandingInstructions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.cs_GetStandingInstructions 
(
	@pnCaseKey			int		= null,	-- if @pnCaseKey is null return an empty result set
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura 		bit 		= 1,	
	@pbIsExternalUser 		bit 		= null,
	@pbCalledFromBusinessEntity	bit		= 0,	-- if set to 1, StandingInstructionEntity will be populated
	@pnUserIdentityId		int		= null
)
as
-- PROCEDURE :	cs_GetStandingInstructions
-- VERSION :	32
-- DESCRIPTION:	A procedure to get all of the standing instructions for a Case.
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21/07/2004	MF			Procedure created	 
-- 20/10/2004	TM	RFC1156	2	Pass two new optional parameters: @pbCalledFromCentura and @pbIsExternalUser.
-- 08/12/2004	TM	RFC1156	3	Add a new RowKey column.
-- 03/02/2005	TM	RFC2278	4	Sort the output by the Instruction Type description and then by the Instruction description 
--					when @pbCalledFromCentura = 0.
-- 12/07/2005	TM	RFC2758	5	When a standing instruction has a CaseID, the NameNo should be ignored.
-- 22/02/2006	TM	RFC3209	6	Add new @pbCalledFromBusinessEntity parameter. When @pbCalledFromBusinessEntity
--					is set to 1, populate the StandingInstructionEntity. 
-- 06/03/2006	TM	RFC3215	7	When @pbCalledFromCentura parameter is set to 0, @pbIsExternalUser = 1 and 
--					@pbCalledFromBusinessEntity = 0, limit standing instructions result set to 
--					the instruction types specified in the Client Instruction Types site control 
--					as well as return new IsDefault (boolean) column. 
-- 07/03/2006	TM	RFC3215	8	Add new optional @pnUserIdentityId int parameter and pass it to 
--					the fn_FilterUserInstructionTypes function.
-- 21/03/2006	PG	RFC3209	9	Return RowKey and PeriodTypeDescriptions
-- 22/03/2006	PG	RFC3209	10	Return InstructionTypeCode
-- 10 Apr 2006	MF	12537	11	If the CASEID is being used directly against the NameInstruction then ignore
--					the other characteristics
-- 24 May 2006	IB	RFC3678	12	Return adjustments for @pbCalledFromCentura = 0 and @pbIsExternalUser = 0
--					or @pbCalledFromBusinessEntity = 1.
-- 29 May 2006	KR	12319	13	Return adjustments for @pbCalledFromCentura = 1 
-- 02 Jun 2006	IB	RFC3910	14	Adjustment type should be translatable.
-- 19 Sep 2006  PG	RFC4063 15	Return NameTypeCode when @pbCalledFromBusinessEntity is set
-- 11 Oct 2006	MF	13162	16	Restructure SQL using derived table in order to remove loop at
--					increase performance.
-- 03 Nov 2006	MF	RFC4551	17	If Adjustment details have been inherited from the home name then
--					dynamically calculate the AdjustDay, AdjustStartMonth and AdjustDayOfWeek
--					as required for the Adjustment using the NameNo of the NameType associated
--					with the Instruction Type.
-- 09 Nov 2006	MF	RFC4662	18	Error in logic calculating default day of week.
-- 10 Jun 2008	MS	RFC6667	19	tinyint variables changed to int and type mismatch error is 
--					corrected by applying Cast to ADJUSTSTARTMONTH, ADJUSTDAYOFWEEK in joins
-- 22 Oct 2008	AT	RFC7179	20	Change all smallints to int
-- 11 Dec 2008	MF	17136	21	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 30 Apr 2009	vql	17542	22	Store and display free format text with a Standing Instruction.
-- 28 May 2009	MF	SQA17735 23	Slow performance extracting standing instructions for a Case.
-- 01 Jul 2010	MF	SQA18758 24	Increase the column size of Instruction Type to allow for expanded list.
-- 04 Oct 2010  DV      RFC7914 	25      Return STANDINGINSTRTEXT in the resultset
-- 07 Jul 2011	DL	RFC10830 26	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 08 Nov 2011	LP	RFC11070 27	Allow defaulting of NAMEINSTRUCTION from the Case Office via OFFICE.ORGNAMENO
-- 09 Feb 2012	LP	RFC11538 28	Suppress AdjustmentStartMonthKey if AdjustmentType is Fortnightly{~6}, Weekly{~7} or User Date{~8}.
--					AdjustMonth should only be defaulted to 11/12 for Bi-Monthly adjustment if not specified.
-- 11 Apr 2013	DV	R13270	 29	Increase the length of nvarchar to 11 when casting or declaring integer
-- 21 Jan 2015	AK	R41473	 30	returned actual ADJUSTDAYOFWEEK and ADJUSTSTARTMONTH values
-- 04 Nov 2015	KR	R53910	31	Adjust formatted names logic (DR-15543)
-- 07 Sep 2018	AV	74738	32	Set isolation level to read uncommited.


set nocount on
set concat_null_yields_null off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


CREATE TABLE 	#TEMPCASENAME (
		CASEID			int		NOT NULL,
		NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
		NAMENO			int		NOT NULL
		)
			
CREATE INDEX XIE1TEMPCASENAME ON #TEMPCASENAME (
	        CASEID,
		NAMETYPE,
		NAMENO
	 	)

declare @tbCaseInstructions table (
	INSTRUCTIONTYPE			nvarchar(3)	collate database_default NOT NULL,
	COMPOSITECODE			nchar(33)	collate database_default NULL,
	NAMENO				int		NULL,
	INTERNALSEQUENCE		int		NULL,
	CASEID				int		NULL,
	INSTRUCTIONCODE 		int		NULL,
	PERIOD1TYPE			nchar(1) 	collate database_default NULL,
	PERIOD1AMT			int		NULL,
	PERIOD2TYPE			nchar(1) 	collate database_default NULL,
	PERIOD2AMT			int		NULL,
	PERIOD3TYPE			nchar(1) 	collate database_default NULL,
	PERIOD3AMT			int		NULL,
	ADJUSTMENT			nvarchar(4)	collate database_default NULL,
	ADJUSTDAY			int		NULL,
	ADJUSTSTARTMONTH		int		NULL,
	ADJUSTDAYOFWEEK			int		NULL,
	ADJUSTTODATE			datetime	NULL,
	STANDINGINSTRTEXT		nvarchar(4000)	collate database_default NULL
)


declare	@ErrorCode		int
declare @nRowCount		int

Declare	@sSQLString		nvarchar(4000)
Declare @sLookupCulture 	nvarchar(10)
Declare @sNameTypes		nvarchar(300)
Declare	@nHomeNameNo		int
Declare	@nWorkDayFlag		int
Declare @nNameNo		int
Declare	@nWorkDays		int
Declare	@nAdjustDay		int
Declare	@nAdjustMonth		int
Declare	@nAdjustWeekDay		int
Declare @nOfficeNameNo		int

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode=0

If @pnCaseKey is not null
Begin
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)	

	Set @sSQLString="
	Select  @nHomeNameNo =S1.COLINTEGER,
		@nWorkDayFlag=C.WORKDAYFLAG
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='HOMECOUNTRY')
	left join COUNTRY C	 on (C.COUNTRYCODE=S2.COLCHARACTER
				 and C.WORKDAYFLAG>0)
	where S1.CONTROLID='HOMENAMENO'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo		int		OUTPUT,
				  @nWorkDayFlag		int		OUTPUT',
				  @nHomeNameNo 		=@nHomeNameNo	OUTPUT,
				  @nWorkDayFlag		=@nWorkDayFlag	OUTPUT

	-- RFC11070: Retrieve the ENTITYNO against the Office of the Case	
	-- Assumes that ORGNAMENO is an Entity (SPECIALNAME.ENTITYFLAG = 1)			  
	Set @sSQLString="
	Select  @nOfficeNameNo = O.ORGNAMENO
	from CASES C
	join OFFICE O on (O.OFFICEID = C.OFFICEID)
	where C.CASEID = @pnCaseKey"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nOfficeNameNo	int		OUTPUT,
				  @pnCaseKey		int		',
				  @nOfficeNameNo 	=@nOfficeNameNo	OUTPUT,
				  @pnCaseKey		=@pnCaseKey	

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
	
	If  @ErrorCode=0
	Begin
		------------------------------------------------
		-- Get the list of NameTypes that can be used
		-- for determining standing instructions
		-- This is being used as a performance technique
		------------------------------------------------
		Set @sSQLString="
		Select @sNameTypes=CASE WHEN(@sNameTypes is not null) 
							THEN @sNameTypes+','''+I.NAMETYPE+''''
							ELSE ''''+I.NAMETYPE+'''' 
				   END
		from (	select NAMETYPE as NAMETYPE
			from INSTRUCTIONTYPE
			where NAMETYPE is not null
			UNION
			select RESTRICTEDBYTYPE
			from INSTRUCTIONTYPE
			where RESTRICTEDBYTYPE is not null) I"

		Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sNameTypes	nvarchar(300)	output',
					  @sNameTypes=@sNameTypes	output
	End
	
	If @ErrorCode=0
	and @sNameTypes is not null
	Begin
		---------------------------------------
		-- Performance improvement by loading 
		-- a temporaty table with the required
		-- CaseNames and then back filling with
		-- the Home NameNo if required NameType 
		-- is missing.
		---------------------------------------
		Set @sSQLString="
		insert into #TEMPCASENAME(CASEID,NAMETYPE,NAMENO)
		select CN.CASEID, CN.NAMETYPE, CN.NAMENO
		from CASENAME CN
		join (	select CN.CASEID, CN.NAMETYPE, min(CN.SEQUENCE) as SEQUENCE
			from CASENAME CN
			where CN.CASEID=@pnCaseKey
			and CN.NAMETYPE in ("+@sNameTypes+")
			and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
			group by CN.CASEID, CN.NAMETYPE) CN1
				on (CN1.CASEID=CN.CASEID
				and CN1.NAMETYPE=CN.NAMETYPE
				and CN1.SEQUENCE=CN.SEQUENCE)"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int',
					  @pnCaseKey=@pnCaseKey
	End
	
	---------------------------------------------
	-- Backfill any CaseNames with the HomeNameNo
	-- if there is no NameType against the Case
	-- This is so we can use a JOIN rather than
	-- a LEFT JOIN in the main SELECT for getting
	-- the standing instructions as the LEFT JOIN
	-- was creating performance problems.
	-- RFC11070: Backfill with OfficeNameNo if available.
	---------------------------------------------
	If  @ErrorCode=0
	and @nHomeNameNo is not null
	AND @sNameTypes  is not null
	Begin
		Set @sSQLString="
		insert into #TEMPCASENAME (CASEID, NAMETYPE, NAMENO)
		select @pnCaseKey, NT.NAMETYPE, isnull(@nOfficeNameNo,@nHomeNameNo)
		from NAMETYPE NT
		left join #TEMPCASENAME CN on (CN.CASEID=@pnCaseKey
					   and CN.NAMETYPE=NT.NAMETYPE)
		where NT.NAMETYPE in ("+@sNameTypes+")
		and CN.CASEID is null"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nHomeNameNo	int,
					  @pnCaseKey	int,
					  @nOfficeNameNo int',
					  @nHomeNameNo=@nHomeNameNo,
					  @pnCaseKey  =@pnCaseKey,
					  @nOfficeNameNo = @nOfficeNameNo
	End

	If @ErrorCode=0
	Begin
		-- To determine the best InstructionCode a weighting is	
		-- given based on the existence of characteristics	
		-- found in the NAMEINSTRUCTIONS row.  The MAX function 
		-- returns the highest weighting to which the required	
		-- INSTRUCTIONCODE has been concatenated.	
		insert into @tbCaseInstructions(INSTRUCTIONTYPE, COMPOSITECODE)
		SELECT	IT.INSTRUCTIONTYPE,
			substring(max (isnull(
			CASE WHEN(NI.CASEID 		is not null) THEN '1' ELSE '0' END +
		 	CASE WHEN(NI.NAMENO		= X1.NAMENO) THEN '1' ELSE '0' END +
		 	CASE WHEN(NI.NAMENO		= @nOfficeNameNo) THEN '1' ELSE '0' END +
			CASE WHEN(NI.RESTRICTEDTONAME	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
			CASE WHEN(NI.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
			convert(nchar(11),NI.NAMENO)          +
			convert(nchar(11),NI.INTERNALSEQUENCE)+
			convert(nchar(11),X1.NAMENO),'')),7,33) as COMPOSITECODE
		FROM		CASES C
		cross join	INSTRUCTIONTYPE IT
		join		INSTRUCTIONS  I		on (  I.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
		join		#TEMPCASENAME X1	on (X1.CASEID=C.CASEID		
							and X1.NAMETYPE=IT.NAMETYPE)
		left join	#TEMPCASENAME X2	on (X2.CASEID=C.CASEID
							and X2.NAMETYPE=IT.RESTRICTEDBYTYPE)
		join		NAMEINSTRUCTIONS NI  on ( NI.INSTRUCTIONCODE=I.INSTRUCTIONCODE
						     and (NI.NAMENO=X1.NAMENO            OR NI.NAMENO=@nOfficeNameNo OR NI.NAMENO=@nHomeNameNo)
						     and (NI.CASEID=C.CASEID 		 OR NI.CASEID 		is NULL) 
						     and (NI.PROPERTYTYPE=C.PROPERTYTYPE OR NI.PROPERTYTYPE	is NULL)
						     and (NI.COUNTRYCODE=C.COUNTRYCODE   OR NI.COUNTRYCODE      is NULL)
						     and (NI.RESTRICTEDTONAME=X2.NAMENO  OR NI.RESTRICTEDTONAME is NULL) )
		Where C.CASEID=@pnCaseKey
		group by IT.INSTRUCTIONTYPE
	
		Select  @ErrorCode = @@Error,
			@nRowCount = @@Rowcount
	End
End

If @ErrorCode=0
and @nRowCount>0
Begin
	---------------------------------------------------------------------------------
	-- Use the CompositeCode saved in the @tbCaseInstructions table to extract the
	-- actual InstructionCode and to also see if there are any user defined Periods 
	-- relevant to the instructions.
	-- Where the Name Instruction is against the Home Name, dynamically calculate the
	-- appropriate adjustment using a the NameNo as a seed to the algorithm
	---------------------------------------------------------------------------------
	-- NOTE : This is separate UPDATE has been included to centralise simplify relatively
	--	  complex code that would have had to be repeate in all of the following SELECTs

	Update @tbCaseInstructions
	set @nNameNo        =convert(int, substring(T.COMPOSITECODE,23, 11)),
	    @nAdjustDay     =CASE WHEN(NI.NAMENO=@nNameNo) THEN isnull(NI.ADJUSTDAY, 1)        ELSE abs(isnull(@nNameNo, 0)%28)+1 END,
	    @nAdjustMonth   =CASE WHEN(NI.NAMENO=@nNameNo) THEN isnull(NI.ADJUSTSTARTMONTH,12) ELSE abs(isnull(@nNameNo,11)%12)+1 END,
	    @nAdjustWeekDay =CASE WHEN(NI.NAMENO=@nNameNo) THEN isnull(NI.ADJUSTDAYOFWEEK, 3)  ELSE abs(isnull(@nNameNo,7)%@nWorkDays)+1 END,
	    NAMENO          =NI.NAMENO,
	    INTERNALSEQUENCE=NI.INTERNALSEQUENCE,
	    CASEID          =NI.CASEID,
	    INSTRUCTIONCODE =NI.INSTRUCTIONCODE,
	    PERIOD1AMT      =NI.PERIOD1AMT,
	    PERIOD1TYPE     =NI.PERIOD1TYPE,
	    PERIOD2AMT      =NI.PERIOD2AMT,
	    PERIOD2TYPE     =NI.PERIOD2TYPE,
	    PERIOD3AMT      =NI.PERIOD3AMT,
	    PERIOD3TYPE     =NI.PERIOD3TYPE,
	    ADJUSTMENT      =NI.ADJUSTMENT,
	    ADJUSTDAY       =CASE WHEN(NI.ADJUSTMENT in ('~1','~2','~3','~4','~5')) THEN @nAdjustDay END,
	    ADJUSTSTARTMONTH=Isnull(CASE WHEN(NI.ADJUSTMENT='~1') THEN @nAdjustMonth
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
					THEN CASE WHEN @nAdjustMonth IS NOT NULL THEN @nAdjustMonth WHEN(@nAdjustMonth%2=1) THEN 11 ELSE 12 END
					-- Suppress if specific User Date adjustment
				  WHEN(NI.ADJUSTMENT='~8')
					THEN NULL 
				  WHEN(NI.ADJUSTMENT is not null)
					THEN 12                                   
			     END,NI.ADJUSTSTARTMONTH),
	    ADJUSTDAYOFWEEK =ISNULL(CASE WHEN(NI.ADJUSTMENT in ('~6','~7')) THEN isnull(@nAdjustWeekDay,3) END, NI.ADJUSTDAYOFWEEK),
	    ADJUSTTODATE    =NI.ADJUSTTODATE,
	    STANDINGINSTRTEXT=NI.STANDINGINSTRTEXT
	From @tbCaseInstructions T
	join NAMEINSTRUCTIONS NI on (NI.NAMENO          =convert(int, substring(T.COMPOSITECODE,1, 11))
				and  NI.INTERNALSEQUENCE=convert(int, substring(T.COMPOSITECODE,12,11)))

	Set @ErrorCode=@@Error
End

If @pbCalledFromBusinessEntity = 0
and @ErrorCode=0
Begin
	If @pnCaseKey is not null
	Begin			
		If @ErrorCode=0
		and @pbCalledFromCentura = 1
		Begin
			Select 	dbo.fn_GetTranslationLimited(IT.INSTRTYPEDESC,null,IT.INSTRTYPEDESC_TID,@sLookupCulture) as INSTRTYPEDESC,
				dbo.fn_GetTranslationLimited(I.DESCRIPTION,null,I.DESCRIPTION_TID,@sLookupCulture) as DESCRIPTION,
				T.CASEID, 
				T.INSTRUCTIONCODE, 
				T.NAMENO, 
				T.INTERNALSEQUENCE, 
				IT.INSTRUCTIONTYPE, 
				T.PERIOD1AMT, 
				T.PERIOD1TYPE,
				T.PERIOD2AMT,
				T.PERIOD2TYPE,
				T.PERIOD3AMT,
				T.PERIOD3TYPE,
				dbo.fn_FormatNameUsingNameNo(N.NAMENO, default) as DEFAULTEDFROM,
				T.ADJUSTMENT,
				T.ADJUSTDAY,
				T.ADJUSTSTARTMONTH,
				T.ADJUSTDAYOFWEEK,
				T.ADJUSTTODATE,
				T.STANDINGINSTRTEXT
			From @tbCaseInstructions T
			join INSTRUCTIONS I	 on (I.INSTRUCTIONCODE=T.INSTRUCTIONCODE)
			join INSTRUCTIONTYPE IT	 on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
			join NAME N		 on (N.NAMENO=T.NAMENO)
			order by 1
		
			Set @ErrorCode = @@Error
		End
		Else
		If @ErrorCode=0
		and @pbCalledFromCentura = 0
		and @pbIsExternalUser = 0
		Begin
			Select 	T.CASEID		as CaseKey, 
				dbo.fn_GetTranslation(IT.INSTRTYPEDESC,null,IT.INSTRTYPEDESC_TID,@sLookupCulture)
							as InstructionType,
				dbo.fn_GetTranslation(I.DESCRIPTION,null,I.DESCRIPTION_TID,@sLookupCulture)
							as Instruction,
				CASE 	WHEN T.CASEID is not null then NULL
					ELSE dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
				END			as DefaultedFromName,
				CASE 	WHEN T.CASEID is not null then NULL
					ELSE N.NAMENO
				END	 		as DefaultedFromNameKey,
				T.PERIOD1AMT		as Period1Amt,
				T.PERIOD1TYPE		as Period1Type,
				T.PERIOD2AMT		as Period2Amt,
				T.PERIOD2TYPE		as Period2Type,
				T.PERIOD3AMT		as Period3Amt,
				T.PERIOD3TYPE		as Period3Type,
				dbo.fn_GetTranslation(A.ADJUSTMENTDESC, null, A.ADJUSTMENTDESC_TID, @sLookupCulture)
							as AdjustmentTypeDescription,
				T.ADJUSTDAY		as AdjustmentDayOfMonth,
				dbo.fn_GetTranslation(TCSM.DESCRIPTION, null, TCSM.DESCRIPTION_TID, @sLookupCulture)
							as AdjustmentStartMonth,
				dbo.fn_GetTranslation(TCDOF.DESCRIPTION, null, TCDOF.DESCRIPTION_TID, @sLookupCulture)
							as AdjustmentDayOfWeek,
				T.ADJUSTTODATE		as AdjustToDate,
				cast(T.NAMENO as varchar(11)) 	+ '^' + 
				cast(T.INTERNALSEQUENCE as varchar(11))	
							as RowKey,
			        T.STANDINGINSTRTEXT     as StandingInstrText				
			From @tbCaseInstructions T
			join INSTRUCTIONS I	 	on (I.INSTRUCTIONCODE=T.INSTRUCTIONCODE)
			join INSTRUCTIONTYPE IT	 	on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
			join NAME N		 	on (N.NAMENO=T.NAMENO)
			left join ADJUSTMENT A	 	on (A.ADJUSTMENT = T.ADJUSTMENT)
			left join TABLECODES TCSM	on (TCSM.USERCODE = CAST(T.ADJUSTSTARTMONTH as nvarchar(11))
							and TCSM.TABLETYPE = 89)
			left join TABLECODES TCDOF	on (TCDOF.USERCODE = CAST(T.ADJUSTDAYOFWEEK as nvarchar(11))
							and TCDOF.TABLETYPE = 88)
			order by InstructionType, Instruction
		
			Set @ErrorCode = @@Error
		End
		Else
		If @ErrorCode=0
		and @pbCalledFromCentura = 0
		and @pbIsExternalUser = 1
		Begin
			Select 	T.CASEID		as CaseKey, 
				IT.INSTRTYPEDESC	as InstructionType,
				dbo.fn_GetTranslation(I.DESCRIPTION,null,I.DESCRIPTION_TID,@sLookupCulture)
							as Instruction,
				CASE 	WHEN T.CASEID is null then CAST(1 as bit)
					ELSE CAST(0 as bit)
				END			as IsDefault,		
				cast(T.NAMENO as varchar(11)) 	+ '^' + 
				cast(T.INTERNALSEQUENCE as varchar(11))	
							as RowKey	
			From @tbCaseInstructions T
			join INSTRUCTIONS I	 on (I.INSTRUCTIONCODE=T.INSTRUCTIONCODE)
			join dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId, 1, @sLookupCulture, @pbCalledFromCentura) IT
						on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)	
			order by InstructionType, Instruction
		
			Set @ErrorCode = @@Error
		End
	End
	Else
	If @pnCaseKey is null
	Begin	
		If @ErrorCode=0
		and @pbCalledFromCentura = 1
		Begin
			Select 	null	as INSTRTYPEDESC, 
				null	as DESCRIPTION, 
				null	as CASEID, 
				null	as INSTRUCTIONCODE, 
				null	as NAMENO, 
				null	as INTERNALSEQUENCE, 
				null	as INSTRUCTIONTYPE, 
				null	as PERIOD1AMT, 
				null	as PERIOD1TYPE,
				null	as PERIOD2AMT,
				null	as PERIOD2TYPE,
				null	as PERIOD3AMT,
				null	as PERIOD3TYPE,
				null	as DEFAULTEDFROM,
				null	as ADJUSTMENT,
				null	as ADJUSTDAY,
				null	as ADJUSTSTARTMONTH,
				null	as ADJUSTDAYOFWEEK,
				null	as ADJUSTTODATE,
				null	as STANDINGINSTRTEXT
			where 1=0		
		End
		Else
		If @pbCalledFromCentura = 0
		and @pbIsExternalUser = 0
		Begin
			Select 	null	as CaseKey, 
				null	as InstructionType,
				null	as Instruction,
				null	as DefaultedFromName,
				null	as DefaultedFromNameKey,
				null	as Period1Amt,
				null	as Period1Type,
				null	as Period2Amt,
				null	as Period2Type,
				null	as Period3Amt,
				null	as Period3Type,
				null	as AdjustmentTypeKey,
				null	as AdjustmentTypeDescription,
				null	as AdjustmentDayOfMonth,
				null	as AdjustmentStartMonthKey,
				null	as AdjustmentStartMonth,
				null	as AdjustmentDayOfWeekKey,
				null	as AdjustmentDayOfWeek,
				null	as AdjustToDate,
				null	as RowKey,
				null	as STANDINGINSTRTEXT		
			where 1=0
		End
		Else
		If @pbCalledFromCentura = 0
		and @pbIsExternalUser = 1
		Begin
			Select 	null	as CaseKey, 
				null	as InstructionType,
				null	as Instruction,
				null	as RowKey
			where 1=0
		End
	End
End
Else If @pbCalledFromBusinessEntity = 1
Begin
	If @ErrorCode=0
	Begin   
		Select  		
		CAST(T.NAMENO as nvarchar(11))+'^'+
		CAST(T.INTERNALSEQUENCE as nvarchar(11)) as RowKey,
		T.NAMENO		as NameKey,
		T.INTERNALSEQUENCE	as Sequence,
		I.INSTRUCTIONTYPE	as InstructionTypeCode,
		dbo.fn_GetTranslation(IT.INSTRTYPEDESC,null,IT.INSTRTYPEDESC_TID,@sLookupCulture)
					as InstructionTypeDescription,
		T.INSTRUCTIONCODE	as InstructionCode,
		dbo.fn_GetTranslation(I.DESCRIPTION,null,I.DESCRIPTION_TID,@sLookupCulture)
					as InstructionDescription,
		CASE 	WHEN T.CASEID is not null then NULL
			ELSE dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)
		END			as DefaultedFromName,
		null			as PropertyTypeCode,
		null			as PropertyTypeDescription,
		null			as CountryCode,
		null			as CountryName,
		null			as RestrictedToNameKey,
		null			as RestrictedToName,
		T.CASEID		as CaseKey, 									
		T.PERIOD1AMT		as Period1Amount,
		T.PERIOD1TYPE		as Period1Type,
		dbo.fn_GetTranslation(TC1.DESCRIPTION,null,TC1.DESCRIPTION_TID,@sLookupCulture)
					as Period1TypeDescription,
		T.PERIOD2AMT		as Period2Amount,
		T.PERIOD2TYPE		as Period2Type,
		dbo.fn_GetTranslation(TC2.DESCRIPTION,null,TC2.DESCRIPTION_TID,@sLookupCulture)
					as Period2TypeDescription,
		T.PERIOD3AMT		as Period3Amount,
		T.PERIOD3TYPE		as Period3Type,
		dbo.fn_GetTranslation(TC3.DESCRIPTION,null,TC3.DESCRIPTION_TID,@sLookupCulture)
					as Period3TypeDescription,
		CASE 	WHEN T.CASEID is null then CAST(1 as bit)
			ELSE CAST(0 as bit)
		END			as IsDefault,
		T.ADJUSTMENT		as AdjustmentTypeKey,
		dbo.fn_GetTranslation(A.ADJUSTMENTDESC, null, A.ADJUSTMENTDESC_TID, @sLookupCulture)
					as AdjustmentTypeDescription,
		T.ADJUSTDAY		as AdjustmentDayOfMonth,
		T.ADJUSTSTARTMONTH	as AdjustmentStartMonthKey,
		dbo.fn_GetTranslation(TCSM.DESCRIPTION, null, TCSM.DESCRIPTION_TID, @sLookupCulture)
					as AdjustmentStartMonth,
		T.ADJUSTDAYOFWEEK	as AdjustmentDayOfWeekKey,
		dbo.fn_GetTranslation(TCDOF.DESCRIPTION, null, TCDOF.DESCRIPTION_TID, @sLookupCulture)
					as AdjustmentDayOfWeek,
		T.ADJUSTTODATE		as AdjustToDate,
		IT.NAMETYPE 		as NameTypeCode,
		T.STANDINGINSTRTEXT     as StandingInstrText	
		From @tbCaseInstructions T
		join INSTRUCTIONS I	 	on (I.INSTRUCTIONCODE=T.INSTRUCTIONCODE)
		join INSTRUCTIONTYPE IT	 	on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		join NAME N		 	on (N.NAMENO=T.NAMENO)
		left join TABLECODES TC1	on (TC1.USERCODE=T.PERIOD1TYPE and TC1.TABLETYPE=127)
		left join TABLECODES TC2	on (TC2.USERCODE=T.PERIOD2TYPE and TC2.TABLETYPE=127)
		left join TABLECODES TC3	on (TC3.USERCODE=T.PERIOD3TYPE and TC3.TABLETYPE=127)	
		left join ADJUSTMENT A	 	on (A.ADJUSTMENT = T.ADJUSTMENT)
		left join TABLECODES TCSM	on (TCSM.USERCODE = CAST(T.ADJUSTSTARTMONTH as nvarchar(11))	and TCSM.TABLETYPE = 89)
		left join TABLECODES TCDOF	on (TCDOF.USERCODE = CAST(T.ADJUSTDAYOFWEEK as nvarchar(11))	and TCDOF.TABLETYPE = 88)
		order by InstructionTypeDescription, InstructionDescription

		Set @ErrorCode = @@Error
	End
	
End

return @ErrorCode
go

grant execute on dbo.cs_GetStandingInstructions  to public
go
