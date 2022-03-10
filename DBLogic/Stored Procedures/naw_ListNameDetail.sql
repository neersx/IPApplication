-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListNameDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameDetail.'
	Drop procedure [dbo].[naw_ListNameDetail]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.naw_ListNameDetail
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int, 		-- Mandatory
	@pbCanViewSalesHighlights	bit		= 0,
	@pbCanViewBillingHistory	bit		= 0,
	@pbCanViewReceivableItems	bit		= 0,
	@pbCanViewPayableItems		bit		= 0,
	@pbCanViewWIPItems		bit		= 0,
	@pbCanViewEmployerInformation	bit		= 0,
	@pbCanViewAttachments		bit		= 0,
	@pbCanViewSupplierDetails	bit		= 0,
	@pbCanViewPrepayments		bit		= 0,
	@pbCanViewContactActivities	bit		= 0,
	@pbCalledFromCentura		bit		= 0,
	@psResultsetsRequired 		nvarchar(1000)	= null,	 	-- Contains a comma separated list of topics required.  
									-- When null (the default), all topics are to be returned,
									-- e.g. 'OtherDetails,NameText'.					
	@psProgramKey			nvarchar(8)	= null									
)
AS
-- PROCEDURE:	naw_ListNameDetail
-- VERSION:	84

-- DESCRIPTION:	Populates NameDetailData dataset. Returns full details regarding a
--		single name. 

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 13-Nov-2003  JEK		1	Procedure created
-- 15-Dec-2003	TM	RFC621	2	Don't return street address if its the same as postal address.
-- 15-Dec-2003	TM	RFC621	3	Implement topic level security. Suppress the data for the following result sets 
--					based on topic security: ReceivableByCurrency result set (Receivable Items topic 
--					200), ReceivableTotal result set (Receivable Items topic 200), Prepayment result  
--					set (Prepayments topic 201).
-- 16-Dec-2003	TM	RFC621	4	Double check to ensure that the naw_ListNameDetail conforms to current coding 
--					standards.
-- 17-Dec-2003	TM	RFC621	5	Do not extract the LastReceipt information if the Receivable Items topic is not
--					available.
-- 23-Dec-2003	TM	RFC621	6	Correct the column name so it 'Restriction' not 'Restriciton'.
-- 28-Jan-2004	TM	RFC881	7	Remove fn_FilterUserNames from the NameLanguage result set.  
-- 19-Feb-2004	TM	RFC976	8	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 10-Mar-2004	TM	RFC868	9	Modify the logic extracting the 'MainContactEmail' and 'Email' columns in the Name
--					Result Set and the In the ResponsibleStaff result set to use new Name.MainEmail column. 
-- 30-Mar-2004	TM	RFC693	10	Suppress the PayableBalance result set if the Payable Items topic is not available (300).
-- 07-Apr-2004	TM	RFC1220	11	In the NameText result set suppress The Billing specific correspondence instruction.
-- 02-Jul-2004	TM	RFC1536	12	Add RestrictionActionKey column.
-- 01-Sep-2004	TM	RFC1538	13	Add the financial totals to the Name result set for use in Additional Information.
--					Add DefaultCorrespondenceInstructions for use in the new CorrespondenceInstructions
--					topic.
-- 07-Sep-2004	TM	RFC1158	14	Extend to populate the new dataset contents.
-- 20 Sep 2004	JEK	RFC886	15	Implement translation.
--					Also, standing instructions should only be shown for Clients (i.e. IPName exists).
-- 21 Sep 2004	JEK	RFC886	16	Fix case sensitivity error.
-- 22 Sep 2004	JEK	RFC886	17	Case count syntax error when no translation.
-- 29 Sep 2004	TM	RFC1806	18	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.	
-- 22 Oct 2004	TM	RFC1158	19	Add new FilesIn datatable.
-- 26 Oct 2004	TM	RFC1158	20	Correct the IntructionType column name to be InstructionType.
-- 29 Oct 2004	TM	RFC1158	21	Add a new RowKey column to the AssociatedName, ClientName, ResponsibleStaff
--					and StandingInstruction result sets.
-- 16 Nov 2004	TM	RFC869	22	Return the TEXTTYPE of 'CB' in the NameText result set.
-- 26 Nov 2004	TM	RFC2043	23	Suppress TextType = 'N' from the NameText result set.
-- 26 Nov 2004	TM	RFC2043	24	Include a comment explaining why the TextType = 'N' from the NameText result set
--					is being suppressed.
-- 15 Dec 2004	TM	RFC2048	25	Implement Name.AttachmentCount column. Remove call to ip_ListAttachment. Implement
--					calls to naw_ListRecentActivity and naw_ListActivitySummary.
-- 21 Dec 2004	TM	RFC2146	26	Only return an Individual result set if there are non-null fields in the result.
-- 11 Jan 2005	TM	RFC1533	27	Populate the new columns in the Name datatable. Populate the new NameOther datatable.
--					Implement a new optional @psResultsRequired nvarchar(1000) 
-- 20 Jan 2005	TM	RFC1533	28	The Attribute and Individual result sets should be populated for OtherDetails.
-- 20 Jan 2005	TM	RFC1533	29	Put the result sets back in the original order.
-- 01 Feb 2005	TM	RFC2265	30	Remove trailing space in the ShowEmployerInformation collumn name in the Name
--					result set.
-- 11 Feb 2005	TM	RFC2309	31	(1533 feedback). Group should be returned in the Name result set instead of 
--					NameOther.
-- 14 Feb 2005	TM	RFC2313	32	Add new columns to the Name datatable: ShowSalesHighlights bit.
-- 14 Feb 2005	TM	RFC2306	33	Add new TextTypeKey (string) column in the NameText DataTable.
-- 16 Feb 2005	TM	RFC2313	34	Improve efficiency and commenting for the ShowSalesHighlights column extraction.
-- 23 Feb 2005	TM	RFC2352	35	When the @psResultsRequired has the new RecentContactActivity and ContactActivitySummary 
--					options, populate only the relevant result sets.
-- 15 May 2005	JEK	RFC2508	36	Extract @sLookupCulture and pass to translation instead of @psCulture
--					Also pass @sLookupCulture to child procedures that are known not to need the original @psCulture
-- 25 Nov 2005	LP	RFC1017	37	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Name result set
-- 15 Dec 2005	AU	RFC2951	38	Add two new columns: 1) “CaseTypeDescription”, “CaseTypeKey” to the PropertyCaseCount result-set.
-- 06 Jan 2006	TM	RFC2951	39	Implement new sorting on the PropertyCaseCount result set.
-- 16 Jan 2006	TM	RFC1659	40	Add new NameVariants result set.
-- 13 Feb 2006	TM	RFC3473	41	Modify StandingInstruction result set to suppress default standing instruction 
--					if it was overwritten by corresponding name specific standing instruction.
-- 02 Mar 2006	LP	RFC3216	42	Implement call to naw_ListNameAlias to populate the Alias result set.
-- 06 Mar 2006	TM	RFC3215 43	Replace existing standing instruction SQL with a call to naw_ListStandingInstructions.
-- 17 Jul 2006	SW	RFC3828	44	Pass getdate() to fn_Permission..
-- 25 Aug 2006	SF	RFC4214	45	Implement ResultSetRequired Parameter, Move financial result sets out as separate sps, Added RowKey
-- 15 Jan 2007	AU	RFC4678	46	Return WebLink result-set.
-- 17 Dec 2007	SW	RFC5740	47	Add new columns SOURCE, ESTIMATEDREV, STATUS for NAME
-- 02 Jan 2008	SW	RFC5740	48	Change column STATUS to NAMESTATUS, add new column CRMONLY
-- 11 Jan 2008	SW	RFC5740	49	Change column SOURCE to NAMESOURCE
-- 14 Feb 2008	SF	RFC6150	50	Return type of entity
-- 25 Mar 2008	Praveen RFC6250 51	Name Details stored procedure no longer support entire result set 
-- 10 Jun 2008	LP	RFC4342	52	Return Name Type Classification result set.
-- 30 Jun 2008	SF	RFC6535 53	Return Lead Details "LEADDETAILS" result set
--					Add "MARKETINGACTIVITIES" result set, "OPPORTUNITIES" result set
--					Add IsLead to Name, Add ModifiedDate to NameText
--					Add IsLead to Name, Add ModifiedDate to NameText
-- 4 July 2008	SF	RFC6535 54	Return Lead Details "LEADSTATUSHISTORY" result set
-- 11 Dec 2008	MF	17136	55	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 20 Mar 2009	AT	RFC7244	56	Return CanConvertToClient flag for Leads and Prospects.
-- 24 Mar 2009  Ash	RFC6312 57	Add new Column for Count the Associated organisation to the Name Result Set.
-- 27 Mar 2009  Ash	RFC6312 58	Add new condition for relevant associated name. .
-- 29 Apr 2009	SF	RFC7927	59	Order Organisation the same way as Associated Names result set if the individual is employed by multiple organisations
-- 16 Jun 2009	KR	RFC6546 60	Screen and Field Control. Return NAMECRITERIANO to Name result set
-- 21 Sep 2009  LP      RFC8047 61      Pass ProfileKey parameter to fn_GetCriteriaNoForName
-- 08 Oct 2009	AT	RFC100080	62	Use CRM program name for screen criteria if the name is CRM Only.
-- 05 Nov 2009	LP	RFC6712	63	Return SecurityFlag column.
-- 06 Jan 2010	LP	RFC8450	64	New ProgramKey parameter to allow viewing of name using a different screen control program.
-- 08 Jan 2010	LP	RFC8525	65	Implement logic to determine default screen control program from PROFILEATTRIBUTE then SITECONTROL.
-- 05 Feb 2010	MS	RFC7281	66	Return Exempt Charges Result Set
-- 10 Feb 2010	MS	RFC7281	67	Return Discount Result Set
-- 02 Mar 2010	MS	RFC100147	68	Change Sort Order in NameText. Sort on TextType rather than NameKey.
-- 19 Mar 2010	MS      RFC3298	69	Return Margin Profile result set.
-- 11 May 2010	PA      RFC9097	70	Get the TAXNO from the NAME table.
-- 25 Aug 2010	LP	RFC9695	71	Execute Row Access Security check for NAME result set only.
-- 14 Jun 2011	JC	RFC100151 72	Improve performance by passing authorisation as parameters
-- 07 Jul 2011	DL	RFC10830 73	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 07 Sep 2011	ASH	R11032 74	Change logic to get Image ID where image order is minimum.
-- 13 Sep 2011	LP	R11251  75	Row access security by Name Office should be independent of any site controls.
-- 10 Oct 2011  MS      R11326  76      Left join of NAME table with ASSOCIATEDNAME table will be removed in select query for name details.
-- 21 Oct 2011  MS      R11438  77      Pass Namestyle in fn_FormatName call
-- 15 Jun 2012	KR	R12005	78	added CASETYPE and WIPCODE to DISCOUNT table.
-- 11 Apr 2013	DV	R13270	79	Increase the length of nvarchar to 11 when casting or declaring integer
-- 19 May 2015	DV	R47600	80	Remove check for WorkBench Attachments site control 
-- 01 Jun 2015	MS	R35907	81	Added COUNTRYCODE to the Discount calculation
-- 02 Nov 2015	vql	R53910	82	Adjust formatted names logic (DR-15543).
-- 11 Jul 2016  MS	R63087  83	Added @psProgramKey inside dynamic sql
-- 17 Mar 2017	MF	70924	84	Postal address is not taking the users culture into consideration.	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 			nvarchar(4000)

Declare @nUsedAsFlag			bit -- identifies if the name is used as staff/individual/organisation
Declare @bIsStaff			bit

Declare @sGenericKey			nvarchar(20)

Declare @sRegistrationNo		nvarchar(30)
Declare @sIncorporated			nvarchar(4000)
Declare @nParentEntityKey		int
Declare @sParentEntityName		nvarchar(254)
Declare @nOrganisationKey		int
Declare @sOrganisationName		nvarchar(254)
Declare @sOrganisationRestriction	nvarchar(50)
Declare @nOrganisationRestrictionActionKey decimal(1,0)
Declare @bShowEmployerInformation	bit
Declare @sPosition			nvarchar(60)

Declare @sStreetAddress			nvarchar(1000)
Declare @sPostalAddress			nvarchar(1000)

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint

Declare @bIsLead			bit
Declare @bIsCRMOnly			bit

Declare @nUrlDocItemKey			int
Declare @sUrl				nvarchar(4000)

Declare @nErrorCode			int
Declare @nRowCount			int

Declare @sLookupCulture		nvarchar(10)

Declare @sResultsetsRequired 	nvarchar(1000)

Declare @nScreenCriteriaKey	int
Declare @nProfileKey            int

Declare @bHasRowAccessSecurity	bit	-- Indicates if Row Access Security exists for the user
Declare @nSecurityFlag		int	-- The security flag return via best fit

Declare @nAttributeId		int		-- The identifier for the profile attribute
Declare @sSiteControl		nvarchar(120)	-- The name of the site control related to screen control

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @nSecurityFlag = 15			-- default to full row access

Set 	@nErrorCode 		 	= 0
Set	@nRowCount		 	= 0

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
-- also prefix with comma so result set ends with the same name as the one requested are not matched.
Set 	@sResultsetsRequired = @psResultsetsRequired  -- keep original for passing to child procs.
Set	@psResultsetsRequired = ',' + upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

-- Get the ProfileKey of the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId

        Set @nErrorCode = @@ERROR
End

-- Get the Default Name Program for the profile
-- Set the Default Program if not specified via input parameters
If @nErrorCode = 0 
AND (@psProgramKey is null or @psProgramKey = '')
Begin
	-- No non-crm name types selected
	If not exists (SELECT 1 from NAME XN
				left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
									and NTC.NAMETYPE <> '~~~'
									and NTC.ALLOW=1)
				left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32<>32)
				where XN.NAMENO = @pnNameKey
				and NTP.NAMETYPE is not null)
	-- and at least 1 CRM Name type selected.
	and exists (SELECT 1 
				from NAME XN
				left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
									and NTC.NAMETYPE <> '~~~'
									and NTC.ALLOW=1)
				left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32=32)
				where XN.NAMENO = @pnNameKey
				and NTP.NAMETYPE is not null)
	Begin
		Set @nAttributeId = 4
		Set @sSiteControl = 'CRM Name Screen Program'			
	End
	Else
	Begin
		Set @nAttributeId = 3
		Set @sSiteControl = 'Name Screen Default Program'		
	End
	If @nErrorCode = 0
	and @nProfileKey is not null
	Begin
		Select @psProgramKey = P.ATTRIBUTEVALUE
		from PROFILEATTRIBUTES P
		where P.PROFILEID = @nProfileKey
		and P.ATTRIBUTEID = @nAttributeId

		Set @nErrorCode = @@ERROR
	End
	
	If @nErrorCode = 0
	and (@psProgramKey is null or @psProgramKey = '')
	Begin 
		Select @psProgramKey = SC.COLCHARACTER
		from SITECONTROL SC
		where SC.CONTROLID = @sSiteControl
	
		Set @nErrorCode = @@ERROR
	End
End

DECLARE @bCanConvertToClient bit
SET @bCanConvertToClient = 0

-- Check if employed by or lead for name is a convertible prospect.
If @nErrorCode = 0
Begin
	-- If the name is a Lead
	-- and they are Employed By or Lead For a Prospect who is not a client
	if exists (
		select LEAD.* from 
			(SELECT NAMENO from NAMETYPECLASSIFICATION where NAMENO = @pnNameKey and NAMETYPE = '~LD' AND ALLOW = 1) as LEAD
			join ASSOCIATEDNAME AN on (AN.RELATEDNAME = LEAD.NAMENO
						AND AN.RELATIONSHIP IN ('EMP', 'LEA'))
			join NAMETYPECLASSIFICATION PNTC on (PNTC.NAMENO = AN.NAMENO
								and PNTC.NAMETYPE = '~PR'
								and ALLOW = 1)
			join NAME PN on (PN.NAMENO = AN.NAMENO)	
			WHERE isnull(PN.USEDASFLAG, 0) & 4 = 0
	)
	Begin
		Set @bCanConvertToClient = 1
	End
	-- If the name is a prospect
	-- and they are not a client
	Else If exists (select N.* from NAME N 
			join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO)
			where N.NAMENO = @pnNameKey 
			and NTC.NAMETYPE = '~PR'
			and NTC.ALLOW = 1
			and isnull(N.USEDASFLAG, 0) & 4 = 0)
	Begin
		Set @bCanConvertToClient = 1
	End
End

-- Extract street and Organisation information into local variables to reduce size of Name and NameOther select
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAME,', @psResultsetsRequired) <> 0
     or CHARINDEX(',RECENTACTIVITY,', @psResultsetsRequired) <> 0
     or CHARINDEX(',RECENTACTIVITYTOTAL,', @psResultsetsRequired) <> 0
     or CHARINDEX(',ACTIVITYBYCONTACT,', @psResultsetsRequired) <> 0
     or CHARINDEX(',ACTIVITYBYCATEGORY,', @psResultsetsRequired) <> 0)
Begin

	Set @sSQLString = 
	"Select top 1 @sStreetAddress		= dbo.fn_FormatAddress("+dbo.fn_SqlTranslatedColumn('ADDRESS','STREET1',null,'SA',@sLookupCulture,@pbCalledFromCentura)+", 
								       SA.STREET2, 
								       "+dbo.fn_SqlTranslatedColumn('ADDRESS','CITY',null,'SA',@sLookupCulture,@pbCalledFromCentura)+", 
								       "+dbo.fn_SqlTranslatedColumn('ADDRESS','STATE',null,'SA',@sLookupCulture,@pbCalledFromCentura)+", 
								       "+dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'SS',@sLookupCulture,@pbCalledFromCentura)+", 
								       SA.POSTCODE, 								       
								       "+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'SC',@sLookupCulture,@pbCalledFromCentura)+", 
								       SC.POSTCODEFIRST, 
								       SC.STATEABBREVIATED, 
								       "+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTCODELITERAL',null,'SC',@sLookupCulture,@pbCalledFromCentura)+", 
								       SC.ADDRESSSTYLE),"+CHAR(10)+ 
	"	@sPostalAddress			= dbo.fn_FormatAddress("+dbo.fn_SqlTranslatedColumn('ADDRESS','STREET1',null,'PA',@sLookupCulture,@pbCalledFromCentura)+", 
								       PA.STREET2, 
								       "+dbo.fn_SqlTranslatedColumn('ADDRESS','CITY',null,'PA',@sLookupCulture,@pbCalledFromCentura)+", 
								       "+dbo.fn_SqlTranslatedColumn('ADDRESS','STATE',null,'PA',@sLookupCulture,@pbCalledFromCentura)+", 
								       "+dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'PS',@sLookupCulture,@pbCalledFromCentura)+", 
								       PA.POSTCODE,
								       "+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTALNAME',null,'PC',@sLookupCulture,@pbCalledFromCentura)+", 
								       PC.POSTCODEFIRST, 
								       PC.STATEABBREVIATED, 
								       "+dbo.fn_SqlTranslatedColumn('COUNTRY','POSTCODELITERAL',null,'PC',@sLookupCulture,@pbCalledFromCentura)+", 
								       PC.ADDRESSSTYLE),"+CHAR(10)+ 
	"	@nOrganisationKey		= ORG.NAMENO,"+CHAR(10)+ 
	"	@sOrganisationName		= dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, null),"+CHAR(10)+	
	"	@sPosition			= "+dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,'EMP',@sLookupCulture,@pbCalledFromCentura)+","+CHAR(10)+				
	"	@sOrganisationRestriction 	= "+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)+","+CHAR(10)+	
	"	@nOrganisationRestrictionActionKey= DS.ACTIONFLAG,"+CHAR(10)+
	"	@bShowEmployerInformation	= CASE WHEN (@pbCanViewEmployerInformation = 1 and ORG.NAMENO is not null) THEN CAST(1 as bit) ELSE CAST(0 as bit) END"+CHAR(10)+
     	"from NAME N"+CHAR(10)+   	
	-- Street Address details
	-- Only show the street address when its different to the postal address
	"left join ADDRESS SA 		on (SA.ADDRESSCODE = N.STREETADDRESS"+CHAR(10)+ 
	"				and N.STREETADDRESS <> N.POSTALADDRESS)"+CHAR(10)+ 	
	"left join COUNTRY SC		on (SC.COUNTRYCODE = SA.COUNTRYCODE)"+CHAR(10)+ 
	"left Join STATE SS		on (SS.COUNTRYCODE = SA.COUNTRYCODE"+CHAR(10)+ 
	" 	           	 	and SS.STATE = SA.STATE)"+CHAR(10)+ 
	-- Postal Address details 
	"left join ADDRESS PA 		on (PA.ADDRESSCODE = N.POSTALADDRESS)"+CHAR(10)+ 
	"left join COUNTRY PC		on (PC.COUNTRYCODE = PA.COUNTRYCODE)"+CHAR(10)+ 
	"left Join STATE PS		on (PS.COUNTRYCODE = PA.COUNTRYCODE"+CHAR(10)+ 
	" 	           	 	and PS.STATE = PA.STATE)"+CHAR(10)+ 
     	-- For 'OrganisationName' for the employed by relationship on AssociatedName.
	"left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO"+CHAR(10)+ 
	"				and EMP.RELATIONSHIP = 'EMP')"+CHAR(10)+ 
	"left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)"+CHAR(10)+ 
	-- For Restriction
	"left join IPNAME IP		on (IP.NAMENO = ORG.NAMENO)"+CHAR(10)+ 
	"left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+ 
	"where N.NAMENO = @pnNameKey
	order by EMP.NAMENO, 4"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@sStreetAddress			nvarchar(1000)		OUTPUT,
					  @sPostalAddress			nvarchar(1000)		OUTPUT,
					  @nOrganisationKey			int			OUTPUT,
					  @sOrganisationName			nvarchar(254)		OUTPUT,
					  @sPosition				nvarchar(60)		OUTPUT,
					  @sOrganisationRestriction 		nvarchar(50)		OUTPUT,
					  @nOrganisationRestrictionActionKey	decimal(1,0)		OUTPUT,
					  @bShowEmployerInformation		bit			OUTPUT,
					  @pnNameKey				int,
					  @pbCanViewEmployerInformation		bit',
					  @sStreetAddress			= @sStreetAddress	OUTPUT,
					  @sPostalAddress			= @sPostalAddress	OUTPUT,
					  @nOrganisationKey			= @nOrganisationKey	OUTPUT,
					  @sOrganisationName			= @sOrganisationName	OUTPUT,
					  @sPosition				= @sPosition		OUTPUT,
					  @sOrganisationRestriction 		= @sOrganisationRestriction OUTPUT,
					  @nOrganisationRestrictionActionKey	= @nOrganisationRestrictionActionKey OUTPUT,
					  @bShowEmployerInformation		= @bShowEmployerInformation OUTPUT,
					  @pnNameKey				= @pnNameKey,
					  @pbCanViewEmployerInformation		= @pbCanViewEmployerInformation
End

-- Populate the Name and Lead Details result set if user is licensed to CRM	
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',LEADDETAILS,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = 
	"Select @bIsLead = NTC.ALLOW"+char(10)+	
	"from	NAMETYPECLASSIFICATION NTC"+char(10)+
	"where	NTC.NAMETYPE = '~LD'"+char(10)+
	"and NTC.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsLead				bit output,
					  @pnNameKey		 	int',
					@bIsLead				= @bIsLead output,
					@pnNameKey				= @pnNameKey
End

-- Check if the name is CRM Only
If @nErrorCode = 0
Begin
	-- No non-crm name types selected
	If not exists (SELECT 1 
				from NAME XN
				left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
												and NTC.NAMETYPE <> '~~~'
												and NTC.ALLOW=1)
				left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32<>32)
				where XN.NAMENO = @pnNameKey
				and NTP.NAMETYPE is not null)
	-- and at least 1 CRM Name type selected.
	and exists (SELECT 1 
				from NAME XN
				left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
												and NTC.NAMETYPE <> '~~~'
												and NTC.ALLOW=1)
				left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32=32)
				where XN.NAMENO = @pnNameKey
				and NTP.NAMETYPE is not null)
		Begin
			Set @bIsCRMOnly = 1
		End

End

-- Check if user has been assigned row access security profile
-- Execute only when requesting the top-level NAME result set
If @nErrorCode = 0
and @pbCalledFromCentura = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAME,', @psResultsetsRequired) <> 0)
Begin
	Select @bHasRowAccessSecurity = 1
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
	where R.RECORDTYPE = 'N'
	and U.IDENTITYID = @pnUserIdentityId
	
	Set @nErrorCode = @@ERROR 

	If @nErrorCode = 0
	and @bHasRowAccessSecurity = 1
	Begin
		Set @nSecurityFlag = 0			-- Set to 0 as we know Row Access has been applied
		
		SELECT @nSecurityFlag = S.SECURITYFLAG
		from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000 
			+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100 
			+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10 
			+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
			FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U, NAME N 		
			WHERE R.RECORDTYPE = 'N' 
			AND R.CASETYPE IS NULL
			AND R.PROPERTYTYPE IS NULL
			AND (R.OFFICE in (select TA.TABLECODE 
						from TABLEATTRIBUTES TA 
						where TA.PARENTTABLE='NAME' 
						and TA.TABLETYPE=44 
						and TA.GENERICKEY=convert(nvarchar, N.NAMENO) )
				OR R.OFFICE IS NULL) 
			AND (R.NAMETYPE in (SELECT NAMETYPE from NAMETYPECLASSIFICATION where NAMENO = @pnNameKey and ALLOW = 1)
				or R.NAMETYPE IS NULL)
			AND U.IDENTITYID = @pnUserIdentityId 
			AND U.ACCESSNAME = R.ACCESSNAME 
			AND N.NAMENO = @pnNameKey
			ORDER BY BESTFIT DESC, SECURITYFLAG ASC) S
		
		Set @nErrorCode = @@ERROR 		
	End
End

-- Populating Name Result Set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAME,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = 
	"Select "+
	"cast(N.NAMENO as nvarchar(11))	as 'RowKey',"+CHAR(10)+
	  "N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
	-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
	-- fn_FormatNameUsingNameNo, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
	"			as 'Name',"+CHAR(10)+  
	"N.NAMECODE		as 'NameCode',"+
	CASE WHEN @psProgramKey is not null THEN
	+char(10)+"dbo.fn_GetCriteriaNoForName(@pnNameKey, 'W', case when @bIsCRMOnly = 1 then 'NAMECRM' else @psProgramKey end, @nProfileKey)" + " as 'ScreenCriteriaKey',"
	ELSE
	+char(10)+"dbo.fn_GetCriteriaNoForName(@pnNameKey, 'W', case when @bIsCRMOnly = 1 then 'NAMECRM' else 'NAMENTRY' end, @nProfileKey)" + " as 'ScreenCriteriaKey',"
	END
	+char(10)+
	"cast((isnull(N.USEDASFLAG, 0) & 1) as bit)		as IsIndividual,"+CHAR(10)+ 
	"~cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	as IsOrganisation,"+CHAR(10)+ 
	"cast((isnull(N.USEDASFLAG, 0) & 2) as bit)		as IsStaff,"+CHAR(10)+ 
	"cast((isnull(N.USEDASFLAG, 0) & 4) as bit)		as IsClient,"+CHAR(10)+ 
	"cast(isnull(N.SUPPLIERFLAG, 0) as bit) 		as IsSupplier,"+CHAR(10)+ 
	"cast(isnull(FI.IsAgent, 0) as bit) 			as IsAgent,"+CHAR(10)+ 
	"cast(isnull(@bIsLead,0) as bit)				as IsLead,"+CHAR(10)+
	"@nOrganisationKey	as 'OrganisationKey',"+CHAR(10)+ 
	"@sOrganisationName	as 'OrganisationName',"+CHAR(10)+
	"@sPosition 		as 'Position',"+CHAR(10)+
	"(Select Count(*) From ASSOCIATEDNAME EMP where EMP.RELATEDNAME = N.NAMENO and EMP.RELATIONSHIP='EMP') as HasMultipleEmployingOrg,"+CHAR(10)+
	"N.SEARCHKEY1		as 'SearchKey1',"+CHAR(10)+
	"N.SEARCHKEY2		as 'SearchKey2',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('NAME','REMARKS',null,'N',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Remarks',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Restriction',"+CHAR(10)+ 
	"DS.ACTIONFLAG		as 'RestrictionActionKey',"+CHAR(10)+ 
	"N.DATECEASED		as 'DateCeased',"+CHAR(10)+ 
	"I.IMAGEID		as 'ImageKey',"+CHAR(10)+ 
	"N1.NAMENO		as 'MainContactKey',"+CHAR(10)+ 
	"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101))"+CHAR(10)+ 	
	"			as 'MainContactName',"+CHAR(10)+ 
	"dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION)"+CHAR(10)+ 
	"     			as 'MainContactEmail',"+CHAR(10)+ 
	"@sStreetAddress	as 'StreetAddress',"+CHAR(10)+ 
	"@sPostalAddress	as 'PostalAddress',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'GRP',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Group',"+CHAR(10)+ 
	-- Email subject set to the name and name code of the current name, formatted as (<Name>' '<NameCode>) 
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+ 
	"+ ' ' + N.NAMECODE	as 'EmailSubject',"+CHAR(10)+
	"ISNULL(TS.IsAvailable,0) as 'CanViewAttachments',"+char(10)+
	"@sOrganisationRestriction as 'OrganisationRestriction',"+CHAR(10)+
	"@nOrganisationRestrictionActionKey as 'OrganisationRestrictionActionKey',"+CHAR(10)+
	"@bShowEmployerInformation as 'ShowEmployerInformation',"+CHAR(10)+
	"@bCanConvertToClient as 'CanConvertToClient',"+CHAR(10)+
	"@nSecurityFlag as 'SecurityFlag'"+CHAR(10)+
	"from NAME N"+CHAR(10)+   	
	"left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+ 
	-- For 'MainContactName' use Name.MainContact
	"left join NAME N1		on (N1.NAMENO  = N.MAINCONTACT)"+CHAR(10)+ 
	"left join TELECOMMUNICATION M  on (M.TELECODE = N1.MAINEMAIL)"+CHAR(10)+
	"left join COUNTRY NN1		on (NN1.COUNTRYCODE = N1.NATIONALITY)"+CHAR(10)+ 
	-- For Restriction
	"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+ 
	"left join NAMEIMAGE I		on (I.IMAGEID = "+CHAR(10)+ 
						"(select NI.IMAGEID "+CHAR(10)+ 
						"from  NAMEIMAGE NI "+CHAR(10)+ 
						"where NI.NAMENO = N.NAMENO "+CHAR(10)+ 
						" AND NI.IMAGESEQUENCE = "+CHAR(10)+ 
							"(SELECT MIN(NIM.IMAGESEQUENCE)"+CHAR(10)+  
							"from  NAMEIMAGE NIM "+CHAR(10)+ 
							"WHERE NIM.NAMENO = N.NAMENO)))"+CHAR(10)+ 
	-- Is Attachments topic available?
	"left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 2, 0, getdate()) TS on (TS.ISAVAILABLE = 1)"+CHAR(10)+ 
	-- For Group
	"left join NAMEFAMILY GRP	on (GRP.FAMILYNO = N.FAMILYNO)"+CHAR(10)+  	
	"left join	(select	FILESIN.NAMENO, 1 as IsAgent
				 from	FILESIN
				) FI				on (FI.NAMENO = N.NAMENO)"+char(10)+
	"where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		 	int,
					  @sStreetAddress	 	nvarchar(1000),
					  @sPostalAddress	 	nvarchar(1000),
					  @sRegistrationNo	 	nvarchar(30),
					  @sIncorporated	 	nvarchar(4000),
					  @nParentEntityKey	 	int,
					  @sParentEntityName	 	nvarchar(254),
					  @nOrganisationKey	 	int,
					  @sOrganisationName	 	nvarchar(254),
					  @sPosition		 	nvarchar(60),
					  @sOrganisationRestriction 	nvarchar(50),
					  @nOrganisationRestrictionActionKey decimal(1,0),
					  @bShowEmployerInformation 	bit,
					  @bIsLead			bit,
					  @bCanConvertToClient		bit,
					  @nScreenCriteriaKey	        int,
					  @nProfileKey                  int,
					  @bIsCRMOnly			bit,
					  @nSecurityFlag		int,
					  @pbCanViewAttachments		bit,
					  @psProgramKey			nvarchar(8),
					  @pnUserIdentityId		int',
					  @pnNameKey		 	= @pnNameKey,
					  @sStreetAddress	 	= @sStreetAddress,
					  @sPostalAddress	 	= @sPostalAddress,
					  @sRegistrationNo	 	= @sRegistrationNo,
					  @sIncorporated	 	= @sIncorporated,
					  @nParentEntityKey	 	= @nParentEntityKey,
					  @sParentEntityName	 	= @sParentEntityName,
					  @nOrganisationKey	 	= @nOrganisationKey,
					  @sOrganisationName	 	= @sOrganisationName,
					  @sPosition		 	= @sPosition,
					  @sOrganisationRestriction	= @sOrganisationRestriction,
					  @nOrganisationRestrictionActionKey = @nOrganisationRestrictionActionKey,
					  @bShowEmployerInformation	= @bShowEmployerInformation,
					  @bIsLead			= @bIsLead,
					  @bCanConvertToClient		= @bCanConvertToClient,
					  @nScreenCriteriaKey		= @nScreenCriteriaKey,
					  @nProfileKey                  = @nProfileKey,
					  @bIsCRMOnly				= @bIsCRMOnly,
					  @nSecurityFlag		= @nSecurityFlag,
					  @pbCanViewAttachments		= @pbCanViewAttachments,
					  @psProgramKey			= @psProgramKey,
					  @pnUserIdentityId		= @pnUserIdentityId
End
	
-- Setting of the ShowSalesHighlights flag:

-- 1) Check whether the Sales Highlights topic (401) is available.
--    If the above topic is not available, the ShowSalesHighlights flag
--    is set to 0.
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',SALESHIGHLIGHTSHEADER,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListNameSalesHighlights 
				@pnUserIdentityId 	= @pnUserIdentityId,
			       	@psCulture 	 	= @sLookupCulture,
				@pnSourceNameKey	= @pnNameKey,
				@pbCanViewSalesHighlights	= @pbCanViewSalesHighlights,
				@pbCanViewBillingHistory	= @pbCanViewBillingHistory,
				@pbCanViewReceivableItems	= @pbCanViewReceivableItems,
				@pbCanViewPayableItems		= @pbCanViewPayableItems,
				@pbCanViewWIPItems		= @pbCanViewWIPItems,
				@pbCalledFromCentura 	= @pbCalledFromCentura,
				@psResultsetsRequired 	= 'HEADER'
End

-- Populating Telecommunications result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',TELECOMMUNICATION,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListTelecommunications @pnUserIdentityId 	= @pnUserIdentityId,
						      @psCulture 		= @sLookupCulture,
						      @pnNameKey 		= @pnNameKey,
						      @pbExcludeMain 		= 0,
						      @pbCalledFromCentura 	= @pbCalledFromCentura
End
	
-- Populating ResponsibleStaff result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',RESPONSIBLESTAFF,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select 
	CAST(AN.NAMENO as varchar(11))+'^'+
	AN.RELATIONSHIP+'^'+
	CAST(AN.RELATEDNAME as varchar(11))+'^'+
	CAST(AN.SEQUENCE as varchar(5))
				as 'RowKey',
	AN.NAMENO		as 'NameKey',
	AN.RELATEDNAME		as 'StaffKey',
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101)) 
				as 'StaffName',
	N.NAMECODE		as 'StaffNameCode',
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Role',
	"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyType',
	dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION)
				as 'Phone',
	dbo.fn_FormatTelecom(F.TELECOMTYPE, F.ISD, F.AREACODE, F.TELECOMNUMBER, F.EXTENSION)
				as 'Fax',
	dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION) 
				as 'Email'
	from ASSOCIATEDNAME AN
	join NAME N			on (N.NAMENO=AN.RELATEDNAME)
	left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)
	left join PROPERTYTYPE P 	on (P.PROPERTYTYPE = AN.PROPERTYTYPE)
	left join TABLECODES R		on (R.TABLECODE = AN.JOBROLE)
	left join TELECOMMUNICATION T 	on (T.TELECODE= isnull(AN.TELEPHONE, N.MAINPHONE) )
	left join TELECOMMUNICATION F	on (F.TELECODE= isnull(AN.FAX,       N.FAX      ) )
	left join TELECOMMUNICATION M	on (M.TELECODE= N.MAINEMAIL)	
	where AN.NAMENO = @pnNameKey 
	and AN.RELATIONSHIP = 'RES'
	order by 'StaffName', 'StaffKey'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End
	
-- Populating Language Result Set

If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',LANGUAGE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	CAST(NL.NAMENO as nvarchar(11)) + '^' + CAST(NL.SEQUENCENO as nvarchar(10)) as 'RowKey',
		N.NAMENO 	  as 'NameKey',
	       "+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PR',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyTypeDescription',
	       "+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'AC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ActionDescription',
	       "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'LanguageDescription'
	-- Client WorkBench should only be run by external users so the call to 
	-- dbo.fn_FilterUserNames is always passing 1 for the @pbIsExternalUser
     	from NAME N 
	join NAMELANGUAGE NL 	  on (NL.NAMENO = N.NAMENO)
	left join PROPERTYTYPE PR on (PR.PROPERTYTYPE = NL.PROPERTYTYPE)	
	left join ACTIONS AC	  on (AC.ACTION = NL.ACTION)	
	left join TABLECODES TC	  on (TC.TABLECODE = NL.LANGUAGE)	
	where N.NAMENO = @pnNameKey
	order by 'PropertyTypeDescription' DESC, 'ActionDescription' DESC"	
 
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End	
	
-- Populating Prepayment Result Set
If @nErrorCode=0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',PREPAYMENT,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListNamePrepayments @pnUserIdentityId 	= @pnUserIdentityId,
					       @psCulture 	 	= @sLookupCulture,
					       @pnNameKey 	 	= @pnNameKey,
					       @pbCanViewPrepayments	= @pbCanViewPrepayments,
					       @pbCalledFromCentura 	= @pbCalledFromCentura
End

-- Populating ClientName result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',CLIENTNAME,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListClientNames @pnUserIdentityId 	= @pnUserIdentityId,
					       @psCulture 	 	= @sLookupCulture,
					       @pnNameKey 	 	= @pnNameKey,
					       @pbCalledFromCentura 	= @pbCalledFromCentura
End
	
-- Populating Addresses result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',ADDRESSES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListAddresses @pnUserIdentityId 		= @pnUserIdentityId,
					     @psCulture        		= @sLookupCulture,
					     @pnNameKey        		= @pnNameKey,
					     @pbExcludeMain    		= 0,
					     @pbCalledFromCentura 	= @pbCalledFromCentura
End
	
-- Populating AssociatedNames result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',ASSOCIATEDNAME,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListAssociatedNames @pnUserIdentityId 	= @pnUserIdentityId,
						   @psCulture 	     	= @sLookupCulture,
						   @pnNameKey 	     	= @pnNameKey,
						   @pbCalledFromCentura = @pbCalledFromCentura
End
	
-- Populating NameText result set
If   @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAMETEXT,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	CAST(NT.NAMENO as nvarchar(11)) + '^' + CAST(NT.TEXTTYPE as nvarchar(10)) as 'RowKey',
		NT.NAMENO		as 'NameKey',
		NT.TEXTTYPE		as 'TextTypeKey',
		"+dbo.fn_SqlTranslatedColumn('TEXTTYPE','TEXTDESCRIPTION',null,'TT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'TextType',
		"+dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','NT',@sLookupCulture,@pbCalledFromCentura)
				+" as 'Text',
		NT.LOGDATETIMESTAMP	as 'ModifiedDate',
		CASE 	WHEN NT.TEXTTYPE in ('CB','CC','CP') 
			THEN 1
			ELSE 0
		END			as 'IsCorrespondenceInstruction'
	from NAMETEXT NT
	"+dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','NT',@sLookupCulture,@pbCalledFromCentura)+"
	join TEXTTYPE TT 	on (TT.TEXTTYPE = NT.TEXTTYPE)
	where NT.NAMENO = @pnNameKey	
	-- Suppress the 'N' TextType so Extended Name will not be treated as text 
	-- and will not appear as a separate Extended Name topic on the Name Details.
	and   NT.TEXTTYPE <> 'N'
	-- TextType
	order by 4"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End

-- Populating Alias result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',ALIAS,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_ListNameAlias   @pnUserIdentityId 	= @pnUserIdentityId,
					       @psCulture 	 	= @sLookupCulture,
					       @pnNameKey 	 	= @pnNameKey,
					       @pbCalledFromCentura 	= @pbCalledFromCentura
End

-- Populating Attribute result set
If   @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',ATTRIBUTE,', @psResultsetsRequired) <> 0)
Begin
	Set @sGenericKey = cast(@pnNameKey as nvarchar(20))
	
	exec @nErrorCode = ipw_ListTableAttributes 	
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	 = @sLookupCulture,
					@psParentTable	 = 'NAME',
					@psGenericKey	 = @sGenericKey,
					@pbIsExternalUser=0
End
	
-- Populating Staff result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',STAFF,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select 
	cast(E.EMPLOYEENO as nvarchar(11)) as 'RowKey',
	E.EMPLOYEENO		as 'NameKey',
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'StaffClassification',
	E.PROFITCENTRECODE	as 'ProfitCentreCode',	
	"+dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ProfitCentre',
	"+dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFNAME',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'SignOffName',
	"+dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFTITLE',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'SignOffTitle',
	E.ABBREVIATEDNAME	as 'AbbreviatedName',
	RS.DESCRIPTION		as 'DefaultPrinter',	
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'CS',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CapacityToSign',
	E.STARTDATE		as 'StartDate'
	from EMPLOYEE E
	left join TABLECODES TC		on (TC.TABLECODE = E.STAFFCLASS)
	left join PROFITCENTRE PC	on (PC.PROFITCENTRECODE = E.PROFITCENTRECODE)
	left join RESOURCE RS		on (RS.RESOURCENO = E.RESOURCENO)
	left join TABLECODES CS		on (CS.TABLECODE = E.CAPACITYTOSIGN)
	where E.EMPLOYEENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End

-- Populating Individual result set
If   @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',INDIVIDUAL,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select 
	cast(I.NAMENO as nvarchar(11))		as 'RowKey',
	I.NAMENO		as 'NameKey',
	I.SEX			as 'GenderCode',
	I.CASUALSALUTATION	as 'CasualSalutation',
	I.FORMALSALUTATION	as 'FormalSalutation'
	from INDIVIDUAL I
	where I.NAMENO = @pnNameKey
	and  (I.SEX is not null
	 or   I.CASUALSALUTATION is not null
	 or   I.FORMALSALUTATION is not null)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End	
	
-- Populating StandingInstruction result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',STANDINGINSTRUCTION,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode=dbo.naw_ListStandingInstructions
					@pnUserIdentityId	= @pnUserIdentityId,
					@pbIsExternalUser	= 0,
					@pnNameKey		= @pnNameKey,
					@psCulture		= @sLookupCulture,
					@pbCalledFromCentura	= @pbCalledFromCentura
End
	
-- Populating Supplier and SupplierEntity result sets
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',SUPPLIER,', @psResultsetsRequired) <> 0
     or CHARINDEX(',SUPPLIERENTITY,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = na_ListSupplierDetails 	
					@pnUserIdentityId 	= @pnUserIdentityId,
			      	 	@psCulture 	  	= @sLookupCulture,
					@pnNameKey	  	= @pnNameKey,
					@pbCanViewSupplierDetails	= @pbCanViewSupplierDetails,
					@pbCalledFromCentura 	= @pbCalledFromCentura,
					@psResultsetsRequired	= @sResultsetsRequired
End
	
-- Populating FilesIn result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',FILESIN,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	
		CAST(FBI.NAMENO as nvarchar(11)) + '^' + FBI.COUNTRYCODE as 'RowKey',
		FBI.NAMENO	    as 'NameKey',
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Country',
		"+dbo.fn_SqlTranslatedColumn('FILESIN','NOTES',null,'FBI',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Notes'
	from FILESIN FBI
	join COUNTRY C	on (C.COUNTRYCODE = FBI.COUNTRYCODE)
	where FBI.NAMENO = @pnNameKey
	order by 'Country'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End
	
-- Populating RecentActivityTotal and RecentActivity result sets
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',RECENTACTIVITYTOTAL,', @psResultsetsRequired) <> 0
     or CHARINDEX(',RECENTACTIVITY,', @psResultsetsRequired) <> 0)
Begin

	exec @nErrorCode = dbo.naw_ListRecentActivity
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @sLookupCulture,
					@pnNameKey		= @pnNameKey,
					@pnOrganisationKey	= @nOrganisationKey,
					@pnTopRowCount		= 5,			-- Shows the 5 most recent contacts
					@pbCalledFromCentura	= @pbCalledFromCentura,
					@psResultsetsRequired	= @sResultsetsRequired
End
	
-- Populating ActivityByContact and ActivityByCategory result sets
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',ACTIVITYBYCONTACT,', @psResultsetsRequired) <> 0
     or CHARINDEX(',ACTIVITYBYCATEGORY,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.naw_ListActivitySummary
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @sLookupCulture,
					@pnNameKey		= @pnNameKey,
					@pnOrganisationKey	= @nOrganisationKey,
					@pbCanViewContactActivities	= @pbCanViewContactActivities,
					@pbCalledFromCentura	= @pbCalledFromCentura,
					@psResultsetsRequired	= @sResultsetsRequired
End

-- Populating OtherDetails
If   @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAMEOTHER,', @psResultsetsRequired) <> 0)
Begin
	-- Populating NameOther Result Set
	Set @sSQLString = 
	"Select cast(N.NAMENO as nvarchar(11)) 	as 'RowKey',"+CHAR(10)+ 
	"	N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
        "	N.TAXNO 	as 'TaxNo',"+CHAR(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'CAT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Category',"+CHAR(10)+ 	
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'NN',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Nationality',"+CHAR(10)+ 
	"O.REGISTRATIONNO	as 'CompanyNo',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('ORGANISATION','INCORPORATED',null,'O',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"			as 'Incorporated',"+CHAR(10)+ 
	"N3.NAMENO		as 'ParentEntityKey',"+CHAR(10)+ 
	"dbo.fn_FormatNameUsingNameNo(N3.NAMENO, null)"+CHAR(10)+
	"			as 'ParentEntityName',"+CHAR(10)+ 
	dbo.fn_SqlTranslatedColumn('AIRPORT','AIRPORTNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Locality',"+CHAR(10)+ 
	dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT','T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ExtendedName'"+CHAR(10)+
     	"from NAME N"+CHAR(10)+   	
	"left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+ 
	"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"left Join ORGANISATION O	on (O.NAMENO = N.NAMENO)"+CHAR(10)+   		
	"left join NAME N3		on (N3.NAMENO = O.PARENT)"+CHAR(10)+ 
	-- For Category
	"left join TABLECODES CAT	on (CAT.TABLECODE = IP.CATEGORY)"+CHAR(10)+ 
	"left join AIRPORT A		on (A.AIRPORTCODE = IP.AIRPORTCODE)"+CHAR(10)+ 
	"left join NAMETEXT T		on (T.NAMENO = N.NAMENO"+CHAR(10)+ 
	"				and T.TEXTTYPE = 'N'"+CHAR(10)+ 
	"				and N.EXTENDEDNAMEFLAG = 1)"+CHAR(10)+ 
	dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT','T',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
	"where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		 	int',
					  @pnNameKey		 	= @pnNameKey	
End

-- Populating NameVariants
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAMEVARIANTS,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = "
	Select 	CAST(NV.NAMENO as nvarchar(11)) + '^' + CAST(NV.NAMEVARIANTNO as nvarchar(11)) as RowKey,
		NV.NAMENO		as NameKey,
		NV.NAMEVARIANTNO	as NameVariantKey, 
		dbo.fn_FormatName(NV.NAMEVARIANT, NV.FIRSTNAMEVARIANT, null, null)
		 			as NameVariant,
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)
					+" as PropertyType, 
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
					+" as Reason
	from NAMEVARIANT NV  
	left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = NV.PROPERTYTYPE)
	left join TABLECODES TC		on (TC.TABLECODE = NV.VARIANTREASON)
	where NV.NAMENO = @pnNameKey
	order by NV.DISPLAYSEQUENCENO"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey
End

-- Populating CorrespondenceInstructions
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',CORRESPONDENCEINSTRUCTIONS,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = "
	Select 	cast(IP.NAMENO as nvarchar(11)) as 'RowKey',"+CHAR(10)+
	"	IP.NAMENO		as 'NameKey',"+CHAR(10)+
	"	"+dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IP',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'DefaultCorrespondenceInstructions',"+CHAR(10)+ 
	"	"+dbo.fn_SqlTranslatedColumn('CREDITOR','INSTRUCTIONS',null,'CR',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Instructions'"+CHAR(10)+
	"from IPNAME IP"+CHAR(10)+
	"left join CREDITOR CR 		on (CR.NAMENO = IP.NAMENO and @pbCanViewSupplierDetails=1)"+CHAR(10)+	
	"where IP.NAMENO = @pnNameKey"+
	" and	("+dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IP',@sLookupCulture,@pbCalledFromCentura)+ " is not null"+CHAR(10)+ 
	" or	"+dbo.fn_SqlTranslatedColumn('CREDITOR','INSTRUCTIONS',null,'CR',@sLookupCulture,@pbCalledFromCentura) + " is not null)"


	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pbCanViewSupplierDetails	bit',
					  @pnNameKey		= @pnNameKey,
					  @pbCanViewSupplierDetails	= @pbCanViewSupplierDetails
End

-- Populate LocalCurrency Result Set
If @nErrorCode=0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',LOCALCURRENCY,', @psResultsetsRequired) <> 0)
Begin
	-- Retrieve Local Currency information
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura

	If @nErrorCode=0
	Begin
		Set @sSQLString = 
		"Select " + CHAR(10)+
		"cast(@pnNameKey as nvarchar(11)) as 'RowKey',"+CHAR(10)+
		"@pnNameKey		as 'NameKey',"+CHAR(10)+
		"@sLocalCurrencyCode	as 'LocalCurrencyCode',"+CHAR(10)+ 
		"@nLocalDecimalPlaces	as 'LocalDecimalPlaces'"+CHAR(10)+ 
		"where 1=1"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey			int,
						  @sLocalCurrencyCode	 	nvarchar(3),
						  @nLocalDecimalPlaces		tinyint',
						  @pnNameKey			= @pnNameKey,
						  @sLocalCurrencyCode	 	= @sLocalCurrencyCode,
						  @nLocalDecimalPlaces		= @nLocalDecimalPlaces
	End
End
-- Populate WebLink Result Set
If @nErrorCode=0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',WEBLINK,', @psResultsetsRequired) <> 0)
Begin
	Select @sUrl = ''

	Set @sSQLString = "
	Select @nUrlDocItemKey = I.ITEM_ID"+CHAR(10)+
	"from SITECONTROL SC"+CHAR(10)+
	"join ITEM I ON (I.ITEM_NAME = SC.COLCHARACTER)"+CHAR(10)+
	"where SC.CONTROLID = 'Name Document URL'"

	exec sp_executesql @sSQLString,
			N'@nUrlDocItemKey		int 			OUTPUT',
			  @nUrlDocItemKey		= @nUrlDocItemKey 	OUTPUT

	
	If @nErrorCode=0
	Begin
		If @nUrlDocItemKey IS NOT NULL
		Begin
			Create table #DocItemText (DocItemText nvarchar(4000) collate database_default )

			IF @@ERROR=0
			Begin	
				Insert into #DocItemText (DocItemText)
				exec @nErrorCode = naw_RunNameDocItem 	@pnUserIdentityId 	= @pnUserIdentityId,
									@psCulture 		= @sLookupCulture,
									@pnDocItemKey		= @nUrlDocItemKey,
									@pnNameKey 		= @pnNameKey
			End			

			If @nErrorCode=0
			Begin
				Select @sUrl = (Select Top 1 DocItemText
				  		from #DocItemText)
			End
		End
	End

	If @nErrorCode=0
	Begin
		Set @sSQLString = 
			"Select " + CHAR(10)+
			"'-1' 				as 'RowKey',"+CHAR(10)+
			"@pnNameKey			as 'NameKey',"+CHAR(10)+
			"@sUrl				as 'URL'"
		
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey	int,
						@sUrl		nvarchar(4000)',
						@pnNameKey	= @pnNameKey,
						@sUrl 		= @sUrl
	End
End

-- Populating NameTypeClassification
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',NAMETYPE,', @psResultsetsRequired) <> 0)
Begin	
	Set @sSQLString = 
	"Select " +
	"CAST(N.NAMENO 	as nvarchar(11)) +'_'+ NT.NAMETYPE	as 'RowKey',"	+char(10)+
	"N.NAMENO				as 'NameKey'," 			+char(10)+
	"NT.NAMETYPE				as 'NameTypeKey',"		+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+
	"					as 'NameTypeDescription',"	+char(10)+
	"case when NT.PICKLISTFLAGS & 32 = 32 then 1 else 0 end as 'IsCRMOnly'"	+char(10)+
	"from NAME N, NAMETYPE NT"						+char(10)+
	"left join NAMETYPECLASSIFICATION NC on (NC.NAMETYPE = NT.NAMETYPE"	+char(10)+
	"					and NAMENO = @pnNameKey)"	+char(10)+
	"where N.NAMENO = @pnNameKey"						+char(10)+
	"and NT.PICKLISTFLAGS & 16 = 16"					+char(10)+ -- Same Name Type
	"and NC.ALLOW = 1"							+char(10)+
	"UNION"									+char(10)+
	"Select " +
	"CAST(N.NAMENO 	as nvarchar(11)) +'_'+ NT1.NAMETYPE	as 'RowKey'," 	+char(10)+
	"N.NAMENO				as 'NameKey'," 			+char(10)+
	"NT1.NAMETYPE				as 'NameTypeKey',"		+char(10)+
	dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT1',@sLookupCulture,@pbCalledFromCentura)+
	"					as 'NameTypeDescription',"	+char(10)+
	"case when NT1.PICKLISTFLAGS & 32 = 32 then 1 else 0 end as 'IsCRMOnly'"+char(10)+
	"from NAME N, NAMETYPE NT"						+char(10)+
	"join NAMETYPE NT1	on (NT.PATHNAMETYPE = NT1.NAMETYPE"		+char(10)+
	"			and NT.HIERARCHYFLAG = 1)"			+char(10)+
	"left join NAMETYPECLASSIFICATION NC	on (NC.NAMETYPE = NT1.NAMETYPE" +char(10)+
	"					and NAMENO = @pnNameKey)"	+char(10)+		 
	"where N.NAMENO = @pnNameKey"						+char(10)+	
	"and NT.PICKLISTFLAGS &  16 = 16"					+char(10)+ -- Same Name Type
	"and NT1.PICKLISTFLAGS & 16 = 0"					+char(10)+
	"and NC.ALLOW = 1"							+char(10)+
	"Order by 'NameTypeDescription'"						

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey	int',
			@pnNameKey	= @pnNameKey
End

-- Populating Lead Details
If @nErrorCode =0
and (	@psResultsetsRequired = ',,'
     or CHARINDEX(',LEADDETAILS,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = crm_GetLeadDetails 
				@pnUserIdentityId 		= @pnUserIdentityId,
			    	@psCulture 	 		= @sLookupCulture,
				@pnNameKey			= @pnNameKey,
				@pbCalledFromCentura 		= @pbCalledFromCentura
End

-- List Opportunities
If @nErrorCode =0
and (	@psResultsetsRequired = ',,'
     or CHARINDEX(',OPPORTUNITIES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = crm_ListOpportunities
				@pnUserIdentityId 		= @pnUserIdentityId,
			    @psCulture 	 			= @sLookupCulture,
				@pnNameKey				= @pnNameKey,
				@pbCalledFromCentura 	= @pbCalledFromCentura
End

-- List Marketing Activities
If @nErrorCode =0
and (	@psResultsetsRequired = ',,'
     or CHARINDEX(',MARKETINGACTIVITIES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = crm_ListMarketingActivities 
				@pnUserIdentityId 		= @pnUserIdentityId,
			    @psCulture 	 			= @sLookupCulture,
				@pnNameKey				= @pnNameKey,
				@pbCalledFromCentura 	= @pbCalledFromCentura
End

-- List Lead Status History
If @nErrorCode =0
and (	@psResultsetsRequired = ',,'
     or CHARINDEX(',LEADSTATUSHISTORY,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = crm_ListLeadStatusHistory 
				@pnUserIdentityId 		= @pnUserIdentityId,
			    @psCulture 	 			= @sLookupCulture,
				@pnNameKey				= @pnNameKey,
				@pbCalledFromCentura 	= @pbCalledFromCentura
End

-- Populating Exempt Charges result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',EXEMPTCHARGES,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	
		CAST(EC.NAMENO as nvarchar(11)) + '^' + CAST(EC.RATENO as nvarchar(11))  as 'RowKey',
		EC.NAMENO	    as 'NameKey',
		EC.RATENO	    as 'RateKey',
		"+dbo.fn_SqlTranslatedColumn('RATES','RATEDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'RateDescription',		
		"+dbo.fn_SqlTranslatedColumn('NAMEEXEMPTCHARGES','NOTES',null,'EC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Notes'
	from NAMEEXEMPTCHARGES EC
	join RATES R	on (R.RATENO = EC.RATENO)
	where EC.NAMENO = @pnNameKey
	order by 'RateDescription'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey


End

-- Populating Discount result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',DISCOUNTS,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	
		CAST(D.DISCOUNTID as nvarchar(11))  as 'RowKey',
		D.NAMENO	    as 'NameKey',
		"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'PropertyName',	
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ActionName',
		cast(D.DISCOUNTRATE as decimal(6,2)) as 'DiscountRate',
		CASE WHEN D.DISCOUNTRATE < 0 THEN 1 ELSE 0 END as 'IsSurcharge',
		"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'WIPCategory',
		"+dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'WIPType',
		CAST(D.BASEDONAMOUNT as bit) as 'IsPreMargin',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ProductName',
		D.EMPLOYEENO	as 'StaffKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'StaffName',
		D.CASEOWNER	as 'CaseOwnerKey',
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null) as 'CaseOwner',
		CT.CASETYPE as CaseTypeKey,
		" + dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura) + " as 'CaseTypeDescription',
		WIPT.WIPCODE as ActivityKey,
		" + dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIPT',@sLookupCulture,@pbCalledFromCentura) + " as 'Activity',
                D.COUNTRYCODE as CountryCode,
                " + dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CNT',@sLookupCulture,@pbCalledFromCentura) + " as 'Country'
	from DISCOUNT D
	LEFT OUTER JOIN PROPERTYTYPE P ON (D.PROPERTYTYPE = P.PROPERTYTYPE)  	
	LEFT OUTER JOIN ACTIONS A ON (D.ACTION = A.ACTION)  	
	LEFT OUTER JOIN WIPCATEGORY WC ON (D.WIPCATEGORY = WC.CATEGORYCODE)  	
	LEFT OUTER JOIN WIPTYPE WT ON (D.WIPTYPEID = WT.WIPTYPEID)  	
	LEFT OUTER JOIN NAME N1 ON (D.CASEOWNER = N1.NAMENO)  	
	LEFT OUTER JOIN NAME N ON (D.EMPLOYEENO = N.NAMENO)  
	LEFT OUTER JOIN TABLECODES TC on (D.PRODUCTCODE = TC.TABLECODE and TC.TABLETYPE = 106)
	Left Outer Join CASETYPE CT on (D.CASETYPE = CT.CASETYPE)
	Left Outer Join WIPTEMPLATE WIPT on (D.WIPCODE = WIPT.WIPCODE)
        Left Outer Join COUNTRY CNT on (D.COUNTRYCODE = CNT.COUNTRYCODE)
	where D.NAMENO = @pnNameKey
	order by D.SEQUENCE"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					  @pnNameKey		= @pnNameKey


End

-- Populating Margin Profiles result set
If @nErrorCode = 0
and (   @psResultsetsRequired = ',,'
     or CHARINDEX(',MARGINPROFILES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = naw_FetchMarginProfile
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnNameKey		= @pnNameKey		
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameDetail to public
GO


