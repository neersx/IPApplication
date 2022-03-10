-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cwb_ListCaseDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cwb_ListCaseDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cwb_ListCaseDetail.'
	Drop procedure [dbo].[cwb_ListCaseDetail]
	Print '**** Creating Stored Procedure dbo.cwb_ListCaseDetail...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cwb_ListCaseDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@psResultsetsRequired	nvarchar(4000)	= null,
        @pnLanguageKey		int	= null
)
AS 
-- PROCEDURE:	cwb_ListCaseDetail
-- VERSION:	99
-- DESCRIPTION:	Returns the details for a single case that are suitable
--		to show an external user.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Sep 2003  JEK		1	Initial prototyping code - needs refinement
-- 16 Sep 2003  TM		2	RFC338 Implement new Language column. A new language column 
--					has been added to the Classes and CaseText result sets.
--					Instead of locating the client's preferred language, all 
--					the languages that are available are to be returned.
-- 16 Sep 2003	JEK		3	Reduce number of accesses to fn_FilterUserCases
--					and fix language logic.
-- 22 Sep 2003	JEK		4	Adjust Classes result set for ClassFirstUse,
--					correct the ImageType for CPA Inprostart images			
-- 23 Sep 2003	TM		5	RFC338 Case Details Web Part. Adjust the code to conform to 
--					coding standards, improve performance and implement YourReference 
--					for the DesignatedCountry result set. Include SubTypeDescription and 
--					ApplicationBasisDescription in the "Select" statement that retrieves 
--					'EmailAddress' details. Implement sp_executesql to execute all existing
--					"Select" statements. In the Financials result set combine two "Select"
--					statements into one to retrieve Billed and ServicesBilled. Also in the 
--					Financial result set convert BilledPercentage and ServicesPercentage 
--					to an integer. 
-- 03-Oct-2003	MF	RFC519	6	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 23-Oct-2003	TM	RFC338	7	Case Details Web Part. Implement the new cs_ListCriticalDates stored 
--					procedure for the Critical Dates result set. Set the @nFilterCaseKey
--					to the @pnCaseKey if the user does have access to the Case. In the 
--					"Images result set" section remove join "and D.TABLETYPE = 12".
-- 04-Nov-2003	TM	RFC581	8	Design an approach for displaying an image using data from database.
--					In the 'Images' result set return IMAGEID as ImageKey instead of IMAGEDATA.	
-- 05-Nov-2003	TM	RFC581	9	Design an approach for displaying an image using data from database.
--					Remove join to the IMAGE table.
-- 14-Nov-2003	TM	RFC338 	10	Add a new CurrencyCode column to the financials result set.
-- 06-Dec-2003	JEK	RFC406	11	Implement topic level security.
-- 09-Dec-2003	JEK	RFC702	12	Select for OurContact email produces no results if there is no email address.
-- 19-Feb-2004	TM	RFC976	13	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Mar-2004	TM	RFC1032	14	In the retrieving of the 'EmailAddress' details ('OurContact' email), SubTypeDescription,  
--					ApplicationBasisDescription, PurchaseOrderNo and TaxTreatment section and in the 
--					Case Result Set pass @pnCaseKey as the @pnCaseKey to the fn_FilterUserCases. 
-- 10-Mar-2004	TM	RFC868	15	Modify the logic extracting the 'EmailAddress' column in the Case Result Set 
--					to use new Name.MainEmail column. 
-- 30-Mar-2004	TM	RFC399	16	Implement a call to ip_RegisterAccess to update the index:
--					@psDatabaseTable = 'CASES', @pnIntegerKey = @pnCaseKey
-- 26-May-2004	TM	RFC863	17	For the NameType in ('Z', 'D') extract the AttentionKey, Attention 
--					and Address  in the same manner as billing (SQA7355).
-- 31-May-2004	TM	RFC863	18	Improve the commenting of SQL extracting the Billing Address/Attention.
-- 03-Sep-2004	TM	RFC1783	19	Populate the new Attachment datatable.
-- 23-Aug-2004	TM	RFC1233	19	Populate the new WebLinks datatable by calling fn_GetCriteriaRows.  
-- 09 Sep 2004	JEK	RFC886	20	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 21 Sep 2004	TM	RFC886	21	Implement translation.
-- 22 Sep 2004	TM	RFC886	22	Implement translation in the WebLinks datatable.
-- 29 Sep 2004	MF	RFC1846	23	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 29-Sep-2004	TM	RFC1806	24	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.
-- 27-Oct-2004	TM	RFC1155	25	Populate new information in the dataset.
-- 29 Oct 2004	TM	RFC1233	26	Modify result sets for WebLinks to include URL and group information.
-- 05 Nov 2004	TM	RFC1233	27	Populate the WebLinks result set using new csw_ListWebLink.				  
-- 29 Nov 2004	TM	RFC1155	28	Use more meaningful full word in the @sEntSzDesc variable name. 
-- 15 Dec 2004	TM	RFC1155	29	Add new new RowKey column in the CaseName, OccurredEvents and DueEvents datatables.
-- 02 Mar 2004	TM	RFC2404	30	Modify the "isnull(CT.SHORTTEXT,CT.TEXT)" to be "isnull(CT.TEXT, CT.SHORTTEXT)" 
--					in the Classes and CaseText result sets. In the Classes result set, cast text 
--					as nvarchar(4000) to avoid SQL error.
-- 26 Apr 2005	TM	RFC2126	31	Implement Case.AttachmentCount column. Remove call to ip_ListAttachment.
-- 15 May 2005	JEK	RFC2508	32	Extract @sLookupCulture and pass to translation instead of @psCulture
--					Also pass @sLookupCulture to child procedures that are known not to need the original @psCulture
-- 23 May 2005	TM	RFC2594	33	Only perform one lookup of the BillingInstructions, BillingHistory, WIP, Prepayments subjects.
-- 11 Jul 2005	TM	RFC2614	34	Debtor level prepayments should only be included if they match the property type 
--					of the case or if no property type was specified for the prepayments.
-- 12 Oct 2005	TM	RFC2255	35	Add new OfficialElementID, ElementDescription and ImageDescription columns to the Images result set.
-- 19 Oct 2005	TM	RFC2177	36	Add new IntClasses columns to the Case result set.
-- 01 Dec 2005	TM	RFC3254	37 	Replace the call to cs_ListCaseTree with a call to csw_ListRelatedCase.
-- 07 Dec 2005	LP	RFC1017	38	Extract @nLocalCurrencyDecimalPlaces and @sLocalCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to Financials and WIP result set
-- 16 Jan 2006	TM	RFC1659	39	In the CaseName result set, return new NameVariant column.
-- 08 Feb 2006	TM	RFC3429	40	Return the EventText column in the OccurredEvents and DueEvents result sets 
--					if Client Event Text site control is set to TRUE.
-- 03 Jul 2006	SW	RFC4038	41	Add RowKey
-- 06 Jul 2006	SW	RFC3614	42	Add status to DesignatedCountries result set
-- 17 Jul 2006	SW	RFC3217	43	Remove population of some CASE fields, implement CaseExtended result set and new param @psResultsetsRequired
-- 21 Jul 2006	SW	RFC3828	44	Pass getdate() to fn_Permission..
-- 27 Jul 2006	SW	RFC3217	45	Code cutting Case and CaseExtended result set
-- 18 Sep 2006	AU	RFC4144	46	Return 2 new columns "FromCaseKey" and "FromCaseReference" in the DueEvents and OccurredEvents tables
-- 22 Sep 2006	LP	RFC4446	47	Return correct Wip Currency Code in WipByCurrency result set
-- 18 Dec 2006	JEK	RFC2982	48	Implement new HasInstructions column.
-- 22 Jan 2007	PG	RFC4903	49	Include CaseText without Classes in CaseText result set
-- 28 Feb 2007	PY	SQA14425 50 Reserved word [date,language]
-- 17 Apr 2007	SF	RFC5146	51	Format a space after each comma in the comma-delimited Local Classes and International Classes
-- 07 May 2007	LP	RFC3865	52	Add event amounts and document number to Events result sets
-- 06 Jun 2007	LP	RFC3865	53	Join to ACTIVITYHISTORY where the ACTIVITYCODE is 3204
-- 03 Oct 2007	SF	RFC4278 54	Remove CanViewAttachments from Case result set
-- 12 Dec 2007	AT	RFC3208	55	Modify Case Classes.
-- 27 Feb 2008	LP	RFC5799	56	Return new ResponsibleNameKey and ResponsibleName in Events result sets
-- 11 Jul 2008  LP      RFC6645 57      Return OurContact based on WorkBench Contact Name Type site control.
-- 01 Sep 2008	AT	RFC6991	58	Return Is CRM flag from CASETYPE.
-- 14-Oct-2008  LP      RFC7165 59      Return CaseTypeKey column in Case result set.
-- 11 Dec 2008	MF	17136	60	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 13 Jan 2009	MF	RFC7264	61	Control the due date cycles that may be displayed by allowing the EVENTS.CONTROLLINGACTION
--					to be used to specify an explicit Action that must be open for the Event to be considered due.
-- 23 Oct 2009	DV	R8371	62	Modify logic to get the classes and sub classes.
-- 15 Dec 2009	ASH	R8561	63	Count of Local and International Classes.
-- 07 Jul 2010	LP	R9531	64	Return Purchase Order Number regardless of BillingInstructions subject security
-- 17 Sep 2010	MF	R9777	65	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 09 Nov 2010	ASH	R9818	66      Modify logic to get the classes and sub classes.
-- 10 Nov 2010	ASH	R9788	67      Maintain CASE TEXT in foreign languages.
-- 16 Nov 2010	ASH	R9788	68      Change logic to get all the selected class in CASECLASSES result set.
-- 29 Nov 2010	ASH	R10009	69     Implement logic to get all CASE CLASSES when there is no row in CASETEXT table.
-- 16 Dec 2010	MF	R10109	70	Recoded RFC10009. SQL Error was occurring. I also took the opportunity to simplify the code
--					and make it run more efficiently.  
--					Also, return the Staff name with the list of names.
-- 11 Jan 2011	SF	R10159	71	Financials resultset not being returned when permission not granted.  
--					Empty result set should be returned for the calling code.
-- 01 Feb 2011	ASH	R8864	72	Include Signatory and Staff Name Types in Case Name result set.
-- 02 Feb 2011  LP      R10199	73	Display class headings where there is no Goods & Services text against the class.
-- 10 Feb 2011	ASH	R100438	74	Change the logic of Case Text for Goods and Services in Case Classes result set Also Added a column "isTextPresent" in CaseClasses result set..
-- 13 Apr 2011	ASH	R100436	75	Include SubClass to row Key in Case Classes result set.
-- 24 Oct 2011	ASH	R11460	76	Cast integer columns as nvarchar(11) data type.
-- 20 Feb 2012	LP	R11835	77	Fix highlight on case text for classes with a subclass
-- 06 Mar 2012	LP	R12027	78	Return IsDueDatePast column in DUEEVENTS result set
-- 07 Jun 2013	AK	R13408  79 Modified designated country result set to return classes, designated date, group joining  date and Extension State 
--10 Jun 2013	AK	R13408	80	Added IsDefaultedFromParentCase in designated country result set 
-- 08 Nov 2013  SW      R27304  81      Apply Name Code style to the formatted name
-- 25 Mar 2014	MF	R32793	82	Ensure CONTROLLINGACTION is considered for Events to be displayed.
-- 22 Apr 2014	MF	R32808	83	External users are to check the sitecontrol "Client Due Dates: Overdue Days" and if a value exists then duedates are
--					displayed are to be restricted so that they are no older than the number of days specified. Related to RFC12703
-- 23 Sep 2015  DV	R50824  84     Return the Trade Mark Image in the header if specified in Image Type for Case Header site control.
-- 23 Sep 2015  MS      R50825  85    Return the Application Filing Date in the header
-- 10 Nov 2015	KR	R53910	86	Adjust formatted names logic (DR-15543)     
-- 07 Dec 2015	MF	R56007	87	For external users the Status Summary for a designated country should only be returned if there is an associated national phase case.
-- 16 Oct 2017  MS      R72507  88      Add CaseFamilyTitle in the resultset
-- 11 Dec 2017  MS      R73074  89      Replaces CaseFamilyTitle with CaseFamilyFormatted field
-- 25 Jun 2018  MS      R73676  90      Do not show CaseFamilyReference in brackets if it matches CaseFamilyTitle Field
-- 07 Sep 2018	DV R74675		91	Do not return sub class if items are configured for a property type
-- 17 Sep 2018	DV R74394		92	Return the count of Items for the Case.
-- 09 Oct 2018  DV R74974	93 Return SubClass as null if Property Type does not allow subclass
-- 11 Oct 2018  AV 74875	94 Highlight items that are not defined
-- 14 Nov 2018  AV  75198/DR-45358	95   Date conversion errors when creating cases and opening names in Chinese DB
-- 16 Apr 2019	AV DR-46835	96   Deleting default Goods & Services text from Case causes it to reappear in blue
-- 25 Apr 2019  SW DR-48469 97 Updated case classes resultset to return correct case text by considering default language
-- 25 Apr 2019  SW DR-46807 98 Return DefaultLanguageKey in Case Classes result set
-- 06 Sep 2019	DV DR-41559 99 Get the Email subject from DocItem if configured

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @nRowCount			int

Declare @sSQLString			nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Declare @nFilterCaseKey			int
Declare @sYourReference			nvarchar(80)
Declare @nClientCorrespondName		int
Declare @nClientMainContact		int

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

Declare @sSubTypeDescription 		nvarchar(50) 
Declare @sApplicationBasisDescription 	nvarchar(50)
Declare @sYourContactName		nvarchar(254)
Declare @nYourContactKey		int

Declare	@nBilledToDate			decimal(11,2)
Declare @nServicesBilled		decimal(11,2)

Declare @bIsBillingRequired		bit
Declare @bIsBillingInstructionsAvailable bit
Declare @bIsAttachmentAvailable		bit
Declare @bIsWIPAvailable		bit
Declare @bIsPrepaymentAvailable		bit
Declare @sEntitySizeDescription		nvarchar(80)
Declare	@bHasInstructions		bit

Declare	@nOverdueDays			int
Declare	@dtOverdueRangeFrom		datetime	-- external users restricted from seeing overdue dates

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @dtToday			datetime
Declare @sClasses 			nvarchar(254)
Declare @sRenewalAction			nvarchar(2)
Declare @bShowEventText			bit
Declare	@bShowAllEventDates		bit

Declare @sLocalClasses 			nvarchar(254)
Declare @sIntClasses 			nvarchar(254)
Declare @nCountIntClasses		int
Declare @nCountLocalClasses		int
Declare @nCountClassItems		int
Declare @nLanguage			int
Declare @dApplicationFilingDate         datetime
Declare @bAllowSubClass bit
Declare @nAllowSubClassItem int

Declare @sCaseReference nvarchar(30)
Declare @nDocItemKey int
Declare @tDocItem table (DocItemText ntext)
Declare @psEmailSubject nvarchar(max)

CREATE TABLE #TEMPCLASSESTEXT (
	CLASS				nvarchar(200)	collate database_default NULL,
	TEXTNO				smallint	NULL
)

set @nLanguage = dbo.fn_GetLanguage(@psCulture)

-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','

Set     @nErrorCode = 0
Set	@dtToday = getdate()

-- Security check, and also prepare variables for CASE result set while checking security
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@nFilterCaseKey		= CASEID,
			@sYourReference		= FC.CLIENTREFERENCENO,
			@nClientCorrespondName	= FC.CLIENTCORRESPONDNAME,
			@nClientMainContact	= FC.CLIENTMAINCONTACT			
		from	dbo.fn_FilterUserCases(@pnUserIdentityId,1,@pnCaseKey) FC
		"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @pnCaseKey			int,
					  @nFilterCaseKey		int				OUTPUT,
					  @sYourReference		nvarchar(80)			OUTPUT,
					  @nClientCorrespondName	int				OUTPUT,
					  @nClientMainContact		int				OUTPUT',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnCaseKey			= @pnCaseKey,
					  @nFilterCaseKey		= @nFilterCaseKey		OUTPUT,
					  @sYourReference		= @sYourReference		OUTPUT,
					  @nClientCorrespondName	= @nClientCorrespondName	OUTPUT,
					  @nClientMainContact		= @nClientMainContact		OUTPUT
	
End

-- Retrieve Local Currency information
If @nErrorCode=0
and (   @psResultsetsRequired = ','
     or CHARINDEX('FINANCIALS,', @psResultsetsRequired) <> 0
     or CHARINDEX('WIPBYCURRENCY,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Check if the Attachments, Billing Instructions, Billing History, Work In Progress Items
-- and Prepayments topics are available:

-- Check whether the Billing History topic available:
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('FINANCIALS,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	select @bIsBillingRequired = IsAvailable
	from	dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsBillingRequired		bit			OUTPUT,
					  @dtToday			datetime',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsBillingRequired		= @bIsBillingRequired	OUTPUT,
					  @dtToday			= @dtToday

End

-- Check whether the Billing Instructions topic available:
If @nErrorCode = 0
and (   @psResultsetsRequired = ',' 
     or CHARINDEX('CASEEXTENDED,', @psResultsetsRequired) <> 0
     or CHARINDEX('BILLINGNAMES,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	select @bIsBillingInstructionsAvailable = IsAvailable
	from	dbo.fn_GetTopicSecurity(@pnUserIdentityId, 100, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId			int,
					  @bIsBillingInstructionsAvailable	bit				   OUTPUT,
					  @dtToday				datetime',
					  @pnUserIdentityId			= @pnUserIdentityId,
					  @bIsBillingInstructionsAvailable	= @bIsBillingInstructionsAvailable OUTPUT,
					  @dtToday				= @dtToday

End

-- Check whether the Work In Progress Items topic available:
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('WIPBYCURRENCY,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	select	@bIsWIPAvailable = WIP.IsAvailable,
		@bIsPrepaymentAvailable = PREPAY.IsAvailable
	from	dbo.fn_GetTopicSecurity(@pnUserIdentityId, 120, default, @dtToday) WIP
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 201, default, @dtToday) PREPAY on (1 = 1)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @bIsWIPAvailable		bit			OUTPUT,
					  @bIsPrepaymentAvailable	bit			  OUTPUT,
					  @dtToday			datetime',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @bIsWIPAvailable		= @bIsWIPAvailable 	OUTPUT,
					  @bIsPrepaymentAvailable	= @bIsPrepaymentAvailable OUTPUT,	
					  @dtToday			= @dtToday
End

-- Prepare variables to populate the Case table 
If @nErrorCode = 0
and (   @psResultsetsRequired = ',' 
     or CHARINDEX('CASE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = " 
	Select   @sSubTypeDescription		= "+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
		"@sApplicationBasisDescription 	= "+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
		"@sEntitySizeDescription	= "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
		"@sYourContactName		= dbo.fn_FormatNameUsingNameNo(CON.NAMENO,COALESCE(CON.NAMESTYLE,CONNAT.NAMESTYLE,7101)),"+char(10)+
		"@nYourContactKey		= CON.NAMENO"+char(10)+
	"from CASES C"+char(10)+
	"left join NAME CON on (CON.NAMENO=isnull(@nClientCorrespondName,@nClientMainContact))"+char(10)+
	"left join COUNTRY CONNAT on (CONNAT.COUNTRYCODE=CON.NATIONALITY)"+char(10)+
	"left join PROPERTY P		 on (P.CASEID = C.CASEID)"+char(10)+
	"left join VALIDSUBTYPE VS	 on (VS.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                          	"and VS.CASETYPE     = C.CASETYPE"+char(10)+
	                          	"and VS.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                          	"and VS.SUBTYPE      = C.SUBTYPE"+char(10)+
	                     		"and VS.COUNTRYCODE  = (select min(VS1.COUNTRYCODE)"+char(10)+
	                     	                               "from VALIDSUBTYPE VS1"+char(10)+
	                     	               	               "where VS1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                                  	               "and   VS1.CASETYPE     = C.CASETYPE"+char(10)+
	                          	                       "and   VS1.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                          	                       "and   VS1.SUBTYPE      = C.SUBTYPE"+char(10)+
	                     	                               "and   VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	"left join VALIDBASIS VB	 on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                          	"and VB.BASIS        = P.BASIS"+char(10)+
	                     		"and VB.COUNTRYCODE  = (select min(VB1.COUNTRYCODE)"+char(10)+
	                     	                               "from VALIDBASIS VB1"+char(10)+
	                     	                               "where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                                  	               "and   VB1.BASIS        = P.BASIS"+char(10)+
	                     	                               "and   VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	"left join TABLECODES TC2 	on (TC2.TABLECODE=C.ENTITYSIZE)"+char(10)+
	"where C.CASEID = @nFilterCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nFilterCaseKey		int,
					  @pnUserIdentityId		int,
					  @nClientCorrespondName	int,
					  @nClientMainContact		int,
					  @sYourContactName		nvarchar(254)		OUTPUT,
					  @nYourContactKey		int			OUTPUT,
					  @sSubTypeDescription	 	nvarchar(50)		OUTPUT,
					  @sApplicationBasisDescription nvarchar(50)	  	OUTPUT,
					  @sEntitySizeDescription	nvarchar(80)		OUTPUT',
					  @nFilterCaseKey		= @nFilterCaseKey,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @nClientCorrespondName	= @nClientCorrespondName,
					  @nClientMainContact		= @nClientMainContact,
					  @sYourContactName		= @sYourContactName	OUTPUT,
					  @nYourContactKey		= @nYourContactKey	OUTPUT,
					  @sSubTypeDescription		= @sSubTypeDescription	OUTPUT,
					  @sApplicationBasisDescription	= @sApplicationBasisDescription OUTPUT,
					  @sEntitySizeDescription	= @sEntitySizeDescription OUTPUT

	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
		SELECT @bHasInstructions=cast(sum(1) as bit)
		FROM INSTRUCTIONDEFINITION D
		-- Driving event is either the prerequisite event or the due event
		JOIN EVENTS E		on (E.EVENTNO=isnull(D.PREREQUISITEEVENTNO,D.DUEEVENTNO))
		-- The driving event must exist against the case
		JOIN CASEEVENT P	on (P.CASEID=@nFilterCaseKey
					and P.EVENTNO=E.EVENTNO)
		-- Available for single case entry
		WHERE 	D.AVAILABILITYFLAGS&2=2"

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nFilterCaseKey		int,
						  @bHasInstructions		bit 	OUTPUT',
						  @nFilterCaseKey		= @nFilterCaseKey,
						  @bHasInstructions		= @bHasInstructions	OUTPUT

		set @bHasInstructions=isnull(@bHasInstructions,0)

	End

        If @nErrorCode = 0
        Begin
                Set @sSQLString = "
                Select @dApplicationFilingDate = ISNULL(CE.EVENTDATE, CE.EVENTDUEDATE)
                FROM CASEEVENT CE
                where CE.CASEID = @nFilterCaseKey
                and EVENTNO = -4
                and CYCLE = (select max(CYCLE)
					from CASEEVENT CE1
					where CE1.CASEID =CE.CASEID
					and   CE1.EVENTNO=CE.EVENTNO
					and   ISNULL(CE1.EVENTDATE, CE1.EVENTDUEDATE) is not null)"

                exec @nErrorCode = sp_executesql @sSQLString,
						N'@nFilterCaseKey		int,
						  @dApplicationFilingDate	datetime 	OUTPUT',
						  @nFilterCaseKey		= @nFilterCaseKey,
						  @dApplicationFilingDate	= @dApplicationFilingDate	OUTPUT
        End

	If @nErrorCode = 0
	BEGIN
		-- Get the DocItem information:
		If @nErrorCode = 0
		Begin		
			-- Get the DocItemKey and CaseReference to pass to the cs_RunCaseDocItem
			-- stored procedure:		
			Set @sSQLString=
			"Select @sCaseReference = C.IRN,
				@nDocItemKey	= I.ITEM_ID	
		  		from ITEM I
				join CASES C		on (C.CASEID = @pnCaseKey) 				
				join SITECONTROL SC	on (SC.CONTROLID = 'Email Case Subject'
							and SC.COLCHARACTER = I.ITEM_NAME)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@sCaseReference	nvarchar(30)	OUTPUT,
						  @nDocItemKey		int		OUTPUT,
						  @pnCaseKey		int',
						  @sCaseReference	= @sCaseReference OUTPUT,
						  @nDocItemKey		= @nDocItemKey	OUTPUT,
						  @pnCaseKey		= @pnCaseKey
		End

		if @nErrorCode = 0  and @nDocItemKey is not null
		BEGIN		
			Insert into @tDocItem (DocItemText)
			Exec  dbo.cs_RunCaseDocItem		
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnDocItemKey 		= @nDocItemKey,
				@pnCaseKey 		= @pnCaseKey,
				@psCaseReference 	= @sCaseReference
				
			Select top 1 @psEmailSubject = DocItemText from @tDocItem
		END		
	END
End

-- Case result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"cast(C.CASEID as nvarchar(11)) as RowKey,"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"C.CASETYPE as CaseTypeKey,"+char(10)+
	"C.CURRENTOFFICIALNO as CurrentOfficialNumber,"+char(10)+
	"@sYourReference as YourReference,"+char(10)+
	"C.IRN as OurReference,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+" as StatusSummary,"+char(10)+
	dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)+" as CaseStatusDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura)+" as RenewalStatusDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+" as CaseTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CountryName,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as PropertyTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+" as CaseCategoryDescription,"+char(10)+
	"@sSubTypeDescription as SubTypeDescription,"+char(10)+
	"@sApplicationBasisDescription as ApplicationBasisDescription,"+char(10)+
	 dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TM',@sLookupCulture,@pbCalledFromCentura)+" as TypeOfMarkDescription,"+char(10)+
	"dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO,COALESCE(STAFF.NAMESTYLE,STAFFNAT.NAMESTYLE,7101))"+char(10)+
	"as OurContactName,"+char(10)+ 
	"STAFF.NAMENO as OurContactKey,"+char(10)+
	"@sYourContactName as YourContactName,"+char(10)+ 
	"@nYourContactKey as YourContactKey,"+char(10)+
	"C.FAMILY as CaseFamilyReference,"+char(10)+
        "CASE WHEN C.FAMILY is not null then case when C.FAMILY <> CF.FAMILYTITLE then char(123) + C.FAMILY + char(125) + SPACE(1) + " + dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura) + " else " + dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura) + " end else null end as CaseFamilyFormatted,"+char(10)+
	"dbo.fn_FormatTelecom(M.TELECOMTYPE,M.ISD,M.AREACODE,M.TELECOMNUMBER,M.EXTENSION)"+char(10)+
	"as EmailAddress,"+char(10)+
	"CASE WHEN @nDocItemKey is null THEN C.IRN + SPACE(1) + "+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"ELSE @psEmailSubject END as EmailSubject,"+char(10)+
	"@sEntitySizeDescription as EntitySizeDescription,"+char(10)+
	"P.NOOFCLAIMS as NoOfClaims,"+char(10)+
	"@bHasInstructions as HasInstructions,"+char(10)+
	"isnull(CS.CRMONLY,0) as IsCRM,"+char(10)+
        "CI.IMAGEID as ImageKey,"+char(10)+
	"CI.CASEIMAGEDESC as ImageDescription,"+char(10)+
        "@dApplicationFilingDate as ApplicationFilingDate"+char(10)+
	"from CASES C"+char(10)+
	"join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)"+char(10)+
	"join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+	
	"left join SITECONTROL SC on (SC.CONTROLID = 'WorkBench Contact Name Type')"+char(10)+
	"join VALIDPROPERTY VP 	on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
				"from VALIDPROPERTY VP1"+char(10)+
				"where VP1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join CASENAME CN		on (CN.CASEID = C.CASEID"+char(10)+
	                      		"and(CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate() )"+char(10)+
	                      		"and CN.NAMETYPE=(select max(CN1.NAMETYPE) from CASENAME CN1"+char(10)+
	                      	                 	 "where CN1.CASEID = CN.CASEID"+char(10)+
	                     	                 	 "and CN1.NAMETYPE in (ISNULL(SC.COLCHARACTER,'SIG'),'EMP')"+char(10)+
	                      	                 	 "and(CN1.EXPIRYDATE is null or CN1.EXPIRYDATE > getdate())))"+char(10)+
	"left join NAME NCN		on (NCN.NAMENO = CN.NAMENO)"+char(10)+
	"left join TELECOMMUNICATION M 	on (M.TELECODE = NCN.MAINEMAIL)"+char(10)+
	"left join PROPERTY P on (P.CASEID=C.CASEID)"+char(10)+
	"left join STATUS RS on (RS.STATUSCODE=P.RENEWALSTATUS)"+char(10)+
	"left join STATUS ST on (ST.STATUSCODE=C.STATUSCODE)"+char(10)+
	"left join TABLECODES TC on (TC.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) THEN 7603"+char(10)+
							"WHEN(ST.REGISTEREDFLAG=1) THEN 7602"+char(10)+
							"ELSE 7601"+char(10)+
							"END)"+char(10)+
	"left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
					"and VC.CASETYPE=C.CASETYPE"+char(10)+
					"and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
					"and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)"+char(10)+
					"from VALIDCATEGORY VC1"+char(10)+
					"where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
					"and VC1.CASETYPE=C.CASETYPE"+char(10)+
					"and VC1.CASECATEGORY=C.CASECATEGORY"+char(10)+
					"and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join TABLECODES TM on (TM.TABLECODE=C.TYPEOFMARK)"+char(10)+	
	"left join CASENAME OUR	on (OUR.CASEID=C.CASEID"+char(10)+
					"and(OUR.EXPIRYDATE is null or OUR.EXPIRYDATE>getdate())"+char(10)+
					"and OUR.NAMETYPE=(select max(CN.NAMETYPE) from CASENAME CN"+char(10)+
					                "where CN.CASEID=OUR.CASEID"+char(10)+
					                "and   CN.NAMETYPE in (ISNULL(SC.COLCHARACTER,'SIG'),'EMP')"+char(10)+
					                "and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))"+char(10)+
	"left join NAME STAFF on (STAFF.NAMENO=OUR.NAMENO)"+char(10)+
	"left join COUNTRY STAFFNAT on (STAFFNAT.COUNTRYCODE=STAFF.NATIONALITY)"+char(10)+
        "left join SITECONTROL SCI on (SCI.CONTROLID='Image Type for Case Header')"+char(10)+
	"left join CASEIMAGE CI on (CI.CASEID=C.CASEID and CI.IMAGETYPE = SCI.COLINTEGER"+char(10)+
				"and CI.IMAGESEQUENCE = (Select MIN(IMAGESEQUENCE) from CASEIMAGE CI1"+char(10)+
							"WHERE CI1.CASEID = @nFilterCaseKey and CI1.IMAGETYPE = SCI.COLINTEGER))"+char(10)+
        "left join CASEFAMILY CF on (C.FAMILY = CF.FAMILY)"+char(10)+		
	"Where C.CASEID=@nFilterCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterCaseKey		int,
					  @pnUserIdentityId	 	int,
					  @dtToday			datetime,
					  @sYourReference		nvarchar(80),
					  @sYourContactName		nvarchar(254),
					  @nYourContactKey		int,
					  @sSubTypeDescription	 	nvarchar(50),
					  @sApplicationBasisDescription nvarchar(50),
					  @sEntitySizeDescription	nvarchar(80),
					  @bHasInstructions		bit,
                      @dApplicationFilingDate       datetime,
					  @nDocItemKey				int,
					  @psEmailSubject			nvarchar(max)',
					  @nFilterCaseKey		= @nFilterCaseKey,
					  @pnUserIdentityId	 	= @pnUserIdentityId,
					  @dtToday			= @dtToday,
					  @sYourReference		= @sYourReference,
					  @sYourContactName		= @sYourContactName,
					  @nYourContactKey		= @nYourContactKey,
					  @sSubTypeDescription		= @sSubTypeDescription,
					  @sApplicationBasisDescription	= @sApplicationBasisDescription,
					  @sEntitySizeDescription	= @sEntitySizeDescription,
					  @bHasInstructions		= @bHasInstructions,
                      @dApplicationFilingDate       = @dApplicationFilingDate,
					  @nDocItemKey = @nDocItemKey,
					  @psEmailSubject = @psEmailSubject

End

if @nErrorCode = 0
begin

    Set @sSQLString = 
    "Select"+char(10)+
	" @sLocalClasses = LOCALCLASSES,"+char(10)+
	" @sIntClasses   = INTCLASSES"+char(10)+
	" From	CASES"+char(10)+
	" where	CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 		int,
					  @sLocalClasses			nvarchar(254) Output,
					  @sIntClasses			nvarchar(254) Output',
					  @pnCaseKey		 		= @pnCaseKey,
					  @sLocalClasses			=  @sLocalClasses Output,
					  @sIntClasses             =  @sIntClasses Output


if @sLocalClasses is not null
Begin
  Set @sSQLString = 
    "Select"+char(10)+
	" @nCountLocalClasses = Count(T.Parameter) "+char(10)+
	" From dbo.fn_Tokenise(@sLocalClasses, ',') T"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCountLocalClasses		 		int Output,
					  @sLocalClasses			nvarchar(254) ',
					  @nCountLocalClasses			=  @nCountLocalClasses Output,
					  @sLocalClasses             =  @sLocalClasses
	Set @sSQLString = 
    "Select"+char(10)+
	" @nCountClassItems = Count(*) "+char(10)+
	" From CASECLASSITEM CCI JOIN CLASSITEM CI on (CCI.CLASSITEMID = CI.ID)
	Where CASEID = @pnCaseKey
	AND CI.LANGUAGE is null"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCountClassItems		 		int Output,
					  @pnCaseKey					int ',
					  @nCountClassItems				=  @nCountClassItems Output,
					  @pnCaseKey					=  @pnCaseKey
  End 

 if @sIntClasses is not null 
 Begin
	Set @sSQLString = 
		"Select"+char(10)+
		" @nCountIntClasses = Count(T.Parameter) "+char(10)+
		" From dbo.fn_Tokenise(@sIntClasses, ',') T"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCountIntClasses		 		int Output,
					  @sIntClasses			nvarchar(254) ',
					  @nCountIntClasses			=  @nCountIntClasses Output,
					  @sIntClasses             =  @sIntClasses
   End 
	
End

-- CaseExtended result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASEEXTENDED,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"REPLACE(ISNULL(C.LOCALCLASSES,''),',',', ') as LocalClasses,"+char(10)+
	"REPLACE(ISNULL(C.INTCLASSES,''),',',', ') as IntClasses,"+char(10)+
	" @nCountLocalClasses as TotalLocal,"+char(10)+
	" @nCountClassItems as TotalItems,"+char(10)+
	" @nCountIntClasses as TotalInternational,"+char(10)+
	"C.PURCHASEORDERNO as PurchaseOrderNo,"+char(10)+
 	-- Does the user has access to the Billing Instructions topic?
	"case 	when @bIsBillingInstructionsAvailable = 1 "+char(10)+
	"	then TR.DESCRIPTION "+char(10)+
	"	else NULL end as TaxTreatment,"+char(10)+
	"C.IPODELAY as IPOfficeDelay,"+char(10)+
	"C.APPLICANTDELAY as ApplicantDelay,"+char(10)+
	"CASE WHEN C.IPODELAY>=C.APPLICANTDELAY THEN (C.IPODELAY-C.APPLICANTDELAY) ELSE NULL END as CalculatedDelay,"+char(10)+
	"C.IPOPTA as IPOfficePTA,"+char(10)+
	"cast(C.CASEID as nvarchar(11)) as RowKey"+char(10)+
	"from CASES C"+char(10)+
	"left join TAXRATES TR		on (C.TAXCODE = TR.TAXCODE)"+char(10)+
	"Where C.CASEID = @nFilterCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nFilterCaseKey		 	int,
					  @bIsBillingInstructionsAvailable	bit,
					  @nCountLocalClasses		int,
					  @nCountIntClasses			int,
					  @nCountClassItems			int,
					  @pnUserIdentityId			int',	
					  @nFilterCaseKey		 	= @nFilterCaseKey,
					  @bIsBillingInstructionsAvailable	= @bIsBillingInstructionsAvailable,
					  @nCountLocalClasses			=  @nCountLocalClasses,
					  @nCountIntClasses             =  @nCountIntClasses,
					  @nCountClassItems				=  @nCountClassItems,
					  @pnUserIdentityId			= @pnUserIdentityId
End

-- security check already done inside cs_ListCriticalDates
-- Critical Dates result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CRITICALDATES,', @psResultsetsRequired) <> 0)
Begin

	exec @nErrorCode = dbo.cs_ListCriticalDates
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbIsExternalUser	= 1,
		@psCulture		= @sLookupCulture,
		@pnCaseKey		= @pnCaseKey

End

-- CaseName result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASENAME,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	CN.CASEID	as CaseKey,
		CN.NAMETYPE	as NameTypeKey,
		CN.NAMENO	as NameKey,
		CN.SEQUENCE 	as NameSequence,
		NT.DESCRIPTION	as NameTypeDescription,
		dbo.fn_ApplyNameCodeStyle(dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NAT.NAMESTYLE, 7101)),
		                        NT.SHOWNAMECODE, N.NAMECODE) as Name,
		CN.REFERENCENO	as ReferenceNo,
		dbo.fn_FormatName(NV.NAMEVARIANT, NV.FIRSTNAMEVARIANT, null, null)
		 		as NameVariant,
		cast(CN.CASEID as varchar(11)) 	+ '^' + 
		CN.NAMETYPE 			+ '^' +
		cast(CN.NAMENO as varchar(11)) 	+ '^' + 
		cast(CN.SEQUENCE as varchar(5))
					as RowKey,
		dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null)
					as Attention,
		N1.NAMENO	 	as AttentionKey		
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,1,@pbCalledFromCentura) NT 
				on (NT.NAMETYPE = CN.NAMETYPE)
	join NAME N 		on (N.NAMENO = CN.NAMENO)
	left join COUNTRY NAT 	on (NAT.COUNTRYCODE = N.NATIONALITY)
	left join NAME N1	on (N1.NAMENO=CN.CORRESPONDNAME)	
	left join NAMEVARIANT NV on (NV.NAMEVARIANTNO=CN.NAMEVARIANTNO)
	where CN.CASEID = @nFilterCaseKey
	-- Exclude Signatory as it is reported separately as our contact
	and   CN.NAMETYPE not in ('SIG')
	order by CASE	CN.NAMETYPE 			-- strictly only for orderby, not needed by CASEDATA
		  	WHEN	'I'	THEN 0		-- Instructor
		  	WHEN 	'A'	THEN 1		-- Agent
		  	WHEN 	'O'	THEN 2		-- Owner
			WHEN	'EMP'	THEN 3		-- Staff
			WHEN	'SIG'	THEN 4		-- Signatory
			ELSE 		     5		/* others, order by description and sequence */
		 END,
		 NT.DESCRIPTION,
		 CN.SEQUENCE"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nFilterCaseKey   	int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @nFilterCaseKey	= @nFilterCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura

End

-- CaseClasses result set
If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CLASSES,', @psResultsetsRequired) <> 0))
Begin
	Set @sSQLString = "
		SELECT @sClasses = C.LOCALCLASSES 
		FROM CASES C
		WHERE C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@sClasses	nvarchar(254) output,
				@pnCaseKey	int',
				@sClasses	= @sClasses output,
				@pnCaseKey	= @pnCaseKey
				
	Set @sSQLString = "
	SELECT @bAllowSubClass = CASE WHEN P.ALLOWSUBCLASS = 1 THEN 1 ELSE 0 END 
			FROM	PROPERTYTYPE P 
			join CASES C ON (C.PROPERTYTYPE = P.PROPERTYTYPE)
			WHERE C.CASEID = @pnCaseKey;
			SELECT @nAllowSubClassItem = CASE WHEN P.ALLOWSUBCLASS = 1 THEN 1
									  WHEN P.ALLOWSUBCLASS = 2 THEN 2 ELSE 0 END 
			FROM	PROPERTYTYPE P 
			join CASES C ON (C.PROPERTYTYPE = P.PROPERTYTYPE)
			WHERE C.CASEID = @pnCaseKey;"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'	@bAllowSubClass	bit output,
			@nAllowSubClassItem int output,
			@pnCaseKey	int',
			@bAllowSubClass	= @bAllowSubClass output,
			@nAllowSubClassItem = @nAllowSubClassItem output,
			@pnCaseKey	= @pnCaseKey	

	If (@nErrorCode = 0 and  @sClasses is not null and @sClasses != '')
	Begin
		-- RFC11394: Removed grouping by LANGUAGE top return list of distinct classes
		Set @sSQLString =
		"insert into #TEMPCLASSESTEXT (CLASS, TEXTNO)
		SELECT DISTINCT CT.CLASS AS CLASS,
                CASE
		  WHEN @nLanguage IS NOT NULL				-- RFC28425
		       AND CT.LANGUAGE = @nLanguage THEN CT.TEXTNO	-- RFC28425
                  WHEN SC.COLINTEGER IS NOT NULL
                       AND SC.COLINTEGER = CT.LANGUAGE THEN CT.TEXTNO
                  WHEN SC.COLINTEGER IS NULL
                       AND CT.LANGUAGE IS NULL
                       AND ( CT.SHORTTEXT IS NOT NULL
                              OR Datalength(CT.TEXT) > 0 ) THEN CT.TEXTNO
                  ELSE NULL
                END      AS TEXTNO
		FROM   CASETEXT CT
		       LEFT JOIN SITECONTROL SC
			 ON ( SC.CONTROLID = 'LANGUAGE' )
		WHERE  CT.CASEID = @pnCaseKey
		       AND CT.TEXTTYPE = 'G'
		       AND ( ( ISNULL(@nLanguage,SC.COLINTEGER) IS NULL		-- RFC28425
			       AND ( ( CT.LANGUAGE IS NOT NULL
				       AND NOT EXISTS (SELECT 1
						       FROM   CASETEXT
						       WHERE  CASEID = @pnCaseKey
							      AND TEXTTYPE = 'G'
							      AND CLASS = CT.CLASS
							      AND LANGUAGE IS NULL) )
				      OR ( CT.LANGUAGE IS NULL
					   AND CT.TEXTNO = (SELECT Max(TEXTNO)
							    FROM   CASETEXT
							    WHERE  CASEID = @pnCaseKey
								   AND CLASS = CT.CLASS
								   AND TEXTTYPE = 'G'
								   AND LANGUAGE IS NULL) ) ) )
			      OR ( ISNULL(@nLanguage,SC.COLINTEGER) IS NOT NULL			-- RFC28425
				   AND ( ( CT.LANGUAGE = ISNULL(@nLanguage,SC.COLINTEGER)	-- RFC28425
					   AND CT.TEXTNO = (SELECT Max(TEXTNO)
							    FROM   CASETEXT
							    WHERE  CASEID = @pnCaseKey
								   AND CLASS = CT.CLASS
								   AND TEXTTYPE = 'G'
								   AND LANGUAGE = CT.LANGUAGE) )
					  OR ( CT.LANGUAGE <> ISNULL(@nLanguage,SC.COLINTEGER)	-- RFC28425
					       AND NOT EXISTS (SELECT 1
							       FROM   CASETEXT
							       WHERE  CASEID = @pnCaseKey
								      AND TEXTTYPE = 'G'
								      AND CLASS = CT.CLASS
								      AND (LANGUAGE = ISNULL(@nLanguage,SC.COLINTEGER) OR LANGUAGE is null)) ) -- RFC28425
					  OR ( CT.LANGUAGE IS NULL
					       AND CT.TEXTNO = (SELECT Max(TEXTNO)
							    FROM   CASETEXT
							    WHERE  CASEID = @pnCaseKey
								   AND CLASS = CT.CLASS
								   AND TEXTTYPE = 'G'
								   AND LANGUAGE IS NULL)
					       AND NOT EXISTS (SELECT 1
							       FROM   CASETEXT
							       WHERE  CASEID = @pnCaseKey
								      AND TEXTTYPE = 'G'
								      AND CLASS = CT.CLASS
								      AND LANGUAGE = ISNULL(@nLanguage,SC.COLINTEGER)) ) ) ) ) -- RFC28425"
	        
	        exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey	int,
			  @nLanguage	int',		-- RFC28425
			  @pnCaseKey	= @pnCaseKey,
			  @nLanguage	= @nLanguage	-- RFC28425

	If (@nErrorCode = 0
			and exists (	SELECT 1
					FROM	TMCLASS CL 
					join CASES C ON (C.COUNTRYCODE = CL.COUNTRYCODE
							AND C.PROPERTYTYPE = CL.PROPERTYTYPE)
					WHERE C.CASEID = @pnCaseKey) 
			and @sClasses is not null 
			and @sClasses != '')
		Begin
			Set @sSQLString = "
			SELECT DISTINCT C.CASEID	AS CaseKey,
			       CL.CLASS			AS Class,
			       CL.INTERNATIONALCLASS	AS InternationalClass,
			       CL.ASSOCIATEDCLASSES	AS AssociatedClasses,
			       CASE WHEN @bAllowSubClass = 0 THEN NULL ELSE CL.SUBCLASS END		AS SubClass,
			       CL.SEQUENCENO		AS SequenceNo,			       
			       CF.FIRSTUSE              AS FirstUseDate,
			       CF.FIRSTUSEINCOMMERCE    AS FirstUseInCommerceDate,
				   CASE WHEN CTE.TEXTNO is null THEN null 
						Else Isnull(convert(nvarchar(max),"+ dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','CT',@sLookupCulture,@pbCalledFromCentura)+"), convert(nvarchar(max),"
						     + dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,@pbCalledFromCentura)+")) END
			              AS [Text]," + 
			       dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'CL',@sLookupCulture,@pbCalledFromCentura) +" AS ClassHeading,
			       C.COUNTRYCODE + '^' + CL.CLASS + '^' + CL.PROPERTYTYPE + '^' + Cast(CL.SEQUENCENO AS NVARCHAR(15)) AS RowKey,			       
				   CASE
					WHEN @nAllowSubClassItem = 2 THEN  dbo.fn_ClassItemConcatedText(C.CASEID, CT.LANGUAGE, CL.CLASS)
					ELSE NULL 
					END as ConcatedItemText,
					CASE WHEN CTE.TEXTNO IS NULL THEN NULL 
						ELSE CT.LANGUAGE END as DefaultLanguageKey
			FROM   TMCLASS CL
			       JOIN CASES C
				 ON ( C.COUNTRYCODE = CL.COUNTRYCODE
				      AND C.PROPERTYTYPE = CL.PROPERTYTYPE )
			       LEFT JOIN CLASSFIRSTUSE CF
				 ON ( CF.CLASS = CL.CLASS
				      AND CF.CASEID = C.CASEID )
			       JOIN dbo.fn_Tokenise(@sClasses, ',') CC
				 ON (( CL.CLASS = CC.Parameter and (@bAllowSubClass = 0 or ISNULL(CL.SUBCLASS,'') = ''))
				       OR CL.CLASS + '.' + CL.SUBCLASS = CC.Parameter )
			       JOIN #TEMPCLASSESTEXT CTE
				 ON ( CTE.CLASS = CL.CLASS OR CTE.CLASS = CL.CLASS + '.' + CL.SUBCLASS)
			       LEFT JOIN CASETEXT CT
				 ON ( CT.CLASS = CC.Parameter
				      AND C.CASEID = CT.CASEID )
			WHERE  C.CASEID = @pnCaseKey 
				   AND ((@bAllowSubClass = 0 and CL.SEQUENCENO = (SELECT min (CL1.SEQUENCENO) from TMCLASS CL1 
													where CL1.CLASS = CL.CLASS AND CL1.PROPERTYTYPE = CL.PROPERTYTYPE 
													AND CL1.COUNTRYCODE = CL.COUNTRYCODE))  
						or (@bAllowSubClass = 1))
			       AND CT.TEXTTYPE = 'G'
				AND (CT.TEXTNO = CTE.TEXTNO 
					or (CTE.TEXTNO IS NULL 
					and CT.LANGUAGE IS NULL 
					and CT.TEXTNO = (select MAX(TEXTNO) from CASETEXT 
							where CLASS = CT.CLASS 
							and CASEID = CT.CASEID 
							and LANGUAGE IS NULL))
					or (CTE.TEXTNO IS NULL 
					and CT.LANGUAGE IS NOT NULL 
					and CT.TEXTNO = (select MAX(TEXTNO) from CASETEXT 
						where CLASS = CT.CLASS 
						and CASEID = CT.CASEID 
						and LANGUAGE = CT.LANGUAGE))
				)			       
			ORDER BY RowKey 
			"
		End
		ELSE IF (@nErrorCode = 0 
				and @sClasses is not null 
				and @sClasses != '')
		Begin
			Set @sSQLString = "
		       SELECT DISTINCT C.CASEID	AS CaseKey,
		       CL.CLASS         AS Class,
		       CL.INTERNATIONALCLASS	AS InternationalClass,
		       CL.ASSOCIATEDCLASSES     AS AssociatedClasses,
		       CASE WHEN @bAllowSubClass = 0 THEN NULL ELSE CL.SUBCLASS END		AS SubClass,
		       CL.SEQUENCENO	AS SequenceNo,		       
		       CF.FIRSTUSE      AS FirstUseDate,
		       CF.FIRSTUSEINCOMMERCE	AS FirstUseInCommerceDate,
			   CASE WHEN CTE.TEXTNO is null THEN null
					ELSE Isnull(convert(nvarchar(max),"+ dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','CT',@sLookupCulture,@pbCalledFromCentura)+"), convert(nvarchar(max),"+ 
						dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,@pbCalledFromCentura)+")) END
		                 AS [Text]," + 
			   dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'CL',@sLookupCulture,@pbCalledFromCentura) +" AS ClassHeading,
		       'ZZZ' + '^' + CL.CLASS + '^' + CL.PROPERTYTYPE + '^' + Cast(CL.SEQUENCENO AS NVARCHAR(15)) AS RowKey,
			   CASE
				WHEN @nAllowSubClassItem = 2 THEN  dbo.fn_ClassItemConcatedText(C.CASEID, CT.LANGUAGE, CL.CLASS)
				ELSE NULL 
				END as ConcatedItemText,
				CASE WHEN CTE.TEXTNO IS NULL THEN NULL 
					ELSE CT.LANGUAGE END as DefaultLanguageKey
		FROM   TMCLASS CL
		       JOIN CASES C
			 ON ( C.PROPERTYTYPE = CL.PROPERTYTYPE )
		       LEFT JOIN CLASSFIRSTUSE CF
			 ON ( CF.CLASS = CL.CLASS
			      AND CF.CASEID = C.CASEID )
		       JOIN dbo.fn_Tokenise(@sClasses, ',') CC
			 ON ( (CL.CLASS = CC.Parameter and (@bAllowSubClass = 0 or ISNULL(CL.SUBCLASS,'') = ''))
			       OR CL.CLASS + '.' + CL.SUBCLASS = CC.Parameter )
		       JOIN #TEMPCLASSESTEXT CTE
			 ON ( CTE.CLASS = CL.CLASS OR CTE.CLASS = CL.CLASS + '.' + CL.SUBCLASS)
		       LEFT JOIN CASETEXT CT
			 ON ( CT.CLASS = CC.Parameter
			      AND C.CASEID = CT.CASEID)
		WHERE  C.CASEID = @pnCaseKey
		       AND CL.COUNTRYCODE = 'ZZZ' AND
			   ((@bAllowSubClass = 0 and CL.SEQUENCENO = (SELECT min (CL1.SEQUENCENO) from TMCLASS CL1 
													where CL1.CLASS = CL.CLASS AND CL1.PROPERTYTYPE = CL.PROPERTYTYPE 
													AND CL1.COUNTRYCODE = 'ZZZ'))  
				or (@bAllowSubClass = 1))
		       AND CT.TEXTTYPE = 'G'
		       AND (CT.TEXTNO = CTE.TEXTNO 
			or (CTE.TEXTNO IS NULL 
				and CT.LANGUAGE IS NULL 
				and CT.TEXTNO = (select MAX(TEXTNO) from CASETEXT 
						where CLASS = CT.CLASS 
						and CASEID = CT.CASEID 
						and LANGUAGE IS NULL)
				)
			or (CTE.TEXTNO IS NULL 
				and CT.LANGUAGE IS NOT NULL 
				and CT.TEXTNO = (select MAX(TEXTNO) from CASETEXT 
						where CLASS = CT.CLASS 
						and CASEID = CT.CASEID 
						and LANGUAGE = CT.LANGUAGE)
				)
			)			       
		ORDER  BY RowKey"
		End
	End

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey	int,
			  @sClasses	nvarchar(254),
			  @bAllowSubClass	bit,
			  @nAllowSubClassItem int',		
			  @pnCaseKey	= @pnCaseKey,
			  @sClasses	= @sClasses,
			  @bAllowSubClass	= @bAllowSubClass,
			  @nAllowSubClassItem = @nAllowSubClassItem	

End -- END Classes Result Set


-- CaseText result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASETEXT,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	  cast(CT.CASEID as nvarchar(11)) + '^'
		+ cast(CT.TEXTTYPE as nvarchar(10)) + '^'
		+ cast(CT.TEXTNO as nvarchar(11))
					as RowKey,
		CT.CASEID		as CaseKey,
		TT.TEXTDESCRIPTION	as TextTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+"
				 	as [Language],	
		ISNULL("+ dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','CT',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,@pbCalledFromCentura)+")
					as Text
	from CASETEXT CT
	join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture,1,@pbCalledFromCentura) TT 
					on (TT.TEXTTYPE  = CT.TEXTTYPE)
	left join TABLECODES TC	   	on (TC.TABLECODE = CT.LANGUAGE)	
	where CT.CASEID = @nFilterCaseKey
	-- Exclude anything with a class, as it is reported in the CLASSES result set
	and   CT.CLASS is null
	-- Select version with the highest modified date and text no
	-- for all the languages that are available
	and  (  convert(nvarchar(24),CT.MODIFIEDDATE, 21)+cast(CT.TEXTNO as nvarchar(6)) ) 
		=
	     ( select max(convert(nvarchar(24), CT2.MODIFIEDDATE, 21)+cast(CT2.TEXTNO as nvarchar(6)) )
	       from CASETEXT CT2
	       where CT2.CASEID   = CT.CASEID
	       and   CT2.TEXTTYPE = CT.TEXTTYPE
	       and   CT2.CLASS is null
	       and   (	(CT2.LANGUAGE = CT.LANGUAGE)
		     or	(CT2.LANGUAGE     is null 
			 and CT.LANGUAGE  is null)
		     )
	     )
	order by TextTypeDescription, Language"
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nFilterCaseKey   	int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @nFilterCaseKey	= @nFilterCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura
End

--Images result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('IMAGES,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	  cast(CI.CASEID as nvarchar(11)) + '^'
		+ cast(CI.IMAGEID as nvarchar(11))
				as RowKey,
		CI.CASEID	as CaseKey,
		CI.IMAGEID	as ImageKey,   
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'D',@sLookupCulture,@pbCalledFromCentura)+"
				as ImageTypeDescription,
		CI.CASEIMAGEDESC as ImageDescription,
		DE.OFFICIALELEMENTID as OfficialElementID,
		"+dbo.fn_SqlTranslatedColumn('DESIGNELEMENT','ELEMENTDESC',null,'DE',@sLookupCulture,@pbCalledFromCentura)+"
				as ElementDescription		
	from CASEIMAGE CI
	join TABLECODES D 	on (D.TABLECODE = CI.IMAGETYPE)
	left join DESIGNELEMENT DE on (DE.FIRMELEMENTID = CI.FIRMELEMENTID
				and DE.CASEID = CI.CASEID)
	where CI.CASEID = @nFilterCaseKey
	-- Exclude CPA Inprostart attachments stored as images
	and   CI.IMAGETYPE != 1206
	order by ImageTypeDescription, CI.IMAGESEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nFilterCaseKey   	int',
					  @nFilterCaseKey	= @nFilterCaseKey	
End

-- DesignatedCountries result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('DESIGNATEDCOUNTRY,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select 	  cast(R.CASEID as nvarchar(11)) + '^'
		+ cast(R.RELATIONSHIPNO as nvarchar(11))
					as RowKey,
		R.CASEID		as CaseKey,
		"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+"
					as CountryName,
		CF.FLAGNAME 		as Status,
		RC.CASEID		as RelatedCaseKey,
		RC.CURRENTOFFICIALNO 	as CurrentOfficialNumber,
		CRC.CLIENTREFERENCENO 	as YourReference,
		RC.IRN			as OurReference,
		TC.[DESCRIPTION]	as StatusSummary,		
		R.PRIORITYDATE as DesignatedDate, 
		(CASE WHEN G.ASSOCIATEMEMBER=1 THEN null ELSE G.FULLMEMBERDATE END) as MembershipDate,									
   REPLACE(
        CASE WHEN RC.CASEID is not null
    THEN RC.LOCALCLASSES
        WHEN R.CLASS is not null
    THEN R.CLASS
        WHEN R.RELATIONSHIPNO = (SELECT MIN(RC1.RELATIONSHIPNO)
        FROM RELATEDCASE RC1
        WHERE RC1.CASEID = R.CASEID
        AND RC1.RELATIONSHIP = R.RELATIONSHIP
        AND RC1.COUNTRYCODE = R.COUNTRYCODE)
    THEN C.LOCALCLASSES 
        ELSE null
   End,',',', ') as Class,
    (CASE WHEN R.CLASS is null and RC.CASEID is null
	THEN 1 ELSE 0 end) as IsDefaultedFromParentCase,
   G.ASSOCIATEMEMBER as IsExtensionState
	from CASES C                                                           
	join RELATEDCASE R		on (R.CASEID = C.CASEID
					and R.RELATIONSHIP = 'DC1')
	join COUNTRY CT			on (CT.COUNTRYCODE = R.COUNTRYCODE)
	join COUNTRYGROUP G             ON (G.MEMBERCOUNTRY = R.COUNTRYCODE)
	left join COUNTRYFLAGS CF	on (CF.COUNTRYCODE = C.COUNTRYCODE
					and CF.FLAGNUMBER = R.CURRENTSTATUS)
	left join CASES RC		on (RC.CASEID = R.RELATEDCASEID)
	left join dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) CRC
					on (CRC.CASEID = RC.CASEID)  
	left join PROPERTY P		on (P.CASEID=RC.CASEID)
	left join STATUS RS		on (RS.STATUSCODE=P.RENEWALSTATUS)
	left join STATUS ST		on (ST.STATUSCODE=RC.STATUSCODE)
	left join TABLECODES TC		on (TC.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) THEN 7603
								WHEN(ST.REGISTEREDFLAG=1)   THEN 7602
								WHEN(RC.CASEID is not null) THEN 7601
								ELSE NULL
							END)
	where G.TREATYCODE = CF.COUNTRYCODE and C.CASEID=@nFilterCaseKey order by CT.COUNTRY, R.PRIORITYDATE, Class"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @nFilterCaseKey	int',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nFilterCaseKey	= @nFilterCaseKey	

End

-- Financials result set
-- Part 1 - Calculated the total billed for the case (@nBilledToDate).
-- Part 2 - Break down the bill for service charges and store the result in 
--          the @nServicesBilled variable.
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('FINANCIALS,', @psResultsetsRequired) <> 0)
Begin 
	
	If @bIsBillingRequired = 1
	Begin
		Set @sSQLString = "
		Select @nBilledToDate   = sum(-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))),
			   @nServicesBilled = sum(CASE WHEN WT.CATEGORYCODE = 'SC' 
				    		   THEN (-WH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) 
						   ELSE 0 
						  END)
		from OPENITEM OI
		join WORKHISTORY WH 		on (WH.REFENTITYNO = OI.ITEMENTITYNO   
						and WH.REFTRANSNO  = OI.ITEMTRANSNO   
						and WH.MOVEMENTCLASS = 2)		
		left join WIPTEMPLATE WTP 	on (WTP.WIPCODE = WH.WIPCODE)
		left join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)
		where OI.STATUS = 1 
		and   WH.CASEID = @nFilterCaseKey"

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nBilledToDate 	decimal(11, 2)     OUTPUT,
						  @nServicesBilled 	decimal(11, 2) 	   OUTPUT,
						  @nFilterCaseKey 	int',
						  @nBilledToDate 	= @nBilledToDate   OUTPUT,
						  @nServicesBilled 	= @nServicesBilled OUTPUT,
						  @nFilterCaseKey 	= @pnCaseKey
		-- Financials result set
		-- Part 2 - relate to case budget if any
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			select	cast(C.CASEID as nvarchar(11)) as RowKey,
				C.CASEID		as CaseKey,
				C.BUDGETAMOUNT 		as Estimated,
				@nBilledToDate 		as Billed,
				CASE WHEN C.BUDGETAMOUNT IS NULL
					 THEN NULL
					 ELSE convert(int, round(@nBilledToDate/CASE WHEN C.BUDGETAMOUNT = 0 
							    			 THEN 1 
							    			 ELSE C.BUDGETAMOUNT 
						       				END * 100,0))
				END 			as BilledPercentage,
				@nServicesBilled	as ServicesBilled,
				convert(int, round(@nServicesBilled/CASE WHEN @nBilledToDate = 0 
						    				 THEN 1 
						    				 ELSE @nBilledToDate 
					       				END * 100,0))
			      				as ServicesPercentage,
				@sLocalCurrencyCode	as CurrencyCode,
				@nLocalDecimalPlaces	as LocalDecimalPlaces
			from CASES C
			where C.CASEID = @nFilterCaseKey
			and ( (C.BUDGETAMOUNT IS NOT NULL)
			 or   (@nBilledToDate IS NOT NULL)
			 or   (@nServicesBilled IS NOT NULL)
				)
			and @bIsBillingRequired = 1"
		
			Exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnUserIdentityId		int,
							  @nFilterCaseKey		int,
							  @nBilledToDate 		decimal(11,2),
							  @nServicesBilled 		decimal(11, 2),
							  @bIsBillingRequired		bit,
							  @sLocalCurrencyCode		nvarchar(3),
							  @nLocalDecimalPlaces		tinyint',
							  @pnUserIdentityId		= @pnUserIdentityId,
							  @nFilterCaseKey      		= @nFilterCaseKey,
							  @nBilledToDate 		= @nBilledToDate,
							  @nServicesBilled 		= @nServicesBilled,
							  @bIsBillingRequired		= @bIsBillingRequired,
							  @sLocalCurrencyCode		= @sLocalCurrencyCode,
							  @nLocalDecimalPlaces		= @nLocalDecimalPlaces
							
		End
	End
	Else
	Begin 
		-- @bIsBillingRequired = 0
		-- empty result set must be returned for the calling code
		Set @sSQLString = "
		select	null 	as RowKey,
				null 	as CaseKey,
				null 	as Estimated,
				null 	as Billed,
				null	as BilledPercentage,
				null	as ServicesBilled,
				null	as ServicesPercentage,
				null	as CurrencyCode,
				null	as LocalDecimalPlaces
		from CASES C
		where C.CASEID = @nFilterCaseKey
		and @bIsBillingRequired = 1"
	
		Exec @nErrorCode = sp_executesql @sSQLString,
						N'@nFilterCaseKey		int,
						  @bIsBillingRequired		bit',
						  @nFilterCaseKey      		= @nFilterCaseKey,
						  @bIsBillingRequired		= @bIsBillingRequired
	End
End

-- BillingNames result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('BILLINGNAMES,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = " 
	Select	  cast(CN.CASEID as nvarchar(11)) + '^'
		+ cast(CN.NAMETYPE as nvarchar(10)) + '^'
		+ cast(CN.NAMENO as nvarchar(11)) + '^'
		+ cast(CN.[SEQUENCE] as nvarchar(10))
						as RowKey,
		CN.CASEID			as CaseKey,
		CN.NAMETYPE			as NameTypeKey,
		CN.NAMENO			as NameKey,
		CN.SEQUENCE			as NameSequence,
		-- Specific logic is required to retrieve the Debtor/Renewal Debtor 
		-- Attention (name types 'D' and 'Z')
		CASE WHEN CN.NAMETYPE in ('D', 'Z')
		     THEN N2.NAMENO
		     ELSE N1.NAMENO		
		END				as AttentionKey,
		CASE WHEN CN.NAMETYPE in ('D', 'Z')
		     THEN dbo.fn_FormatNameUsingNameNo(N2.NAMENO, coalesce(N2.NAMESTYLE,NAT2.NAMESTYLE,7101))
		     ELSE dbo.fn_FormatNameUsingNameNo(N1.NAMENO, coalesce(N1.NAMESTYLE,NAT1.NAMESTYLE,7101))
		END				as Attention,
		NT.DESCRIPTION 			as NameTypeDescription,  	
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, coalesce(N.NAMESTYLE,NAT.NAMESTYLE,7101))
						as Name,  	
		-- Specific logic is required to retrieve the Debtor/Renewal Debtor 
		-- Address (name types 'D' and 'Z')
		CASE WHEN CN.NAMETYPE in ('D', 'Z')
		     THEN dbo.fn_FormatAddress(BA.STREET1, BA.STREET2, BA.CITY, BA.STATE, BS.STATENAME, BA.POSTCODE, BC.POSTALNAME, BC.POSTCODEFIRST, BC.STATEABBREVIATED, BC.POSTCODELITERAL, BC.ADDRESSSTYLE)					
		     ELSE dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
		END				as Address,
		CN.REFERENCENO			as ReferenceNo,
		CN.BILLPERCENTAGE		as BillPercent
		from CASENAME CN
		join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture, 1,@pbCalledFromCentura) NT
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
		-- For name types that are not Debtor (Name type = 'D') or Renewal Debtor ('Z')
		-- Attention and Address are obtained as the following:
		-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed; 
		-- 2)	Extract the Attention and Address details stored against the Name as the PostalAddress 
		--	and MainContact.
		-- Address
		left join ADDRESS A		on (A.ADDRESSCODE=isnull(CN.ADDRESSCODE, N.POSTALADDRESS))
		left join COUNTRY CT		on (CT.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S		on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE=A.STATE)
		-- Attention
		left join NAME N1		on (N1.NAMENO=isnull(CN.CORRESPONDNAME, N.MAINCONTACT))
		left join COUNTRY NAT1		on (NAT1.COUNTRYCODE=N1.NATIONALITY)
		where CN.CASEID = @nFilterCaseKey
		and   CN.EXPIRYDATE is null    
		and   CN.NAMETYPE in ('D','CD','Z','ZC')
		-- An empty result set is required if the user does not have access to the Billing Instructions topic
		and @bIsBillingInstructionsAvailable = 1
		order by NT.DESCRIPTION, CN.SEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nFilterCaseKey   	int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @bIsBillingInstructionsAvailable bit',
					  @nFilterCaseKey	= @nFilterCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @bIsBillingInstructionsAvailable = @bIsBillingInstructionsAvailable
End

-- OccurredEvents result set
-- where :
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('OCCURREDEVENTS,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	Select	@bShowAllEventDates=isnull(S.COLBOOLEAN,0)
	from SITECONTROL S
	where S.CONTROLID='Always Show Event Date'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bShowAllEventDates		bit		OUTPUT',
				 @bShowAllEventDates=@bShowAllEventDates	OUTPUT
				 
	If @nErrorCode=0
	Begin			  
		Set @sSQLString="
		Select	CE.CASEID 	as CaseKey,
			dbo.fn_GetTranslation  (CE.EVENTDESCRIPTION, null, CE.EVENTDESCRIPTION_TID, @sLookupCulture) as EventDescription,
			dbo.fn_GetTranslation  (CE.DEFINITION, null, CE.DEFINITION_TID, @sLookupCulture) as EventDefinition,
			CE.EVENTDATE 	as [Date],
			CASE WHEN SC.COLBOOLEAN = 1 THEN CE.EVENTTEXT END		
					as EventText,
			CE.FROMCASEID	as FromCaseKey,
			C.IRN		as FromCaseReference,
			O.OPENITEMNO	as DocumentNumber,
			O.LOCALVALUE	as LocalAmount,
			@sLocalCurrencyCode	as LocalCurrencyCode,
			O.FOREIGNVALUE	as ForeignAmount,
			O.CURRENCY		as ForeignCurrencyCode,
			CE.EMPLOYEENO	as ResponsibleNameKey,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
						as ResponsibleName,
			NT.DESCRIPTION	as ResponsibleNameType,
			cast(CE.CASEID 	as varchar(11)) + '^' +
			cast(CE.EVENTNO as varchar(11)) + '^' +
			cast(CE.CYCLE 	as varchar(10))
						as RowKey
		from dbo.fn_GetCaseOccurredDates(@bShowAllEventDates) CE
		join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture, 1,@pbCalledFromCentura) E			
						on (E.EVENTNO=CE.EVENTNO)
		left join ACTIVITYHISTORY AH	on (AH.CASEID=CE.CASEID
						and AH.EVENTNO=CE.EVENTNO
						and AH.CYCLE=CE.CYCLE
						and AH.DEBITNOTENO IS NOT NULL
						and AH.ACTIVITYCODE = 3204)
		left join OPENITEM O		on (O.OPENITEMNO = AH.DEBITNOTENO)
		left join CASES C		on (C.CASEID = CE.FROMCASEID)
		left join SITECONTROL SC	on (SC.CONTROLID = 'Client Event Text')
		left join NAME N		on (N.NAMENO = CE.EMPLOYEENO)
		left join NAMETYPE NT		on (NT.NAMETYPE = CE.DUEDATERESPNAMETYPE)
		where CE.CASEID = @nFilterCaseKey
		order by CE.EVENTDATE desc, 2"

		exec sp_executesql @sSQLString,
						N'@nFilterCaseKey   	int,
						  @pnUserIdentityId 	int,
						  @sLookupCulture	nvarchar(10),
						  @pbCalledFromCentura	bit,
						  @sLocalCurrencyCode	nvarchar(3),
						  @bShowAllEventDates	bit',
						  @nFilterCaseKey	= @nFilterCaseKey, 
						  @pnUserIdentityId 	= @pnUserIdentityId,
						  @sLookupCulture	= @sLookupCulture,
						  @pbCalledFromCentura	= @pbCalledFromCentura,
						  @sLocalCurrencyCode	= @sLocalCurrencyCode,
						  @bShowAllEventDates	= @bShowAllEventDates
	End

End

-- DueEvents result set
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
	
If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('DUEEVENTS,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	Select	@sRenewalAction=S.COLCHARACTER,
		@bShowEventText=S1.COLBOOLEAN,
		@nOverdueDays  =S2.COLINTEGER
	from SITECONTROL S
	join SITECONTROL S1	on (S1.CONTROLID='Client Event Text')
	left join SITECONTROL S2 on (S2.CONTROLID='Client Due Dates: Overdue Days')
	where S.CONTROLID='Main Renewal Action'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sRenewalAction	nvarchar(2)	OUTPUT,
				  @bShowEventText	bit		OUTPUT,
				  @nOverdueDays		int		OUTPUT',
				  @sRenewalAction=@sRenewalAction	OUTPUT,
				  @bShowEventText=@bShowEventText	OUTPUT,
				  @nOverdueDays  =@nOverdueDays		OUTPUT

	---------------------------------------------------					  
	-- If the user is external then determine the date
	-- from which due dates are allowed to be displayed
	-- by subtracting the OverdueDays from todays date.
	---------------------------------------------------
	If  @nErrorCode = 0
	and @nOverdueDays is not null
	begin
		Set @dtOverdueRangeFrom = convert(nvarchar(11),dateadd(Day, @nOverdueDays*-1, getdate()),112)
	end


	If @nErrorCode=0
	Begin
		Set @sSQLString="
		Select	CE.CASEID as CaseKey,
		dbo.fn_GetTranslation  (CE.EVENTDESCRIPTION, null, CE.EVENTDESCRIPTION_TID, @sLookupCulture) as EventDescription,
		dbo.fn_GetTranslation  (CE.DEFINITION, null, CE.DEFINITION_TID, @sLookupCulture) as EventDefinition,
		CE.EVENTDUEDATE as [Date],
		CASE WHEN @bShowEventText = 1 THEN CE.EVENTTEXT END
				as EventText,
		CE.FROMCASEID	as FromCaseKey,
		C.IRN		as FromCaseReference,
		O.OPENITEMNO	as DocumentNumber,
		O.LOCALVALUE	as LocalAmount,
		@sLocalCurrencyCode	as LocalCurrencyCode,
		O.FOREIGNVALUE	as ForeignAmount,
		O.CURRENCY		as ForeignCurrencyCode,
		CE.EMPLOYEENO	as ResponsibleNameKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as ResponsibleName,
		NT.DESCRIPTION	as ResponsibleNameType,
		cast(CE.CASEID 	as varchar(11)) + '^' +
		cast(CE.EVENTNO as varchar(11)) + '^' +
		cast(CE.CYCLE 	as varchar(10))
					as RowKey,
		cast(case when (CE.EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast'
		from dbo.fn_GetCaseDueDates() CE
		join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture, 1,@pbCalledFromCentura) E			
						on (E.EVENTNO=CE.EVENTNO)
		left join ACTIVITYHISTORY AH	on (AH.CASEID=CE.CASEID
						and AH.EVENTNO=CE.EVENTNO
						and AH.CYCLE=CE.CYCLE
						and AH.DEBITNOTENO IS NOT NULL
						and AH.ACTIVITYCODE = 3204)
		left join OPENITEM O	on (O.OPENITEMNO = AH.DEBITNOTENO)
		left join CASES C		on (C.CASEID = CE.FROMCASEID)
		left join NAME N		on (N.NAMENO = CE.EMPLOYEENO)
		left join NAMETYPE NT		on (NT.NAMETYPE = CE.DUEDATERESPNAMETYPE)
		where	CE.CASEID = @nFilterCaseKey
		and (CE.EVENTDUEDATE>=@dtOverdueRangeFrom OR @dtOverdueRangeFrom is null)
		order by CE.EVENTDUEDATE, 2"

		exec sp_executesql @sSQLString,
					N'@nFilterCaseKey   	int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @bShowEventText	bit,
					  @sRenewalAction	nvarchar(2),
					  @dtOverdueRangeFrom	datetime',
					  @nFilterCaseKey	= @nFilterCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @bShowEventText	= @bShowEventText,
					  @sRenewalAction	= @sRenewalAction,
					  @dtOverdueRangeFrom	= @dtOverdueRangeFrom
	End
End

-- RenewalInstructions, RenewalNames, RenewalDetails result sets
If @nErrorCode=0
and (   @psResultsetsRequired = ','
     or CHARINDEX('RENEWALINSTRUCTIONS,', @psResultsetsRequired) <> 0
     or CHARINDEX('RENEWALNAMES,', @psResultsetsRequired) <> 0
     or CHARINDEX('RENEWALDETAILS,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_GetCaseRenewalDetails
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pbExternalUser		= 1,
		@pnCaseKey		= @pnCaseKey,
		@psResultsetsRequired	= @psResultsetsRequired
End

-- RelatedCases result set
If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('RELATEDCASES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListRelatedCase
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pbIsExternalUser	= 1,
		@pnCaseKey		= @pnCaseKey
End

-- Populate the new WebLinks datatable
If @nErrorCode=0
and (   @psResultsetsRequired = ','
     or CHARINDEX('WEBLINKGROUP,', @psResultsetsRequired) <> 0
     or CHARINDEX('WEBLINK,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListWebLink
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @sLookupCulture,
				@pnCaseKey		= @nFilterCaseKey,
			  	@pbIsExternalUser	= 1,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psResultsetsRequired	= @psResultsetsRequired
End

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin
	exec @nErrorCode = dbo.ac_GetAgeingBrackets @pdtBaseDate  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
End

-- WIPByCurrency result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('WIPBYCURRENCY,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = 
	"Select"+CHAR(10)+ 
	"  cast(WIP.CASEID as nvarchar(11)) + '^'"+CHAR(10)+
	"+ cast(WIP.ENTITYNO as nvarchar(11)) + '^'"+CHAR(10)+
	"+ cast(WIP.CurrencyCode as nvarchar(10)) as RowKey,"+CHAR(10)+
	"WIP.CASEID 	as 'CaseKey',"+CHAR(10)+  		
	"WIP.ENTITYNO 	as 'EntityKey',"+CHAR(10)+ 		
	"WIP.EntityName as 'EntityName',"+CHAR(10)+ 
	"WIP.CurrencyCode as 'CurrencyCode',"+CHAR(10)+
	-- Avoid  'Warning: null value is eliminated by an aggregate or other SET operation.'
	-- by using 'ISNULL' before the 'SUM'. 
	"SUM(ISNULL(WIP.Bracket0Total,0))"+CHAR(10)+   	
	"		as 'Bracket0Total',"+CHAR(10)+ 
	"SUM(ISNULL(WIP.Bracket1Total,0))"+CHAR(10)+   	
	"		as 'Bracket1Total',"+CHAR(10)+ 
	"SUM(ISNULL(WIP.Bracket2Total,0))"+CHAR(10)+ 
	"		as 'Bracket2Total',"+CHAR(10)+ 
	"SUM(ISNULL(WIP.Bracket3Total,0))"+CHAR(10)+ 
	"		as 'Bracket3Total',"+CHAR(10)+ 
	"SUM(ISNULL(WIP.Total,0))"+CHAR(10)+ 
	"	        as 'Total',"+CHAR(10)+ 
	-- Prepayment information should be null unless the current user has access to the Prepayments information 
	-- security topic (201).
	"CASE WHEN @bIsPrepaymentAvailable = 1 THEN SUM(ISNULL(WIP.PrepaymentsForCase,0)) ELSE NULL END"+CHAR(10)+  	
	"		as 'PrepaymentsForCase',"+CHAR(10)+ 
	"CASE WHEN @bIsPrepaymentAvailable = 1 THEN SUM(ISNULL(WIP.PrepaymentsForDebtors,0)) ELSE NULL END"+CHAR(10)+   
	"		as 'PrepaymentsForDebtors',"+CHAR(10)+ 
	"CASE WHEN @bIsPrepaymentAvailable = 1 THEN SUM(ISNULL(WIP.PrepaymentsTotal,0)) ELSE NULL END"+CHAR(10)+ 	
	"		as 'PrepaymentsTotal'"+CHAR(10)+ 	
	"from("+CHAR(10)+ 	
	"Select"+CHAR(10)+ 
	"W.CASEID 	as CASEID,"+CHAR(10)+  		
	"W.ENTITYNO 	as ENTITYNO,"+CHAR(10)+ 		
	"N.NAME	as EntityName,"+CHAR(10)+ 
	"ISNULL(W.FOREIGNCURRENCY, @sLocalCurrencyCode)"+CHAR(10)+ 	
	"		as CurrencyCode,"+CHAR(10)+ 
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) <  @nAge0) 		      THEN ISNULL(W.FOREIGNBALANCE, W.BALANCE) ELSE 0 END"+CHAR(10)+  
	"		as Bracket0Total,"+CHAR(10)+ 
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN ISNULL(W.FOREIGNBALANCE, W.BALANCE) ELSE 0 END"+CHAR(10)+  
	"		as Bracket1Total,"+CHAR(10)+ 
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN ISNULL(W.FOREIGNBALANCE, W.BALANCE) ELSE 0 END"+CHAR(10)+  
	"		as Bracket2Total,"+CHAR(10)+ 
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) >= @nAge2) 		      THEN ISNULL(W.FOREIGNBALANCE, W.BALANCE) ELSE 0 END"+CHAR(10)+  
	"		as Bracket3Total,"+CHAR(10)+ 
	"ISNULL(W.FOREIGNBALANCE, W.BALANCE)"+CHAR(10)+  
	"		as Total,"+CHAR(10)+ 
	"null		as PrepaymentsForCase,"+CHAR(10)+ 
	"null		as PrepaymentsForDebtors,"+CHAR(10)+ 
	"null		as PrepaymentsTotal"+CHAR(10)+ 	
	"from WORKINPROGRESS W"+CHAR(10)+ 
	"join NAME N 	 	on (N.NAMENO = W.ENTITYNO)"+CHAR(10)+  	 
	"where W.CASEID = @pnCaseKey"+CHAR(10)+  
	"and W.STATUS <> 0"+CHAR(10)+ 
	"and W.TRANSDATE <= getdate()"+CHAR(10)+ 	
	"UNION ALL"+CHAR(10)+ 
	"Select"+CHAR(10)+ 
	"OIC.CASEID,"+CHAR(10)+  		
	"OIC.ACCTENTITYNO,"+CHAR(10)+ 		
	"PFCN.NAME,"+CHAR(10)+ 
	"ISNULL(O.CURRENCY, @sLocalCurrencyCode),"+CHAR(10)+ 	
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"ISNULL(OIC.FOREIGNBALANCE, OIC.LOCALBALANCE),"+CHAR(10)+ 	
	"null,"+CHAR(10)+ 
	"ISNULL(OIC.FOREIGNBALANCE, OIC.LOCALBALANCE)"+CHAR(10)+	
	"from OPENITEMCASE OIC"+CHAR(10)+  
	"left join OPENITEM O 	on (O.ITEMENTITYNO = OIC.ITEMENTITYNO"+CHAR(10)+  
	"         	     	and O.ITEMTRANSNO  = OIC.ITEMTRANSNO"+CHAR(10)+  
	"	 	     	and O.ACCTENTITYNO = OIC.ACCTENTITYNO"+CHAR(10)+  
	"	 	     	and O.ACCTDEBTORNO = OIC.ACCTDEBTORNO)"+CHAR(10)+ 
	"join SITECONTROL SC 	on (SC.CONTROLID = 'CURRENCY')"+CHAR(10)+  		   
	"left join NAME PFCN 	on (PFCN.NAMENO = OIC.ACCTENTITYNO)"+CHAR(10)+ 
	"where OIC.STATUS IN (1, 2)"+CHAR(10)+  
	"and O.ITEMTYPE = 523"+CHAR(10)+
	"and OIC.CASEID = @pnCaseKey"+CHAR(10)+ 
	"UNION ALL"+CHAR(10)+ 
	"Select"+CHAR(10)+ 
	"CNN.CASEID,"+CHAR(10)+  		
	"O.ACCTENTITYNO,"+CHAR(10)+ 		
	"PFDN.NAME,"+CHAR(10)+ 
	"ISNULL(O.CURRENCY, @sLocalCurrencyCode),"+CHAR(10)+	
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"null,"+CHAR(10)+ 
	"CASE WHEN O.PAYPROPERTYTYPE = CNN.PROPERTYTYPE or O.PAYPROPERTYTYPE is null THEN ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE) ELSE NULL END,"+CHAR(10)+	
	"ISNULL(O.FOREIGNBALANCE, O.LOCALBALANCE)"+CHAR(10)+ 	
	"from OPENITEM O"+CHAR(10)+ 
	"join ((Select CN.NAMENO, CN.CASEID, C.PROPERTYTYPE"+CHAR(10)+    
	"       from CASENAME CN"+CHAR(10)+    
	"	join CASES C on (C.CASEID = CN.CASEID)"+CHAR(10)+  
	"       where CN.CASEID = @pnCaseKey"+CHAR(10)+   
	"       and CN.NAMETYPE = 'D'"+CHAR(10)+   
	"       and CN.EXPIRYDATE IS NULL)) CNN"+CHAR(10)+  
	"			on (CNN.NAMENO = O.ACCTDEBTORNO)"+CHAR(10)+ 
	"left join NAME PFDN 	on (PFDN.NAMENO = O.ACCTENTITYNO)"+CHAR(10)+ 
	"where not exists"+CHAR(10)+  
	"	(Select *"+CHAR(10)+    
	"	 from OPENITEMCASE OIC"+CHAR(10)+    
	"	 where  O.ITEMENTITYNO = OIC.ITEMENTITYNO"+CHAR(10)+  
	"	 and    O.ITEMTRANSNO = OIC.ITEMTRANSNO"+CHAR(10)+  
	"	 and    O.ACCTENTITYNO = OIC.ACCTENTITYNO"+CHAR(10)+  
	"	 and    O.ACCTDEBTORNO = OIC.ACCTDEBTORNO)"+CHAR(10)+  
	"and O.STATUS IN (1, 2)"+CHAR(10)+  		   	
	"and O.ITEMTYPE = 523"+CHAR(10)+ 
	") WIP"+CHAR(10)+ 
	-- The result sets should only be published if the Work In Progress Items information security topic (120) 
	-- is available.
	"where @bIsWIPAvailable = 1"+CHAR(10)+
	"group by WIP.CASEID, WIP.ENTITYNO, WIP.EntityName, WIP.CurrencyCode"+CHAR(10)+ 
	"order by 'EntityName', 'EntityKey', 'CurrencyCode'" 

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @bIsWIPAvailable	bit,
					  @bIsPrepaymentAvailable bit,
					  @sLocalCurrencyCode	nvarchar(3)',
					  @pnCaseKey		= @nFilterCaseKey, 
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @dtBaseDate		= @dtBaseDate,
					  @nAge0		= @nAge0,
					  @nAge1		= @nAge1,
					  @nAge2		= @nAge2,
					  @bIsWIPAvailable	= @bIsWIPAvailable,
					  @bIsPrepaymentAvailable = @bIsPrepaymentAvailable,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode 		
End 

-- OfficialNumber result set
If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('OFFICIALNUMBER,', @psResultsetsRequired) <> 0)
Begin	
	exec @nErrorCode = dbo.csw_ListOfficialNumber
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @sLookupCulture,
					@pnCaseKey		= @nFilterCaseKey,
				  	@pbIsExternalUser	= 1,
					@pbCalledFromCentura	= @pbCalledFromCentura	
End

-- StandingInstruction result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('STANDINGINSTRUCTION,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_GetStandingInstructions
		@pnCaseKey		= @nFilterCaseKey,
		@psCulture		= @sLookupCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pbIsExternalUser	= 1
End

-- FirstUse result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('FIRSTUSE,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListFirstUse 	
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @nFilterCaseKey,
					@pbIsExternalUser = 1,
					@pbCalledFromCentura=@pbCalledFromCentura	
End

-- Journal result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('JOURNAL,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListJournal 	
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @nFilterCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura	
End

-- Prior Art result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('PRIORART,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListSearchResult 	
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @nFilterCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura	
End

-- Patent Term Adjustments result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('PTAEVENT,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_GetPTA
		@pnCaseId		= @nFilterCaseKey,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbIsExternalUser	= 1,
		@psCulture		= @sLookupCulture
End

-- Patent Design Element result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('DESIGNELEMENT,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListDesignElement
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pnCaseKey		= @nFilterCaseKey,
		@pbCalledFromCentura	= @pbCalledFromCentura	
End

-- Update any Quick Indexes for the current user to reflect the fact that a database table has been accessed:
If @nErrorCode=0
and @nFilterCaseKey is not null
Begin
	exec @nErrorCode = dbo.ip_RegisterAccess
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psDatabaseTable	= 'CASES',
		@pnIntegerKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.cwb_ListCaseDetail to public
GO
