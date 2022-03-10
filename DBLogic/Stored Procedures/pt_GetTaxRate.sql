-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetTaxRate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetTaxRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetTaxRate.'
	drop procedure dbo.pt_GetTaxRate
end
print '**** Creating procedure dbo.pt_GetTaxRate...'
print ''
go

CREATE PROCEDURE dbo.pt_GetTaxRate 
		@prnTaxRate 		decimal(11,4)	output, 
		@psNewTaxCode 		nvarchar(3) 	= null output, -- If the tax code has been changed, otherwise null
		@psTaxCode		nvarchar(3), 
		@pnCaseId		int,		-- The Case ID
		@pnDebtorNo 		int,		-- the NAMENO for the debtor
		@pdtCalculationDate	datetime	= null -- the date for which the rate is being calculated

-- PROCEDURE :	pt_GetTaxRate
-- VERSION :	6
-- DESCRIPTION:	Returns the tax rate associated with a particular tax code
-- CALLED BY :	pt_DoCalculation

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 FEB2002	MF			Procedure Created
-- 18 MAR 2003	JB	8116		Multiple tax rates per tax code	
-- 16 JAN 2008	Dw	9782		TaxNo moved from Organisation to Name table
-- 15 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 18 Feb 2009	Dw	13940	5	Adjusted SQL to include EFFECTIVEDATE
-- 20 Oct 2015  MS      R53933  6       Changed size from decimal(8,4) to decimal(11,4) for @prnTaxRate col

AS

Set nocount on

-- Variable decleration
Declare @sDebtorCountryCode 	nvarchar(3)
Declare @sVatNo 		nvarchar(30)
Declare @sSourceCountryCode 	nvarchar(3)
Declare	@nErrorCode 		int
Declare @nCount 		int
Declare @nEmployeeNo		int

Set	@nErrorCode = 0
Set 	@psNewTaxCode = null

-- If calculation date is not provided then default to today
-- using getdate as the default in the param specification causes errors.
If @pdtCalculationDate is null
Begin
	Set @pdtCalculationDate = getdate()
End

-- For exempt we always use a tax rate of zero
If @psTaxCode = '0'
Begin
	Set @prnTaxRate = 0
	Return @nErrorCode
End


-- Need to work out where the bill is coming from
If @nErrorCode=0 
Begin
	-- First find the employee for case
	Select @nEmployeeNo = NAMENO
		from	CASENAME CN
		where 	CN.CASEID = @pnCaseId 
		and 	CN.NAMETYPE = 'EMP'
	Set @nErrorCode = @@ERROR

	-- Find the country for the office of the empolyee
	if @nErrorCode = 0 and @nEmployeeNo is not null
	begin
		Select @sSourceCountryCode = COUNTRYCODE 
			from OFFICE O
			join TABLEATTRIBUTES TA
				on TA.PARENTTABLE = 'NAME'
				and TA.TABLETYPE = 44
				and TA.TABLECODE = O.OFFICEID
			where TA.GENERICKEY = cast(@nEmployeeNo as nvarchar(20))
		Set @nErrorCode = @@ERROR
	end

	If @nErrorCode=0 and @sSourceCountryCode is null
	-- Could be a host of reasons: no case, no employee on case, no office on employee, no country on office
	Begin
		Set @sSourceCountryCode = 'ZZZ' -- Default country
	End 
End

-- Check the site control
If @nErrorCode=0 
Begin
	Declare @sEUTaxCode nvarchar(10)
	Select @sEUTaxCode=COLCHARACTER
		from	SITECONTROL
		where	CONTROLID = 'Tax Code for EU billing'
	Set @nErrorCode = @@ERROR
End
	
If @nErrorCode=0
Begin 
	-- Check that the site control is filled in
	If @sEUTaxCode is not null and len(@sEUTaxCode) > 0
	Begin
		Select  @sDebtorCountryCode = A.COUNTRYCODE, 
			@sVatNo=N.TAXNO
			from NAME N
			join ADDRESS A on (A.ADDRESSCODE=N.POSTALADDRESS)
			where N.NAMENO = @pnDebtorNo
		Set @nErrorCode = @@ERROR

		-- Check that it is a cross-border bill
		-- and that they have a Tax/VAT Number
		If @nErrorCode = 0 
			and (@sDebtorCountryCode != @sSourceCountryCode)
			and @sVatNo is not null
		Begin
			-- Check that both countries are in the EU
			If exists(Select * from TABLEATTRIBUTES TA1
				join TABLEATTRIBUTES TA2 on TA2.PARENTTABLE = 'COUNTRY'
						and TA2.GENERICKEY = @sSourceCountryCode 
						and TA2.TABLECODE = 5008 and TA2.TABLETYPE = 50
				where TA1.PARENTTABLE = 'COUNTRY' 
					and TA1.GENERICKEY = @sDebtorCountryCode
					and TA1.TABLECODE = 5008 and TA1.TABLETYPE = 50)
			Begin			
				Set @psTaxCode = @sEUTaxCode
				Set @psNewTaxCode = @sEUTaxCode
			End
		End
	End
End

If @nErrorCode = 0
Begin
	-- Try and find the tax rate for the specified country
	Select @prnTaxRate = RATE
		from TAXRATESCOUNTRY
		where TAXCODE = @psTaxCode
		and COUNTRYCODE = @sSourceCountryCode
		and EFFECTIVEDATE = (select max(EFFECTIVEDATE) from TAXRATESCOUNTRY 
			where TAXCODE = @psTaxCode
			and COUNTRYCODE = @sSourceCountryCode
			and EFFECTIVEDATE <= @pdtCalculationDate)

	Select @nErrorCode = @@ERROR, @nCount = @@ROWCOUNT

	-- Fall back to the default tax rate
	If @nErrorCode = 0 and @nCount = 0
	Begin
		Select @prnTaxRate = RATE
			from TAXRATESCOUNTRY
			where TAXCODE = @psTaxCode
			and COUNTRYCODE = 'ZZZ'
			and EFFECTIVEDATE = (select max(EFFECTIVEDATE) from TAXRATESCOUNTRY 
				where TAXCODE = @psTaxCode
				and COUNTRYCODE = 'ZZZ'
				and EFFECTIVEDATE <= @pdtCalculationDate)

		Set @nErrorCode=@@Error
                
	End
End

Return @nErrorCode
go

grant execute on dbo.pt_GetTaxRate to public
go
