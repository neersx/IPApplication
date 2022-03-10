-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ConstructCaseWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ConstructCaseWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ConstructCaseWhere.'
	Drop procedure [dbo].[csw_ConstructCaseWhere]
End
Print '**** Creating Stored Procedure dbo.csw_ConstructCaseWhere...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[csw_ConstructCaseWhere]
(
	@psReturnClause			nvarchar(max)  = null output, -- variable to hold the constructed "where" clause
	@pnUserIdentityId		int		= null, -- RFC463. @pnUserIdentityId must accept null (when called from InPro)
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterCriteria		nvarchar(max)	= null,	-- The filtering to be performed on the result set.
	@pnFilterGroupIndex		tinyint		= null,  -- The FilterCriteriaGroup node number.
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)
AS
-- PROCEDURE:	csw_ConstructCaseWhere
-- VERSION:	204
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Cases and
--		constructs a JOIN and WHERE clause.
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number  Version	Change
-- ------------	-------	-------	-------	-----------------------------------------------
-- 27 Oct 2003  TM	RFC537	1	Procedure created based on v2 of fnw_FilterCases.
-- 30-Oct-2003	TM	RFC495	2	Subset site control implementation with patindex. Enhance the
--					existing logic that implements patindex to find the matching item
--					in the following manner:
--					before change: "and patindex('%'+XCL.NAMETYPE+'%',XS.COLCHARACTER)>0"
--					after change:  "where patindex('%'+','+XCL.NAMETYPE+','+'%',',' +
--								       replace(XS.COLCHARACTER, ' ', '') + ',')>0
-- 31-Oct-2003	TM		3	Implement "Any Search" as XML.
-- 11-Nov-2003	TM	RFC509	4	Implement XML parameters in Case Search.
-- 19-Nov-2003	TM	RFC509	5	Implement Julie's feedback.
-- 24-Nov-2003	TM	RFC509	6	Rename the csw_FilterCases to csw_ConstructCaseWhere. Cater for situation
--					when there is no FilterCriteria.
-- 28-Nov-2003	JEK	RFC509	7	Syntax error in sounds like logic.
-- 02-Dec-2003	JEK	RFC509	8	Allow like for lists of classes.
-- 04-Dec-2003	JEK	RFC509	9	Event data range not extracted from XML.
-- 29 Dec 2003	TM	RFC781	10	Correct the XML path to count the FilterCriteria instead of the FilterCriteriaGroup.
-- 27-Jan-2004	TM	RFC853	11	Remove function dbo.fn_WrapQuotes from the 'If @sStatusFlag is not null...' statement.
-- 04-Feb-2004	TM	RFC642	12	RFC642 Case Advanced Filter continued.  New filter criteria for IncludeClosedActions,
--					Attribute BooleanOr, RenewalStatus, HasIncompletePolicing, PatentTermAdjustments.
-- 19-Feb-2004	TM	RFC976	13	Add @pbCalledFromCentura bit parameter and pass it to the relevant functions.
-- 04-Feb-2004	TM	RFC1032	14	Pass @pnCaseKey as the @pnCaseKey to the fn_FilterUserCases.
-- 08-Mar-2004	TM	RFC934	15	Modify implementation of fn_FilterUserEvents to apply for external users only.
-- 08-Mar-2004	TM	RFC1127	16	Remove the CPA Inprostart row level security. Implement InPro client/server row level
--					security activated if the stored procedure has been called with @pbCalledFromCentura = 1.
-- 10-Mar-2004	TM	RFC1045	17	When both Letters and Charges are selected use OR search instead of AND.
-- 16-Mar-2004	MF	RFC928	18	Ensure that the entire Text column is considered in a search rather than just the
--					first 256 characters.  This can be achieved by ensuring that ISNULL checks TEXT
--					before SHORTTEXT as the length of the first column used in an ISNULL is then
--					used as a mask for the second column.
-- 17-Mar-2004	MF	SQA9689	19	Additional filter parameters for CaseEvents.
-- 23-Mar-2004	MF	SQA9279	20	Provide filtering on CaseList and/or Cases marked as a prime Case on a Case List.
-- 23-Mar-2004	MF	SQA9839	21	Correction to Operator 3 and 4 for Classes.
-- 05-May-2004	TM	RFC1353	22	Allow the Case Search Name Reference filter for Any Name Type for Exist or Not Exist.
-- 25-May-2004	MF	SQA10089 23	For row level security purposes get the userid from the USERS table using
--					the @pnUserIdentityId
-- 11-Jun-2004	TM	RFC1007	24	Modify the logic processing the CaseTextGroup filter criteria to be able to search
--					on text without specifying the text type.
-- 15-Jun-2004	TM	RFC1007	25	Implement 'Exists' and 'Not Exists' operators in the CaseText Filter criteria.
-- 13-Jul-2004	MF	SQA10272 26	Pass the DEFAULT parameter to fn_FilterUserNameTypes if the user is not known
--					to be internal or external.  This will avoid a SQL error.
-- 29-Jul-2004	MF	SQA10332 27	Remove the UPPER function with IRN.  The IRN is always stored as upper case and
--					the use of this function causes problem with index selection.  Also remove against
--					KEYWORD as it is also exclusively stored in upper case.
-- 23-Jun-2004	MF	SQA6395 26	A KEYWORD search should also consider the synonymns defined for the keyword and
--					return the Cases attached to the Synonym.
-- 07-Jul-2004	TM	RFC1230	27	Ensure that the procedures only process the contents of the <csw_ListCase>
--					node and that the node is processed whether it is the root node for the
--					@ptXMLFilterCriteria or not. Implement new ActionKey filter criterion.
-- 16-Jul-2004	TM	RFC1641	27	Extract the @pbIsExternalUser from UserIdentity if it has not been supplied.
-- 23-Jul-2004	TM	RFC1610	29	Increase the datasize of the @sReferenceNo and @sClientReference variables from
--					nvarchar(50) to nvarchar(80). Use 'upper' when filtering on the @sReferenceNo.
-- 25-Aug-2004	JEK	RFC1717	30	Replace fn_FilterUser... joins with additional where clause;e.g. CASETYPE in ('A', 'B',etc.)
--					to improve performance with row level security.
-- 02 Sep 2004	JEK	RFC1377	31	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 09 Sep 2004	JEK	RFC886	32	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 13 Sep 2004	JEK	RFC886	33	Implement fn_WrapQuotes for @psCulture.
-- 16 Sep 2004	JEK	RFC886	34	Handle null @psCulture.  Culture is only required for FilterUser functions when translation is relevant.
-- 17 Sep 2004	TM	RFC886	35	Implement translation.
-- 27 Sep 2004	MF	RFC1846	36	The Next Renewal Due Date (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 13 Oct 2004	MF	SQA10463 37	Additional filter parameters for NameVariant.
-- 26 Oct 2004	MF	SQA10589 38	Performance problem using row level security where Cases have multiple offices.
--					Code was modified to move LEFT JOIN to TABLEATTRIBUTES into a subselect.
-- 01 Dec 2004	MF	SQA10755 39	If NAMETYPE is used as a filter without a Name it is being ignored.
-- 17 Dec 2004	TM	RFC1674	 40	Remove the UPPER function around the KeyWord to improve performance.
-- 10 Jan 2005	MF	SQA10442 41	A new filter option to allow searching by International Class is to be provided.
-- 14 Jan 2005	MF	SQA10868 42	Coding error is not correctly checking the OPENACTION is open when searching by
--					due date.
-- 20 Jan 2005	MF	SQA10904 43	Revisit 10442.  Need to make JOIN to CASETEXT a LEFT JOIN as the Local Class
--					does not need to exist if the search also is by International Class.
-- 11 Jan 2005	TM	RFC1533	 44	New NameGroup filter criteria.
-- 14 Feb 2005	MF	SQA11144 45	Filter is generating invalid SQL when the Classes Operator is set to Starts
--					With (2) but no starting value is provided.
-- 15 Mar 2005	TM	RFC1896	 46	Add new CaseNameFromCase filter criteria.
-- 22 Mar 2005	MF	SQA11187 47	Allow the special processing of Next Renewal Date (-11) seaches to be suppressed
--					by a sitecontrol.  Currently the Next Renewal forces the action determined by the
--					"Main Renewal Action" sitecontrol to be open.
-- 07 Apr 2005	MF	RFC2518	 48	Rework of RFC1533.  The loading of the @tblCaseNameGroup table variable
--					needs to be split into two separate OPEN XML statements.
-- 15 May 2005	JEK	RFC2508	49	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 18 May 2005	TM	RFC2582	50 	Correct the CaseNameFromCase filtering logic.
-- 05 Jul 2005	TM	RFC2794	51	New IncludeExpired attribute for case names.
-- 07 Jul 2005  TM	RFC2330	52	Increase the size of all case category parameters and local variables to 2 characters.
-- 01 Sep 2005	MF	SQA11820 53	Allow filtering on CPA Batch No and also a flag that indicates the Case is to be
--					extracted in the next CPA Batch.
-- 26 Oct 2005	TM	RFC2177	54	Correct local/international classes filtering logic.
-- 28 Oct 2005	TM	RFC2177	55	Correct 'Exists' and 'Not Exists' operator logic when both local and international classes selected.
-- 14 Dec 2005	TM	RFC2483	56	Add new standing instruction filter criteria.
-- 09 Jan 2006	MF	SQA12186 57	When Instruction or Instruction Flags are combined with the NOT operator then
--					the result should return Cases that do have a Standinging Instruction of the
--					same Instruction Type but not the actual value.
-- 18 Jan 2006	DL	SQA10635 58	Add new attribute IsCurrentUser.
-- 20 Feb 2006	TM	RFC3535	59	Implement Exists/Not Exists operators for not inherited standing instructions.
-- 29 Mar 2006	SW	RFC3220	60	Extend to handle the new operators Starts with and Contains for case name search
-- 23 Jun 2006	MF	SQA12337 61	New search parameters to find Cases where Name has been inherited
-- 27 Jun 2006	DR	SQA12337 62	Fix syntax error in CN_INH.INHERITEDNAMENO where clause.
-- 24 Jul 2006	MF	SQA13095 63	Revisit of 12337 change.
-- 13 Sep 2006	SF	RFC1240	64	Optionally suppress dead cases for external users
-- 01 Nov 2006	SW	RFC4607	65	Fix case filtering for Staff or Signatory names and Is Myself not working
-- 02 Nov 2006	SF	RFC4555	66	Allow multiple property types and case category search
-- 13 Dec 2006	JEK	RFC2984	67	Allow filtering on multiple renewal statuses
-- 08 Feb 2007	MF	RFC2982	68	General performance improvement during implementation of this modification
--					resulted in using the CREATEDBYACTION to find OpenAction instead of the
--					more theoretically correct EVENTCONTROL approach.
-- 03 Mar 2007	MF	SQA14490 69	Search by country including designated country was not returning Cases where
--					the Country was included within a group country that does not require explicit
--					designations.
-- 29 Mar 2007	SW	RFC4671	 70	Additional filters required for WIP Overview Screen.
-- 05 Apr 2007	DL 	SQA12427 71	Add new filters IncludeDraftCase, EDEDataSource, EDEBatchIdentifier, AuditSessionNumber
-- 26 Apr 2007	DL 	SQA12427 72 	Fix syntax error bug.
-- 04 Jun 2007	SW	RFC5481	 73	Exclude draft cases from quick search
-- 18 Oct 2007	MF	SQA15487 74	Allow multiple EventNos to be passed and used in the filter.  Return Cases if
--					any of the EventNos match on the case.
-- 23 Oct 2007	MF	SQA15487 75	Increase the size of the field that holds the comma separated list of Events.
-- 23 Oct 2007	MF	SQA14013 75	If filter is on TextType only then all Cases were being returned.
-- 21 Dec 2007	MF	SQA12586 76	Extend Case queries to cater for Events that have been associated with a
--					specific Name and or Name Type.
-- 16 Jan 2008	MF	SQA15824 76	If search of Attention Name is included in a query that is also searching for
--					a specific Instructor, then ensure the search is where the Attention is against
--					the Instructor.
-- 11 Feb 2008	MF	RFC6191	74	CASEINDEXES.GENERICINDEX is now stored as Upper Case so no need to convert to UPPER for search.
-- 30 May 2008	MF	SQA16431 77	Allow search of cases that have outstanding global name changes.
-- 07 Aug 2008	MF	SQA16802 78	Searching by Official Number are running slowly on very large database.  Remove the use of UPPER
--					and rely on the database being either Case Insensitive or the search being entered accurately.
-- 11 Jul 2008	SF	RFC5763	 78	Extend to support Opportunity Search (CRM WorkBench)
-- 07 Aug 2008	MF	SQA16802 79	Searching by Official Number are running slowly on very large database.  Remove the use of UPPER
--					and rely on the database being either Case Insensitive or the search being entered accurately.
-- 01 Aug 2008  LP  RFC5767 80 For CRM Cases also use AnySearch to return cases based on matching Case Names
-- 13 Aug 2008	SF	RFC5760	81	Extend to support Marketing Activity Search (Campaign) (CRM WorkBench)
-- 14 Sep 2008	SF	RFC5760	82	Actual Event Dates not filtering
-- 19 Sep 2008	JCLG	RFC7095	83	Remove extra spaces for @sSQLString to not exceed 4000 characters
-- 30 Sep 2008	SF	RFC7124 84	Filter potential value by local value as well as foreign value.
-- 27 Oct 2008	AT	RFC5773	85	Add additional Opportunity Filters.
-- 21 Oct 2008	vql	S115963 79	Make sure when searching by batch identifier it is wrapped around quotes.
-- 10 Nov 2008	AT	RFC5769	86	Add additional Marketing Event Filters.
-- 14 Nov 2008	AT	RFC5773	87	Fix reported bugs.
-- 20 Nov 2008  LP      RFC7310 88      Fix AttributeGroup logic regarding Not Equal To operator.
-- 25 Nov 2008  LP      RFC7262 89      Syntax error.
-- 09 Dev 2008	SF	RFC7390	90	Add SuitableForRelationship filter to list cases for a related case picklist
-- 12 Dec 2008	AT	RFC7365	91	Added date to Case Type filter for license check.
-- 22 Jan 2008	MS	RFC6845	92	Allow multiple Attribute Types for search
-- 02 Feb 2009  LP      RFC7600 93	Add new PurchaseOrderNo filter.
-- 01 Apr 2009	MF	RFC7834	94	Multiple Case Category search not returning any result.
-- 16 Apr 2009	MF	RFC6712	95	Enable row level security for workbenches
-- 05 May 2009	AT	RFC7958	96	Change JOIN on CASEINDEXES to LEFT JOIN with fallback to CASE.IRN.
-- 27 May 2009	MF	S17730	97	Official number searches by with Search On Numbers Only option is to use CASEINDEXES to improve performance.
-- 03 Jul 2009	MF	S17748	98	Add WITH(NOLOCK) hint to each table to ensure long query do not block other users.
-- 28 Jul 2009	MF	S17917	99	Improve performance by removing EXISTS clause to CASETYPE for exclusion of draft Case Types and also
--					change EXISTS subselect for CASENAME to a JOIN on a derived table.
-- 31 Jul 2009	ASH	R8226	100	Add a Condition to check null value of TEXT or SHORTTEXT in CASETEXT table for CASE Operator in 5,6.
-- 31 Jul 2009	ASH	R8226	101	Check the condition if CASE Operator in 5,6.
-- 05 Aug 2009	MF	S17917	102	Revisit to correct problem with @sAnySearch
-- 05 Aug 2009	MF	S17917	103	Revisit to correct problem with @sAnySearch
-- 07 Oct 2009	AT	R100081	104	Fix upper syntax for AnySearch.
-- 11 Aug 2009	KR	R8337	105	fix the reference to XN.upper(FIRSTNAME) it should be upper(XN.FIRSTNAME)
-- 22 Oct 2009	LP	R6712	106	Implement Row level security for WorkBenches only users (USERIDENTITY)
-- 12 Nov 2009	LP	R6712	107	Allow cases to be filtered by user's row access.
-- 27 Jan 2010	MF	R100186 108	Search where Official Number "does not exist" is returning incorrect results.
-- 12 Feb 2010	MF	R8846	109	Replace joins to fn_FilterUserCases and fn_FilterUserEvents with previously loaded temporary
--					tables as a performance improvement step
-- 24 Mar 2010	SF	R8768	110	Allow CASES.STEM to be filtered on
-- 08 Apr 2010	MF	R9127	111	ClearCase merge correction where code for getting list of CaseTypes is repeated.
-- 10 May 2010	MS	R9200	112	Event Filter will not be considered in case of Within operator for the Event.
-- 14 May 2010	MF	R9326	113	Allow selection of Cases based on a comparison between two events.
-- 26 May 2010	LP	R100276 114	Change correlation prefix for CASEEVENT when EventDateOperator is Does Not Exist
-- 28 Jun 2010	MF	R9296	115	New table CASEINSTRUCTIONS is to be used when filter is by inherited Instruction Type
-- 05 Jul 2010	MF	R9505	116	Allows selection of Cases where the logged on user, is associated with names by one or
--					more Name Relationships and those related Names are associated with Cases by one or more
--					NameTypes.
-- 09 Jul 2010	MF	S18885	117	Patent Term Adjustments Operators are being set incorrectly by calling program. Correction
--					can be made within this procedure.
-- 09 Jul 2010	MF	R9536	118	When searching for Live Cases that don't have a Renewal Status there were dead cases being returned. This
--					was because the Status checkbox flags were being ignored when a specific Status/Renewal Status or NOT EXIST
--					was also being used in the search.
-- 20 Jul 2010	MF	S18631	119	When filtering by due date, allow the Event to exist for any OpenAction and not just the Action that created it.
-- 24 Aug 2010	MF	R9711	120	When multiple NameTypes are selected in the filter they should be treated as if they are OR'd together.
-- 25 Aug 2010	MF	S19006	121	Revisit of SQA11187 to allow Main Renewal Action to be ignored when filtering on Next Renewal Date.
-- 18 Oct 2010	MF	S19125	122	When searching by Basis and Pending status a SQL error occurred.
-- 19 Oct 2010	LP	R9321	123	Extend to filter by ProcessId for cases that were updated via global case field updates.
-- 21 Oct 2010  PA      R9540	124	Inclusion/exclusion of Events belonging to Renewals is missing. Filtering by Importance Level is also missing.
-- 23 Nov 2010	MF	R9988	125	Revisit RFC9540 and remove the introduced code. The required code for the inclusion/exclusion of events and filtering
--					on Importance Level already existed.  The change required was actually to the user interface to make use of this functionality.
-- 04 Feb 2011  ASH	R100455	126    Change the column name from �NAMETYP� to �NAMETYPE� when @sNameGroupTypeKey is not null.
-- 24 May 2011	MF	S17652	127	When using date comparison functionality(RFC9326) also consider the OpenAction associated with the Event.
-- 03 Jun 2011	MF	S17652	128	Revisit. Need to cater for the situation where the first Event in the comparison may not exist.  The assumption is that the Event
--					on the right hand side of the comparison must exist. This will typically be the Event that were taken as a snap shot during the
--					load of the Law Updates. After Policing has recalculated we want to compare the current date against the snapshot date. If the
--					current date is missing then this needs to be shown as a mismatch against the compared event. Any case that does not have a law
--					change will not have a snap shot Event to start with so there is no point returning those Cases that are missing the snapshot
--					event as it may just indicate that no law change occurred.
-- 06 Jun 2011	MF	S17652	129	Revisit. Only the Not Equal To comparison should consider null values.  All other comparisons must have a date on both sides
--					of the comparison.
-- 30 Jun 2011	MF	R10924	130	Searches by Due Date should take the Controlling Action into consideration as the Event will only be considered due if the
--					specified Controlling Action is open against the Case.
-- 07 Jul 2011	DL	R10830	131	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 20 Jul 2011	DV	R10984	132	Rename temporary table #TEMPCASES to #TEMPCASESEXT as a table with same name is already
--                                      getting created in csw_GetExtendedCaseDetails stored proc
-- 04 Aug 2011	MF	R11063	133	SQL Error when searching for Renewal Status at the same time Basis is also included in search.
-- 30 Aug 2011	ASH	R10937	134	Display all Cases where name is a Case Name Type as well as an Attention Name.
-- 17 Oct 2011	DL	S19823	135	Search for cases associated with a EDE batch does not return all cases.
-- 28 Nov 2011	MF	R11634	136	Search on name where NOT EQUAL TO is used is returning Cases incorrectly if there are multiple name of the given
--					name type attached.
-- 12 Jan 2012	ASH	R11725 137	If search of Attention Name is included in a query that is also searching for a specific Name Type (Debtor)
--					search result is displaying all cases where name is used as any name type (Instructor but not Attention Name in that Case)
-- 13 Mar 2012	ASH	R11736 138	"And" operator is not working in Case Boolean search.
-- 11 Apr 2012	MF	R12158	139	Date comparison query is not always reporting a missing date.
-- 22 May 2012	MF	R12131	140	When NOT EXISTS for Classes is used in conjunction with both Local and International classes then BOTH the Local and International
--					must not exist.
-- 05 Sep 2012	MF	R12701	141	Rework of RFC9326. When comparing Events where the OpenAction needs to be considered for Due Dates, ensure that the Event in the
--					comparison is one that is referenced by the Action.  This is because the comparison also considers missing data and so we were
--					getting a false positive result at times.
-- 30 Oct 2012  AK	R12702	142	Changes made to check 'Client Exclude Dead Case Stats' value in SITECONTROL and applied for External user for AnySearch Scenario.
-- 06 Dec 2012	MF	R13009	143	Provide an option as to whether the specified CONTROLLINGACTION must be open or whether any open action that includes
--					the Event will do.
-- 20 Dec 2012	MF	R12965	144	I suspect this is correcting a problem introduced with R11725. When searching by Attention and NameType the search is incorrectly using
--					an "OR" in such a way that the filter on NameType is being lost.
-- 05 Feb 2013  ASH	R13113	145	Ability for a Case Reference field in Case Advanced Search to be multi-select
-- 08 Feb 2013  vql	R13113	146	Fixed start with search.
-- 15 Apr 2013	DV	R13270	147	Increase the length of nvarchar to 11 when casting or declaring integer
-- 22 Apr 2013	MF	R13418	148	Performance problem where UPPER function is still in use.
-- 20 May 2013	ASH	R13499	149	Increase the length of Case Reference to 1000 so that Case Search returns correct results when a long batch of IRN is supplied
-- 21 May 2013	ASH	R13499	150	Logic change to retrive Case Reference from semicolon string when operator is between 2 and 6.
-- 18 Jun 2013  SW	DR115	151	Used OfficeKeys to construct where clause to support multiple selections in Case Office picklist in Case Search.
-- 21 Jun 2013  MS      DR108   152     Added IncludeMembers for including members of the group countries in search result.
-- 05 Jul 2013	vql	R13629	153	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 29 Aug 2013	MF	R13649	154	Modify the Row Level Security code to improve SQL performance
-- 24 Sep 2013	MF	R26648	155	NOT EXISTS for a due date is only working if a specific Event is included in the filter.
-- 29 Nov 2013	NF	R29064	156	Revist RFC26648 to handle Client/Server where NOT EXISTS sets bothe the Search By Due Date and Search By Event Date to 0.
-- 2  Dec 2013  SW      R28907  157     Handle <Office> construct to support saved searches after the upgrade to Release 9.
-- 07 Mar 2014	MF	R31402	158	Change the AnySearch so that if no match is found on CASEINDEXES then drop through and then search on Keywords.
-- 25 Mar 2014  SW      R30703  159     Applied fn_StripHTML on Case Text columns to strip html when running search from user interface.
-- 14 May 2014	KR	R33829	160	If row access security is assigned to a user, users with no row access security should NOT be able to access cases
-- 20 May 2014	MF	R33829	161	Revisit of RFC33829 to cater for when the procedure is executed from Centura
-- 21 May 2014	MF	R31402	162	Revisit to improve performance where Keyword searches are also being considered.
-- 04 Jun 2014  AK      R33301  163	Add ability to search cases by File Location and Bay Number
-- 11 Jun 2014  AK      R34938  164	Ability to see Bay number and File Part Title in the Case Search results
-- 09 Jul 2014	MF	R36600	165	When an Occurred Event is being searched as NOT EXISTS then need to use fn_GetCaseOccurredDates instead of fn_GetCaseDueDates.
-- 14 Jul 2014	MF	R37352	166	Reversal of RFC30703. Inclusion of fn_StripHTML makes the searching of Case Text unusable due to the performance impact it causes.
-- 01 Aug 2014  SS	36952   167     Modified the size of CaseKeys to max to cater to condition where the 200 case keys will be passed for Global Name change
-- 05 Aug 2014  AK      R35504  168	Changes made to make Case Status as multi-select field for Case Search
-- 28 Oct 2014	MF	R41041	169	The CaseReferenceStem should strip any characters from the ~ onwards as only the characters before this are the actual Stem.
-- 03 Mar 2015	MF	R43207	170	Allow filtering on EventText and EventTextType.
-- 17 Apr 2015	MS	R46603	171	Set size of CaseReference variable to max
-- 28 May 2015	MF	R38464	172	External login was including #TEMPCASEEXT multiple time in the generated FROM clause.
-- 04 Jun 2015	MF	R48189	173	When semi colon separated list of CaseReferences are supplied with a "Starts With" operator, we need to switch to "Equal To" as there
--					is a significant performance issue. We might reverse this change in the future if the operator can be set correctly in the front end.
-- 10 Jun 2015	MF	R48454	174	If @nActionKeyOperator is 1 (not equal to) or 6 (not exists) then the WHERE clause requires a test for "OA1.CASEID is NULL".
--					This test had been commented out with no explanation why. It has now been reinstated.
-- 15 Jun 2015	MF	R48487	175	The use of WHERE 1=1 is causing problems in a multi step Query Manager query because the WHERE 1=1 is being used as a marker to join to
--					the previous result set.
-- 05 Oct 2015  MS      R38939  176     Allow multiple selection of events in case filter
-- 02 Nov 2015	MF	R54710	177	Quick search should return single case if there is a direct match on IRN
-- 27 Apr 2016	MF	R60349	178	Ethical Walls rules applied for logged on user.
-- 02 Jun 2016	MF	R62341	179	Row level security broken out into user defined functions fn_CasesRowSecurity or fn_CasesRowSecurityMultiOffice.
-- 26 Jul 2016	MF	64804	180	The search for an attribute using the NOT EQUAL operator is returning incorrect results. It should work more like Not Exists but for
--					specific attribute.
-- 23 Aug 2016	MF	63114	180	Rework of 54710. Only retun the single direct match Case if it does not also have a direct match on Official Number.
-- 24 Aug 2016	MF	63101	181	Rework of 48189. If a semi colon separated list of CaseReferences is supplied and the wild card character "%" is detected anywhere in
--					the string, then the system will revert to using a Starts With operator search for ALL of the case references (not just the one with the %).
-- 05 Sep 2016	MF	63114	182	Rework due to merge issue. Need to consider Ethical Wall when checking for exact match on Case IRN.
-- 16 Nov 2016	MF	69945	183	When NAMEKEYS are supplied but the operator is Starts With, Ends With or Contains then change to Equal To. This is because of a front end
--					problem where for Staff and Signatory these operators are still using the Name picklist.
-- 01 Aug 2017  MS      R71789  184     Add Family as multiple selection
-- 17 Aug 2017	MF	72177	185	Allow Related Cases to be suppressed from the Quick Search (AnySearch).
-- 20 Sep 2017	AT	72086	186	Enable filtering by multiple case types.
-- 28 Sep 2017  MS  	R72437  187     Increase @psReturnClause size to max
-- 01 Nov 2017	MF	72830	188	Revist of 72086 as failed testing for an external user.
-- 13 Dec 2017	MF	73126	189	Extend the option for AnySearch so that it can elect to return all matches and ignore the functionality introduced with 54710.
-- 20 Feb 2018	AK	73057	189	Handled multiple parentNamekeys
-- 11 May 2018	MF	74087	190	Error thrown when searching on Standing Instruction using Inherited option without first selecting an Instruction.
-- 22 May 2018	DV	72612	191	Add ability to search on Design Elements
-- 13 Jun 2018	MF	74294	192	Web Row Access ignored when doing quick search for a case and no row access security applied to user. User should not see any cases.
-- 07 Sep 2018	AV	74738	193	Set isolation level to read uncommited.
-- 28 Sep 2018	MF	74987	194	CaseKeys parameter changed to nvarchar(max) from nvarchar(1000) to avoid trunction of list of CaseKeys.
-- 03 Oct 2018	MF	75224	195	Searches by Patent Term Adjustment fields should cater for open ended searches.
-- 31 Oct 2018	DL	DR-45102 196	Replace control character (word hyphen) with normal sql editor hyphen
-- 14 Nov 2018  AV	DR-45358 197	Date conversion errors when creating cases and opening names in Chinese DB
-- 12 Mar 2019	MF	DR-47469 198	Search by Any CaseText Type should also consider the TITLE column in CASES.
-- 01 Aug 2019	MF	DR=50649 199	When the NOT EXISTS operator was used for Basis, no row was returned if the PROPERTY row was missing.
-- 03 Sep 2019  LP	DR-44128 200    Ignore CaseKeys operator if there are no CaseKeys specified.
-- 09 Sep 2019	SF 	DR-49793 201	Support FamilyKey containing comma, FamilyKeyList/FamilyKey replaces existing FamilyKey structure; FamilyKey remains for FC created by Apps and C/S. 
-- 11 Nov 2019	MF	DR-50649 202	Change the JOIN to the PROPERTY table to a LEFT JOIN to allow for NOT EXISTS searches on values held in PROPERTY.
-- 30 Mar 2020	MS	DR-51563 203	Added EntitySize in where condition
-- 13 May 2020	DL	DR-58943 204	Ability to enter up to 3 characters for Number type code via client server	


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @nErrorCode 				int

Declare @sSQLString				nvarchar(max)

-- Declare Filter Variables
Declare @sAnySearch 				nvarchar(max)
Declare	@nAnySearchOperator			tinyint
Declare @sCaseKey				nvarchar(11)    -- the CaseId of the Case
Declare	@sCaseReference 			nvarchar(max)
Declare	@nCaseReferenceOperator			tinyint
Declare	@bIsWithinFileCover			bit		-- if TRUE, select both the @sCaseReference Case, and any Cases where the @sCaseReference case is defined as the FileCover. @sCaseReference is never partial in this context.
Declare	@sCaseReferenceStem 			nvarchar(30)
Declare	@nCaseReferenceStemOperator		tinyint
Declare	@sCaseTypeKeys				nvarchar(200)	-- A comma separated list of Case Types
Declare	@nCaseTypeKeyOperator			tinyint
Declare	@sCaseTypeKey				nvarchar(200)	-- A comma separated list of Case Types
Declare	@nCaseTypeKeysOperator			tinyint
Declare	@bIncludeCRMCases			bit		-- if TRUE, allow CASETYPE.CRMOnly = 1 to be returned
Declare	@bIncludeCRMCasesCaseType	bit		-- if TRUE, allow CASETYPE.CRMOnly = 1 to be returned
Declare	@sCountryCodes				nvarchar(1000)	-- A comma separated list of Country Codes.
Declare	@nCountryCodesOperator			tinyint
Declare @sFileLocationKeys			nvarchar(max)
Declare @sFileLocationBayNo			nvarchar(40)
Declare @nFileLocationOperator			tinyint
Declare @nFileLocationBayNoOperator		tinyint

-- RFC9505
Declare @sNameRelations				nvarchar(200)	-- A comma separated list of Name Relationships
Declare @nNameRelationsOperator			tinyint
Declare	@sRelatedNameTypes			nvarchar(1000)	-- A comma separated list of NameType used in conjunction with @sNameRelations
Declare @nUserNameNo				int

Declare	@bIncludeDesignations			bit
Declare @bIncludeMembers			bit
Declare	@sPropertyTypeKey			nchar(200)
Declare	@nPropertyTypeKeyOperator		tinyint
Declare	@sPropertyTypeKeyList			nvarchar(1000)	-- A comma separated qouted list of PropertyType Keys.
Declare	@nPropertyTypeKeysOperator		tinyint
Declare	@sCategoryKey				nvarchar(200)	-- Include/Exclude based on next parameter
Declare	@nCategoryKeyOperator			tinyint
Declare	@sSubTypeKey				nvarchar(200)	-- Include/Exclude based on next parameter
Declare @nSubTypeKeyOperator			tinyint
Declare @sBasisKey				nvarchar(200)
Declare @nBasisKeyOperator			tinyint
Declare	@sClasses				nvarchar(1000)
Declare	@nClassesOperator			tinyint
Declare @nOriginalClassesOperator		tinyint
Declare	@bIsLocal				bit
Declare	@bIsInternational			bit
Declare	@sKeyWord	 			nvarchar(50)
Declare	@nKeyWordOperator			tinyint
Declare	@sFamilyKeys	 			nvarchar(max) -- for older saved searches and centura
Declare	@nFamilyKeyOperator			tinyint		-- for older saved searches and centura
Declare	@sFamilyKeyList	 			nvarchar(max)
Declare	@nFamilyKeyListOperator			tinyint
Declare	@sTitle					nvarchar(254)	-- if partial, a "%" character is present.  The search should be case independent
Declare	@nTitleOperator				tinyint
Declare @bTitleSoundsLike			bit		-- When turned on, the words in Title are compared to KeyWords for the case using a sound-alike algorithm.  If there are multiple words in Title, they are treated separately and a case is returned if any of the words matches.
Declare	@nTypeOfMarkKey				int 		-- Include/Exclude based on next parameter
Declare	@nTypeOfMarkKeyOperator			tinyint
Declare	@nInstructionKey			int		-- Applies to instructions held against the Case or inherited from the Case's Names depending on the IncludeInherited option. When IncludeInherited=1, only the Equal To and Not Equal To operators are available.
Declare	@nInstructionKeyOperator		tinyint		-- Only Operators Equal To and Not Equal to are implemented
Declare @bCaseNameGroupBooleanOr		bit		-- When set to 1, matches on at least one of the CaseNames are returned. Otherwise, matches on all of the CaseNames specified are returned.
Declare	@sInstructionType			nvarchar(3)
Declare @bIncludeInherited			bit		-- When true, the filtering is performed against all standing instructions - both those recorded directly against the case and those inherited. Otherwise, the filtering is only performed on standing instructions stored directly against the case.
Declare @nCharacteristicFlag			smallint	-- Only Operators Equal To and Not Equal To are implemented. Returns cases where the standing instructions implement the characteric filtering provided.
Declare @nCharacteristicFlagOperator		tinyint
Declare	@sEventKeys				nvarchar(max)	-- A comma separated list of EventNos
Declare @nEventKeyForCompare			int		-- EventNo used in comparison against @sEventKey
Declare @bIncludeClosedActions			bit		-- IncludeClosedActions only applies when searching ByDueDate.  If set to true, Due Dates do not need to conform to the restriction that the due date belongs to an open action.
Declare	@bByDueDate 				bit
Declare @bByEventDate 				bit
Declare	@bIsRenewalsOnly			bit
Declare @bIsNonRenewalsOnly			bit
Declare	@nEventDateOperator			tinyint
Declare	@dtDateRangeFrom			datetime
Declare	@dtDateRangeTo				datetime
Declare @sPeriodType				nvarchar(2)	-- D - Days, W - Weeks, M - Months, Y - Years
Declare @nPeriodQuantity			smallint	-- May be positive or negative.  Always supplied in conjunction with Type.
Declare @nImportanceLevelOperator		tinyint		-- ImportanceLevel - returns cases where the Events are of a particular Importance Level or range.
Declare @sImportanceLevelFrom			nvarchar(2)
Declare @sImportanceLevelTo			nvarchar(2)
Declare	@nEventNoteTypeKeysOperator		tinyint
Declare	@sEventNoteTypeKeys			nvarchar(4000)	-- The Event Text Types required to be reported on.
Declare	@nEventNoteTextOperator			tinyint
Declare	@sEventNoteText				nvarchar(max)	-- The Event Text required to be reported on.
Declare	@sStatusKey	 			nvarchar(4000)	-- if supplied, @pbCasePending, @pbCaseRegistered and @pbCaseDead are ignored.
Declare	@nStatusKeyOperator			tinyint
Declare @sRenewalStatusKeys			nvarchar(3500)	-- If supplied, StatusFlags are ignored.Searches the RenewalStatus only.
								-- May contain a comma separated list of StatusKeys.
Declare @nRenewalStatusKeyOperator		tinyint
Declare	@bCheckDeadCaseRestriction		bit		-- if TRUE, and Site Control Client Exclude Dead Case Stats is TRUE, and caller is an External user, explicitly set @bIsDead=0
Declare	@bIsPending				bit		-- if TRUE, any cases with a status that is Live but not registered
Declare	@bIsRegistered				bit		-- if TRUE, any cases with a status that is both Live and Registered
Declare	@bIsDead				bit		-- if TRUE, any Cases with a status that is not Live.
Declare	@bRenewalFlag				bit
Declare @sRenewalStatusDescription		nvarchar(50)	-- Any cases where the description of the RenewalStatus matches that supplied are retirned (for external users -  external description, otherwise - internal).
Declare @nRenewalStatusDescriptionOperator 	tinyint		-- Valid options are:Equal ToNot Equal ToIs Null (Property.RenewalStatus is null)Is Not Null (Property.RenewalStatus is not null)
Declare	@bHasLettersOnQueue			bit
Declare	@bHasChargesOnQueue			bit
Declare	@sQuickIndexKey				nvarchar(10)
Declare	@sQuickIndexKeyOperator			tinyint
Declare	@sOffice				nvarchar(4000)
Declare	@nOfficeOperator	        	tinyint
Declare	@sOfficeKeys				nvarchar(4000)
Declare	@nOfficeKeyOperator	        	tinyint
Declare	@sClientKeys				nvarchar(4000)	-- A comma separated list of NameKeys that an external user is allowed to see. Used in conjunction with @nClientKeysOperator if supplied.
Declare	@nClientKeysOperator			tinyint
Declare @sClientReference			nvarchar(80)	-- The reference number supplied by the name acting in the client role for the case (according to Client Name Types site control).
Declare @nClientReferenceOperator		tinyint
Declare	@sOfficialNumber 			nvarchar(36)	-- The official number data to search with.  Case insensitive search.
Declare	@nOfficialNumberOperator 		tinyint
Declare	@sNumberTypeKey				nvarchar(3)	-- By default, the search is conducted on the OfficialNumbers for the case.  The TypeKey may optionally be used to filter the results to a specific Number Type.
Declare	@bUseRelatedCase			bit 		-- When turned on, the search is conducted on any official numbers stored as related Cases.  Any NumberType values are ignored.
Declare	@bUseNumericSearch 			bit		-- When turned on, any non-numeric characters are removed from Number and this is compared to the numeric characters in the official numbers on the database.
Declare @bUseCurrent				bit		-- When turned on, the search is conducted on the current official number for the case.  Any NumberType values are ignored.Either UseCurrent or UseRelatedCase may be turned on, but not both.
Declare @sNumericOfficialNumber			nvarchar(36)	-- Number with any non-numeric characters removed from it
Declare @sNameKeys				nvarchar(4000)	-- A comma separated list of NameNos.
Declare @sInstructorAttnKeys			nvarchar(4000)	-- A comma separated list of NameNos for Instructor.Attention searching
Declare @nNameKeysOperator			tinyint
Declare @sCaseNameName				nvarchar(254)	-- Name used for direct search (without look up of NameNo)
Declare @sInstructorAttnName			nvarchar(254)	-- Name used for direct search used for Instructor.Attention searching
Declare @nAttnKeysOperator			tinyint
Declare	@bCaseNameNameUseAttentionName		bit
Declare	@bMatchInstructorAttn			bit
Declare @nAttentionRow				tinyint		-- Row number containing Attention filter to associate with Instructor.

Declare @sNameVariantKeys			nvarchar(4000)	-- A comma separated list of NameVariantNos.
Declare @sNameKeysTypeKey			nvarchar(100)	-- The TypeKey may optionally be used to filter the results to a comma separated list of Name Types.
Declare @bNameIncludeExpired			bit		-- When set 1, matches on both expired and unexpired relationships are returned. Otherwise, only matches on unexpired relationships are returned.
Declare @bUseAttentionName			bit		-- When turned on, the search is performed on the attention names for the CaseName row rather than the direct names.
Declare @bIsCurrentUser				bit		-- When turned on, search for CASENAME where name is the current login user linked name.
Declare @nNameGroupKey				int		-- Search for all the case names where the name belongs to the supplied name group.
Declare @nNameGroupKeyOperator			tinyint
Declare @bNameGroupIncludeExpired		bit		-- When set 1, matches on both expired and unexpired relationships are returned. Otherwise, only matches on unexpired relationships are returned.
Declare @sNameGroupTypeKey			nvarchar(100)	-- The TypeKey may optionally be used to filter the results to a comma separated list of Name Types. Only matches on name types the user may access are returned.
Declare	@sReferenceNo				nvarchar(80)
Declare @sReferenceTypeKey			nvarchar(100)	-- The TypeKey may optionally be used to filter the results to a comma separated list of Name Types.Only matches on name types the user may access are returned.
Declare	@nReferenceNoOperator			tinyint		-- The ReferenceNo supplied by a case name.  All searches are case insensitive.
Declare @sAttributeKeys				nvarchar(4000)  -- Comma seperated list of Attribute Keys
Declare @sAttributeTypeKey			nvarchar(11)
Declare @nAttributeOperator			tinyint
Declare @bBooleanOr				bit		-- When set to 1, cases are returned that match any of the attributes in the group.When set to 0 (or not supplied), cases are returned that match all of the attributes in the group.
Declare @sStringOr				nvarchar(5)
Declare @sCaseText				nvarchar(4000)
Declare @sCaseTextTypeKey			nvarchar(2)
Declare @nCaseTextOperator			tinyint
Declare @bHasIncompletePolicing			bit		-- Returns cases that have incomplete policing requests.
Declare @bHasIncompleteNameChange		bit		-- Returns cases that have outstanding global name change requests.
Declare @bOnCPAUpdate				bit		-- Returns cases flagged for inclusion in the next CPA Batch (SQA11820)
Declare	@nCPASentBatchNo			int		-- Returns cases sent to CPA in the entered Batch Number (SQA11820)
Declare @nIPOfficeAdjustmentOperator		tinyint		-- IPOfficeAdjustment - returns cases with a Patent Term Adjustment supplied by an IP Office within the specified range of days.
Declare @nIPOfficeAdjustmentFromDays		int
Declare @nIPOfficeAdjustmentToDays		int
Declare @nCalculatedAdjustmentOperator		tinyint		-- CalculatedAdjustment - returns cases with a derived adjustment figure (IP Office Delay - Applicant Delay) within the specified range of days.
Declare @nCalculatedAdjustmentFromDays		int
Declare @nCalculatedAdjustmentToDays		int
Declare @nIPOfficeDelayOperator			tinyint		-- IPOfficeDelay - returns cases with the specified number of days delay at the IP Office.
Declare @nIPOfficeDelayFromDays			int
Declare @nIPOfficeDelayToDays			int
Declare @nApplicantDelayOperator		tinyint		-- ApplicantDelay - returns cases with the specified number of days delay by the applicant.
Declare @nApplicantDelayFromDays		int
Declare @nApplicantDelayToDays			int
Declare @bHasDiscrepancy			bit		-- When true, returns cases where IPOfficeAdjustment differs from the CalculatedAdjustment
Declare	@nCaseListKeyOperator			tinyint
Declare	@nCaseListKey				int
Declare @bIsPrimeCasesOnly			bit
Declare @sActionKey				nvarchar(2)	-- Cases with the specific action are returned.
Declare @nActionKeyOperator			tinyint
Declare @bIsOpen				bit		-- When true, only open actions are assessed.
Declare @nCaseNameFromCaseCaseKey		int		-- CaseNameFromCase filter criteria: Returns all the cases that share the name and name type of the supplied case; i.e. locates the NameKeys for
Declare @sCaseNameFromCaseNameTypeKey		nvarchar(100)	-- the CaseKey and NameTypeKey combination, and then returns all the cases that have the NameKeys and NameTypeKey combination.
Declare @sNameKeysList				nvarchar(4000)	-- holds the NameKeys for the CaseKey and NameTypeKey combination.
Declare	@nInheritParentNameKey			nvarchar(4000)	-- Return Cases where the Name against the Case was inherited from this Name
Declare @nInheritParentNameKeyOperator		tinyint
Declare	@sInheritNameTypeKey			nvarchar(100)	-- Return Cases where the Name of this comma separated list of NameTypes was inherited
Declare @nInheritNameTypeKeyOperator		tinyint
Declare @sInheritRelationshipKey		nvarchar(3)	-- Return Cases where the Name against the Case was inherited using this relationship
Declare @nInheritRelationshipKeyOperator	tinyint
-- SQA12427
Declare @bIncludeDraftCase				bit		-- When turned on, allow draft cases to be included in the search.
Declare @nEDEDataSourceNameNo			int		-- Return cases associated with EDE data source
Declare @sEDEBatchIdentifier			nvarchar(254)
Declare @nAuditSessionNumber			int		-- Return cases that modified in the specified audit session number.
-- SQA19823
Declare @bDraftCaseOnly				bit		-- Indicate filter by casetype = 'X'
-- RFC7600
Declare @nPurchaseOrderNoOperator               int
Declare @sPurchaseOrderNo                       nvarchar(160)
-- RFC5763
Declare @nOpportunityStatus			int
Declare @nOpportunityStatusOperator		tinyint
Declare @nOpportunitySource			int
Declare @nOpportunitySourceOperator		tinyint
Declare @sOpporunityRemarks			nvarchar(2000)
Declare @nOpportunityRemarksOperator		tinyint
Declare	@dtOpportunityExpCloseDateFrom		datetime
Declare	@dtOpportunityExpCloseDateTo		datetime
Declare	@nOpportunityExpCloseDateOperator	tinyint
Declare @nOpportunityPotentialValueFrom		decimal(11,2)
Declare @nOpportunityPotentialValueTo		decimal(11,2)
Declare @nOpportunityPotentialValueOperator tinyint
--RFC5773
Declare @nOpportunityPotValCurOperator		tinyint
Declare @sOpportunityPotValCurCode		nvarchar(3)
Declare @nOpportunityNextStepOperator		tinyint
Declare @sOpportunityNextStep			nvarchar(1000)
Declare @nOpportunityPotentialWinOperator	tinyint
Declare @nOpportunityPotentialWinFrom		decimal(5,2)
Declare @nOpportunityPotentialWinTo		decimal(5,2)
Declare @nOpportunityNumberOfStaffOperator	tinyint
Declare @nOpportunityNumberOfStaffFrom		int
Declare @nOpportunityNumberOfStaffTo		int
--RFC5760
Declare @nBudgetAmountFrom				decimal(11,2)
Declare @nBudgetAmountTo				decimal(11,2)
Declare @nBudgetAmountOperator 			tinyint

Declare @nMktActivityStatus			int
Declare @nMktActivityStatusOperator		tinyint
Declare @dtMktActivityStartDateFrom		datetime
Declare @dtMktActivityStartDateTo		datetime
Declare @nMktActivityStartDateOperator		tinyint
Declare @dtMktActivityActualDateFrom		datetime
Declare @dtMktActivityActualDateTo		datetime
Declare @nMktActivityActualDateOperator		tinyint
Declare @nMktActivityActualCostFrom		decimal(11,2)
Declare @nMktActivityActualCostTo		decimal(11,2)
Declare @nMktActivityActualCostOperator 	tinyint
--RFC5769
Declare @sMktActivityActualCostCurrency		nvarchar(3)
Declare @nMktActivityActualCostCurOperator	tinyint
Declare @nMktActivityExpectedResponsesFrom	int
Declare @nMktActivityExpectedResponsesTo	int
Declare @nMktActivityExpectedResponsesOperator	tinyint
Declare @nMktActivityActualResponsesFrom	int
Declare @nMktActivityActualResponsesTo		int
Declare @nMktActivityActualResponsesOperator	tinyint
Declare @nMktActivityAcceptedResponsesFrom	int
Declare @nMktActivityAcceptedResponsesTo	int
Declare @nMktActivityAcceptedResponsesOperator	tinyint
Declare @nMktActivityStaffAttendedFrom		int
Declare @nMktActivityStaffAttendedTo		int
Declare @nMktActivityStaffAttendedOperator	tinyint
Declare @nMktActivityContactsAttendedFrom	int
Declare @nMktActivityContactsAttendedTo		int
Declare @nMktActivityContactsAttendedOperator	tinyint
-- RFC7390
Declare @sSuitableForRelationshipCode nvarchar(3)			-- Must be specified along with ForCaseKey attribute
Declare @nSuitableForRelationshipCaseKey int				-- Returns cases that is valid for the relationship specified
Declare @sSuitableForRelationshipCountryCode nvarchar(3)		-- local variable from RelationshipCaseKey
Declare @sSuitableForRelationshipCodePropertyType nvarchar(1)	-- local variable from RelationshipCaseKey
-- RFC6712
Declare @nCaseAccessMode			tinyint			-- row access for which the case is required
									-- 1=select(default),2=delete,4=insert,8=update
--RFC72612
Declare @sFirmElement    nvarchar(20)
Declare @nFirmElementOperator    tinyint
Declare @sClientElement    nvarchar(20)
Declare @nClientElementOperator    tinyint
Declare @sOfficialElement    nvarchar(20)
Declare @nOfficialElementOperator    tinyint
Declare @sRegistrationNo    nvarchar(36)
Declare @nRegistrationNoOperator    tinyint
Declare @sTypeface    nvarchar(11)
Declare @nTypefaceOperator    tinyint
Declare @sElementDescription    nvarchar(254)
Declare @nElementDescriptionOperator    tinyint
Declare @bIsRenew    bit
Declare @nEntitySize int
Declare @nEntitySizeOperator	tinyint

Declare @nProcessKey				int		-- RFC9321: ProcessId of Global Field Update background process
Declare @sFrom					nvarchar(max)
Declare @sWhere					nvarchar(max)
Declare @sInOperator				nvarchar(6)
Declare @sOperator	   			nvarchar(6)
Declare @sStatusFlag				nvarchar(5)
Declare @nImportance				int		-- the level of importance of Events to be searched
Declare @sDisplayAction				nvarchar(3)	-- the default action allowed to be seen by the user
Declare @bCaseOffice				bit		-- RFC224 - @bCaseOffice = 1 if the Row Security Uses Case Office site control is turned on
Declare @sOfficeFilter				nvarchar(1000)	-- RFC224 - Dynamically set filter accordingly to the site control
Declare @sSystemUser				nvarchar(30)	-- RFC1127 @sSystemUser is used to pass the SYSTEM_USER into the SQL statement to avoid SqlDumpExceptionHandler exception.
Declare @sList					nvarchar(4000)	-- RFC1717 variable to prepare a comma separated list of values
Declare @sTempWhere				nvarchar(1000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument

Declare @tblCaseNameGroup table			(CaseNameIdentity	int IDENTITY,
					 	 NameKeys		nvarchar(3000) collate database_default,
		      		 		 NameKeysOperator	tinyint,
						 NameIncludeExpired	bit,
		      		 		 NameKeysTypeKey	nvarchar(100) collate database_default,
						 [Name]			nvarchar(254) collate database_default,
						 NameUseAttentionName	bit,
					 	 NameVariantKeys	nvarchar(500) collate database_default ,
						 UseAttentionName       bit,
						 IsCurrentUser		bit,
						 NameGroupKey		int,
						 NameGroupKeyOperator	tinyint,
						 NameGroupIncludeExpired bit,
						 NameGroupTypeKey	nvarchar(100) collate database_default )

Declare @tblAttributeGroup table		(AttributeIdentity	int IDENTITY,
					         BooleanOr		bit,
					 	 AttributeKeys		nvarchar(4000) collate database_default ,
		      		 	 	 AttributeOperator	tinyint,
		      		 	 	 AttributeTypeKey	nvarchar(11) collate database_default )

Declare @tblCaseTextGroup table			(CaseTextIdentity	int IDENTITY,
						 CaseText		nvarchar(4000) collate database_default ,
		      		 	 	 CaseTextTypeKey	nvarchar(2) collate database_default ,
		      		 	 	 CaseTextOperator	tinyint)

Declare @sRowPattern				nvarchar(100)	-- Is used to dynamically build the XPath to use with OPENXML depending on the FilterCriteriaGroup node number.
Declare @sCorrelationName			nvarchar(20)

Declare @nCaseNameRowCount			int		-- Number of rows in the @tblCaseNameGroup table
Declare @nNameVariantRowCount			int		-- Number of rows in the @tblNameVariantGroup table
Declare @nAttributeRowCount			int		-- Number of rows in the @tblAttributeGroup table
Declare @nCaseTextRowCount			int		-- Number of rows in the @tblCaseTextGroup table
Declare @nCount					int		-- Current table row being processed
Declare	@sInClause				nvarchar(max)	-- Contans the string to be placed within an in clause; e.g. in ( ... )
Declare	@sOr					nvarchar(4)
Declare @sRenewalAction				nvarchar(2)	-- The Action used for the Next Renewal Date
Declare	@bAnyRenewalAction			bit		-- Flag that indicates that the Renewal Search on Any Action sitecontrol is on.
declare @bAnyOpenAction				bit		-- Flag that indicates a due date is not forced to use the ControllingAction
Declare @sHomeCurrency				nvarchar(50)
Declare @dtToday				datetime
Declare @bRowLevelSecurity			bit		-- Flag to indicate the user has a row access level profile
Declare @bRowLevelSecurityCentura		bit		-- Flag to indicate the user has a row access level profile for Centura logon
Declare	@bBlockCaseAccess			bit		-- Flag to indicate the user has no row access security but other users do. Default is to block access.
Declare @sCaseKeys				nvarchar(max)
Declare	@nCaseKeysOperator			tinyint
Declare @sFirstCaseReference			nvarchar(20)
Declare @sCaseReferenceWhere			nvarchar(max)
Declare @sOutputString				nvarchar(max)
Declare	@bMultipleCaseRefs			bit
Declare	@bSuppressRelatedCase			bit
Declare @or					nvarchar(5)


-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String
Declare	@ColumnName				nchar(3)
Declare @SemiColon				nchar(1)
Declare	@sNPrefix				nchar(1)

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'
Set	@ColumnName				='COL'
Set	@SemiColon				=';'


Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set     @nCount					= 1
Set	@nErrorCode      			= 0
Set 	@dtToday				= getdate()
Set	@bRowLevelSecurity			= 0
Set	@bRowLevelSecurityCentura		= 0
Set	@bBlockCaseAccess			= 0
Set	@bAnyRenewalAction			= 0
Set	@bAnyOpenAction				= 0

-- Extract the @pbIsExternalUser from UserIdentity
-- and also get the NAMENO associated with the User.
If @nErrorCode=0
Begin
	Set @sSQLString='
	Select @pbIsExternalUser=ISEXTERNALUSER,
	       @nUserNameNo     =NAMENO
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser	bit	OUTPUT,
				  @nUserNameNo		int			OUTPUT,
				  @pnUserIdentityId	int',
				  @pbIsExternalUser	=@pbIsExternalUser	OUTPUT,
				  @nUserNameNo		=@nUserNameNo		OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-----------------------------------
-- Determine  if Row Level Security
-- is to be applied for the user.
-----------------------------------
If @nErrorCode=0
Begin
	-------------------------------------------
	-- Get the @sSystemUser associated with the
	-- IdentityId to be used for Row Security
	-- restrictions
	-------------------------------------------
	Set @sSQLString = "
	Select  @sSystemUser = min(USERID)
	from USERS
	where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@sSystemUser		nvarchar(30)	output,
				  @pnUserIdentityId	int',
				  @sSystemUser	= @sSystemUser	output,
				  @pnUserIdentityId=@pnUserIdentityId

	-------------------------------------------
	-- If no USERID was found then use the
	-- current login
	-------------------------------------------
	If @sSystemUser is null
	Begin
		Set @sSystemUser=SYSTEM_USER
	End

	If @nErrorCode = 0
	Begin
		If @pbCalledFromCentura = 1
		Begin
			Select @bRowLevelSecurityCentura=1
			from USERROWACCESS U WITH (NOLOCK)
			join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
			where RECORDTYPE = 'C'
			and USERID = @sSystemUser

			Set @nErrorCode = @@ERROR
		End
		Else Begin
			Select @bRowLevelSecurity = 1
			from IDENTITYROWACCESS U WITH (NOLOCK)
			join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
			where R.RECORDTYPE = 'C'
			and U.IDENTITYID = @pnUserIdentityId

			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode=0
		Begin
			If (@bRowLevelSecurity=1 OR @bRowLevelSecurityCentura=1)
			Begin
				---------------------------------------------
				-- Determine how/if Office is stored against
				-- Cases.  It is possible to store the office
				-- directly in the CASES table or if a Case
				-- is to have multiple offices then it is
				-- stored in TABLEATTRIBUTES.
				---------------------------------------------
				Select  @bCaseOffice = COLBOOLEAN
				from SITECONTROL
				where CONTROLID = 'Row Security Uses Case Office'

				Set @nErrorCode = @@ERROR

				If(@bCaseOffice=0 or @bCaseOffice is null)
				and not exists (select 1 from TABLEATTRIBUTES where PARENTTABLE='CASES' and TABLETYPE=44)
					Set @bCaseOffice=1
			End
			Else Begin
				---------------------------------------------
				-- If the user is not configured for row
				-- security, then check if any other users
				-- are configured.  If they are then internal
				-- users that have no configuration will be
				-- blocked from ALL cases.
				---------------------------------------------
				If @pbIsExternalUser = 0
				Begin
					If @pbCalledFromCentura = 0
					Begin
						Select @bBlockCaseAccess = 1
						from IDENTITYROWACCESS U WITH (NOLOCK)
						join USERIDENTITY UI     WITH (NOLOCK) on (U.IDENTITYID = UI.IDENTITYID)
						join ROWACCESSDETAIL R   WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
						where R.RECORDTYPE = 'C'
						and isnull(UI.ISEXTERNALUSER,0) = 0

						Set @nErrorCode = @@ERROR
					End
					Else Begin
						Select @bBlockCaseAccess = 1
						from USERROWACCESS U   WITH (NOLOCK)
						join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME)
						where R.RECORDTYPE = 'C'

						Set @nErrorCode = @@ERROR
					End
				End
			End
		End
	End
End

-- If there is no @ptXMLFilterCriteria passed then return the basic "Where" clause filtering on the UserCases if necessary

If (datalength(@ptXMLFilterCriteria) = 0
or datalength(@ptXMLFilterCriteria) is null)
and @nErrorCode = 0
Begin
	set @sWhere = char(10)+"	WHERE 1=1"

 	set @sFrom  = char(10)+"	FROM dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") XC "

 	---------------------------------------------
 	-- If Row Level Security checking is required
 	-- then add the function that returns the
 	-- Case information with the security flag
 	---------------------------------------------
 	If @bRowLevelSecurity = 1
 	Begin
		If @bCaseOffice = 1
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurity("+convert(nvarchar,@pnUserIdentityId)+") RLS on (RLS.CASEID=XC.CASEID"
		Else
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurityMultiOffice("+convert(nvarchar,@pnUserIdentityId)+") RLS on (RLS.CASEID=XC.CASEID"

		If @nCaseAccessMode is not null
			Set @sFrom=@sFrom+" and RLS.SECURITYFLAG&"+convert(nvarchar(2),@nCaseAccessMode)+" = "+convert(nvarchar(2),@nCaseAccessMode)+")"
		Else
			Set @sFrom=@sFrom+" and RLS.READALLOWED = 1)"
	End
	Else If @bRowLevelSecurityCentura=1
 	Begin
		If @bCaseOffice = 1
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurityCentura("+dbo.fn_WrapQuotes(@sSystemUser,0,@pbCalledFromCentura)+") RLS on (RLS.CASEID=XC.CASEID"
		Else
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurityMultiOfficeCentura("+dbo.fn_WrapQuotes(@sSystemUser,0,@pbCalledFromCentura)+") RLS on (RLS.CASEID=XC.CASEID"

		If @nCaseAccessMode is not null
			Set @sFrom=@sFrom+" and RLS.SECURITYFLAG&"+convert(nvarchar(2),@nCaseAccessMode)+" = "+convert(nvarchar(2),@nCaseAccessMode)+")"
		Else
			Set @sFrom=@sFrom+" and RLS.READALLOWED = 1)"
	End
	Else If @bBlockCaseAccess=1
	Begin
		------------------------------------------------
		-- When any row level security is defined
		-- but the current user has no rules configured
		-- then by default they will have no access
		-- to any Cases.
		------------------------------------------------
		Set @sWhere=@sWhere+CHAR(10)+"	and 0=1"
	End

	-- RFC337 If the user is external then filter the Cases
	If @pbIsExternalUser=1
	and @sFrom not like '%join #TEMPCASESEXT XFC%'
	Begin
		Set @sFrom=@sFrom+char(10)+"	join #TEMPCASESEXT XFC on (XFC.CASEID=XC.CASEID)"
	End
End
Else
Begin -- If there are some @ptXMLFilterCriteria passed then begin:

	If @nErrorCode = 0
	Begin
		-- Create an XML document in memory and then retrieve the information
		-- from the rowset using OPENXML

		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

		-- This Statement is full, use the next one directly below!
		-- Retrieve the parametersusing element-centric mapping
		Set @sSQLString =
		"Select @sAnySearch 			= AnySearch,"+CHAR(10)+
		"	@nAnySearchOperator		= AnySearchOperator,"+CHAR(10)+
		"	@sCaseKey			= CaseKey,"+CHAR(10)+
		"	@sCaseReference			= CaseReference,"+CHAR(10)+
		"	@nCaseReferenceOperator		= CaseReferenceOperator,"+CHAR(10)+
		"	@bIsWithinFileCover		= IsWithinFileCover,"+CHAR(10)+
		"	@sCaseReferenceStem		= LEFT(CaseReferenceStem, CASE WHEN(CaseReferenceStem LIKE '%~%') THEN PATINDEX('%~%',CaseReferenceStem)-1 ELSE 30 END),"+CHAR(10)+
		"	@nCaseReferenceStemOperator		= CaseReferenceStemOperator,"+CHAR(10)+
		"	@sCaseTypeKey			= CaseTypeKey,"+CHAR(10)+
		"	@nCaseTypeKeyOperator		= CaseTypeKeyOperator,"+CHAR(10)+
		"	@bIncludeCRMCasesCaseType = IncludeCRMCasesCaseType,"+CHAR(10)+
		"	@sCountryCodes			= CountryCodes,"+CHAR(10)+
		"	@nCountryCodesOperator		= CountryCodesOperator,"+CHAR(10)+
		"	@bIncludeDesignations		= IncludeDesignations,"+CHAR(10)+
		"	@bIncludeMembers		= IncludeMembers,"+CHAR(10)+
		"	@sPropertyTypeKey		= PropertyTypeKey,"+CHAR(10)+
		"	@nPropertyTypeKeyOperator 	= PropertyTypeKeyOperator,"+CHAR(10)+
		"	@nPropertyTypeKeysOperator	= PropertyTypeKeysOperator,"+CHAR(10)+
		"	@sCategoryKey			= CategoryKey,"+CHAR(10)+
		"	@nCategoryKeyOperator		= CategoryKeyOperator,"+CHAR(10)+
		"	@sSubTypeKey			= SubTypeKey,"+CHAR(10)+
		"	@nSubTypeKeyOperator		= SubTypeKeyOperator,"+CHAR(10)+
		"	@sBasisKey			= BasisKey,"+CHAR(10)+
		"	@nBasisKeyOperator		= BasisKeyOperator,"+CHAR(10)+
		"	@sClasses			= Classes,"+CHAR(10)+
		"	@nClassesOperator		= ClassesOperator,"+CHAR(10)+
		"	@bIsLocal			= IsLocal,"+CHAR(10)+
		"	@bIsInternational		= IsInternational,"+CHAR(10)+
		"	@sKeyWord			= upper(KeyWord),"+CHAR(10)+
		"	@nKeyWordOperator		= KeyWordOperator,"+CHAR(10)+
		"	@sTitle				= Title,"+CHAR(10)+
		"	@nTitleOperator			= TitleOperator,"+CHAR(10)+
		"	@bTitleSoundsLike		= UseSoundsLike,"+CHAR(10)+
		"	@nTypeOfMarkKey			= TypeOfMarkKey,"+CHAR(10)+		
		"	@nTypeOfMarkKeyOperator = TypeOfMarkKeyOperator,"+CHAR(10)+
		"	@nEntitySizeOperator	= EntitySizeOperator,"+CHAR(10)+
		"	@nEntitySize			= EntitySize"+CHAR(10)+
		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      AnySearch			nvarchar(max)	'AnySearch/text()',"+CHAR(10)+
		"	      AnySearchOperator		tinyint		'AnySearch/@Operator/text()',"+CHAR(10)+
		"	      CaseKey			nvarchar(11)	'CaseKey/text()',"+CHAR(10)+
		"	      CaseReference		nvarchar(max)	'CaseReference/text()',"+CHAR(10)+
		"	      CaseReferenceOperator	tinyint		'CaseReference/@Operator/text()',"+CHAR(10)+
	 	"	      IsWithinFileCover		bit		'CaseReference/@IsWithinFileCover',"+CHAR(10)+
	 	"	      CaseReferenceStem		nvarchar(30)	'CaseReferenceStem/text()',"+CHAR(10)+
		"	      CaseReferenceStemOperator	tinyint		'CaseReferenceStem/@Operator/text()',"+CHAR(10)+
		"	      CaseTypeKey		nvarchar(200)	'CaseTypeKey/text()',"+CHAR(10)+
		"	      CaseTypeKeyOperator	tinyint		'CaseTypeKey/@Operator/text()',"+CHAR(10)+
		"	      IncludeCRMCasesCaseType		bit		'CaseTypeKey/@IncludeCRMCases/text()',"+CHAR(10)+
		"	      CountryCodes		nvarchar(1000)	'CountryCodes/text()',"+CHAR(10)+
		"	      CountryCodesOperator	tinyint		'CountryCodes/@Operator/text()',"+CHAR(10)+
		"	      IncludeDesignations	bit		'CountryCodes/@IncludeDesignations',"+CHAR(10)+
		"	      IncludeMembers		bit		'CountryCodes/@IncludeMembers',"+CHAR(10)+
		"	      PropertyTypeKey		nvarchar(200)	'PropertyTypeKey/text()',"+CHAR(10)+
		"	      PropertyTypeKeyOperator	tinyint		'PropertyTypeKey/@Operator/text()',"+CHAR(10)+
		"	      PropertyTypeKeysOperator 	tinyint		'PropertyTypeKeys/@Operator/text()',"+CHAR(10)+
		"	      CategoryKey		nvarchar(200)	'CategoryKey/text()',"+CHAR(10)+
		"	      CategoryKeyOperator	tinyint		'CategoryKey/@Operator/text()',"+CHAR(10)+
		"	      CategoryKeysOperator	tinyint		'CategoryKeys/@Operator/text()',"+CHAR(10)+
		"	      SubTypeKey		nvarchar(200)	'SubTypeKey/text()',"+CHAR(10)+
		"	      SubTypeKeyOperator	tinyint		'SubTypeKey/@Operator/text()',"+CHAR(10)+
		"	      BasisKey			nvarchar(200)	'BasisKey/text()',"+CHAR(10)+
		"	      BasisKeyOperator		tinyint		'BasisKey/@Operator/text()',"+CHAR(10)+
		"	      Classes			nvarchar(1000)	'Classes/text()',"+CHAR(10)+
		"	      ClassesOperator 		tinyint 	'Classes/@Operator/text()',"+CHAR(10)+
		"	      IsLocal			bit		'Classes/@IsLocal',"+CHAR(10)+
		"	      IsInternational		bit		'Classes/@IsInternational',"+CHAR(10)+
		"	      KeyWord			nvarchar(50)	'KeyWord/text()',"+CHAR(10)+
		"	      KeyWordOperator		tinyint		'KeyWord/@Operator/text()',"+CHAR(10)+
		"	      Title			nvarchar(254)	'Title/text()',"+CHAR(10)+
		"	      TitleOperator		tinyint		'Title/@Operator/text()',"+CHAR(10)+
		"	      UseSoundsLike		bit		'Title/@UseSoundsLike',"+CHAR(10)+
		"	      TypeOfMarkKey		int		'TypeOfMarkKey/text()',"+CHAR(10)+
		"	      TypeOfMarkKeyOperator	tinyint		'TypeOfMarkKey/@Operator/text()',"+CHAR(10)+
		"	      EntitySize			int			'EntitySize/text()',"+CHAR(10)+
		"	      EntitySizeOperator	tinyint		'EntitySize/@Operator/text()'"+CHAR(10)+
		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @sAnySearch 			nvarchar(max)			output,
					  @nAnySearchOperator		tinyint				output,
					  @sCaseKey			nvarchar(11)			output,
					  @sCaseReference		nvarchar(max)			output,
					  @nCaseReferenceOperator	tinyint				output,
					  @bIsWithinFileCover		bit				output,
					  @sCaseReferenceStem		nvarchar(30)			output,
					  @nCaseReferenceStemOperator	tinyint				output,
					  @sCaseTypeKey		nvarchar(200)			output,
					  @nCaseTypeKeyOperator		tinyint				output,
					  @bIncludeCRMCasesCaseType		bit				output,
					  @sCountryCodes		nvarchar(1000)			output,
					  @nCountryCodesOperator	tinyint				output,
					  @bIncludeDesignations		bit				output,
					  @bIncludeMembers		bit				output,
					  @sPropertyTypeKey		nvarchar(200)			output,
					  @nPropertyTypeKeyOperator 	tinyint				output,
					  @nPropertyTypeKeysOperator	tinyint				output,
					  @sCategoryKey			nvarchar(200)			output,
					  @nCategoryKeyOperator		tinyint				output,
					  @sSubTypeKey			nvarchar(200)			output,
					  @nSubTypeKeyOperator		tinyint				output,
					  @sBasisKey			nvarchar(200)			output,
					  @nBasisKeyOperator		tinyint				output,
					  @sClasses			nvarchar(1000)			output,
					  @nClassesOperator		tinyint				output,
					  @bIsLocal			bit				output,
					  @bIsInternational		bit				output,
					  @sKeyWord			nvarchar(50)			output,
					  @nKeyWordOperator		tinyint				output,					  
					  @sTitle			nvarchar(254)			output,
					  @nTitleOperator		tinyint				output,
					  @bTitleSoundsLike		bit				output,
					  @nTypeOfMarkKey		int				output,
					  @nTypeOfMarkKeyOperator	tinyint				output,
					  @nEntitySize				int					output,
					  @nEntitySizeOperator		tinyint				output',
					  @idoc				= @idoc,
					  @sAnySearch 			= @sAnySearch			output,
					  @nAnySearchOperator		= @nAnySearchOperator		output,
					  @sCaseKey			= @sCaseKey			output,
					  @sCaseReference		= @sCaseReference		output,
					  @nCaseReferenceOperator	= @nCaseReferenceOperator	output,
					  @bIsWithinFileCover		= @bIsWithinFileCover		output,
					  @sCaseReferenceStem		= @sCaseReferenceStem		output,
					  @nCaseReferenceStemOperator	= @nCaseReferenceStemOperator	output,
					  @sCaseTypeKey		= @sCaseTypeKey		output,
					  @nCaseTypeKeyOperator		= @nCaseTypeKeyOperator		output,
					  @bIncludeCRMCasesCaseType		= @bIncludeCRMCasesCaseType		output,
					  @sCountryCodes		= @sCountryCodes		output,
					  @nCountryCodesOperator	= @nCountryCodesOperator	output,
					  @bIncludeDesignations		= @bIncludeDesignations		output,
					  @bIncludeMembers		= @bIncludeMembers		output,
					  @sPropertyTypeKey		= @sPropertyTypeKey		output,
					  @nPropertyTypeKeyOperator 	= @nPropertyTypeKeyOperator	output,
					  @nPropertyTypeKeysOperator	= @nPropertyTypeKeysOperator	output,
					  @sCategoryKey			= @sCategoryKey			output,
					  @nCategoryKeyOperator		= @nCategoryKeyOperator		output,
					  @sSubTypeKey			= @sSubTypeKey			output,
					  @nSubTypeKeyOperator		= @nSubTypeKeyOperator		output,
					  @sBasisKey			= @sBasisKey			output,
					  @nBasisKeyOperator		= @nBasisKeyOperator		output,
					  @sClasses			= @sClasses			output,
					  @nClassesOperator		= @nClassesOperator		output,
					  @bIsLocal			= @bIsLocal			output,
					  @bIsInternational		= @bIsInternational		output,
					  @sKeyWord			= @sKeyWord			output,
					  @nKeyWordOperator		= @nKeyWordOperator		output,
					  @sTitle			= @sTitle			output,
					  @nTitleOperator		= @nTitleOperator		output,
					  @bTitleSoundsLike		= @bTitleSoundsLike		output,
					  @nTypeOfMarkKey		= @nTypeOfMarkKey		output,
					  @nTypeOfMarkKeyOperator	= @nTypeOfMarkKeyOperator	output,
					  @nEntitySize				= @nEntitySize			output,
					  @nEntitySizeOperator		= @nEntitySizeOperator	output


		-- Add more variables to avoid exceeding 4000 chars above.
		If @nErrorCode = 0
		Begin
			Set @sSQLString =
			"Select @nInstructionKey	= InstructionKey,"+CHAR(10)+
			"@nInstructionKeyOperator	= InstructionKeyOperator,"+CHAR(10)+
			"@bCaseNameGroupBooleanOr	= CaseNameGroupBooleanOr,"+CHAR(10)+
			"@nCaseNameFromCaseCaseKey	= CaseNameFromCaseCaseKey,"+CHAR(10)+
			"@sCaseNameFromCaseNameTypeKey	= CaseNameFromCaseNameTypeKey,"+CHAR(10)+
			"@sCaseTypeKeys			= CaseTypeKeys,"+CHAR(10)+
			"@nCaseTypeKeysOperator		= CaseTypeKeysOperator,"+CHAR(10)+
			"@bIncludeCRMCases = IncludeCRMCases,"+CHAR(10)+
			"@sFamilyKeys			= upper(FamilyKeys),"+CHAR(10)+
			"@nFamilyKeyOperator		= FamilyKeyOperator,"+CHAR(10)+
			"@nFamilyKeyListOperator		= FamilyKeyListOperator,"+CHAR(10)+
			"@nBudgetAmountFrom 		= BudgetAmountFrom,"+CHAR(10)+
			"@nBudgetAmountTo 		= BudgetAmountTo,"+CHAR(10)+
			"@nBudgetAmountOperator 	= BudgetAmountOperator,"+CHAR(10)+
			"@sSuitableForRelationshipCode 	= SuitableForRelationshipCode,"+CHAR(10)+
			"@nSuitableForRelationshipCaseKey = SuitableForRelationshipCaseKey,"+CHAR(10)+
			"@nCaseAccessMode 		= AccessMode,"+CHAR(10)+
			"@sCaseKeys			= CaseKeys,"+CHAR(10)+
			"@sFileLocationKeys		= FileLocationKeys,"+CHAR(10)+
			"@sFileLocationBayNo		= FileLocationBayNo,"+CHAR(10)+
			"@nFileLocationOperator		= FileLocationOperator,"+CHAR(10)+
			"@nFileLocationBayNoOperator	= FileLocationBayNoOperator,"+CHAR(10)+
			"@nCaseKeysOperator	= CaseKeysOperator"+CHAR(10)+
			"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
			"	WITH ("+CHAR(10)+
			"InstructionKey 		int 		'InstructionKey/text()',"+CHAR(10)+
			"InstructionKeyOperator		tinyint 	'InstructionKey/@Operator/text()',"+CHAR(10)+
			"CaseNameGroupBooleanOr		bit 		'CaseNameGroup/@BooleanOr/text()',"+CHAR(10)+
			"CaseNameFromCaseCaseKey 	int 		'CaseNameFromCase/CaseKey/text()',"+CHAR(10)+
			"CaseNameFromCaseNameTypeKey	nvarchar(3)	'CaseNameFromCase/NameTypeKey/text()',"+CHAR(10)+
			"CaseTypeKeys		nvarchar(200)	'CaseTypeKeys/text()',"+CHAR(10)+
			"CaseTypeKeysOperator	tinyint		'CaseTypeKeys/@Operator/text()',"+CHAR(10)+
			"IncludeCRMCases		bit			'CaseTypeKeys/@IncludeCRMCases/text()',"+CHAR(10)+
			"FamilyKeys		nvarchar(1000)	'FamilyKey/text()',"+CHAR(10)+
			"FamilyKeyOperator		tinyint		'FamilyKey/@Operator/text()',"+CHAR(10)+
			"FamilyKeyListOperator		tinyint		'FamilyKeyList/@Operator/text()',"+CHAR(10)+
			"BudgetAmountFrom		decimal(11,2)	'BudgetAmount/From/text()',"+CHAR(10)+
			"BudgetAmountTo			decimal(11,2)	'BudgetAmount/To/text()',"+CHAR(10)+
			"BudgetAmountOperator		tinyint 	'BudgetAmount/@Operator/text()',"+CHAR(10)+
			"SuitableForRelationshipCode	nvarchar(3) 	'SuitableForRelationship/RelationshipCode/text()',"+CHAR(10)+
			"SuitableForRelationshipCaseKey int 		'SuitableForRelationship/RelatedCaseKey/text()',"+CHAR(10)+
			"AccessMode 			tinyint 	'AccessMode/text()',"+CHAR(10)+
			"CaseKeys			nvarchar(max)	'CaseKeys/text()',"+CHAR(10)+
			"FileLocationKeys		nvarchar(max)	'FileLocationKeys/text()',"+CHAR(10)+
			"FileLocationBayNo		nvarchar(40)	'FileLocationBayNo/text()',"+CHAR(10)+
			"FileLocationOperator		tinyint		'FileLocationKeys/@Operator/text()',"+CHAR(10)+
			"FileLocationBayNoOperator	tinyint		'FileLocationBayNo/@Operator/text()',"+CHAR(10)+
			"CaseKeysOperator 		tinyint		'CaseKeys/@Operator/text()'"+CHAR(10)+
			")"

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@idoc				int,
						  @nInstructionKey		int				output,
						  @nInstructionKeyOperator	tinyint				output,
						  @bCaseNameGroupBooleanOr	bit				output,
						  @nCaseNameFromCaseCaseKey	int				output,
						  @sCaseNameFromCaseNameTypeKey nvarchar(100)			output,
						  @sCaseTypeKeys			nvarchar(200)	output,
						  @nCaseTypeKeysOperator	tinyint			output,
						  @bIncludeCRMCases			bit				output,
						  @sFamilyKeys			nvarchar(max)			output,
						  @nFamilyKeyOperator		tinyint				output,
					  	  @nFamilyKeyListOperator		tinyint				output,
						  @nBudgetAmountFrom		decimal(11,2)			output,
						  @nBudgetAmountTo		decimal(11,2)			output,
						  @nBudgetAmountOperator 	tinyint				output,
						  @sSuitableForRelationshipCode nvarchar(3)			output,
						  @nSuitableForRelationshipCaseKey int				output,
						  @nCaseAccessMode		tinyint				output,
						  @sCaseKeys              	nvarchar(max)			output,
				                  @sFileLocationKeys		nvarchar(max)			output,
				                  @sFileLocationBayNo		nvarchar(40)			output,
				                  @nFileLocationOperator	tinyint				output,
				                  @nFileLocationBayNoOperator	tinyint				output,
						  @nCaseKeysOperator	tinyint					output ',
						  @idoc				= @idoc,
					  	  @nInstructionKey		= @nInstructionKey		output,
					  	  @nInstructionKeyOperator	= @nInstructionKeyOperator	output,
					    	  @bCaseNameGroupBooleanOr	= @bCaseNameGroupBooleanOr	output,
						  @nCaseNameFromCaseCaseKey	= @nCaseNameFromCaseCaseKey	output,
						  @sCaseNameFromCaseNameTypeKey = @sCaseNameFromCaseNameTypeKey output,
						  @sCaseTypeKeys		= @sCaseTypeKeys		output,
						  @nCaseTypeKeysOperator		= @nCaseTypeKeysOperator		output,
						  @bIncludeCRMCases		= @bIncludeCRMCases		output,
						  @sFamilyKeys			= @sFamilyKeys			output,
					  	  @nFamilyKeyOperator		= @nFamilyKeyOperator		output,
					  	  @nFamilyKeyListOperator		= @nFamilyKeyListOperator		output,
					  	  @nBudgetAmountFrom		= @nBudgetAmountFrom		output,
						  @nBudgetAmountTo		= @nBudgetAmountTo		output,
						  @nBudgetAmountOperator 	= @nBudgetAmountOperator	output,
						  @sSuitableForRelationshipCode = @sSuitableForRelationshipCode output,
						  @nSuitableForRelationshipCaseKey = @nSuitableForRelationshipCaseKey output,
						  @nCaseAccessMode		= @nCaseAccessMode		output,
					          @sCaseKeys                	= @sCaseKeys  			output,
						  @sFileLocationKeys		= @sFileLocationKeys		output,
						  @sFileLocationBayNo		= @sFileLocationBayNo		output,
						  @nFileLocationOperator	= @nFileLocationOperator	output,
						  @nFileLocationBayNoOperator	= @nFileLocationBayNoOperator	output,
					          @nCaseKeysOperator		= @nCaseKeysOperator 		output
		End

		-- RFC4555 Allow searching on multiple property types
		If @nPropertyTypeKeysOperator in (0,1)
		Begin
			Set @sSQLString =
			"Select @sPropertyTypeKeyList		= @sPropertyTypeKeyList + "+CHAR(10)+
				"nullif(',',','+@sPropertyTypeKeyList)+"+CHAR(10)+
			"	dbo.fn_WrapQuotes(PropertyTypeKey,0,@pbCalledFromCentura)"+CHAR(10)+
			"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+
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

		-- Retrieve the Event and Standing Instructions related parameters
		Set @sSQLString =
		"Select @sEventKeys			= EventKeys,"+CHAR(10)+
		"	@nEventDateOperator		= EventDateOperator,"+CHAR(10)+
		"	@sEventNoteTypeKeys		= EventNoteTypeKeys,"+CHAR(10)+
		"	@nEventNoteTypeKeysOperator	= EventNoteTypeKeysOperator,"+CHAR(10)+
		"	@sEventNoteText			= EventNoteText,"+CHAR(10)+
		"	@nEventNoteTextOperator		= EventNoteTextOperator,"+CHAR(10)+
		"	@nEventKeyForCompare		= EventKeyForCompare,"+CHAR(10)+
		"	@bIncludeClosedActions		= IncludeClosedActions,"+CHAR(10)+
		"	@bByDueDate			= ByDueDate,"+CHAR(10)+
		"	@bByEventDate			= ByEventDate,"+CHAR(10)+
		"	@bIsRenewalsOnly		= IsRenewalsOnly,"+CHAR(10)+
		"	@bIsNonRenewalsOnly		= IsNonRenewalsOnly,"+CHAR(10)+
		"	@dtDateRangeFrom		= DateRangeFrom,"+CHAR(10)+
		"	@dtDateRangeTo			= DateRangeTo,"+CHAR(10)+
		"	@nImportanceLevelOperator	= ImportanceLevelOperator,"+char(10)+
		"	@sImportanceLevelFrom		= ImportanceLevelFrom,"+char(10)+
		"	@sImportanceLevelTo		= ImportanceLevelTo,"+char(10)+
		"	@sActionKey			= ActionKey,"+char(10)+
		"	@nActionKeyOperator		= ActionKeyOperator,"+char(10)+
		"	@bIsOpen			= IsOpen,"+char(10)+
		"	@bIncludeInherited		= IncludeInherited,"+CHAR(10)+
		"	@nCharacteristicFlag		= CharacteristicFlag,"+CHAR(10)+
		"	@nCharacteristicFlagOperator	= CharacteristicFlagOperator,"+CHAR(10)+
		"	@sNameRelations			= NameRelationships,"+CHAR(10)+
		"	@nNameRelationsOperator		= NameRelationshipOperator,"+CHAR(10)+
		"	@sRelatedNameTypes		= RelatedNameTypes"+CHAR(10)+
		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      EventKeys			nvarchar(max)	'Event/EventKey/text()',"+CHAR(10)+
		"	      EventDateOperator		tinyint		'Event/@Operator/text()',"+CHAR(10)+
		"	      EventNoteTypeKeys		nvarchar(4000)	'Event/EventNoteTypeKeys/text()',"+CHAR(10)+
		"	      EventNoteTypeKeysOperator	tinyint		'Event/EventNoteTypeKeys/@Operator/text()',"+CHAR(10)+
		"	      EventNoteText		nvarchar(max)	'Event/EventNoteText/text()',"+CHAR(10)+
		"	      EventNoteTextOperator	tinyint		'Event/EventNoteText/@Operator/text()',"+CHAR(10)+
		"	      EventKeyForCompare	int		'Event/EventKeyForCompare/text()',"+CHAR(10)+
		"	      IncludeClosedActions	bit		'Event/@IncludeClosedActions',"+CHAR(10)+
		"	      ByDueDate			bit		'Event/@ByDueDate',"+CHAR(10)+
		"	      ByEventDate		bit		'Event/@ByEventDate',"+CHAR(10)+
		"	      IsRenewalsOnly		bit		'Event/@IsRenewalsOnly',"+CHAR(10)+
		"	      IsNonRenewalsOnly		bit		'Event/@IsNonRenewalsOnly',"+CHAR(10)+
		"	      DateRangeFrom		datetime	'Event/DateRange/From/text()',"+CHAR(10)+
		"	      DateRangeTo		datetime	'Event/DateRange/To/text()',"+CHAR(10)+
		"	      ImportanceLevelOperator	tinyint		'Event/ImportanceLevel/@Operator/text()',"+char(10)+
		"	      ImportanceLevelFrom	nvarchar(2)	'Event/ImportanceLevel/From/text()',"+char(10)+
		"	      ImportanceLevelTo		nvarchar(2)	'Event/ImportanceLevel/To/text()',"+char(10)+
		"	      ActionKey			nvarchar(2)	'ActionKey/text()',"+char(10)+
		"	      ActionKeyOperator		tinyint		'ActionKey/@Operator/text()',"+char(10)+
		"	      IsOpen			bit		'ActionKey/@IsOpen',"+char(10)+
		"	      IncludeInherited		bit		'StandingInstructions/@IncludeInherited/text()',"+CHAR(10)+
		"	      CharacteristicFlag	smallint	'StandingInstructions/CharacteristicFlag/text()',"+CHAR(10)+
		"	      CharacteristicFlagOperator tinyint	'StandingInstructions/CharacteristicFlag/@Operator/text()',"+CHAR(10)+
		"	      NameRelationships		nvarchar(200)	'NameRelationships/Relationships/text()',"+CHAR(10)+
		"	      NameRelationshipOperator	tinyint		'NameRelationships/@Operator/text()',"+CHAR(10)+
		"	      RelatedNameTypes		nvarchar(1000)	'NameRelationships/NameTypes/text()'"+CHAR(10)+
	     	"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @sEventKeys			nvarchar(max)			output,
					  @nEventDateOperator		tinyint				output,
					  @sEventNoteTypeKeys		nvarchar(4000)			output,
					  @nEventNoteTypeKeysOperator	tinyint				output,
					  @sEventNoteText		nvarchar(max)			output,
					  @nEventNoteTextOperator	tinyint				output,
					  @nEventKeyForCompare		int				output,
					  @bIncludeClosedActions	bit				output,
					  @bByDueDate			bit				output,
					  @bByEventDate			bit				output,
					  @bIsRenewalsOnly		bit				output,
					  @bIsNonRenewalsOnly		bit				output,
					  @dtDateRangeFrom		datetime			output,
					  @dtDateRangeTo		datetime			output,
					  @nImportanceLevelOperator	tinyint				output,
					  @sImportanceLevelFrom		nvarchar(2)			output,
					  @sImportanceLevelTo		nvarchar(2)			output,
					  @sActionKey			nvarchar(2)			output,
					  @nActionKeyOperator		tinyint				output,
					  @bIsOpen			bit				output,
					  @bIncludeInherited		bit				output,
					  @nCharacteristicFlag		smallint			output,
					  @nCharacteristicFlagOperator	tinyint			  	output,
					  @sNameRelations		nvarchar(200)			output,
					  @nNameRelationsOperator	tinyint				output,
					  @sRelatedNameTypes		nvarchar(1000)			output',
					  @idoc				= @idoc,
					  @sEventKeys			= @sEventKeys			output,
					  @nEventDateOperator		= @nEventDateOperator		output,
					  @sEventNoteTypeKeys		= @sEventNoteTypeKeys		output,
					  @nEventNoteTypeKeysOperator	= @nEventNoteTypeKeysOperator	output,
					  @sEventNoteText		= @sEventNoteText		output,
					  @nEventNoteTextOperator	= @nEventNoteTextOperator	output,
					  @nEventKeyForCompare		= @nEventKeyForCompare		output,
					  @bIncludeClosedActions	= @bIncludeClosedActions	output,
					  @bByDueDate			= @bByDueDate			output,
					  @bByEventDate			= @bByEventDate			output,
					  @bIsRenewalsOnly		= @bIsRenewalsOnly		output,
					  @bIsNonRenewalsOnly		= @bIsNonRenewalsOnly		output,
					  @dtDateRangeFrom		= @dtDateRangeFrom		output,
					  @dtDateRangeTo		= @dtDateRangeTo		output,
					  @nImportanceLevelOperator	= @nImportanceLevelOperator	output,
					  @sImportanceLevelFrom		= @sImportanceLevelFrom		output,
					  @sImportanceLevelTo		= @sImportanceLevelTo		output,
					  @sActionKey			= @sActionKey			output,
					  @nActionKeyOperator		= @nActionKeyOperator		output,
					  @bIsOpen			= @bIsOpen			output,
					  @bIncludeInherited		= @bIncludeInherited		output,
					  @nCharacteristicFlag		= @nCharacteristicFlag	   	output,
					  @nCharacteristicFlagOperator	= @nCharacteristicFlagOperator  output,
					  @sNameRelations		= @sNameRelations		output,
					  @nNameRelationsOperator	= @nNameRelationsOperator	output,
					  @sRelatedNameTypes		= @sRelatedNameTypes		output

		Select @sSQLString =
		"Select @sPeriodType= 	CASE WHEN PeriodType = 'D' THEN 'dd'"+CHAR(10)+
		"			     WHEN PeriodType = 'W' THEN 'wk'"+CHAR(10)+
		"			     WHEN PeriodType = 'M' THEN 'mm'"+CHAR(10)+
		"			     WHEN PeriodType = 'Y' THEN 'yy'"+CHAR(10)+
		"		   	END,"+CHAR(10)+
		"@nPeriodQuantity	= PeriodQuantity,"+CHAR(10)+
		"@sStatusKey		= StatusKey,"+CHAR(10)+
		"@nStatusKeyOperator	= StatusKeyOperator,"+CHAR(10)+
		"@sRenewalStatusKeys	= RenewalStatusKey,"+CHAR(10)+
		"@nRenewalStatusKeyOperator= RenewalStatusKeyOperator,"+CHAR(10)+
		"@bIsPending		= IsPending,"+CHAR(10)+
		"@bIsRegistered		= IsRegistered,"+CHAR(10)+
		"@bIsDead		= IsDead,"+CHAR(10)+
		"@bCheckDeadCaseRestriction= CheckDeadCaseRestriction,"+CHAR(10)+
		"@bRenewalFlag		= HasRenewalStatus,"+CHAR(10)+
		"@sRenewalStatusDescription= RenewalStatusDescription,"+CHAR(10)+
		"@nRenewalStatusDescriptionOperator= RenewalStatusDescriptionOperator,"+CHAR(10)+
		"@bHasLettersOnQueue	= HasLettersOnQueue,"+CHAR(10)+
		"@bHasChargesOnQueue	= HasChargesOnQueue,"+CHAR(10)+
		"@sQuickIndexKey	= QuickIndex,"+CHAR(10)+
		"@sQuickIndexKeyOperator= QuickIndexOperator,"+CHAR(10)+
		"@sOfficeKeys		= OfficeKeys,"+CHAR(10)+
		"@nOfficeKeyOperator	= OfficeKeyOperator,"+CHAR(10)+
	        "@sOffice		= Office,"+CHAR(10)+
		"@nOfficeOperator	= OfficeOperator,"+CHAR(10)+
		"@sClientKeys		= ClientKeys,"+CHAR(10)+
	 	"@nClientKeysOperator	= ClientKeysOperator,"+CHAR(10)+
		"@sClientReference	= ClientReference,"+CHAR(10)+
		"@nClientReferenceOperator= ClientReferenceOperator,"+CHAR(10)+
		"@sOfficialNumber	= OfficialNumber,"+CHAR(10)+
		"@nOfficialNumberOperator= OfficialNumberOperator,"+CHAR(10)+
		"@sNumberTypeKey	= NumberTypeKey,"+CHAR(10)+
		"@bUseRelatedCase	= UseRelatedCase,"+CHAR(10)+
		"@bUseNumericSearch	= UseNumericSearch,"+CHAR(10)+
		"@bUseCurrent		= UseCurrent,"+CHAR(10)+
		"@sReferenceNo		= ReferenceNo,"+CHAR(10)+
		"@sReferenceTypeKey	= ReferenceTypeKey,"+CHAR(10)+
		"@nReferenceNoOperator	= ReferenceNoOperator,"+CHAR(10)+
		"@bHasIncompletePolicing= HasIncompletePolicing,"+CHAR(10)+
		"@bHasIncompleteNameChange= HasIncompleteNameChange,"+CHAR(10)+
		"@bOnCPAUpdate		= OnCPAUpdate,"+CHAR(10)+
		"@nCPASentBatchNo	= CPASentBatchNo,"+CHAR(10)+
		"@bIsPrimeCasesOnly	= IsPrimeCasesOnly,"+CHAR(10)+
		"@nCaseListKeyOperator	= CaseListKeyOperator,"+CHAR(10)+
		"@nCaseListKey		= CaseListKey"+CHAR(10)+
		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)
		select	@sSQLString = @sSQLString +
		"PeriodType		nvarchar(2)	'Event/Period/Type/text()',"+CHAR(10)+
		"PeriodQuantity		smallint	'Event/Period/Quantity/text()',"+CHAR(10)+
		"StatusKey		nvarchar(4000)	'StatusKey/text()',"+CHAR(10)+
		"StatusKeyOperator	tinyint		'StatusKey/@Operator/text()',"+CHAR(10)+
		"RenewalStatusKey	nvarchar(3500)	'RenewalStatusKey/text()',"+CHAR(10)+
		"RenewalStatusKeyOperator tinyint		'RenewalStatusKey/@Operator/text()',"+CHAR(10)+
		"IsPending		bit		'StatusFlags/IsPending',"+CHAR(10)+
		"IsRegistered		bit		'StatusFlags/IsRegistered',"+CHAR(10)+
		"IsDead			bit		'StatusFlags/IsDead',"+CHAR(10)+
		"CheckDeadCaseRestriction bit		'StatusFlags/@CheckDeadCaseRestriction/text()',"+CHAR(10)+
		"HasRenewalStatus	bit		'HasRenewalStatus',"+CHAR(10)+
		"RenewalStatusDescription nvarchar(50)	'RenewalStatusDescription/text()',"+CHAR(10)+
		"RenewalStatusDescriptionOperator tinyint 'RenewalStatusDescription/@Operator/text()',"+CHAR(10)+
		"HasLettersOnQueue	bit		'QueueFlags/HasLettersOnQueue',"+CHAR(10)+
		"HasChargesOnQueue	bit		'QueueFlags/HasChargesOnQueue',"+CHAR(10)+
		"QuickIndex		nvarchar(10)	'QuickIndex/text()',"+CHAR(10)+
		"QuickIndexOperator	tinyint		'QuickIndex/@Operator/text()',"+CHAR(10)+
		"Office			nvarchar(4000)	'Office/text()',"+CHAR(10)+
		"OfficeOperator		tinyint		'Office/@Operator/text()',"+CHAR(10)+
		"OfficeKeys		nvarchar(4000)	'OfficeKeys/text()',"+CHAR(10)+
		"OfficeKeyOperator	tinyint		'OfficeKeys/@Operator/text()',"+CHAR(10)+
		"ClientKeys		nvarchar(4000)	'ClientKeys/text()',"+CHAR(10)+
		"ClientKeysOperator	tinyint		'ClientKeys/@Operator/text()',"+CHAR(10)+
		"ClientReference	nvarchar(80)	'ClientReference/text()',"+CHAR(10)+
		"ClientReferenceOperator tinyint	'ClientReference/@Operator/text()',"+CHAR(10)+
		"OfficialNumber		nvarchar(36)	'OfficialNumber/Number/text()',"+CHAR(10)+
		"OfficialNumberOperator	tinyint		'OfficialNumber/@Operator/text()',"+CHAR(10)+
		"NumberTypeKey		nvarchar(3)	'OfficialNumber/TypeKey/text()',"+CHAR(10)+
		"UseRelatedCase		bit		'OfficialNumber/@UseRelatedCase',"+CHAR(10)+
		"UseNumericSearch	bit		'OfficialNumber/Number/@UseNumericSearch',"+CHAR(10)+
		"UseCurrent		nvarchar(36)	'OfficialNumber/@UseCurrent',"+CHAR(10)+
		"ReferenceNo		nvarchar(80)	'CaseNameReference/ReferenceNo/text()',"+CHAR(10)+
		"ReferenceTypeKey	nvarchar(100)	'CaseNameReference/TypeKey/text()',"+CHAR(10)+
		"ReferenceNoOperator	tinyint		'CaseNameReference/@Operator/text()',"+CHAR(10)+
		"HasIncompletePolicing	bit		'HasIncompletePolicing',"+CHAR(10)+
		"HasIncompleteNameChange bit		'HasIncompleteNameChange',"+CHAR(10)+
		"OnCPAUpdate		bit		'OnCPAUpdate',"+CHAR(10)+
		"CPASentBatchNo		int		'CPASentBatchNo',"+CHAR(10)+
		"IsPrimeCasesOnly	bit		'CaseList/@IsPrimeCasesOnly/text()',"+CHAR(10)+
		"CaseListKeyOperator	tinyint		'CaseList/CaseListKey/@Operator/text()',"+CHAR(10)+
		"CaseListKey		int		'CaseList/CaseListKey/text()'"+CHAR(10)+
		")"

		execute sp_executesql @sSQLString,
					N'@idoc					int,
					  @sPeriodType				nvarchar(2)			output,
					  @nPeriodQuantity			smallint			output,
					  @sStatusKey				nvarchar(4000)			output,
					  @nStatusKeyOperator			tinyint				output,
					  @sRenewalStatusKeys			nvarchar(3500)			output,
					  @nRenewalStatusKeyOperator		tinyint				output,
					  @bIsPending				bit				output,
				          @bIsRegistered			bit				output,
					  @bIsDead				bit				output,
					  @bCheckDeadCaseRestriction		bit				output,
					  @bRenewalFlag				bit				output,
				 	  @sRenewalStatusDescription		nvarchar(50)			output,
					  @nRenewalStatusDescriptionOperator	tinyint				output,
					  @bHasLettersOnQueue			bit				output,
					  @bHasChargesOnQueue			bit				output,
					  @sQuickIndexKey			nvarchar(10)			output,
					  @sQuickIndexKeyOperator		tinyint				output,
					  @sOffice				nvarchar(4000)			output,
					  @nOfficeOperator			tinyint				output,
					  @sOfficeKeys				nvarchar(4000)			output,
					  @nOfficeKeyOperator			tinyint				output,
					  @sClientKeys				nvarchar(4000)			output,
					  @nClientKeysOperator			tinyint				output,
					  @sClientReference			nvarchar(80)			output,
					  @nClientReferenceOperator		tinyint				output,
					  @sOfficialNumber			nvarchar(36)			output,
					  @nOfficialNumberOperator		tinyint				output,
					  @sNumberTypeKey			nvarchar(3)			output,
					  @bUseRelatedCase			bit				output,
					  @bUseNumericSearch			bit				output,
					  @bUseCurrent				bit				output,
					  @sReferenceNo				nvarchar(80)			output,
					  @sReferenceTypeKey			nvarchar(100)			output,
					  @nReferenceNoOperator			tinyint				output,
					  @bHasIncompletePolicing		bit				output,
					  @bHasIncompleteNameChange		bit				output,
					  @bOnCPAUpdate				bit				output,
					  @nCPASentBatchNo			int				output,
					  @bIsPrimeCasesOnly			bit				output,
					  @nCaseListKeyOperator			tinyint				output,
					  @nCaseListKey				int				output',
					  @idoc					= @idoc,
					  @sPeriodType				= @sPeriodType			output,
					  @nPeriodQuantity			= @nPeriodQuantity		output,
					  @sStatusKey				= @sStatusKey			output,
					  @nStatusKeyOperator			= @nStatusKeyOperator		output,
					  @sRenewalStatusKeys			= @sRenewalStatusKeys		output,
					  @nRenewalStatusKeyOperator		= @nRenewalStatusKeyOperator	output,
					  @bIsPending				= @bIsPending			output,
					  @bIsRegistered			= @bIsRegistered		output,
					  @bIsDead				= @bIsDead			output,
					  @bCheckDeadCaseRestriction		= @bCheckDeadCaseRestriction	output,
					  @bRenewalFlag				= @bRenewalFlag			output,
					  @sRenewalStatusDescription		= @sRenewalStatusDescription 	output,
					  @nRenewalStatusDescriptionOperator	= @nRenewalStatusDescriptionOperator output,
					  @bHasLettersOnQueue			= @bHasLettersOnQueue		output,
					  @bHasChargesOnQueue			= @bHasChargesOnQueue		output,
					  @sQuickIndexKey			= @sQuickIndexKey   		output,
					  @sQuickIndexKeyOperator		= @sQuickIndexKeyOperator	output,
					  @sOffice				= @sOffice			output,
					  @nOfficeOperator			= @nOfficeOperator		output,
					  @sOfficeKeys				= @sOfficeKeys			output,
					  @nOfficeKeyOperator			= @nOfficeKeyOperator		output,
					  @sClientKeys				= @sClientKeys			output,
					  @nClientKeysOperator			= @nClientKeysOperator		output,
					  @sClientReference			= @sClientReference		output,
					  @nClientReferenceOperator		= @nClientReferenceOperator	output,
					  @sOfficialNumber			= @sOfficialNumber		output,
					  @nOfficialNumberOperator		= @nOfficialNumberOperator	output,
				          @sNumberTypeKey			= @sNumberTypeKey		output,
					  @bUseRelatedCase			= @bUseRelatedCase		output,
					  @bUseNumericSearch			= @bUseNumericSearch		output,
					  @bUseCurrent				= @bUseCurrent			output,
					  @sReferenceNo				= @sReferenceNo			output,
					  @sReferenceTypeKey			= @sReferenceTypeKey		output,
					  @nReferenceNoOperator			= @nReferenceNoOperator		output,
					  @bHasIncompletePolicing		= @bHasIncompletePolicing	output,
					  @bHasIncompleteNameChange		= @bHasIncompleteNameChange	output,
					  @bOnCPAUpdate				= @bOnCPAUpdate			output,
					  @nCPASentBatchNo			= @nCPASentBatchNo		output,
					  @bIsPrimeCasesOnly			= @bIsPrimeCasesOnly		output,
					  @nCaseListKeyOperator			= @nCaseListKeyOperator		output,
					  @nCaseListKey				= @nCaseListKey			output

		-- Retrieve the PatentTermAdjustments filter criteria using
		-- element-centric mapping
		Set @sSQLString =
		"Select	@nIPOfficeAdjustmentOperator	= IPOfficeAdjustmentOperator,"+CHAR(10)+
		"	@nIPOfficeAdjustmentFromDays	= IPOfficeAdjustmentFromDays,"+CHAR(10)+
		"	@nIPOfficeAdjustmentToDays	= IPOfficeAdjustmentToDays,"+CHAR(10)+
		"	@nCalculatedAdjustmentOperator	= CalculatedAdjustmentOperator,"+CHAR(10)+
		"	@nCalculatedAdjustmentFromDays	= CalculatedAdjustmentFromDays,"+CHAR(10)+
		"	@nCalculatedAdjustmentToDays	= CalculatedAdjustmentToDays,"+CHAR(10)+
		"	@nIPOfficeDelayOperator		= IPOfficeDelayOperator,"+CHAR(10)+
		"	@nIPOfficeDelayFromDays		= IPOfficeDelayFromDays,"+CHAR(10)+
		"	@nIPOfficeDelayToDays 		= IPOfficeDelayToDays,"+CHAR(10)+
		"	@nApplicantDelayOperator	= ApplicantDelayOperator,"+CHAR(10)+
		"	@nApplicantDelayFromDays	= ApplicantDelayFromDays,"+CHAR(10)+
		"	@nApplicantDelayToDays		= ApplicantDelayToDays,"+CHAR(10)+
		"	@bHasDiscrepancy		= HasDiscrepancy"+CHAR(10)+
		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/PatentTermAdjustments',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      IPOfficeAdjustmentOperator 	tinyint		'IPOfficeAdjustment/@Operator/text()',"+CHAR(10)+
		"	      IPOfficeAdjustmentFromDays	int		'IPOfficeAdjustment/FromDays/text()',"+CHAR(10)+
		"	      IPOfficeAdjustmentToDays		int		'IPOfficeAdjustment/ToDays/text()',"+CHAR(10)+
	 	"	      CalculatedAdjustmentOperator	tinyint		'CalculatedAdjustment/@Operator/text()',"+CHAR(10)+
		"	      CalculatedAdjustmentFromDays	int		'CalculatedAdjustment/FromDays/text()',"+CHAR(10)+
		"	      CalculatedAdjustmentToDays	int		'CalculatedAdjustment/ToDays/text()',"+CHAR(10)+
		"	      IPOfficeDelayOperator		tinyint		'IPOfficeDelay/@Operator/text()',"+CHAR(10)+
		"	      IPOfficeDelayFromDays		int		'IPOfficeDelay/FromDays/text()',"+CHAR(10)+
		"	      IPOfficeDelayToDays		int		'IPOfficeDelay/ToDays/text()',"+CHAR(10)+
		"	      ApplicantDelayOperator		tinyint		'ApplicantDelay/@Operator/text()',"+CHAR(10)+
		"	      ApplicantDelayFromDays		int		'ApplicantDelay/FromDays/text()',"+CHAR(10)+
		"	      ApplicantDelayToDays		int		'ApplicantDelay/ToDays/text()',"+CHAR(10)+
		"	      HasDiscrepancy			bit		'HasDiscrepancy'"+CHAR(10)+
		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				  int,
					  @nIPOfficeAdjustmentOperator	  tinyint			   output,
					  @nIPOfficeAdjustmentFromDays	  int			   	   output,
					  @nIPOfficeAdjustmentToDays	  int			   	   output,
					  @nCalculatedAdjustmentOperator  tinyint			   output,
					  @nCalculatedAdjustmentFromDays  int				   output,
					  @nCalculatedAdjustmentToDays	  int				   output,
					  @nIPOfficeDelayOperator	  tinyint			   output,
					  @nIPOfficeDelayFromDays	  int				   output,
					  @nIPOfficeDelayToDays 	  int				   output,
					  @nApplicantDelayOperator	  tinyint			   output,
					  @nApplicantDelayFromDays	  int				   output,
					  @nApplicantDelayToDays	  int				   output,
					  @bHasDiscrepancy		  bit				   output',
					  @idoc				  = @idoc,
					  @nIPOfficeAdjustmentOperator	  = @nIPOfficeAdjustmentOperator   output,
					  @nIPOfficeAdjustmentFromDays	  = @nIPOfficeAdjustmentFromDays   output,
					  @nIPOfficeAdjustmentToDays	  = @nIPOfficeAdjustmentToDays	   output,
					  @nCalculatedAdjustmentOperator  = @nCalculatedAdjustmentOperator output,
					  @nCalculatedAdjustmentFromDays  = @nCalculatedAdjustmentFromDays output,
					  @nCalculatedAdjustmentToDays	  = @nCalculatedAdjustmentToDays   output,
					  @nIPOfficeDelayOperator	  = @nIPOfficeDelayOperator	   output,
					  @nIPOfficeDelayFromDays	  = @nIPOfficeDelayFromDays	   output,
					  @nIPOfficeDelayToDays 	  = @nIPOfficeDelayToDays	   output,
					  @nApplicantDelayOperator	  = @nApplicantDelayOperator	   output,
					  @nApplicantDelayFromDays	  = @nApplicantDelayFromDays	   output,
					  @nApplicantDelayToDays	  = @nApplicantDelayToDays	   output,
					  @bHasDiscrepancy		  = @bHasDiscrepancy		   output


		-- RFC72612
        -- Retrieve the DesignElements filter criteria using
        -- element-centric mapping
        Set @sSQLString =
        "Select    @sFirmElement			= FirmElement,"+CHAR(10)+
        "    @nFirmElementOperator			= FirmElementOperator,"+CHAR(10)+
        "    @sClientElement				= ClientElement,"+CHAR(10)+
        "    @nClientElementOperator		= ClientElementOperator,"+CHAR(10)+
        "    @sOfficialElement				= OfficialElement,"+CHAR(10)+
        "    @nOfficialElementOperator		= OfficialElementOperator,"+CHAR(10)+
        "    @sRegistrationNo				= RegistrationNo,"+CHAR(10)+
        "    @nRegistrationNoOperator		= RegistrationNoOperator,"+CHAR(10)+
        "    @sTypeface						= Typeface,"+CHAR(10)+
        "    @nTypefaceOperator				= TypefaceOperator,"+CHAR(10)+
        "    @sElementDescription			= ElementDescription,"+CHAR(10)+
        "    @nElementDescriptionOperator   = ElementDescriptionOperator,"+CHAR(10)+
        "    @bIsRenew						= IsRenew"+CHAR(10)+
        "from    OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/DesignElements',2)"+CHAR(10)+
        "    WITH ("+CHAR(10)+
        "          FirmElementOperator			tinyint			'FirmElement/@Operator/text()',"+CHAR(10)+
        "          FirmElement					nvarchar(20)    'FirmElement/text()',"+CHAR(10)+
        "          ClientElementOperator		tinyint			'ClientElement/@Operator/text()',"+CHAR(10)+
        "          ClientElement				nvarchar(20)    'ClientElement/text()',"+CHAR(10)+
        "          OfficialElementOperator		tinyint			'OfficialElement/@Operator/text()',"+CHAR(10)+
        "          OfficialElement				nvarchar(20)    'OfficialElement/text()',"+CHAR(10)+
        "          RegistrationNoOperator		tinyint			'RegistrationNo/@Operator/text()',"+CHAR(10)+
        "          RegistrationNo               nvarchar(36)	'RegistrationNo/text()',"+CHAR(10)+
        "          TypefaceOperator				tinyint			'Typeface/@Operator/text()',"+CHAR(10)+
        "          Typeface						nvarchar(11)    'Typeface/text()',"+CHAR(10)+
        "          ElementDescriptionOperator	tinyint			'ElementDescription/@Operator/text()',"+CHAR(10)+
        "          ElementDescription			nvarchar(11)    'ElementDescription/text()',"+CHAR(10)+
        "          IsRenew						bit				'IsRenew'"+CHAR(10)+
        "         )"

        exec @nErrorCode = sp_executesql @sSQLString,
                    N'@idoc								int,
                        @sFirmElement					nvarchar(20)    output,
                        @nFirmElementOperator			tinyint         output,
                        @sClientElement					nvarchar(20)    output,
                        @nClientElementOperator			tinyint         output,
                        @sOfficialElement				nvarchar(20)    output,
                        @nOfficialElementOperator		tinyint			output,
                        @sRegistrationNo                nvarchar(36)    output,
                        @nRegistrationNoOperator        tinyint			output,
                        @sTypeface						nvarchar(11)    output,
                        @nTypefaceOperator				tinyint         output,
                        @sElementDescription            nvarchar(254)   output,
                        @nElementDescriptionOperator    tinyint         output,
                        @bIsRenew						bit				output',
                        @idoc							= @idoc,
                        @sFirmElement					= @sFirmElement					output,
                        @nFirmElementOperator			= @nFirmElementOperator			output,
                        @sClientElement					= @sClientElement				output,
                        @nClientElementOperator			= @nClientElementOperator		output,
                        @sOfficialElement				= @sOfficialElement				output,
                        @nOfficialElementOperator		= @nOfficialElementOperator		output,
                        @sRegistrationNo                = @sRegistrationNo				output,
                        @nRegistrationNoOperator        = @nRegistrationNoOperator		output,
                        @sTypeface						= @sTypeface					output,
                        @nTypefaceOperator				= @nTypefaceOperator			output,
                        @sElementDescription            = @sElementDescription			output,
                        @nElementDescriptionOperator    = @nElementDescriptionOperator	output,
                        @bIsRenew						= @bIsRenew						output

		-- Retrieve the Name Inheritance filter criteria using
		-- element-centric mapping
		Set @sSQLString =
		"Select @nInheritParentNameKey		= ParentNameKey,"+CHAR(10)+
		"	@nInheritParentNameKeyOperator	= ParentNameKeyOperator,"+CHAR(10)+
		"	@sInheritNameTypeKey		= NameTypeKey,"+CHAR(10)+
		"	@nInheritNameTypeKeyOperator	= NameTypeKeyOperator,"+CHAR(10)+
		"	@sInheritRelationshipKey	= DefaultRelationshipKey,"+CHAR(10)+
		"	@nInheritRelationshipKeyOperator= DefaultRelationshipKeyOperator"+CHAR(10)+

		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      ParentNameKey		nvarchar(4000) 'InheritedName/ParentNameKey/text()',"+CHAR(10)+
		"	      ParentNameKeyOperator	tinyint		'InheritedName/ParentNameKey/@Operator/text()',"+CHAR(10)+
		"	      NameTypeKey		nvarchar(3)	'InheritedName/NameTypeKey/text()',"+CHAR(10)+
		"	      NameTypeKeyOperator	tinyint		'InheritedName/NameTypeKey/@Operator/text()',"+CHAR(10)+
		"	      DefaultRelationshipKey	nvarchar(3)	'InheritedName/DefaultRelationshipKey/text()',"+CHAR(10)+
		"	      DefaultRelationshipKeyOperator tinyint	'InheritedName/DefaultRelationshipKey/@Operator/text()'"+CHAR(10)+

	     	"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc					int,
					  @nInheritParentNameKey		nvarchar(4000)			output,
					  @nInheritParentNameKeyOperator	tinyint			output,
					  @sInheritNameTypeKey			nvarchar(100)		output,
					  @nInheritNameTypeKeyOperator		tinyint			output,
					  @sInheritRelationshipKey		nvarchar(3)		output,
					  @nInheritRelationshipKeyOperator	tinyint			output',
					  @idoc				  = @idoc,
					  @nInheritParentNameKey	  = @nInheritParentNameKey		output,
					  @nInheritParentNameKeyOperator  = @nInheritParentNameKeyOperator 	output,
					  @sInheritNameTypeKey		  = @sInheritNameTypeKey		output,
					  @nInheritNameTypeKeyOperator	  = @nInheritNameTypeKeyOperator	output,
					  @sInheritRelationshipKey	  = @sInheritRelationshipKey		output,
					  @nInheritRelationshipKeyOperator	=@nInheritRelationshipKeyOperator	output

		
		-- Retrieve the Families filter criteria using
		-- element-centric mapping
		Set @sSQLString =
		"Select @sFamilyKeyList		= @sFamilyKeyList + "+CHAR(10)+
				"nullif(',',','+@sFamilyKeyList)+"+CHAR(10)+
			"	dbo.fn_WrapQuotes( upper(FamilyKey),0,0)"+CHAR(10)+
		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/FamilyKeyList/FamilyKey',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      FamilyKey	nvarchar(1000)	'text()'"+CHAR(10)+		
	     	"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc					int,
					  @sFamilyKeyList		nvarchar(max)		output',
					  @idoc					= @idoc,
					  @sFamilyKeyList		= @sFamilyKeyList		output

		-- SQA12427 - Retrieve additional filter criteria using element-centric mapping
		Set @sSQLString =
		"Select @bIncludeDraftCase			= IncludeDraftCase,"+CHAR(10)+
		"	@nEDEDataSourceNameNo			= EDEDataSourceNameNo,"+CHAR(10)+
		"	@sEDEBatchIdentifier			= EDEBatchIdentifier,"+CHAR(10)+
		"	@nAuditSessionNumber			= AuditSessionNumber,"+CHAR(10)+
		"	@nPurchaseOrderNoOperator		= PurchaseOrderNoOperator,"+CHAR(10)+
		"	@sPurchaseOrderNo			= PurchaseOrderNo,"+CHAR(10)+
		"	@nProcessKey				= ProcessKey"+CHAR(10)+

		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
	 	"		IncludeDraftCase		bit		'IncludeDraftCase/text()',"+CHAR(10)+
		"		EDEDataSourceNameNo	int		'EDEDataSourceNameNo/text()',"+CHAR(10)+
		"		EDEBatchIdentifier	nvarchar(254)	'EDEBatchIdentifier/text()',"+CHAR(10)+
		"		AuditSessionNumber	int		'AuditSessionNumber/text()',"+CHAR(10)+
		"		PurchaseOrderNoOperator tinyint        'PurchaseOrderNo/@Operator/text()',"+CHAR(10)+
		"		PurchaseOrderNo        nvarchar(160)	'PurchaseOrderNo/text()',"+CHAR(10)+
		"		ProcessKey	        int		'GlobalProcessKey/text()'"+CHAR(10)+
     		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @bIncludeDraftCase		bit			output,
					  @nEDEDataSourceNameNo		int			output,
					  @sEDEBatchIdentifier		nvarchar(254)		output,
					  @nAuditSessionNumber		int			output,
					  @nPurchaseOrderNoOperator	int			output,
					  @sPurchaseOrderNo             nvarchar(160)		output,
					  @nProcessKey			int			output',
					  @idoc				= @idoc,
					  @bIncludeDraftCase		= @bIncludeDraftCase	output,
					  @nEDEDataSourceNameNo		= @nEDEDataSourceNameNo	output,
					  @sEDEBatchIdentifier		= @sEDEBatchIdentifier	output,
					  @nAuditSessionNumber		= @nAuditSessionNumber	output,
					  @nPurchaseOrderNoOperator	= @nPurchaseOrderNoOperator	output,
					  @sPurchaseOrderNo             = @sPurchaseOrderNo     output,
					  @nProcessKey			= @nProcessKey		output

		-- RFC5763 - Retrieve Opportunities filter criteria using element-centric mapping
		Set @sSQLString =
		"Select @nOpportunityStatus				= StatusKey,"+CHAR(10)+
		"	@nOpportunityStatusOperator			= StatusKeyOperator,"+CHAR(10)+
		"	@nOpportunitySource					= SourceKey,"+CHAR(10)+
		"	@nOpportunitySourceOperator			= SourceKeyOperator,"+CHAR(10)+
		"	@sOpporunityRemarks					= Remarks,"+CHAR(10)+
		"	@nOpportunityRemarksOperator		= RemarksOperator,"+CHAR(10)+
		"	@dtOpportunityExpCloseDateFrom		= ExpectedCloseDateFrom,"+CHAR(10)+
		"	@dtOpportunityExpCloseDateTo		= ExpectedCloseDateTo,"+CHAR(10)+
		"	@nOpportunityExpCloseDateOperator	= ExpectedCloseDateOperator,"+CHAR(10)+
		"	@nOpportunityPotentialValueFrom		= PotentialValueFrom,"+CHAR(10)+
		"	@nOpportunityPotentialValueTo		= PotentialValueTo,"+CHAR(10)+
		"	@nOpportunityPotentialValueOperator	= PotentialValueOperator,"+CHAR(10)+
		"	@nOpportunityPotValCurOperator		= PotentialValueCurrencyOperator,"+CHAR(10)+
		"	@sOpportunityPotValCurCode		= PotentialValueCurrencyCode,"+CHAR(10)+
		"	@nOpportunityNextStepOperator		= NextStepOperator,"+CHAR(10)+
		"	@sOpportunityNextStep			= NextStep,"+CHAR(10)+
		"	@nOpportunityPotentialWinOperator	= PotentialWinOperator,"+CHAR(10)+
		"	@nOpportunityPotentialWinFrom		= PotentialWinFrom,"+CHAR(10)+
		"	@nOpportunityPotentialWinTo		= PotentialWinTo,"+CHAR(10)+
		"	@nOpportunityNumberOfStaffOperator	= NumberOfStaffOperator,"+CHAR(10)+
		"	@nOpportunityNumberOfStaffFrom		= NumberOfStaffFrom,"+CHAR(10)+
		"	@nOpportunityNumberOfStaffTo		= NumberOfStaffTo"+CHAR(10)+


		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/Opportunities',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
	 	"	      StatusKey					int			'StatusKey/text()',"+CHAR(10)+
	 	"	      StatusKeyOperator			tinyint		'StatusKey/@Operator/text()',"+CHAR(10)+
	 	"	      SourceKey					int			'SourceKey/text()',"+CHAR(10)+
	 	"	      SourceKeyOperator			tinyint		'SourceKey/@Operator/text()',"+CHAR(10)+
	 	"	      Remarks					nvarchar(2000)	'Remarks/text()',"+CHAR(10)+
	 	"	      RemarksOperator			tinyint	 		'Remarks/@Operator/text()',"+CHAR(10)+
	 	"	      ExpectedCloseDateFrom		datetime		'ExpectedCloseDate/DateRange/From/text()',"+CHAR(10)+
	 	"	      ExpectedCloseDateTo		datetime		'ExpectedCloseDate/DateRange/To/text()',"+CHAR(10)+
		"	      ExpectedCloseDateOperator	tinyint			'ExpectedCloseDate/DateRange/@Operator/text()',"+CHAR(10)+
	 	"	      PotentialValueFrom		decimal(11,2)	'PotentialValue/From/text()',"+CHAR(10)+
	 	"	      PotentialValueTo			decimal(11,2)	'PotentialValue/To/text()',"+CHAR(10)+
	 	"	      PotentialValueOperator		tinyint		'PotentialValue/@Operator/text()',"+CHAR(10)+
	 	"	      PotentialValueCurrencyOperator	tinyint		'PotentialValueCurrency/@Operator/text()',"+CHAR(10)+
	 	"	      PotentialValueCurrencyCode	nvarchar(3)	'PotentialValueCurrency/text()',"+CHAR(10)+
	 	"	      NextStepOperator			tinyint		'NextStep/@Operator/text()',"+CHAR(10)+
	 	"	      NextStep				nvarchar(1000)	'NextStep/text()',"+CHAR(10)+
	 	"	      PotentialWinOperator		tinyint		'PotentialWin/@Operator/text()',"+CHAR(10)+
	 	"	      PotentialWinFrom			decimal(5,2)	'PotentialWin/From/text()',"+CHAR(10)+
	 	"	      PotentialWinTo			decimal(5,2)	'PotentialWin/To/text()',"+CHAR(10)+
	 	"	      NumberOfStaffOperator		tinyint		'NumberOfStaff/@Operator/text()',"+CHAR(10)+
	 	"	      NumberOfStaffFrom			int		'NumberOfStaff/From/text()',"+CHAR(10)+
	 	"	      NumberOfStaffTo			int		'NumberOfStaff/To/text()'"+CHAR(10)+
     	"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc					int,
					@nOpportunityStatus					int	output,
					@nOpportunityStatusOperator			tinyint	output,
					@nOpportunitySource					int	output,
					@nOpportunitySourceOperator			tinyint	output,
					@sOpporunityRemarks					nvarchar(2000)	output,
					@nOpportunityRemarksOperator		tinyint	output,
					@dtOpportunityExpCloseDateFrom		datetime	output,
					@dtOpportunityExpCloseDateTo		datetime	output,
					@nOpportunityExpCloseDateOperator	tinyint	output,
					@nOpportunityPotentialValueFrom		decimal(11,2)	output,
					@nOpportunityPotentialValueTo		decimal(11,2)	output,
					@nOpportunityPotentialValueOperator 	tinyint	output,
					@nOpportunityPotValCurOperator		tinyint	output,
					@sOpportunityPotValCurCode		nvarchar(3)	output,
					@nOpportunityNextStepOperator		tinyint	output,
					@sOpportunityNextStep			nvarchar(1000)	output,
					@nOpportunityPotentialWinOperator	tinyint	output,
					@nOpportunityPotentialWinFrom		decimal(5,2)	output,
					@nOpportunityPotentialWinTo		decimal(5,2)	output,
					@nOpportunityNumberOfStaffOperator	tinyint	output,
					@nOpportunityNumberOfStaffFrom		int	output,
					@nOpportunityNumberOfStaffTo		int	output',
					  @idoc									= @idoc,
					  @nOpportunityStatus					= @nOpportunityStatus					output,
					  @nOpportunityStatusOperator			= @nOpportunityStatusOperator			output,
					  @nOpportunitySource					= @nOpportunitySource					output,
					  @nOpportunitySourceOperator			= @nOpportunitySourceOperator			output,
					  @sOpporunityRemarks					= @sOpporunityRemarks					output,
					  @nOpportunityRemarksOperator			= @nOpportunityRemarksOperator			output,
					  @dtOpportunityExpCloseDateFrom		= @dtOpportunityExpCloseDateFrom		output,
					  @dtOpportunityExpCloseDateTo			= @dtOpportunityExpCloseDateTo			output,
					  @nOpportunityExpCloseDateOperator		= @nOpportunityExpCloseDateOperator		output,
					  @nOpportunityPotentialValueFrom		= @nOpportunityPotentialValueFrom		output,
					  @nOpportunityPotentialValueTo			= @nOpportunityPotentialValueTo			output,
					@nOpportunityPotentialValueOperator	= @nOpportunityPotentialValueOperator	output,
					@nOpportunityPotValCurOperator		= @nOpportunityPotValCurOperator	output,
					@sOpportunityPotValCurCode		= @sOpportunityPotValCurCode		output,
					@nOpportunityNextStepOperator		= @nOpportunityNextStepOperator		output,
					@sOpportunityNextStep			= @sOpportunityNextStep 		output,
					@nOpportunityPotentialWinOperator	= @nOpportunityPotentialWinOperator	output,
					@nOpportunityPotentialWinFrom		= @nOpportunityPotentialWinFrom		output,
					@nOpportunityPotentialWinTo		= @nOpportunityPotentialWinTo		output,
					@nOpportunityNumberOfStaffOperator	= @nOpportunityNumberOfStaffOperator	output,
					@nOpportunityNumberOfStaffFrom		= @nOpportunityNumberOfStaffFrom	output,
					@nOpportunityNumberOfStaffTo		= @nOpportunityNumberOfStaffTo		output


		-- RFC5760 - Retrieve Marketing Activities filter criteria using element-centric mapping
		Set @sSQLString =
		"Select @nMktActivityStatus			= StatusKey,"+CHAR(10)+
		"	@nMktActivityStatusOperator		= StatusKeyOperator,"+CHAR(10)+
		"	@dtMktActivityStartDateFrom		= StartDateFrom,"+CHAR(10)+
		"	@dtMktActivityStartDateTo		= StartDateTo,"+CHAR(10)+
		"	@nMktActivityStartDateOperator		= StartDateOperator,"+CHAR(10)+
		"	@dtMktActivityActualDateFrom		= ActualDateFrom,"+CHAR(10)+
		"	@dtMktActivityActualDateTo		= ActualDateTo,"+CHAR(10)+
		"	@nMktActivityActualDateOperator		= ActualDateOperator,"+CHAR(10)+
		"	@nMktActivityActualCostFrom		= ActualCostFrom,"+CHAR(10)+
		"	@nMktActivityActualCostTo		= ActualCostTo,"+CHAR(10)+
		"	@nMktActivityActualCostOperator		= ActualCostOperator,"+CHAR(10)+
		"	@sMktActivityActualCostCurrency		= ActualCostCurrencyCode,"+CHAR(10)+
		"	@nMktActivityActualCostCurOperator	= ActualCostCurrencyOperator,"+CHAR(10)+
		"	@nMktActivityExpectedResponsesFrom	= ExpectedResponsesFrom,"+CHAR(10)+
		"	@nMktActivityExpectedResponsesTo	= ExpectedResponsesTo,"+CHAR(10)+
		"	@nMktActivityExpectedResponsesOperator	= ExpectedResponsesOperator,"+CHAR(10)+
		"	@nMktActivityActualResponsesFrom	= ActualResponsesFrom,"+CHAR(10)+
		"	@nMktActivityActualResponsesTo		= ActualResponsesTo,"+CHAR(10)+
		"	@nMktActivityActualResponsesOperator	= ActualResponsesOperator,"+CHAR(10)+
		"	@nMktActivityAcceptedResponsesFrom	= AcceptedResponsesFrom,"+CHAR(10)+
		"	@nMktActivityAcceptedResponsesTo	= AcceptedResponsesTo,"+CHAR(10)+
		"	@nMktActivityAcceptedResponsesOperator	= AcceptedResponsesOperator,"+CHAR(10)+
		"	@nMktActivityStaffAttendedFrom		= StaffAttendedFrom,"+CHAR(10)+
		"	@nMktActivityStaffAttendedTo		= StaffAttendedTo,"+CHAR(10)+
		"	@nMktActivityStaffAttendedOperator	= StaffAttendedOperator,"+CHAR(10)+
		"	@nMktActivityContactsAttendedFrom	= ContactsAttendedFrom,"+CHAR(10)+
		"	@nMktActivityContactsAttendedTo		= ContactsAttendedTo,"+CHAR(10)+
		"	@nMktActivityContactsAttendedOperator 	= ContactsAttendedOperator"+CHAR(10)+

		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/MarketingActivities',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
	 	"	      StatusKey			int		'StatusKey/text()',"+CHAR(10)+
	 	"	      StatusKeyOperator		tinyint		'StatusKey/@Operator/text()',"+CHAR(10)+
	 	"	      StartDateFrom		datetime	'StartDate/DateRange/From/text()',"+CHAR(10)+
	 	"	      StartDateTo		datetime	'StartDate/DateRange/To/text()',"+CHAR(10)+
		"	      StartDateOperator		tinyint		'StartDate/DateRange/@Operator/text()',"+CHAR(10)+
	 	"	      ActualDateFrom		datetime	'ActualDate/DateRange/From/text()',"+CHAR(10)+
	 	"	      ActualDateTo		datetime	'ActualDate/DateRange/To/text()',"+CHAR(10)+
		"	      ActualDateOperator	tinyint		'ActualDate/DateRange/@Operator/text()',"+CHAR(10)+
	 	"	      ActualCostFrom		decimal(11,2)	'ActualCost/From/text()',"+CHAR(10)+
	 	"	      ActualCostTo		decimal(11,2)	'ActualCost/To/text()',"+CHAR(10)+
	 	"	      ActualCostOperator	tinyint		'ActualCost/@Operator/text()',"+CHAR(10)+
	 	"	      ActualCostCurrencyCode	nvarchar(3)	'ActualCostCurrency/text()',"+CHAR(10)+
	 	"	      ActualCostCurrencyOperator tinyint		'ActualCostCurrency/@Operator/text()',"+CHAR(10)+
	 	"	      ExpectedResponsesFrom	int		'ExpectedResponses/From/text()',"+CHAR(10)+
	 	"	      ExpectedResponsesTo	int		'ExpectedResponses/To/text()',"+CHAR(10)+
	 	"	      ExpectedResponsesOperator	tinyint		'ExpectedResponses/@Operator/text()',"+CHAR(10)+
	 	"	      ActualResponsesFrom	int		'ActualResponses/From/text()',"+CHAR(10)+
	 	"	      ActualResponsesTo		int		'ActualResponses/To/text()',"+CHAR(10)+
	 	"	      ActualResponsesOperator	tinyint		'ActualResponses/@Operator/text()',"+CHAR(10)+
	 	"	      AcceptedResponsesFrom	int		'AcceptedResponses/From/text()',"+CHAR(10)+
	 	"	      AcceptedResponsesTo	int		'AcceptedResponses/To/text()',"+CHAR(10)+
	 	"	      AcceptedResponsesOperator	tinyint		'AcceptedResponses/@Operator/text()',"+CHAR(10)+
	 	"	      StaffAttendedFrom		int		'StaffAttended/From/text()',"+CHAR(10)+
	 	"	      StaffAttendedTo		int		'StaffAttended/To/text()',"+CHAR(10)+
	 	"	      StaffAttendedOperator	tinyint		'StaffAttended/@Operator/text()',"+CHAR(10)+
	 	"	      ContactsAttendedFrom	int		'ContactsAttended/From/text()',"+CHAR(10)+
	 	"	      ContactsAttendedTo	int		'ContactsAttended/To/text()',"+CHAR(10)+
	 	"	      ContactsAttendedOperator	tinyint		'ContactsAttended/@Operator/text()'"+CHAR(10)+
     		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc					int,
					@nMktActivityStatus			int	output,
					@nMktActivityStatusOperator		tinyint	output,
					@dtMktActivityStartDateFrom		datetime	output,
					@dtMktActivityStartDateTo		datetime	output,
					@nMktActivityStartDateOperator		tinyint	output,
					@dtMktActivityActualDateFrom		datetime	output,
					@dtMktActivityActualDateTo		datetime	output,
					@nMktActivityActualDateOperator		tinyint	output,
					@nMktActivityActualCostFrom		decimal(11,2)	output,
					@nMktActivityActualCostTo		decimal(11,2)	output,
					@nMktActivityActualCostOperator 	tinyint	output,
					@sMktActivityActualCostCurrency		nvarchar(3) output,
					@nMktActivityActualCostCurOperator	tinyint output,
					@nMktActivityExpectedResponsesFrom	int output,
					@nMktActivityExpectedResponsesTo	int output,
					@nMktActivityExpectedResponsesOperator	tinyint output,
					@nMktActivityActualResponsesFrom	int output,
					@nMktActivityActualResponsesTo		int output,
					@nMktActivityActualResponsesOperator	tinyint output,
					@nMktActivityAcceptedResponsesFrom	int output,
					@nMktActivityAcceptedResponsesTo	int output,
					@nMktActivityAcceptedResponsesOperator	tinyint output,
					@nMktActivityStaffAttendedFrom		int output,
					@nMktActivityStaffAttendedTo		int output,
					@nMktActivityStaffAttendedOperator	tinyint output,
					@nMktActivityContactsAttendedFrom	int output,
					@nMktActivityContactsAttendedTo		int output,
					@nMktActivityContactsAttendedOperator	tinyint output',
					  @idoc					= @idoc,
					  @nMktActivityStatus			= @nMktActivityStatus			output,
					  @nMktActivityStatusOperator		= @nMktActivityStatusOperator		output,
					  @dtMktActivityStartDateFrom		= @dtMktActivityStartDateFrom		output,
					  @dtMktActivityStartDateTo		= @dtMktActivityStartDateTo		output,
					  @nMktActivityStartDateOperator	= @nMktActivityStartDateOperator	output,
					  @dtMktActivityActualDateFrom		= @dtMktActivityActualDateFrom		output,
					  @dtMktActivityActualDateTo		= @dtMktActivityActualDateTo		output,
					  @nMktActivityActualDateOperator	= @nMktActivityActualDateOperator	output,
					  @nMktActivityActualCostFrom		= @nMktActivityActualCostFrom		output,
					  @nMktActivityActualCostTo		= @nMktActivityActualCostTo		output,
					  @nMktActivityActualCostOperator	= @nMktActivityActualCostOperator	output,
					  @sMktActivityActualCostCurrency	= @sMktActivityActualCostCurrency	output,
					  @nMktActivityActualCostCurOperator	= @nMktActivityActualCostCurOperator	output,
					  @nMktActivityExpectedResponsesFrom	= @nMktActivityExpectedResponsesFrom	output,
					  @nMktActivityExpectedResponsesTo	= @nMktActivityExpectedResponsesTo	output,
					  @nMktActivityExpectedResponsesOperator = @nMktActivityExpectedResponsesOperator output,
					  @nMktActivityActualResponsesFrom	= @nMktActivityActualResponsesFrom	output,
					  @nMktActivityActualResponsesTo	= @nMktActivityActualResponsesTo	output,
					  @nMktActivityActualResponsesOperator	= @nMktActivityActualResponsesOperator	output,
					  @nMktActivityAcceptedResponsesFrom	= @nMktActivityAcceptedResponsesFrom	output,
					  @nMktActivityAcceptedResponsesTo	= @nMktActivityAcceptedResponsesTo	output,
					  @nMktActivityAcceptedResponsesOperator = @nMktActivityAcceptedResponsesOperator output,
					  @nMktActivityStaffAttendedFrom	= @nMktActivityStaffAttendedFrom	output,
					  @nMktActivityStaffAttendedTo		= @nMktActivityStaffAttendedTo		output,
					  @nMktActivityStaffAttendedOperator	= @nMktActivityStaffAttendedOperator	output,
					  @nMktActivityContactsAttendedFrom	= @nMktActivityContactsAttendedFrom	output,
					  @nMktActivityContactsAttendedTo	= @nMktActivityContactsAttendedTo	output,
					  @nMktActivityContactsAttendedOperator	= @nMktActivityContactsAttendedOperator	output

		Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/CaseNameGroup/CaseName"

		Insert into @tblCaseNameGroup(NameKeys,NameKeysOperator,NameIncludeExpired,NameKeysTypeKey,[Name],NameUseAttentionName,NameVariantKeys,UseAttentionName,IsCurrentUser)
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      NameKeys			nvarchar(3500)	'NameKeys/text()',
		      NameKeysOperator		tinyint		'@Operator/text()',
		      NameIncludeExpired	bit		'@IncludeExpired/text()',
		      NameKeysTypeKey		nvarchar(100)	'TypeKey/text()',
		      [Name]			nvarchar(254)	'Name/text()',
		      NameUseAttentionName	bit		'Name/@UseAttentionName',
		      NameVariantKeys		nvarchar(500)	'NameVariantKeys/text()',
		      UseAttentionName		bit		'NameKeys/@UseAttentionName',
		      IsCurrentUser		bit		'NameKeys/@IsCurrentUser'
		     )
		Set @nCaseNameRowCount = @@RowCount

		Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/CaseNameGroup/NameGroup"

		Insert into @tblCaseNameGroup(NameGroupKey,NameGroupKeyOperator,NameGroupIncludeExpired,NameGroupTypeKey)
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      NameGroupKey		int		'GroupKey/text()',
		      NameGroupKeyOperator	tinyint		'@Operator/text()',
		      NameGroupIncludeExpired	bit		'@IncludeExpired/text()',
		      NameGroupTypeKey		nvarchar(100)	'TypeKey/text()'
		     )
		Set @nCaseNameRowCount = @nCaseNameRowCount+@@RowCount

		Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/AttributeGroup/Attribute"

		Insert into @tblAttributeGroup
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      BooleanOr			bit		'../@BooleanOr/text()',
		      AttributeKeys		nvarchar(4000)	'AttributeKey/text()',
		      AttributeOperator		tinyint		'@Operator/text()',
		      AttributeTypeKey		nvarchar(11)	'TypeKey/text()'
		     )

		Set @nAttributeRowCount = @@RowCount

		Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]/CaseTextGroup/CaseText"

		Insert into @tblCaseTextGroup
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      CaseText			nvarchar(4000)	'Text/text()',
		      CaseTextTypeKey		nvarchar(2)	'TypeKey/text()',
		      CaseTextOperator		tinyint		'@Operator/text()'
		     )

		Set @nCaseTextRowCount = @@RowCount


		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc

		Set @nErrorCode=@@Error
	End

	-- Initialise the FROM clause
	set @sFrom  = char(10)+"	FROM dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") XC "

	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"	WHERE 1=1"

	If @sCaseTypeKey is not null
	Begin
		Set @sCaseTypeKeys = @sCaseTypeKey
		Set @bIncludeCRMCases = @bIncludeCRMCasesCaseType
		Set @nCaseTypeKeysOperator = @nCaseTypeKeyOperator
	End

 	---------------------------------------------
 	-- If Row Level Security checking is required
 	-- then add the function that returns the
 	-- Case information with the security flag
 	---------------------------------------------
 	If @bRowLevelSecurity = 1
 	Begin
		If @bCaseOffice = 1
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurity("+convert(nvarchar,@pnUserIdentityId)+") RLS on (RLS.CASEID=XC.CASEID and RLS.READALLOWED = 1)"
		Else
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurityMultiOffice("+convert(nvarchar,@pnUserIdentityId)+") RLS on (RLS.CASEID=XC.CASEID and RLS.READALLOWED = 1)"
	End
	Else If @bRowLevelSecurityCentura=1
 	Begin
		If @bCaseOffice = 1
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurityCentura("+dbo.fn_WrapQuotes(@sSystemUser,0,@pbCalledFromCentura)+") RLS on (RLS.CASEID=XC.CASEID and RLS.READALLOWED = 1)"
		Else
			Set @sFrom=@sFrom+char(10)+"	join fn_CasesRowSecurityMultiOfficeCentura("+dbo.fn_WrapQuotes(@sSystemUser,0,@pbCalledFromCentura)+") RLS on (RLS.CASEID=XC.CASEID and RLS.READALLOWED = 1)"
	End
	Else If @bBlockCaseAccess=1
	Begin
		------------------------------------------------
		-- When any row level security is defined
		-- but the current user has no rules configured
		-- then by default they will have no access
		-- to any Cases.
		------------------------------------------------
		Set @sWhere=@sWhere+CHAR(10)+"	and 0=1"
	End

	If @nErrorCode = 0
	Begin
		-- If an AnySearch filter criterion is provided, all other filter parameters are ignored.
		If @sAnySearch is not NULL
		Begin
			-- RFC54710
			-- Check if the quick search matches directly on the IRN.
			if exists(select 1 from dbo.fn_CasesEthicalWall(@pnUserIdentityId) where IRN=@sAnySearch)
			and (@nAnySearchOperator<>2 OR @nAnySearchOperator is null)	-- If @nAnySearchOperator is 2 then drop through to search CASEINDEXES)
			begin
				-- If it also matches directly on an OfficialNumber
				-- then return the rows that match directly on both
				If exists(select 1 from OFFICIALNUMBERS O
					  join dbo.fn_CasesEthicalWall(@pnUserIdentityId) C on (C.CASEID=O.CASEID)
					  join NUMBERTYPES N on (N.NUMBERTYPE=O.NUMBERTYPE
							     and N.ISSUEDBYIPOFFICE=1)
					  where O.OFFICIALNUMBER=@sAnySearch)
				Begin
					Set @sWhere=@sWhere+CHAR(10)+"	and (XX.CASEID is not null"

					Set @sFrom = @sFrom+ CHAR(10)+"	join (  SELECT C.CASEID"
							   + CHAR(10)+"		FROM dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") C"
							   + CHAR(10)+"		where C.IRN = " + dbo.fn_WrapQuotes(@sAnySearch,0,@pbCalledFromCentura)
							   + CHAR(10)+"		UNION ALL"
							   + CHAR(10)+"		SELECT O.CASEID"
							   + CHAR(10)+"		FROM OFFICIALNUMBERS O WITH (NOLOCK)"
							   + CHAR(10)+"		join dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") C on (C.CASEID=O.CASEID)"
							   + CHAR(10)+"		join NUMBERTYPES N WITH (NOLOCK) on (N.NUMBERTYPE = O.NUMBERTYPE"
							   + CHAR(10)+"		                                 and N.ISSUEDBYIPOFFICE=1)"
							   + CHAR(10)+"		where O.OFFICIALNUMBER = " + dbo.fn_WrapQuotes(@sAnySearch,0,@pbCalledFromCentura) +") XX on (XX.CASEID=XC.CASEID)"
				End
				Else Begin
					-- If no direct match on Official Number then
					-- return the Case with the direct IRN match
					Set @sWhere=@sWhere+CHAR(10)+"	and (XX.IRN = " + dbo.fn_WrapQuotes(@sAnySearch,0,@pbCalledFromCentura)

					Set @sFrom = @sFrom+ CHAR(10)+"	join CASES XX on (XX.CASEID=XC.CASEID)"	-- Already joining to fn_CasesEthicalWalls, so can just use CASES here.
				End
			End
			Else Begin
				-- If no direct match on IRN then drop through to CASEINDEXES search.

				-- Check the Site Control to see if Related Case details
				-- are to be suppressed from the quick search
				Select @bSuppressRelatedCase=COLBOOLEAN
				from SITECONTROL
				where CONTROLID='Related Case Quick Search Suppressed'

				-- Initialise the WHERE clause with a test that will always be true and will have no performance
				-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
				Set @sWhere=@sWhere+CHAR(10)+"	and (XX.CASEID is not null"

				If @bSuppressRelatedCase=1
				Begin
					Set @sFrom = @sFrom+ CHAR(10)+"	left join (SELECT CR.CASEID"
							   + CHAR(10)+"		FROM CASEINDEXES CR WITH (NOLOCK)"
							   + CHAR(10)+"		join dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") C on (C.CASEID=CR.CASEID)"
							   + CHAR(10)+"		where CR.GENERICINDEX like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,@pbCalledFromCentura)
							   + CHAR(10)+"		and CR.SOURCE<>7"
							   + CHAR(10)+"		UNION ALL"
							   + CHAR(10)+"		SELECT CW.CASEID"
							   + CHAR(10)+"		FROM KEYWORDS  KW WITH (NOLOCK)"
							   + CHAR(10)+"		join CASEWORDS CW WITH (NOLOCK) on (CW.KEYWORDNO = KW.KEYWORDNO)"
							   + CHAR(10)+"		join dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") C on (C.CASEID=CW.CASEID)"
							   + CHAR(10)+"		left join CASEINDEXES CR WITH (NOLOCK) on (CR.GENERICINDEX like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,@pbCalledFromCentura)
							   + CHAR(10)+"		                                  and CR.CASEID = CW.CASEID"
							   + CHAR(10)+"		                                  and CR.SOURCE <>7)"
							   + CHAR(10)+"		where CR.CASEID is null"
							   + CHAR(10)+"		and KW.KEYWORD like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,@pbCalledFromCentura) +") XX on (XX.CASEID=XC.CASEID)"
				End
				Else Begin
					Set @sFrom = @sFrom+ CHAR(10)+"	left join (SELECT CR.CASEID"
							   + CHAR(10)+"		FROM CASEINDEXES CR WITH (NOLOCK)"
							   + CHAR(10)+"		join dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") C on (C.CASEID=CR.CASEID)"
							   + CHAR(10)+"		where CR.GENERICINDEX like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,@pbCalledFromCentura)
							   + CHAR(10)+"		UNION ALL"
							   + CHAR(10)+"		SELECT CW.CASEID"
							   + CHAR(10)+"		FROM KEYWORDS  KW WITH (NOLOCK)"
							   + CHAR(10)+"		join CASEWORDS CW WITH (NOLOCK) on (CW.KEYWORDNO = KW.KEYWORDNO)"
							   + CHAR(10)+"		join dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") C on (C.CASEID=CW.CASEID)"
							   + CHAR(10)+"		left join CASEINDEXES CR WITH (NOLOCK) on (CR.GENERICINDEX like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,@pbCalledFromCentura)
							   + CHAR(10)+"		                                  and CR.CASEID = CW.CASEID)"
							   + CHAR(10)+"		where CR.CASEID is null"
							   + CHAR(10)+"		and KW.KEYWORD like " + dbo.fn_WrapQuotes(@sAnySearch + '%',0,@pbCalledFromCentura) +") XX on (XX.CASEID=XC.CASEID)"
				End
			End

			-- RFC337 If the user is external then filter the Cases
			If @pbIsExternalUser=1
			Begin
				--RFC12702 Applied 'Client Exclude Dead Case Stats' check
				If @bCheckDeadCaseRestriction=1
					and exists(select * from SITECONTROL
						where CONTROLID = 'Client Exclude Dead Case Stats' and COLBOOLEAN=1)
				Begin
					Set @bIsDead = 0
					Set @bIsPending=isnull(@bIsPending,1)
					Set @bIsRegistered=isnull(@bIsRegistered,1)

					If @sFrom NOT LIKE '%STATUS XST%'
					Set @sFrom=@sFrom+char(10)+"	left join STATUS XST WITH (NOLOCK) on (XST.STATUSCODE = XC.STATUSCODE)"
					Set @sWhere = @sWhere+char(10)+"	and    (XST.LIVEFLAG=1 or XST.STATUSCODE is null)"

				End

				If CHARINDEX('join #TEMPCASESEXT XFC', isnull(@sFrom,''))=0
					Set @sFrom=@sFrom+char(10)+"	join #TEMPCASESEXT XFC on (XFC.CASEID=XC.CASEID)"
			End

			-- CRM search to include Name search as well
			If @bIncludeCRMCases = 1
			Begin
				Set @sFrom = @sFrom + char(10)+" left join (select DISTINCT CN.NAMENO as NAMENO, CN.CASEID as CASEID
                                                                from CASENAME CN
                                                                join NAME XN on (XN.NAMENO = CN.NAMENO)" +
                                                        char(10)+"        where XN.NAME like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + " OR"+
							char(10)+"        XN.FIRSTNAME  like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + " OR"+
							char(10)+"        XN.SEARCHKEY1 like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + " OR"+
							char(10)+"        XN.SEARCHKEY2 like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + " OR"+
                                                        char(10)+"        XN.NAMECODE like " 	+ dbo.fn_WrapQuotes(@sAnySearch + '%',0,0) + ") OCN on (OCN.CASEID = XC.CASEID)"

				Set @sWhere = @sWhere +	char(10)+"        OR OCN.CASEID IS NOT NULL)"
				If @sPropertyTypeKey is not NULL
		                or @nPropertyTypeKeyOperator between 2 and 6
		                Begin
			                Set @sWhere = @sWhere+char(10)+"	and	XC.PROPERTYTYPE"+dbo.fn_ConstructOperator(@nPropertyTypeKeyOperator,@String,@sPropertyTypeKey, null,@pbCalledFromCentura)
		                End

		                If @sCaseTypeKeys is not NULL
		                or @nCaseTypeKeysOperator between 2 and 6
		                Begin
			                Set @sWhere = @sWhere+char(10)+"	and	XC.CASETYPE"+dbo.fn_ConstructOperator(@nCaseTypeKeysOperator,@CommaString,@sCaseTypeKeys, null,@pbCalledFromCentura)
		                End
			End
			Else Begin
				Set @sWhere=@sWhere+")"
			End

			-- Get a list of the CaseTypes the user may view
			-- SQA12427 Allow draft case types to be excluded
			Set @sList = null

			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(CASETYPE,0,@pbCalledFromCentura)
			From dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura, @dtToday)
			Where ACTUALCASETYPE is null
			and (isnull(CRMONLY,0)=0 OR @bIncludeCRMCases=1)

			If @sList is not null
				Set @sWhere= @sWhere +char(10)+"	and XC.CASETYPE IN ("+@sList+")"
			Else Begin
				Set @sWhere=@sWhere+")"
			End
		End

		If @sCaseKey is not null
		Begin
			-- RFC337 If the user is external then filter the Cases
			If  CHARINDEX('join #TEMPCASESEXT XFC', isnull(@sFrom,''))=0
			and @pbIsExternalUser=1
			Begin
				Set @sFrom=@sFrom+char(10)+"	join #TEMPCASESEXT XFC on (XFC.CASEID=XC.CASEID)"
			End

			Set @sWhere=@sWhere+char(10)+"	and	XC.CASEID="+@sCaseKey
		End


		If @sFileLocationKeys is not null  or  @nFileLocationOperator in (5,6)
		Begin
			Set @sFrom=@sFrom+char(10)+"	left join CASELOCATION FL on (FL.CASEID=XC.CASEID and FL.WHENMOVED in (Select MAX(WHENMOVED) from CASELOCATION CL2
																where CL2.CASEID = XC.CASEID
                                                                                                                                and (CL2.FILEPARTID=FL.FILEPARTID OR (CL2.FILEPARTID is null and FL.FILEPARTID is null))))"
			If @nFileLocationOperator between 0 and 1
				Begin
					Set @sWhere=@sWhere+char(10)+"	and	FL.FILELOCATION " + dbo.fn_ConstructOperator(@nFileLocationOperator,@CommaString,@sFileLocationKeys, null,@pbCalledFromCentura)
				End
			Else
				Begin
					Set @sWhere=@sWhere+char(10)+"	and	FL.FILELOCATION "+ dbo.fn_ConstructOperator(@nFileLocationOperator,@String,@sFileLocationKeys, null,@pbCalledFromCentura)
				End
		End

		If @sFileLocationBayNo is not null 	 or  @nFileLocationBayNoOperator in (5,6)
		Begin
		    if charindex("CASELOCATION FL", @sFrom)	<=0
			Begin
				Set @sFrom=@sFrom+char(10)+"	left join CASELOCATION FL on (FL.CASEID=XC.CASEID and FL.WHENMOVED in (Select MAX(WHENMOVED) from CASELOCATION CL2
																where CL2.CASEID = XC.CASEID
                                                                                                                                and (CL2.FILEPARTID=FL.FILEPARTID OR (CL2.FILEPARTID is null and FL.FILEPARTID is null))))"
                        End
			Set @sWhere=@sWhere+char(10)+"	and	FL.BAYNO "+ dbo.fn_ConstructOperator(@nFileLocationBayNoOperator,@String,@sFileLocationBayNo, null,@pbCalledFromCentura)

			If @nFileLocationBayNoOperator between 2 and 4
			Begin
				Set @sWhere=@sWhere+char(10)+"	and	FL.CASEID is not null"
			End
		End

		-- RFC337 If the user is external then filter the Cases
		Else If @pbIsExternalUser=1
		Begin
			If CHARINDEX('join #TEMPCASESEXT XFC', isnull(@sFrom,''))=0
			Set @sFrom=@sFrom+char(10)+"	join #TEMPCASESEXT XFC on (XFC.CASEID=XC.CASEID)"

			If @bCheckDeadCaseRestriction=1
			and exists(select * from SITECONTROL
				where CONTROLID = 'Client Exclude Dead Case Stats' and COLBOOLEAN=1)
			Begin
				Set @bIsDead = 0
				Set @bIsPending=isnull(@bIsPending,1)
				Set @bIsRegistered=isnull(@bIsRegistered,1)
			End
		End

		If @sCaseReference is not NULL
		or @nCaseReferenceOperator between 2 and 6
			Begin
			If @bIsWithinFileCover=1
			Begin
				Set @sFrom = @sFrom+char(10)+"	     join dbo.fn_CasesEthicalWall("+ cast(@pnUserIdentityId as varchar)+") XC1 on (XC1.CASEID = XC.CASEID" +char(10)
													+"or  XC1.CASEID      = XC.FILECOVER)"
			End

			-----------------------------------------
			-- Check if a list of semicolon separated
			-- Case References have been supplied
			-----------------------------------------
			If  PATINDEX('%;%',@sCaseReference)>0
				Set @bMultipleCaseRefs=1
			Else
				Set @bMultipleCaseRefs=0

			-----------------------------------------
			-- RFC 48189
			-- NOTE:
			-- The following may be removed in the
			-- future if the front end is changed
			-- so that @nCaseReferenceOperator is
			-- set to "Equal" when multiple Case
			-- Reference searches are provided from
			-- the Standard case search window.
			-----------------------------------------
			If  @bMultipleCaseRefs=1
			and @nCaseReferenceOperator=2
			and PATINDEX('%[%]%',@sCaseReference)=0
				Set @nCaseReferenceOperator=0

			If  @bMultipleCaseRefs=1
			and @nCaseReferenceOperator in (0,1)
			Begin
				If @pbCalledFromCentura = 0
					Set @sNPrefix = 'N'

				-- Any occurrence of a single Quote is to be replaced with two single Quotes
				Set @sCaseReference=Replace(@sCaseReference, char(39), char(39)+char(39) )

				Select @sOutputString=ISNULL(NULLIF(@sOutputString + ',', ','),'')  +@sNPrefix+char(39)+t.Parameter+char(39)
				from dbo.fn_Tokenise(@sCaseReference, @SemiColon) t

				If @nCaseReferenceOperator=0
				Begin
					If @bIsWithinFileCover=1
						Set @sWhere = @sWhere + ' and XC1.IRN in ('+ @sOutputString + ')'
					Else
						Set @sWhere = @sWhere + ' and XC.IRN in (' + @sOutputString + ')'
				End
				Else Begin
					If @bIsWithinFileCover=1
						Set @sWhere = @sWhere + ' and XC1.IRN not in ('+ @sOutputString + ')'
					Else
						Set @sWhere = @sWhere + ' and XC.IRN not in (' + @sOutputString + ')'
				End

			End
			Else Begin
				Set @sCaseReferenceWhere = ''
				Set @or = ''
				select @sCaseReferenceWhere = @sCaseReferenceWhere +
				Case
					When @bIsWithinFileCover=1 then
						@or + 'XC1.IRN' + dbo.fn_ConstructOperator(@nCaseReferenceOperator, @String, RTRIM(LTRIM(t.Parameter)), null, @pbCalledFromCentura)
					else
					   @or + 'XC.IRN' + dbo.fn_ConstructOperator(@nCaseReferenceOperator, @String, RTRIM(LTRIM(t.Parameter)), null, @pbCalledFromCentura)
				End,
				@or = ' or '
				from dbo.fn_Tokenise(@sCaseReference, @SemiColon) t
				where t.Parameter <> ''
				and t.Parameter is not null

			    	If (@sCaseReferenceWhere <> '')
			    	Begin
				   Set @sWhere = @sWhere + ' and (' + @sCaseReferenceWhere + ')'
				End
			End
		End

		If @sCaseKeys is not NULL
		or @nCaseKeysOperator between 0 and 1
		Begin
			If @bIsWithinFileCover=1
			Begin
				Set @sFrom = @sFrom+char(10)+"	     join CASES XC1 WITH (NOLOCK) on (XC1.CASEID      = XC.CASEID"+
						   +char(10)+"	                   	or  XC1.CASEID      = XC.FILECOVER)"
				Set @sWhere = @sWhere+char(10)+"	and	XC1.CASEID"+dbo.fn_ConstructOperator(@nCaseKeysOperator,@CommaString,@sCaseKeys, null,@pbCalledFromCentura)
			End
			Else
			Begin
                If (@sCaseKeys is not NULL and @sCaseKeys <> '')
                Begin
				    Set @sWhere = @sWhere+char(10)+"	and	XC.CASEID "+dbo.fn_ConstructOperator(@nCaseKeysOperator,@CommaString,@sCaseKeys, null,@pbCalledFromCentura)
                End
			End
		End

		If @sCaseReferenceStem is not NULL
		or @nCaseReferenceStemOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	LEFT(XC.STEM, CASE WHEN(XC.STEM LIKE '%~%') THEN PATINDEX('%~%',XC.STEM)-1 ELSE 30 END)"+dbo.fn_ConstructOperator(@nCaseReferenceStemOperator,@String,@sCaseReferenceStem, null,@pbCalledFromCentura)
		End

		If @sQuickIndexKey is not NULL
		Begin
			Set @sFrom = @sFrom+char(10)+"	     join IDENTITYINDEX IX WITH (NOLOCK) on (IX.IDENTITYID = " + convert(varchar,@pnUserIdentityId)
					   +char(10)+"	                   		and IX.INDEXID = " + @sQuickIndexKey + ")"
			Set @sWhere = @sWhere+char(10)+"	and	XC.CASEID = IX.COLINTEGER"
		End

		If @sOfficeKeys is not NULL
		or @nOfficeKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.OFFICEID"+dbo.fn_ConstructOperator(@nOfficeKeyOperator,@Numeric,@sOfficeKeys, null,@pbCalledFromCentura)
		End

		If @sOffice is not NULL
		or @nOfficeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.OFFICEID"+dbo.fn_ConstructOperator(@nOfficeOperator,@Numeric,@sOffice, null,@pbCalledFromCentura)
		End

		If  @sOfficialNumber is not NULL
		or  @nOfficialNumberOperator between 2 and 6
		or  @sNumberTypeKey is not NULL
		Begin
			-- When @bUseCurrent is turned on, the search is conducted on the current official number for
			-- the case. Any NumberType values are ignored.

			If @bUseCurrent = 1
			Begin
				-- When turned on, any non-numeric characters are removed from Number and this is compared to the numeric characters in the official numbers on the database.

				If @bUseNumericSearch = 1
				Begin
					Set @sNumericOfficialNumber = dbo.fn_StripNonNumerics(@sOfficialNumber)

					Set @sFrom = @sFrom+char(10)+"	     join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID = XC.CASEID"
					                   +char(10)+"                                  and XCI.GENERICINDEX="+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
					   		   +char(10)+"                                  and XCI.SOURCE =5)"

					Set @sWhere = @sWhere+char(10)+" and	dbo.fn_StripNonNumerics(XC.CURRENTOFFICIALNO)"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
				End
				Else
				Begin

					Set @sFrom = @sFrom+char(10)+"	     join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID = XC.CASEID"
					                   +char(10)+"                                  and XCI.GENERICINDEX="+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
					   		   +char(10)+"                                  and XCI.SOURCE =5)"
					Set @sWhere = @sWhere+char(10)+" and	XC.CURRENTOFFICIALNO"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
				End
			End
			Else If @bUseRelatedCase = 1
			and (@sOfficialNumber is not NULL
			or @nOfficialNumberOperator between 2 and 6)
			Begin
				Set @sFrom = @sFrom+char(10)+"	     join RELATEDCASE XRC WITH (NOLOCK) on (XRC.CASEID = XC.CASEID)"
					   	+char(10)+"          join CASERELATION XCR WITH (NOLOCK) on (XCR.RELATIONSHIP=XRC.RELATIONSHIP"
					   	+char(10)+"                             	and XCR.SHOWFLAG=1)"
					   	+char(10)+"     left join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID = XRC.RELATEDCASEID"
					   	+char(10)+"                                     and XCI.SOURCE =5)"

				-- When @bUseCurrent is turned on, the search is conducted on the current official number for
				-- the case. Any NumberType values are ignored.

				If @bUseNumericSearch = 1
				Begin
					Set @sNumericOfficialNumber = dbo.fn_StripNonNumerics(@sOfficialNumber)

					Set @sWhere = @sWhere+char(10)+"	and	isnull(XCI.GENERICINDEX,dbo.fn_StripNonNumerics(XRC.OFFICIALNUMBER))"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
				End
				Else
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	isnull(XCI.GENERICINDEX,XRC.OFFICIALNUMBER)"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
				End
			End
			Else
			Begin
				If @bUseNumericSearch = 1
					Set @sNumericOfficialNumber = dbo.fn_StripNonNumerics(@sOfficialNumber)
				Else
					Set @sNumericOfficialNumber = null

				if @nOfficialNumberOperator = 6
				Begin
					Set @sFrom = @sFrom+char(10)+"	left join OFFICIALNUMBERS XO WITH (NOLOCK) on(XO.CASEID    = XC.CASEID"
				End
				Else If @sOfficialNumber is not NULL
				Begin
					Set @sFrom = @sFrom+char(10)+"	     join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID   = XC.CASEID"
							   +char(10)+"					and XCI.GENERICINDEX"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,isnull(@sNumericOfficialNumber,@sOfficialNumber), null,@pbCalledFromCentura)
							   +char(10)+"					and XCI.SOURCE   =5)"
					                   +char(10)+"	     join OFFICIALNUMBERS XO WITH (NOLOCK) on (XO.CASEID    = XC.CASEID"
				End
				Else Begin
					Set @sFrom = @sFrom+char(10)+"	     join OFFICIALNUMBERS XO WITH (NOLOCK) on (XO.CASEID    = XC.CASEID"
				End

				-- RFC1717 Ensure that the filter criteria is limited to values the user may view
				Set @sList = null
				Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NUMBERTYPE,0,@pbCalledFromCentura)
				From dbo.fn_FilterUserNumberTypes(@pnUserIdentityId,null, @pbIsExternalUser,@pbCalledFromCentura)

				If  @nOfficialNumberOperator in (5,6)
				Begin
					If @sNumberTypeKey is not NULL
						Set @sFrom = @sFrom+char(10)+"	                               and XO.NUMBERTYPE="+dbo.fn_WrapQuotes(@sNumberTypeKey,0,@pbCalledFromCentura)

					If @sList is not null
						Set @sFrom = @sFrom+char(10)+"	                               and XO.NUMBERTYPE IN ("+@sList+")"

					Set @sFrom = @sFrom+")"
				End
				Else Begin
					Set @sFrom = @sFrom+")"

					If  @sList is not null
						Set @sWhere= @sWhere+char(10)+"	and	XO.NUMBERTYPE IN ("+@sList+")"
				End


				If @nOfficialNumberOperator=6
				Begin
					Set @sWhere= @sWhere+char(10)+"	and	XO.CASEID is null"
				End
				Else If @nOfficialNumberOperator<>5
				     and @sNumberTypeKey is not NULL
				Begin
					Set @sWhere= @sWhere+char(10)+"	and	XO.NUMBERTYPE = "+dbo.fn_WrapQuotes(@sNumberTypeKey,0,@pbCalledFromCentura)
				End

				If @sOfficialNumber is not NULL
				and @nOfficialNumberOperator not in (5,6)
				Begin
					If @bUseNumericSearch = 1
					Begin
						Set @sWhere = @sWhere+char(10)+"	and	dbo.fn_StripNonNumerics(XO.OFFICIALNUMBER)"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
					End
					Else
					Begin
						Set @sWhere = @sWhere+char(10)+"	and	XO.OFFICIALNUMBER"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
					End
				End
			End
		End

		If @sCaseTypeKeys is not NULL
		or @nCaseTypeKeysOperator between 2 and 6
		Begin
			-- RFC1717 Ensure that the filter criteria is limited to values the user may view
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(CASETYPE,0,@pbCalledFromCentura)
			From dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura,@dtToday)

			if @sWhere not like '%and XC.CASETYPE IN ('+@sList+')%'
				Set @sWhere= @sWhere+char(10)+"	and XC.CASETYPE IN ("+@sList+")"

			Set @sWhere = @sWhere+char(10)+" and XC.CASETYPE"+dbo.fn_ConstructOperator(@nCaseTypeKeysOperator,@CommaString,@sCaseTypeKeys, null,@pbCalledFromCentura)
		End
		Else Begin
			-- Get a list of the CaseTypes the user may view
			-- SQA12427 Allow draft case types to be excluded
			Set @sList = null

			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(CASETYPE,0,@pbCalledFromCentura)
			From dbo.fn_FilterUserCaseTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura,@dtToday)
			Where (ACTUALCASETYPE is null OR @bIncludeDraftCase=1)
			and (isnull(CRMONLY,0)=0 OR @bIncludeCRMCases=1)

			If @sList is not null
			Begin
				if @sWhere not like '%and XC.CASETYPE IN ('+@sList+')%'
					Set @sWhere= @sWhere+char(10)+"	and XC.CASETYPE IN ("+@sList+")"
			End
		End

		-- SQA19823 -- filter by draft case only.
		set @bDraftCaseOnly = 0
		If (@nCaseTypeKeysOperator <> 1 and @sCaseTypeKeys = 'X' )
			set @bDraftCaseOnly = 1

		If @sCountryCodes is not NULL
		or @nCountryCodesOperator between 2 and 6
		Begin
			If @bIncludeDesignations=1
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	(XC.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryCodesOperator,@CommaString,@sCountryCodes, null,@pbCalledFromCentura)
						     +char(10)+"	 or  EXISTS (	Select 1  from COUNTRYGROUP XCG WITH (NOLOCK)"
						     +char(10)+"			join COUNTRY XCT WITH (NOLOCK) on (XCT.COUNTRYCODE=XCG.TREATYCODE)"
						     +char(10)+"	             	where XCG.MEMBERCOUNTRY"+dbo.fn_ConstructOperator(@nCountryCodesOperator,@CommaString,@sCountryCodes, null,@pbCalledFromCentura)
						     +char(10)+"	             	and XCG.TREATYCODE=XC.COUNTRYCODE and XCT.ALLMEMBERSFLAG = 1 )"
						     +char(10)+"	 or  EXISTS (	Select 1  from RELATEDCASE XRC1 WITH (NOLOCK) "
						     +char(10)+"	             	left join COUNTRYFLAGS XCF WITH (NOLOCK) on (XCF.COUNTRYCODE=XC.COUNTRYCODE"
						     +char(10)+"	             	                           and XCF.FLAGNUMBER =XRC1.CURRENTSTATUS)"
						     +char(10)+"	             	where XRC1.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryCodesOperator,@CommaString,@sCountryCodes, null,@pbCalledFromCentura)
						     +char(10)+"	             	and XRC1.RELATIONSHIP='DC1'"
						     +char(10)+"		     	and XRC1.RELATEDCASEID is null"
						     +char(10)+"	             	and XRC1.CASEID=XC.CASEID"

				-- If the filter is restricting on the status category (Pending, Registered and/or Dead)
				-- then the search must also take the Designated Countries status into consideration
				If @bIsPending=1
					Set @sStatusFlag='1 '
				If @bIsRegistered=1
					Set @sStatusFlag=@sStatusFlag+'2 '
				If @bIsDead=1
					Set @sStatusFlag=@sStatusFlag+'0'

				Set @sStatusFlag=replace(rtrim(@sStatusFlag),' ',',')

				If @sStatusFlag is not null
					Set @sWhere=@sWhere+char(10)+"	             	and XCF.STATUS in ("+@sStatusFlag+") )"
				Else
					Set @sWhere=@sWhere+")"
			End
			-- IncludeDesignations is OFF
			Else
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	(XC.COUNTRYCODE"+dbo.fn_ConstructOperator(@nCountryCodesOperator,@CommaString,@sCountryCodes, null,@pbCalledFromCentura)
			End

			If @bIncludeMembers = 1
			Begin
				Set @sWhere = @sWhere+char(10)+"		or  (XC.COUNTRYCODE in  (Select CG.MEMBERCOUNTRY  from COUNTRYGROUP CG WITH (NOLOCK)"
						     +char(10)+"	             	where CG.TREATYCODE"+dbo.fn_ConstructOperator(@nCountryCodesOperator,@CommaString,@sCountryCodes, null,@pbCalledFromCentura)
						     +char(10)+"	             	))"
			End

			Set @sWhere=@sWhere+")"

		End

		If @sPropertyTypeKeyList is not null
		Begin

			-- RFC4555 Allow searching on multiple property types
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
			Set @sWhere = @sWhere+char(10)+"	and	XC.PROPERTYTYPE"+dbo.fn_ConstructOperator(@nPropertyTypeKeyOperator,@CommaString,@sPropertyTypeKey, null,@pbCalledFromCentura)
		End

		If @sCategoryKey is not NULL
		or @nCategoryKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.CASECATEGORY"+dbo.fn_ConstructOperator(@nCategoryKeyOperator,@CommaString,@sCategoryKey, null,@pbCalledFromCentura)
		End

		If @sSubTypeKey is not NULL
		or @nSubTypeKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.SUBTYPE"+dbo.fn_ConstructOperator(@nSubTypeKeyOperator,@CommaString,@sSubTypeKey, null,@pbCalledFromCentura)
		End

		If @sBasisKey is not NULL
		or @nBasisKeyOperator between 2 and 6
		Begin
			If @nBasisKeyOperator=6
				Set @sFrom = @sFrom+char(10)+"	left join PROPERTY XPB WITH (NOLOCK) on (XPB.CASEID=XC.CASEID)"
			Else
				Set @sFrom = @sFrom+char(10)+"	join PROPERTY XPB WITH (NOLOCK) on (XPB.CASEID=XC.CASEID)"

			Set @sWhere = @sWhere+char(10)+"	and	XPB.BASIS"+dbo.fn_ConstructOperator(@nBasisKeyOperator,@CommaString,@sBasisKey, null,@pbCalledFromCentura)

		End

                If @sPurchaseOrderNo is not NULL
		or @nPurchaseOrderNoOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.PURCHASEORDERNO"+dbo.fn_ConstructOperator(@nPurchaseOrderNoOperator,@String,@sPurchaseOrderNo, null,@pbCalledFromCentura)
		End

		-- RFC9321: No operator required
		If @nProcessKey is not NULL
		Begin
			Set @sFrom = @sFrom+char(10)+"	join GLOBALCASECHANGERESULTS XGC WITH (NOLOCK) on (XGC.CASEID=XC.CASEID AND XGC.PROCESSID=GCR.PROCESSID)"
			Set @sWhere = @sWhere+char(10)+"	and	XGC.PROCESSID="+convert(nvarchar, @nProcessKey)

		End

		If @sSuitableForRelationshipCode is not NULL
		and @nSuitableForRelationshipCaseKey is not NULL
		Begin
			-- RFC7390
			-- Returns only the cases that can be used as a Related Case (@sSuitableForRelationshipCode)
			-- against @nSuitableForRelationshipCaseKey

			Set @sSQLString="
				select  @sSuitableForRelationshipCountryCode=COUNTRYCODE,
					@sSuitableForRelationshipCodePropertyType=PROPERTYTYPE
				from dbo.fn_CasesEthicalWall(@pnUserIdentityId)
				where CASEID=@nSuitableForRelationshipCaseKey"

			exec sp_executesql @sSQLString,
						N'@sSuitableForRelationshipCountryCode		nvarchar(3)	OUTPUT,
						  @sSuitableForRelationshipCodePropertyType	nvarchar(1)	OUTPUT,
						  @nSuitableForRelationshipCaseKey		int,
						  @pnUserIdentityId				int',
						  @sSuitableForRelationshipCountryCode=@sSuitableForRelationshipCountryCode	OUTPUT,
						  @sSuitableForRelationshipCodePropertyType =@sSuitableForRelationshipCodePropertyType OUTPUT,
						  @nSuitableForRelationshipCaseKey		=@nSuitableForRelationshipCaseKey,
						  @pnUserIdentityId				=@pnUserIdentityId

			-- Get valid relationships that can be attached to the case @nSuitableForRelationshipCaseKey
			Set @sFrom = @sFrom+char(10)+"
				join  	VALIDRELATIONSHIPS VR
						on (	VR.PROPERTYTYPE "+dbo.fn_ConstructOperator(0,@String,@sSuitableForRelationshipCodePropertyType, null,@pbCalledFromCentura)+"
							and	(VR.COUNTRYCODE = (	Select min(VR1.COUNTRYCODE)
													from VALIDRELATIONSHIPS VR1
													where VR1.PROPERTYTYPE = VR.PROPERTYTYPE
													and   (VR1.COUNTRYCODE = 'ZZZ' or
															VR1.COUNTRYCODE"+dbo.fn_ConstructOperator(0,@String,@sSuitableForRelationshipCountryCode, null,@pbCalledFromCentura)+"))))"+
			-- get the reciprocal side of the relationship
				"join VALIDRELATIONSHIPS VR2
						on (	VR2.RECIPRELATIONSHIP = VR.RELATIONSHIP)"

			-- return the cases where property type and/or country that are valid for the reciprocal relationship.
			-- these are typicaly the cases displayed in a related case picklist.
			Set @sWhere =@sWhere+char(10)+"		and XC.PROPERTYTYPE = VR2.PROPERTYTYPE
												and (XC.COUNTRYCODE = VR2.COUNTRYCODE or VR2.COUNTRYCODE = 'ZZZ')"
		End

		-- Set @nCount to 1 so it points to the first record of the table
		Set @nCount = 1

		-- @nAttributeRowCount is the number of rows in the @tblAttributeGroup table, which is used to loop the Attributes while constructing the 'From' and the 'Where' clause
		While @nCount <= @nAttributeRowCount
		Begin
			Set @sCorrelationName = 'XTA_' + cast(@nCount as nvarchar(20))

			Select  @bBooleanOr		= BooleanOr,
				@sAttributeKeys		= AttributeKeys,
				@sAttributeTypeKey	= AttributeTypeKey,
			     	@nAttributeOperator	= AttributeOperator
			from	@tblAttributeGroup
			where   AttributeIdentity = @nCount

			If (@sAttributeKeys is not null
			or @nAttributeOperator between 2 and 6)
			Begin
				If @nAttributeRowCount > 1
				and @nCount >1
				Begin
					set @sStringOr = CASE WHEN @bBooleanOr = 1 THEN " or "
					      	      	      WHEN @bBooleanOr = 0 or @bBooleanOr is null THEN " and "
					 	 	 END
				End
				Else If @nCount = 1
				Begin
					set @sWhere =@sWhere+char(10)+"	and ("
				End

				Set @sFrom = @sFrom+char(10)+"	left join TABLEATTRIBUTES " + @sCorrelationName + " WITH (NOLOCK) on (" + @sCorrelationName + ".PARENTTABLE='CASES'"
					   	   +char(10)+"	                               and " + @sCorrelationName + ".TABLETYPE="+@sAttributeTypeKey

				If  @nAttributeOperator=1
				and @sAttributeKeys is not null
				Begin
					--------------------------------------------------
					-- RFC64804
					-- Note that when @AttributeOperator=1 (Not Equal)
					-- we will substitute it with a 0 (Equal To)
					-- as the WHERE clause will then check that
					-- the TABLEATTRIBUTES row does not exist.
					--------------------------------------------------
					Set @sFrom = @sFrom+char(10)+"	                               and " + @sCorrelationName + ".TABLECODE" + dbo.fn_ConstructOperator(0,@CommaString,@sAttributeKeys, null,@pbCalledFromCentura)
   				End
				Set @sFrom = @sFrom+char(10)+"	                               and " + @sCorrelationName + ".GENERICKEY=convert(varchar,XC.CASEID))"

				If @nAttributeOperator=1
				Begin
					Set @sWhere =@sWhere+@sStringOr+space(1)+
						+ @sCorrelationName + ".TABLECODE is null"
				End
				Else
				Begin
					Set @sWhere =@sWhere+@sStringOr+space(1)+
						 + @sCorrelationName + ".TABLECODE"+dbo.fn_ConstructOperator(@nAttributeOperator,@Numeric,@sAttributeKeys, null,@pbCalledFromCentura)
				End

				If @nCount = @nAttributeRowCount
				Begin
					Set @sWhere = @sWhere + ")"
				End
			End

			Set @nCount = @nCount + 1

		End

		-- Set @nCount to 1 so it points to the first record of the table
		Set @nCount = 1

		-- @nCaseTextRowCount is the number of rows in the @tblCaseTextGroup table, which is used to loop the Attributes while constructing the 'From' and the 'Where' clause
		While @nCount <= @nCaseTextRowCount
		Begin

			Set @sCorrelationName = 'XCT_' + cast(@nCount as nvarchar(20))

			Select  @sCaseText		= CaseText,
				@sCaseTextTypeKey	= CaseTextTypeKey,
			     	@nCaseTextOperator	= CaseTextOperator
			from	@tblCaseTextGroup
			where   CaseTextIdentity = @nCount

			If  @nCaseTextOperator is not null
			Begin
				set @sFrom =@sFrom+char(10)+"	Left Join (Select distinct CT.CASEID from CASETEXT CT with(NOLOCK)"

				Set @sFrom =@sFrom+char(10)+"	           Where 2=2"

				If  @nCaseTextOperator in (5,6)
				Begin
					Set @sFrom =@sFrom+char(10)+" and (CT.TEXT is not null OR CT.SHORTTEXT is not null)"
				End

				If @nCaseTextOperator not in (5, 6)
				and @sCaseText is not null
				Begin
					Set @sFrom =@sFrom+char(10)+"	           and isnull(CT.TEXT, CT.SHORTTEXT)"+dbo.fn_ConstructOperator(@nCaseTextOperator,@Text,@sCaseText, null,@pbCalledFromCentura)
				End

				If  @sCaseTextTypeKey is not NULL
				Begin
					Set @sFrom = @sFrom+char(10)+"	           and CT.TEXTTYPE="+dbo.fn_WrapQuotes(@sCaseTextTypeKey,0,@pbCalledFromCentura)
				End

				Set @sFrom = @sFrom + ")" +@sCorrelationName+" on ("+@sCorrelationName+".CASEID=XC.CASEID)"

				If @nCaseTextOperator = 6
				Begin
					Set @sWhere = @sWhere+char(10)+"and "+@sCorrelationName+".CASEID is null"
				End
				Else Begin
					-- DR-47469
					-- If Any Text Type is to be searched, then also consider the TITLE of the CASE.
					If @sCaseTextTypeKey is null
						Set  @sWhere = @sWhere+char(10)+"	and ("+@sCorrelationName+".CASEID is not null OR XC.TITLE"+dbo.fn_ConstructOperator(@nCaseTextOperator,@Text,@sCaseText, null,@pbCalledFromCentura)+")"
					Else
						Set  @sWhere = @sWhere+char(10)+"	and " +@sCorrelationName+".CASEID is not null"
				End


			End

			Set @nCount = @nCount + 1
		End

		If @sClasses is not NULL
		or @nClassesOperator between 2 and 6
		Begin
			-- If no Class value has been provided and the operator is set to
			-- Starts With (2), Ends With (3) or Contains (4) then change the operator
			-- to IS NOT NULL (5)
			If @sClasses is NULL
			and @nClassesOperator in (2,3,4)
				set @nClassesOperator=5

			-- If both of the Local and International flags are off then by
			-- default turn the IsLocal flag on.
			If  isnull(@bIsLocal,0)=0
			and isnull(@bIsInternational,0)=0
				Set @bIsLocal=1

			If @bIsLocal=1
			Begin
				-- Open bracket
				Set @sWhere=@sWhere+char(10)+"and ("

				-- Save original value of the @nClassesOperator for use
				-- in the international classes filtering:
				Set @nOriginalClassesOperator = @nClassesOperator

				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nClassesOperator in (1,6)
				Begin
					Set @nClassesOperator = 0

					Set @sWhere=@sWhere+char(10)+"not exists"
				End
				Else Begin
					Set @sWhere=@sWhere+char(10)+"exists"
				End

				Set @sWhere = @sWhere	+char(10)+"(Select * "
				     				+char(10)+" from CASETEXT XCT"
								+char(10)+" where XCT.CASEID    = XC.CASEID"

				If @nClassesOperator = 2
				Begin
					set @sInClause = null
					-- Generates: XCT.CLASS like N'01%' or XCT.CLASS like N'02%'
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"XCT.CLASS like " + dbo.fn_WrapQuotes(Parameter+"%",0,@pbCalledFromCentura)
					from dbo.fn_Tokenise(@sClasses,",")
					Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If @nClassesOperator = 3
				Begin
					set @sInClause = null
					-- Generates: XCT.CLASS like N'%01' or XCT.CLASS like N'%02'
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"XCT.CLASS like " + dbo.fn_WrapQuotes("%"+Parameter,0,@pbCalledFromCentura)
					from dbo.fn_Tokenise(@sClasses,",")
					Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If @nClassesOperator = 4
				Begin
					set @sInClause = null
					-- Generates: XCT.CLASS like N'%01%' or XCT.CLASS like N'%02%'
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"XCT.CLASS like " + dbo.fn_WrapQuotes("%"+Parameter+"%",0,@pbCalledFromCentura)
					from dbo.fn_Tokenise(@sClasses,",")
					Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If @nOriginalClassesOperator = 6
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	XCT.CLASS is not null"
				End
				Else Begin
					Set @sWhere = @sWhere+char(10)+"	and	(XCT.CLASS"+dbo.fn_ConstructOperator(@nClassesOperator,@CommaString,@sClasses, 1,@pbCalledFromCentura)+")"
				End

				-- Close subquery bracket
				Set @sWhere=@sWhere+")"
			End

			If @bIsInternational=1
			Begin
				If ISNULL(@nOriginalClassesOperator, @nClassesOperator) = 0
				Begin
					set @sInClause = null
					-- remove embedded spaces and leading zeroes and ensure a comma delimiter
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"','+replace(XC.INTCLASSES,' ','')+',' like " + dbo.fn_WrapQuotes("%,"+Parameter+","+"%",0,1)
					from dbo.fn_Tokenise(@sClasses,",")

					If @bIsLocal=1
						Set @sWhere = @sWhere+char(10)+"	or	("+@sInClause+")"
					Else
						Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If ISNULL(@nOriginalClassesOperator, @nClassesOperator) = 1
				Begin
					set @sInClause = null
					-- remove embedded spaces and leading zeroes and ensure a comma delimiter
					select @sInClause = ISNULL(NULLIF(@sInClause + " and ", " and "),"") +
						"','+replace(XC.INTCLASSES,' ','')+',' not like " + dbo.fn_WrapQuotes("%,"+Parameter+","+"%",0,1)
					from dbo.fn_Tokenise(@sClasses,",")

					Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If ISNULL(@nOriginalClassesOperator, @nClassesOperator) = 2
				Begin
					set @sInClause = null
					-- remove embedded spaces and leading zeroes and ensure a comma delimiter
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"','+replace(XC.INTCLASSES,' ','')+',' like " + dbo.fn_WrapQuotes("%,"+Parameter+"%",0,1)
					from dbo.fn_Tokenise(@sClasses,",")

					If @bIsLocal=1
						Set @sWhere = @sWhere+char(10)+"	or	("+@sInClause+")"
					Else
						Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If ISNULL(@nOriginalClassesOperator, @nClassesOperator) = 5
				Begin
					If @bIsLocal=1
						Set @sWhere = @sWhere+char(10)+"	or	(XC.INTCLASSES "+dbo.fn_ConstructOperator(ISNULL(@nOriginalClassesOperator, @nClassesOperator),@CommaString,@sClasses, 1,@pbCalledFromCentura)+")"
					Else
						Set @sWhere = @sWhere+char(10)+"	and	(XC.INTCLASSES"+dbo.fn_ConstructOperator(ISNULL(@nOriginalClassesOperator, @nClassesOperator),@CommaString,@sClasses, 1,@pbCalledFromCentura)+")"
				End
				Else If ISNULL(@nOriginalClassesOperator, @nClassesOperator) = 6
				Begin
					------------------------------------------------------------------
					-- RFC12131
					-- It doesn't matter if the Local Class has also been considered
					-- as the operator must be an AND for both Local and International
					-- Classes to be considered to Not Exist.
					------------------------------------------------------------------
					Set @sWhere = @sWhere+char(10)+"	and	(XC.INTCLASSES"+dbo.fn_ConstructOperator(ISNULL(@nOriginalClassesOperator, @nClassesOperator),@CommaString,@sClasses, 1,@pbCalledFromCentura)+")"
				End

				-- Logic for @nClassesOperator = 3 and 4 is not correct. It should be
				-- corrected in the future when it will be used in the UI.

				/*
				Else If @nClassesOperator = 3
				Begin
					set @sInClause = null
					-- remove embedded spaces and leading zeroes and ensure a comma delimiter
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"replace(','+replace(XC.INTCLASSES,' ','')+',',',0',',') like " + replace(dbo.fn_WrapQuotes("%,_"+Parameter+","+"%",0,1),",0",",")
					from dbo.fn_Tokenise(@sClasses,",")

					If @bIsLocal=1
						Set @sWhere = @sWhere+char(10)+"	or	"+@sInClause
					Else
						Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				Else If @nClassesOperator = 4
				Begin
					set @sInClause = null
					-- remove embedded spaces and leading zeroes and ensure a comma delimiter
					select @sInClause = ISNULL(NULLIF(@sInClause + " or ", " or "),"") +
						"replace(','+replace(XC.INTCLASSES,' ','')+',',',0',',') like " + replace(dbo.fn_WrapQuotes("%"+Parameter+"%",0,1),",0",",")
					from dbo.fn_Tokenise(@sClasses,",")

					If @bIsLocal=1
						Set @sWhere = @sWhere+char(10)+"	or	"+@sInClause
					Else
						Set @sWhere = @sWhere+char(10)+"	and	("+@sInClause+")"
				End
				*/
			End

			If @bIsLocal=1
			Begin
				-- Close bracket
				Set @sWhere=@sWhere+")"
			End

		End

		If @sKeyWord is not NULL
		or @nKeyWordOperator between 2 and 6
		Begin
			-- SQA6395 Search for the synonyms of keywords as well
			Set @sFrom = @sFrom+char(10)+"	join KEYWORDS XKW WITH (NOLOCK) on (XKW.KEYWORD"+dbo.fn_ConstructOperator(@nKeyWordOperator,@String,@sKeyWord, null,@pbCalledFromCentura)+")"
				           +char(10)+"	left join SYNONYMS XSY WITH (NOLOCK) on (XKW.KEYWORDNO in (XSY.KEYWORDNO, XSY.KWSYNONYM))"
					   +char(10)+"	join CASEWORDS XCW WITH (NOLOCK) on (XCW.CASEID     = XC.CASEID"
					   +char(10)+"	                  	and XCW.KEYWORDNO in (XKW.KEYWORDNO, XSY.KWSYNONYM, XSY.KEYWORDNO))"
		End

		If isnull(@sFamilyKeyList, @sFamilyKeys) is not NULL
		or isnull(@nFamilyKeyListOperator, @nFamilyKeyOperator) between 2 and 6
		Begin
			Set @sWhere = case 
				when @sFamilyKeyList is not null and @nFamilyKeyListOperator = 0 then @sWhere+char(10)+"	and	XC.FAMILY in (" + @sFamilyKeyList + ")"
				when @sFamilyKeyList is not null and @nFamilyKeyListOperator = 1 then @sWhere+char(10)+"	and	XC.FAMILY not in (" + @sFamilyKeyList + ")"
				when @nFamilyKeyListOperator = 5 then @sWhere+char(10)+"	and	XC.FAMILY is not null"
				when @nFamilyKeyListOperator = 6 then @sWhere+char(10)+"	and	XC.FAMILY is null"
				else @sWhere+char(10)+"	and	XC.FAMILY"+dbo.fn_ConstructOperator(@nFamilyKeyOperator, @CommaString, @sFamilyKeys, null, @pbCalledFromCentura)
			End
		End

		If @sTitle is not NULL
		or @nTitleOperator between 2 and 6
		Begin
			-- When @bTitleSoundsLike is turned on, the words in Title are compared to KeyWords for the case
			-- using a sound-alike algorithm.  If there are multiple words in Title, they are treated separately
			-- and a case is returned if any of the words matches.

			If @bTitleSoundsLike = 1
			Begin
				Set @sFrom = @sFrom+char(10)+"	Join (Select distinct CW.CASEID"
						   +char(10)+"	      from dbo.fn_Tokenise("+dbo.fn_WrapQuotes(@sTitle,0,@pbCalledFromCentura)+", ' ') TOK"
						   +char(10)+"	      join KEYWORDS  KW WITH (NOLOCK) ON (dbo.fn_SoundsLike(KW.KEYWORD) = dbo.fn_SoundsLike(TOK.Parameter))"
						   +char(10)+"	      join CASEWORDS CW WITH (NOLOCK) ON (CW.KEYWORDNO = KW.KEYWORDNO)) XCW on (XCW.CASEID=XC.CASEID)"
			End
			Else
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	"+dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'XC',@sLookupCulture,@pbCalledFromCentura)+dbo.fn_ConstructOperator(@nTitleOperator,@String,@sTitle, null,@pbCalledFromCentura)
			End
		End

		If @nTypeOfMarkKey is not NULL
		or @nTypeOfMarkKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.TYPEOFMARK"+dbo.fn_ConstructOperator(@nTypeOfMarkKeyOperator,@Numeric,@nTypeOfMarkKey, null,@pbCalledFromCentura)
		End

		If @nEntitySize is not NULL
		or @nEntitySizeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XC.ENTITYSIZE"+dbo.fn_ConstructOperator(@nEntitySizeOperator, @Numeric, @nEntitySize, null, @pbCalledFromCentura)
		End

		-- RFC5760 Marketing Activity Search - provide minimal filtering on Case Budget Amount
		If @nBudgetAmountFrom is not null
		or @nBudgetAmountTo is not null
		or @nBudgetAmountOperator is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	ISNULL(XC.BUDGETAMOUNT,0)"+dbo.fn_ConstructOperator(@nBudgetAmountOperator,@Numeric,@nBudgetAmountFrom, @nBudgetAmountTo,@pbCalledFromCentura)
		End

		-------------------------------------------------
		-- Beginning of the Standing Instructions section
		-------------------------------------------------

		-- If the Instruction Key or a specific Flag has been specified along with the NOT operator
		-- then we must find the InstructionType so we can find Cases that do have
		-- a Standing Instruction of that InstructionType but where
		-- the actual Instruction or associated InstructionFlag does not match the
		-- the value specified.
		If   @nInstructionKey is not null
		 and(@nInstructionKeyOperator=1 OR @bIncludeInherited=1)
		Begin
			Set @sSQLString="
			select @sInstructionType=I.INSTRUCTIONTYPE
			from INSTRUCTIONS I
			where I.INSTRUCTIONCODE=@nInstructionKey"

			exec sp_executesql @sSQLString,
					N'@sInstructionType	nvarchar(3)	OUTPUT,
					  @nInstructionKey	smallint',
					  @sInstructionType=@sInstructionType	OUTPUT,
					  @nInstructionKey =@nInstructionKey
		End
		Else If  @nCharacteristicFlag is not null
		     and(@nCharacteristicFlagOperator=1 OR @bIncludeInherited=1)
		Begin
			Set @sSQLString="
			select @sInstructionType=L.INSTRUCTIONTYPE
			from INSTRUCTIONLABEL L
			where L.FLAGNUMBER=@nCharacteristicFlag"

			exec sp_executesql @sSQLString,
					N'@sInstructionType	nvarchar(3)	OUTPUT,
					  @nCharacteristicFlag	smallint',
					  @sInstructionType=@sInstructionType	OUTPUT,
					  @nCharacteristicFlag=@nCharacteristicFlag
		End

		If @bIncludeInherited = 1
		and @sInstructionType is not null
		Begin
			Set @sFrom  = @sFrom +char(10)+"	join CASEINSTRUCTIONS CSI WITH (NOLOCK) on (CSI.CASEID = XC.CASEID"
					     +char(10)+"	                                        and CSI.INSTRUCTIONTYPE="+dbo.fn_WrapQuotes(@sInstructionType,0,@pbCalledFromCentura)+")"

			-- Users can opt to either filter on the Standing Instructions, or using
			-- the Instruction Characteristics.
			If @nInstructionKey is not NULL
			Begin
				If @nInstructionKeyOperator = 0
				Begin
					Set @sWhere = @sWhere+char(10)+"	and CSI.INSTRUCTIONCODE = "+cast(@nInstructionKey as nvarchar(6))
				End
				Else If @nInstructionKeyOperator = 1
				Begin
					Set @sWhere = @sWhere+char(10)+"	and CSI.INSTRUCTIONCODE <>"+cast(@nInstructionKey as nvarchar(6))
				End
			End
			Else If @nCharacteristicFlag is not NULL
			Begin
				-- Only Operators Equal To and Not Equal To are implemented.
				If @nCharacteristicFlagOperator = 0
				Begin
					Set @sFrom  = @sFrom +char(10)+"	join INSTRUCTIONFLAG FLG WITH (NOLOCK) on (FLG.INSTRUCTIONCODE = CSI.INSTRUCTIONCODE"
							     +char(10)+"	                                       and FLG.FLAGNUMBER="+cast(@nCharacteristicFlag as nvarchar(10))+")"
				End
				Else If @nCharacteristicFlagOperator = 1
				Begin
					Set @sFrom  = @sFrom +char(10)+"	left join INSTRUCTIONFLAG FLG WITH (NOLOCK) on (FLG.INSTRUCTIONCODE = CSI.INSTRUCTIONCODE"
							     +char(10)+"	                                            and FLG.FLAGNUMBER="+cast(@nCharacteristicFlag as nvarchar(10))+")"
					Set @sWhere = @sWhere+char(10)+"	and FLG.INSTRUCTIONCODE is null"
				End

			End
		End
		Else If @nInstructionKey     is not NULL
		     OR @nCharacteristicFlag is not NULL
		Begin
			Set @sFrom = @sFrom+char(10)+"	join NAMEINSTRUCTIONS XNI WITH (NOLOCK) on (XNI.CASEID = XC.CASEID)"

			-- Users can opt to either filter on the Standing Instructions, or use
			-- the Instruction Characteristics.
			If @nInstructionKey is not NULL
			Begin
				-- Only Operators Equal To and Not Equal To are implemented.
				If @nInstructionKeyOperator = 0
				Begin
					Set @sWhere = @sWhere+char(10)+"	and XNI.INSTRUCTIONCODE = "+cast(@nInstructionKey as nvarchar(10))
				End
				Else If @nInstructionKeyOperator = 1
				Begin
					Set @sFrom = @sFrom+char(10)+"	join INSTRUCTIONS XI WITH (NOLOCK) on (XI.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE)"
					Set @sWhere = @sWhere+char(10)+"	and XNI.INSTRUCTIONCODE <> "+cast(@nInstructionKey as nvarchar(10))
							     +char(10)+"	and XI.INSTRUCTIONTYPE="+dbo.fn_WrapQuotes(@sInstructionType,0,@pbCalledFromCentura)
				End
			End
			Else If @nCharacteristicFlag is not NULL
			Begin
				-- Only Operators Equal To and Not Equal To are implemented.
				If @nCharacteristicFlagOperator = 0
				Begin
					Set @sFrom  = @sFrom +char(10)+"	join INSTRUCTIONFLAG FLG WITH (NOLOCK) on (FLG.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE)"
					Set @sWhere = @sWhere+char(10)+"	and FLG.FLAGNUMBER="+cast(@nCharacteristicFlag as nvarchar(10))
				End
				Else If @nCharacteristicFlagOperator = 1
				Begin
					Set @sFrom = @sFrom+char(10)+"	join INSTRUCTIONS XI WITH (NOLOCK) on (XI.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE)"
					Set @sWhere = @sWhere+char(10)+"	and XI.INSTRUCTIONTYPE="+dbo.fn_WrapQuotes(@sInstructionType,0,@pbCalledFromCentura)
							     +char(10)+"	and not exists (select 1 from INSTRUCTIONFLAG FLG"
						     	     +char(10)+"			where FLG.FLAGNUMBER = "+cast(@nCharacteristicFlag as nvarchar(10))
						     	     +char(10)+"			and   FLG.INSTRUCTIONCODE = XNI.INSTRUCTIONCODE)"
				End
			End

		End
		Else If @nInstructionKeyOperator in (5,6)
		Begin
			If @nInstructionKeyOperator in (5)
			Begin
				Set @sWhere = @sWhere+char(10)+" and exists (Select 1"
						     +char(10)+"	     from  NAMEINSTRUCTIONS XNI"
					     	     +char(10)+"	     where XNI.CASEID = XC.CASEID)"
			End
			Else Begin
				Set @sWhere = @sWhere+char(10)+" and not exists (Select 1"
						     +char(10)+"	     from  NAMEINSTRUCTIONS XNI"
					     	     +char(10)+"	     where XNI.CASEID = XC.CASEID)"
			End
		End-- End of the Standing Instructions section

		------------------------------------------------------------------------
		-- RFC9505
		-- Return cases linked to Name via specified NameTypes where those Names
		-- are associtated with the connected user via specified Relationships.
		------------------------------------------------------------------------
		If  @sNameRelations    is not NULL
		and @sRelatedNameTypes is not NULL
		and @nUserNameNo       is not NULL
		Begin
			Set @sFrom = @sFrom+char(10)+"	join ASSOCIATEDNAME XAN WITH (NOLOCK) on (XAN.RELATEDNAME="+convert(nvarchar,@nUserNameNo)
					   +char(10)+"                                        and XAN.RELATIONSHIP"+dbo.fn_ConstructOperator(@nNameRelationsOperator,@CommaString,@sNameRelations, null,@pbCalledFromCentura)+")"
					   +char(10)+"	join CASENAME XRCN WITH (NOLOCK) on (XRCN.CASEID     = XC.CASEID"
					   +char(10)+"	                  	         and XRCN.NAMETYPE"+dbo.fn_ConstructOperator(@nNameRelationsOperator,@CommaString,@sRelatedNameTypes, null,@pbCalledFromCentura)
				           +char(10)+"	                  	         and XRCN.NAMENO=XAN.NAMENO"
				           +char(10)+"	                  	         and XRCN.EXPIRYDATE is null)"
		End


		-- Set @nCount to 1 so it points to the first record of the table
		Set @nCount = 1

		-- @nCaseNameRowCount is the number of rows in the @tblCaseNameGroup table, which is used to loop the CaseNames while constructing the 'From' and the 'Where' clause
		While @nCount <= @nCaseNameRowCount
		Begin
			If @nCount=1
			Begin
				-- RFC1717 Ensure that the filter criteria is limited to values the user may view
				Set @sList = null
				Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NAMETYPE,0,@pbCalledFromCentura)
				From dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura)
			End

			Set @sCorrelationName = 'XCNK_' + cast(@nCount as nvarchar(20))

			Select  @sNameKeysTypeKey		= NameKeysTypeKey,
				@sNameKeys	 		= NameKeys,
				@sCaseNameName			= [Name],
				@bCaseNameNameUseAttentionName	= NameUseAttentionName,
			     	@nNameKeysOperator		= NameKeysOperator,
				@bNameIncludeExpired		= NameIncludeExpired,
				@sNameVariantKeys		= NameVariantKeys,
				@bUseAttentionName		= UseAttentionName,
				@bIsCurrentUser			= IsCurrentUser,
				@nNameGroupKey			= NameGroupKey,
				@nNameGroupKeyOperator		= NameGroupKeyOperator,
				@bNameGroupIncludeExpired	= NameGroupIncludeExpired,
				@sNameGroupTypeKey		= NameGroupTypeKey
			from	@tblCaseNameGroup
			where   CaseNameIdentity = @nCount

			-- If Instructor Name is being filtered on then check to
			-- see if any Attention Names are also being searched on and
			-- if so this will be combined with the Instructor search
			If @sNameKeysTypeKey='I'
			and @nNameKeysOperator=0
			Begin
				Select  @sInstructorAttnKeys  = NameKeys,
					@sInstructorAttnName  = [Name],
					@nAttnKeysOperator    = NameKeysOperator,
					@bMatchInstructorAttn = 1,
					@nAttentionRow	      = CaseNameIdentity
				from	@tblCaseNameGroup
				where   CaseNameIdentity <> @nCount
				and	NameKeysTypeKey is null
				and    (NameUseAttentionName=1 OR UseAttentionName=1)
				and 	NameKeysOperator is not null
			End
			Else Begin
				Set @sInstructorAttnKeys  = Null
				Set @sInstructorAttnName  = Null
				Set @bMatchInstructorAttn = Null
				Set @nAttentionRow	  = Null
			End

			If (@sNameKeys is not null
			or  @sCaseNameName is not null
			or  @sNameKeysTypeKey is not null
			or  @sNameVariantKeys is not null
			or  @nNameKeysOperator between 1 and 6)
			or (@nNameGroupKey is not null
			or  @nNameGroupKeyOperator between 2 and 6
			or  @sNameGroupTypeKey is not  null)
			Begin
				If @bCaseNameGroupBooleanOr = 1
				or @nNameKeysOperator  in (1, 6)
				or @nNameGroupKeyOperator = 6
				Begin
					Set @sFrom=@sFrom+char(10)+"	Left Join (Select distinct CN.CASEID from CASENAME CN with(NOLOCK)"
				End
				Else Begin
					Set @sFrom=@sFrom+char(10)+"	     Join (Select distinct CN.CASEID from CASENAME CN with(NOLOCK)"
				End

				If  @nNameGroupKey is not null
				or  @nNameGroupKeyOperator between 2 and 6
				Begin
					If @nNameGroupKeyOperator not in (5,6)
					Begin
						Set @sFrom = @sFrom+char(10)+"	           join [NAME] N WITH (NOLOCK) on (N.NAMENO = CN.NAMENO"
								   +char(10)+"	                                       and N.FAMILYNO "+dbo.fn_ConstructOperator(@nNameGroupKeyOperator,@Numeric,@nNameGroupKey, null,0)+")"
					End
	 				Else
					Begin
						Set @sFrom = @sFrom+char(10)+"	           join [NAME] N WITH (NOLOCK) on (N.NAMENO = CN.NAMENO"
								   +char(10)+"	                                       and N.FAMILYNO is not null)"
					End
				End

				-- RFC3220 If @bCaseNameNameUseAttentionName = 1, join against CORRESPONDNAME to get AttentionName
				-- else join against NAMENO to get NAME
				If @sCaseNameName is not null
				Begin
					If @bCaseNameNameUseAttentionName = 1
						Set @sFrom = @sFrom+char(10)+"	           join [NAME] NA WITH (NOLOCK) on (NA.NAMENO = CN.CORRESPONDNAME)"
					Else
						Set @sFrom = @sFrom+char(10)+"	           join [NAME] NA WITH (NOLOCK) on (NA.NAMENO = CN.NAMENO)"
				End

				If @sInstructorAttnName is not null
				Begin
					Set @sFrom = @sFrom+char(10)+"	           join [NAME] ATTN WITH (NOLOCK) on (ATTN.NAMENO = CN.CORRESPONDNAME)"
				End

				If  @bNameIncludeExpired = 1
				or @bNameGroupIncludeExpired = 1
				Begin
					Set @sFrom = @sFrom+char(10)+"	           where 2=2"
				End
				Else
				Begin
					Set @sFrom = @sFrom+char(10)+"	           where (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate())"
				End

				Set @sFrom= @sFrom+char(10)+"	           and CN.NAMETYPE IN ("+@sList+")"

				--SQA10635
				If @bIsCurrentUser = 1
				Begin
					-- Replace the search name with the linked staff of the current login user
					Select @sNameKeys = UI.NAMENO
					from USERIDENTITY UI
					where UI.IDENTITYID = @pnUserIdentityId
				End

				-- Check to see if the Instructor record is also being restricted
				-- by one or more Attention Names.
				-- NOTE: this code had disappeared from version 6.3 onwards for no obvious reason
				If  @sInstructorAttnKeys is not null
				Begin
					If @nAttnKeysOperator not in (5,6)
					Begin
						Set @sFrom = @sFrom+char(10)+"	           and CN.CORRESPONDNAME"+dbo.fn_ConstructOperator(@nAttnKeysOperator,@Numeric,@sInstructorAttnKeys, null,@pbCalledFromCentura)
					End
					Else Begin
						Set @sFrom = @sFrom+char(10)+"	           and CN.CORRESPONDNAME is not null"
					End
				End

				-- Check if to use @sNameKeys or @sCaseNameName
				If @sNameKeys is not null
				Begin
						------------------------------------------
						-- Where NameKeys are in use the operator
						-- for Starts With, Ends With and Contains
						-- will be substituted with Equal
						------------------------------------------
						If @nNameKeysOperator in (2,3,4)
							set @nNameKeysOperator=0

					If @nNameKeysOperator = 1 -- Not Equal To
					Begin
						-- If Operator is "Not Equal To" switch to use "Equal To" and then later
						-- test for the non existence of the CaseName row.
						If @bUseAttentionName = 1
							Set @sFrom = @sFrom+char(10)+"	 and  (CN.NAMENO"+dbo.fn_ConstructOperator(0,@Numeric,@sNameKeys, null,@pbCalledFromCentura)+" OR CN.CORRESPONDNAME"+dbo.fn_ConstructOperator(0,@Numeric,@sNameKeys, null,@pbCalledFromCentura)+")"
						Else
						Set @sFrom = @sFrom+char(10)+"	 and  CN.NAMENO"+dbo.fn_ConstructOperator(0,@Numeric,@sNameKeys, null,@pbCalledFromCentura)
					End
					Else If @nNameKeysOperator not in (5,6)
				      Begin
						If @bUseAttentionName = 1
							Set @sFrom = @sFrom+char(10)+"	 and  (CN.NAMENO"+dbo.fn_ConstructOperator(@nNameKeysOperator,@Numeric,@sNameKeys, null,@pbCalledFromCentura)+"OR CN.CORRESPONDNAME"+dbo.fn_ConstructOperator(@nNameKeysOperator,@Numeric,@sNameKeys, null,@pbCalledFromCentura)+")"
						Else
				          Set @sFrom = @sFrom+char(10)+"	 and  CN.NAMENO"+dbo.fn_ConstructOperator(@nNameKeysOperator,@Numeric,@sNameKeys, null,@pbCalledFromCentura)
				      End
					Else If  @nNameKeysOperator = 5
					     and @bUseAttentionName = 1
						Set @sFrom = @sFrom+char(10)+"	 and  CN.CORRESPONDNAME is not null"
					Else If  @nNameKeysOperator = 6
					     and @bUseAttentionName = 1
						Set @sFrom = @sFrom+char(10)+"	 and  CN.CORRESPONDNAME is null"
				End

				-- RFC3220 Operator supported between 0 - 6.
				If @sCaseNameName is not null
				Begin
					if (@nNameKeysOperator not in (5,6))
					Begin
						Set @sFrom = @sFrom+char(10)+" and (NA.[NAME]"+dbo.fn_ConstructOperator(@nNameKeysOperator,@String,@sCaseNameName, null,@pbCalledFromCentura)+char(10)+
										"or NA.[FIRSTNAME]"+dbo.fn_ConstructOperator(@nNameKeysOperator,@String,@sCaseNameName, null,@pbCalledFromCentura)+char(10)+
										")"
					End
					Else Begin
						Set @sFrom = @sFrom+char(10)+"	           and NA.[NAME]"+dbo.fn_ConstructOperator(@nNameKeysOperator,@String,@sCaseNameName, null,@pbCalledFromCentura)
				End
				End

				If @sInstructorAttnName is not null
				Begin
					Set @sFrom = @sFrom+char(10)+"	           and ATTN.[NAME]"+dbo.fn_ConstructOperator(@nAttnKeysOperator,@String,@sInstructorAttnName, null,@pbCalledFromCentura)
				End

				If @nNameKeysOperator not in (5,6)
				Begin
					If @sNameVariantKeys is not null
						Set @sFrom = @sFrom+char(10)+"	           and CN.NAMEVARIANTNO"+dbo.fn_ConstructOperator(@nNameKeysOperator,@Numeric,@sNameVariantKeys, null,@pbCalledFromCentura)
				End

				If @sNameKeysTypeKey is not null
				Begin
					Set @sFrom = @sFrom+char(10)+"	           and CN.NAMETYPE = "+dbo.fn_WrapQuotes(@sNameKeysTypeKey,0,@pbCalledFromCentura)
				End

				If @sNameGroupTypeKey is not null
				Begin
					Set @sFrom = @sFrom+char(10)+"	          and CN.NAMETYPE = "+dbo.fn_WrapQuotes(@sNameGroupTypeKey,0,@pbCalledFromCentura)
				End

				Set @sFrom = @sFrom+") "+@sCorrelationName+" on (" + @sCorrelationName + ".CASEID = XC.CASEID)"

				-- RFC4671 optionally to match one or all casenames
				If @bCaseNameGroupBooleanOr = 1
				Begin
					If @nCount=1
						set @sWhere =@sWhere+char(10)+"and COALESCE("+@sCorrelationName+".CASEID"
					Else
						set @sWhere =@sWhere+","+@sCorrelationName+".CASEID"

					If @nCount=@nCaseNameRowCount
						set @sWhere =@sWhere+") is not null"
				End
				-- If Operator is set to IS NULL or NOT EQUAL TO then check no matching CASEID exists
				Else If @nNameKeysOperator in (1,6)
				     or @nNameGroupKeyOperator = 6
				Begin
					set @sWhere =@sWhere+char(10)+"and "+@sCorrelationName+".CASEID is null"
				End

			End

			Set @nCount = @nCount + 1

			-- If next row to process is the Attention row that
			-- was associated with the Instructor, then skip
			-- it as no additional filtering is required.
			If @nCount=@nAttentionRow
				Set @nCount=@nCount+1
		End

		If @sReferenceNo is not NULL
		or @sReferenceTypeKey is not null
		or @nReferenceNoOperator between 2 and 6
		Begin
			-- If Operator is set to IS NULL then use LEFT JOIN
			If @nReferenceNoOperator = 6
			Begin
				set @sFrom =@sFrom+char(10)+"	Left Join (Select distinct CN.CASEID from CASENAME CN with (NOLOCK)"
			End
			Else
			Begin
				Set @sFrom =@sFrom+char(10)+"	Join (Select distinct CN.CASEID from CASENAME CN with (NOLOCK)"
			End

			Set @sFrom = @sFrom+char(10)+"	      where (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate())"

			-- RFC1717 Ensure that the filter criteria is limited to values the user may view
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NAMETYPE,0,@pbCalledFromCentura)
			From dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null,@pbIsExternalUser,@pbCalledFromCentura)

			Set @sFrom= @sFrom+char(10)+"	      and CN.NAMETYPE IN ("+@sList+")"

			If @nReferenceNoOperator not in (5,6)
			and @sReferenceNo is not null
			Begin
				Set @sFrom=@sFrom+char(10)+"	      and CN.REFERENCENO"+dbo.fn_ConstructOperator(@nReferenceNoOperator,@String,@sReferenceNo, null,@pbCalledFromCentura)
			End
			Else
			Begin
				Set @sFrom=@sFrom+char(10)+"	      and CN.REFERENCENO is not null"
			End

			If @sReferenceTypeKey is not null
			Begin
				Set @sFrom=@sFrom+char(10)+"	      and CN.NAMETYPE=" + dbo.fn_WrapQuotes(@sReferenceTypeKey,0,@pbCalledFromCentura)
			End

			Set @sFrom=@sFrom+") XCNR on (XCNR.CASEID=XC.CASEID)"

			If @nReferenceNoOperator = 6
				Set @sWhere = @sWhere+char(10)+" and XCNR.CASEID is null"
		End

		-- SQA12337 Filter on Cases where the associated Name  has
		-- been inherited (or not inherited).
		If @nInheritParentNameKey           is not null
		or @nInheritParentNameKeyOperator   is not null
		or @sInheritNameTypeKey             is not null
		or @nInheritNameTypeKeyOperator     is not null
		or @sInheritRelationshipKey         is not null
		or @nInheritRelationshipKeyOperator is not null
		Begin
			Set @sFrom = @sFrom+char(10)+"	Join (Select distinct CASEID from CASENAME with (NOLOCK)"
			                   +char(10)+"	      Where 2=2"


			select @sList=dbo.fn_WrapQuotes(@nInheritParentNameKey,1,@pbCalledFromCentura)
			If @nInheritParentNameKeyOperator=6
				Set @sFrom = @sFrom+char(10)+"	      and isnull(INHERITED,0)=0"
			Else
				Set @sFrom = @sFrom+char(10)+"	      and INHERITED=1"

			If  @nInheritParentNameKey is not null
			and @nInheritParentNameKeyOperator=1
			Begin
				Set @sFrom = @sFrom+char(10)+"	      and isnull(INHERITEDNAMENO,-99999999) NOT IN ("+@sList+ ")"+char(10)+
							     "	      and isnull(NAMENO,-99999999)         NOT IN ("+@sList+ ") "
			End
			Else If  @nInheritParentNameKey is not null
			     and @nInheritParentNameKeyOperator=0
			Begin
				Set @sFrom = @sFrom+char(10)+"	      and (INHERITEDNAMENO IN ("+@sList+ ")"+char(10)+
							     "	       or (NAMENO         IN ("+@sList+") and INHERITEDNAMENO is null))"
			End

			If @sInheritNameTypeKey is not null
			Begin
				Set @sFrom = @sFrom+char(10)+"	      and NAMETYPE"+dbo.fn_ConstructOperator(@nInheritNameTypeKeyOperator,@CommaString,@sInheritNameTypeKey, null,@pbCalledFromCentura)
			End

			If @sInheritRelationshipKey is not null
			Begin
				Set @sFrom = @sFrom+char(10)+"	      and INHERITEDRELATIONS"+dbo.fn_ConstructOperator(@nInheritRelationshipKeyOperator,@String,@sInheritRelationshipKey, null,@pbCalledFromCentura)
			End

			Set @sFrom = @sFrom+") CN_INH on (CN_INH.CASEID = XC.CASEID)"
		End

		-- RFC5763 Opportunity Search (CRM WorkBench)
		If (@nOpportunitySource is not null or @nOpportunitySourceOperator between 2 and 6)
		or (@sOpporunityRemarks is not null or @nOpportunityRemarksOperator between 2 and 6)
		or (@dtOpportunityExpCloseDateFrom is not null or @dtOpportunityExpCloseDateTo is not null)
		or (@nOpportunityPotentialValueFrom is not null or @nOpportunityPotentialValueTo is not null)
		or (@sOpportunityPotValCurCode is not null or @nOpportunityPotValCurOperator between 5 and 6)
		or (@sOpportunityNextStep is not null or @nOpportunityNextStepOperator between 5 and 6)
		or (@nOpportunityPotentialWinFrom is not null or @nOpportunityPotentialWinTo is not null)
		or (@nOpportunityNumberOfStaffFrom is not null or @nOpportunityNumberOfStaffTo is not null)
		Begin
			If (@nOpportunitySource is not null or @nOpportunitySourceOperator between 2 and 6)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	OPP.SOURCE"+dbo.fn_ConstructOperator(@nOpportunitySourceOperator,@String,@nOpportunitySource, null,@pbCalledFromCentura)
			End

			If (@sOpporunityRemarks is not null or @nOpportunityRemarksOperator between 2 and 6)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	OPP.REMARKS"+dbo.fn_ConstructOperator(@nOpportunityRemarksOperator,@String,@sOpporunityRemarks, null,@pbCalledFromCentura)
			End

			If @dtOpportunityExpCloseDateFrom is not null
			or @dtOpportunityExpCloseDateTo   is not null
			Begin
				if (@nOpportunityExpCloseDateOperator=8)
				Begin
					Set @sWhere =  @sWhere+char(10)+"	and	(OPP.EXPCLOSEDATE"+dbo.fn_ConstructOperator(@nOpportunityExpCloseDateOperator,@Date,convert(nvarchar,@dtOpportunityExpCloseDateFrom,112), convert(nvarchar,@dtOpportunityExpCloseDateTo,112),@pbCalledFromCentura)+char(10)+
									"		or OPP.EXPCLOSEDATE is null)"
				End
				Else
				Begin
					Set @sWhere =  @sWhere+char(10)+"	and	OPP.EXPCLOSEDATE"+dbo.fn_ConstructOperator(@nOpportunityExpCloseDateOperator,@Date,convert(nvarchar,@dtOpportunityExpCloseDateFrom,112), convert(nvarchar,@dtOpportunityExpCloseDateTo,112),@pbCalledFromCentura)
				End
			End

			select @sHomeCurrency = COLCHARACTER
			from SITECONTROL
			where CONTROLID = 'CURRENCY'

			If @nOpportunityPotentialValueFrom is not NULL
			or @nOpportunityPotentialValueTo is not NULL
			or @nOpportunityPotentialValueOperator is not null
			Begin
				If (@sOpportunityPotValCurCode is not null and @sOpportunityPotValCurCode != @sHomeCurrency)
				Begin
					-- If Currency is specified, don't bother checking the local amount.
					Set @sWhere = @sWhere+char(10)+"	and	OPP.POTENTIALVALUE"+dbo.fn_ConstructOperator(@nOpportunityPotentialValueOperator,@Numeric,@nOpportunityPotentialValueFrom, @nOpportunityPotentialValueTo,@pbCalledFromCentura)
				End
				Else If (@sOpportunityPotValCurCode = @sHomeCurrency)
				Begin
					-- force local search
					Set @sWhere = @sWhere+char(10)+"	and	ISNULL(OPP.POTENTIALVALUELOCAL,0)"+dbo.fn_ConstructOperator(@nOpportunityPotentialValueOperator,@Numeric,@nOpportunityPotentialValueFrom, @nOpportunityPotentialValueTo,@pbCalledFromCentura)
				End
				Else
				Begin
				Set @sWhere = @sWhere+char(10)+"	and	ISNULL(ISNULL(OPP.POTENTIALVALUE,OPP.POTENTIALVALUELOCAL),0)"+dbo.fn_ConstructOperator(@nOpportunityPotentialValueOperator,@Numeric,@nOpportunityPotentialValueFrom, @nOpportunityPotentialValueTo,@pbCalledFromCentura)
			End
		End

			If (@sOpportunityPotValCurCode is not NULL or @nOpportunityPotValCurOperator between 5 and 6)
			Begin
				If  (@sOpportunityPotValCurCode != @sHomeCurrency or @sOpportunityPotValCurCode is NULL)
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	OPP.POTENTIALVALCURRENCY"+dbo.fn_ConstructOperator(@nOpportunityPotValCurOperator,@String,@sOpportunityPotValCurCode, null,@pbCalledFromCentura)
				End
				Else
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	(OPP.POTENTIALVALCURRENCY is null or OPP.POTENTIALVALCURRENCY"+dbo.fn_ConstructOperator(@nOpportunityPotValCurOperator,@String,@sOpportunityPotValCurCode, null,@pbCalledFromCentura) + ")"
				End
			End

			If (@sOpportunityNextStep is not null or @nOpportunityNextStepOperator between 5 and 6)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	OPP.NEXTSTEP"+dbo.fn_ConstructOperator(@nOpportunityNextStepOperator,@String,@sOpportunityNextStep, null,@pbCalledFromCentura)
			End

			If (@nOpportunityPotentialWinFrom is not NULL
			or @nOpportunityPotentialWinTo is not NULL)
			and @nOpportunityPotentialWinOperator is not null
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	OPP.POTENTIALWIN"+dbo.fn_ConstructOperator(@nOpportunityPotentialWinOperator,@Numeric,@nOpportunityPotentialWinFrom, @nOpportunityPotentialWinTo,@pbCalledFromCentura)
			End

			If (@nOpportunityNumberOfStaffFrom is not NULL
			or @nOpportunityNumberOfStaffTo is not NULL)
			and @nOpportunityNumberOfStaffOperator is not null
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	isnull(OPP.NUMBEROFSTAFF,0)"+dbo.fn_ConstructOperator(@nOpportunityNumberOfStaffOperator,@Numeric,@nOpportunityNumberOfStaffFrom, @nOpportunityNumberOfStaffTo,@pbCalledFromCentura)
			End
		End

		If (@nOpportunityStatus is not null or @nOpportunityStatusOperator between 2 and 6)
		Begin
			Set @sFrom=@sFrom+char(10)+"left join (Select XOCSH.CASEID, XOCSH.CRMCASESTATUS"+char(10)+
						"		From CRMCASESTATUSHISTORY XOCSH"+char(10)+
						"		Join (Select MAX(STATUSID) as MAXSTATUSID, CASEID"+char(10)+
						"			From CRMCASESTATUSHISTORY"+char(10)+
						"			Group by CASEID) XMAXOCSH on (XMAXOCSH.MAXSTATUSID = XOCSH.STATUSID)) as XOCSH on (XOCSH.CASEID = OPP.CASEID)"

			set @sWhere=@sWhere+char(10)+"	and XOCSH.CRMCASESTATUS"+dbo.fn_ConstructOperator(@nOpportunityStatusOperator,@Numeric,@nOpportunityStatus, null,0)
		End

		-- RFC5760 Campaign Search - variation of Marketing Activities search (CRM WorkBench)
		If @nMktActivityActualCostFrom is not null
		or @nMktActivityActualCostTo is not null
		or @nMktActivityActualCostOperator is not null
		Begin
			If (@sMktActivityActualCostCurrency is not null and @sMktActivityActualCostCurrency != @sHomeCurrency)
			Begin
				-- If Currency is specified, don't bother checking the local amount.
				Set @sWhere = @sWhere+char(10)+"	and	M.ACTUALCOST"+dbo.fn_ConstructOperator(@nMktActivityActualCostOperator,@Numeric,@nMktActivityActualCostFrom, @nMktActivityActualCostTo,@pbCalledFromCentura)
			End
			Else If (@sMktActivityActualCostCurrency = @sHomeCurrency)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	ISNULL(M.ACTUALCOSTLOCAL,0)"+dbo.fn_ConstructOperator(@nMktActivityActualCostOperator,@Numeric,@nMktActivityActualCostFrom, @nMktActivityActualCostTo,@pbCalledFromCentura)
			End
			Else
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	ISNULL(ISNULL(M.ACTUALCOST,M.ACTUALCOSTLOCAL),0)"+dbo.fn_ConstructOperator(@nMktActivityActualCostOperator,@Numeric,@nMktActivityActualCostFrom, @nMktActivityActualCostTo,@pbCalledFromCentura)
			End
		End

		If (@sMktActivityActualCostCurrency is not null or @nMktActivityActualCostCurOperator between 5 and 6)
		Begin

			If  (@sOpportunityPotValCurCode != @sHomeCurrency or @sOpportunityPotValCurCode is NULL)
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	M.ACTUALCOSTCURRENCY"+dbo.fn_ConstructOperator(@nMktActivityActualCostCurOperator,@String,@sMktActivityActualCostCurrency, null,@pbCalledFromCentura)
			End
			Else
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	(M.ACTUALCOSTCURRENCY is null or M.ACTUALCOSTCURRENCY"+dbo.fn_ConstructOperator(@nMktActivityActualCostCurOperator,@String,@sMktActivityActualCostCurrency, null,@pbCalledFromCentura) + ")"
			End

		End

		If (@nMktActivityStartDateOperator is not null
		or @dtMktActivityStartDateFrom is not NULL
		or @dtMktActivityStartDateTo   is not NULL)
		Begin
			If  @nMktActivityStartDateOperator=6
			Begin
				-- Find Cases where the Event does not exist
				Set @sFrom = @sFrom+char(10)+"	left join CASEEVENT XMCESt on (XMCESt.CASEID	= M.CASEID"
						   +char(10)+"	                        and XMCESt.EVENTNO = -12210 )"
				Set @sWhere= @sWhere+char(10)+"	and XMCESt.CASEID is NULL"
			End
			Else
			Begin
				-- always by event date
				If (@dtMktActivityStartDateFrom is not NULL
			        or @dtMktActivityStartDateTo   is not NULL)
				Begin
					Set @sFrom = @sFrom+char(10)+"	     join CASEEVENT XMCESt	on (XMCESt.CASEID     = M.CASEID)"
					Set @sWhere = @sWhere+char(10)+	"	and	XMCESt.EVENTNO = -12210"+CHAR(10)+
									"	and	XMCESt.OCCURREDFLAG between 1 and 8"+CHAR(10)+
									"	and	XMCESt.EVENTDATE"+dbo.fn_ConstructOperator(@nMktActivityStartDateOperator,@Date,convert(nvarchar,@dtMktActivityStartDateFrom,112), convert(nvarchar,@dtMktActivityStartDateTo,112),@pbCalledFromCentura)
				End
			End
		End

		If (@nMktActivityActualDateOperator is not null
		or @dtMktActivityActualDateFrom is not NULL
		or @dtMktActivityActualDateTo   is not NULL)
		Begin
			If  @nMktActivityActualDateOperator=6
			Begin
				-- Find Cases where the Event does not exist
				Set @sFrom = @sFrom+char(10)+"	left join CASEEVENT XMCEAc on (XMCEAc.CASEID	= M.CASEID"
						   +char(10)+"	                        and XMCEAc.EVENTNO = -12211 )"
				Set @sWhere= @sWhere+char(10)+"	and XMCEAc.CASEID is NULL"
			End
			Else
			Begin
				-- always by event date
				If (@dtMktActivityActualDateFrom is not NULL
			        or @dtMktActivityActualDateTo   is not NULL)
				Begin
					Set @sFrom = @sFrom+char(10)+"	     join CASEEVENT XMCEAc	on (XMCEAc.CASEID     = M.CASEID)"
					Set @sWhere = @sWhere+char(10)+	"	and	XMCEAc.EVENTNO = -12211"+CHAR(10)+
									"	and	XMCEAc.OCCURREDFLAG between 1 and 8"+CHAR(10)+
									"	and	XMCEAc.EVENTDATE"+dbo.fn_ConstructOperator(@nMktActivityActualDateOperator,@Date,convert(nvarchar,@dtMktActivityActualDateFrom,112), convert(nvarchar,@dtMktActivityActualDateTo,112),@pbCalledFromCentura)
				End
			End
		End

		If (@nMktActivityStatus is not null or @nMktActivityStatusOperator between 2 and 6)
		Begin
			Set @sFrom=@sFrom+char(10)+"	left join (select CASEID,"
					+char(10)+"	MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(CRMCASESTATUS as nvarchar(10)) ) as [DATE]"
					+char(10)+"	from CRMCASESTATUSHISTORY"
					+char(10)+"	group by CASEID	) XMLASTMODIFIED on (XMLASTMODIFIED.CASEID = M.CASEID)"
					+char(10)+"	Left Join CRMCASESTATUSHISTORY XMCSH on (XMCSH.CASEID = M.CASEID "
					+char(10)+"	and ( (convert(nvarchar(24),XMCSH.LOGDATETIMESTAMP, 21)+cast(XMCSH.CRMCASESTATUS as nvarchar(10))) = XMLASTMODIFIED.[DATE]"
					+char(10)+"	or XMLASTMODIFIED.[DATE] is null ))"

			set @sWhere=@sWhere+char(10)+"	and XMCSH.CRMCASESTATUS"+dbo.fn_ConstructOperator(@nMktActivityStatusOperator,@Numeric,@nMktActivityStatus, null,0)
		End

		If (@nMktActivityExpectedResponsesOperator is not null
		or @nMktActivityExpectedResponsesFrom is not NULL
		or @nMktActivityExpectedResponsesTo   is not NULL)
		Begin
			set @sWhere=@sWhere+char(10)+"	and M.EXPECTEDRESPONSES"+dbo.fn_ConstructOperator(@nMktActivityExpectedResponsesOperator,@Numeric,@nMktActivityExpectedResponsesFrom,@nMktActivityExpectedResponsesTo,0)
		End

		If (@nMktActivityStaffAttendedOperator is not null
		or @nMktActivityStaffAttendedFrom is not NULL
		or @nMktActivityStaffAttendedTo   is not NULL)
		Begin
			set @sWhere=@sWhere+char(10)+"	and M.STAFFATTENDED"+dbo.fn_ConstructOperator(@nMktActivityStaffAttendedOperator,@Numeric,@nMktActivityStaffAttendedFrom,@nMktActivityStaffAttendedTo,0)
		End

		If (@nMktActivityContactsAttendedOperator is not null
		or @nMktActivityContactsAttendedFrom is not NULL
		or @nMktActivityContactsAttendedTo   is not NULL)
		Begin
			set @sWhere=@sWhere+char(10)+"	and M.CONTACTSATTENDED"+dbo.fn_ConstructOperator(@nMktActivityContactsAttendedOperator,@Numeric,@nMktActivityContactsAttendedFrom,@nMktActivityContactsAttendedTo,0)
		End

		If (@nMktActivityActualResponsesOperator is not null
		or @nMktActivityActualResponsesFrom is not NULL
		or @nMktActivityActualResponsesTo   is not NULL)
		Begin
			Set @sFrom=@sFrom+char(10)+"	left join (select ARCN.CASEID, count(ARCN.NAMENO) NAMECOUNT"+char(10)+
						"		from CASENAME ARCN"+char(10)+
						"		where ARCN.NAMETYPE = '~CN'"+char(10)+
						"		and ARCN.CORRESPRECEIVED is not null"+char(10)+
						"		group by ARCN.CASEID) as ARCN on (ARCN.CASEID = M.CASEID)"
			set @sWhere=@sWhere+char(10)+"	and ARCN.NAMECOUNT"+dbo.fn_ConstructOperator(@nMktActivityActualResponsesOperator,@Numeric,@nMktActivityActualResponsesFrom,@nMktActivityActualResponsesTo,0)
		End

		If (@nMktActivityAcceptedResponsesOperator is not null
		or @nMktActivityAcceptedResponsesFrom is not NULL
		or @nMktActivityAcceptedResponsesTo   is not NULL)
		Begin
			Set @sFrom=@sFrom+char(10)+"	left join (select CN.CASEID, count(CN.NAMENO) NAMECOUNT"+char(10)+
						"		from CASENAME CN"+char(10)+
						"		join TABLECODES TC ON (TC.TABLECODE = CN.CORRESPRECEIVED)"+char(10)+
						"		where TC.TABLECODE = (SELECT COLINTEGER FROM SITECONTROL WHERE CONTROLID = 'CRM Activity Accept Response')"+char(10)+
						"		group by CN.CASEID) as ARYES on (ARYES.CASEID = M.CASEID)"

			set @sWhere=@sWhere+char(10)+"	and ARYES.NAMECOUNT"+dbo.fn_ConstructOperator(@nMktActivityAcceptedResponsesOperator,@Numeric,@nMktActivityAcceptedResponsesFrom,@nMktActivityAcceptedResponsesTo,0)
		End

		-- SQA9279 Provide filtering on the Case List.
		If @nCaseListKey is not NULL
		or @bIsPrimeCasesOnly = 1
		or @nCaseListKeyOperator in (0,1,5,6)
		Begin
			-- If Operator is set to NOT EQUAL or IS NULL then use LEFT JOIN
			If @nCaseListKeyOperator in (1,6)
			Begin
				set @sFrom = @sFrom+char(10)+"	Left Join (select distinct CASEID from CASELISTMEMBER with (NOLOCK)"
						   +char(10)+"	      where 2=2"
			End
			Else
			Begin
				Set @sFrom = @sFrom+char(10)+"	Join (select distinct CASEID from CASELISTMEMBER with (NOLOCK)"
						   +char(10)+"	      where 2=2"
			End

			If @nCaseListKey is not null
				Set @sFrom = @sFrom+char(10)+"	      and CASELISTNO="+convert(varchar,@nCaseListKey)

			If @bIsPrimeCasesOnly=1
				Set @sFrom = @sFrom+char(10)+"	      and PRIMECASE=1"

			Set @sFrom = @sFrom+") XCLM on (XCLM.CASEID=XC.CASEID)"

			If @nCaseListKeyOperator in (1,6)
				Set @sWhere=@sWhere+char(10)+"and XCLM.CASEID is NULL"
		End

		-- RFC337 ClientKeys must be associated with a Case with one of the NameTypes defined in the
		-- Site Control for "Client Name Types"

	        If @sClientKeys is not null
		or @nClientKeysOperator between 2 and 6
		Begin
			select @sList=dbo.fn_WrapQuotes(COLCHARACTER,1,@pbCalledFromCentura)
			from SITECONTROL WITH (NOLOCK)
			where CONTROLID='Client Name Types'

			If @sList is null
				set @sList="''"

			-- If Operator is set to IS NULL or NOT EQUAL then use LEFT JOIN
			If @nClientKeysOperator  in (1,6)
			Begin
				set @sFrom =@sFrom+char(10)+"	Left Join (Select distinct CASEID from CASENAME with (NOLOCK)"
				                  +char(10)+"	      Where (EXPIRYDATE is NULL or EXPIRYDATE>getdate())"
				                  +char(10)+"	      and NAMETYPE in ("+@sList+")"

			End

			Else Begin
				set @sFrom =@sFrom+char(10)+"	Join (Select distinct CASEID from CASENAME with (NOLOCK)"
				                  +char(10)+"	      Where (EXPIRYDATE is NULL or EXPIRYDATE>getdate())"
				                  +char(10)+"	      and NAMETYPE in ("+@sList+")"
			End

			If  @sClientKeys is not null
			and @nClientKeysOperator not in (5,6)
			Begin
				-- If the ClientKeysOperator is 1 (not equal) then change this to 0 (equal) because
				-- the NOT EXISTS clause will handle the inequality

				If @nClientKeysOperator=1
					set @nClientKeysOperator=0

				set @sFrom = @sFrom+char(10)+"	      and NAMENO"+dbo.fn_ConstructOperator(@nClientKeysOperator,@Numeric,@sClientKeys, null,@pbCalledFromCentura)
			End

			set @sFrom = @sFrom+") XCL on (XCL.CASEID = XC.CASEID)"

			If @nClientKeysOperator  in (1,6)
				Set @sWhere = @sWhere+char(10)+"and XCL.CASEID is NULL"
		End

		-- The reference number supplied by the name acting in the client role for the case (according to Client
		-- Name Types site control).Only available for external users.
		If @pbIsExternalUser = 1
		and(@sClientReference is not NULL
		or @nClientReferenceOperator between 2 and 6)
		Begin
			Set @sWhere =@sWhere+char(10)+"	and XFC.CLIENTREFERENCENO"+dbo.fn_ConstructOperator(@nClientReferenceOperator,@String,@sClientReference, null,@pbCalledFromCentura)
		End

		--------------------------
		-- Events do not Exist
		--------------------------
		If  @nEventDateOperator=6
		Begin
			--------------------------
			-- Due Date does not exist
			--------------------------
			If @bByDueDate=1
			and isnull(@bByEventDate,0)=0
			Begin
				Set @sFrom = @sFrom+char(10)+"	left join dbo.fn_GetCaseDueDates() XCNE on (XCNE.CASEID	= XC.CASEID"

					If @sEventKeys is not null
						Set @sFrom=@sFrom+char(10)+"	                        and XCNE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)

				------------------------------------------------
				-- For internal users check to see if the events
				-- are to be restricted by importance level.
				------------------------------------------------
				If   isnull(@pbIsExternalUser,0)=0
				and  @nImportanceLevelOperator is not null
				and (@sImportanceLevelFrom     is not null
				 or  @sImportanceLevelTo       is not null)
				Begin
					Set @sFrom=@sFrom+char(10)+"	                        and XCNE.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
				End

				Set @sFrom=@sFrom+char(10)+")"

				If @pbIsExternalUser=1
				Begin
					Set @sFrom = @sFrom+char(10)+"	left join #TEMPEVENTS XUE on (XUE.EVENTNO=XCNE.EVENTNO)"
					Set @sWhere= @sWhere+char(10)+"	and XUE.EVENTNO is NULL"
				End
				Else Begin
					Set @sWhere= @sWhere+char(10)+"	and XCNE.CASEID is NULL"
				End
			End
			----------------------------
			-- Event Date does not exist
			----------------------------
			Else If @bByEventDate=1
			and isnull(@bByDueDate,0)=0
			Begin
				Set @sFrom = @sFrom+char(10)+"	left join dbo.fn_GetCaseOccurredDates(default) XCNE on (XCNE.CASEID	= XC.CASEID"

					If @sEventKeys is not null
						Set @sFrom=@sFrom+char(10)+"	                        and XCNE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)

				------------------------------------------------
				-- For internal users check to see if the events
				-- are to be restricted by importance level.
				------------------------------------------------
				If   isnull(@pbIsExternalUser,0)=0
				and  @nImportanceLevelOperator is not null
				and (@sImportanceLevelFrom     is not null
				 or  @sImportanceLevelTo       is not null)
				Begin
					Set @sFrom=@sFrom+char(10)+"	                        and XCNE.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
				End

				Set @sFrom=@sFrom+char(10)+")"

				If @pbIsExternalUser=1
				Begin
					Set @sFrom = @sFrom+char(10)+"	left join #TEMPEVENTS XUE on (XUE.EVENTNO=XCNE.EVENTNO)"
					Set @sWhere= @sWhere+char(10)+"	and XUE.EVENTNO is NULL"
				End
				Else Begin
					Set @sWhere= @sWhere+char(10)+"	and XCNE.CASEID is NULL"
				End
			End
			----------------------------
			-- Event Date and Due Date
			-- does not exist
			----------------------------
			Else If (isnull(@bByEventDate,0)=0 and isnull(@bByDueDate,0)=0)
			     OR (       @bByEventDate   =1 and        @bByDueDate   =1)
			Begin
				Set @sFrom = @sFrom+char(10)+"	left join CASEEVENT XCNE on (XCNE.CASEID= XC.CASEID"
					           +char(10)+"	                         and XCNE.OCCURREDFLAG<9"

					If @sEventKeys is not null
						Set @sFrom=@sFrom+char(10)+"	                         and XCNE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)

				------------------------------------------------
				-- For internal users check to see if the events
				-- are to be restricted by importance level.
				------------------------------------------------
				If   isnull(@pbIsExternalUser,0)=0
				and  @nImportanceLevelOperator is not null
				and (@sImportanceLevelFrom     is not null
				 or  @sImportanceLevelTo       is not null)
				Begin
					Set @sFrom=@sFrom+char(10)+"	                         and XCNE.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
				End

				Set @sFrom=@sFrom+char(10)+")"

				If @pbIsExternalUser=1
				Begin
					Set @sFrom = @sFrom+char(10)+"	left join #TEMPEVENTS XUE on (XUE.EVENTNO=XCNE.EVENTNO)"
					Set @sWhere= @sWhere+char(10)+"	and XUE.EVENTNO is NULL"
				End
				Else Begin
					Set @sWhere= @sWhere+char(10)+"	and XCNE.CASEID is NULL"
				End
			End
		End

			If @sEventKeys is not null
		and @nEventKeyForCompare is not null
		and @nEventDateOperator in (0,1,10,11,12,13)
		Begin
			-------------------------------------------
			-- RFC9326 & SQA17652
			-- Two events may be compared to each other
			-- Handle NULLs for Not Equal
			-------------------------------------------
			If @nEventDateOperator=1
			Begin
				Set @sFrom = @sFrom+char(10)+"	left join (select OA.CASEID, OA.ACTION, OA.CRITERIANO, EC.NUMCYCLESALLOWED,EC.EVENTNO,min(OA.CYCLE) as CYCLE"
						   +char(10)+"		from OPENACTION OA WITH (NOLOCK)"
						   +char(10)+"		join EVENTCONTROL EC WITH (NOLOCK) on (EC.CRITERIANO=OA.CRITERIANO"
							   +char(10)+"		                                   and EC.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)+")"
						   +char(10)+"		join EVENTS E WITH (NOLOCK)        on (E.EVENTNO=EC.EVENTNO)"
						   +char(10)+"		where OA.POLICEEVENTS=1"
							   +char(10)+"		and   OA.ACTION=CASE WHEN(EC.EVENTNO=-11) THEN '"+coalesce(@sRenewalAction,'RN')+"' ELSE isnull(E.CONTROLLINGACTION,OA.ACTION) END"
						   +char(10)+"		group by OA.CASEID, OA.ACTION, OA.CRITERIANO, EC.NUMCYCLESALLOWED,EC.EVENTNO) XOA"
						   +char(10)+"					  on (XOA.CASEID=XC.CASEID)"
						   +char(10)+"	left join ACTIONS XA WITH(NOLOCK)	  on (XA.ACTION=XOA.ACTION)"
							   +char(10)+"	left join EVENTS XE WITH(NOLOCK)	  on (XE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)+")"
						   +char(10)+"	left join CASEEVENT XCE WITH (NOLOCK)  on (XCE.CASEID=XC.CASEID"
							   +char(10)+"	                                  and XCE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)
						   +char(10)+"	                                  and XCE.CYCLE  =CASE WHEN(isnull(XOA.NUMCYCLESALLOWED,XE.NUMCYCLESALLOWED)=1)"
						   +char(10)+"	                                  			THEN 1"
						   +char(10)+"	                                  		     WHEN(isnull(XA.NUMCYCLESALLOWED,1)=1)"
						   +char(10)+"	                                  			THEN (	select min(XCE1.CYCLE)"
						   +char(10)+"	                                  				from CASEEVENT XCE1"
						   +char(10)+"	                                  				where XCE1.CASEID=XCE.CASEID"
						   +char(10)+"	                                  				and XCE1.EVENTNO=XCE.EVENTNO"
						   +char(10)+"	                                  				and XCE1.OCCURREDFLAG=0)"
						   +char(10)+"	                                  			ELSE XOA.CYCLE"
						   +char(10)+"	                                  		END)"
								-------------------------------------------------
								-- Use a JOIN here because the assumption is that
								-- the Event being compared to MUST exist
								-------------------------------------------------
						   +char(10)+" join CASEEVENT XCE1 WITH (NOLOCK) on (XCE1.CASEID=XC.CASEID"
						   +char(10)+"	                                  and XCE1.CYCLE=1"
						   +char(10)+"	                                  and XCE1.EVENTNO="+convert(varchar,@nEventKeyForCompare)+")"

				-- Both DueDate and EventDate are being considered
				If  @bByDueDate  =1
				and @bByEventDate=1
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	coalesce(XCE.OCCURREDFLAG,0) between 0 and 8"
							     +char(10)+"	and	(XCE.EVENTNO=XOA.EVENTNO or XCE.EVENTDATE is not null or XCE.EVENTNO is null)" --RFC12158 Allow for missing CASEEVENT row
							     +char(10)+"	and	coalesce(XCE.EVENTDATE,XCE.EVENTDUEDATE,'01-01-1753')"+dbo.fn_ConstructOperator(@nEventDateOperator,@ColumnName,'coalesce(XCE1.EVENTDATE,XCE1.EVENTDUEDATE,''01-01-1753'')', default,@pbCalledFromCentura)
				End
				-- Only DueDate is being considered
				Else If @bByDueDate=1
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	coalesce(XCE.OCCURREDFLAG,0)=0"
							     +char(10)+"	and	         XCE1.OCCURREDFLAG   between 0 and 8"
							     +char(10)+"	and	(XCE.EVENTNO=XOA.EVENTNO or XCE.EVENTNO is null)"	 --RFC12158 Allow for missing CASEEVENT row
							     +char(10)+"	and	coalesce(XCE.EVENTDUEDATE,'01-01-1753')"+dbo.fn_ConstructOperator(@nEventDateOperator,@ColumnName,'coalesce(XCE1.EVENTDATE,XCE1.EVENTDUEDATE,''01-01-1753'')', default,@pbCalledFromCentura)
				End
				-- Only EventDate is being considered
				Else If @bByEventDate=1
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	coalesce(XCE.OCCURREDFLAG,1)  between 1 and 8"
							     +char(10)+"	and	         XCE1.OCCURREDFLAG   between 0 and 8"
							     +char(10)+"	and	coalesce(XCE.EVENTDATE,'01-01-1753')"+dbo.fn_ConstructOperator(@nEventDateOperator,@ColumnName,'coalesce(XCE1.EVENTDATE,XCE1.EVENTDUEDATE,''01-01-1753'')', default,@pbCalledFromCentura)
				End
			End
			Else Begin
				Set @sFrom = @sFrom+char(10)+"	left join (select OA.CASEID, OA.ACTION, OA.CRITERIANO,EC.NUMCYCLESALLOWED,EC.EVENTNO, min(OA.CYCLE) as CYCLE"
						   +char(10)+"		from OPENACTION OA WITH (NOLOCK)"
						   +char(10)+"		join EVENTCONTROL EC WITH (NOLOCK) on (EC.CRITERIANO=OA.CRITERIANO"
							   +char(10)+"		                                   and EC.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)+")"
						   +char(10)+"		join EVENTS E WITH (NOLOCK)        on (E.EVENTNO=EC.EVENTNO)"
						   +char(10)+"		where OA.POLICEEVENTS=1"
							   +char(10)+"		and   OA.ACTION=CASE WHEN(EC.EVENTNO=-11) THEN '"+coalesce(@sRenewalAction,'RN')+"' ELSE isnull(E.CONTROLLINGACTION,OA.ACTION) END"
						   +char(10)+"		group by OA.CASEID, OA.ACTION, OA.CRITERIANO,EC.NUMCYCLESALLOWED,EC.EVENTNO) XOA"
						   +char(10)+"					  on (XOA.CASEID=XC.CASEID)"
						   +char(10)+"	left join ACTIONS XA WITH(NOLOCK) on (XA.ACTION=XOA.ACTION)"
							   +char(10)+"	join EVENTS XE WITH(NOLOCK)	  on (XE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)+")"
						   +char(10)+"	join CASEEVENT XCE WITH (NOLOCK)  on (XCE.CASEID=XC.CASEID"
							   +char(10)+"	                                  and XCE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)
						   +char(10)+"	                                  and XCE.CYCLE  =CASE WHEN(isnull(XOA.NUMCYCLESALLOWED,XE.NUMCYCLESALLOWED)=1)"
						   +char(10)+"	                                  			THEN 1"
						   +char(10)+"	                                  		     WHEN(isnull(XA.NUMCYCLESALLOWED,1)=1)"
						   +char(10)+"	                                  			THEN (	select min(XCE1.CYCLE)"
						   +char(10)+"	                                  				from CASEEVENT XCE1"
						   +char(10)+"	                                  				where XCE1.CASEID=XCE.CASEID"
						   +char(10)+"	                                  				and XCE1.EVENTNO=XCE.EVENTNO"
						   +char(10)+"	                                  				and XCE1.OCCURREDFLAG=0)"
						   +char(10)+"	                                  			ELSE XOA.CYCLE"
						   +char(10)+"	                                  		END)"
						   +char(10)+"	join CASEEVENT XCE1 WITH (NOLOCK) on (XCE1.CASEID=XC.CASEID"
						   +char(10)+"	                                  and XCE1.CYCLE=1"
						   +char(10)+"	                                  and XCE1.EVENTNO="+convert(varchar,@nEventKeyForCompare)+")"

				--If @sEventKey='-11'
				--	Set @sWhere = @sWhere+char(10)+"	and	XOA.ACTION='"+coalesce(@sRenewalAction,'RN')+"'"
				--Else
				--	Set @sWhere = @sWhere+char(10)+"	and	XOA.ACTION=coalesce(XE.CONTROLLINGACTION,XOA.ACTION)"

			-- Both DueDate and EventDate are being considered
			If  @bByDueDate  =1
			and @bByEventDate=1
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG  between 0 and 8"
						     +char(10)+"	and	XCE1.OCCURREDFLAG between 0 and 8"
								     +char(10)+"	and	(XCE.EVENTNO=XOA.EVENTNO or XCE.EVENTDATE is not null or XCE.EVENTNO is null)"  --RFC12158 Allow for missing CASEEVENT row
						     +char(10)+"	and	isnull(XCE.EVENTDATE,XCE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(@nEventDateOperator,@ColumnName,'isnull(XCE1.EVENTDATE,XCE1.EVENTDUEDATE)', default,@pbCalledFromCentura)
			End
			-- Only DueDate is being considered
			Else If @bByDueDate=1
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG=0"
						     +char(10)+"	and	XCE1.OCCURREDFLAG between 0 and 8"
								     +char(10)+"	and	(XCE.EVENTNO=XOA.EVENTNO or XCE.EVENTNO is null)"  --RFC12158 Allow for missing CASEEVENT row
						     +char(10)+"	and	XCE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateOperator,@ColumnName,'isnull(XCE1.EVENTDATE,XCE1.EVENTDUEDATE)', default,@pbCalledFromCentura)
			End
				-- Only EventDate is being considered
			Else If @bByEventDate=1
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG  between 1 and 8"
						     +char(10)+"	and	XCE1.OCCURREDFLAG between 0 and 8"
						     +char(10)+"	and	XCE.EVENTDATE"+dbo.fn_ConstructOperator(@nEventDateOperator,@ColumnName,'isnull(XCE1.EVENTDATE,XCE1.EVENTDUEDATE)', default,@pbCalledFromCentura)
			End
		End
		End
		Else If @nEventDateOperator<>6
		Begin
			-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
			-- and To date before proceeding.  The dates are calculated by adding the period and type to the
			-- current date.  If Quantity is positive, the current date is the From date and the derived date
			-- the To date.  If Quantity is negative, the current date is the To date and the derived date
			-- the From date.

			If @sPeriodType is not null
			and @nPeriodQuantity is not null
			Begin
				If @nPeriodQuantity > 0
				Begin
					Set @dtDateRangeFrom 	= getdate()

					Set @sSQLString = "Set @dtDateRangeTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFrom) + "')"

					execute sp_executesql @sSQLString,
							N'@dtDateRangeTo	datetime 		output,
			 				  @sPeriodType		nvarchar(1),
							  @nPeriodQuantity	smallint,
						          @dtDateRangeFrom	datetime',
			  				  @dtDateRangeTo	= @dtDateRangeTo 	output,
							  @sPeriodType		= @sPeriodType,
							  @nPeriodQuantity	= @nPeriodQuantity,
							  @dtDateRangeFrom	= @dtDateRangeFrom
				End
				Else
				Begin
					Set @dtDateRangeTo	= getdate()

					Set @sSQLString = "Set @dtDateRangeFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeTo) + "')"

					execute sp_executesql @sSQLString,
							N'@dtDateRangeFrom	datetime 		output,
			 				  @sPeriodType		nvarchar(1),
							  @nPeriodQuantity	smallint,
						          @dtDateRangeTo	datetime',
			  				  @dtDateRangeFrom	= @dtDateRangeFrom 	output,
							  @sPeriodType		= @sPeriodType,
							  @nPeriodQuantity	= @nPeriodQuantity,
							  @dtDateRangeTo	= @dtDateRangeTo
				End
			End

			If (@bByDueDate=0 OR @bByDueDate is null)
			Begin
				If  (@bByEventDate is NULL or @bByEventDate=0)
					Set @bByEventDate=1

				Set @sFrom = @sFrom+char(10)+"	     join CASEEVENT XCE WITH (NOLOCK) on (XCE.CASEID     = XC.CASEID)"

				If @pbIsExternalUser=1
				Begin
					Set @sFrom = @sFrom+char(10)+"	     join #TEMPEVENTS XUE on (XUE.EVENTNO=XCE.EVENTNO)"
				End

					If @sEventKeys is not NULL
				Begin
						Set @sWhere = @sWhere+char(10)+"	and	XCE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)
				End

				Set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG between 1 and 8"

				If @dtDateRangeFrom is not null
				or @dtDateRangeTo   is not null
				Begin
					Set @sWhere =  @sWhere+char(10)+"	and	XCE.EVENTDATE"+dbo.fn_ConstructOperator(@nEventDateOperator,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
				End

				-- Restrict Events that were created either by a Renewals type Action or not.
				-- Note that if both options have been selected then no restriction is required.
				If (@bIsRenewalsOnly   =1 and isnull(@bIsNonRenewalsOnly,0)=0)
				or (@bIsNonRenewalsOnly=1 and isnull(@bIsRenewalsOnly,0)   =0)
				Begin
					Set @sFrom = @sFrom+char(10)+"	     join ACTIONS XA WITH (NOLOCK) on (XA.ACTION=XCE.CREATEDBYACTION)"

					If @bIsRenewalsOnly=1
						Set @sWhere=@sWhere+char(10)+"	and	XA.ACTIONTYPEFLAG=1"
					Else
						Set @sWhere=@sWhere+char(10)+"	and	isnull(XA.ACTIONTYPEFLAG,0)<>1"
				End

				-- For internal users check to see if the events are to be
				-- restricted by importance level.
				If   isnull(@pbIsExternalUser,0)=0
				and  @nImportanceLevelOperator is not null
				and (@sImportanceLevelFrom     is not null
				 or  @sImportanceLevelTo       is not null)
				Begin
					-- Will require the EventControl or Events row for the CaseEvent in order
					-- to get the importance level.
					Set @sFrom=@sFrom
						   +char(10)+"	left join EVENTCONTROL XEC WITH (NOLOCK) on (XEC.CRITERIANO=XCE.CREATEDBYCRITERIA"
						   +char(10)+"                             and XEC.EVENTNO   =XCE.EVENTNO)"
						   +char(10)+"       join EVENTS XE WITH (NOLOCK) on (XE.EVENTNO    =XCE.EVENTNO)"

					Set @sWhere =  @sWhere+char(10)+"	and	coalesce(XEC.IMPORTANCELEVEL,XE.IMPORTANCELEVEL,0)"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
				End
			End
			Else If  @bByDueDate=1
			Begin
				If exists(select 1 from SITECONTROL with (NOLOCK) where CONTROLID='Renewal Search on Any Action' and COLBOOLEAN=1)
				Begin
					Set @bAnyRenewalAction=1
				End
				Else Begin
					-- Extract the Action used to identify the Renewal process so that the
					-- Next Renewal Date will only be considered due if it is attached to the
					-- specific Action

					Set @bAnyRenewalAction=0

					Set @sSQLString="
					Select @sRenewalAction=S.COLCHARACTER
					from SITECONTROL S
						where S.CONTROLID='Main Renewal Action'"

					exec @nErrorCode=sp_executesql @sSQLString,
								N'@sRenewalAction	nvarchar(2)	OUTPUT',
								  @sRenewalAction=@sRenewalAction	OUTPUT
				End

				If exists(select 1 from SITECONTROL with (NOLOCK) where CONTROLID='Any Open Action for Due Date' and COLBOOLEAN=1)
				and @nErrorCode=0
				Begin
					Set @bAnyOpenAction=1
				End

				-- If the Case search is restricted to Event Due Dates then the events to be considered
				-- must be attached to an open action.
/************************
RFC2982
Performance improvement to remove EVENTCONTROL
and rely on the CREATEDBYACTION
				Set @sFrom = @sFrom+char(10)+"	     join OPENACTION XOA on (XOA.CASEID     = XC.CASEID"
						   +char(10)+"				 and XOA.POLICEEVENTS="+CASE WHEN(@bByDueDate=1 and isnull(@bIncludeClosedActions,0) = 0) THEN "1)" ELSE "XOA.POLICEEVENTS)" END
						   +char(10)+"	     join ACTIONS XA	   on (XA.ACTION     = XOA.ACTION)"
						   +char(10)+"	     join EVENTCONTROL XEC on (XEC.CRITERIANO= XOA.CRITERIANO)"
						   +char(10)+"	     join CASEEVENT XCE	on (XCE.CASEID     = XC.CASEID"
						   +char(10)+"				and XCE.EVENTNO    = XEC.EVENTNO"
						   +char(10)+"				and XCE.CYCLE      = CASE WHEN(XA.NUMCYCLESALLOWED>1) THEN XOA.CYCLE ELSE XCE.CYCLE END)"
*************************/
				Set @sFrom = @sFrom+char(10)+"	     join CASEEVENT XCE WITH (NOLOCK) on (XCE.CASEID     = XC.CASEID)"
						   +char(10)+"	     join OPENACTION XOA WITH (NOLOCK) on (XOA.CASEID    = XC.CASEID"
						   +char(10)+"				 and(XOA.POLICEEVENTS="+CASE WHEN(@bByDueDate=1 and isnull(@bIncludeClosedActions,0) = 0) THEN "1" ELSE "XOA.POLICEEVENTS" END+CASE WHEN(@bByEventDate=1) THEN " OR XCE.OCCURREDFLAG>0" END +"))"	--RFC10924
						   +char(10)+"	     join EVENTCONTROL XEC WITH (NOLOCK) on (XEC.CRITERIANO = XOA.CRITERIANO"
						   +char(10)+"						 and XEC.EVENTNO    = XCE.EVENTNO)"
						   +char(10)+"	     join EVENTS  XE WITH(NOLOCK) on (XE.EVENTNO=XEC.EVENTNO)"	--RFC10924
						   +char(10)+"	     join ACTIONS XA WITH (NOLOCK) on (XA.ACTION     = XOA.ACTION)"

				-- For internal users check to see if the events are to be
				-- restricted by importance level.
				If   isnull(@pbIsExternalUser,0)=0
				and  @nImportanceLevelOperator is not null
				and (@sImportanceLevelFrom     is not null
				 or  @sImportanceLevelTo       is not null)
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	ISNULL(XEC.IMPORTANCELEVEL,0)"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
				End

				-- RFC2982 Event cycle must be appropriate for the Aciton
				-- Next Renewal Date must use the Main Renewal Action
				Set @sWhere = @sWhere+char(10)+"	and	XCE.CYCLE=CASE WHEN(XA.NUMCYCLESALLOWED>1) THEN XOA.CYCLE ELSE XCE.CYCLE END"

					If @sEventKeys is not NULL
				Begin
						-- Next Renewal Date must use the Main Renewal Action unless "Renewal Search on Any Action" site control is on.
						Set @sWhere = @sWhere+char(10)+"	and	XCE.EVENTNO"+dbo.fn_ConstructOperator(0,'N',@sEventKeys, null,@pbCalledFromCentura)
					End
							-- No restriction on Action is required if @bAnyOpenAction=1

					-- No restriction on Action is required if @bAnyOpenAction=1
					If @bAnyOpenAction=0
					Begin
						-- Next Renewal Date must use the Main Renewal Action unless "Renewal Search on Any Action" site control is on.
						If @bAnyRenewalAction=0
							Set @sWhere = @sWhere+char(10)+"	and	XOA.ACTION=CASE WHEN(XCE.EVENTNO=-11) THEN '"+isnull(@sRenewalAction,'RN')+"' ELSE coalesce(XE.CONTROLLINGACTION,XOA.ACTION) END"
						Else
							Set @sWhere = @sWhere+char(10)+"	and	XOA.ACTION=CASE WHEN(XCE.EVENTNO=-11) THEN XOA.ACTION ELSE coalesce(XE.CONTROLLINGACTION,XOA.ACTION) END"
				End

				-- Both DueDate and EventDate are being considered
				If  @bByDueDate  =1
				and @bByEventDate=1
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG between 0 and 8"

					If @dtDateRangeFrom is not null
					or @dtDateRangeTo   is not null
					Begin
						Set @sWhere =  @sWhere+char(10)+"	and	isnull(XCE.EVENTDATE,XCE.EVENTDUEDATE)"+dbo.fn_ConstructOperator(@nEventDateOperator,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
					End
				End
				-- Only DueDate is being considered
				Else
				Begin
					Set @sWhere = @sWhere+char(10)+"	and	XCE.OCCURREDFLAG=0"

					If @dtDateRangeFrom is not null
					or @dtDateRangeTo   is not null
					Begin
						Set @sWhere =  @sWhere+char(10)+"	and	XCE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateOperator,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
					End
/************************
RFC2982
Removed as a result of performance improvement
See above JOIN for new code
					-- The Next Renewal Date will only be considered due if it is attached
					-- to the specific Action
					If @sRenewalAction is not null
					Begin
						Set @sWhere = @sWhere+char(10)+
							"	and	((XOA.ACTION='"+@sRenewalAction+"' and XCE.EVENTNO=-11) OR XCE.EVENTNO<>-11)"
					End
**********************/
				End

				If @pbIsExternalUser=1
				Begin
					Set @sFrom=@sFrom+char(10)+"	join #TEMPEVENTS XUE on (XUE.EVENTNO=XCE.EVENTNO)"
				End

				-- Restrict Events that were created either by a Renewals type Action or not.
				-- Note that if both options have been selected then no restriction is required.
				If (@bIsRenewalsOnly=1 and isnull(@bIsNonRenewalsOnly,0)=0)
					Set @sWhere=@sWhere+char(10)+"	and	XA.ACTIONTYPEFLAG=1"
				Else
				If (@bIsNonRenewalsOnly=1 and isnull(@bIsRenewalsOnly,0)   =0)
					Set @sWhere=@sWhere+char(10)+"	and	isnull(XA.ACTIONTYPEFLAG,0)<>1"

				End
		End

			--------------------------
			-- RFC43207
			-- Filtering on Event Text
			--------------------------
			If @nEventNoteTypeKeysOperator is not null
			or @nEventNoteTextOperator     is not null
			Begin

				Set @sFrom=@sFrom
					   +char(10)+"	left join CASEEVENTTEXT XCET WITH (NOLOCK) on (XCET.CASEID =XC.CASEID"

				-- If filtering by CASEEVENT then the text must
				-- be associated with the CASEEVENT
				If PATINDEX ('%join CASEEVENT XCE%', @sFrom)>0
					Set @sFrom=@sFrom
					   +char(10)+"	                                           and XCET.EVENTNO=XCE.EVENTNO"
					   +char(10)+"	                                           and XCET.CYCLE  =XCE.CYCLE)"
				Else
					Set @sFrom=@sFrom+")"

				Set @sFrom=@sFrom
					   +char(10)+"	left join EVENTTEXT XET WITH (NOLOCK)      on (XET.EVENTTEXTID=XCET.EVENTTEXTID)"

				If @nEventNoteTypeKeysOperator is not null
					Set @sWhere =  @sWhere+char(10)+"	and	XET.EVENTTEXTTYPEID"+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)

				If @nEventNoteTextOperator is not null
					Set @sWhere =  @sWhere+char(10)+"	and	XET.EVENTTEXT"+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
			End

		-- Return any cases where the description of the RenewalStatus matches that supplied.  For external users,
		-- compare to the external description otherwise use the internal description.

		If @sRenewalStatusDescription is not NULL
		or @nRenewalStatusDescriptionOperator between 2 and 6
		Begin
			Set @sFrom=@sFrom+char(10)+"	left join PROPERTY XPD WITH (NOLOCK) on (XPD.CASEID      = XC.CASEID)"
					 +char(10)+"	left join STATUS XRSD WITH (NOLOCK) on (XRSD.STATUSCODE = XPD.RENEWALSTATUS)"

			If @pbIsExternalUser=1
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	"+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'XRSD',@sLookupCulture,@pbCalledFromCentura)+dbo.fn_ConstructOperator(@nRenewalStatusDescriptionOperator,@String,@sRenewalStatusDescription, null,@pbCalledFromCentura)
			End
			Else
			Begin
				Set @sWhere = @sWhere+char(10)+"	and	"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'XRSD',@sLookupCulture,@pbCalledFromCentura)+dbo.fn_ConstructOperator(@nRenewalStatusDescriptionOperator,@String,@sRenewalStatusDescription, null,@pbCalledFromCentura)
			End
		End

		-- When a specific status is being filtered on check to see if it is a Renewal Status and if so
		-- then also join on the RenewalStatus

		If @sStatusKey is not NULL
		or @nStatusKeyOperator between 2 and 6
		or @sRenewalStatusKeys is not NULL
		or @nRenewalStatusKeyOperator between 2 and 6
		Begin
			If @sStatusKey is not NULL
			or @nStatusKeyOperator between 2 and 6
			Begin
				If exists (select * from STATUS
                                            join  dbo.fn_Tokenise(@sStatusKey, ',') as CS on (CS.parameter=STATUSCODE)
                                            where RENEWALFLAG=1)
				Begin
					Set @sFrom=@sFrom+char(10)+"	left join PROPERTY XP WITH (NOLOCK) on (XP.CASEID      = XC.CASEID)"
							 +char(10)+"	left join STATUS XRS WITH (NOLOCK) on (XRS.STATUSCODE = XP.RENEWALSTATUS)"

					Set @sWhere = @sWhere+char(10)+"	and	XRS.STATUSCODE"+dbo.fn_ConstructOperator(@nStatusKeyOperator,@CommaString,@sStatusKey, null,@pbCalledFromCentura)

					Set @nErrorCode = @@Error
				End
				Else
				Begin
					Set @sFrom=@sFrom+char(10)+"	left join STATUS XST WITH (NOLOCK) on (XST.STATUSCODE = XC.STATUSCODE)"

					Set @sWhere = @sWhere+char(10)+"	and	XST.STATUSCODE"+dbo.fn_ConstructOperator(@nStatusKeyOperator,@CommaString,@sStatusKey, null,@pbCalledFromCentura)
				End
			End

			If @sRenewalStatusKeys is not NULL
			or @nRenewalStatusKeyOperator between 2 and 6
			Begin
				If @sFrom NOT LIKE '%PROPERTY XP%'
					Set @sFrom=@sFrom+char(10)+"	left join PROPERTY XP WITH (NOLOCK) on (XP.CASEID      = XC.CASEID)"

				If @sFrom like '%PROPERTY XPB%'
					Set @sWhere = @sWhere+char(10)+"	and	XPB.RENEWALSTATUS"+dbo.fn_ConstructOperator(@nRenewalStatusKeyOperator,@Numeric,@sRenewalStatusKeys, null,@pbCalledFromCentura)
				Else
				If @sFrom like '%PROPERTY XPD%'
					Set @sWhere = @sWhere+char(10)+"	and	XPD.RENEWALSTATUS"+dbo.fn_ConstructOperator(@nRenewalStatusKeyOperator,@Numeric,@sRenewalStatusKeys, null,@pbCalledFromCentura)
				Else
					Set @sWhere = @sWhere+char(10)+"	and	XP.RENEWALSTATUS"+dbo.fn_ConstructOperator(@nRenewalStatusKeyOperator,@Numeric,@sRenewalStatusKeys, null,@pbCalledFromCentura)
			End
		End

		If @bRenewalFlag =1
		or @bIsDead      =1
		or @bIsRegistered =1
		or @bIsPending    =1
		Begin
			If @sFrom NOT LIKE '%PROPERTY XP%'
				Set @sFrom=@sFrom+char(10)+"	left join PROPERTY XP WITH (NOLOCK) on (XP.CASEID      = XC.CASEID)"

			If @sFrom NOT LIKE '%STATUS XRS%'
			Begin
				-- SQA19125
				If @sFrom like '%PROPERTY XPB%'
					Set @sFrom=@sFrom+char(10)+"	left join STATUS XRS WITH (NOLOCK)  on (XRS.STATUSCODE = XPB.RENEWALSTATUS)"
				Else
				If @sFrom like '%PROPERTY XPD%'
					Set @sFrom=@sFrom+char(10)+"	left join STATUS XRS WITH (NOLOCK)  on (XRS.STATUSCODE = XPD.RENEWALSTATUS)"
				Else
					Set @sFrom=@sFrom+char(10)+"	left join STATUS XRS WITH (NOLOCK)  on (XRS.STATUSCODE = XP.RENEWALSTATUS)"
			End

			If @sFrom NOT LIKE '%STATUS XST%'
				Set @sFrom=@sFrom+char(10)+"	left join STATUS XST WITH (NOLOCK) on (XST.STATUSCODE = XC.STATUSCODE)"
		End

		-- If the RenewalFlag is set on then there must be a RenewalStatus
		If @bRenewalFlag=1
		Begin
			Set @sWhere = @sWhere+char(10)+"	and    	XP.RENEWALSTATUS is not null"
		End

		-- Dead cases only
		If   @bIsDead      =1
		and (@bIsRegistered=0 or @bIsRegistered is null)
		and (@bIsPending   =0 or @bIsPending    is null)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and    (XST.LIVEFLAG=0 OR XRS.LIVEFLAG=0)"
		End

		-- Registered cases only
		Else
		If  (@bIsDead      =0 or @bIsDead       is null)
		and (@bIsRegistered=1)
		and (@bIsPending   =0 or @bIsPending    is null)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and	XST.LIVEFLAG=1"
				    	     +char(10)+"	and	XST.REGISTEREDFLAG=1"
				     	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
		End

		-- Pending cases only
		Else
		If  (@bIsDead      =0 or @bIsDead       is null)
		and (@bIsRegistered=0 or @bIsRegistered is null)
		and (@bIsPending   =1)
		Begin
			-- Note the absence of a Case Status will be treated as "Pending"
			Set @sWhere = @sWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=0) OR XST.STATUSCODE is null)"
				    	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
		End

		-- Pending cases or Registed cases only (not dead)
		Else
		If  (@bIsDead      =0 or @bIsDead       is null)
		and (@bIsRegistered=1)
		and (@bIsPending   =1)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and    (XST.LIVEFLAG=1 or XST.STATUSCODE is null)"
				     	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
		End

		-- Registered cases or Dead cases
		Else
		If  (@bIsDead      =1)
		and (@bIsRegistered=1)
		and (@bIsPending   =0 or @bIsPending is null)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=1) OR XST.LIVEFLAG =0 OR XRS.LIVEFLAG=0)"
		End

		-- Pending cases or Dead cases
		Else
		If  (@bIsDead      =1)
		and (@bIsRegistered=0 or @bIsRegistered is null)
		and (@bIsPending   =1)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=0) OR XST.STATUSCODE is null OR XST.LIVEFLAG =0 OR XRS.LIVEFLAG=0)"

		End

		If @nErrorCode = 0
		begin

			If @bHasLettersOnQueue=1
			or @bHasChargesOnQueue=1
			Begin
				Set @sFrom = @sFrom+char(10)+"	Join (Select distinct CASEID from ACTIVITYREQUEST with (NOLOCK)"

				If  @bHasLettersOnQueue=1
				and @bHasChargesOnQueue=1
					Set @sFrom = @sFrom+char(10)+"	      Where ACTIVITYCODE in (3202,3204)"
				Else
				If  @bHasLettersOnQueue=1
				and isnull(@bHasChargesOnQueue,0)=0
					Set @sFrom = @sFrom+char(10)+"	      Where ACTIVITYCODE=3204 and LETTERNO is not null"
				Else
				If  isnull(@bHasLettersOnQueue,0)=0
				and @bHasChargesOnQueue=1
					Set @sFrom = @sFrom+char(10)+"	      Where ACTIVITYCODE=3202 and LETTERNO is null"

				Set @sFrom = @sFrom+") XAR1 on (XAR1.CASEID=XC.CASEID)"
			End

			If @bHasIncompletePolicing=1
			Begin
				Set @sFrom=@sFrom+char(10)+"	left join POLICING POLC WITH (NOLOCK) on (POLC.CASEID      = XC.CASEID)"

				Set @sWhere = @sWhere+char(10)+"	and	POLC.SYSGENERATEDFLAG = 1"
			End

			If @bHasIncompleteNameChange=1
			Begin
				Set @sFrom=@sFrom+char(10)+"	join CASENAMEREQUESTCASES CNREQ WITH (NOLOCK) on (CNREQ.CASEID      = XC.CASEID)"
			End

			-- SQA11820
			-- Cases that are flagged to appear on next CPA batch.
			If @bOnCPAUpdate=1
			Begin
				Set @sFrom=@sFrom+char(10)+"	join CPAUPDATE CPAU WITH (NOLOCK) on (CPAU.CASEID = XC.CASEID)"
			End

			-- SQA11820
			-- Cases that have been attached to a specific batch sent to CPA
			If @nCPASentBatchNo is not null
			Begin
				Set @sFrom=@sFrom+char(10)+"	join CPASEND CPAS WITH (NOLOCK) on (CPAS.CASEID = XC.CASEID"
						 +char(10)+"	                  and CPAS.BATCHNO="+convert(varchar,@nCPASentBatchNo)+")"
			End


			-- SQA12427 and SQA19823 Get cases associated with EDE batch
			If (@nEDEDataSourceNameNo is not null) or (@sEDEBatchIdentifier is not null)
			Begin
				Set @sTempWhere = ''
				If @nEDEDataSourceNameNo is not null
					set @sTempWhere = @sTempWhere + " and SD.SENDERNAMENO = "+convert(varchar(30),@nEDEDataSourceNameNo)
				If @sEDEBatchIdentifier is not null
					set @sTempWhere = @sTempWhere + " and SD.SENDERREQUESTIDENTIFIER = "+ dbo.fn_WrapQuotes(@sEDEBatchIdentifier,0,@pbCalledFromCentura)
				If @bDraftCaseOnly = 1
					-- draft case only
					Set @sWhere = @sWhere + " and XC.CASEID in
										(Select ISNULL(CD.CASEID, CM.DRAFTCASEID)
										from EDESENDERDETAILS SD WITH (NOLOCK)
										join EDECASEDETAILS CD WITH (NOLOCK) on (CD.BATCHNO = SD.BATCHNO)
										left join EDECASEMATCH CM WITH (NOLOCK) on (CM.BATCHNO = CD.BATCHNO
													AND CM.TRANSACTIONIDENTIFIER = CD.TRANSACTIONIDENTIFIER)
										where 1 = 1 " + @sTempWhere + ")"
				else If @bIncludeDraftCase=1
					-- Include both draft and live cases
					Set @sWhere = @sWhere + " and XC.CASEID in
										(Select ISNULL(CD.CASEID, CM.LIVECASEID)
										from EDESENDERDETAILS SD WITH (NOLOCK)
										join EDECASEDETAILS CD WITH (NOLOCK) on (CD.BATCHNO = SD.BATCHNO)
										left join EDECASEMATCH CM WITH (NOLOCK) on (CM.BATCHNO = CD.BATCHNO
													AND CM.TRANSACTIONIDENTIFIER = CD.TRANSACTIONIDENTIFIER)
										where 1 = 1 " + @sTempWhere + "

										UNION ALL

										Select ISNULL(CD.CASEID, CM.DRAFTCASEID)
										from EDESENDERDETAILS SD WITH (NOLOCK)
										join EDECASEDETAILS CD WITH (NOLOCK) on (CD.BATCHNO = SD.BATCHNO)
										left join EDECASEMATCH CM WITH (NOLOCK) on (CM.BATCHNO = CD.BATCHNO
													AND CM.TRANSACTIONIDENTIFIER = CD.TRANSACTIONIDENTIFIER)
										where 1 = 1 " + @sTempWhere + ")"
				else
					-- Include Live cases only
					Set @sWhere = @sWhere + " and XC.CASEID in
										(Select ISNULL(CD.CASEID, CM.LIVECASEID)
										from EDESENDERDETAILS SD WITH (NOLOCK)
										join EDECASEDETAILS CD WITH (NOLOCK) on (CD.BATCHNO = SD.BATCHNO)
										left join EDECASEMATCH CM WITH (NOLOCK) on (CM.BATCHNO = CD.BATCHNO
													AND CM.TRANSACTIONIDENTIFIER = CD.TRANSACTIONIDENTIFIER)
										where 1 = 1 " + @sTempWhere + ")"
			End



			-- SQA12427 Get cases associated with an audit session number
			If @nAuditSessionNumber is not null
			Begin
				Set @sWhere = @sWhere + " and XC.CASEID in
										(Select TI.CASEID
										from SESSION SES WITH (NOLOCK)
										join TRANSACTIONINFO TI WITH (NOLOCK) on (TI.SESSIONNO = SES.SESSIONNO)
										Where SES.SESSIONNO = "+convert(varchar(30),@nAuditSessionNumber) + "
										and PROGRAM = 'CASE') "
			End

			-- PatentTermAdjustments filtering
			If (@nIPOfficeAdjustmentFromDays is not null
			 OR @nIPOfficeAdjustmentToDays   is not null)
			and @nIPOfficeAdjustmentOperator in (0,7,8)
			Begin
				If @nIPOfficeAdjustmentOperator=0
					Set @nIPOfficeAdjustmentOperator=7

				Set @sWhere =  @sWhere+char(10)+"	and	XC.IPOPTA"+dbo.fn_ConstructOperator(@nIPOfficeAdjustmentOperator,@Numeric,coalesce(@nIPOfficeAdjustmentFromDays,0), coalesce(@nIPOfficeAdjustmentToDays,9999),@pbCalledFromCentura)
			End

			If (@nCalculatedAdjustmentFromDays is not null
			 OR @nCalculatedAdjustmentToDays   is not null)
			and @nCalculatedAdjustmentOperator in (0,7,8)
			Begin
				If @nCalculatedAdjustmentOperator=0
					Set @nCalculatedAdjustmentOperator=7

				Set @sWhere =  @sWhere+char(10)+"	and	(coalesce(XC.IPODELAY,0) - coalesce(XC.APPLICANTDELAY,0))"+dbo.fn_ConstructOperator(@nCalculatedAdjustmentOperator,@Numeric,coalesce(@nCalculatedAdjustmentFromDays,0), coalesce(@nCalculatedAdjustmentToDays,9999),@pbCalledFromCentura)
			End

			If (@nIPOfficeDelayFromDays is not null
			 OR @nIPOfficeDelayToDays   is not null)
			and @nIPOfficeDelayOperator in (0,7,8)
			Begin
				If @nIPOfficeDelayOperator=0
					Set @nIPOfficeDelayOperator=7

				Set @sWhere =  @sWhere+char(10)+"	and	XC.IPODELAY"+dbo.fn_ConstructOperator(@nIPOfficeDelayOperator,@Numeric,coalesce(@nIPOfficeDelayFromDays,0), coalesce(@nIPOfficeDelayToDays,9999),@pbCalledFromCentura)
			End

			If (@nApplicantDelayFromDays is not null
			 OR @nApplicantDelayToDays   is not null)
			and @nApplicantDelayOperator in (0,7,8)
			Begin
				If @nApplicantDelayOperator=0
					Set @nApplicantDelayOperator=7

				Set @sWhere =  @sWhere+char(10)+"	and	XC.APPLICANTDELAY"+dbo.fn_ConstructOperator(@nApplicantDelayOperator,@Numeric,coalesce(@nApplicantDelayFromDays,0), coalesce(@nApplicantDelayToDays,9999),@pbCalledFromCentura)
			End

			If @bHasDiscrepancy=1
			Begin
				Set @sWhere = @sWhere+char(10)+"	and (coalesce(XC.IPODELAY,0) - coalesce(XC.APPLICANTDELAY,0)) <> coalesce(XC.IPOPTA,0)"
			End

			If (@sActionKey is not null
			or @nActionKeyOperator between 2 and 6)
			Begin
				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nActionKeyOperator in (1,6)
				Begin
					-- Set @nActionKeyOperator = 'not equal to' to 'equal to' as we use
					-- 'not exists' with it.
					If @nActionKeyOperator = 1
					Begin
						Set @nActionKeyOperator = 0
					End

					set @sFrom = @sFrom+char(10)+"	Left Join (Select distinct CASEID from OPENACTION with (NOLOCK)"
							   +char(10)+"	      Where 2=2"

					Set @sWhere = @sWhere+char(10)+"and OA1.CASEID is NULL"
				End
				Else
				Begin
					Set @sFrom = @sFrom+char(10)+"	Join (Select distinct CASEID from OPENACTION with (NOLOCK)"
							   +char(10)+"	      Where 2=2"
				End

				If @bIsOpen = 1
				Begin
					Set @sFrom = @sFrom+char(10)+"	      and POLICEEVENTS = 1"
				End

				If @sActionKey is not null
				and @nActionKeyOperator not in (5,6)
				Begin
					Set @sFrom = @sFrom+char(10)+"	      and ACTION"+dbo.fn_ConstructOperator(@nActionKeyOperator,@String,@sActionKey, null,@pbCalledFromCentura)
				End

				Set @sFrom = @sFrom+") OA1 on (OA1.CASEID=XC.CASEID)"
			End
		End

		If  @nCaseNameFromCaseCaseKey is not NULL
		and @sCaseNameFromCaseNameTypeKey is not NULL
		Begin
			Set @sNameKeysList = null

			Set @sSQLString = "
			Select @sNameKeysList = @sNameKeysList + nullif(',', ',' + @sNameKeysList) + CAST(CN.NAMENO as varchar(11))
			from CASENAME CN with (NOLOCK)
			where CN.CASEID = @nCaseNameFromCaseCaseKey
			and   CN.NAMETYPE in("+dbo.fn_WrapQuotes(@sCaseNameFromCaseNameTypeKey,1,@pbCalledFromCentura)+")
			and (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate())"

			exec @nErrorCode = sp_executesql @sSQLString,
					N'@sNameKeysList		nvarchar(4000)		output,
					  @nCaseNameFromCaseCaseKey	int',
					  @sNameKeysList		= @sNameKeysList	output,
					  @nCaseNameFromCaseCaseKey	= @nCaseNameFromCaseCaseKey

			If @sNameKeysList is not null
			Begin
				Set @sFrom = @sFrom+char(10)+"	Join (Select distinct CASEID from CASENAME with (NOLOCK)"
						   +char(10)+"	      Where NAMETYPE in("+dbo.fn_WrapQuotes(@sCaseNameFromCaseNameTypeKey,0,@pbCalledFromCentura)+")"
				                   +char(10)+"	      and NAMENO in ("+@sNameKeysList+")"
						   +char(10)+"	      and (EXPIRYDATE is NULL or EXPIRYDATE >getdate())) CN on (CN.CASEID=XC.CASEID)"

			End
			-- If the @sNameKeysList is null then suppress the result set:
			Else Begin
				Set @sWhere = @sWhere+char(10)+"and 1=2"
			End
		End

		-- RFC72612
        If  @sFirmElement is not null
        or @sClientElement is not null
        or @sOfficialElement is not null
        or @sRegistrationNo is not null
        or @sTypeface is not null
        or @sElementDescription	is not null
        or @bIsRenew = 1
        Begin
            Set @sFrom=@sFrom
                       +char(10)+"    left join DESIGNELEMENT XDE WITH (NOLOCK)      on (XDE.CASEID=XC.CASEID)"
            If  @sFirmElement is not null
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.FIRMELEMENTID "+ dbo.fn_ConstructOperator(@nFirmElementOperator,@String,@sFirmElement, null,@pbCalledFromCentura)
            End
            If  @sClientElement is not null
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.CLIENTELEMENTID "+ dbo.fn_ConstructOperator(@nClientElementOperator,@String,@sClientElement, null,@pbCalledFromCentura)
            End
            If  @sOfficialElement is not null
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.OFFICIALELEMENTID "+ dbo.fn_ConstructOperator(@nOfficialElementOperator,@String,@sOfficialElement, null,@pbCalledFromCentura)
            End
            If  @sRegistrationNo is not null
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.REGISTRATIONNO "+ dbo.fn_ConstructOperator(@nRegistrationNoOperator,@String,@sRegistrationNo, null,@pbCalledFromCentura)
            End
            If  @sTypeface is not null
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.TYPEFACE "+ dbo.fn_ConstructOperator(@nTypefaceOperator,@String,@sTypeface, null,@pbCalledFromCentura)
            End
            If  @sElementDescription is not null
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.ELEMENTDESC "+ dbo.fn_ConstructOperator(@nElementDescriptionOperator,@String,@sElementDescription, null,@pbCalledFromCentura)
            End
            If @bIsRenew = 1
            Begin
                Set @sWhere=@sWhere+char(10)+"    and    XDE.RENEWFLAG = 1 "
            End
        End
	End
End

Set @psReturnClause = ltrim(rtrim(@sFrom+char(10)+@sWhere))
--print @psReturnClause
Return @nErrorCode
GO

Grant execute on dbo.csw_ConstructCaseWhere  to public
GO
