-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchStandingInstruction									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchStandingInstruction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchStandingInstruction.'
	Drop procedure [dbo].[naw_FetchStandingInstruction]
End
Print '**** Creating Stored Procedure dbo.naw_FetchStandingInstruction...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchStandingInstruction
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_FetchStandingInstruction
-- VERSION:	11
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the StandingInstructionEntity business entity for supplied NameKey.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Feb 2006	TM	RFC3209	1	Procedure created
-- 21 Mar 2006 	PG	RFC3209	2	Return RowKey and PeriodTypeDescriptions
-- 24 May 2006 	IB	RFC3678	3	Return adjustments
-- 02 Jun 2006	IB	RFC3910	4	Adjustment type should be translatable.
-- 06 Nov 2007	AT	RFC3502 5	Return tinyInts as Ints.
-- 07 Dec 2007	AT	RFC3502	6	Return smallInts as Ints.
-- 28 Oct 2008	AT	RFC7202	7	Return more Small/tinyInts as Ints.
-- 04 Oct 2010  DV     	 RFC7914 	8       Return STANDINGINSTRTEXT column.
-- 21 Oct 2010	LP	RFC9756	9	Only return name-level instructions, i.e. CASEID IS NULL
-- 11 Apr 2013	DV	R13270	10	Increase the length of nvarchar to 11 when casting or declaring integer 
-- 02 Nov 2015	vql	R53910	11	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select  CAST(NI.NAMENO as nvarchar(11))+'^'+
		CAST(NI.INTERNALSEQUENCE as nvarchar(10)) as RowKey,
		NI.NAMENO		as NameKey,
		NI.INTERNALSEQUENCE	as Sequence,	
		I.INSTRUCTIONTYPE	as InstructionTypeCode,
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'IT',@sLookupCulture,@pbCalledFromCentura)+"
					as InstructionTypeDescription,
		cast(NI.INSTRUCTIONCODE as int)	as InstructionCode,
		"+dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,'I',@sLookupCulture,@pbCalledFromCentura)+"
					as InstructionDescription,
		null			as DefaultedFromName,
		NI.PROPERTYTYPE		as PropertyTypeCode,
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)+"
					as PropertyTypeDescription,
		NI.COUNTRYCODE		as CountryCode,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)+"
					as CountryName,
		NI.RESTRICTEDTONAME	as RestrictedToNameKey,
		dbo.fn_FormatNameUsingNameNo(NR.NAMENO, default)
					as RestrictedToName,
		NI.CASEID		as CaseKey, 									
		cast(NI.PERIOD1AMT as int)		as Period1Amount,
		NI.PERIOD1TYPE		as Period1Type,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)+"
					as Period1TypeDescription,
		cast(NI.PERIOD2AMT as int)		as Period2Amount,
		NI.PERIOD2TYPE		as Period2Type,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)+"
					as Period2TypeDescription,
		cast(NI.PERIOD3AMT as int)		as Period3Amount,
		NI.PERIOD3TYPE		as Period3Type,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC3',@sLookupCulture,@pbCalledFromCentura)+"
					as Period3TypeDescription,
		null			as IsDefault,
		NI.ADJUSTMENT		as AdjustmentTypeKey,
		"+dbo.fn_SqlTranslatedColumn('ADJUSTMENT','ADJUSTMENTDESC',null,'A',@sLookupCulture,@pbCalledFromCentura)+"
					as AdjustmentTypeDescription,
		cast(NI.ADJUSTDAY as int)
					as AdjustmentDayOfMonth,
		cast(NI.ADJUSTSTARTMONTH as int)	
					as AdjustmentStartMonthKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCSM',@sLookupCulture,@pbCalledFromCentura)+"
					as AdjustmentStartMonth,
		cast(NI.ADJUSTDAYOFWEEK as int)
					as AdjustmentDayOfWeekKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCDOF',@sLookupCulture,@pbCalledFromCentura)+"
					as AdjustmentDayOfWeek,
		NI.ADJUSTTODATE		as AdjustToDate,
		NI.STANDINGINSTRTEXT    as StandingInstrText			
		from NAMEINSTRUCTIONS NI 	
		join INSTRUCTIONS I	 	on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
		join INSTRUCTIONTYPE IT	 	on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = NI.PROPERTYTYPE)
		left join COUNTRY C		on (C.COUNTRYCODE = NI.COUNTRYCODE)
		left join NAME NR		on (NR.NAMENO = NI.RESTRICTEDTONAME)
		left join TABLECODES TC1	on (TC1.USERCODE = NI.PERIOD1TYPE and TC1.TABLETYPE=127)
		left join TABLECODES TC2	on (TC2.USERCODE = NI.PERIOD2TYPE and TC2.TABLETYPE=127)
		left join TABLECODES TC3	on (TC3.USERCODE = NI.PERIOD3TYPE and TC3.TABLETYPE=127)	
		left join ADJUSTMENT A	 	on (A.ADJUSTMENT = NI.ADJUSTMENT)
		left join TABLECODES TCSM	on (TCSM.USERCODE = NI.ADJUSTSTARTMONTH	and TCSM.TABLETYPE = 89)
		left join TABLECODES TCDOF	on (TCDOF.USERCODE = NI.ADJUSTDAYOFWEEK	and TCDOF.TABLETYPE = 88)
		where NI.NAMENO = @pnNameKey 
		and NI.CASEID IS NULL
		order by InstructionTypeDescription, CountryName, PropertyTypeDescription, InstructionDescription"	

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnNameKey	int',
				@pnNameKey	 = @pnNameKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchStandingInstruction to public
GO