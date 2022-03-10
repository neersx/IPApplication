-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertBillFormat
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertBillFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertBillFormat.'
	Drop procedure [dbo].[biw_InsertBillFormat]
End
Print '**** Creating Stored Procedure dbo.biw_InsertBillFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_InsertBillFormat
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 		= null,
	@psBillFormatName 	nvarchar(40),		-- Mandatory
	@pnNameKey		int			= null,
	@pnLanguageKey		int			= null,
	@pnEntityKey		int			= null,
	@psCaseTypeKey		nvarchar(1)		= null,
	@psActionKey		nvarchar(2)		= null,
	@pnStaffKey		int			= null,
	@psFormatDescription	nvarchar(254)		= null,
	@psReportFileName	nvarchar(254)		= null,
	@pnConsolidateSC	smallint		= null,
	@pnConsolidatePD	smallint		= null,
	@pnConsolidateOR	smallint		= null,
	@pnConsolidateDISC	smallint		= null,
	@pnConsolidateMAR	smallint		= null,
	@pbConsolidateSCByCase	bit			= null,
	@pbConsolidatePDByCase	bit			= null,
	@pbConsolidateORByCase	bit			= null,
	@pbConsolidateDISCByCase bit			= null,
	@pbConsolidateMARByCase bit			= null,
	@psExpenseGroupTitle	nvarchar(30)		= null,
	@pbConsolidateChargeType bit		= null,
	@pnOfficeKey		int			= null,
	@pnDebitNoteKey		smallint		= null,
	@pnCoverLetterKey	smallint		= null,
	@psPropertyTypeKey	nvarchar(2)		= null,
	@pbRenewalWip		bit			= null,
	@pbNonRenewalWip	bit			= null,
	@pbDebtorOnly		bit			= null,
	@pbSingleCase		bit			= null,
	@pbMultiCase		bit			= null,
	@pnSortDate		smallint		= null,
	@pnSortCase		smallint		= null,
	@pnSortCaseMode		smallint		= null,
	@pnSortCaseTitle	smallint		= null,
	@pnSortCaseDebtor	smallint		= null,
	@pnSortWIPCategory	smallint		= null,
	@pnFormatProfileKey	int			= null,
	@pbDisplayDate		bit			= null,
	@pbDisplayStaff		bit			= null,
	@pbDisplayTime		bit			= null,
	@pbDisplayChargeRate	bit			= null,
	@pbDisplayCase		bit			= null,
	@pbDisplayWipCode	bit			= null,
	@pnSortTaxCode		smallint		= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	biw_InsertBillFormat
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Inserts the details of a single bill format.

-- MODIFICATIONS :
-- Date		Who	Change		Version Description
-- -----------	-------	--------	------- ----------------------------------------------- 
-- 11 Feb 2010	LP	RFC8203		1	Procedure created
-- 19 May 2010	LP	RFC7276		2	Save Bill Format Profile Key.
-- 24 Jun 2010	MS	RFC7269		3	Added ConsolidateMAR in the insert	
-- 05 Dec 2011	AT	RFC10458	4	Added SortTaxCode.
-- 31 Jan 2012	KR	RFC10832 	5	Changed SINGLECASE value for Debtor Only and Multiple Case to match with c/s
-- 24 Oct 2017	AK	R72645	        6	Make compatible with case sensitive server with case insensitive database.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @nBillFormatKey int

declare @nDetailsRequired int
declare @nIsRenewal	tinyint
declare @nIsSingleCase	tinyint
declare @nConsolidateSC tinyint
declare @nConsolidatePD tinyint
declare @nConsolidateOR tinyint
declare @nConsolidateDISC tinyint
declare @nConsolidateMAR tinyint

-- Initialise variables
Set @nErrorCode = 0
Set @nDetailsRequired = 0
Set @nIsRenewal = 0
Set @nIsSingleCase = 0
Set @nConsolidateSC = 0
Set @nConsolidatePD = 0
Set @nConsolidateOR = 0
Set @nConsolidateDISC = 0
Set @nConsolidateMAR = 0

Set @nDetailsRequired = CASE	WHEN @pbDisplayDate = 1 THEN @nDetailsRequired + 1 ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pbDisplayStaff = 1 THEN @nDetailsRequired + 2 ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pbDisplayTime = 1 THEN @nDetailsRequired + 4 ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pbDisplayChargeRate = 1 THEN @nDetailsRequired + 8 ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pbDisplayCase = 1 THEN @nDetailsRequired + 16 ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pbDisplayWipCode = 1 THEN @nDetailsRequired + 32 ELSE @nDetailsRequired END
				
Set @nIsRenewal = CASE	WHEN @pbRenewalWip = 1 THEN 1 
			WHEN @pbNonRenewalWip = 1 THEN 0 END

Set @nIsSingleCase = CASE	WHEN @pbDebtorOnly = 1 THEN 2 
				WHEN @pbSingleCase = 1 THEN 1 
				WHEN @pbMultiCase = 1 THEN 0 END

Set @nConsolidateSC = CASE	WHEN @pnConsolidateSC > 0 and @pbConsolidateSCByCase = 1 THEN @pnConsolidateSC + 10
				ELSE @pnConsolidateSC END
				
Set @nConsolidatePD = CASE	WHEN @pnConsolidatePD > 0 and @pbConsolidatePDByCase = 1 THEN @pnConsolidatePD + 10
				ELSE @pnConsolidatePD END
				
Set @nConsolidateOR = CASE	WHEN @pnConsolidateOR > 0 and @pbConsolidateORByCase = 1 THEN @pnConsolidateOR + 10
				ELSE @pnConsolidateOR END
				
Set @nConsolidateDISC = CASE	WHEN @pnConsolidateDISC > 0 and @pbConsolidateDISCByCase = 1 THEN @pnConsolidateDISC + 10
				ELSE @pnConsolidateDISC END

Set @psReportFileName = CASE	WHEN PATINDEX('%.rdl',@psReportFileName) <= 0 THEN @psReportFileName + '.rdl'
				ELSE @psReportFileName END
				
Set @nConsolidateMAR = CASE	WHEN @pnConsolidateMAR > 0 and @pbConsolidateMARByCase = 1 THEN @pnConsolidateMAR + 10
				ELSE @pnConsolidateMAR END

-- Get the next available ID
exec @nErrorCode = dbo.ip_GetLastInternalCode
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psTable		= N'BILLFORMAT',
				@pnLastInternalCode	= @nBillFormatKey OUTPUT	
			

-- Construct the query
If @nErrorCode = 0
Begin
	Set @sSQLString = "INSERT INTO BILLFORMAT(
			BILLFORMATID,
			FORMATNAME,
			LANGUAGE,
			ENTITYNO,
			CASETYPE,
			ACTION,
			EMPLOYEENO,
			BILLFORMATDESC,
			BILLFORMATREPORT,
			CONSOLIDATESC,
			CONSOLIDATEPD,
			CONSOLIDATEOR,
			DETAILSREQUIRED,
			CONSOLIDATEDISC,
			CONSOLIDATEMAR,
			EXPENSEGROUPTITLE,
			CONSOLIDATECHTYP,
			OFFICEID,
			DEBITNOTE,
			COVERINGLETTER,
			PROPERTYTYPE,
			RENEWALWIP,
			SINGLECASE,
			SORTDATE,
			SORTCASE,
			SORTCASEMODE,
			SORTCASETITLE,
			SORTCASEDEBTORREF,
			SORTWIPCATEGORY,
			FORMATPROFILEID,
			SORTTAXCODE)			
			VALUES(
			@nBillFormatKey, 
			@psBillFormatName,
			@pnLanguageKey,
			@pnEntityKey, 
			@psCaseTypeKey,
			@psActionKey, 
			@pnStaffKey,
			@psFormatDescription, 
			@psReportFileName,			
			@nConsolidateSC, 
			@nConsolidatePD, 
			@nConsolidateOR,
			@nDetailsRequired,
			@nConsolidateDISC,
			@nConsolidateMAR,
			@psExpenseGroupTitle,
			@pbConsolidateChargeType,
			@pnOfficeKey,
			@pnDebitNoteKey,
			@pnCoverLetterKey,
			@psPropertyTypeKey,
			@nIsRenewal,
			@nIsSingleCase,
			@pnSortDate, 
			@pnSortCase, 
			@pnSortCaseMode, 
			@pnSortCaseTitle, 
			@pnSortCaseDebtor, 
			@pnSortWIPCategory,
			@pnFormatProfileKey,
			@pnSortTaxCode
		)"
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@nBillFormatKey	smallint,
						  @psBillFormatName 	nvarchar(254),
						  @pnLanguageKey	int,
						  @pnEntityKey		int,
						  @psCaseTypeKey	nvarchar(1),
						  @psActionKey		nvarchar(2),
						  @pnStaffKey		int,
						  @psFormatDescription  nvarchar(254),
						  @psReportFileName	nvarchar(254),
						  @nConsolidateSC	smallint,
						  @nConsolidatePD	smallint,
						  @nConsolidateOR	smallint,
						  @nDetailsRequired	smallint,
						  @nConsolidateDISC	smallint,
						  @nConsolidateMAR	smallint,
						  @psExpenseGroupTitle	nvarchar(30),
						  @pbConsolidateChargeType smallint,
						  @pnOfficeKey		int,
						  @pnDebitNoteKey	smallint,
						  @pnCoverLetterKey	smallint,
						  @psPropertyTypeKey	nvarchar(2),
						  @nIsRenewal		smallint,
						  @nIsSingleCase	smallint,
						  @pnSortDate		smallint,
						  @pnSortCase		smallint,
						  @pnSortCaseMode	smallint,
						  @pnSortCaseTitle	smallint,
						  @pnSortCaseDebtor	smallint,
						  @pnSortWIPCategory	smallint,
						  @pnFormatProfileKey	int,
						  @pnSortTaxCode	smallint',
						  @nBillFormatKey	= @nBillFormatKey,
						  @psBillFormatName 	= @psBillFormatName,
						  @pnLanguageKey	= @pnLanguageKey,
						  @pnEntityKey		= @pnEntityKey,
						  @psCaseTypeKey	= @psCaseTypeKey,
						  @psActionKey		= @psActionKey,
						  @pnStaffKey		= @pnStaffKey,
						  @psFormatDescription	= @psFormatDescription,
						  @psReportFileName	= @psReportFileName,
						  @nConsolidateSC	= @nConsolidateSC,
						  @nConsolidatePD	= @nConsolidatePD,
						  @nConsolidateOR	= @nConsolidateOR,
						  @nDetailsRequired	= @nDetailsRequired,
						  @nConsolidateDISC	= @nConsolidateDISC,
						  @nConsolidateMAR	= @nConsolidateMAR,
						  @psExpenseGroupTitle	= @psExpenseGroupTitle,
						  @pbConsolidateChargeType = @pbConsolidateChargeType,
						  @pnOfficeKey		= @pnOfficeKey,
						  @pnDebitNoteKey	= @pnDebitNoteKey,
						  @pnCoverLetterKey	= @pnCoverLetterKey,
						  @psPropertyTypeKey	= @psPropertyTypeKey,
						  @nIsRenewal		= @nIsRenewal,
						  @nIsSingleCase	= @nIsSingleCase,
						  @pnSortDate		= @pnSortDate,
						  @pnSortCase		= @pnSortCase,
						  @pnSortCaseMode	= @pnSortCaseMode,
						  @pnSortCaseTitle	= @pnSortCaseTitle,
						  @pnSortCaseDebtor	= @pnSortCaseDebtor,
						  @pnSortWIPCategory	= @pnSortWIPCategory,
						  @pnFormatProfileKey	= @pnFormatProfileKey,
						  @pnSortTaxCode	= @pnSortTaxCode
	
	
        SELECT @nBillFormatKey as BillFormatKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertBillFormat to public
GO
