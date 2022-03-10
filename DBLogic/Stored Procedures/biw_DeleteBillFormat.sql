-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_DeleteBillFormat
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_DeleteBillFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_DeleteBillFormat.'
	Drop procedure [dbo].[biw_DeleteBillFormat]
End
Print '**** Creating Stored Procedure dbo.biw_DeleteBillFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.biw_DeleteBillFormat
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 		= null,
	@pnBillFormatKey	int,			-- Mandatory
	@psOldBillFormatName 	nvarchar(40),		-- Mandatory
	@pnOldLanguageKey	int			= null,
	@pnOldEntityKey		int			= null,
	@psOldCaseTypeKey	nvarchar(1)		= null,
	@psOldActionKey		nvarchar(2)		= null,
	@pnOldStaffKey		int			= null,
	@psOldFormatDescription	nvarchar(254)		= null,
	@psOldReportFileName	nvarchar(254)		= null,
	@pnOldConsolidateSC	smallint		= null,
	@pnOldConsolidatePD	smallint		= null,
	@pnOldConsolidateOR	smallint		= null,
	@pnOldConsolidateDISC	smallint		= null,
	@pnOldConsolidateMAR	smallint		= null,
	@pnOldConsolidateSCByCase	bit			= null,
	@pnOldConsolidatePDByCase	bit			= null,
	@pnOldConsolidateORByCase	bit			= null,
	@pnOldConsolidateDISCByCase	bit			= null,
	@pbOldConsolidateMARByCase	bit			= null,
	@psOldExpenseGroupTitle		nvarchar(30)		= null,
	@pnOldConsolidateChargeType	smallint		= null,
	@pnOldOfficeKey			int			= null,
	@pnOldDebitNoteKey		smallint		= null,
	@pnOldCoverLetterKey		smallint		= null,
	@psOldPropertyTypeKey		nvarchar(2)		= null,
	@pnOldRenewalWip		bit		= null,
	@pnOldNonRenewalWip		bit		= null,
	@pnOldDebtorOnly		bit		= null,
	@pnOldSingleCase		bit		= null,
	@pnOldMultiCase			bit		= null,
	@pnOldSortDate			smallint		= null,
	@pnOldSortCase			smallint		= null,
	@pnOldSortCaseMode		smallint		= null,
	@pnOldSortCaseTitle		smallint		= null,
	@pnOldSortCaseDebtor		smallint		= null,
	@pnOldSortWIPCategory		smallint		= null,
	@pnOldFormatProfileKey		int			= null,
	@pnOldDisplayDate		bit		= null,
	@pnOldDisplayStaff		bit		= null,
	@pnOldDisplayTime		bit		= null,
	@pnOldDisplayChargeRate		bit		= null,
	@pnOldDisplayCase		bit		= null,
	@pnOldDisplayWipCode		bit		= null,
	@pnOldSortTaxCode		smallint	= null,
	@pbCalledFromCentura		bit			= 0
)
as
-- PROCEDURE:	biw_DeleteBillFormat
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes the specified bill format. Contains concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change		Version Description
-- -----------	-------	--------------- ------- ----------------------------------------------- 
-- 11 Feb 2010	LP	RFC8203		1	Procedure created
-- 19 May 2010	LP	RFC7276		2	Add Format Profile Key in where clause.
-- 24 Jun 2010	MS	RFC7269		3	Added parameter @pnOldConsolidateMAR and @pbOldConsolidateMARByCase in the Delete 
-- 05 Dec 2011	AT	RFC10458	4	Added SortTaxCode.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @nOldDetailsRequired tinyint
declare @nOldIsRenewal	tinyint
declare @nOldIsSingleCase tinyint
declare @nOldConsolidateSC tinyint
declare @nOldConsolidatePD tinyint
declare @nOldConsolidateOR tinyint
declare @nOldConsolidateDISC tinyint
declare @nOldConsolidateMAR tinyint

-- Initialise variables
Set @nErrorCode = 0
Set @nOldDetailsRequired = 0
Set @nOldIsRenewal = 0
Set @nOldIsSingleCase = 0
Set @nOldConsolidateSC = 0
Set @nOldConsolidatePD = 0
Set @nOldConsolidateOR = 0
Set @nOldConsolidateDISC = 0
Set @nOldConsolidateMAR = 0

Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayDate = 1 THEN @nOldDetailsRequired + 1  ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayStaff = 1 THEN @nOldDetailsRequired + 2 ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayTime = 1 THEN @nOldDetailsRequired + 4 ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayChargeRate = 1 THEN @nOldDetailsRequired + 8 ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayCase = 1 THEN @nOldDetailsRequired + 16 ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayWipCode = 1 THEN @nOldDetailsRequired + 32 ELSE @nOldDetailsRequired END
				
Set @nOldIsRenewal = CASE	WHEN @pnOldRenewalWip = 1 THEN 1 
				WHEN @pnOldNonRenewalWip = 1 THEN 0 ELSE NULL END
			
Set @nOldIsSingleCase = CASE	WHEN @pnOldDebtorOnly = 1 THEN 0 
				WHEN @pnOldSingleCase = 1 THEN 1 
				WHEN @pnOldMultiCase = 1 THEN 2 ELSE NULL END

Set @nOldConsolidateSC = CASE	WHEN @pnOldConsolidateSC > 0 and @pnOldConsolidateSCByCase = 1 THEN @pnOldConsolidateSC + 10
				ELSE @pnOldConsolidateSC END
				
Set @nOldConsolidatePD = CASE	WHEN @pnOldConsolidatePD > 0 and @pnOldConsolidatePDByCase = 1 THEN @pnOldConsolidatePD + 10
				ELSE @pnOldConsolidatePD END
				
Set @nOldConsolidateOR = CASE	WHEN @pnOldConsolidateOR > 0 and @pnOldConsolidateORByCase = 1 THEN @pnOldConsolidateOR + 10
				ELSE @pnOldConsolidateOR END
				
Set @nOldConsolidateDISC = CASE	WHEN @pnOldConsolidateDISC > 0 and @pnOldConsolidateDISCByCase = 1 THEN @pnOldConsolidateDISC + 10
				ELSE @pnOldConsolidateDISC END

Set @nOldConsolidateMAR = CASE	WHEN @pnOldConsolidateMAR > 0 and @pbOldConsolidateMARByCase = 1 THEN @pnOldConsolidateMAR + 10
				ELSE @pnOldConsolidateMAR END

-- Construct the query
If @nErrorCode = 0
Begin
	Set @sSQLString = "DELETE FROM BILLFORMAT
				WHERE
				BILLFORMATID		=@pnBillFormatKey
				AND FORMATNAME          =@psOldBillFormatName   
				AND LANGUAGE            =@pnOldLanguageKey         
				AND ENTITYNO            =@pnOldEntityKey          
				AND CASETYPE            =@psOldCaseTypeKey         
				AND ACTION              =@psOldActionKey        
				AND EMPLOYEENO          =@pnOldStaffKey           
				AND BILLFORMATDESC      =@psOldFormatDescription                
				AND BILLFORMATREPORT    =@psOldReportFileName		                 
				AND DETAILSREQUIRED     =@nOldDetailsRequired                
				AND CONSOLIDATESC       =@nOldConsolidateSC               
				AND CONSOLIDATEPD       =@nOldConsolidatePD               
				AND CONSOLIDATEOR       =@nOldConsolidateOR              				
				AND CONSOLIDATEDISC     =@nOldConsolidateDISC   
				AND CONSOLIDATEMAR      =@nOldConsolidateMAR              
				AND EXPENSEGROUPTITLE   =@psOldExpenseGroupTitle                  
				AND CONSOLIDATECHTYP   =@pnOldConsolidateChargeType                  
				AND OFFICEID            =@pnOldOfficeKey         
				AND DEBITNOTE           =@pnOldDebitNoteKey          
				AND COVERINGLETTER      =@pnOldCoverLetterKey               
				AND PROPERTYTYPE        =@psOldPropertyTypeKey             
				AND RENEWALWIP          =@nOldIsRenewal           
				AND SINGLECASE          =@nOldIsSingleCase           
				AND (SORTDATE           =@pnOldSortDate	OR SORTDATE IS NULL)
				AND (SORTCASE            =@pnOldSortCase OR SORTCASE IS NULL)         
				AND (SORTCASETITLE       =@pnOldSortCaseTitle OR SORTCASETITLE IS NULL)               
				AND (SORTCASEDEBTORREF   =@pnOldSortCaseDebtor OR SORTCASEDEBTORREF IS NULL)                   
				AND (SORTWIPCATEGORY     =@pnOldSortWIPCategory OR SORTWIPCATEGORY IS NULL)
				AND (FORMATPROFILEID	 =@pnOldFormatProfileKey OR FORMATPROFILEID IS NULL)
				and (SORTTAXCODE	=@pnOldSortTaxCode OR SORTTAXCODE IS NULL)"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBillFormatKey	smallint,
				  @psOldBillFormatName 	nvarchar(40),
				  @pnOldLanguageKey	int,
				  @pnOldEntityKey	int,
				  @psOldCaseTypeKey	nvarchar(1),
				  @psOldActionKey	nvarchar(2),
				  @pnOldStaffKey	int,
				  @psOldFormatDescription  nvarchar(254),
				  @psOldReportFileName	nvarchar(254),
				  @nOldDetailsRequired	smallint,
				  @nOldConsolidateSC	smallint,
				  @nOldConsolidatePD	smallint,
				  @nOldConsolidateOR	smallint,
				  @nOldConsolidateDISC	smallint,
				  @nOldConsolidateMAR	smallint,
				  @psOldExpenseGroupTitle nvarchar(30),
				  @pnOldConsolidateChargeType smallint,
				  @pnOldOfficeKey	int,
				  @pnOldDebitNoteKey	smallint,
				  @pnOldCoverLetterKey	smallint,
				  @psOldPropertyTypeKey	nvarchar(2),
				  @nOldIsRenewal	smallint,
				  @nOldIsSingleCase	smallint,
				  @pnOldSortDate	smallint,
				  @pnOldSortCase	smallint,
				  @pnOldSortCaseMode	smallint,
				  @pnOldSortCaseTitle	smallint,
				  @pnOldSortCaseDebtor	smallint,
				  @pnOldSortWIPCategory	smallint,
				  @pnOldFormatProfileKey int,
				  @pnOldSortTaxCode	smallint',
				  @pnBillFormatKey	= @pnBillFormatKey,
				  @psOldBillFormatName 	= @psOldBillFormatName,
				  @pnOldLanguageKey	= @pnOldLanguageKey,
				  @pnOldEntityKey	= @pnOldEntityKey,
				  @psOldCaseTypeKey	= @psOldCaseTypeKey,
				  @psOldActionKey	= @psOldActionKey,
				  @pnOldStaffKey	= @pnOldStaffKey,
				  @psOldFormatDescription = @psOldFormatDescription,
				  @psOldReportFileName	= @psOldReportFileName,
				  @nOldDetailsRequired	= @nOldDetailsRequired,
				  @nOldConsolidateSC	= @nOldConsolidateSC,
				  @nOldConsolidatePD	= @nOldConsolidatePD,
				  @nOldConsolidateOR	= @nOldConsolidateOR,
				  @nOldConsolidateDISC	= @nOldConsolidateDISC,
				  @nOldConsolidateMAR	= @nOldConsolidateMAR,
				  @psOldExpenseGroupTitle = @psOldExpenseGroupTitle,
				  @pnOldConsolidateChargeType = @pnOldConsolidateChargeType,
				  @pnOldOfficeKey	= @pnOldOfficeKey,
				  @pnOldDebitNoteKey	= @pnOldDebitNoteKey,
				  @pnOldCoverLetterKey	= @pnOldCoverLetterKey,
				  @psOldPropertyTypeKey	= @psOldPropertyTypeKey,
				  @nOldIsRenewal	= @nOldIsRenewal,
				  @nOldIsSingleCase	= @nOldIsSingleCase,
				  @pnOldSortDate	= @pnOldSortDate,
				  @pnOldSortCase	= @pnOldSortCase,
				  @pnOldSortCaseMode	= @pnOldSortCaseMode,
				  @pnOldSortCaseTitle	= @pnOldSortCaseTitle,
				  @pnOldSortCaseDebtor	= @pnOldSortCaseDebtor,
				  @pnOldSortWIPCategory	= @pnOldSortWIPCategory,
				  @pnOldFormatProfileKey = @pnOldFormatProfileKey,
				  @pnOldSortTaxCode	= @pnOldSortTaxCode
	
End

Return @nErrorCode
GO

Grant execute on dbo.biw_DeleteBillFormat to public
GO
