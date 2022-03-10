-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_UpdateBillFormat
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_UpdateBillFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_UpdateBillFormat.'
	Drop procedure [dbo].[biw_UpdateBillFormat]
End
Print '**** Creating Stored Procedure dbo.biw_UpdateBillFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.biw_UpdateBillFormat
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 		= null,
	@pnBillFormatKey	int,			-- Mandatory
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
	@pnConsolidateSCByCase	bit			= null,
	@pnConsolidatePDByCase	bit			= null,
	@pnConsolidateORByCase	bit			= null,
	@pnConsolidateDISCByCase bit			= null,
	@pbConsolidateMARByCase bit			= null,
	@psExpenseGroupTitle	nvarchar(30)		= null,
	@pnConsolidateChargeType smallint		= null,
	@pnOfficeKey		int			= null,
	@pnDebitNoteKey		smallint		= null,
	@pnCoverLetterKey	smallint		= null,
	@psPropertyTypeKey	nvarchar(2)		= null,
	@pnRenewalWip		bit		= null,
	@pnNonRenewalWip	bit		= null,
	@pnDebtorOnly		bit		= null,
	@pnSingleCase		bit		= null,
	@pnMultiCase		bit		= null,
	@pnSortDate		smallint		= null,
	@pnSortCase		smallint		= null,
	@pnSortCaseMode		smallint		= null,
	@pnSortCaseTitle	smallint		= null,
	@pnSortCaseDebtor	smallint		= null,
	@pnSortWIPCategory	smallint		= null,
	@pnFormatProfileKey	int			= null,
	@pnDisplayDate		bit		= null,
	@pnDisplayStaff		bit		= null,
	@pnDisplayTime		bit		= null,
	@pnDisplayChargeRate	bit		= null,
	@pnDisplayCase		bit		= null,
	@pnDisplayWipCode	bit		= null,
	@pnSortTaxCode		smallint	= null,
	@psOldBillFormatName 	nvarchar(40),		-- Mandatory
	@pnOldNameKey		int			= null,
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
	@psOldExpenseGroupTitle	nvarchar(30)		= null,
	@pnOldConsolidateChargeType smallint		= null,
	@pnOldOfficeKey		int			= null,
	@pnOldDebitNoteKey	smallint		= null,
	@pnOldCoverLetterKey	smallint		= null,
	@psOldPropertyTypeKey	nvarchar(2)		= null,
	@pnOldRenewalWip	bit		= null,
	@pnOldNonRenewalWip	bit		= null,
	@pnOldDebtorOnly	bit		= null,
	@pnOldSingleCase	bit		= null,
	@pnOldMultiCase		bit		= null,
	@pnOldSortDate		smallint		= null,
	@pnOldSortCase		smallint		= null,
	@pnOldSortCaseMode	smallint		= null,
	@pnOldSortCaseTitle	smallint		= null,
	@pnOldSortCaseDebtor	smallint		= null,
	@pnOldSortWIPCategory	smallint		= null,
	@pnOldFormatProfileKey	int			= null,
	@pnOldDisplayDate	bit		= null,
	@pnOldDisplayStaff	bit		= null,
	@pnOldDisplayTime	bit		= null,
	@pnOldDisplayChargeRate	bit		= null,
	@pnOldDisplayCase	bit		= null,
	@pnOldDisplayWipCode	bit		= null,
	@pnOldSortTaxCode	smallint	= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	biw_UpdateBillFormat
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates the specified bill format. Contains concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 12 Feb 2010	LP	RFC8203		1	Procedure created
-- 19 may 2010	LP	RFC7276		2	Save Bill Format Profile key.
-- 24 Jun 2010	MS	RFC7269		3	Added ConsolidateMAR in the Update
-- 05 Dec 2011	AT	RFC10458		4	Added SortTaxCode.
-- 31 Jan 2012	KR	RFC10832 		5	 Changed SINGLECASE value for Debtor Only and Multiple Case to match with c/s


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @nDetailsRequired tinyint
declare @nOldDetailsRequired tinyint
declare @nIsRenewal	tinyint
declare @nOldIsRenewal	tinyint
declare @nIsSingleCase	tinyint
declare @nOldIsSingleCase tinyint
declare @nConsolidateSC tinyint
declare @nConsolidatePD tinyint
declare @nConsolidateOR tinyint
declare @nConsolidateDISC tinyint
declare @nConsolidateMAR tinyint
declare @nOldConsolidateSC tinyint
declare @nOldConsolidatePD tinyint
declare @nOldConsolidateOR tinyint
declare @nOldConsolidateDISC tinyint
declare @nOldConsolidateMAR tinyint

-- Initialise variables
Set @nErrorCode = 0
Set @nDetailsRequired = 0
Set @nOldDetailsRequired = 0
Set @nIsRenewal = 0
Set @nOldIsRenewal = 0
Set @nIsSingleCase = 0
Set @nOldIsSingleCase = 0
Set @nConsolidateSC = 0
Set @nConsolidatePD = 0
Set @nConsolidateOR = 0
Set @nConsolidateDISC = 0
Set @nOldConsolidateSC = 0
Set @nOldConsolidatePD = 0
Set @nOldConsolidateOR = 0
Set @nOldConsolidateDISC = 0

Set @nDetailsRequired = CASE	WHEN @pnDisplayDate = 1 THEN @nDetailsRequired + 1  ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pnDisplayStaff = 1 THEN @nDetailsRequired + 2  ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pnDisplayTime = 1 THEN @nDetailsRequired + 4  ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pnDisplayChargeRate = 1 THEN @nDetailsRequired + 8  ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pnDisplayCase = 1 THEN @nDetailsRequired + 16 ELSE @nDetailsRequired END
Set @nDetailsRequired = CASE	WHEN @pnDisplayWipCode = 1 THEN @nDetailsRequired + 32  ELSE @nDetailsRequired END

Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayDate = 1 THEN @nOldDetailsRequired + 1  ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayStaff = 1 THEN @nOldDetailsRequired + 2  ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayTime = 1 THEN @nOldDetailsRequired + 4  ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayChargeRate = 1 THEN @nOldDetailsRequired + 8  ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayCase = 1 THEN @nOldDetailsRequired + 16  ELSE @nOldDetailsRequired END
Set @nOldDetailsRequired = CASE	WHEN @pnOldDisplayWipCode = 1 THEN @nOldDetailsRequired + 32  ELSE @nOldDetailsRequired END
				
Set @nIsRenewal = CASE	WHEN @pnRenewalWip = 1 THEN 1 
			WHEN @pnNonRenewalWip = 1 THEN 0 ELSE NULL END

Set @nOldIsRenewal = CASE	WHEN @pnOldRenewalWip = 1 THEN 1 
				WHEN @pnOldNonRenewalWip = 1 THEN 0 ELSE NULL END
			
Set @nIsSingleCase = CASE	WHEN @pnDebtorOnly = 1 THEN 2 
				WHEN @pnSingleCase = 1 THEN 1 
				WHEN @pnMultiCase = 1 THEN 0 ELSE NULL END

Set @nOldIsSingleCase = CASE	WHEN @pnOldDebtorOnly = 1 THEN 2 
				WHEN @pnOldSingleCase = 1 THEN 1 
				WHEN @pnOldMultiCase = 1 THEN 0 ELSE NULL END

Set @nConsolidateSC = CASE	WHEN @pnConsolidateSC > 0 and @pnConsolidateSCByCase = 1 THEN @pnConsolidateSC + 10
				ELSE @pnConsolidateSC END
				
Set @nConsolidatePD = CASE	WHEN @pnConsolidatePD > 0 and @pnConsolidatePDByCase = 1 THEN @pnConsolidatePD + 10
				ELSE @pnConsolidatePD END
				
Set @nConsolidateOR = CASE	WHEN @pnConsolidateOR > 0 and @pnConsolidateORByCase = 1 THEN @pnConsolidateOR + 10
				ELSE @pnConsolidateOR END
				
Set @nConsolidateDISC = CASE	WHEN @pnConsolidateDISC > 0 and @pnConsolidateDISCByCase = 1 THEN @pnConsolidateDISC + 10
				ELSE @pnConsolidateDISC END

Set @nConsolidateMAR = CASE	WHEN @pnConsolidateMAR > 0 and @pbConsolidateMARByCase = 1 THEN @pnConsolidateMAR + 10
				ELSE @pnConsolidateMAR END

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

Set @psReportFileName = CASE	WHEN PATINDEX('%.rdl',@psReportFileName) <= 0 THEN @psReportFileName + '.rdl'
				ELSE @psReportFileName END
-- Construct the query
If @nErrorCode = 0
Begin
	Set @sSQLString = "UPDATE BILLFORMAT
				SET
				FORMATNAME          =@psBillFormatName, 
				LANGUAGE            =@pnLanguageKey,         
				ENTITYNO            =@pnEntityKey,          
				CASETYPE            =@psCaseTypeKey,         
				ACTION              =@psActionKey,        
				EMPLOYEENO          =@pnStaffKey,           
				BILLFORMATDESC      =@psFormatDescription,                
				BILLFORMATREPORT    =@psReportFileName,		                 
				CONSOLIDATESC       =@nConsolidateSC,               
				CONSOLIDATEPD       =@nConsolidatePD,               
				CONSOLIDATEOR       =@nConsolidateOR,              
				DETAILSREQUIRED     =@nDetailsRequired,                
				CONSOLIDATEDISC     =@nConsolidateDISC,
				CONSOLIDATEMAR	    =@nConsolidateMAR,                
				EXPENSEGROUPTITLE   =@psExpenseGroupTitle,                  
				CONSOLIDATECHTYP    =@pnConsolidateChargeType,                  
				OFFICEID            =@pnOfficeKey,         
				DEBITNOTE           =@pnDebitNoteKey,          
				COVERINGLETTER      =@pnCoverLetterKey,               
				PROPERTYTYPE        =@psPropertyTypeKey,             
				RENEWALWIP          =@nIsRenewal,           
				SINGLECASE          =@nIsSingleCase,           
				SORTDATE            =@pnSortDate,          
				SORTCASE            =@pnSortCase,          
				SORTCASEMODE        =@pnSortCaseMode,              
				SORTCASETITLE       =@pnSortCaseTitle,               
				SORTCASEDEBTORREF   =@pnSortCaseDebtor,                   
				SORTWIPCATEGORY     =@pnSortWIPCategory,
				FORMATPROFILEID	    =@pnFormatProfileKey,
				SORTTAXCODE	    =@pnSortTaxCode
				WHERE
				BILLFORMATID	    =@pnBillFormatKey AND 
				FORMATNAME          =@psOldBillFormatName AND  
				LANGUAGE            =@pnOldLanguageKey AND          
				ENTITYNO            =@pnOldEntityKey AND           
				CASETYPE            =@psOldCaseTypeKey AND          
				ACTION              =@psOldActionKey AND         
				EMPLOYEENO          =@pnOldStaffKey AND            
				BILLFORMATDESC      =@psOldFormatDescription AND 		                 
				CONSOLIDATESC       =@nOldConsolidateSC AND                
				CONSOLIDATEPD       =@nOldConsolidatePD AND                
				CONSOLIDATEOR       =@nOldConsolidateOR AND                  
				CONSOLIDATEDISC     =@nOldConsolidateDISC AND
				ISNULL(CONSOLIDATEMAR,0)  =ISNULL(@nOldConsolidateMAR,0) AND                           
				EXPENSEGROUPTITLE   =@psOldExpenseGroupTitle AND                   
				CONSOLIDATECHTYP    =@pnOldConsolidateChargeType AND                   
				OFFICEID            =@pnOldOfficeKey AND          
				DEBITNOTE           =@pnOldDebitNoteKey AND           
				COVERINGLETTER      =@pnOldCoverLetterKey AND                
				PROPERTYTYPE        =@psOldPropertyTypeKey AND				                 
				BILLFORMATREPORT    =@psOldReportFileName AND
				FORMATPROFILEID	    =@pnOldFormatProfileKey"
			
			exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBillFormatKey		smallint,
				  @psBillFormatName 		nvarchar(100),
				  @pnLanguageKey		int,
				  @pnEntityKey			int,
				  @psCaseTypeKey		nvarchar(1),
				  @psActionKey			nvarchar(2),
				  @pnStaffKey			int,
				  @psFormatDescription		nvarchar(254),
				  @psReportFileName		nvarchar(254),
				  @nConsolidateSC		smallint,
				  @nConsolidatePD		smallint,
				  @nConsolidateOR		smallint,
				  @nDetailsRequired		smallint,
				  @nConsolidateDISC		smallint,
				  @nConsolidateMAR		smallint,
				  @psExpenseGroupTitle		nvarchar(30),
				  @pnConsolidateChargeType	smallint,
				  @pnOfficeKey			int,
				  @pnDebitNoteKey		smallint,
				  @pnCoverLetterKey		smallint,
				  @psPropertyTypeKey		nvarchar(2),
				  @nIsRenewal			smallint,
				  @nIsSingleCase		smallint,
				  @pnSortDate			smallint,
				  @pnSortCase			smallint,
				  @pnSortCaseMode		smallint,
				  @pnSortCaseTitle		smallint,
				  @pnSortCaseDebtor		smallint,
				  @pnSortWIPCategory		smallint,
				  @pnFormatProfileKey		int,
				  @pnSortTaxCode		smallint,
				  @psOldBillFormatName 		nvarchar(100),
				  @pnOldLanguageKey		int,
				  @pnOldEntityKey		int,
				  @psOldCaseTypeKey		nvarchar(1),
				  @psOldActionKey		nvarchar(2),
				  @pnOldStaffKey		int,
				  @psOldFormatDescription	nvarchar(254),
				  @psOldReportFileName		nvarchar(254),
				  @nOldConsolidateSC		smallint,
				  @nOldConsolidatePD		smallint,
				  @nOldConsolidateOR		smallint,
				  @nOldDetailsRequired		smallint,
				  @nOldConsolidateDISC		smallint,
				  @nOldConsolidateMAR		smallint,
				  @psOldExpenseGroupTitle	nvarchar(30),
				  @pnOldConsolidateChargeType	smallint,
				  @pnOldOfficeKey		int,
				  @pnOldDebitNoteKey		smallint,
				  @pnOldCoverLetterKey		smallint,
				  @psOldPropertyTypeKey		nvarchar(2),
				  @nOldIsRenewal		smallint,
				  @nOldIsSingleCase		smallint,
				  @pnOldSortWIPCategory		smallint,
				  @pnOldFormatProfileKey	int',
				  @pnBillFormatKey	= @pnBillFormatKey,
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
				  @pnConsolidateChargeType = @pnConsolidateChargeType,
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
				  @pnSortTaxCode	= @pnSortTaxCode,
				  @psOldBillFormatName 	= @psOldBillFormatName,
				  @pnOldLanguageKey	= @pnOldLanguageKey,
				  @pnOldEntityKey	= @pnOldEntityKey,
				  @psOldCaseTypeKey	= @psOldCaseTypeKey,
				  @psOldActionKey	= @psOldActionKey,
				  @pnOldStaffKey	= @pnOldStaffKey,
				  @psOldFormatDescription = @psOldFormatDescription,
				  @psOldReportFileName	= @psOldReportFileName,
				  @nOldConsolidateSC	= @nOldConsolidateSC,
				  @nOldConsolidatePD	= @nOldConsolidatePD,
				  @nOldConsolidateOR	= @nOldConsolidateOR,
				  @nOldDetailsRequired	= @nOldDetailsRequired,
				  @nOldConsolidateDISC	= @nOldConsolidateDISC,
				  @nOldConsolidateMAR	= @nOldConsolidateMAR,
				  @psOldExpenseGroupTitle	= @psOldExpenseGroupTitle,
				  @pnOldConsolidateChargeType = @pnOldConsolidateChargeType,
				  @pnOldOfficeKey		= @pnOldOfficeKey,
				  @pnOldDebitNoteKey	= @pnOldDebitNoteKey,
				  @pnOldCoverLetterKey	= @pnOldCoverLetterKey,
				  @psOldPropertyTypeKey	= @psOldPropertyTypeKey,
				  @nOldIsRenewal	= @nOldIsRenewal,
				  @nOldIsSingleCase	= @nOldIsSingleCase,
				  @pnOldSortWIPCategory	= @pnOldSortWIPCategory,
				  @pnOldFormatProfileKey = @pnOldFormatProfileKey

End


Return @nErrorCode
GO

Grant execute on dbo.biw_UpdateBillFormat to public
GO
