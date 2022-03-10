-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_DeleteDraftBill									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_DeleteDraftBill]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_DeleteDraftBill.'
	Drop procedure [dbo].[biw_DeleteDraftBill]
End
Print '**** Creating Stored Procedure dbo.biw_DeleteDraftBill...'
Print ''
GO

SET QUOTED_IDENTIFIER on
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS on
GO


CREATE PROCEDURE dbo.biw_DeleteDraftBill
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnItemEntityNo			int	= null,	
	@psItemNo			nvarchar(12) = null,
	@psMergeXMLKeys			nvarchar(max) = null
)
as
-- PROCEDURE:	biw_DeleteDraftBill
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Draft Bill.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	-----------------------------------------------
-- 23 Feb 2010	MS	RFC8301		1	Procedure created
-- 29 Apr 2011	AT	RFC7956		2	Delete bills to be merged.
-- 01 Jun 2011	AT	RFC10753	3	Fixed parameter reference error causing delete single bill to fail.

SET CONCAT_NULL_YIELDS_NULL on
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nItemTransNo		int

Declare	@sXMLJoin nvarchar(500)
Declare	@XMLKeys	XML

-- Initialise variables
Set @nErrorCode = 0

if (@psMergeXMLKeys is not null)
Begin		
	Set @XMLKeys = cast(@psMergeXMLKeys as XML)
	
	Set @sXMLJoin = char(10) + 'JOIN (
		select	K.value(N''ItemEntityNo[1]'',N''int'') as ItemEntityNo,
			K.value(N''ItemTransNo[1]'',N''int'') as ItemTransNo
		from @XMLKeys.nodes(N''/Keys/Key'') KEYS(K)) AS XM'
End

-- Get the TransNo for deleting the records
If @nErrorCode = 0 and @psItemNo is not null
Begin
	SET @sSQLString = 'SELECT @nItemTransNo = ITEMTRANSNO
		FROM OPENITEM
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND OPENITEMNO	= @psItemNo'

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@nItemTransNo		int			output,
			@pnItemEntityNo		int,
			@psItemNo		nvarchar(12)',
			@nItemTransNo		= @nItemTransNo		output,
			@pnItemEntityNo		= @pnItemEntityNo,
			@psItemNo		= @psItemNo	
End

If @nErrorCode = 0 and (@nItemTransNo is not null or @sXMLJoin is not null)
Begin
	-- Set Status = 1 for WORKINPROGRESS on bill
	Set @sSQLString	= 'UPDATE WIP 
			SET STATUS = 1
			FROM WORKINPROGRESS WIP
			JOIN BILLEDITEM BI ON 
				(BI.WIPENTITYNO = WIP.ENTITYNO 
				and BI.WIPTRANSNO = WIP.TRANSNO
				and BI.WIPSEQNO = WIP.WIPSEQNO)'
		
	if @sXMLJoin is not null
	Begin
		-- JOIN to the XML Keys
		Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
		char(10) + 'on (XM.ItemEntityNo = BI.ENTITYNO
				and XM.ItemTransNo = BI.TRANSNO)'
	End
	Else
	Begin
		Set @sSQLString = @sSQLString + char(10) + 'Where BI.ENTITYNO = @pnItemEntityNo
			and BI.TRANSNO = @nItemTransNo'
	End
	
	exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys

	-- Set Status = 1 for Credits applied to the bill
	If @nErrorCode = 0
	Begin
		Set @sSQLString	= 'UPDATE OPENITEM 
			SET STATUS = 1
			FROM BILLEDCREDIT BC'
			
			if @sXMLJoin is not null
			Begin
				-- JOIN to the XML Keys
				Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
				char(10) + 'on (XM.ItemEntityNo = BC.DRITEMENTITYNO
						and XM.ItemTransNo = BC.DRITEMTRANSNO)
						WHERE 1=1'
			End
			Else
			Begin
				Set @sSQLString = @sSQLString + char(10) + 'WHERE BC.DRITEMTRANSNO = @nItemTransNo
					AND	BC.DRITEMENTITYNO = @pnItemEntityNo'
			End
			
			Set @sSQLString = @sSQLString + char(10) + 'AND	BC.CRITEMENTITYNO = OPENITEM.ITEMENTITYNO
				AND 	BC.CRITEMTRANSNO = OPENITEM.ITEMTRANSNO
				AND 	BC.CRACCTENTITYNO = OPENITEM.ACCTENTITYNO
				AND 	BC.CRACCTDEBTORNO =  OPENITEM.ACCTDEBTORNO
				AND	BC.CRCASEID IS NULL'
	
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys


	End

	-- Set Status = 1 for Credits applied to the bill
	If @nErrorCode = 0
	Begin
		Set @sSQLString	= 'UPDATE OPENITEMCASE 
			SET STATUS = 1
			FROM BILLEDCREDIT BC'
		
			if @sXMLJoin is not null
			Begin
				-- JOIN to the XML Keys
				Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
				char(10) + 'on (XM.ItemEntityNo = BC.DRITEMENTITYNO
						and XM.ItemTransNo = BC.DRITEMTRANSNO)
						WHERE 1=1'
			End
			Else
			Begin
				Set @sSQLString = @sSQLString + char(10) + 'WHERE BC.DRITEMTRANSNO = @nItemTransNo
					AND	BC.DRITEMENTITYNO = @pnItemEntityNo'
			End
			
			Set @sSQLString = @sSQLString + char(10) + 'AND BC.CRITEMENTITYNO = OPENITEMCASE.ITEMENTITYNO
			AND 	BC.CRITEMTRANSNO = OPENITEMCASE.ITEMTRANSNO
			AND 	BC.CRACCTENTITYNO = OPENITEMCASE.ACCTENTITYNO
			AND 	BC.CRACCTDEBTORNO = OPENITEMCASE.ACCTDEBTORNO
			AND	BC.CRCASEID = OPENITEMCASE.CASEID'

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End

	-- Check if we are processing an Instalment Bill
	If @nErrorCode = 0 
	and exists (Select * from SITECONTROL where CONTROLID = 'Quotations' AND COLBOOLEAN = 1) -- Quotations set
	and not exists( 
		SELECT * FROM TRANSACTIONHEADER
		Where TRANSTYPE IN (516, 519)
		and ENTITYNO = @pnItemEntityNo
		and TRANSNO = @nItemTransNo) -- Not a credit note
	and exists (
		SELECT *
		FROM INSTALMENT I
		Where I.ENTITYNO = @pnItemEntityNo
		and I.TRANSNO = @nItemTransNo) -- An Instalment exists
	Begin
		SET @sSQLString = 'UPDATE I
			SET LOCALAMT = I.FOREIGNAMT / ISNULL(Q.EXCHANGERATE, 1) 
			from INSTALMENT I
			Join QUOTATION Q ON (Q.QUOTATIONNO = I.QUOTATIONNO)
			where I.ENTITYNO = @pnItemEntityNo
			and I.TRANSNO = @nItemTransNo'
		
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo
		
		-- Set Status to accepted for the Quotation
		If @nErrorCode = 0
		Begin
			SET @sSQLString = 'UPDATE Q
				SET STATUS = 7402 
				from QUOTATION Q
				JOIN INSTALMENT I
				on (I.QUOTATIONNO = I.QUOTATIONNO)
				where I.ENTITYNO = @pnItemEntityNo
				and I.TRANSNO = @nItemTransNo'

			exec @nErrorCode=sp_executesql @sSQLString,
				      N'@nItemTransNo		int,
					@pnItemEntityNo		int',
					@nItemTransNo		= @nItemTransNo,
					@pnItemEntityNo		= @pnItemEntityNo
		End
	End
	
	-- Delete from BILLEDITEM table
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'DELETE BI
		FROM BILLEDITEM BI'
		
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = BI.ENTITYNO
					and XM.ItemTransNo = BI.TRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE BI.ENTITYNO  = @pnItemEntityNo
					AND BI.TRANSNO	= @nItemTransNo'
		End
		
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End
	

	-- Delete from BILLLINE table
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'DELETE B
		FROM BILLLINE B'
	
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = B.ITEMENTITYNO
					and XM.ItemTransNo = B.ITEMTRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE B.ITEMENTITYNO  = @pnItemEntityNo
					AND B.ITEMTRANSNO= @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End
	
	if (@nErrorCode = 0)
	Begin
		-- Delete from WORKINPROGRESS table
		SET @sSQLString = 'DELETE W
		FROM WORKINPROGRESS W'
			
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = W.ENTITYNO
					and XM.ItemTransNo = W.TRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE W.ENTITYNO = @pnItemEntityNo
					AND W.TRANSNO = @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End

	-- Delete from WORKHISTORY table
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'DELETE W
		FROM WORKHISTORY W'
		
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = W.REFENTITYNO
					and XM.ItemTransNo = W.REFTRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE W.REFENTITYNO = @pnItemEntityNo
					AND W.REFTRANSNO = @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End
		
	-- Delete from DEBTORHISTORY table
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'DELETE D
		FROM DEBTORHISTORY D'
		
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = D.REFENTITYNO
					and XM.ItemTransNo = D.REFTRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE D.REFENTITYNO = @pnItemEntityNo
					AND D.REFTRANSNO = @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End

	-- Delete from OPENITEMTAX table
	If @nErrorCode = 0
	Begin
	
		SET @sSQLString = 'DELETE O
		FROM OPENITEMTAX O'
		
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = O.ITEMENTITYNO
					and XM.ItemTransNo = O.ITEMTRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE O.ITEMENTITYNO = @pnItemEntityNo
					AND O.ITEMTRANSNO = @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End

	-- Delete from OPENITEM table
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'DELETE O
		FROM OPENITEM O'
		
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = O.ITEMENTITYNO
					and XM.ItemTransNo = O.ITEMTRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE O.ITEMENTITYNO = @pnItemEntityNo
					AND O.ITEMTRANSNO = @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End

	-- Delete from TRANSACTIONHEADER table
	If @nErrorCode = 0
	Begin
		SET @sSQLString = 'DELETE T
		FROM TRANSACTIONHEADER T'
		
		if @sXMLJoin is not null
		Begin
			-- JOIN to the XML Keys
			Set @sSQLString = @sSQLString + char(10) + @sXMLJoin +
			char(10) + 'on (XM.ItemEntityNo = T.ENTITYNO
					and XM.ItemTransNo = T.TRANSNO)'
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + 'WHERE T.ENTITYNO = @pnItemEntityNo
					AND T.TRANSNO = @nItemTransNo'
		End

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@nItemTransNo		int,
				@pnItemEntityNo		int,
				@XMLKeys		xml',
				@nItemTransNo		= @nItemTransNo,
				@pnItemEntityNo		= @pnItemEntityNo,
				@XMLKeys		= @XMLKeys
	End

End

Return @nErrorCode
GO

Grant execute on dbo.biw_DeleteDraftBill to public
GO

