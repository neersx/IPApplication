-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Ta_ListReceiptDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[Ta_ListReceiptDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.Ta_ListReceiptDetails.'
	drop procedure dbo.Ta_ListReceiptDetails
end
print '**** Creating procedure dbo.Ta_ListReceiptDetails...'
print ''
go 

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.Ta_ListReceiptDetails
(
	@pnRowCount					int	output,
	@pnUserIdentityId			int				= null,	-- Included for use by .NET
	@psCulture					nvarchar(10)	= null, -- The language in which output is to be expressed
	@pbCalledFromCentura		bit		= 0,
	@pnEntityNo					int,					-- The NameNo of Entity from which the receipt was issued
	@pnTransNo					int						-- The TransNo of the trust receipt
)
AS
-- PROCEDURE :	Ta_ListReceiptDetails
-- VERSION :	3
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	TA
-- DESCRIPTION:	Get the trust receipt details for a transaction.
-- CALLED BY :	Centura

-- MODIFICTIONS :
-- Date         Who  	SQA#	Version  Change
-- ------------ ----	---- 	-------- ------------------------------------------- 
-- 28/03/2011	DL	15632	1	Created.
-- 23/09/2011	DL	19384	2	Allow printing of trust receipts that have been transferred from other receipt
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int,
	@sEntityName			nvarchar(254),
	@sEntityAddr			nvarchar(254),
	@sDeborName				nvarchar(254),
	@sDeborAddr				nvarchar(254),
	@sPaymentCurrency		nvarchar(3),
	@dtPaymentDate			DateTime,
	@sPaymentRef			nvarchar(30),
	@sPaymentMethod			nvarchar(30),
	@nPaymentAmount			Decimal(11,2),
	@sPaymentAmountInWords	nVarchar(254),
	@sPaymentDescription	nvarchar(254),
	@sProcAmountToWords		nVarChar (128),
	@sSQLString				nVarChar(4000),
	@sSQLString2			nvarchar(4000)
  


If (@pnEntityNo is not null) and (@pnTransNo is not null)
Begin
	Set @nErrorCode = 0
End
Else
Begin
	Set @nErrorCode = -1
End


If (@nErrorCode = 0)
Begin
		Select 
		@sEntityName = dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null),
		@sEntityAddr = dbo.fn_GetFormattedAddress(N1.POSTALADDRESS, NULL, NULL, NULL, NULL),
		@sDeborName = dbo.fn_FormatNameUsingNameNo(N2.NAMENO, null),
		@sDeborAddr = dbo.fn_GetFormattedAddress(N2.POSTALADDRESS, NULL, NULL, NULL, NULL),
		@sPaymentCurrency = TI.CURRENCY,
		@dtPaymentDate = TI.ITEMDATE ,
		@sPaymentRef = CI.ITEMREFNO,
		@sPaymentMethod = PM.PAYMENTDESCRIPTION,
		@nPaymentAmount = Case when TI.CURRENCY IS NOT NULL then TI.FOREIGNVALUE else TI.LOCALVALUE end,
		@sPaymentDescription = CI.DESCRIPTION
		
		from TRUSTITEM TI
		join NAME N1 ON N1.NAMENO = TI.ITEMENTITYNO
		join NAME N2 ON N2.NAMENO = TI.TACCTNAMENO
		-- Cater for transfer receipt which don't link directly to CASHITEM.
		--left join CASHITEM CI ON CI.TRANSENTITYNO = TI.ITEMENTITYNO
		--					and CI.TRANSNO = TI.ITEMTRANSNO
		JOIN (SELECT DISTINCT TI2.ITEMNO AS ITEMNO, CI2.ITEMTYPE , CI2.DESCRIPTION, CI2.ITEMREFNO 
			FROM TRUSTITEM TI2 
			JOIN TRUSTITEM TI3 ON TI3.ITEMNO = TI2.ITEMNO
			JOIN CASHITEM  CI2  ON  (CI2.TRANSENTITYNO = TI2.ITEMENTITYNO 
						AND CI2.TRANSNO = TI2.ITEMTRANSNO )   
			WHERE  TI3.ITEMENTITYNO = @pnEntityNo AND TI3.ITEMTRANSNO = @pnTransNo ) CI ON CI.ITEMNO = TI.ITEMNO		
		----
							
		join PAYMENTMETHODS PM on (PM.PAYMENTMETHOD = CI.ITEMTYPE)								
		where TI.ITEMENTITYNO = @pnEntityNo
		and TI.ITEMTRANSNO = @pnTransNo
	
		Select @nErrorCode = @@Error, @pnRowCount = @@RowCount
End

-- Get the payment amount in words
If @nErrorCode = 0
Begin
	Select @sProcAmountToWords = B.PROCAMOUNTTOWORDS 
	from BANKACCOUNT B 
	-- Cater for transfer receipt which don't link directly to CASHITEM.
	JOIN (SELECT DISTINCT CI2.ENTITYNO, CI2.BANKNAMENO, CI2.SEQUENCENO 
		FROM TRUSTITEM TI1 
		JOIN TRUSTITEM TI2 ON TI2.ITEMNO = TI1.ITEMNO
		JOIN CASHITEM  CI2  ON  (CI2.TRANSENTITYNO = TI2.ITEMENTITYNO 
					AND CI2.TRANSNO = TI2.ITEMTRANSNO )   
		WHERE  TI1.ITEMENTITYNO = @pnEntityNo AND TI1.ITEMTRANSNO = @pnTransNo ) P 
			ON (P.ENTITYNO = B.ACCOUNTOWNER 
			    AND  P.BANKNAMENO = B.BANKNAMENO 
			    AND  P.SEQUENCENO = B.SEQUENCENO )

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0 and @sProcAmountToWords is not null
Begin
		Set @sSQLString = 'exec ' +   @sProcAmountToWords + ' @pnUserIdentityId, @psCulture, 0, @nPaymentAmount, @sPaymentAmountInWords output'

		Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnUserIdentityId		int,
			@psCulture			nvarchar(10),
			@nPaymentAmount		decimal(11,2),
			@sPaymentAmountInWords	nvarchar(254) output',
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture 			= @psCulture,
			@nPaymentAmount		= @nPaymentAmount,
			@sPaymentAmountInWords	= @sPaymentAmountInWords output
End

Select @sEntityName, @sEntityAddr, @sDeborName, @sDeborAddr, @sPaymentCurrency, @dtPaymentDate,
@sPaymentRef, @sPaymentMethod, @nPaymentAmount, @sPaymentAmountInWords, @sPaymentDescription

RETURN @nErrorCode	
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.Ta_ListReceiptDetails to public
go

