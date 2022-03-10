-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GetInvoiceDeliveryDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GetInvoiceDeliveryDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GetInvoiceDeliveryDetails.'
	Drop procedure [dbo].[biw_GetInvoiceDeliveryDetails]
End
Print '**** Creating Stored Procedure dbo.biw_GetInvoiceDeliveryDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_GetInvoiceDeliveryDetails
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psOpenItemNo		nvarchar(50),
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	biw_GetInvoiceDeliveryDetails
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the delivery details for a specific open item

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Jul 2010	LP	RFC7282	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @sDocItemQuery	nvarchar(max)
declare @sRecipients	nvarchar(max)
declare @sCCRecipients	nvarchar(max)
declare @sEmailSubject	nvarchar(max)
declare @sEmailBody	nvarchar(max)
declare @nLetterNo	int
declare @nCaseKey	int
declare @sCaseRef	nvarchar(60)
declare @bSendAsEmail	bit
declare @bIsWPDocument	bit
declare @bIsPDF		bit
declare @sBillReport	nvarchar(max)
declare	@nDebtorNo	int
declare @bIsRenewalDebtor bit

-- Initialise variables
Set @nErrorCode = 0

-- first get the Letter No and CaseKey
If @nErrorCode = 0
Begin
	Select 
	@nCaseKey = C.CASEID,
	@sCaseRef = C.IRN,
	@sBillReport = B.BILLFORMATREPORT,
	@nDebtorNo = O.ACCTDEBTORNO,
	@bSendAsEmail = CAST(1 as bit),
	@bIsWPDocument = CAST(0 as bit),
	@bIsPDF = CAST(1 as bit),
	@bIsRenewalDebtor = O.RENEWALDEBTORFLAG
	from OPENITEM O
	left join BILLFORMAT B on (B.BILLFORMATID = O.BILLFORMATID)
	join BILLLINE BL on (O.ITEMTRANSNO = BL.ITEMTRANSNO and O.ITEMENTITYNO = BL.ITEMENTITYNO)
	left join CASES C on (C.IRN = BL.IRN)
	where OPENITEMNO = @psOpenItemNo
	
	Set @nErrorCode = @@ERROR
End

-- For Bills with a Case
If @nCaseKey is not null
Begin
	-- Get the possible body and subject
	-- for the email from the doc items
	If @nErrorCode = 0
	Begin
		select @sSQLString = SQL_QUERY 
		from ITEM I
		join SITECONTROL SC on (SC.CONTROLID = 'Email Case Subject')
		where I.ITEM_NAME = SC.COLCHARACTER
		
		Set @sDocItemQuery = REPLACE(REPLACE(@sSQLString, ':gstrEntryPoint', '''' + @sCaseRef + ''''),' from ',' as [1] from ')
			
		Set @sSQLString = "
		Select @sEmailSubject = S.[1]
		from ("+
			@sDocItemQuery
		+") S"
		
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@sEmailSubject	nvarchar(max) output',
			@sEmailSubject		= @sEmailSubject output
	End

	If @nErrorCode = 0
	Begin
		select @sSQLString = SQL_QUERY 
		from ITEM I
		join SITECONTROL SC on (SC.CONTROLID = 'Email Case Body')
		where I.ITEM_NAME = SC.COLCHARACTER
		
		Set @sDocItemQuery = REPLACE(REPLACE(@sSQLString, ':gstrEntryPoint', '''' + @sCaseRef + ''''),' from ',' as [1] from ')
		
		Set @sSQLString = "
		Select @sEmailBody = S.[1]
		from ("+
			@sDocItemQuery
		+") S"
		
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@sEmailBody	nvarchar(max) output',
			@sEmailBody		= @sEmailBody output
			
	End	
End

If @nDebtorNo is not null
Begin
-- Debtor-only bills
	If @nErrorCode = 0
	Begin
		select 	@sRecipients = isnull(@sRecipients,'')+CASE WHEN(@sRecipients is NOT NULL) THEN ";" ELSE '' END+EMAIL.TELECOMNUMBER
		from (  select distinct T.TELECOMNUMBER
			from	NAMETELECOM NT 		
			join	TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE
							and T.TELECOMTYPE = 1903)
			where NT.NAMENO = @nDebtorNo) EMAIL
			
			Set @nErrorCode = @@ERROR
	End
	
	If @nErrorCode=0
	and @nCaseKey is not null
	Begin
		Set @sSQLString = "
		select 	@sCCRecipients = isnull(@sCCRecipients,'''')+CASE WHEN(@sCCRecipients is NOT NULL) THEN ';' ELSE '''' END+EMAIL.TELECOMNUMBER
		from (  select distinct T.TELECOMNUMBER
			from	ASSOCIATEDNAME AN 		
			join	NAMETELECOM NT 		on (AN.NAMENO = NT.NAMENO)
			join	TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE
							and T.TELECOMTYPE = 1903)
			-- if RenewalDebtor = ZC, else CD 
			where AN.RELATIONSHIP = " + 
			CASE WHEN @nDebtorNo = 1 THEN "'ZC'" ELSE "'CD'" END
			+ " and AN.NAMENO = @nDebtorNo) EMAIL"
		
		exec @nErrorCode = sp_executesql @sSQLString,
			N'@sCCRecipients	nvarchar(max),
			@nDebtorNo		int',
			@sCCRecipients		= @sCCRecipients,
			@nDebtorNo		= @nDebtorNo
			
	End
	Else 
	Begin
		select 	@sCCRecipients = isnull(@sCCRecipients,'')+CASE WHEN(@sCCRecipients is NOT NULL) THEN ";" ELSE '' END+EMAIL.TELECOMNUMBER
		from (  select distinct T.TELECOMNUMBER
			from	ASSOCIATEDNAME AN 		
			join	NAMETELECOM NT 		on (AN.NAMENO = NT.NAMENO)
			join	TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE
							and T.TELECOMTYPE = 1903)
			where AN.RELATIONSHIP = 'BI2'
			and AN.NAMENO = @nDebtorNo) EMAIL
		
		set @nErrorCode=@@Error
	End
End

-- Return all the information
If @nErrorCode = 0
Begin
	
	Set @sSQLString = "
	SELECT 
	O.BILLFORMATID as BillFormatKey, 
	O.ITEMENTITYNO as EntityKey,
	O.OPENITEMNO as OpenItemNo,
	@sRecipients as ToEmailAddress,
	@sCCRecipients as CopyEmailAddress,
	@sEmailSubject as EmailSubject,
	@sEmailBody as EmailBody,	
	@sBillReport as BillReport,
	@bSendAsEmail as IsDraftEmail,
	@bIsWPDocument as IsWPDocument,
	@bIsPDF as IsPDF,
	@nCaseKey as CaseKey
	from OPENITEM O
	left join BILLFORMAT B on (B.BILLFORMATID = O.BILLFORMATID)
	where OPENITEMNO = @psOpenItemNo"
	
	exec @nErrorCode = sp_executesql @sSQLString, 
		N'@sRecipients	nvarchar(max),
		@sCCRecipients	nvarchar(max),
		@sEmailSubject	nvarchar(max),
		@sEmailBody		nvarchar(max),
		@sBillReport	nvarchar(max),
		@bSendAsEmail	bit,
		@bIsWPDocument	bit,
		@bIsPDF			bit,
		@psOpenItemNo	nvarchar(50),
		@nCaseKey	int',
		@sRecipients	= @sRecipients,
		@sCCRecipients	= @sCCRecipients,
		@sEmailSubject	= @sEmailSubject,
		@sEmailBody		= @sEmailBody,
		@bSendAsEmail	= @bSendAsEmail,
		@bIsWPDocument	= @bIsWPDocument,
		@bIsPDF			= @bIsPDF,
		@psOpenItemNo	= @psOpenItemNo,
		@sBillReport	= @sBillReport,
		@nCaseKey	= @nCaseKey
	
	Set @nErrorCode = @@ERROR	
End

Return @nErrorCode
GO

Grant execute on dbo.biw_GetInvoiceDeliveryDetails to public
GO

