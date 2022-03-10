-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.cwb_ListNameSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListNameSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListNameSummary.'
	Drop procedure [dbo].[cwb_ListNameSummary]
	Print '**** Creating Stored Procedure dbo.cwb_ListNameSummary...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListNameSummary
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int, 		-- Mandatory
	@pnCaseKey		int		= null,
	@psNameTypeKey		nvarchar(3)	= null,
	@pnCaseNameSequence	int		= null,
	@pbCalledFromCentura	bit		= 0	
)
AS
-- PROCEDURE:	cwb_ListNameSummary
-- VERSION:	12
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates NameSummaryExternalData dataset. Provides a summary of
--		appropriate information for names.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 01-Sep-2003  TM		1	Procedure created
-- 04-Oct-2003	TM	RFC581	2	Design an approach for displaying an image using data from database.
--					IMAGEID is returned instead of IMAGEDATA as ImageKey.
-- 05-Nov-2003	TM	RFC581	3	Design an approach for displaying an image using data from database.
--					Remove join to the IMAGE table.
-- 26-Nov-2003	TM	RFC645	4	Implement the 'derived table' approach for the MainEmail 
-- 10-Mar-2004	TM	RFC868	5	Modify the logic extracting the 'MainEmail' column to use new Name.MainEmail column. 
-- 25-May-2004	TM	RFC863	6	For the @psNameTypeKey = 'D' or 'Z' extract the ContactKey, ContactName, 
--					and CaseAddress in the same manner as billing (SQA7355).
-- 31-May-2004	TM	RFC863	7	Improve the commenting of SQL extracting the Billing Address/Attention.
-- 28-Sep-2004	TM	RFC1806	8	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.
-- 02-Mar-2006	LP	RFC3216	9	Add a new NameCode column in the Name result set.
--					Implement a call to naw_ListNameAlias to populate Alias result set.
-- 22-Jul-2008	AT	RFC5788	10	Return CRM Only flag.
-- 15-Jul-2009	KR	RFC8109	11	Added Search Key 1 and Search Key 2 to the select.
-- 10 Nov 2015	KR	R53910	12	Adjust formatted names logic (DR-15543)     



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int

Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

Set 	@nErrorCode 	= 0
Set 	@pnRowCount	= 0

-- Populating NameSummaryExternalData dataset 

-- check if the name is CRM Only
	declare @sCRMNameTypes nvarchar(1000)
	declare @bIsCRMOnly bit

	set @sSQLString = "
		select @sCRMNameTypes = isnull(@sCRMNameTypes,'') +
			case when (@sCRMNameTypes is not null) then ',' else '' end + ''''+NAMETYPE+''''
			from NAMETYPE WHERE PICKLISTFLAGS&32=32"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@sCRMNameTypes 	nvarchar(1000) output',
				  @sCRMNameTypes	= @sCRMNameTypes output

	if (@sCRMNameTypes is not null and @nErrorCode=0)
	Begin
	set @sSQLString = "	
		select @bIsCRMOnly =
			case when (
				exists(Select 1
				from NAMETYPECLASSIFICATION 
				WHERE NAMENO=@pnNameKey
				and NAMETYPE IN (" + @sCRMNameTypes + ")
				and ALLOW=1)
				  and
				not exists(Select 1
				from NAMETYPECLASSIFICATION 
				WHERE NAMENO=@pnNameKey
				and NAMETYPE NOT IN (" + @sCRMNameTypes + ")
				and ALLOW=1)
			) then 1 else 0 end"
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey	int,
				  @bIsCRMOnly 	bit output',
				  @pnNameKey	= @pnNameKey,
				  @bIsCRMOnly	= @bIsCRMOnly output
	End




If @nErrorCode = 0
Begin
	set @sSQLString=
	"Select N.NAMENO 	as 'NameKey',"+char(10)+
	-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
	-- fn_FormatName, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+char(10)+ 
	"			as 'Name', "+char(10)+ 
	"N.NAMECODE		as 'NameCode', "+char(10)+
	"N1.NAMENO 		as 'ContactKey',"+char(10)+
	"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101))"+char(10)+ 
	"			as 'ContactName',"+char(10)+
	-- Street Address is only populated if it is different from the Postal Address.
	"CASE WHEN N.POSTALADDRESS = N.STREETADDRESS"+char(10)+
	"     THEN NULL"+char(10)+
	"     ELSE dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, SC.POSTALNAME, SC.POSTCODEFIRST, SC.STATEABBREVIATED,  SC.POSTCODELITERAL, SC.ADDRESSSTYLE)"+char(10)+
	"END			as 'StreetAddress',"+char(10)+
	"dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, PS.STATENAME, PA.POSTCODE, PC.POSTALNAME, PC.POSTCODEFIRST, PC.STATEABBREVIATED, PC.POSTCODELITERAL, PC.ADDRESSSTYLE)"+char(10)+
	"			as 'PostalAddress',"+char(10)+
	-- If linked from a CaseName, use any overriding address against the case. Null if there is no data to display.
	"CASE WHEN CA.ADDRESSCODE IS NOT NULL"+char(10)+
	"     THEN dbo.fn_FormatAddress(CA.STREET1, CA.STREET2, CA.CITY, CA.STATE, CS.STATENAME, CA.POSTCODE, CC.POSTALNAME, CC.POSTCODEFIRST, CC.STATEABBREVIATED, CC.POSTCODELITERAL, CC.ADDRESSSTYLE)"+char(10)+
	"     ELSE NULL"+char(10)+
	"END			as 'CaseAddress',"+char(10)+
	"dbo.fn_FormatTelecom(PH.TELECOMTYPE, PH.ISD, PH.AREACODE, PH.TELECOMNUMBER, PH.EXTENSION)"+char(10)+
	"			as 'MainPhone',"+char(10)+
	"dbo.fn_FormatTelecom(FX.TELECOMTYPE, FX.ISD, FX.AREACODE, FX.TELECOMNUMBER, FX.EXTENSION)"+char(10)+
	"			as 'MainFax',"+char(10)+
	"dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION)"+char(10)+
	"			as 'MainEmail',"+char(10)+
	"I.IMAGEID		as 'ImageKey',"+char(10)+
	"isnull(@bIsCRMOnly,0)	as 'IsCRMOnly',"+char(10)+
	"N.SEARCHKEY1		as 'SearchKey1',"+CHAR(10)+
	"N.SEARCHKEY2		as 'SearchKey2'"+CHAR(10)+
	"from NAME N"+char(10)+ 
	"left join COUNTRY NN	        on (NN.COUNTRYCODE  = N.NATIONALITY)"+char(10)+
	-- Names linked from cases will provide @pnNameKey, @pnCaseKey, @psNameTypeKey 
	-- and @pnCaseNameSequence parameters. Otherwise, the @pnNameKey is provided.  
	"left join CASENAME CN		on (CN.NAMENO = N.NAMENO"+char(10)+
	"				and CN.CASEID = @pnCaseKey"+char(10)+
	"				and CN.NAMETYPE = @psNameTypeKey"+char(10)+
	"				and CN.SEQUENCE = @pnCaseNameSequence)"+char(10)
	-- For Debtor and Renewal Debtor (name types 'D' and 'Z') ContactName and CaseAddress should be 
	-- extracted in the same manner as billing (SQA7355):
	-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed;
	-- 2)	If the debtor was inherited from the associated name then the details recorded against this 
	--      associated name will be returned; if the debtor was not inherited then go to the step 3;
	-- 3)	Check if the Address/Attention has been overridden on the AssociatedName table with 
	--	Relationship = 'BIL' and NameNo = RelatedName; if no information was found then go to the step 4; 
	-- 4)	Extract the ContactName and CaseAddress details stored against the Name as the PostalAddress 
	--	and MainContact.
	If @psNameTypeKey in ('D', 'Z')
	Begin
		Set @sSQLString = @sSQLString +
		"left join ASSOCIATEDNAME AN1	on (AN1.NAMENO = CN.INHERITEDNAMENO"+char(10)+
	    	"				and AN1.RELATIONSHIP = CN.INHERITEDRELATIONS"+char(10)+
	    	"				and AN1.RELATEDNAME = CN.NAMENO"+char(10)+
		"				and AN1.SEQUENCE = CN.INHERITEDSEQUENCE)"+char(10)+
		"left join ASSOCIATEDNAME AN2	on (AN2.NAMENO = CN.NAMENO"+char(10)+
		"				and AN2.RELATIONSHIP = N'BIL'"+char(10)+
		"				and AN2.NAMENO = AN2.RELATEDNAME"+char(10)+
		"				and AN1.NAMENO is null)"+char(10)+
		"left join NAME N1		on (N1.NAMENO = COALESCE(CN.CORRESPONDNAME, AN1.CONTACT, AN2.CONTACT, N.MAINCONTACT))"+char(10)+
		-- Case Address details
		"left join ADDRESS CA 		on (CA.ADDRESSCODE = COALESCE(CN.ADDRESSCODE, AN1.POSTALADDRESS, AN2.POSTALADDRESS, N.POSTALADDRESS))"+char(10)+
		"left join COUNTRY CC		on (CC.COUNTRYCODE = CA.COUNTRYCODE)"+char(10)+
		"left join STATE CS		on (CS.COUNTRYCODE = CA.COUNTRYCODE"+char(10)+
		" 	           	 	and CS.STATE = CA.STATE)"+char(10)
	End
	-- For name types that are not Debtor (Name type = 'D') or Renewal Debtor ('Z')
	-- ContactName and CaseAddress are obtained as the following:
	-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed; 
	-- 2)	Extract the ContactName and CaseAddress details stored against the Name as the PostalAddress 
	--	and MainContact.
	Else Begin
		Set @sSQLString = @sSQLString +
		-- Use CaseName.CorrespondName as 'ContactName'. If not found, use Name.MainContact for Namekey. 
		"left join NAME N1		on (N1.NAMENO = CASE WHEN CN.CORRESPONDNAME IS NOT NULL"+char(10)+
		"						     THEN CN.CORRESPONDNAME ELSE N.MAINCONTACT END)"+char(10)+
		-- Case Address details
		"left join ADDRESS CA 		on (CA.ADDRESSCODE = CN.ADDRESSCODE)"+char(10)+
		"left join COUNTRY CC		on (CC.COUNTRYCODE = CA.COUNTRYCODE)"+char(10)+
		"left Join STATE CS		on (CS.COUNTRYCODE = CA.COUNTRYCODE"+char(10)+
		" 	           	 	and CS.STATE = CA.STATE)"+char(10)
	End

	Set @sSQLString = @sSQLString +
	"left join COUNTRY NN1	        on (NN1.COUNTRYCODE = N1.NATIONALITY)"+char(10)+
	-- Postal Address details 
	"left join ADDRESS PA 		on (PA.ADDRESSCODE = N.POSTALADDRESS)"+char(10)+
	"left join COUNTRY PC		on (PC.COUNTRYCODE = PA.COUNTRYCODE)"+char(10)+
	"left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE"+char(10)+
	" 	           	 	and PS.STATE = PA.STATE)"+char(10)+
	-- Street Address details
	"left join ADDRESS SA 		on (SA.ADDRESSCODE = N.STREETADDRESS)"+char(10)+
	"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+char(10)+
	"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+char(10)+
	" 	           	 	and SS.STATE = SA.STATE)"+char(10)+	
	-- Telecommunication details
	"left join TELECOMMUNICATION PH on (PH.TELECODE = N.MAINPHONE)"+char(10)+
	"left join TELECOMMUNICATION FX	on (FX.TELECODE = N.FAX)"+char(10)+
	"left join TELECOMMUNICATION M	on (M.TELECODE  = N.MAINEMAIL)"+char(10)+	
	"left join NAMEIMAGE I		on (I.IMAGEID = (select min(NI.IMAGEID)"+char(10)+
	"					         from  NAMEIMAGE NI"+char(10)+
	"					         where NI.NAMENO = N.NAMENO)) "+char(10)+
	"where N.NAMENO = @pnNameKey"

	exec @nErrorCode = sp_executesql @sSQLString,	
					      N'@pnNameKey		int,
						@pnCaseKey		int,
						@psNameTypeKey		nvarchar(3),
						@pnCaseNameSequence	int,
						@bIsCRMOnly		bit',
						@pnNameKey 		= @pnNameKey,
						@pnCaseKey		= @pnCaseKey,
						@psNameTypeKey		= @psNameTypeKey,
						@pnCaseNameSequence	= @pnCaseNameSequence,
						@bIsCRMOnly		= @bIsCRMOnly

	Set @pnRowCount=@@Rowcount
End

-- Populating Alias result set
If @nErrorCode = 0
Begin
	exec @nErrorCode = naw_ListNameAlias   @pnUserIdentityId 	= @pnUserIdentityId,
					       @psCulture 	 	= @sLookupCulture,
					       @pnNameKey 	 	= @pnNameKey,
					       @pbCalledFromCentura 	= @pbCalledFromCentura
End

Return @nErrorCode
GO

Grant execute on dbo.cwb_ListNameSummary to public
GO



 
