-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetHistExchRate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetHistExchRate') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetHistExchRate'
	Drop function [dbo].[fn_GetHistExchRate]
End
Print '**** Creating Function dbo.fn_GetHistExchRate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetHistExchRate
(
	@pdtTransactionDate	datetime, 		-- Required for historical exchange rates.
	@psCurrencyCode		nvarchar(3), 		-- The currency the information is required for
	@pnExchRateType		tinyint		= 1	-- Bank Rate = 1, Buy Rate = 2, Sell Rate = 4
) 
RETURNS decimal(11,4)
AS
-- Function :	fn_GetHistExchRate
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Historical Exchange Rate appropriate, as requested
--		NOTE: This specifically does not take into account closed periods 
--		or Exchange Schedules as it was designed for use with the General Ledger
--		If an exchange rate of NULL or 0 is derived this will be interpreted as 
--		Local Currency and the rate returned will be 1

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 OCT 206	CR	12605	1	Function created
-- 20 Oct 2015  MS      R53933  2       Changed size from decimal(8,4) to decimal(11,4) for rate cols

Begin

	declare @nExchRate		decimal(11,4),
		@nErrorCode		int

	Set @nErrorCode = 0

	Select @nExchRate = (Case @pnExchRateType
						when 1 then isnull(H.BANKRATE, C.BANKRATE)
						when 2 then isnull( H.BUYRATE, C.BUYRATE)
						else isnull(H.SELLRATE, C.SELLRATE)
					End)
	from	CURRENCY C
	left join EXCHANGERATEHIST H	on (H.CURRENCY = C.CURRENCY
					and H.DATEEFFECTIVE = 
						(select max(H1.DATEEFFECTIVE)
						from 	EXCHANGERATEHIST H1
						where 	H1.CURRENCY = H.CURRENCY
						and	H1.DATEEFFECTIVE <= @pdtTransactionDate)
					    )
	where	C.CURRENCY = @psCurrencyCode

	if (@nExchRate is null or @nExchRate = 0)
	Begin
		Set @nExchRate = 1
	End

	return @nExchRate
End
GO

grant execute on dbo.fn_GetHistExchRate to public
go
