-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_HasDebtorSatisfyEUBilling
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_HasDebtorSatisfyEUBilling') and xtype='FN')
begin
	print '**** Drop function dbo.fn_HasDebtorSatisfyEUBilling.'
	drop function dbo.fn_HasDebtorSatisfyEUBilling
	print '**** Creating function dbo.fn_HasDebtorSatisfyEUBilling...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_HasDebtorSatisfyEUBilling
	(		
		@pnDebtorKey	int = null, 
		@pnStaffKey		int = null,
		@pnEntityKey	int = null 
	)
Returns nvarchar(3)

-- FUNCTION :	fn_HasDebtorSatisfyEUBilling
-- VERSION :	1
-- DESCRIPTION:	This function returns 1 the if provided debtor satisfy EU billing condition

-- Date		Who	Number		Version	Description
-- ===========	===	======		=======	==========================================
-- 07 Mar 2018	AK 	RFC73598		1	Function created.
-- 04 Oct 2018  AK  R74005			2   included  @pnEntityKey as function paramater

AS
Begin

Declare @sSQLString nvarchar(1000)
Declare @nErrorCode	int

Declare @sReturnTaxCode bit = 0

Declare @sEUTaxCode nvarchar(3)
Declare @nSourceContryFromEntity bit

Declare @sDebtorCountryCode 	nvarchar(3)
Declare @sVatNo 		nvarchar(30)
Declare @sStaffCountryCode 	nvarchar(3)

Set @nErrorCode = 0	

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
					Set @sReturnTaxCode = 1
					return @sReturnTaxCode
				End	
			End
		End
	
		Set @sReturnTaxCode = 0
	End
	

Return @sReturnTaxCode

End
go

grant execute on dbo.fn_HasDebtorSatisfyEUBilling to public
GO
