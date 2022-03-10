-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ConstructNameWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ConstructNameWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ConstructNameWhere.'
	Drop procedure [dbo].[naw_ConstructNameWhere]
	Print '**** Creating Stored Procedure dbo.naw_ConstructNameWhere...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ConstructNameWhere 
(	
	@psReturnClause			nvarchar(max)  = null output, -- variable to hold the constructed "where" clause 
	@pnUserIdentityId		int		= null,			
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pnFilterGroupIndex		tinyint		= null,  -- The FilterCriteriaGroup node number.			
	@pbCalledFromCentura		bit 		= 0
)
AS
-- PROCEDURE:	naw_ConstructNameWhere
-- VERSION:	64
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Names and constructs
--		a JOIN and WHERE clause. It is responsible for the preparation of a where clause given a single 
--		occurrence of FilterCriteria. 

-- MODIFICATIONS :
-- Date		Who	Number  Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 19 Dec 2003  TM	R710	1	Procedure created 
-- 07 Jan 2004	TM	R804	2	Implement  searching on the post code for an address. Correct the filtering logic
--					for Street1 Filter Criteria.  
-- 08 Jan 2004 	TM	R710	3	Sounds Like Search Key should cater for all of the flags UseSearchKey1, UseSearchKey2 
--					and UseSoundsLike to be turned on; i.e. add the sounds like test added to the others 
--					as another OR condition. 
-- 20 Jan 2004	TM	R861	4	Modify naw_ConstructNameWhere to only pad @sNameCode with leading zeroes for operators
--					Equal To and Not Equal To.
-- 20 Jan 2004	TM	R862	5	Names Advanced Search - Unable to filter using the Supplier checkbox  
-- 20 Jan 2004 	TM	R864	6	Correct the Name filter criteria logic.
-- 21 Jan 2004	TM	R876	7	Correct the @sSearchKey filter criteria logic.  
-- 22 Mar 2004	TM	R964	8	Correct the 'Search Key Sounds Like' filter criteria logic.
-- 14 Mar 2004	TM	R964	9	Replace the 'or (@bUseSearchKey1<>1 and @bUseSearchKey2<>1)' logic with defaulting the 
--					@bUseSearchKey1 to 1 if both @bUseSearchKey1 and @bUseSearchKey2 are 0. 
-- 02 Sep 2004	JEK	R1377	10	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 07 Sep 2004	TM	R1158	11	Add new filter criteria for internal use.
-- 22 Sep 2004	TM	R886	12	Implement translation.
-- 22 Nov 2004	TM	R2007	13	Correct the filtering on the SupplierAccountNo criteria.
-- 15 Dec 2004	TM	R2128	14	For the NameTypeKey filter criteria only names that appear on cases 
--					the user may access are returned.
-- 16 Dec 2004	TM	R2128	15	For the NameTypeKey filter criteria return only name types that the user 
--					has access to.
-- 17 Dec 2004	TM	R1674	16	Remove the UPPER function around the NameCode, SearchKey1 and SearchKey2 to
--					improve performance.
-- 15 May 2005	JEK	R2508	17	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 16 Jan 2006	TM	R1659	18	Allow searching on both name and/or name variant.
-- 24 Feb 2006	LP	R3539	19	Add NAMEINSTRUCTION.CASEID is NULL to Instructions Where clause if the operator is
--					either Exists or Not Exists
-- 06 Mar 2006	TM	R3215	20	Implement new IncludeInherited filter criteria in the StandingInstructions section.
-- 17 Mar 2006	SW	R3212	21	Implement new filter criteria for <AccessAccountKey>.
-- 22 Mar 2006	IB	R3325	22	Name Search/List for external users.
-- 03 May 2006	SW	R3779	23	Modify the logic for inherited instruction searching to check the name type of the instruction type.
-- 17 Oct 2006	MF	R4405	24	Correction to RFC3779 and modify filter on Standing Instructions to improve 
--					performance.
-- 30 Jan 2007	PY	12521	25	Replace function call Soundex with fn_SoundsLike
-- 19 Oct 2007	AT	R5064	26	Fix operator check on Credit Limit.
-- 09 Nov 2007	vql	R5762	27	Add a second Associated Name search filter and Name Source and Name Status filter.
-- 19 Mar 2008	vql	14773	28	Make PurchaseOrderNo nvarchar(80)
-- 30 Jun 2008	LP	R5764	29	Add filtering for RES and REF Associated Names and additional Boolean for Attributes
--					Modify Name Source and Name Status filters to use LEADDETAILS and LEADSTATUSHISTORY
-- 01 Aug 2008  LP      R5767	30      Extend to filter by Employing Organisation when AnySearch is specified for Leads
-- 09 Sep 2008  LP      R6910	31      Fix Leads Search to not reference LEADDETAILS table.
-- 11 Sep 2008  LP      R5729	32      Allow searching on multiple NameKeys.
-- 17 Sep 2008  LP      R5751	33      Fix Leads Search to filter by Lead Name Type.
-- 16 Oct 2008	AT	R5771	34	Add Estimated Revenue filtering.
-- 11 Dec 2008	MF	17136	35	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 09 Feb 2008	AT	R7229	36	Added SoundEx support on the Name filter.
-- 15 Apr 2009  LP      R7867	37      Allow filtering for Renewal Agent picklist.
-- 26 Oct 2009	LP	R6712	38	Implement row access security logic.
-- 08 Jan 2010	ASH	R8599	39	Implement the logic of Ceased Names when @sAnySearch is not NULL.
-- 22 Jan 2010	MF	R8834	40	Revisit RFC6712. Correction required to row access security to get the OFFICE from the TableAttribute
--					held against "NAME" not "EMPLOYEE".
-- 17 Feb 2010	MS	R8825	41	Allow searching for Main, Correspondence and Street Addresses.
-- 21 Oct 2010  PA      R9268	42	Added Case Type and Property Type fields for Name Advanced Search filter.
-- 07 Jul 2011	DL	R10830	43	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 12 Aug 2011	MF	R11122	44	Restrict the SEARCHKEY to only use the first 20 characters entered
-- 26 Aug 2010  MS      R10939  45      Restrict the SEARCHKEY to only use the first 20 characters entered
-- 27 Sep 2011	LP	R11343	46	Remove left join on CASENAME and CASES table if not filtering on CaseType or PropertyType
--					Set date parameter to current date when calling fn_FilterUserCaseTypes
-- 11 Oct 2011  ASH     R10794  47      Added Name Type on the Name filter.
--					should just get the Office from the Attributes assigned to the Name.
-- 02 Mar 2012  MS      R11992  48    	If both Supplier and Client checkboxes are checked, results will be 
--                                    	fetched based on "Or" condition between them
-- 24 Sep 2012  DV      R100762 49      Convert @psReturnClause to nvarchar(max)
-- 01 Feb 2013  vql     R12797  50      Fixed row security best fit algorithm.
-- 02 Dec 2011  MS	R11208  51	Added Files Department Staff filtering
-- 01 Feb 2013  vql     R12797  52      Fixed row security best fit algorithm.
-- 11 Apr 2013	DV	R13270	53	Increase the length of nvarchar to 11 when casting or declaring integer
-- 18 Apr 2013	MF	R13142	54	Performance problem where row access security in use and the Name list is to return Organisations.
-- 26 Sep 2013	MS	DR144	55	Added Case filter for finding case names for specific name type
-- 19 Dec 2013	MF	R13474	56	The current search for Main Phone should be extended so that it searches any Telecom Type.
-- 10 Apr 2014	MF	R31341	57	Row level security that includes Office restriction is causing poor performance. 
-- 22 Jul 2014	MF	R37451	58	Quick Search (AnySearch) needs to also consider Row Level Security rules.
-- 29 Jul 2015	MF	50505	59	When searching by Files In country, return names that match on the Country or do not specify
--					any Country.
-- 08 Apr 2016  MS      R52206  60      Addded fn_WrapQuotes to avoid sql injection
-- 27 Apr 2016	MF	R60349	61	Ethical Walls rules applied for logged on user.
-- 11 May 2016	MF	R61268	62	When returning related names, ensure that the relationship has not ceased.
-- 27 Apr 2016	MF	R60350	63	Revisit 60349 - due to merge error Ethical Walls restriction was missing.
-- 15 May 2018	AK	R12675	64	included checks for taxno and companyno.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare @nErrorCode	int

-- Declare Filter Variables
Declare @sAnySearch 				nvarchar(254)	-- A generic search string used to search for appropriate names based on a variety of criteria.
Declare @sNameKey 				nvarchar(11)
Declare @sSuitableForNameTypeKey		nvarchar(3)
Declare @nPickListFlags				smallint	-- Is calculated from the NAMETYPE.PICKLISTFLAGS and determines if the Name is individual, staff, organisation or client.
Declare	@pbIsOrganisation			bit		
Declare	@pbIsIndividual				bit	
Declare	@pbIsStaff				bit		
Declare	@pbIsClient				bit	
Declare	@bIsOrganisation			bit		
Declare	@bIsIndividual				bit	
Declare	@bIsStaff				bit		
Declare	@bIsClient				bit		
Declare	@bIsCurrent				bit		
Declare	@bIsCeased				bit	
Declare @bIsSupplier				bit	
Declare @bIsLead				bit	
Declare @bIsCRM					bit	
Declare	@sSearchKey				nvarchar(20)	
Declare	@bUseSearchKey1				bit		
Declare	@bUseSearchKey2				bit		
Declare	@nSearchKeyOperator			tinyint	
Declare	@bSoundsLikeSearchKey			bit
Declare	@sName					nvarchar(254) 	
Declare	@nNameOperator				tinyint
Declare	@bSoundsLikeName			bit 			
Declare @bUseMainName				bit
Declare @bUseVariantName			bit
Declare	@sNameCode				nvarchar(10)	
Declare	@nNameCodeOperator			tinyint
Declare	@sFirstName				nvarchar(50)	
Declare	@nFirstNameOperator			tinyint
Declare	@dtLastChangedFromDate			datetime	
Declare	@dtLastChangedToDate			datetime	
Declare	@nLastChangedOperator			tinyint	
Declare	@sRemarks				nvarchar(254)	
Declare	@nRemarksOperator			tinyint
Declare	@sTextTypeKey				nvarchar(2)	
Declare	@sText					nvarchar(4000)	
Declare	@nTextOperator				tinyint		
Declare @bIsMainAddress				bit
Declare @bIsCorrespondence			bit
Declare @bIsStreet				bit				
Declare	@sCountryKey				nvarchar(3)	
Declare	@nCountryKeyOperator			tinyint		
Declare	@sStateKey				nvarchar(20)	
Declare	@nStateKeyOperator			tinyint		
Declare	@sCity					nvarchar(30)	
Declare	@nCityOperator				tinyint		
Declare @sStreet1				nvarchar(254)
Declare @nStreet1Operator			tinyint
Declare @sPostCode				nvarchar(10)
Declare @nPostCodeOperator			tinyint
Declare	@nNameGroupKey				smallint	
Declare	@nNameGroupKeyOperator			tinyint		
Declare	@sNameTypeKey				nvarchar(3)	
Declare	@nNameTypeKeyOperator			tinyint	
Declare	@sAirportKey				nvarchar(5)	
Declare	@nAirportKeyOperator			tinyint	
Declare	@sCaseTypeKey				nvarchar(1)	-- Include/Exclude based on next parameter
Declare	@nCaseTypeKeyOperator			tinyint		
Declare	@bIncludeCRMCases			bit		-- if TRUE, allow CASETYPE.CRMOnly = 1 to be returned
Declare	@sPropertyTypeKey			nchar(200)
Declare	@nPropertyTypeKeyOperator		tinyint		
Declare	@sPropertyTypeKeyList			nvarchar(1000)	-- A comma separated qouted list of PropertyType Keys.	
Declare	@nPropertyTypeKeysOperator		tinyint		
Declare	@nNameCategoryKey			int		
Declare	@nNameCategoryKeyOperator		tinyint
Declare	@nBadDebtorKey				int		
Declare	@nBadDebtorKeyOperator			tinyint	
Declare	@sFilesInKey				nvarchar(3)	
Declare	@nFilesInKeyOperator			tinyint		
Declare	@nInstructionKey			int		
Declare	@nInstructionKeyOperator		tinyint		
Declare @bIncludeInherited			bit
Declare	@nParentNameKey				int		
Declare	@nParentNameKeyOperator			tinyint	
Declare	@sRelationshipKey			nvarchar(3)	
Declare	@bIsReverseRelationship			bit		
Declare	@sAssociatedNameKeys			nvarchar(4000)	
Declare	@nAssociatedNameKeyOperator		tinyint		
Declare	@sMainPhoneNumber			nvarchar(50)	
Declare	@nMainPhoneNumberOperator		tinyint		
Declare	@sMainPhoneAreaCode			nvarchar(5)	
Declare	@nMainPhoneAreaCodeOperator		tinyint		
Declare	@nAttributeKey				int	
Declare	@nAttributeKeyOperator			tinyint		
Declare @sAttributeTypeKey			nvarchar(11)
Declare @bAttributeBooleanOr			bit
Declare @bBooleanOr				bit
Declare @sStringOr				nvarchar(5)
Declare	@sAliasTypeKey				nvarchar(2)	
Declare	@sAlias					nvarchar(20)	
Declare	@nAliasOperator				tinyint		
Declare	@sQuickIndexKey				nvarchar(10)		
Declare	@nQuickIndexKeyOperator			tinyint		
Declare	@sBillingCurrencyKey			nvarchar(3)	
Declare	@nBillingCurrencyKeyOperator		tinyint	
Declare	@sTaxRateKey				nvarchar(3)	
Declare	@nTaxRateKeyOperator			tinyint	
Declare	@nDebtorTypeKey				int		
Declare	@nDebtorTypeKeyOperator			tinyint		
Declare	@sPurchaseOrderNo			nvarchar(80)	
Declare	@nPurchaseOrderNoOperator		tinyint		
Declare	@nBillingFrequencyKey			int		
Declare	@nBillingFrequencyKeyOperator		tinyint		
Declare	@bIsLocalClient				bit		
Declare	@nIsLocalClientOperator			tinyint	
Declare	@nReceivableTermsFromDays		int		
Declare	@nReceivableTermsToDays			int		
Declare	@nReceivableTermsOperator		tinyint		
Declare @nStaffClassificationKey		int
Declare @nStaffClassificationOperator 		tinyint
Declare @sStaffProfitCentreKey			nvarchar(6)
Declare @nStaffProfitCentreOperator		tinyint
Declare @nFromAmount				decimal(11,2)
Declare @nToAmount				decimal(11,2)
Declare @nDebtorCreditLimitOperator		tinyint
Declare @nSupplierTypeKey 			int
Declare @nSupplierTypeKeyOperator		tinyint
Declare @nSupplierRestrictionKey 		int
Declare @nSupplierRestrictionOperator		tinyint
Declare @sPurchaseCurrency			nvarchar(3)
Declare @nPurchaseCurrencyOperator		tinyint
Declare @nSupplierPaymentTermsKey		int
Declare @nSupplierPaymentTermsOperator		tinyint
Declare @nSupplierPaymentMethodKey		int
Declare @nSupplierPaymentMethodOperator 	tinyint
Declare @sSupplierAccountNo			nvarchar(30) 
Declare @nSupplierAccountNoOperator		tinyint
Declare @bAccessAccountKeyForCurrentUser	bit
Declare @bAccessAccountKeyIsAccessName		bit
Declare @bAccessAccountKeyIsAccessEmployee	bit
Declare @bAccessAccountKeyIsUserName		bit
Declare @nAccessAccountKey			int
Declare @nAccessAccountKeyOperator		tinyint
Declare	@sCompanyNo			nvarchar(60)	
Declare	@nCompanyNoOperator		tinyint	
Declare	@sTaxNo			nvarchar(60)	
Declare	@nTaxNoOperator		tinyint	

Declare @nHomeNameNo				int
Declare @nNameStatusKey				int
Declare @nNameStatusOperator			tinyint
Declare @nNameSourceKey				int
Declare @nNameSourceOperator			tinyint
Declare @nLeadEstRevFrom			decimal(11,2)
Declare @nLeadEstRevTo				decimal(11,2)
Declare @nLeadEstRevOperator			tinyint
Declare @sLeadEstRevCurrency			nvarchar(3)
Declare @nLeadEstRevCurrencyOperator		tinyint
Declare @bIncludeDraftCase			bit		-- When turned on, allow draft cases to be included in the search.
Declare @bIsFilesDeptStaff                      bit
Declare @bIsEntity				bit
Declare @idoc 				int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		

Declare @sRowPattern			nvarchar(100)	-- Is used to dynamically build the XPath to use with OPENXML depending on the FilterCriteriaGroup node number.
Declare @sCorrelationName		nvarchar(20)
Declare @sHomeCurrency			nvarchar(3)
Declare @nCaseKey			int
Declare @sCaseNameTypes			nvarchar(100)

Declare @tblNameKeys table              (NameKeyIdentity        int IDENTITY,
                                         NameKey                int)
Declare @nNameKeyRowCount		int		-- Number of rows in the @tblNameKeys table                                           

Declare @tblAttributeGroup table	(AttributeIdentity	int IDENTITY,
					 BooleanOr		bit,
					 AttributeKey		int,
		      		 	 AttributeOperator	tinyint,		
		      		 	 AttributeTypeKey	nvarchar(11) collate database_default )	
Declare @nAttributeRowCount		int		-- Number of rows in the @tblAttributeGroup table  

Declare @tblAssociateNameGroup table	(AssociateNameIdentity	int IDENTITY,
					AssociateNameKeys		nvarchar(4000) collate database_default,
		      	 		AssociateNameOperator		tinyint,
					AssociateNameIsReverseRelationship tinyint,
		      	 		AssociateNameRelationshipKey	nvarchar(10)collate database_default)	
Declare @nAssociateNameRowCount		int		-- Number of rows in the @tblAssociateNameGroup table  
Declare @bHasWBRowLevelSecurity		bit		-- Indicates if row access security for WorkBenches users is set up
declare @bOfficeSecurity		bit		-- Indicates that row access security has been defined by Office
declare @bNameTypeSecurity		bit		-- Indicates that row access security has been defined by NameType
Declare @bColboolean			bit

Declare @nCount				int		-- Current table row being processed
Declare @sList				nvarchar(4000)	-- RFC2128 variable to prepare a comma separated list of values
Declare @sUsedAsFlag			nvarchar(20)

Declare	@sSQLString			nvarchar(max)
Declare	@sFrom				nvarchar(4000)
Declare	@sWhere				nvarchar(max)
Declare	@sWhere1			nvarchar(4000)
Declare	@sInOperator			nvarchar(6)
Declare	@sOperator			nvarchar(6)
Declare	@sOr				nvarchar(4)
Declare @dtToday			datetime
-- Declare some constants
Declare @String				nchar(1)
Declare	@Date				nchar(2)
Declare	@Numeric			nchar(1)
Declare	@Text				nchar(1)
Declare @CommaString			nchar(2)

Set	@String 			='S'
Set	@Date   			='DT'
Set	@Numeric			='N'
Set	@Text   			='T'
Set	@CommaString			= 'CS'


Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode     		= 0
Set	@bHasWBRowLevelSecurity		= 0
Set	@bOfficeSecurity		= 0
Set	@bNameTypeSecurity		= 0
Set	@dtToday			= getdate()


-- Extract the @pbIsExternalUser from UserIdentity if it has not been supplied.
If @nErrorCode=0
and @pbIsExternalUser is null
Begin		
	Set @sSQLString='
	Select @pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @pbIsExternalUser	=@pbIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-- If there is no @ptXMLFilterCriteria passed then return the basic "Where" clause.

If (datalength(@ptXMLFilterCriteria) = 0
or datalength(@ptXMLFilterCriteria) is null)
and @nErrorCode = 0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.

	Set @sWhere = char(10)+"	WHERE 1=1"

	Set @sFrom  = char(10)+"	FROM      dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") XN"
	
	-- RFC3325 If the user is external then filter the Names
	If @pbIsExternalUser=1
	Begin
    		Set @sFrom=@sFrom+char(10)+"	join dbo.fn_FilterUserViewNames("+convert(varchar,@pnUserIdentityId)+") XFUVN on (XFUVN.NAMENO=XN.NAMENO)"
	End
End
Else
-- If there are some @ptXMLFilterCriteria passed then begin:
If @nErrorCode = 0
and datalength(@ptXMLFilterCriteria) > 0 
Begin

	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"	WHERE 1=1"
	
	 set @sFrom  = char(10)+"	FROM       dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") XN"
	
	-- RFC3325 If the user is external then filter the Names
	If @pbIsExternalUser=1
	Begin
    		Set @sFrom=@sFrom+char(10)+"	join dbo.fn_FilterUserViewNames("+convert(varchar,@pnUserIdentityId)+") XFUVN on (XFUVN.NAMENO=XN.NAMENO)"
	End
	
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the FilterCriteria elements using element-centric mapping    
	Set @sSQLString = 	
	"Select @sAnySearch 		 = upper(AnySearch),"+CHAR(10)+
		"@pbIsOrganisation	 = IsOrganisation,"+CHAR(10)+
		"@pbIsIndividual	 = IsIndividual,"+CHAR(10)+
		"@pbIsStaff		 = IsStaff,"+CHAR(10)+
		"@pbIsClient		 = IsClient,"+CHAR(10)+				
		"@sSuitableForNameTypeKey = SuitableForNameTypeKey,"+CHAR(10)+		
		"@bIsCurrent		 = IsCurrent,"+CHAR(10)+
		"@bIsCeased		 = IsCeased,"+CHAR(10)+
		"@bIsSupplier		 = IsSupplier,"+CHAR(10)+
		"@bIsLead		 = IsLead,"+CHAR(10)+
		"@bIsCRM		 = IsCRM,"+CHAR(10)+
		"@bIsEntity		 = IsEntity,"+CHAR(10)+
		"@sSearchKey		 = upper(SearchKey),"+CHAR(10)+
		"@bUseSearchKey1	 = UseSearchKey1,"+CHAR(10)+
		"@bUseSearchKey2	 = UseSearchKey2,"+CHAR(10)+
		"@nSearchKeyOperator 	 = SearchKeyOperator,"+CHAR(10)+
		"@bSoundsLikeSearchKey	 = SoundsLikeSearchKey,"+CHAR(10)+
		"@sName			 = upper(Name),"+CHAR(10)+
		"@nNameOperator		 = NameOperator,"+CHAR(10)+
		"@bSoundsLikeName	 = SoundsLikeName,"+CHAR(10)+	
		"@sNameCode		 = upper(NameCode),"+CHAR(10)+
		"@nNameCodeOperator	 = NameCodeOperator,"+CHAR(10)+
		"@sFirstName		 = upper(FirstName),"+CHAR(10)+		
		"@nFirstNameOperator	 = FirstNameOperator,"+CHAR(10)+	
		"@dtLastChangedFromDate	 = LastChangedFromDate,"+CHAR(10)+
		"@dtLastChangedToDate	 = LastChangedToDate,"+CHAR(10)+
		"@nLastChangedOperator	 = LastChangedOperator,"+CHAR(10)+
		"@sRemarks		 = upper(Remarks),"+CHAR(10)+
		"@nRemarksOperator	 = RemarksOperator,"+CHAR(10)+	
		"@sTextTypeKey		 = TextTypeKey,"+CHAR(10)+ 
		"@sText			 = Text,"+CHAR(10)+
		"@nTextOperator		 = TextOperator,"+CHAR(10)+
		"@bIsMainAddress	 = IsMainAddress,"+CHAR(10)+
		"@bIsCorrespondence	 = IsCorrespondence,"+CHAR(10)+
		"@bIsStreet		 = IsStreet,"+CHAR(10)+
		"@sCountryKey		 = CountryKey,"+CHAR(10)+
		"@nCountryKeyOperator	 = CountryKeyOperator,"+CHAR(10)+
		"@sStateKey		 = StateKey,"+CHAR(10)+
		"@nStateKeyOperator	 = StateKeyOperator,"+CHAR(10)+
		"@sCity			 = upper(City),"+CHAR(10)+
		"@nCityOperator		 = CityOperator,"+CHAR(10)+ 
		"@sStreet1		 = upper(Street1),"+CHAR(10)+
		"@nStreet1Operator	 = Street1Operator,"+CHAR(10)+
		"@sPostCode		 = PostCode,"+CHAR(10)+
		"@nPostCodeOperator	 = PostCodeOperator,"+CHAR(10)+	
		"@sNameTypeKey		 = NameTypeKey,"+CHAR(10)+
		"@nNameTypeKeyOperator	 = NameTypeKeyOperator"+CHAR(10)+			
	"from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
	"WITH ("+CHAR(10)+
	"AnySearch		nvarchar(254)	'AnySearch/text()',"+CHAR(10)+
	"IsOrganisation		bit		'EntityFlags/IsOrganisation/text()',"+CHAR(10)+
	"IsIndividual		bit		'EntityFlags/IsIndividual/text()',"+CHAR(10)+	
	"IsStaff		bit		'EntityFlags/IsStaff/text()',"+CHAR(10)+
	"IsClient		bit		'IsClient/text()',"+CHAR(10)+	
	"SuitableForNameTypeKey	nvarchar(3)	'SuitableForNameTypeKey/text()',"+CHAR(10)+	
	"IsCurrent		bit		'IsCurrent',"+CHAR(10)+	
	"IsCeased		bit		'IsCeased',"+CHAR(10)+
	"IsSupplier		bit		'IsSupplier',"+CHAR(10)+
	"IsLead			bit		'IsLead',"+CHAR(10)+
	"IsCRM			bit		'IsCRM',"+CHAR(10)+
	"IsEntity		bit		'IsEntity',"+CHAR(10)+
	"SearchKey		nvarchar(20)	'SearchKey/text()',"+CHAR(10)+	
	"UseSearchKey1		bit		'SearchKey/@UseSearchKey1',"+CHAR(10)+
	"UseSearchKey2		bit		'SearchKey/@UseSearchKey2',"+CHAR(10)+ 	
	"SearchKeyOperator	tinyint		'SearchKey/@Operator/text()',"+CHAR(10)+
	"SoundsLikeSearchKey	bit		'SearchKey/@UseSoundsLike',"+CHAR(10)+
	"Name			nvarchar(254)	'Name/text()',"+CHAR(10)+
	"NameOperator		tinyint		'Name/@Operator/text()',"+CHAR(10)+	
	"SoundsLikeName		bit		'Name/@UseSoundsLike',"+CHAR(10)+
	"NameCode		nvarchar(10)	'NameCode/text()',"+CHAR(10)+
	"NameCodeOperator	tinyint		'NameCode/@Operator/text()',"+CHAR(10)+
	"FirstName		nvarchar(50)	'FirstName/text()',"+CHAR(10)+
	"FirstNameOperator 	tinyint 	'FirstName/@Operator/text()',"+CHAR(10)+
	"LastChangedFromDate	datetime	'LastChanged/DateFrom/text()',"+CHAR(10)+	
	"LastChangedToDate	datetime	'LastChanged/DateTo/text()',"+CHAR(10)+
	"LastChangedOperator	tinyint		'LastChanged/@Operator/text()',"+CHAR(10)+
	"Remarks		nvarchar(254)	'Remarks/text()',"+CHAR(10)+
	"RemarksOperator	tinyint		'Remarks/@Operator/text()',"+CHAR(10)+
	"TextTypeKey		nvarchar(2)	'NameText/TypeKey/text()',"+CHAR(10)+
	"Text			nvarchar(4000)	'NameText/Text/text()',"+CHAR(10)+
	"TextOperator		tinyint		'NameText/@Operator/text()',"+CHAR(10)+	
	"IsMainAddress		bit		'Address/IsMain/text()',"+CHAR(10)+	
	"IsCorrespondence	bit		'Address/IsCorrespondence/text()',"+CHAR(10)+	
	"IsStreet		bit		'Address/IsStreet/text()',"+CHAR(10)+				      						      	
	"CountryKey		nvarchar(3)	'Address/CountryKey/text()',"+CHAR(10)+
	"CountryKeyOperator	tinyint		'Address/CountryKey/@Operator/text()',"+CHAR(10)+
	"StateKey		nvarchar(20)	'Address/StateKey/text()',"+CHAR(10)+
	"StateKeyOperator	tinyint		'Address/StateKey/@Operator/text()',"+CHAR(10)+
	"City			nvarchar(30)	'Address/City/text()',"+CHAR(10)+		   	
	"CityOperator		tinyint		'Address/City/@Operator/text()',"+CHAR(10)+		
	"Street1		nvarchar(254)	'Address/Street1/text()',"+CHAR(10)+	
	"Street1Operator	tinyint		'Address/Street1/@Operator/text()',"+CHAR(10)+	
	"PostCode		nvarchar(10)	'Address/PostCode/text()',"+CHAR(10)+	
	"PostCodeOperator	tinyint		'Address/PostCode/@Operator/text()',"+CHAR(10)+	
	"NameTypeKey		nvarchar(3)	'NameTypeKey/text()',"+CHAR(10)+	
	"NameTypeKeyOperator	tinyint		'NameTypeKey/@Operator/text()'"+CHAR(10)+		
	")"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sAnySearch 			nvarchar(254)			output,
				  @pbIsOrganisation		bit				output,
				  @pbIsIndividual		bit				output,
				  @pbIsStaff			bit				output,
				  @pbIsClient			bit				output,				
				  @sSuitableForNameTypeKey	nvarchar(3)			output,
				  @bIsCurrent			bit				output,	
				  @bIsCeased			bit				output,		
				  @bIsSupplier			bit				output,
				  @bIsLead			bit				output,		
				  @bIsCRM			bit				output,
				  @sSearchKey			nvarchar(20)			output,
				  @bUseSearchKey1		bit				output,	
				  @bUseSearchKey2		bit				output, 	 	
				  @nSearchKeyOperator 		tinyint				output,
				  @bSoundsLikeSearchKey		bit				output,
				  @sName			nvarchar(254)			output,
				  @nNameOperator		tinyint				output,	
				  @bSoundsLikeName		bit				output,
				  @sNameCode			nvarchar(10)			output,
				  @nNameCodeOperator		tinyint				output,	
				  @sFirstName			nvarchar(50)			output,	
				  @nFirstNameOperator		tinyint				output,
				  @dtLastChangedFromDate	datetime			output,
				  @dtLastChangedToDate		datetime			output,
				  @nLastChangedOperator		tinyint				output,
				  @sRemarks			nvarchar(254)			output,
				  @nRemarksOperator		tinyint				output,
				  @sTextTypeKey			nvarchar(2)			output,
				  @sText			nvarchar(4000)			output,
				  @nTextOperator		tinyint				output,
				  @bIsMainAddress		bit				output,
				  @bIsCorrespondence		bit				output,
				  @bIsStreet			bit				output,
				  @sCountryKey			nvarchar(3)			output,
				  @nCountryKeyOperator		tinyint				output,
				  @sStateKey			nvarchar(20)			output,
				  @nStateKeyOperator		tinyint				output,
				  @sCity			nvarchar(30)			output,
				  @nCityOperator		tinyint				output,
				  @sStreet1			nvarchar(254)			output,
				  @nStreet1Operator		tinyint				output,
				  @sPostCode			nvarchar(10)			output,
				  @nPostCodeOperator		tinyint				output,				  
				  @sNameTypeKey			nvarchar(3)			output,
				  @nNameTypeKeyOperator		tinyint				output,
				  @bIsEntity			bit				output',	
				  @idoc				= @idoc,
				  @sAnySearch 			= @sAnySearch			output,
				  @pbIsOrganisation		= @pbIsOrganisation		output,
				  @pbIsIndividual		= @pbIsIndividual		output,
				  @pbIsStaff			= @pbIsStaff			output,
				  @pbIsClient			= @pbIsClient			output,				
				  @sSuitableForNameTypeKey	= @sSuitableForNameTypeKey 	output,
				  @bIsCurrent			= @bIsCurrent			output,
				  @bIsCeased			= @bIsCeased			output,
				  @bIsSupplier			= @bIsSupplier			output,
				  @bIsLead			= @bIsLead			output,
				  @bIsCRM			= @bIsCRM			output,
				  @sSearchKey			= @sSearchKey			output,
				  @bUseSearchKey1		= @bUseSearchKey1		output,
				  @bUseSearchKey2		= @bUseSearchKey2		output,
				  @nSearchKeyOperator 		= @nSearchKeyOperator		output,
				  @bSoundsLikeSearchKey		= @bSoundsLikeSearchKey		output,
				  @sName			= @sName			output,
				  @nNameOperator		= @nNameOperator		output,
				  @bSoundsLikeName		= @bSoundsLikeName		output,
				  @sNameCode			= @sNameCode			output,
				  @nNameCodeOperator		= @nNameCodeOperator		output,
				  @sFirstName			= @sFirstName			output,		
				  @nFirstNameOperator		= @nFirstNameOperator		output,
				  @dtLastChangedFromDate	= @dtLastChangedFromDate	output,
				  @dtLastChangedToDate		= @dtLastChangedToDate		output,
				  @nLastChangedOperator		= @nLastChangedOperator		output,
				  @sRemarks			= @sRemarks			output,
				  @nRemarksOperator		= @nRemarksOperator		output,
				  @sTextTypeKey			= @sTextTypeKey			output,
				  @sText			= @sText			output,
				  @nTextOperator		= @nTextOperator		output,
				  @bIsMainAddress		= @bIsMainAddress		output,
				  @bIsCorrespondence		= @bIsCorrespondence		output,
				  @bIsStreet			= @bIsStreet			output,
				  @sCountryKey			= @sCountryKey			output,
				  @nCountryKeyOperator		= @nCountryKeyOperator		output,
				  @sStateKey			= @sStateKey			output,
				  @nStateKeyOperator		= @nStateKeyOperator		output,
				  @sCity			= @sCity			output,
				  @nCityOperator		= @nCityOperator		output,
				  @sStreet1			= @sStreet1			output,
				  @nStreet1Operator		= @nStreet1Operator		output,
				  @sPostCode			= @sPostCode			output,
				  @nPostCodeOperator		= @nPostCodeOperator		output,				  
				  @sNameTypeKey			= @sNameTypeKey			output,
				  @nNameTypeKeyOperator		= @nNameTypeKeyOperator		output,
				  @bIsEntity			= @bIsEntity			output	

	Set @sSQLString = 	
	"Select @nNameCategoryKey 	= NameCategoryKey,"+CHAR(10)+
		"@nNameCategoryKeyOperator	= NameCategoryKeyOperator,"+CHAR(10)+	
		"@nBadDebtorKey			= BadDebtorKey,"+CHAR(10)+
		"@nBadDebtorKeyOperator		= BadDebtorKeyOperator,"+CHAR(10)+
		"@sFilesInKey			= FilesInKey,"+CHAR(10)+				
		"@nFilesInKeyOperator		= FilesInKeyOperator,"+CHAR(10)+
		"@nInstructionKey		= InstructionKey,"+CHAR(10)+
		"@nInstructionKeyOperator	= InstructionKeyOperator,"+CHAR(10)+
		"@sCompanyNo		 = CompanyNo,"+CHAR(10)+
		"@nCompanyNoOperator	 = CompanyNoOperator,"+CHAR(10)+
		"@sTaxNo		 = TaxNo,"+CHAR(10)+
		"@nTaxNoOperator	 = TaxNoOperator,"+CHAR(10)+	
		"@nParentNameKey		= ParentNameKey,"+CHAR(10)+
		"@nParentNameKeyOperator	= ParentNameKeyOperator,"+CHAR(10)+
		"@sRelationshipKey		= RelationshipKey,"+CHAR(10)+
		"@bIsReverseRelationship 	= IsReverseRelationship,"+CHAR(10)+
		"@sAssociatedNameKeys		= AssociatedNameKeys,"+CHAR(10)+
		"@nAssociatedNameKeyOperator	= AssociatedNameKeyOperator,"+CHAR(10)+
		"@sMainPhoneNumber		= MainPhoneNumber,"+CHAR(10)+
		"@nMainPhoneNumberOperator	= MainPhoneNumberOperator,"+CHAR(10)+	
		"@sMainPhoneAreaCode		= MainPhoneAreaCode,"+CHAR(10)+
		"@nMainPhoneAreaCodeOperator	= MainPhoneAreaCodeOperator,"+CHAR(10)+	
		"@sAliasTypeKey			= AliasTypeKey,"+CHAR(10)+		
		"@sAlias			= upper(Alias),"+CHAR(10)+	
		"@nAliasOperator		= AliasOperator,"+CHAR(10)+
		"@sQuickIndexKey		= QuickIndexKey,"+CHAR(10)+
		"@nQuickIndexKeyOperator	= QuickIndexKeyOperator,"+CHAR(10)+
		"@sBillingCurrencyKey		= BillingCurrencyKey,"+CHAR(10)+
		"@nBillingCurrencyKeyOperator	= BillingCurrencyKeyOperator,"+CHAR(10)+	
		"@sTaxRateKey			= TaxRateKey,"+CHAR(10)+ 
		"@nTaxRateKeyOperator		= TaxRateKeyOperator,"+CHAR(10)+	
		"@nDebtorTypeKey		= DebtorTypeKey,"+CHAR(10)+
		"@nDebtorTypeKeyOperator	= DebtorTypeKeyOperator,"+CHAR(10)+
		"@sPurchaseOrderNo		= upper(PurchaseOrderNo),"+CHAR(10)+
		"@nPurchaseOrderNoOperator	= PurchaseOrderNoOperator,"+CHAR(10)+
		"@nBillingFrequencyKey		= BillingFrequencyKey,"+CHAR(10)+
		"@nBillingFrequencyKeyOperator	= BillingFrequencyKeyOperator,"+CHAR(10)+
		"@bIsLocalClient		= IsLocalClient,"+CHAR(10)+ 
		"@nIsLocalClientOperator	= IsLocalClientOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"WITH ("+CHAR(10)+
		"NameCategoryKey	 int	'NameCategoryKey/text()',"+CHAR(10)+
		"NameCategoryKeyOperator tinyint 'NameCategoryKey/@Operator/text()',"+CHAR(10)+
		"BadDebtorKey		 int	'BadDebtorKey/text()',"+CHAR(10)+	
		"BadDebtorKeyOperator	tinyint	'BadDebtorKey/@Operator/text()',"+CHAR(10)+
		"FilesInKey		nvarchar(3) 'FilesInKey/text()',"+CHAR(10)+	
		"FilesInKeyOperator	tinyint	'FilesInKey/@Operator/text()',"+CHAR(10)+
		"InstructionKey		int	'InstructionKey/text()',"+CHAR(10)+
		"InstructionKeyOperator	tinyint	'InstructionKey/@Operator/text()',"+CHAR(10)+
		"CompanyNo			nvarchar(60)	'CompanyNo/text()',"+CHAR(10)+
		"CompanyNoOperator		tinyint		'CompanyNo/@Operator/text()',"+CHAR(10)+	
		"TaxNo			nvarchar(60)	'TaxNo/text()',"+CHAR(10)+
		"TaxNoOperator		tinyint		'TaxNo/@Operator/text()',"+CHAR(10)+
		"ParentNameKey		int	'ParentNameKey/text()',"+CHAR(10)+	
		"ParentNameKeyOperator	tinyint	'ParentNameKey/@Operator/text()',"+CHAR(10)+
		"RelationshipKey	nvarchar(3) 'AssociatedName/RelationshipKey/text()',"+CHAR(10)+ 	
		"IsReverseRelationship	bit	'AssociatedName/@IsReverseRelationship',"+CHAR(10)+
		"AssociatedNameKeys	nvarchar(4000) 'AssociatedName/NameKeys/text()',"+CHAR(10)+
		"AssociatedNameKeyOperator tinyint 'AssociatedName/@Operator/text()',"+CHAR(10)+
		"MainPhoneNumber	nvarchar(50) 'MainPhone/Number/text()',"+CHAR(10)+	
		"MainPhoneNumberOperator tinyint 'MainPhone/Number/@Operator/text()',"+CHAR(10)+
		"MainPhoneAreaCode	nvarchar(5) 'MainPhone/AreaCode/text()',"+CHAR(10)+
		"MainPhoneAreaCodeOperator tinyint 'MainPhone/AreaCode/@Operator/text()',"+CHAR(10)+
		"AliasTypeKey		nvarchar(2) 'NameAlias/TypeKey/text()',"+CHAR(10)+
		"Alias		 	nvarchar(20) 'NameAlias/Alias/text()',"+CHAR(10)+
		"AliasOperator		tinyint	'NameAlias/@Operator/text()',"+CHAR(10)+	
		"QuickIndexKey		nvarchar(10) 'QuickIndex/text()',"+CHAR(10)+
		"QuickIndexKeyOperator	tinyint	'QuickIndex/@Operator/text()',"+CHAR(10)+
		"BillingCurrencyKey	nvarchar(3) 'BillingCurrency/text()',"+CHAR(10)+
		"BillingCurrencyKeyOperator tinyint 'BillingCurrency/@Operator/text()',"+CHAR(10)+
		"TaxRateKey		nvarchar(3) 'TaxRateKey/text()',"+CHAR(10)+
		"TaxRateKeyOperator	tinyint	'TaxRateKey/@Operator/text()',"+CHAR(10)+
		"DebtorTypeKey		int	'DebtorTypeKey/text()',"+CHAR(10)+					      						      	
		"DebtorTypeKeyOperator	tinyint	'DebtorTypeKey/@Operator/text()',"+CHAR(10)+
		"PurchaseOrderNo	nvarchar(80) 'PurchaseOrderNo/text()',"+CHAR(10)+
		"PurchaseOrderNoOperator tinyint 'PurchaseOrderNo/@Operator/text()',"+CHAR(10)+
		"BillingFrequencyKey	int	'BillingFrequency/text()',"+CHAR(10)+
		"BillingFrequencyKeyOperator tinyint 'BillingFrequency/@Operator/text()',"+CHAR(10)+		   	
		-- Do not default the IsLocalClient to 0 if it is null as it has an Operator to cater for 'IsLocalClient = null' situation
		"IsLocalClient		bit	'IsLocalClient/text()',"+CHAR(10)+		
		"IsLocalClientOperator	tinyint	'IsLocalClient/@Operator/text()'"+CHAR(10)+
	")"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nNameCategoryKey		int				output,
				  @nNameCategoryKeyOperator	tinyint				output,
				  @nBadDebtorKey		int				output,
				  @nBadDebtorKeyOperator	tinyint				output,
				  @sCompanyNo			nvarchar(60)		output,
				  @nCompanyNoOperator		tinyint		output,
				  @sTaxNo			nvarchar(60)		output,
				  @nTaxNoOperator		tinyint		output,
				  @sFilesInKey			nvarchar(3)			output,				
				  @nFilesInKeyOperator		tinyint				output,	
				  @nInstructionKey		int				output,		
				  @nInstructionKeyOperator	tinyint				output,
				  @nParentNameKey		int				output,
				  @nParentNameKeyOperator	tinyint				output,	
				  @sRelationshipKey		nvarchar(3)			output, 	 	
				  @bIsReverseRelationship 	bit				output,
				  @sAssociatedNameKeys		nvarchar(4000)			output,
				  @nAssociatedNameKeyOperator	tinyint				output,
				  @sMainPhoneNumber		nvarchar(50)			output,	
				  @nMainPhoneNumberOperator	tinyint				output,
				  @sMainPhoneAreaCode		nvarchar(5)			output,
				  @nMainPhoneAreaCodeOperator	tinyint				output,	
				  @sAliasTypeKey		nvarchar(2)			output,	
				  @sAlias			nvarchar(20)			output,
				  @nAliasOperator		tinyint				output,
				  @sQuickIndexKey		nvarchar(10)			output,
				  @nQuickIndexKeyOperator	tinyint				output,
				  @sBillingCurrencyKey		nvarchar(3)			output,
				  @nBillingCurrencyKeyOperator	tinyint				output,
				  @sTaxRateKey			nvarchar(3)			output,
				  @nTaxRateKeyOperator		tinyint				output,
				  @nDebtorTypeKey		int				output,
				  @nDebtorTypeKeyOperator	tinyint				output,
				  @sPurchaseOrderNo		nvarchar(80)			output,
				  @nPurchaseOrderNoOperator	tinyint				output,
				  @nBillingFrequencyKey		int				output,
				  @nBillingFrequencyKeyOperator	tinyint				output,
				  @bIsLocalClient		bit				output,
				  @nIsLocalClientOperator	tinyint				output',	
				  @idoc				= @idoc,
				  @nNameCategoryKey 		= @nNameCategoryKey		output,
				  @nNameCategoryKeyOperator	= @nNameCategoryKeyOperator	output,
				  @nBadDebtorKey		= @nBadDebtorKey		output,
				  @nBadDebtorKeyOperator	= @nBadDebtorKeyOperator	output,
				  @sCompanyNo			= @sCompanyNo		output,
				  @nCompanyNoOperator	= @nCompanyNoOperator		output,
				  @sTaxNo				= @sTaxNo		output,
				  @nTaxNoOperator		= @nTaxNoOperator		output,
				  @sFilesInKey			= @sFilesInKey			output,				
				  @nFilesInKeyOperator		= @nFilesInKeyOperator		output,
				  @nInstructionKey		= @nInstructionKey		output,
				  @nInstructionKeyOperator	= @nInstructionKeyOperator	output,
				  @nParentNameKey		= @nParentNameKey		output,
				  @nParentNameKeyOperator	= @nParentNameKeyOperator	output,
				  @sRelationshipKey		= @sRelationshipKey		output,
				  @bIsReverseRelationship 	= @bIsReverseRelationship	output,
				  @sAssociatedNameKeys		= @sAssociatedNameKeys		output,
				  @nAssociatedNameKeyOperator	= @nAssociatedNameKeyOperator	output,
				  @sMainPhoneNumber		= @sMainPhoneNumber		output,
				  @nMainPhoneNumberOperator	= @nMainPhoneNumberOperator	output,
				  @sMainPhoneAreaCode		= @sMainPhoneAreaCode		output,
				  @nMainPhoneAreaCodeOperator	= @nMainPhoneAreaCodeOperator	output,
				  @sAliasTypeKey		= @sAliasTypeKey		output,		
				  @sAlias			= @sAlias			output,
				  @nAliasOperator		= @nAliasOperator		output,
				  @sQuickIndexKey		= @sQuickIndexKey		output,
				  @nQuickIndexKeyOperator	= @nQuickIndexKeyOperator	output,
				  @sBillingCurrencyKey		= @sBillingCurrencyKey		output,
				  @nBillingCurrencyKeyOperator	= @nBillingCurrencyKeyOperator	output,
				  @sTaxRateKey			= @sTaxRateKey			output, 
				  @nTaxRateKeyOperator		= @nTaxRateKeyOperator		output,
				  @nDebtorTypeKey		= @nDebtorTypeKey		output,
				  @nDebtorTypeKeyOperator	= @nDebtorTypeKeyOperator	output,
				  @sPurchaseOrderNo		= @sPurchaseOrderNo		output,
				  @nPurchaseOrderNoOperator	= @nPurchaseOrderNoOperator	output,
				  @nBillingFrequencyKey		= @nBillingFrequencyKey		output,
				  @nBillingFrequencyKeyOperator	= @nBillingFrequencyKeyOperator	output,
				  @bIsLocalClient		= @bIsLocalClient		output,
				  @nIsLocalClientOperator	= @nIsLocalClientOperator	output

		Set @sSQLString = 	
		"Select @sNameKey		= NameKey,"+CHAR(10)+		
			"@nReceivableTermsFromDays	= ReceivableTermsFromDays,"+CHAR(10)+
			"@nReceivableTermsToDays	= ReceivableTermsToDays,"+CHAR(10)+
			"@nReceivableTermsOperator	= ReceivableTermsOperator,"+CHAR(10)+
			"@bIncludeInherited		= IncludeInherited,"+CHAR(10)+
			"@sAirportKey			= AirportKey,"+CHAR(10)+
			"@nAirportKeyOperator		= AirportKeyOperator,"+CHAR(10)+			
			"@nNameGroupKey			= NameGroupKey,"+CHAR(10)+
			"@nNameGroupKeyOperator		= NameGroupKeyOperator,"+CHAR(10)+
			"@nStaffClassificationKey	= StaffClassificationKey,"+CHAR(10)+
			"@nStaffClassificationOperator	= StaffClassificationOperator,"+CHAR(10)+
			"@sStaffProfitCentreKey		= StaffProfitCentreKey,"+CHAR(10)+
			"@nStaffProfitCentreOperator	= StaffProfitCentreOperator,"+CHAR(10)+
			"@nFromAmount			= FromAmount,"+CHAR(10)+			
			"@nToAmount			= ToAmount,"+CHAR(10)+	
			"@nDebtorCreditLimitOperator	= DebtorCreditLimitOperator,"+CHAR(10)+
			"@nSupplierTypeKey		= SupplierTypeKey,"+CHAR(10)+
			"@nSupplierTypeKeyOperator	= SupplierTypeKeyOperator,"+CHAR(10)+
			"@nSupplierRestrictionKey	= SupplierRestrictionKey,"+CHAR(10)+
			"@nSupplierRestrictionOperator	= SupplierRestrictionOperator,"+CHAR(10)+
			"@sPurchaseCurrency		= PurchaseCurrency,"+CHAR(10)+
			"@nPurchaseCurrencyOperator	= PurchaseCurrencyOperator,"+CHAR(10)+			
			"@nSupplierPaymentTermsKey	= SupplierPaymentTermsKey,"+CHAR(10)+
			"@nSupplierPaymentTermsOperator	= SupplierPaymentTermsOperator,"+CHAR(10)+
			"@nSupplierPaymentMethodKey	= SupplierPaymentMethodKey,"+CHAR(10)+
			"@nSupplierPaymentMethodOperator = SupplierPaymentMethodOperator,"+CHAR(10)+			
			"@sSupplierAccountNo		= SupplierAccountNo,"+CHAR(10)+
			"@nSupplierAccountNoOperator	= SupplierAccountNoOperator,"+CHAR(10)+
			"@bUseMainName			= UseMainName,"+CHAR(10)+
			"@bUseVariantName		= UseVariantName"+CHAR(10)+
		"from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"WITH ("+CHAR(10)+
		"NameKey			nvarchar(11)	'NameKey/text()',"+CHAR(10)+
		"ReceivableTermsFromDays	int		'ReceivableTerms/FromDays/text()',"+CHAR(10)+		
		"ReceivableTermsToDays		int		'ReceivableTerms/ToDays/text()',"+CHAR(10)+	
		"ReceivableTermsOperator	tinyint		'ReceivableTerms/@Operator/text()',"+CHAR(10)+	
		"IncludeInherited		bit		'InstructionKey/@IncludeInherited/text()',"+CHAR(10)+
		"AirportKey			nvarchar(5)	'AirportKey/text()',"+CHAR(10)+	
		"AirportKeyOperator		tinyint		'AirportKey/@Operator/text()',"+CHAR(10)+	
		"NameGroupKey			smallint	'NameGroupKey/text()',"+CHAR(10)+	
		"NameGroupKeyOperator		tinyint		'NameGroupKey/@Operator/text()',"+CHAR(10)+			
		"StaffClassificationKey		int		'StaffClassificationKey/text()',"+CHAR(10)+
		"StaffClassificationOperator 	tinyint		'StaffClassificationKey/@Operator/text()',"+CHAR(10)+				
		"StaffProfitCentreKey		nvarchar(6)	'StaffProfitCentreKey/text()',"+CHAR(10)+	
		"StaffProfitCentreOperator	tinyint		'StaffProfitCentreKey/@Operator/text()',"+CHAR(10)+	
		"FromAmount			decimal(11,2)	'DebtorCreditLimit/FromAmount/text()',"+CHAR(10)+	
		"ToAmount			decimal(11,2)	'DebtorCreditLimit/ToAmount/text()',"+CHAR(10)+	
		"DebtorCreditLimitOperator	tinyint		'DebtorCreditLimit/@Operator/text()',"+CHAR(10)+	
		"SupplierTypeKey		int		'SupplierTypeKey/text()',"+CHAR(10)+	
		"SupplierTypeKeyOperator	tinyint		'SupplierTypeKey/@Operator/text()',"+CHAR(10)+	
		"SupplierRestrictionKey		int		'SupplierRestrictionKey/text()',"+CHAR(10)+	
		"SupplierRestrictionOperator 	tinyint		'SupplierRestrictionKey/@Operator/text()',"+CHAR(10)+	
		"PurchaseCurrency		nvarchar(3)	'PurchaseCurrency/text()',"+CHAR(10)+	
		"PurchaseCurrencyOperator	tinyint		'PurchaseCurrency/@Operator/text()',"+CHAR(10)+		
		"SupplierPaymentTermsKey	int		'SupplierPaymentTermsKey/text()',"+CHAR(10)+	
		"SupplierPaymentTermsOperator 	tinyint		'SupplierPaymentTermsKey/@Operator/text()',"+CHAR(10)+	
		"SupplierPaymentMethodKey 	int		'SupplierPaymentMethodKey/text()',"+CHAR(10)+	
		"SupplierPaymentMethodOperator 	tinyint		'SupplierPaymentMethodKey/@Operator/text()',"+CHAR(10)+	
		"SupplierAccountNo		nvarchar(30)	'SupplierAccountNo/text()',"+CHAR(10)+	
		"SupplierAccountNoOperator 	tinyint		'SupplierAccountNo/@Operator/text()',"+CHAR(10)+	
		"UseMainName			bit		'NameSearchType/@UseMainName/text()',"+CHAR(10)+
		"UseVariantName		bit		'NameSearchType/@UseVariantName/text()'"+CHAR(10)+
	     	")"
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc					int,
					  @sNameKey 				nvarchar(11)			output,					 
					  @nReceivableTermsFromDays		int				output,
				  	  @nReceivableTermsToDays		int				output,
				  	  @nReceivableTermsOperator		tinyint				output,
					  @bIncludeInherited			bit				output,
					  @sAirportKey				nvarchar(5)			output,
				  	  @nAirportKeyOperator			tinyint				output,
					  @nNameGroupKey			smallint			output,
				  	  @nNameGroupKeyOperator		tinyint				output,
					  @nStaffClassificationKey		int				output,
					  @nStaffClassificationOperator 	tinyint				output,
					  @sStaffProfitCentreKey		nvarchar(6)			output,
					  @nStaffProfitCentreOperator		tinyint				output,
					  @nFromAmount				decimal(11,2)			output,
					  @nToAmount				decimal(11,2)			output,
					  @nDebtorCreditLimitOperator		tinyint				output,
					  @nSupplierTypeKey			int				output,
					  @nSupplierTypeKeyOperator		tinyint				output,
					  @nSupplierRestrictionKey		int				output,
					  @nSupplierRestrictionOperator 	tinyint				output,
					  @sPurchaseCurrency			nvarchar(3) 			output,
					  @nPurchaseCurrencyOperator		tinyint				output,
					  @nSupplierPaymentTermsKey		int				output,
					  @nSupplierPaymentTermsOperator 	tinyint				output,
					  @nSupplierPaymentMethodKey		int				output,
					  @nSupplierPaymentMethodOperator 	tinyint				output,
					  @sSupplierAccountNo			nvarchar(30)			output,
					  @nSupplierAccountNoOperator		tinyint				output,
					  @bUseMainName				bit				output,
					  @bUseVariantName			bit				output',	
					  @idoc					= @idoc,
					  @sNameKey 				= @sNameKey			output,					  
				          @nReceivableTermsFromDays		= @nReceivableTermsFromDays 	output,
				  	  @nReceivableTermsToDays		= @nReceivableTermsToDays	output,
				  	  @nReceivableTermsOperator		= @nReceivableTermsOperator	output,
					  @bIncludeInherited			= @bIncludeInherited		output,
					  @sAirportKey				= @sAirportKey			output,
				  	  @nAirportKeyOperator			= @nAirportKeyOperator		output,
					  @nNameGroupKey			= @nNameGroupKey		output,
				 	  @nNameGroupKeyOperator		= @nNameGroupKeyOperator	output,
					  @nStaffClassificationKey		= @nStaffClassificationKey	output,
					  @nStaffClassificationOperator 	= @nStaffClassificationOperator output,
					  @sStaffProfitCentreKey		= @sStaffProfitCentreKey	output,
					  @nStaffProfitCentreOperator		= @nStaffProfitCentreOperator 	output,
					  @nFromAmount				= @nFromAmount 			output,
					  @nToAmount				= @nToAmount			output,
					  @nDebtorCreditLimitOperator		= @nDebtorCreditLimitOperator	output,
					  @nSupplierTypeKey			= @nSupplierTypeKey		output,
					  @nSupplierTypeKeyOperator		= @nSupplierTypeKeyOperator	output,
					  @nSupplierRestrictionKey		= @nSupplierRestrictionKey	output,
				  	  @nSupplierRestrictionOperator		= @nSupplierRestrictionOperator	output,
			 		  @sPurchaseCurrency			= @sPurchaseCurrency		output,
					  @nPurchaseCurrencyOperator		= @nPurchaseCurrencyOperator	output,
					  @nSupplierPaymentTermsKey		= @nSupplierPaymentTermsKey	output,
					  @nSupplierPaymentTermsOperator 	= @nSupplierPaymentTermsOperator output,
					  @nSupplierPaymentMethodKey		= @nSupplierPaymentMethodKey	output,
					  @nSupplierPaymentMethodOperator	= @nSupplierPaymentMethodOperator output,
					  @sSupplierAccountNo			= @sSupplierAccountNo		output,
					  @nSupplierAccountNoOperator		= @nSupplierAccountNoOperator 	output,
					  @bUseMainName				= @bUseMainName			output,
					  @bUseVariantName			= @bUseVariantName		output 

		Set @sSQLString = 	
		"Select @bAccessAccountKeyForCurrentUser = AccessAccountKeyForCurrentUser,"+CHAR(10)+
		"	@bAccessAccountKeyIsAccessName	= AccessAccountKeyIsAccessName,"+CHAR(10)+
		"	@bAccessAccountKeyIsAccessEmployee = AccessAccountKeyIsAccessEmployee,"+CHAR(10)+
		"	@bAccessAccountKeyIsUserName	= AccessAccountKeyIsUserName,"+CHAR(10)+
		"	@nAccessAccountKey		= AccessAccountKey,"+CHAR(10)+
		"	@nAccessAccountKeyOperator	= AccessAccountKeyOperator,"+CHAR(10)+
		"	@nNameStatusKey			= NameStatusKey,"+CHAR(10)+
		"	@nNameStatusOperator		= NameStatusOperator,"+CHAR(10)+
		"	@nNameSourceKey			= NameSourceKey,"+CHAR(10)+
		"	@nNameSourceOperator		= NameSourceOperator,"+CHAR(10)+
		"	@nLeadEstRevFrom		= LeadEstimatedRevFrom,"+CHAR(10)+
		"	@nLeadEstRevTo			= LeadEstimatedRevTo,"+CHAR(10)+
		"	@nLeadEstRevOperator		= LeadEstimatedRevOperator,"+CHAR(10)+
		"	@sLeadEstRevCurrency		= LeadEstRevCurrency,"+CHAR(10)+
		"	@nLeadEstRevCurrencyOperator	= LeadEstRevCurrencyOperator"+CHAR(10)+
		"from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"      AccessAccountKeyForCurrentUser	bit	'AccessAccountKey/@ForCurrentUser/text()',"+CHAR(10)+	
		"      AccessAccountKeyIsAccessName	bit	'AccessAccountKey/@IsAccessName/text()',"+CHAR(10)+	
		"      AccessAccountKeyIsAccessEmployee	bit	'AccessAccountKey/@IsAccessEmployee/text()',"+CHAR(10)+	
		"      AccessAccountKeyIsUserName	bit	'AccessAccountKey/@IsUserName/text()',"+CHAR(10)+	
		"      AccessAccountKey			int	'AccessAccountKey/text()',"+CHAR(10)+	
		"      AccessAccountKeyOperator		tinyint	'AccessAccountKey/@Operator/text()',"+CHAR(10)+	
		"      NameStatusKey			int	'NameStatusKey/text()',"+CHAR(10)+
		"      NameStatusOperator		tinyint	'NameStatusKey/@Operator/text()',"+CHAR(10)+
		"      NameSourceKey			int	'NameSourceKey/text()',"+CHAR(10)+
		"      NameSourceOperator		tinyint	'NameSourceKey/@Operator/text()',"+CHAR(10)+
		"	LeadEstimatedRevFrom		decimal(11,2) 	'LeadEstimatedRev/From/text()',"+CHAR(10)+
		"	LeadEstimatedRevTo		decimal(11,2) 	'LeadEstimatedRev/To/text()',"+CHAR(10)+
		"	LeadEstimatedRevOperator	tinyint		'LeadEstimatedRev/@Operator/text()',"+CHAR(10)+
		"	LeadEstRevCurrency		nvarchar(3)	'LeadEstimatedRev/Currency/text()',"+CHAR(10)+
		"	LeadEstRevCurrencyOperator	tinyint		'LeadEstimatedRev/Currency/@Operator/text()'"+CHAR(10)+
	     	")"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc					int,
					  @bAccessAccountKeyForCurrentUser	bit		output,
					  @bAccessAccountKeyIsAccessName	bit		output,
					  @bAccessAccountKeyIsAccessEmployee	bit		output,
					  @bAccessAccountKeyIsUserName		bit		output,
					  @nAccessAccountKey			int		output,
					  @nAccessAccountKeyOperator		tinyint		output,
					  @nNameStatusKey			int		output,
					  @nNameStatusOperator			tinyint		output,
					  @nNameSourceKey			int		output,
					  @nNameSourceOperator			tinyint		output,
					  @nLeadEstRevFrom			decimal(11,2)	output,
					  @nLeadEstRevTo			decimal(11,2)	output,
					  @nLeadEstRevOperator			tinyint		output,
					  @sLeadEstRevCurrency			nvarchar(3)	output,
					  @nLeadEstRevCurrencyOperator		tinyint		output',
					  @idoc					= @idoc,
					  @bAccessAccountKeyForCurrentUser 	= @bAccessAccountKeyForCurrentUser output,
					  @bAccessAccountKeyIsAccessName 	= @bAccessAccountKeyIsAccessName output,
					  @bAccessAccountKeyIsAccessEmployee 	= @bAccessAccountKeyIsAccessEmployee output,
					  @bAccessAccountKeyIsUserName		= @bAccessAccountKeyIsUserName	output,
					  @nAccessAccountKey			= @nAccessAccountKey		output,
					  @nAccessAccountKeyOperator		= @nAccessAccountKeyOperator	output,
					  @nNameStatusKey			= @nNameStatusKey		output,
					  @nNameStatusOperator			= @nNameStatusOperator		output,      
					  @nNameSourceKey			= @nNameSourceKey		output,
					  @nNameSourceOperator			= @nNameSourceOperator		output,
					  @nLeadEstRevFrom			= @nLeadEstRevFrom		output,
					  @nLeadEstRevTo			= @nLeadEstRevTo		output,
					  @nLeadEstRevOperator			= @nLeadEstRevOperator		output,
					  @sLeadEstRevCurrency			= @sLeadEstRevCurrency		output,
					  @nLeadEstRevCurrencyOperator		= @nLeadEstRevCurrencyOperator	output

--To Filter the Names by Case Type and Property type
	Set @sSQLString =
		"Select @sCaseTypeKey			= CaseTypeKey,"+CHAR(10)+
		"@nCaseTypeKeyOperator		= CaseTypeKeyOperator,"+CHAR(10)+
		"@bIncludeCRMCases = IncludeCRMCases,"+CHAR(10)+
		"@sPropertyTypeKey		= PropertyTypeKey,"+CHAR(10)+
		"@nPropertyTypeKeyOperator 	= PropertyTypeKeyOperator,"+CHAR(10)+ 
		"@nPropertyTypeKeysOperator	= PropertyTypeKeysOperator,"+CHAR(10)+		
		"@bIsFilesDeptStaff		= IsFilesDeptStaff,"+CHAR(10)+	
		"@nCaseKey			= CaseKey,"+CHAR(10)+
		"@sCaseNameTypes		= CaseNameTypes"+CHAR(10)+
	    "from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"WITH ("+CHAR(10)+
		"CaseTypeKey		nchar(1)	'CaseTypeKey/text()',"+CHAR(10)+	
		"CaseTypeKeyOperator	tinyint		'CaseTypeKey/@Operator/text()',"+CHAR(10)+
		"IncludeCRMCases		bit		'CaseTypeKey/@IncludeCRMCases/text()',"+CHAR(10)+
		"PropertyTypeKey		nvarchar(200)	'PropertyTypeKey/text()',"+CHAR(10)+ 	
		"PropertyTypeKeyOperator	tinyint		'PropertyTypeKey/@Operator/text()',"+CHAR(10)+
		"PropertyTypeKeysOperator 	tinyint		'PropertyTypeKeys/@Operator/text()',"+CHAR(10)+
		"IsFilesDeptStaff               bit             'IsFilesDeptStaff/text()',"+CHAR(10)+
		"CaseKey			int		'CaseFilter/CaseKey/text()',"+CHAR(10)+
		"CaseNameTypes			nvarchar(100)	'CaseFilter/NameType/text()'"+CHAR(10)+
		")"
		
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sCaseTypeKey			nchar(1)			output,	
				  @nCaseTypeKeyOperator		tinyint				output,		
				  @bIncludeCRMCases		bit				output,
				  @sPropertyTypeKey		nvarchar(200)			output, 	 	
				  @nPropertyTypeKeyOperator 	tinyint				output,
				  @nPropertyTypeKeysOperator	tinyint				output,
				  @bIsFilesDeptStaff            bit                             output,
				  @nCaseKey			int				output,
				  @sCaseNameTypes		nvarchar(100)			output',
				  @idoc				= @idoc,
				  @sCaseTypeKey			= @sCaseTypeKey			output,
				  @nCaseTypeKeyOperator		= @nCaseTypeKeyOperator		output,
				  @bIncludeCRMCases		= @bIncludeCRMCases		output,
				  @sPropertyTypeKey		= @sPropertyTypeKey		output,
				  @nPropertyTypeKeyOperator 	= @nPropertyTypeKeyOperator	output,
				  @nPropertyTypeKeysOperator	= @nPropertyTypeKeysOperator	output,
				  @bIsFilesDeptStaff            = @bIsFilesDeptStaff            output,
				  @nCaseKey			= @nCaseKey			output,
				  @sCaseNameTypes		= @sCaseNameTypes		output

	-- Allow searching on multiple property types 		
	If @nPropertyTypeKeysOperator in (0,1)
	Begin
		Set @sSQLString = 	
		"Select @sPropertyTypeKeyList		= @sPropertyTypeKeyList + "+CHAR(10)+
			"nullif(',',','+@sPropertyTypeKeyList)+"+CHAR(10)+ 
		"	dbo.fn_WrapQuotes(PropertyTypeKey,0,@pbCalledFromCentura)"+CHAR(10)+	
		"from	OPENXML (@idoc, '//naw_ListName/FilterCriteriaGroup/FilterCriteria["+
			convert(nvarchar(3), @pnFilterGroupIndex)+"]/PropertyTypeKeys/PropertyTypeKey',2)"+CHAR(10)+
		"	WITH (PropertyTypeKey		nchar(1)	'text()')"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,					  
					@pbCalledFromCentura		tinyint,
					@sPropertyTypeKeyList		nvarchar(1000)			output',				
					@idoc				= @idoc,
					@pbCalledFromCentura		= @pbCalledFromCentura,					 
					@sPropertyTypeKeyList		= @sPropertyTypeKeyList		output	
	End

	Set @sRowPattern = "/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/AttributeGroup/Attribute"
		
	Insert into @tblAttributeGroup
	Select	*
	from	OPENXML (@idoc, @sRowPattern, 2)
	WITH (
		BooleanOr			bit		'@BooleanOr/text()',
		AttributeKey			int		'AttributeKey/text()',
		AttributeOperator		tinyint		'@Operator/text()',
		AttributeTypeKey		nvarchar(11)	'TypeKey/text()'
	     )

	Set @nAttributeRowCount = @@RowCount	
	
	Select @bAttributeBooleanOr = BooleanOr
	from OPENXML (@idoc, @sRowPattern, 2)
	WITH ( BooleanOr			bit		'../@BooleanOr/text()' )	

	Set @sRowPattern = "/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/AssociatedNameGroup/AssociatedName"
		
	Insert into @tblAssociateNameGroup
	Select	*
	from	OPENXML (@idoc, @sRowPattern, 2)
	WITH (
		AssociateNameKeys		nvarchar(4000)		'NameKeys/text()',
		AssociateNameOperator	tinyint		'@Operator/text()',
		AssociateNameIsReverseRelationship		tinyint		'@IsReverseRelationship',
		AssociateNameRelationshipKey		nvarchar(10)	'RelationshipKey/text()'
	     )

	Set @nAssociateNameRowCount = @@RowCount

        Set @sRowPattern = "/naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/NameKeys/NameKey"
        Insert into @tblNameKeys
	Select	*
	from	OPENXML (@idoc, @sRowPattern, 2)
	WITH (
		NameKey		int     'text()'		
	     )

	Set @nNameKeyRowCount = @@RowCount
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End	

-- If @sAnySearch is provided, all other filter parameters are ignored.
If @sAnySearch is not NULL	    
and @nErrorCode = 0
Begin
        Set @sWhere = 	char(10)+" where (((UPPER(XN.NAME) like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + " OR"+ 
			char(10)+"        UPPER(XN.FIRSTNAME) like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + " OR"+ 
			char(10)+"        XN.SEARCHKEY1 like " 	+ dbo.fn_WrapQuotes(left(@sAnySearch,20) + '%',0,0) + " OR"+ 
			char(10)+"        XN.SEARCHKEY2 like " 	+ dbo.fn_WrapQuotes(left(@sAnySearch,20) + '%',0,0) + " OR"+ 
			char(10)+"        XN.NAMECODE like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) 

	If ISNUMERIC(@sAnySearch)=1
	Begin
		Set @sSQLString = "
		Select @sAnySearch=Replicate('0',S.COLINTEGER-len(@sAnySearch))+@sAnySearch 
		From SITECONTROL S
		Where S.CONTROLID='NAMECODELENGTH'"

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@sAnySearch 			nvarchar(254)		output',
			  @sAnySearch 			= @sAnySearch		output
		
		Set @sWhere = @sWhere + char(10)+"	OR XN.NAMECODE = '" + @sAnySearch + "')"  
	End
	Else
	Begin
	        Set @sWhere = @sWhere + ")"
	End	

	If   @bIsCurrent=1	
	 and (@bIsCeased =0 or @bIsCeased is NULL)
	Begin
		set @sWhere = @sWhere+char(10)+"	and (XN.DATECEASED is null OR XN.DATECEASED>getdate())"
	End
	Else If   @bIsCeased=1
		 and (@bIsCurrent=0 or @bIsCurrent is NULL)
	Begin
		set @sWhere = @sWhere+char(10)+"	and (XN.DATECEASED <=getdate())"
	End	
	
	If @bIsLead is null or @bIsLead <> 1
	Begin
	        Set @sWhere = @sWhere + "))"
	End
	Else If @bIsLead = 1
        Begin
                Set @sFrom=@sFrom+char(10)+"	join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
                                            and NTC.NAMETYPE = '~LD'
                                            and NTC.ALLOW=1)"
		Set @sFrom=@sFrom+char(10)+"	left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE) and NTP.PICKLISTFLAGS&32<>32"		
		Set @sFrom=@sFrom+char(10)+"	left join (select DISTINCT AN.RELATEDNAME as LEADNO, XNL.NAME as LEADNAME, XNA.NAME as ORGNAME, AN.NAMENO as ORGNO
                                                from ASSOCIATEDNAME AN
                                                join NAME XNA on (XNA.NAMENO = AN.NAMENO)
                                                join NAME XNL on (XNL.NAMENO = AN.RELATEDNAME)
                                                where RELATIONSHIP in ('EMP','LEA')" +
                                                " and exists(SELECT 1 FROM LEADDETAILS LD WHERE LD.NAMENO = XNL.NAMENO)" +
                                                " and XNL.NAME IS NOT NULL and UPPER(XNA.NAME) like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + ") ANL on (ANL.LEADNO = N.NAMENO)"  
                                                                
                set @sWhere = @sWhere+char(10)+" or (ANL.LEADNAME IS NOT NULL and ANL.ORGNAME IS NOT NULL))" 
                Set @sWhere = @sWhere + ")"               
        	                                          
        End
End	
Else If @sAnySearch is NULL	
     and @nErrorCode = 0
Begin
	if @sNameKey is not null
	begin
		Set @sWhere=@sWhere+char(10)+'and XN.NAMENO=' + @sNameKey
	end
	
	-- If @sSuitableForNameTypeKey is provided, filter criteria needs
	-- to be obtained from the NameType rules.

	set @nPickListFlags = 0
	
	if @sSuitableForNameTypeKey is not null
	begin
	        Set @sSQLString = "
		Select @nPickListFlags = PICKLISTFLAGS
		from NAMETYPE
		where NAMETYPE = replace(@sSuitableForNameTypeKey,'&amp;','&')"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nPickListFlags		smallint		output,
					  @sSuitableForNameTypeKey	nvarchar(3)',
					  @nPickListFlags		= @nPickListFlags	output,
					  @sSuitableForNameTypeKey	= @sSuitableForNameTypeKey
	end
	
	If @nErrorCode = 0 
	Begin
		If @nPickListFlags > 0
		Begin
			-- Take explicit parameters in preference to name type rules
			Set @bIsIndividual = isnull(@pbIsIndividual, cast(@nPickListFlags&1 as bit))
			Set @bIsOrganisation = isnull(@pbIsOrganisation, cast(@nPickListFlags&8 as bit))
			Set @bIsStaff = isnull(@pbIsStaff, cast(@nPickListFlags&2 as bit))
			Set @bIsClient = isnull(@pbIsClient, cast(@nPickListFlags&4 as bit))
		End
		Else
		Begin
			-- User parameters directly
			Set @bIsIndividual = @pbIsIndividual
			Set @bIsOrganisation = @pbIsOrganisation
			Set @bIsClient = @pbIsClient
			Set @bIsStaff = @pbIsStaff
		End
		
		Set @sUsedAsFlag=null
		
		If @bIsOrganisation=1
		Begin
			If @bIsClient=1
				Set @sUsedAsFlag='4'
			Else
				Set @sUsedAsFlag='0,4'
		End
		
		If @bIsIndividual=1
		Begin
			If @bIsClient=1
				Set @sUsedAsFlag=CASE WHEN(@sUsedAsFlag is null) Then '5'   Else @sUsedAsFlag+',5' END
			Else
				Set @sUsedAsFlag=CASE WHEN(@sUsedAsFlag is null) Then '1,5' Else @sUsedAsFlag+',1,5' END
		End
		
		If @bIsStaff=1
		Begin
			Set @sUsedAsFlag=CASE WHEN(@sUsedAsFlag is null) Then '2,3' Else @sUsedAsFlag+',2,3' END
		End
		
		If @bIsClient=1
		and ISNULL(@bIsOrganisation,0)=0
		and ISNULL(@bIsIndividual  ,0)=0
		and ISNULL(@bIsStaff       ,0)=0
		Begin
			Set @sUsedAsFlag='4,5,6'
		End
		
		If @sUsedAsFlag is not null
		Begin
			If  @bIsSupplier=1
			Begin
				If @bIsClient=1
					Set @sWhere=@sWhere+char(10)+"	and (XN.USEDASFLAG in ("+@sUsedAsFlag+") or XN.SUPPLIERFLAG = 1)"
				Else
					Set @sWhere=@sWhere+char(10)+"	and XN.USEDASFLAG in ("+@sUsedAsFlag+") and XN.SUPPLIERFLAG = 1"
			End
			Else Begin
				Set @sWhere=@sWhere+char(10)+"	and XN.USEDASFLAG in ("+@sUsedAsFlag+")"
			End
		End
		Else If  @bIsSupplier=1
		Begin
			Set @sWhere=@sWhere+char(10)+"	and XN.SUPPLIERFLAG = 1"
		End
		
		If @bIsLead=1 or @bIsCRM=1
		Begin
			Set @sFrom=@sFrom+char(10)+"	left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
                                            and NTC.NAMETYPE <> '~~~'
                                            and NTC.ALLOW=1)"
			Set @sFrom=@sFrom+char(10)+"	left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32<>32)"
			
			If @bIsLead=1	 
			begin   
				set @sWhere = @sWhere+char(10)+"	and NTC.NAMETYPE='~LD'"
			end
			
			If @bIsCRM=1	 
			begin   
				set @sWhere = @sWhere+char(10)+"	and NTP.NAMETYPE is null"
						+char(10)+"and exists(SELECT 1 FROM NAMETYPECLASSIFICATION NTC1"
						+char(10)+"JOIN NAMETYPE NT on (NT.NAMETYPE = NTC1.NAMETYPE)"
						+char(10)+"WHERE NTC1.NAMENO = XN.NAMENO "
						+char(10)+"AND NT.PICKLISTFLAGS&32=32 and NTC1.ALLOW=1)"
			end
		End
		
	
		If   @bIsCurrent=1
		and (@bIsCeased =0 or @bIsCeased is NULL)
		begin
			set @sWhere = @sWhere+char(10)+"	and (XN.DATECEASED is null OR XN.DATECEASED>getdate())"
		End
		Else If   @bIsCeased=1
		     and (@bIsCurrent=0 or @bIsCurrent is NULL)
		begin
			set @sWhere = @sWhere+char(10)+"	and (XN.DATECEASED <=getdate())"
		end		
	
		If @sSearchKey is not NULL
		 or @nSearchKeyOperator between 2 and 6				
		Begin
			-- Default the @bUseSearchKey1 to 1 if both @bUseSearchKey1 and @bUseSearchKey2 are 0. (Use '=0'	
			-- because if @bUseSearchKey1 and/or @bUseSearchKey2 have not been supplied  they are defaulted 
			-- to 0 while extracting from XML) 

			If @bUseSearchKey1=0 
			and @bUseSearchKey2=0
			Begin
				Set @bUseSearchKey1 = 1
			End			
	
			Set @sWhere = @sWhere+char(10)+"	and ("
			Set @sOr    = NULL
	
			If @bUseSearchKey1=1			
			Begin
				set @sWhere = @sWhere+"XN.SEARCHKEY1"+dbo.fn_ConstructOperator(@nSearchKeyOperator,@String,@sSearchKey, null,0)
				set @sOr    =' OR '
			End
	
			If @bUseSearchKey2=1
			Begin
				set @sWhere = @sWhere+@sOr+"XN.SEARCHKEY2"+dbo.fn_ConstructOperator(@nSearchKeyOperator,@String,@sSearchKey, null,0)
				set @sOr    =' OR '
			End			

			If @bSoundsLikeSearchKey=1
			and @bUseSearchKey1=1 			
			and @sSearchKey is not null
			Begin
				If @nSearchKeyOperator = 1
				Begin
					Set @sWhere=@sWhere+@sOr+char(10)+"	dbo.fn_SoundsLike(XN.SEARCHKEY1)<>dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sSearchKey,0,0)+")"
					set @sOr    =' OR '
				End
				Else
				Begin
					Set @sWhere=@sWhere+@sOr+char(10)+"	dbo.fn_SoundsLike(XN.SEARCHKEY1)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sSearchKey,0,0)+")"
					set @sOr    =' OR '
				End
			End

			If @bSoundsLikeSearchKey=1
			and @bUseSearchKey2=1 
			and @sSearchKey is not null
			Begin
				If @nSearchKeyOperator = 1
				Begin
					Set @sWhere=@sWhere+@sOr+char(10)+"	dbo.fn_SoundsLike(XN.SEARCHKEY2)<>dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sSearchKey,0,0)+")"					
				End
				Else
				Begin
					Set @sWhere=@sWhere+@sOr+char(10)+"	dbo.fn_SoundsLike(XN.SEARCHKEY2)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sSearchKey,0,0)+")"					
				End
			End

			Set @sWhere=@sWhere+")"			
		End		
	
		If @bIsEntity=1	 
		begin   
			set @sWhere = @sWhere+char(10)+"	and exists(SELECT 1 from SPECIALNAME XSN where XSN.NAMENO = XN.NAMENO and XSN.ENTITYFLAG = 1)"
		end
	
		If  @sNameCode is not NULL
		 or @nNameCodeOperator between 2 and 6
		Begin
			If isnumeric(@sNameCode)=1
			and @nNameCodeOperator in (0,1)
			Begin
				-- Only pad @sNameCode with leading zeroes for operators Equal To and Not Equal To.
		
				Select @sNameCode=Replicate('0',S.COLINTEGER-len(@sNameCode))+@sNameCode 
				From SITECONTROL S
				Where S.CONTROLID='NAMECODELENGTH'
				
				Set @nErrorCode = @@Error
			End
			
			If @nErrorCode = 0
			Begin
				set @sWhere=@sWhere+char(10)+"	and XN.NAMECODE"+dbo.fn_ConstructOperator(@nNameCodeOperator,@String,@sNameCode, null,0)
			End
		End
	End

	If @nErrorCode = 0
	Begin
		-- If neither of UseMainName or UseVariantName where supplied, 
		-- or they both are set to 0, then UseMainName will be defaulted to 1:
		If  isnull(@bUseMainName, 0) 	= 0
		and isnull(@bUseVariantName, 0) = 0		
		Begin
			Set @bUseMainName 	= 1
			Set @bUseVariantName 	= 0
		End		

		If (@sName is not null and @nNameOperator=9)
		Begin
			Set @sWhere =@sWhere+char(10)+"	and ("

			If @bUseMainName = 1
			Begin
				Set @sWhere=@sWhere+char(10)+" dbo.fn_SoundsLike(XN.NAME)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sName,0,0)+")"
			End

			If @bUseVariantName = 1
			Begin
				Set @sWhere =@sWhere+char(10)+CASE WHEN @bUseMainName = 1 THEN " or exists" ELSE " exists" END
				Set @sWhere =@sWhere+" (Select 1"
						    +char(10)+"  from NAMEVARIANT XNV"
						    +char(10)+"  where XNV.NAMENO = XN.NAMENO"
						    +char(10)+"	 and   dbo.fn_SoundsLike(XNV.NAMEVARIANT)=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sName,0,0)+"))"
			End

			Set @sWhere= @sWhere + ")"+char(10)
		End
		Else
		If (@sName is not NULL or @nNameOperator between 2 and 6)
		Begin
			Set @sWhere =@sWhere+char(10)+"	and ("

			If @bUseMainName = 1
			Begin
				Set @sWhere=@sWhere+char(10)+"	upper(XN.NAME)"+dbo.fn_ConstructOperator(@nNameOperator,@String,upper(@sName), null,0)
			End

			If @bUseVariantName = 1
			Begin
				If @nNameOperator in (1,6)
				Begin
					Set @sWhere =@sWhere+char(10)+CASE WHEN @bUseMainName = 1 THEN " and not exists" ELSE " not exists" END

					If @nNameOperator in (1)
					Begin
						Set @nNameOperator = 0
					End
					Else If @nNameOperator in (6)
					Begin
						Set @nNameOperator = 5
					End
				End
				Else Begin
					Set @sWhere =@sWhere+char(10)+CASE WHEN @bUseMainName = 1 THEN " or exists" ELSE " exists" END
				End

				Set @sWhere =@sWhere+char(10)+" (Select 1"
						    +char(10)+"  from NAMEVARIANT XNV"
						    +char(10)+"  where XNV.NAMENO = XN.NAMENO"
						    +char(10)+"	 and   upper(XNV.NAMEVARIANT) "+dbo.fn_ConstructOperator(@nNameOperator,@String,@sName, null,0)+")"
			End				
			
			Set @sWhere = @sWhere + ")"
		End		


		If @sFirstName is not NULL
		or @nFirstNameOperator between 2 and 6
		Begin
			Set @sWhere =@sWhere+char(10)+"	and ("

			If @bUseMainName = 1
			Begin
				set @sWhere=@sWhere+char(10)+"	upper(XN.FIRSTNAME)"+dbo.fn_ConstructOperator(@nFirstNameOperator,@String,@sFirstName, null,0)
			End
			
			If @bUseVariantName = 1
			Begin
				If @nFirstNameOperator in (1,6)
				Begin
					Set @sWhere =@sWhere+char(10)+CASE WHEN @bUseMainName = 1 THEN " and not exists" ELSE " not exists" END

					If @nFirstNameOperator in (1)
					Begin
						Set @nFirstNameOperator = 0
					End
					Else If @nFirstNameOperator in (6)
					Begin
						Set @nFirstNameOperator = 5
					End
				End
				Else Begin
					Set @sWhere =@sWhere+char(10)+CASE WHEN @bUseMainName = 1 THEN " or exists" ELSE " exists" END
				End

				Set @sWhere =@sWhere+char(10)+" (Select 1"
						    +char(10)+"  from NAMEVARIANT XNV2"
						    +char(10)+"  where XNV2.NAMENO = XN.NAMENO"
						    +char(10)+"	 and   upper(XNV2.FIRSTNAMEVARIANT) "+dbo.fn_ConstructOperator(@nFirstNameOperator,@String,@sFirstName, null,0)+")"
			End				
			
			Set @sWhere = @sWhere + ")"			
		End
	

		If @dtLastChangedFromDate is not NULL
		or @dtLastChangedToDate   is not NULL
		or @nLastChangedOperator between 2 and 6
		Begin
			set @sWhere=@sWhere+char(10)+"	and isnull(XN.DATECHANGED, XN.DATEENTERED)"+dbo.fn_ConstructOperator(@nLastChangedOperator,@Date,@dtLastChangedFromDate, @dtLastChangedToDate,0)
		End
	
		If @sRemarks is not NULL
		or @nRemarksOperator between 2 and 6
		Begin					 
			set @sWhere=@sWhere+char(10)+"	and upper("+dbo.fn_SqlTranslatedColumn('NAME','REMARKS',null,'XN',@sLookupCulture,@pbCalledFromCentura)+")"+dbo.fn_ConstructOperator(@nRemarksOperator,@String,@sRemarks, null,0)
		End
				
		If @sTaxNo is not NULL
		or @nTaxNoOperator between 2 and 6
		Begin			
			set @sWhere=@sWhere+char(10)+"	and XN.TaxNo"+dbo.fn_ConstructOperator(@nTaxNoOperator,@String,@sTaxNo, null,0)
		End

		if @sCountryKey is not null
		or @nCountryKeyOperator between 2 and 6
		or @sStateKey   is not null
		or @nStateKeyOperator between 2 and 6
		or @sCity       is not null
		or @nCityOperator between 2 and 6
		or @sStreet1 	is not null
		or @nStreet1Operator between 2 and 6
		or @sPostCode 	is not null
		or @nPostCodeOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join NAMEADDRESS XNA on (XNA.NAMENO=XN.NAMENO"
					   +char(10)+"	                          and(XNA.DATECEASED is null OR XNA.DATECEASED>getdate()))"
					   +char(10)+"	left join ADDRESS XA      on (XA.ADDRESSCODE=XNA.ADDRESSCODE)"

			If @bIsMainAddress = 1
			Begin
				If @bIsCorrespondence = 1 and @bIsStreet = 0
				Begin
					set @sWhere =@sWhere+char(10)+"	and (XNA.ADDRESSTYPE = 301 and XN.POSTALADDRESS = XNA.ADDRESSCODE)"
				End	
				Else if @bIsCorrespondence = 0 and @bIsStreet = 1
				Begin
					set @sWhere =@sWhere+char(10)+"	and (XNA.ADDRESSTYPE = 302 and XN.STREETADDRESS = XNA.ADDRESSCODE)"
				End
				Else
				Begin
					set @sWhere =@sWhere+char(10)+"	and ((XNA.ADDRESSTYPE = 301 and XN.POSTALADDRESS = XNA.ADDRESSCODE)"+char(10)+
						"or (XNA.ADDRESSTYPE = 302 and XN.STREETADDRESS = XNA.ADDRESSCODE))"
				End
			End
			ELSE
				Begin
				If @bIsCorrespondence = 1 and @bIsStreet = 1
				Begin
					set @sWhere =@sWhere+char(10)+" and (XNA.ADDRESSTYPE = 301 or XNA.ADDRESSTYPE = 302)"
				End
				Else If @bIsCorrespondence = 1 and @bIsStreet = 0
				Begin
					set @sWhere =@sWhere+char(10)+" and XNA.ADDRESSTYPE = 301"
				End
				Else If @bIsCorrespondence = 0 and @bIsStreet = 1
				Begin
					set @sWhere =@sWhere+char(10)+" and XNA.ADDRESSTYPE = 302"
				End 
			End

			if @sCountryKey is not null
			or @nCountryKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XA.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryKeyOperator,@String,@sCountryKey, null,0)
	
			if @sStateKey is not null
			or @nStateKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XA.STATE"+dbo.fn_ConstructOperator(@nStateKeyOperator,@String,@sStateKey, null,0)
	
			if @sCity is not null
			or @nCityOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	upper(XA.CITY)"+dbo.fn_ConstructOperator(@nCityOperator,@String,@sCity, null,0)

			if @sStreet1 is not null
			or @nStreet1Operator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	upper(XA.STREET1)"+dbo.fn_ConstructOperator(@nStreet1Operator,@String,@sStreet1, null,0)

			if @sPostCode is not null
			or @nPostCodeOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XA.POSTCODE"+dbo.fn_ConstructOperator(@nPostCodeOperator,@String,@sPostCode, null,0)
		end
	
		If @nNameGroupKey is not NULL
		or @nNameGroupKeyOperator between 2 and 6
		Begin
			set @sWhere=@sWhere+char(10)+"	and XN.FAMILYNO"+dbo.fn_ConstructOperator(@nNameGroupKeyOperator,@Numeric,@nNameGroupKey, null,0)
		End


		If (@nNameStatusKey is not NULL	or @nNameStatusOperator between 2 and 6) or
		(@nNameSourceKey is not NULL or @nNameSourceOperator between 2 and 6) or
		 @nLeadEstRevFrom is not NULL or 
		 @nLeadEstRevTo is not NULL or
		(@sLeadEstRevCurrency is not NULL or @nLeadEstRevCurrencyOperator between 2 and 6)
		Begin

			Set @sFrom=@sFrom+char(10)+"	left join LEADDETAILS XLD on (XLD.NAMENO=XN.NAMENO)"
			Set @sFrom=@sFrom+char(10)+"	left join (select NAMENO," 
					+char(10)+"	MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(LEADSTATUSID as nvarchar(11)) ) as [DATE]"
					+char(10)+"	from LEADSTATUSHISTORY"
					+char(10)+"	group by NAMENO	) XLASTMODIFIED on (XLASTMODIFIED.NAMENO = XLD.NAMENO)"
					+char(10)+"	Left Join LEADSTATUSHISTORY XLSH on (XLSH.NAMENO = XLD.NAMENO "
					+char(10)+"	and ( (convert(nvarchar(24),XLSH.LOGDATETIMESTAMP, 21)+cast(XLSH.LEADSTATUSID as nvarchar(11))) = XLASTMODIFIED.[DATE]"
					+char(10)+"	or XLASTMODIFIED.[DATE] is null ))"
					
			If @nNameStatusKey is not NULL
			or @nNameStatusOperator between 2 and 6
			Begin
				set @sWhere=@sWhere+char(10)+"	and XLSH.LEADSTATUS"+dbo.fn_ConstructOperator(@nNameStatusOperator,@Numeric,@nNameStatusKey, null,0)
			End

			If @nNameSourceKey is not NULL
			or @nNameSourceOperator between 2 and 6
			Begin
				set @sWhere=@sWhere+char(10)+"	and XLD.LEADSOURCE"+dbo.fn_ConstructOperator(@nNameSourceOperator,@Numeric,@nNameSourceKey, null,0)
			End

			select @sHomeCurrency = COLCHARACTER
			from SITECONTROL
			where CONTROLID = 'CURRENCY'

			If ((@nLeadEstRevFrom is not NULL or @nLeadEstRevTo is not NULL) 
				and @nLeadEstRevOperator is not null)
			Begin
				if (@sLeadEstRevCurrency is not NULL and @sLeadEstRevCurrency != @sHomeCurrency)
				Begin
					-- If Currency is specified, don't bother checking the local amount.
					set @sWhere=@sWhere+char(10)+"	and XLD.ESTIMATEDREV"+dbo.fn_ConstructOperator(@nLeadEstRevOperator,@Numeric,@nLeadEstRevFrom, @nLeadEstRevTo,0)
				End
				Else If (@sLeadEstRevCurrency = @sHomeCurrency)
				Begin
					-- Force local search.
					set @sWhere=@sWhere+char(10)+"	and ISNULL(XLD.ESTIMATEDREVLOCAL,0)"+dbo.fn_ConstructOperator(@nLeadEstRevOperator,@Numeric,@nLeadEstRevFrom, @nLeadEstRevTo,0)
				End
				Else
				Begin
					set @sWhere=@sWhere+char(10)+"	and ISNULL(ISNULL(XLD.ESTIMATEDREV,XLD.ESTIMATEDREVLOCAL),0)"+dbo.fn_ConstructOperator(@nLeadEstRevOperator,@Numeric,@nLeadEstRevFrom, @nLeadEstRevTo,0)
				End
			End

			if (@sLeadEstRevCurrency is not NULL or @nLeadEstRevCurrencyOperator between 5 and 6)
			Begin
				If (@sLeadEstRevCurrency != @sHomeCurrency or @sLeadEstRevCurrency is NULL)
				Begin
					set @sWhere=@sWhere+char(10)+"	and XLD.ESTREVCURRENCY"+dbo.fn_ConstructOperator(@nLeadEstRevCurrencyOperator,@String,@sLeadEstRevCurrency,NULL,0)
				End
				Else
				Begin
					set @sWhere=@sWhere+char(10)+"	and (XLD.ESTREVCURRENCY is null or XLD.ESTREVCURRENCY"+dbo.fn_ConstructOperator(@nLeadEstRevCurrencyOperator,@String,@sLeadEstRevCurrency,NULL,0) + ")"
				End
			End
		End
		
		if @sNameTypeKey is not null
		or @nNameTypeKeyOperator between 2 and 6
		begin
			If @nNameTypeKeyOperator in (0,2,3,4,5,7)
				set @sWhere =@sWhere+char(10)+" and exists"
			Else
				set @sWhere =@sWhere+char(10)+" and not exists"			
			
			-- RFC2128 Ensure that the filter criteria is limited to values the user may view
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NAMETYPE,0, @pbCalledFromCentura)
			From dbo.fn_FilterUserNameTypes(@pnUserIdentityId, null, @pbIsExternalUser, @pbCalledFromCentura)

			set @sWhere =@sWhere+char(10)+" (select * from CASENAME XCN"+
					    CASE 	WHEN @pbIsExternalUser = 1
							-- For external users, only names that appear on cases 
							-- the user may access are returned.
							THEN 	+char(10)+"join dbo.fn_FilterUserCases("+cast(@pnUserIdentityId as varchar(11))+", 1, null) FC" 
						   		+char(10)+"on (FC.CASEID=XCN.CASEID)"
					    END+
					    +char(10)+"  where XCN.NAMENO=XN.NAMENO"
					    -- Make sure that the users can only see NameTypes
					    -- they have access to.
					    +char(10)+"	 and  XCN.NAMETYPE IN ("+@sList+")"
					    +char(10)+"  and  (XCN.EXPIRYDATE is null OR XCN.EXPIRYDATE>getdate())"
	
			If @nNameTypeKeyOperator in (0,2,3,4,7)
				set @sWhere =@sWhere+char(10)+"	 and   XCN.NAMETYPE"+dbo.fn_ConstructOperator(@nNameTypeKeyOperator,@String,@sNameTypeKey, null,0)+")"
			Else
				set @sWhere =@sWhere+")"
		end
		
		if @sAirportKey is not null
		or @nAirportKeyOperator between 2 and 6
		or @sCaseTypeKey is not NULL
		or @nCaseTypeKeyOperator between 2 and 6
		or @sPropertyTypeKeyList is not null
		or @sPropertyTypeKey is not NULL
		or @nPropertyTypeKeyOperator between 2 and 6
		or @nNameCategoryKey is not null
		or @nNameCategoryKeyOperator between 2 and 6		
		or @nBadDebtorKey is not null
		or @nBadDebtorKeyOperator between 2 and 6
		or @sBillingCurrencyKey is not null
		or @nBillingCurrencyKeyOperator between 2 and 6
		or @sTaxRateKey is not null
		or @nTaxRateKeyOperator between 2 and 6
		or @nDebtorTypeKey is not null
		or @nDebtorTypeKeyOperator between 2 and 6
		or @sPurchaseOrderNo is not null
		or @nPurchaseOrderNoOperator between 2 and 6
		or @nReceivableTermsFromDays is not null
		or @nReceivableTermsToDays is not null
		or @nReceivableTermsOperator between 2 and 6
		or @nBillingFrequencyKey is not null
		or @nBillingFrequencyKeyOperator between 2 and 6
		or @bIsLocalClient is not null
		or @nIsLocalClientOperator between 2 and 6
		or @sNameTypeKey is not null
		or @nNameTypeKeyOperator in (0,2,3,4,7)
		begin
			set @sFrom = @sFrom+char(10)+"	left join IPNAME XIP on (XIP.NAMENO=XN.NAMENO)"
	
			if @bIsLocalClient is not null
			or @nIsLocalClientOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.LOCALCLIENTFLAG"+dbo.fn_ConstructOperator(@nIsLocalClientOperator,@Numeric,@bIsLocalClient, null,0)
	
			if @nBillingFrequencyKey is not null
			or @nBillingFrequencyKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.BILLINGFREQUENCY"+dbo.fn_ConstructOperator(@nBillingFrequencyKeyOperator,@Numeric,@nBillingFrequencyKey, null,0)
	
			if @nReceivableTermsFromDays is not null
			or @nReceivableTermsToDays is not null
			or @nReceivableTermsOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.TRADINGTERMS"+dbo.fn_ConstructOperator(@nReceivableTermsOperator,@Numeric,@nReceivableTermsFromDays, @nReceivableTermsToDays,0)
	
			if @sPurchaseOrderNo is not null
			or @nPurchaseOrderNoOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	upper(XIP.PURCHASEORDERNO)"+dbo.fn_ConstructOperator(@nPurchaseOrderNoOperator,@String,@sPurchaseOrderNo, null,0)
				
			if @nDebtorTypeKey is not null
			or @nDebtorTypeKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.DEBTORTYPE"+dbo.fn_ConstructOperator(@nDebtorTypeKeyOperator,@Numeric,@nDebtorTypeKey, null,0)
	
			if @sTaxRateKey is not null
			or @nTaxRateKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.TAXCODE"+dbo.fn_ConstructOperator(@nTaxRateKeyOperator,@String,@sTaxRateKey, null,0)
	
			if @sBillingCurrencyKey is not null
			or @nBillingCurrencyKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.CURRENCY"+dbo.fn_ConstructOperator(@nBillingCurrencyKeyOperator,@String,@sBillingCurrencyKey, null,0)
	
			if @sAirportKey is not null
			or @nAirportKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.AIRPORTCODE"+dbo.fn_ConstructOperator(@nAirportKeyOperator,@String,@sAirportKey, null,0)
	
			If @sCaseTypeKey is not NULL
			  or @nCaseTypeKeyOperator between 2 and 6
			  or @sPropertyTypeKey is not NULL
			  or @sPropertyTypeKeyList is not NULL
			  or @nPropertyTypeKeyOperator between 2 and 6
			  or @sNameTypeKey is not null
			  or @nNameTypeKeyOperator in (0,2,3,4,7)
			Begin
				set @sFrom  = @sFrom + char(10)+"  left join CASENAME XCN on (XCN.NAMENO   = XN.NAMENO) 
				left join CASES XC on (XC.CASEID=XCN.CASEID)" + char(10)
				
				If @sCaseTypeKey is not NULL
				or @nCaseTypeKeyOperator between 2 and 6
				Begin
					Set @sList = null
					Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(CASETYPE,0,@pbCalledFromCentura)
					From dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura,@dtToday)
	                                
					if @sList is not null
					Begin
					Set @sWhere= @sWhere+char(10)+" and XC.CASETYPE IN ("+@sList+")"
					End
					Set @sWhere = @sWhere+char(10)+" and XC.CASETYPE"+dbo.fn_ConstructOperator(@nCaseTypeKeyOperator,@String,@sCaseTypeKey, null,@pbCalledFromCentura)
				End
				
				If @sPropertyTypeKeyList is not null
				Begin				 
					Set @sWhere = @sWhere+char(10)+"	and XC.PROPERTYTYPE "+
						case @nPropertyTypeKeysOperator
						when 0 then "in ("
						when 1 then "not in ("
					End+@sPropertyTypeKeyList+")"
				End
				Else
				If @sPropertyTypeKey is not NULL
				or @nPropertyTypeKeyOperator between 2 and 6
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	XC.PROPERTYTYPE"+dbo.fn_ConstructOperator(@nPropertyTypeKeyOperator,',',@sPropertyTypeKey, null,@pbCalledFromCentura)
				End
				If @sNameTypeKey is not null
			        or @nNameTypeKeyOperator in (0,2,3,4,7)
				Begin
					Set @sWhere =@sWhere+char(10)+"	 and   XCN.NAMETYPE"+dbo.fn_ConstructOperator(@nNameTypeKeyOperator,@String,@sNameTypeKey, null,0)	
				End
			End
			
			if @nNameCategoryKey is not null
			or @nNameCategoryKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.CATEGORY"+dbo.fn_ConstructOperator(@nNameCategoryKeyOperator,@Numeric,@nNameCategoryKey, null,0)
	
			if @nBadDebtorKey is not null
			or @nBadDebtorKeyOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	XIP.BADDEBTOR"+dbo.fn_ConstructOperator(@nBadDebtorKeyOperator,@Numeric,@nBadDebtorKey, null,0)
			
			
		end
		
		-- RFC50505
		-- Filtering on FilesIn Country is also to consider no explicitly
		-- defined Files In countries to be a match for any country.
		if @nFilesInKeyOperator in (0,1,2,6)
		begin
			if @nFilesInKeyOperator in (5,6)
			Begin
				set @sFrom = @sFrom+char(10)+"	left join (select distinct NAMENO from FILESIN) XFI on (XFI.NAMENO=XN.NAMENO)"
				set @sWhere =@sWhere+char(10)+"	and XFI.NAMENO"+dbo.fn_ConstructOperator(@nFilesInKeyOperator,@String,@sFilesInKey, null,0)
			End
			Else
			if @nFilesInKeyOperator = 0  -- Allowed to file in a specific Country
			and @sFilesInKey is not null
			Begin
				set @sFrom = @sFrom+char(10)+"	left join FILESIN XFI on (XFI.NAMENO=XN.NAMENO"
				                   +char(10)+"	                      and XFI.COUNTRYCODE"+dbo.fn_ConstructOperator(@nFilesInKeyOperator,@String,@sFilesInKey, null,0)+")"
				                   +char(10)+"	left join (select distinct NAMENO from FILESIN) XFI1 on (XFI1.NAMENO=XN.NAMENO)"
				                   
				set @sWhere =@sWhere+char(10)+"	and (XFI.NAMENO is not null OR XFI1.NAMENO is null)" -- Either matches FilesIn Country or no FilesIn Countries specified for Name.
			End
			Else
			if  @nFilesInKeyOperator = 1  -- Not allowed to file in a specific Country
			and @sFilesInKey is not null
			Begin
				set @nFilesInKeyOperator = 0
				set @sFrom = @sFrom+char(10)+"	left join FILESIN XFI on (XFI.NAMENO=XN.NAMENO"
				                   +char(10)+"	                      and XFI.COUNTRYCODE"+dbo.fn_ConstructOperator(@nFilesInKeyOperator,@String,@sFilesInKey, null,0)+")"
				                   +char(10)+"	left join (select distinct NAMENO from FILESIN) XFI1 on (XFI1.NAMENO=XN.NAMENO)"
				                   
				set @sWhere =@sWhere+char(10)+"	and (XFI.NAMENO is null AND XFI1.NAMENO is not null)" -- Does not match FilesIn Country AND other FilesIn Countries specified for Name.
			End
		end
			
		if @sTextTypeKey is not null
		or @sText        is not null
		or @nTextOperator between 2 and 6
		begin
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(TEXTTYPE,0, @pbCalledFromCentura)
			From dbo.fn_FilterUserTextTypes(@pnUserIdentityId, null, @pbIsExternalUser, @pbCalledFromCentura)
			If @sList is null
			Begin
				Set @sList = "''"
			End
		
			If @nTextOperator in (0,2,3,4,5,7)
				set @sWhere =@sWhere+char(10)+" and exists"
			Else
				set @sWhere =@sWhere+char(10)+" and not exists"
	
			set @sWhere =@sWhere+char(10)+" (select * from NAMETEXT XNT"
					    +char(10)+"  where XNT.NAMENO=XN.NAMENO"
			
			If @sTextTypeKey is not null
				set @sWhere =@sWhere+char(10)+" and XNT.TEXTTYPE="+dbo.fn_WrapQuotes(@sTextTypeKey,0,0)
			
			set @sWhere =@sWhere+char(10)+" and XNT.TEXTTYPE in ("+@sList+")"

			-- If the Operator is 1 (not equal) then change to 0 (equal) because of the 
			-- NOT EXISTS clause
			If @nTextOperator=1
				set @nTextOperator=0
	
			If @nTextOperator in (0,2,3,4,7)
				set @sWhere =@sWhere+char(10)+"  and XNT.TEXT"+dbo.fn_ConstructOperator(@nTextOperator,@Text,@sText, null,0)+")"
			Else
				set @sWhere =@sWhere+")"
		end

		if (@nInstructionKey is not null
		or @nInstructionKeyOperator between 2 and 6)
		and @pbIsExternalUser = 1
		begin
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(INSTRUCTIONTYPE,0, @pbCalledFromCentura)
			From dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId, null, @pbIsExternalUser, @pbCalledFromCentura)
			If @sList is null
			Begin
				Set @sList = "''"
			End
		end

		If @bIncludeInherited = 0
		or @bIncludeInherited is null
		Begin
			if @nInstructionKey is not null
			or @nInstructionKeyOperator between 2 and 6
			begin
				If @nInstructionKeyOperator in (0,2,3,4,7,8)
				Begin
					set @sFrom = @sFrom +char(10)+"	left join NAMEINSTRUCTIONS XNI on (XNI.NAMENO=XN.NAMENO"
							    +char(10)+"	                               and XNI.CASEID is null)"
					    		    +char(10)+"	left join INSTRUCTIONS XISR	on (XISR.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE)"
		
					set @sWhere =@sWhere+char(10)+"	and	XNI.INSTRUCTIONCODE"+dbo.fn_ConstructOperator(@nInstructionKeyOperator,@Numeric,@nInstructionKey, null,0)
					
					If @pbIsExternalUser = 1
					Begin
						set @sWhere =@sWhere+char(10)+" and 	XISR.INSTRUCTIONTYPE in ("+@sList+")"
					End
				End
				Else Begin
					If @nInstructionKeyOperator in (5)
						set @sWhere =@sWhere+char(10)+" and exists"
					Else
						set @sWhere =@sWhere+char(10)+" and not exists"
		
					set @sWhere =@sWhere+char(10)+" (select * from NAMEINSTRUCTIONS XNI"
							    +char(10)+"	 join  INSTRUCTIONS XI2	on (XI2.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE"

					If @pbIsExternalUser = 1
					Begin
						set @sWhere =@sWhere+char(10)+"		  		and XI2.INSTRUCTIONTYPE in ("+@sList+")"
					End

					set @sWhere =@sWhere+")"
							    +char(10)+"  where XNI.NAMENO=XN.NAMENO"
							    +char(10)+"  and XNI.CASEID is NULL"
		
					-- If the Operator is 1 (not equal) then change to 0 (equal) because of the 
					-- NOT EXISTS clause
					If @nInstructionKeyOperator=1
						set @sWhere=@sWhere+char(10)+"  and XNI.INSTRUCTIONCODE="+cast(@nInstructionKey as nvarchar(11))
		
					set @sWhere =@sWhere+")"
				End
			end
		End
		Else If  @bIncludeInherited = 1
		     and @nInstructionKeyOperator in (0,1)
		Begin 
			If @nInstructionKeyOperator in (0)
			Begin
				set @sWhere =@sWhere+char(10)+"and exists"
			End
			Else Begin
				set @sWhere =@sWhere+char(10)+"and not exists"
			End
	
			-- Get the Home NameNo.  This is being done as a separate SELECT as it
			-- provides a significant performance improvement compared to embedding
			-- the join to the SITECONTROL within the constructed SQL

			Set @sSQLString="
			Select @nHomeNameNo=S.COLINTEGER
			from SITECONTROL S
			where S.CONTROLID='HOMENAMENO'"

			exec sp_executesql @sSQLString,
					N'@nHomeNameNo		int OUTPUT',
					  @nHomeNameNo=@nHomeNameNo OUTPUT

			Set @sWhere =@sWhere+char(10)+" (select 1"
					    +char(10)+"  from NAMEINSTRUCTIONS XNI"
					    +char(10)+"  join INSTRUCTIONS XISR		on (XISR.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE)"
					    +char(10)+"  join INSTRUCTIONTYPE XIT	on (XIT.INSTRUCTIONTYPE  = XISR.INSTRUCTIONTYPE)"
					    +char(10)+"  left join CASENAME XCN		on (XCN.NAMETYPE = XIT.NAMETYPE"
					    +char(10)+"                                 and XCN.NAMENO   = XN.NAMENO"
					    +char(10)+"                                 and XCN.EXPIRYDATE is NULL OR XCN.EXPIRYDATE>getdate())"
					    +char(10)+"  where XNI.NAMENO in (XN.NAMENO"+CASE WHEN(@nHomeNameNo is not null) THEN ","+convert(varchar,@nHomeNameNo) END+")"
					    +char(10)+"  and   XNI.CASEID is null"

			If @pbIsExternalUser = 1
			Begin
				Set @sWhere =@sWhere+char(10)+"  and   XISR.INSTRUCTIONTYPE in ("+@sList+")"
			End

			Set @sWhere =@sWhere+char(10)+"  and   XNI.INSTRUCTIONCODE="+cast(@nInstructionKey as nvarchar(11))

			-- RFC3779 Show all standing instructions recorded directly against the name
			Set @sWhere =@sWhere+char(10)+"  and ( XNI.NAMENO = XN.NAMENO"

					    -- Note that if the default standing instruction has been overridden 
					    -- by a name-specific instruction, the default instruction should not 
					    -- be filtered on.
					    +char(10)+"  OR not exists"
					    +char(10)+"	   (Select 1 from  NAMEINSTRUCTIONS XNI2"
					    +char(10)+"	    join INSTRUCTIONS XI2 on (XI2.INSTRUCTIONCODE = XNI2.INSTRUCTIONCODE"

			If @pbIsExternalUser = 1
			Begin
				Set @sWhere =@sWhere+char(10)+"		  		  and XI2.INSTRUCTIONTYPE in ("+@sList+")"
			End

			Set @sWhere =@sWhere+")"
					    +char(10)+"	    where  XNI2.RESTRICTEDTONAME is null"
					    +char(10)+"	    and    XNI2.CASEID is null"
					    +char(10)+"     and    XI2.INSTRUCTIONTYPE = XISR.INSTRUCTIONTYPE"
					    +char(10)+"     and   (XNI2.PROPERTYTYPE = XNI.PROPERTYTYPE or XNI2.PROPERTYTYPE is null)"
					    +char(10)+"     and   (XNI2.COUNTRYCODE  = XNI.COUNTRYCODE  or XNI2.COUNTRYCODE  is null)"
					    +char(10)+"     and    XNI2.NAMENO = XN.NAMENO"
					    +char(10)+"     and    XNI2.NAMENO <> XNI.NAMENO) ) )"				
		End			

		If @nParentNameKey is not null
		or @nParentNameKeyOperator between 2 and 6
		or @sCompanyNo is not null
		or @nCompanyNoOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join ORGANISATION XO on (XO.NAMENO=XN.NAMENO)"
	
			If @nParentNameKey is not null
				or @nParentNameKeyOperator between 2 and 6
			Begin
				set @sWhere =@sWhere+char(10)+"	and	XO.PARENT"+dbo.fn_ConstructOperator(@nParentNameKeyOperator,@Numeric,@nParentNameKey, null,0)
			End
			Else
			Begin
				set @sWhere =@sWhere+char(10)+"	and	XO.REGISTRATIONNO"+dbo.fn_ConstructOperator(@nCompanyNoOperator,@String,@sCompanyNo, null,0)
			End			
		end
		
		If @sRelationshipKey is not null
		or @sAssociatedNameKeys is not null
		or @nAssociatedNameKeyOperator between 2 and 6
		Begin
			-- If Operator is set to IS NULL then use NOT EXISTS
			If @nAssociatedNameKeyOperator = 6
			Begin
				Set @sWhere =@sWhere+char(10)+"and not exists"
			End
			Else 
			Begin
				Set @sWhere =@sWhere+char(10)+"and exists"
			End
	
			set @sWhere=@sWhere+char(10)+"(select * from ASSOCIATEDNAME XAN"
					   +char(10)+" where XN.NAMENO="+CASE WHEN(@bIsReverseRelationship=1) THEN "XAN.RELATEDNAME" ELSE "XAN.NAMENO" END
			
			-- RFC61268
			-- When the reverse relationship is being used (e.g. return the employees for a company)
			-- then ensure the related name has not ceased in the relationship. 		   
			If @bIsReverseRelationship=1
				set @sWhere=@sWhere+char(10)+" and (XAN.CEASEDDATE > getdate() OR XAN.CEASEDDATE is null)"
	
			If  @sRelationshipKey is not null
			Begin				
				Set @sWhere=@sWhere+char(10)+" and XAN.RELATIONSHIP = "+dbo.fn_WrapQuotes(@sRelationshipKey,0,0)
			End						
	
			If @sAssociatedNameKeys is not null
			Begin
				If @nAssociatedNameKeyOperator not in (5,6)
				Begin
					If @bIsReverseRelationship=1
					Begin
						Set @sWhere =@sWhere+char(10)+" and XAN.NAMENO"+dbo.fn_ConstructOperator(@nAssociatedNameKeyOperator,@Numeric,@sAssociatedNameKeys, null,0)
					End
					Else
					Begin
						Set @sWhere =@sWhere+char(10)+" and XAN.RELATEDNAME"+dbo.fn_ConstructOperator(@nAssociatedNameKeyOperator,@Numeric,@sAssociatedNameKeys, null,0)
					End
				End				
			End
			
			set @sWhere =@sWhere+")"
		End
		
		If @sMainPhoneNumber is not null
		or @nMainPhoneNumberOperator between 5 and 6
		or @sMainPhoneAreaCode is not null
		or @nMainPhoneAreaCodeOperator between 5 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	join NAMETELECOM XNMT on (XNMT.NAMENO=XN.NAMENO)"
					   +char(10)+"	join TELECOMMUNICATION XT on (XT.TELECODE=XNMT.TELECODE)"
	
			If @sMainPhoneNumber is not null
			or @nMainPhoneNumberOperator between 5 and 6
				set @sWhere =@sWhere+char(10)+"	and	XT.TELECOMNUMBER"+dbo.fn_ConstructOperator(@nMainPhoneNumberOperator,@String,@sMainPhoneNumber, null,0)
	
			If @sMainPhoneAreaCode is not null
			or @nMainPhoneAreaCodeOperator between 5 and 6
				set @sWhere =@sWhere+char(10)+"	and	XT.AREACODE"+dbo.fn_ConstructOperator(@nMainPhoneAreaCodeOperator,@String,@sMainPhoneAreaCode, null,0)
		end
		
		-- AttributeGroup Filter criteria implementation:
		-- Set @nCount to 1 so it points to the first record of the table		
		Set @nCount = 1	

		-- @nAttributeRowCount is the number of rows in the @tblAttributeGroup table, which is used to loop the Attributes while constructing the 'From' and the 'Where' clause  		
		While @nCount <= @nAttributeRowCount
		begin
			set @sCorrelationName = 'XTA_' + cast(@nCount as nvarchar(20))
				
			Select  @bBooleanOr		= BooleanOr,
				@nAttributeKey		= AttributeKey,
				@nAttributeKeyOperator	= AttributeOperator,
				@sAttributeTypeKey	= AttributeTypeKey
			from	@tblAttributeGroup
			where   AttributeIdentity = @nCount 
 						
			If (@nAttributeKey is not null
			or @nAttributeKeyOperator between 2 and 6)		
			begin
				If @nAttributeRowCount > 1
				and @nCount >1 
				Begin 
					set @sStringOr = CASE WHEN isnull(@bBooleanOr,@bAttributeBooleanOr) = 1 THEN " or "
						      	      WHEN isnull(@bBooleanOr,@bAttributeBooleanOr) = 0 THEN " and "
						 	 END
				End
				Else If @nCount = 1
				Begin
					set @sWhere =@sWhere+char(10)+"	and ("
				End
		
				set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES "+@sCorrelationName+" on ("+@sCorrelationName+".PARENTTABLE='NAME'"
					   +char(10)+"	                                and "+@sCorrelationName+".TABLETYPE="+@sAttributeTypeKey
					   +char(10)+"	                                and "+@sCorrelationName+".GENERICKEY=convert(varchar,XN.NAMENO))"
				set @sWhere =@sWhere+@sStringOr+space(1)+ 
							     +@sCorrelationName+".TABLECODE"+dbo.fn_ConstructOperator(@nAttributeKeyOperator,@Numeric,@nAttributeKey, null,0)	
					
				If @nCount = @nAttributeRowCount
				begin
					set @sWhere = @sWhere + ")"
				end
			
			end				
					
			set @nCount = @nCount + 1
	
		end	
		
		-- NameKeys Filter criteria implementation:
		-- Set @nCount to 1 to point to first record in the table
		If @nNameKeyRowCount > 0
	        Begin
	                Insert into #TEMPNAMELIST(NAMENO)
	                select NameKey from @tblNameKeys
	                
	                set @sFrom = @sFrom+char(10)+"	join #TEMPNAMELIST TN on (TN.NAMENO=XN.NAMENO)"
		End
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- AssociatedNameGroup Filter criteria implementation:
		-- Set @nCount to 1 so it points to the first record of the table		
		Set @nCount = 1

		-- @nAssociateNameRowCount is the number of rows in the @tblAssociateNameGroup table, which is used to loop the Associated Names while constructing the 'From' and the 'Where' clause
		While @nCount <= @nAssociateNameRowCount
		begin
			set @sCorrelationName = 'XANG_' + cast(@nCount as nvarchar(20))
				
			Select  @sAssociatedNameKeys	= AssociateNameKeys,
				@nAssociatedNameKeyOperator	= AssociateNameOperator,
				@bIsReverseRelationship		= AssociateNameIsReverseRelationship,
				@sRelationshipKey		= AssociateNameRelationshipKey
			from	@tblAssociateNameGroup
			where   AssociateNameIdentity = @nCount 
			
			If @sRelationshipKey is not null
			or @sAssociatedNameKeys is not null
			or @nAssociatedNameKeyOperator between 2 and 6
			Begin
				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nAssociatedNameKeyOperator = 6
				Begin
					Set @sWhere =@sWhere+char(10)+"and not exists"
				End
				Else 
				Begin
					Set @sWhere =@sWhere+char(10)+"and exists"
				End
		
				set @sWhere=@sWhere+char(10)+"(select * from ASSOCIATEDNAME "+@sCorrelationName
						   +char(10)+" where XN.NAMENO="+	CASE WHEN(@bIsReverseRelationship=1)
												THEN @sCorrelationName+".RELATEDNAME" 
												ELSE @sCorrelationName+".NAMENO"
											END
		
				If  @sRelationshipKey is not null
				Begin				
					Set @sWhere=@sWhere+char(10)+" and "+@sCorrelationName+".RELATIONSHIP = "+dbo.fn_WrapQuotes(@sRelationshipKey,0,0)
				End						
		
				If @sAssociatedNameKeys is not null
				Begin
					If @nAssociatedNameKeyOperator not in (5,6)
					Begin
						If @bIsReverseRelationship=1
						Begin
							Set @sWhere =@sWhere+char(10)+" and "+@sCorrelationName+".NAMENO"+dbo.fn_ConstructOperator(@nAssociatedNameKeyOperator,@Numeric,@sAssociatedNameKeys, null,0)
						End
						Else
						Begin
							Set @sWhere =@sWhere+char(10)+" and "+@sCorrelationName+".RELATEDNAME"+dbo.fn_ConstructOperator(@nAssociatedNameKeyOperator,@Numeric,@sAssociatedNameKeys, null,0)
						End
					End				
				End
				
				set @sWhere =@sWhere+")"
			End
					
			set @nCount = @nCount + 1
	
		end	
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				
		If @sAliasTypeKey is not null
		or @sAlias        is not null
		or @nAliasOperator between 2 and 6
		begin
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(ALIASTYPE,0, @pbCalledFromCentura)
			From dbo.fn_FilterUserAliasTypes(@pnUserIdentityId, null, @pbIsExternalUser, @pbCalledFromCentura)
			If @sList is null
			Begin
				Set @sList = "''"
			End

			set @sFrom = @sFrom+char(10)+"	left join NAMEALIAS XNA2 on (XNA2.NAMENO=XN.NAMENO"
					   +char(10)+"				 and XNA2.ALIASTYPE in ("+@sList+"))"
	
			If @sAliasTypeKey is not null
				set @sWhere=@sWhere+char(10)+"	and	XNA2.ALIASTYPE="+dbo.fn_WrapQuotes(@sAliasTypeKey,0,0)

			If @sAlias is not null
			or @nAliasOperator between 2 and 6
				set @sWhere =@sWhere+char(10)+"	and	upper(XNA2.ALIAS)"+dbo.fn_ConstructOperator(@nAliasOperator,@String,@sAlias, null,0)

		end

		if  @sQuickIndexKey is not NULL
		and @nQuickIndexKeyOperator is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join IDENTITYINDEX IX	on (IX.IDENTITYID      = " + cast(@pnUserIdentityId as varchar(11)) +
					   +char(10)+"	                   	and  	IX.INDEXID      = " + @sQuickIndexKey + ")"
			set @sWhere = @sWhere+char(10)+"	and	XN.NAMENO = IX.COLINTEGER"
		end

		if @nStaffClassificationKey is not null
		or @nStaffClassificationOperator between 2 and 6
		or @sStaffProfitCentreKey is not null
		or @nStaffProfitCentreOperator between 2 and 6
		begin
			set @sFrom = @sFrom+char(10)+"	left join EMPLOYEE EM			on (EM.EMPLOYEENO=XN.NAMENO)"

			if @nStaffClassificationKey is not null
			or @nStaffClassificationOperator between 2 and 6					  
			begin
				set @sWhere = @sWhere+char(10)+"	and	EM.STAFFCLASS "+dbo.fn_ConstructOperator(@nStaffClassificationOperator,@Numeric,@nStaffClassificationKey, null,0)	
			end

			If @sStaffProfitCentreKey is not null
			or @nStaffProfitCentreOperator between 2 and 6
			begin
				set @sWhere = @sWhere+char(10)+"	and	EM.PROFITCENTRECODE "+dbo.fn_ConstructOperator(@nStaffProfitCentreOperator,@String,@sStaffProfitCentreKey, null,0)	
			end
		end		

		if @nFromAmount is not null 
		or @nToAmount is not null
		or @nDebtorCreditLimitOperator between 7 and 8
		begin 
			set @sFrom = @sFrom+char(10)+"	left join IPNAME IP		on (IP.NAMENO=XN.NAMENO)"

			set @sWhere = @sWhere+char(10)+"	and IP.CREDITLIMIT "+dbo.fn_ConstructOperator(@nDebtorCreditLimitOperator,@Numeric,@nFromAmount, @nToAmount,0)	
		end 		

		if @nSupplierTypeKey is not null or
		   @nSupplierTypeKeyOperator between 2 and 6
		or @nSupplierRestrictionKey is not null or
		   @nSupplierRestrictionOperator between 2 and 6
		or @sPurchaseCurrency is not NULL or
		   @nPurchaseCurrencyOperator between 2 and 6
		or @nSupplierPaymentTermsKey is not null or
		   @nSupplierPaymentTermsOperator between 2 and 6
		or @nSupplierPaymentMethodKey is not null or
		   @nSupplierPaymentMethodOperator between 2 and 6	
		begin
			set @sFrom = @sFrom+char(10)+"	left join CREDITOR CR		on (CR.NAMENO=XN.NAMENO)"

			if @nSupplierTypeKey is not NULL
			or @nSupplierTypeKeyOperator between 2 and 6					  
			begin
				set @sWhere = @sWhere+char(10)+"	and	CR.SUPPLIERTYPE "+dbo.fn_ConstructOperator(@nSupplierTypeKeyOperator,@Numeric,@nSupplierTypeKey, null,0)	
			end

			If @nSupplierRestrictionKey is not null
			or @nSupplierRestrictionOperator between 2 and 6
			begin
				set @sWhere = @sWhere+char(10)+"	and	CR.RESTRICTIONID "+dbo.fn_ConstructOperator(@nSupplierRestrictionOperator,@Numeric,@nSupplierRestrictionKey, null,0)	
			end

			If @sPurchaseCurrency is not null
			or @nPurchaseCurrencyOperator between 2 and 6
			begin
				set @sWhere = @sWhere+char(10)+"	and	CR.PURCHASECURRENCY "+dbo.fn_ConstructOperator(@nPurchaseCurrencyOperator,@String,@sPurchaseCurrency, null,0)	
			end

			If @nSupplierPaymentTermsKey is not null
			or @nSupplierPaymentTermsOperator between 2 and 6
			begin
				set @sWhere = @sWhere+char(10)+"	and	CR.PAYMENTTERMNO "+dbo.fn_ConstructOperator(@nSupplierPaymentTermsOperator,@Numeric,@nSupplierPaymentTermsKey, null,0)	
			end

			If @nSupplierPaymentMethodKey is not null
			or @nSupplierPaymentMethodOperator between 2 and 6
			begin
				set @sWhere = @sWhere+char(10)+"	and	CR.PAYMENTMETHOD "+dbo.fn_ConstructOperator(@nSupplierPaymentMethodOperator,@Numeric,@nSupplierPaymentMethodKey, null,0)	
			end					
		end	

		If @sSupplierAccountNo is not null
		or @nSupplierAccountNoOperator between 2 and 6
		begin				
			set @sFrom = @sFrom+char(10)+"	left join CRENTITYDETAIL CRE		on (CRE.NAMENO=XN.NAMENO)"

			set @sWhere = @sWhere+char(10)+"	and CRE.SUPPLIERACCOUNTNO "+dbo.fn_ConstructOperator(@nSupplierAccountNoOperator,@String,@sSupplierAccountNo, null,0)	
		end	

		-- Filter by <AccessAccountKey>

		-- Only progress if sufficient information provided, ie. User ID or Account No.
		-- or check for exists/non-exists
		If @bAccessAccountKeyForCurrentUser = 1
		or @nAccessAccountKey is not null
		or @nAccessAccountKeyOperator between 5 and 6
		Begin
	
			-- Assign @nAccessAccountKey if Account ID not provided
			If @bAccessAccountKeyForCurrentUser = 1
			Begin
	
				Set @sSQLString='
					Select	@nAccessAccountKey = AA.ACCOUNTID
					from	USERIDENTITY UI
					join	ACCESSACCOUNT AA on (UI.ACCOUNTID = AA.ACCOUNTID)
					where	UI.IDENTITYID = @pnUserIdentityId'
			
				Exec  @nErrorCode=sp_executesql @sSQLString,
								N'@nAccessAccountKey	int	OUTPUT,
								  @pnUserIdentityId	int',
								  @nAccessAccountKey	=@nAccessAccountKey	OUTPUT,
								  @pnUserIdentityId	=@pnUserIdentityId
	
			End		
	
			-- Default @bAccessAccountKeyIsAccessName to 1 if none of the below options are provided
			If coalesce(@bAccessAccountKeyIsAccessName, @bAccessAccountKeyIsAccessEmployee, @bAccessAccountKeyIsUserName) is null
			or (@bAccessAccountKeyIsAccessName <> 1 and @bAccessAccountKeyIsAccessEmployee <> 1 and @bAccessAccountKeyIsUserName <> 1)
			Begin
				Set @bAccessAccountKeyIsAccessName = 1
			End		
	
			-- Setup exists clause for where clause depends on @nAccessAccountKeyOperator
			If @nAccessAccountKeyOperator in (0, 5)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and exists (	Select 1 from ACCESSACCOUNT AA"
			End

			If @nAccessAccountKeyOperator in (1, 6)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and not exists (	Select 1 from ACCESSACCOUNT AA"
			End

			-- Set "always false" for Or clause
			Set @sWhere1 = '	(0 = 1)'

			If @bAccessAccountKeyIsAccessName = 1 or @bAccessAccountKeyIsAccessEmployee = 1
			Begin	
				Set @sWhere = @sWhere+char(10)+"		left join ACCESSACCOUNTNAMES AAN	on (AAN.ACCOUNTID=AA.ACCOUNTID)"
			End

			If @bAccessAccountKeyIsAccessEmployee = 1
			Begin	
				Set @sWhere = @sWhere+char(10)+"		left join ASSOCIATEDNAME AN 		on (AN.NAMENO=AAN.NAMENO"
				Set @sWhere = @sWhere+char(10)+"							and AN.RELATIONSHIP='EMP'"
				Set @sWhere = @sWhere+char(10)+"							and AN.CEASEDDATE IS NULL)"

				Set @sWhere1 = @sWhere1+char(10)+"	or (XN.NAMENO = AN.RELATEDNAME)"
			End

			If @bAccessAccountKeyIsUserName = 1
			Begin	
				Set @sWhere = @sWhere+char(10)+"		left join USERIDENTITY UI		on (UI.ACCOUNTID=AA.ACCOUNTID)"
			
				Set @sWhere1 = @sWhere1+char(10)+"	or (XN.NAMENO = UI.NAMENO)"
			End

			If @bAccessAccountKeyIsAccessName = 1
			Begin
				Set @sWhere1 = @sWhere1+char(10)+"	or (XN.NAMENO = AAN.NAMENO)"
			End
	
			Set @sWhere = @sWhere+char(10)+"		where ((1=1)"

			If @nAccessAccountKeyOperator between 0 and 1
			and @nAccessAccountKey is not null
			Begin
				Set @sWhere = @sWhere+char(10)+"		and (AA.ACCOUNTID="+Cast(@nAccessAccountKey as varchar(50)) + ")"
			End

			-- Only attach @sWhere1 to @sWhere if at least 1 of the condition provided.
			If @bAccessAccountKeyIsAccessName = 1
			or @bAccessAccountKeyIsAccessEmployee = 1
			or @bAccessAccountKeyIsUserName = 1
			Begin
				Set @sWhere = @sWhere+char(10)+"		and (" + @sWhere1 + ")"
			End

			Set @sWhere = @sWhere+char(10)+"		))"
		End
		
		If @bIsFilesDeptStaff is not null and @bIsFilesDeptStaff = 1
		Begin
		        Set @sFrom = @sFrom+char(10)+" join USERIDENTITY UIF on (UIF.NAMENO = XN.NAMENO)
		                                       join fn_PermissionsGrantedAll('TASK',193, null, GETDATE()) as FP on (FP.IdentityKey = UIF.IDENTITYID)"
		End

		If @nCaseKey is not null
		Begin
			Set @sFrom = @sFrom+char(10)+" join CASENAME CN on (CN.NAMENO = XN.NAMENO
										and (CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()) 
										and CN.CASEID = "+Cast(@nCaseKey as varchar(11))
			If @sCaseNameTypes is not null
			Begin
				Set @sFrom = @sFrom+char(10)+"and CN.NAMETYPE"+dbo.fn_ConstructOperator(0,@CommaString,@sCaseNameTypes, null,0)
			End
			
			Set @sFrom = @sFrom+char(10)+")"					
		End

		Set @nErrorCode = @@Error
	End
End

-- RFC37451
-- Row Access Security is to also be considered if an Any Search is being performed.
If @nErrorCode = 0
Begin
	If @pbCalledFromCentura = 0
		Begin
			--------------------------------------------------------------------
			-- RFC13142
			-- Check what level of Row Access Security has been defined.
			-- This will help tailor the generated SELECT to improve performance
			--------------------------------------------------------------------
			Set @sSQLString = "
			Select	@bHasWBRowLevelSecurity=SUM(CASE WHEN(R.RECORDTYPE IS NOT NULL) THEN 1 ELSE 0 END),
				@bOfficeSecurity       =SUM(CASE WHEN(R.OFFICE     IS NOT NULL) THEN 1 ELSE 0 END),
				@bNameTypeSecurity     =SUM(CASE WHEN(R.NAMETYPE   IS NOT NULL) THEN 1 ELSE 0 END)
			from IDENTITYROWACCESS U WITH (NOLOCK) 
			join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
			where R.RECORDTYPE = 'N'
			and U.IDENTITYID = @pnUserIdentityId"
			
			exec @nErrorCode = sp_executesql @sSQLString,
				N'@bHasWBRowLevelSecurity	bit		output,
				  @bOfficeSecurity		bit		output,
				  @bNameTypeSecurity		bit		output,
				 @pnUserIdentityId		int',
				  @bHasWBRowLevelSecurity	= @bHasWBRowLevelSecurity	output,
				  @bOfficeSecurity		= @bOfficeSecurity		output,
				  @bNameTypeSecurity		= @bNameTypeSecurity		output,
				  @pnUserIdentityId		= @pnUserIdentityId
			
			 
		End
		
		If  @bHasWBRowLevelSecurity = 1
			Begin
				Set @sWhere = @sWhere
				+char(10)+"and  Substring("          
				+char(10)+"	(select MAX (   CASE WHEN RAD.OFFICE    IS NULL THEN '0' ELSE '1' END +" 
				+char(10)+"			CASE WHEN RAD.NAMETYPE  IS NULL THEN '0' ELSE '1' END +"
				+char(10)+"			CASE WHEN RAD.SECURITYFLAG < 10 THEN '0' ELSE ''  END +"  
				+char(10)+"	convert(nvarchar,RAD.SECURITYFLAG))"   
				+char(10)+"	     from IDENTITYROWACCESS UA WITH (NOLOCK) "
				+char(10)+"	left join ROWACCESSDETAIL RAD WITH (NOLOCK) on (RAD.ACCESSNAME=UA.ACCESSNAME"  

				---------------------------------------------------
				-- RFC13142
				-- Performance improvement step to only restrict to 
				-- OFFICE if row access has been defined for OFFICE
				---------------------------------------------------					
				If @bOfficeSecurity=1
				begin
					-------------------------------------------------------------------------------
					-- RFC31341 The left join to TABLEATTRIBUEST has been deliberately moved out 
					--          of the WHERE clause because if a Name is associated with more than
					--          one office then we are interested in any rule that allows the user
					--          access to the Names associated with any of those offices.
					-------------------------------------------------------------------------------
					Set @sFrom = @sFrom+char(10)+" left join TABLEATTRIBUTES TA on (TA.PARENTTABLE='NAME' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, XN.NAMENO))"
					
					Set @sWhere = @sWhere
					+char(10)+"					and (RAD.OFFICE = TA.TABLECODE or RAD.OFFICE is NULL)" 
				end

				-------------------------------------------------------
				-- RFC13142
				-- Performance improvement step to only restrict to 
				-- NAMETYPE if row access has been defined for NAMETYPE
				-------------------------------------------------------	
				If @bNameTypeSecurity=1
					Set @sWhere = @sWhere
					+char(10)+"					and (RAD.NAMETYPE in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = XN.NAMENO)" 
					+char(10)+"					 or RAD.NAMETYPE is NULL)" 

				Set @sWhere = @sWhere
				+char(10)+"					and RAD.RECORDTYPE = 'N')"  
				+char(10)+"	where UA.IDENTITYID = "+convert(nvarchar,@pnUserIdentityId)+"),   3,2)"
				+char(10)+"	in (  '01','03','05','07','09','10','11','13','15' )"     
	End
End

Set @psReturnClause=ltrim(rtrim(@sFrom+char(10)+@sWhere))
Return @nErrorCode
GO

Grant execute on dbo.naw_ConstructNameWhere to public
GO


				
			
				

