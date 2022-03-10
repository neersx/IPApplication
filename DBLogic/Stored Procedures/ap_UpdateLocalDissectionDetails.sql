-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_UpdateLocalDissectionDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ap_UpdateLocalDissectionDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_UpdateLocalDissectionDetails.'
	Drop procedure [dbo].[ap_UpdateLocalDissectionDetails]
End
Print '**** Creating Stored Procedure dbo.ap_UpdateLocalDissectionDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ap_UpdateLocalDissectionDetails
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(10) 	= null,
	@pnPlanId		int,
	@psTableName		nvarchar(32)
)
as
-- PROCEDURE:	ap_UpdateLocalDissectionDetails
-- VERSION:	7
-- SCOPE:	InProma
-- DESCRIPTION:	Update Local and Dissection details of the Plan's payments
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 04-Dec-2003  SFOO	8816	1	Procedure created
-- 10-Dec-2003	CR	8817	2	Fixed bugs
-- 17-Dec-2003	CR	8817	3	Fixed updating of Local Charges and Net
-- 27-Jan-2004	CR	9558	4	Fixed updating of Local Charges when Local Exchange Rate
--					is NULL.
-- 18-Feb-2004	SS	9297	5	Incorporated Bank Rate.
-- 25-Jun-2004	CR	10082	6	Fixed the setting of the Local Amount.
-- 20 Oct 2015  MS      R53933  7       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare 
		@nErrorCode 	int,
		@sSQLString	nvarchar(4000),
		@sBankCurrency	nvarchar(3),
		@sLocalCurrency	nvarchar(3),
		@nExchRateType	tinyint
	
	Set @nErrorCode = 0
	
	If @nErrorCode = 0
	Begin
		Select @sBankCurrency = BA.CURRENCY
		from BANKACCOUNT BA
		join PAYMENTPLAN PP 	on (BA.ACCOUNTOWNER = PP.ENTITYNO
					and	BA.BANKNAMENO = PP.BANKNAMENO
					and	BA.SEQUENCENO = PP.BANKSEQUENCENO)
		where PP.PLANID = @pnPlanId
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sBankCurrency		nvarchar(3)	OUTPUT,
					@pnPlanId 			int',
					@sBankCurrency=@sBankCurrency			OUTPUT,
					@pnPlanId=@pnPlanId
	End
	
	If @nErrorCode = 0
	Begin
		Select @sLocalCurrency = SI.COLCHARACTER
		from SITECONTROL SI	
		where SI.CONTROLID = 'CURRENCY'
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sLocalCurrency		nvarchar(3)	OUTPUT',
					@sLocalCurrency=@sLocalCurrency			OUTPUT
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Select @nExchRateType = SI.COLBOOLEAN
		from SITECONTROL SI
		where SI.CONTROLID = 'Bank Rate In Use'"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nExchRateType	tinyint	OUTPUT',
					@nExchRateType=@nExchRateType	OUTPUT

		If @nExchRateType <> 1
		Begin
			--Bank Rate is not in use so use Buy Rate
			Set @nExchRateType = 2
		End
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update " + @psTableName + " 
		SET LOCALAMOUNT =	
			Case when (@sBankCurrency = @sLocalCurrency)
			then
				BANKAMOUNT
			else
				Case when PAYMENTCURRENCY IS NOT NULL 
				then 
					convert( decimal(11,2), dbo.fn_ConvertCurrency(PAYMENTCURRENCY, NULL, PAYMENTAMOUNT, @nExchRateType)) 
				else
					Case when (@sBankCurrency <> @sLocalCurrency)
					then
						convert( decimal(11,2), dbo.fn_ConvertCurrency(@sBankCurrency, NULL, BANKAMOUNT, @nExchRateType)) 
					else
						BANKAMOUNT
					End
				End
			End
		"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@psTableName		nvarchar(32),
					@sBankCurrency		nvarchar(3),
					@sLocalCurrency		nvarchar(3),
					@nExchRateType		tinyint',
					@psTableName,
					@sBankCurrency,
					@sLocalCurrency,
					@nExchRateType
	End
	
	If @nErrorCode = 0
	Begin
	
		Set @sSQLString = "Update " + @psTableName + "
		SET 	LOCALEXCHANGERATE = 
				Case when @sBankCurrency <> @sLocalCurrency 
				then
					convert( decimal(11,4), (BANKAMOUNT / LOCALAMOUNT))
				else
					NULL
				End,
			LOCALUNALLOCATED = LOCALAMOUNT"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@psTableName		nvarchar(32),
					@sBankCurrency		nvarchar(3),
					@sLocalCurrency		nvarchar(3)',
					@psTableName,
					@sBankCurrency,
					@sLocalCurrency
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update " + @psTableName + " 
		SET LOCALCHARGES = Case when LOCALEXCHANGERATE IS NULL
				then
					BANKCHARGES
				else
					ISNULL((BANKCHARGES / LOCALEXCHANGERATE), 0)
				End"

		exec @nErrorCode=sp_executesql @sSQLString

	End
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "Update " + @psTableName + " 
		SET LOCALNET = LOCALAMOUNT - LOCALCHARGES
		"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@psTableName		nvarchar(32),
					@sBankCurrency		nvarchar(3),
					@sLocalCurrency		nvarchar(3)',
					@psTableName,
					@sBankCurrency,
					@sLocalCurrency
	End

	If @nErrorCode = 0
	Begin
	
		Set @sSQLString = "Update " + @psTableName + " 
		set DISSECTIONCURRENCY = 
			Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTCURRENCY
			else
				CASE WHEN @sBankCurrency <> @sLocalCurrency 
				then
					@sBankCurrency
				Else
					NULL
				End
			End,
		DISSECTIONAMOUNT = 
			Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTAMOUNT
			else
				CASE WHEN @sBankCurrency <> @sLocalCurrency 
				then
					BANKAMOUNT
				Else
					NULL
				End
			End,
		DISSECTIONUNALLOC = 
			Case when PAYMENTCURRENCY <> @sLocalCurrency 
			then PAYMENTAMOUNT
			else
				CASE WHEN @sBankCurrency <> @sLocalCurrency 
				then
					BANKAMOUNT
				Else
					NULL
				End
			End"


		exec @nErrorCode=sp_executesql @sSQLString,
					N'@psTableName		nvarchar(32),
					@sBankCurrency		nvarchar(3),
					@sLocalCurrency		nvarchar(3)',
					@psTableName,
					@sBankCurrency,
					@sLocalCurrency
	End

	If @nErrorCode = 0
	Begin

		Set @sSQLString = "Update " + @psTableName + " 
		set DISSECTIONEXCHANGE = 
			Case when DISSECTIONCURRENCY IS NULL
			then 
				NULL
			else
				convert( decimal(11,4), (DISSECTIONAMOUNT/LOCALAMOUNT))
			End"

		exec @nErrorCode=sp_executesql @sSQLString
	End
	
	Return @nErrorCode

End
GO

Grant execute on dbo.ap_UpdateLocalDissectionDetails to public
GO
