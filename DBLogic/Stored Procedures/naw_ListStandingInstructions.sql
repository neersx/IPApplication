-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListStandingInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListStandingInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListStandingInstructions.'
	Drop procedure [dbo].[naw_ListStandingInstructions]
End
Print '**** Creating Stored Procedure dbo.naw_ListStandingInstructions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListStandingInstructions
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@pbIsExternalUser	bit,		-- External user flag which should already be known
	@pnNameKey		int		= null, -- Returns an empty result set if @pnNameKey is null
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListStandingInstructions
-- VERSION:	16
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates Standing Instructions result set for both internal and external users.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 Mar 2006	TM	RFC3215	1	Procedure created
-- 10 Mar 2006	TM	RFC3215	2	Add new RowKey column to the StandingInstruction result set for external users.
-- 03 May 2006	SW	RFC3779	3	For both internal and external users, modify the logic to check the name type 
--					of the instruction type.
-- 24 May 2006 	IB	RFC3678	4	Return adjustments for internal users.
-- 02 Jun 2006	IB	RFC3910	5	Adjustment type should be translatable.
-- 17 Oct 2006	MF	RFC4405	6	Modify to SQL improve performance. Also improve logic in regards to returing
--					the inherited instructions and default the Adjustment details using an 
--					algorithm seeded from the NAMENO if the standing instruction have come
--					from the Home NameNo.
--					If a standing instruction has come via the HomeNameNo then dynamically determine
--					any Adjustment details for Month, Day and Day of Week using the NameNo to seed
--					the calculation.
-- 20 Nov 2006	SF	RFC4692	7	Modify sql construction method to remove spaces, tabs and comments.  
--					This is causing sql string overflow when translation is turned on.
-- 28 Oct 2008	AT	RFC7202	8	Return SmallInts as Ints.

-- 11 Dec 2008	MF	17136	9	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 21 May 2009	SF	RFC8017	10	IsDefault is returning true even when @pnNameKey is HOMENAMENO.
-- 02 Mar 2010	MS	FC100147 10	Change Sort Order. Added Instruction after InstructionType.
-- 20 Jul 2011	MF	RFC10974 11	Display default standing instructions even if the Name has not been linked to a case by the NameType.
--					Note that I have only removed the CaseName restriction for the web and left it when called by Centura.
-- 17 Nov 2011	LP	R11070	12	Default instruction to ORGNAMENO of the Name's Office, before defaulting to HOMENAMENO.
-- 08 Feb 2012	LP	R11834	13	Do not highlight as inherited if ORGNAMENO of Name's Office is the current Name.
--					Corrected logic for external users.
-- 11 Apr 2013	DV	R13270	14	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	15	Adjust formatted names logic (DR-15543).
-- 14 Nov 2016	LP	R67307	16	Return Standing Instructions Text column.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare	@nHomeNameNo	int
Declare @nWorkDayFlag	int
Declare @nWorkDays	tinyint
Declare	@nOfficeNameNo	int
Declare @nOfficeTableType int

-- Initialise variables
Set @nErrorCode 	= 0
Set @nWorkDays		= 5
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode=0
Begin
	SELECT @nOfficeTableType = TABLETYPE from TABLETYPE where DATABASETABLE = 'OFFICE'
End

-- Get the Home Name and Home Country as a separate step to improve performance
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select  @nHomeNameNo =S1.COLINTEGER,
		@nWorkDayFlag=C.WORKDAYFLAG
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='HOMECOUNTRY')
	left join COUNTRY C	 on (C.COUNTRYCODE=S2.COLCHARACTER
				 and C.WORKDAYFLAG>0)
	where S1.CONTROLID='HOMENAMENO'"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nHomeNameNo		int		OUTPUT,
				  @nWorkDayFlag		int		OUTPUT',
				  @nHomeNameNo 		=@nHomeNameNo	OUTPUT,
				  @nWorkDayFlag		=@nWorkDayFlag	OUTPUT
End

If @nErrorCode = 0
and @pnNameKey is not null
Begin
	-- RFC11070: Retrieve the ENTITYNO against the Office of the Case	
	-- Assumes that ORGNAMENO is an Entity (SPECIALNAME.ENTITYFLAG = 1)
	-- Only applies to Names with one Office
	If (SELECT COUNT(*) from TABLEATTRIBUTES 
		where PARENTTABLE = 'NAME' 
		and GENERICKEY = @pnNameKey 
		and TABLETYPE = @nOfficeTableType) = 1			  
	Begin
		Set @sSQLString="
		Select  @nOfficeNameNo = O.ORGNAMENO
		from TABLEATTRIBUTES T
		join OFFICE O on (O.OFFICEID = T.TABLECODE)
		and T.PARENTTABLE = 'NAME'
		and T.GENERICKEY = @pnNameKey
		and T.TABLETYPE = @nOfficeTableType"
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nOfficeNameNo	int		OUTPUT,
					  @pnNameKey		int		,
					  @nOfficeTableType	int',
					  @nOfficeNameNo 	=@nOfficeNameNo	OUTPUT,
					  @pnNameKey		=@pnNameKey,
					  @nOfficeTableType	=@nOfficeTableType	
	End
End

-- Populating StandingInstruction result set for internal users
If  @nErrorCode = 0
and @pbIsExternalUser = 0
Begin
	If @nWorkDayFlag>0
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

	Set @sSQLString = 
	"Select "+CHAR(10)+
	"CAST(NI.NAMENO as varchar(11))+'^'+"+CHAR(10)+
	"CAST(NI.INTERNALSEQUENCE as varchar(10))"+CHAR(10)+
	"			as 'RowKey',"+CHAR(10)+
	"@pnNameKey		as 'NameKey',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'IT',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'InstructionType',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'Instruction',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'PropertyType',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'Country',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'RestrictedByNameType',"+CHAR(10)+
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)"+CHAR(10)+
	"			as 'RestrictedToName',"+CHAR(10)+
	"N.NAMECODE		as 'RestrictedToNameCode',"+CHAR(10)+
	"N.NAMENO		as 'RestrictedToNameKey',"+CHAR(10)+
	"CAST(NI.PERIOD1AMT AS INT)		as 'Period1Amount',"+CHAR(10)+
	"NI.PERIOD1TYPE		as 'Period1TypeCode',"+CHAR(10)+
	"CAST(NI.PERIOD2AMT AS INT)		as 'Period2Amount',"+CHAR(10)+
	"NI.PERIOD2TYPE 	as 'Period2TypeCode',"+CHAR(10)+
	"CAST(NI.PERIOD3AMT AS INT)		as 'Period3Amount',"+CHAR(10)+
	"NI.PERIOD3TYPE 	as 'Period3TypeCode',"+CHAR(10)+
	"CASE WHEN @pnNameKey = @nHomeNameNo THEN CAST(0 as bit)"+CHAR(10)+ 	
	"	WHEN (NI.NAMENO = @nOfficeNameNo and @pnNameKey <> @nOfficeNameNo) THEN CAST(1 as bit)"+CHAR(10)+
	"	WHEN (NI.NAMENO = @nHomeNameNo)  THEN CAST(1 as bit)"+CHAR(10)+	
	"	ELSE CAST(0 as bit)"+CHAR(10)+
	"END			as 'IsDefault',"+CHAR(10)+
	"NI.ADJUSTMENT		as 'AdjustmentTypeKey',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('ADJUSTMENT','ADJUSTMENTDESC',null,'A',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'AdjustmentTypeDescription',"+CHAR(10)+
	"CASE WHEN(NI.NAMENO=@pnNameKey) "+CHAR(10)+
	"	THEN cast(NI.ADJUSTDAY as int) "+CHAR(10)+
	"	ELSE CASE WHEN(NI.ADJUSTMENT in ('~1','~2','~3','~4','~5')) THEN abs(@pnNameKey%28)+1 END"+CHAR(10)+
	"END			as 'AdjustmentDayOfMonth',"+CHAR(10)+
	"TCSM.USERCODE		as 'AdjustmentStartMonthKey',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCSM',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'AdjustmentStartMonth',"+CHAR(10)+
	"TCDOF.USERCODE		as 'AdjustmentDayOfWeekKey',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCDOF',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'AdjustmentDayOfWeek',"+CHAR(10)+
	"NI.ADJUSTTODATE	as 'AdjustToDate',"+CHAR(10)+
	"NI.STANDINGINSTRTEXT	as 'StandingInstrText'"+CHAR(10)+
	"from NAME IP"+CHAR(10)+
	"     join NAMEINSTRUCTIONS NI	on (NI.NAMENO = IP.NAMENO"+CHAR(10)+
	"				or  NI.NAMENO = @nOfficeNameNo"+CHAR(10)+
	"				or  NI.NAMENO = @nHomeNameNo)"+CHAR(10)+
	"left join INSTRUCTIONS I	on (I.INSTRUCTIONCODE = NI.INSTRUCTIONCODE)"+CHAR(10)+
	"left join INSTRUCTIONTYPE IT	on (IT.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE)"+CHAR(10)+
	"left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = NI.PROPERTYTYPE)"+CHAR(10)+
	"left join COUNTRY C 		on (C.COUNTRYCODE = NI.COUNTRYCODE)"+CHAR(10)+
	"left join NAMETYPE NT		on (NT.NAMETYPE = IT.RESTRICTEDBYTYPE)"+CHAR(10)+
	"left join NAME N		on (N.NAMENO = NI.RESTRICTEDTONAME)"+CHAR(10)+
	"left join ADJUSTMENT A	 	on (A.ADJUSTMENT = NI.ADJUSTMENT)"+CHAR(10)+
	"left join TABLECODES TCSM	on (TCSM.USERCODE  = CASE WHEN(NI.NAMENO=@pnNameKey) "+CHAR(10)+
	"							THEN NI.ADJUSTSTARTMONTH "+CHAR(10)+
								     -- if name is inherited then dynamically default adjustment month
	"							ELSE CASE WHEN(NI.ADJUSTMENT in ('~1','~2','~3','~4')) THEN abs(@pnNameKey%12)+1 END"+CHAR(10)+
	"						     END"+CHAR(10)+
	"				and TCSM.TABLETYPE = 89)"+CHAR(10)+
	"left join TABLECODES TCDOF	on (TCDOF.USERCODE = CASE WHEN(NI.NAMENO=@pnNameKey)"+CHAR(10)+
	"							THEN NI.ADJUSTDAYOFWEEK  "+CHAR(10)+
								     -- if name is inherited then dynamically default adjustment day of week
	"							ELSE CASE WHEN(NI.ADJUSTMENT in ('~6','~7')) THEN abs(@pnNameKey%@nWorkDays)+1 END"+CHAR(10)+
	"						     END"+CHAR(10)+
	"				and TCDOF.TABLETYPE= 88)"+CHAR(10)+
	"where IP.NAMENO = @pnNameKey"+CHAR(10)+
	"and NI.CASEID is null"+CHAR(10)+
			-- Don't return the Name Instruction against the Home Name
			-- if there is an equal or less specific rule aganst the Name
	"and not exists (Select *  "+CHAR(10)+
	"		from  NAMEINSTRUCTIONS NI2"+CHAR(10)+
	"		join  INSTRUCTIONS I2	on (I2.INSTRUCTIONCODE = NI2.INSTRUCTIONCODE)"+CHAR(10)+
	"		where ( (NI2.NAMENO=IP.NAMENO and NI.NAMENO  in (@nOfficeNameNo,@nHomeNameNo) )
				OR (NI2.NAMENO=@nOfficeNameNo and NI.NAMENO=@nHomeNameNo))"+CHAR(10)+
	"		and   NI2.NAMENO<>NI.NAMENO"+CHAR(10)+
	"		and   NI2.RESTRICTEDTONAME is null"+CHAR(10)+
	"		and   NI2.CASEID is null"+CHAR(10)+
	"		and   I2.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE"+CHAR(10)+
	"		and  (NI2.PROPERTYTYPE = NI.PROPERTYTYPE or NI2.PROPERTYTYPE is null)"+CHAR(10)+
	"		and  (NI2.COUNTRYCODE  = NI.COUNTRYCODE  or NI2.COUNTRYCODE  is null)"+CHAR(10)+
	"		)"
	+CHAR(10)

	-- RFC10974
	-- I can't understand why we have the code that restricts showing defaulted
	-- standing instructions unless the Name has been used against a case. I
	-- will only apply this test if the procedure is called from Centura so as 
	-- not to break the functionality there.

	If @pbCalledFromCentura=1
	Begin
		Set @sSQLString=@sSQLString+
			-- Show all standing instructions recorded directly against the name
			"and(NI.NAMENO = IP.NAMENO"+CHAR(10)+
			" or exists     (Select 1"+CHAR(10)+
			"		from  CASENAME CN"+CHAR(10)+
					-- For defaulted instructions, a corresponding case name must exist
			"		where CN.NAMENO = IP.NAMENO"+CHAR(10)+
			"		and   NI.NAMENO <> IP.NAMENO"+CHAR(10)+
			"		and   CN.NAMETYPE = IT.NAMETYPE"+CHAR(10)+
			"		and  (CN.EXPIRYDATE IS NULL or CN.EXPIRYDATE > GETDATE()))"+CHAR(10)+
			"	)"+CHAR(10)
	End
	
	Set @sSQLString=@sSQLString+
			-- InstructionType, Instruction, PropertyType, Country, RestrictedToName
			"Order by 'InstructionType', 'Instruction', 'PropertyType', 'Country', 'RestrictedToName'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @nOfficeNameNo	int,
					  @nHomeNameNo		int,
					  @nWorkDays		tinyint',
					  @pnNameKey		= @pnNameKey,
					  @nOfficeNameNo	= @nOfficeNameNo,
					  @nHomeNameNo		= @nHomeNameNo,
					  @nWorkDays		= @nWorkDays

	Set @pnRowCount = @@RowCount
End
-- Populating StandingInstruction result set for external users
If  @nErrorCode = 0
and @pbIsExternalUser = 1
Begin
	If @pnNameKey is not null
	Begin
		Set @sSQLString = "
		Select 
		CAST(NI.NAMENO as varchar(11))+'^'+
		CAST(NI.INTERNALSEQUENCE as varchar(10))
					as 'RowKey',
		@pnNameKey		as 'NameKey',
		IT.INSTRTYPEDESC	as 'InstructionType',
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'Instruction',
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'PropertyType',
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'Country',
		"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'RestrictedByNameType',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)
					as 'RestrictedToName',
		N.NAMECODE		as 'RestrictedToNameCode',
		N.NAMENO		as 'RestrictedToNameKey',
		CASE 	WHEN NI.NAMENO = @nHomeNameNo			
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END			as 'IsDefault'		
		from NAME IP
		     join NAMEINSTRUCTIONS NI	on (NI.NAMENO = IP.NAMENO
						or  NI.NAMENO = @nOfficeNameNo
						or NI.NAMENO = @nHomeNameNo)
		left join INSTRUCTIONS I	on (I.INSTRUCTIONCODE = NI.INSTRUCTIONCODE)
		join dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId, 1, @sLookupCulture, @pbCalledFromCentura) IT
						on (IT.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE)
		left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = NI.PROPERTYTYPE)
		left join COUNTRY C 		on (C.COUNTRYCODE = NI.COUNTRYCODE)
		left join NAMETYPE NT		on (NT.NAMETYPE = IT.RESTRICTEDBYTYPE)
		left join NAME N		on (N.NAMENO = NI.RESTRICTEDTONAME)
		where IP.NAMENO = @pnNameKey
		and NI.CASEID is null
			-- Don't return the Name Instruction against the Home Name
			-- if there is an equal or less specific rule aganst the Name
		and not exists (Select *  
				from  NAMEINSTRUCTIONS NI2
				join  INSTRUCTIONS I2	on (I2.INSTRUCTIONCODE = NI2.INSTRUCTIONCODE)
				where NI2.NAMENO= IP.NAMENO
				and   NI2.NAMENO<>NI.NAMENO
				and   NI2.RESTRICTEDTONAME is null
				and   NI2.CASEID is null
				and   I2.INSTRUCTIONTYPE = I.INSTRUCTIONTYPE
				and  (NI2.PROPERTYTYPE = NI.PROPERTYTYPE or NI2.PROPERTYTYPE is null)
				and  (NI2.COUNTRYCODE  = NI.COUNTRYCODE  or NI2.COUNTRYCODE  is null)
				)
		-- Show all standing instructions recorded directly against the name
		--and(NI.NAMENO = IP.NAMENO
		-- or exists     (Select	1
		--		from	CASENAME CN
		--		-- For defaulted instructions, a corresponding case name must exist
		--		where CN.NAMENO = IP.NAMENO
		--		and   NI.NAMENO <> IP.NAMENO
		--		and   CN.NAMETYPE = IT.NAMETYPE
		--		and  (CN.EXPIRYDATE IS NULL or CN.EXPIRYDATE > GETDATE()))
		--	)

		-- InstructionType, Instruction, PropertyType, Country, RestrictedToName
		Order by 'InstructionType', 'Instruction', 'PropertyType', 'Country', 'RestrictedToName'"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		int,
						  @nHomeNameNo		int,
						  @pnUserIdentityId	int,
						  @sLookupCulture	nvarchar(10),
						  @pbCalledFromCentura	bit,
						  @nOfficeNameNo	int',
						  @pnNameKey		= @pnNameKey,
						  @nHomeNameNo		= @nHomeNameNo,
						  @pnUserIdentityId	= @pnUserIdentityId,
						  @sLookupCulture	= @sLookupCulture,
						  @pbCalledFromCentura	= @pbCalledFromCentura,
						  @nOfficeNameNo	= @nOfficeNameNo
	
		Set @pnRowCount = @@RowCount
	End
	-- Unlike internal users, external users may not have access to the name.
	-- To improve performance, return an empty result without accessing the database. 
	Else If @pnNameKey is null
	Begin
		Select 
		null as 'NameKey',
		null as 'InstructionType',
		null as 'Instruction',
		null as 'PropertyType',
		null as 'Country',
		null as 'RestrictedByNameType',
		null as 'RestrictedToName',
		null as 'RestrictedToNameCode',
		null as 'RestrictedToNameKey',
		null as 'IsDefault'		
		where 1=2
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListStandingInstructions to public
GO
