-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetEffectiveTaxRate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetEffectiveTaxRate') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetEffectiveTaxRate.'
	drop function dbo.fn_GetEffectiveTaxRate
	print '**** Creating function dbo.fn_GetEffectiveTaxRate...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetEffectiveTaxRate
	(
		@psTaxCode		 nvarchar(3), -- the tax code
		@psSourceCountry nvarchar(3) = null,
		@pdtTransactionDate datetime = null,
		@pnEntityKey	int = null
	)
Returns decimal(11,4)

-- FUNCTION :	fn_GetEffectiveTaxRate
-- VERSION :	4
-- DESCRIPTION:	This function returns the applicable tax rate from TAXRATESCOUNTRY.

-- Date		Who	Number		Version	Description
-- ===========	===	======		=======	==========================================
-- 20 Jan 2010	AT 	RFC3605		1	Function created.
-- 05 Aug 2011	AT	RFC11085	2	Reversed order of effective date.
-- 20 Oct 2015  MS  R53933      3   Changed size from decimal(8,4) to decimal(11,4) for rate cols
-- 10 Oct 2018  AK	R74005      4   implemented changes to pick source country from entity based on 'Tax Source Country Derived from Entity' sitecontrol

AS
Begin

Declare @dReturnRate decimal(11,4)
Declare @nSourceContryFromEntity bit
Declare @sEntityCountryCode 	nvarchar(3)
Select @nSourceContryFromEntity=COLBOOLEAN
		from	SITECONTROL
		where	CONTROLID = 'Tax Source Country Derived from Entity'

if @pnEntityKey is not null and @nSourceContryFromEntity  = 1
Begin
SELECT @sEntityCountryCode = ISNULL(N.NATIONALITY , A.COUNTRYCODE)
					FROM NAME N
					JOIN ADDRESS A ON (A.ADDRESSCODE = N.STREETADDRESS)
					WHERE N.NAMENO = @pnEntityKey

	If @sEntityCountryCode is not null
	Begin
		set @psSourceCountry = @sEntityCountryCode
	End
End

if (@pdtTransactionDate is null)
Begin
	set @pdtTransactionDate = dbo.fn_DateOnly(getdate())
End

select @dReturnRate = RATE.RATE
FROM
(SELECT TOP 1 RATE
From TAXRATESCOUNTRY
WHERE TAXCODE = @psTaxCode
AND COUNTRYCODE = ISNULL(@psSourceCountry, 'ZZZ')
AND dbo.fn_DateOnly(EFFECTIVEDATE) <= dbo.fn_DateOnly(@pdtTransactionDate)
order by EFFECTIVEDATE desc) AS RATE

if (@dReturnRate is null)
Begin
	select @dReturnRate = RATE.RATE
	FROM
	(SELECT TOP 1 RATE
	From TAXRATESCOUNTRY
	WHERE TAXCODE = @psTaxCode
	AND COUNTRYCODE = 'ZZZ'
	AND dbo.fn_DateOnly(EFFECTIVEDATE) <= dbo.fn_DateOnly(@pdtTransactionDate)
	order by EFFECTIVEDATE desc) AS RATE
End

Return @dReturnRate

End
go

grant execute on dbo.fn_GetEffectiveTaxRate to public
GO
