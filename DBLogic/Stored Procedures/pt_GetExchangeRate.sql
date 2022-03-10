-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetExchangeRate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetExchangeRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetExchangeRate.'
	drop procedure dbo.pt_GetExchangeRate
	print '**** Creating procedure dbo.pt_GetExchangeRate...'
	print ''
end
go

create proc dbo.pt_GetExchangeRate 
	@psCurrency 		varchar(3), 
	@prnBuyRate 		decimal(11,4)	output, 
	@prnSellRate 		decimal(11,4)	output,
	@prnRoundBilledValues	smallint	output
as

-- PROCEDURE :	pt_GetExchangeRate
-- VERSION :	2
-- DESCRIPTION:	
-- CALLED BY :	pt_DoCalculation

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 26/02/2002	MF		Procedure Created
-- 20 Oct 2015  MS  R53933 2    Changed size from decimal(8,4) to decimal(11,4) for rates cols

set nocount on

declare	@ErrorCode	int

Select	@ErrorCode=0

If @ErrorCode=0
Begin
	SELECT 	@prnBuyRate		=BUYRATE,
		@prnSellRate		=SELLRATE,
		@prnRoundBilledValues	=ROUNDBILLEDVALUES 
	FROM	CURRENCY 
	WHERE   CURRENCY = @psCurrency

	Select @ErrorCode=@@Error

	If (@prnBuyRate is null) OR (@prnBuyRate = 0)
		select @prnBuyRate = 1

	If (@prnSellRate is null) OR (@prnSellRate = 0)
		select @prnSellRate = 1
End

Return @ErrorCode
go

grant execute on dbo.pt_GetExchangeRate to public
go
