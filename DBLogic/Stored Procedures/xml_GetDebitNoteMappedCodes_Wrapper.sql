-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_GetDebitNoteMappedCodes_Wrapper 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_GetDebitNoteMappedCodes_Wrapper]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_GetDebitNoteMappedCodes_Wrapper.'
	drop procedure dbo.xml_GetDebitNoteMappedCodes_Wrapper
end
print '**** Creating procedure dbo.xml_GetDebitNoteMappedCodes_Wrapper...'
print ''
go

-- Quoted_Identifer must be on to use XML value() functions.
set QUOTED_IDENTIFIER on
go
set ANSI_NULLS on
go

create procedure dbo.xml_GetDebitNoteMappedCodes_Wrapper	
		@ptXMLFilterCriteria		nvarchar(max)	-- The filtering to be performed on the result set.	-- todo make this the first param in the list	
as
---PROCEDURE :	xml_GetDebitNoteMappedCodes_Wrapper
-- VERSION :	1
-- DESCRIPTION:	A wrapper procedure of xml_GetDebitNoteMappedCodes  so that it can be 
--		called by DocGen.  It returns all of the details required on a formatted
--		open item such as a Debit or Credit Note.
--
--		The following details will be returned :
--			OpenItemNo
--			AccountNo
--			LawFirmID
--			YourRef
--			ItemDate
--			RefText
--			TaxLocal
--			TaxForeign
--			CurrencyL
--			LocalValue
--			CurrencyF
--			CurrencyF
--			ForeignValue
--			BillPercentage
--			TaxLabel
--			Tax
--			DebtorName
--			DebtorAddress
--			DebtorAttentionName
--			StatusText
--			CopyToList
--			CopyToAddress
--			CopyToAttention
--			OurRef
--			PurchaseOrderNo
--			StaffName
--			Regarding
--			BillScope
--			Reductions
--			CreditNoteFlag
--			ForeignReductions
--			TaxNumber
--			CopyLabel
--			Image
--			ForeignEquivCurrency
--			ForeignEquivExRate
--			PenaltyInterestRate
--			ItemTypeAbbreviation
--			DueDate
--			LocalTakenUp
--			ForeignTakenUp
--			OpenItemAction
--
--			LawFirmName
--			LawFirmAddress1
--			LawFirmAddress2
--			LawFirmCity
--			LawFirmState
--			LawFirmPostcode
--			LawFirmCountry
--			
--			TaxRate1
--			TaxableAmount1
--			TaxAmount1
--			TaxDescription1
--			TaxRate2
--			TaxableAmount2
--			TaxAmount2
--			TaxDescription2
--			TaxRate3
--			TaxableAmount3
--			TaxAmount3
--			TaxDescription3
--			TaxRate4
--			TaxableAmount4
--			TaxAmount4
--			TaxDescription4
--			
--
--			DisplaySequence
--			DetailChargeRate
--			DetailStaffName
--			DetailDate
--			DetailInternalRef
--			DetailTime
--			DetailWIPCode
--			DetailWIPTypeId
--			DetailCatDesc
--			DetailNarrative
--			DetailValue
--			DetailForeignValue
--			DetailChargeCurrency
--			DetailCaseSequence
--			DetailStaffClass
--			DetailCaseCountryCode
--			DetailCaseCountry
--			DetailCaseTypeDesc
--			DetailPropertyType
--			DetailOfficialNo
--			DetailCaseTitle
--			DetailStaffCode
--			DetailCasePurchaseOrder
--			DetailFeeEarnerName
--			DetailFeeEarnerStaffClass
--			DetailFeeEarnerStaffCode
--
--			DetailFeeEarnerLastName		(surname of employee on the bill detail line)
--			DetailFeeEarnerFirstName	(first name of employee on the bill detail line)
--			DetailTaxTotal			(BILLLINE.LOCALTAX)
--
--			DetailRefDocItem1
--			DetailRefDocItem2
--			DetailRefDocItem3
--			DetailRefDocItem4
--			DetailRefDocItem5
--			DetailRefDocItem6
	
-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 11-05-2011	DL	11300	1	A wrapper procedure of xml_GetDebitNoteMappedCodes_DCC so that it can be called from DocGen
		
set nocount on
set concat_null_yields_null on


Declare	@hDocument 		int 		-- handle to the XML parameter which is the Activity Request row
Declare @ErrorCode		int
Declare @nUserIdentity		int
Declare	@sSQLString		nvarchar(max)


-----------------
-- Initialisation
-----------------
Set @ErrorCode		= 0

-------------------------------------------------
--
--    Get the FILTER of Item to be Extracted
--
-------------------------------------------------

-------------------------------------------------
-- Check for a null value or emptiness of the 
-- @ptXMLFilterCriteria parameter and raise an
-- error before attempting to open the XML document.
-------------------------------------------------
If isnull(@ptXMLFilterCriteria,'') = ''
Begin	
	Raiserror('Activity request row XML parameter is empty.', 16, 1)
	Set 	@ErrorCode = @@Error
End

-------------------------------------------------
-- Collect the key for the Activity Request row 
-- that has been passed as an XML parameter 
-- using OPENXML functionality.
-------------------------------------------------
If @ErrorCode = 0
Begin	
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @ptXMLFilterCriteria
	Set 	@ErrorCode = @@Error
End
-------------------------------------------------
-- Now select the key from the xml, at the same 
-- time joining it to the ACTIVITYREQUEST table.
-------------------------------------------------
If @ErrorCode = 0
Begin
	Set @sSQLString='
	select 	@nUserIdentity = IDENTITYID
		from openxml(@hDocument,''ACTIVITYREQUEST'',2)
		with ACTIVITYREQUEST'
	Exec @ErrorCode=sp_executesql @sSQLString,
		N'@nUserIdentity		int     		OUTPUT,
		  @hDocument			int',
		  @nUserIdentity		= @nUserIdentity		OUTPUT,
		  @hDocument 			= @hDocument
End

-- remove the document.
Exec sp_xml_removedocument @hDocument 


If @ErrorCode = 0
Begin
	EXEC	@ErrorCode = [dbo].[xml_GetDebitNoteMappedCodes]
			@pnUserIdentityId = @nUserIdentity,
			@ptXMLFilterCriteria = @ptXMLFilterCriteria
End


return @ErrorCode
go

grant execute on dbo.xml_GetDebitNoteMappedCodes_Wrapper  to public
go

