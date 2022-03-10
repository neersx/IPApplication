-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetBilledValue
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetBilledValue]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	print '**** Drop function dbo.fn_GetBilledValue.'
	drop function dbo.fn_GetBilledValue
end
print '**** Creating function dbo.fn_GetBilledValue...'
print ''
go


CREATE FUNCTION [dbo].[fn_GetBilledValue]
(
	-- All exchange rates relate to local currency;
	-- i.e. LocalAmount * ExchangeRate = ForeignAmount
	@pnUserIdentityId		INT,		-- Mandatory
	@psCurrencyCode			NVARCHAR(5),	-- The currency the information is required for
	@pnCaseID			INT,		-- CaseID used to obtain the correct exchange rate variation
	@pnNameNo			INT,		-- NameNo used to obtain the correct exchange rate variation
	@pbIsSupplier		BIT,			-- SQA12361 User entered Exchange Rate Schedule
	@pdBalance			decimal(11,2)
)
RETURNS DECIMAL(11,2)
AS
-- PROCEDURE:	fn_GetBilledValue
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Obtain foreign balance based on sell rate and currency

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Aug 2017	MS		R71887	1		Procedure created 
 
BEGIN
	DECLARE @nSellRate		DECIMAL(11,4)
	DECLARE @nDecimalPlaces		TINYINT
	DECLARE @nRoundBilledValues	SMALLINT
	DECLARE @nForeignAmount	DECIMAL(11,4)
	declare @nRemainder	smallint

	Select @nSellRate = SellRate,  @nDecimalPlaces= DecimalPlaces, @nRoundBilledValues = RoundBilledValues
	from dbo.fn_GetExchangeDetails(@pnUserIdentityId, 0, @psCurrencyCode, getdate(), null, @pnCaseID, @pnNameNo, @pbIsSupplier, null, null, null, null, null, null)
	
	Set @nForeignAmount = ROUND(@pdBalance * ISNULL(@nSellRate,1), ISNULL(@nDecimalPlaces, 2))

	if ISNULL(@nRoundBilledValues,0) <> 0
	Begin

		Set @nForeignAmount = Round(@nForeignAmount,0)

		-- Perform a Modulus division to get the remainder of the amount divided by the Unit Size
		Set @nRemainder = @nForeignAmount % @nRoundBilledValues

		-- Subtract the remainder from the integer
		Set @nForeignAmount= @nForeignAmount-@nRemainder

		-- Now determine if rounding up or down is required.
		If ABS(convert(decimal(11,2),@nRemainder)/@nRoundBilledValues)>0.5
		begin
			If @nForeignAmount>0
				Set @nForeignAmount=@nForeignAmount+@nRoundBilledValues
			else If @nForeignAmount<0
				Set @nForeignAmount=@nForeignAmount-@nRoundBilledValues
		end
	End 

	RETURN @nForeignAmount
END

GO

grant execute on dbo.fn_GetBilledValue to public
GO