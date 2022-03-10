
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_InsertOpportunity									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_InsertOpportunity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_InsertOpportunity.'
	Drop procedure [dbo].[crm_InsertOpportunity]
End
Print '**** Creating Stored Procedure dbo.crm_InsertOpportunity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_InsertOpportunity
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory.
	@pnPotentialValueLocal		decimal(11,2)	= null,
	@pnPotentialValue		decimal(11,2)	= null,
	@pnSource			int		= null,
	@pdtExpCloseDate		datetime	= null,
	@psRemarks			nvarchar(254)	= null,
	@pnPotentialWin			decimal(5,2)	= null,
	@psNextStep			nvarchar(254)	= null,
	@pnStage			int		= null,
	@psPotentialValCurrency		nvarchar(3)	= null,
	@pnNumberOfStaff		int		= null,
	@pnProductInterest		int		= null,
	@pbIsPotentialValueLocalInUse	bit	 	= 0,
	@pbIsPotentialValueInUse	bit	 	= 0,
	@pbIsSourceInUse		bit	 	= 0,
	@pbIsExpCloseDateInUse		bit	 	= 0,
	@pbIsRemarksInUse		bit	 	= 0,
	@pbIsPotentialWinInUse		bit	 	= 0,
	@pbIsNextStepInUse		bit	 	= 0,
	@pbIsStageInUse			bit	 	= 0,
	@pbIsPotentialValCurrencyInUse	bit		= 0,
	@pbIsNumberOfStaffInUse		bit		= 0,
	@pbIsProductInterestInUse	bit		= 0
)
as
-- PROCEDURE:	crm_InsertOpportunity
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Opportunity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 17 Jun 2008	AT	RFC5748	1	Procedure created
-- 20 Aug 2008	AT	RFC6894	2	Added Potential Value Local
-- 13 Nov 2008	AT	RFC7029	3	Default Lead For relationship between Prospect and Lead.

SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into OPPORTUNITY
				("

	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			CASEID
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnCaseKey
			"

	If @pbIsPotentialValueLocalInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POTENTIALVALUELOCAL"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPotentialValueLocal"
		Set @sComma = ","
	End

	If @pbIsPotentialValueInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POTENTIALVALUE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPotentialValue"
		Set @sComma = ","
	End

	If @pbIsSourceInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"SOURCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnSource"
		Set @sComma = ","
	End

	If @pbIsExpCloseDateInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"EXPCLOSEDATE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pdtExpCloseDate"
		Set @sComma = ","
	End

	If @pbIsRemarksInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"REMARKS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psRemarks"
		Set @sComma = ","
	End

	If @pbIsPotentialWinInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POTENTIALWIN"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnPotentialWin"
		Set @sComma = ","
	End

	If @pbIsNextStepInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NEXTSTEP"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psNextStep"
		Set @sComma = ","
	End

	If @pbIsStageInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"STAGE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnStage"
		Set @sComma = ","
	End

	If @pbIsPotentialValCurrencyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"POTENTIALVALCURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psPotentialValCurrency"
		Set @sComma = ","
	End

	If @pbIsNumberOfStaffInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"NUMBEROFSTAFF"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnNumberOfStaff"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnPotentialValueLocal	decimal(11,2),
			@pnPotentialValue	decimal(11,2),
			@pnSource		int,
			@pdtExpCloseDate	datetime,
			@psRemarks		nvarchar(254),
			@pnPotentialWin		decimal(5,2),
			@psNextStep		nvarchar(254),
			@pnStage		int,
			@psPotentialValCurrency	nvarchar(3),
			@pnNumberOfStaff	int',
			@pnCaseKey	 	= @pnCaseKey,
			@pnPotentialValueLocal	= @pnPotentialValueLocal,
			@pnPotentialValue	= @pnPotentialValue,
			@pnSource	 	= @pnSource,
			@pdtExpCloseDate	= @pdtExpCloseDate,
			@psRemarks		= @psRemarks,
			@pnPotentialWin		= @pnPotentialWin,
			@psNextStep		= @psNextStep,
			@pnStage		= @pnStage,
			@psPotentialValCurrency	= @psPotentialValCurrency,
			@pnNumberOfStaff	= @pnNumberOfStaff
End

if (@nErrorCode = 0 and @pbIsProductInterestInUse = 1 and @pnProductInterest is not null)
Begin
	-- Insert Product Interest attribute
	Set @sSQLString = "
		insert into TABLEATTRIBUTES(PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
		values('CASES', @pnCaseKey, @pnProductInterest, 151)"

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
				@pnCaseKey		int,
				@pnProductInterest	int',
				@pnCaseKey = @pnCaseKey,
				@pnProductInterest = @pnProductInterest
End

if (@nErrorCode = 0)
Begin
	-- Default the Lead For relationship between the lead and the prospect (if it doesn't already exist)
	Set @sSQLString = "
		Insert into ASSOCIATEDNAME (NAMENO, RELATIONSHIP, RELATEDNAME, [SEQUENCE])
		Select PR.NAMENO, 'LEA' RELATIONSHIP, LD.NAMENO RELATEDNAME, ISNULL(ANSEQ.[SEQUENCE], 0) [SEQUENCE]
		from CASENAME PR 
		join CASENAME LD on (LD.CASEID = PR.CASEID
					and LD.NAMETYPE = '~LD'
					and PR.NAMETYPE = '~PR')
		left join ASSOCIATEDNAME AN on (AN.RELATEDNAME = LD.NAMENO 
					and AN.NAMENO = PR.NAMENO
					and AN.RELATIONSHIP = 'LEA')
		left join (SELECT ANS.NAMENO, MAX(ANS.SEQUENCE) + 1 AS SEQUENCE
				FROM ASSOCIATEDNAME ANS
				WHERE ANS.RELATIONSHIP = 'LEA'
				GROUP BY ANS.NAMENO) ANSEQ ON (ANSEQ.NAMENO = PR.NAMENO)
		where PR.CASEID = @pnCaseKey
		and AN.NAMENO is null"

	exec @nErrorCode=sp_executesql @sSQLString,
		      		N'@pnCaseKey		int',
				@pnCaseKey = @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.crm_InsertOpportunity to public
GO