-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ConvertCurrency
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ConvertCurrency') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_ConvertCurrency'
	Drop function [dbo].[fn_ConvertCurrency]
End
Print '**** Creating Function dbo.fn_ConvertCurrency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_ConvertCurrency
(
	@psFromCurrency	nvarchar(3),
	@psToCurrency	nvarchar(3),
	@pnFromAmount	decimal(11,2),
	@pnExchRateType	tinyint
) 
RETURNS decimal(14,5)
AS
-- Function :	fn_ConvertCurrency
-- VERSION :	8
-- DESCRIPTION:	Return the amount after converting from one currency to another currency.
--		NOTE: Passing NULL as a currency is interpreted as Local Currency.
--		NOTE: This function will return a decimal of precision 1 higher than the 
--		highest level of precision stored (amounts are generally stored as 11,2 
--		and exchange rates are generally stored as 8, 4 . it is up to the calling 
--		code to ensure
-- 		the precision is correct before committing to the database.
--		Constants to use for @pnExchRateType:
--			* Bank Rate = 1
--			* Buy Rate = 2
--			* Sell Rate = 4

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 NOV 2003	CR	8816	1.00	Function created
-- 15 DEC 2003	CR	8816	1.01	change the precision of what is returned to 
-- 					try to avoid rounding errors.
-- 18 FEB 2004	SS	9297	1.02	Modified parameter @pbUseSellRate to @pnExchRateType
--					so the bank, buy and sell rate can be used.
-- 14 MAY 2004  JB	9917	4	Tidy up and make more robust
-- 18 OCT 2008	KR	17051	5	Extended the decimal size of the return from 11,5 to 14,5
-- 15 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 31 Jan 2011	DL	19261	7	Fix decimal size for variables @nFromExchRate and @nToExchRate to match database column CURRENCY.BANKRATE, BUYRATE and SELLRATE.
-- 08 Sep 2017	MAF	72376	8	Fix decimal size for variables @nFromExchRate and @nToExchRate to match database column CURRENCY.BANKRATE, BUYRATE and SELLRATE (11.4)

Begin

	declare @nResult	decimal(14,5),
		-- change from decimal (8,5) to (11,4) to match the database column CURRENCY.BANKRATE, BUYRATE and SELLRATE.
		@nFromExchRate 	decimal(11, 4),
		@nToExchRate 	decimal(11, 4),
		@sHomeCurrency	nvarchar(3)

	Set @nFromExchRate = 1
	Set @nToExchRate = 1
	Select @sHomeCurrency = UPPER(COLCHARACTER)
	from 	SITECONTROL 
	where   CONTROLID = 'CURRENCY'

	If (@psFromCurrency is not null) and (@psFromCurrency != @sHomeCurrency)
	Begin
		
		Select @nFromExchRate = (Case @pnExchRateType
						when 1 then C.BANKRATE
						when 2 then C.BUYRATE
						else C.SELLRATE
					End)
		from CURRENCY C
		where C.CURRENCY = @psFromCurrency

	End

	If (@psToCurrency is not null) and (@psToCurrency != @sHomeCurrency)
	Begin
		Select @nToExchRate = (Case @pnExchRateType
						when 1 then C.BANKRATE
						when 2 then C.BUYRATE
						else C.SELLRATE
					End)
		from CURRENCY C
		where C.CURRENCY = @psToCurrency

	End	

	-- Convert Foreign to Local
	If ((@nFromExchRate is not null) AND (@nFromExchRate <> 0))
	Begin
		Set @nResult = @pnFromAmount / @nFromExchRate 

		-- Convert Local to Foreign
		If ((@nToExchRate is not null) AND (@nToExchRate <> 0))
			Set @nResult = @nResult * @nToExchRate 

	End

	Return @nResult
End
GO

grant execute on dbo.fn_ConvertCurrency to public
GO
