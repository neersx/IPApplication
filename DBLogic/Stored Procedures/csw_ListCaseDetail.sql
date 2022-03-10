-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseDetail.'
	Drop procedure [dbo].[csw_ListCaseDetail]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseDetail...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_ListCaseDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,		-- Mandatory
	@pbCanViewBillingInstructions	bit		= 0,
	@pbCanViewBillingHistory	bit		= 0,
	@pbCanViewWorkInProgressItems	bit		= 0,
	@pbCanViewPrepayments		bit		= 0,
	@pbCanViewContactActivities	bit		= 0,
	@pbCalledFromCentura	bit 		= 0,
	@psResultsetsRequired	nvarchar(4000)	= null,		-- comma seperated list to describe which resultset to return
	@psProgramKey		nvarchar(8)	= null,
    @pnLanguageKey		int	= '4704'
)
AS
-- PROCEDURE:	csw_ListCaseDetail
-- VERSION:	180
-- DESCRIPTION:	Returns the details for a single case that are suitable
--		to show an internal user.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	-----------------------------------------------
-- 07 Jan 2004  TM	RFC768	1	Procedure created. It is not finished yet, i.e. some security topics
--					are not implemented. Also the code needs to be double checked that it
--					conforms to the current coding standards.
-- 15 Jan 2004	TM	RFC768	2	Fine tune.
-- 20 Jan 2003	TM	RFC768	3	The email address should be for the responsible staff member only (i.e.
--					no signatory). Use display format for Attention in the CaseName result set.
--					WIP - check for ItemType= 523 in the case prepayment totalling.
--					Rename the local variable @bIsBillingRequired as @bIsBillingRequired.
--					Reminder result set - change the formatting of ToName to use the standard
--					functions.
-- 20 Jan 2003	TM	RFC768	4	According to SQA8073 the total WIP and Time value should include Draft WIP.
--					Remove the clause "and STATUS <> 0" for the Billing result set.
-- 18-Feb-2004	TM	RFC976	5	Add the @pbCalledFromCentura  = default parameter to the calling code
--					for relevant functions.
-- 04-Mar-2004	TM	RFC934	6	Remove all use of fn_FilterUserEventControl and fn_FilterUserEvents as
--					the procedure is for internal use only.Return the new ImportanceLevel column.
--					This should be obtained from EventControl for preference and Events otherwise.
-- 10-Mar-2004	TM	RFC868	7	Modify the logic extracting the 'EmailAddress' column to use new Name.MainEmail column.
-- 10-Mar-2004	TM	RFC1065	8	Display Internal Status instead of External.
-- 30-Mar-2004	TM	RFC399	9	Implement a call to ip_RegisterAccess to update the index:
--					@psDatabaseTable = 'CASES', @pnIntegerKey = @pnCaseKey
-- 26-May-2004	TM	RFC863	10	For the NameType in ('Z', 'D') extract the AttentionKey, Attention
--					and Address  in the same manner as billing (SQA7355).
-- 31-May-2004	TM	RFC863	11	Improve the commenting of SQL extracting the Billing Address/Attention.
-- 16-Jul-2004	TM	RFC1541	12	Populate the new Case.WIPTotal field.
-- 19-Jul-2004	TM	RFC1541	13	Move the Derived Table calculating the WIPTotal into the preceding SELECT
--					which has far fewer Joins.
-- 24-Aug-2004	TM	RFC1233	14	Populate the new WebLinks datatable by calling fn_GetCriteriaRows.
-- 07-Sep-2004	TM	RFC1158	15	Call ip_ListAttachment and ipw_ListTableAttributes.
-- 09 Sep 2004	JEK	RFC886	16	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 21 Sep 2004	TM	RFC886	17	Implement translation.
-- 22 Sep 2004	TM	RFC886	18	Implement translation in the WebLinks datatable.
-- 29 Sep 2004	MF	RFC1846	19	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 29-Sep-2004	TM	RFC1806	20	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.
-- 19-Oct-2004	TM	RFC1156	21	Populate new columns in the dataset.
-- 29 Oct 2004	TM	RFC1233	23	Modify result sets for WebLinks to include URL and group information.
-- 05 Nov 2004	TM	RFC1233	24	Populate the WebLinks result set using new csw_ListWebLink.
-- 19 Nov 2004	TM	RFC2001	25	Change the stored procedure back to populating the old format Billing datatable.
-- 29 Nov 2004	TM	RFC1156	26	Use more meaningful full words in the following variable names of the @sEntSzDesc
--					and @nActvHstrCount.
-- 07 Dec 2004 	TM	RFC1156	27	Re-implement new Billing datatable.
-- 08 Dec 2004	TM	RFC1156	28	Populate new columns in the dataset.
-- 15 Dec 2004	TM	RFC1991	29	Populate the new Case.BillingNotes field. Modify the population of the CaseText
--					result set to specifically exclude the special text type '_B'.
-- 15 Dec 2004	TM	RFC1991	30	Return the most recent version of the BillingNotes.
-- 23 Dec 2004 	TM	RFC2164	31	Extract NoOfClaims, StatusSummary, CaseStatusDescription and RenewalStatusDescription
--					columns into the local variables to retain the Cases result set SQL statement less
--					than 4000 characters.
-- 04 Mar 2004	TM	RFC2367	32	Add new CaseOffice column to the Case result set.
-- 26 Apr 2005	TM	RFC2126	33	Implement Case.AttachmentCount column. Remove call to ip_ListAttachment.
-- 15 May 2005	JEK	RFC2508	34	Extract @sLookupCulture and pass to translation instead of @psCulture
--					Also pass @sLookupCulture to child procedures that are known not to need the original @psCulture
-- 23 May 2005	TM	RFC2594	35	Populate the new cs_GetBudgetDetails parameter.Only perform one lookup of the
--					BillingInstructions, BillingHistory, WIP, Prepayments subjects.
-- 11 Jul 2005	TM	RFC2614	36	Debtor level prepayments should only be included if they match the property type
--					of the case or if no property type was specified for the prepayments.
-- 20 Sep 2005	TM	RFC3008	37	Implement new ComparisonSystem result set.
-- 12 Oct 2005	TM	RFC2255	38	Add new FirmElementID and ElementDescription columns to the Images result set.
-- 24 Nov 2005	LP	RFC1017	39	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from
--					ac_GetLocalCurrencyDetails and add to Case result set
-- 01 Dec 2005	TM	RFC3254	40 	Replace the call to cs_ListCaseTree with a call to csw_ListRelatedCase.
-- 16 Jan 2006	TM	RFC1659	41	In the CaseName result set, return new NameVariant column.
-- 23 Jan 2006	TM	RFC1850	42	Add new EventStaff column to OccurredEvents and DueEvents, formatted for display.
-- 28 Feb 2006	LP	RFC3216	43	Add new NameCode column to the CaseName result set.
-- 28 Jun 2006	SW	RFC4038	44	Add RowKey
-- 06 Jul 2006	SW	RFC3614	45	Add status to DesignatedCountries result set
-- 17 Jul 2006	SW	RFC3217	46	Remove population of some CASE fields, implement CaseExtended result set and new param @psResultsetsRequired
-- 21 Jul 2006	SW	RFC3828	47	Pass getdate() to fn_Permission..
-- 27 Jul 2006	SW	RFC3217	48	Code cutting Case and CaseExtended result set
-- 18 Sep 2006	AU	RFC4144	49	Return 2 new columns "FromCaseKey" and "FromCaseReference" in the DueEvents and OccurredEvents tables
-- 18 Dec 2006	JEK	RFC2982	50	Implement new HasInstructions column in Case table.
-- 12 Jan 2007	SW	RFC4903	51	Fix Goods and Services casetext.
-- 22 Jan 2007	PG	RFC4903	52	Return CaseText without a Class in CaseText
-- 1 Mar 2007	PY	SQA14425 53	Reserved word [language,date]
-- 17 Apr 2007	SF	RFC5146	54	Format a space after each comma in the comma-delimited Local Classes and International Classes
-- 07 May 2007	LP	RFC3865	55	Add event amounts and document number to Events result sets
-- 06 Jun 2007	LP	RFC3865	56	Join to ACTIVITYHISTORY where the ACTIVITYCODE is 3204
-- 26 Jun 2007	PG	RFC3865	57	Backout changes
-- 03 Oct 2007	SF	RFC4278 58	Remove CanViewAttachments, LocalCurrentcyCode and LocalDecimalPlaces from Case result set, Add CaseBilling and CaseWIP resultsets
-- 22 Nov 2007	AT	RFC3208	59	Return classes as a seperate dataset, Moved ClassesText to CaseEntity dataset.
-- 23 Nov 2007	SF	RFC5776	60	Return CaseScreens result set
-- 10 Dec 2007	LP	RFC3210	61	Sort Designated Countries result set by Country Name
-- 10 Jan 2008	LP	RFC3210	62	Return Sequence column in Designated Countries result set
-- 22 Jan 2008	SF	RFC5710	63	Return more columns in CaseScreens result set
-- 27 Feb 2008	LP	RFC5799	64	Return ResponsibleNameKey and ResponsibleName columns in Events result sets
-- 05 Jun 2008	JCLG	RFC6709	65	Change 'left join' to 'join' with SITECONTROL to improve performance
-- 01 Jul 2008	LP	RFC6709	65	Change 'left join' to 'join' with SITECONTROL to improve performance
-- 19 Aug 2008	AT	RFC6859	66	Add Case Profit Centre.
-- 08 Jul 2008	SF	RFC5743	66	Add Recent Contacts, Activity By Contact, Activity By Category and Total Activities resultset
--                  		        Also change Case result set to Add CaseTypeKey and PropertyTypeKey
-- 10 Jul 2008	AT	RFC5749	67	Change screen control program for CRM case types.
--					Return Opportunity details.
-- 22 Jul 2008	AT	RFC5788	68	Return Is CRM flag from CASETYPE.
-- 26 Aug 2008	AT	RFC5712	69	Return Marketing Activity details.
-- 01 Sep 2008  LP  	RFC5751 70  	Return ProspectIsClient column in CONTACTACTIVITYNAMES.
-- 23 Oct 2008	SF	RFC3392	71	Return ImageSequence column in IMAGES
-- 11 Dec 2008	MF	17136	72	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jan 2009	JCLG	RFC7362	73	Screen and Field Control. Remove CASESCREENS result set and return CRITERIANO to Case result set
-- 13 Jan 2009	MF	RFC7264	74	Control the due date cycles that may be displayed by allowing the EVENTS.CONTROLLINGACTION
--					to be used to specify an explicit Action that must be open for the Event to be considered due.
-- 28 Jan 2009	SF	RFC7459	75	New result set to return ChecklistInfo
-- 28 Jan 2009	SF	RFC7459	76	Continuation.
-- 16 Feb 2009	SF	RFC7565	77	Reformatted Case Resultset sql so it won't overflow in cultures other than English
-- 13 Feb 2009	PA	RFC6843	77	Set NameType as '~LD' to return lead contact details instead of prospect contact details  against
--					an opportunity.
-- 05 May 2009	DV	RFC7950	78	Added IsTextPresent in select statement for classes to indicate if topic text is present for the class.
-- 13 May 2009	DV	RFC7950	79	Checking for Text and ShortText column values for setting IsTextPresent
-- 21 Sep 2009  LP      RFC8047 80      Pass ProfileKey parameter to fn_GetCriteriaNo
--                                      Return Default Minimum Importance Level as a column
-- 08 Oct 2009	SF	RFC8517	81	SQL Overflow for 'Case' resultset when culture is non-neutral
-- 23 Oct 2009	DV	RFC8371 82      Modify logic to get the classes and sub classes.
-- 26 Oct 2009	LP	RFC6712	83	Return SecurityFlag as part of Case result set.
-- 15 Dec 2009	ASH	RFC8561	84	Count Local and International Classes.
-- 05 Jan 2010	LP	RFC8450	85	New ProgramKey parameter to allow viewing of case using a different screen control program.
-- 07 Jan 2009	SF	RFC4996	86	Add Ad Hoc Dates result set
-- 08 Jan 2010	LP	RFC8525	87	Implement logic to determine default case program from PROFILEATTRIBUTE then SITECONTROL.
-- 08 Jan 2009	SF	RFC4996	88	Continuation
-- 09 Mar 2010	PS      RFC8630 89      Add CountryCode column in the Designated Country result set.
-- 05 May 2010  PA      RFC9109 90      Add a condition to filter the correct designated countries.
-- 05 July 2010	ASH	RFC9273 91	Modify logic to get the value of IsTextPresent for CLASSES.
-- 07 Jul 2010	LP	RFC9513	92	Return Purchase Order Number regardless of BillingInstructions subject security
-- 25 Aug 2010	LP	RFC9695	93	Execute Row Access Security check for CASE result set only.
-- 17 Sep 2010	MF	RFC9777	94	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 25 Oct 2010	ASH	RFC9564	95	Add new columns First Use,First use in commerce in Classes result set and filter the column according to language.
-- 29 Oct 2010	ASH	RFC9788 96      Maintain Title in foreign languages.
-- 03 Nov 2010	ASH	RFC9788 97      Change logic to get all the selected class in CASECLASSES result set.
-- 09 Nov 2010	ASH	RFC9818 98      Modify logic to get the classes and sub classes.
-- 10 Nov 2010	ASH	R9788	99      Maintain CASE TEXT in foreign languages.
-- 29 Nov 2010	ASH	R10009	100	Implement logic to get all CASE CLASSES when there is so row in CASETEXT table.
-- 01 Feb 2011  LP      R10199	101	Display class heading if there is no Case Text against the class.
-- 10 Feb 2011	ASH	R100438	102	Undo the logic of Language Key.
-- 11 Feb 2011	ASH	R100438	103	Modify the logic to get ISTEXTPRESENT Flag.
-- 13 Apr 2011	ASH	R100436	104	Modify logic to get the row key in Case Classes result set .
-- 14 Feb 2011	ASH	R9876   105	Add Actual Response result set.
-- 04 Apr 2011  LP      R10404  106	Use translation when displaying default class headers.
-- 24 May 2011	JC	R10689  107	Fix response time issue with the Profile Importance Level and check the row access security for CASE only
-- 26 May 2011	JC	R9882	108	Add flag to check than an entry exists for OCCURREDEVENTS and DUEEVENTS
-- 14 Jun 2011	JC	R100151 109	Improve performance by passing authorisation as parameters
-- 20 Jul 2011	MF	R11008  110	Occurred Events that have a Controlling Action will require the OpenAction row that matches to have PoliceEvents=1.
-- 27 Sep 2011	MF	R11345	111	Revisit of R11008 to introduce a site control to force the display of the Event even if the controlling action is not open.
-- 10 Oct 2011	LP	R11394	112	Prevent duplicate rows of classes from being displayed if Goods & Services text exists for multiple languages
--					Goods & Services Text to display should be based on LANGUAGE site control, otherwise English
-- 19 Oct 2011	LP	R11394	113	Prevent duplicate rows of classes from being displayed if Goods & Services text exists for multiple languages
--					Goods & Services Text to display should be based on LANGUAGE site control, otherwise English
-- 20 Oct 2011  DV      R11439	114     Modify the join for Valid Property, Category, Basis and Sub Type
-- 21 Oct 2011	LP	R6896	115	Return HasAttachments column for OccurredEvents and DueEvents result sets.
-- 24 Oct 2011	ASH	R11460 	116	Cast integer columns as nvarchar(11) data type.
-- 01 Nov 2011	MF	R11458	117	Allow the creation of a hyperlink against an Action to be determined by a Site Control.

-- 02 Nov 2011	LP	R11394	118	Use Default Language from Site Control or English when returning text in Classes result set
-- 09 Nov 2011  LP	R11394	119	If the only Goods & Services text for the Class has a language other than the default, then display that.
-- 28 Nov 2011	LP	R11615	120	Corrected issue with classes displaying error
-- 13 Dec 2011	LP	R10451	121	Return ClientName, WorkingAttorney and FirstApplicant names in Case result set.
-- 26 Dec 2011	DV	R11140	122	Check for Case Access Security.
-- 12 Jan 2012	MF	R11788	123	Events Dates should only be displayed if they are associated with an OPENACTION row. This will avoid displaying
--					orphaned events.
-- 27 Jan 2012	LP	R11835	124	Fixed duplicate Class text when there are no class text in default language from site control
--					Display class heading if there are no class text matching the LANGUAGE site control
-- 10 Feb 2012  KR	R11926  125	fixed the case sensitive issue with the call for fn_Tokenise
-- 15 Feb 2012	LP	R11835	126	Fix highlighting logic for classes text with sub classes.
-- 06 Mar 2012	LP	R12027	127	Return IsDueDatePast flag in DUEEVENT result sets.
-- 20 Mar 2012	LP	R12094	128	Fix logic when displaying classes whose Goods/Services text are not in the default language.
-- 16 May 2012	MF	R12310	129	The logic for determining Due Dates and Occurred Dates has been encapsulated into user defined
--					functions.
-- 12-Jun-2012	LP	R12398	130	Consider CASECATEGORY when determining which VALIDSUBTYPE rule to use.
-- 20 Jul 2012	ASH	R12463	131	Corrected issue with Owner Name in Case Details window.
-- 06-Aug-2012	vql	R12471	132	Error in a specific case (make temp class table column larger).
-- 06-Sep-2012  MS      R12673  133     Added RENEWALDATES resultset
-- 21 Sep 2012	MF	R12703	134	External users are to check the sitecontrol "Client Due Dates: Overdue Days" and if a value exists then duedates are
--					displayed are to be restricted so that they are no older than the number of days specified.
--24 JAN 2013	AK	R13000	135	Removed transaction Date check from WIPByCurrency, WIPTotal result set
-- 15 Apr 2013	DV	R13270	136	Increase the length of nvarchar to 11 when casting or declaring integer
--06 Jun 2013	AK	R13408  137	Modified designated country result set to return classes, designated date, group joining  date and Extension State
--10 Jun 2013	AK	R13408	138	Added IsDefaultedFromParentCase in designated country result set
-- 21 Jun 2013	LP	DR53	139	Return CaseNameText result set.
-- 05 Jul 2013	vql	R13629	140	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 03 Oct 2013	MF	R13772	141	Profile associated with User is not being extracted when CaseNameText data is being requested.
-- 02 Dec 2013	MF	R28425	142	Solution provided by Adri Koopman (Novagraaf)
--					Consider the language of @psCulture when determining the CaseText for Classes to display before considering the 'LANGUAGE' specified in SITECONTROL.
-- 02 Jan 2014  DV	R27003	143	Return LOGDATETIMESTAMP column for Designated Country
-- 20 Jan 2014  MS      R100844 144     Pass @psProgramKey to csw_ListCaseName stored proc call
-- 24 Mar 2014	DV	R31401	145     Fixed issue to retun Designated country with no status
-- 22 Apr 2014	MF	R32808	146	Revisit of RFC12703. External users are to check the sitecontrol "Client Due Dates: Overdue Days" and if a value exists then duedates are
--					displayed are to be restricted so that they are no older than the number of days specified.
-- 22 May 2014  MS      R34385  147     Fix Classes data when goods and classes text have history maintained
-- 01 Jul 2014	MF	R36496	148	Revisit of RFC32808 to remove some debug code that was causing a problem.
-- 16 Sep 2014  SW      R27882  149     Evaluate ScreenCriteriaKey prior to execution of csw_ListCaseName.
-- 16 Mar 2015  DV	R45581  150     Return the default Event text based on the user preferred settings.
-- 14 Sep 2015  DV	R50824  151     Return the Trade Mark Image in the header if specified in Image Type for Case Header site control.
-- 21 Sep 2015  MS      R51622  152     Return the Application Filing Date in the header
-- 02 Nov 2015	vql	R53910	153	Adjust formatted names logic (DR-15543).
-- 14 Dec 2015  MS      R54670  154     Get Event Text for null event text type in Events tab
-- 14 Oct 2016	MF	64866	155	Need to cater for the possibility that an Event could potentially have multiple Event Notes of the same Note Type. This can occur when
--					an Event that has its own notes as become a member of a NoteGroup where Notes existed for other Events in that NoteGroup. To decide which Note
--					to return, the system will give preference to a Note that has been shared followed by the latest note edited.
-- 27 Oct 2016	MF	64289	156	Return Event Text of the default EventNoteType preference of the user, however if that does not exist then return the most recently modified text.
-- 14 Nov 2016	MF	69882	157	Implement translation for COUNTRYFLAGS(change provided by AK of Novagraaf).
-- 26 Dec 2016  AK      R54034  158     'Instructor Reference' and 'Agent Reference' columns in DesignatedCountries result set
-- 05 Oct 2017  MS      R72507  159     Add CaseFamilyTitle in the resultset
-- 03 Nov 2017  MS      R72861  160     Get Billing result set after CaseBilling to avoid errors
-- 28 Nov 2017	MF	72968	161	Revisit of 64289.  Event Notes with no Event Note Type will be returned in preference.  If none exists then the user's preference will be shown or finally the most recently modified text.
-- 11 Dec 2017  MS      R73074  162     Replaces CaseFamilyTitle with CaseFamilyFormatted field
-- 07 Dec 2017  DV	R73083	163	Return Designation for a Case even if it has been removed from the Country Group.
-- 04 Jan 2018	MF	73214	164	Revisit 64866. We were previously returning Event Notes that were shared between Events, even though there was not a physical connection between the Event and the Note (no CASEEVENTTEXT row). This could
--					occur if the rules around how Events sharing have changed after notes had been entered.  This solution however only works well when looking at the details of a single Case, whereas a list of Cases such
--					as returned by the Due Date List (ipw_ListDueDate) would result in an unacceptable performance overhead. To ensure consistency of behaviour only notes directly linked to a CASEEVENT will be shown here.
-- 04 Jan 2018	MF	73220	164	Event Notes not being returned when the EVENTTEXT row is missing a LOGDATETIMESTAMP value. Resolved by defaulting to 1900-01-01.
-- 25 Jun 2018  MS 	R73676	165	Do not show CaseFamilyReference in brackets if it matches CaseFamilyTitle Field
-- 17 Aug 2018	DV	R74350	166	Return Contact activity details for non Crm cases
-- 07 Sep 2018	DV	R74675	167	Do not return sub class if items are configured for a property type
-- 07 Sep 2018	AV	74738	168	Set isolation level to read uncommited.
-- 17 Sep 2018	DV	R74394	169	Return the count of Items for the Case.
-- 09 Oct 2018  DV	R74974	170	Return SubClass as null if Property Type does not allow subclass
-- 11 Oct 2018  AV	R74875	171	Highlight items that are not defined
-- 01 Nov 2018	DV	R75391	172	Return default class heading in resultset
-- 14 Nov 2018  AV	DR-45358 173 Date conversion errors when creating cases and opening names in Chinese DB
-- 04 Feb 2019	MF	DR-46845 174 When a designated country row is returned, the country to display should first consider the country of the related case if it exists, as it may be
--								 different to the country that was originally designated.
-- 16 Apr 2019	AV	DR-46835 175 Deleting default Goods & Services text from Case causes it to reappear in blue
-- 25 Apr 2019  SW	DR-48469 176 Goods & Services Text should display as blank if there is no text with default language/ Removed TextNo column from case classes resultset
-- 25 Apr 2019	SW  DR-46807 177 Return DefaultLanguageKey in CaseClasses resultset
-- 06 Sep 2019  BS  DR-32212 178 File Location for main file part takes precedence over other file parts
-- 06 Sep 2019	DV	DR-41559 179 Get the Email subject from DocItem if configured
-- 09 Sep 2019  LP  DR-51948 180 Return ProgramKey as part of Case data set

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @nErrorCode 			int

Declare @sSQLString			nvarchar(max)

Declare @sLookupCulture			nvarchar(10)
Declare	@nLanguage			int		-- RFC28425

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @nLanguage      = dbo.fn_GetLanguage(@psCulture)	-- RFC28425

Declare @nBillingCaseKey		int
Declare	@bHasInstructions		bit
Declare @bEntryFlag			bit
Declare	@bShowAllEventDates		bit

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

Declare @sGenericKey			nvarchar(20)

declare @sCaseTypeKey 			nchar(1)
declare @sPropertyTypeKey		nchar(1)
declare @bIsCRMCaseType			bit
Declare @nActivityCaseKey		int

Declare	@bIsExternalUser		bit
Declare	@nOverdueDays			int
Declare	@dtOverdueRangeFrom		datetime	-- external users restricted from seeing overdue dates

Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @nLeadKey			int
Declare @nProspectKey			int
Declare @sNameBasedResultsets		nvarchar(4000)

Declare @sCaseStatusDescription		nvarchar(50)
Declare @sStatusSummary			nvarchar(80)
Declare @sEntitySizeDescription		nvarchar(80)
Declare @sRenewalStatusDescription	nvarchar(80)
Declare @sCaseOffice			nvarchar(80)
Declare @sClasses 			nvarchar(254)
Declare @sRenewalAction			nvarchar(2)
Declare @nScreenCriteriaKey		int

Declare @nChecklistType			int
Declare @sValidChecklistDescription 	nvarchar(50)
Declare @nProfileKey			int
Declare @nProfileImportance		int

Declare @bHasRowAccessSecurity		bit	-- Indicates if Row Access Security exists for the user
Declare @nSecurityFlag			int	-- The security flag return via best fit
Declare @bHasCaseAccessSecurity		bit	-- Indicates if Row Access Security exists for the user
Declare @nCaseAccessSecurityFlag	int	-- The security flag return from USERSTATUS
Declare @bUseOfficeSecurity		bit	-- Indicates if Row Access Security restricts by Case Office

Declare @sLocalClasses 			nvarchar(254)
Declare @sIntClasses 			nvarchar(254)
Declare @nCountIntClasses		int
Declare @nCountLocalClasses		int
Declare @nCountClassItems		int
Declare	@nDefaultEventNoteType		int
Declare @bAllowSubClass bit
Declare @nAllowSubClassItem int

Declare @sCaseReference nvarchar(30)
Declare @nDocItemKey int
Declare @tDocItem table (DocItemText ntext)
Declare @psEmailSubject nvarchar(max)

CREATE TABLE #TEMPCLASSESTEXT (
	CLASS				nvarchar(200)	collate database_default NULL,
	TEXTNO				smallint	NULL,
	INDEFAULTLANGUAGE		bit		NULL
)

Declare @nClientNameKey			int
Declare @sClientName			nvarchar(254)
Declare @sClientNameCode		nvarchar(254)
Declare @nWorkingAttorneyNameKey	int
Declare @sWorkingAttorneyName		nvarchar(254)
Declare @sWorkingAttorneyNameCode	nvarchar(254)
Declare @nFirstApplicantNameKey		int
Declare @sFirstApplicantName		nvarchar(254)
Declare @sFirstApplicantNameCode	nvarchar(254)
Declare @dApplicationFilingDate         datetime

Set     @nErrorCode = 0
Set 	@nBillingCaseKey = null
Set	@bHasRowAccessSecurity = 0
Set	@bHasCaseAccessSecurity = 0
Set	@nSecurityFlag = 15		-- Set Security Flag to maximum row access level
Set	@bUseOfficeSecurity = 0
Set	@bShowAllEventDates = 0

-- Set the Case Security level to the default value.
If @nErrorCode=0
Begin
	SELECT @nCaseAccessSecurityFlag = ISNULL(SC.COLINTEGER,15)
	FROM SITECONTROL SC
	WHERE SC.CONTROLID = 'Default Security'
End
-- add comma at the end so the last field also have a comma when doing charindex later on
-- and strip off spaces.
-- @psResultsetsRequired become ',' if @psResultsetsRequired is originally null
Set	@psResultsetsRequired = upper(replace(isnull(@psResultsetsRequired, ''), ' ', '')) + ','
Set	@sNameBasedResultsets = ',' + @psResultsetsRequired

-- Retrieve Local Currency information
If @nErrorCode=0
and (   @psResultsetsRequired = ','
     or CHARINDEX('CASEBILLING,', @psResultsetsRequired) <> 0
     or CHARINDEX('CASEWIP,', @psResultsetsRequired) <> 0
     or CHARINDEX('WIPBYCURRENCY,', @psResultsetsRequired) <> 0)	-- RFC13772
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode = 0
and (@psResultsetsRequired = ','
     or CHARINDEX('OPPORTUNITYDETAIL,', @psResultsetsRequired) <> 0
     or CHARINDEX('ACTIVITYBYCONTACT,', @psResultsetsRequired) <> 0
     or CHARINDEX('ACTIVITYBYCATEGORY,', @psResultsetsRequired) <> 0
	 or CHARINDEX('RECENTACTIVITYTOTAL,', @psResultsetsRequired) <> 0
	 or CHARINDEX('RECENTACTIVITY,', @psResultsetsRequired) <> 0)
Begin
	set @sSQLString = "select @sCaseTypeKey = CASETYPE,
			@sPropertyTypeKey = PROPERTYTYPE
			from CASES where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnCaseKey	int,
						@sCaseTypeKey	nchar(1) output,
						@sPropertyTypeKey nchar(1) output',
						@pnCaseKey		= @pnCaseKey,
						@sCaseTypeKey		= @sCaseTypeKey output,
						@sPropertyTypeKey	= @sPropertyTypeKey output
End

-------------------------------------
-- Get the ProfileKey for the current
-- user and check if External User
-------------------------------------
If @nErrorCode = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('CASE,', @psResultsetsRequired) <> 0
     or CHARINDEX('CHECKLISTINFO,', @psResultsetsRequired) <> 0
     or CHARINDEX('CASENAMETEXT,', @psResultsetsRequired) <> 0)
Begin
        Select	@nProfileKey	 = PROFILEID,
		@bIsExternalUser = ISEXTERNALUSER
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId

        Set @nErrorCode = @@ERROR
End

-- Check if user has been assigned row access security profile
If @nErrorCode = 0
and @pbCalledFromCentura = 0
and (   @psResultsetsRequired = ','
     or CHARINDEX('CASE,', @psResultsetsRequired) <> 0)
Begin
	Select @bHasRowAccessSecurity = 1,
	@bUseOfficeSecurity = ISNULL(SC.COLBOOLEAN, 0)
	from IDENTITYROWACCESS U WITH (NOLOCK)
	join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
	left join SITECONTROL SC WITH (NOLOCK) on (SC.CONTROLID = 'Row Security Uses Case Office')
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId

	Set @nErrorCode = @@ERROR

	If  @nErrorCode = 0
	and @bHasRowAccessSecurity = 1
	Begin
		Set @nSecurityFlag = 0		-- Set to 0 since we know that Row Access has been applied
		If @bUseOfficeSecurity = 1
		Begin
			SELECT @nSecurityFlag = S.SECURITYFLAG
			from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000
				+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100
				+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10
				+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
				FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U, CASES C
				WHERE R.RECORDTYPE = 'C'
				AND (R.CASETYPE = C.CASETYPE OR R.CASETYPE IS NULL)
				AND (R.PROPERTYTYPE = C.PROPERTYTYPE OR R.PROPERTYTYPE IS NULL)
				AND (R.OFFICE = C.OFFICEID OR R.OFFICE IS NULL)
				AND R.NAMETYPE IS NULL
				AND U.IDENTITYID = @pnUserIdentityId
				AND U.ACCESSNAME = R.ACCESSNAME
				AND C.CASEID = @pnCaseKey
				ORDER BY BESTFIT DESC, SECURITYFLAG ASC) S
		End
		Else
		Begin
			SELECT @nSecurityFlag = S.SECURITYFLAG
			from (SELECT TOP 1 SECURITYFLAG as SECURITYFLAG,(1- isnull( (R.OFFICE * 0), 1 ) ) * 1000
				+  CASE WHEN R.CASETYPE IS NULL THEN 0 ELSE 1 END  * 100
				+  CASE WHEN R.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END  * 10
				+  CASE WHEN R.NAMETYPE IS NULL THEN 0 ELSE 1 END  * 1 as BESTFIT
				FROM ROWACCESSDETAIL R, IDENTITYROWACCESS U, CASES C
				WHERE R.RECORDTYPE = 'C'
				AND (R.CASETYPE = C.CASETYPE OR R.CASETYPE IS NULL)
				AND (R.PROPERTYTYPE = C.PROPERTYTYPE OR R.PROPERTYTYPE IS NULL)
				AND (R.OFFICE in (select TA.TABLECODE
							from TABLEATTRIBUTES TA
							where TA.PARENTTABLE='CASES'
							and TA.TABLETYPE=44
							and TA.GENERICKEY=convert(nvarchar, C.CASEID) )
					OR R.OFFICE IS NULL)
				AND R.NAMETYPE IS NULL
				AND U.IDENTITYID = @pnUserIdentityId
				AND U.ACCESSNAME = R.ACCESSNAME
				AND C.CASEID = @pnCaseKey
				ORDER BY BESTFIT DESC, SECURITYFLAG ASC) S
		End
		Set @nErrorCode = @@ERROR
	End

	Set @sSQLString =
		"SELECT @bHasCaseAccessSecurity = 1,
			@nCaseAccessSecurityFlag = ISNULL(U.SECURITYFLAG,@nCaseAccessSecurityFlag)
		FROM USERSTATUS U
		JOIN USERIDENTITY UI ON UI.LOGINID = U.USERID
		JOIN CASES C ON C.STATUSCODE = U.STATUSCODE
		WHERE UI.IDENTITYID = @pnUserIdentityId
		AND C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nCaseAccessSecurityFlag	int output,
					  @bHasCaseAccessSecurity       int output,
					  @pnUserIdentityId		int,
					  @pnCaseKey			int',
					  @nCaseAccessSecurityFlag	= @nCaseAccessSecurityFlag output,
					  @bHasCaseAccessSecurity	= @bHasCaseAccessSecurity output,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnCaseKey			= @pnCaseKey

	Set @sSQLString =
		"SELECT @nSecurityFlag = CASE
					WHEN @bHasCaseAccessSecurity = 0 and @bHasRowAccessSecurity = 0 THEN
							CASE WHEN @nCaseAccessSecurityFlag & 4 = 4 THEN ISNULL(@nSecurityFlag,15)
							ELSE @nCaseAccessSecurityFlag END
					 WHEN @bHasCaseAccessSecurity = 0 and @bHasRowAccessSecurity = 1 THEN ISNULL(@nSecurityFlag,15)
					 WHEN @bHasCaseAccessSecurity = 1 and @bHasRowAccessSecurity = 0 THEN
							CASE WHEN @nCaseAccessSecurityFlag & 4 = 4 THEN ISNULL(@nSecurityFlag,15)
							ELSE @nCaseAccessSecurityFlag END
					 ELSE
							CASE WHEN ISNULL(@nSecurityFlag,15) <=
								CASE WHEN @nCaseAccessSecurityFlag & 4 = 4 THEN ISNULL(@nSecurityFlag,15)
								ELSE @nCaseAccessSecurityFlag END
							     THEN ISNULL(@nSecurityFlag,15)
							ELSE @nCaseAccessSecurityFlag END
					 END"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nSecurityFlag		int output,
					  @nCaseAccessSecurityFlag	int,
					  @bHasCaseAccessSecurity	bit,
					  @bHasRowAccessSecurity	bit',
					  @nSecurityFlag		= @nSecurityFlag output,
					  @nCaseAccessSecurityFlag	= @nCaseAccessSecurityFlag,
					  @bHasCaseAccessSecurity	= @bHasCaseAccessSecurity,
					  @bHasRowAccessSecurity	= @bHasRowAccessSecurity


End

-- Prepare variables to populate the Case table
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASE,', @psResultsetsRequired) <> 0)
Begin

	-- Get the Minimum Importance Level for the profile
	If @nErrorCode = 0 and @nProfileKey is not null
	Begin
		Select @nProfileImportance = convert(int, PA.ATTRIBUTEVALUE)
		from PROFILEATTRIBUTES PA
		where PA.PROFILEID = @nProfileKey and PA.ATTRIBUTEID = 1
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0 and @nProfileImportance is null
	Begin
		Select @nProfileImportance = isnull(SC.COLINTEGER,0)
		from SITECONTROL SC
		where SC.CONTROLID='Events Displayed'
		Set @nErrorCode = @@ERROR
	End

	-- Get the default program for the Case if not specified via input param
	If @nErrorCode = 0 and (@psProgramKey is null or @psProgramKey = '')
	Begin
		If @nErrorCode = 0 and @nProfileKey is not null
		Begin
			Select @psProgramKey = P.ATTRIBUTEVALUE
			from PROFILEATTRIBUTES P
			where P.PROFILEID = @nProfileKey
			and P.ATTRIBUTEID = 2 -- Default Case Program
			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode = 0 and (@psProgramKey is null or @psProgramKey = '')
		Begin
			Select @psProgramKey = SC.COLCHARACTER
			from SITECONTROL SC
			where SC.CONTROLID = 'Case Screen Default Program'
			Set @nErrorCode = @@ERROR
		End
	End

	If @nErrorCode=0
	Begin
	Set @sSQLString =
	"Select"+char(10)+
	"@sCaseStatusDescription = "+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@sStatusSummary = "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@sEntitySizeDescription = "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@sRenewalStatusDescription = "+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura)+","+char(10)+
	"@sCaseOffice = "+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,@pbCalledFromCentura)+","+
		"@nScreenCriteriaKey = +dbo.fn_GetCaseScreenCriteriaKey(@pnCaseKey, 'W', @psProgramKey, @nProfileKey)"+char(10)+
		"from CASES C"+char(10)+
		"join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)"+char(10)+
	"left join PROPERTY P		on (P.CASEID = C.CASEID)"+char(10)+
	"left join STATUS ST 		on (ST.STATUSCODE=C.STATUSCODE)"+char(10)+
	"left join STATUS RS 		on (RS.STATUSCODE=P.RENEWALSTATUS)"+char(10)+
	"left join TABLECODES TC 	on (TC.TABLECODE=CASE 	WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) THEN 7603"+char(10)+
							       "WHEN(ST.REGISTEREDFLAG=1) THEN 7602"+char(10)+
							       "ELSE 7601"+char(10)+
							"END)"+char(10)+
	"left join TABLECODES TC2 	on (TC2.TABLECODE=C.ENTITYSIZE)"+char(10)+
	"left join OFFICE OFC		on (OFC.OFFICEID=C.OFFICEID)"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
					  @sCaseStatusDescription	nvarchar(50)			OUTPUT,
					  @sStatusSummary		nvarchar(80)			OUTPUT,
					  @sEntitySizeDescription	nvarchar(80)			OUTPUT,
					  @sRenewalStatusDescription	nvarchar(80)			OUTPUT,
					  @sCaseOffice			nvarchar(80)			OUTPUT,
					  @nScreenCriteriaKey	int					OUTPUT,
						  @nProfileKey                  int,
						  @psProgramKey			nvarchar(8)',
					  @pnCaseKey		 	= @pnCaseKey,
					  @sCaseStatusDescription	= @sCaseStatusDescription	OUTPUT,
					  @sStatusSummary		= @sStatusSummary		OUTPUT,
					  @sEntitySizeDescription	= @sEntitySizeDescription	OUTPUT,
					  @sRenewalStatusDescription	= @sRenewalStatusDescription	OUTPUT,
					  @sCaseOffice			= @sCaseOffice			OUTPUT,
					  @nScreenCriteriaKey	= @nScreenCriteriaKey	OUTPUT,
						  @nProfileKey                  = @nProfileKey,
						  @psProgramKey			= @psProgramKey
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		SELECT @bHasInstructions=cast(sum(1) as bit)
		FROM INSTRUCTIONDEFINITION D
		-- Driving event is either the prerequisite event or the due event
		JOIN EVENTS E		on (E.EVENTNO=isnull(D.PREREQUISITEEVENTNO,D.DUEEVENTNO))
		-- The driving event must exist against the case
		JOIN CASEEVENT P	on (P.CASEID=@pnCaseKey
					and P.EVENTNO=E.EVENTNO)
		-- Available for single case entry
		WHERE 	D.AVAILABILITYFLAGS&2=2"

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnCaseKey			int,
						  @bHasInstructions		bit 	OUTPUT',
						  @pnCaseKey			= @pnCaseKey,
						  @bHasInstructions		= @bHasInstructions	OUTPUT

		set @bHasInstructions=isnull(@bHasInstructions,0)
	End

        If @nErrorCode = 0
        Begin
                Set @sSQLString = "
                Select @dApplicationFilingDate = ISNULL(CE.EVENTDATE, CE.EVENTDUEDATE)
                FROM CASEEVENT CE
                where CE.CASEID = @pnCaseKey
                and EVENTNO = -4
                and CYCLE = (select max(CYCLE)
					from CASEEVENT CE1
					where CE1.CASEID =CE.CASEID
					and   CE1.EVENTNO=CE.EVENTNO
					and   ISNULL(CE1.EVENTDATE, CE1.EVENTDUEDATE) is not null)"

                exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnCaseKey			int,
						  @dApplicationFilingDate	datetime 	OUTPUT',
						  @pnCaseKey			= @pnCaseKey,
						  @dApplicationFilingDate	= @dApplicationFilingDate	OUTPUT
        End
End


-- Case result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASE,', @psResultsetsRequired) <> 0)
Begin
	-- RFC10451: Retrieve Case Names
	Select
	@nClientNameKey = N1.NAMENO,
	@sClientName = dbo.fn_FormatNameUsingNameNo(N1.NAMENO,N1.NAMESTYLE),
	@sClientNameCode = N1.NAMECODE,
	@nWorkingAttorneyNameKey = N2.NAMENO,
	@sWorkingAttorneyName = dbo.fn_FormatNameUsingNameNo(N2.NAMENO,N2.NAMESTYLE),
	@sWorkingAttorneyNameCode = N2.NAMECODE,
	@nFirstApplicantNameKey = N3.NAMENO,
	@sFirstApplicantName = dbo.fn_FormatNameUsingNameNo(N3.NAMENO,N3.NAMESTYLE),
	@sFirstApplicantNameCode = N3.NAMECODE
	from CASES C
	left join CASENAME CN1 on (CN1.CASEID = C.CASEID
		and CN1.NAMETYPE = 'I'
		and CN1.EXPIRYDATE IS NULL)
	left join NAME N1 on (N1.NAMENO=CN1.NAMENO)
	left join CASENAME CN2 on (CN2.CASEID = C.CASEID
		and CN2.NAMETYPE = 'EMP'
		and CN2.EXPIRYDATE IS NULL)
	left join NAME N2 on (N2.NAMENO=CN2.NAMENO)
	left join CASENAME CN3 on (CN3.CASEID = C.CASEID
		and CN3.NAMETYPE = 'O'
		and CN3.EXPIRYDATE IS NULL
		and CN3.SEQUENCE = (SELECT MIN(SEQUENCE)
					from CASENAME CN
					where CN.CASEID=CN1.CASEID
					and CN.NAMETYPE='O'
					and CN.EXPIRYDATE is null))
	left join NAME N3 on (N3.NAMENO=CN3.NAMENO)
	where C.CASEID=@pnCaseKey

	Set @nErrorCode = @@ERROR

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



	If @nErrorCode = 0
	Begin
	Set @sSQLString =
	"Select"+char(10)+
	"cast(C.CASEID as nvarchar(11)) as RowKey,"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"C.IRN as CaseReference,"+char(10)+
	CASE WHEN @nScreenCriteriaKey IS NULL THEN "NULL" ELSE convert(nvarchar(11),@nScreenCriteriaKey) END + " as ScreenCriteriaKey,"+char(10)+
	"C.CURRENTOFFICIALNO as CurrentOfficialNumber,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	"@sStatusSummary as StatusSummary,"+char(10)+
	"@sCaseStatus as CaseStatusDescription,"+char(10)+
	"@sRenewalStatus as RenewalStatusDescription,"+char(10)+
	"C.CASETYPE as CaseTypeKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+" as CaseTypeDescription,"+char(10)+
	"C.COUNTRYCODE as CountryCode,"+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)+" as CountryName,"+char(10)+
	"VP.PROPERTYTYPE as PropertyTypeKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura)+" as PropertyTypeDescription,"+char(10)+
	"CASE WHEN VP.PROPERTYTYPE is null THEN NULL ELSE "+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura)+" END as CaseCategoryDescription,"+char(10)+
	"CASE WHEN (VC.CASECATEGORY is null or VP.PROPERTYTYPE is null) THEN NULL ELSE "+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura)+" END as SubTypeDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura)+" as ApplicationBasisDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TM',@sLookupCulture,@pbCalledFromCentura)+" as TypeOfMarkDescription,"+char(10)+
	"C.FAMILY as CaseFamilyReference,"+char(10)+
        "CASE WHEN C.FAMILY is not null then case when C.FAMILY <> CF.FAMILYTITLE then char(123) + C.FAMILY + char(125) + SPACE(1) + " + dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura) + " else " + dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura) + " end else null end as CaseFamilyFormatted,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TF',@sLookupCulture,@pbCalledFromCentura)+" as FileLocation,"+char(10)+
	"C.LOCALCLIENTFLAG as LocalClientFlag,"+char(10)+
	"@sLocCurrency as LocalCurrencyCode,"+char(10)+
	"@nLocDecimal as LocalDecimalPlaces,"+char(10)+
	"dbo.fn_FormatTelecom(M.TELECOMTYPE, M.ISD, M.AREACODE, M.TELECOMNUMBER, M.EXTENSION)"+char(10)+
	"as EmailAddress,"+char(10)+
	"CASE WHEN @nDocItemKey is null THEN C.IRN + SPACE(1) + "+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"ELSE @psEmailSubject END as EmailSubject,"+char(10)+
	"@sEntitySize as EntitySizeDescription,"+char(10)+
	"@sCaseOffice as CaseOffice,"+char(10)+
	"@bHasInstructions as HasInstructions,"+char(10)+
	"isnull(CS.CRMONLY,0) as IsCRM,"+char(10)+
	"C.PROFITCENTRECODE as ProfitCentreKey,"+char(10)+
	"PC.DESCRIPTION as ProfitCentreDescription,"+char(10)+
	/* @nImportance is profile importance */
	"@nImportance as DefaultImportanceLevel,"+char(10)+
		convert(nvarchar(3),@nSecurityFlag) + " as SecurityFlag,"+char(10)+
		"@nClientNameKey as ClientNameKey,"+char(10)+
		"@sClientName as ClientName,"+char(10)+
		"@sClientNameCode as ClientNameCode,"+char(10)+
		"@nWorkingAttorneyNameKey as WorkingAttorneyNameKey,"+char(10)+
		"@sWorkingAttorneyName as WorkingAttorneyName,"+char(10)+
		"@sWorkingAttorneyNameCode as WorkingAttorneyNameCode,"+char(10)+
		"@nFirstApplicantNameKey as FirstApplicantNameKey,"+char(10)+
		"@sFirstApplicantName as FirstApplicantName,"+char(10)+
		"@sFirstApplicantNameCode as FirstApplicantNameCode,"+char(10)+
		"CI.IMAGEID as ImageKey,"+char(10)+
		"CI.CASEIMAGEDESC as ImageDescription,"+char(10)+
                "@dApplicationFilingDate as ApplicationFilingDate,"+char(10)+
        "@psProgramKey as ProgramKey"+char(10)+
	"from CASES C"+char(10)+
	"join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)"+char(10)+
	"join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
	"left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)"+char(10)+
				"from VALIDPROPERTY VP1"+char(10)+
				"where VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join PROPERTY P on (P.CASEID = C.CASEID)"+char(10)+
	"left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                               "and VS.CASETYPE = C.CASETYPE"+char(10)+
	                               "and VS.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                               "and VS.SUBTYPE = C.SUBTYPE"+char(10)+
	                     	       "and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)"+char(10)+
	                     	                              "from VALIDSUBTYPE VS1"+char(10)+
	                     	               	              "where VS1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                                  	              "and VS1.CASETYPE = C.CASETYPE"+char(10)+
	                                  	              "and VS1.CASECATEGORY = C.CASECATEGORY"+char(10)+
	                     	                              "and VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	"left join VALIDBASIS VB on (VB.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
	                         	       "and VB.BASIS = P.BASIS"+char(10)+
	                    		       "and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)"+char(10)+
		                     	                              "from VALIDBASIS VB1"+char(10)+
		                     	                              "where VB1.PROPERTYTYPE = C.PROPERTYTYPE"+char(10)+
		                     	                              "and VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
	"left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VC.CASETYPE=C.CASETYPE"+char(10)+
				"and VC.CASECATEGORY=C.CASECATEGORY"+char(10)+
				"and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)"+char(10)+
				"from VALIDCATEGORY VC1"+char(10)+
				"where VC1.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
				"and VC1.CASETYPE=C.CASETYPE"+char(10)+
				"and VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))"+char(10)+
	"left join TABLECODES TM on (TM.TABLECODE=C.TYPEOFMARK)"+char(10)+
	"left join TABLECODES TF on TF.TABLECODE=(
                select FILELOCATION
                FROM (select CL.FILELOCATION, FP.ISMAINFILE, ROW_NUMBER() over ( order by ISMAINFILE desc , WHENMOVED desc) RN
                        from CASELOCATION CL
                        left join FILEPART FP on (CL.FILEPARTID = FP.FILEPART and FP.CASEID = CL.CASEID and FP.ISMAINFILE = 1)
                        where CL.CASEID = C.CASEID
                ) T where RN=1)"+char(10)+
				"left join CASENAME CN on (CN.CASEID=C.CASEID"+char(10)+
				"and(CN.EXPIRYDATE IS NULL or CN.EXPIRYDATE>getdate())"+char(10)+
				"and CN.NAMETYPE=(select max(CN1.NAMETYPE) from CASENAME CN1"+char(10)+
				"where CN1.CASEID=CN.CASEID"+char(10)+
				"and CN1.NAMETYPE in ('EMP')"+char(10)+
				"and(CN1.EXPIRYDATE IS NULL or CN1.EXPIRYDATE>getdate())))"+char(10)+
	"left join NAME NCN on (NCN.NAMENO=CN.NAMENO)"+char(10)+
	"left join TELECOMMUNICATION M on (M.TELECODE=NCN.MAINEMAIL)"+char(10)+
	"left join PROFITCENTRE PC on (PC.PROFITCENTRECODE=C.PROFITCENTRECODE)"+char(10)+
	"left join SITECONTROL SC on (SC.CONTROLID='Image Type for Case Header')"+char(10)+
	"left join CASEIMAGE CI on (CI.CASEID=C.CASEID and CI.IMAGETYPE = SC.COLINTEGER"+char(10)+
				"and CI.IMAGESEQUENCE = (Select MIN(IMAGESEQUENCE) from CASEIMAGE CI1"+char(10)+
							"WHERE CI1.CASEID = @pnCaseKey and CI1.IMAGETYPE = SC.COLINTEGER))"+char(10)+
        "left join CASEFAMILY CF on (C.FAMILY = CF.FAMILY)"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
					  @sStatusSummary		nvarchar(80),
					  @sCaseStatus	nvarchar(50),
					  @sEntitySize	nvarchar(80),
					  @sRenewalStatus	nvarchar(80),
					  @sCaseOffice			nvarchar(80),
					  @sLocCurrency			nvarchar(3),
					  @nLocDecimal		tinyint,
					  @bHasInstructions		bit,
					  @nScreenCriteriaKey	int,
					  @nImportance   int,
						  @nSecurityFlag	int,
						  @nClientNameKey	int,
						  @sClientName		nvarchar(254),
						  @sClientNameCode	nvarchar(20),
						  @nWorkingAttorneyNameKey	int,
						  @sWorkingAttorneyName	nvarchar(254),
						  @sWorkingAttorneyNameCode nvarchar(20),
						  @nFirstApplicantNameKey	int,
						  @sFirstApplicantName	nvarchar(254),
					  @sFirstApplicantNameCode      nvarchar(20),
                      @dApplicationFilingDate       datetime,
					  @nDocItemKey				int,
					  @psEmailSubject			nvarchar(max),
                      @psProgramKey         nvarchar(8)',
					  @pnCaseKey		 	= @pnCaseKey,
					  @sStatusSummary		= @sStatusSummary,
					  @sCaseStatus	= @sCaseStatusDescription,
					  @sEntitySize	= @sEntitySizeDescription,
					  @sRenewalStatus	= @sRenewalStatusDescription,
					  @sCaseOffice			= @sCaseOffice,
					  @sLocCurrency		= @sLocalCurrencyCode,
					  @nLocDecimal		= @nLocalDecimalPlaces,
					  @bHasInstructions		= @bHasInstructions,
					  @nScreenCriteriaKey	= @nScreenCriteriaKey,
					  @nImportance   = @nProfileImportance,
						  @nSecurityFlag	= @nSecurityFlag,
						  @nClientNameKey	= @nClientNameKey,
						  @sClientName		= @sClientName,
						  @sClientNameCode	= @sClientNameCode,
						  @nWorkingAttorneyNameKey	= @nWorkingAttorneyNameKey,
						  @sWorkingAttorneyName	= @sWorkingAttorneyName,
						  @sWorkingAttorneyNameCode	= @sWorkingAttorneyNameCode,
						  @nFirstApplicantNameKey = @nFirstApplicantNameKey,
						  @sFirstApplicantName	= @sFirstApplicantName,
					  @sFirstApplicantNameCode      = @sFirstApplicantNameCode,
                      @dApplicationFilingDate       = @dApplicationFilingDate,
					  @nDocItemKey = @nDocItemKey,
					  @psEmailSubject = @psEmailSubject,
                        @psProgramKey			= @psProgramKey

	End
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
					  @pnCaseKey					int',
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
	"C.NOINSERIES as NoInSeries,"+char(10)+
	"REPLACE(ISNULL(C.LOCALCLASSES,''),',',', ') as LocalClasses,"+char(10)+
	"REPLACE(ISNULL(C.INTCLASSES,''),',',', ') as IntClasses,"+char(10)+
	" @nCountLocalClasses as TotalLocal,"+char(10)+
	" @nCountClassItems as TotalItems,"+char(10)+
	" @nCountIntClasses as TotalInternational,"+char(10)+
	"C.PURCHASEORDERNO as PurchaseOrderNo,"+char(10)+
	"CASE WHEN @pbCanViewBillingInstructions = 1"+char(10)+
		"THEN TR.DESCRIPTION"+char(10)+
		"ELSE NULL END as TaxTreatment,"+char(10)+
	"C.FILECOVER as FileCoverCaseKey,"+char(10)+
	"C2.IRN as FileCoverCaseReference,"+char(10)+
	"C.PREDECESSORID as PredecessorCaseKey,"+char(10)+
	"C3.IRN as PredecessorCaseReference,"+char(10)+
	"P.NOOFCLAIMS as NoOfClaims,"+char(10)+
	"C.IPODELAY as IPOfficeDelay,"+char(10)+
	"C.APPLICANTDELAY as ApplicantDelay,"+char(10)+
	"CASE WHEN C.IPODELAY>=C.APPLICANTDELAY THEN (C.IPODELAY-C.APPLICANTDELAY) ELSE NULL END as CalculatedDelay,"+char(10)+
	"C.IPOPTA as IPOfficePTA,"+char(10)+
	CASE 	WHEN @pbCanViewBillingInstructions = 1
		THEN "ISNULL(CTX.TEXT,CTX.SHORTTEXT) as BillingNotes,"
		ELSE "NULL as BillingNotes,"
	END+char(10)+
	"cast(C.CASEID as nvarchar(11)) as RowKey"+char(10)+
	"from CASES C"+char(10)+
	"left join CASETEXT CTX on (CTX.CASEID=C.CASEID"+char(10)+
					"and CTX.LANGUAGE is null and CTX.TEXTTYPE='_B' AND CTX.CLASS IS NULL"+char(10)+
					"and (convert(nvarchar(24),CTX.MODIFIEDDATE,21)+cast(CTX.TEXTNO as nvarchar(6)))"+char(10)+
						"="+char(10)+
					    "(select max(convert(nvarchar(24),CT2.MODIFIEDDATE,21)+cast(CT2.TEXTNO as nvarchar(6)))"+char(10)+
					     "from CASETEXT CT2"+char(10)+
					     "where CT2.CASEID=CTX.CASEID"+char(10)+
					     "and CT2.TEXTTYPE=CTX.TEXTTYPE"+char(10)+
					     "and CT2.CLASS IS NULL"+char(10)+
					     "and CT2.LANGUAGE IS NULL"+char(10)+
					     ")"+char(10)+
					     ")"+char(10)+
	"left join PROPERTY P		on (P.CASEID = C.CASEID)"+char(10)+
	"left join TAXRATES TR		on (C.TAXCODE = TR.TAXCODE)"+char(10)+
	"left join CASES C2 		on (C2.CASEID=C.FILECOVER)"+char(10)+
	"left join CASES C3 		on (C3.CASEID=C.PREDECESSORID)"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
					  @nCountLocalClasses		int,
					  @nCountIntClasses		int,
					  @nCountClassItems		int,
					  @pbCanViewBillingInstructions	bit',
					  @pnCaseKey		 	= @pnCaseKey,
					  @pbCanViewBillingInstructions	= @pbCanViewBillingInstructions,
					  @nCountLocalClasses		=  @nCountLocalClasses,
					  @nCountClassItems		=  @nCountClassItems,
					  @nCountIntClasses             =  @nCountIntClasses
End

-- Critical Dates result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CRITICALDATES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_ListCriticalDates
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbIsExternalUser	= 0,
		@psCulture		= @sLookupCulture,
		@pnCaseKey		= @pnCaseKey
End

-- CaseName result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASENAME,', @psResultsetsRequired) <> 0)
Begin
        IF (@nScreenCriteriaKey is null)
	    Begin
		  Set @nScreenCriteriaKey = dbo.fn_GetCaseScreenCriteriaKey(@pnCaseKey, 'W', @psProgramKey, @nProfileKey)
	    End

	exec @nErrorCode = dbo.csw_ListCaseName
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey,
					@psProgramKey = @psProgramKey,
					@pnScreenCriteriaKey = @nScreenCriteriaKey
End

-- CaseText result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASETEXT,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "
	Select	  cast(CT.CASEID as nvarchar(11)) + '^'
		+ cast(CT.TEXTTYPE as nvarchar(11)) + '^'
		+ cast(CT.TEXTNO as nvarchar(10))
					as RowKey,
		CT.CASEID		as CaseKey,
		TT.TEXTDESCRIPTION	as TextTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+"
				  	as [Language],
		ISNULL("+ dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','CT',@sLookupCulture,@pbCalledFromCentura)+", "+ dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,@pbCalledFromCentura)+")
					as Text,
		CASE WHEN CTR.CaseTextRows > 1 THEN CAST(1 as bit) ELSE CAST(0 as bit) END
					as HasHistory,
		CT.TEXTTYPE		as TextTypeKey,
		CT.LANGUAGE		as LanguageKey
	from CASETEXT CT
	join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture,0,@pbCalledFromCentura) TT
					on (TT.TEXTTYPE  = CT.TEXTTYPE)
	left join TABLECODES TC	   	on (TC.TABLECODE = CT.LANGUAGE)
	left join (Select CT1.CASEID, CT1.TEXTTYPE, CT1.CLASS, CT1.LANGUAGE, COUNT(*) as CaseTextRows
		   from CASETEXT CT1
		   group by CT1.CASEID, CT1.TEXTTYPE, CT1.CLASS, CT1.LANGUAGE) CTR on (CTR.CASEID = CT.CASEID
								   and CTR.TEXTTYPE = CT.TEXTTYPE
								   and (CTR.CLASS is null and
								        CT.CLASS is null)
								   and (CTR.LANGUAGE = CT.LANGUAGE
								    or (CTR.LANGUAGE is null and
									CT.LANGUAGE is null)))
	where CT.CASEID = @pnCaseKey
	-- Exclude anything with a class, as it is reported in the CLASSES result set
	and   CT.CLASS IS NULL
	-- Select version with the highest modified date and text no
	-- for all the languages that are available
	and  (  convert(nvarchar(24),CT.MODIFIEDDATE, 21)+cast(CT.TEXTNO as nvarchar(6)) )
		=
	     ( select max(convert(nvarchar(24), CT2.MODIFIEDDATE, 21)+cast(CT2.TEXTNO as nvarchar(6)) )
	       from CASETEXT CT2
	       where CT2.CASEID   = CT.CASEID
	       and   CT2.TEXTTYPE = CT.TEXTTYPE
	       and   CT2.CLASS IS NULL
	       and   (	(CT2.LANGUAGE = CT.LANGUAGE)
		     or	(CT2.LANGUAGE     IS NULL
			 and CT.LANGUAGE  IS NULL)
		     )
	     )
	order by TextTypeDescription, [Language]"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit',
					  @pnCaseKey		= @pnCaseKey,
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
		DE.FIRMELEMENTID as FirmElementID,
		"+dbo.fn_SqlTranslatedColumn('DESIGNELEMENT','ELEMENTDESC',null,'DE',@sLookupCulture,@pbCalledFromCentura)+"
				as ElementDescription,
		CI.IMAGESEQUENCE as ImageSequence
	from CASEIMAGE CI
	join TABLECODES D 	on (D.TABLECODE = CI.IMAGETYPE)
	left join DESIGNELEMENT DE on (DE.FIRMELEMENTID = CI.FIRMELEMENTID
				and DE.CASEID = CI.CASEID)
	where CI.CASEID = @pnCaseKey
	-- Exclude CPA Inprostart attachments stored as images
	and   CI.IMAGETYPE != 1206
	order by ImageTypeDescription, CI.IMAGESEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   	int',
					  @pnCaseKey	= @pnCaseKey
End

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin
	exec @nErrorCode = dbo.ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
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
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsForCase,0)) ELSE NULL END"+CHAR(10)+
	"		as 'PrepaymentsForCase',"+CHAR(10)+
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsForDebtors,0)) ELSE NULL END"+CHAR(10)+
	"		as 'PrepaymentsForDebtors',"+CHAR(10)+
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsTotal,0)) ELSE NULL END"+CHAR(10)+
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
	"where @pbCanViewWorkInProgressItems = 1"+CHAR(10)+
	"group by WIP.CASEID, WIP.ENTITYNO, WIP.EntityName, WIP.CurrencyCode"+CHAR(10)+
	"order by 'EntityName', 'EntityKey', 'CurrencyCode'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   	int,
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @pbCanViewWorkInProgressItems	bit,
					  @pbCanViewPrepayments		bit,
					  @sLocalCurrencyCode	nvarchar(3)',
					  @pnCaseKey		= @pnCaseKey,
					  @dtBaseDate		= @dtBaseDate,
					  @nAge0		= @nAge0,
					  @nAge1		= @nAge1,
					  @nAge2		= @nAge2,
					  @pbCanViewWorkInProgressItems	= @pbCanViewWorkInProgressItems,
					  @pbCanViewPrepayments		= @pbCanViewPrepayments,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode
End

-- WIPTotal result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('WIPTOTAL,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString =
	"Select"+CHAR(10)+
	"  cast(WIP.CASEID as nvarchar(11)) + '^'"+CHAR(10)+
	"+ cast(WIP.ENTITYNO as nvarchar(11)) as RowKey,"+CHAR(10)+
	"WIP.CASEID 	as 'CaseKey',"+CHAR(10)+
	"WIP.ENTITYNO 	as 'EntityKey',"+CHAR(10)+
	"WIP.EntityName as 'EntityName',"+CHAR(10)+
	-- Avoid  'Warning: null value is eliminated by an aggregate or other SET operation.'
	-- by using 'ISNULL' before the 'SUM'
	"SUM(ISNULL(WIP.Bracket0Total,0))"+CHAR(10)+
	"		as 'Bracket0Total',"+CHAR(10)+
	"SUM(ISNULL(WIP.Bracket1Total,0))"+CHAR(10)+
	"		as 'Bracket1Total',"+CHAR(10)+
	"SUM(ISNULL(WIP.Bracket2Total,0))"+CHAR(10)+
	"		as 'Bracket2Total',"+CHAR(10)+
	"SUM(ISNULL(WIP.Bracket3Total,0))"+CHAR(10)+
	"		as 'Bracket3Total',"+CHAR(10)+
	"SUM(ISNULL(WIP.Total,0))"+CHAR(10)+
	" 		as 'Total',"+CHAR(10)+
	-- Prepayment information should be null unless the current user has access to the Prepayments information
	-- security topic (201).
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsForCase,0)) 	ELSE NULL END"+CHAR(10)+
	"		as 'PrepaymentsForCase',"+CHAR(10)+
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsForDebtors,0)) 	ELSE NULL END"+CHAR(10)+
	"		as 'PrepaymentsForDebtors',"+CHAR(10)+
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsTotal,0)) 	ELSE NULL END"+CHAR(10)+
	"		as 'PrepaymentsTotal',"+CHAR(10)+
	"CASE WHEN @pbCanViewPrepayments = 1 THEN SUM(ISNULL(WIP.PrepaymentsOnDraftBill,0)) 	ELSE NULL END"+CHAR(10)+
	"		as 'PrepaymentsOnDraftBill'"+CHAR(10)+
	"from("+CHAR(10)+
	"Select"+CHAR(10)+
	"W.CASEID 	as CASEID,"+CHAR(10)+
	"W.ENTITYNO 	as ENTITYNO,"+CHAR(10)+
	"N.NAME		as EntityName,"+CHAR(10)+
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) <  @nAge0) 		      THEN W.BALANCE ELSE 0 END"+CHAR(10)+
	"		as Bracket0Total,"+CHAR(10)+
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge0 and @nAge1-1) THEN W.BALANCE ELSE 0 END"+CHAR(10)+
	"		as Bracket1Total,"+CHAR(10)+
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) between @nAge1 and @nAge2-1) THEN W.BALANCE ELSE 0 END"+CHAR(10)+
	"		as Bracket2Total,"+CHAR(10)+
	"CASE WHEN(datediff(day,W.TRANSDATE,@dtBaseDate) >= @nAge2) 		      THEN W.BALANCE ELSE 0 END"+CHAR(10)+
	"		as Bracket3Total,"+CHAR(10)+
	"W.BALANCE 	as Total,"+CHAR(10)+
	"null 		as PrepaymentsForCase,"+CHAR(10)+
	"null 		as PrepaymentsForDebtors,"+CHAR(10)+
	"null 		as PrepaymentsTotal,"+CHAR(10)+
	"null 		as PrepaymentsOnDraftBill"+CHAR(10)+
	"from WORKINPROGRESS W"+CHAR(10)+
	"join NAME N 	 	on (N.NAMENO = W.ENTITYNO)"+CHAR(10)+
	"where W.CASEID = @pnCaseKey"+CHAR(10)+
	"and W.STATUS <> 0"+CHAR(10)+
	"UNION ALL"+CHAR(10)+
	"Select"+CHAR(10)+
	"OIC.CASEID,"+CHAR(10)+
	"OIC.ACCTENTITYNO,"+CHAR(10)+
	"PFCN.NAME,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"OIC.LOCALBALANCE,"+CHAR(10)+
	"null,"+CHAR(10)+
	"OIC.LOCALBALANCE,"+CHAR(10)+
	"null as PrepaymentsOnDraftBill"+CHAR(10)+
	"from OPENITEMCASE OIC"+CHAR(10)+
	"join OPENITEM O 	on (O.ITEMENTITYNO = OIC.ITEMENTITYNO"+CHAR(10)+
	"         	     	and O.ITEMTRANSNO  = OIC.ITEMTRANSNO"+CHAR(10)+
	"	 	     	and O.ACCTENTITYNO = OIC.ACCTENTITYNO"+CHAR(10)+
	"	 	     	and O.ACCTDEBTORNO = OIC.ACCTDEBTORNO)"+CHAR(10)+
	"left join NAME PFCN 	on (PFCN.NAMENO = OIC.ACCTENTITYNO)"+CHAR(10)+
	"where OIC.STATUS IN (1, 2)"+CHAR(10)+
	"and O.ITEMTYPE = 523"+CHAR(10)+
	"and OIC.CASEID = @pnCaseKey"+CHAR(10)+
	"UNION ALL"+CHAR(10)+
	"Select"+CHAR(10)+
	"CNN.CASEID,"+CHAR(10)+
	"O.ACCTENTITYNO,"+CHAR(10)+
	"PFDN.NAME,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"CASE WHEN O.PAYPROPERTYTYPE = CNN.PROPERTYTYPE or O.PAYPROPERTYTYPE is null THEN O.LOCALBALANCE ELSE NULL END,"+CHAR(10)+
	"O.LOCALBALANCE,"+CHAR(10)+
	"null"+CHAR(10)+
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
	"UNION ALL"+CHAR(10)+
	"Select"+CHAR(10)+
	"CNN1.CASEID,"+CHAR(10)+
	"BC.CRACCTENTITYNO,"+CHAR(10)+
	"PDBN.NAME,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"null,"+CHAR(10)+
	"BC.LOCALSELECTED"+CHAR(10)+
	"from BILLEDCREDIT BC"+CHAR(10)+
	"join (Select CASEID, NAMENO"+CHAR(10)+
	"      from   CASENAME"+CHAR(10)+
	"      where  CASEID = @pnCaseKey"+CHAR(10)+
	"      and NAMETYPE = 'D'"+CHAR(10)+
	"      and EXPIRYDATE IS NULL) CNN1"+CHAR(10)+
	"			on (CNN1.NAMENO = BC.CRACCTDEBTORNO)"+CHAR(10)+
	"left join NAME PDBN 	on (PDBN.NAMENO = BC.CRACCTENTITYNO)"+CHAR(10)+
	"  ) WIP"+CHAR(10)+
	-- The result sets should only be published if the Work In Progress Items information security topic (120)
	-- is available.
	"where @pbCanViewWorkInProgressItems = 1"+CHAR(10)+
	"group by WIP.CASEID, WIP.ENTITYNO, WIP.EntityName"+CHAR(10)+
	"order by 'EntityName', 'EntityKey'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   	int,
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint,
					  @pbCanViewWorkInProgressItems	bit,
					  @pbCanViewPrepayments		bit',
					  @pnCaseKey	= @pnCaseKey,
					  @dtBaseDate			= @dtBaseDate,
					  @nAge0			= @nAge0,
					  @nAge1			= @nAge1,
					  @nAge2			= @nAge2,
					  @pbCanViewWorkInProgressItems	= @pbCanViewWorkInProgressItems,
					  @pbCanViewPrepayments		= @pbCanViewPrepayments
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
		CT.COUNTRYCODE   as CountryCode,
		"+dbo.fn_SqlTranslatedColumn('COUNTRYFLAGS','FLAGNAME',null,'CF',@sLookupCulture,@pbCalledFromCentura)+	-- Modification 157
		"
			 		as Status,
		RC.CASEID		as RelatedCaseKey,
		RC.IRN			as CaseReference,
		RC.CURRENTOFFICIALNO 	as CurrentOfficialNumber,
		R.ACCEPTANCEDETAILS	as Comments,
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+	-- Modification 157
		"
			 		as CaseStatus,
		R.RELATIONSHIPNO	as SequenceNo,
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
	    G.ASSOCIATEMEMBER as IsExtensionState,
		R.LOGDATETIMESTAMP  as LastModifiedDate,
		CNI.REFERENCENO as InstructorReference,
		CNA.REFERENCENO as AgentReference
	from CASES C
	join RELATEDCASE R		on (R.CASEID = C.CASEID
					and R.RELATIONSHIP = 'DC1')
	left join CASES RC		on (RC.CASEID = R.RELATEDCASEID)
	join COUNTRY CT			on (CT.COUNTRYCODE = isnull(RC.COUNTRYCODE, R.COUNTRYCODE))
	left join CASENAME CNI		on ( R.RELATEDCASEID = CNI.CASEID and CNI.NAMETYPE = 'I')
	left join CASENAME CNA		on ( R.RELATEDCASEID = CNA.CASEID and CNA.NAMETYPE = 'A')
	left join COUNTRYFLAGS CF	on (CF.COUNTRYCODE = C.COUNTRYCODE
					and CF.FLAGNUMBER = R.CURRENTSTATUS)
	left join STATUS S		on (S.STATUSCODE = RC.STATUSCODE)
	left join COUNTRYGROUP G	on (G.MEMBERCOUNTRY = CT.COUNTRYCODE and G.TREATYCODE = C.COUNTRYCODE)
	where C.CASEID=@pnCaseKey
	order by CT.COUNTRYCODE, R.PRIORITYDATE, Class"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
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
		join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture, 0,@pbCalledFromCentura) NT
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
		left join ADDRESS A		on (A.ADDRESSCODE=ISNULL(CN.ADDRESSCODE, N.POSTALADDRESS))
		left join COUNTRY CT		on (CT.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S		on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE=A.STATE)
		-- Attention
		left join NAME N1		on (N1.NAMENO=ISNULL(CN.CORRESPONDNAME, N.MAINCONTACT))
		left join COUNTRY NAT1		on (NAT1.COUNTRYCODE=N1.NATIONALITY)
		where CN.CASEID = @pnCaseKey
		and   CN.EXPIRYDATE IS NULL
		and   CN.NAMETYPE in ('D','CD','Z','ZC')
		-- An empty result set is required if the user does not
		-- have access to the Billing Instructions topic
		and   @pbCanViewBillingInstructions = 1
		order by NT.DESCRIPTION, CN.SEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   		int,
					  @pnUserIdentityId 	int,
					  @sLookupCulture	nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @pbCanViewBillingInstructions bit',
					  @pnCaseKey		= @pnCaseKey,
					  @pnUserIdentityId 	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @pbCanViewBillingInstructions = @pbCanViewBillingInstructions
End

-- OccurredEvents result set
-- where :
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see
If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('OCCURREDEVENTS,', @psResultsetsRequired) <> 0)
Begin
	------------------------------------
	-- Check for a default EventNoteType
	------------------------------------
	If @nDefaultEventNoteType is null
		Set @nDefaultEventNoteType = dbo.fn_GetDefaultEventNoteType(@pnUserIdentityId)

	Set @sSQLString="
	Select	@bEntryFlag=isnull(S.COLBOOLEAN,0),
		@bShowAllEventDates=isnull(S1.COLBOOLEAN,0)
	from SITECONTROL S
	left join SITECONTROL S1 on (S1.CONTROLID='Always Show Event Date')
	where S.CONTROLID='Event Link to Workflow Allowed'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bEntryFlag			bit		OUTPUT,
				  @bShowAllEventDates		bit		OUTPUT',
				  @bEntryFlag    =@bEntryFlag			OUTPUT,
				  @bShowAllEventDates=@bShowAllEventDates	OUTPUT

	Set @sSQLString="
	With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
			as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
					CASE WHEN(ET.EVENTTEXTTYPEID is null)
						THEN '2'
						WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
						THEN '1'
						ELSE '0'
					END
				from CASEEVENTTEXT CT
				join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
				Where CT.CASEID=@pnCaseKey
			)
	Select	CE.CASEID 		as CaseKey,
		dbo.fn_GetTranslation  (CE.EVENTDESCRIPTION, null, CE.EVENTDESCRIPTION_TID, @sLookupCulture) as EventDescription,
		dbo.fn_GetTranslation  (CE.DEFINITION, null, CE.DEFINITION_TID, @sLookupCulture) as EventDefinition,
		CE.EVENTDATE 		as [Date],
		CE.IMPORTANCELEVEL	as ImportanceLevel,
		ET.EVENTTEXT		as EventNotes,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as EventStaff,
		CE.FROMCASEID		as FromCaseKey,
		C.IRN			as FromCaseReference,
		CE.EMPLOYEENO		as ResponsibleNameKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as ResponsibleName,
		NT.DESCRIPTION		as ResponsibleNameType,"

		If @bEntryFlag=0
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		0 as DoesEntryExistForCaseEvent,"
		End
		Else Begin
			Set @sSQLString=@sSQLString+char(10)+"		dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,CE.CASEID,CE.EVENTNO,CE.CYCLE) as DoesEntryExistForCaseEvent,"
		End

		Set @sSQLString=@sSQLString+"
		cast(CE.CASEID 	as varchar(11)) + '^' +
		cast(CE.EVENTNO as varchar(11)) + '^' +
		cast(CE.CYCLE 	as varchar(10))
					as RowKey,
		cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = CE.EVENTNO and A.CYCLE = CE.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments'
	from dbo.fn_GetCaseOccurredDates(@bShowAllEventDates) CE
	-------------------------------------------
	-- The Event Note to return is based on the
	-- following hierarchy:
	-- 1 - No TextType
	-- 2 - Users default Text Type
	-- 3 - Most recently modified text
	-------------------------------------------
	left join CTE_EventText CTE	on (CTE.EVENTNO  =CE.EVENTNO
					and CTE.CYCLE    =CE.CYCLE
					and CTE.EVENTTEXTID = Cast
						     (substring
						      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
							from CTE_EventText CTE1
							where CTE1.EVENTNO  =CTE.EVENTNO
							and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
						)
	left join EVENTTEXT ET		on (ET.EVENTTEXTID = CTE.EVENTTEXTID)
	left join CASES C		on (C.CASEID = CE.FROMCASEID)
	left join NAME N		on (N.NAMENO = CE.EMPLOYEENO)
	left join NAMETYPE NT		on (NT.NAMETYPE = CE.DUEDATERESPNAMETYPE)
	where CE.CASEID = @pnCaseKey
	order by CE.EVENTDATE desc, 2"

	exec sp_executesql @sSQLString,
			N'@pnUserIdentityId	 int,
			  @pnCaseKey		 int,
			  @nDefaultEventNoteType int,
			  @sLocalCurrencyCode	 nvarchar(3),
			  @sLookupCulture	 nvarchar(10),
			  @bShowAllEventDates	 bit',
			  @pnUserIdentityId	 = @pnUserIdentityId,
			  @pnCaseKey		 = @pnCaseKey,
			  @nDefaultEventNoteType = @nDefaultEventNoteType,
			  @sLocalCurrencyCode	 = @sLocalCurrencyCode,
			  @sLookupCulture	 = @sLookupCulture,
			  @bShowAllEventDates	 = @bShowAllEventDates
End

-- DueEvents result set
-- a) the user has access to the Case
-- b) the Event has an importance level that the user is allowed to see

If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('DUEEVENTS,', @psResultsetsRequired) <> 0)
Begin
	------------------------------------
	-- Check for a default EventNoteType
	------------------------------------
	If @nDefaultEventNoteType is null
		Set @nDefaultEventNoteType = dbo.fn_GetDefaultEventNoteType(@pnUserIdentityId)

	Set @sSQLString="
	Select	@sRenewalAction=S1.COLCHARACTER,
		@nOverdueDays  =S2.COLINTEGER
	from SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='Client Due Dates: Overdue Days')
	where S1.CONTROLID='Main Renewal Action'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@sRenewalAction	nvarchar(2)	OUTPUT,
				  @nOverdueDays		int		OUTPUT',
				  @sRenewalAction=@sRenewalAction	OUTPUT,
				  @nOverdueDays  =@nOverdueDays		OUTPUT

	---------------------------------------------------
	-- If the user is external then determine the date
	-- from which due dates are allowed to be displayed
	-- by subtracting the OverdueDays from todays
	---------------------------------------------------
	If  @nErrorCode = 0
	and @nOverdueDays is not null
	and @bIsExternalUser = 1
	begin
		Set @dtOverdueRangeFrom = convert(nvarchar,dateadd(Day, @nOverdueDays*-1, getdate()),112)
	end

	If @nErrorCode=0
	Begin
		Set @sSQLString="
		With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
				as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
						CASE WHEN(ET.EVENTTEXTTYPEID is null)
							THEN '2'
						     WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
							THEN '1'
							ELSE '0'
						END
					from CASEEVENTTEXT CT
					join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
					Where CT.CASEID=@pnCaseKey
				)
		Select
		CE.CASEID 	as CaseKey,
		dbo.fn_GetTranslation  (CE.EVENTDESCRIPTION, null, CE.EVENTDESCRIPTION_TID, @sLookupCulture) as EventDescription,
		dbo.fn_GetTranslation  (CE.DEFINITION, null, CE.DEFINITION_TID, @sLookupCulture) as EventDefinition,
		CE.EVENTDUEDATE 	as [Date],
		CE.IMPORTANCELEVEL	as ImportanceLevel,
		ET.EVENTTEXT		as EventNotes,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as EventStaff,
		CE.FROMCASEID		as FromCaseKey,
		C.IRN			as FromCaseReference,
		CE.EMPLOYEENO		as ResponsibleNameKey,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
					as ResponsibleName,
		NT.DESCRIPTION		as ResponsibleNameType,"

		If @bEntryFlag=0
		Begin
			Set @sSQLString=@sSQLString+char(10)+"		0 as DoesEntryExistForCaseEvent,"
		End
		Else Begin
			Set @sSQLString=@sSQLString+char(10)+"		dbo.fn_DoesEntryExistForCaseEvent(@pnUserIdentityId,CE.CASEID,CE.EVENTNO,CE.CYCLE) as DoesEntryExistForCaseEvent,"
		End

		Set @sSQLString=@sSQLString+"
		cast(CE.CASEID 	as varchar(11)) + '^' +
		cast(CE.EVENTNO as varchar(11)) + '^' +
		cast(CE.CYCLE 	as varchar(10))
					as RowKey,
		cast (case when exists (select 1 from ACTIVITY A where A.EVENTNO = CE.EVENTNO and A.CYCLE = CE.CYCLE and A.CASEID = @pnCaseKey) then 1 else 0 end as bit) as 'HasAttachments',
		cast(case when (CE.EVENTDUEDATE < getdate()) then 1 else 0 end as bit) as 'IsDueDatePast'
		from dbo.fn_GetCaseDueDates() CE
		-------------------------------------------
		-- The Event Note to return is based on the
		-- following hierarchy:
		-- 1 - No TextType
		-- 2 - Users default Text Type
		-- 3 - Most recently modified text
		-------------------------------------------
		left join CTE_EventText CTE	on (CTE.EVENTNO  =CE.EVENTNO
						and CTE.CYCLE    =CE.CYCLE
						and CTE.EVENTTEXTID = Cast
							     (substring
							      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
								from CTE_EventText CTE1
								where CTE1.EVENTNO  =CTE.EVENTNO
								and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
							)
		left join EVENTTEXT ET		on (ET.EVENTTEXTID = CTE.EVENTTEXTID)
		left join CASES C		on (C.CASEID = CE.FROMCASEID)
		left join NAME N		on (N.NAMENO = CE.EMPLOYEENO)
		left join NAMETYPE NT		on (NT.NAMETYPE = CE.DUEDATERESPNAMETYPE)
		where	CE.CASEID = @pnCaseKey
		and (CE.EVENTDUEDATE>=@dtOverdueRangeFrom OR @dtOverdueRangeFrom is null)
		order by CE.EVENTDUEDATE, 2"

		exec sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					 @pnCaseKey		int,
					 @nDefaultEventNoteType int,
					 @sLocalCurrencyCode	nvarchar(3),
					 @sRenewalAction	nvarchar(2),
					 @sLookupCulture	nvarchar(10),
					 @dtOverdueRangeFrom	datetime',
					 @pnUserIdentityId	= @pnUserIdentityId,
					 @pnCaseKey		= @pnCaseKey,
					 @nDefaultEventNoteType = @nDefaultEventNoteType,
					 @sLocalCurrencyCode	= @sLocalCurrencyCode,
					 @sRenewalAction	= @sRenewalAction,
					 @sLookupCulture	= @sLookupCulture,
					 @dtOverdueRangeFrom	= @dtOverdueRangeFrom
	End
End

-- RenewalInstructions, RenewalNames, RenewalDetails result sets
If @nErrorCode=0
and (   @psResultsetsRequired = ','
     or CHARINDEX('RENEWALINSTRUCTIONS,', @psResultsetsRequired) <> 0
     or CHARINDEX('RENEWALNAMES,', @psResultsetsRequired) <> 0
     or CHARINDEX('RENEWALDETAILS,', @psResultsetsRequired) <> 0
     or CHARINDEX('RENEWALDATES',@psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_GetCaseRenewalDetails
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pbExternalUser		= 0,
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
		@pbIsExternalUser	= 0,
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
				@pnCaseKey		= @pnCaseKey,
			  	@pbIsExternalUser	= 0,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@psResultsetsRequired	= @psResultsetsRequired
End

-- Attributes result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('ATTRIBUTE,', @psResultsetsRequired) <> 0)
Begin
	Set @sGenericKey = cast(@pnCaseKey as nvarchar(20))

	exec @nErrorCode = dbo.ipw_ListTableAttributes
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@psParentTable	  = 'CASES',
					@psGenericKey	  = @sGenericKey,
					@pbIsExternalUser = 0
End

-- OfficialNumber result set
If @nErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('OFFICIALNUMBER,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListOfficialNumber
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @sLookupCulture,
					@pnCaseKey		= @pnCaseKey,
				  	@pbIsExternalUser	= 0,
					@pbCalledFromCentura	= @pbCalledFromCentura
End

-- KeyWord result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('KEYWORD,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListKeyWord
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pnCaseKey		= @pnCaseKey,
		@pbCalledFromCentura	= @pbCalledFromCentura
End

-- StandingInstruction result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('STANDINGINSTRUCTION,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_GetStandingInstructions
		@pnCaseKey		= @pnCaseKey,
		@psCulture		= @sLookupCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pbIsExternalUser	= 0
End

-- FirstUse result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('FIRSTUSE,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListFirstUse
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @pnCaseKey,
					@pbIsExternalUser = 0,
					@pbCalledFromCentura=@pbCalledFromCentura
End

-- Journal result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('JOURNAL,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListJournal
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @pnCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura
End

-- Prior Art result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('PRIORART,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListSearchResult
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @pnCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura
End

-- Assigned Cases result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('ASSIGNEDCASES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListAssignedCases
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @pnCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura
End

-- Assigned Cases Change Of Owner result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('ASSIGNORS,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListAssignors
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @pnCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura
End

If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('ASSIGNEES,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListAssignees
					@pnUserIdentityId = @pnUserIdentityId,
			      	 	@psCulture 	  = @sLookupCulture,
					@pnCaseKey	  = @pnCaseKey,
					@pbCalledFromCentura=@pbCalledFromCentura
End
-- Patent Term Adjustments result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('PTAEVENT,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.cs_GetPTA
		@pnCaseId		= @pnCaseKey,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbIsExternalUser	= 0,
		@psCulture		= @sLookupCulture
End

-- Patent Design Element result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('DESIGNELEMENT,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListDesignElement
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pnCaseKey		= @pnCaseKey,
		@pbCalledFromCentura	= @pbCalledFromCentura
End

-- CaseList result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASELIST,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString="
	Select	  cast(CLM.CASELISTNO as nvarchar(11)) + '^'
		+ cast(CLM.CASEID as nvarchar(11))
				as RowKey,
		CLM.CASEID	as CaseKey,
		CL.CASELISTNO	as CaseListKey,
		"+dbo.fn_SqlTranslatedColumn('CASELIST','CASELISTNAME',null,'CL',@sLookupCulture,@pbCalledFromCentura)
			     +" as CaseListName,
		CAST(CLM.PRIMECASE as bit)
				as ThisIsPrimeCase
	FROM CASELISTMEMBER CLM
	JOIN CASELIST CL ON (CLM.CASELISTNO = CL.CASELISTNO)
	WHERE CLM.CASEID = @pnCaseKey
	ORDER BY ThisIsPrimeCase DESC, CaseListName"

	exec sp_executesql @sSQLString,
				N'@pnCaseKey		int',
				  @pnCaseKey		= @pnCaseKey
End

-- ComparisonSystem result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('COMPARISONSYSTEM,', @psResultsetsRequired) <> 0)
Begin
	exec @nErrorCode = dbo.csw_ListComparisonSystem
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pnCaseKey		= @pnCaseKey,
		@pbIsExternalUser	= 0,
		@pbCalledFromCentura	= @pbCalledFromCentura
End

-- CaseBilling result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASEBILLING,', @psResultsetsRequired) <> 0)
Begin

	Set @sSQLString =
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"C.IRN as CaseReference,"+char(10)+
	"@sLocalCurrencyCode as LocalCurrencyCode,"+char(10)+
	"@nLocalDecimalPlaces as LocalDecimalPlaces"+char(10)+
	"from CASES C"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 		int,
					  @sLocalCurrencyCode		nvarchar(3),
					  @nLocalDecimalPlaces		tinyint',
					  @pnCaseKey		 		= @pnCaseKey,
					  @sLocalCurrencyCode		= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces		= @nLocalDecimalPlaces
End

-- Billing result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('BILLING,', @psResultsetsRequired) <> 0)
Begin
	If @pbCanViewBillingHistory = 1
	Begin
		Set @nBillingCaseKey = @pnCaseKey
	End

	exec @nErrorCode = dbo.cs_GetBudgetDetails
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @sLookupCulture,
		@pnCaseId		= @nBillingCaseKey,
		@pnOrderBy		= null,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pbTotalsFromCase	= 1,
		@pbHasBillingHistorySubject = @pbCanViewBillingHistory
End

-- CaseWIP result set
If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASEWIP,', @psResultsetsRequired) <> 0)
Begin

	Set @sSQLString =
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"@sLocalCurrencyCode as LocalCurrencyCode,"+char(10)+
	"@nLocalDecimalPlaces as LocalDecimalPlaces"+char(10)+
	"from CASES C"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 		int,
					  @sLocalCurrencyCode		nvarchar(3),
					  @nLocalDecimalPlaces		tinyint',
					  @pnCaseKey		 		= @pnCaseKey,
					  @sLocalCurrencyCode		= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces		= @nLocalDecimalPlaces
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
			       CASE
				 WHEN CT.TEXTTYPE <> 'G'
				      AND CT.LANGUAGE IS NULL THEN NULL
				 ELSE 'G'
			       END			AS TextType,
			       CF.FIRSTUSE              AS FirstUseDate,
			       CF.FIRSTUSEINCOMMERCE    AS FirstUseInCommerceDate,
				  CASE WHEN CTE.TEXTNO is null THEN null
						Else Isnull(convert(nvarchar(max),"+ dbo.fn_SqlTranslatedColumn('CASETEXT',null,'TEXT','CT',@sLookupCulture,@pbCalledFromCentura)+"), convert(nvarchar(max),"
						     + dbo.fn_SqlTranslatedColumn('CASETEXT','SHORTTEXT',null,'CT',@sLookupCulture,@pbCalledFromCentura)+")) END
			              AS [Text]," +
			       dbo.fn_SqlTranslatedColumn('TMCLASS','CLASSHEADING',null,'CL',@sLookupCulture,@pbCalledFromCentura) +" AS ClassHeading,
			       C.COUNTRYCODE + '^' + CL.CLASS + '^' + CL.PROPERTYTYPE + '^' + Cast(CL.SEQUENCENO AS NVARCHAR(15)) AS RowKey,
			       CTE.INDEFAULTLANGUAGE,
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
		       CASE
			 WHEN CT.TEXTTYPE <> 'G'
			      AND CT.LANGUAGE IS NULL THEN NULL
			 ELSE 'G'
		       END              AS TextType,
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

-- Prepare the variables to be used fo RecentActivityTotal, RecentActivity, ActivityByContact and ActivityByCategory result sets
If @nErrorCode = 0
and (@psResultsetsRequired = ','
	or 	(CHARINDEX(',RECENTACTIVITYTOTAL,', @sNameBasedResultsets) <> 0
	or	CHARINDEX(',RECENTACTIVITY,', @sNameBasedResultsets) <> 0
	or 	CHARINDEX(',ACTIVITYBYCONTACT,', @sNameBasedResultsets) <> 0
	or	CHARINDEX(',ACTIVITYBYCATEGORY,', @sNameBasedResultsets) <> 0
	or	CHARINDEX(',CONTACTACTIVITYNAMES,', @sNameBasedResultsets) <> 0))
Begin
	Set @sSQLString =  "
		Select	@nProspectKey = Prospect.NAMENO,
				@nLeadKey = Lead.NAMENO
		from CASENAME Prospect
		left join CASENAME Lead on (Lead.CASEID = @pnCaseKey
								and Lead.NAMETYPE = '~LD'
								and Lead.SEQUENCE = (select min(Lead2.SEQUENCE)
														from CASENAME Lead2
														where Lead2.CASEID = @pnCaseKey
														and Lead2.NAMETYPE = '~LD'))
		where Prospect.CASEID = @pnCaseKey
		and Prospect.NAMETYPE ='~PR'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'
						@nProspectKey	int output,
						@nLeadKey		int output,
						@pnCaseKey		int',
						@nProspectKey	= @nProspectKey output,
						@nLeadKey		= @nLeadKey output,
						@pnCaseKey		= @pnCaseKey
End

If @nErrorCode = 0
and (@psResultsetsRequired = ','
	or 	(CHARINDEX(',CONTACTACTIVITYNAMES,', @sNameBasedResultsets) <> 0))
Begin
	Set @sSQLString =  "
		Select	@pnCaseKey as CaseKey,
				@nProspectKey as ProspectKey,
				@nLeadKey as LeadKey,
				CASE WHEN NPR.USEDASFLAG&4=4 THEN 1 ELSE 0 END as ProspectIsClient
		from CASES
		join NAME NPR on (NPR.NAMENO = @nProspectKey)
		where CASEID=@pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnCaseKey		int,
						@nProspectKey	int,
						@nLeadKey		int',
						@pnCaseKey		= @pnCaseKey,
						@nProspectKey	= @nProspectKey,
						@nLeadKey		= @nLeadKey

End

-- Populating RecentActivityTotal and RecentActivity result sets
If @nErrorCode = 0
and (@psResultsetsRequired = ','
	or 	(CHARINDEX(',RECENTACTIVITYTOTAL,', @sNameBasedResultsets) <> 0
	or	CHARINDEX(',RECENTACTIVITY,', @sNameBasedResultsets) <> 0))
Begin
	if(@sCaseTypeKey <> 'O')
	Begin
		Set @nActivityCaseKey = @pnCaseKey
	End
	exec @nErrorCode = dbo.naw_ListRecentActivity
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @sLookupCulture,
					@pnNameKey		= @nLeadKey,
					@pnOrganisationKey	= @nProspectKey,
					@pnCaseKey		= @nActivityCaseKey,
					@pnTopRowCount		= 5,			-- Shows the 5 most recent contacts
					@pbCalledFromCentura	= @pbCalledFromCentura,
					@psResultsetsRequired	= @sNameBasedResultsets
End

-- Populating ActivityByContact and ActivityByCategory result sets
If @nErrorCode = 0
and (@psResultsetsRequired = ','
	or 	(CHARINDEX(',ACTIVITYBYCONTACT,', @sNameBasedResultsets) <> 0
	or	CHARINDEX(',ACTIVITYBYCATEGORY,', @sNameBasedResultsets) <> 0))
Begin
	if(@sCaseTypeKey <> 'O')
	Begin
		Set @nActivityCaseKey = @pnCaseKey
	End
	exec @nErrorCode = dbo.naw_ListActivitySummary
					@pnUserIdentityId	= @pnUserIdentityId,
					@psCulture		= @sLookupCulture,
					@pnNameKey		= @nLeadKey,
					@pnCaseKey		= @nActivityCaseKey,
					@pnOrganisationKey	= @nProspectKey,
					@pbCanViewContactActivities	= @pbCanViewContactActivities,
					@pbCalledFromCentura	= @pbCalledFromCentura,
					@psResultsetsRequired	= @sNameBasedResultsets
End

If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('OPPORTUNITYDETAIL,', @psResultsetsRequired) <> 0))
Begin
	if (@sCaseTypeKey = 'O' and @sPropertyTypeKey = (select COLCHARACTER from SITECONTROL where CONTROLID = 'Property Type Opportunity'))
	Begin
		exec @nErrorCode = dbo.crm_FetchOpportunityDetail
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey
	End
End

If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CRMCASESTATUSHISTORY,', @psResultsetsRequired) <> 0))
Begin
	exec @nErrorCode = dbo.crm_ListCRMCaseStatusHistory
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey
End

If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CASENAMECONTACTDETAIL', @psResultsetsRequired) <> 0))
Begin

	declare @sNameType nvarchar(3)
	-- this doesn't work at the moment because the ContactDetail topic automatically calls
	-- the stored proc on its own without a parameter.
/*
	declare @nStartPosition int
	declare @nEndCommaPosition int
	declare @sTempNameTypeString nvarchar(4)

	-- start position of the name type
	set @nStartPosition = CHARINDEX('CASENAMECONTACTDETAIL',@psResultSetsRequired) + 21
	-- name type string and then some
	set @sTempNameTypeString = substring(@psResultSetsRequired, @nStartPosition, 4)
	-- position of comma after name type
	set @nEndCommaPosition = CHARINDEX(',',@sTempNameTypeString)
	-- only set the name type if one has been passed
	if @nEndCommaPosition > 1
	Begin
		set @sNameType = substring(@sTempNameTypeString, 1, @nEndCommaPosition)
	End
*/
	set @sNameType = '~LD'

	exec @nErrorCode = dbo.csw_ListCaseNameContactDetails
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey,
					@psNameType=@sNameType
End

If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('CRMDATES,', @psResultsetsRequired) <> 0))
Begin
	exec @nErrorCode = dbo.crm_ListCRMDates
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey
End

If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('MARKETINGDETAIL,', @psResultsetsRequired) <> 0))
Begin

	set @sSQLString = "select @sCaseTypeKey = CASETYPE,
			@sPropertyTypeKey = PROPERTYTYPE
			from CASES where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@pnCaseKey	int,
						@sCaseTypeKey	nchar(1) output,
						@sPropertyTypeKey nchar(1) output',
						@pnCaseKey		= @pnCaseKey,
						@sCaseTypeKey		= @sCaseTypeKey output,
						@sPropertyTypeKey	= @sPropertyTypeKey output

	if (@sCaseTypeKey = 'M')
	Begin
		exec @nErrorCode = dbo.crm_FetchMarketingDetail
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey
	End
End

-- Populating Checklist and ChecklistInfo result sets
If @nErrorCode = 0
and (@psResultsetsRequired = ','
	or	CHARINDEX('CHECKLISTINFO,', @psResultsetsRequired) <> 0)
Begin

	-- Determine default checklist type if not provided
	-- With WorkBenches screen control rule, it will not be possible to
	-- assign multiple frmCheckList to the rule.  Instead, all valid checklists
	-- for the case will be available for selection.
	-- This will choose the first one in the list.
	Set @sSQLString = "
	Select top 1 @nChecklistType = VCL.CHECKLISTTYPE,
				@sValidChecklistDescription = "+dbo.fn_SqlTranslatedColumn('VALIDCHECKLISTS','CHECKLISTDESC',null,'VCL',@sLookupCulture,@pbCalledFromCentura)
	+" from CASES C
	join VALIDCHECKLISTS VCL on (VCL.PROPERTYTYPE	= C.PROPERTYTYPE
							and VCL.CASETYPE	= C.CASETYPE
							and VCL.COUNTRYCODE=(
											select min(VCL1.COUNTRYCODE)
											from VALIDCHECKLISTS VCL1
											where VCL1.PROPERTYTYPE=C.PROPERTYTYPE
											and VCL1.CASETYPE     = C.CASETYPE
											and VCL1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
	where C.CASEID = @pnCaseKey"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'	@sValidChecklistDescription 	nvarchar(50) OUTPUT,
					@nChecklistType			int			OUTPUT,
					@pnCaseKey				int',
					@sValidChecklistDescription 	= @sValidChecklistDescription OUTPUT,
					@nChecklistType			= @nChecklistType	OUTPUT,
					@pnCaseKey				= @pnCaseKey

	If @nErrorCode = 0
	Begin
		-- SQA9421 product code to be returned
		Set @sSQLString = "SELECT "+ char(10)+
			+"@pnCaseKey				as RowKey,"+char(10)
			+"@pnCaseKey				as CaseKey," + char(10)
			+"@nChecklistType			as ChecklistTypeKey," + char(10)
			+"isnull(@sValidChecklistDescription,"
			+dbo.fn_SqlTranslatedColumn('CHECKLISTS','CHECKLISTDESC',null,'CLT',@sLookupCulture,@pbCalledFromCentura)
				+ ") as 'ChecklistTypeDescription'," + char(10)
			+"ISNULL(SC.COLBOOLEAN,1)	as ProcessChecklist," + char(10)
			+"C.PRODUCTCODE			as ProductCode
		FROM CHECKLISTS CLT
		LEFT JOIN SITECONTROL SC on (SC.CONTROLID = 'Process Checklist')
		LEFT JOIN SITECONTROL SCProdCode on (SCProdCode.CONTROLID = 'Product Recorded on WIP')
		LEFT JOIN CRITERIA C on (SCProdCode.COLBOOLEAN = 1
			and C.CRITERIANO = dbo.fn_GetCriteriaNo(@pnCaseKey, 'C', @nChecklistType, null, @nProfileKey))
		WHERE CLT.CHECKLISTTYPE = @nChecklistType"

		exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnCaseKey		 		int,
							  @nChecklistType			int,
							  @sValidChecklistDescription nvarchar(50),
							  @nProfileKey                          int',
							  @pnCaseKey		 		= @pnCaseKey,
							  @nChecklistType			= @nChecklistType,
							  @sValidChecklistDescription = @sValidChecklistDescription,
							  @nProfileKey                          = @nProfileKey
	End
End


If (@nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('ADHOCDATES,', @psResultsetsRequired) <> 0))
Begin
	exec @nErrorCode = dbo.csw_ListCaseAdHocDates
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey
End

If @nErrorCode = 0
and (@psResultsetsRequired = ',' or CHARINDEX('ACTUALRESPONSE,', @psResultsetsRequired) <> 0)
Begin
	Set @sSQLString = "Select isnull(CN.RowKey,TC.TABLECODE)+ '^'
	+ cast(TC.TABLETYPE as nvarchar(11))  as RowKey, CN.CaseKey as CaseKey,
	TC.DESCRIPTION As Description, isnull(CN.RESPONSE,0) As Response
	FROM TABLECODES TC
	LEFT JOIN
	(SELECT COUNT (*) AS RESPONSE, CORRESPRECEIVED, CAST(CASEID as nvarchar(11)) as RowKey, CASEID as CaseKey FROM CASENAME
	WHERE CASEID = @pnCaseKey
	and NAMETYPE = '~CN'
	GROUP BY CORRESPRECEIVED, CASEID) AS CN
	ON (TC.TABLECODE = CN.CORRESPRECEIVED) WHERE TABLETYPE=153 Order By RESPONSE DESC"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			    @pnCaseKey		int',
			    @pnCaseKey	 = @pnCaseKey
END

If @nErrorCode = 0
and (@psResultsetsRequired = ',' OR CHARINDEX('CASENAMETEXT,', @psResultsetsRequired) <> 0)
Begin
	if (@nScreenCriteriaKey is null)
	begin
		Set @nScreenCriteriaKey = dbo.fn_GetCaseScreenCriteriaKey(@pnCaseKey, 'W', @psProgramKey, @nProfileKey)
	End
	exec @nErrorCode = dbo.csw_ListCaseNameText
					@pnUserIdentityId=@pnUserIdentityId,
					@psCulture=@sLookupCulture,
					@pbCalledFromCentura=@pbCalledFromCentura,
					@pnCaseKey=@pnCaseKey,
					@pnScreenCriteriaKey=@nScreenCriteriaKey
End

-- Update any Quick Indexes for the current user to reflect the fact that a database table has been accessed:
If @nErrorCode=0
Begin
	exec @nErrorCode = dbo.ip_RegisterAccess
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psDatabaseTable	= 'CASES',
		@pnIntegerKey		= @pnCaseKey
End



Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseDetail to public
GO
