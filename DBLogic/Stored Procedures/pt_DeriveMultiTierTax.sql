-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_DeriveMultiTierTax
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_DeriveMultiTierTax]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_DeriveMultiTierTax.'
	drop procedure dbo.pt_DeriveMultiTierTax
end
print '**** Creating procedure dbo.pt_DeriveMultiTierTax...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go


CREATE PROCEDURE dbo.pt_DeriveMultiTierTax 
		@prnFederalTaxRate 		decimal(11,4)	output, 
		@prnStateTaxRate		decimal(11,4)	output, 
		@prsFederalTaxCode 		nvarchar(3) 	= null output, -- Federal Tax Code
		@prsStateTaxCode 		nvarchar(3) 	= null output, -- State Tax Code
		@prbStateHarmonised		bit		= 0 output,
		@prbTaxOnTax			bit		= 0 output,
		@prbMultiTierTax		bit		= 0 output,
		@prsDestinationCountryCode 	nvarchar(3)	= null output, 
		@prsSourceCountryCode 		nvarchar(3)	= null output, 
		@prsDestinationState		nvarchar(20)	= null output, 
		@prsSourceState			nvarchar(20)	= null output, 	
		@prsCaseFederalTaxCode 		nvarchar(3)	= null output, 
		@prsCaseStateTaxCode 		nvarchar(3) 	= null output, 
		@prsIPNameFederalTaxCode 	nvarchar(3)	= null output, 
		@prsIPNameStateTaxCode 		nvarchar(3) 	= null output, 
		@prsHomeCountryCode 		nvarchar(3)	= null output, 
		@prsEUTaxCode 			nvarchar(10)	= null output, 
		@psWIPCode			nvarchar(6), 
		@pnCaseId			int,		-- The Case ID
		@pnDebtorNo 			int,		-- the NAMENO for the debtor
		@pnRaisedBy			int		-- the NameNo for the Raised By Staff Member

-- PROCEDURE :	pt_DeriveMultiTierTax
-- VERSION :	6
-- DESCRIPTION:	Returns the tax codes and rates associated with a particular WIP Item
-- CALLED BY :	pt_DoCalculation
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 29/11/2007	CR	14649	1	Procedure Created
-- 11/01/2008	CR	14649	2	Fixed syntax errors.
-- 16/01/2008	CR	9782	3	Updated references to TAXNO (formally VATNO) 
--					and STATETAXNO
-- 12/05/2008	CR	14649	4	Fixed problem with StateTaxCode parameters.
-- 15 Dec 2008	MF	17136	5	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 20 Oct 2015  MS      R53933  6       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols

AS

Set nocount on

-- Variable decleration
Declare @sTaxNo 			nvarchar(30)
Declare @nEmployeeNo			int
Declare	@nErrorCode 			int
Declare @nCount 			int
Declare @sWIPFederalTaxCode 		nvarchar(3)
Declare @sWIPStateTaxCode 		nvarchar(3) 
Declare @bFederalHarmonised		bit
Declare @sSQLString			nvarchar(4000)


Set	@nErrorCode = 0

-- initialise the setting of the return parameters
Set @prnFederalTaxRate = NULL
Set @prnStateTaxRate = NULL
Set @prsFederalTaxCode = null 
Set @prsStateTaxCode = null
Set @prbStateHarmonised = 0
Set @prbTaxOnTax = 0
Set @bFederalHarmonised = 0

-- This stored proc will only be called if @prbMultiTierTax is intially set to 1
If @nErrorCode=0 AND @prsHomeCountryCode IS NULL
Begin			
	Set @sSQLString="
	SELECT 	@prsHomeCountryCode=COLCHARACTER
	from SITECONTROL SC
	where SC.CONTROLID = 'HOMECOUNTRY'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@prsHomeCountryCode nvarchar(3)	output',
				  @prsHomeCountryCode	OUTPUT

End


-- LOOKUP WIP TAXCODES
If @nErrorCode=0 
Begin
	Set @sSQLString="
	select @sWIPFederalTaxCode = TAXCODE, @sWIPStateTaxCode = STATETAXCODE
	FROM WIPTEMPLATE
	WHERE WIPCODE = @psWIPCode"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sWIPFederalTaxCode	nvarchar(3)	output,
				  @sWIPStateTaxCode	nvarchar(3)	output,
				  @psWIPCode 		nvarchar(6)',
				  @sWIPFederalTaxCode	OUTPUT,
				  @sWIPStateTaxCode 	OUTPUT,
				  @psWIPCode
End

-- LOOKUP CASE TAXCODES, SERVPERFORMEDIN
If @nErrorCode=0 AND @prsCaseFederalTaxCode IS NULL AND @prsCaseStateTaxCode IS NULL
Begin
	Set @sSQLString="
	Select @prsCaseFederalTaxCode = TAXCODE, @prsCaseStateTaxCode = STATETAXCODE, 
	@prsDestinationState = SERVPERFORMEDIN
	FROM CASES
	WHERE CASEID = @pnCaseId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@prsCaseFederalTaxCode	nvarchar(3)	output,
				  @prsCaseStateTaxCode		nvarchar(3)	output,
				  @prsDestinationState		nvarchar(20)	output,
				  @pnCaseId 			int',
				  @prsCaseFederalTaxCode	= @prsCaseFederalTaxCode	OUTPUT,
				  @prsCaseStateTaxCode 		= @prsCaseStateTaxCode		OUTPUT,
				  @prsDestinationState		= @prsDestinationState 		OUTPUT,
				  @pnCaseId			= @pnCaseId
End

-- LOOKUP DEBTOR TAXCODES, DESTINATION COUNTRY, DESTINATIONPROVINCE
If @nErrorCode=0 AND 
@prsIPNameFederalTaxCode IS NULL AND 
@prsIPNameStateTaxCode IS NULL AND
@prsDestinationCountryCode IS NULL AND 
@prsDestinationState IS NULL
Begin
	Set @sSQLString="
	Select  @prsIPNameFederalTaxCode = IPN.TAXCODE, @prsIPNameStateTaxCode = IPN.STATETAXCODE,
	@prsDestinationCountryCode = A.COUNTRYCODE, 
	@prsDestinationState = COALESCE(@prsDestinationState, IPN.SERVPERFORMEDIN, A.STATE), 
	@sTaxNo=N.TAXNO
	from NAME N
	join ADDRESS A 			on (A.ADDRESSCODE=N.POSTALADDRESS)
	LEFT JOIN IPNAME IPN		on (IPN.NAMENO = N.NAMENO)
	where N.NAMENO = @pnDebtorNo"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@prsIPNameFederalTaxCode	nvarchar(3)	output,
				  @prsIPNameStateTaxCode	nvarchar(3)	output,
				  @prsDestinationCountryCode	nvarchar(3)	output,
				  @prsDestinationState		nvarchar(20)	output,
				  @sTaxNo			nvarchar(30)	output,	
				  @pnDebtorNo 			int',
				  @prsIPNameFederalTaxCode	= @prsIPNameFederalTaxCode	OUTPUT,
				  @prsIPNameStateTaxCode 	= @prsIPNameStateTaxCode		OUTPUT,
				  @prsDestinationCountryCode	= @prsDestinationCountryCode	OUTPUT,
				  @prsDestinationState		= @prsDestinationState		OUTPUT,
				  @sTaxNo			= @sTaxNo			OUTPUT,
				  @pnDebtorNo			= @pnDebtorNo
End

-- LOOKUP OFFICE OF EMPLOYEE - SOURCECOUNTRY, SOURCEPROVINCE
-- Need to work out where the bill is coming from
If @nErrorCode=0 AND @prsSourceCountryCode IS NULL AND @prsSourceState IS NULL
Begin

	Set @nEmployeeNo = @pnRaisedBy

	If @nEmployeeNo is NULL
	Begin
		-- First find the employee for case
		Set @sSQLString="
		Select @nEmployeeNo = NAMENO
			from	CASENAME CN
			where 	CN.CASEID = @pnCaseId 
			and 	CN.NAMETYPE = 'EMP'
			AND EXPIRYDATE is null
			AND SEQUENCE = (	SELECT MIN(CN2.SEQUENCE)
						FROM CASENAME CN2
						WHERE CN2.CASEID = @PnCaseId
						AND CN2.NAMETYPE = 'EMP'
						AND CN2.EXPIRYDATE is null)"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nEmployeeNo	int	output,
					  @pnCaseId 	int',
					  @nEmployeeNo	= @nEmployeeNo	OUTPUT,
					  @pnCaseId	= @pnCaseId
	End

	-- Find the country and state for the office of the empolyee
	if @nErrorCode = 0 and @nEmployeeNo is not null
	begin
		Set @sSQLString="
		Select @prsSourceCountryCode = ISNULL(O.COUNTRYCODE, A.COUNTRYCODE), 
			@prsSourceState = A.STATE 
			from OFFICE O
			join TABLEATTRIBUTES TA	on (TA.PARENTTABLE = 'NAME'
						and TA.TABLETYPE = 44
						and TA.TABLECODE = O.OFFICEID)
			left join NAME N	on (N.NAMENO = O.ORGNAMENO)
			join ADDRESS A		on (A.ADDRESSCODE=N.POSTALADDRESS)
			where TA.GENERICKEY = cast(@nEmployeeNo as nvarchar(20))"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@prsSourceCountryCode	nvarchar(3)	output,
					  @prsSourceState	nvarchar(20)	output,
					  @nEmployeeNo 		int',
					  @prsSourceCountryCode	= @prsSourceCountryCode	OUTPUT,
					  @prsSourceState	= @prsSourceState	OUTPUT,
					  @nEmployeeNo		= @nEmployeeNo
	end


	If @nErrorCode=0 and @prsSourceCountryCode is null
	-- Organisation and Country NOT Set use HOMENAMENO
	Begin
		Set @sSQLString="
		Select @prsSourceCountryCode = A.COUNTRYCODE, 
			@prsSourceState = A.STATE 
		from SITECONTROL SC
		left join NAME N	on (N.NAMENO = SC.COLINTEGER)
		join ADDRESS A		on (A.ADDRESSCODE=N.POSTALADDRESS)
		where SC.CONTROLID = 'HOMENAMENO'"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@prsSourceCountryCode	nvarchar(3)	output,
					  @prsSourceState	nvarchar(20)	output',
					  @prsSourceCountryCode	= @prsSourceCountryCode	OUTPUT,
					  @prsSourceState	= @prsSourceState	OUTPUT
	End 


	If @nErrorCode=0 and @prsSourceCountryCode is null
	-- Could be a host of reasons: no case, no employee on case, no office on employee, no country on office
	Begin

		Set @prsSourceCountryCode = 'ZZZ' -- Default country
	End 
End

If @nErrorCode = 0
Begin
	If (@prsDestinationCountryCode = @prsSourceCountryCode) AND (@prsSourceCountryCode = @prsHomeCountryCode)  
		Set @prbMultiTierTax = 1
	Else 
		Set @prbMultiTierTax = 0
	-- Only Federal Tax will apply.
	Set @prnStateTaxRate = NULL
	Set @prsStateTaxCode = NULL
	Set @prbStateHarmonised = 0
	Set @prbTaxOnTax = 0
End

If @nErrorCode = 0 AND @prbMultiTierTax = 1
Begin
	-- Federal Tax
	If @sWIPFederalTaxCode = '0' OR @prsIPNameFederalTaxCode = '0' OR @prsCaseFederalTaxCode = '0'
	begin
		-- Tax Exempt
		Set @prnFederalTaxRate =  0
		Set @prsFederalTaxCode = '0'
	end
	
	If @prsFederalTaxCode is NULL
	begin
		If @prsCaseFederalTaxCode is not NULL
			Set @prsFederalTaxCode = @prsCaseFederalTaxCode
		Else If @prsIPNameFederalTaxCode is not NULL
			Set @prsFederalTaxCode = @prsIPNameFederalTaxCode	
		
	end
	
	-- State Tax Code
	If @sWIPStateTaxCode = '0' OR @prsIPNameStateTaxCode = '0' OR @prsCaseStateTaxCode = '0'
	begin
		-- Tax Exempt
		Set @prnStateTaxRate =  0
		Set @prsStateTaxCode = '0'
	end
	
	If @prsStateTaxCode is NULL
	begin
		If @prsCaseStateTaxCode is not NULL
			Set @prsStateTaxCode = @prsCaseStateTaxCode
		Else If @prsIPNameStateTaxCode is not NULL
			Set @prsStateTaxCode = @prsIPNameStateTaxCode	
		
	end
	
	-- For exempt we always use a tax rate of zero
	If @prsFederalTaxCode = '0' AND @prsStateTaxCode = '0'
	Begin
		Set @prnFederalTaxRate = 0
		Set @prnStateTaxRate = 0
	End
	
	-- Check the site control
	If @nErrorCode=0 AND (@prsFederalTaxCode<> '0') AND @prsEUTaxCode IS NULL
	Begin
		Set @sSQLString="
		Select @prsEUTaxCode=COLCHARACTER
		from	SITECONTROL
		where	CONTROLID = 'Tax Code for EU billing'"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@prsEUTaxCode	nvarchar(3)	output',
					  @prsEUTaxCode	= @prsEUTaxCode	OUTPUT
		
		If @nErrorCode=0
		Begin 
			-- Check that the site control is filled in
			If @prsEUTaxCode is not null and len(@prsEUTaxCode) > 0
			Begin
				-- Check that it is a cross-border bill
				-- and that they have a Tax/VAT Number
				If @nErrorCode = 0 
					and (@prsDestinationCountryCode != @prsSourceCountryCode)
					and @sTaxNo is not null
				Begin
					-- Check that both countries are in the EU
					If exists(Select * from TABLEATTRIBUTES TA1
						join TABLEATTRIBUTES TA2 on TA2.PARENTTABLE = 'COUNTRY'
								and TA2.GENERICKEY = @prsSourceCountryCode 
								and TA2.TABLECODE = 5008 and TA2.TABLETYPE = 50
						where TA1.PARENTTABLE = 'COUNTRY' 
							and TA1.GENERICKEY = @prsDestinationCountryCode
							and TA1.TABLECODE = 5008 and TA1.TABLETYPE = 50)
					Begin			
						Set @prsFederalTaxCode = @prsEUTaxCode
					End
				End
			End
		End
	End

	-- BASED ON THIS LOOK UP TAX RATES
	-- Federal Tax 
	-- NOTE: federal Tax cannot be Tax On Tax
	If @nErrorCode = 0 AND (@prsFederalTaxCode <> '0')
	Begin
		-- Try and find the tax rate for the specified country
		Set @sSQLString="
		Select @prnFederalTaxRate = RATE,
			@bFederalHarmonised = HARMONISED
			from TAXRATESCOUNTRY
			where TAXCODE = @prsFederalTaxCode
			and COUNTRYCODE = @prsSourceCountryCode"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@prnFederalTaxRate	decimal(11,4)	output,
					  @bFederalHarmonised	bit		output,
					  @prsFederalTaxCode	nvarchar(3),
					  @prsSourceCountryCode	nvarchar(3)',
					  @prnFederalTaxRate	= @prnFederalTaxRate	OUTPUT,
					  @bFederalHarmonised	= @bFederalHarmonised	OUTPUT,
					  @prsFederalTaxCode	= @prsFederalTaxCode,
					  @prsSourceCountryCode	= @prsSourceCountryCode
	
		-- Fall back to the default tax rate
		If @nErrorCode = 0 and @prnFederalTaxRate is NULL
		Begin
			Set @sSQLString="
			Select @prnFederalTaxRate = RATE,
				@bFederalHarmonised = HARMONISED
				from TAXRATESCOUNTRY
				where TAXCODE = @prsFederalTaxCode
				and COUNTRYCODE = 'ZZZ'"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@prnFederalTaxRate	decimal(11,4)	output,
						  @bFederalHarmonised	bit		output,
						  @prsFederalTaxCode	nvarchar(3)',
						  @prnFederalTaxRate	= @prnFederalTaxRate	OUTPUT,
						  @bFederalHarmonised	= @bFederalHarmonised	OUTPUT,
						  @prsFederalTaxCode	= @prsFederalTaxCode
		End
	End
	
	
	-- State Tax
	If @nErrorCode = 0 AND (@prsStateTaxCode<> '0') AND ( @bFederalHarmonised = 0 )
	Begin
		-- Try and find the tax rate for the specified country
		Set @sSQLString="
		Select @prnStateTaxRate = RATE, 
			@prbStateHarmonised = HARMONISED, 
			@prbTaxOnTax = TAXONTAX
			from TAXRATESCOUNTRY
			where TAXCODE = @prsStateTaxCode
			and COUNTRYCODE = @prsSourceCountryCode
			and STATE = @prsSourceState"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@prnStateTaxRate	decimal(11,4)	output,
					  @prbStateHarmonised	bit		output,
					  @prbTaxOnTax		bit		output,
					  @prsStateTaxCode	nvarchar(3),
					  @prsSourceCountryCode	nvarchar(3),
					  @prsSourceState	nvarchar(20)',
					  @prnStateTaxRate	= @prnStateTaxRate	OUTPUT,
					  @prbStateHarmonised	= @prbStateHarmonised	OUTPUT,
					  @prbTaxOnTax		= @prbTaxOnTax		OUTPUT,
					  @prsStateTaxCode	= @prsStateTaxCode,
					  @prsSourceCountryCode	= @prsSourceCountryCode,
					  @prsSourceState	= @prsSourceState
	
	
		-- Fall back to the default tax rate
		If @nErrorCode = 0 and @prnStateTaxRate is NULL
		Begin
			Set @sSQLString="
			Select @prnStateTaxRate = RATE, 
			@prbStateHarmonised = HARMONISED, 
			@prbTaxOnTax = TAXONTAX
			from TAXRATESCOUNTRY
			where TAXCODE = @prsStateTaxCode
			and COUNTRYCODE = 'ZZZ'"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@prnStateTaxRate	decimal(11,4)	output,
						  @prbStateHarmonised	bit		output,
						  @prbTaxOnTax		bit		output,
						  @prsStateTaxCode	nvarchar(3)',
						  @prnStateTaxRate	= @prnStateTaxRate 	OUTPUT,
						  @prbStateHarmonised	= @prbStateHarmonised	OUTPUT,
						  @prbTaxOnTax		= @prbTaxOnTax		OUTPUT,
						  @prsStateTaxCode	= @prsStateTaxCode
		End
	End
End

Return @nErrorCode
go

grant execute on dbo.pt_DeriveMultiTierTax to public
go
