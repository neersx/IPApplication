-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDefaultTaxCodeForWIP
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetDefaultTaxCodeForWIP') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetDefaultTaxCodeForWIP.'
	drop function dbo.fn_GetDefaultTaxCodeForWIP
	print '**** Creating function dbo.fn_GetDefaultTaxCodeForWIP...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetDefaultTaxCodeForWIP
	(
		@pnCaseKey	int = null,
		@pnWIPCode	nvarchar(6),
		@pnDebtorKey	int = null, -- only applicable for single-debtor debit notes
		@pnStaffKey		int = null, -- applicable when sitecontrol Tax Code for EU billing is set
		@pnEntityKey	int = null -- applicatble only when sitecontrol Tax Source Country derived from Entity is set
	)
Returns nvarchar(3)

-- FUNCTION :	fn_GetDefaultTaxCodeForWIP
-- VERSION :	5
-- DESCRIPTION:	This function returns the default tax for a WIP Item

-- Date		Who	Number		Version	Description
-- ===========	===	======		=======	==========================================
-- 20 Jan 2010	AT 	RFC3605		1	Function created.
-- 21 Dec 2010	AT	RFC10042	2	Added Debtor Key.
-- 08 Jun 2011	AT	RFC10791	3	Fixed Debtor Key null check.
-- 15 Feb 2018	AK	RFC72937	4	applied check to return tax code when sitecontrol Tax Code for EU billing is set.
-- 06 Mar 2018	AK	RFC73598	5	Tax code for EU will take preference over tax code set against Case or WIP.
-- 13 Jul 2018  AK	RFC74498	6	Corrected the tax preference and exempt will take preference over EU.

AS
Begin

Declare @sSQLString nvarchar(1000)
Declare @nErrorCode	int

Declare @sReturnTaxCode nvarchar(3)
Declare @sCaseTaxCode nvarchar(3)
Declare @sWIPTaxCode nvarchar(3)
Declare @sDebtorTaxCode nvarchar(3)
Declare @sEUTaxCode nvarchar(3)
Declare @nSourceContryFromEntity bit

Declare @sDebtorCountryCode 	nvarchar(3)
Declare @sVatNo 		nvarchar(30)
Declare @sStaffCountryCode 	nvarchar(3)

Set @nErrorCode = 0

-- Get the Debtor Tax Code
If (@nErrorCode = 0 and @pnDebtorKey is not null)
Begin
	Select @sDebtorTaxCode = IPN.TAXCODE
	From IPNAME IPN 
	Where IPN.NAMENO = @pnDebtorKey
End

-- Get the WIP Tax Code
If (@nErrorCode = 0)
Begin
	Select @sWIPTaxCode = WT.TAXCODE
	From WIPTEMPLATE WT 
	Where WT.WIPCODE = @pnWIPCode
End

-- Get the Case tax code
If (@nErrorCode = 0 and @pnCaseKey is not null)
Begin
	Select @sCaseTaxCode = C.TAXCODE
	FROM CASES C
	where CASEID = @pnCaseKey
End

If (@sDebtorTaxCode = '0' or @sWIPTaxCode = '0'  or @sCaseTaxCode = '0')
Begin
	-- If any are exempt, return exempt.
	Set @sReturnTaxCode = '0'
	return @sReturnTaxCode
End
Else
Begin
	
	Select @nSourceContryFromEntity=COLBOOLEAN
		from	SITECONTROL
		where	CONTROLID = 'Tax Source Country Derived from Entity'
	Set @nErrorCode = @@ERROR

	Select @sEUTaxCode=COLCHARACTER
		from	SITECONTROL
		where	CONTROLID = 'Tax Code for EU billing'
	Set @nErrorCode = @@ERROR

	If @nErrorCode=0 
	Begin 
		-- Check that the site control is filled in
		If @sEUTaxCode is not null and len(@sEUTaxCode) > 0
		Begin

			Select  @sDebtorCountryCode = A.COUNTRYCODE, 
				@sVatNo=N.TAXNO
				from NAME N
				join ADDRESS A on (A.ADDRESSCODE=N.POSTALADDRESS)
				where N.NAMENO = @pnDebtorKey
			Set @nErrorCode = @@ERROR		
		
			if @nErrorCode = 0 and @pnStaffKey is not null and @nSourceContryFromEntity = 0
			begin
				Select @sStaffCountryCode = COUNTRYCODE 
				from OFFICE O
				join TABLEATTRIBUTES TA
					on TA.PARENTTABLE = 'NAME'
					and TA.TABLETYPE = 44
					and TA.TABLECODE = O.OFFICEID
				where TA.GENERICKEY = cast(@pnStaffKey as nvarchar(20))
				Set @nErrorCode = @@ERROR
			end
			Else
			Begin
				if @nErrorCode = 0 and @pnEntityKey is not null and @nSourceContryFromEntity = 1
				begin
					SELECT @sStaffCountryCode = ISNULL(N.NATIONALITY , A.COUNTRYCODE)
					FROM NAME N
					JOIN ADDRESS A ON (A.ADDRESSCODE = N.STREETADDRESS)
					WHERE N.NAMENO = @pnEntityKey
					Set @nErrorCode = @@ERROR
				end
			End
									
			If @nErrorCode = 0 
				and (@sDebtorCountryCode != @sStaffCountryCode)
				and @sVatNo is not null
			Begin
				-- Check that both countries are in the EU
				If exists(Select * from TABLEATTRIBUTES TA1
					join TABLEATTRIBUTES TA2 on TA2.PARENTTABLE = 'COUNTRY'
							and TA2.GENERICKEY = @sStaffCountryCode 
							and TA2.TABLECODE = 5008 and TA2.TABLETYPE = 50
					where TA1.PARENTTABLE = 'COUNTRY' 
						and TA1.GENERICKEY = @sDebtorCountryCode
						and TA1.TABLECODE = 5008 and TA1.TABLETYPE = 50)
				Begin
					Set @sReturnTaxCode = @sEUTaxCode
					return @sReturnTaxCode
				End	
			End
		End
	End		
	-- Otherwise, debtor tax, then case tax code has priority
	Set @sReturnTaxCode = coalesce(@sDebtorTaxCode, @sCaseTaxCode, @sWIPTaxCode)
End

Return @sReturnTaxCode

End
go

grant execute on dbo.fn_GetDefaultTaxCodeForWIP to public
GO
