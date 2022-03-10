-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GetInvoicePrintDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GetInvoicePrintDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GetInvoicePrintDetails.'
	Drop procedure [dbo].[biw_GetInvoicePrintDetails]
End
Print '**** Creating Stored Procedure dbo.biw_GetInvoicePrintDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_GetInvoicePrintDetails
(
	@pnUserIdentityId		int,		
	@psCulture				nvarchar(10) 	= null,
	@pnEntityNo				int		= null,
	@psOpenItemNo			nvarchar(50),
	@pbCalledFromCentura	bit		= 0,
	@pbPrintAsOriginal		bit		= 0
)
as
-- PROCEDURE:	biw_GetInvoicePrintDetails
-- VERSION:		12
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return details on how an invoice will be printed, including how many copies,
--				and what bill format each copy should use.

-- MODIFICATIONS:
-- Date			Who		Change		Version	Description
-- -----------	-------	-----------	-------	----------------------------------------------- 
-- 31 Aug 2010	LP		RFC9729		1		Procedure created.
-- 14 Oct 2010	AT		RFC8982		2		Return saved copy to.
-- 11 Nov 2010	LP		RFC9729		3		Do not generate copies for DRAFT bills.
--											Fix logic for generating Debtor Copies To Copies.
--											Fix logic for determining SingleCase or MultiCase bill.
-- 01 Dec 2010	LP		RFC9730		4		Fix logic get BILLFORMATID against the OPENITEM record when selecting the format.
-- 12 Jul 2011	Dw		RFC10942 	5		Fixed problem where only one 'Copy To' Name returned.
-- 13 Jul 2011	JC		RFC9599 	6		Add new column to resultset to know the type of the report.
-- 21 Jul 2011	JC		RFC9599 	7		Add REPRINT and ENTITYCODE to resultset and fix various issues with 'DN Copy Text %' site controls
-- 25 Aug 2011	JC		RFC9599 	8		Replace the Debtor Code by the Entiry Code
-- 24 Jan 2012	LP		R11726		9		Use EntityNo to determine correct bill printing settings.
-- 08 Jan 2012	AT		RFC13059	10		Pass in @pbPrintAsOriginal instead of using printed flag.
-- 11 Feb 2013	DV		RFC13175	11		Add logic to get the OFFICEID
-- 08 May 2013	LP		RFC13459	12		Use the Best Fit bill format when the Debtor's "Copy Bills To" names do not use a specific format.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

create table #BillPrintDetails (
	COPYNO		int		identity(0,1) primary key,
	BILLPRINTTYPE	nvarchar(50)	collate database_default,
	OPENITEMNO	nvarchar(50)	collate database_default,
	ENTITYCODE	nvarchar(50)	collate database_default	NULL,
	BILLTEMPLATE	nvarchar(254)	collate database_default	NULL,
	REPRINTLABEL	nvarchar(254)	collate database_default	NULL,
	COPYLABEL	nvarchar(254)	collate database_default	NULL,
	COPYTONAME	nvarchar(max)	collate database_default	NULL,
	COPYTOATTENTION	nvarchar(max)	collate database_default	NULL,
	COPYTOADDRESS	nvarchar(max)	collate database_default	NULL
)

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @nBillFormatId		int
Declare @nLanguage		int
Declare @nEntityNo		int
Declare @nDebtorNo		int
Declare @sEntityCode		nvarchar(50)
Declare @sCaseType		nvarchar(1)
Declare @sAction		nvarchar(2)
Declare @sPropertyType		nvarchar(1)
Declare @nSingleCase		int
Declare @nEmployeeNo		int
Declare @nMainCaseId		int
Declare @nOfficeId		int
Declare @nBillLetterNo		int
Declare @nCoveringLetterNo	int
Declare @nItemEntityNo		int
Declare @nItemTransNo		int
Declare @nFirmCopies		int
Declare @sBillFormatTemplate	nvarchar(100)
Declare @sDefaultBillTemplate	nvarchar(100)
Declare @nDebtorCopies		int
Declare @nCopyCount		smallint
Declare @bUseRenewalDebtor	bit

Declare @sCopyToTableName	nvarchar(30)
Declare @bIsFinalisedBill	bit

-- Initialise variables
Set @nErrorCode = 0
Set @sDefaultBillTemplate = 'Billing.rdl'

-- Get the Copies To Names
Set @sCopyToTableName = "##CopyTo" + Cast(@@SPID as nvarchar(30))

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sCopyToTableName )
Begin 
	Set @sSQLString = 'DROP TABLE ' + @sCopyToTableName

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"create table " + @sCopyToTableName + "
	(DEBTORNO int, 
	RELATEDNAMENO int,
	COPYTONAME nvarchar(254) COLLATE database_default null,
	CONTACTNAMEKEY int null,
	CONTACTNAME nvarchar(254) COLLATE database_default null,
	ADDRESSKEY int null,
	ADDRESS nvarchar(254) COLLATE database_default null,
	ADDRESSCHANGEREASON int null)"
	
	Exec @nErrorCode=sp_executesql @sSQLString
End

-- Populate the necessary properties from the open item
If @nErrorCode = 0
Begin
	-- RFC10942
	Set @sSQLString = "
	Select  @nLanguage = O.LANGUAGE,
		@nEntityNo = O.ITEMENTITYNO,
		@nDebtorNo = O.ACCTDEBTORNO,
		@sEntityCode = N.NAMECODE,
		@nEmployeeNo = O.EMPLOYEENO,
		@nItemEntityNo	= O.ITEMENTITYNO,
		@nItemTransNo = O.ITEMTRANSNO,
		@nMainCaseId = ISNULL(O.MAINCASEID, WH.CASEID),
		@bUseRenewalDebtor = O.RENEWALDEBTORFLAG,
		@bIsFinalisedBill = CASE WHEN O.STATUS = 1 THEN convert(bit,1) ELSE convert(bit,0) END,
		@nBillFormatId = O.BILLFORMATID,
		@nOfficeId = TA.TABLECODE
	from OPENITEM O
	join NAME N on (N.NAMENO = O.ITEMENTITYNO)
	left join WORKHISTORY WH on (WH.REFTRANSNO = O.ITEMTRANSNO AND WH.REFENTITYNO = O.ITEMENTITYNO)
	left join TABLEATTRIBUTES TA on (TA.GENERICKEY = O.EMPLOYEENO AND TA.TABLETYPE = 44 AND TA.PARENTTABLE = 'NAME') 
	where O.OPENITEMNO = @psOpenItemNo
	and O.ITEMENTITYNO = @pnEntityNo"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@nLanguage	int output,
		@nEntityNo	int output,
		@nDebtorNo	int output,
		@sEntityCode		nvarchar(50) output,
		@nEmployeeNo	int output,
		@nItemEntityNo	int output,
		@nItemTransNo	int output,
		@nMainCaseId	int output,
		@bUseRenewalDebtor bit output,
		@psOpenItemNo	nvarchar(50),
		@bIsFinalisedBill	bit output,
		@nBillFormatId  int output,
		@nOfficeId		int output,
		@pnEntityNo		int',
		@nLanguage	= @nLanguage output,
		@nEntityNo	= @nEntityNo output,
		@nDebtorNo	= @nDebtorNo output,
		@sEntityCode		= @sEntityCode output,
		@nEmployeeNo	= @nEmployeeNo output,
		@nItemEntityNo	= @nItemEntityNo output,
		@nItemTransNo	= @nItemTransNo output,
		@nMainCaseId	= @nMainCaseId output,
		@bUseRenewalDebtor = @bUseRenewalDebtor output,
		@psOpenItemNo	= @psOpenItemNo,
		@bIsFinalisedBill	= @bIsFinalisedBill output,
		@nBillFormatId	= @nBillFormatId output,
		@nOfficeId	= @nOfficeId output,
		@pnEntityNo	= @pnEntityNo
End

-- Get the properties of the main case on the bill
If @nErrorCode = 0 
and @nMainCaseId is not null
Begin
	Set @sSQLString = "SELECT @sCaseType = C.CASETYPE,
				  @sPropertyType = C.PROPERTYTYPE
			FROM CASES C
			WHERE C.CASEID = @nMainCaseId"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@sCaseType		nvarchar(1) OUTPUT,
				  @sPropertyType	nvarchar(1) OUTPUT,
				  @nMainCaseId		int',
				  @sCaseType = @sCaseType OUTPUT,
				  @sPropertyType = @sPropertyType OUTPUT,
				  @nMainCaseId = @nMainCaseId
				  
	-- Check if the bill is Multi-case, single-case or debtor only
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Select @nSingleCase = CASE WHEN WHCASECOUNT.CASECOUNT > 1 THEN 0 -- Multi-Case
							WHEN WHCASECOUNT.CASECOUNT = 1 THEN 1 -- Single Case
							WHEN WHCASECOUNT.CASECOUNT = 0 THEN 2 -- Debtor Only
							END	-- Single Case
				From (Select count(*) as CASECOUNT from 
							(Select CASEID 
							From WORKHISTORY 
							Where REFENTITYNO = @pnItemEntityNo 
							and REFTRANSNO = @pnItemTransNo 
							Group by CASEID) AS WHC) AS WHCASECOUNT"

		exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nSingleCase		int OUTPUT,
				  @pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @nSingleCase = @nSingleCase OUTPUT,
				  @pnItemEntityNo = @nItemEntityNo,
				  @pnItemTransNo = @nItemTransNo
	End
End
-- Get the best-fit bill format
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.biw_FetchBestBillFormat
		@pnUserIdentityId = @pnUserIdentityId,		-- Mandatory
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnBillFormatId = @nBillFormatId OUTPUT,
		@pnLanguage	= @nLanguage, -- Set the remainder if best fit is to be used.
		@pnEntityNo = @nEntityNo,
		@pnNameNo = @nDebtorNo,
		@psCaseType = @sCaseType,
		@psAction = @sAction,
		@psPropertyType	= @sPropertyType,
		@pnRenewalWIP =	null, -- always null in this case
		@pnSingleCase = @nSingleCase,
		@pnEmployeeNo = @nEmployeeNo,
		@pnOfficeId	= @nOfficeId,
		@pbReturnBillFormatDetails = 0
End

-- Return bill template for original invoice
If @nErrorCode = 0
Begin
	Select @sBillFormatTemplate = B.BILLFORMATREPORT
	from BILLFORMAT B
	where B.BILLFORMATID = @nBillFormatId
	
	Set @nErrorCode = @@ERROR
	
	If @sBillFormatTemplate is null
	Begin
		Set @sBillFormatTemplate = @sDefaultBillTemplate
	End
End

-- Row for original invoice
If @nErrorCode = 0
and @sBillFormatTemplate is not null
Begin
	-- set to default billing template if nothing fits
	Insert into #BillPrintDetails(BILLPRINTTYPE, OPENITEMNO, ENTITYCODE, BILLTEMPLATE, COPYLABEL, REPRINTLABEL)
	Select CASE WHEN @bIsFinalisedBill = 1 THEN 'FinalisedInvoice' ELSE 'DraftInvoice' END,
	@psOpenItemNo, @sEntityCode, @sBillFormatTemplate,
	SCC.COLCHARACTER,
	CASE WHEN @pbPrintAsOriginal = 1 THEN null ELSE SCR.COLCHARACTER END
	from OPENITEM O
	left join SITECONTROL SCC on (SCC.CONTROLID = 'DN Copy Text 0')
	left join SITECONTROL SCR on (SCR.CONTROLID = 'DN Orig Copy Text')
	where O.OPENITEMNO = @psOpenItemNo
	and O.ITEMENTITYNO=@pnEntityNo
	
	Set @nErrorCode = @@ERROR
End

-- Get the Firm Copy information
If @nErrorCode = 0
and @bIsFinalisedBill = 1
Begin
	Select @nFirmCopies = COLINTEGER
	from SITECONTROL
	where CONTROLID = 'DN Firm Copies'
	
	If @nFirmCopies > 0
	Begin
		Set @nCopyCount = 1
		
		While @nCopyCount <= @nFirmCopies
		Begin
			insert into #BillPrintDetails(BILLPRINTTYPE, OPENITEMNO, ENTITYCODE, BILLTEMPLATE, COPYLABEL)
			Select 'FirmInvoiceCopy', @psOpenItemNo, @sEntityCode, @sBillFormatTemplate, SC.COLCHARACTER
			from OPENITEM O
			left join SITECONTROL SC on (SC.CONTROLID = 'DN Copy Text ' + cast(@nCopyCount as nvarchar))
			where O.OPENITEMNO = @psOpenItemNo
			
			Set @nCopyCount = @nCopyCount + 1
		End
		Set @nErrorCode = @@ERROR
		
	End
End

-- Get the Debtor Copy information
If @nErrorCode = 0
and @bIsFinalisedBill = 1
Begin
	Select @nDebtorCopies = I.DEBITCOPIES
	from IPNAME I
	join OPENITEM O on (O.ACCTDEBTORNO = I.NAMENO)
	where O.OPENITEMNO = @psOpenItemNo
	and O.ITEMENTITYNO = @pnEntityNo
		
	Set @nCopyCount = 1
		
	While @nCopyCount <= @nDebtorCopies
	Begin
		insert into #BillPrintDetails(BILLPRINTTYPE, OPENITEMNO, ENTITYCODE, BILLTEMPLATE, COPYLABEL)
		Select 'CustomerRequestedInvoiceCopies', @psOpenItemNo, @sEntityCode, @sBillFormatTemplate, SC.COLCHARACTER
		from SITECONTROL SC
		where CONTROLID = 'DN Cust Copy Text'
		
		Set @nCopyCount = @nCopyCount + 1
	End
	
	Set @nErrorCode = @@ERROR	

End

If @nErrorCode = 0
and @bIsFinalisedBill = 1
Begin

	exec dbo.biw_GetCopyToNames
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnEntityKey		= @nItemEntityNo,
		@pnTransKey		= @nItemTransNo,
		@pnDebtorKey		= @nDebtorNo,
		@pnCaseKey		= @nMainCaseId,
		@pbUseRenewalDebtor	= @bUseRenewalDebtor,
		@psResultTable		= @sCopyToTableName -- the copy to name table to hold the result set
End


If @nErrorCode = 0
and @bIsFinalisedBill = 1
Begin
	-- insert the copy to names.
	Set @sSQLString = "
	insert into #BillPrintDetails(BILLPRINTTYPE, OPENITEMNO, ENTITYCODE, BILLTEMPLATE, COPYLABEL, COPYTONAME, COPYTOATTENTION, COPYTOADDRESS)
	Select distinct 'CopyToInvoice', @psOpenItemNo, @sEntityCode,
		ISNULL(B.BILLFORMATREPORT,@sBillFormatTemplate),
		NULL,
		CT.COPYTONAME,
		CT.CONTACTNAME,
		CT.ADDRESS
	from " + @sCopyToTableName + " CT

	join NAME N ON (N.NAMENO = CT.RELATEDNAMENO)
	left join IPNAME IPN ON (IPN.NAMENO = N.NAMENO)
	left join ASSOCIATEDNAME AN on (AN.NAMENO = CT.DEBTORNO
					AND AN.RELATEDNAME = CT.RELATEDNAMENO)
	left join BILLFORMAT B on (B.FORMATPROFILEID = ISNULL(AN.FORMATPROFILEID,IPN.BILLFORMATID))"
		
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psOpenItemNo nvarchar(13),
					@sEntityCode nvarchar(50),
					@sBillFormatTemplate nvarchar(100)',
					@psOpenItemNo = @psOpenItemNo,
					@sEntityCode = @sEntityCode,
					@sBillFormatTemplate = @sBillFormatTemplate
End

-- Return the result
select	COPYNO		as 'CopyNo',
	BILLPRINTTYPE	as 'BillPrintType',
	OPENITEMNO	as 'OpenItemNo',
	ENTITYCODE	as 'EntityCode',
	BILLTEMPLATE	as 'BillTemplate',
	REPRINTLABEL	as 'ReprintLabel',
	COPYLABEL	as 'CopyLabel',
	COPYTONAME	as 'CopyToName',
	COPYTOATTENTION	as 'CopyToAttention',
	COPYTOADDRESS	as 'CopyToAddress'
from #BillPrintDetails

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = @sCopyToTableName )
Begin 
	Set @sSQLString = 'DROP TABLE ' + @sCopyToTableName

	Exec @nErrorCode=sp_executesql @sSQLString
End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = '#BillPrintDetails' )
Begin 
	Set @sSQLString = 'DROP TABLE #BillPrintDetails'

	Exec @nErrorCode=sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.biw_GetInvoicePrintDetails to public
GO
