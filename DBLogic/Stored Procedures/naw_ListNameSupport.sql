-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameSupport.'
	Drop procedure [dbo].[naw_ListNameSupport]
	Print '**** Creating Stored Procedure dbo.naw_ListNameSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListNameSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) 	= null,		-- Is the comma separated list of requested tables (e.g.'NameType,NameCategory')
	@pnNameKey		int		=null
)
AS
-- PROCEDURE:	naw_ListNameSupport
-- VERSION:	11
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of valid values for the requested tables. Allows the calling code to request multiple tables in one round trip.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 19-Dec-2003	TM	RFC611	2	Remove the @pnCaseKey and @pnCaseAccessMode. Change 'BadDebtor' to Restrictions 
-- 06-Jan-2003	TM	RFC611	3	Change the name expected in @psTables for the following:
--					TextType => NameTextType, AttributeType => NameAttributeType
-- 07-Sep-2004	TM	RFC1158	4	Implement the following new support tables: StaffClassification, ProfitCentre,
--					SupplierType, SupplierRestriction, PaymentTerms, PayablePaymentMethod.
-- 19-May-2006	SW	RFC3492	5	Implement the following new support tables: NamePresentationStyle,
--					CapacityToSign, Title, Printer
-- 16-Nov-2006 	PG	RFC4341 6 	Add @pnNameKey
-- 11-Oct-2007 	PG	RFC3501 7 	Pass @pnNameKey to naw_ListRelationships. Add PositionCategory entry point
-- 26-Nov-2007 	vql	RFC5740 8	Add Job Role pick list.
-- 29-Nov-2007 	PG	RFC3497 9	Add Address Type, Address Status
-- 13-May-2011  MS  RFC7998 10  Add PurchaseTaxTreatment, BankAccount
-- 11 Apr 2013	DV	R13270	11	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@ErrorCode		int
Declare @nRowCount		int

Declare @nRow			smallint	-- Is used to point to the current stored procedure
Declare	@sProc			nvarchar(254)	-- Current stored procedure name	
Declare @sParams		varchar(1000)	-- Current parameters list
Declare @nTableTypeKey		nchar(5)	-- @pnTableType parameter value to call the ipw_ListTableCodes    

-- Initialise variables
Set @nRow			= 1		

Set @nRowCount			= 0
Set @ErrorCode			= 0

While @nRow is not null
and @ErrorCode = 0
Begin
	-- Extruct the stored procedure's name from the @psTables comma separated string using function fn_Tokenise
	
	Select 	@sProc =
		CASE Parameter
			WHEN 'NameType'			THEN 'ipw_ListNameTypes'
			-- For NameCategory, BillingFrequency and DebtorType concatenate corresponding TableType 
			-- (i.e. '6', '75' and '7') required to call ipw_ListTableCodes
			WHEN 'NameCategory'		THEN 'ipw_ListTableCodes6'
			WHEN 'NameTextType'		THEN 'naw_ListTextTypes'
			WHEN 'Restrictions'		THEN 'naw_ListRestrictions'
			WHEN 'Relationship'		THEN 'naw_ListRelationships'
			WHEN 'AliasType'		THEN 'naw_ListAliasTypes'
			WHEN 'StandingInstructions'	THEN 'ipw_ListInstructions'
			WHEN 'NameAttributeType'	THEN 'naw_ListAttributeTypes'
			WHEN 'Currency'			THEN 'ac_ListCurrencies'
			WHEN 'BillingFrequency'		THEN 'ipw_ListTableCodes75'
			WHEN 'DebtorType'		THEN 'ipw_ListTableCodes7'
			WHEN 'TaxTreatment'		THEN 'ac_ListTaxRates'
			WHEN 'StaffClassification'	THEN 'ipw_ListTableCodes15'
			WHEN 'ProfitCentre'		THEN 'ac_ListProfitCentres'
			WHEN 'SupplierType'		THEN 'ipw_ListTableCodes79'
			WHEN 'SupplierRestriction'	THEN 'naw_ListCRRestrictions'
			WHEN 'PaymentTerms'		THEN 'ac_ListFrequencies'
			WHEN 'PayablePaymentMethod'	THEN 'ac_ListPaymentMethods8'
			WHEN 'NamePresentationStyle'	THEN 'ipw_ListTableCodes71'
			WHEN 'CapacityToSign'		THEN 'ipw_ListTableCodes35'
			WHEN 'Title'			THEN 'naw_ListTitles'
			WHEN 'Printer'			THEN 'ipw_ListResources0'
			WHEN 'PositionCategory'	        THEN 'ipw_ListTableCodes45'
			WHEN 'JobRole'		        THEN 'ipw_ListTableCodes18'
			WHEN 'AddressType'		THEN 'ipw_ListTableCodes3'
			WHEN 'AddressStatus'		THEN 'ipw_ListTableCodes48'
                        WHEN 'PurchaseTaxTreatment'     THEN 'ipw_ListTableCodes80'
                        WHEN 'BankAccount'              THEN 'acw_ListBankAccounts'
			ELSE NULL
		END	
	from fn_Tokenise (@psTables, NULL)
	where InsertOrder = @nRow

	Set @nRowCount = @@Rowcount

	-- If the dataset name is valid build the string to execute required stored procedure
	If (@nRowCount > 0)
	Begin
		If @sProc is not null
		Begin
			-- Build the parameters

			Set @sParams = '@pnUserIdentityId=' + CAST(@pnUserIdentityId as varchar(11)) 

			If @psCulture is not null
			Begin
				Set @sParams = @sParams + ", @psCulture='" + @psCulture + "'"
			End

			If @sProc like 'ipw_ListTableCodes%'  
			Begin
				-- For the ipw_ListTableCodes the @pnTableTypeKey is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnTableTypeKey = ' + substring(@sProc, 19, 5)

				-- Cut off the @pnTableTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListTableCodes' 
				Set @sProc = substring(@sProc, 1, 18)  
			End

			If @sProc like 'ac_ListPaymentMethods%'  
			Begin
				-- For the ac_ListPaymentMethods the @pnUsedByFlags is concatenated at the end of 
				-- the @sProc string so cut it off it and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnUsedByFlags = ' + substring(@sProc, 22, 5)

				-- Cut off the @pnUsedByFlags from the end of the @sProc to get the actual
				-- @sProc = 'ac_ListPaymentMethods' 
				Set @sProc = substring(@sProc, 1, 21)  
			End


			If @sProc like 'ipw_ListResources%' 
			Begin
				-- For the ipw_ListResources the @pnResourceTypeKey is concatenated at the end of 
				-- the @sProc string so cut it off and pass it to the stored procedure: 				

				Set @sParams = @sParams + ', @pnResourceTypeKey = ' + substring(@sProc, 18, 5)

				-- Cut off the @pnResourceTypeKey from the end of the @sProc to get the actual
				-- @sProc = 'ipw_ListResources' 
				Set @sProc = substring(@sProc, 1, 17)  
			End

			If ((@sProc like 'naw_ListAttributeTypes') or (@sProc like 'naw_ListRelationships'))
			Begin
				If @pnNameKey is not null
				Begin
					Set @sParams = @sParams + ', @pnNameKey = ' + cast(@pnNameKey as nvarchar)
				End
			End
			
			Exec (@sProc + ' ' + @sParams)	

			Set @ErrorCode=@@Error		
		End

		-- Increment @nRow by one so it points to the next dataset name
		
		Set @nRow = @nRow + 1
	End
	Else 
	Begin
		-- If the dataset name is not valid then exit the 'While' loop
	
		Set @nRow = null
	End

End

RETURN @ErrorCode
GO

Grant execute on dbo.naw_ListNameSupport to public
GO
