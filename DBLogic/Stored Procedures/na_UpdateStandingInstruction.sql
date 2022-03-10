-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_UpdateStandingInstruction
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateStandingInstruction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateStandingInstruction.'
	Drop procedure [dbo].[na_UpdateStandingInstruction]
End
Print '**** Creating Stored Procedure dbo.na_UpdateStandingInstruction...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_UpdateStandingInstruction
(
	@pnNameNo		int,
	@psInstructionType      nvarchar(3),
        @pnInstructionCode      smallint,
	@psAction		char(1),		-- I=Insert, U=Update, D=Delete
	@pnInternalSequence	int,			-- Must have a value for Deletes and Updates
        @pnRestrictedToName     int		=NULL,
	@pnCaseId		int		=NULL,
        @psCountryCode          nvarchar(3)	=NULL,
        @psPropertyType         nchar(1)	=NULL,
        @pnPeriod1Amt           smallint	=NULL,
        @psPeriod1Type          nchar(1)	=NULL,
        @pnPeriod2Amt           smallint	=NULL,
        @psPeriod2Type          nchar(1)	=NULL,
        @pnPeriod3Amt           smallint	=NULL,
        @psPeriod3Type          nchar(1)	=NULL,
	@pnUserIdentityId	int		=NULL,
	@psAdjustment		nvarchar(4)	=NULL,
	@pnAdjustDay		int		=NULL,
	@pnAdjustStartMonth	int		=NULL,
	@pnAdjustDayOfWeek	int		=NULL,
	@pdtAdjustToDate	datetime	=NULL,
	@psStandingInstrText	ntext	=NULL
)
as
-- PROCEDURE:	na_UpdateStandingInstruction
-- VERSION:	11
-- DESCRIPTION:	Used to insert or update a Standing Instruction against either a 
--		a Name or a Case.  Changing the standing instruction will generate
--		Policing requests to recalculate due dates of any events that rely
--		on the same instruction type.
-- COPYRIGHT	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Version	Number	Change
-- ------------	-------	-------	------	----------------------------------------------- 
--  2 Sep 2003	MF	1		Procedure created
-- 17 Aug 2004	MF	2 	10384	If the @psInstructionType is passed as an empty string then determine the value for the specific 
--					InstructionCode.  Also when generating POLICING rows to recalculate only ignore those Cases that 
--					have an existing Case level NameInstruction that matches the NameNo being modified.
-- 06 Aug 2004	AB	3	8035	Add collate database_default to temp table definitions
-- 16/11/2005	vql	4	9704	When updating POLICING table insert @pnUserIdentityId.
--					Create @pnUserIdentityId also.
-- 27 Feb 2006	TM	5	RFC3209	Replace existing Policing generation logic with a call to new ip_RecalculateInstructionType sp. 
-- 29 May 2006	KR	6	12319	Added adjustment type new columns to the insert/update list.
-- 15 Jul 2008	MF	7	16706	Remove #TEMPPOLICING table
-- 30 Apr 2009	vql	8	17542	Store and display free format text with a Standing Instruction.
-- 20 May 2010	MF	9	18761	Be more selective in what Cases are to be repoliced based on the characteristics of the Standing
--					Instruction being changed.
-- 17 May 2012	MF	10	R12317	Extension to SQA18761. Keep track of the specific NAMEINSTRUCTIONS row inserted to allows a more
--					targetted set of Policing requests to be raised.
-- 02 May 2013	MF	11	R13450	Retrofit of previously delivered changes.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @ErrorCode		int
Declare @RowCount 		int

Declare @sSQLString		nvarchar(4000)
Declare @bExistingEventsOnly	bit
Declare @bCountryNotChanged	bit
Declare	@bPropertyNotChanged	bit
Declare @bNameNotChanged	bit

Set @ErrorCode = 0
Set @RowCount  = 0

-- Get the Instruction Type if it has not been passed correctly.

If  @psInstructionType 	is null
and @pnInstructionCode  is not null
Begin
	Set @sSQLString=
		"Select @psInstructionType=INSTRUCTIONTYPE"+char(10)+
		"from INSTRUCTIONS I"+char(10)+
		"where I.INSTRUCTIONCODE=@pnInstructionCode"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psInstructionType	nvarchar(3)	OUTPUT,
				  @pnInstructionCode	smallint',
				  @psInstructionType=@psInstructionType	OUTPUT,
				  @pnInstructionCode=@pnInstructionCode
End

-- Delete the NAMEINSTRUCTION row

If  @ErrorCode=0
and @psAction='D'
Begin
	Set @sSQLString=
		"Delete NAMEINSTRUCTIONS"+char(10)+
		"From NAMEINSTRUCTIONS NI"+char(10)+ 
		"where NI.NAMENO=@pnNameNo"+char(10)+
		"and NI.INTERNALSEQUENCE=@pnInternalSequence"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNameNo		int,
				  @pnInternalSequence	int',
				  @pnNameNo=@pnNameNo,
				  @pnInternalSequence=@pnInternalSequence
	
	Set @RowCount=@@ROWCOUNT
End

-- Update the NAMEINSTRUCTION row

Else If  @ErrorCode=0
     and @psAction='U'
Begin
	--------------------------------------------------------------------
	-- Check which Case characteristics against the Standing Instruction 
	-- have changed.  This will be used to determine which Cases will
	-- require repolicing.
	--------------------------------------------------------------------
	Set @sSQLString=
	"Select @bCountryNotChanged =CASE WHEN(isnull(NI.COUNTRYCODE,     '')=isnull(@psCountryCode,     '')) THEN 1 ELSE 0 END,"+char(10)+
	"	@bPropertyNotChanged=CASE WHEN(isnull(NI.PROPERTYTYPE,    '')=isnull(@psPropertyType,    '')) THEN 1 ELSE 0 END,"+char(10)+
	"	@bNameNotChanged    =CASE WHEN(isnull(NI.RESTRICTEDTONAME,'')=isnull(@pnRestrictedToName,'')) THEN 1 ELSE 0 END," +char(10)+
	"	@bExistingEventsOnly=CASE WHEN(NI.INSTRUCTIONCODE            =@pnInstructionCode"+char(10)+
	"				   and isnull(NI.COUNTRYCODE,     '')=isnull(@psCountryCode,     '')"+char(10)+
	"				   and isnull(NI.PROPERTYTYPE,    '')=isnull(@psPropertyType,    '')"+char(10)+
	"				   and isnull(NI.RESTRICTEDTONAME,'')=isnull(@pnRestrictedToName,'')) THEN 1 ELSE 0 END" +char(10)+
	"From NAMEINSTRUCTIONS NI"+char(10)+ 
	"join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+char(10)+
	"where NI.NAMENO=@pnNameNo"+char(10)+
	"and NI.INTERNALSEQUENCE=@pnInternalSequence"+char(10)+
	"and I.INSTRUCTIONTYPE=@psInstructionType"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@bCountryNotChanged	bit	OUTPUT,
				  @bPropertyNotChanged	bit	OUTPUT,
				  @bNameNotChanged	bit	OUTPUT,
				  @bExistingEventsOnly	bit	OUTPUT,
				  @pnNameNo		int,
				  @pnInternalSequence	int,
				  @psInstructionType	nvarchar(3),
				  @pnInstructionCode	smallint,
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @pnRestrictedToName	int',
				  @bCountryNotChanged	=@bCountryNotChanged	OUTPUT,
				  @bPropertyNotChanged	=@bPropertyNotChanged	OUTPUT,
				  @bNameNotChanged	=@bNameNotChanged	OUTPUT,
				  @bExistingEventsOnly	=@bExistingEventsOnly	OUTPUT,
				  @pnNameNo		=@pnNameNo,
				  @pnInternalSequence	=@pnInternalSequence,
				  @psInstructionType	=@psInstructionType,
				  @pnInstructionCode	=@pnInstructionCode,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyType,
				  @pnRestrictedToName	=@pnRestrictedToName

	If @ErrorCode=0
	Begin
		Set @sSQLString=
		"Update NAMEINSTRUCTIONS"+char(10)+
		"Set INSTRUCTIONCODE=@pnInstructionCode,"+char(10)+
		"    COUNTRYCODE=@psCountryCode,"+char(10)+
		"    PROPERTYTYPE=@psPropertyType,"+char(10)+
		"    RESTRICTEDTONAME=@pnRestrictedToName,"+char(10)+
		"    PERIOD1AMT=@pnPeriod1Amt,"+char(10)+
		"    PERIOD1TYPE=@psPeriod1Type,"+char(10)+
		"    PERIOD2AMT=@pnPeriod2Amt,"+char(10)+
		"    PERIOD2TYPE=@psPeriod2Type,"+char(10)+
		"    PERIOD3AMT=@pnPeriod3Amt,"+char(10)+
		"    PERIOD3TYPE=@psPeriod3Type,"+char(10)+
		"    ADJUSTMENT=@psAdjustment,"+char(10)+
		"    ADJUSTDAY=@pnAdjustDay,"+char(10)+
		"    ADJUSTSTARTMONTH=@pnAdjustStartMonth,"+char(10)+
		"    ADJUSTDAYOFWEEK=@pnAdjustDayOfWeek,"+char(10)+
		"    ADJUSTTODATE=@pdtAdjustToDate,"+char(10)+
		"    STANDINGINSTRTEXT=cast(@psStandingInstrText as nvarchar(4000))"+char(10)+
		"From NAMEINSTRUCTIONS NI"+char(10)+ 
		"join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+char(10)+
		"where NI.NAMENO=@pnNameNo"+char(10)+
		"and NI.INTERNALSEQUENCE=@pnInternalSequence"+char(10)+
		"and I.INSTRUCTIONTYPE=@psInstructionType"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNameNo		int,
				  @pnInternalSequence	int,
				  @psInstructionType	nvarchar(3),
				  @pnInstructionCode	smallint,
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @pnRestrictedToName	int,
				  @pnPeriod1Amt		smallint,
				  @psPeriod1Type	nchar(1),
				  @pnPeriod2Amt		smallint,
				  @psPeriod2Type	nchar(1),
				  @pnPeriod3Amt		smallint,
				  @psPeriod3Type	nchar(1),
				  @psAdjustment		nvarchar(4),
				  @pnAdjustDay		int,
				  @pnAdjustStartMonth	int,
				  @pnAdjustDayOfWeek	int,
				  @pdtAdjustToDate	datetime,
				  @psStandingInstrText	nvarchar(4000)',
				  @pnNameNo		=@pnNameNo,
				  @pnInternalSequence	=@pnInternalSequence,
				  @psInstructionType	=@psInstructionType,
				  @pnInstructionCode	=@pnInstructionCode,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyType,
				  @pnRestrictedToName	=@pnRestrictedToName,
				  @pnPeriod1Amt		=@pnPeriod1Amt,
				  @psPeriod1Type	=@psPeriod1Type,
				  @pnPeriod2Amt		=@pnPeriod2Amt,
				  @psPeriod2Type	=@psPeriod2Type,
				  @pnPeriod3Amt		=@pnPeriod3Amt,
				  @psPeriod3Type	=@psPeriod3Type,
				  @psAdjustment		=@psAdjustment,
				  @pnAdjustDay		=@pnAdjustDay,
				  @pnAdjustStartMonth	=@pnAdjustStartMonth,
				  @pnAdjustDayOfWeek	=@pnAdjustDayOfWeek,
				  @pdtAdjustToDate	=@pdtAdjustToDate,
				  @psStandingInstrText	=@psStandingInstrText
	
		Set @RowCount=@@ROWCOUNT

		-- If no rows have been updated then raise an error as it is probable
		-- that the INSTRUCTIONTYPE of the new INSTRUCTIONCODE is not matching 
		-- the INSTRUCTIONTYPE of the INSTRUCTIONCODE being changed.

		If @RowCount=0
			Set @ErrorCode=-1
	End
End

-- Insert a new NAMEINSTRUCTION row

Else If  @ErrorCode=0
     and @psAction='I'
Begin
	-------------------------------------------------------------
	-- RFC 12317
	-- Get the next InternalSequence to be used so that a more
	-- targetted set of Policing requests can be later generated.
	-------------------------------------------------------------
	Set @pnInternalSequence=0
	
	Set @sSQLString="
	Select @pnInternalSequence=max(INTERNALSEQUENCE)
	from NAMEINSTRUCTIONS
	where NAMENO=@pnNameNo"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnInternalSequence			int	OUTPUT,
				  @pnNameNo				int',
				  @pnInternalSequence=@pnInternalSequence	OUTPUT,
				  @pnNameNo          =@pnNameNo
				  
	Set @pnInternalSequence=ISNULL(@pnInternalSequence,0)+1
	
	If @ErrorCode=0
	Begin	
	Set @sSQLString=
	"insert into NAMEINSTRUCTIONS(NAMENO, INTERNALSEQUENCE, INSTRUCTIONCODE, CASEID, COUNTRYCODE, PROPERTYTYPE,"+char(10)+ 
	"                             RESTRICTEDTONAME, PERIOD1AMT, PERIOD1TYPE, PERIOD2AMT, PERIOD2TYPE, PERIOD3AMT,"+char(10)+
		"                             PERIOD3TYPE, ADJUSTMENT, ADJUSTDAY, ADJUSTSTARTMONTH, ADJUSTDAYOFWEEK, ADJUSTTODATE, STANDINGINSTRTEXT)"+char(10)+
		"values(@pnNameNo, @pnInternalSequence, @pnInstructionCode, @pnCaseId, @psCountryCode, @psPropertyType,"+char(10)+
	"       @pnRestrictedToName, @pnPeriod1Amt, @psPeriod1Type,@pnPeriod2Amt, @psPeriod2Type,@pnPeriod3Amt,"+char(10)+
		"       @psPeriod3Type, @psAdjustment, @pnAdjustDay, @pnAdjustStartMonth, @pnAdjustDayOfWeek, @pdtAdjustToDate, cast(@psStandingInstrText as nvarchar(4000)) )"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNameNo		int,
				  @pnInternalSequence	int,
				  @pnInstructionCode	smallint,
				  @pnCaseId		int,
				  @psCountryCode	nvarchar(3),
				  @psPropertyType	nchar(1),
				  @pnRestrictedToName	int,
				  @pnPeriod1Amt		smallint,
				  @psPeriod1Type	nchar(1),
				  @pnPeriod2Amt		smallint,
				  @psPeriod2Type	nchar(1),
				  @pnPeriod3Amt		smallint,
				  @psPeriod3Type	nchar(1),
				  @psAdjustment		nvarchar(4),
				  @pnAdjustDay		int,
				  @pnAdjustStartMonth	int,
				  @pnAdjustDayOfWeek	int,
				  @pdtAdjustToDate	datetime,
				  @psStandingInstrText	nvarchar(4000)',
				  @pnNameNo		=@pnNameNo,
				  @pnInternalSequence	=@pnInternalSequence,
				  @pnInstructionCode	=@pnInstructionCode,
				  @pnCaseId		=@pnCaseId,
				  @psCountryCode	=@psCountryCode,
				  @psPropertyType	=@psPropertyType,
				  @pnRestrictedToName	=@pnRestrictedToName,
				  @pnPeriod1Amt		=@pnPeriod1Amt,
				  @psPeriod1Type	=@psPeriod1Type,
				  @pnPeriod2Amt		=@pnPeriod2Amt,
				  @psPeriod2Type	=@psPeriod2Type,
				  @pnPeriod3Amt		=@pnPeriod3Amt,
				  @psPeriod3Type	=@psPeriod3Type,
				  @psAdjustment		=@psAdjustment,
				  @pnAdjustDay		=@pnAdjustDay,
				  @pnAdjustStartMonth	=@pnAdjustStartMonth,
				  @pnAdjustDayOfWeek	=@pnAdjustDayOfWeek,
				  @pdtAdjustToDate	=@pdtAdjustToDate,
				  @psStandingInstrText	=@psStandingInstrText
	
		Set @RowCount=@@ROWCOUNT
	End
End

-- Now generate Policing requests for the Case Events that should be recalculated as a result
-- of either the new, updated or removed standing instructions

If @ErrorCode=0
and @RowCount>0
Begin
	exec @ErrorCode=dbo.ip_RecalculateInstructionType
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= 1,
			@psInstructionType 	= @psInstructionType,
			@psAction		= @psAction,
			@pnCaseKey 		= @pnCaseId,		-- If the standing instruction has been modified against the Case then only recalculate Events for that specific Case.
			@pnNameKey 		= @pnNameNo,		-- If the standing instruction has been modified at the Name level then recalculate the CaseEvent rows for Cases linked to that name via the relevant NameType
			@pnInternalSequence	= @pnInternalSequence,
			@pbExistingEventsOnly	= @bExistingEventsOnly,
			@pbCountryNotChanged	= @bCountryNotChanged,
			@pbPropertyNotChanged	= @bPropertyNotChanged,
			@pbNameNotChanged	= @bNameNotChanged
End

Return @ErrorCode
GO

Grant execute on dbo.na_UpdateStandingInstruction to public
GO
