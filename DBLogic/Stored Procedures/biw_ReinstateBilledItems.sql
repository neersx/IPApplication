-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ReinstateBilledItems									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ReinstateBilledItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ReinstateBilledItems.'
	Drop procedure [dbo].[biw_ReinstateBilledItems]
End
Print '**** Creating Stored Procedure dbo.biw_ReinstateBilledItems...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.biw_ReinstateBilledItems
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnEntityNo		int,	-- Mandatory
	@pnTransNo		int	-- Mandatory
)
as
-- PROCEDURE:	biw_ReinstateBilledItems
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete BilledItems for an OpenItem (in preparation to re-insert data).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 09-Mar-2010	AT	RFC3605	1	Procedure created.
-- 23-Jun-2010	AT	RFC8291	2	Remove DebtorHistory for credits notes.
-- 03-Aug-2010	AT	RFC9556	3	Delete OPENITEMXML.
-- 23-Aug-2010	AT	RFC9589 4	Unused draft WIP to be deleted by biw_DeleteUnusedDraftWIP.
-- 13-Oct-2010	AT	RFC8982	5	Delete OPENITEMCOPYTO and OPENITEM

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Before deleting, re-instate WorkInProgress status
If @nErrorCode = 0
Begin
	Set @sSQLString ="Update WIP
		Set STATUS = 1
		from WORKINPROGRESS WIP
		join BILLEDITEM BI on (BI.WIPENTITYNO = WIP.ENTITYNO
								and BI.WIPTRANSNO = WIP.TRANSNO
								and BI.WIPSEQNO = WIP.WIPSEQNO)
		Where BI.ENTITYNO = @pnEntityNo
		and BI.TRANSNO = @pnTransNo
		and WIP.STATUS = 2"

		exec @nErrorCode=sp_executesql @sSQLString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

-- Re-instate Credits.
If @nErrorCode = 0
Begin
	Set @sSQLString ="
	update OI
	Set STATUS = 1,
	LOCALORIGTAKENUP = NULL,
	FOREIGNORIGTAKENUP = NULL
	FROM OPENITEM OI
	JOIN BILLEDCREDIT BC ON (BC.CRITEMENTITYNO = OI.ITEMENTITYNO
				AND BC.CRITEMTRANSNO = OI.ITEMTRANSNO
				AND BC.CRACCTENTITYNO = OI.ACCTENTITYNO
				AND BC.CRACCTDEBTORNO = OI.ACCTDEBTORNO)
	WHERE BC.DRITEMENTITYNO = @pnEntityNo
	AND BC.DRITEMTRANSNO = @pnTransNo"

--BC.CRCASEID IS NULL

	exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnEntityNo		int,
			@pnTransNo		int',
			@pnEntityNo	 = @pnEntityNo,
			@pnTransNo	 = @pnTransNo
End

If @nErrorCode = 0
Begin
	Set @sSQLString ="update OIC
	Set STATUS = 1
	FROM OPENITEMCASE OIC
	JOIN BILLEDCREDIT BC ON (BC.CRITEMENTITYNO = OIC.ITEMENTITYNO
				AND BC.CRITEMTRANSNO = OIC.ITEMTRANSNO
				AND BC.CRACCTENTITYNO = OIC.ACCTENTITYNO
				AND BC.CRACCTDEBTORNO = OIC.ACCTDEBTORNO
				AND BC.CRCASEID = OIC.CASEID)
	WHERE BC.DRITEMENTITYNO = @pnEntityNo
	AND BC.DRITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sSQLString,
		      	N'@pnEntityNo		int,
			@pnTransNo		int',
			@pnEntityNo	 = @pnEntityNo,
			@pnTransNo	 = @pnTransNo
End

-- Delete BILLED CREDITS
If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from BILLEDCREDIT
			   where DRITEMENTITYNO = @pnEntityNo 
					and DRITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from BILLEDITEM
			   where ENTITYNO = @pnEntityNo 
					and TRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from BILLLINE
			   where ITEMENTITYNO = @pnEntityNo 
					and ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from OPENITEMTAX
		   where ITEMENTITYNO = @pnEntityNo 
			and ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from DEBTORHISTORY
		   where ITEMENTITYNO = @pnEntityNo
			and ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

-- DELETE OPENITEMXML
If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from OPENITEMXML
		   where ITEMENTITYNO = @pnEntityNo
			and ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

-- DELETE OPENITEMCOPYTO
If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from OPENITEMCOPYTO
		   where ITEMENTITYNO = @pnEntityNo
			and ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

-- DELETE OPENITEMS
If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from OPENITEM
		   where ITEMENTITYNO = @pnEntityNo
			and ITEMTRANSNO = @pnTransNo"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'@pnEntityNo		int,
				@pnTransNo		int',
				@pnEntityNo	 = @pnEntityNo,
				@pnTransNo	 = @pnTransNo
End

Return @nErrorCode
GO

Grant execute on dbo.biw_ReinstateBilledItems to public
GO