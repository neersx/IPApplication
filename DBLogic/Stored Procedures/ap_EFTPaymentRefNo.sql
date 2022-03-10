-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_EFTPaymentRefNo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.ap_EFTPaymentRefNo') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ap_EFTPaymentRefNo.'
	Drop procedure dbo.ap_EFTPaymentRefNo
End
Print '**** Creating Stored Procedure dbo.ap_EFTPaymentRefNo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ap_EFTPaymentRefNo
(
	@prnRowCount			int 		= null	Output,
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura 		tinyint 	= 0,
	@psTableName			nvarchar(32)	= null,
	@pnEFTFileFormat		int		= null,		
	@pnAccountOwner			int,				-- Bank Account Owner's Name No
	@pnBankNameNo			int,				-- Bank Account Bank's Name No
	@pnSequenceNo			int				-- Bank Account SequenceNo
)
AS
-- PROCEDURE :	ap_EFTPaymentRefNo
-- VERSION :	2
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generates Payment Ref No for use with EFT Payments.
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 26/11/2004	CR	10601	1	Creation.
-- 13/12/2004	AB	10793	2	Add go before grant statement

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nPaymentRefNo		int,
	@nMaxRefNo		int,
	@sPaymentRefNo		nvarchar(18),
	@nErrorCode		int,
	@sSQLString 		nvarchar(4000),
	@nEFTFileFormatABA	int,
	@nEFTFileFormatSWIFT	int,
	@nLength		int,
	@sPadding		char(1),
	@sPrefix		nvarchar(8)


Set @nErrorCode = 0
Set @nEFTFileFormatSWIFT = 9301
Set @nEFTFileFormatABA = 9302
set @sPadding = '0'
Set @prnRowCount = 0

If @nErrorCode = 0
Begin
	Set @sSQLString="
	SELECT @nPaymentRefNo = ISNULL(LASTPAYMENTREFNO, 0), @sPrefix = PAYMENTREFPREFIX
	FROM EFTDETAIL
	WHERE ACCOUNTOWNER = @pnAccountOwner
	AND BANKNAMENO = @pnBankNameNo
	AND SEQUENCENO = @pnSequenceNo"	

	Exec @nErrorCode=sp_executesql @sSQLString,
	N' @nPaymentRefNo	int			OUTPUT,
	  @sPrefix		nvarchar(8)		OUTPUT,
	  @pnAccountOwner	int,				
	  @pnBankNameNo		int,				
	  @pnSequenceNo		int',
	  @nPaymentRefNo	= @nPaymentRefNo	OUTPUT,
	  @sPrefix		= @sPrefix		OUTPUT,
	  @pnAccountOwner	= @pnAccountOwner,
	  @pnBankNameNo		= @pnBankNameNo,
	  @pnSequenceNo		= @pnSequenceNo
End

If @nErrorCode = 0
Begin
		If @pnEFTFileFormat = @nEFTFileFormatABA -- 18
		Begin
			SET @nLength = (18 - len(@sPrefix))
		end
		Else -- 16 SWIFT or nothing
		Begin
			SET @nLength = (16 - len(@sPrefix))
		end
End

-- make sure that the next Payment Ref No hasn't already been used for the current bank account.
-- if it is find the next available Payment Ref No that may be used for the current bank account.
If @nErrorCode = 0
Begin

		Set @nPaymentRefNo = @nPaymentRefNo + 1

		SET @sPaymentRefNo = @sPrefix + CAST(dbo.fn_GetPaddedString(CONVERT(nvarchar(18), @nPaymentRefNo), @nLength, @sPadding, 1) AS NVARCHAR(18))

		While exists (Select * 
				from CASHITEM 
				where ITEMREFNO = @sPaymentRefNo
				and ENTITYNO = @pnAccountOwner
				and BANKNAMENO = @pnBankNameNo
				and SEQUENCENO = @pnSequenceNo) and (@nErrorCode = 0)
		Begin
			Set @nPaymentRefNo = @nPaymentRefNo + 1
			Set @sPaymentRefNo = @sPrefix + CAST(dbo.fn_GetPaddedString(CONVERT(nvarchar(18), @nPaymentRefNo), @nLength, @sPadding, 1) AS NVARCHAR(18))		
		End
End


If @nErrorCode = 0
Begin
	-- If a Manual Payment Update the EFTDETAIL.LASTPAYMENTREFNO for the current Bank Account 
	-- and return the Payment Ref No derived above.
	if @psTableName is Null
	Begin
		
		Set @sSQLString = "Update EFTDETAIL
				Set LASTPAYMENTREFNO = @nPaymentRefNo
				WHERE ACCOUNTOWNER = @pnAccountOwner
				AND BANKNAMENO = @pnBankNameNo
				AND SEQUENCENO = @pnSequenceNo"

		exec @nErrorCode=sp_executesql @sSQLString,
		N'@nPaymentRefNo	int,
		  @pnAccountOwner	int,				
		  @pnBankNameNo		int,				
		  @pnSequenceNo		int',
		  @nPaymentRefNo	= @nPaymentRefNo,
		  @pnAccountOwner	= @pnAccountOwner,
		  @pnBankNameNo		= @pnBankNameNo,
		  @pnSequenceNo		= @pnSequenceNo

		If @nErrorCode = 0
		Begin
			-- all the hard work has been done
			SELECT @sPaymentRefNo AS PAYMENTREFNO
		End
	End
	Else 
	-- Must be a payment plan.
	-- from the number prior to the Next Payment Ref No derived above 
	-- figure out what the Last Payment Ref No will be and update the EFTDETAIL.LASTPAYMENTREFNO 
	-- for the current Bank Account 
	-- Return the Payment Ref No for each payment in @psTableName
	Begin

		Set @nPaymentRefNo = @nPaymentRefNo - 1
		
		Set @sSQLString = "Select @nMaxRefNo = @nPaymentRefNo + MAX(SEQUENCE)
		from " 	+ @psTableName

		exec @nErrorCode=sp_executesql @sSQLString,
		N'@nMaxRefNo		int		OUTPUT,
	    	  @nPaymentRefNo	int',
		  @nMaxRefNo		= @nMaxRefNo	OUTPUT,
	    	  @nPaymentRefNo	= @nPaymentRefNo

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "Update EFTDETAIL
					Set LASTPAYMENTREFNO = @nMaxRefNo
					WHERE ACCOUNTOWNER = @pnAccountOwner
					AND BANKNAMENO = @pnBankNameNo
					AND SEQUENCENO = @pnSequenceNo"

			exec @nErrorCode=sp_executesql @sSQLString,
			N'@nMaxRefNo		int,
			  @pnAccountOwner	int,				
		  	@pnBankNameNo		int,				
			  @pnSequenceNo		int',
			  @nMaxRefNo		= @nMaxRefNo,
			  @pnAccountOwner	= @pnAccountOwner,
			  @pnBankNameNo		= @pnBankNameNo,
			  @pnSequenceNo		= @pnSequenceNo
		End

		If @nErrorCode = 0
		Begin

			Set @sSQLString = "Select @sPrefix + CAST(dbo.fn_GetPaddedString(CONVERT(nvarchar(18), @nPaymentRefNo + SEQUENCE), @nLength, @sPadding, 1) AS NVARCHAR(18)) AS PAYMENTREFNO
				from " + @psTableName

			exec @nErrorCode=sp_executesql @sSQLString,
			N'@sPrefix			nvarchar(8),
			  @nPaymentRefNo		int,
		    	  @nLength			int,
			  @sPadding			char(1)',
			  @sPrefix			= @sPrefix,
			  @nPaymentRefNo		= @nPaymentRefNo,
		    	  @nLength			= @nLength,
			  @sPadding			= @sPadding
		End

	End
End

Set @prnRowCount = @@Rowcount 

Return @nErrorCode
go

Grant execute on dbo.ap_EFTPaymentRefNo to public
GO
