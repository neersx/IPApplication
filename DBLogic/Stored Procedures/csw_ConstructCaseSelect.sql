-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ConstructCaseSelect
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_ConstructCaseSelect]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_ConstructCaseSelect.'
	drop procedure dbo.csw_ConstructCaseSelect
end
print '**** Creating procedure dbo.csw_ConstructCaseSelect...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.csw_ConstructCaseSelect
	@pnTableCount			tinyint			OUTPUT,	-- the number of table in the constructed FROM clause
	@pnUserIdentityId		int,				-- Mandatory
	@psCulture			nvarchar(10)	= null,		-- the language in which output is to be expressed
	@pbExternalUser			bit,				-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@psTempTableName		nvarchar(60)	= null,		-- Temporary table that may hold extended column details.
	@pnQueryContextKey		int		= null,		-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null,		-- The columns and sorting required in the result set. 
	@ptXMLFilterCriteria		ntext		= null,		-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0,		-- Indicates that Centura called the stored procedure
	@psPublishedColumns		nvarchar(max)	= null	OUTPUT,	-- Concatenated list of the columns to be displayed.
	@psPublishedOrderBy		nvarchar(max)	= null	OUTPUT	-- Concatenated list of the columns in the ORDER BY that are also published.
	
AS
-- PROCEDURE :	csw_ConstructCaseSelect
-- VERSION :	225
-- DESCRIPTION:	Receives a list of columns and details of a required sort order and constructs
--		the components of the SELECT statement to meet the requirement
-- CALLED BY :	

-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 03 Sep 2003	MF  	RFC337	1	Additional columns required : ClientReference, ClientContact, ClientContactKey,
--					OurContact, OurContactKey
-- 15 Sep 2003	JEK  	RFC337	2	ClientContactKey is returning the key of the client instead of the contact.
-- 02 Oct 2003	JEK		3	New .net version based on v15 of cs_ConstructCaseSelect.
-- 13 Oct 2003	MF   	RFC519	4	Remove call of fn_FilterUserCases as this will be included in the Where clause 
--					if it is required.
-- 31 Oct 2003	TM  		5	Replace the following:
--					C.CLIENTCORRESPONDNAME	=>	XFC.CLIENTCORRESPONDNAME
--					C.CLIENTMAINCONTACT	=>	XFC.CLIENTMAINCONTACT
--					C.CLIENTREFERENCENO	=>	XFC.CLIENTREFERENCENO
--					Include the join on the fn_FilterUserCases if one of the following columns are
--					selected: 'ClientContact', 'ClientContactKey', 'ClientReference'
-- 17-Nov-2003	TM	RFC509	6	Implement XML parameters in Case Search.
-- 19-Nov-2003	TM	RFC509	7	Implement Julie's feedback
-- 21-Nov-2003	TM	RFC509	8	Move defaulting to some hard coded columns to be returned to fn_GetOutputRequests.
-- 24-Nov-2003	TM	RFC509	9	Add 'or datalength(@ptXMLOutputRequests) is null' to check if there is a @ptXMLOutputRequests
-- 25-Nov-2003  TM	RFC509	10	Remove the space from the call to the address formatting function: '...dbo.fn_FormatAddres s...'
-- 25-Nov-2003	TM	RFC509	11	Obtaine the NameAttention in the same manner as for DisplayName; i.e. selecting 
--					the CaseName row with the minimum sequence
-- 26-Nov-2003	TM	RFC509	12	Correct the logic obtaining the CPA Renewal Date.
-- 26-Nov-2003	TM	RFC509	13	Implement the NameAttention i the main name section under the following IF statemen:
--					If @sColumn in ('DisplayName', 'NameAddress', 'NameCode', 'NameCountry', 'NameKey','NameReference').
--					Correct the test if the CPARenewalDate joins are in the 'From' clause already.
-- 26-Nov-2003	TM	RFC509	14	Change the column ID from SericesBilledPercent to ServicesBilledPercent.
-- 26-Nov-2003	TM	RFC509	15	Correct the logic producing the Text column.
-- 26-Nov-2003	TM	RFC509	16	Concatenate '_' at the end of every correlation suffix so the various joins distinguished 
--					(e.g. the join for Event -1 will be created even though this search is matching on the join already present for -16).
--					Change the following for the NextRenewalDate: 
--					'If dbo.fn_ExistsInSplitString(@sCurrentFromString, @psFrom2, 'Left Join SITECONTROL'+@sTable1 )=0' 
--					to 'If dbo.fn_ExistsInSplitString(@sCurrentFromString, @psFrom2, 'Left Join SITECONTROL NRSC')=0'.
--					Update the table correlation names list. 
-- 26-Nov-2003	TM	RFC509	17	Consider Class in the Text column.
-- 27-Nov-2003	MF	RFC509	18	When returning Text columns attempt to get the language that best matches
--					the language of the user.
-- 02-Dec-2003	JEK	RFC509	19	Sorting not handling sort only columns.
-- 08-Dec-2003	JEK	RFC509	20	ImageData/ImageKey contain syntax error, brought back multiple rows and did join twice.
-- 09-Dec-2003	JEK	RFC643	21	Change type of QueryContextKey and provide default.
-- 30-Dec-2003	TM	RFC638	22	Display an appropriate description if an Office attribute is chosen.
-- 05-Jan-2004	TM	RFC638	23	Use TABLETYPE.DATABASETABLE = 'OFFICE' instead of the hard coding a specific table type.  
-- 16-Jan-2004	TM	RFC830	24	Add new OurContactNameCode and ClientContactNameCode columns.
-- 19-Feb-2004	TM	RFC976	25	Add @pbCalledFromCentura bit parameter and pass it to the relevant functions.
-- 23-Feb-2004	MF	SQA9663	26	Additional columns of data to be returned.
-- 25-Feb-2004	MF	SQA9662	26	Cater for extended columns of information that have already been extracted
-- 26-Feb-2004	MF	RFC865	27	Add WIPBalance as a column to be returned.
-- 04-Mar-2004	TM	RFC1032	28	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 08-Mar-2004	TM	RFC934	29	Modify implementation of fn_FilterUserEvents to apply for external users only.
-- 09-Mar-2004	TM	RFC865	30	Add new LocalCurrencyCode column.
-- 15-Mar-2004	MF	SQA9789	31	Extended columns giving SQL Error if same column used multiple times.  Use
--					the PublishName for the internal column name.
-- 22-Mar-2004	MF	RFC1219	32	Error when internal user returning list of Case Events.
-- 24-Mar-2004	MF	SQA9840 33	Non alphanumeric characters are not to be used in correlation names.
-- 24-Mar-2004	MF	SQA9840	34	Put the underscore back on the end of the generated correlation name (see RFC509 version 16).
-- 05 Apr 2004	MF	SQA9664	35	Drop the parameter @psReturnClause and make use of the temporary table 
--					#TempConstructSQL to build the SQL.  Remove the function fn_ExistsInSplitString
--					and stored procedure ip_ConcatenateSplitString.
-- 25 Apr 2004	MF	RFC1334	36	Additional columns for reporting Due Dates.
-- 07 May 2004	JEK	RFC919	37	Make QueryDataItem optional.
-- 12 May 2004	TM	RFC840	38	Obtain the RelatedCountryName from the country code of the Related Case when
--					the country code is null on the RELATEDCASE table. 
-- 10 May 2004	MF	RFC1334	38	Allow filtering on Due Date even if DueDate columns not selected.
-- 11 May 2004	MF	RFC1412	38	Corrections to various test failures.
-- 11 May 2004	MF	RFC941	39	The From Date range is to default for external users if a value has been
--					provide in the Sitecontrol "Client Due Dates: Overdue Days"
-- 13 May 2004	TM	RFC1246	40	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 14 May 2004	TM	RFC941	41	Move the defaulting of filter information to take in the possibility that no
-- 16 Jun 2004	MF	SQA10180 42	Ignore certain types of records on CPA Portfolio when determining the CPA
--					Renewal Date.  This is because CPA create multiple Portfolio records to
--					handle such things as Nominal Working or Affidavit of Use.
-- 24 May 2004	TM	RFC863	42	Extract Billing Address/Attention in the same manner as billing (SQA7355).
--					Correct the logic extracting the DebtorStatusDescription column.
-- 31 May 2004	TM	RFC863	43	Improve the commenting of SQL extracting the Billing Address/Attention.
-- 10 Jun 2004	TM	RFC1456	44	Add new NameAttentionKey column to be able to provide links from attention 
--					names to names.
-- 11 Jun 2004	TM	RFC1456	45	Add a NameAttentionCode column.
-- 02-Jul-2004	TM	RFC1536	46	Add DebtorStatusActionKey column.
-- 22-Jul-2004	TM	RFC1501	47	Set @sReplacementString variable to '' when required and combine the DueDates 
--					and ReminderDates columns logic.
-- 26-Jul-2004	TM	RFC1323	48	Implement Event Category as filter criterion and columns.  
-- 18 Aug 2004	AB	8035	49	Add collate database_default syntax to temp tables.
-- 02 Sep 2004	JEK	RFC1377	50	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 09 Sep 2004	JEK	RFC886	51	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 13 Sep 2004	JEK	RFC886	52	Implement fn_WrapQuotes for @psCulture.
-- 13 Sep 2004	JEK	RFC886	53	Implement fn_WrapQuotes for @psCulture for text type.
-- 16 Sep 2004	JEK	RFC886	54	Handle null @psCulture.  Culture is only required for FilterUser functions when translation is relevant.
-- 16 Sep 2004	IB	SQA8752	55	When constructing a Left Join to the CASEIMAGE table 
--					for ImageData or ImageKey columns instead of joining 
--					on min(IMAGEID) join on min(IMAGESEQUENCE).
-- 17 Sep 2004	TM	RFC886	56	Implement translation.
-- 20 Sep 2004	TM	RFC886	57	Correct the @sUnionSelect construction logic.
-- 27 Sep 2004	MF	RFC1846	58	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 29-Sep-2004	TM	RFC1806	59	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.		

-- 30 Sep 2004	JEK	RFC1695 60	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 01 Oct 2004	TM	RFC1846	61	Correct the IncludeClosedActions logic.
-- 13 Oct 2004	MF	SQA10463 62	Additional columns required : NameVariantMain, NameVariantAny, 
--					NameVariantMainOrName, NameVariantOrNameAny, NameVariantAll, NameVariantOrNameAll
-- 07 Dec 2004	TM	RFC1842	63	Cast the Text column as nvarchar(4000) when the Union is used.
-- 07 Dec 2004	MF	SQA10772 64	Additional columns required : EventDueDate, EventText, RelatedCaseCategoryDescription,
--					RelatedSubTypeDescription, RelatedTypeOfMarkDescription, RelatedLocalClasses
-- 10 Jan 2005	MF	SQA10442 65	Additional column to report whether LocalClasses have been recorded or only
--					international classes.
-- 13 Jan 2005	MF	SQA9914	 66	Additional columns to report the Case List Name and the PrimeCase for the CaseList.
-- 15 Feb 2005	MF	SQA11092 67	CaseText data not being returned when MODIFIEDDATE was null.  
--					Add an ISNULL(CT.MODIFIEDDATE,'') to cater for this.
-- 17 Mar 2005	TM	RFC2450	 68	Cast the EventText and DatesTextAny columns as nvarchar(4000) if the Union 
--					is implemented in the assembled SQL.
-- 24 Mar 2005	MF	SQA11198 69	When multiple Attribute Description columns are selected only one set
--					of table joins are being included.
-- 31 Mar 2005	TM	RFC2457	70	Add the exec sp_xml_removedocument in the filter criteria extraction section
--					for the corresponding "sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria"
-- 07 Apr 2005	TM	RFC2492	71	Save the result of the dbo.fn_GetLanguage() function in the variable to avoid
--					the SQL error.
-- 22 Apr 2005	TM	RFC1896	72	Add new CountryCode column.
-- 15 May 2005	JEK	RFC2508	73	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	74	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 03 Aug 2005	JEK	RFC2947	75	Searching on Ad Hoc Due Dates produced syntax error on @sLookupCulture.
-- 18 Aug 2005	TM	RFC2938	76	Extend importance level filtering to cover both ad hoc and event related due dates.
-- 07 Dec 2005	MF	SQA12109 77	Since change to declare Primary Key performance has dropped off on Event Date
--					selection if the Cycle is not explicitly defined.  Include a default CYCLE=1.
-- 10 Jan 2005	MF	SQA12184 78	Earliest Due Date and Earliest Due Event are returning inaccurate information. 
-- 16 Jan 2005	vql	SQA11738 79	SQL Error - Accented characters in QUERYCOLUMN. Centura cannot have [] delimiters.
-- 19 Jan 2006	TM	RFC1850	 80	Add new EventStaff columns.
-- 31 Jan 2006	MF	SQA11942 81	There are now different methods available for calculating the Age of Case (Annuity)
--					that depend upon the Property Type and Country.
-- 02 Mar 2006	MF	SQA12396 82	If ImportanceLevel value is not defined for an Event or Alert then assume a 
--					value of 9 (highest level) so as the Event/Alert will always be reported. I 
--					would prefer to return too much information than risk not returning the details
--					of an Event or Alert because the Importance Level had not been defined.
-- 03 Mar 2006	MF	SQA12409 83	Revisit RFC941 to apply this only to external users.
-- 21 Jun 2006	JEK	RFC4010	84	Columns created by csw_GetExtendedCaseDetails being corrupted in WorkBenches but not client/server.
-- 22 Jun 2006	JEK	RFC4010	85	Include brackets around column name to allow for calls from Query Analyser.
-- 31 Oct 2006	Dev	SQA12766 86	Changed to exclude CASEEVENT rows with no due dates.
-- 27 Nov 2006	JEK	RFC2982	87	Introduce new ProvideInstructions columns and associated filtering.
--					Note: implementation of fee columns still outstanding.
--				88	Add InstructionCycleAny column.
-- 06 Dec 2006	JEK	RFC2982	89	Add InstructionIsPastDueAny column.
-- 11 Dec 2006	JEK	RFC2984	90	Implement new columns NameSearchKey2, StandingInstruction and new Fees columns.
-- 12 Dec 2006	JEK	RFC2984	91	Implement subset security on InstructionType for external users.
--					Complete implementation of Fees columns and filtering.
-- 18 Dec 2006	JEK	RFC2984	92	Fees implementation continued.
-- 20 Dec 2006	JEK	RFC2982	93	Allow filtering of ProvideInstructions on a reminder.
-- 20 Dec 2006	MF	RFC2982	94	Fees implementation continued.
-- 15 Jan 2007	IB	SQA12785 95	Handle multiple importance levels and multiple event numbers 
--					when either the Duedate or Reminders are being reported on.
-- 23 Jan 2007	MF	SQA12744 96	Allow Name variables to accept more than one NameType as a parameter
-- 14 Feb 2007	MF	RFC2982	 97	Save the database column name that is being used in a the ORDER BY as this
--					may be required to be used instead of output column name when we are sorting
--					the result set but not actually extracting the columns.  This will be used in
--					the procedure csw_LoadSortedResults.
-- 28 Feb 2007	PY	SQA14425 98 	Reserved word [cycle]
-- 17 Apr 2007	SF	RFC5146	 99	For WB only, format a space after each comma in the comma-delimited Local Classes and International Classes
-- 19 Apr 2007	MF	SQA14698 100	The CLASS column when used in an ORDER BY clause is being converted to numeric
--					if the characters are numerics.  The test to determine conversion must exclude
--					the following characters $ + , - .
-- 16 Jul 2007	MF	SQA14957 101	SQL Error on Due Date enquiry with Alerts and user defined column.  Required the
--					temporary table name of case results to be replaced.  Also found problem in
--					pagination.
-- 03 Oct 2007	MF	SQA15416 102	Next Renewal Date being displayed even though Renewal Action is closed.
-- 15 Nov 2007	MF	SQA15438 103	Revisit of RFC2982 where a JOIN was commented out to improve performance.  This
--					resulted in Due Dates being displayed even though the Event had been removed from
--					the Action and so was effectively an orphan.  Reinstate this code.
-- 14 Dec 2007	MF	SQA15747 104	SQL Error - Accented characters in QUERYCOLUMN. Centura cannot have [] delimiters.
-- 21 Dec 2007	MF	SQA12586 105	Extend Case queries to cater for Events that have been associated with a 
--					specific Name and or Name Type.
-- 16 May 2008	MF	SQA16423 106	Do not use the Renewal Laws Action (~2) when determining if an Event is due.
-- 01 Jul 2008  LP  	RFC6645  107    Retrieve Our Contact based on WorkBench Contact Name Type site control.
-- 11 Jul 2008	SF	RFC5763	 108	Extend to support Opportunity Search (CRM WorkBench)
-- 13 Aug 2008	SF	RFC5760  109	Extend to support Marketing Activity Search (Campaigns) (CRM WorkBench)
-- 12 Nov 2008	AT	RFC5769	 110	Add additional Marketing Activity columns.
-- 14 Nov 2008	AT	RFC5773	 111	Modified retrieval of CRMCASESTATUS to use indexed column.
-- 11 Dec 2008	MF	SQA17136 112	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

-- 19 Dec 2008	MF	SQA16423 113	Do not use the Renewal Laws Action (~2) when determining if an Event is due.
-- 02 Apr 2009	MF	SQA17562 114	SQL error when Renewal Date and Due Date column selected on Presentation tab for Case enquiry.
--					Problem caused because UNION ALL being create to include ALERTS and the embedded SELECT for the
--					Renewal Date is being picked up by the REPLACE statement.
-- 04 Apr 2009	vql	SQA17542 110	Store and display free format text with a Standing Instruction.
-- 02 Apr 2009  LP      RFC7832  114    Add MapCountryCode column for Cases World Map.
-- 15 May 2009	MF	SQA17868 115	The use of the Exclude Action check box for a Due Date Report was not returning the correct result
--					because it was generating a NOT EXISTS for the select of the OPENACTION as well as excluding 
--					the specific ACTIONS. It should always be an EXISTS clause.
-- 03 Jul 2009	MF	SQA17748 116	Add WITH(NOLOCK) hint to each table to ensure long query do not block other users.
-- 24 Jul 2009	MF	SQA16548 117	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 05 Aug 2009	MF	SQA17917 103	Performance improvement by building in check of valid Nametypes the user has access to.
-- 01 Sep 2009	NG	RFC7321	 118	Return another column IsProspectClient in case of Opportunity Advanced Search. 	
-- 10 Sep 2009	ASH	RFC100058	 119 Change all the references of the SCUR to match the first instance of site control alias SCUR. 
-- 14 Oct 2009  LP      RFC100085 120   Fix replaceString logic when returning Adhoc Reminder data.	
-- 30 Oct 2009	LP	RFC6712	 121	Return IsEditable column (row access security) for WorkBenches.
-- 03 Dec 2009	MF	RFC100148 122	Correct merge problem when WITH (NOLOCK) was introduced.
-- 22 Jan 2010	MF	RFC8834	 123	Rework of RFC6712 this row level security code to improve performance.
-- 01 Feb 2010	LP	RFC6712	124	Exclude Insert privilege from IsEditable flag calculation.
-- 12 Feb 2010	MF	RFC8846	125	Replace joins to fn_FilterUserCases and fn_FilterUserEvents with previously loaded temporary
--					tables as a performance improvement step.
-- 16 Feb 2010	JCLG	RFC8544	126	Return IsEditable, ReportToThirdParty and IsProspectClient as bit
-- 09 Mar 2010  LP      RFC8970 127     Enable external users to select due dates within specific importance level range.
--                                      Always set @bUseAdHocDates to 0 for external users.
-- 19 Mar 2010	MF	SQA18562 128	The EventDueDate column should only return a date if the Event is actually consider to be due.
-- 23 Mar 2010	MF	SQA18550 129	Need to include ESCAPE character when search for generating table correlation name that included underscores.
-- 24 Mar 2010	SF	RFC8768	 130	Add CaseReferenceStem column
-- 01 Apr 2010	LP	RFC8970	 131	Add left join to EVENTS table for external users to get CLIENTIMPLEVEL.
-- 12 Apr 2010	MF	RFC9104	 132	If no explicit Order By columns have been identified then default to the first column.
-- 11 May 2010	MF	SQA18738 133	Allow Cycle of due events to be reported in the Due Date report.
-- 11 May 2010	MF	RFC100255 133	Order By on a CLASS field is currently handled with special functionality that converts numeric value CLASSES into
--					an actual numeric field so the Order By is performed numerically.  This is causing problems with the new paging
--					approach used in the web version.  The solution is to return an additional Class column that has been converted to
--					its equivalent numeric value if the data is numeric otherwise null.  That column can then be used in the ORDER BY.
-- 13 May 2010	MF	SQA15032 134	Allow Importance Level of due events to be reported in the Due Date Report
-- 09 Jul 2010	MF	RFC9537	 135	When Reminder or Due Dates are being filtered, duplicate rows were being returned. Needed to introduce DISTINCT
--					into the SELECT.
-- 20 Jul 2010	MF	SQA18631 136	When checking for the existence of an OPENACTION to ensure the Due Date being reported is in fact due, the ACTION
--					should not be restricted to the Action that created the Event as that Action may now be closed even though another
--					Action that references the Event is open.
-- 05 Aug 2010	MF	RFC9463	137	Provide new columns that will report on where a Name has been inherited from.
-- 25 Aug 2010	MF	SQA19006 138	Revisit of SQA11187 to allow Main Renewal Action to be ignored when filtering on Next Renewal Date for Due Date columns.
-- 16 Sep 2010	MF	SQA19068 139	Revisit of RFC100255.  For Centura if the column has not been included in the select list then we cannot use a 
--					numeric version of that column.
-- 22 Oct 2010	LP	RFC9321	140	Add global case field updates columns.
-- 26 Oct 2010	DV	RFC100409 141   Add a missing left join with EVENTS in case of external user.
-- 09 Nov 2010  DV	RFC7914	142	Replaced join with a left join with INSTRUCTIONS table for external users.
-- 21 Nov 2010	MF	RFC9981	143	Case search error - "The ntext data type cannot be selected as DISTINCT because it is not comparable". When RFC9537
--					introduced the DISTINCT keyword it also caused this problem where NTEXT columns are included.
-- 14 Dec 2010	MF	SQA19256 144	SQL error when running custom view with large number of columns including 2 Event Dates. Problem occured when using 
--					LIKE to see if the table join has already been included.  Need to introduce ESCAPE for underscore character.
-- 02 Mar 2011  LP      RFC10252 145    Error when ImageData is required in the results, e.g. reporting services, due to DISTINCT keyword.
-- 19 Apr 2011  LP      RFC10502 146    Error when ImageData is required in the results, e.g. reporting services, due to DISTINCT keyword.
-- 16 May 2011	MF	RFC10631 147	Allow the address associated with CaseName of a given NameType to be extracted. Where the Name type exists multiple
--					times for the Case then there will be multiple rows returned.
-- 27 Jun 2011	LP	RFC10854 148	Only use DISTINCT keyword when returning Due Dates columns.
-- 30 Jun 2011	MF	RFC10924 149	Event Due Date should take the Controlling Action into consideration as the Event will only be considered due if
--					the specified Controlling Action is open against the Case.
-- 20 Jul 2011  DV      RFC10984 150    Rename temporary table #TEMPCASES to #TEMPCASESEXT as a table with same name is already 
--                               	getting created in csw_GetExtendedCaseDetails stored proc
-- 13 Sep 2011	ASH	R11175	 151	Maintain ReminderMessage in foreign languages.
-- 19 Sep 2011  MS      RFC11278 152    Consider Importance Level filters in Earliest Due Date and Earliest Due Event columns       
-- 28 Sep 2011	MF	R11351	 153	Allow DISTINCT to be used where RelatedCase data is being joined to.  This is particularly required where a column from
--					RelatedCase is used to Sort on but is not included in the data to be displayed.
-- 12 Oct 2011	ASH	R11042	 154	Replace LONGMESSAGE to SHORTMESSAGE in fn_SqlTranslatedColumn when column name is ReminderMessage.
-- 17 OCT 2011	MF	R11432	155	Whereever the EVENTDESCRIPTION is to be displayed then the CONTROLLINGACTION should be used in preference in order to 
--					determine which criteria should supply the description.
-- 20 Oct 2011	MF	R11432	156	Revisit after failed testinging as multiple rows for same Due Event being returned where Description was changed in 
--					Controlling Action.
-- 31 Oct 2011	MF	R11484	157	Provide new columns that will reported on visible Related Case details without specifying a particular Relationship.
-- 26 Dec 2011	DV	R11140	158	Check for Case Access Security.
-- 11 Jan 2012	LP	R11720	159	Extend to return due dates from events that may not have controlling action but are associated with an open action.
-- 10 Feb 2012	MF	R100681	160	Error on Case Search when Dates columns are selected for display.
-- 18 Apr 2012	MF	R12193	161	The CONTROLLINGACTION for an Event is not being considered in checking if a Due Date should be reported.
-- 24 May 2012	MF	S20587	162	Reporting CaseEvent details where the CONTROLLINGACTION may be used was not restricting the OPENACTION rows adequately
--					resulting in multiple rows being returned instead of a single row.
-- 21 Jun 2012	vql	S20667	162	Case Search crashing with accented characters in presentation columns.
-- 20 Aug 2012	MF	S20833	163	Correction of SQA20667. Order By clause was being corrupted.
-- 06 Dec 2012	MF	R13009	164	Provide an option as to whether the specified CONTROLLINGACTION must be open or whether any open action that includes 
--					the Event will do.
-- 01 Mar 2013	MF	R13274	165	Add new column to indicate that Reminder was generated from an Ad Hoc.
-- 09 Apr 2013	MF	R13035	166	The DatesXXXAny columns are using full JOINs instead of a filtered Left Outer Join. The result of this
--					is that Cases that do not have a matching row are being filtered out of the result set.
-- 05 Jul 2013	vql	R13629	167	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 19 Jul 2013	MF	R13081	168	Provide new columns that will report CaseEvent data changes that occurred as a result of Policing new Law Update changes.
-- 24 Jul 2013	MF	R13683	169	Provide new columns that will report the Event with the latest Due Date that belongs to the same Event Group of the Event
--					Due Date that is being returned.
-- 10 Mar 2014	MF	R31723	170	JOIN to RelatedCase and CaseRelation changed to LEFT JOIN to ensure Case rows are not filtered out.
-- 25 Mar 2014	MF	R32794	171	If Due Dates are being returned and being filtered to match an explicit Action then ignore ControllingAction of Event and
--					match on the Action.
-- 14 May 2014	KR	R13961	172	If row access security is assigned to a user, users with no row access security should NOT be able to access cases
-- 09 Jun 2014  AK      R34938  173     Ability to see Bay number and File Part Title in the Case Search results
-- 07 Jul 2014	MF	R36905	174	The ~2 Action is ignored for determining due dates.  If however the CONTROLLINGACTION of the Event explicitly
--					specifies ~2 then it should be able to be used.
-- 30 Jul 2014	MF	R37890	175	New column to report the latest modified date against a Due Date Event.
-- 07 Oct 2014	MF	R40200	176	If the filter Action is ~2 then allow due dates to be returned whose Open Action is ~2 otherwise filter these out.
-- 28 Oct 2014	MF	R41041	177	The CaseReferenceStem should strip any characters from the ~ onwards as only the characters before this are the actual Stem.
-- 30 Jan 2015	MF	R44200	178	Error in the generated order by clause.  Change @sPublishName to PublishName.
-- 19 Feb 2015	MF	R45041	179	Error when RelatedOfficialNumberAny columns selected with no other Related Case columns.
-- 24 Feb 2015	MF	R41426	180	Provide new columns to report Billing Currency and Debtor Type of associated name type.
-- 02 Mar 2015	MF	R43207	181	Replace text columns for CASEEVENT table with new tables CASEEVENTTEXT and EVENTTEXT.
-- 10 Jun 2015	MF	R48446	182	SQL Error when ad hocs returned in Due Date list.
-- 21 Jul 2015  MS      R50247  183     Add check for EVENTTEXTTYPE.ISEXTERNAL for externl users
-- 17 Sep 2015	MF	R52415	184	Returning TrademarkClass and Text for the same TextType is incorrectly joining multiple times to the same table.
-- 08 Oct 2015  DV      R50247  185	Change EventCategory to allow multiple values to be passed.
-- 02 Nov 2015	MF	R54660	186	EventDueDate was incorrectly being restricted to Cycle 1.
-- 04 Nov 2015	KR	R53910	187	Adjust formatted names logic (DR-15543)
-- 23 Mar 2016	MF	R59688	188	After RFC53910 was implemented it exposed a bug that previously existed.  Just needed to comment out some code.
-- 15 Apr 2016	MF	R60405	189	Report on EventNo.
-- 25 May 2016	MF	R58007	190	New columns to report Event Notes for a specific Text Type as well as date the note was modified.
-- 02 Jun 2016	MF	R62341	191	Row level security broken out into user defined functions fn_CasesRowSecurity or fn_CasesRowSecurityMultiOffice. 
-- 14 Jul 2016	MF	62317	192	Performance problem on large result set reporting Names assoicated with a Case. The solution of using a common table expression
--					cannot be used for Centura.
--					WARNING: This version must be released with csw_ListCase, csw_LoadSortedResult, ip_ListConflict, ipw_ListDueDate and wp_ListWorkInProgress <----------------
-- 18 Aug 2016	MF	65363	193	Extend the @sEventKeys variable to nvarchar(max) so that the entered Events to be searched are not truncated.
-- 15 Sep 2016	MF	53876	194	New columns for Next Due Date, Next Due Event and Next Due Event Number.
-- 13 Dec 2016	MF	70107	195	A merge problem to do with RFC59688 causing a failure on Due Date when Ad Hoc selected.
-- 04 Jan 2017	MF	70127	196	Case Notes columns are causing duplicate Case Event rows to be returned.
-- 07 Feb 2017	MF	70512	197	Allow reporting of when a File has been moved (FILEMOVEDDATE) and who moved it (FILEMOVEDBY)
-- 08 Jun 2017	MF	71701	198	If an EventDate or an EventDueDate is being reported, then the OCCURREDFLAG can be set to restrict the rows (if cyclic) that may be returned.
-- 04 Jul 2017	MF	71861	199	Display Attention Name details for Name Types that can have multiple names associated with the case. Includes listed names and semicolon separated names.
-- 21 Sep 2017	AT	72084	200	Add return of keys for filtering in apps.
-- 09 Jan 2018	MF	73246	201	If the Filter makes reference to Global Process Key then we need to ensure that the GLOBALCASECHANGERESULTS table is included, even if no specific column 
--					is requested to be returned in the Select list.
-- 08 May 2017	MF	74061	202	The EarliestDueDate and NextDueDate columns are to consider the Event related filters so as to only report due dates that match those filters.
-- 19 Apr 2018	MF	73777	203	Introduce a new File Location column called BayNoOrLocation that will report the BayNo if it is available, otherwise the File Location.
-- 11 May 2018	MF	73690	204	Correction of problem when RelatedCountryNameAny is selected.
-- 22 May 2018	DV	74153	205	New columns for FirmElementId, ClientElementId, OfficialElementId, ElementRegistrationNo, ElementTypeface, ElementDescription
-- 23 May 2018	MF	73957	206	The EventDate and EventDueDate for a specific EventNo is to consider the Case due date Filters that also specify the same EventNo. This will also apply to
--					OpenEventOrDue, OpenRenewalEventOrDue, and  NextRenewalDate.  This is similar to what was previously implemented for RFC 74061.
-- 05 Jun 2018	MF	73777	207	Merge issue with 737777.
-- 12 Jul 2018	MF	74483	208	When reporting File Location. Just report the last movement with no consideration to whether it has a file part or not.  Previously we were returning two
--					different locations for each of the Case with a File Part and the Case when it does not have a File Part
-- 16 Jul 2018  MS	R11355  209     Added IsPoliced field in resultset done via Global field update
-- 17 Jul 2018	MF	74524	210	New columns to report the Title of any related cases or a related case for a specific relationship.
-- 07 Sep 2018	AV	74738	211	Set isolation level to read uncommited.
-- 10 Oct 2018	MF	DR-44817 212	Designated Country details should not be returned if the designated country was ceased before the designation was last updated or has been removed as 
--					an available country.
-- 11 Oct 2018	MF	DR-44826 212	Ad Hoc dates are not returned when an event note type column is displayed in search results. 
-- 31 Oct 2018	DL	DR-45102 213	Replace control character (word hyphen) with normal sql editor hyphen
-- 14 Nov 2018  AV	DR-45358 214	Date conversion errors when creating cases and opening names in Chinese DB
-- 24 Jan 2019	MF	DR-46050 215	New column for NextDueText to be associated with NextDueDate and NextDueEvent. Only Event Notes with no EventTextType will be reported.
-- 31 May 2019	MF	DR-49447 216	When any of DatesAny column are included, also consider the <ColumnFilterCriteria> (same fas for Due Dates), to limit the specific Events to be reported.
-- 02 Sep 2019	vql	DR-45990 217	Merge issue with csw_ConstructCaseSelect for Bay and Location No.
-- 20 Sep 2019  MS  DR-37452 218    Added columns DatesTextNoType and DatesTextNoTypeModifiedDate
-- 21 Oct 2019  BS  DR-52884 219    Fixed a bug to exclude resolved Ad Hoc dates from Next Due Date and Next Due Event columns in Case Searches
-- 18 Dec 2019  AK  DR-51223 220    Included new columns EntitySizeUpdated, ProfitCentreCodeUpdated, PurchaseOrderNoUpdated, TypeOfMarkUpdated in Global Case Field Updates result set
-- 19 Mar 2020	MS	DR-55234 221	Added NameCountry column for Debtor and Renewal Debtors
-- 20 Mar 2020 	SF	DR-45207 222	Introduce LastAccessed for use in sorting Recent Cases list
-- 24 Mar 2020  SR  DR-54690 223	Remove DDE.CONTROLLINGACTION reference when DDE table is not used
-- 14 Apr 2020  BS  DR-58910 224	Event Notes should be returned with Due Dates in Case Searches when date range or period applied
-- 02 Jun 2020	MS	DR-60866 225	Added Global Case Change IsPoliced column in result set

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	AgeOfCase
-- 	ApplicationBasisDescription
--	AttributeDescription
--	BilledCurrencyCode (RFC509)
--	BilledTotal (RFC509)
--	Budget (RFC509)
--	BudgetCurrencyCode (RFC509)
--	BudgetUtilisedPercent (RCF509)
--	CaseCategoryCode (SQA9663)
-- 	CaseCategoryDescription
--	CaseFamilyReference
--	CaseFamilyTitle
--	CaseKey
--	CaseListName
--	CaseOfficeDescription (RFC224)
--	CasePurchaseOrderNo
--	CaseReference
--	CaseReferenceStem (RFC8768)
--	CaseStatusSummary
--	CaseStatusSummaryKey (DR-33416)
--	CaseTypeDescription
--	CaseTypeKey (DR-33416)
--	ChargeDueEventAny (RFC2984)
--	Class
--	ClientContact 	(RFC337)
--	ClientContactKey(RFC337)
--	ClientContactNameCode (RFC830)
--	ClientElementId (RFC74153)
--	ClientReference	(RFC337)
--	CountryCode (RFC1896)
--	CountryName
--	CountryAdjective
--	CPARenewalDate (RFC509)
--	CPAStatus (SQA9633)
--	CurrentOfficialNumber
--	DatesCycleAny (SQA9663)
--	DatesDescAny (SQA9663)
--	DatesDueAny (SQA9663)
--	DatesEventAny (SQA9663)
--	DatesEventCategoryAny (RFC1323)
-- 	DatesEventCategoryAnyIconKey (RFC1323)
--	DatesTextAny (SQA9663)
--	DatesTextTypeAny (RFC43207)
--	DatesTextModifiedDateAny (RFC43207)
--	DatesTextAnyOfType (RFC58007)
--	DatesTextAnyOfTypeModifiedDate(RFC58007)
--	DebtorStatusActionKey (RFC1536)
--	DebtorStatusDescription
--	DesigCountryCode
--	DesigCountryName
--	DesigCountryCaseStatus
--	DesigCountryStatus
--	DisplayName
--	DisplayNameAll (RFC509)
--	DisplayNameAny (RFC13)
--	DisplayNamesUnrestrictedAny (SQA9663)
--	DueDate (RFC1334)
--	DueDateCycle (SQA18738)
--	DueDateDescription (RFC1334)
--	DueDateImportance (SQA15032)
--	DueDateNotes (RFC1334)
--	DueDateResp (SQA12586)
--	DueEventCategory (RFC1323)
--	DueEventCategoryIconKey (RFC1323)
--	DueEventNo (RFC60405)
--	DueEventStaff (RFC1850)
--	DueEventStaffCode (RFC1850)
--	DueEventStaffKey (RFC1850)
--	DueDescriptionLatestInGroup		(RFC13683)
--	DueDateLatestInGroup			(RFC13683)
--	DueDateLastModified			(RFC37890)
--	EarliestDueDate (RFC12)
--	EarliestDueEvent (RFC12)
--	ElementDescription (RFC74153)
--	ElementRegistrationNo (RFC74153)
--	ElementTypeface (RFC74153)
--	EntitySizeDescription
--	EventDate
--	EventDueDate(SQL10772)
--	EventChangedDescription			(RFC13081)
--	EventChangedNumber			(RFC13081)
--	EventChangedCycle			(RFC13081)
--	EventChangedImportanceDescription	(RFC13081)
--	EventChangedImportance			(RFC13081)
--	EventChangedType			(RFC13081)
--	EventChangedDateBefore			(RFC13081)
--	EventChangedDateNow			(RFC13081)
--	EventChangedDueBefore			(RFC13081)
--	EventChangedDueNow			(RFC13081)
--	EventText(SQL10772)
--	FeeBillCurrencyAny (RFC2984)
--	FeeBilledAmountAny (RFC2984)
--	FeeBilledPerYearAny (RFC2984)
--	FeeDueDateAny (RFC2984)
--	FeesChargeTypeAny (RFC2984)
--	FeeYearNoAny (RFC2984)
--	FirmElementId (RFC74153)
--	FirstUseClass (RFC509)
--	FirstUseDate (RFC509)
--	FirstUseCommerceDate (RFC509)
--	FileLocationDescription
--	FilePartTitle
--	FileMovedDate (RFC70512)
--	FileMovedBy (RFC70512)
--	ImageData
--	ImageKey (RFC509)
--	InheritedFromName (RF9463)
--	InheritedRelationship (RF9463)
--	InstructionBillCurrencyAny (RFC2982)
--	InstructionCycleAny (RFC2982)
--	InstructionDefinitionAny (RFC2982)
--	InstructionDefinitionKeyAny (RFC2982)
--	InstructionDueDateAny (RFC2982)
--	InstructionDueEventAny (RFC2982)
--	InstructionIsPastDueAny (RFC2982)
-- 	InstructionExplanationAny (RFC2982)
--	InstructionFeeBilledAny (RFC2982)
--	IntClasses
--	IsLocalClient
--	IsEditable (RFC6712)
--	IsTextUpdated (RFC9321)
--	IsOfficeUpdated (RFC9321)
--	IsStatusUpdated (RFC9321)
--	IsFamilyUpdated (RFC9321)
--	IsTitleUpdated (RFC9321)
--	IsFileLocationUpdated (RFC9321)
-- 	LastAccessed (DR-45207)
--	LocalClasses
--	LocalClassIndicator(SQA10442)
--	LocalCurrencyCode (RFC865)
--      MapCountryCode (RFC7832)
--	MarketingActivityStatusDescription (RFC5760)
--	MarketingActivityActualCost (RFC5760)
--	MarketingActivityActualCostLocal (RFC5760)
--	MarketingActivityActualCostCurrency (RFC5760)
--	MarketingActivityAcceptence (RFC5760)
--	MarketingActivityNoOfContacts (RFC5769)
-- 	MarketingActivityNoOfResponses (RFC5769)
--	MarketingActivityNoOfStaffAttended (RFC5769)
--	MarketingActivityNoOfContactsAttended (RFC5769)
--	MarketingActivityNewOpportunities (RFC5769)
--	NameAddress
--	NameAddressAny (RFC10631)
--	NameAttention (RFC509)
--	NameAttentionCode (RFC1456)
--	NameAttentionKey (RFC1456)
--	NameAttentionAll (RFC71861)
--	NameAttentionAny (RFC71861)
--	NameAttentionCodeAny (RFC71861)
--	NameAttentionKeyAny (RFC71861)
--	NameCode
--	NameCodeAny (RFC13)
--	NameCountry
--	NameBillCurrency (RFC41426)
--	NameDebtorType   (RFC41426)
--	NameKey (RFC13)
--	NameKeyAny (RFC13)
--	NameKeyAll (RFC5763)
--	NameReference
--	NameReferenceAny (RFC13)
--	NameSearchKey2 (RFC2984)
--	NameTypeAny
--	NameVariantMain (SQA10463)
--	NameVariantAny (SQA10463)
--	NameVariantMainOrName (SQA10463)
--	NameVariantOrNameAny (SQA10463)
--	NameVariantAll (SQA10463)
--	NameVariantOrNameAll (SQA10463)
--	NextRenewalDate (RFC509)
--	NextDueDate   (RFC53876)
--	NextDueEvent  (RFC53876)
--	NextDueEventNo(RFC53876)
--	NextDueText (DR-46050)
--	NoInSeries
--	NoOfClaims
--	NoOfClasses
--	NULL (RFC13)
--	NumberTypeEventDate
--	OfficialElementId (RFC74153)
--	OfficialNumber
--	OpenEventOrDueDate
--	OpenRenewalEventOrDue
-- 	OpportunityExpectedCloseDate (RFC5763)
-- 	OpportunityNextStep (RFC5763)
-- 	OpportunityNumberOfStaff (RFC5763)
-- 	OpportunityPotentialValue (RFC5763)
-- 	OpportunityPotentialValueCurrency (RFC5763)
-- 	OpportunityPotentialWin (RFC5763)
-- 	OpportunityProdInterestDescription (RFC5763)
-- 	OpportunityRemarks (RFC5763)
-- 	OpportunitySourceDescription (RFC5763)
-- 	OpportunityStatusDescription (RFC5763)
--	OurContact	(RFC337)
--	OurContactKey	(RFC337)
--	OurContactNameCode (RFC830)
--	PlaceFirstUsed
--	PrimeCaseIRN
--	PropertyTypeDescription
--	PropertyTypeKey (DR-33416)
--	ProposedUse
--	RelatedCountryName
--	RelatedOfficialNumber
--	RelatedCaseCategoryDescription(SQL10772)
--	RelatedLocalClasses(SQL10772)
--	RelatedSubTypeDescription(SQL10772)
--	RelatedTitle (R74524)
--	RelatedTypeOfMark(SQL10772)
--	RelationshipEventDate
--
--	RelatedCaseRelationshipAny (R11484)
--	RelatedOfficialNumberAny (R11484)
--	RelatedCountryNameAny (R11484)
--	RelatedCaseCategoryAny (R11484)
--	RelatedCaseSubTypeAny (R11484)
--	RelatedCaseTitleAny (R74524)
--	RelatedCaseTypeOfMarkAny (R11484)
--	RelatedEventDateAny (R11484)
--	RelatedLocalClassesAny (R11484)
--
--	ReminderAdHocFlag (R13274)
--	ReminderDate
--	ReminderMessage
--	RenewalNotes
--	RenewalStatusDescription
--	RenewalStatusExternalDescription
--	RenewalStatusKey (DR-33416)
--	ReportToThirdParty
--	ROIOpportunityPotentialVsActual (RFC5760)
--	ServicesBilledPercent (RFC509)
--	ServicesBilledTotal (RFC509)
--	ShortTitle
--	StandingInstruction (RFC2984)
--	StatusDescription
--	StatusKey (DR-33416)
--	StatusExternalDescription
--	SubTypeDescription
--	Text
--	TextAll
--	TotalOpportunityPotentials
--	TrademarkClass
--	TypeOfMarkDescription
--	WIPBalance(RFC865)
--      DatesTextNoType (DR-37452)
--      DatesTextNoTypeModifiedDate (DR-37452)

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	A
--	AC
--	AD  (RFC10631)	
--	ADC (RFC10631)
--	ADS (RFC10631)
--	AN2 (RFC863)
--	AN3 (RFC863)
--	AT
--	AX
--	BA (RFC863)
--	BC (RFC863)
--	BEFORE(RFC13081)
--	BLN (RFC863)
--	BS (RFC863)
--	C
--	CE
--	CET (RFC43207)
--	CG (DR-44817)
--	CF (SQA9663)
--	CI
--	CL
--	CLF (RFC509)
--	CN
--	CNA
--	CNDD(SQA12586)
--	CPA (SQA9663)
--	CPAE(SQA9663)
--	CR
--	C_R	(R11484)
--	CS
--	CSL
--	CSLM
--	CT
--	CT_ALL
--	CON (RFC337)
--	CU (RFC41426)
--	DA (SQA9663)
--	DC
--	DCC
--	DCS
--	DS
--	DCN
--	DD  (RFC1334)
--	DDAC(SQA18562)
--	DDE (RFC1334)
--	DDEC(RFC1334)
--	DDECT (RFC1323)
--	DDEMP (RFC1850)
--	DDET (RFC43207)
--	DDETT(RFC43207)
--	DDEV(SQA18562)
--	DDEX (RFC8970)
--	DDOA(SQA18562)
--	DD_OA(RFC11432)
--  	DE(RFC74153)
--	DT (RFC41426)
--	E (SQA9663)
--	EC (SQA9663)
--	ECT (RFC1323)
--	EDD (SQA12586)
--	EMP (SQA12586)
--	ER  (RFC1334)
--	ETT (RFC43207)
--	CET (RFC43207) 
--	EVDD (SQA12184)
--	FC (RFC2984)
--	FD (RFC2984)
--	FE (RFC2984)
--	FEC (RFC2984)
--	FEX (RFC2984)
-- 	FNWH (RFC509)
--	GCR (RFC9321)
--	I
--	IL
--	INCE (RFC2982)
--	IND (RFC2982)
--	INDCE (RFC2982)
--	INDE (RFC2982)
--	INE (RFC2982)
--	INEC (RFC2982)
--	INOA (RFC2982)
--	IP (SQA9663)
--	M (RFC5760)
--	N
--	N2 (RFC509)
--	NA
--	NE
--	NI (RFC9463)
--	NIR(RFC9463)
--	NOW(RFC13081)
--	NROA
--	NT
--	NTA
--	NV
--	NX
--	O
--	OI (RFC509)
--	OFAT (RFC638)
--	OFC
--	OUR
--	OPP (RFC5763)
--	P
--	PC
--	RC
--	RN (RFC509)
--	RCE
--	RCN
--	RCS
--   	RCR (RFC840)
--
--	R_C	(R11484)
--	R_CE	(R11484)
--	R_CN	(R11484)
--	R_CR	(R11484)
--	R_VC	(R11484)
--	R_VS	(R11484)
--
--	RS
--	RSC (RFC6712)
--	SCUR (RFC509)
--	SI (RFC2984)
--	SIG (SQA12586)
--	ST
--	STAFF
--	STATE
--	TA
--	TL
--	TC
--	TE
--	TM
--	TTP (RFC638)
--	TT (SQA9662)
--	TCMST (RFC5760) Marketing Activity Status
--	TCOPSO (RFC5763) Opportunity Source
--	TCOPST (RFC5763) Opportunity Status
--	VB
--	VC
--	VP
--	VS
--	WIP(RFC865)
--	WT (RFC509)
--	WTP (RFC509)
--	XFC 
--	XX


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @ErrorCode		int
declare	@sDelimiter		nchar(1)
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
declare @sReturn		char(1)
declare @sRenewalAction		nvarchar(2)
declare	@bAnyRenewalAction	bit		-- Flag that indicates that the Renewal Search on Any Action sitecontrol is on.
declare @bAnyOpenAction		bit		-- Flag that indicates a due date is not forced to use the ControllingAction
declare	@sSQLString		nvarchar(max)
declare @sAddSelectString	nvarchar(4000)	-- the SELECT string currently being searched for
declare	@sCurrentSelectString	nvarchar(4000)	-- the SELECT string being constructed until it exceeds 4000 characters
declare @sAddFromString		nvarchar(4000)	-- the FROM string currently being searched for
declare @sAddFromString1	nvarchar(4000)	-- a second part of the FROM string.
declare	@sDateFilter		nvarchar(4000)	-- constuction of a filter for CaseEvents being reported.
declare @sSearchString		nvarchar(4000)	-- the FROM string with wildcard and escape characters SQA18550
declare	@sCurrentFromString	nvarchar(4000)	-- the FROM string being constructed until it exceeds 4000 characters
declare @sAddWhereString	nvarchar(4000)	-- the WHERE string currently being searched for
declare	@sCurrentWhereString	nvarchar(4000)	-- the WHERE string being constructed until it exceeds 4000 characters
declare @sAddOrderByString	nvarchar(4000)	-- the ORDER BY string currently being searched for
declare @sOrderColumnString	nvarchar(4000)	-- the ORDER BY string using the base column names 
declare	@sCurrentOrderByString	nvarchar(4000)	-- the ORDER BY string being constructed until it exceeds 4000 characters
declare	@sCurrentOrderColumnString nvarchar(4000)-- the ORDER BY string being constructed until it exceeds 4000 characters

declare	@sSelect		char(1)
declare	@sFrom			char(1)
declare @sWhere			char(1)
declare	@sUnionSelect		char(1)
declare	@sUnionFrom		char(1)
declare @sUnionWhere		char(1)
declare	@sOrderBy		char(1)
declare	@sColumnOrderBy		char(1)

declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sFirstPublishName	nvarchar(50)	 --RFC9104
declare @sQualifier		nvarchar(50)
declare @sNameType		nvarchar(200)
declare @sTableColumn		nvarchar(1000)
declare @sFirstTableColumn	nvarchar(1000)	 --RFC9104
declare	@sSaveExistsClause	nvarchar(1000)
declare @sSaveReminderJoin	nvarchar(1000)
declare @sReplacementString	nvarchar(1000)
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)
declare @sCorrelationSuffix2	nvarchar(20)
declare @sSuffixSaved		nvarchar(20)
declare	@sCaseEventCorrelation	nvarchar(25)
declare @sTable1		nvarchar(25)
declare @sTable2		nvarchar(25)
declare @sTable3		nvarchar(25)
declare @sTable4		nvarchar(25)
declare @sTable5		nvarchar(25)
declare @sTable6		nvarchar(25)
declare @sTable7		nvarchar(25)
declare @sTable8		nvarchar(25)
declare @sTable9		nvarchar(25)
declare @sTable10		nvarchar(25)
declare @sTable11		nvarchar(25)
declare	@sSeparator		nvarchar(254)
declare @sList			nvarchar(4000)	-- Variable to prepare a comma separated list of values

declare @nColumnNo		tinyint
declare @nFirstColumnNo		tinyint		 --RFC9104
declare @nOrderPosition		tinyint
declare @nCloseBracket		tinyint
declare @nLastPosition		smallint
declare @nTranNo		int		--RFC13081
declare @nOverdueDays		int
declare @dtOverdueRangeFrom	datetime

declare	@bExtendedData			bit
declare @bDueDatesLoaded		bit
declare	@bDueDatesRequired		bit
declare @bAllEventAndDueDatesRequired bit
declare @bAllEventsRequired		bit
declare @bRemindersLoaded		bit
declare @bRemindersRequired		bit
declare @bRenewalActionExtracted 	bit
declare	@bProvideInstructionsRequired	bit --RFC2982
declare	@bFeesRequired			bit --RFC2984
declare	@bOrderByDefined		bit --RFC9104
declare @bRowLevelSecurity		bit
declare @bCaseOffice			bit
Declare @bHasImageData          	bit
declare	@bHiddenColumn			bit
declare	@bHasFilePartColumn	        bit --RFC34938
declare	@bDueDateOnly			bit --RFC71701
declare @bEventDateOnly			bit --RFC71701


-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 				int 		

declare @nOutRequestsRowCount		int
declare @nCount				int

-- declare variables to store the parameters to be used in the Where filter
declare @bUseEventDates			bit
declare @bUseAdHocDates			bit
declare	@bUseDueDate			bit
declare	@bUseReminderDate		bit
declare	@bUseRelatedCase		bit
declare	@bIsRenewalsOnly		bit
declare	@bIsNonRenewalsOnly		bit
declare	@bIncludeClosedActions		bit
declare	@nDateRangeOperator		tinyint
declare	@nImportanceLevelOperator	tinyint
declare	@nPeriodRangeOperator		tinyint
declare	@nEventOperator			tinyint
declare @nActionOperator		tinyint
declare	@nPeriodRangeFrom		smallint
declare	@nPeriodRangeTo			smallint
declare @sEventKeys 			nvarchar(max)
declare @sActionKeys			nvarchar(1000)
declare	@dtDateRangeFrom		datetime
declare	@dtDateRangeTo			datetime
declare	@sPeriodRangeType		nvarchar(2)
declare	@sImportanceLevelFrom		nvarchar(50)
declare	@sImportanceLevelTo		nvarchar(2)
Declare	@nEventNoteTypeKeysOperator	tinyint
Declare	@sEventNoteTypeKeys		nvarchar(4000)	-- The Event Text Types required to be reported on.
Declare	@nEventNoteTextOperator		tinyint
Declare	@sEventNoteText			nvarchar(max)	-- The Event Text required to be reported on.
declare @sEventCategoryKeys		nvarchar(max)
declare @nEventCategoryKeyOperator	tinyint
declare @nEventStaffKey			int
declare @nEventStaffKeyOperator		tinyint
declare @bIsSignatory			bit
declare @bIsStaff			bit
declare @bIsAnyName			bit
declare @nNameTypeOperator		tinyint
declare @sNameTypeKey			nvarchar(1000)
declare @nNameOperator			tinyint
declare @sNameKey			nvarchar(3500)
declare @nNameGroupOperator		tinyint
declare @sNameGroupKey			nvarchar(1000)
declare @nStaffClassOperator		tinyint
declare @sStaffClassKey			nvarchar(1000)
declare	@nImpLevelFilterOperator	tinyint
declare	@sImpLevelFilterFrom		nvarchar(50)
declare	@sImpLevelFilterTo		nvarchar(2)
Declare	@sEventFilterKeys		nvarchar(max)
Declare @nEventDateFilterOperator	tinyint
Declare @bIsRenewalsOnlyFilter		bit
Declare @bIsNonRenewalsOnlyFilter	bit  
Declare	@bByDueDate 			bit		
Declare @bByEventDate 			bit
Declare @dtDateRangeFilterFrom		datetime
Declare @dtDateRangeFilterTo		datetime	
Declare @sPeriodType			nvarchar(2)	-- D - Days, W – Weeks, M – Months, Y - Years
Declare @nPeriodQuantity		smallint	-- May be positive or negative.  Always supplied in conjunction with Type.
declare @nProcessKey			int	

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		    		ID		nvarchar(100)	collate database_default not null,
		    		SORTORDER	tinyint		null,
		    		SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,
				EXTENDEDDATA	bit
			  )

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null, 
	HiddenColumn		bit		not null
			)

declare @sLanguage		varchar(10)

Declare @sLookupCulture		nvarchar(10)

-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @nCaseAccessSecurityFlag	int

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

-- Initialisation
set @ErrorCode			=0
set @nOutRequestsRowCount	=0
set @bOrderByDefined		=0	--RFC9104
set @nCount			=1
set @bRenewalActionExtracted	=0
set @sSelect			='S'
set @sFrom			='F'
set @sWhere			='W'
set @sUnionSelect		='U'
set @sUnionFrom			='V'
set @sUnionWhere		='X'
set @sOrderBy			='O'
set @sColumnOrderBy		='C'
set @sDelimiter			='^'
set @sReturn			=char(10)

set @sCurrentSelectString	=' Select '	-- SQA17562 Leading SPACE is essential for later REPLACE that creates UNION SELECT
set @sCurrentFromString		=' From CASES C with (NOLOCK)'
set @sCurrentWhereString	=char(10)+'	Where 1=1'

set @pnTableCount		=1
set @sLanguage 			= isnull(cast(dbo.fn_GetLanguage(isnull(@psCulture,'NULL')) as varchar(10)), 'NULL')
set @sLookupCulture		= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @bRowLevelSecurity		= 0
set @bCaseOffice		= 0
set @bHasImageData              = 0
set @bAnyRenewalAction		= 0
set @bAnyOpenAction		= 0
set @bHasImageData              = 0

-- Set the Case Security level to the default value.
If @ErrorCode=0
and @pbCalledFromCentura = 0
Begin
	SELECT @nCaseAccessSecurityFlag = ISNULL(SC.COLINTEGER,15)
	FROM SITECONTROL SC 
	WHERE SC.CONTROLID = 'Default Security'
	
	Set @ErrorCode = @@ERROR 
End


-- Check if user has been assigned row access security profile
If @ErrorCode = 0
and @pbCalledFromCentura = 0
Begin
	Select  @bRowLevelSecurity = 1,
		@bCaseOffice = ISNULL(SC.COLBOOLEAN, 0)
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R  WITH (NOLOCK)  on (R.ACCESSNAME = U.ACCESSNAME) 
	left join SITECONTROL SC WITH (NOLOCK) on (SC.CONTROLID = 'Row Security Uses Case Office')
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId
	
	Set @ErrorCode = @@ERROR 
End

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria 	

If @ErrorCode = 0 and datalength(@ptXMLFilterCriteria) > 0
Begin
        -- Retrieve the Event related filters that are to impact columns to be displayed.
	Set @sSQLString = 	
		"Select" +char(10)+
		"	@sEventFilterKeys		= EventKeys,"+CHAR(10)+
		"	@nEventDateFilterOperator	= EventDateOperator,"+CHAR(10)+
		"	@sPeriodType			= CASE WHEN PeriodType = 'D' THEN 'dd'"+CHAR(10)+
		"					       WHEN PeriodType = 'W' THEN 'wk'"+CHAR(10)+
		"					       WHEN PeriodType = 'M' THEN 'mm'"+CHAR(10)+
		"					       WHEN PeriodType = 'Y' THEN 'yy'"+CHAR(10)+
		"		   			  END,"+CHAR(10)+
		"	@nPeriodQuantity		= PeriodQuantity,"+CHAR(10)+
		"	@sEventNoteTypeKeys		= EventNoteTypeKeys,"+CHAR(10)+
		"	@nEventNoteTypeKeysOperator	= EventNoteTypeKeysOperator,"+CHAR(10)+
		"	@sEventNoteText			= EventNoteText,"+CHAR(10)+
		"	@nEventNoteTextOperator		= EventNoteTextOperator,"+CHAR(10)+	
		"	@bByDueDate			= ByDueDate,"+CHAR(10)+ 
		"	@bByEventDate			= ByEventDate,"+CHAR(10)+
		"	@bIsRenewalsOnlyFilter		= IsRenewalsOnly,"+CHAR(10)+
		"	@bIsNonRenewalsOnlyFilter	= IsNonRenewalsOnly,"+CHAR(10)+
		"	@dtDateRangeFilterFrom		= DateRangeFrom,"+CHAR(10)+
		"	@dtDateRangeFilterTo		= DateRangeTo,"+CHAR(10)+
		"	@nImpLevelFilterOperator	= ImportanceLevelOperator,"+char(10)+
		"	@sImpLevelFilterFrom		= ImportanceLevelFrom,"+char(10)+
		"	@sImpLevelFilterTo		= ImportanceLevelTo"+char(10)+
		"from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria[1]' ,2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+ 
		"	      EventKeys			nvarchar(max)	'Event/EventKey/text()',"+CHAR(10)+
		"	      EventDateOperator		tinyint		'Event/@Operator/text()',"+CHAR(10)+    
		"	      PeriodType		nvarchar(2)	'Event/Period/Type/text()',"+CHAR(10)+	
		"	      PeriodQuantity		smallint	'Event/Period/Quantity/text()',"+CHAR(10)+		
		"	      EventNoteTypeKeys		nvarchar(4000)	'Event/EventNoteTypeKeys/text()',"+CHAR(10)+
		"	      EventNoteTypeKeysOperator	tinyint		'Event/EventNoteTypeKeys/@Operator/text()',"+CHAR(10)+  	
		"	      EventNoteText		nvarchar(max)	'Event/EventNoteText/text()',"+CHAR(10)+
		"	      EventNoteTextOperator	tinyint		'Event/EventNoteText/@Operator/text()',"+CHAR(10)+  
		"	      ByDueDate			bit		'Event/@ByDueDate',"+CHAR(10)+
		"	      ByEventDate		bit		'Event/@ByEventDate',"+CHAR(10)+
		"	      IsRenewalsOnly		bit		'Event/@IsRenewalsOnly',"+CHAR(10)+
		"	      IsNonRenewalsOnly		bit		'Event/@IsNonRenewalsOnly',"+CHAR(10)+
		"	      DateRangeFrom		datetime	'Event/DateRange/From/text()',"+CHAR(10)+
		"	      DateRangeTo		datetime	'Event/DateRange/To/text()',"+CHAR(10)+	 
		"	      ImportanceLevelOperator	tinyint		'Event/ImportanceLevel/@Operator/text()',"+char(10)+
		"	      ImportanceLevelFrom	nvarchar(2)	'Event/ImportanceLevel/From/text()',"+char(10)+
		"	      ImportanceLevelTo		nvarchar(2)	'Event/ImportanceLevel/To/text()'"+char(10)+
		"	     )"

	exec @ErrorCode = sp_executesql @sSQLString,
		N'@idoc				int,
		  @sEventFilterKeys		nvarchar(max)			output,
		  @nEventDateFilterOperator	tinyint				output,
		  @sPeriodType			nvarchar(2)			output,
		  @nPeriodQuantity		smallint			output,
		  @sEventNoteTypeKeys		nvarchar(4000)			output,
		  @nEventNoteTypeKeysOperator	tinyint				output,
		  @sEventNoteText		nvarchar(max)			output,
		  @nEventNoteTextOperator	tinyint				output,
		  @bByDueDate			bit				output,
		  @bByEventDate			bit				output,
		  @bIsRenewalsOnlyFilter	bit				output,
		  @bIsNonRenewalsOnlyFilter	bit				output,
		  @dtDateRangeFilterFrom	datetime			output,
		  @dtDateRangeFilterTo		datetime			output,
		  @nImpLevelFilterOperator	tinyint				output,
		  @sImpLevelFilterFrom		nvarchar(2)			output,
		  @sImpLevelFilterTo		nvarchar(2)			output',
		  @idoc				= @idoc,
		  @sEventFilterKeys		= @sEventFilterKeys		output,
		  @nEventDateFilterOperator	= @nEventDateFilterOperator	output,
		  @sPeriodType			= @sPeriodType			output,
		  @nPeriodQuantity		= @nPeriodQuantity		output,
		  @sEventNoteTypeKeys		= @sEventNoteTypeKeys		output,
		  @nEventNoteTypeKeysOperator	= @nEventNoteTypeKeysOperator	output,
		  @sEventNoteText		= @sEventNoteText		output,
		  @nEventNoteTextOperator	= @nEventNoteTextOperator	output,
		  @bByDueDate			= @bByDueDate			output,
		  @bByEventDate			= @bByEventDate			output,
		  @bIsRenewalsOnlyFilter	= @bIsRenewalsOnlyFilter	output,
		  @bIsNonRenewalsOnlyFilter	= @bIsNonRenewalsOnlyFilter	output,
		  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom	output,
		  @dtDateRangeFilterTo		= @dtDateRangeFilterTo		output,
		  @nImpLevelFilterOperator	= @nImpLevelFilterOperator	output,
		  @sImpLevelFilterFrom		= @sImpLevelFilterFrom		output,
		  @sImpLevelFilterTo		= @sImpLevelFilterTo		output
End



If PATINDEX ('%<GlobalProcessKey>%', @ptXMLFilterCriteria)>0
and @ErrorCode=0
Begin
	--------------------------------------------------------------
	-- If the Filter makes reference to Global Process Key
	-- then we need to ensure that the GLOBALCASECHANGERESULTS
	-- table is included, even if no specific column is requested
	-- to be returned in the Select list.
	--------------------------------------------------------------					
	Set @sAddFromString = 'Left Join GLOBALCASECHANGERESULTS GCR	on (GCR.CASEID = C.CASEID)'

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentFromString	OUTPUT,
				@psAddString	=@sAddFromString,
				@psComponentType=@sFrom,
				@psSeparator    =@sReturn,
				@pbForceLoad=0

	Set @pnTableCount=@pnTableCount+1
End

-- Extract the filtering details that are to be applied to the extracted columns as opposed
-- to the filtering that applies to the result set.

If PATINDEX ('%<ColumnFilterCriteria>%', @ptXMLFilterCriteria)>0
and @ErrorCode=0
Begin
	
	Set @sSQLString = 	
	"Select @bUseEventDates			= UseEventDates,"+CHAR(10)+
	"	@bUseAdHocDates			= UseAdHocDates,"+CHAR(10)+
	"	@bUseDueDate			= UseDueDate,"+CHAR(10)+
	"	@bUseReminderDate		= UseReminderDate,"+CHAR(10)+
	"	@nDateRangeOperator		= DateRangeOperator,"+char(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+char(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+char(10)+
	"	@nPeriodRangeOperator		= PeriodRangeOperator,"+CHAR(10)+
	"	@sPeriodRangeType		= PeriodRangeType,"+CHAR(10)+
	"	@nPeriodRangeFrom		= PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo			= PeriodRangeTo,"+CHAR(10)+
	"	@bIsRenewalsOnly		= IsRenewalsOnly,"+CHAR(10)+
	"	@bIsNonRenewalsOnly		= IsNonRenewalsOnly,"+CHAR(10)+
	"	@bIncludeClosedActions		= IncludeClosed,"+CHAR(10)+
	"	@nActionOperator		= ActionOperator,"+CHAR(10)+
	"	@sActionKeys			= ActionKey,"+CHAR(10)+
	"	@nImportanceLevelOperator	= ImportanceLevelOperator,"+CHAR(10)+
	"	@sImportanceLevelFrom		= ImportanceLevelFrom,"+CHAR(10)+
	"	@sImportanceLevelTo		= ImportanceLevelTo,"+CHAR(10)+
	"	@nEventOperator			= EventOperator,"+CHAR(10)+
	"	@sEventKeys			= EventKey,"+CHAR(10)+
	"	@sEventCategoryKeys		= EventCategoryKey,"+CHAR(10)+
	"	@nEventCategoryKeyOperator	= EventCategoryKeyOperator,"+CHAR(10)+
	"	@nEventStaffKey			= EventStaffKey,"+CHAR(10)+
	"	@nEventStaffKeyOperator		= EventStaffKeyOperator,"+CHAR(10)+
	"	@sEventNoteTypeKeys		= EventNoteTypeKeys,"+CHAR(10)+
	"	@nEventNoteTypeKeysOperator	= EventNoteTypeKeysOperator,"+CHAR(10)+
	"	@sEventNoteText			= EventNoteText,"+CHAR(10)+
	"	@nEventNoteTextOperator		= EventNoteTextOperator,"+CHAR(10)+
	"	@bIsSignatory			= IsSignatory,"+CHAR(10)+
	"	@bIsStaff			= IsStaff,"+CHAR(10)+
	"	@bIsAnyName			= IsAnyName,"+CHAR(10)+
	"	@nNameTypeOperator		= NameTypeOperator,"+CHAR(10)+
	"	@sNameTypeKey			= NameTypeKey,"+CHAR(10)+
	"	@nNameOperator			= NameOperator,"+CHAR(10)+
	"	@sNameKey			= NameKey,"+CHAR(10)+
	"	@nNameGroupOperator		= NameGroupOperator,"+CHAR(10)+
	"	@sNameGroupKey			= NameGroupKey,"+CHAR(10)+
	"	@nStaffClassOperator		= StaffClassOperator,"+CHAR(10)+
	"	@sStaffClassKey			= StaffClassKey"+CHAR(10)+
	"from	OPENXML (@idoc, '/csw_ListCase/ColumnFilterCriteria/DueDates',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      UseEventDates		bit		'@UseEventDates',"+CHAR(10)+
	"	      UseAdHocDates		bit		'@UseAdHocDates',"+CHAR(10)+
	"	      UseDueDate		bit		'Dates/@UseDueDate',"+CHAR(10)+
	"	      UseReminderDate		bit		'Dates/@UseReminderDate',"+CHAR(10)+
	"	      DateRangeOperator		tinyint		'Dates/DateRange/@Operator/text()',"+char(10)+
	"	      DateRangeFrom		datetime	'Dates/DateRange/From/text()',"+char(10)+
	"	      DateRangeTo		datetime	'Dates/DateRange/To/text()',"+char(10)+
	"	      PeriodRangeOperator	tinyint		'Dates/PeriodRange/@Operator/text()',"+char(10)+
	"	      PeriodRangeType		nchar(1)	'Dates/PeriodRange/Type/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'Dates/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'Dates/PeriodRange/To/text()',"+CHAR(10)+
	"	      IsRenewalsOnly		bit		'Actions/@IsRenewalsOnly',"+CHAR(10)+
	"	      IsNonRenewalsOnly		bit		'Actions/@IsNonRenewalsOnly',"+CHAR(10)+
	"	      IncludeClosed		bit		'Actions/@IncludeClosed',"+CHAR(10)+
	"	      ActionOperator		tinyint		'Actions/ActionKey/@Operator/text()',"+CHAR(10)+
	"	      ActionKey			nvarchar(1000)	'Actions/ActionKey/text()',"+CHAR(10)+
	"	      ImportanceLevelOperator	tinyint		'ImportanceLevel/@Operator/text()',"+CHAR(10)+
	"	      ImportanceLevelFrom	nvarchar(50)	'ImportanceLevel/From/text()',"+CHAR(10)+
	"	      ImportanceLevelTo		nvarchar(2)	'ImportanceLevel/To/text()',"+CHAR(10)+
	"	      EventOperator		tinyint		'EventKey/@Operator/text()',"+CHAR(10)+
	"	      EventKey			nvarchar(max)	'EventKey/text()',"+CHAR(10)+
	"	      EventCategoryKey		nvarchar(max)	'EventCategoryKey/text()',"+CHAR(10)+
	"	      EventCategoryKeyOperator	tinyint		'EventCategoryKey/@Operator/text()',"+CHAR(10)+
	"	      EventStaffKey		int		'EventStaffKey/text()',"+CHAR(10)+
	"	      EventStaffKeyOperator	tinyint		'EventStaffKey/@Operator/text()',"+CHAR(10)+
	"	      EventNoteTypeKeys		nvarchar(4000)	'EventNoteTypeKeys/text()',"+CHAR(10)+
	"	      EventNoteTypeKeysOperator	tinyint		'EventNoteTypeKeys/@Operator/text()',"+CHAR(10)+  	
	"	      EventNoteText		nvarchar(max)	'EventNoteText/text()',"+CHAR(10)+
	"	      EventNoteTextOperator	tinyint		'EventNoteText/@Operator/text()',"+CHAR(10)+
	"	      IsSignatory		bit		'DueDateResponsibilityOf/@IsSignatory',"+CHAR(10)+
	"	      IsStaff			bit		'DueDateResponsibilityOf/@IsStaff',"+CHAR(10)+
	"	      IsAnyName			bit		'DueDateResponsibilityOf/@IsAnyName',"+CHAR(10)+
	"	      NameTypeOperator		tinyint		'DueDateResponsibilityOf/NameTypeKey/@Operator/text()',"+CHAR(10)+
	"	      NameTypeKey		nvarchar(1000)	'DueDateResponsibilityOf/NameTypeKey/text()',"+CHAR(10)+
	"	      NameOperator		tinyint		'DueDateResponsibilityOf/NameKey/@Operator/text()',"+CHAR(10)+
	"	      NameKey			nvarchar(3500)	'DueDateResponsibilityOf/NameKey/text()',"+CHAR(10)+
	"	      NameGroupOperator		tinyint		'DueDateResponsibilityOf/NameGroupKey/@Operator/text()',"+CHAR(10)+
	"	      NameGroupKey		nvarchar(1000)	'DueDateResponsibilityOf/NameGroupKey/text()',"+CHAR(10)+
	"	      StaffClassOperator	tinyint		'DueDateResponsibilityOf/StaffClassificationKey/@Operator/text()',"+CHAR(10)+
	"	      StaffClassKey		nvarchar(1000)	'DueDateResponsibilityOf/StaffClassificationKey/text()'"+CHAR(10)+
     	"	     )"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @bUseEventDates		bit		output,
				  @bUseAdHocDates		bit		output,
				  @bUseDueDate			bit		output,
				  @bUseReminderDate		bit		output,
				  @nDateRangeOperator		tinyint		output,
				  @dtDateRangeFrom		datetime	output,
				  @dtDateRangeTo		datetime	output,
				  @nPeriodRangeOperator		tinyint		output,
				  @sPeriodRangeType		nchar(1)	output,
				  @nPeriodRangeFrom		smallint	output,
				  @nPeriodRangeTo		smallint	output,
				  @bIsRenewalsOnly		bit		output,
				  @bIsNonRenewalsOnly		bit		output,
				  @bIncludeClosedActions	bit		output,
				  @nActionOperator		tinyint		output,
				  @sActionKeys			nvarchar(1000)	output,
				  @nImportanceLevelOperator	tinyint		output,
				  @sImportanceLevelFrom		nvarchar(50)	output,
				  @sImportanceLevelTo		nvarchar(2)	output,
				  @nEventOperator		tinyint		output,
				  @sEventKeys			nvarchar(max)	output,
				  @sEventCategoryKeys		nvarchar(max)	output,
				  @nEventCategoryKeyOperator	tinyint		output,
				  @nEventStaffKey		int		output,
				  @nEventStaffKeyOperator	tinyint		output,
				  @sEventNoteTypeKeys		nvarchar(4000)	output,
				  @nEventNoteTypeKeysOperator	tinyint		output,
				  @sEventNoteText		nvarchar(max)	output,
				  @nEventNoteTextOperator	tinyint		output,
				  @bIsSignatory			bit		output,
				  @bIsStaff			bit		output,
				  @bIsAnyName			bit		output,
				  @nNameTypeOperator		tinyint		output,
				  @sNameTypeKey			nvarchar(1000)	output,
				  @nNameOperator		tinyint		output,
				  @sNameKey			nvarchar(3500)	output,
				  @nNameGroupOperator		tinyint		output,
				  @sNameGroupKey		nvarchar(1000)	output,
				  @nStaffClassOperator		tinyint		output,
				  @sStaffClassKey		nvarchar(1000)	output',
				  @idoc				= @idoc,
				  @bUseEventDates		= @bUseEventDates		output,
				  @bUseAdHocDates		= @bUseAdHocDates		output,
				  @bUseDueDate			= @bUseDueDate			output,
				  @bUseReminderDate		= @bUseReminderDate		output,
				  @nDateRangeOperator		= @nDateRangeOperator		output,
				  @dtDateRangeFrom		= @dtDateRangeFrom		output,
				  @dtDateRangeTo		= @dtDateRangeTo		output,
				  @nPeriodRangeOperator		= @nPeriodRangeOperator		output,
				  @sPeriodRangeType		= @sPeriodRangeType		output,
				  @nPeriodRangeFrom		= @nPeriodRangeFrom		output,
				  @nPeriodRangeTo		= @nPeriodRangeTo		output,
				  @bIsRenewalsOnly		= @bIsRenewalsOnly		output,
				  @bIsNonRenewalsOnly		= @bIsNonRenewalsOnly		output,
				  @bIncludeClosedActions	= @bIncludeClosedActions	output,
				  @nActionOperator		= @nActionOperator		output,
				  @sActionKeys			= @sActionKeys			output,
				  @nImportanceLevelOperator	= @nImportanceLevelOperator	output,
				  @sImportanceLevelFrom		= @sImportanceLevelFrom		output,
				  @sImportanceLevelTo		= @sImportanceLevelTo		output,
				  @nEventOperator		= @nEventOperator		output,
				  @sEventKeys			= @sEventKeys			output,
				  @sEventCategoryKeys		= @sEventCategoryKeys		output,
				  @nEventCategoryKeyOperator  	= @nEventCategoryKeyOperator	output,
				  @nEventStaffKey		= @nEventStaffKey		output,
				  @nEventStaffKeyOperator	= @nEventStaffKeyOperator	output,
				  @sEventNoteTypeKeys		= @sEventNoteTypeKeys		output,
				  @nEventNoteTypeKeysOperator	= @nEventNoteTypeKeysOperator	output,
				  @sEventNoteText		= @sEventNoteText		output,
				  @nEventNoteTextOperator	= @nEventNoteTextOperator	output,
				  @bIsSignatory			= @bIsSignatory			output,
				  @bIsStaff			= @bIsStaff			output,
				  @bIsAnyName			= @bIsAnyName			output,
				  @nNameTypeOperator		= @nNameTypeOperator		output,
				  @sNameTypeKey			= @sNameTypeKey			output,
				  @nNameOperator		= @nNameOperator		output,
				  @sNameKey			= @sNameKey			output,
				  @nNameGroupOperator		= @nNameGroupOperator		output,
				  @sNameGroupKey		= @sNameGroupKey		output,
				  @nStaffClassOperator		= @nStaffClassOperator		output,
				  @sStaffClassKey		= @sStaffClassKey		output

	If @dtDateRangeFrom  is not null
	or @dtDateRangeTo    is not null
	or @sPeriodRangeType is not null
	or @nPeriodRangeFrom is not null
	Begin
		If @bUseDueDate=1
			Set @bDueDatesRequired=1

		If @bUseReminderDate=1
			Set @bRemindersRequired=1
	End
End

-- deallocate the xml document handle when finished.
exec sp_xml_removedocument @idoc

-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
If datalength(@ptXMLOutputRequests) = 0
or datalength(@ptXMLOutputRequests) is null
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 2)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, EXTENDEDDATA)
	Select F.ROWNUMBER, F.COLUMNID, F.SORTORDER, F.SORTDIRECTION, F.PUBLISHNAME, F.QUALIFIER, 
	CASE WHEN(Q.QUALIFIERTYPE=12 
	       OR F.DOCITEMKEY is not NULL
	       OR F.COLUMNID in ('InstructionBillCurrencyAny',
				 'InstructionCycleAny',
				 'InstructionDefinitionAny',
				 'InstructionDefinitionKeyAny',
				 'InstructionDueDateAny',
				 'InstructionDueEventAny',
				 'InstructionIsPastDueAny',
				 'InstructionExplanationAny',
				 'InstructionFeeBilledAny',
				 'ChargeDueEventAny',
				 'FeeBillCurrencyAny',
				 'FeeBilledAmountAny',
				 'FeeBilledPerYearAny',
				 'FeeDueDateAny',
				 'FeesChargeTypeAny',
				 'FeeYearNoAny'))
		THEN 1 ELSE 0 
	END
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null) F
	left join QUERYDATAITEM Q	on (Q.PROCEDURENAME='csw_ListCase'
					and Q.PROCEDUREITEMID=F.COLUMNID)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End
Else
--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, EXTENDEDDATA)
	Select  F.ROWNUMBER, F.COLUMNID, F.SORTORDER, F.SORTDIRECTION, F.PUBLISHNAME, F.QUALIFIER,
	CASE WHEN(Q.QUALIFIERTYPE=12 
	       OR F.DOCITEMKEY is not NULL
	       OR F.COLUMNID in ('InstructionBillCurrencyAny',
				 'InstructionCycleAny',
				 'InstructionDefinitionAny',
				 'InstructionDefinitionKeyAny',
				 'InstructionDueDateAny',
				 'InstructionDueEventAny',
				 'InstructionIsPastDueAny',
				 'InstructionExplanationAny',
				 'InstructionFeeBilledAny',
				 'ChargeDueEventAny',
				 'FeeBillCurrencyAny',
				 'FeeBilledAmountAny',
				 'FeeBilledPerYearAny',
				 'FeeDueDateAny',
				 'FeesChargeTypeAny',
				 'FeeYearNoAny'))
		THEN 1 ELSE 0 
	END
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null) F
	left join QUERYDATAITEM Q	on (Q.PROCEDURENAME='csw_ListCase'
					and Q.PROCEDUREITEMID=F.COLUMNID)
	
	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @ErrorCode=0
Begin
	-- Get the ColumnID, Name of the column to be published (@sPublishName), the position of the Column 
	-- in the Order By clause (@nOrderPosition), the direction of the sort (@sOrderDirection),
	-- Qualifier to be used to get the column (@sQualifier)   
	Select	@nColumnNo 		= ROWNUMBER,
		@sColumn   		= ID,
		@sPublishName 		= PUBLISHNAME,
		@nOrderPosition		= SORTORDER,
		@sOrderDirection	= CASE WHEN SORTORDER > 0 THEN SORTDIRECTION
					       ELSE NULL
					  END,
		@sQualifier		= QUALIFIER,
		@bExtendedData		= EXTENDEDDATA
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount
	---------------------------------------------
	-- If there is no @sPublishName value then 
	-- the column has been included for sorting.
	-- We will generate a name for these to use
	-- in the ORDER BY so we can still use a 
	-- DISTINCT clause on the result set.
	---------------------------------------------
	If @sPublishName is not null
	Begin
		Set @bHiddenColumn=0
	End
	Else Begin
		Set @bHiddenColumn=1
		If @nOrderPosition is not null
			Set @sPublishName='SortColumn'+cast(@nOrderPosition as nvarchar)
	End

	-- Certain columns require the Action used by renewals which is held in a SiteControl
	If  @ErrorCode=0
	and @bRenewalActionExtracted=0
	and @sColumn in ('EarliestDueDate', 'EarliestDueEvent', 'OpenEventOrDue', 'OpenRenewalEventOrDue',
			 'AgeOfCase','NextRenewalDate','DueDateDescription','DueDate','DueDateCycle','DueDateImportance','DueDateNotes',
 			 'DueEventCategory','DueEventCategoryIconKey','DueEventNo','DueEventStaffKey', 'DueEventStaff',
			 'DueEventStaffCode','DueDateResp','EventDueDate','DueDescriptionLatestInGroup','DueDateLatestInGroup','DueDateLastModified',
			 'NextDueDate', 'NextDueEvent', 'NextDueEventNo', 'NextDueText')
	Begin
		Set @sSQLString="
		Select @sRenewalAction=S.COLCHARACTER
		from SITECONTROL S
		where CONTROLID='Main Renewal Action'"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sRenewalAction	nvarchar(2)	OUTPUT',
					  @sRenewalAction=@sRenewalAction	OUTPUT

		Set @bRenewalActionExtracted=1

		If exists(select 1 from SITECONTROL with (NOLOCK) where CONTROLID='Renewal Search on Any Action' and COLBOOLEAN=1)
		and @ErrorCode=0
		Begin
			Set @bAnyRenewalAction=1
		End

		If exists(select 1 from SITECONTROL with (NOLOCK) where CONTROLID='Any Open Action for Due Date' and COLBOOLEAN=1)
		and @ErrorCode=0
		Begin
			Set @bAnyOpenAction=1
		End
	End

	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If  @ErrorCode=0
	and @sQualifier is null
	Begin
		Set @sCorrelationSuffix=NULL
	End
	Else Begin	
		----------------------------------------
		-- Translate the descriptive name of the
		-- Event Text Type into its interal id
		-- when it is used as the qualifier.
		----------------------------------------
		If @sColumn in ('DatesTextAnyOfType',
				'DatesTextAnyOfTypeModifiedDate')
		Begin					
			Select @sQualifier=cast(EVENTTEXTTYPEID as nvarchar)
			From EVENTTEXTTYPE
			where DESCRIPTION=@sQualifier	
		End
		
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End
		
	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.

	If @ErrorCode=0
	Begin
		If  @bExtendedData=1		-- SQA9662
		and @psTempTableName is not null
		Begin
			-- There are a set of columns processed as extended data which must have
			-- hardcoded column names in order to allow cs_ListCaseCharges to
			-- populate the appropriate column
			Set @sTableColumn   = 	CASE WHEN(@sColumn in (	'InstructionBillCurrencyAny',
									'InstructionCycleAny',
									'InstructionDefinitionAny',
									'InstructionDefinitionKeyAny',
									'InstructionDueDateAny',
									'InstructionDueEventAny',
									'InstructionIsPastDueAny',
									'InstructionExplanationAny',
									'InstructionFeeBilledAny',
									'ChargeDueEventAny',
									'FeeBillCurrencyAny',
									'FeeBilledAmountAny',
									'FeeBilledPerYearAny',
									'FeeDueDateAny',
									'FeesChargeTypeAny',
									'FeeYearNoAny'))
						   THEN 'TT.'+@sColumn
							-- RFC4010 when the column name has quotes around it, 
							-- WorkBenches returns it as a literal instead of the 
							-- contents of the column.  However, client/server 
							-- requires the quotes to handle special characters - See SQA11738.
						   ELSE CASE WHEN @pbCalledFromCentura = 0 
								THEN '['+@sPublishName+']' 
								ELSE '"'+@sPublishName+'"'
							END
						END
			Set @sAddFromString = 'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0	

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='NULL'		-- RFC13
		Begin
			Set @sTableColumn='NULL'
		End

		Else If @sColumn='CaseCategoryCode'
		Begin
			Set @sTableColumn='C.CASECATEGORY'
		End

		Else If @sColumn='CaseFamilyReference'
		Begin
			Set @sTableColumn='C.FAMILY'
		End

		Else If @sColumn='CaseKey'
		Begin
			Set @sTableColumn='C.CASEID'
		End

		Else If @sColumn='CaseTypeKey'
		Begin
			Set @sTableColumn='C.CASETYPE'
		End
		
		Else If @sColumn='PropertyTypeKey'
		Begin
			Set @sTableColumn='C.PROPERTYTYPE'
		End
		
		Else If @sColumn='StatusKey'
		Begin
			Set @sTableColumn='C.STATUSCODE'
		End

		Else If @sColumn='CasePurchaseOrderNo'
		Begin
			Set @sTableColumn='C.PURCHASEORDERNO'
		End

		Else If @sColumn='CaseReference'
		Begin
			Set @sTableColumn='C.IRN'
		End
		
		Else If @sColumn='CaseReferenceStem'
		Begin
			Set @sTableColumn='LEFT(C.STEM, CASE WHEN(C.STEM LIKE ''%~%'') THEN PATINDEX(''%~%'',C.STEM)-1 ELSE 30 END)' -- Only return characters up to the "~" delimiter
		End

		Else If @sColumn='CurrentOfficialNumber'
		Begin
			Set @sTableColumn='C.CURRENTOFFICIALNO'
		End

		Else If @sColumn='IntClasses'
		Begin
			If @pbCalledFromCentura=0
			Begin
				Set @sTableColumn = 'CASE WHEN(C.INTCLASSES is not null) THEN REPLACE(C.INTCLASSES, '','', '', '') END'
			End
			Else
			Begin
				Set @sTableColumn='C.INTCLASSES'
			End
		End
		
		Else If @sColumn='IsLocalClient'
		Begin
			Set @sTableColumn='cast(C.LOCALCLIENTFLAG as bit)'
		End

		Else If @sColumn='LocalClasses'
		Begin
			If @pbCalledFromCentura=0
			Begin
				Set @sTableColumn = 'CASE WHEN(C.LOCALCLASSES is not null) THEN REPLACE(C.LOCALCLASSES, '','', '', '') END'
			End
			Else
			Begin
				Set @sTableColumn='C.LOCALCLASSES'
			End			
		End

		Else If @sColumn='LocalClassIndicator'
		Begin
			Set @sTableColumn='CASE WHEN(C.LOCALCLASSES is not null) THEN 1 WHEN(C.INTCLASSES is not null) THEN 0 END'
		End

		Else If @sColumn='NoInSeries'
		Begin
			Set @sTableColumn='C.NOINSERIES'
		End

		Else If @sColumn='NoOfClasses'
		Begin
			Set @sTableColumn='C.NOOFCLASSES'
		End

		Else If @sColumn='ShortTitle'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura) 
		End

		Else If @sColumn='ReportToThirdParty'
		Begin 
			Set @sTableColumn='Cast(isnull(C.REPORTTOTHIRDPARTY,0) as bit)'
		End

		Else If @sColumn='Budget'
		Begin 
			Set @sTableColumn='C.BUDGETAMOUNT'
		End

		Else If @sColumn in ('CountryCode', 'MapCountryCode')
		Begin 
			Set @sTableColumn='C.COUNTRYCODE'
		End

		Else If @sColumn='LastAccessed'
		and @sQualifier is not null 
		Begin
			Set @sTableColumn='IX.LASTACCESSED'

			Set @sAddFromString = 'join IDENTITYINDEX IX'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "join IDENTITYINDEX IX WITH (NOLOCK) on (IX.IDENTITYID = " + convert(varchar,@pnUserIdentityId)
					   +char(10)+"	                   		and IX.INDEXID = " + @sQualifier + ")"
					   +char(10)+"	                   		and IX.COLINTEGER = C.CASEID"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0	

				Set @pnTableCount=@pnTableCount+1
			End
		
		End

		Else If @sColumn='ClientReference'
		     and @pbExternalUser=1	-- Data only available for External Users
		Begin
			Set @sTableColumn='XFC.CLIENTREFERENCENO'
			Set @sAddFromString = 'Join #TEMPCASESEXT'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = 'Join #TEMPCASESEXT XFC		on (XFC.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0	

				Set @pnTableCount=@pnTableCount+1
			End
		
		End

		Else If @sColumn in ('BudgetCurrencyCode', 'BilledCurrencyCode', 'LocalCurrencyCode')
		Begin
			Set @sTableColumn='SCUR.COLCHARACTER'
			Set @sAddFromString = 'Left Join SITECONTROL SCUR with (NOLOCK) on (SCUR.CONTROLID = ''CURRENCY'')'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End				
		
		Else If @sColumn='BudgetUtilisedPercent'
		Begin
			Set @sTableColumn=	  "CASE WHEN C.BUDGETAMOUNT IS NULL"
		     			+char(10)+"	        THEN NULL"
		     			+char(10)+"		ELSE convert(int, round(Billed.nBilledToDate /CASE WHEN C.BUDGETAMOUNT = 0" 
					+char(10)+"	    		 					   THEN 1"
					+char(10)+"	    		 					   ELSE C.BUDGETAMOUNT "
					+char(10)+"       		    				      END * 100,0))"
					+char(10)+"	   END"	
			Set @sAddFromString = 'Left Join (Select FNWH.CASEID,'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = " Left Join (Select FNWH.CASEID,"						
						+char(10)+"              sum(-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) AS nBilledToDate,"
						+char(10)+"              sum(CASE WHEN WT.CATEGORYCODE = 'SC'"
						+char(10)+"			  THEN (-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1)))" 
						+char(10)+"			  ELSE 0" 
						+char(10)+"		     END) AS nServicesBilled"
						+char(10)+"      from OPENITEM OI"
						+char(10)+"      join WORKHISTORY FNWH 		on (FNWH.REFENTITYNO = OI.ITEMENTITYNO"   
						+char(10)+"					and FNWH.REFTRANSNO  = OI.ITEMTRANSNO"   
						+char(10)+"					and FNWH.MOVEMENTCLASS = 2)"		
						+char(10)+" Left Join WIPTEMPLATE WTP 		on (WTP.WIPCODE = FNWH.WIPCODE)"
						+char(10)+" Left Join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)"
						+char(10)+"      where OI.STATUS = 1 "						
						+char(10)+"      group by FNWH.CASEID) Billed	on (Billed.CASEID = C.CASEID"	
						+char(10)+"					and ( C.BUDGETAMOUNT IS NOT NULL"
						+char(10)+" 					 or Billed.nBilledToDate IS NOT NULL"
						+char(10)+" 					 or Billed.nServicesBilled IS NOT NULL))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+5
			End
								
		End		

		Else If @sColumn='BilledTotal'
		Begin
			Set @sTableColumn= "cast(Billed.nBilledToDate as decimal(11,2))"
			Set @sAddFromString = 'Left Join (Select FNWH.CASEID,'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin				
				Set @sAddFromString = " Left Join (Select FNWH.CASEID,"						
						+char(10)+"              sum(-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) AS nBilledToDate,"
						+char(10)+"              sum(CASE WHEN WT.CATEGORYCODE = 'SC'"
						+char(10)+"			  THEN (-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1)))" 
						+char(10)+"			  ELSE 0" 
						+char(10)+"		     END) AS nServicesBilled"
						+char(10)+"      from OPENITEM OI"
						+char(10)+"      join WORKHISTORY FNWH 		on (FNWH.REFENTITYNO = OI.ITEMENTITYNO"   
						+char(10)+"					and FNWH.REFTRANSNO  = OI.ITEMTRANSNO"   
						+char(10)+"					and FNWH.MOVEMENTCLASS = 2)"		
						+char(10)+" Left Join WIPTEMPLATE WTP 		on (WTP.WIPCODE = FNWH.WIPCODE)"
						+char(10)+" Left Join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)"
						+char(10)+"      where OI.STATUS = 1 "						
						+char(10)+"      group by FNWH.CASEID) Billed	on (Billed.CASEID = C.CASEID"	
						+char(10)+"					and ( C.BUDGETAMOUNT IS NOT NULL"
						+char(10)+" 					 or Billed.nBilledToDate IS NOT NULL"
						+char(10)+" 					 or Billed.nServicesBilled IS NOT NULL))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0


				Set @pnTableCount=@pnTableCount+5
			End								
		End	

		Else If @sColumn='ServicesBilledTotal'
		Begin
			Set @sTableColumn= "cast(Billed.nServicesBilled as decimal(11,2))"
			Set @sAddFromString = 'Left Join (Select FNWH.CASEID,'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = " Left Join (Select FNWH.CASEID,"						
						+char(10)+"              sum(-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) AS nBilledToDate,"
						+char(10)+"              sum(CASE WHEN WT.CATEGORYCODE = 'SC'"
						+char(10)+"			  THEN (-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1)))" 
						+char(10)+"			  ELSE 0" 
						+char(10)+"		     END) AS nServicesBilled"
						+char(10)+"      from OPENITEM OI"
						+char(10)+"      join WORKHISTORY FNWH 		on (FNWH.REFENTITYNO = OI.ITEMENTITYNO"   
						+char(10)+"					and FNWH.REFTRANSNO  = OI.ITEMTRANSNO"   
						+char(10)+"					and FNWH.MOVEMENTCLASS = 2)"		
						+char(10)+" Left Join WIPTEMPLATE WTP 		on (WTP.WIPCODE = FNWH.WIPCODE)"
						+char(10)+" Left Join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)"
						+char(10)+"      where OI.STATUS = 1 "						
						+char(10)+"      group by FNWH.CASEID) Billed	on (Billed.CASEID = C.CASEID"	
						+char(10)+"					and ( C.BUDGETAMOUNT IS NOT NULL"
						+char(10)+" 					 or Billed.nBilledToDate IS NOT NULL"
						+char(10)+" 					 or Billed.nServicesBilled IS NOT NULL))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+5
			End								
		End	

		Else If @sColumn='ServicesBilledPercent'
		Begin
			Set @sTableColumn= 	  "convert(int, round(Billed.nServicesBilled/CASE WHEN Billed.nBilledToDate = 0" 
					+char(10)+"    	         				  THEN 1" 
					+char(10)+"    	         				  ELSE Billed.nBilledToDate"  
				       	+char(10)+"	    				     END * 100,0))"
			Set @sAddFromString = 'Left Join (Select FNWH.CASEID,'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = " Left Join (Select FNWH.CASEID,"						
						+char(10)+"              sum(-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1))) AS nBilledToDate,"
						+char(10)+"              sum(CASE WHEN WT.CATEGORYCODE = 'SC'"
						+char(10)+"			  THEN (-FNWH.LOCALTRANSVALUE * (isnull(OI.BILLPERCENTAGE/100, 1)))" 
						+char(10)+"			  ELSE 0" 
						+char(10)+"		     END) AS nServicesBilled"
						+char(10)+"      from OPENITEM OI"
						+char(10)+"      join WORKHISTORY FNWH 		on (FNWH.REFENTITYNO = OI.ITEMENTITYNO"   
						+char(10)+"					and FNWH.REFTRANSNO  = OI.ITEMTRANSNO"   
						+char(10)+"					and FNWH.MOVEMENTCLASS = 2)"		
						+char(10)+" Left Join WIPTEMPLATE WTP 		on (WTP.WIPCODE = FNWH.WIPCODE)"
						+char(10)+" Left Join WIPTYPE WT 		on (WT.WIPTYPEID = WTP.WIPTYPEID)"
						+char(10)+"      where OI.STATUS = 1 "						
						+char(10)+"      group by FNWH.CASEID) Billed	on (Billed.CASEID = C.CASEID"	
						+char(10)+"					and ( C.BUDGETAMOUNT IS NOT NULL"
						+char(10)+" 					 or Billed.nBilledToDate IS NOT NULL"
						+char(10)+" 					 or Billed.nServicesBilled IS NOT NULL))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+5
			End								
		End	
		
		Else If @sColumn in ('FirstUseClass')
		Begin
			Set @sTableColumn='CLF.CLASS'
			Set @sAddFromString = 'Left Join CLASSFIRSTUSE CLF'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join CLASSFIRSTUSE CLF with (NOLOCK) on (CLF.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('FirstUseDate')
		Begin
			Set @sTableColumn='CLF.FIRSTUSE'
			Set @sAddFromString = 'Left Join CLASSFIRSTUSE CLF'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join CLASSFIRSTUSE CLF with (NOLOCK) on (CLF.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('FirstUseCommerceDate')
		Begin
			Set @sTableColumn='CLF.FIRSTUSEINCOMMERCE'
			Set @sAddFromString = 'Left Join CLASSFIRSTUSE CLF'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join CLASSFIRSTUSE CLF with (NOLOCK) on (CLF.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End
		
		Else If @sColumn='ClientContactKey'
		     and @pbExternalUser=1	-- Data only available for External Users
		Begin
			Set @sTableColumn='isnull(XFC.CLIENTCORRESPONDNAME,XFC.CLIENTMAINCONTACT)'
			Set @sAddFromString = 'Join #TEMPCASESEXT'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Join #TEMPCASESEXT XFC		on (XFC.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('NoOfClaims', 'PlaceFirstUsed', 'ProposedUse', 'RenewalNotes')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROPERTY',upper(@sColumn),null,'P',@psCulture,@pbCalledFromCentura) 
						
			Set @sAddFromString = 'Left Join PROPERTY P'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join PROPERTY P with (NOLOCK) on (P.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CountryAdjective'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CT',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Join COUNTRY CT'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Join COUNTRY CT with (NOLOCK) on (CT.COUNTRYCODE=C.COUNTRYCODE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CountryName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Join COUNTRY CT'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Join COUNTRY CT with (NOLOCK) on (CT.COUNTRYCODE=C.COUNTRYCODE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				
				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CaseTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Join CASETYPE CS'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Join CASETYPE CS with (NOLOCK) on (CS.CASETYPE=C.CASETYPE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='ApplicationBasisDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join PROPERTY P'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join PROPERTY P with (NOLOCK) on (P.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join VALIDBASIS VB'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join VALIDBASIS VB with (NOLOCK) on (VB.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                          	and VB.BASIS       =P.BASIS"
				                   +char(10)+"                     		and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDBASIS VB1 with (NOLOCK)"
				                   +char(10)+"                     	                              where VB1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VB1.BASIS       =P.BASIS"
				                   +char(10)+"                     	                              and   VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='CaseOfficeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OFC',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join OFFICE OFC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join OFFICE OFC with (NOLOCK) on (OFC.OFFICEID=C.OFFICEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				
				Set @pnTableCount=@pnTableCount+1
			End
		End


		Else If @sColumn='CaseCategoryDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join VALIDCATEGORY VC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join VALIDCATEGORY VC with (NOLOCK) on (VC.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                          	and VC.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	and VC.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                     		and VC.COUNTRYCODE = (select min(VC1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDCATEGORY VC1 with (NOLOCK)"
				                   +char(10)+"                     	                              where VC1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VC1.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	                      and   VC1.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                     	                              and   VC1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='PropertyTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Join VALIDPROPERTY VP'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE"
				                   +char(10)+"                     		and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)"
				                   +char(10)+"                     		                      from VALIDPROPERTY VP1 with (NOLOCK)"
				                   +char(10)+"                     		                      where VP1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                     		                      and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='SubTypeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join VALIDSUBTYPE VS'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join VALIDSUBTYPE VS with (NOLOCK)  on (VS.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                          	and VS.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	and VS.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                          	and VS.SUBTYPE     =C.SUBTYPE"
				                   +char(10)+"                     		and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDSUBTYPE VS1 with (NOLOCK)"
				                   +char(10)+"                     	               	              where VS1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VS1.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	                      and   VS1.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                          	                      and   VS1.SUBTYPE     =C.SUBTYPE"
				                   +char(10)+"                     	                              and   VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))" 

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
			
				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn in ('RenewalStatusDescription','RenewalStatusExternalDescription', 'RenewalStatusKey')
		Begin
			If @pbExternalUser=1 or @sColumn='RenewalStatusExternalDescription'
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura) 
			Else if @sColumn='RenewalStatusDescription'
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura) 
			Else
				Set @sTableColumn='RS.STATUSCODE'

			Set @sAddFromString = 'Left Join PROPERTY P'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join PROPERTY P with (NOLOCK) on (P.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				
				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join STATUS RS'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join STATUS RS with (NOLOCK) on (RS.STATUSCODE=P.RENEWALSTATUS)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('StatusDescription', 'StatusExternalDescription')
		Begin
			If @pbExternalUser=1
			or @sColumn='StatusExternalDescription'
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) 
			Else
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join STATUS ST'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join STATUS ST with (NOLOCK) on (ST.STATUSCODE=C.STATUSCODE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('CaseStatusSummary', 'CaseStatusSummaryKey')
		Begin
			if @sColumn = 'CaseStatusSummaryKey'
				Set @sTableColumn='TC.TABLECODE'
			else
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join PROPERTY P'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join PROPERTY P with (NOLOCK) on (P.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join STATUS RS'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join STATUS RS with (NOLOCK) on (RS.STATUSCODE=P.RENEWALSTATUS)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join STATUS ST'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join STATUS ST with (NOLOCK) on (ST.STATUSCODE=C.STATUSCODE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join TABLECODES TC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join TABLECODES TC with (NOLOCK) on (TC.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) Then 7603'
			                           +char(10)+'                       		                      WHEN(ST.REGISTEREDFLAG=1)            Then 7602'
				                   +char(10)+'                       		                                                           Else 7601'
				                   +char(10)+'                       			                 END)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='TypeOfMarkDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TM',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join TABLECODES TM'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join TABLECODES TM with (NOLOCK) on (TM.TABLECODE=C.TYPEOFMARK)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='EntitySizeDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TE',@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join TABLECODES TE'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join TABLECODES TE with (NOLOCK) on (TE.TABLECODE=C.ENTITYSIZE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		-------------------------------------------
		-- RFC13081
		-- Columns to report on Event differences 
		-- resulting from Policing after Law Update
		-------------------------------------------
		Else If @sColumn in (	'EventChangedDescription',
					'EventChangedNumber',
					'EventChangedCycle',
					'EventChangedImportanceDescription',
					'EventChangedImportance',
					'EventChangedType',
					'EventChangedDateBefore',
					'EventChangedDateNow',
					'EventChangedDueBefore',
					'EventChangedDueNow')
		Begin
			Set @sAddFromString = 'Join CASEEVENT_iLOG BEFORE'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin	
				Select @nTranNo=LOGTRANSACTIONNO
				from SITECONTROL
				where CONTROLID='CPA Law Update Service'
							
				Set @sAddFromString = 'Join CASEEVENT_iLOG BEFORE with(NOLOCK) on (BEFORE.CASEID=C.CASEID and BEFORE.LOGTRANSACTIONNO='+cast(@nTranNo as varchar)+')'+char(10)+
						      'Left Join CASEEVENT NOW    with(NOLOCK) on (NOW.CASEID   =C.CASEID and NOW.EVENTNO=BEFORE.EVENTNO and NOW.CYCLE=BEFORE.CYCLE)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
				-------------------------------------------------------------------------	
				-- We only want to report on those CASEEVENT rows that are now different. 
				-- Use CHECKSUM as this will handle the possibility of NULL values and
				-- only compare EVENTDUEDATE if the event has not occurred.
				-------------------------------------------------------------------------				
				Set @sAddWhereString='and ( CHECKSUM(BEFORE.OCCURREDFLAG)<>CHECKSUM(NOW.OCCURREDFLAG)'+CHAR(10)+
						     '  OR (BEFORE.OCCURREDFLAG=0 and NOW.OCCURREDFLAG=0 and CHECKSUM(BEFORE.EVENTDUEDATE)<>CHECKSUM(NOW.EVENTDUEDATE))'+CHAR(10)+
						     '  OR  CHECKSUM(BEFORE.EVENTDATE)<>CHECKSUM(NOW.EVENTDATE))'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentWhereString	OUTPUT,
								@psAddString	=@sAddWhereString,
								@psComponentType=@sWhere,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
			End
			
			If @sColumn in ('EventChangedDescription',
					'EventChangedImportanceDescription',
					'EventChangedImportance')
			Begin
				Set @sAddFromString = 'Left Join OPENACTION LOG_OA'
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin		
					Set @sAddFromString = 'Left Join OPENACTION LOG_OA   with(NOLOCK) on (LOG_OA.CASEID=C.CASEID)'+char(10)+
							      'Left Join ACTIONS LOG_A       with(NOLOCK) on (LOG_A.ACTION=LOG_OA.ACTION)'+char(10)+
							      'Left Join EVENTCONTROL LOG_EC with(NOLOCK) on (LOG_EC.CRITERIANO=LOG_OA.CRITERIANO and LOG_EC.EVENTNO=BEFORE.EVENTNO)'+char(10)+
							      '     Join EVENTS LOG_E        with(NOLOCK) on (LOG_E.EVENTNO=BEFORE.EVENTNO)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+3
					
					-- Use the CONTROLLINGACTION if defined to indicate which Action's rules should be used
					-- and also limit the cycle of OPENACTION so as not to return multiple rows.
					Set @sAddWhereString='and (LOG_OA.ACTION=LOG_E.CONTROLLINGACTION or (LOG_E.CONTROLLINGACTION is null and LOG_EC.CRITERIANO=isnull(BEFORE.CREATEDBYCRITERIA,LOG_OA.CRITERIANO)) or LOG_OA.CASEID is null)'+char(10)+
					                     'and (LOG_OA.CYCLE=CASE WHEN(LOG_A.NUMCYCLESALLOWED>1) THEN BEFORE.CYCLE ELSE 1 END OR LOG_OA.CASEID is null)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentWhereString	OUTPUT,
									@psAddString	=@sAddWhereString,
									@psComponentType=@sWhere,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
				END
				
				If @sColumn in ('EventChangedImportanceDescription')
				Begin
					Set @sAddFromString = 'Left Join IMPORTANCE LOG_I'
					
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = 'Left Join IMPORTANCE LOG_I on (LOG_I.IMPORTANCELEVEL=isnull(LOG_EC.IMPORTANCELEVEL,LOG_E.IMPORTANCELEVEL))'
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1
					End
				End
			End
				
			If @sColumn in ('EventChangedType')
			Begin
				Set @sAddFromString = 'Left Join TABLECODES LOG_TC'
				
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = 'Left Join TABLECODES LOG_TC on (LOG_TC.TABLETYPE=117 and LOG_TC.USERCODE=BEFORE.LOGACTION)'
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End
			
			Set @sTableColumn=
				CASE(@sColumn)
					WHEN('EventChangedDescription')	THEN 'isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'LOG_EC',@sLookupCulture,@pbCalledFromCentura)
										 +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'LOG_E',@sLookupCulture,@pbCalledFromCentura)+')'
					WHEN('EventChangedNumber')	THEN 'BEFORE.EVENTNO'
					WHEN('EventChangedCycle')	THEN 'BEFORE.CYCLE'
					WHEN('EventChangedImportanceDescription') 
									THEN dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'LOG_I',@sLookupCulture,@pbCalledFromCentura)
					WHEN('EventChangedImportance')	THEN 'ISNULL(LOG_EC.IMPORTANCELEVEL, LOG_E.IMPORTANCELEVEL)'
					WHEN('EventChangedType')	THEN dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'LOG_TC',@sLookupCulture,@pbCalledFromCentura)
					WHEN('EventChangedDateBefore')	THEN 'BEFORE.EVENTDATE'
					WHEN('EventChangedDateNow')	THEN 'NOW.EVENTDATE'
					WHEN('EventChangedDueBefore')	THEN 'CASE WHEN(BEFORE.OCCURREDFLAG=0) THEN BEFORE.EVENTDUEDATE END'
					WHEN('EventChangedDueNow')	THEN 'CASE WHEN(   NOW.OCCURREDFLAG=0) THEN NOW.EVENTDUEDATE END'
	
	
				End
			
		End

		Else If @sColumn in (	'DisplayName',
					'DebtorStatusDescription',
					'DebtorStatusActionKey',
					'NameAddress',
					'NameCode',
					'NameCountry',
					'NameBillCurrency',	-- RFC41426
					'NameDebtorType',	-- RFC41426
					'NameKey',
					'NameReference',
					'NameAttention',
					'NameAttentionKey',
					'NameAttentionCode',
					'NameSearchKey2',
					'NameVariantMain',
					'NameVariantMainOrName')
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin		
			Set @sTable1='CN'+@sCorrelationSuffix
			Set @sTable2='IP'+@sCorrelationSuffix
			Set @sTable3='DS'+@sCorrelationSuffix

			Set @sAddFromString = 'Left Join CASENAME '+@sTable1
			Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
	
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				-- Check if the user is allowed access to the NameType passed as a parameter
				Set @sNameType=''
				
				Set @sSQLString="
				select @sNameType=@sNameType+CASE WHEN(@sNameType='') THEN NAMETYPE ELSE ','+NAMETYPE END
				from dbo.fn_FilterUserNameTypes(@pnUserIdentityId,default,@pbExternalUser,default)
				where NAMETYPE=("+dbo.fn_WrapQuotes(@sQualifier,1,0)+")"
				
				exec @ErrorCode=sp_executesql @sSQLString,
							N'@sNameType		nvarchar(200)	OUTPUT,
							  @sQualifier		nvarchar(50),
							  @pnUserIdentityId	int,
							  @pbExternalUser	bit',
							  @sNameType		=@sNameType	OUTPUT,
							  @sQualifier		=@sQualifier,
							  @pnUserIdentityId	=@pnUserIdentityId,
							  @pbExternalUser	=@pbExternalUser
									
				If isnull(@sNameType,'')<>''
					If @pbCalledFromCentura=1
						--------------------------------------------
						-- Centura is unable to use the CTE approach
						-- so having to continue with old method.
						--------------------------------------------
						Set @sAddFromString = "Left Join CASENAME "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
							   +char(10)+"                         		and "        +@sTable1+".NAMETYPE=" + dbo.fn_WrapQuotes(@sNameType,0,@pbCalledFromCentura)
							   +char(10)+"                         		and("       +@sTable1+".EXPIRYDATE is null or "+@sTable1+".EXPIRYDATE>getdate() )"
							   +char(10)+"                         		and "        +@sTable1+".SEQUENCE=(select min(SEQUENCE) from CASENAME CN with (NOLOCK)"
							   +char(10)+"                    		                                   where CN.CASEID=C.CASEID"
							   +char(10)+"                     		                                   and CN.NAMETYPE=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)
							   +char(10)+"                      		                                   and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))"
					Else						
						Set @sAddFromString = "Left Join CASENAME "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
							   +char(10)+"                         		and "        +@sTable1+".NAMETYPE=" + dbo.fn_WrapQuotes(@sNameType,0,@pbCalledFromCentura)
							   +char(10)+"                         		and "        +@sTable1+".SEQUENCE=(select SEQUENCE from CTE_CaseNameSequence CN"
							   +char(10)+"                    		                                   where CN.CASEID=C.CASEID"
							   +char(10)+"                     		                                   and CN.NAMETYPE=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)+"))"
				Else				
					Set @sAddFromString = "Left Join CASENAME "+@sTable1+" with (NOLOCK) on (0=1)" -- User may not see this Name Type

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+3
			End

			If @sColumn in ('NameVariantMain',
					'NameVariantMainOrName')
			Begin			
				Set @sTable11='NV' +@sCorrelationSuffix

				Set @sAddFromString = 'Left Join NAMEVARIANT '+@sTable11
				Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAMEVARIANT "+@sTable11+" with (NOLOCK) on ("+@sTable11+".NAMEVARIANTNO="+@sTable1+".NAMEVARIANTNO)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1					
				End
			End
			
			If @sColumn in ('DebtorStatusDescription',
					'DebtorStatusActionKey',
					'NameBillCurrency',
					'NameDebtorType')
			Begin			
				Set @sAddFromString = 'Left Join IPNAME '+@sTable2
				Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join IPNAME "+@sTable2+" with (NOLOCK) on ("+@sTable2+".NAMENO="+@sTable1+".NAMENO)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1					
				End
			
				If @sColumn in ('DebtorStatusDescription','DebtorStatusActionKey')
				Begin
					If @sColumn= 'DebtorStatusDescription'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,@sTable3,@sLookupCulture,@pbCalledFromCentura) 
					End
					Else If @sColumn= 'DebtorStatusActionKey' 
					Begin
						Set @sTableColumn=@sTable3+'.ACTIONFLAG'
					End
				
					Set @sAddFromString = 'Left Join DEBTORSTATUS '+@sTable3
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join DEBTORSTATUS "+@sTable3+" with (NOLOCK) on ("+@sTable3+".BADDEBTOR="+@sTable2+".BADDEBTOR)"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1					
					End
				End
			
				If @sColumn in ('NameBillCurrency')
				Begin
					Set @sTable5='CU'+@sCorrelationSuffix
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,@sTable5,@sLookupCulture,@pbCalledFromCentura) 
					
					Set @sAddFromString = 'Left Join CURRENCY '+@sTable5
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join CURRENCY "+@sTable5+" with (NOLOCK) on ("+@sTable5+".CURRENCY="+@sTable2+".CURRENCY)"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1					
					End
				End
			
				If @sColumn in ('NameDebtorType')
				Begin
					Set @sTable6='DT'+@sCorrelationSuffix
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,@sTable6,@sLookupCulture,@pbCalledFromCentura) 
					
					Set @sAddFromString = 'Left Join TABLECODES '+@sTable6
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join TABLECODES "+@sTable6+" with (NOLOCK) on ("+@sTable6+".TABLECODE="+@sTable2+".DEBTORTYPE)"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1					
					End
				End
			End
	
			If @sColumn='NameReference'
			Begin
				set @sTableColumn=@sTable1+'.REFERENCENO'
			End
			Else If @sColumn='NameKey'			-- RFC13
			Begin
				Set @sTableColumn=@sTable1+'.NAMENO'
			End
			Else If @sColumn='NameVariantMain'
			Begin
				Set @sTableColumn='dbo.fn_FormatName('+@sTable11+'.NAMEVARIANT, '+@sTable11+'.FIRSTNAMEVARIANT, NULL, NULL)'
			End
			Else Begin
				Set @sTable2='N'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join NAME '+@sTable2
				Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAME "+@sTable2+" with (NOLOCK) on ("+@sTable2+".NAMENO="+@sTable1+".NAMENO)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				If @sColumn in ('NameAttention',
						'NameAddress',
						'NameAttentionKey',
						'NameAttentionCode',
						'NameCountry')
				-- Specific logic is required to retrieve the Debtor and Renewal Debtor Address 
				-- and Attention ('D' and 'Z' name types):
				-- 1)	Details recorded on the CaseName table; if no information is found then 
				-- 	step 2 will be performed;
				-- 2)	If the debtor was inherited from the associated name then the details 
				-- 	recorded against this associated name will be returned; if the debtor was not 
				-- 	inherited then go to the step 3;
				-- 3)	Check if the Address/Attention has been overridden on the AssociatedName 
				-- 	table with Relationship = ‘BIL’ and NameNo = RelatedName; if no information
				--	was found then go to the step 4; 
				-- 4)	Extract the Billing Address/Attention details stored against the Name as 
				--	the PostalAddress and MainContact.
				and @sQualifier in ('D', 'Z')					
			     	Begin		
					Set @sTable5='AN2'+@sCorrelationSuffix
					Set @sTable6='AN3'+@sCorrelationSuffix
					Set @sTable7='BLN'+@sCorrelationSuffix					
					Set @sAddFromString = 'Left Join ASSOCIATEDNAME '+@sTable5
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join ASSOCIATEDNAME "+@sTable5+" with (NOLOCK) on ("+@sTable5+".NAMENO = "+@sTable1+".INHERITEDNAMENO"
							    +char(10)+"	    					and "+@sTable5+".RELATIONSHIP = "+@sTable1+".INHERITEDRELATIONS"
							    +char(10)+"	    					and "+@sTable5+".RELATEDNAME = "+@sTable1+".NAMENO"
							    +char(10)+"						and "+@sTable5+".SEQUENCE = "+@sTable1+".INHERITEDSEQUENCE)"
							    +char(10)+"Left Join ASSOCIATEDNAME "+@sTable6+" with (NOLOCK) on ("+@sTable6+".NAMENO = "+@sTable1+".NAMENO"
							    +char(10)+"						and "+@sTable6+".RELATIONSHIP = N'BIL'"
							    +char(10)+"						and "+@sTable6+".NAMENO = "+@sTable6+".RELATEDNAME"
							    +char(10)+"						and "+@sTable5+".NAMENO is null)"
							    +char(10)+"Left Join NAME "+@sTable7+" with (NOLOCK) on ("+@sTable7+".NAMENO = COALESCE("+@sTable1+".CORRESPONDNAME, "+@sTable5+".CONTACT, "+@sTable6+".CONTACT, "+@sTable2+".MAINCONTACT))"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+3					
					End					
					
					If @sColumn='NameAttention'
					Begin						
						Set @sTableColumn="dbo.fn_FormatNameUsingNameNo("+@sTable7+".NAMENO, null)"	
					End
					Else If @sColumn='NameAttentionKey'			
					Begin
						Set @sTableColumn=@sTable7+'.NAMENO'
					End
					Else If @sColumn='NameAttentionCode'			
					Begin
						Set @sTableColumn=@sTable7+'.NAMECODE'
					End
					Else If @sColumn in ('NameAddress', 'NameCountry')
					Begin
						Set @sTable8='BA'+@sCorrelationSuffix
						Set @sTable9='BC'+@sCorrelationSuffix
						Set @sTable10='BS'+@sCorrelationSuffix

						Set @sAddFromString = 'Left Join ADDRESS '+@sTable8
						Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
				
						If not exists(	select 1 from #TempConstructSQL T
								where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
						and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
						Begin									
							Set @sAddFromString =  "Left Join ADDRESS "+@sTable8+" with (NOLOCK) on ("+@sTable8+".ADDRESSCODE = COALESCE("+@sTable1+".ADDRESSCODE, "+@sTable5+".POSTALADDRESS,"+@sTable6+".POSTALADDRESS, "+@sTable2+".POSTALADDRESS))"
								     +char(10)+"Left Join COUNTRY "+@sTable9+" with (NOLOCK) on ("+@sTable9+".COUNTRYCODE = "+@sTable8+".COUNTRYCODE)"
								     +char(10)+"Left Join STATE   "+@sTable10+" with (NOLOCK) on ("+@sTable10+".COUNTRYCODE = "+@sTable8+".COUNTRYCODE"
								     +char(10)+"	 	           	        and "+@sTable10+".STATE = "+@sTable8+".STATE)"
			
							exec @ErrorCode=dbo.ip_LoadConstructSQL
										@psCurrentString=@sCurrentFromString	OUTPUT,
										@psAddString	=@sAddFromString,
										@psComponentType=@sFrom, 
										@psSeparator    =@sReturn,
										@pbForceLoad=0
			
							Set @pnTableCount=@pnTableCount+3

						End

						If @sColumn = 'NameCountry'
						Begin
							Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,@sTable9,@sLookupCulture,@pbCalledFromCentura) 
						End
						Else If @sColumn = 'NameAddress'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO,'+@sTable9+'.NAMESTYLE)+char(13)+char(10)+'
								  +'dbo.fn_FormatAddress('+@sTable8+'.STREET1, '+@sTable8+'.STREET2, '+@sTable8+'.CITY, '+@sTable8+'.STATE, '+@sTable10+'.STATENAME, '+@sTable8+'.POSTCODE, '+@sTable9+'.POSTALNAME, '+@sTable9+'.POSTCODEFIRST, '+@sTable9+'.STATEABBREVIATED, '+@sTable9+'.POSTCODELITERAL, '+@sTable9+'.ADDRESSSTYLE)'
						End					
					End				
				End	
				
				If @sColumn in ('NameAttention',
						'NameAttentionKey',
						'NameAttentionCode')				
				-- For name types that are not Debtor (Name type = 'D') or Renewal Debtor ('Z')
				-- NameAttention is obtained as the following:
				-- 1)	Details recorded on the CaseName table; if no information is found then 
				-- 	step 2 will be performed; 
				-- 2)   Extract the NameAddress details stored against the Name as the PostalAddress.
				and @sQualifier not in ('D', 'Z')						
			     	Begin	
					Set @sTable4='N2'+@sCorrelationSuffix
					Set @sAddFromString = 'Left Join NAME '+@sTable4
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join NAME "+@sTable4+" with (NOLOCK) on ("+@sTable4+".NAMENO=isnull("+@sTable1+".CORRESPONDNAME, "+@sTable2+".MAINCONTACT))"						    
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1
	
					End				

					If @sColumn='NameAttention'
					Begin						
						Set @sTableColumn="dbo.fn_FormatNameUsingNameNo("+@sTable4+".NAMENO, null)"
					End
					Else If @sColumn='NameAttentionKey'			
					Begin
						Set @sTableColumn=@sTable4+'.NAMENO'
					End
					Else If @sColumn='NameAttentionCode'			
					Begin
						Set @sTableColumn=@sTable4+'.NAMECODE'
					End
				End	
					
				If @sColumn='NameVariantMainOrName'
				Begin
					Set @sTableColumn='isnull( dbo.fn_FormatName('+@sTable11+'.NAMEVARIANT, '+@sTable11+'.FIRSTNAMEVARIANT, NULL, NULL),'+
								  'dbo.fn_FormatNameUsingNameNo('+@sTable2+ '.NAMENO, NULL) )'

				End
				Else If @sColumn='DisplayName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, NULL)'
				End
				Else If @sColumn='NameCode'
				Begin
					Set @sTableColumn=@sTable2+'.NAMECODE'
				End
				Else If @sColumn='NameSearchKey2' -- RFC2984
				Begin
					Set @sTableColumn=@sTable2+'.SEARCHKEY2'
				End				-- Address information for name types that are not Debtor (Name type = 'D') 
				-- or Renewal Debtor ('Z') is obtained as the following:
				-- 1)	Details recorded on the CaseName table; if no information is found then 
				-- 	step 2 will be performed; 
				-- 2)   Extract the Attention details stored against the Name as the MainContact.
				Else If @sQualifier not in ('D', 'Z')
				Begin
					Set @sTable3='A'+@sCorrelationSuffix
					Set @sAddFromString = 'Left Join ADDRESS '+@sTable3
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join ADDRESS "+@sTable3+" with (NOLOCK) on ("+@sTable3+".ADDRESSCODE=isnull("+@sTable1+".ADDRESSCODE,"+@sTable2+".POSTALADDRESS))"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
						
						Set @pnTableCount=@pnTableCount+1
					End

					Set @sTable4='AC'+@sCorrelationSuffix
					Set @sAddFromString = 'Left Join COUNTRY '+@sTable4
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join COUNTRY "+@sTable4+" with (NOLOCK) on ("+@sTable4+".COUNTRYCODE="+@sTable3+".COUNTRYCODE)"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1
					End

					If @sColumn='NameCountry'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,@sTable4,@sLookupCulture,@pbCalledFromCentura) 
					End
					Else If @sColumn='NameAddress'					
					Begin

						Set @sTable5='STATE'+@sCorrelationSuffix
						Set @sAddFromString = 'Left Join STATE '+@sTable5
						Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- SQA18550 Add Escape character to ignore as wildcard
				
						If not exists(	select 1 from #TempConstructSQL T
								where T.SavedString like @sSearchString ESCAPE '\') -- SQA18550
						and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
						Begin									
							Set @sAddFromString = "Left Join STATE "+@sTable5+" with (NOLOCK) on ("+@sTable5+".COUNTRYCODE="+@sTable3+".COUNTRYCODE"
									   +char(10)+"                   			and "+@sTable5+".STATE="+@sTable3+".STATE)"
			
							exec @ErrorCode=dbo.ip_LoadConstructSQL
										@psCurrentString=@sCurrentFromString	OUTPUT,
										@psAddString	=@sAddFromString,
										@psComponentType=@sFrom, 
										@psSeparator    =@sReturn,
										@pbForceLoad=0
			
							Set @pnTableCount=@pnTableCount+1

						End

						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, '+@sTable4+'.NAMESTYLE)+char(13)+char(10)+'
								  +'dbo.fn_FormatAddress('+@sTable3+'.STREET1, '+@sTable3+'.STREET2, '+@sTable3+'.CITY, '+@sTable3+'.STATE, '+@sTable5+'.STATENAME, '+@sTable3+'.POSTCODE, '+@sTable4+'.POSTALNAME, '+@sTable4+'.POSTCODEFIRST, '+@sTable4+'.STATEABBREVIATED, '+@sTable4+'.POSTCODELITERAL, '+@sTable4+'.ADDRESSSTYLE)'
					End

				End
			End
		End

		Else If @sColumn='NameAttentionAll'					
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin	
			Set @sTableColumn="dbo.fn_GetConcatenatedNameAttentions(C.CASEID, '"+@sQualifier+"', ';', getdate(), null)"
		End

		Else If @sColumn='NameVariantAll'					
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin	
			Set @sTableColumn="dbo.fn_GetConcatenatedNameVariants(C.CASEID, '"+@sQualifier+"', ';', 1, getdate(), null)"
		End

		Else If @sColumn='NameVariantOrNameAll'					
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin	
			Set @sTableColumn="dbo.fn_GetConcatenatedNameVariants(C.CASEID, '"+@sQualifier+"', ';', 0, getdate(), null)"
		End	

		Else If @sColumn='DisplayNameAll'					
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin	
			Set @sTableColumn="dbo.fn_GetConcatenatedNames(C.CASEID, '"+@sQualifier+"', ';', getdate(), null)"
		End		

		Else If @sColumn='NameKeyAll'					
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin	
			Set @sTableColumn="dbo.fn_GetConcatenatedNameKeys(C.CASEID, '"+@sQualifier+"', ';', getdate())"
		End		
	
		Else If @sColumn in ('ClientContact',
				     'ClientContactNameCode')
		     and @pbExternalUser=1	-- Data only available for external users
		Begin
			Set @sAddFromString = 'Join #TEMPCASESEXT'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Join #TEMPCASESEXT XFC		on (XFC.CASEID=C.CASEID)" 		
						  +char(10)+"Left Join NAME CON with (NOLOCK) on (CON.NAMENO=isnull(XFC.CLIENTCORRESPONDNAME,XFC.CLIENTMAINCONTACT))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End  
			Else Begin
				Set @sAddFromString = 'Left Join NAME CON'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAME CON with (NOLOCK) on (CON.NAMENO=isnull(XFC.CLIENTCORRESPONDNAME,XFC.CLIENTMAINCONTACT))"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End			

			If @sColumn='ClientContact'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(CON.NAMENO, NULL)'
			End
			Else If @sColumn='ClientContactNameCode'
			Begin
				Set @sTableColumn='CON.NAMECODE'
			End
		End		

		-- RFC13 Implement versions of the Report Ids that will return any names, not just the main one
		Else If @sColumn in (	'DisplayNameAny',
					'DisplayNamesUnrestrictedAny',
					'InheritedFromName',
					'InheritedRelationship',
					'NameAddressAny',
					'NameCodeAny',
					'NameKeyAny',
					'NameReferenceAny',
					'NameTypeAny',
					'NameVariantAny',
					'NameVariantOrNameAny',
					'NameAttentionAny',
					'NameAttentionCodeAny',
					'NameAttentionKeyAny')
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin
			Set @sTable1='CNA'+@sCorrelationSuffix
			Set @sAddFromString = 'Left Join CASENAME '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				-- Check if the user is allowed access to the NameType passed as a parameter
				Set @sNameType=''
				
				Set @sSQLString="
				select @sNameType=@sNameType+CASE WHEN(@sNameType='') THEN NAMETYPE ELSE ','+NAMETYPE END
				from dbo.fn_FilterUserNameTypes(@pnUserIdentityId,default,@pbExternalUser,default)
				where NAMETYPE=("+dbo.fn_WrapQuotes(@sQualifier,1,0)+")"
				
				exec @ErrorCode=sp_executesql @sSQLString,
							N'@sNameType		nvarchar(200)	OUTPUT,
							  @sQualifier		nvarchar(50),
							  @pnUserIdentityId	int,
							  @pbExternalUser	bit',
							  @sNameType		=@sNameType	OUTPUT,
							  @sQualifier		=@sQualifier,
							  @pnUserIdentityId	=@pnUserIdentityId,
							  @pbExternalUser	=@pbExternalUser

				If isnull(@sNameType,'')<>''
					Set @sAddFromString = "Left Join CASENAME "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                         		and "        +@sTable1+".NAMETYPE" + dbo.fn_ConstructOperator(0,@CommaString,@sNameType, null,@pbCalledFromCentura)
							-- Restrict to current names unless explicitly requested Unrestricted
						   +CASE WHEN(@sColumn<>'DisplayNamesUnrestrictedAny')
						    	THEN char(10)+"                         		and("       +@sTable1+".EXPIRYDATE is null or "+@sTable1+".EXPIRYDATE>getdate() )"
						    END
						   +char(10)+"					)"
				Else
					Set @sAddFromString = "Left Join CASENAME "+@sTable1+" with (NOLOCK) on (0=1)"	-- User does not have access to NameType

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End

			If @sColumn in ('NameVariantAny',
					'NameVariantOrNameAny')
			Begin			
				Set @sTable11='NVA' +@sCorrelationSuffix

				Set @sAddFromString = 'Left Join NAMEVARIANT '+@sTable11
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAMEVARIANT "+@sTable11+" with (NOLOCK) on ("+@sTable11+".NAMEVARIANTNO="+@sTable1+".NAMEVARIANTNO)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

	
					Set @pnTableCount=@pnTableCount+1					
				End
			End

			If @sColumn = 'NameTypeAny'
			Begin			
				Set @sTable3='NTA' +@sCorrelationSuffix

				Set @sTableColumn=@sTable3+'.DESCRIPTION'

				Set @sAddFromString = 'Left Join NAMETYPE '+@sTable3
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAMETYPE "+@sTable3+" with (NOLOCK) on ("+@sTable3+".NAMETYPE="+@sTable1+".NAMETYPE)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

	
					Set @pnTableCount=@pnTableCount+1				
				End
			End
			Else If @sColumn='NameReferenceAny'
			Begin
				set @sTableColumn=@sTable1+'.REFERENCENO'
			End
			Else If @sColumn='NameKeyAny'
			Begin
				Set @sTableColumn=@sTable1+'.NAMENO'
			End
			Else If @sColumn='NameVariantAny'
			Begin
				Set @sTableColumn='dbo.fn_FormatName('+@sTable11+'.NAMEVARIANT, '+@sTable11+'.FIRSTNAMEVARIANT, NULL, NULL)'
			End
			Else If @sColumn='InheritedFromName'
			Begin
				Set @sTable3='IN'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join NAME '+@sTable3
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAME "+@sTable3+" with (NOLOCK) on ("+@sTable3+".NAMENO="+@sTable1+".INHERITEDNAMENO and "+@sTable1+".INHERITED=1)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0				
	
					Set @pnTableCount=@pnTableCount+1

					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable3+'.NAMENO,NULL)'
				End
			End
			Else If @sColumn='InheritedRelationship'
			Begin
				Set @sTable4='INR'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join NAMERELATION '+@sTable4
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAMERELATION "+@sTable4+" with (NOLOCK) on ("+@sTable4+".RELATIONSHIP="+@sTable1+".INHERITEDRELATIONS and "+@sTable1+".INHERITED=1)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0				
	
					Set @pnTableCount=@pnTableCount+1

					Set @sTableColumn=@sTable4+'.RELATIONDESCR'
				End

			End
			Else Begin
				Set @sTable2='NA'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join NAME '+@sTable2
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join NAME "+@sTable2+" with (NOLOCK) on ("+@sTable2+".NAMENO="+@sTable1+".NAMENO)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0				
	
					Set @pnTableCount=@pnTableCount+1
				End

				If  @sColumn in ('NameAttentionAny','NameAttentionCodeAny','NameAttentionKeyAny')
				and @sQualifier in ('D', 'Z')						
				Begin
					-------------------------------------------------------------------------------------
					-- Specific logic is required to retrieve the Debtor and Renewal Debtor Address 
					-- and Attention ('D' and 'Z' name types):
					-- 1)	Details recorded on the CaseName table; if no information is found then 
					-- 	step 2 will be performed;
					-- 2)	If the debtor was inherited from the associated name then the details 
					-- 	recorded against this associated name will be returned; if the debtor was not 
					-- 	inherited then go to the step 3;
					-- 3)	Check if the Address/Attention has been overridden on the AssociatedName 
					-- 	table with Relationship = ‘BIL’ and NameNo = RelatedName; if no information
					--	was found then go to the step 4; 
					-- 4)	Extract the Billing Address/Attention details stored against the Name as 
					--	the PostalAddress and MainContact.
					-------------------------------------------------------------------------------------	
					Set @sTable5='AN2'+@sCorrelationSuffix
					Set @sTable6='AN3'+@sCorrelationSuffix
					Set @sTable7='BLN'+@sCorrelationSuffix					
					Set @sAddFromString = 'Left Join ASSOCIATEDNAME '+@sTable5
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join ASSOCIATEDNAME "+@sTable5+" with (NOLOCK) on ("+@sTable5+".NAMENO = "+@sTable1+".INHERITEDNAMENO"
							    +char(10)+"	    					and "+@sTable5+".RELATIONSHIP = "+@sTable1+".INHERITEDRELATIONS"
							    +char(10)+"	    					and "+@sTable5+".RELATEDNAME = "+@sTable1+".NAMENO"
							    +char(10)+"						and "+@sTable5+".SEQUENCE = "+@sTable1+".INHERITEDSEQUENCE)"
							    +char(10)+"Left Join ASSOCIATEDNAME "+@sTable6+" with (NOLOCK) on ("+@sTable6+".NAMENO = "+@sTable1+".NAMENO"
							    +char(10)+"						and "+@sTable6+".RELATIONSHIP = N'BIL'"
							    +char(10)+"						and "+@sTable6+".NAMENO = "+@sTable6+".RELATEDNAME"
							    +char(10)+"						and "+@sTable5+".NAMENO is null)"
							    +char(10)+"Left Join NAME "+@sTable7+" with (NOLOCK) on ("+@sTable7+".NAMENO = COALESCE("+@sTable1+".CORRESPONDNAME, "+@sTable5+".CONTACT, "+@sTable6+".CONTACT, "+@sTable2+".MAINCONTACT))"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+3					
					End					
					
					If @sColumn='NameAttentionAny'
					Begin						
						Set @sTableColumn="dbo.fn_FormatNameUsingNameNo("+@sTable7+".NAMENO, null)"	
					End
					Else If @sColumn='NameAttentionKeyAny'			
					Begin
						Set @sTableColumn=@sTable7+'.NAMENO'
					End
					Else If @sColumn='NameAttentionCodeAny'			
					Begin
						Set @sTableColumn=@sTable7+'.NAMECODE'
					End
				End

				If  @sColumn in ('NameAttentionAny','NameAttentionCodeAny','NameAttentionKeyAny')
				and @sQualifier not in ('D', 'Z')						
				Begin
					Set @sTable3='ATTN'+@sCorrelationSuffix
					Set @sAddFromString = 'Left Join NAME '+@sTable3
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'  -- Add Escape character to ignore as wildcard
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = "Left Join NAME "+@sTable3+" with (NOLOCK) on ("+@sTable3+".NAMENO=isnull("+@sTable1+".CORRESPONDNAME, "+@sTable2+".MAINCONTACT))"
	
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0				
	
						Set @pnTableCount=@pnTableCount+1
					End

					If @sColumn = 'NameAttentionAny'
					Begin
						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable3+'.NAMENO, NULL)'
					End
					Else If @sColumn='NameAttentionCodeAny'
					Begin
						Set @sTableColumn=@sTable3+'.NAMECODE'
					End
					Else If @sColumn='NameAttentionKeyAny'
					Begin
						Set @sTableColumn=@sTable3+'.NAMENO'
					End
				End
				Else If @sColumn in ('DisplayNameAny','DisplayNamesUnrestrictedAny')
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, NULL)'
				End
				Else If @sColumn='NameCodeAny'
				Begin
					Set @sTableColumn=@sTable2+'.NAMECODE'
				End
				Else If @sColumn='NameVariantOrNameAny'
				Begin
					Set @sTableColumn='isnull( dbo.fn_FormatName('+@sTable11+'.NAMEVARIANT, '+@sTable11+'.FIRSTNAMEVARIANT, NULL, NULL),'+
								  'dbo.fn_FormatNameUsingNameNo('+@sTable2+ '.NAMENO,  NULL) )'

				End
				------------
				--  RFC10631
				------------
				Else If @sColumn='NameAddressAny'
				Begin
					Set @sTable8='AD'+@sCorrelationSuffix
					Set @sTable9='ADC'+@sCorrelationSuffix
					Set @sTable10='ADS'+@sCorrelationSuffix

					Set @sAddFromString = 'Left Join ADDRESS '+@sTable8
					Set @sSearchString  = '%'+replace(@sAddFromString,'_','\_')+'%'
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like @sSearchString ESCAPE '\') 
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString =  "Left Join ADDRESS "+@sTable8+" with (NOLOCK) on ("+@sTable8+".ADDRESSCODE = COALESCE("+@sTable1+".ADDRESSCODE, "+@sTable2+".STREETADDRESS,"+@sTable2+".POSTALADDRESS))"
							     +char(10)+"Left Join COUNTRY "+@sTable9+" with (NOLOCK) on ("+@sTable9+".COUNTRYCODE = "+@sTable8+".COUNTRYCODE)"
							     +char(10)+"Left Join STATE   "+@sTable10+" with (NOLOCK) on ("+@sTable10+".COUNTRYCODE = "+@sTable8+".COUNTRYCODE"
							     +char(10)+"	 	           	        and "+@sTable10+".STATE = "+@sTable8+".STATE)"
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+3

					End

					Set @sTableColumn='dbo.fn_FormatAddress('+@sTable8+'.STREET1, '+@sTable8+'.STREET2, '+@sTable8+'.CITY, '+@sTable8+'.STATE, '+@sTable10+'.STATENAME, '+@sTable8+'.POSTCODE, '+@sTable9+'.POSTALNAME, '+@sTable9+'.POSTCODEFIRST, '+@sTable9+'.STATEABBREVIATED, '+@sTable9+'.POSTCODELITERAL, '+@sTable9+'.ADDRESSSTYLE)'	
				End				
			End
		End

		Else If @sColumn in (	'OurContact',
					'OurContactKey',
					'OurContactNameCode') 
		Begin
			Set @sAddFromString = 'Left join SITECONTROL SWCNT'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left join SITECONTROL SWCNT with (NOLOCK) on (SWCNT.CONTROLID = 'WorkBench Contact Name Type')"
				                   +char(10)+"Left Join CASENAME OUR with (NOLOCK)	on (OUR.CASEID=C.CASEID"
						   +char(10)+"                      	and(OUR.EXPIRYDATE is null or OUR.EXPIRYDATE>getdate() )"
						   +char(10)+"                      	and OUR.NAMETYPE=(select max(CN.NAMETYPE) from CASENAME CN with (NOLOCK)"
						   +char(10)+"                      	                  where CN.CASEID=OUR.CASEID"
						   +char(10)+"                     	                  and CN.NAMETYPE in (ISNULL(SWCNT.COLCHARACTER,'SIG'),'EMP')"
						   +char(10)+"                      	                  and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))"
						   +char(10)+"Left Join NAME STAFF with (NOLOCK) on (STAFF.NAMENO=OUR.NAMENO)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+3
			End
	
			If @sColumn='OurContact'
			Begin
				set @sTableColumn='dbo.fn_FormatNameUsingNameNo(STAFF.NAMENO, NULL)'
			End
			Else If @sColumn='OurContactKey'
			Begin
				Set @sTableColumn='STAFF.NAMENO'
			End
			Else If @sColumn='OurContactNameCode'
			Begin
				Set @sTableColumn='STAFF.NAMECODE'
			End
		End

		Else If @sColumn='AttributeDescription'
		Begin
			Set @sTable1='TA'+@sCorrelationSuffix
			Set @sTable2='AT'+@sCorrelationSuffix
			Set @sTable3='OFAT'+@sCorrelationSuffix					
			Set @sTable4='TTP'+@sCorrelationSuffix 
			Set @sTableColumn="CASE WHEN UPPER("+@sTable4+".DATABASETABLE) = 'OFFICE' THEN "+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,@sTable3,@sLookupCulture,@pbCalledFromCentura)+
												" ELSE "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,@sTable2,@sLookupCulture,@pbCalledFromCentura)+" END" 
			Set @sAddFromString = 'Left Join TABLEATTRIBUTES '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join TABLEATTRIBUTES "+@sTable1+" with (NOLOCK) on ("+@sTable1+".GENERICKEY=cast(C.CASEID as varchar)"
						   +char(10)+"                                 	and "+@sTable1+".PARENTTABLE='CASES'"
						   +char(10)+"                                 	and "+@sTable1+".TABLETYPE=" + @sQualifier+")"
						   +char(10)+"Left Join TABLETYPE "+@sTable4+" with (NOLOCK) on ("+@sTable4+".TABLETYPE="+@sTable1+".TABLETYPE)"	
						   +char(10)+"Left Join TABLECODES "+@sTable2+" with (NOLOCK) on ("+@sTable2+".TABLECODE="+@sTable1+".TABLECODE)"
						   +char(10)+"Left Join OFFICE "+@sTable3+" with (NOLOCK) on ("+@sTable3+".OFFICEID = "+@sTable1+".TABLECODE)"			   

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0	

				Set @pnTableCount=@pnTableCount+4
			End
		End
		Else If @sColumn in (	'NextDueEventNo', 
					'NextDueDate',
					'NextDueEvent',
					'NextDueText')
		Begin
			Set @sTable1='NX' +@sCorrelationSuffix
			Set @sTable2='NXT'+@sCorrelationSuffix
			
			Set @sAddFromString =	"left join (select min(convert(char(8),DueDate,112) + convert(char(11),EVENTNO) + Description + convert(char(11),EVENTTEXTID)) as EVENTDUESTRING, CASEID"
				      +char(10)+"           FROM ("
				      +char(10)+"           Select CE.CASEID, CE.EVENTNO, CE.EVENTDUEDATE as DueDate,cast("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+" as nchar(100)) as Description, isnull(CET.EVENTTEXTID,'') as EVENTTEXTID"
				      +char(10)+"           from OPENACTION O with (NOLOCK)"
				      +char(10)+"           join ACTIONS A with (NOLOCK) on (A.ACTION=O.ACTION)"
				      +char(10)+"           join EVENTCONTROL EC with (NOLOCK) on (EC.CRITERIANO=O.CRITERIANO)"
				      +char(10)+"           join EVENTS E with (NOLOCK) on (EC.EVENTNO=E.EVENTNO)"
				      +char(10)+"           join CASEEVENT CE with (NOLOCK) on (CE.CASEID=O.CASEID"
				      +char(10)+"           	                 and CE.EVENTNO=EC.EVENTNO"
				      +char(10)+"           	                 and CE.OCCURREDFLAG=0"
				      +char(10)+"           	                 and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN O.CYCLE ELSE CE.CYCLE END"
				      +char(10)+"           	                 and CE.EVENTDUEDATE>=convert(nvarchar,GETDATE(),106))"
				      +char(10)+"           left join CASEEVENTTEXT CET with (NOLOCK) on (CET.CASEID=CE.CASEID"
				      +char(10)+"                                                     and CET.EVENTNO=CE.EVENTNO"
				      +char(10)+"                                                     and CET.CYCLE  =CE.CYCLE"
				      +char(10)+"                                                     and CET.EVENTTEXTID=(select ET1.EVENTTEXTID from EVENTTEXT ET1 where ET1.EVENTTEXTID=CET.EVENTTEXTID and ET1.EVENTTEXTTYPEID is null))"
						
			If @pbExternalUser=1
			Begin
				Set @sAddFromString1=null
				--------------------------------
				-- Restrict available Events for
				-- external users.
				--------------------------------
				Set @sAddFromString=@sAddFromString
						+char(10)+"           join #TEMPEVENTS FUE on (FUE.EVENTNO=CE.EVENTNO)"
			End
			Else Begin
				---------------------------------------
				-- Internal users should also consider
				-- any ad hoc alerts that have been set
				-- against the Case.
				---------------------------------------
				Set @sAddFromString1=	
						"           UNION ALL"
				      +char(10)+"           Select A.CASEID, null, A.DUEDATE, cast(A.ALERTMESSAGE as nchar(100)),''"
				      +char(10)+"           from ALERT A with (NOLOCK)"
				      +char(10)+"           Where A.DUEDATE>=convert(nvarchar,GETDATE(),106) and ISNULL(A.OCCURREDFLAG,0) = 0"
			End

			Set @sAddFromString=@sAddFromString+
					+char(10)+"           where O.POLICEEVENTS=1"
					

			-----------------------------------------------------------------
			-- RFC40200
			-- If the filter Action is not ~2 (Renewals - Law Update Service)
			-- then explicitly filter out the ~2 Open Action
			-----------------------------------------------------------------				
			If isnull(@sActionKeys,'') not like '%~2%'
			or @nActionOperator>0
				Set @sAddFromString=@sAddFromString
					+char(10)+" and (O.ACTION<>'~2' OR E.CONTROLLINGACTION='~2')" --SQA16423

			-- Any OpenAction can be used for the Event and not just the ControllingAction
			If @bAnyOpenAction=1
			Begin
				If @sRenewalAction is not NULL
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and ((O.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR CE.EVENTNO<>-11 )"
			End
			Else Begin
				If @sRenewalAction is not NULL
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and ((O.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR (CE.EVENTNO<>-11 and O.ACTION=isnull(E.CONTROLLINGACTION,O.ACTION)))"
				Else
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and O.ACTION=isnull(E.CONTROLLINGACTION,O.ACTION)"
			End
			
			--------------------------------------------------------------------------------
			-- Restrict Events that were created either by a Renewals type Action or not.
			-- Note that if both options have been selected then no restriction is required.
			--------------------------------------------------------------------------------
			If (@bIsRenewalsOnlyFilter   =1 and isnull(@bIsNonRenewalsOnlyFilter,0)=0)
			or (@bIsNonRenewalsOnlyFilter=1 and isnull(@bIsRenewalsOnlyFilter   ,0)=0)
			Begin

				If @bIsRenewalsOnly=1
					Set @sAddFromString=@sAddFromString+char(10)+"           and A.ACTIONTYPEFLAG=1"
				Else
					Set @sAddFromString=@sAddFromString+char(10)+"           and isnull(A.ACTIONTYPEFLAG,0)<>1"
			End

			--------------------------------------------------------------------------------
			-- If no Event has been specified and a date range is required then filter
			-- next due date by the provided date range if Due Date filtering is required.
			--------------------------------------------------------------------------------
			If  @nEventDateFilterOperator = 7
			and @sEventFilterKeys is null
			and @bByDueDate = 1
			Begin
				-------------------------------------------------------------------------------------------------
				-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
				-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
				-- current date.  If Quantity is positive, the current date is the From date and the derived date
				-- the To date.  If Quantity is negative, the current date is the To date and the derived date 
				-- the From date.
				-------------------------------------------------------------------------------------------------
				If @sPeriodType is not null
				and @nPeriodQuantity is not null
				Begin
					If @nPeriodQuantity > 0 
					Begin
						Set @dtDateRangeFilterFrom 	= getdate()					

						Set @sSQLString = "Set @dtDateRangeFilterTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterFrom) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterTo		datetime 		output,
			 					  @sPeriodType			nvarchar(1),
								  @nPeriodQuantity		smallint,
								  @dtDateRangeFilterFrom	datetime',
			  					  @dtDateRangeFilterTo		= @dtDateRangeFilterTo 	output,
								  @sPeriodType			= @sPeriodType,
								  @nPeriodQuantity		= @nPeriodQuantity,
								  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom					  
					End
					Else
					Begin
						Set @dtDateRangeFilterTo	= getdate()

						Set @sSQLString = "Set @dtDateRangeFilterFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterTo) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterFrom	datetime 		output,
			 					  @sPeriodType		nvarchar(1),
								  @nPeriodQuantity	smallint,
								  @dtDateRangeFilterTo	datetime',
			  					  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom 	output,
								  @sPeriodType		= @sPeriodType,
								  @nPeriodQuantity	= @nPeriodQuantity,
								  @dtDateRangeFilterTo	= @dtDateRangeFilterTo					
					End
				End
	
				If @dtDateRangeFilterFrom is not null
				or @dtDateRangeFilterTo   is not null
				Begin
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and	CE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)

					If isnull(@pbExternalUser,0)=0
						Set @sAddFromString1=@sAddFromString1
						+char(10)+"           and	A.DUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)
				End
			End
			------------------------------------------------------------
			-- If the Importance Level has been supplied as a qualifier
			-- of the column, then only consider due dates whose Event
			-- is equal to or higher than that level of Importance Level
			------------------------------------------------------------
			If @sQualifier is not null
			Begin
			        Set @sAddFromString=@sAddFromString
					+char(10)+"           and coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0)>="+@sQualifier
					
				If @sAddFromString1 is not null
					Set @sAddFromString1=@sAddFromString1
					+char(10)+"           and A.IMPORTANCELEVEL>="+@sQualifier
			End
			------------------------------------------------------------
			-- If there is no Importance Level passed as a qualifier but
			-- the user has entered an importance level filter, then use
			-- the entered filter.
			------------------------------------------------------------
			Else If @nImpLevelFilterOperator is not null
			   and (@sImpLevelFilterFrom is not null or @sImpLevelFilterTo is not null)
			Begin
			        Set @sAddFromString=@sAddFromString
					+char(10)+"           and coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0)"+dbo.fn_ConstructOperator(@nImpLevelFilterOperator,@String,@sImpLevelFilterFrom,@sImpLevelFilterTo,@pbCalledFromCentura)
					
				If @sAddFromString1 is not null
					Set @sAddFromString1=@sAddFromString1
					+char(10)+"           and A.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImpLevelFilterOperator,@String,@sImpLevelFilterFrom,@sImpLevelFilterTo,@pbCalledFromCentura)
			End
			
			Set @sAddFromString=@sAddFromString+
					+char(10)+@sAddFromString1 + ") XX"
					+char(10)+"           group by CASEID) "+@sTable1+" on ("+@sTable1+".CASEID=C.CASEID)"
					+char(10)+"left join EVENTTEXT "+@sTable2+" on ("+@sTable2+".EVENTTEXTID=cast(substring("+@sTable1+".EVENTDUESTRING,120,11) as int))"

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin	
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+6
			End

			If @sColumn='NextDueDate'
				Set @sTableColumn='convert(datetime, left('+@sTable1+'.EVENTDUESTRING,8))'
			Else If @sColumn='NextDueEvent'
				Set @sTableColumn='substring('+@sTable1+'.EVENTDUESTRING,20,100)'
			Else If @sColumn='NextDueEventNo'
				Set @sTableColumn='substring('+@sTable1+'.EVENTDUESTRING,9,11)'
			Else If @sColumn='NextDueText'
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,@sTable2,@sLookupCulture,@pbCalledFromCentura)
		End

		Else If @sColumn in ('EarliestDueDate',
				     'EarliestDueEvent')
		Begin
			Set @sAddFromString =	"left join (select min(convert(char(8),CE.EVENTDUEDATE,112) + "+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+") as EVENTDUESTRING, O.CASEID as CASEID"
				      +char(10)+"           from OPENACTION O with (NOLOCK)"
				      +char(10)+"           join ACTIONS A with (NOLOCK) on (A.ACTION=O.ACTION)"
				      +char(10)+"           join EVENTCONTROL EC with (NOLOCK) on (EC.CRITERIANO=O.CRITERIANO)"
				      +char(10)+"           join EVENTS E with (NOLOCK) on (EC.EVENTNO=E.EVENTNO)"
				      +char(10)+"           join CASEEVENT CE with (NOLOCK) on (CE.CASEID=O.CASEID"
				      +char(10)+"           	                 and CE.EVENTNO=EC.EVENTNO"
				      +char(10)+"           	                 and CE.OCCURREDFLAG=0"
				      +char(10)+"           	                 and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN O.CYCLE ELSE CE.CYCLE END)"

			If @pbExternalUser=1
			Begin
				Set @sAddFromString=@sAddFromString
						+char(10)+"           join #TEMPEVENTS FUE on (FUE.EVENTNO=CE.EVENTNO)"
			End

			Set @sAddFromString=@sAddFromString+
					+char(10)+"           where O.POLICEEVENTS=1"
					

			-----------------------------------------------------------------
			-- RFC40200
			-- If the filter Action is not ~2 (Renewals - Law Update Service)
			-- then explicitly filter out the ~2 Open Action
			-----------------------------------------------------------------				
			If isnull(@sActionKeys,'') not like '%~2%'
			or @nActionOperator>0
				Set @sAddFromString=@sAddFromString
					+char(10)+" and (O.ACTION<>'~2' OR E.CONTROLLINGACTION='~2')" --SQA16423

			-- Any OpenAction can be used for the Event and not just the ControllingAction
			If @bAnyOpenAction=1
			Begin
				If @sRenewalAction is not NULL
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and ((O.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR CE.EVENTNO<>-11 )"
			End
			Else Begin
				If @sRenewalAction is not NULL
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and ((O.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR (CE.EVENTNO<>-11 and O.ACTION=isnull(E.CONTROLLINGACTION,O.ACTION)))"
				Else
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and O.ACTION=isnull(E.CONTROLLINGACTION,O.ACTION)"
			End
			
			--------------------------------------------------------------------------------
			-- Restrict Events that were created either by a Renewals type Action or not.
			-- Note that if both options have been selected then no restriction is required.
			--------------------------------------------------------------------------------
			If (@bIsRenewalsOnlyFilter   =1 and isnull(@bIsNonRenewalsOnlyFilter,0)=0)
			or (@bIsNonRenewalsOnlyFilter=1 and isnull(@bIsRenewalsOnlyFilter   ,0)=0)
			Begin

				If @bIsRenewalsOnly=1
					Set @sAddFromString=@sAddFromString+char(10)+"           and A.ACTIONTYPEFLAG=1"
				Else
					Set @sAddFromString=@sAddFromString+char(10)+"           and isnull(A.ACTIONTYPEFLAG,0)<>1"
			End

			--------------------------------------------------------------------------------
			-- If no Event has been specified and a date range is required then filter
			-- next due date by the provided date range if Due Date filtering is required.
			--------------------------------------------------------------------------------
			If  @nEventDateFilterOperator = 7
			and @sEventFilterKeys is null
			and @bByDueDate = 1
			Begin
				-------------------------------------------------------------------------------------------------
				-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
				-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
				-- current date.  If Quantity is positive, the current date is the From date and the derived date
				-- the To date.  If Quantity is negative, the current date is the To date and the derived date 
				-- the From date.
				-------------------------------------------------------------------------------------------------
				If @sPeriodType is not null
				and @nPeriodQuantity is not null
				Begin
					If @nPeriodQuantity > 0 
					Begin
						Set @dtDateRangeFilterFrom 	= getdate()					

						Set @sSQLString = "Set @dtDateRangeFilterTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterFrom) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterTo		datetime 		output,
			 					  @sPeriodType			nvarchar(1),
								  @nPeriodQuantity		smallint,
								  @dtDateRangeFilterFrom	datetime',
			  					  @dtDateRangeFilterTo		= @dtDateRangeFilterTo 	output,
								  @sPeriodType			= @sPeriodType,
								  @nPeriodQuantity		= @nPeriodQuantity,
								  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom					  
					End
					Else
					Begin
						Set @dtDateRangeFilterTo	= getdate()

						Set @sSQLString = "Set @dtDateRangeFilterFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterTo) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterFrom	datetime 		output,
			 					  @sPeriodType		nvarchar(1),
								  @nPeriodQuantity	smallint,
								  @dtDateRangeFilterTo	datetime',
			  					  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom 	output,
								  @sPeriodType		= @sPeriodType,
								  @nPeriodQuantity	= @nPeriodQuantity,
								  @dtDateRangeFilterTo	= @dtDateRangeFilterTo					
					End
				End
	
				If @dtDateRangeFilterFrom is not null
				or @dtDateRangeFilterTo   is not null
				Begin
					Set @sAddFromString=@sAddFromString
						+char(10)+"           and	CE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)
				End
			End
			------------------------------------------------------------
			-- If the user has entered an importance level filter, then
			-- use the entered filter.
			------------------------------------------------------------			
			If @nImpLevelFilterOperator is not null
			and (@sImpLevelFilterFrom is not null or @sImpLevelFilterTo is not null)
			Begin
			        Set @sAddFromString=@sAddFromString
					+char(10)+"           and coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0)"+dbo.fn_ConstructOperator(@nImpLevelFilterOperator,@String,@sImpLevelFilterFrom,@sImpLevelFilterTo,@pbCalledFromCentura)
			End

			Set @sAddFromString=@sAddFromString+
					+char(10)+"           group by O.CASEID) EVDD on (EVDD.CASEID=C.CASEID)"
			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin	
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='EarliestDueDate'
				Set @sTableColumn='convert(datetime, left(EVDD.EVENTDUESTRING,8))'
			Else If @sColumn='EarliestDueEvent'
				Set @sTableColumn='substring(EVDD.EVENTDUESTRING,9,100)'
		End

		Else If @sColumn in ('EventDate',
				     'EventDueDate',
				     'EventText',
				     'EventTextType',
				     'EventTextModifiedDate')
		Begin
			Set @sTable1='CE'+@sCorrelationSuffix
			Set @sAddFromString = 'Left Join CASEEVENT '+@sTable1
			-----------------------------------------------------------
			-- RFC71701
			-- If the Event Due Date for the particular EVENTNO is
			-- to be reported and the Event Date for the same EVENTNO
			-- is NOT being reported then we can restrict the CASEEVENT
			-- rows to be returned to be Due Dates only.
			-----------------------------------------------------------
			If      exists(select 1 from @tblOutputRequests where ID='EventDueDate' and QUALIFIER=@sQualifier)
			and not exists(select 1 from @tblOutputRequests where ID='EventDate'    and QUALIFIER=@sQualifier)
			Begin
				Set @bDueDateOnly=1
			End
			Else Begin
				Set @bDueDateOnly=0
				--------------------------------------------
				-- Now check if ONLY the Event Date is to be
				-- reported and NOT the Event Due date.
				--------------------------------------------
				If      exists(select 1 from @tblOutputRequests where ID='EventDate' and QUALIFIER=@sQualifier)
				and not exists(select 1 from @tblOutputRequests where ID='EventDueDate' and QUALIFIER=@sQualifier)
					Set @bEventDateOnly=1
				Else
					Set @bEventDateOnly=0
			End
			
			Set @sDateFilter = NULL
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+replace(@sAddFromString,'_','~_')+'%' ESCAPE '~')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				------------------------------------------------------------
				-- If the result set has been filtered on an Event
				-- for a specific date range, then if that Event is being
				-- reported then the date range filter is to be applied
				------------------------------------------------------------
				If  @nEventDateFilterOperator = 7
				and(@bByDueDate = 1 OR @bByEventDate = 1)
				and @sQualifier=@sEventFilterKeys
				Begin
					-------------------------------------------------------------------------------------------------
					-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
					-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
					-- current date.  If Quantity is positive, the current date is the From date and the derived date
					-- the To date.  If Quantity is negative, the current date is the To date and the derived date 
					-- the From date.
					-------------------------------------------------------------------------------------------------
					If @sPeriodType is not null
					and @nPeriodQuantity is not null
					Begin
						If @nPeriodQuantity > 0 
						Begin
							Set @dtDateRangeFilterFrom 	= getdate()					

							Set @sSQLString = "Set @dtDateRangeFilterTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterFrom) + "')"

							execute sp_executesql @sSQLString,
									N'@dtDateRangeFilterTo		datetime 		output,
			 						  @sPeriodType			nvarchar(1),
									  @nPeriodQuantity		smallint,
									  @dtDateRangeFilterFrom	datetime',
			  						  @dtDateRangeFilterTo		= @dtDateRangeFilterTo 	output,
									  @sPeriodType			= @sPeriodType,
									  @nPeriodQuantity		= @nPeriodQuantity,
									  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom					  
						End
						Else
						Begin
							Set @dtDateRangeFilterTo	= getdate()

							Set @sSQLString = "Set @dtDateRangeFilterFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterTo) + "')"

							execute sp_executesql @sSQLString,
									N'@dtDateRangeFilterFrom	datetime 		output,
			 						  @sPeriodType		nvarchar(1),
									  @nPeriodQuantity	smallint,
									  @dtDateRangeFilterTo	datetime',
			  						  @dtDateRangeFilterFrom	= @dtDateRangeFilterFrom 	output,
									  @sPeriodType		= @sPeriodType,
									  @nPeriodQuantity	= @nPeriodQuantity,
									  @dtDateRangeFilterTo	= @dtDateRangeFilterTo					
						End
					End
	
					If @dtDateRangeFilterFrom is not null
					or @dtDateRangeFilterTo   is not null
					Begin
						--------------------------------------------------------
						-- Now create the date filter depending on whether it is
						-- the EventDate and/or the EventDueDate being filtered.
						--------------------------------------------------------
						If @bByEventDate=1
						Begin
							Set @sDateFilter="                                 	and ("+@sTable1+".EVENTDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)

							If @bByDueDate=1
								Set @sDateFilter=@sDateFilter+char(10)+"                                 	OR ("+@sTable1+".OCCURREDFLAG=0 and "+@sTable1+".EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)+")"

							Set @sDateFilter=@sDateFilter+")"
						End
						Else Begin
							Set @sDateFilter="                                 	and "+@sTable1+".OCCURREDFLAG=0 and "+@sTable1+".EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)
						End
					End
				End	
										
				Set @sAddFromString = "Left Join CASEEVENT "+@sTable1+"	 with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 	and "+@sTable1+".EVENTNO="+@sQualifier
						   
				If @bDueDateOnly=1
				Begin
					Set @sAddFromString = @sAddFromString
						   +char(10)+"                                 	and "+@sTable1+".OCCURREDFLAG=0"
				End
				Else If @bEventDateOnly=1
				Begin
					Set @sAddFromString = @sAddFromString
						   +char(10)+"                                 	and "+@sTable1+".OCCURREDFLAG between 1 and 8"
				End

				If @sDateFilter is not null
					Set  @sAddFromString = @sAddFromString+char(10)+@sDateFilter

				If @pbExternalUser=1
				Begin
					Set @sAddFromString = @sAddFromString+
						   +char(10)+"					and exists (select 1 from #TEMPEVENTS "+@sTable1+"_FUE where ("+@sTable1+"_FUE.EVENTNO="+@sTable1+".EVENTNO))"
				End

				Set @sAddFromString = @sAddFromString+")"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End

			-- SQA18562 ensure the due date reported is actually due
			If @sColumn = 'EventDueDate'
			Begin
				Set @sTable2='DDEV'+@sCorrelationSuffix
				Set @sTable3='DDAC'+@sCorrelationSuffix
				Set @sTable4='DDOA'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join EVENTS '+@sTable2
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+replace(@sAddFromString,'_','~_')+'%' ESCAPE '~')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin							
					Set @sAddFromString ="Left Join EVENTS "    +@sTable2+" with (NOLOCK) on ("+@sTable2+".EVENTNO="+@sTable1+".EVENTNO)"
						   +char(10)+"Left Join ACTIONS "   +@sTable3+" with (NOLOCK) on ("+@sTable3+".ACTION=isnull("+@sTable2+".CONTROLLINGACTION,"+@sTable1+".CREATEDBYACTION))"
						   +char(10)+"Left Join OPENACTION "+@sTable4+" with (NOLOCK) on ("+@sTable4+".CASEID="+@sTable1+".CASEID"
						   +char(10)+" 				and "+@sTable4+".ACTION="+@sTable3+".ACTION"
						   +char(10)+" 				and "+@sTable4+".CYCLE=CASE WHEN("+@sTable3+".NUMCYCLESALLOWED=1) THEN 1 ELSE "+@sTable1+".CYCLE END"
						   +char(10)+" 				and "+@sTable4+".POLICEEVENTS=1)"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+3
				End
			End

			-- RFC43207 Changed data structure for text associated with CaseEvent
			If @sColumn in ('EventText',
					'EventTextType',
					'EventTextModifiedDate')
			Begin
				Set @sTable5='CET'+@sCorrelationSuffix
				Set @sTable6='ET' +@sCorrelationSuffix
				Set @sAddFromString = 'Left Join CASEEVENTTEXT '+@sTable5
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+replace(@sAddFromString,'_','~_')+'%' ESCAPE '~')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin							
					Set @sAddFromString ="Left Join CASEEVENTTEXT "+@sTable5+" with (NOLOCK) on ("+@sTable5+".CASEID ="+@sTable1+".CASEID"
						   +char(10)+"                                                   and "+@sTable5+".EVENTNO="+@sTable1+".EVENTNO"
						   +char(10)+"                                                   and "+@sTable5+".CYCLE  ="+@sTable1+".CYCLE)"
						   +char(10)+"Left Join EVENTTEXT "    +@sTable6+" with (NOLOCK) on ("+@sTable6+".EVENTTEXTID="+@sTable5+".EVENTTEXTID)"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+2
				End
				
				If @sColumn in ('EventTextType') or @pbExternalUser=1
				Begin
					Set @sTable7='ETT'+@sCorrelationSuffix
					Set @sAddFromString = 'Left Join EVENTTEXTTYPE '+@sTable7
			
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+replace(@sAddFromString,'_','~_')+'%' ESCAPE '~')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin							
						Set @sAddFromString ="Left Join EVENTTEXTTYPE "+@sTable7+" with (NOLOCK) on ("+@sTable7+".EVENTTEXTTYPEID="+@sTable6+".EVENTTEXTTYPEID)"

						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom, 
									@psSeparator    =@sReturn,
									@pbForceLoad=0

						Set @pnTableCount=@pnTableCount+1
					End
				End
			End

			If @sColumn='EventDate'
			Begin
				Set @sTableColumn=@sTable1+'.EVENTDATE'
			End
			Else If @sColumn='EventDueDate'
			Begin
				--SQA18562 only report the due date if it is actually due
				Set @sTableColumn='CASE WHEN('+@sTable1+'.OCCURREDFLAG=0 and '+@sTable4+'.CASEID is not null) THEN '+@sTable1+'.EVENTDUEDATE ELSE NULL END'
			End
			Else If @sColumn in ('EventText',
			                     'EventTextModifiedDate', 
			                     'EventTextType')
			Begin
				Set @sTableColumn=CASE(@sColumn) WHEN('EventText')             THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,@sTable6,@sLookupCulture,@pbCalledFromCentura) 
								 WHEN('EventTextModifiedDate') THEN @sTable6+'.LOGDATETIMESTAMP'
								 WHEN('EventTextType')         THEN dbo.fn_SqlTranslatedColumn('EVENTTEXTTYPE','DESCRIPTION',null,@sTable7,@sLookupCulture,@pbCalledFromCentura)
						  END
			
				---------------------------------------
				-- RFC43207
				-- Apply any of the filter restrictions
				-- to the text being returned if the
				-- filter has not already been added.
				---------------------------------------
				If (@nEventNoteTypeKeysOperator is not null and PATINDEX ('%and '+@sTable6+'.EVENTTEXT %',       @sCurrentWhereString)=0)
				or (@nEventNoteTextOperator     is not null and PATINDEX ('%and '+@sTable6+'.EVENTTEXTTYPEID %', @sCurrentWhereString)=0)
				Begin
					If @nEventNoteTextOperator is not null
						Set @sAddWhereString =  "and "+@sTable6+".EVENTTEXT "+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
										   
					If  @nEventNoteTypeKeysOperator is not null
						Set @sAddWhereString =  @sAddWhereString+char(10)+"and "+@sTable6+".EVENTTEXTTYPEID "+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)

					exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentWhereString	OUTPUT,
									@psAddString	=@sAddWhereString,
									@psComponentType=@sWhere,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
				End

                                If @pbExternalUser=1
                                Begin
                                        Set @sAddWhereString =  @sAddWhereString+char(10)+ "and ("+@sTable6+".EVENTTEXTTYPEID is null or "+@sTable7+".ISEXTERNAL = 1)"

                                        exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentWhereString	OUTPUT,
									@psAddString	=@sAddWhereString,
									@psComponentType=@sWhere,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
                                End
			End
		End

		Else If @sColumn='OpenEventOrDue'
		Begin
			Set @sTableColumn=	  "(select min(isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"
					+char(10)+" from CASEEVENT CE with (NOLOCK)"
					+char(10)+" join EVENTS EV with (NOLOCK)	on (EV.EVENTNO=CE.EVENTNO)"
					+char(10)+CASE WHEN(@bAnyOpenAction=1)
							THEN " join ACTIONS AC	with (NOLOCK) on (AC.ACTION=CE.CREATEDBYACTION)"
							ELSE " join ACTIONS AC	with (NOLOCK) on (AC.ACTION=isnull(EV.CONTROLLINGACTION,CE.CREATEDBYACTION))"
					          END
					+char(10)+" join OPENACTION O	 with (NOLOCK) on (O.CASEID=CE.CASEID"
					+char(10)+" 			and O.ACTION=AC.ACTION"
					+char(10)+" 			and O.CYCLE=CASE WHEN(AC.NUMCYCLESALLOWED=1) THEN 1 ELSE CE.CYCLE END"
					+char(10)+" 			and O.CYCLE=(select min(O1.CYCLE)"
					+char(10)+" 					from OPENACTION O1 with (NOLOCK)"
					+char(10)+" 					where O1.CASEID=CE.CASEID"
					+char(10)+" 					and O1.ACTION=O.ACTION"
					+char(10)+" 					and O1.POLICEEVENTS=1))"

			-- Only events the external user has access to will be returned.
			If @pbExternalUser=1
			Begin
				Set @sTableColumn=@sTableColumn
					+char(10)+" join #TEMPEVENTS FUE on (FUE.EVENTNO=CE.EVENTNO)"
			End
		
			Set @sTableColumn=@sTableColumn					
					+char(10)+"  where CE.CASEID=C.CASEID"
				   	+char(10)+"  and CE.EVENTNO="+@sQualifier

			------------------------------------------------------------
			-- If the result set has been filtered on an Event
			-- for a specific date range, then if that Event is being
			-- reported then the date range filter is to be applied
			------------------------------------------------------------
			Set @sDateFilter = NULL
			
			If  @nEventDateFilterOperator = 7
			and(@bByDueDate = 1 OR @bByEventDate = 1)
			and @sQualifier=@sEventFilterKeys
			Begin
				-------------------------------------------------------------------------------------------------
				-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
				-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
				-- current date.  If Quantity is positive, the current date is the From date and the derived date
				-- the To date.  If Quantity is negative, the current date is the To date and the derived date 
				-- the From date.
				-------------------------------------------------------------------------------------------------
				If @sPeriodType is not null
				and @nPeriodQuantity is not null
				Begin
					If @nPeriodQuantity > 0 
					Begin
						Set @dtDateRangeFilterFrom 	= getdate()					

						Set @sSQLString = "Set @dtDateRangeFilterTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterFrom) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterTo		datetime 		output,
			 						@sPeriodType			nvarchar(1),
									@nPeriodQuantity		smallint,
									@dtDateRangeFilterFrom	datetime',
			  						@dtDateRangeFilterTo		= @dtDateRangeFilterTo 	output,
									@sPeriodType			= @sPeriodType,
									@nPeriodQuantity		= @nPeriodQuantity,
									@dtDateRangeFilterFrom	= @dtDateRangeFilterFrom					  
					End
					Else
					Begin
						Set @dtDateRangeFilterTo	= getdate()

						Set @sSQLString = "Set @dtDateRangeFilterFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterTo) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterFrom	datetime 		output,
			 						@sPeriodType		nvarchar(1),
									@nPeriodQuantity	smallint,
									@dtDateRangeFilterTo	datetime',
			  						@dtDateRangeFilterFrom	= @dtDateRangeFilterFrom 	output,
									@sPeriodType		= @sPeriodType,
									@nPeriodQuantity	= @nPeriodQuantity,
									@dtDateRangeFilterTo	= @dtDateRangeFilterTo					
					End
				End
	
				If @dtDateRangeFilterFrom is not null
				or @dtDateRangeFilterTo   is not null
				Begin
					--------------------------------------------------------
					-- Now create the date filter depending on whether it is
					-- the EventDate and/or the EventDueDate being filtered.
					--------------------------------------------------------
					If @bByEventDate=1
					Begin
						Set @sDateFilter="  and (CE.EVENTDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)

						If @bByDueDate=1
							Set @sDateFilter=@sDateFilter+char(10)+"   OR (CE.OCCURREDFLAG=0 and CE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)+")"

						Set @sDateFilter=@sDateFilter+")"
					End
					Else Begin
						Set @sDateFilter="  and CE.OCCURREDFLAG=0 and CE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)
					End
				End

				If @sDateFilter is not null
					Set @sTableColumn=@sTableColumn+char(10)+@sDateFilter
			End

			-----------------------------------------------------------------
			-- RFC40200
			-- If the filter Action is not ~2 (Renewals - Law Update Service)
			-- then explicitly filter out the ~2 Open Action
			-----------------------------------------------------------------				
			If isnull(@sActionKeys,'') not like '%~2%'
			or @nActionOperator>0
				Set @sTableColumn=@sTableColumn
				   	+char(10)+"  and (AC.ACTION<>'~2' OR EV.CONTROLLINGACTION='~2')"

			If @sRenewalAction is NULL
				Set @sTableColumn=@sTableColumn+")"
			else
				Set @sTableColumn=@sTableColumn
					+char(10)+"  and ((O.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR CE.EVENTNO<>-11))"					
		End

		Else If @sColumn='OpenRenewalEventOrDue'
		Begin
			Set @sTableColumn=	  "(select isnull(CE.EVENTDATE,CE.EVENTDUEDATE)"
					+char(10)+" from CASEEVENT CE"
					+char(10)+" join OPENACTION O with (NOLOCK) on (O.CASEID=CE.CASEID"
					+char(10)+" 			and O.ACTION='"+@sRenewalAction+"'"
					+char(10)+" 			and O.CYCLE=CE.CYCLE"
					+char(10)+" 			and O.CYCLE=(select min(O1.CYCLE)"
					+char(10)+" 					from OPENACTION O1 with (NOLOCK)"
					+char(10)+" 					where O1.CASEID=CE.CASEID"
					+char(10)+" 					and O1.ACTION=O.ACTION"
					+char(10)+" 					and O1.POLICEEVENTS=1))"			

			-- Only events the external user has access to will be returned.
			If @pbExternalUser=1
			Begin
				Set @sTableColumn=@sTableColumn
					+char(10)+" join #TEMPEVENTS FUE on (FUE.EVENTNO=CE.EVENTNO)"
			End

			Set @sTableColumn=@sTableColumn
					+char(10)+"  where CE.CASEID=C.CASEID"
				   	+char(10)+"  and CE.EVENTNO="+@sQualifier

			------------------------------------------------------------
			-- If the result set has been filtered on an Event
			-- for a specific date range, then if that Event is being
			-- reported then the date range filter is to be applied
			------------------------------------------------------------
			Set @sDateFilter = NULL
			
			If  @nEventDateFilterOperator = 7
			and(@bByDueDate = 1 OR @bByEventDate = 1)
			and @sQualifier=@sEventFilterKeys
			Begin
				-------------------------------------------------------------------------------------------------
				-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
				-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
				-- current date.  If Quantity is positive, the current date is the From date and the derived date
				-- the To date.  If Quantity is negative, the current date is the To date and the derived date 
				-- the From date.
				-------------------------------------------------------------------------------------------------
				If @sPeriodType is not null
				and @nPeriodQuantity is not null
				Begin
					If @nPeriodQuantity > 0 
					Begin
						Set @dtDateRangeFilterFrom 	= getdate()					

						Set @sSQLString = "Set @dtDateRangeFilterTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterFrom) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterTo		datetime 		output,
			 						@sPeriodType			nvarchar(1),
									@nPeriodQuantity		smallint,
									@dtDateRangeFilterFrom	datetime',
			  						@dtDateRangeFilterTo		= @dtDateRangeFilterTo 	output,
									@sPeriodType			= @sPeriodType,
									@nPeriodQuantity		= @nPeriodQuantity,
									@dtDateRangeFilterFrom	= @dtDateRangeFilterFrom					  
					End
					Else
					Begin
						Set @dtDateRangeFilterTo	= getdate()

						Set @sSQLString = "Set @dtDateRangeFilterFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterTo) + "')"

						execute sp_executesql @sSQLString,
								N'@dtDateRangeFilterFrom	datetime 		output,
			 						@sPeriodType		nvarchar(1),
									@nPeriodQuantity	smallint,
									@dtDateRangeFilterTo	datetime',
			  						@dtDateRangeFilterFrom	= @dtDateRangeFilterFrom 	output,
									@sPeriodType		= @sPeriodType,
									@nPeriodQuantity	= @nPeriodQuantity,
									@dtDateRangeFilterTo	= @dtDateRangeFilterTo					
					End
				End
	
				If @dtDateRangeFilterFrom is not null
				or @dtDateRangeFilterTo   is not null
				Begin
					--------------------------------------------------------
					-- Now create the date filter depending on whether it is
					-- the EventDate and/or the EventDueDate being filtered.
					--------------------------------------------------------
					If @bByEventDate=1
					Begin
						Set @sDateFilter="  and (CE.EVENTDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)

						If @bByDueDate=1
							Set @sDateFilter=@sDateFilter+char(10)+"   OR (CE.OCCURREDFLAG=0 and CE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)+")"

						Set @sDateFilter=@sDateFilter+")"
					End
					Else Begin
						Set @sDateFilter="  and CE.OCCURREDFLAG=0 and CE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)
					End
				End

				If @sDateFilter is not null
					Set @sTableColumn=@sTableColumn+char(10)+@sDateFilter
			End
			

			Set @sTableColumn=@sTableColumn+')'				
		End

		Else If @sColumn='OfficialNumber'
		Begin
			Set @sTable1='O'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.OFFICIALNUMBER'
			Set @sAddFromString = 'Left Join OFFICIALNUMBERS '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join OFFICIALNUMBERS "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 	and "+@sTable1+".ISCURRENT=1"
						   +char(10)+"                                 	and "+@sTable1+".NUMBERTYPE=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)
						   +char(10)+"					and exists (select * from dbo.fn_FilterUserNumberTypes("+convert(varchar,@pnUserIdentityId)+",null,"+cast(@pbExternalUser as nvarchar(1))+","+cast(@pbCalledFromCentura as nvarchar(1))+ ") "+@sTable1+"_FNT where "+@sTable1+"_FNT.NUMBERTYPE="+@sTable1+".NUMBERTYPE))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='NumberTypeEventDate'
		Begin
			Set @sTable1='NT'+@sCorrelationSuffix
			Set @sTable2='NE'+@sCorrelationSuffix
			Set @sTableColumn=@sTable2+'.EVENTDATE'
			Set @sAddFromString = 'Left Join NUMBERTYPES '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join NUMBERTYPES "+@sTable1+" with (NOLOCK) on ("+@sTable1+".NUMBERTYPE=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)
						  +char(10)+"					and exists (select * from dbo.fn_FilterUserNumberTypes("+convert(varchar,@pnUserIdentityId)+",null,"+cast(@pbExternalUser as nvarchar(1))+","+cast(@pbCalledFromCentura as nvarchar(1))+ ") "+@sTable1+"_FNT where "+@sTable1+"_FNT.NUMBERTYPE="+@sTable1+".NUMBERTYPE))"
						  +char(10)+"Left Join CASEEVENT "  +@sTable2+" with (NOLOCK) on ("+@sTable2+".CASEID=C.CASEID"
						  +char(10)+"                                  	and "+@sTable2+".CYCLE=1"
						  +char(10)+"                 	       		and "+@sTable2+".EVENTNO="+@sTable1+".RELATEDEVENTNO)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+3
			End
		End

		Else If @sColumn='AgeOfCase'
		Begin
			Set @sTableColumn=	  "(select CASE(VP.ANNUITYTYPE)"
					+char(10)+"		WHEN(0) THEN NULL"
					+char(10)+"		WHEN(1) THEN floor(datediff(mm,CE1.EVENTDATE, isnull(CE.EVENTDUEDATE,CE.EVENTDATE))/12)+isnull(VP.OFFSET,0)"
					+char(10)+"		WHEN(2) THEN CE.CYCLE+isnull(VP.CYCLEOFFSET,0)"
					+char(10)+"	   END"
					+char(10)+" from CASEEVENT CE with (NOLOCK)"
					+char(10)+" join CASEEVENT CE1 with (NOLOCK)	on (CE1.CASEID=CE.CASEID"
					+char(10)+"			           	and CE1.EVENTNO=-9"
					+char(10)+"				       	and CE1.CYCLE=1)"
					+char(10)+" join OPENACTION O with (NOLOCK)	on (O.CASEID=CE.CASEID"
					+char(10)+" 				and O.ACTION='"+@sRenewalAction+"'"
					+char(10)+" 				and O.CYCLE=CE.CYCLE"
					+char(10)+" 				and O.CYCLE=(select min(O1.CYCLE)"
					+char(10)+" 					from OPENACTION O1 with (NOLOCK)"
					+char(10)+" 					where O1.CASEID=CE.CASEID"
					+char(10)+" 					and O1.ACTION=O.ACTION"
					+char(10)+" 					and O1.POLICEEVENTS=1))"
					+char(10)+"  where CE.CASEID=C.CASEID"
					+char(10)+"  and CE.EVENTNO=-11)"

			Set @sAddFromString = 'Join VALIDPROPERTY VP'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE"
				                   +char(10)+"                     		and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)"
				                   +char(10)+"                     		                      from VALIDPROPERTY VP1 with (NOLOCK)"
				                   +char(10)+"                     		                      where VP1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                     		                      and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn in ('Text',	
				     'TrademarkClass')	-- RFC52415
		Begin
			Set @sTable1='CT'+@sCorrelationSuffix
			
			If @sColumn='Text'
				-- When the Union is used in the Select statement, cast the Text column 
				-- as nvarchar(max) to avoid SQL error:
				Set @sTableColumn='CAST(isnull('+@sTable1+'.TEXT,'+@sTable1+'.SHORTTEXT) as nvarchar(max))'
			Else
				Set @sTableColumn=@sTable1+'.CLASS'
				

			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By	
			Set @sAddFromString = 'Left Join CASETEXT '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join dbo.fn_FilterUserTextTypes("+cast(@pnUserIdentityId as varchar(12)) + ",null," + isnull(cast(@pbExternalUser as varchar(4)),@pbCalledFromCentura) + ", " + convert(varchar,@pbCalledFromCentura) + ") "+@sTable1+"_TXT"+" on ("+@sTable1+"_TXT"+".TEXTTYPE="+ dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)+")"+char(10)+
				 		   "Left Join CASETEXT "+@sTable1+" with (NOLOCK)	on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".TEXTTYPE=" + @sTable1+"_TXT"+".TEXTTYPE"
						   +char(10)+"						and convert(char(6),"+@sTable1+".TEXTNO)="
						   +char(10)+"							(select substring(max("
						   +char(10)+"								CASE WHEN(CT.LANGUAGE="+@sLanguage+") THEN '2'"
						   +char(10)+"								     WHEN(CT.LANGUAGE=SCRL.COLINTEGER) THEN '1' ELSE '0'"
						   +char(10)+"								END + convert(char(23),isnull(CT.MODIFIEDDATE,''),21)+convert(char(6),CT.TEXTNO) ),25,6)"
						   +char(10)+"							from CASETEXT CT with (NOLOCK)"
						   +char(10)+"							left join SITECONTROL SCRL  with (NOLOCK)on (SCRL.CONTROLID = 'LANGUAGE')"
						   +char(10)+"							where CT.CASEID="+@sTable1+".CASEID"
						   +char(10)+"							and CT.TEXTTYPE="+@sTable1+".TEXTTYPE"
						   +char(10)+"							and (CT.CLASS="+@sTable1+".CLASS OR (CT.CLASS is null and "+@sTable1+".CLASS is null))"
						   +char(10)+"							and (CT.LANGUAGE in (SCRL.COLINTEGER, "+@sLanguage+") OR CT.LANGUAGE is null)))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='TextAll'
		Begin
			Set @sTable1='CT_ALL'+@sCorrelationSuffix

			Select @sSeparator = COLCHARACTER 
			from SITECONTROL 
			where CONTROLID = 'Default Delimiter'

			If @sSeparator is null
				Set @sSeparator=';'

			Set @sTableColumn="dbo.fn_GetConcatenatedCaseText(C.CASEID,"+ @sTable1+".TEXTTYPE,'"+@sSeparator+"')"

			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By	
			Set @sAddFromString = @sTable1+'.TEXTTYPE'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join dbo.fn_FilterUserTextTypes("+cast(@pnUserIdentityId as varchar(12)) + ",null," + isnull(cast(@pbExternalUser as varchar(4)),@pbCalledFromCentura) + ", " + convert(varchar,@pbCalledFromCentura) + ") "+@sTable1+" on ("+@sTable1+".TEXTTYPE="+ dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)+")"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('ImageData','ImageKey')
		Begin
			Set @sTable1='CI'+@sCorrelationSuffix
			Set @sTable2='I' +@sCorrelationSuffix
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By
			Set @sAddFromString = 'Left Join CASEIMAGE '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASEIMAGE "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".IMAGETYPE="+@sQualifier
						   -- The special Attachment image type used for CPA Inprostart attachments will not be shown.
						   +char(10)+"						and "+@sTable1+".IMAGETYPE != 1206"
						   +char(10)+"                               		and "+@sTable1+".IMAGESEQUENCE=(select min(CI.IMAGESEQUENCE)"
						   +char(10)+"                                				from CASEIMAGE CI with (NOLOCK)"
						   +char(10)+"                                				where CI.CASEID="+@sTable1+".CASEID"
						   +char(10)+"                                				and CI.IMAGETYPE="+@sTable1+".IMAGETYPE))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2

			End

			If @sColumn = 'ImageKey'
			Begin
				Set @sTableColumn=@sTable1+'.IMAGEID'
			End
			Else If @sColumn = 'ImageData'
			Begin
				Set @sAddFromString = 'Left Join IMAGE '+@sTable2
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join IMAGE "+@sTable2+" with (NOLOCK) on ("+@sTable2+".IMAGEID="+@sTable1+".IMAGEID)" 
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=@sTable2+'.IMAGEDATA'
				Set @bHasImageData = 1

			End

		End

		Else If @sColumn='DesigCountryCode'
		Begin
			Set @sTableColumn='DC.COUNTRYCODE'
			Set @sAddFromString = 'Left Join RELATEDCASE DC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE DC with (NOLOCK) on (DC.CASEID=C.CASEID"
					    +char(10)+"                                       and DC.RELATIONSHIP='DC1')"
					    +char(10)+"left join COUNTRYGROUP CG with(NOLOCK) on (CG.TREATYCODE=C.COUNTRYCODE"
					    +char(10)+"                                       and CG.MEMBERCOUNTRY=DC.COUNTRYCODE"
					    +char(10)+"                                       and(CG.DATECEASED>DC.LOGDATETIMESTAMP or CG.DATECEASED is null or DC.LOGDATETIMESTAMP is null))"


				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
				Set @bUseRelatedCase=1
				
				Set @sAddWhereString= 'and (DC.CASEID is null OR CG.MEMBERCOUNTRY is not null)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentWhereString	OUTPUT,
								@psAddString	=@sAddWhereString,
								@psComponentType=@sWhere,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
			End
		End

		Else If @sColumn='DesigCountryName'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'DCN',@sLookupCulture,@pbCalledFromCentura)
			Set @sAddFromString = 'Left Join RELATEDCASE DC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE DC with (NOLOCK) on (DC.CASEID=C.CASEID"
					    +char(10)+"                                       and DC.RELATIONSHIP='DC1')"
					    +char(10)+"left join COUNTRYGROUP CG with(NOLOCK) on (CG.TREATYCODE=C.COUNTRYCODE"
					    +char(10)+"                                       and CG.MEMBERCOUNTRY=DC.COUNTRYCODE"
					    +char(10)+"                                       and(CG.DATECEASED>DC.LOGDATETIMESTAMP or CG.DATECEASED is null or DC.LOGDATETIMESTAMP is null))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
				Set @bUseRelatedCase=1
				
				Set @sAddWhereString= 'and (DC.CASEID is null OR CG.MEMBERCOUNTRY is not null)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentWhereString	OUTPUT,
								@psAddString	=@sAddWhereString,
								@psComponentType=@sWhere,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
			End

			Set @sAddFromString = 'Left Join COUNTRY DCN'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join COUNTRY DCN with (NOLOCK) on (DCN.COUNTRYCODE=DC.COUNTRYCODE)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DesigCountryStatus'
		Begin
			Set @sTableColumn='DCF.FLAGNAME'

			Set @sAddFromString = 'Left Join RELATEDCASE DC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE DC with (NOLOCK) on (DC.CASEID=C.CASEID"
					    +char(10)+"                                       and DC.RELATIONSHIP='DC1')"
					    +char(10)+"left join COUNTRYGROUP CG with(NOLOCK) on (CG.TREATYCODE=C.COUNTRYCODE"
					    +char(10)+"                                       and CG.MEMBERCOUNTRY=DC.COUNTRYCODE"
					    +char(10)+"                                       and(CG.DATECEASED>DC.LOGDATETIMESTAMP or CG.DATECEASED is null or DC.LOGDATETIMESTAMP is null))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
				Set @bUseRelatedCase=1
				
				Set @sAddWhereString= 'and (DC.CASEID is null OR CG.MEMBERCOUNTRY is not null)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentWhereString	OUTPUT,
								@psAddString	=@sAddWhereString,
								@psComponentType=@sWhere,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
			End

			Set @sAddFromString = 'Left Join COUNTRYFLAGS DCF'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join COUNTRYFLAGS DCF with (NOLOCK)	on (DCF.COUNTRYCODE=C.COUNTRYCODE"
						   +char(10)+"                           		and DCF.FLAGNUMBER =DC.CURRENTSTATUS)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DesigCountryCaseStatus'
		Begin
			-- Consider if the user is external when returning the
			-- status of the case linked to the designated country.
			If @pbExternalUser=1
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'DCS',@sLookupCulture,@pbCalledFromCentura) 
			Else
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'DCS',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join RELATEDCASE DC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE DC with (NOLOCK) on (DC.CASEID=C.CASEID"
					    +char(10)+"                                       and DC.RELATIONSHIP='DC1')"
					    +char(10)+"left join COUNTRYGROUP CG with(NOLOCK) on (CG.TREATYCODE=C.COUNTRYCODE"
					    +char(10)+"                                       and CG.MEMBERCOUNTRY=DC.COUNTRYCODE"
					    +char(10)+"                                       and(CG.DATECEASED>DC.LOGDATETIMESTAMP or CG.DATECEASED is null or DC.LOGDATETIMESTAMP is null))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
				Set @bUseRelatedCase=1
				
				Set @sAddWhereString= 'and (DC.CASEID is null OR CG.MEMBERCOUNTRY is not null)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentWhereString	OUTPUT,
								@psAddString	=@sAddWhereString,
								@psComponentType=@sWhere,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
			End

			Set @sAddFromString = 'Left Join CASES DCC'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASES DCC with (NOLOCK)	on (DCC.CASEID=DC.RELATEDCASEID)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join STATUS DCS'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join STATUS DCS with (NOLOCK)	on (DCS.STATUSCODE=DCC.STATUSCODE)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('FileLocationDescription', 'BayNo', 'FilePartTitle', 'FileMovedDate','FileMovedBy', 'BayNoOrLocation')
		Begin			
                        Set @bHasFilePartColumn=1 
			Set @sAddFromString = 'Left Join CASELOCATION CL'
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASELOCATION CL on (CL.CASEID=C.CASEID"
						   +char(10)+"                       and CL.WHENMOVED in (Select MAX(WHENMOVED) from CASELOCATION CL2 
											where CL2.CASEID = C.CASEID))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End

                        If @sColumn in ('FileLocationDescription', 'BayNoOrLocation')
                        Begin
                                Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TL',@sLookupCulture,@pbCalledFromCentura)
                                Set @sAddFromString = 'Left Join TABLECODES TL' 
                         
                                If not exists(	select 1 from #TempConstructSQL T
					        where T.SavedString like '%'+@sAddFromString+'%')
			        and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			        Begin									
				        Set @sAddFromString = "Left Join TABLECODES TL on (TL.TABLECODE=CL.FILELOCATION)"
				        exec @ErrorCode=dbo.ip_LoadConstructSQL
							        @psCurrentString=@sCurrentFromString	OUTPUT,
							        @psAddString	=@sAddFromString,
							        @psComponentType=@sFrom,
							        @psSeparator    =@sReturn,
							        @pbForceLoad=0

				        Set @pnTableCount=@pnTableCount+1
			        End 
				
				If @sColumn = 'FileLocationDescription'
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TL',@sLookupCulture,@pbCalledFromCentura)
				Else
				If @sColumn = 'BayNoOrLocation'
					Set @sTableColumn='isnull(cast(CL.BAYNO as NVARCHAR(80)),'+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TL',@sLookupCulture,@pbCalledFromCentura) +')'    
                        End

                        If @sColumn='FileMovedBy'
                        Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(CL_N.NAMENO, null)'
                                Set @sAddFromString = 'Left Join NAME CL_N' 
                         
                                If not exists(	select 1 from #TempConstructSQL T
					        where T.SavedString like '%'+@sAddFromString+'%')
			        and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			        Begin									
				        Set @sAddFromString = "Left Join NAME CL_N on (CL_N.NAMENO=CL.ISSUEDBY)"
				        exec @ErrorCode=dbo.ip_LoadConstructSQL
							        @psCurrentString=@sCurrentFromString	OUTPUT,
							        @psAddString	=@sAddFromString,
							        @psComponentType=@sFrom,
							        @psSeparator    =@sReturn,
							        @pbForceLoad=0

				        Set @pnTableCount=@pnTableCount+1
			        End     
                        End
                        
                        If @sColumn='FileMovedDate'
                        Begin
			        Set @sTableColumn='CL.WHENMOVED'
                                           
		        End 
                        
                        If @sColumn='BayNo'
                        Begin
			        Set @sTableColumn=dbo.fn_SqlTranslatedColumn('BAYNO','BAYNO',null,'CL',@sLookupCulture,@pbCalledFromCentura)                                             
                                           
		        End    
                        
                        If @sColumn='FilePartTitle'
                        Begin
			        Set @sTableColumn=dbo.fn_SqlTranslatedColumn('FilePartTitle','FilePartTitle',null,'CFP',@sLookupCulture,@pbCalledFromCentura)
                                Set @sAddFromString = 'Left Join FILEPART CFP' 

                                If not exists(	select 1 from #TempConstructSQL T
					        where T.SavedString like '%'+@sAddFromString+'%')
			        and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			        Begin									
				        Set @sAddFromString = "Left Join FILEPART CFP on (CFP.CASEID=C.CASEID AND CFP.FILEPART=CL.FILEPARTID)"
				        exec @ErrorCode=dbo.ip_LoadConstructSQL
							        @psCurrentString=@sCurrentFromString	OUTPUT,
							        @psAddString	=@sAddFromString,
							        @psComponentType=@sFrom,
							        @psSeparator    =@sReturn,
							        @pbForceLoad=0

				        Set @pnTableCount=@pnTableCount+2
			        End                                                         		           
		        End           
		End               		
		Else If @sColumn='RelatedCountryName'
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCN'+@sCorrelationSuffix
			Set @sTable3='RCR' +@sCorrelationSuffix
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,@sTable2,@sLookupCulture,@pbCalledFromCentura)
			Set @sAddFromString = 'Left Join RELATEDCASE '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                          	and "+@sTable1+".RELATIONSHIP=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura) 						   

				If @pbExternalUser = 1
				Begin
					Set @sAddFromString = @sAddFromString+char(10)+"				and exists (select 1 from #TEMPCASESEXT "+@sTable1+"_FCU"+" where "+@sTable1+"_FCU"+".CASEID="+@sTable1+".CASEID"+"))"

					Set @pnTableCount=@pnTableCount+1
				End							  
				Else
				Begin
					Set @sAddFromString = @sAddFromString+")"						   
				End

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
				Set @bUseRelatedCase=1
			End

			Set @sAddFromString = 'Left Join CASES '+@sTable3
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASES "+@sTable3+" with (NOLOCK) on ("+@sTable3+".CASEID="+@sTable1+".RELATEDCASEID)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join COUNTRY '+@sTable2
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join COUNTRY "+@sTable2+" with (NOLOCK) on ("+@sTable2+".COUNTRYCODE=ISNULL("+@sTable1+".COUNTRYCODE, "+@sTable3+".COUNTRYCODE))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End
		-----------------------------------------------------
		-- RFC74524
		-- New column to report the Title of the Related Case
		-- for a parameter provided Relationship
		-----------------------------------------------------	
		Else If @sColumn='RelatedTitle'
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCN'+@sCorrelationSuffix
			Set @sTable3='RCR' +@sCorrelationSuffix
			Set @sTableColumn="ISNULL("+@sTable1+".TITLE, "+@sTable3+".TITLE)"
			Set @sAddFromString = 'Left Join RELATEDCASE '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                          	and "+@sTable1+".RELATIONSHIP=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura) 						   

				If @pbExternalUser = 1
				Begin
					Set @sAddFromString = @sAddFromString+char(10)+"				and exists (select 1 from #TEMPCASESEXT "+@sTable1+"_FCU"+" where "+@sTable1+"_FCU"+".CASEID="+@sTable1+".CASEID"+"))"

					Set @pnTableCount=@pnTableCount+1
				End							  
				Else
				Begin
					Set @sAddFromString = @sAddFromString+")"						   
				End

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
				Set @bUseRelatedCase=1
			End

			Set @sAddFromString = 'Left Join CASES '+@sTable3
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASES "+@sTable3+" with (NOLOCK) on ("+@sTable3+".CASEID="+@sTable1+".RELATEDCASEID)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='RelationshipEventDate'
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCE'+@sCorrelationSuffix
			set @sTable3='CR' +@sCorrelationSuffix
			Set @sTableColumn='isnull('+@sTable2+'.EVENTDATE, '+@sTable1+'.PRIORITYDATE)'
			Set @sAddFromString = 'Left Join RELATEDCASE '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".RELATIONSHIP=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura) 

				If @pbExternalUser = 1
				Begin
					Set @sAddFromString = @sAddFromString+char(10)+"				and exists (select 1 from #TEMPCASESEXT "+@sTable1+"_FCU"+" where "+@sTable1+"_FCU"+".CASEID="+@sTable1+".CASEID"+"))"

					Set @pnTableCount=@pnTableCount+1
				End							  
				Else Begin
					Set @sAddFromString = @sAddFromString+")"
				End

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
				Set @bUseRelatedCase=1
			End

			Set @sAddFromString = 'Left Join CASERELATION '+@sTable3
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASERELATION "+@sTable3+" with (NOLOCK) on ("+@sTable3+".RELATIONSHIP="+@sTable1+".RELATIONSHIP)"
				                   +char(10)+"Left Join CASEEVENT "   +@sTable2+" with (NOLOCK) on ("+@sTable2+".CASEID=" +@sTable1+".RELATEDCASEID"
						   +char(10)+"                         			and "+@sTable2+".EVENTNO=isnull("+@sTable3+".DISPLAYEVENTNO,"+@sTable3+".FROMEVENTNO)"
						   +char(10)+"                         			and "+@sTable2+".CYCLE=1)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('RelatedOfficialNumber',
				     'RelatedCaseCategoryDescription',
				     'RelatedSubTypeDescription',
				     'RelatedTypeOfMarkDescription',
				     'RelatedLocalClasses')
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCS'+@sCorrelationSuffix
			Set @sAddFromString = 'Left Join RELATEDCASE '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE "+@sTable1+" with (NOLOCK) on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                and "+@sTable1+".RELATIONSHIP=" + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura) 

				If @pbExternalUser = 1
				Begin
					Set @sAddFromString = @sAddFromString+char(10)+"				and exists (select 1 from #TEMPCASESEXT "+@sTable1+"_FCU"+" where "+@sTable1+"_FCU"+".CASEID="+@sTable1+".CASEID"+"))"

					Set @pnTableCount=@pnTableCount+1
				End							  
				Else Begin
					Set @sAddFromString = @sAddFromString+")"
				End

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
				Set @bUseRelatedCase=1
			End

			Set @sAddFromString = 'Left Join CASES '+@sTable2
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASES " +@sTable2+" with (NOLOCK) on ("+@sTable2+".CASEID=" +@sTable1+".RELATEDCASEID)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='RelatedCaseCategoryDescription'
			Begin
				Set @sTable3='VC'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join VALIDCATEGORY '+@sTable3
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join VALIDCATEGORY "+@sTable3+" with (NOLOCK) on ("+@sTable3+".PROPERTYTYPE="+@sTable2+".PROPERTYTYPE"
					                   +char(10)+"                          	and "+@sTable3+".CASETYPE    ="+@sTable2+".CASETYPE"
					                   +char(10)+"                          	and "+@sTable3+".CASECATEGORY="+@sTable2+".CASECATEGORY"
					                   +char(10)+"                     		and "+@sTable3+".COUNTRYCODE = (select min(VC1.COUNTRYCODE)"
					                   +char(10)+"                     	                              from VALIDCATEGORY VC1 with (NOLOCK)"
					                   +char(10)+"                     	                              where VC1.PROPERTYTYPE="+@sTable2+".PROPERTYTYPE"
					                   +char(10)+"                                  	              and   VC1.CASETYPE    ="+@sTable2+".CASETYPE"
					                   +char(10)+"                          	                      and   VC1.CASECATEGORY="+@sTable2+".CASECATEGORY"
					                   +char(10)+"                     	                              and   VC1.COUNTRYCODE in ("+@sTable2+".COUNTRYCODE, 'ZZZ')))"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,@sTable3,@sLookupCulture,@pbCalledFromCentura) 
			End

			If @sColumn='RelatedSubTypeDescription'
			Begin
				Set @sTable4='VS'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join VALIDSUBTYPE '+@sTable4
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join VALIDSUBTYPE "+@sTable4+" with (NOLOCK) on ("+@sTable4+".PROPERTYTYPE="+@sTable2+".PROPERTYTYPE"
				                   +char(10)+"                          	and "+@sTable4+".CASETYPE    ="+@sTable2+".CASETYPE"
				                   +char(10)+"                          	and "+@sTable4+".CASECATEGORY="+@sTable2+".CASECATEGORY"
				                   +char(10)+"                          	and "+@sTable4+".SUBTYPE     ="+@sTable2+".SUBTYPE"
				                   +char(10)+"                     		and "+@sTable4+".COUNTRYCODE = (select min(VS1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDSUBTYPE VS1 with (NOLOCK)"
				                   +char(10)+"                     	               	              where VS1.PROPERTYTYPE="+@sTable2+".PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VS1.CASETYPE    ="+@sTable2+".CASETYPE"
				                   +char(10)+"                          	                      and   VS1.CASECATEGORY="+@sTable2+".CASECATEGORY"
				                   +char(10)+"                          	                      and   VS1.SUBTYPE     ="+@sTable2+".SUBTYPE"
				                   +char(10)+"                     	                              and   VS1.COUNTRYCODE in ("+@sTable2+".COUNTRYCODE, 'ZZZ')))" 
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,@sTable4,@sLookupCulture,@pbCalledFromCentura) 
			End

			If @sColumn='RelatedTypeOfMarkDescription'
			Begin
				Set @sTable5='TM'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join TABLECODES '+@sTable5
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join TABLECODES "+@sTable5+" with (NOLOCK) on ("+@sTable5+".TABLECODE="+@sTable2+".TYPEOFMARK)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,@sTable5,@sLookupCulture,@pbCalledFromCentura) 
			End

			If @sColumn='RelatedOfficialNumber'
			Begin
				Set @sTableColumn='isnull('+@sTable2+'.CURRENTOFFICIALNO, '+@sTable1+'.OFFICIALNUMBER)'
			End
			Else If @sColumn='RelatedLocalClasses'
			Begin
				Set @sTableColumn=@sTable2+'.LOCALCLASSES'
			End
		End


		Else If @sColumn in (	'RelatedCountryNameAny',
					'RelatedEventDateAny',
					'RelatedCaseCategoryAny',
					'RelatedCaseSubTypeAny',
					'RelatedCaseTitleAny',
					'RelatedCaseTypeOfMarkAny',
					'RelatedLocalClassesAny',
					'RelatedCaseRelationshipAny',
					'RelatedOfficialNumberAny',
					'RelatedCaseReferenceAny')

		Begin
			Set @sAddFromString = 'Left Join RELATEDCASE  R_C'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join RELATEDCASE  R_C with (NOLOCK) on (R_C.CASEID=C.CASEID"

				If @pbExternalUser = 1
				Begin
					Set @sAddFromString = @sAddFromString+char(10)+"                                    and exists (select 1 from #TEMPCASESEXT R_C_FCU"+" where R_C_FCU"+".CASEID=R_C.CASEID"+"))"

					Set @pnTableCount=@pnTableCount+1
				End							  
				Else
				Begin
					Set @sAddFromString = @sAddFromString+")"						   
				End

				Set @sAddFromString = @sAddFromString
					   +char(10)+ "Left Join CASERELATION C_R with (NOLOCK) on (C_R.RELATIONSHIP=R_C.RELATIONSHIP"
					   +char(10)+ "                                         and C_R.SHOWFLAG=1)"


				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
				Set @bUseRelatedCase=1
			End

			If @sColumn='RelatedEventDateAny'
			Begin
				Set @sTableColumn='isnull(R_CE.EVENTDATE, R_C.PRIORITYDATE)'


				Set @sAddFromString = 'Left Join CASEEVENT R_CE'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join CASEEVENT R_CE with (NOLOCK) on (R_CE.CASEID=R_C.RELATEDCASEID"
						    +char(10)+"                                       and R_CE.EVENTNO=isnull(C_R.DISPLAYEVENTNO,C_R.FROMEVENTNO)"
						    +char(10)+"                                       and R_CE.CYCLE=1)"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			If @sColumn in ('RelatedCountryNameAny', 
					'RelatedCaseCategoryAny',
					'RelatedCaseSubTypeAny',
					'RelatedCaseTitleAny',
					'RelatedCaseTypeOfMarkAny',
					'RelatedLocalClassesAny',
					'RelatedCaseReferenceAny',
					'RelatedOfficialNumberAny')	-- RFC45041
			Begin
				Set @sAddFromString = 'Left Join CASES R_CR'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join CASES R_CR with (NOLOCK) on (R_CR.CASEID=R_C.RELATEDCASEID)"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			If @sColumn='RelatedCountryNameAny'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'R_CN',@sLookupCulture,@pbCalledFromCentura)
				Set @sAddFromString = 'Left Join COUNTRY R_CN'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join COUNTRY R_CN with (NOLOCK) on (R_CN.COUNTRYCODE=ISNULL(R_CR.COUNTRYCODE, R_C.COUNTRYCODE))"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			
			If @sColumn='RelatedCaseCategoryAny'
			Begin
				Set @sAddFromString = 'Left Join VALIDCATEGORY R_VC'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join VALIDCATEGORY R_VC with (NOLOCK) on (R_VC.PROPERTYTYPE=R_CR.PROPERTYTYPE"
						    +char(10)+"                                           and R_VC.CASETYPE    =R_CR.CASETYPE"
						    +char(10)+"                                           and R_VC.CASECATEGORY=R_CR.CASECATEGORY"
						    +char(10)+"                                           and R_VC.COUNTRYCODE = (select min(VC1.COUNTRYCODE)"
						    +char(10)+"                     	                              from VALIDCATEGORY VC1 with (NOLOCK)"
						    +char(10)+"                     	                              where VC1.PROPERTYTYPE=R_CR.PROPERTYTYPE"
						    +char(10)+"                                  	              and   VC1.CASETYPE    =R_CR.CASETYPE"
						    +char(10)+"                          	                      and   VC1.CASECATEGORY=R_CR.CASECATEGORY"
						    +char(10)+"                     	                              and   VC1.COUNTRYCODE in (R_CR.COUNTRYCODE, 'ZZZ')))"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'R_VC',@sLookupCulture,@pbCalledFromCentura) 
			End

			If @sColumn='RelatedCaseSubTypeAny'
			Begin
				Set @sAddFromString = 'Left Join VALIDSUBTYPE R_VS'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join VALIDSUBTYPE R_VS with (NOLOCK) on (R_VS.PROPERTYTYPE=R_CR.PROPERTYTYPE"
				                   +char(10)+"                                           and R_VS.CASETYPE    =R_CR.CASETYPE"
				                   +char(10)+"                                           and R_VS.CASECATEGORY=R_CR.CASECATEGORY"
				                   +char(10)+"                                           and R_VS.SUBTYPE     =R_CR.SUBTYPE"
				                   +char(10)+"                     	                 and R_VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDSUBTYPE VS1 with (NOLOCK)"
				                   +char(10)+"                     	               	              where VS1.PROPERTYTYPE=R_CR.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VS1.CASETYPE    =R_CR.CASETYPE"
				                   +char(10)+"                          	                      and   VS1.CASECATEGORY=R_CR.CASECATEGORY"
				                   +char(10)+"                          	                      and   VS1.SUBTYPE     =R_CR.SUBTYPE"
				                   +char(10)+"                     	                              and   VS1.COUNTRYCODE in (R_CR.COUNTRYCODE, 'ZZZ')))" 
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'R_VS',@sLookupCulture,@pbCalledFromCentura) 
			End

			If @sColumn='RelatedCaseTypeOfMarkAny'
			Begin
				Set @sAddFromString = 'Left Join TABLECODES R_TM'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = "Left Join TABLECODES R_TM with (NOLOCK) on (R_TM.TABLECODE=R_CR.TYPEOFMARK)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'R_TM',@sLookupCulture,@pbCalledFromCentura) 
			End

			If @sColumn='RelatedOfficialNumberAny'
			Begin
				Set @sTableColumn='isnull(R_CR.CURRENTOFFICIALNO, R_C.OFFICIALNUMBER)'
			End
			Else If @sColumn='RelatedLocalClassesAny'
			Begin
				Set @sTableColumn='R_CR.LOCALCLASSES'
			End
			Else If @sColumn='RelatedCaseRelationshipAny'
			Begin
				Set @sTableColumn='C_R.RELATIONSHIPDESC'
			End
			Else If @sColumn='RelatedCaseReferenceAny'
			Begin
				Set @sTableColumn='R_CR.IRN'
			End
			Else If @sColumn='RelatedCaseTitleAny'
			Begin
				Set @sTableColumn='ISNULL(R_CR.TITLE, R_C.TITLE)'
			End
		End

		Else If @sColumn='NextRenewalDate'
		Begin
			Set @sTableColumn="isnull(NRCE.EVENTDATE, NRCE.EVENTDUEDATE)"
			Set @sAddFromString = 'Left Join CASEEVENT NRCE'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin			
				-- to get the Next Renewal Date we need the lowest open Renewal Action.						
				Set @sAddFromString =        "Left join (select min(OA.CYCLE) as [CYCLE], OA.CASEID"
						   +char(10)+"           from OPENACTION OA with (NOLOCK)"
						   +char(10)+"           where OA.ACTION='"+@sRenewalAction+"'"
						   +char(10)+"           and OA.POLICEEVENTS=1"
						   +char(10)+"           group by OA.CASEID) NROA on (NROA.CASEID=C.CASEID)"
						   +char(10)+"Left Join CASEEVENT NRCE with (NOLOCK) on (NRCE.CASEID = C.CASEID"
						   +char(10)+"				and NRCE.EVENTNO = -11"
						   +char(10)+"				and NRCE.CYCLE=NROA.CYCLE"

				------------------------------------------------------------
				-- If the result includes a filter on Event -11
				-- for a specific date range, then the date range filter
				-- is to be applied
				------------------------------------------------------------
				Set @sDateFilter = NULL

				If  @nEventDateFilterOperator = 7
				and(@bByDueDate = 1 OR @bByEventDate = 1)
				and @sEventFilterKeys = '-11'
				Begin
					-------------------------------------------------------------------------------------------------
					-- If Period Quantity and Period Type are supplied, these are used to calculate Event From date
					-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
					-- current date.  If Quantity is positive, the current date is the From date and the derived date
					-- the To date.  If Quantity is negative, the current date is the To date and the derived date 
					-- the From date.
					-------------------------------------------------------------------------------------------------
					If @sPeriodType is not null
					and @nPeriodQuantity is not null
					Begin
						If @nPeriodQuantity > 0 
						Begin
							Set @dtDateRangeFilterFrom 	= getdate()					

							Set @sSQLString = "Set @dtDateRangeFilterTo = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterFrom) + "')"

							execute sp_executesql @sSQLString,
									N'@dtDateRangeFilterTo		datetime 		output,
			 							@sPeriodType			nvarchar(1),
										@nPeriodQuantity		smallint,
										@dtDateRangeFilterFrom	datetime',
			  							@dtDateRangeFilterTo		= @dtDateRangeFilterTo 	output,
										@sPeriodType			= @sPeriodType,
										@nPeriodQuantity		= @nPeriodQuantity,
										@dtDateRangeFilterFrom	= @dtDateRangeFilterFrom					  
						End
						Else
						Begin
							Set @dtDateRangeFilterTo	= getdate()

							Set @sSQLString = "Set @dtDateRangeFilterFrom = dateadd("+@sPeriodType+", @nPeriodQuantity, '" + convert(nvarchar(25),@dtDateRangeFilterTo) + "')"

							execute sp_executesql @sSQLString,
									N'@dtDateRangeFilterFrom	datetime 		output,
			 							@sPeriodType		nvarchar(1),
										@nPeriodQuantity	smallint,
										@dtDateRangeFilterTo	datetime',
			  							@dtDateRangeFilterFrom	= @dtDateRangeFilterFrom 	output,
										@sPeriodType		= @sPeriodType,
										@nPeriodQuantity	= @nPeriodQuantity,
										@dtDateRangeFilterTo	= @dtDateRangeFilterTo					
						End
					End
	
					If @dtDateRangeFilterFrom is not null
					or @dtDateRangeFilterTo   is not null
					Begin
						--------------------------------------------------------
						-- Now create the date filter depending on whether it is
						-- the EventDate and/or the EventDueDate being filtered.
						--------------------------------------------------------
						If @bByEventDate=1
						Begin
							Set @sDateFilter="				and (NRCE.EVENTDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)

							If @bByDueDate=1
								Set @sDateFilter=@sDateFilter+char(10)+"				 OR (NRCE.OCCURREDFLAG=0 and NRCE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)+")"

							Set @sDateFilter=@sDateFilter+")"
						End
						Else Begin
							Set @sDateFilter="				and NRCE.OCCURREDFLAG=0 and NRCE.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nEventDateFilterOperator,@Date,convert(nvarchar,@dtDateRangeFilterFrom,112), convert(nvarchar,@dtDateRangeFilterTo,112),@pbCalledFromCentura)
						End
					End

					If @sDateFilter is not null
						Set @sAddFromString=@sAddFromString+char(10)+@sDateFilter
				End

				Set @sAddFromString=@sAddFromString+')'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End	

		Else If @sColumn='CPARenewalDate'
		Begin	
			Set @sTableColumn="RN.CPARenewalDate"
			Set @sAddFromString = 'Left Join ( select CASE WHEN convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join ( select CASE WHEN convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'18010101'),112)+ convert(char(8),isnull(P.NEXTRENEWALDATE,'18010101'),112)),9,8)) = '1801-01-01 00:00:00.000' "
						   +char(10)+" 		   THEN NULL ELSE convert(datetime,substring(max(convert(char(8),isnull(P.ASATDATE,'18010101'),112)+ convert(char(8),isnull(P.NEXTRENEWALDATE,'18010101'),112)),9,8)) END as CPARenewalDate, P.CASEID"
						   +char(10)+" 	    from (select DATEOFPORTFOLIOLST as ASATDATE, NEXTRENEWALDATE, CASEID"
						   +char(10)+"	    from CPAPORTFOLIO with (NOLOCK)"
						   +char(10)+"	    where STATUSINDICATOR='L'"
						   +char(10)+"	    and NEXTRENEWALDATE is not null"
						   +char(10)+"	    and TYPECODE not in ('A1','A6','AF','CI','CN','DE','DI','NW','SW')" --SQA10180
						   +char(10)+"	    UNION ALL"
						   +char(10)+"	    select EVENTDATE, RENEWALEVENTDATE, CASEID"
						   +char(10)+"	    from CPAEVENT with (NOLOCK)"
						   +char(10)+"	    UNION ALL"
						   +char(10)+"	    select BATCHDATE, RENEWALDATE, CASEID"
						   +char(10)+"	    from CPARECEIVE with (NOLOCK)"
						   +char(10)+"	    where IPRURN is not null"
						   +char(10)+"	    ) P GROUP BY P.CASEID) RN on (RN.CASEID=C.CASEID and C.REPORTTOTHIRDPARTY = 1)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+3
			End			
		End

		Else If @sColumn in (	'DatesCycleAny', 
					'DatesDescAny',
					'DatesDueAny',
					'DatesEventAny',
					'DatesTextAny',
					'DatesTextTypeAny',
					'DatesTextModifiedDateAny',
					'DatesTextAnyOfType',			-- RFC58007	The qualifier will be the TextType
					'DatesTextAnyOfTypeModifiedDate',	-- RFC58007	The qualifier will be the TextType
					'DatesEventCategoryAny',
					'DatesEventCategoryAnyIconKey',
                                        'DatesTextNoType',
                                        'DatesTextNoTypeModifiedDate')
		Begin
			If @sColumn in (
					'DatesTextAny',
					'DatesTextAnyOfType',
					'DatesTextAnyOfTypeModifiedDate',
					'DatesTextModifiedDateAny',
					'DatesTextNoType',
					'DatesTextNoTypeModifiedDate',
					'DatesTextTypeAny')
			Begin
				Set @bAllEventAndDueDatesRequired =1
			End

			If @sColumn in (	
					'DatesDescAny',
					'DatesEventAny',
					'DatesEventCategoryAny',
					'DatesEventCategoryAnyIconKey')
			Begin
				Set @bAllEventsRequired =1
			End
			----------------------------------------------------------------------------------------
			-- The @sQualifier supplied with the DatesTextAnyOfType & DatesTextAnyOfTypeModifiedDate
			-- columns is the EventTextType that the note to be supplied for.  In this situation the
			-- Event to be used will be determined from the de
			----------------------------------------------------------------------------------------
			If @sColumn in ('DatesTextAnyOfType',
					'DatesTextAnyOfTypeModifiedDate',
                                        'DatesTextNoType',
                                        'DatesTextNoTypeModifiedDate')
			Begin
				Set @sCorrelationSuffix2=@sCorrelationSuffix
				Set @sCorrelationSuffix =@sSuffixSaved
			End
			Else Begin
				Set @sSuffixSaved=@sCorrelationSuffix
			End
						
			Set @sTable1='DA'+@sCorrelationSuffix
			Set @sTable2='E' +@sCorrelationSuffix
			Set @sTable3='ECT'+@sCorrelationSuffix
			
			-- Save the correlation name for dbo.fn_GetCaseEventDates()
			Set @sCaseEventCorrelation=@sTable1
			
			Set @sAddFromString = 'Left Join dbo.fn_GetCaseEventDates() '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join dbo.fn_GetCaseEventDates() "+@sTable1+" on ("+@sTable1+".CASEID=C.CASEID"
							      +CASE WHEN(@sQualifier is null)
								    THEN ")"
								    ELSE char(10)+"					and isnull("+@sTable1+".IMPORTANCELEVEL,9)>="+@sQualifier+")" 
						    	       END
						   +CASE WHEN(@pbExternalUser=1)
							 THEN +char(10)+" Left Join #TEMPEVENTS "+@sTable2+" on ("+@sTable2+".EVENTNO="+@sTable1+".EVENTNO)"
						    END		

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+5
				
				If @pbExternalUser=1
					Set @sAddWhereString= 'and ('+@sTable1+'.EVENTNO is NULL OR '+@sTable2+'.EVENTNO is not NULL)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentWhereString	OUTPUT,
								@psAddString	=@sAddWhereString,
								@psComponentType=@sWhere,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
			End
				
			If @sColumn in ('DatesTextTypeAny')
			Begin
				Set @sTable4='ETT'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join EVENTTEXTTYPE '+@sTable4
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+replace(@sAddFromString,'_','~_')+'%' ESCAPE '~')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin							
					Set @sAddFromString ="Left Join EVENTTEXTTYPE "+@sTable4+" with (NOLOCK) on ("+@sTable4+".EVENTTEXTTYPEID="+@sTable1+".EVENTTEXTTYPEID)"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			Else If @sColumn in ('DatesTextAnyOfType',
			   		     'DatesTextAnyOfTypeModifiedDate',
                                             'DatesTextNoType',
                                             'DatesTextNoTypeModifiedDate')
			Begin
				Set @sTable4='CETT'+@sCorrelationSuffix2
				Set @sAddFromString = 'ON ('+@sTable4+'.CASEID'
		
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+replace(@sAddFromString,'_','~_')+'%' ESCAPE '~')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin	
					Set @sAddFromString="Left Join (Select CET.CASEID, CET.EVENTNO, CET.CYCLE, ET.EVENTTEXT, ET.LOGDATETIMESTAMP"
						  +char(10)+"	        from CASEEVENTTEXT CET with (NOLOCK)"
						  +char(10)+"	        join EVENTTEXT ET  with (NOLOCK)on (ET.EVENTTEXTID=CET.EVENTTEXTID"

					-- Check if the EVENTTEXT is being filtered
					If @sQualifier is not null
					Begin
						Set @sAddFromString=@sAddFromString+
									+char(10)+"                                                   and ET.EVENTTEXTTYPEID="+@sQualifier+")) "+@sTable4
					End
					Else Begin
						Set @sAddFromString=@sAddFromString+
									+char(10)+"                                                   and ET.EVENTTEXTTYPEID is null)) "+@sTable4
					End
					
					Set @sAddFromString=@sAddFromString+char(10)+"			ON ("+@sTable4+".CASEID  = "+@sTable1+".CASEID"
									   +char(10)+"			AND "+@sTable4+".EVENTNO = "+@sTable1+".EVENTNO"
									   +char(10)+"			AND "+@sTable4+".CYCLE   = "+@sTable1+".CYCLE )"	

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+2

				End
			End

			Set @sTableColumn=
				CASE(@sColumn) 
					WHEN('DatesCycleAny')	   THEN @sTable1+'.CYCLE'
					WHEN('DatesDescAny')	   THEN dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,@sTable1,@sLookupCulture,@pbCalledFromCentura)
					WHEN('DatesDueAny')	   THEN @sTable1+'.EVENTDUEDATE'
					WHEN('DatesEventAny')	   THEN @sTable1+'.EVENTDATE'
					WHEN('DatesTextModifiedDateAny')	   
								   THEN @sTable1+'.LOGDATETIMESTAMP'
					WHEN('DatesTextAny')	   THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT',    'EVENTTEXT',  null,@sTable1,@sLookupCulture,@pbCalledFromCentura)
					WHEN('DatesTextTypeAny')   THEN dbo.fn_SqlTranslatedColumn('EVENTTEXTTYPE','DESCRIPTION',null,@sTable4,@sLookupCulture,@pbCalledFromCentura)
					WHEN('DatesTextAnyOfType') THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,@sTable4,@sLookupCulture,@pbCalledFromCentura)
					WHEN('DatesTextAnyOfTypeModifiedDate') THEN @sTable4+'.LOGDATETIMESTAMP'
                                        WHEN('DatesTextNoType')     THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,@sTable4,@sLookupCulture,@pbCalledFromCentura)
					WHEN('DatesTextNoTypeModifiedDate')    THEN @sTable4+'.LOGDATETIMESTAMP'
				End

			If @sColumn in ('DatesEventCategoryAny',
					'DatesEventCategoryAnyIconKey')
			Begin
				Set @sAddFromString = 'Left Join EVENTCATEGORY '+@sTable3
				
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = 'Left Join EVENTCATEGORY '+@sTable3+" with (NOLOCK) on ("+@sTable3+".CATEGORYID="+@sTable1+".CATEGORYID)"
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				If @sColumn='DatesEventCategoryAny'
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,@sTable3,@sLookupCulture,@pbCalledFromCentura)
				End
				Else Begin
					Set @sTableColumn=@sTable3+'.ICONIMAGEID'
				End 
			End

		End

		Else If @sColumn in (	'DueDateDescription',
					'DueDate',
					'DueDateCycle',
					'DueDateImportance',
					'DueDateNotes',
					'DueDateEventTextType',		-- RFC43207
					'DueDateTextModifiedDate',	-- RFC43207
					'DueDateLastModified',
					'ReminderDate',
					'ReminderMessage',
					'ReminderAdHocFlag',
					'DueEventCategory',
					'DueEventCategoryIconKey',
					'DueEventNo',			-- RFC60405
					'DueEventStaffKey',
					'DueEventStaff',
					'DueEventStaffCode',
					'DueDateResp',
					'DueDescriptionLatestInGroup',
					'DueDateLatestInGroup')
		Begin
			If @sColumn in ('DueDateDescription',
					'DueDate',
					'DueDateCycle',
					'DueDateImportance',
					'DueDateNotes',
					'DueDateEventTextType',		-- RFC43207
					'DueDateTextModifiedDate',	-- RFC43207
					'DueDateLastModified',
					'DueEventCategory',
					'DueEventCategoryIconKey',
					'DueEventNo',
					'DueEventStaffKey',
					'DueEventStaff',
					'DueEventStaffCode',
					'DueDateResp',
					'DueDescriptionLatestInGroup',
					'DueDateLatestInGroup')
			-- If the Ad Hoc specific Due Date filter criteria is seleted make sure that
			-- CASEEVENT join will always be in front of the EMPLOYEEREMINDER join.
			or @bUseAdHocDates = 1	
			Begin
				Set @sAddFromString = 'Join CASEEVENT DD'
		
				If isnull(@bDueDatesLoaded,0)=0
				Begin									
					Set @sAddFromString = "Join CASEEVENT DD with (NOLOCK) on (DD.CASEID=C.CASEID"
					
					If @sCaseEventCorrelation is not null
						Set @sAddFromString = @sAddFromString + " and DD.EVENTNO="+@sCaseEventCorrelation+".EVENTNO and DD.CYCLE  ="+@sCaseEventCorrelation+".CYCLE"
					
					
					Set @sAddFromString = @sAddFromString + ")"
							   +char(10)+"Left Join OPENACTION DD_OA with (NOLOCK) on (DD_OA.CASEID=C.CASEID)"
							   +char(10)+"Left Join EVENTCONTROL DDEC with (NOLOCK) on (DDEC.CRITERIANO=DD_OA.CRITERIANO"
							   +char(10)+"				and DDEC.EVENTNO=DD.EVENTNO)"
							   +CASE WHEN(@pbExternalUser=1)
								 THEN +char(10)+"     Join #TEMPEVENTS DDE          on (DDE.EVENTNO=DD.EVENTNO)"
									  +char(10)+"     Left Join EVENTS DDEX			on (DDEX.EVENTNO=DDE.EVENTNO)"
								 ELSE +char(10)+"     Join EVENTS DDE with (NOLOCK) on (DDE.EVENTNO=DD.EVENTNO)"
							    END
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+4
	
					Set @bDueDatesLoaded=1

					-- Use the CONTROLLINGACTION if defined to indicate which Action's rules should be used
					Set @sAddWhereString='and (DD_OA.ACTION=DDE.CONTROLLINGACTION or (DDE.CONTROLLINGACTION is null and DDEC.CRITERIANO=isnull(DD.CREATEDBYCRITERIA,DD_OA.CRITERIANO)) OR DD_OA.CASEID is null)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentWhereString	OUTPUT,
									@psAddString	=@sAddWhereString,
									@psComponentType=@sWhere,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
				End

				If @sColumn in ('DueDescriptionLatestInGroup',
						'DueDateLatestInGroup')
				Begin
					Set @sAddFromString = 'Left Join (select DD1.CASEID, DDE1.EVENTGROUP, max(DD1.EVENTDUEDATE) as EVENTDUEDATE'
					
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin
						------------------------------------------------------
						-- Get the latest due date for Events that match the 
						-- Event Group of the main due date being reported on.
						------------------------------------------------------									
						Set @sAddFromString = 'Left Join (select DD1.CASEID, DDE1.EVENTGROUP, max(DD1.EVENTDUEDATE) as EVENTDUEDATE'
						            +char(10)+'           from EVENTS DDE1 with (NOLOCK)'
						            +char(10)+'           join CASEEVENT DD1 with (NOLOCK) on (DD1.EVENTNO=DDE1.EVENTNO'
						            +char(10)+'                                            and DD1.OCCURREDFLAG=0)'
						            +char(10)+'           where DDE1.EVENTGROUP  is not null'
						            +char(10)+'           and   DD1.EVENTDUEDATE is not null'
						            +char(10)+'           group by DD1.CASEID, DDE1.EVENTGROUP) GRP on (GRP.CASEID=DD.CASEID'
						            +char(10)+'                                                     and GRP.EVENTGROUP=DDE.EVENTGROUP)'
						            +char(10)+'left join CASEEVENT DD2 with (NOLOCK) on (DD2.CASEID=GRP.CASEID'
						            +char(10)+'                                      and DD2.OCCURREDFLAG=0'
						            +char(10)+'                                      and DD2.EVENTDUEDATE=GRP.EVENTDUEDATE)'
						            +char(10)+'left join EVENTS DDE2 with (NOLOCK)   on (DDE2.EVENTNO=DD2.EVENTNO'
						            +char(10)+'                                      and DDE2.EVENTGROUP=GRP.EVENTGROUP)'
						            +char(10)+'left join EVENTCONTROL DDEC2 with (NOLOCK) on (DDEC2.CRITERIANO=DD2.CREATEDBYCRITERIA'
						            +char(10)+'				                  and DDEC2.EVENTNO   =DD2.EVENTNO)'
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+5
					End
				End
	
				Set @sTableColumn=
					CASE(@sColumn)
						WHEN('DueDateDescription')  THEN 'isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'DDEC',@sLookupCulture,@pbCalledFromCentura)
								 	 		  +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'DDE',@sLookupCulture,@pbCalledFromCentura)+')'
						WHEN('DueDateCycle')	    THEN 'DD.CYCLE'
						WHEN('DueDate')		    THEN 'DD.EVENTDUEDATE'
						WHEN('DueDateLastModified') THEN 'DD.LOGDATETIMESTAMP'
						WHEN('DueEventNo')          THEN 'DD.EVENTNO'
						WHEN('DueEventStaffKey')    THEN 'DD.EMPLOYEENO'
						WHEN('DueDescriptionLatestInGroup')
									    THEN 'isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'DDEC2',@sLookupCulture,@pbCalledFromCentura)
							 	 			  +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'DDE2',@sLookupCulture,@pbCalledFromCentura)+')'
						WHEN('DueDateLatestInGroup')THEN 'DD2.EVENTDUEDATE'
					End
					
				If @sColumn in ('DueDateNotes',
						'DueDateEventTextType',
						'DueDateTextModifiedDate')
				Begin
					Set @sAddFromString = 'Left Join CASEEVENTTEXT DDCET'
					
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = 'Left Join CASEEVENTTEXT DDCET with (NOLOCK) on (DDCET.CASEID =DD.CASEID'
						            +char(10)+'                                            and DDCET.EVENTNO=DD.EVENTNO'
						            +char(10)+'                                            and DDCET.CYCLE  =DD.CYCLE)'
						            +char(10)+'Left Join EVENTTEXT DDET with (NOLOCK)      on (DDET.EVENTTEXTID=DDCET.EVENTTEXTID)'
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+2
					End
					
					If (@sColumn in ('DueDateEventTextType')) or (@pbExternalUser = 1)
					Begin
						Set @sAddFromString = 'Left Join EVENTTEXTTYPE DDETT'
						
						If not exists(	select 1 from #TempConstructSQL T
								where T.SavedString like '%'+@sAddFromString+'%')
						and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
						Begin									
							Set @sAddFromString = 'Left Join EVENTTEXTTYPE DDETT with (NOLOCK) on (DDETT.EVENTTEXTTYPEID =DDET.EVENTTEXTTYPEID)'
			
							exec @ErrorCode=dbo.ip_LoadConstructSQL
										@psCurrentString=@sCurrentFromString	OUTPUT,
										@psAddString	=@sAddFromString,
										@psComponentType=@sFrom,
										@psSeparator    =@sReturn,
										@pbForceLoad=0
			
							Set @pnTableCount=@pnTableCount+1
						End
					End
	
					Set @sTableColumn=
						CASE(@sColumn)
							WHEN('DueDateTextModifiedDate')THEN 'DDET.LOGDATETIMESTAMP'
							WHEN('DueDateNotes')	       THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'DDET',@sLookupCulture,@pbCalledFromCentura) 			
							WHEN('DueDateEventTextType')   THEN dbo.fn_SqlTranslatedColumn('EVENTTEXTTYPE','DESCRIPTION',null,'DDETT',@sLookupCulture,@pbCalledFromCentura) 			
						End
					---------------------------------------
					-- RFC43207
					-- Apply any of the filter restrictions
					-- to the text being returned if the
					-- filter has not already been added.
					---------------------------------------
					If (@nEventNoteTypeKeysOperator is not null and PATINDEX ('%and DDET.EVENTTEXT %',       @sCurrentWhereString)=0)
					or (@nEventNoteTextOperator     is not null and PATINDEX ('%and DDET.EVENTTEXTTYPEID %', @sCurrentWhereString)=0)
					Begin
						If @nEventNoteTextOperator is not null
							Set @sAddWhereString =  "and DDET.EVENTTEXT "+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
											   
						If  @nEventNoteTypeKeysOperator is not null
							Set @sAddWhereString =  @sAddWhereString+char(10)+"and DDET.EVENTTEXTTYPEID "+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)

						exec @ErrorCode=dbo.ip_LoadConstructSQL
										@psCurrentString=@sCurrentWhereString	OUTPUT,
										@psAddString	=@sAddWhereString,
										@psComponentType=@sWhere,
										@psSeparator    =@sReturn,
										@pbForceLoad=0
					End
                                        
                                        If @pbExternalUser=1
                                        Begin
                                                Set @sAddWhereString =  @sAddWhereString+char(10)+ "and (DDET.EVENTTEXTTYPEID is null or DDETT.ISEXTERNAL = 1)"

                                                exec @ErrorCode=dbo.ip_LoadConstructSQL
									        @psCurrentString=@sCurrentWhereString	OUTPUT,
									        @psAddString	=@sAddWhereString,
									        @psComponentType=@sWhere,
									        @psSeparator    =@sReturn,
									        @pbForceLoad=0
                                        End					
				End	
					
				If @sColumn in ('DueDateImportance')
				Begin
					Set @sAddFromString = 'Left Join IMPORTANCE IL'
					
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = 'Left Join IMPORTANCE IL on (IL.IMPORTANCELEVEL=isnull(DDEC.IMPORTANCELEVEL,DDE.IMPORTANCELEVEL))'
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1
					End
	
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IL',@sLookupCulture,@pbCalledFromCentura)
				End	
				
				If @sColumn in ('DueEventCategory',
						'DueEventCategoryIconKey')
				Begin
					Set @sAddFromString = 'Left Join EVENTCATEGORY DDECT'
					
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = 'Left Join EVENTCATEGORY DDECT with (NOLOCK) on (DDECT.CATEGORYID=DDE.CATEGORYID)'
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1
					End
	
					If @sColumn='DueEventCategory'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'DDECT',@sLookupCulture,@pbCalledFromCentura)
					End
					Else Begin
						Set @sTableColumn='DDECT.ICONIMAGEID'
					End 
				End		

				If @sColumn in ('DueEventStaff',
						'DueEventStaffCode',
						'DueDateResp')
				Begin
					Set @sAddFromString = 'Left Join NAME DDEMP'
					
					If not exists(	select 1 from #TempConstructSQL T
							where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
					Begin									
						Set @sAddFromString = 'Left Join NAME DDEMP with (NOLOCK) on (DDEMP.NAMENO=DD.EMPLOYEENO)'
		
						exec @ErrorCode=dbo.ip_LoadConstructSQL
									@psCurrentString=@sCurrentFromString	OUTPUT,
									@psAddString	=@sAddFromString,
									@psComponentType=@sFrom,
									@psSeparator    =@sReturn,
									@pbForceLoad=0
		
						Set @pnTableCount=@pnTableCount+1
					End
	
					If @sColumn='DueEventStaff'
					Begin
						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(DDEMP.NAMENO, null)'
					End
					Else Begin
						Set @sTableColumn='DDEMP.NAMECODE'
					End 
	
					If @sColumn='DueDateResp'
					Begin
						Set @sAddFromString = 'Left Join NAMETYPE DDNT'
						
						If not exists(	select 1 from #TempConstructSQL T
								where T.SavedString like '%'+@sAddFromString+'%')
						and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
						Begin									
							Set @sAddFromString = 'Left Join NAMETYPE DDNT WITH (NOLOCK) on (DDNT.NAMETYPE=DD.DUEDATERESPNAMETYPE)'
			
							exec @ErrorCode=dbo.ip_LoadConstructSQL
										@psCurrentString=@sCurrentFromString	OUTPUT,
										@psAddString	=@sAddFromString,
										@psComponentType=@sFrom,
										@psSeparator    =@sReturn,
										@pbForceLoad=0
			
							Set @pnTableCount=@pnTableCount+1
						End

						If @bIsSignatory=1
						Begin		
							Set @sAddFromString = 'Left Join CASENAME SIG'
						
							If not exists(	select 1 from #TempConstructSQL T
									where T.SavedString like '%'+@sAddFromString+'%')
							and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
							Begin						
								Set @sAddFromString = "Left Join CASENAME SIG	on (SIG.CASEID=C.CASEID"
										   +char(10)+"                      	and(SIG.EXPIRYDATE is null or SIG.EXPIRYDATE>getdate() )"
										   +char(10)+"                      	and SIG.NAMETYPE='SIG')"
										   +char(10)+"Left Join NAME NSIG	on (NSIG.NAMENO=SIG.NAMENO)"
							
								exec @ErrorCode=dbo.ip_LoadConstructSQL
											@psCurrentString=@sCurrentFromString	OUTPUT,
											@psAddString	=@sAddFromString,
											@psComponentType=@sFrom,
											@psSeparator    =@sReturn,
											@pbForceLoad=0
							
								Set @pnTableCount=@pnTableCount+1
							End
						End

						If @bIsStaff=1
						Begin		
							Set @sAddFromString = 'Left Join CASENAME EMP'
						
							If not exists(	select 1 from #TempConstructSQL T
									where T.SavedString like '%'+@sAddFromString+'%')
							and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
							Begin						
								Set @sAddFromString = "Left Join CASENAME EMP	on (EMP.CASEID=C.CASEID"
										   +char(10)+"                      	and(EMP.EXPIRYDATE is null or EMP.EXPIRYDATE>getdate() )"
										   +char(10)+"                      	and EMP.NAMETYPE='EMP')"
										   +char(10)+"Left Join NAME NEMP	on (NEMP.NAMENO=EMP.NAMENO)"
							
								exec @ErrorCode=dbo.ip_LoadConstructSQL
											@psCurrentString=@sCurrentFromString	OUTPUT,
											@psAddString	=@sAddFromString,
											@psComponentType=@sFrom,
											@psSeparator    =@sReturn,
											@pbForceLoad=0
							
								Set @pnTableCount=@pnTableCount+1
							End
						End

						Set @sTableColumn=char(10)+
								  'CASE WHEN(DDEMP.NAMENO  is not null) THEN dbo.fn_FormatNameUsingNameNo(DDEMP.NAMENO, null)'+char(10)+
								  '     WHEN(DDNT.NAMETYPE is not null) THEN DDNT.DESCRIPTION'

						If @bIsSignatory=1
							Set @sTableColumn=@sTableColumn+char(10)+
								  '     WHEN(NSIG.NAMENO   is not null) THEN dbo.fn_FormatNameUsingNameNo(NSIG.NAMENO, null)'

						If @bIsStaff=1
							Set @sTableColumn=@sTableColumn+char(10)+
								  '     WHEN(NEMP.NAMENO   is not null) THEN dbo.fn_FormatNameUsingNameNo(NEMP.NAMENO, null)'

						Set @sTableColumn=@sTableColumn+char(10)+
								  'END'
					End  -- @sColumn='DueDateResp'
				End	
	
				-- Turn a flag on to indicate that one of the DueDate columns is required
				-- as we will need to know this to construct a UNION clause to get details 
				-- from the Alerts.
				Set @bDueDatesRequired=1
			End			

			If @sColumn in ('ReminderDate',
					'ReminderMessage',
					'ReminderAdHocFlag')
			Begin
				Set @sAddFromString = 'Left Join EMPLOYEEREMINDER ER'
			
				If isnull(@bRemindersLoaded,0)=0
				Begin
					Set @bRemindersRequired=1
					Set @bRemindersLoaded  =1
							
					Set @sAddFromString = "Left Join EMPLOYEEREMINDER ER with (NOLOCK) on (ER.CASEID=C.CASEID"
	
					-- If Due Dates have also been reported then the Reminders should
					-- match the EventNo and Cycle of the Due Date.
					If @bDueDatesRequired=1
					Begin
						Set @sAddFromString=@sAddFromString
							   +char(10)+"				and ER.EVENTNO=DD.EVENTNO"
							   +char(10)+"				and ER.CYCLENO=DD.CYCLE"
					End
	
					-- Need to cater for the possibility of the Reminders being sent to multiple
					-- Names.  Just get the reminder against the first name
					Set @sAddFromString=@sAddFromString
							   +char(10)+"				and ER.EMPLOYEENO=(select min(ER1.EMPLOYEENO)"
							   +char(10)+"				                   from EMPLOYEEREMINDER ER1"
							   +char(10)+"				                   WHERE ER1.CASEID=ER.CASEID"
							   +char(10)+"				                   and (ER1.EVENTNO=ER.EVENTNO or (ER1.EVENTNO is null and ER.EVENTNO is null))"
							   +char(10)+"				                   and (ER1.CYCLENO=ER.CYCLENO or (ER1.CYCLENO is null and ER.CYCLENO is null))"
	
					-- External users are only to see reminders addressed to 
					-- a name they have access to.
					If @pbExternalUser=1
					Begin
						Set @sAddFromString=@sAddFromString
							   +char(10)+"				                   and ER1.EMPLOYEENO in (select NAMENO from dbo.fn_FilterUserNames("+cast(@pnUserIdentityId as nvarchar(12))+",1))"
					End
	
					Set @sAddFromString=@sAddFromString+'))'
	
					-- The EmployeeReminder join is saved so that it can be replaced if 
					-- a UNION is generated for the ALERT table
					Set @sSaveReminderJoin=@sAddFromString
	
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+2
				End
	
				Set @sTableColumn=
					CASE(@sColumn)
						WHEN('ReminderDate')   THEN 'ER.REMINDERDATE'
						WHEN('ReminderMessage')THEN dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE','LONGMESSAGE','ER',@sLookupCulture,@pbCalledFromCentura)
						WHEN('ReminderAdHocFlag') THEN 'cast(ER.SOURCE as bit)'
					End
			End
		End

		Else If @sColumn = 'CaseFamilyTitle'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura)
			Set @sAddFromString = 'Left Join CASEFAMILY CF'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CASEFAMILY CF with (NOLOCK) on (CF.FAMILY=C.FAMILY)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('CaseListName')
		Begin
			Set @sTableColumn='CSL.CASELISTNAME'
			Set @sAddFromString = 'Left Join CASELISTMEMBER CSLM'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join CASELISTMEMBER CSLM with (NOLOCK) on (CSLM.CASEID=C.CASEID)'+char(10)+
						      'Left Join CASELIST CSL with (NOLOCK) on (CSL.CASELISTNO=CSLM.CASELISTNO)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn in ('PrimeCaseIRN')
		Begin
			Set @sTableColumn='PC.IRN'
			Set @sAddFromString = 'Left Join CASELISTMEMBER CSLM'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join CASELISTMEMBER CSLM with (NOLOCK) on (CSLM.CASEID=C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join (Select CASELISTNO, IRN'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 	'Left Join (Select CASELISTNO, IRN'+char(10)+
							'           From CASELISTMEMBER CSLM1 with (NOLOCK)'+char(10)+
							'           join CASES C1 with (NOLOCK) on (C1.CASEID=CSLM1.CASEID)'+char(10)+
							'           where CSLM1.PRIMECASE=1) PC	on (PC.CASELISTNO=CSLM.CASELISTNO)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn = 'CPAStatus'
		Begin
			Set @sTableColumn='CPAE.DESCRIPTION'
			Set @sAddFromString = 'Left Join CPAEVENT CPA'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = "Left Join CPAEVENT CPA with (NOLOCK)on (CPA.CASEID=C.CASEID"
						   +char(10)+"				and CPA.EVENTDATE=(select max(CPA1.EVENTDATE)"
						   +char(10)+"						from CPAEVENT CPA1 with (NOLOCK)"
						   +char(10)+"						where CPA1.CASEID=C.CASEID))"
						   +char(10)+"Left Join CPAEVENTCODE CPAE with (NOLOCK) on (CPAE.CPAEVENTCODE=CPA.EVENTCODE)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='WIPBalance' -- RFC865
		Begin
			Set @sTableColumn= "WIP.WIPBalance"
			Set @sAddFromString = 'Left Join (Select W.CASEID,'
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = " Left Join (Select W.CASEID,"						
						+char(10)+"           sum(isnull(W.BALANCE, 0)) AS WIPBalance"
						+char(10)+"      from WORKINPROGRESS W"
						+char(10)+"      where W.STATUS <>0"						
						+char(10)+"      group by W.CASEID) WIP	on (WIP.CASEID = C.CASEID)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End								
		End

		Else If @sColumn='StandingInstruction' 	--RFC2984
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin		
			Set @sTable1='SI'+@sCorrelationSuffix
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('INSTRUCTIONS','DESCRIPTION',null,@sTable1,@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join INSTRUCTIONS '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join INSTRUCTIONS '+@sTable1+' with (NOLOCK) on ('+@sTable1+'.INSTRUCTIONCODE=dbo.fn_StandingInstruction(C.CASEID, '+dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)+')'

				-- External users may only view a specific list of instruction types
				If @pbExternalUser=1
				Begin
					-- Create a comma separate list of the instruction types
					Set @sList = null
					Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(INSTRUCTIONTYPE,0,@pbCalledFromCentura)
					From dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId,null, 1,@pbCalledFromCentura)

					Set @sAddFromString = @sAddFromString+char(10)+
						'					and '+@sTable1+'.INSTRUCTIONTYPE IN ('+@sList+')'
				End

				Set @sAddFromString=@sAddFromString+')'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				
				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='StandingInstructionText' 	--SQA17542
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin		
			Set @sTable1='NI'+@sCorrelationSuffix
			Set @sTable2='I'+@sCorrelationSuffix
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMEINSTRUCTIONS','STANDINGINSTRTEXT',null,@sTable1,@sLookupCulture,@pbCalledFromCentura) 
			Set @sAddFromString = 'Left Join NAMEINSTRUCTIONS '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join NAMEINSTRUCTIONS '+@sTable1+'	on ('+@sTable1+'.CASEID = C.CASEID and '+@sTable1+'.INSTRUCTIONCODE=dbo.fn_StandingInstruction(C.CASEID, '+dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)+')'

				Set @sAddFromString=@sAddFromString+')'

				-- External users may only view a specific list of instruction types
				If @pbExternalUser=1
				Begin
					-- Create a comma separate list of the instruction types
					Set @sList = null
					Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(INSTRUCTIONTYPE,0,@pbCalledFromCentura)
					From dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId,null, 1,@pbCalledFromCentura)

					Set @sAddFromString = @sAddFromString+char(10)+
					    'Left Join INSTRUCTIONS '+@sTable2+' on ('+@sTable2+'.INSTRUCTIONCODE='+@sTable1+'.INSTRUCTIONCODE and '+@sTable2+'.INSTRUCTIONTYPE in ('+@sList+')'

					Set @sAddFromString=@sAddFromString+')'					
				End


				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				
				Set @pnTableCount=@pnTableCount+1
			End
		End

		-------------------------------------------
		-- RFC74153
		-- Columns to report on Design Elements 
		-------------------------------------------
		Else If @sColumn in ('FirmElementId', 'ClientElementId', 'OfficialElementId', 'ElementRegistrationNo', 'ElementTypeface', 'ElementDescription')
        Begin
            if @sColumn in ('FirmElementId', 'ClientElementId', 'OfficialElementId')
            Begin
                Set @sTableColumn='DE.' + upper(@sColumn)
            End
            else if @sColumn = 'ElementRegistrationNo'
            Begin
                Set @sTableColumn='DE.REGISTRATIONNO'
            End
            else if @sColumn = 'ElementTypeface'
            Begin
                Set @sTableColumn= 'DE.TYPEFACE'
            End
            else if @sColumn = 'ElementDescription'
            Begin
                Set @sTableColumn=dbo.fn_SqlTranslatedColumn('DESIGNELEMENT','ELEMENTDESC',null,'DE',@psCulture,@pbCalledFromCentura)
            End
                        
            Set @sAddFromString = 'Left Join DESIGNELEMENT DE'
        
            If not exists(    select 1 from #TempConstructSQL T
                    where T.SavedString like '%'+@sAddFromString+'%')
            and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
            Begin                                    
                Set @sAddFromString = 'Left Join DESIGNELEMENT DE with (NOLOCK) on (DE.CASEID=C.CASEID)'

                exec @ErrorCode=dbo.ip_LoadConstructSQL
                            @psCurrentString=@sCurrentFromString    OUTPUT,
                            @psAddString    =@sAddFromString,
                            @psComponentType=@sFrom, 
                            @psSeparator    =@sReturn,
                            @pbForceLoad=0

                Set @pnTableCount=@pnTableCount+1
            End
        End

		If @sColumn in ('IsEditable')
		Begin
			---------------------------------------------
			-- If there is no Row Access Security defined
			-- then assume all rows are editable.
			---------------------------------------------
			If isnull(@bRowLevelSecurity,0)=0
			Begin
				------------------------------------
				-- Now check if any other users have 
				-- row level security configured.
				------------------------------------
				Select @bRowLevelSecurity = 1
				from IDENTITYROWACCESS U WITH (NOLOCK) 
				join USERIDENTITY UI WITH (NOLOCK) on (U.IDENTITYID = UI.IDENTITYID)
				join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
				where R.RECORDTYPE = 'C' and isnull(UI.ISEXTERNALUSER,0) = 0
				
				Set @ErrorCode = @@ERROR 
				
				if  @ErrorCode = 0 
				and @bRowLevelSecurity = 1
					Set @sTableColumn='Cast(0 as bit)'
				else
					Set @sTableColumn='Cast(1 as bit)'
			End
			Else Begin
				Set @sTableColumn='(Cast(CASE	WHEN(RSC.DELETEALLOWED=1)	THEN 1 
								WHEN(RSC.UPDATEALLOWED=1)	THEN 1
								WHEN(RSC.SECURITYFLAG IS NULL)	THEN 1 
												ELSE 0 
							 END as bit)) 
								& 
							   (Cast(CASE	WHEN convert(bit,(RUC.SECURITYFLAG&2))=1 THEN 1 
									WHEN convert(bit,(RUC.SECURITYFLAG&4))=1 THEN 1
									WHEN convert(bit,(RUC.SECURITYFLAG&8))=1 THEN 1
									WHEN RUC.SECURITYFLAG IS NULL THEN 
											CASE WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 2)) = 1 THEN 1
											     WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 4)) = 1 THEN 1
											     WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 8)) = 1 THEN 1
											     ELSE 0 
											END
									  ELSE 0 
								END  as bit))'
			
				Set @sAddFromString="
				left join (select UC.CASEID as CASEID,
							(Select ISNULL(US.SECURITYFLAG,"+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+")
							  from USERSTATUS US WITH (NOLOCK)
							  JOIN USERIDENTITY UI ON (UI.LOGINID = US.USERID and US.STATUSCODE = UC.STATUSCODE)
							  WHERE UI.IDENTITYID ="+convert(nvarchar,@pnUserIdentityId)+") as SECURITYFLAG
						   from CASES UC) RUC on (RUC.CASEID=C.CASEID)"
				If @bCaseOffice = 1
				Begin
					Set @sAddFromString= @sAddFromString +"
						left join fn_CasesRowSecurity("+convert(nvarchar,@pnUserIdentityId)+") RSC on (RSC.CASEID=C.CASEID)"
				End
				Else Begin
					Set @sAddFromString= @sAddFromString +"
						left join fn_CasesRowSecurityMultiOffice("+convert(nvarchar,@pnUserIdentityId)+") RSC on (RSC.CASEID=C.CASEID)"
				End
			End
			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in (
				'OpportunityExpectedCloseDate',
				'OpportunityNextStep',
				'OpportunityNumberOfStaff',			
				'OpportunityPotentialValue',
				'OpportunityPotentialValueCurrency',
				'OpportunityPotentialWin',				
				'OpportunityRemarks',
				'OpportunitySourceDescription',
				'OpportunityStatusDescription',
				'IsProspectClient') --RFC5763 
		Begin
			Set @sTableColumn=
					CASE(@sColumn)
						WHEN('OpportunityExpectedCloseDate')   THEN 'OPP.EXPCLOSEDATE'
						WHEN('OpportunityNextStep')   THEN dbo.fn_SqlTranslatedColumn('OPPORTUNITY','NEXTSTEP',null,'OPP',@sLookupCulture,@pbCalledFromCentura)
						WHEN('OpportunityNumberOfStaff')   THEN 'OPP.NUMBEROFSTAFF'
						WHEN('OpportunityPotentialValue')   THEN 'ISNULL(OPP.POTENTIALVALUE,OPP.POTENTIALVALUELOCAL)'	/* part of RFC6894 */
						WHEN('OpportunityPotentialValueCurrency')   THEN 'ISNULL(OPP.POTENTIALVALCURRENCY, SCUR.COLCHARACTER)'
						WHEN('OpportunityPotentialWin')   THEN 'OPP.POTENTIALWIN'
						WHEN('OpportunityRemarks')   THEN dbo.fn_SqlTranslatedColumn('OPPORTUNITY','REMARKS',null,'OPP',@sLookupCulture,@pbCalledFromCentura)						
					End

			Set @sAddFromString = 'Left Join OPPORTUNITY OPP'
			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join OPPORTUNITY OPP		on (OPP.CASEID = C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
	
			If @sColumn='OpportunitySourceDescription'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCOPSO',@sLookupCulture,@pbCalledFromCentura) 
				Set @sAddFromString = 'Left Join TABLECODES TCOPSO'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = 'Left Join TABLECODES TCOPSO		on (TCOPSO.TABLECODE=OPP.SOURCE)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			If (@sColumn = 'OpportunityStatusDescription')
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCOPST',@psCulture,@pbCalledFromCentura)
				Set @sAddFromString = "Left Join CRMCASESTATUSHISTORY OCSH" 			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					-- Get the highest status for the case.
					Set @sAddFromString = "left join (Select CCSH.CASEID, CCSH.CRMCASESTATUS"+char(10)+
								"	From CRMCASESTATUSHISTORY CCSH"+char(10)+
								"	Join (Select MAX(STATUSID) as MAXSTATUSID, CASEID"+char(10)+
								"		From CRMCASESTATUSHISTORY"+char(10)+
								"		Group by CASEID) MAXOCSH on (MAXOCSH.MAXSTATUSID = CCSH.STATUSID)) as OCSH on (OCSH.CASEID = OPP.CASEID)"+char(10)+
								"left join TABLECODES TCOPST on (TCOPST.TABLECODE = OCSH.CRMCASESTATUS)"

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
			End

			If @sColumn in ('OpportunityPotentialValueCurrency')
			Begin
				Set @sTableColumn='ISNULL(OPP.POTENTIALVALCURRENCY, SCUR.COLCHARACTER)'
				Set @sAddFromString = 'Left Join SITECONTROL SCUR with (NOLOCK) on (SCUR.CONTROLID = ''CURRENCY'')'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			
			If @sColumn in ('IsProspectClient')
			Begin
				Set @sTableColumn = 
					"CASE" +char(10)+
						"WHEN (exists (Select * from NAMETYPECLASSIFICATION NTC" +char(10)+ 
							"where NTC.NAMENO = OPPCN.NAMENO and NTC.NAMETYPE = '~PR' and NTC.ALLOW = 1" +char(10)+
							"and isnull(NAME.USEDASFLAG, 0) & 4 = 0))" +char(10)+
						"THEN Cast(0 as bit)" +char(10)+
						"ELSE Cast(1 as bit)" +char(10)+
					"END"
									
				Set @sAddFromString = 'Left Join CASENAME OPPCN'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = " Left Join CASENAME OPPCN 	on (OPPCN.CASEID = OPP.CASEID and OPPCN.NAMETYPE = '~PR')" + char(10)
										+ " Left Join NAME on (NAME.NAMENO = OPPCN.NAMENO)"
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End				
		
		End

		-- Marketing Activity
		Else If @sColumn in (
				'MarketingActivityStatusDescription',
				'MarketingActivityActualCostLocal',
				'MarketingActivityActualCost',
				'MarketingActivityActualCostCurrency',
				'MarketingActivityAcceptence',
				'TotalOpportunityPotentials',
				'ROIOpportunityPotentialVsActual', --RFC5760 
				'MarketingActivityNoOfStaffAttended', -- OK
				'MarketingActivityNoOfContactsAttended', -- OK
				'MarketingActivityNoOfContacts', -- OK
				'MarketingActivityNoOfResponses',
				'MarketingActivityNewOpportunities') --RFC5769
		Begin
			Set @sTableColumn=
					CASE(@sColumn)
						WHEN('MarketingActivityActualCostLocal')	THEN 'M.ACTUALCOSTLOCAL'												
						WHEN('MarketingActivityActualCost')		THEN 'ISNULL(M.ACTUALCOST,M.ACTUALCOSTLOCAL)'
						WHEN('MarketingActivityActualCostCurrency')   	THEN 'ISNULL(M.ACTUALCOSTCURRENCY, SCUR.COLCHARACTER)'
						WHEN('MarketingActivityNoOfStaffAttended')	THEN 'M.STAFFATTENDED'
						WHEN('MarketingActivityNoOfContactsAttended')	THEN 'M.CONTACTSATTENDED'
						-- Return on investment for Marketing Activities
						WHEN('TotalOpportunityPotentials')	THEN 'dbo.fn_GetTotalPotentialsForMarketingOpportunities(M.CASEID)'
						WHEN('ROIOpportunityPotentialVsActual')			THEN 'CASE 
								WHEN M.ACTUALCOSTLOCAL is null or M.ACTUALCOSTLOCAL = 0 THEN null 
								ELSE cast((dbo.fn_GetTotalPotentialsForMarketingOpportunities(M.CASEID)/M.ACTUALCOSTLOCAL)*100 as decimal(11,0)) END'
					End

			Set @sAddFromString = 'Left Join MARKETING M'
			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join MARKETING M		on (M.CASEID = C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If (@sColumn = 'MarketingActivityNewOpportunities')
			Begin
				Set @sTableColumn = 'OPPCOUNT.OPPORTUNITIES'
				set @sAddFromString = "	left join (SELECT CASEID, COUNT(RELATEDCASEID) as OPPORTUNITIES"+CHAR(10)+
							"		from RELATEDCASE RC"+CHAR(10)+
							"		where RELATIONSHIP = '~OP'"+CHAR(10)+
							"		group by RC.CASEID) as OPPCOUNT on (OPPCOUNT.CASEID = M.CASEID)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If (@sColumn in ('MarketingActivityNoOfContacts','MarketingActivityNoOfResponses','MarketingActivityAcceptence'))
			Begin
				Set @sTableColumn = 
					Case(@sColumn)
					WHEN 'MarketingActivityNoOfContacts' THEN 'ARCN.NAMECOUNT'
					WHEN 'MarketingActivityNoOfResponses' THEN 'ARCN.CORRESPRECEIVEDSUM'
					WHEN 'MarketingActivityAcceptence' THEN 'ARCN.CORRESPACCEPTEDSUM'
					End

				set @sAddFromString = 'ARCN on (ARCN.CASEID = M.CASEID)'

				-- get all the aggregates in 1 left join to avoid potentially joining 3 times.
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
					and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 	"	left join (select CASEID, COUNT(NAMENO) NAMECOUNT,"+char(10)+
								"		SUM(CASE WHEN CORRESPRECEIVED IS NOT NULL THEN 1 ELSE 0 END) AS CORRESPRECEIVEDSUM,"+char(10)+
								"		SUM(CASE WHEN CORRESPRECEIVED = SC.COLINTEGER THEN 1 ELSE 0 END) AS CORRESPACCEPTEDSUM"+char(10)+
								"		from CASENAME"+char(10)+
								"		join SITECONTROL SC on (SC.CONTROLID = 'CRM Activity Accept Response')"+char(10)+
								"		where NAMETYPE = '~CN'"+char(10)+
								"		group by CASEID) as ARCN on (ARCN.CASEID = M.CASEID)"
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			If (@sColumn = 'MarketingActivityStatusDescription')
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCMST',@psCulture,@pbCalledFromCentura)
				Set @sAddFromString = 'Left Join CRMCASESTATUSHISTORY MCSH' 			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'left join (	select	CASEID, 
										MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(STATUSID as nvarchar(10)) ) as [DATE]
										from CRMCASESTATUSHISTORY
										group by CASEID	
										) LASTMODIFIED on (LASTMODIFIED.CASEID = M.CASEID)
								Left Join CRMCASESTATUSHISTORY MCSH on (MCSH.CASEID = M.CASEID
									and ( (convert(nvarchar(24),MCSH.LOGDATETIMESTAMP, 21)+cast(MCSH.STATUSID as nvarchar(10))) = LASTMODIFIED.[DATE]
									or LASTMODIFIED.[DATE] is null ))
								left join TABLECODES TCMST 	on (TCMST.TABLECODE = MCSH.CRMCASESTATUS)'
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
			End

			If @sColumn in ('MarketingActivityActualCostCurrency')
			Begin
				Set @sTableColumn='ISNULL(M.ACTUALCOSTCURRENCY, SCUR.COLCHARACTER)'
				Set @sAddFromString = 'Left Join SITECONTROL SCUR with (NOLOCK) on (SCUR.CONTROLID = ''CURRENCY'')'
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End				
							
		End

		-- RFC9321: Global Case Field Updates
		Else If @sColumn in (
				'IsTextUpdated',
				'IsOfficeUpdated',
				'IsFamilyUpdated',
				'IsTitleUpdated',
				'IsStatusUpdated',
				'IsFileLocationUpdated',
                'IsPoliced',
				'EntitySizeUpdated',
				'ProfitCentreCodeUpdated',
				'PurchaseOrderNoUpdated',
				'TypeOfMarkUpdated'
				)
		Begin
			Set @sTableColumn=
				CASE(@sColumn)
					WHEN('IsTextUpdated')	THEN 'GCR.CASETEXTUPDATED'												
					WHEN('IsOfficeUpdated')	THEN 'GCR.OFFICEUPDATED'
					WHEN('IsFamilyUpdated') THEN 'GCR.FAMILYUPDATED'
					WHEN('IsTitleUpdated')	THEN 'GCR.TITLEUPDATED'
					WHEN('IsStatusUpdated')	THEN 'GCR.STATUSUPDATED'
					WHEN('IsFileLocationUpdated')	THEN 'GCR.FILELOCATIONUPDATED'		
					WHEN('EntitySizeUpdated')	THEN 'GCR.EntitySizeUpdated'		
					WHEN('ProfitCentreCodeUpdated')	THEN 'GCR.ProfitCentreCodeUpdated'		
					WHEN('PurchaseOrderNoUpdated')	THEN 'GCR.PurchaseOrderNoUpdated'		
					WHEN('TypeOfMarkUpdated')	THEN 'GCR.TypeOfMarkUpdated'
					WHEN('IsPoliced')       THEN 'GCR.ISPOLICED'		
				End

			Set @sAddFromString = 'Left Join GLOBALCASECHANGERESULTS GCR'
			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join GLOBALCASECHANGERESULTS GCR	on (GCR.CASEID = C.CASEID)'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		-- If the column is being published then concatenate it to the Select list

		If datalength(@sPublishName)>0
		Begin  
			Set @sAddSelectString=@sTableColumn+' as "'+@sPublishName+'"'

			exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentSelectString	OUTPUT,
						@psAddString	=@sAddSelectString,
						@psComponentType=@sSelect,
						@psSeparator    =@sComma,
						@pbForceLoad=0
			Set @sComma=', '
		End
		Else Begin
			Set @sPublishName=NULL
		End 	

		-- RFC100255
		-- If either the FirstUseClass or TrademarkClass columns
		-- are being reported then a system generated version of
		-- this column converted to its numeric value is required
		-- if the column is to be included in the Order By
		If @sColumn in ('FirstUseClass','TrademarkClass')
		and @nOrderPosition>0
		begin
			-- SQA19068
			-- For Centura if the column has not been included in the select
			-- list then we cannot use a numeric version of that column.
			If @pbCalledFromCentura=0
			or @sPublishName is not null
			Begin
				Set @sAddSelectString=
					'CASE WHEN(isnumeric('+@sTableColumn+')=1 and '+@sTableColumn+' not in (''$'',''+'','','',''-'',''.'')) THEN cast('+@sTableColumn+' as numeric) END as "'+isnull(@sPublishName,@sColumn)+'_Sort'+'"'


				exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentSelectString	OUTPUT,
					@psAddString	=@sAddSelectString,
					@psComponentType=@sSelect,
					@psSeparator    =@sComma,
					@pbForceLoad=0
			End
		end		

		-- If the column is to be sorted on then save the name of the table column along
		-- with the sort details so that later the Order By can be constructed in the correct sequence

		If @nOrderPosition>0
		and @ErrorCode=0
		Begin
			-- RFC100255
			-- If either the FirstUseClass or TrademarkClass columns
			-- are included in the Order By then a special numeric
			-- version of the column is additionally added in the Order By.
			If @sColumn in ('FirstUseClass','TrademarkClass')
			and (@pbCalledFromCentura=0	-- SQA19068
			  or @sPublishName is not null)
			Begin
				Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction, HiddenColumn)
				values(@nOrderPosition, @sTableColumn, isnull(@sPublishName,@sColumn)+'_Sort', @nColumnNo, @sOrderDirection, 1)

				Set @ErrorCode = @@ERROR
			End

			If @ErrorCode=0
			Begin
				Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction, HiddenColumn)
				values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection, @bHiddenColumn)

				Set @ErrorCode = @@ERROR
				Set @bOrderByDefined=1
			End
		End
	
		-- RFC9104
		-- Save the first published column. If there is not explicit Order By
		-- defined then the first column will be used.
		If @sFirstPublishName is null
		and datalength(@sPublishName)>0
		Begin
			Set @sFirstPublishName=@sPublishName
			Set @sFirstTableColumn=@sTableColumn
			Set @nFirstColumnNo   =@nColumnNo
		End
	End
	------------------------------------------------------
	-- String together a list of all the published columns
	-- that will exclude the hidden columns that have been
	-- used for sorting only.
	------------------------------------------------------
	If @bHiddenColumn=0
		Set @psPublishedColumns=CASE WHEN(@psPublishedColumns is not null) THEN @psPublishedColumns+',' END + 
		CASE WHEN (@pbCalledFromCentura=1) THEN '"'+@sPublishName+'"' ELSE '['+@sPublishName+']' END

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
End

-- RFC9104
-- If no ORDER BY column defined
-- then default to first column
If  @ErrorCode=0
and @bOrderByDefined=0
Begin
	Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction, HiddenColumn)
	values(1, @sFirstTableColumn, @sFirstPublishName, @nFirstColumnNo, 'A', 0)

	Set @ErrorCode = @@ERROR
End
	

-- If the Duedate, AllEvents or Reminders are being reported on then 
-- set some basic defaults for the filtering which was extracted 
-- earlier from XML.

If (@bDueDatesRequired=1
or  @bAllEventAndDueDatesRequired=1
or  @bAllEventsRequired=1
or  @bRemindersRequired=1)
and @ErrorCode=0
Begin
	-- If due dates are to be returned then at least one of the UseEventDate 
	-- or UseAdHocDates must be turned on
	If  isnull(@bUseEventDates,0)=0
	and isnull(@bUseAdHocDates,0)=0
		Set @bUseEventDates=1

	-- If due dates are to be returned then at least one of the UseDueDate
	-- or UseReminderDate options must be selected if dates are to be filtered on
	If(@bDueDatesRequired =1 
	or @bRemindersRequired=1)
	and isnull(@bUseDueDate,0)=0
	and isnull(@bUseReminderDate,0)=0
		Set @bUseDueDate=1

	-- If both the Renewals Only and NonRenewalsOnly flags are OFF then turn
	-- them both on so that all actions are reported.
	If  isnull(@bIsRenewalsOnly,0)=0
	and isnull(@bIsNonRenewalsOnly,0)=0
	Begin
		Set @bIsRenewalsOnly=1
		Set @bIsNonRenewalsOnly=1
	End

	-- Translate the PeriodRangeType if it exists
	Set @sPeriodRangeType=	Case(@sPeriodRangeType)
					When('D') Then 'dd'
					When('W') Then 'wk'
					When('M') Then 'mm'
					When('Y') Then 'yy'
				End

	-- If PeriodRangeType and either PeriodRangeFrom or PeriodRangeTo are supplied, then
	-- these are used to calculate DateRangeFrom date and the DateRangeTo before proceeding.
	-- The dates are calculated by adding the period and type to the 
	-- current date.

	If @sPeriodRangeType is not null
	Begin
		If @nPeriodRangeFrom is not null
		Begin
			Set @sSQLString = "Set @dtDateRangeFrom = dateadd("+@sPeriodRangeType+", @nPeriodRangeFrom, '" + convert(nvarchar,getdate(),112) + "')"

			execute sp_executesql @sSQLString,
					N'@dtDateRangeFrom	datetime 		output,
					  @nPeriodRangeFrom	smallint',
	  				  @dtDateRangeFrom	= @dtDateRangeFrom 	output,
					  @nPeriodRangeFrom	= @nPeriodRangeFrom		
	  
		End

		If @nPeriodRangeTo is not null
		Begin
			Set @sSQLString = "Set @dtDateRangeTo = dateadd("+@sPeriodRangeType+", @nPeriodRangeTo, '" + convert(nvarchar,getdate(),112) + "')"

			execute sp_executesql @sSQLString,
					N'@dtDateRangeTo	datetime 		output,
					  @nPeriodRangeTo	smallint',
	  				  @dtDateRangeTo	= @dtDateRangeTo 	output,
					  @nPeriodRangeTo	= @nPeriodRangeTo				  
		End

		Set @nDateRangeOperator=@nPeriodRangeOperator
	End

	-- RFC941
	-- If Due Dates are to be filtered on and the user is external then the starting
	-- date range may be overridden by a value determined from a Site Control.

	-- Get the number of days earlier than the current system date
	-- that due date searches are to be restricted from
	If @pbExternalUser=1
	Begin
		Set @sSQLString="
		Select @nOverdueDays=COLINTEGER
		from SITECONTROL
		where CONTROLID='Client Due Dates: Overdue Days'"
	
		execute sp_executesql @sSQLString,
					N'@nOverdueDays		int	output',
					  @nOverdueDays=@nOverdueDays	output
	
		If @nOverdueDays is not null
		Begin
			Set @dtOverdueRangeFrom = convert(nvarchar,dateadd(Day, @nOverdueDays*-1, getdate()),112)
	
			If @dtOverdueRangeFrom>@dtDateRangeFrom
			or @dtDateRangeFrom is null
				Set @dtDateRangeFrom=@dtOverdueRangeFrom
	
			If @dtDateRangeTo is null
				Set @nDateRangeOperator=7 -- between
		End
	End
End

-- If filtering is required on Due Dates but the tables required have not yet
-- been joined to, then add the appropriate Joins.
If isnull(@bDueDatesLoaded,0)=0
and  @bUseDueDate=1
and (@dtDateRangeFrom is not null
 or  @dtDateRangeTo   is not null)
Begin						
	Set @sAddFromString = "Join CASEEVENT DD with (NOLOCK) on (DD.CASEID=C.CASEID"
	
	If @sCaseEventCorrelation is not null
		Set @sAddFromString = @sAddFromString + " and DD.EVENTNO="+@sCaseEventCorrelation+".EVENTNO and DD.CYCLE  ="+@sCaseEventCorrelation+".CYCLE"
						
	Set @sAddFromString = @sAddFromString + ")"
			   +char(10)+"Left Join EVENTCONTROL DDEC with (NOLOCK) on (DDEC.CRITERIANO=DD.CREATEDBYCRITERIA"
			   +char(10)+"				and DDEC.EVENTNO=DD.EVENTNO)"
			   +CASE WHEN(@pbExternalUser=1)
				 THEN +char(10)+"     Join #TEMPEVENTS DDE          on (DDE.EVENTNO=DD.EVENTNO)"
					  +char(10)+"     Left Join EVENTS DDEX			on (DDEX.EVENTNO=DDE.EVENTNO)"
				 ELSE +char(10)+"     Join EVENTS DDE with (NOLOCK) on (DDE.EVENTNO=DD.EVENTNO)"
			    END

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentFromString	OUTPUT,
				@psAddString	=@sAddFromString,
				@psComponentType=@sFrom,
				@psSeparator    =@sReturn,
				@pbForceLoad=0

	Set @pnTableCount=@pnTableCount+3
	
	Set @bDueDatesRequired=1
End

If  @bDueDatesRequired=1
and isnull(@bIsSignatory,0) | isnull(@bIsStaff,0) | isnull(@bIsAnyName,0)=1	-- at least 1 flag is ON
and isnull(@bIsSignatory,0) & isnull(@bIsStaff,0) & isnull(@bIsAnyName,0)=0	-- at least 1 flag must be OFF
Begin
	------------------------------------------------------------------------------
	-- If the Due Date is to be associated with the Signatory or Staff then filter
	-- for CaseEvents either directly associated with the Signatory or  Staff name
	-- or where no specific NameNo and NameType has been linked to the Case Event.
	------------------------------------------------------------------------------
	If @bIsSignatory=1
	and isnull(@bIsAnyName,0)=0
	Begin		
		Set @sAddFromString = 'Left Join CASENAME SIG'
	
		If not exists(	select 1 from #TempConstructSQL T
				where T.SavedString like '%'+@sAddFromString+'%')
		and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
		Begin						
			Set @sAddFromString = "Left Join CASENAME SIG	on (SIG.CASEID=C.CASEID"
					   +char(10)+"                      	and(SIG.EXPIRYDATE is null or SIG.EXPIRYDATE>getdate() )"
					   +char(10)+"                      	and SIG.NAMETYPE='SIG')"
		
			exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentFromString	OUTPUT,
						@psAddString	=@sAddFromString,
						@psComponentType=@sFrom,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
		
			Set @pnTableCount=@pnTableCount+1
		End
	End

	If @bIsStaff=1
	and isnull(@bIsAnyName,0)=0
	Begin						
		Set @sAddFromString = 'Left Join CASENAME EMP'
	
		If not exists(	select 1 from #TempConstructSQL T
				where T.SavedString like '%'+@sAddFromString+'%')
		and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
		Begin		
			Set @sAddFromString = "Left Join CASENAME EMP	on (EMP.CASEID=C.CASEID"
					   +char(10)+"                      	and(EMP.EXPIRYDATE is null or EMP.EXPIRYDATE>getdate() )"
					   +char(10)+"                      	and EMP.NAMETYPE='EMP')"
		
			exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentFromString	OUTPUT,
						@psAddString	=@sAddFromString,
						@psComponentType=@sFrom,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
		
			Set @pnTableCount=@pnTableCount+1
		End
	End

	Set @sAddWhereString=null

	-- IsAnyName   requires a specific Name or NameType against the CaseEvent
	-- IsStaff     requires no Name and NameType or points to the EMP CaseName
	-- IsSignatory requires no Name and NameType or points to the SIG CaseName

	-- Note:
	-- Do not use the Close Bracket as other conditions may need to be added
	Set @nCloseBracket=0
	
	If  @bIsAnyName=1
	and isnull(@bIsStaff,0)=0
	and isnull(@bIsSignatory,0)=0
	Begin
		Set @sAddWhereString="and (DD.EMPLOYEENO is not null OR DD.DUEDATERESPNAMETYPE is not null"
		Set @nCloseBracket=1
	End
	Else if  @bIsStaff=1
	     and @bIsSignatory=1
	Begin
		Set @sAddWhereString="and(DD.EMPLOYEENO in (EMP.NAMENO,SIG.NAMENO) OR DD.DUEDATERESPNAMETYPE in ('EMP','SIG') OR (DD.EMPLOYEENO is null and DD.DUEDATERESPNAMETYPE is null)"
		Set @nCloseBracket=1
	End
	Else If @bIsStaff=1
	     and isnull(@bIsAnyName,0)=0
	Begin
		Set @sAddWhereString="and(DD.EMPLOYEENO=EMP.NAMENO OR DD.DUEDATERESPNAMETYPE='EMP' OR (DD.EMPLOYEENO is null AND DD.DUEDATERESPNAMETYPE is null)"
		Set @nCloseBracket=1
	End
	Else If @bIsSignatory=1
	     and isnull(@bIsAnyName,0)=0
	Begin
		Set @sAddWhereString="and(DD.EMPLOYEENO=SIG.NAMENO OR DD.DUEDATERESPNAMETYPE='SIG' OR (DD.EMPLOYEENO is null AND DD.DUEDATERESPNAMETYPE is null)"
		Set @nCloseBracket=1
	End

	If @sAddWhereString is not null
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
End

If  @bDueDatesRequired=1
and @nNameTypeOperator is not null
and @sNameTypeKey is not null
Begin
	------------------------------------------------------------------------------
	-- If the Due Date is to be restricted by NameType(s) then get the CaseName
	-- rows for the Case associated with the NameType(s).
	------------------------------------------------------------------------------
	Set @sAddFromString = "Left Join CASENAME CNDD	on (CNDD.CASEID=C.CASEID"
			   +char(10)+"                      	and(CNDD.EXPIRYDATE is null or CNDD.EXPIRYDATE>getdate() )"
			   +char(10)+"                      	and CNDD.NAMETYPE"+dbo.fn_ConstructOperator(@nNameTypeOperator,@CommaString,@sNameTypeKey,null,@pbCalledFromCentura)+")"

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentFromString	OUTPUT,
				@psAddString	=@sAddFromString,
				@psComponentType=@sFrom,
				@psSeparator    =@sReturn,
				@pbForceLoad=0

	Set @pnTableCount=@pnTableCount+1

	If @nCloseBracket>0
	Begin
		Set @sAddWhereString=" OR ((DD.EMPLOYEENO=CNDD.NAMENO OR DD.DUEDATERESPNAMETYPE"+dbo.fn_ConstructOperator(@nNameTypeOperator,@CommaString,@sNameTypeKey,null,@pbCalledFromCentura)+")"
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =' ',
					@pbForceLoad=0
	End
	Else Begin
		Set @sAddWhereString="and(DD.EMPLOYEENO=CNDD.NAMENO OR DD.DUEDATERESPNAMETYPE"+dbo.fn_ConstructOperator(@nNameTypeOperator,@CommaString,@sNameTypeKey,null,@pbCalledFromCentura)+")"
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
	
	Set @nCloseBracket=@nCloseBracket+1
End

If  @bDueDatesRequired=1
and @nNameOperator is not null
and @sNameKey is not null
Begin
	-------------------------------------
	-- Restrict the Due Date to NameNo(s)
	-------------------------------------

	If @nCloseBracket=0
	Begin
		Set @sAddWhereString="and DD.EMPLOYEENO"+dbo.fn_ConstructOperator(@nNameOperator,@Numeric,@sNameKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
	If @nCloseBracket=1
	Begin
		Set @nCloseBracket=2
		Set @sAddWhereString=" OR (DD.EMPLOYEENO"+dbo.fn_ConstructOperator(@nNameOperator,@Numeric,@sNameKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =' ',
					@pbForceLoad=0
	End
	Else Begin
		Set @sAddWhereString="and DD.EMPLOYEENO"+dbo.fn_ConstructOperator(@nNameOperator,@Numeric,@sNameKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
End

If  @bDueDatesRequired=1
and @nNameGroupOperator is not null
and @sNameGroupKey is not null
Begin
	-------------------------------------------------------------------------
	-- Restrict the Due Date to Names associated with a particular Name Group
	-------------------------------------------------------------------------

	Set @sAddFromString = 'Left Join NAME DDEMP'

	If not exists(	select 1 from #TempConstructSQL T
			where T.SavedString like '%'+@sAddFromString+'%')
	and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
	Begin									
		Set @sAddFromString = "Left Join NAME DDEMP	on (DDEMP.NAMENO=DD.EMPLOYEENO)"
	
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentFromString	OUTPUT,
					@psAddString	=@sAddFromString,
					@psComponentType=@sFrom,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	
		Set @pnTableCount=@pnTableCount+1
	End

	If @nCloseBracket=0
	Begin
		Set @sAddWhereString="and DDEMP.FAMILYNO"+dbo.fn_ConstructOperator(@nNameGroupOperator,@Numeric,@sNameGroupKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
	If @nCloseBracket=1
	Begin
		Set @nCloseBracket=2
		Set @sAddWhereString=" OR (DDEMP.FAMILYNO"+dbo.fn_ConstructOperator(@nNameGroupOperator,@Numeric,@sNameGroupKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =' ',
					@pbForceLoad=0
	End
	Else Begin
		Set @sAddWhereString="and DDEMP.FAMILYNO"+dbo.fn_ConstructOperator(@nNameGroupOperator,@Numeric,@sNameGroupKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
End

If  @bDueDatesRequired=1
and @nStaffClassOperator is not null
and @sStaffClassKey is not null
Begin
	--------------------------------------------------------------------------------
	-- Restrict the Due Date to Names belonging to a particular Staff Classification
	--------------------------------------------------------------------------------

	Set @sAddFromString = 'Left Join EMPLOYEE EDD'

	If not exists(	select 1 from #TempConstructSQL T
			where T.SavedString like '%'+@sAddFromString+'%')
	and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
	Begin									
		Set @sAddFromString = "Left Join EMPLOYEE EDD	on (EDD.EMPLOYEENO=DD.EMPLOYEENO)"
	
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentFromString	OUTPUT,
					@psAddString	=@sAddFromString,
					@psComponentType=@sFrom,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	
		Set @pnTableCount=@pnTableCount+1
	End

	If @nCloseBracket=0
	Begin
		Set @sAddWhereString="and EDD.STAFFCLASS"+dbo.fn_ConstructOperator(@nStaffClassOperator,@Numeric,@sStaffClassKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
	If @nCloseBracket=1
	Begin
		Set @nCloseBracket=2
		Set @sAddWhereString=" OR (EDD.STAFFCLASS"+dbo.fn_ConstructOperator(@nStaffClassOperator,@Numeric,@sStaffClassKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =' ',
					@pbForceLoad=0
	End
	Else Begin
		Set @sAddWhereString="and EDD.STAFFCLASS"+dbo.fn_ConstructOperator(@nStaffClassOperator,@Numeric,@sStaffClassKey,null,@pbCalledFromCentura)
		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
	End
End

If @nCloseBracket>0
Begin
		-- Add in the variable number of close brackets
		-- to end the expression.
		Set @sAddWhereString=replicate(')',@nCloseBracket)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    ='',
					@pbForceLoad=0
End

/*
declare @nStaffClassOperator		tinyint
declare @sStaffClassKey			nvarchar(1000)
*/

-- Construct the WHERE clause to filter the columns
If @bDueDatesRequired=1
and @ErrorCode=0
Begin	
	-- For the DueDate range of columns then a restriction in the WHERE clause
	-- is required to ensure that the Event has not actually occurred.

	-- SQA12766 Added 'and DD.EVENTDUEDATE IS NOT NULL' below
	Set @sAddWhereString='and isnull(DD.OCCURREDFLAG,0)=0 and DD.EVENTDUEDATE IS NOT NULL'

	exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0

	--RFC8970 Remove restriction to filtering by Due Date importance level
	-- This is now enabled for external users.
	If   @ErrorCode=0
	and  @nImportanceLevelOperator is not null
	and (@sImportanceLevelFrom     is not null
	 or  @sImportanceLevelTo       is not null)
	Begin
	        If ISNULL(@pbExternalUser,0) = 0
	        Begin
		        Set @sAddWhereString="and coalesce(DDEC.IMPORTANCELEVEL,DDE.IMPORTANCELEVEL,9)"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
		End
		Else if @pbExternalUser = 1
		Begin
		        Set @sAddWhereString="and coalesce(DDEX.CLIENTIMPLEVEL,DDE.IMPORTANCELEVEL,9)"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
		End

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End

	If  @ErrorCode=0
	and @nEventCategoryKeyOperator is not null
	Begin
		Set @sAddWhereString="and DDE.CATEGORYID"+dbo.fn_ConstructOperator(@nEventCategoryKeyOperator,'N',@sEventCategoryKeys, null,@pbCalledFromCentura)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End

	-- Check for any restrictions on the OpenActions
	-- If the IncludeClosedActions option is off then only report due dates
	-- that have an associated OpenAction.
	If @ErrorCode=0
	and( isnull(@bIncludeClosedActions,0)=0
	 or (@bIsRenewalsOnly   =1 and isnull(@bIsNonRenewalsOnly,0)=0)
	 or (@bIsNonRenewalsOnly=1 and isnull(@bIsRenewalsOnly,0)   =0)
	 or  @sActionKeys is not null
	 or  @nActionOperator is not null)
	Begin
		Set @sAddWhereString="and exists"
				+char(10)+"(select 1 from OPENACTION OAX with (NOLOCK)"
				+char(10)+" join EVENTCONTROL ECX with (NOLOCK) on (ECX.CRITERIANO=OAX.CRITERIANO"
				+char(10)+"                                     and ECX.EVENTNO=DD.EVENTNO)"
				+char(10)+" join ACTIONS AX with (NOLOCK) on (AX.ACTION=OAX.ACTION)"
				+char(10)+" where OAX.CASEID=C.CASEID"

		If @sRenewalAction is not NULL
		and(@sActionKeys is NULL or @nActionOperator>0)
		and @bAnyRenewalAction=0
		and @bAnyOpenAction=0
			Set @sAddWhereString=@sAddWhereString
				+char(10)+" and OAX.ACTION=CASE WHEN(DD.EVENTNO=-11) THEN '"+@sRenewalAction+"' ELSE isnull(DDE.CONTROLLINGACTION,OAX.ACTION) END"

		If isnull(@bIncludeClosedActions,0)=0
			Set @sAddWhereString=@sAddWhereString
				+char(10)+" and OAX.POLICEEVENTS=1"
				+char(10)+" and OAX.CYCLE=CASE WHEN(AX.NUMCYCLESALLOWED>1) THEN DD.CYCLE ELSE 1 END"
				
		-----------------------------------------------------------------
		-- RFC40200
		-- If the filter Action is not ~2 (Renewals - Law Update Service)
		-- then explicitly filter out the ~2 Open Action
		-----------------------------------------------------------------				
		If isnull(@sActionKeys,'') not like '%~2%'
		or @nActionOperator>0
			Set @sAddWhereString=@sAddWhereString
				+char(10)+" and (OAX.ACTION<>'~2' OR DDE.CONTROLLINGACTION='~2')" --SQA16423

		If @bIsRenewalsOnly=1 
		and isnull(@bIsNonRenewalsOnly,0)=0
			Set @sAddWhereString = @sAddWhereString+char(10)+" and AX.ACTIONTYPEFLAG=1"

		If @bIsNonRenewalsOnly=1 
		and isnull(@bIsRenewalsOnly,0)=0
			Set @sAddWhereString = @sAddWhereString+char(10)+" and isnull(AX.ACTIONTYPEFLAG,0)<>1"

		If @sActionKeys is not null
		or @nActionOperator is not null
			Set @sAddWhereString=@sAddWhereString+char(10)+" and OAX.ACTION"+dbo.fn_ConstructOperator(@nActionOperator,@CommaString,@sActionKeys,null,@pbCalledFromCentura)

		Set @sAddWhereString=@sAddWhereString+')'

		-- Need to save this subselect so it can be removed if the UNION select 
		-- for Alerts is created
		Set @sSaveExistsClause=@sAddWhereString

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End

	If  @ErrorCode=0
	and @nEventOperator is not null
	Begin
		Set @sAddWhereString="and DD.EVENTNO"+dbo.fn_ConstructOperator(@nEventOperator,'N',@sEventKeys, null,@pbCalledFromCentura)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End	

	If  @ErrorCode=0
	and @nEventStaffKeyOperator is not null
	Begin
		Set @sAddWhereString="and DD.EMPLOYEENO"+dbo.fn_ConstructOperator(@nEventStaffKeyOperator,'N',@nEventStaffKey, null,@pbCalledFromCentura)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End	

End

-- Construct the WHERE clause to filter the columns
-- if All Events are being reported on.
If @bAllEventsRequired=1 or @bAllEventAndDueDatesRequired=1
and @ErrorCode=0
Begin	
	--RFC8970 Remove restriction to filtering by Due Date importance level
	-- This is now enabled for external users.
	If   @nImportanceLevelOperator is not null
	and (@sImportanceLevelFrom     is not null
	 or  @sImportanceLevelTo       is not null)
	Begin
	        If ISNULL(@pbExternalUser,0) = 0
	        Begin
		        Set @sAddWhereString="and "+@sCaseEventCorrelation+".IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
		End
		Else if @pbExternalUser = 1
		Begin
		        Set @sAddWhereString="and coalesce("+@sCaseEventCorrelation+".CLIENTIMPLEVEL,9)"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)
		End

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End

	If  @ErrorCode=0
	and @nEventCategoryKeyOperator is not null
	Begin
		Set @sAddWhereString="and "+@sCaseEventCorrelation+".CATEGORYID"+dbo.fn_ConstructOperator(@nEventCategoryKeyOperator,'N',@sEventCategoryKeys, null,@pbCalledFromCentura)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End

	-- Check for any restrictions on the OpenActions
	-- If the IncludeClosedActions option is off then only report due dates
	-- that have an associated OpenAction.
	If @ErrorCode=0
	and( isnull(@bIncludeClosedActions,0)=0
	 or (@bIsRenewalsOnly   =1 and isnull(@bIsNonRenewalsOnly,0)=0)
	 or (@bIsNonRenewalsOnly=1 and isnull(@bIsRenewalsOnly,0)   =0)
	 or  @sActionKeys is not null
	 or  @nActionOperator is not null)
	Begin
		Set @sAddWhereString="and exists"
				+char(10)+"(select 1 from OPENACTION OAX with (NOLOCK)"
				+char(10)+" join EVENTCONTROL ECX with (NOLOCK) on (ECX.CRITERIANO=OAX.CRITERIANO"
				+char(10)+"                                     and ECX.EVENTNO="+@sCaseEventCorrelation+".EVENTNO)"
				+char(10)+" join ACTIONS AX with (NOLOCK) on (AX.ACTION=OAX.ACTION)"
				+char(10)+" where OAX.CASEID=C.CASEID"

		If @sRenewalAction is not NULL
		and(@sActionKeys is NULL or @nActionOperator>0)
		and @bAnyRenewalAction=0
		and @bAnyOpenAction=0
			Set @sAddWhereString=@sAddWhereString
				+char(10)+" and OAX.ACTION=CASE WHEN("+@sCaseEventCorrelation+".EVENTNO=-11) THEN '"+@sRenewalAction+"' ELSE OAX.ACTION END"

		If isnull(@bIncludeClosedActions,0)=0
			Set @sAddWhereString=@sAddWhereString
				+char(10)+" and OAX.POLICEEVENTS=1"
				+char(10)+" and OAX.CYCLE=CASE WHEN(AX.NUMCYCLESALLOWED>1) THEN "+@sCaseEventCorrelation+".CYCLE ELSE 1 END"
				
		If @bIsRenewalsOnly=1 
		and isnull(@bIsNonRenewalsOnly,0)=0
			Set @sAddWhereString = @sAddWhereString+char(10)+" and AX.ACTIONTYPEFLAG=1"

		If @bIsNonRenewalsOnly=1 
		and isnull(@bIsRenewalsOnly,0)=0
			Set @sAddWhereString = @sAddWhereString+char(10)+" and isnull(AX.ACTIONTYPEFLAG,0)<>1"

		If @sActionKeys is not null
		or @nActionOperator is not null
			Set @sAddWhereString=@sAddWhereString+char(10)+" and OAX.ACTION"+dbo.fn_ConstructOperator(@nActionOperator,@CommaString,@sActionKeys,null,@pbCalledFromCentura)

		Set @sAddWhereString=@sAddWhereString+')'

		-- Need to save this subselect so it can be removed if the UNION select 
		-- for Alerts is created
		Set @sSaveExistsClause=@sAddWhereString

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End

	If  @ErrorCode=0
	and @nEventOperator is not null
	Begin
		Set @sAddWhereString="and "+@sCaseEventCorrelation+".EVENTNO"+dbo.fn_ConstructOperator(@nEventOperator,'N',@sEventKeys, null,@pbCalledFromCentura)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End	

	If  @ErrorCode=0
	and @nEventStaffKeyOperator is not null
	Begin
		Set @sAddWhereString="and "+@sCaseEventCorrelation+".EMPLOYEENO"+dbo.fn_ConstructOperator(@nEventStaffKeyOperator,'N',@nEventStaffKey, null,@pbCalledFromCentura)

		exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentWhereString	OUTPUT,
						@psAddString	=@sAddWhereString,
						@psComponentType=@sWhere,
						@psSeparator    =@sReturn,
						@pbForceLoad=0
	End	

End

-- If filtering on the EmployeeReminder date is require but no EmployeeReminder
-- columns have been selected then we need to add the appropriate join to allow 
-- the filtering to occur.

If isnull(@bRemindersLoaded,0)=0
and @bUseReminderDate=1
and @ErrorCode=0
Begin						
	Set @sAddFromString = "Left Join EMPLOYEEREMINDER ER	on (ER.CASEID=C.CASEID"

	-- If Due Dates have also been reported then the Reminders should
	-- match the EventNo and Cycle of the Due Date.
	If @bDueDatesRequired=1
	Begin
		Set @sAddFromString=@sAddFromString
			   +char(10)+"				and ER.EVENTNO=DD.EVENTNO"
			   +char(10)+"				and ER.CYCLENO=DD.CYCLE"
	End

	-- Need to cater for the possibility of the Reminders being sent to multiple
	-- Names.  Just get the reminder against the first name
	Set @sAddFromString=@sAddFromString
			   +char(10)+"				and ER.EMPLOYEENO=(select min(ER1.EMPLOYEENO)"
			   +char(10)+"				                   from EMPLOYEEREMINDER ER1"
			   +char(10)+"				                   WHERE ER1.CASEID=ER.CASEID"
			   +char(10)+"				                   and (ER1.EVENTNO=ER.EVENTNO or (ER1.EVENTNO is null and ER.EVENTNO is null))"
			   +char(10)+"				                   and (ER1.CYCLENO=ER.CYCLENO or (ER1.CYCLENO is null and ER.CYCLENO is null))"


	-- External users are only to see reminders addressed to 
	-- a name they have access to.
	If @pbExternalUser=1
	Begin
		Set @sAddFromString=@sAddFromString
			   +char(10)+"				                   and ER1.EMPLOYEENO in (select NAMENO from dbo.fn_FilterUserNames("+cast(@pnUserIdentityId as nvarchar(12))+",1))"
	End

	Set @sAddFromString=@sAddFromString+'))'

	-- The EmployeeReminder join is saved so that it can be replaced if 
	-- a UNION is generated for the ALERT table
	Set @sSaveReminderJoin=@sAddFromString

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentFromString	OUTPUT,
				@psAddString	=@sAddFromString,
				@psComponentType=@sFrom,
				@psSeparator    =@sReturn,
				@pbForceLoad=0

	Set @pnTableCount=@pnTableCount+2
End

-- Filter on the date range
If   @ErrorCode=0
and (@dtDateRangeFrom is not null
 or  @dtDateRangeTo   is not null)
Begin
	If @bAllEventsRequired=1 or (isnull(@bUseDueDate,0)=0 and @bAllEventAndDueDatesRequired=1)
	Begin
		Set @sAddWhereString= "and "+@sCaseEventCorrelation+".EVENTDATE"+dbo.fn_ConstructOperator(@nDateRangeOperator,'DT',convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
	End
	Else If @bUseDueDate=1 or @bAllEventAndDueDatesRequired=1
	Begin
		Set @sAddWhereString= "and(DD.EVENTDUEDATE"+dbo.fn_ConstructOperator(@nDateRangeOperator,'DT',convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
		
		If @bAllEventAndDueDatesRequired=1
			Set @sAddWhereString=@sAddWhereString+char(10)+ "or "+@sCaseEventCorrelation+".EVENTDATE"+dbo.fn_ConstructOperator(@nDateRangeOperator,'DT',convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)

		If @bUseReminderDate=1
			Set @sAddWhereString=@sAddWhereString+char(10)+" or ER.REMINDERDATE"+dbo.fn_ConstructOperator(@nDateRangeOperator,'DT',convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)+')'
		Else
			Set @sAddWhereString=@sAddWhereString+')'
	End
	Else If @bUseReminderDate=1
	Begin
		Set @sAddWhereString= "and ER.REMINDERDATE"+dbo.fn_ConstructOperator(@nDateRangeOperator,'DT',convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
	End


	exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentWhereString	OUTPUT,
					@psAddString	=@sAddWhereString,
					@psComponentType=@sWhere,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
End

-- Now construct the Order By clause

If @ErrorCode=0
Begin		
	-- Assemble the "Order By" clause.
	-- If the CLASS column is to be sorted on then also include an extra sort on the numeric 
	-- equivalent of the class.

	Select @sAddOrderByString= ISNULL(NULLIF(@sAddOrderByString+',', ','),'')			
			 +CASE WHEN(PublishName is null) THEN ColumnName
				-- RFC4010 when the column name has quotes around it, 
				-- WorkBenches returns it as a literal instead of the 
				-- contents of the column.  However, client/server 
				-- requires the quotes to handle special characters - See SQA11738.
			       ELSE CASE WHEN (@pbCalledFromCentura=1) THEN '"'+PublishName+'"' ELSE '['+PublishName+']' END	-- SQA20833
			  END
			+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END,
		-- A second ORDER BY list will be based on the column names rather than the presentation column names.
		-- This ORDER BY will be used when generating an interim table of sorted Cases without all of
		-- the presentation columns.  Any columns that get calculated by cs_ListCaseCharges will be excluded
		-- from the list as at the point of generating the interim table the values will not be known.
	       @sOrderColumnString=			
			CASE   WHEN(ColumnName in ('TT.ChargeDueEventAny',
						   'TT.FeeBillCurrencyAny',
					 	   'TT.FeeBilledAmountAny',
						   'TT.FeeBilledPerYearAny',
						   'TT.FeeDueDateAny',
						   'TT.FeesChargeTypeAny',
						   'TT.FeeYearNoAny')) THEN @sOrderColumnString
			       ELSE ISNULL(NULLIF(@sOrderColumnString+',', ','),'')
				   +ColumnName+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
			END,
		-- A third ORDER BY will contain just the columns that will actually 
		-- be displayed in the final result.
		@psPublishedOrderBy=CASE WHEN(HiddenColumn=1) 
					THEN @psPublishedOrderBy
					ELSE CASE WHEN(@psPublishedOrderBy is not null)
						THEN @psPublishedOrderBy+','
						ELSE ''
					     END +
					     CASE WHEN (@pbCalledFromCentura=1) THEN '"'+PublishName+'"' ELSE '['+PublishName+']' END+	-- RFC44200 change @sPublishName to PublishName
					     CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				    END
			from @tbOrderBy
			order by Position

	Set @ErrorCode=@@Error		

	If @psPublishedOrderBy is not null
		Set @psPublishedOrderBy= 'Order by '+@psPublishedOrderBy

	If @sAddOrderByString is not null
	and @ErrorCode=0
	Begin
		Set @sAddOrderByString = char(10)+'Order by ' + @sAddOrderByString

		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentOrderByString	OUTPUT,
					@psAddString	=@sAddOrderByString,
					@psComponentType=@sOrderBy,
					@psSeparator    =null,
					@pbForceLoad=1

		If @ErrorCode=0
		Begin
			Set @sOrderColumnString = char(10)+'Order by ' + @sOrderColumnString
	
			exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentOrderColumnString	OUTPUT,
						@psAddString	=@sOrderColumnString,
						@psComponentType=@sColumnOrderBy,
						@psSeparator    =null,
						@pbForceLoad=1
		End
	End
End

-- Force the current From string to be saved
If datalength(@sCurrentFromString)>0	
and @ErrorCode=0
Begin
	Set @sAddFromString=null

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentFromString	OUTPUT,
				@psAddString	=@sAddFromString,
				@psComponentType=@sFrom, 
				@psSeparator    =null,
				@pbForceLoad=1
End

-- Force the current Select string to be saved
If datalength(@sCurrentSelectString)>0	
and @ErrorCode=0
Begin
	If (@bDueDatesRequired=1 AND 
	(@bUseAdHocDates  =1
	OR @bUseRelatedCase =1
	OR @bUseDueDate     =1
	OR @bUseReminderDate=1) AND @bHasImageData = 0)
		Set @sCurrentSelectString=replace(@sCurrentSelectString,'Select ','Select DISTINCT ')

	Set @sAddSelectString=null

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentSelectString	OUTPUT,
				@psAddString	=@sAddSelectString,
				@psComponentType=@sSelect, 
				@psSeparator    =null,
				@pbForceLoad=1
End

-- Force the current Where string to be saved
If datalength(@sCurrentWhereString)>0	
and @ErrorCode=0
Begin
	Set @sAddWhereString=null

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentWhereString	OUTPUT,
				@psAddString	=@sAddWhereString,
				@psComponentType=@sWhere, 
				@psSeparator    =null,
				@pbForceLoad=1
End

-- RFC8970 Only return Event Due Dates for External Users
If @ErrorCode = 0
and @pbExternalUser = 1
Begin
        Set @bUseAdHocDates = 0
End

-- If a UNION is required (to return Ad-Hoc Reminders) then the generated SELECT, FROM 
-- and WHERE clauses are to be copied and modified for later inclusion

If  @bDueDatesRequired=1
and @bUseAdHocDates=1
and @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TempConstructSQL (ComponentType, SavedString)
	Select	@sUnionSelect, 
		replace(
		replace(
		replace(
		replace(
		replace(
		replace(
		replace(
		replace(
		replace(
		replace(
		replace(
		--replace(	--RFC59688 comment out
		--replace(	--RFC59688 comment out
		replace(
		replace(SavedString, 'isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'DDEC',@sLookupCulture,@pbCalledFromCentura)
					      +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'DDE',@sLookupCulture,@pbCalledFromCentura)+')', 'DD.ALERTMESSAGE'),
				     'DD.EVENTDUEDATE','DD.DUEDATE'),
				     'DDET.EVENTTEXT','NULL'),
				     'DDET.LOGDATETIMESTAMP','NULL'),
				     'DDETT.DESCRIPTION','NULL'),
				     dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'DDECT',@sLookupCulture,@pbCalledFromCentura),'NULL'),
				     'DDECT.ICONIMAGEID','NULL'),
				     'DD.CYCLE', 'NULL'),
				     'DD.EMPLOYEENO', 'NULL'),
				    -- 'dbo.fn_FormatName(DDEMP.NAME, DDEMP.FIRSTNAME, DDEMP.TITLE, null)', 'NULL'),	--RFC59688 comment out
				    -- 'DDEMP.NAMECODE', 'NULL'),							--RFC59688 comment out
				     ' Select','Union /*All*/'+char(10)+'Select'),	--SQA17562 Leading space before SELECT is essential
				     char(10)+'     WHEN(DDNT.NAMETYPE is not null) THEN DDNT.DESCRIPTION',''),
				     'isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'DDEC2',@sLookupCulture,@pbCalledFromCentura)
					      +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'DDE2',@sLookupCulture,@pbCalledFromCentura)+')', 'NULL'),
				     'DD2.EVENTDUEDATE', 'NULL')
	From #TempConstructSQL
	Where ComponentType='S'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sUnionSelect		char(1),
				  @sLookupCulture		nvarchar(10),
				  @pbCalledFromCentura  bit',
				  @sUnionSelect=@sUnionSelect,
				  @sLookupCulture=@sLookupCulture,
				  @pbCalledFromCentura=@pbCalledFromCentura

	If @ErrorCode=0
	Begin
		-- Reset the @sSaveReminderJoin if it is NULL to ensure the REPLACE performs correctly.
		If @sSaveReminderJoin is null
		Begin
			Set @sSaveReminderJoin=''
			Set @sReplacementString = ''
		End
		Else Begin
			Set @sReplacementString="Left Join EMPLOYEEREMINDER ER with (NOLOCK) on (ER.CASEID=C.CASEID"
					   +char(10)+"				and ER.EMPLOYEENO=DD.EMPLOYEENO"
					   +char(10)+"				and ER.SEQUENCENO=DD.SEQUENCENO"
					   +char(10)+"				and ER.EVENTNO is null)"
		End

		Set @sSQLString="
		Insert into #TempConstructSQL (ComponentType, SavedString)
		Select	@sUnionFrom,
			replace(
			replace(
			replace(
			replace( 
			replace(
			replace(
			replace(
			replace(
			replace( 
			replace(
			replace(
			replace(
			replace(
			replace( 
			replace(
			replace(
			replace(
			replace(
			replace( 
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(SavedString, 'Join CASEEVENT DD with (NOLOCK) on (DD.CASEID=C.CASEID and DD.EVENTNO="+@sCaseEventCorrelation+".EVENTNO and DD.CYCLE  ="+@sCaseEventCorrelation+".CYCLE)', 'Join ALERT DD with (NOLOCK) on (DD.CASEID=C.CASEID)'),
					     'Join CASEEVENT DD with (NOLOCK)', 'Join ALERT DD with (NOLOCK)'),
					     'Left Join dbo.fn_GetCaseEventDates() "+@sCaseEventCorrelation+" on ("+@sCaseEventCorrelation+".CASEID=C.CASEID','Left Join dbo.fn_GetCaseEventDates() "+@sCaseEventCorrelation+" on (0=1'),
					     'Left Join IMPORTANCE IL on (IL.IMPORTANCELEVEL=isnull(DDEC.IMPORTANCELEVEL,DDE.IMPORTANCELEVEL))','Left Join IMPORTANCE IL on (IL.IMPORTANCELEVEL=DD.IMPORTANCELEVEL)'),
					     char(10)+'Left Join OPENACTION DD_OA with (NOLOCK) on (DD_OA.CASEID=C.CASEID)',''),
					     char(10)+'Left Join EVENTCONTROL DDEC with (NOLOCK) on (DDEC.CRITERIANO=DD_OA.CRITERIANO',''),
					     char(10)+'Left Join EVENTCONTROL DDEC with (NOLOCK) on (DDEC.CRITERIANO=DD.CREATEDBYCRITERIA',''),
					     char(10)+'				and DDEC.EVENTNO=DD.EVENTNO)',''),
					     char(10)+'     Join #TEMPEVENTS DDE',''),
					     char(10)+'     Left Join EVENTS DDEX         on (DDEX.EVENTNO=DDE.EVENTNO)',''),
					     char(10)+'     Join EVENTS DDE with (NOLOCK) on (DDE.EVENTNO=DD.EVENTNO)',''),
					     char(10)+'				on (DDE.EVENTNO=DD.EVENTNO)',''),
					     @sSaveReminderJoin,@sReplacementString),
					     char(10)+' join ACTIONS AX with (NOLOCK) on (AX.ACTION=OAX.ACTION)',''),
					     char(10)+'Left Join EVENTCATEGORY DDECT with (NOLOCK) on (DDECT.CATEGORYID=DDE.CATEGORYID)',''),
					     char(10)+'Left Join NAMETYPE DDNT WITH (NOLOCK) on (DDNT.NAMETYPE=DD.DUEDATERESPNAMETYPE)',''),
					     'Left Join (select DD1.CASEID, DDE1.EVENTGROUP, max(DD1.EVENTDUEDATE) as EVENTDUEDATE',''),
				             char(10)+'           from EVENTS DDE1 with (NOLOCK)',''),
				             char(10)+'           join CASEEVENT DD1 with (NOLOCK) on (DD1.EVENTNO=DDE1.EVENTNO',''),
				             char(10)+'                                            and DD1.OCCURREDFLAG=0)',''),
				             char(10)+'           where DDE1.EVENTGROUP  is not null',''),
				             char(10)+'           and   DD1.EVENTDUEDATE is not null',''),
				             char(10)+'           group by DD1.CASEID, DDE1.EVENTGROUP) GRP on (GRP.CASEID=DD.CASEID',''),
				             char(10)+'                                                     and GRP.EVENTGROUP=DDE.EVENTGROUP)',''),
				             char(10)+'left join CASEEVENT DD2 with (NOLOCK) on (DD2.CASEID=GRP.CASEID',''),
				             char(10)+'                                      and DD2.OCCURREDFLAG=0',''),
				             char(10)+'                                      and DD2.EVENTDUEDATE=GRP.EVENTDUEDATE)',''),
				             char(10)+'left join EVENTS DDE2 with (NOLOCK)   on (DDE2.EVENTNO=DD2.EVENTNO',''),
				             char(10)+'                                      and DDE2.EVENTGROUP=GRP.EVENTGROUP)',''),
				             char(10)+'left join EVENTCONTROL DDEC2 with (NOLOCK) on (DDEC2.CRITERIANO=DD2.CREATEDBYCRITERIA',''),
				             char(10)+'				                  and DDEC2.EVENTNO   =DD2.EVENTNO)','')
		From #TempConstructSQL
		Where ComponentType='F'"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		char(1),
					  @sSaveReminderJoin	nvarchar(1000),
					  @sReplacementString	nvarchar(1000),
					  @pbCalledFromCentura	bit',
					  @sUnionFrom=@sUnionFrom,
					  @sSaveReminderJoin=@sSaveReminderJoin,
					  @sReplacementString=@sReplacementString,
					  @pbCalledFromCentura=@pbCalledFromCentura
	End

	If @ErrorCode=0
	Begin
		-- Reset the @sSaveExistsClause if it is NULL to ensure the REPLACE performs correctly
		If @sSaveExistsClause is null
			Set @sSaveExistsClause=''

		If @nEventStaffKeyOperator is not null
			Set @sSQLString="
			Insert into #TempConstructSQL (ComponentType, SavedString)
			Select	@sUnionWhere, 
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(SavedString,'DD.EVENTDUEDATE','DD.DUEDATE'),
				            char(10)+'and coalesce(DDEC.IMPORTANCELEVEL,DDE.IMPORTANCELEVEL,9)'+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura),' and isnull(DD.IMPORTANCELEVEL,9) '+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)),
					    @sSaveExistsClause,''),
					    'and (DD_OA.ACTION=DDE.CONTROLLINGACTION or (DDE.CONTROLLINGACTION is null and DDEC.CRITERIANO=isnull(DD.CREATEDBYCRITERIA,DD_OA.CRITERIANO)) OR DD_OA.CASEID is null)',''),
					    char(10)+'and DD.EVENTNO'+dbo.fn_ConstructOperator(@nEventOperator,'N',@sEventKeys, null,@pbCalledFromCentura),''),
					    'and DD.EMPLOYEENO'+dbo.fn_ConstructOperator(@nEventStaffKeyOperator,'N',@nEventStaffKey, null,@pbCalledFromCentura),''),
					    char(10)+'and DDE.CATEGORYID'+dbo.fn_ConstructOperator(@nEventCategoryKeyOperator,'N',@sEventCategoryKeys, null,@pbCalledFromCentura),''),
					    ' OR DD.DUEDATERESPNAMETYPE is not null',''),
					    ' OR DD.DUEDATERESPNAMETYPE in (''EMP'',''SIG'') OR (DD.EMPLOYEENO is null and DD.DUEDATERESPNAMETYPE is null)',''),
					    ' OR DD.DUEDATERESPNAMETYPE=''EMP'' OR (DD.EMPLOYEENO is null AND DD.DUEDATERESPNAMETYPE is null)',''),
					    ' OR DD.DUEDATERESPNAMETYPE=''SIG'' OR (DD.EMPLOYEENO is null AND DD.DUEDATERESPNAMETYPE is null)',''),
					    ' OR DD.DUEDATERESPNAMETYPE'+dbo.fn_ConstructOperator(@nNameTypeOperator,'CS',@sNameTypeKey,null,@pbCalledFromCentura),''),
						' isnull(DDE.CONTROLLINGACTION,OAX.ACTION)',' OAX.ACTION'),
						' OR DDE.CONTROLLINGACTION=''~2''','')
			From #TempConstructSQL
			Where ComponentType='W'"
		Else
			Set @sSQLString="
			Insert into #TempConstructSQL (ComponentType, SavedString)
			Select	@sUnionWhere, 
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(
			replace(SavedString,'DD.EVENTDUEDATE','DD.DUEDATE'),
				            char(10)+'and coalesce(DDEC.IMPORTANCELEVEL,DDE.IMPORTANCELEVEL,9)'+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura),' and isnull(DD.IMPORTANCELEVEL,9) '+dbo.fn_ConstructOperator(@nImportanceLevelOperator,'CS',@sImportanceLevelFrom, @sImportanceLevelTo,@pbCalledFromCentura)),
					    @sSaveExistsClause,''),
					    'and (DD_OA.ACTION=DDE.CONTROLLINGACTION or (DDE.CONTROLLINGACTION is null and DDEC.CRITERIANO=isnull(DD.CREATEDBYCRITERIA,DD_OA.CRITERIANO)) OR DD_OA.CASEID is null)',''),
					    char(10)+'and DD.EVENTNO'+dbo.fn_ConstructOperator(@nEventOperator,'N',@sEventKeys, null,@pbCalledFromCentura),''),
					    char(10)+'and DDE.CATEGORYID'+dbo.fn_ConstructOperator(@nEventCategoryKeyOperator,'N',@sEventCategoryKeys, null,@pbCalledFromCentura),''),
					    ' OR DD.DUEDATERESPNAMETYPE is not null',''),
					    ' OR DD.DUEDATERESPNAMETYPE in (''EMP'',''SIG'') OR (DD.EMPLOYEENO is null and DD.DUEDATERESPNAMETYPE is null)',''),
					    ' OR DD.DUEDATERESPNAMETYPE=''EMP'' OR (DD.EMPLOYEENO is null AND DD.DUEDATERESPNAMETYPE is null)',''),
					    ' OR DD.DUEDATERESPNAMETYPE=''SIG'' OR (DD.EMPLOYEENO is null AND DD.DUEDATERESPNAMETYPE is null)',''),
					    ' OR DD.DUEDATERESPNAMETYPE'+dbo.fn_ConstructOperator(@nNameTypeOperator,'CS',@sNameTypeKey,null,@pbCalledFromCentura),''),
						' isnull(DDE.CONTROLLINGACTION,OAX.ACTION)',' OAX.ACTION'),
						' OR DDE.CONTROLLINGACTION=''~2''','')
			From #TempConstructSQL
			Where ComponentType='W'"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionWhere			char(1),
					  @nImportanceLevelOperator	tinyint,
					  @sImportanceLevelFrom		nvarchar(50),
					  @sImportanceLevelTo		nvarchar(2),
					  @nEventOperator		tinyint,
					  @sEventKeys			nvarchar(200),
					  @sSaveExistsClause		nvarchar(1000),
					  @sEventCategoryKeys		nvarchar(max),
					  @nEventCategoryKeyOperator	tinyint,
					  @pbCalledFromCentura		bit,
					  @nEventStaffKey		int,
					  @nEventStaffKeyOperator	tinyint,
					  @sNameTypeKey			nvarchar(1000),
					  @nNameTypeOperator		tinyint',
					  @sUnionWhere=@sUnionWhere,
					  @nImportanceLevelOperator=@nImportanceLevelOperator,
					  @sImportanceLevelFrom    =@sImportanceLevelFrom,
					  @sImportanceLevelTo	   =@sImportanceLevelTo,
					  @nEventOperator	   =@nEventOperator,
					  @sEventKeys		   =@sEventKeys,
					  @sSaveExistsClause	   =@sSaveExistsClause,
					  @sEventCategoryKeys	   =@sEventCategoryKeys,
					  @nEventCategoryKeyOperator=@nEventCategoryKeyOperator,
					  @pbCalledFromCentura	   =@pbCalledFromCentura,
					  @nEventStaffKey	   = @nEventStaffKey,
					  @nEventStaffKeyOperator  =@nEventStaffKeyOperator,
					  @sNameTypeKey		   =@sNameTypeKey,
					  @nNameTypeOperator	   =@nNameTypeOperator			  
	End

	-- If the @bUseEventDates parameter is off then make the SQL for the
	-- ALERTS table the main SELECT and remove the UNION.

	If isnull(@bUseEventDates,0)=0
	and @ErrorCode=0
	Begin
		Set @sSQLString="Delete from #TempConstructSQL where ComponentType in ('S', 'F','W')"
		
		Exec @ErrorCode=sp_executesql @sSQLString

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update #TempConstructSQL 
			Set ComponentType=CASE(ComponentType)
						WHEN('U') THEN 'S'
						WHEN('V') THEN 'F'
						WHEN('X') THEN 'W'
							  ELSE ComponentType
					  END,
			    SavedString=replace(SavedString,'Union /*All*/'+char(10)+'Select', 'Select')"
		
			Exec @ErrorCode=sp_executesql @sSQLString
		End
	End
End

RETURN @ErrorCode
go

grant execute on dbo.csw_ConstructCaseSelect  to public
go
