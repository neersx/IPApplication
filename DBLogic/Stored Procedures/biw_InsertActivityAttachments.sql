-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertActivityAttachments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertActivityAttachments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertActivityAttachments.'
	Drop procedure [dbo].[biw_InsertActivityAttachments]
End
Print '**** Creating Stored Procedure dbo.biw_InsertActivityAttachments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_InsertActivityAttachments
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnItemEntityNo		int,		-- Mandatory
	@psOpenItemNo		nvarchar(50),	-- Mandatory
	@psActivitySummary	nvarchar(254),	-- Mandatory
	@psNameForDebit		nvarchar(254),	-- Mandatory
	@psNameForCredit	nvarchar(254),	-- Mandatory
	@psFileName		nvarchar(254)	-- Mandatory
)
as
-- PROCEDURE:	biw_InsertActivityAttachments
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Activity Attachment for billing when 'Bill Save As PDF' site control is set to 2.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Jul 2011	JC	RFC9599	1	Procedure created
-- 08 Sep 2011	JC	R10201	2	Use ipw_InsertSingleActivityAttachment

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

create table #BillActivityAttachment (
	ROWNO		int		identity(0,1) primary key,
	CASEKEY		int
)

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nDebtorKey		int
Declare @nCaseKey		int
Declare @dItemDate		datetime
Declare @nActivityKey		int
Declare @nSequenceKey		int
Declare @sAttachmentName	nvarchar(254)
Declare @nRowCount		int
Declare @nRowNo			int

-- Initialise variables
Set @nErrorCode = 0
Set @nActivityKey = null
Set @nSequenceKey = null
Set @nRowCount	= 0
Set @nRowNo	= 0

if @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT @nDebtorKey		= O.ACCTDEBTORNO,
				  @dItemDate		= O.ITEMDATE,
				  @sAttachmentName	= CASE WHEN O.ITEMTYPE = 510 THEN @psNameForDebit ELSE @psNameForCredit END 
			FROM OPENITEM O
			WHERE O.ITEMENTITYNO = @pnItemEntityNo
			AND O.OPENITEMNO = @psOpenItemNo"

	exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
			@nDebtorKey		int output,
			@dItemDate		datetime output,
			@sAttachmentName	nvarchar(254) output,
			@pnItemEntityNo		int,
			@psOpenItemNo		nvarchar(50),
			@psNameForDebit 	nvarchar(254),
			@psNameForCredit	nvarchar(254)',
			@nDebtorKey		= @nDebtorKey output,
			@dItemDate		= @dItemDate output,
			@sAttachmentName	= @sAttachmentName output, 
			@pnItemEntityNo		= @pnItemEntityNo,
			@psOpenItemNo		= @psOpenItemNo,
			@psNameForDebit		= @psNameForDebit,
			@psNameForCredit	= @psNameForCredit
End

-- Add Attachmnent against the Debtor
	
if @nErrorCode = 0 and @nDebtorKey is not null
Begin
	exec @nErrorCode=ipw_InsertSingleActivityAttachment 
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnCaseKey		= null,
		@pnNameKey		= @nDebtorKey,
		@pnActivityTypeKey	= 5807,
		@pnActivityCategoryKey	= 5905,
		@pdActivityDate		= @dItemDate,
		@psActivitySummary	= @psActivitySummary,
		@psAttachmentName	= @sAttachmentName,
		@psFileName		= @psFileName,
		@pbIsPublic		= 1
End

-- Add Attachmnent against the Cases

If @nErrorCode=0
Begin
	Set @sSQLString = "INSERT INTO #BillActivityAttachment (CASEKEY)
			SELECT  distinct W.CASEID                 
			FROM OPENITEM O
			JOIN WORKHISTORY W on (W.REFENTITYNO = O.ITEMENTITYNO and W.REFTRANSNO = O.ITEMTRANSNO and W.CASEID is not null)
			WHERE O.ITEMENTITYNO = @pnItemEntityNo
			AND O.OPENITEMNO = @psOpenItemNo"

	exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
			@pnItemEntityNo	int,
			@psOpenItemNo	nvarchar(50)',
			@pnItemEntityNo	= @pnItemEntityNo,
			@psOpenItemNo	= @psOpenItemNo
			
	Set @nRowCount=@@Rowcount

End

If @nErrorCode=0 and @nRowCount > 0
Begin
	While @nErrorCode=0 and @nRowNo < @nRowCount
	Begin
		Set @sSQLString = "SELECT @nCaseKey	= CASEKEY
				FROM #BillActivityAttachment
				WHERE ROWNO = @nRowNo"

		exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
				@nCaseKey	int output,
				@nRowNo		int',
				@nCaseKey	= @nCaseKey output,
				@nRowNo		= @nRowNo
		
		If @nErrorCode=0
		Begin

			exec @nErrorCode=ipw_InsertSingleActivityAttachment 
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnCaseKey		= @nCaseKey,
				@pnNameKey		= null,
				@pnActivityTypeKey	= 5807,
				@pnActivityCategoryKey	= 5905,
				@pdActivityDate		= @dItemDate,
				@psActivitySummary	= @psActivitySummary,
				@psAttachmentName	= @sAttachmentName,
				@psFileName		= @psFileName,
				@pbIsPublic		= 1
		End
					
		Set @nRowNo = @nRowNo + 1
	End

End

If @nErrorCode=0 and exists(select * from tempdb.dbo.sysobjects where name = '#BillActivityAttachment' )
Begin 
	Set @sSQLString = 'DROP TABLE #BillActivityAttachment'

	Exec @nErrorCode=sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertActivityAttachments to public
GO