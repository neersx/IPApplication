-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_RoundLocalCurrency 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_RoundLocalCurrency ') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_RoundLocalCurrency'
	Drop function [dbo].[fn_RoundLocalCurrency ]
End
Print '**** Creating Function dbo.fn_RoundLocalCurrency ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_RoundLocalCurrency 
(
	@pnDecimalValue decimal(20,11)
) 
RETURNS decimal(11,2)
AS
-- Function :	fn_RoundLocalCurrency 
-- VERSION :	3
-- DESCRIPTION:	Rounds a decimal value to the appropriate number of decimal places for use as local currency.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jan 2005	TM	RFC1533	1	Function created
-- 20 Jan 2005	TM	RFC1533	2	Increase the number of decimal places in the input parameter from 2 to 11
--					and use the 'round' function instead of the 'cast' to round the input value. 
-- 15 Dec 2008	MF	17136	3	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

Begin
	-- If the Currency Whole Units site control is set to true the result 
	-- should be rounded to a whole number, otherwise it should be rounded 
	-- to 2 decimal places.
	If exists (	select 1 
			from SITECONTROL 
			where CONTROLID = 'Currency Whole Units'	
			and   COLBOOLEAN = 1)
	Begin
		Set @pnDecimalValue = round(@pnDecimalValue,0)
	End
	Else Begin
		Set @pnDecimalValue = round(@pnDecimalValue,2)
	End	
	
	Return @pnDecimalValue
End
GO

Grant execute on dbo.fn_RoundLocalCurrency  to public
GO
