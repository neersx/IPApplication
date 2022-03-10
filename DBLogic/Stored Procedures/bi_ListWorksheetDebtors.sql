-----------------------------------------------------------------------------------------------------------------------------
-- Creation of bi_ListWorksheetDebtors
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[bi_ListWorksheetDebtors]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.bi_ListWorksheetDebtors.'
	Drop procedure [dbo].[bi_ListWorksheetDebtors]
	Print '**** Creating Stored Procedure dbo.bi_ListWorksheetDebtors...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.bi_ListWorksheetDebtors
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,	-- The key of the case being billed.
	@pnWipNameKey		int		= null, -- The key of the name being billed (for WIP recorded directly against a name only).
	@pbIsRenewalDebtor	bit		= null,	-- Indicates whether the information should be extracted for the renewal debtor or the main debtor.	
	@pbCalledFromCentura	bit		= 0
)
AS 
-- PROCEDURE:	bi_ListWorksheetDebtors
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro.net
-- DESCRIPTION:	This stored procedure produces result set containing the debtor information 
--		for the Billing Worksheet Report. This contains a row for each debtor of 
--		the case/name being billed.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 28 Apr 2005  TM	RFC2554	1	Procedure created. 
-- 02 May 2005	TM	RFC1554	2	There is no need to call wp_FilterWip. Remove @ptXMLFilterCriteria parameter, 
--					and receive the necessary information as specific parameters.
-- 15 May 2005  JEK	RFC2508	3	Pass @sLookupCulture to fn_FilterUserXxx.
-- 11 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 02 Nov 2015	vql	R53910	5	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)

Declare	@sNameTypeKey 		nvarchar(3)

Declare @idoc 			int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

Set     @nErrorCode = 0			

-- Set the Debtor type
If @nErrorCode=0
Begin	
	Set @sNameTypeKey	= CASE 	WHEN @pbIsRenewalDebtor = 1
					THEN 'Z'
					ELSE 'D'
				  END
End

If  @nErrorCode = 0
and @pnCaseKey is not null
Begin
	Set @sSQLString = " 
	Select	CN.NAMENO			as DebtorKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, coalesce(N.NAMESTYLE,NAT.NAMESTYLE,7101))
						as DebtorName,				
		N.NAMECODE			as DebtorCode,
		dbo.fn_FormatAddress(BA.STREET1, BA.STREET2, BA.CITY, BA.STATE, BS.STATENAME, BA.POSTCODE, BC.POSTALNAME, BC.POSTCODEFIRST, BC.STATEABBREVIATED, BC.POSTCODELITERAL, BC.ADDRESSSTYLE)					
		    				as DebtorAddress,		
		dbo.fn_FormatNameUsingNameNo(N2.NAMENO, coalesce(N2.NAMESTYLE,NAT2.NAMESTYLE,7101))
						as DebtorAttention,
		CN.REFERENCENO			as YourReference,
		ISNULL(C.PURCHASEORDERNO, IP.PURCHASEORDERNO)
		 				as PurchaseOrderNo,
		CASE 	WHEN SC2.COLBOOLEAN = 1
			THEN SC.COLCHARACTER 	
			ELSE ISNULL(IP.CURRENCY, SC.COLCHARACTER)
		END
						as BillCurrencyCode,		
		CN.BILLPERCENTAGE		as BillPercent
		from CASENAME CN
		join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null, 0,@pbCalledFromCentura) NT
						on (NT.NAMETYPE=CN.NAMETYPE)		
		join NAME N			on (N.NAMENO=CN.NAMENO)
		left join COUNTRY NAT		on (NAT.COUNTRYCODE=N.NATIONALITY)
		-- Debtor/Renewal Debtor Attention
		left join ASSOCIATEDNAME AN2	on (AN2.NAMENO = CN.INHERITEDNAMENO
						and AN2.RELATIONSHIP = CN.INHERITEDRELATIONS
						and AN2.RELATEDNAME = CN.NAMENO
						and AN2.SEQUENCE = CN.INHERITEDSEQUENCE)
		left join ASSOCIATEDNAME AN3	on (AN3.NAMENO = CN.NAMENO
						and AN3.RELATIONSHIP = N'BIL'
						and AN3.NAMENO = AN3.RELATEDNAME
						and AN2.NAMENO is null)"
		-- For Debtor and Renewal Debtor (name types 'D' and 'Z') Attention and Address should be 
		-- extracted in the same manner as billing (SQA7355):
		-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed;
		-- 2)	If the debtor was inherited from the associated name then the details recorded against this 
		--      associated name will be returned; if the debtor was not inherited then go to the step 3;
		-- 3)	Check if the Address/Attention has been overridden on the AssociatedName table with 
		--	Relationship = 'BIL' and NameNo = RelatedName; if no information was found then go to the step 4; 
		-- 4)	Extract the Attention and Address details stored against the Name as the PostalAddress 
		--	and MainContact.
		Set @sSQLString = @sSQLString + " 
		left join NAME N2		on (N2.NAMENO = COALESCE(CN.CORRESPONDNAME, AN2.CONTACT, AN3.CONTACT, N.MAINCONTACT))
		left join COUNTRY NAT2		on (NAT2.COUNTRYCODE=N2.NATIONALITY)
		-- Debtor/Renewal Debtor Address
		left join ADDRESS BA 		on (BA.ADDRESSCODE = COALESCE(CN.ADDRESSCODE, AN2.POSTALADDRESS,AN3.POSTALADDRESS, N.POSTALADDRESS))
		left join COUNTRY BC		on (BC.COUNTRYCODE = BA.COUNTRYCODE)
		left join STATE   BS		on (BS.COUNTRYCODE = BA.COUNTRYCODE
			 	           	and BS.STATE = BA.STATE)
		left join IPNAME IP		on (IP.NAMENO = CN.NAMENO)
		left join CASES C		on (C.CASEID = CN.CASEID) 
		left join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY')
		left join SITECONTROL SC2 	on (SC2.CONTROLID= 'Bill Foreign Equiv')
		where CN.CASEID = @pnCaseKey
		and   CN.EXPIRYDATE IS NULL    
		and   CN.NAMETYPE = @sNameTypeKey
		order by CN.SEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @sNameTypeKey		nvarchar(3)',
					  @pnCaseKey		= @pnCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,	
					  @psCulture		= @psCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @sNameTypeKey		= @sNameTypeKey
	Set @pnRowCount=@@Rowcount	
End
Else If  @nErrorCode = 0
     and @pnWipNameKey is not null
Begin
	Set @sSQLString = " 
	Select	N.NAMENO			as DebtorKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, coalesce(N.NAMESTYLE,NAT.NAMESTYLE,7101))
						as DebtorName,				
		N.NAMECODE			as DebtorCode,
		dbo.fn_FormatAddress(BA.STREET1, BA.STREET2, BA.CITY, BA.STATE, BS.STATENAME, BA.POSTCODE, BC.POSTALNAME, BC.POSTCODEFIRST, BC.STATEABBREVIATED, BC.POSTCODELITERAL, BC.ADDRESSSTYLE)					
		    				as DebtorAddress,		
		dbo.fn_FormatNameUsingNameNo(N2.NAMENO, coalesce(N2.NAMESTYLE,NAT2.NAMESTYLE,7101))
						as DebtorAttention,
		NULL				as YourReference,
		IP.PURCHASEORDERNO		as PurchaseOrderNo,
		CASE 	WHEN SC2.COLBOOLEAN = 1
			THEN SC.COLCHARACTER 	
			ELSE ISNULL(IP.CURRENCY, SC.COLCHARACTER)
		END
						as BillCurrencyCode,		
		100				as BillPercent
	from NAME N	
	left join COUNTRY NAT		on (NAT.COUNTRYCODE=N.NATIONALITY)
	left join NAME N2		on (N2.NAMENO = N.MAINCONTACT)
	left join COUNTRY NAT2		on (NAT2.COUNTRYCODE=N2.NATIONALITY)
	-- Debtor/Renewal Debtor Address
	left join ADDRESS BA 		on (BA.ADDRESSCODE = N.POSTALADDRESS)
	left join COUNTRY BC		on (BC.COUNTRYCODE = BA.COUNTRYCODE)
	left join STATE   BS		on (BS.COUNTRYCODE = BA.COUNTRYCODE
		 	           	and BS.STATE = BA.STATE)
	left join IPNAME IP		on (IP.NAMENO = N.NAMENO)
	left join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY')
	left join SITECONTROL SC2 	on (SC2.CONTROLID= 'Bill Foreign Equiv')
	where N.NAMENO = @pnWipNameKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnWipNameKey   	int,
					  @pnUserIdentityId 	int,
					  @psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @pnWipNameKey		= @pnWipNameKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,	
					  @psCulture		= @psCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura
	Set @pnRowCount=@@Rowcount	
End


Return @nErrorCode
GO

Grant execute on dbo.bi_ListWorksheetDebtors to public
GO
