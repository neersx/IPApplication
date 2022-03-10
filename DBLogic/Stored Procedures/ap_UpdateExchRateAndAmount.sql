-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_UpdateExchRateAndAmount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_UpdateExchRateAndAmount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_UpdateExchRateAndAmount.'
	Drop procedure [dbo].[ap_UpdateExchRateAndAmount]
End
Print '**** Creating Stored Procedure dbo.ap_UpdateExchRateAndAmount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ap_UpdateExchRateAndAmount
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@psPaymentCurrency	nvarchar(3)	      ,
	@pnCurrencyRate		decimal(11,4)	      ,
	@pnPlanId		int                   ,
	@psTempPaymentTable	nvarchar(116)
)
as
-- PROCEDURE:	ap_UpdateExchRateAndAmount
-- VERSION:	4
-- SCOPE:	InPro
-- DESCRIPTION:	Update Plan Payment temp table with the new
--		BANKEXCHANGERATE and Recalculate BANKAMOUNT, BANKNET, DISSECTIONAMOUNT
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2003	SFOO	8816	1	Procedure created
-- 15 Dec 2003	SFOO	8816	2	Call ap_UpdateLocalDissectionAmount rather than	providing duplicate code.
-- 09 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 20 Oct 2015  MS      R53933  4       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	declare	@nErrorCode		int
	declare @sErrMessage		nvarchar(397)
	declare @sSql			nvarchar(1000)
	declare @sLocalCurrency 	nvarchar(3)
	declare @sBankCurrency		nvarchar(3)
	
	-- Initialise variable(s)
	Set @nErrorCode = 0
	
	-- Input Validations
	If (@psTempPaymentTable is Null OR LEN(LTRIM(@psTempPaymentTable)) = 0)
	Begin
		Set @sErrMessage = N'The temporary payment plan table passed to ' +
		                   N'ap_UpdateExchRateAndAmount is blank.'
		RAISERROR( @sErrMessage, 16, 1 )
		Set @nErrorCode = 99
		Return @nErrorCode
	End
	
	If (@pnCurrencyRate <= 0)
	Begin
		Set @sErrMessage = N'The Currency Rate passed to ap_UpdateExchRateAndAmount ' +
				   N'cannot be less than and equal to zero.'
		RAISERROR( @sErrMessage, 16, 1 )
		Set @nErrorCode = 99
		Return @nErrorCode
	End
	
	If (@psPaymentCurrency is Null OR LEN(LTRIM(@psPaymentCurrency)) = 0)
	Begin
		Set @sErrMessage = N'The payment currency code passed to ' +
		                   N'ap_UpdateExchRateAndAmount is blank.'
		RAISERROR( @sErrMessage, 16, 1 )
		Set @nErrorCode = 99
		Return @nErrorCode
	End
	
	-- Get Home Currency
	If @nErrorCode = 0
	Begin
		SELECT @sLocalCurrency = COLCHARACTER
		FROM SITECONTROL
		WHERE CONTROLID = 'CURRENCY'	
		Set @nErrorCode = @@Error
	End

	-- Get Bank Currency
	If @nErrorCode = 0
	Begin
		Set @sSql = 'SELECT DISTINCT @sBankCurrency = BA.CURRENCY
			     FROM ' + @psTempPaymentTable + ' TT
				INNER JOIN
	     		     BANKACCOUNT BA ON (BA.ACCOUNTOWNER = TT.ENTITYNO AND
						BA.BANKNAMENO = TT.BANKNAMENO AND
						BA.SEQUENCENO = TT.BANKSEQUENCENO)'
		Execute @nErrorCode=sp_executesql @sSql,
						  N'@sBankCurrency Nvarchar(3) OUTPUT',
						  @sBankCurrency OUTPUT
	End
		
	Begin Transaction

	If @nErrorCode = 0
	Begin
		If @psPaymentCurrency <> @sLocalCurrency
		Begin
			Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
				    N'Set BANKEXCHANGERATE = @pnCurrencyRate  
				      Where DISSECTIONCURRENCY = @psPaymentCurrency
				      And PAYMENTCURRENCY is not Null'
			--Print @sSql
			Execute @nErrorCode = sp_executesql @sSql,
							    N'@pnCurrencyRate    decimal(11, 4),
							      @psPaymentCurrency nvarchar(3)',
							    @pnCurrencyRate,
							    @psPaymentCurrency
							    
			If @nErrorCode = 0
			Begin
				Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
						  N'Set BANKAMOUNT = PAYMENTAMOUNT / BANKEXCHANGERATE
						    Where DISSECTIONCURRENCY = @psPaymentCurrency
						    And PAYMENTCURRENCY is not Null'
				--Print @sSql		    
		 		Execute @nErrorCode = sp_executesql @sSql,
		 						    N'@psPaymentCurrency nvarchar(3)',
		 						    @psPaymentCurrency
		 	End
		 	
		 	If @nErrorCode = 0
		 	Begin
		 		Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
		 				  N'Set BANKNET = BANKAMOUNT - BANKCHARGES
						    Where DISSECTIONCURRENCY = @psPaymentCurrency
				                    And PAYMENTCURRENCY is not Null'
				--Print @sSql           
				Execute @nErrorCode = sp_executesql @sSql,
								    N'@psPaymentCurrency nvarchar(3)',
								    @psPaymentCurrency
 		 	End
 		End
		Else If ( @sBankCurrency <> @sLocalCurrency )
		Begin
			Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
					  N'Set BANKEXCHANGERATE = @pnCurrencyRate  
					    Where DISSECTIONCURRENCY = @sBankCurrency
					    And PAYMENTCURRENCY is not Null'
			--Print @sSql
			Execute @nErrorCode = sp_executesql @sSql,
							    N'@pnCurrencyRate    decimal(11, 4),
							      @sBankCurrency	 nvarchar(3)',
							    @pnCurrencyRate,
							    @sBankCurrency
							    
			If @nErrorCode = 0
			Begin
				Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
						  N'Set BANKAMOUNT = PAYMENTAMOUNT / BANKEXCHANGERATE
						    Where DISSECTIONCURRENCY = @sBankCurrency
						    And PAYMENTCURRENCY is not Null'
				--Print @sSql		    
		 		Execute @nErrorCode = sp_executesql @sSql,
		 						    N'@sBankCurrency nvarchar(3)',
		 						    @sBankCurrency
		 	End
		 	
		 	If @nErrorCode = 0
		 	Begin
		 		Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
		 				  N'Set BANKNET = BANKAMOUNT - BANKCHARGES
						    Where DISSECTIONCURRENCY = @sBankCurrency
				                    And PAYMENTCURRENCY is not Null'
				--Print @sSql           
				Execute @nErrorCode = sp_executesql @sSql,
								    N'@sBankCurrency nvarchar(3)',
								    @sBankCurrency
 		 	End
		End
		Else
		Begin
			Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
					  N'Set BANKEXCHANGERATE = @pnCurrencyRate
					    Where DISSECTIONCURRENCY is Null
					    And PAYMENTCURRENCY is not Null'
			--Print @sSql
			Execute @nErrorCode = sp_executesql @sSql,
							    N'@pnCurrencyRate decimal(11, 4)',
							    @pnCurrencyRate

			If @nErrorCode = 0
			Begin
				Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
					  	  N'Set BANKAMOUNT = PAYMENTAMOUNT / BANKEXCHANGERATE
						    Where DISSECTIONCURRENCY is Null
						    And PAYMENTCURRENCY is not Null'
				--Print @sSql
				Execute @nErrorCode = sp_executesql @sSql					      
			End

			If @nErrorCode = 0
			Begin
				Set @sSql = N'Update ' + @psTempPaymentTable + SPACE(1) +
						  N'Set BANKNET = BANKAMOUNT - BANKCHARGES
						    Where DISSECTIONCURRENCY is Null
						    And PAYMENTCURRENCY is not Null'
				--Print @sSql
				Execute @nErrorCode = sp_executesql @sSql
			End
		End
	End

	If @nErrorCode = 0
		Execute @nErrorCode=ap_UpdateLocalDissectionDetails @pnPlanId=@pnPlanId, @psTableName=@psTempPaymentTable

	
	If @nErrorCode = 0
		Commit Transaction
	Else
		Rollback Transaction

	Return @nErrorCode
End
GO

Grant execute on dbo.ap_UpdateExchRateAndAmount to public
GO
