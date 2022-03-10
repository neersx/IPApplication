-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDueDate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_ListDueDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ipw_ListDueDate.'
	drop procedure dbo.ipw_ListDueDate
End
print '**** Creating procedure dbo.ipw_ListDueDate...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE PROCEDURE dbo.ipw_ListDueDate
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 160, 	-- The key for the context of the query (default output requests).	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0,
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null,
	@pbReturnResultSet		bit		= 1,	-- Allows explicit control of whether the result list should be returned.
	@pbGetTotalRowCount		bit		= 1	-- Allows explicit control of execution of Count against constructed SQL.
)	
AS
-- PROCEDURE :	ipw_ListDueDate
-- VERSION :	145
-- DESCRIPTION:	Returns the requested information, for due dates that match the filter criteria provided.  
--		Due Dates may be related to case events, or to ad hoc reminders. 
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 06 Jul 2004  TM	RFC1230	1	Procedure created 
-- 14 Jul 2004	TM	RFC1230	2	Set @pnRowCount as required.
-- 15 Jul 2004	TM	RFC1230	3	Implement Julie's feedback. 
-- 16 Jul 2004	TM	RFC1230	4	Remove unnecessary @tblActingAs table variable. Improve 
--					the logic extracting NameTypeKey filter criteria.
-- 23 Jul 2004	TM	RFC1230	5	Remove CaseId from the  DueDateRowKey column. If IsAdHoc is true and IsGeneral 
--					is true and HasCase is false then use Alert.Reference for Reference column 
--					instead of the 'isnull(C.CaseReference, A.REFERENCE)'.
-- 26 Jul 2004	TM	RFC1323	6	Add EventCategory and EventCategoryIconKey columns. Implement 
--					EventCategoryKey filter criteria.
-- 02 Aug 2004	TM	RFC1230	7	Improve performance of the ipw_ListDueDate by embedding CaseEvents and Alerts
--					Where clauses into the Cases Derived table Where clause. Modify the datasize 
--					of the @sPeriodRangeType from nvarchar(1) to nvarchar(2). 
-- 04 Aug 2004	TM	RFC1323	8	Correct the ipw_ListDueDate code after merging.
-- 10 Aug 2004	TM	RFC1320	9	Provide the necessary filter criteria and columns for To Do search.	
-- 11 Aug 2004	TM	RFC1320	10	Implement both the true and the false test for @bIsReminderOnHold. Move 
--					'NextReminderDate', 'GoverningEventDate', 'GoverningEventDescription', 
--					'GoverningEventDefinition', 'IsEnteredDueDate' columns out of the employee reminder
--					columns group. For the 'AdHocReference' column remove the condition: 
--					'...and @bIsGeneral = 1 and @bHasCase = 0...' as it may cause a SQL error.
-- 11 Aug 2004	TM	RFC1320	11	Use pr_GetOneAfterPrevWorkDay instead of the fn_GetOneAfterPrevWorkDay function
--					to calculate 'SinceLastWorkingDay' date.
-- 18 Aug 2004	AB	8035		Change temp table to use collate database_default syntax.
-- 02 Sep 2004	JEK	RFC1377	12	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 09 Sep 2004	JEK	RFC886	13	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 13 Sep 2004	JEK	RFC886	14	Implement fn_WrapQuotes for @psCulture.
-- 16 Sep 2004	JEK	RFC886	15	Implement translation.
-- 22 Sep 2004	TM	RFC1327	16	Ad Hoc Date search. Implement new filter criteria and columns required.
-- 24 Sep 2004	TM	RFC1852	17	Correct the FamilyGroup and NameTypeKey filter criteria logic. Make sure that the 
--					SearchType are always not null (i.e. 0 or 1 as required).
-- 24 Sep 2004	TM	RFC1845	18	Exclude closed actions even if the IncludeClosed attribute is missing.
-- 29 Sep 2004	MF	RFC1846	19	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 30 Sep 2004	JEK	RFC1695 20	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 20 Oct 2004	TM	RFC1845	21	Correct the ClosedActions filter criteria logic.
-- 08 Nov 2004	TM	RFC1980	22	Save the fn_GetLookupCulture in @psCulture to improve performance.
-- 09 Nov 2004	TM	RFC1985	23	Correct an SQL error that occurs when both the Reference and CaseReference 
--					columns are selected. Correct the logic that assembles the columns for inner
--					select (derived Cases table).
-- 22 Nov 2004	TM	RFC1959	24	Modify DueDateRowKey to return the key of the source event/ad hoc date when 
--					run for Reminders.
-- 22 Nov 2004	TM	RFC1322	25	Add EventProfileKey column.
-- 30 Nov 2004	TM	RFC2075	26	Filtering for outstanding due dates should only be performed for Due Date searching.
-- 22 Dec 2004	TM	RFC1837	27	Increase the number of 'From' and 'Select' hard coded variables to 12 and 8 
--					respectively. 
-- 20 Jan 2005	TM	RFC1319	28	New ReminderChecksum and IsRead columns.
-- 21 Feb 2005	TM	RFC1319	29	Implement new IsReminderRead filter criteria. 
-- 22 Feb 2005	TM	RFC1319	30	Correct columns ReminderChecksum and AdHocChecksum to be ReminderCheckSum and 
--					AdHocCheckSum as specified in the spec.
-- 22 Feb 2005	TM	RFC1319	31	Correct the ReminderCheckSum column logic in the second part of the Union.
-- 15 Mar 2005	TM	RFC2238	32	Implement new EventImportanceLevel and EventImportanceDescription columns. 
-- 01 Apr 2005	TM	RFC2481	33	When setting the @nNullGroupNameKey variable correct the datatype from 
--					smallint to an integer.
-- 07 Apr 2005	TM	RFC2481	34	Cast @nNullGroupNameKey as varchar(10) instead of the varchar(5).
-- 07 Apr 2005	TM	RFC2493	35	Add new DATAFORMATID  int null column to the @tblOutputRequests table variable. 
--					If the @tblOutputRequests.DataFormatId = 9107 (i.e. text type column) and 
--					@sProcedureName = 'csw_ListCase' then cast the @sTableColumn as nvarchar(4000).
-- 15 May 2005	JEK	RFC2508	36	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	37	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 18 Aug 2005	TM	RFC2938	38	Implement importance level for ad hoc dates.
-- 02 Sep 2005	MF	SQA11833 39	Allow NULLS to be consdered in data comparisons by SET ANSI_NULLS OFF
-- 14 Sep 2005	TM	RFC2593	40	Implement the IsPastDue column for both Ad Hoc and Event Dates.
-- 20 Oct 2005	TM	RFC3024	41	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 20 Jan 2006	TM	RFC1850	42	Add new Event Staff columns and filter criteria.
-- 10 Mar 2006	TM	RFC3465	43	Add two new parameters @pnPageStartRow, @pnPageEndRow and implement
--					SQL Server Paging.
-- 19 Jun 2006	SW	RFC3632	44	"Anyone in my group" bug fix
-- 13 Dec 2006	MF	14002	45	Paging should not do a separate count() on the database if the rows returned
--					are less than the maximum allowed for.
-- 18 Dec 2006	JEK	RFC2982	46	Implement new HasInstructions column.
-- 20 Dec 2006	JEK	RFC4863	47	IsPastDue column is incorrectly including a join to EMPLOYEEREMINDER
--					when used for due dates only.
-- 08 Jan 2007	SW	RFC4779	48	If the Site Control : Critical Level is not set then you receive an error when attempting to view the What's Due tab
-- 28 Aug 2007	AT	RFC4920	49	Modified AdHocDateCreated to return as formatted string.
-- 11 Dec 2008	MF	17136	50	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 Feb 2009  LP      RFC6047 51      Implement new NameReference column.
-- 03 Mar 2009	MF	RFC7674	52	Only include sort columns related to Cases if those specific columns have been included in the Select list.
-- 13 May 2009  LP      RFC7822 53      Match on NAMENO columns when checking EMPLOYEEREMINDER table for reminders.
-- 12 Jun 2009	SF	RFC8114	54	Only return Alerts where CASEID is null when HasCase=0
-- 09 Jun 2009	SF	RFC8118 55	Return Next Reminder Date for Ad Hoc Reminders, A.ALERTDATE.
-- 16 Jun 2009	SF	RFC8114	56	Return case columns as NULL when running a query that is not case related but has case related column in Select list.
-- 07 Aug 2009	SF	RFC5803	57	Add DaysUntilDue data item
-- 14 Sep 2009	SF	RFC5803	58	Add RowNameKey which is equivalent to ReminderNameKey but with additional rules for the Reminders application
-- 01 Oct 2009	SF	RFC5803 59	Add IsEligibleForDelete data item
-- 02 Nov 2009	SF	RFC5803	60 	Correction to IsEligibleForDelete data item
-- 02 Nov 2009	LP	RFC6712	61	Add IsEditable data item
-- 06 Nov 2009	LP	RFC6712	62	Correct filtering of reminders for current user only. 
--						Prevent multiple instances of the same reminder from being returned in WorkBenches Due Date Search.
-- 23 Nov 2009	SF	RFC5803	63	Calculate Days Until Due using CE.DUEDATE rather than EM.
-- 01 Dec 2009	KR	RFC8169	64	Added CanUpdate and CanDelete
-- 10 Dec 2009	MF	RFC8724	65	Use a new technique for handling paging.  This is a SQLServer 2005 feature.
-- 05 Jan 2010	SF	RFC8776	66	Ensure ad hoc reminders against a Name are returned.
-- 22 Jan 2010	KR	RFC8350 67	Removed link to ALERT using EMPLOYEENO where necessary so that the forwarded ALERT appears correctly in To Do Webpart and other places.
-- 27 Jan 2010	MF	SQA18398 68	Ad hoc reminders continue to display in to do list when resolved.
-- 01 Feb 2010	SF	RFC100184 69	Row access join incorrectly filtering out valid results
-- 2 Mar 2010	LP	RFC8959	70	Determine IsPastDue column based on CASEEVENT.DUEDATE instead of EMPLOYEEREMINDER.DUEDATE
-- 01 Apr 2010  DV	RFC8355 71	Stop all reminders from being returned.
-- 12 Apr 2010	MF	RFC9104	72	If no explicit Order By columns have been identified then default to the first column.
-- 18 Jun 2010	LP	RFC9450	73	Fix logic for filtering due dates on Renewal and Non-Renewal Actions
-- 17 Sep 2010	MF	RFC9777	74	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 22 Oct 2010	SF	RFC9865	75	Return LONGMESSAGE over SHORTMESSAGE if exists.  Search on LONGMESSAGE
-- 25 Oct 2010	SF	RFC9783	76	Case displayed multiple times on whats due tab
-- 17 Nov 2010	JC	RFC10114 	77	Fix issue when sorting by ReminderMessage: Cast LONGMESSAGE to nvarchar
-- 25 Nov 2010	LP	RFC9998	78	Add CHECKSUM to DueDateRowKey for Ad Hoc Reminder rows.
-- 11 Feb 2011	SF	RFC10224 	79	When subsequent page is requested, all rows are incorrectly returned.
-- 11 Feb 2011	SF	RFC9824	80	Replace use of ReminderChecksum with LOGDATETIMESTAMP, remove IsEligibleForDelete
-- 02 Mar 2011	MF	RFC10227 	81	Duplicate due dates were returned. OpenAction join with multiple cycles was causing this plus a join to 
--					EmployeeReminder where multiple reminders exist. There should not be a join to EmployeeReminder where
--					the procedure has a context of Due Date Calendar (160) or Ad Hoc related (163 & 164).
-- 20 Apr 2011	MF	RFC10333 82	Employee Reminders may be associated with an Alert that belongs to a different Name. We now carry a reference
--					to the originating name in the ALERTNAMENO column on the EMPLOYEEREMINDER table. This will now be used in joins
--					to the ALERT.
-- 19 May 2011  LP      RFC10653 83	Add missing join to EMPLOYEEREMINDER when searching for Ad Hoc Date Reminders without date parameters.
-- 20 Jun 2011	MF	RFC10873 84	If the CONTROLLINGACTION is set for an Event then the event will only be considered as a due date if there is a 
--					matching OPENACTION.
-- 13 Jul 2011	DL	RFC10830 85	Specify collation default in temp table.
-- 14 Jul 2011	MF	RFC10707 86	Improve performance of generated SQL reporting on EmployeeReminders associated with an open CaseEvent.
-- 09 Sep 2011	LP	RFC11277 87	If a Case Filter has been specified, Event Reminders should also be filtered accordingly.
-- 13 Sep 2011	ASH	R11175 88	Maintain ReminderMessage in foreign languages.
-- 21 Dec 2011	LP	RFC11720 89	Only return due dates for Events with a controlling action when filtering either Renewal or Non-Renewal Actions (not both).
-- 10 Jan 2012	SF	RFC11720 90	Evaluate fn_FilterUserNameType once only to improve performance.
-- 11 Jan 2012	LP	RFC11720 91	Due Dates for Events must be returned even if controlling action is null, if associated with an OPENACTION.
-- 20 Jan 2012  DV	R11140   92	Add check for Case Access security.
-- 31 Jan 2012	MF	RFC11863 92	Ensure EMPLOYEEREMINDER has been included as a Join before referencing a column from that table.
-- 01 Feb 2012	LP	R11799	93	IsPastDue column does not require Left Join to EMPLOYEEREMINDER. This was resulting in duplicate reminders.
-- 02 Feb 2012  MS      RFC11842 94     EMPLOYEEREMINDER.EMPLOYEENO will be included for DueDateRowKey if EMPLOYEEREMINDER is included in join    
-- 03 Feb 2012	LP	RFC11863 95	Corrected logic as it was causing an error regarding A.REFERENCE column.
-- 03 Feb 2012  MS      RFC10362 96     Changed RowKey to MainRowKey used for pagination to avoid clash between column name RowKey 
-- 06 Feb 2012	ASH	RFC100680 97	Corrected logic to add 'where' condition of @sWhereDueDate string after the joining with Name table if @bMemberIsCurrentUser is 1
-- 07 Feb 2012  DV	RFC9946  98	Return Adhoc Dates if TRIGGEREVENTNO is not null
-- 08 Feb 2012  MS      RFC11842  99    Corrected error for What's Due List when pagination is enabled
-- 16 Feb 2012  DV      RFC9946  100    Remove the null check for EVENTNO in left join with ALERT for Reminders.
-- 17 Feb 2012  DV      RFC11949 101     Fix issue where finalised Ad Hoc Dates are not getting displayed. 
-- 14 Mar 2012	DV	RFC9946	 102	Add a check to match the EVENTNO in ALERT table with the EMPLOYEEREMINDER table.	
-- 08 May 2012	DV	R100689	 103	Change the order in the coalesce for Description column to check for ALERTMESSAGE at the end                      
-- 26 Apr 2012	MF	R12200	103	Ad hocs are not always being filtered by name when the Acting As name filter is used when called from the Whats Due web part.
--					The problem is caused by the @bIsRecipient being set incorrectly in the filter XML. When called by Whats Due the @bIsRecipient
--					should always be set to 1 to force the restiction to the user.           
-- 01 May 2012	MF	R12232	104	Ad hocs that have no importance level should always be returned when there is an explicit filter on importance level.


-- 30 May 2012	MF	R12361	105	Cast LONGMESSAGE to nvarchar(max) to avoid problem when used in ORDER BY.
-- 17 Jul 2012	LP	R11722	106	Extend to return reminders belonging to multiple staff recipients.
-- 24 Jul 2012	LP	R11722	107	Extend to filter reminders which the user has Read access according to Function Security rules

-- 01 Aug 2012	vql	R12566	108	Invalid alerts reminders being returned.
-- 04 Aug 2012	AK	R11248	109	Forced @bHasReminder=0 When called from Whats Due list.
-- 15 Feb 2013  MS      R11721  110     Allow multiple actions for search 
-- 26 Mar 2013	SF	R13286	111	Row Access Security should be considered where there is one or more row access details against the user identity
--					It should be applied over the top of Case Access Security.
-- 11 Apr 2013	DV	R13270	111	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Jul 2013	vql	R13629	112	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 28 Feb 2014	SF	R31355	113	Use the @bRowLevelSecurity rather than the unnecessary left join which resulted in duplicates being returned 
--					if more than 1 IDENTITYROWACCESSDETAIL is set against the user.
-- 25 Mar 2014	MF	R32794	113	If the due dates are to explicitly match on an Action then EVENTS that have a different Controlling Aciton may 
--					still be reported if the Event is defined within that explicit Action.
-- 04 Jul 2014	MF	R35524	114	Correction to generated query when specific Name used in search. There was a different performance compared to when
--					the query was reporting on Myself even though the specific Name chosen was in fact myself.
-- 18 Sep 2014	MF	R39617	115	Filter on Action was not filtering out Reminders being returned where the associated Event belonged to a different Action.
-- 15 Oct 2014	MF	R40438	116	When checking for a Due Date just ensure OCCURREDFLAG=0 no need to check for NULL and EVENTDATE is null as this is potentially
--					impacting performance.
-- 23 Dec 2014  SW      R37249  117     Get Importance and Importance Level for AdHoc entries
-- 08 Jan 2014	MF	R41514	118	Merge problem resulting from RFC39617. 
-- 02 Mar 2015	MF	R43207	119	Replace text columns for CASEEVENT table with new tables CASEEVENTTEXT and EVENTTEXT.
-- 09 Apr 2015  MS      R46381  120     Fix bug to use A.ImportanceLeel for AdHoc entries only
-- 22 Apr 2015	MS	R46603	121	Set size of variables @sWhereCase and @sWhereFilter to nvarchar(max)
-- 05 Jun 2015	MS	R48289	122	Add EventTextTypeId in DueDateRowKey
-- 06 Jun 2015	MF	R49400	123	Correction to filtering on Actions. The XML label appears to have been changed to support multiple Actions but the change had not merged correctly.
-- 17 Jun 2015	MF	R48508	124	Allow an option for EventText of a specified Type to be returned as a column.
-- 02 Jul 2015	MF	R49300	125	Revisit of RFC46381. When the procedure is called from Whats Due List with the ImportanceLevelDescription selected and Alerts
--					included, the SQL continued to crash because A.IMPORTANCELEVEL is referenced in a part of the query where the ALERTS table
--					was not included.
-- 16 Jul 2015	AT	R49021	126	Separate Case filtering into temp table to improve performance.
-- 28 Jul 2015	AT	R50628	127	Filter Case list before retrieving Case data.
-- 08 Oct 2015  MS      R38939  128     Set EventKey to multiselect
-- 02 Nov 2015	vql	R53910	129	Adjust formatted names logic (DR-15543).
-- 04 Nov 2015	MF	R41514	130	When Reminders calls this procedure with a filter on Action it is using the XML "<ActionKey Operator="0">EN</ActionKey>"
--					whereas the Due Date search is correctly using "<ActionKeys Operator="0">EN</ActionKeys>".  To solve this problem the procedure
--					will now recognise both "ActionKey" and "ActionKeys".
-- 30 Mar 2016	MF	R59842	131	The Governing Event being reported may also be a due date.
-- 27 Apr 2016	MF	R60349	132	Ethical Walls rules applied for logged on user.
-- 16 May 2016	MF	R61473	133	Importance level against Alerts is not always being returned.
-- 14 Jul 2016	MF	62317	134	Performance improvement using a CTE to get the minimum SEQUENCE by Caseid and NameType. 
-- 20 Jul 2016	MF	62642	135	This is a revisit of the work performed in RFC 49021 and 50628. We need a solution that can vary between the implemented temporary
--					table solution and one where the code used CTEs as an alternative to the temporary table approach. We are getting varying levels
--					of performance on different client databases where one approach works well for one database but very poorly on another.
--					The site control "Due Date Event Threshhold" will compare the number of rows in the EVENTS table. If that number exceeds the number in
--					the site control then the temporary table solution will be used otherwisw the CTE approach will operate.
-- 25 Jan 2017	LP	R69856	136	Allow filtering of due dates by cases that match the CaseQuickSearch filter keyword.
--					This calls the new function fn_GetMatchingCases which replicates the same Case Quick Search algorithm.
-- 29 Sep 2017	MF	72456	137	Add Row Level Security
-- 24 Oct 2017	AK	R72645	138	Make compatible with case sensitive server with case insensitive database.
-- 01 May 2018	MF	73641	139	When getting the Governing Date, need to consider the DueDateCalc rule to get the appropriate cycle to use for the GoverningEvent.
-- 21 Jun 2018	MF	74404	140	Revisit of 69856 which introduced a problem when reporting on both Case and non case related ad hoc reminders.
-- 07 Sep 2018	AV	74738	141	Set isolation level to read uncommited.
-- 09 Nov 2018	AV	75198/DR-45358	142	Date conversion errors when creating cases and opening names in Chinese DB.
-- 27 Mar 2019	MF	DR-47740 143	When both Events & Adhocs are being reported, the Importance Level filter is not being applied to the Adhocs (ALERTS).
-- 07 Jun 2019	MF	DR-49518 144	Add new columns to report the latest due date of an event that shares the same Group as the Due Date being reported.
-- 20 Sep 2019  MS      DR-37452 145    Added new columns EventTextNoType and EventTextNoTypeModifiedDate

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
-- 	AdHocCheckSum (RFC1319)
--	AdHocReference (RFC1320)
--	DaysUntilDue
--	DueDateRowKey
-- 	EventCategory (RFC1323)
--	EventCategoryIconKey (RFC1323)
--	Reference
--	Description
--	DueDate
--	DueDateLatestInGroup (DR-49518)
--	DueDescriptionLatestInGroup (DR-49518)
--	EventDescription (RFC1320)
--	HasInstructions (RFC2982)
--	IsCriticalEvent
--	EventDefinition
-- 	EventText
--	EventTextOfType	(RFC48508)
--	EventTextOfTypeModifiedDate (RFC48508)
--	EventTextType
--	EventTextModifiedDate
--	EventImportanceDescription (RFC2238)
--	EventImportanceLevel (RFC2238)
--	ImportanceLevel (RFC2938)
--	ImportanceDescription (RFC2938)
--	IsAdHoc
--	IsRead (RFC1319)
--	IsEditable (RFC6712)
--	CanUpdate (RFC8169)
--	CanDelete (RFC8169)
--      NameReferenceKey (RFC6047)
--      NameReferenceCode (RFC6047)
--	ReminderCheckSum (RFC1319)
--	ReminderNameKey (RFC1320)
--	ReminderDisplayName (RFC1320)
--	ReminderFormalName (RFC1320)
--	ReminderNameCode (RFC1320)
--	ReminderDateCreated (RFC1320)
--	ReminderReplyEmail (RFC1320)
--	IsPastDue (RFC1320)
--	ReminderDate (RFC1320)
--	ReminderMessage (RFC1320)
--	ReminderDateUpdated (RFC1320)
--	ReminderHoldUntilDate (RFC1320)
--	ReminderComment (RFC1320)
--	RowNameKey (RFC5803)
--	NextReminderDate (RFC1320)
--	GoverningEventDate (RFC1320)
--	GoverningEventDescription (RFC1320)
--	GoverningEventDefinition (RFC1320)
--	IsEnteredDueDate (RFC1320)
--      EventTextNoType (DR-37452)
--      EventTextNoTypeModifiedDate (DR-37452)

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	A
--	C
--	CE
--	CE1 (RFC1320)
--	CET
--	CETT(RFC48508)
--	CN (RFC1320)
--	D  (RFC2982)
--	EC
--	E
--	E1 (RFC1320)
--  	ECT (RFC1323)
--	ER (RFC1320)
-- 	ERC (RFC1320)
--	ERN (RFC1320)
--	ET
--	ETT(RFC48508)
--	FCN
--	FN (RFC1320)
--	IMPC (RFC2238)
--	ML (RFAC1320)
--	N
-- 	NCN (RFC1320)
--	NDA (RFC1327)
--	NEMPL (RFC1850)
--      NR (RFC6047)
--	OA
--	OAX
--	OX
--	RC (RFC6712)
--	RS (RFC6712)
--	S


-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode			int
Declare @sAlertXML	 		nvarchar(400)

-- The SQL used by the csw_ListCase stored procedure
Declare @sSql				nvarchar(4000)
Declare @sSQLString			nvarchar(max)
Declare	@sSelectList1			nvarchar(4000)	-- the SQL list of columns to return
Declare	@sSelectList2			nvarchar(4000)
Declare	@sSelectList3			nvarchar(4000)
Declare	@sSelectList4			nvarchar(4000)
Declare	@sSelectList5			nvarchar(4000)	-- the SQL list of columns to return
Declare	@sSelectList6			nvarchar(4000)
Declare	@sSelectList7			nvarchar(4000)
Declare	@sSelectList8			nvarchar(4000)
Declare	@sFrom1				nvarchar(max)	-- the SQL to list tables and joins
Declare	@sFrom2				nvarchar(4000)
Declare	@sFrom3				nvarchar(4000)
Declare	@sFrom4				nvarchar(4000)
Declare	@sFrom5				nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom6				nvarchar(4000)
Declare	@sFrom7				nvarchar(4000)
Declare	@sFrom8				nvarchar(4000)
Declare	@sFrom9				nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom10			nvarchar(4000)
Declare	@sFrom11			nvarchar(4000)
Declare	@sFrom12			nvarchar(4000)
declare @sAddFromString			nvarchar(4000)	-- the FROM string currently being searched for
Declare @sWhereCase			nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect)
Declare @sWhereFilter			nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_FilterCases)
Declare	@sOpenWrapper			nvarchar(1000)
Declare @sCloseWrapper			nvarchar(100)
Declare @sCTE				nvarchar(max)
Declare	@sCTE_CaseNameSequence		nvarchar(max)
Declare @sCTE_Cases			nvarchar(max)
Declare @sCTE_CasesSelect		nvarchar(max)
Declare @sCTE_CaseDetails		nvarchar(max)
Declare @sReminderExists		nvarchar(1000)
Declare @sAlertExists			nvarchar(1000)
declare @sTable1			nvarchar(25)
declare @sTable2			nvarchar(25)

-- The SQL used by the ipw_ListDueDate stored procedure
Declare @nCount				int	 	-- Current table row being processed.
Declare @sSelectDueDate			nvarchar(max)
Declare @sFromDueDate			nvarchar(max)
Declare @sFromReminders			nvarchar(max)
Declare @sWhereDateRange		nvarchar(4000)
Declare @sUnionDateRange		nvarchar(max)
Declare	@sWhereFilterEventText		nvarchar(max)
Declare @sWhereFilterDueDate		nvarchar(max) 	-- the 'Where' clause that holds Events 'Where' clause to be concatenated to the Cases 'Where' clause. 
Declare @sWhereDueDate			nvarchar(max)	-- the 'Where' clause that only includes filter criteria for Event Due Dates.
Declare @sWhereFromDueDate		nvarchar(max)	-- the 'From' clause inside the 'Where' clause that only includes filter criteria that are applicable for Event Due Dates.
Declare @sOrderDueDate			nvarchar(4000)
Declare @sUnionSelectDueDate		nvarchar(max)  -- the SQL list of columns to return for the UNION
Declare	@sUnionFromDueDate		nvarchar(max)	-- the SQL to list tables and joins for the UNION
Declare	@sUnionFromReminders		nvarchar(max)	-- the SQL to list tables and joins for the UNION Reminders
Declare @sUnionWhereFilterDueDate	nvarchar(max) 	-- the 'Where' clause that holds Alerts 'Where' clause to be concatenated to the Cases 'Where' clause. 
Declare @sUnionWhereDueDate		nvarchar(max) 	-- the 'Where' clause that only includes filter criteria for Ad Hoc Due Dates.
Declare @sUnionWhereFromDueDate		nvarchar(max) 	-- the 'From' clause inside the 'Where' clause that only includes filter criteria that are applicable for Ad Hoc Due Dates.
Declare @sUnionJoinPredicate		nvarchar(2000)	-- the join 'on' condition for ad-hoc dates
Declare @sWhereFromReminder		nvarchar(max)	-- the 'From' clause inside the 'Where' clause that only includes filter criteria for Reminders.
Declare @sWhereReminder			nvarchar(max)	-- the 'Where' clause that only includes filter criteria for Reminders.
Declare @sWhereFilterReminder		nvarchar(max) 	-- the 'Where' clause that holds Reminders 'Where' clause to be concatenated to the Cases 'Where' clause. 

Declare @sDateRangeFilter		nvarchar(200)	-- the Date Range Filter for the 'Where' clauses

Declare @sCountSelect			nvarchar(4000)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare	@sTopUnionSelect1		nvarchar(max)	-- the SQL list of columns to return for the UNION modified for paging
Declare	@sTopSelectList1		nvarchar(max)	-- the SQL list of columns to return modified for paging

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests 	table 
			 	(	ROWNUMBER	int 		not null,
		    			ID		nvarchar(100)	collate database_default not null,
		    			SORTORDER	tinyint		null,
		    			SORTDIRECTION	nvarchar(1)	collate database_default null,
					PUBLISHNAME	nvarchar(100)	collate database_default null,
					QUALIFIER	nvarchar(100)	collate database_default null,				
					DOCITEMKEY	int		null,
					PROCEDURENAME	nvarchar(50)	collate database_default null,
					DATAFORMATID  	int 		null
			 	)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy 	table (
					Position	tinyint		not null,
					Direction	nvarchar(5)	collate database_default not null,
					ColumnName	nvarchar(1000)	collate database_default not null,
					PublishName	nvarchar(50)	collate database_default null,
					ColumnNumber	tinyint		not null
				)
-- SQA9664
-- Create a temporary table to be used in the construction of the SELECT.
Create table #TempConstructSQL 	       
				(
					Position	smallint	identity(1,1),
					ComponentType	char(1)		collate database_default ,
					SavedString	nvarchar(4000) 	collate database_default 
				 )
-- RFC11720				 
Create table #TempFilteredUserNameTypes
				(
					NAMETYPE  nvarchar(3)	collate database_default NOT NULL primary key
				)
declare @sCasesTempTable		nvarchar(128)
declare @sCaseIdsTempTable		nvarchar(128)

Declare @sGetCasesOnlySql		nvarchar(max)
Declare @sPopulateTempCaseTableSql	nvarchar(max)

Declare @sCurrentTable 			nvarchar(60)	

Declare @nOutRequestsRowCount		int
Declare @sCaseXMLOutputRequests		nvarchar(4000)	-- The XML Output Requests prepared for the case search procedure.

Declare @nTableCount			tinyint
Declare @nNumberOfBrakets		tinyint
Declare @nColumnNo			tinyint
declare @nFirstColumnNo			tinyint		 --RFC9104
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
declare @sFirstPublishName		nvarchar(50)	 --RFC9104
Declare @sPublishNameForXML		nvarchar(50)	-- Publish name with such characters as '.' and ' ' removed.
Declare @sQualifier			nvarchar(50)
Declare @sProcedureName			nvarchar(50)
Declare @sCorrelationSuffix		nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @nDataFormatID			int
Declare @sTableColumn			nvarchar(4000)
declare @sFirstTableColumn		nvarchar(1000)	 --RFC9104
Declare	@bExternalUser			bit
Declare	@nCriticalLevel			int
Declare @bIsNameOperResetFrom1To0	bit		-- set to 1 when the 'Events' filtering logic resets NameKeyOperator from 1 to 0. 
Declare @bIsMemberOperResetFrom1To0	bit		-- set to 1 when the 'Events' filtering logic resets MemberKeyOperator from 1 to 0.
declare	@bOrderByDefined		bit		--RFC9104
Declare @bFilterDueDateByReminderRecipient bit -- RFC9783

-- Declare Filter Variables	
Declare @sCaseQuickSearch		nvarchar(max)	-- Used for filtering of results by case quick search
Declare @bHasReminder			bit		-- HasReminder indicates that the date must have a reminder associated with it.
Declare @bExcludeOccurred		bit		-- Indicates that only due dates that have occurred should be excluded.
Declare @bIsEvent			bit		-- When true, event related due dates are included.
Declare @bIsAdHoc			bit		-- When true, ad hoc related due dates are included.
Declare @bHasCase			bit		-- When true, due dates that are related to a specific case are included.
Declare @bIsGeneral			bit		-- When true, duedates that are not related to a case are included.
Declare @nNameKey			int		-- The key of the name the due dates belong to.
Declare @sNameKeys			nvarchar(max)	-- A comma-separated list of recipients' name keys
Declare @nNameKeyOperator		tinyint		
Declare @bIsCurrentUser			bit		-- Indicates that the NameKey of the current user should be used as the NameKey value.
Declare @nMemberOfGroupKey		smallint	-- Indicates that the Name.FamilyNo of the current user should be used as the MemberOfGroupKey value.
Declare @nMemberOfGroupKeyOperator 	tinyint		 
Declare @bMemberIsCurrentUser		bit		-- Indicates that the Name.FamilyNo of the current user should be used as the MemberOfGroupKey value.
Declare @nNullGroupNameKey		int		-- If the user does not belong to a group and 'MemberOfGroupKey for a current user' is selected use @nNullGroupNameKey to join to the Name table.
Declare @bIsRecipient			bit		-- Indicates that Ad Hoc due dates sent to the name(s) identified above should be returned.
Declare @sNameTypeKeys			nvarchar(4000)	-- The string that contains a list of passed Name Type Keys separated by a comma.
Declare @bUseDueDate			bit		-- Indicates whether the <Dates> filter criteria applies to the Due Date or the Reminder Date or either.  
--							   If neither is provided, defaults to UseDueDate=1.
Declare @nClientDueDates		int 		-- This holds the number of days prior to the current date for which due dates should be shown to external (client) users. 
Declare @bUseReminderDate		bit		-- Not implemented yet. 
Declare @nDateRangeOperator		tinyint
Declare @dtDateRangeFrom		datetime	-- Return due dates between these dates.  From and/or To value must be provided.
Declare @dtDateRangeTo			datetime		
Declare @nPeriodRangeOperator		tinyint
Declare @nPeriodQuantity		smallint	-- May be positive or negative.  Always supplied in conjunction with Type.
Declare @sPeriodRangeType		nvarchar(2)	-- D - Days, W – Weeks, M – Months, Y - Years.
Declare @nPeriodRangeFrom		smallint	-- May be positive or negative.  Always supplied in conjunction with Type.
Declare @nPeriodRangeTo			smallint	
Declare @bSinceLastWorkingDay		bit		-- Indicates that the From value should be set to the day after the working day before today’s date.
Declare @dtTodaysDate			datetime
Declare @dtClientDateRangeFrom		datetime	-- From Date for external users if site control Client Due Dates: Overdue Dates present and the search is UseDueDate.
Declare @sReminderMessage		nvarchar(254)	-- Return reminders for the specified message.
Declare @nReminderMessageOperator	tinyint
Declare @bIsReminderOnHold		bit		-- Returns reminders that are, or are not, on hold as requested. If absent, then all reminders are returned.
Declare @bIsReminderRead		bit		-- Returns reminders that are, or are not, read as requested.  If absent, then all reminders are returned.
Declare @sAdHocReference		nvarchar(20)	-- Return Ad Hoc dates with the specified Reference.
Declare @nAdHocReferenceOperator	tinyint	
Declare @sAdHocMessage			nvarchar(254)	-- Return Ad Hoc dates with the specified message.
Declare @nAdHocMessageOperator		tinyint
Declare @sAdHocEmailSubject		nvarchar(100)	-- Return Ad Hoc dates with the specified email subject.
Declare @nAdHocEmailSubjectOperator	tinyint		
Declare @sRenewalAction			nvarchar(2)
Declare @nNameReferenceKey		int	        -- Return Ad Hoc dates with the specified Name Reference.
Declare @nNameReferenceKeyOperator	tinyint	

-- The following Filter Criteria do not affect Ad Hoc due dates:
Declare @bIsRenewalsOnly		bit		-- Indicates whether only due dates related to renewal actions and/or non-renewal actions are to be reported on.
Declare @bIsNonRenewalsOnly		bit		-- Note: if both are false, due dates for all actions are returned.
Declare @bIncludeClosed			bit		-- Indicates whether due dates associated with closed actions should be returned.
Declare @sActionKeys			nvarchar(1000)	-- Returns events attached to the specified actions.
Declare @nActionKeysOperator		tinyint
Declare @sActionKey			nvarchar(1000)	-- Returns events attached to the specified actions.
Declare @nActionKeyOperator		tinyint
Declare @nImportanceLevelOperator	tinyint
Declare @sImportanceLevelFrom		nvarchar(2)	-- Return event related due dates with an importance level between these values. 
Declare @sImportanceLevelTo		nvarchar(2)	-- From and/or To value must be provided.			
Declare @sEventKeys			nvarchar(max)	-- Return due dates for the specified event.
Declare @nEventKeyOperator		tinyint
Declare @nEventCategoryKey		smallint	-- Return due dates for events with the specified category.	
Declare @nEventCategoryKeyOperator	tinyint
Declare @bIsEventStaff			bit		-- Indicates that due date events that have  name(s) identified above as a responsible staff member should be returned. Does not affect Ad Hoc due dates. 
Declare	@nEventNoteTypeKeysOperator	tinyint
Declare	@sEventNoteTypeKeys		nvarchar(4000)	-- The Event Text Types required to be reported on.
Declare	@nEventNoteTextOperator		tinyint
Declare	@sEventNoteText			nvarchar(max)	-- The Event Text required to be reported on.

Declare @sReminderChecksumColumns	nvarchar(4000)	-- A comma separated list of all comparable columns of the EmployeeReminder table.
Declare @sAdHocChecksumColumns		nvarchar(4000)	-- A comma separated list of all comparable columns of the Alert table.

declare @bRowLevelSecurity		bit
declare @bHasCaseAccessSecurity		bit
declare @bHasFunctionSecurity		bit
declare	@bBlockCaseAccess		bit
declare @bCaseOffice			bit
Declare @sLookupCulture			nvarchar(10)
declare @sFromRowSecurity		nvarchar(4000)
declare @sFromCaseSecurity		nvarchar(4000)
declare @sFromFunctionSecurity		nvarchar(max)
declare @nCurrentUserNameKey		int
Declare @nCaseAccessSecurityFlag	int
Declare @bHasEventTextColumn		bit
Declare	@bUseTempTables			bit

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

set @bRowLevelSecurity	= 0
set @bHasCaseAccessSecurity	= 0
set @bCaseOffice		= 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode			= 0
Set     @nCount				= 1
Set	@nNumberOfBrakets		= 0
Set	@bOrderByDefined		= 0	--RFC9104
Set     @sCaseXMLOutputRequests 	= '<?xml version="1.0"?>'
				  	+char(10)+'	<OutputRequests>'
					
-- Initialise the 'From' and the 'Where' clauses
Set	@sFromDueDate			= ''
Set	@sUnionFromDueDate		= ''    
Set	@sWhereFilterEventText		= ''

Set	@sWhereFromDueDate		= char(10)+"FROM CASEEVENT CEX"
Set	@sWhereDueDate			= char(10)+"WHERE 1=1"
					 +char(10)+"and CEX.EVENTDUEDATE IS NOT NULL"

Set	@sUnionWhereFromDueDate		= char(10)+"FROM ALERT AX"
Set	@sUnionWhereDueDate		= char(10)+"WHERE 1=1"		
					 +char(10)+"and (AX.DUEDATE is not null or AX.TRIGGEREVENTNO is not null)"

Set	@sWhereFromReminder		= char(10)+"FROM EMPLOYEEREMINDER ERX"
Set	@sWhereReminder			= char(10)+"WHERE 1=1"

Set @bFilterDueDateByReminderRecipient = 0

Set @bHasEventTextColumn = 0

-------------------------------------------------
-- RFC62642
-- Compare the number of rows in the Events table 
-- against a configure site control setting to 
-- determine if temporary tables are to be used
-- as interim steps during the query.
-------------------------------------------------
If exists (select 1
	   from SITECONTROL S
	   where S.CONTROLID='Due Date Event Threshhold'
	   and S.COLINTEGER<(select count(*) from EVENTS))
Begin
	Set @bUseTempTables        = 1
	Set @sCasesTempTable	   = '##LISTDUEDATE' + REPLACE(CAST(NEWID() as nvarchar(50)), '-','')
	Set @sCaseIdsTempTable     = '##LISTDUEDATE' + REPLACE(CAST(NEWID() as nvarchar(50)), '-','')
End	

-- Set the Case Security level to the default value.
If @nErrorCode=0
and @pbCalledFromCentura = 0
Begin
	SELECT @nCaseAccessSecurityFlag = ISNULL(SC.COLINTEGER,15)
	FROM SITECONTROL SC 
	WHERE SC.CONTROLID = 'Default Security'
End

-- Check if user has been assigned row access security profile
If @nErrorCode = 0
and @pbCalledFromCentura = 0
Begin
	Select  @bRowLevelSecurity = 1,
		@bCaseOffice = ISNULL(SC.COLBOOLEAN, 0)
	from IDENTITYROWACCESS U WITH (NOLOCK) 
	join ROWACCESSDETAIL R  WITH (NOLOCK)  on (R.ACCESSNAME = U.ACCESSNAME) 
	left join SITECONTROL SC WITH (NOLOCK) on (SC.CONTROLID = 'Row Security Uses Case Office')
	where R.RECORDTYPE = 'C'
	and U.IDENTITYID = @pnUserIdentityId
	
	Set @nErrorCode = @@ERROR 
End

If @nErrorCode = 0
Begin
	Select @nCurrentUserNameKey = NAMENO
	From USERIDENTITY
	Where IDENTITYID = @pnUserIdentityId
	
	Set @nErrorCode = @@ERROR 
End

If @bRowLevelSecurity = 1
Begin
	If @bCaseOffice = 1
	Begin
		Set @sFromRowSecurity = char(10)+"
			left join fn_CasesRowSecurity("+convert(nvarchar,@pnUserIdentityId)+") RS on (RS.CASEID=C.CaseKey and RS.READALLOWED=1)"
	End
	Else Begin
		Set @sFromRowSecurity = char(10)+"
			left join fn_CasesRowSecurityMultiOffice("+convert(nvarchar,@pnUserIdentityId)+") RS on (RS.CASEID=C.CaseKey and RS.READALLOWED=1)"
	End
End
Else Begin
	---------------------------------------------
	-- If Row Level Security is NOT in use for
	-- the current user, then check if any other 
	-- users are configured.  If they are, then 
	-- users that have no configuration 
	-- will be blocked from ALL cases.
	---------------------------------------------
	If @nErrorCode=0
	Begin
		Select @bBlockCaseAccess = 1
		from IDENTITYROWACCESS U
		join USERIDENTITY UI	on (U.IDENTITYID = UI.IDENTITYID) 
		join ROWACCESSDETAIL R	on (R.ACCESSNAME = U.ACCESSNAME) 
		where R.RECORDTYPE = 'C' 
		and isnull(UI.ISEXTERNALUSER,0) = 0

		Set @nErrorCode=@@ERROR
	End
End
Set @sFromFunctionSecurity = char(10)+"
		Join (Select R.EMPLOYEENO 
			FROM (select distinct EMPLOYEENO from EMPLOYEEREMINDER) R
			JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
			JOIN NAME N          ON (UI.NAMENO = N.NAMENO)			
			LEFT JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=2)						
			WHERE (F.ACCESSPRIVILEGES&1 = 1 or R.EMPLOYEENO = UI.NAMENO)
			AND (F.OWNERNO       = R.EMPLOYEENO or R.EMPLOYEENO = UI.NAMENO OR F.OWNERNO IS NULL)
			AND (F.ACCESSSTAFFNO = UI.NAMENO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSSTAFFNO IS NULL) 
			AND (F.ACCESSGROUP   = N.FAMILYNO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSGROUP IS NULL)			  
			group by R.EMPLOYEENO) FS on (FS.EMPLOYEENO=ERX.EMPLOYEENO)"

Set @sFromCaseSecurity = char(10)+"
		  left join (select UC.CASEID as CASEID,
			(Select ISNULL(US.SECURITYFLAG,"+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+")
			  from USERSTATUS US WITH (NOLOCK)
			  JOIN USERIDENTITY UI ON (UI.LOGINID = US.USERID and US.STATUSCODE = UC.STATUSCODE)
			  WHERE UI.IDENTITYID ="+convert(nvarchar,@pnUserIdentityId)+") as SECURITYFLAG
			from CASES UC) RUC on (RUC.CASEID=C.CaseKey)"


Set @sFromFunctionSecurity = char(10)+"
		Join (Select R.EMPLOYEENO 
			FROM (select distinct EMPLOYEENO from EMPLOYEEREMINDER) R
			JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
			JOIN NAME N          ON (UI.NAMENO = N.NAMENO)			
			LEFT JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=2)						
			WHERE (F.ACCESSPRIVILEGES&1 = 1 or R.EMPLOYEENO = UI.NAMENO)
			AND (F.OWNERNO       = R.EMPLOYEENO or R.EMPLOYEENO = UI.NAMENO OR F.OWNERNO IS NULL)
			AND (F.ACCESSSTAFFNO = UI.NAMENO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSSTAFFNO IS NULL) 
			AND (F.ACCESSGROUP   = N.FAMILYNO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSGROUP IS NULL)			  
			group by R.EMPLOYEENO) FS on (FS.EMPLOYEENO=ERX.EMPLOYEENO)"

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSES  ****/
/****                                       ****/
/***********************************************/

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the Filter elements using element-centric mapping (implement 
	--    Case Insensitive searching) 

	Set @sSQLString = 	
	"Select @sCaseQuickSearch		= CaseQuickSearch, "+CHAR(10)+	
	"	@bHasReminder			= HasReminder,"+CHAR(10)+	
	"	@bExcludeOccurred		= ExcludeOccurred,"+CHAR(10)+
	"	@bIsEvent			= IsEvent,"+CHAR(10)+
	"	@bIsAdHoc			= IsAdHoc,"+CHAR(10)+
	"	@bHasCase			= HasCase,"+CHAR(10)+
	"	@bIsGeneral			= IsGeneral,"+CHAR(10)+
	"	@nNameKey			= NameKey,"+CHAR(10)+				
	"	@sNameKeys			= NameKeys,"+CHAR(10)+				
	"	@nNameKeyOperator		= NameKeyOperator,"+CHAR(10)+
	"	@bIsCurrentUser			= IsCurrentUser,"+CHAR(10)+
	"	@nMemberOfGroupKey		= MemberOfGroupKey,"+CHAR(10)+
	"	@nMemberOfGroupKeyOperator	= MemberOfGroupKeyOperator,"+CHAR(10)+
	"	@bMemberIsCurrentUser		= MemberIsCurrentUser,"+CHAR(10)+
	"	@bIsRecipient			= IsRecipient,"+CHAR(10)+
	"	@bUseDueDate			= UseDueDate,"+CHAR(10)+
	"	@bUseReminderDate		= UseReminderDate,"+CHAR(10)+
	"	@nDateRangeOperator		= DateRangeOperator,"+CHAR(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+CHAR(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+CHAR(10)+
	"	@nPeriodRangeOperator		= PeriodRangeOperator,"+CHAR(10)+
	"	@sPeriodRangeType		= CASE WHEN PeriodRangeType = 'D' THEN 'dd'"+CHAR(10)+
	"					       WHEN PeriodRangeType = 'W' THEN 'wk'"+CHAR(10)+
	"					       WHEN PeriodRangeType = 'M' THEN 'mm'"+CHAR(10)+
	"					       WHEN PeriodRangeType = 'Y' THEN 'yy'"+CHAR(10)+
	"					  END,"+CHAR(10)+
	"	@nPeriodRangeFrom		= PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo			= PeriodRangeTo,"+CHAR(10)+			
	"	@bSinceLastWorkingDay		= SinceLastWorkingDay,"+CHAR(10)+
	"	@sReminderMessage		= ReminderMessage,"+CHAR(10)+
	"	@nReminderMessageOperator	= ReminderMessageOperator,"+CHAR(10)+
	"	@bIsReminderOnHold		= IsReminderOnHold,"+CHAR(10)+		
	"	@bIsReminderRead		= IsReminderRead,"+CHAR(10)+
	"	@sAdHocReference		= AdHocReference,"+CHAR(10)+
	"	@nAdHocReferenceOperator	= AdHocReferenceOperator,"+CHAR(10)+			
	"	@sAdHocMessage			= AdHocMessage,"+CHAR(10)+
	"	@nAdHocMessageOperator		= AdHocMessageOperator,"+CHAR(10)+
	"	@sAdHocEmailSubject		= AdHocEmailSubject,"+CHAR(10)+
	"	@nAdHocEmailSubjectOperator	= AdHocEmailSubjectOperator,"+CHAR(10)+		
	"	@bIsEventStaff			= IsEventStaff,"+CHAR(10)+
	"	@nNameReferenceKey		= NameReferenceKey,"+CHAR(10)+
	"	@nNameReferenceKeyOperator	= NameReferenceKeyOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_ListDueDate/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseQuickSearch		nvarchar(max)	'CaseQuickSearch/text()',"+CHAR(10)+
	"	      HasReminder		bit		'SearchType/@HasReminder',"+CHAR(10)+
	"	      ExcludeOccurred		bit		'SearchType/@ExcludeOccurred',"+CHAR(10)+
	"	      IsEvent			bit		'SearchType/IsEvent',"+CHAR(10)+
	"	      IsAdHoc			bit		'SearchType/IsAdHoc',"+CHAR(10)+
	"	      HasCase			bit		'SearchType/HasCase',"+CHAR(10)+	
	"	      IsGeneral			bit		'SearchType/IsGeneral',"+CHAR(10)+
 	"	      NameKey			int		'BelongsTo/NameKey/text()',"+CHAR(10)+	
 	"	      NameKeys			nvarchar(max)	'BelongsTo/NameKeys/text()',"+CHAR(10)+	
	"	      NameKeyOperator		tinyint		'BelongsTo/NameKey/@Operator/text()',"+CHAR(10)+	
	"	      IsCurrentUser		bit		'BelongsTo/NameKey/@IsCurrentUser',"+CHAR(10)+	
	"IsAnyone			bit		'BelongsTo/NameKey/@IsAnyone',"+CHAR(10)+	
	"	      MemberOfGroupKey		smallint	'BelongsTo/MemberOfGroupKey/text()',"+CHAR(10)+	
	"	      MemberOfGroupKeyOperator	tinyint		'BelongsTo/MemberOfGroupKey/@Operator/text()',"+CHAR(10)+	
	"	      MemberIsCurrentUser	bit		'BelongsTo/MemberOfGroupKey/@IsCurrentUser',"+CHAR(10)+	
	"	      IsRecipient		bit		'BelongsTo/ActingAs/@IsRecipient',"+CHAR(10)+
	"	      UseDueDate		bit		'Dates/@UseDueDate/text()',"+CHAR(10)+	
	"	      UseReminderDate		bit		'Dates/@UseReminderDate/text()',"+CHAR(10)+	
	"	      DateRangeOperator		tinyint		'Dates/DateRange/@Operator/text()',"+CHAR(10)+		
	"	      DateRangeFrom		datetime	'Dates/DateRange/From/text()',"+CHAR(10)+	
	"	      DateRangeTo		datetime	'Dates/DateRange/To/text()',"+CHAR(10)+	
	"	      PeriodRangeOperator	tinyint		'Dates/PeriodRange/@Operator/text()',"+CHAR(10)+		
	"	      PeriodRangeType		nvarchar(2)	'Dates/PeriodRange/Type/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'Dates/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'Dates/PeriodRange/To/text()',"+CHAR(10)+		
	"	      SinceLastWorkingDay	bit		'Dates/@SinceLastWorkingDay/text()',"+CHAR(10)+	
	"	      ReminderMessage		nvarchar(254)	'ReminderMessage/text()',"+CHAR(10)+	
	"	      ReminderMessageOperator	tinyint		'ReminderMessage/@Operator/text()',"+CHAR(10)+	
	"	      IsReminderOnHold		bit		'IsReminderOnHold/text()',"+CHAR(10)+		
	"	      IsReminderRead		bit		'IsReminderRead/text()',"+CHAR(10)+	
	"	      AdHocReference		nvarchar(20)	'AdHocReference/text()',"+CHAR(10)+
	"	      AdHocReferenceOperator	tinyint		'AdHocReference/@Operator/text()',"+CHAR(10)+
	"	      AdHocMessage		nvarchar(254)	'AdHocMessage/text()',"+CHAR(10)+		
	"	      AdHocMessageOperator	tinyint		'AdHocMessage/@Operator/text()',"+CHAR(10)+	
	"	      AdHocEmailSubject		nvarchar(100)	'AdHocEmailSubject/text()',"+CHAR(10)+	
	"	      AdHocEmailSubjectOperator tinyint		'AdHocEmailSubject/@Operator/text()',"+CHAR(10)+			
	"IsEventStaff		bit		'BelongsTo/ActingAs/@IsEventStaff',"+CHAR(10)+
	"NameReferenceKey	int	        'NameReferenceKey/text()',"+CHAR(10)+
	"NameReferenceKeyOperator	tinyint		'NameReferenceKey/@Operator/text()'"+CHAR(10)+
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sCaseQuickSearch		nvarchar(max)		output,
				  @bHasReminder			bit			output,
				  @bExcludeOccurred		bit			output,
				  @bIsEvent 			bit			output,
				  @bIsAdHoc			bit			output,
				  @bHasCase			bit			output,
				  @bIsGeneral			bit			output,	
				  @nNameKey			int			output,				
				  @sNameKeys			nvarchar(max)		output,				
				  @nNameKeyOperator		tinyint			output,
				  @bIsCurrentUser		bit			output,		
				  @nMemberOfGroupKey		smallint		output,		
				  @nMemberOfGroupKeyOperator	tinyint			output,		
				  @bMemberIsCurrentUser		bit			output,		
				  @bIsRecipient			bit			output,
				  @bUseDueDate			bit			output,
				  @bUseReminderDate		bit			output,
				  @nDateRangeOperator		tinyint			output,
				  @dtDateRangeFrom		datetime		output,
				  @dtDateRangeTo		datetime		output,
				  @nPeriodRangeOperator		tinyint			output,
				  @sPeriodRangeType		nvarchar(2)		output,
				  @nPeriodRangeFrom		smallint		output,
				  @nPeriodRangeTo		smallint		output,
				  @bSinceLastWorkingDay		bit			output,
				  @sReminderMessage		nvarchar(254)		output,
				  @nReminderMessageOperator	tinyint			output,
				  @bIsReminderOnHold		bit			output,
				  @bIsReminderRead		bit			output,
				  @sAdHocReference		nvarchar(20)		output,
				  @nAdHocReferenceOperator	tinyint			output,
				  @sAdHocMessage		nvarchar(254)		output,
				  @nAdHocMessageOperator	tinyint			output,
				  @sAdHocEmailSubject		nvarchar(100)		output,
				  @nAdHocEmailSubjectOperator	tinyint			output,
				  @bIsEventStaff		bit			output,
				  @nNameReferenceKey		int     		output,
				  @nNameReferenceKeyOperator	tinyint			output',
				  @idoc				= @idoc,
				  @sCaseQuickSearch		= @sCaseQuickSearch	output,
				  @bHasReminder			= @bHasReminder		output,
				  @bExcludeOccurred		= @bExcludeOccurred	output,
				  @bIsEvent 			= @bIsEvent		output,
				  @bIsAdHoc			= @bIsAdHoc		output,
				  @bHasCase			= @bHasCase		output,
				  @bIsGeneral			= @bIsGeneral		output,
				  @nNameKey			= @nNameKey		output,				
				  @sNameKeys			= @sNameKeys		output,			
				  @nNameKeyOperator		= @nNameKeyOperator	output,
				  @bIsCurrentUser 		= @bIsCurrentUser	output,
				  @nMemberOfGroupKey		= @nMemberOfGroupKey	output,
				  @nMemberOfGroupKeyOperator	= @nMemberOfGroupKeyOperator output,
				  @bMemberIsCurrentUser		= @bMemberIsCurrentUser output,
				  @bIsRecipient			= @bIsRecipient		output,
				  @bUseDueDate			= @bUseDueDate		output,
				  @bUseReminderDate		= @bUseReminderDate 	output,
				  @nDateRangeOperator		= @nDateRangeOperator	output,
				  @dtDateRangeFrom		= @dtDateRangeFrom	output,
				  @dtDateRangeTo		= @dtDateRangeTo 	output,
				  @nPeriodRangeOperator		= @nPeriodRangeOperator output,
				  @sPeriodRangeType		= @sPeriodRangeType 	output,
				  @nPeriodRangeFrom		= @nPeriodRangeFrom 	output,
				  @nPeriodRangeTo		= @nPeriodRangeTo	output,
				  @bSinceLastWorkingDay		= @bSinceLastWorkingDay output,
				  @sReminderMessage		= @sReminderMessage	output,
				  @nReminderMessageOperator	= @nReminderMessageOperator output,
				  @bIsReminderOnHold		= @bIsReminderOnHold	output,
				  @bIsReminderRead		= @bIsReminderRead	output,
				  @sAdHocReference		= @sAdHocReference	output,
				  @nAdHocReferenceOperator	= @nAdHocReferenceOperator output,
				  @sAdHocMessage		= @sAdHocMessage	output,
				  @nAdHocMessageOperator	= @nAdHocMessageOperator output,
				  @sAdHocEmailSubject		= @sAdHocEmailSubject output,
				  @nAdHocEmailSubjectOperator	= @nAdHocEmailSubjectOperator output,
				  @bIsEventStaff		= @bIsEventStaff	output,
				  @nNameReferenceKey		= @nNameReferenceKey	output,
				  @nNameReferenceKeyOperator	= @nNameReferenceKeyOperator output

	-- Extract Events specific filter criteria.
	If  @nErrorCode = 0
	Begin		
		Set @sSQLString = 	
		"Select @bIsRenewalsOnly		= IsRenewalsOnly,"+CHAR(10)+
		"	@bIsNonRenewalsOnly		= IsNonRenewalsOnly,"+CHAR(10)+
		"	@bIncludeClosed			= IncludeClosed,"+CHAR(10)+
		"	@nActionKeysOperator		= ActionKeysOperator,"+CHAR(10)+
		"	@sActionKeys			= ActionKeys,"+CHAR(10)+					
		"	@nActionKeyOperator		= ActionKeyOperator,"+CHAR(10)+
		"	@sActionKey			= ActionKey,"+CHAR(10)+			
		"	@nImportanceLevelOperator	= ImportanceLevelOperator,"+CHAR(10)+
		"	@sImportanceLevelFrom		= ImportanceLevelFrom,"+CHAR(10)+
		"	@sImportanceLevelTo		= ImportanceLevelTo,"+CHAR(10)+
		"	@sEventKeys			= EventKeys,"+CHAR(10)+
		"	@nEventKeyOperator		= EventKeyOperator,"+CHAR(10)+				
		"	@nEventCategoryKey		= EventCategoryKey,"+CHAR(10)+	
		"	@nEventCategoryKeyOperator	= EventCategoryKeyOperator,"+CHAR(10)+	
		"	@sEventNoteTypeKeys		= EventNoteTypeKeys,"+CHAR(10)+
		"	@nEventNoteTypeKeysOperator	= EventNoteTypeKeysOperator,"+CHAR(10)+
		"	@sEventNoteText			= EventNoteText,"+CHAR(10)+
		"	@nEventNoteTextOperator		= EventNoteTextOperator"+CHAR(10)+
		"from	OPENXML (@idoc, '/ipw_ListDueDate/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	      IsRenewalsOnly		bit		'Actions/@IsRenewalsOnly',"+CHAR(10)+
		"	      IsNonRenewalsOnly		bit		'Actions/@IsNonRenewalsOnly',"+CHAR(10)+
		"	      IncludeClosed		bit		'Actions/@IncludeClosed',"+CHAR(10)+	
	 	"	      ActionKeysOperator	tinyint		'Actions/ActionKeys/@Operator/text()',"+CHAR(10)+
	 	"	      ActionKeys		nvarchar(1000)	'Actions/ActionKeys/text()',"+CHAR(10)+
	 	"	      ActionKeyOperator		tinyint		'Actions/ActionKey/@Operator/text()',"+CHAR(10)+
	 	"	      ActionKey			nvarchar(1000)	'Actions/ActionKey/text()',"+CHAR(10)+
		"	      ImportanceLevelOperator	tinyint		'ImportanceLevel/@Operator/text()',"+CHAR(10)+
		"	      ImportanceLevelFrom	nvarchar(2)	'ImportanceLevel/From/text()',"+CHAR(10)+	
		"	      ImportanceLevelTo		nvarchar(2)	'ImportanceLevel/To/text()',"+CHAR(10)+	
		"	      EventKeys			nvarchar(max)	'EventKey/text()',"+CHAR(10)+	
		"	      EventKeyOperator		tinyint		'EventKey/@Operator/text()',"+CHAR(10)+		
		"	      EventCategoryKey		smallint	'EventCategoryKey/text()',"+CHAR(10)+	
		"	      EventCategoryKeyOperator	tinyint		'EventCategoryKey/@Operator/text()',"+CHAR(10)+	
		"	      EventNoteTypeKeys		nvarchar(4000)	'EventNoteTypeKeys/text()',"+CHAR(10)+
		"	      EventNoteTypeKeysOperator	tinyint		'EventNoteTypeKeys/@Operator/text()',"+CHAR(10)+  	
		"	      EventNoteText		nvarchar(max)	'EventNoteText/text()',"+CHAR(10)+
		"	      EventNoteTextOperator	tinyint		'EventNoteText/@Operator/text()'"+CHAR(10)+  
	     	"     		)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @bIsRenewalsOnly 		bit			output,
					  @bIsNonRenewalsOnly		bit			output,
					  @bIncludeClosed		bit			output,
					  @nActionKeysOperator		tinyint			output,
					  @sActionKeys            	nvarchar(1000)		output,				
					  @nActionKeyOperator		tinyint			output,
					  @sActionKey            	nvarchar(1000)		output,				
					  @nImportanceLevelOperator	tinyint			output,					  
				          @sImportanceLevelFrom		nvarchar(2)		output,
					  @sImportanceLevelTo		nvarchar(2)		output,		
					  @sEventKeys			nvarchar(max)		output,
					  @nEventKeyOperator		tinyint			output,
					  @nEventCategoryKey		smallint		output,
					  @nEventCategoryKeyOperator	tinyint			output,
					  @sEventNoteTypeKeys		nvarchar(4000)		output,
					  @nEventNoteTypeKeysOperator	tinyint			output,
					  @sEventNoteText		nvarchar(max)		output,
					  @nEventNoteTextOperator	tinyint			output',
					  @idoc				= @idoc,
					  @bIsRenewalsOnly 		= @bIsRenewalsOnly	output,
					  @bIsNonRenewalsOnly		= @bIsNonRenewalsOnly	output,
					  @bIncludeClosed		= @bIncludeClosed	output,
					  @nActionKeysOperator		= @nActionKeysOperator	output,	
					  @sActionKeys             	= @sActionKeys 		output,			
					  @nActionKeyOperator		= @nActionKeyOperator	output,	
					  @sActionKey			= @sActionKey		output,			
					  @nImportanceLevelOperator	= @nImportanceLevelOperator output,
					  @sImportanceLevelFrom		= @sImportanceLevelFrom output,
					  @sImportanceLevelTo 		= @sImportanceLevelTo	output,
					  @sEventKeys			= @sEventKeys		output,
					  @nEventKeyOperator		= @nEventKeyOperator 	output,
					  @nEventCategoryKey		= @nEventCategoryKey	output,
					  @nEventCategoryKeyOperator	= @nEventCategoryKeyOperator output,
					  @sEventNoteTypeKeys		= @sEventNoteTypeKeys	output,
					  @nEventNoteTypeKeysOperator	= @nEventNoteTypeKeysOperator output,
					  @sEventNoteText		= @sEventNoteText	output,
					  @nEventNoteTextOperator	= @nEventNoteTextOperator output	
	End 

	If @sActionKeys is null
	and @sActionKey is not null
		Set @sActionKeys=@sActionKey
		
	If @nActionKeysOperator is null
	and @nActionKeyOperator is not null
		Set @nActionKeysOperator=@nActionKeyOperator

	If @nErrorCode = 0
	Begin
		Select @sNameTypeKeys = @sNameTypeKeys + nullif(',', ',' + @sNameTypeKeys) + dbo.fn_WrapQuotes(NameTypeKey,0,0) 
		from	OPENXML (@idoc, '/ipw_ListDueDate/FilterCriteria/BelongsTo/ActingAs/NameTypeKey', 2)
		WITH (
		      NameTypeKey	nvarchar(3)	'text()'
		     )
		where NameTypeKey is not null
	 				
		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc			
		
		Set @nErrorCode=@@Error
	End

	If @nErrorCode = 0
	Begin
		-- If the following parameters were not supplied 
		-- then set them to 0:
		Set @bIsEvent 		= isnull(@bIsEvent,0)
		Set @bIsAdHoc 		= isnull(@bIsAdHoc,0)
		Set @bHasCase 		= isnull(@bHasCase,0)
		Set @bIsGeneral 	= isnull(@bIsGeneral,0)
		Set @bHasReminder 	= isnull(@bHasReminder,0)
		Set @bIncludeClosed	= isnull(@bIncludeClosed,0)
		Set @bExcludeOccurred	= isnull(@bExcludeOccurred,0)
		Set @bIsEventStaff	= isnull(@bIsEventStaff,0)
		
		-- If none of the following parameters were supplied 
		-- then set them all to 1:
		If  (@bIsEvent=0
			and @bIsAdHoc=0
			and @bHasCase=0
			and @bIsGeneral=0)
		Begin
			Set @bIsEvent 	= 1
			Set @bIsAdHoc 	= 1
			Set @bHasCase 	= 1
			Set @bIsGeneral = 1			
		End 
		
		-------------------------------------------
		-- If the procedure has been called by the 
		-- Whats Due web part (QueryContextKey=160) 
		-- then force the IsRecipient flag to 1
		-- and @bHasReminder to 0
		-------------------------------------------
			
		If @pnQueryContextKey=160
		Begin
			set @bHasReminder=0
			If isnull(@bIsRecipient,0)<>1
			Begin
				Set @bIsRecipient=1
			End
		End	
		
	End
	
	-- Due dates that have occurred should be excluded
	If @bExcludeOccurred = 1
	Begin
		Set	@sWhereDueDate			= @sWhereDueDate
							 +char(10)+"and    CEX.OCCURREDFLAG = 0"
		
		Set	@sUnionWhereDueDate		= @sUnionWhereDueDate
							 +char(10)+"and  (AX.OCCURREDFLAG = 0 or AX.OCCURREDFLAG is null)"
				     			 +char(10)+"and	  AX.DATEOCCURRED is null"							
	End
	Else if @bHasReminder = 1
	Begin
	        Set	@sUnionWhereDueDate             = @sUnionWhereDueDate		
					                 +char(10)+"and isnull(AX.OCCURREDFLAG,0)=0"	
	End
	
	-- Reduce the number of joins in the main statement.
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  @nNameKey = CASE WHEN @bIsCurrentUser = 1
					 THEN U.NAMENO ELSE @nNameKey END, 
			@nCriticalLevel = SC.COLINTEGER, 
			@bExternalUser = U.ISEXTERNALUSER,
			@nMemberOfGroupKey = CASE WHEN @bMemberIsCurrentUser = 1 
						  THEN N.FAMILYNO ELSE @nMemberOfGroupKey END, 
			@nNullGroupNameKey = CASE WHEN @bMemberIsCurrentUser = 1 and N.FAMILYNO is null
						  THEN U.NAMENO END,
			@nClientDueDates = SC1.COLINTEGER 
		from USERIDENTITY U
		join NAME N on (N.NAMENO = U.NAMENO)
		left join SITECONTROL SC  on (SC.CONTROLID  = 'CRITICAL LEVEL')
		left join SITECONTROL SC1 on (SC1.CONTROLID = 'Client Due Dates: Overdue Days')
		where IDENTITYID = @pnUserIdentityId"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						      N'@nNameKey			int			OUTPUT,
							@nCriticalLevel			int			OUTPUT,
							@bExternalUser			bit			OUTPUT,
							@nMemberOfGroupKey	 	smallint		OUTPUT,
							@nClientDueDates		int			OUTPUT,
							@nNullGroupNameKey		int			OUTPUT,
							@pnUserIdentityId		int,
							@bIsCurrentUser			bit,
							@bMemberIsCurrentUser		bit',
							@nNameKey 			= @nNameKey 		OUTPUT,
							@nCriticalLevel			= @nCriticalLevel 	OUTPUT,
							@bExternalUser			= @bExternalUser  	OUTPUT,
							@nMemberOfGroupKey		= @nMemberOfGroupKey OUTPUT,
							@nClientDueDates		= @nClientDueDates 	OUTPUT,
						 	@nNullGroupNameKey		= @nNullGroupNameKey OUTPUT,
							@pnUserIdentityId		= @pnUserIdentityId,
							@bIsCurrentUser			= @bIsCurrentUser,
							@bMemberIsCurrentUser		= @bMemberIsCurrentUser								
						
	End	

	-- RFC11720
	If @nErrorCode = 0
	Begin 
		-- avoid re-evaluating this multiple times
		Insert into #TempFilteredUserNameTypes (NAMETYPE)
		select NAMETYPE 
		from dbo.fn_FilterUserNameTypes(@pnUserIdentityId, null, @bExternalUser, @pbCalledFromCentura)
	End

	-- A period range is converted to a date range by adding the from/to period to the 
	-- current date.  Returns the due dates within the resulting date range.	
	If   @sPeriodRangeType is not null
	and (@nPeriodRangeFrom is not null or
	     @nPeriodRangeTo is not null)			 
	Begin
		If @nPeriodRangeFrom is not null
		Begin
			Set @sSQLString = "Set @dtDateRangeFrom = dateadd("+@sPeriodRangeType+", @nPeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtDateRangeFrom	datetime 		output,
	 				  @sPeriodRangeType	nvarchar(2),
					  @nPeriodRangeFrom	smallint',
	  				  @dtDateRangeFrom	= @dtDateRangeFrom 	output,
					  @sPeriodRangeType	= @sPeriodRangeType,
					  @nPeriodRangeFrom	= @nPeriodRangeFrom				  
		End
	
		If @nPeriodRangeTo is not null
		Begin
			Set @sSQLString = "Set @dtDateRangeTo = dateadd("+@sPeriodRangeType+", @nPeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtDateRangeTo	datetime 		output,
	 				  @sPeriodRangeType	nvarchar(2),
					  @nPeriodRangeTo	smallint',
	  				  @dtDateRangeTo	= @dtDateRangeTo 	output,
					  @sPeriodRangeType	= @sPeriodRangeType,
					  @nPeriodRangeTo	= @nPeriodRangeTo				
		End	
	End		

	-- If SinceLastWorkingDay is true then the From Date value should be set to 
	-- the day after the working day before today’s date.
	If @bSinceLastWorkingDay = 1
	Begin
		Set @dtTodaysDate = getdate()

		Exec @nErrorCode = ipr_GetOneAfterPrevWorkDay
					@pdtStartDate		= @dtTodaysDate,
					@pbCalledFromCentura	= 0,
					@pdtResultDate		= @dtDateRangeFrom output
		
		Set @nDateRangeOperator = 7 
	End
	
	-- For external users, the range of dates selected may be overridden by the Client Due Dates: 
	-- Overdue Dates site control.If a site control value has been provided, the lower range will 
	-- be replaced with (today’s date – site control value days), if it is less than any value 
	-- supplied.

	If @bExternalUser = 1
	and @nClientDueDates is not null
	and @bUseDueDate = 1
	Begin
		Set @dtClientDateRangeFrom = CASE WHEN @dtDateRangeFrom > DATEADD(dd, -@nClientDueDates, GETDATE())
					    	  THEN @dtDateRangeFrom 
					    	  ELSE DATEADD(dd, -@nClientDueDates, GETDATE()) 
				       	     END
	End 
	
	Set @sDateRangeFilter = dbo.fn_ConstructOperator(ISNULL(@nDateRangeOperator, @nPeriodRangeOperator),@Date,convert(nvarchar,ISNULL(@dtClientDateRangeFrom, @dtDateRangeFrom),112), convert(nvarchar,@dtDateRangeTo,112),0)

	-- Default the UseDueDate to true if neither of UseDueDate
	-- or UseReminderDate were supplied.  
	If @bUseDueDate is null
	and @bUseReminderDate is null
	Begin
		Set @bUseDueDate = 1
		Set @bUseReminderDate = 0
	End 
	-- Set @bUseDueDate and @bUseReminderDate
	-- to 0 if they were not supplied.  
	Else If @bUseDueDate is null
	Begin
		Set @bUseDueDate = 0
	End
	Else If @bUseReminderDate is null
	Begin
		Set @bUseReminderDate = 0
	End 


	-- Construction of the Event Due Dates 'Where' clause
	If @bIsEvent = 1	
	and @bHasCase = 1
	Begin			
		-- If the user does not belong to a group and 'Belonging to Anyone in my group
		-- Acting as Recipient' we should return an empty  result set:
		If   @bMemberIsCurrentUser = 1
		and  @nMemberOfGroupKey is null
		and  @nMemberOfGroupKeyOperator is not null
		Begin
			Set @sWhereFromDueDate = @sWhereFromDueDate +char(10)+" join NAME N	on (N.NAMENO = "+CAST(@nNullGroupNameKey  as varchar(11))
								    +char(10)+"			and N.FAMILYNO is not null)"								 
		End

		If  ((@sNameTypeKeys is not null or @bIsEventStaff = 1)
		and((@nNameKey is not null 
		or @sNameKeys is not null
		or   @nNameKeyOperator between 2 and 6)		
		or  (@nMemberOfGroupKey is not null
		or   @nMemberOfGroupKeyOperator between 2 and 6)))		
		Begin	

			Set @sWhereDueDate=@sWhereDueDate+char(10)+"and ("

			If @sNameTypeKeys is not null
			Begin	
				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nNameKeyOperator in (1,6)			
				or @nMemberOfGroupKeyOperator in (1,6)
				Begin
					If @nNameKeyOperator = 1	
					Begin
						-- Set operator to 0 as we use 'not exists':
						Set @nNameKeyOperator = 0
	
						-- Set the 'Reset' flags to 1 so the Ad Hoc filtering logic will be aware of 
						-- modified operators:
						Set @bIsNameOperResetFrom1To0 = 1
					End
	
					If @nMemberOfGroupKeyOperator = 1
					Begin
						-- Set operator to 0 as we use 'not exists':
						Set @nMemberOfGroupKeyOperator = 0				
						
						-- Set the 'Reset' flags to 1 so the Ad Hoc filtering logic will be aware of 
						-- modified operators:					
						Set @bIsMemberOperResetFrom1To0 = 1
					End				

					Set @sWhereDueDate=@sWhereDueDate+char(10)+" not exists"
				End
				Else 
				Begin
					Set @sWhereDueDate=@sWhereDueDate+char(10)+" exists"
				End			
	
				Set @sWhereDueDate = @sWhereDueDate+char(10)+"(Select * from CASENAME CN"  
									+char(10)+" join #TempFilteredUserNameTypes FCN"+cast(@nCount as varchar(10))
									+" on (FCN"+cast(@nCount as nvarchar(20))+".NAMETYPE = CN.NAMETYPE)"
							
				-- This is indicator to be used when considering due dates with 
				-- a reminder that is sent to muiltiple recipients (e.g. SIG, EMP)
				-- and the Acting As clause indicates that it should be for a particular name type only
				Set @bFilterDueDateByReminderRecipient = 1							
				
				If  @nMemberOfGroupKey is not null 
				or  @nMemberOfGroupKeyOperator between 2 and 6 
				Begin				
					If @nMemberOfGroupKeyOperator not in (5,6)
					and @bMemberIsCurrentUser = 1
					Begin
						Set @sWhereDueDate = @sWhereDueDate+char(10)+" join NAME N	on (N.NAMENO = CN.NAMENO"
									   	   +char(10)+" 			and N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)+")"			
					End
	 				Else
					Begin
						Set @sWhereDueDate = @sWhereDueDate+char(10)+" join NAME N	on (N.NAMENO = CN.NAMENO"
									   	   +char(10)+" 			and N.FAMILYNO is not null)"		
					End						
				End		
				
				Set @sWhereDueDate = @sWhereDueDate+char(10)+" where  CN.NAMETYPE in ("+@sNameTypeKeys+")"
									+char(10)+" and CN.CASEID = CEX.CASEID"				     		  
				If @nNameKeyOperator not in (5,6)
				Begin
					If @nNameKey is not null
				Begin
					Set @sWhereDueDate = @sWhereDueDate+char(10)+" and CN.NAMENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
				End							
					If @sNameKeys is not null
					Begin
						Set @sWhereDueDate = @sWhereDueDate+char(10)+" and CN.NAMENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
					End
				End
	
				Set @sWhereDueDate = @sWhereDueDate+char(10)+" and (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate()))"
			End

			If @bIsEventStaff = 1
			Begin	
				-- If the @nNameKeyOperator has been changed from 1 to 0 by the Events
				-- filtering logic we need to change it back to 1:					
				If @bIsNameOperResetFrom1To0 = 1
				Begin
					Set @nNameKeyOperator = 1
				End
	
				-- If the @nMemberOfGroupKeyOperator has been changed from 1 to 0 by the Events
				-- filtering logic we need to change it back to 1:					
				If @bIsMemberOperResetFrom1To0 = 1
				Begin
					Set @nMemberOfGroupKeyOperator = 1
				End

				If (@nMemberOfGroupKey is not null
				or @nMemberOfGroupKeyOperator between 2 and 6)
				-- If the group of the current user is selected as filter criteria
				-- but the current user does not belong to any group the code
				-- above should suppress the result set
				and @nNullGroupNameKey is null
				Begin
					Set @sWhereFromDueDate = @sWhereFromDueDate+char(10)+"left join NAME NEMP		on (NEMP.NAMENO = CEX.EMPLOYEENO)" 
				   	
					-- If Operator is set to IS NULL then use NOT EXISTS
					If @nMemberOfGroupKeyOperator in (1,6)
					Begin
						If @sNameTypeKeys is not null
						Begin
							Set @sWhereDueDate=@sWhereDueDate+char(10)+"and NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)		 						
						End
						Else Begin
							Set @sWhereDueDate=@sWhereDueDate+char(10)+" NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
						End
					End
					Else If @nMemberOfGroupKeyOperator not in (1,6)
					Begin
						If @sNameTypeKeys is not null
						Begin
							Set @sWhereDueDate=@sWhereDueDate+char(10)+"or NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
						End
						Else Begin
							Set @sWhereDueDate=@sWhereDueDate+char(10)+" NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
						End
					End							
				End
				Else If @nNameKey is not null
				or @nNameKeyOperator between 2 and 6
				Begin
					If @nNameKeyOperator = 1
					Begin
						If @sNameTypeKeys is not null
						Begin
							Set @sWhereDueDate=@sWhereDueDate+char(10)+" and "					
						End
					End
					Else If @sNameTypeKeys is not null
					Begin
						Set @sWhereDueDate=@sWhereDueDate+char(10)+" or "
					End				

					Set @sWhereDueDate = @sWhereDueDate+char(10)+" CEX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
					
				End	
				Else If @sNameKeys is not null
				Begin
					If @sNameTypeKeys is not null
					Begin
						Set @sWhereDueDate=@sWhereDueDate+char(10)+" or "
					End
					Set @sWhereDueDate = @sWhereDueDate+char(10)+" CEX.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
				End
			End	

			If @bIsRecipient = 1
			and @bHasReminder = 1
			Begin
				-- If the @nNameKeyOperator has been changed from 1 to 0 by the Events
				-- filtering logic we need to change it back to 1:					
				If @bIsNameOperResetFrom1To0 = 1
				Begin
					Set @nNameKeyOperator = 1
				End
	
				-- If the @nMemberOfGroupKeyOperator has been changed from 1 to 0 by the Events
				-- filtering logic we need to change it back to 1:					
				If @bIsMemberOperResetFrom1To0 = 1
				Begin
					Set @nMemberOfGroupKeyOperator = 1
				End

				Set @sWhereFromDueDate = @sWhereFromDueDate
				+char(10)+"left join EMPLOYEEREMINDER ERX		on (ERX.CASEID = CEX.CASEID"
				+char(10)+"						and ERX.EVENTNO = CEX.EVENTNO"
				+char(10)+"						and ERX.CYCLENO = CEX.CYCLE)"

				-- Ad Hoc date is for the specified name.
				If  @nNameKey is not null
				or  @nNameKeyOperator between 2 and 6
				Begin					
					If @sNameTypeKeys is not null
					or @bIsEventStaff = 1
					Begin
						If @nNameKeyOperator in (1, 6)
						Begin
							Set @sWhereDueDate = @sWhereDueDate+char(10)+"and ERX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)													
						End
						Else Begin
							Set @sWhereDueDate = @sWhereDueDate+char(10)+"or ERX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)													
						End
					End
					Else Begin
						Set @sWhereDueDate = @sWhereDueDate+char(10)+" ERX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)													
					End				
				End		

				If  @sNameKeys is not null
				Begin
					Set @sWhereDueDate = @sWhereDueDate+char(10)+" or ERX.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
				End
				

				-- Ad Hoc date is for any of the names in the Name Group.
				If  @nMemberOfGroupKey is not null 
				or  @nMemberOfGroupKeyOperator between 2 and 6
				Begin				
					Set @sWhereFromDueDate = @sWhereFromDueDate 
								+char(10)+"left join NAME NX	on (NX.NAMENO = ERX.EMPLOYEENO)"																												
	
					If @sNameTypeKeys is not null
					or @bIsEventStaff = 1
					Begin
						If @nNameKeyOperator in (1, 6)
						Begin
							Set @sWhereDueDate = @sWhereDueDate+char(10)+" and NX.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
						End
						Else Begin
							Set @sWhereDueDate = @sWhereDueDate+char(10)+" or NX.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
						End
					End
					Else Begin
						Set @sWhereDueDate = @sWhereDueDate+char(10)+" ERX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)													
					End							
				End			
			End	

			Set @sWhereDueDate=@sWhereDueDate+")"
		End

		If @bHasReminder=1
		Begin
			If  @bIsEvent=1
			and @bIsAdHoc=0	
			Begin
				Set @sWhereDateRange="and ER.SOURCE=0 and CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0"
			End
			Else If  @bIsEvent=0
			     and @bIsAdHoc=1	
			Begin
				Set @sWhereDateRange="and ER.SOURCE=1 and A.DUEDATE is not null and isnull(A.OCCURREDFLAG,0)=0)"
			End
			Else If  @bIsEvent=1
			     and @bIsAdHoc=1	
			Begin
				Set @sWhereDateRange="and ( (A.DUEDATE is not null and isnull(A.OCCURREDFLAG,0)=0)
							OR (CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0) )"
			End
		End

		If @dtDateRangeFrom is not null
		or @dtDateRangeTo is not null
		or @dtClientDateRangeFrom is not null
		Begin 
			If @bIsAdHoc = 0			
			Begin
				If  @bUseDueDate = 1
				and @bUseReminderDate = 0
				Begin
					Set @sWhereDueDate = @sWhereDueDate+char(10)+" and CEX.EVENTDUEDATE "+@sDateRangeFilter									
						Set @sWhereDateRange = @sWhereDateRange+char(10)+" and CE.EVENTDUEDATE " +@sDateRangeFilter
				End
				Else If @bUseDueDate = 0
				and @bUseReminderDate = 1
				Begin
					If charindex('join EMPLOYEEREMINDER ERX',@sWhereFromDueDate)=0	
					Begin
						Set @sWhereFromDueDate = @sWhereFromDueDate 
								+char(10)+"join EMPLOYEEREMINDER ERX	on (ERX.CASEID=CEX.CASEID"
								+char(10)+"				and CEX.EVENTNO=ERX.EVENTNO"
								+char(10)+"				and CEX.CYCLE=ERX.CYCLENO)"
					End		

					Set @sWhereDueDate = @sWhereDueDate+char(10)+" and ERX.REMINDERDATE "+@sDateRangeFilter																	
						Set @sWhereDateRange = @sWhereDateRange+char(10)+" and ER.REMINDERDATE " +@sDateRangeFilter
				End
				Else If @bUseDueDate = 1
				and @bUseReminderDate = 1
				Begin
					If charindex('join EMPLOYEEREMINDER ERX',@sWhereFromDueDate)=0	
					Begin
						Set @sWhereFromDueDate = @sWhereFromDueDate 
								+char(10)+"join EMPLOYEEREMINDER ERX	on (ERX.CASEID=CEX.CASEID"
								+char(10)+"				and CEX.EVENTNO=ERX.EVENTNO"
								+char(10)+"				and CEX.CYCLE=ERX.CYCLENO)"
					End	

					Set @sWhereDueDate = @sWhereDueDate+char(10)+" and ((CEX.EVENTDUEDATE "+@sDateRangeFilter+")"								
			        						       +char(10)+"  or  (ERX.DUEDATE "     +@sDateRangeFilter+")"
			        						       +char(10)+"  or  (ERX.REMINDERDATE "+@sDateRangeFilter+"))"
			        					       
					Set @sWhereDateRange = @sWhereDateRange+char(10)+" and ((CE.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						       +char(10)+"  or  (ER.DUEDATE "     +@sDateRangeFilter+")"
			        						       +char(10)+"  or  (ER.REMINDERDATE "+@sDateRangeFilter+"))"
				End	
			End
			Else If  @bHasReminder = 1  
			     and @bIsAdhoc = 1
			Begin
				If charindex('join EMPLOYEEREMINDER ERX',@sWhereFromDueDate)=0	
				Begin
					Set @sWhereFromDueDate = @sWhereFromDueDate 
						+char(10)+"join EMPLOYEEREMINDER ERX	on (ERX.CASEID=CEX.CASEID"
						+char(10)+"				and CEX.EVENTNO=ERX.EVENTNO"
						+char(10)+"				and CEX.CYCLE=ERX.CYCLENO)"
				End
				
				If  @bUseDueDate = 1
				and @bUseReminderDate = 0
				Begin
					Set @sWhereDueDate   = @sWhereDueDate  +char(10)+" and ((CEX.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						+char(10)+"  or  (ERX.DUEDATE "     +@sDateRangeFilter+"))"
			        					       
					Set @sWhereDateRange = @sWhereDateRange+char(10)+" and ((CE.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						+char(10)+"  or  (A.DUEDATE "      +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.DUEDATE "     +@sDateRangeFilter+"))"
				End
				Else If  @bUseDueDate = 0
					and @bUseReminderDate = 1
				Begin
					Set @sWhereDueDate   = @sWhereDueDate  +char(10)+" and (ERX.REMINDERDATE "+@sDateRangeFilter+")"
					
					Set @sWhereDateRange = @sWhereDateRange+char(10)+" and (ER.REMINDERDATE "+@sDateRangeFilter+")"
				End
				Else If  @bUseDueDate = 1
					and @bUseReminderDate = 1
				Begin
					Set @sWhereDueDate   = @sWhereDueDate  +char(10)+" and ((CEX.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						+char(10)+"  or  (ERX.DUEDATE "     +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ERX.REMINDERDATE "+@sDateRangeFilter+"))"
			        					       
					Set @sWhereDateRange = @sWhereDateRange+char(10)+" and ((CE.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						+char(10)+"  or  (A.DUEDATE "      +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.DUEDATE "     +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.REMINDERDATE "+@sDateRangeFilter+"))"
				End	
			End
			Else If  @bHasReminder = 0
			     and @bIsAdhoc     = 1
			Begin
				If  @bUseReminderDate = 1
				and charindex('join EMPLOYEEREMINDER ERX',@sWhereFromDueDate)=0	
				Begin
					Set @sWhereFromDueDate = @sWhereFromDueDate 
						+char(10)+"join EMPLOYEEREMINDER ERX	on (ERX.CASEID=CEX.CASEID"
						+char(10)+"				and CEX.EVENTNO=ERX.EVENTNO"
						+char(10)+"				and CEX.CYCLE=ERX.CYCLENO)"
				End
				
				If  @bUseDueDate = 1
				and @bUseReminderDate = 0
				Begin
					Set @sWhereDueDate   = @sWhereDueDate  +char(10)+" and (CEX.EVENTDUEDATE "+@sDateRangeFilter+")"
					
					Set @sWhereDateRange = @sWhereDateRange+char(10)+" and (CE.EVENTDUEDATE "+@sDateRangeFilter+")"

					Set @sUnionDateRange = @sUnionDateRange+char(10)+" and (A.DUEDATE "      +@sDateRangeFilter+")"
				End
				Else If  @bUseDueDate = 0
					and @bUseReminderDate = 1
				Begin
					Set @sWhereDueDate   = @sWhereDueDate  +char(10)+" and (ERX.REMINDERDATE "+@sDateRangeFilter+")"
					
					Set @sWhereDateRange = null

					Set @sUnionDateRange = null
				End
				Else If  @bUseDueDate = 1
					and @bUseReminderDate = 1
				Begin
					Set @sWhereDueDate   = @sWhereDueDate  +char(10)+" and ((CEX.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						+char(10)+"  or  (ERX.DUEDATE "     +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ERX.REMINDERDATE "+@sDateRangeFilter+"))"

					Set @sWhereDateRange = @sWhereDateRange+char(10)+" and ((CE.EVENTDUEDATE "+@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.DUEDATE "     +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.REMINDERDATE "+@sDateRangeFilter+"))"

					Set @sUnionDateRange = @sUnionDateRange+char(10)+" and ((A.DUEDATE "      +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.DUEDATE "     +@sDateRangeFilter+")"
			        						+char(10)+"  or  (ER.REMINDERDATE "+@sDateRangeFilter+"))"
				End	
			End			
		End
		
		If @bIsRenewalsOnly = 1
		or @bIsNonRenewalsOnly = 1
		or @bIncludeClosed = 0	
		or @sActionKeys is not null
		or @nActionKeysOperator between 2 and 6
		Begin
			Set @sWhereDueDate=@sWhereDueDate+char(10)+"and exists"
	
			Set @sWhereDueDate = @sWhereDueDate
			+char(10)+"    (select 1"
			+char(10)+"	from OPENACTION OA"
			+char(10)+"	join EVENTS OE		on (OE.EVENTNO  = CEX.EVENTNO"
			
			If @sActionKeys is null
			or @nActionKeysOperator>0
				Set @sWhereDueDate = @sWhereDueDate
				+char(10)+"				and OA.ACTION   = isnull(OE.CONTROLLINGACTION,OA.ACTION)"
				
			Set @sWhereDueDate = @sWhereDueDate +")"
			+char(10)+"	join EVENTCONTROL OEC	on (OEC.EVENTNO = CEX.EVENTNO"
			+char(10)+"				and OEC.CRITERIANO = OA.CRITERIANO)"
			+char(10)+"	join EVENTS E  on (E.EVENTNO=CEX.EVENTNO)"
			+char(10)+"	join ACTIONS A		on (A.ACTION = OA.ACTION)"		
			+char(10)+"	where OA.CASEID = CEX.CASEID"
			
			If @sActionKeys is null
			or @nActionKeysOperator>0
				Set @sWhereDueDate = @sWhereDueDate
				+char(10)+"	and OA.ACTION=isnull(E.CONTROLLINGACTION, OA.ACTION)"
			
			If @sActionKeys is not null or @nActionKeysOperator between 2 and 6
			Begin
				Set @sWhereDueDate = @sWhereDueDate +char(10)+"	and OA.ACTION"+dbo.fn_ConstructOperator(@nActionKeysOperator,@CommaString,@sActionKeys, null,@pbCalledFromCentura) 
			End
			
			
			If @bIncludeClosed <> 1			
			Begin
				Set @sWhereDueDate = @sWhereDueDate
				+char(10)+"		and	OA.POLICEEVENTS = 1"	
				+char(10)+"		and   ((A.NUMCYCLESALLOWED > 1 and OA.CYCLE = CEX.CYCLE)"
		 		+char(10)+"		or      A.NUMCYCLESALLOWED = 1)"	

				-- Get the Action used for Renewals
				Select @sRenewalAction=S.COLCHARACTER
				from SITECONTROL S
				where CONTROLID='Main Renewal Action'

				-- If Renewal Actions have not been excluded then we need to ensure that the Next Renewal
				-- Due Date is only considered if the appropriate Action is opened.
				If @sRenewalAction is not NULL
				and isnull(@bIsNonRenewalsOnly,0)=0
				Begin
					Set @sWhereDueDate = @sWhereDueDate
					+char(10)+"		and   ((OA.ACTION='"+@sRenewalAction+"' and CEX.EVENTNO=-11) OR CEX.EVENTNO<>-11)"
				End

			End		
	
			If @bIsNonRenewalsOnly <> @bIsRenewalsOnly
			Begin
				If @bIsNonRenewalsOnly = 1
				Begin
					Set @sWhereDueDate = @sWhereDueDate
					+char(10)+"				and	A.ACTIONTYPEFLAG <> 1"
				End
				Else
				If @bIsRenewalsOnly = 1
				Begin
					Set @sWhereDueDate = @sWhereDueDate
					+char(10)+"				and	A.ACTIONTYPEFLAG = 1"
				End
			End
			
			Set @sWhereDueDate = @sWhereDueDate+char(10)+")"
		End

		If   @nImportanceLevelOperator is not null
		and (@sImportanceLevelFrom is not null
		 or  @sImportanceLevelTo is not null)
		Begin
			If charindex('join EVENTS EX',@sWhereFromDueDate)=0	
			Begin
				Set @sWhereFromDueDate = @sWhereFromDueDate 
					+char(10)+"join EVENTS EX	on (EX.EVENTNO = CEX.EVENTNO)"
			End
			Set @sWhereFromDueDate = @sWhereFromDueDate + char(10) 
						+char(10)+"left join OPENACTION OAX	on (OAX.CASEID = CEX.CASEID"
						+char(10)+"				and OAX.ACTION = EX.CONTROLLINGACTION)"
						+char(10)+"left join EVENTCONTROL ECX	on (ECX.EVENTNO = CEX.EVENTNO"
				  	 	+char(10)+"				and ECX.CRITERIANO = isnull(OAX.CRITERIANO,CEX.CREATEDBYCRITERIA))"

			Set @sWhereDueDate = @sWhereDueDate+char(10)+" and coalesce(ECX.IMPORTANCELEVEL,EX.IMPORTANCELEVEL,0)"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0)	

			If @bHasReminder=1
			and @bIsAdHoc   =1
				Set @sWhereDateRange = @sWhereDateRange+char(10)+" and (A.IMPORTANCELEVEL"+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0)+" OR A.IMPORTANCELEVEL is null)"		
		End

		If @sEventKeys is not null
		or @nEventKeyOperator between 2 and 6
		Begin	
			Set @sWhereDueDate = @sWhereDueDate+char(10)+" and CEX.EVENTNO "+dbo.fn_ConstructOperator(@nEventKeyOperator,@Numeric,@sEventKeys, null,0)
		End		

		If @nEventCategoryKey is not null
		or @nEventCategoryKeyOperator between 2 and 6
		Begin
			If charindex('join EVENTS EX',@sWhereFromDueDate)=0	
			Begin
				Set @sWhereFromDueDate = @sWhereFromDueDate + char(10) 
							+char(10)+"join EVENTS EX		on (EX.EVENTNO = CEX.EVENTNO)"
			End	

			Set @sWhereDueDate = @sWhereDueDate+char(10)+" and EX.CATEGORYID "+dbo.fn_ConstructOperator(@nEventCategoryKeyOperator,@Numeric,@nEventCategoryKey, null,0)
		End	
				
		--------------------------
		-- RFC43207
		-- Filtering on Event Text
		--------------------------
		If @nEventNoteTypeKeysOperator is not null
		or @nEventNoteTextOperator     is not null
		Begin
		
			Set @sWhereFromDueDate=@sWhereFromDueDate
				   +char(10)+"left join CASEEVENTTEXT XCET WITH (NOLOCK) on (XCET.CASEID =CEX.CASEID"
				   +char(10)+"                                           and XCET.EVENTNO=CEX.EVENTNO"
				   +char(10)+"                                           and XCET.CYCLE  =CEX.CYCLE)"
				   +char(10)+"left join EVENTTEXT XET WITH (NOLOCK)      on (XET.EVENTTEXTID=XCET.EVENTTEXTID)"

			If @nEventNoteTypeKeysOperator is not null
				Set @sWhereDueDate =  @sWhereDueDate+char(10)+"	and XET.EVENTTEXTTYPEID"+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)

			If @nEventNoteTextOperator is not null
				Set @sWhereDueDate =  @sWhereDueDate+char(10)+"	and XET.EVENTTEXT"+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
		End	
	End

	-- Construction of the Ad Hoc Due Dates 'Where' clause
	If @bIsAdHoc = 1
	Begin		
	        If  @nNameReferenceKey is not null
	        and @nNameReferenceKeyOperator < 2
		Begin	
		        Set @sUnionWhereDueDate = @sUnionWhereDueDate
		                                        +char(10)+" and AX.NAMENO "+dbo.fn_ConstructOperator(@nNameReferenceKeyOperator,@String,@nNameReferenceKey, null,0)
		End
		-- If the user does not belong to a group and 'Belonging to Anyone in my group
		-- Acting as Recipient' we should return an empty  result set:
		If   @bMemberIsCurrentUser = 1
		and  @nMemberOfGroupKey is null
		and  @nMemberOfGroupKeyOperator is not null
		Begin
			Set @sUnionWhereFromDueDate = @sUnionWhereFromDueDate +char(10)+" join NAME N	on (N.NAMENO = "+CAST(@nNullGroupNameKey  as varchar(11))
								   	      +char(10)+"		and N.FAMILYNO is not null)"								 
		End

		If (@nNameKey is not null 
		or @sNameKeys is not null
		or  @nNameKeyOperator between 2 and 6)		
		or (@nMemberOfGroupKey is not null
		or  @nMemberOfGroupKeyOperator between 2 and 6)
		Begin
			-- If the @nNameKeyOperator has been changed from 1 to 0 by the Events
			-- filtering logic we need to change it back to 1:					
			If @bIsNameOperResetFrom1To0 = 1
			Begin
				Set @nNameKeyOperator = 1
			End

			-- If the @nMemberOfGroupKeyOperator has been changed from 1 to 0 by the Events
			-- filtering logic we need to change it back to 1:					
			If @bIsMemberOperResetFrom1To0 = 1
			Begin
				Set @nMemberOfGroupKeyOperator = 1
			End
			
			If @bIsRecipient = 1
			Begin
				-- Ad Hoc date is for the specified name.
				If  @nNameKey is not null
				or @sNameKeys is not null
				or  @nNameKeyOperator between 2 and 6
				Begin					
					Set @nNumberOfBrakets = 1					
					If @bUseReminderDate = 1 
					Begin
					        -- RFC10653: Add join to EMPLOYEEREMINDERS to be able to filter against it
					        If charindex('join EMPLOYEEREMINDER ERX',@sUnionWhereFromDueDate)=0	
					        Begin 
					        Set @sUnionWhereFromDueDate = @sUnionWhereFromDueDate
							+char(10)+"join EMPLOYEEREMINDER ERX	on (AX.EMPLOYEENO = ERX.ALERTNAMENO"
							+char(10)+"				and AX.SEQUENCENO = ERX.SEQUENCENO"
							+char(10)+"				AND ERX.EVENTNO IS NULL)"
				                End
					End
					
					If @sNameKeys is not null
					Begin
						If @bUseReminderDate = 1					        	
						Begin
							Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+"and (ERX.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
						End
						Else
						Begin
							Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+"and (AX.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
						End
					End
					Else
					Begin
						If @bUseReminderDate = 1					        	
						Begin
						Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+"and (ERX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
						End
						Else
						Begin
					Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+"and (AX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
						End
					End
						
				End		

				-- Ad Hoc date is for any of the names in the Name Group.
				If  @nMemberOfGroupKey is not null 
				or  @nMemberOfGroupKeyOperator between 2 and 6
				Begin				
					Set @sUnionWhereFromDueDate = @sUnionWhereFromDueDate 
								+char(10)+"left join NAME N	on (N.NAMENO = AX.EMPLOYEENO)"														

					Set @nNumberOfBrakets = 1
					Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and (N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
				End			
			End			
			
			-------------------------------------------
			-- RFC12200
			-- If the procedure has been called by the 
			-- Whats Due web part (QueryContextKey=160) 
			-- then Alert rows to be returned will not
			-- take consideration of the CaseName
			-- filtering
			-------------------------------------------
			If  @pnQueryContextKey not in (160)
			and @bHasCase = 1
			and @sNameTypeKeys is not null
			Begin
				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nNameKeyOperator in (1,6)			
				or @nMemberOfGroupKeyOperator in (1,6)
				Begin
					If @nNameKeyOperator = 1
					Begin
						-- Set operator to 0 as we use 'not exists':
						Set @nNameKeyOperator = 0

						-- Set the 'Reset' flags to 1 so the Reminders filtering logic will be aware of 
						-- modified operators:
						Set @bIsNameOperResetFrom1To0 = 1
					End

					If @nMemberOfGroupKeyOperator = 1
					Begin
						-- Set operator to 0 as we use 'not exists':
						Set @nMemberOfGroupKeyOperator = 0

						-- Set the 'Reset' flags to 1 so the Reminders filtering logic will be aware of 
						-- modified operators:					
						Set @bIsMemberOperResetFrom1To0 = 1
					End
								
					Set @sUnionWhereDueDate=@sUnionWhereDueDate+char(10)+"and not exists"
				End
				Else 
				Begin
					-- If there is an Ad Hoc date is for the specified name or Ad Hoc date 
					-- is for any of the names in the Name Group then use 'or exists':
					If @bIsRecipient = 1
					Begin
						Set @sUnionWhereDueDate=@sUnionWhereDueDate+char(10)+"or exists"
					End
					Else Begin
						Set @sUnionWhereDueDate=@sUnionWhereDueDate+char(10)+"and exists"
					End
				End
	
				Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+"(Select * "  
						     		   +char(10)+" from CASENAME CN"  							     
   								   +char(10)+" join #TempFilteredUserNameTypes FCN"+cast(@nCount as varchar(10))+" on (FCN"+cast(@nCount as nvarchar(20))+".NAMETYPE=CN.NAMETYPE"
						     		   +char(10)+" 		and  CN.NAMETYPE in ("+@sNameTypeKeys+"))"		
				
				If (@nMemberOfGroupKey is not null
				or  @nMemberOfGroupKeyOperator between 2 and 6)
				Begin
					If @nMemberOfGroupKeyOperator not in (5,6)
					Begin
						Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" join NAME N 	on (N.NAMENO = CN.NAMENO"
										     +char(10)+" 		and N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)+")"
					End
	 				Else
					Begin
						Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" join NAME N 	on (N.NAMENO = CN.NAMENO"
										     +char(10)+" 		and N.FAMILYNO is not null)"
					End					
				End
						     
				Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" where CN.CASEID = AX.CASEID"
	
				If  @nNameKeyOperator not in (5,6)
				and @nNameKey is not null 
				Begin					
					Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and CN.NAMENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
				End						
	
				Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate()))"									
			End
			
			If @nNumberOfBrakets = 1
			Begin
				Set @sUnionWhereDueDate = @sUnionWhereDueDate + ")"	
			End	
		End												
		
		If @dtDateRangeFrom is not null
		or @dtDateRangeTo is not null
		or @dtClientDateRangeFrom is not null
		Begin
			If  @bUseDueDate = 1
			and @bUseReminderDate = 0
			Begin
				Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and AX.DUEDATE "+@sDateRangeFilter									
			End
			Else If @bUseDueDate = 0
			and @bUseReminderDate = 1
			Begin
				If charindex('join EMPLOYEEREMINDER ERX',@sUnionWhereFromDueDate)=0	
				Begin 
					Set @sUnionWhereFromDueDate = @sUnionWhereFromDueDate
							+char(10)+"join EMPLOYEEREMINDER ERX	on (AX.EMPLOYEENO = ERX.ALERTNAMENO"
							+char(10)+"				and AX.SEQUENCENO = ERX.SEQUENCENO"
							+char(10)+"				AND ERX.EVENTNO IS NULL)"
				End

				Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and ERX.REMINDERDATE "+@sDateRangeFilter													
			End
			Else If @bUseDueDate = 1
			and @bUseReminderDate = 1
			Begin
				If charindex('join EMPLOYEEREMINDER ERX',@sUnionWhereFromDueDate)=0	
				Begin 
					Set @sUnionWhereFromDueDate = @sUnionWhereFromDueDate
							+char(10)+"join EMPLOYEEREMINDER ERX	on (AX.EMPLOYEENO = ERX.ALERTNAMENO"
							+char(10)+"				and AX.SEQUENCENO = ERX.SEQUENCENO"
							+char(10)+"				AND ERX.EVENTNO IS NULL)"
				End

				Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and ((AX.DUEDATE "+@sDateRangeFilter+")"								
			        				  	     +char(10)+"  or  (ERX.REMINDERDATE "+@sDateRangeFilter+"))"																	
			End			
		End	

		If  @sAdHocReference is not null
		or  @nAdHocReferenceOperator between 2 and 6
		Begin					
			Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and 	AX.REFERENCE "+dbo.fn_ConstructOperator(@nAdHocReferenceOperator,@String,@sAdHocReference, null,0)
		End		

		If  @sAdHocMessage is not null
		or  @nAdHocMessageOperator between 2 and 6
		Begin					
			Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and 	AX.ALERTMESSAGE "+dbo.fn_ConstructOperator(@nAdHocMessageOperator,@String,@sAdHocMessage, null,0)
		End	

		
		If  @sAdHocEmailSubject is not null
		or  @nAdHocEmailSubjectOperator between 2 and 6
		Begin					
			Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+" and 	AX.EMAILSUBJECT "+dbo.fn_ConstructOperator(@nAdHocEmailSubjectOperator,@String,@sAdHocEmailSubject, null,0)
		End	

		If   @nImportanceLevelOperator is not null
		and (@sImportanceLevelFrom is not null
		 or  @sImportanceLevelTo is not null)
		Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate+char(10)+"and (AX.IMPORTANCELEVEL "+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0)+" or AX.IMPORTANCELEVEL is null)"	-- RFC12232	
		End
	End

	-- Construction of the Reminders 'Where' clause
	If @bHasReminder = 1 
	Begin
		-- If the user does not belong to a group and 'Belonging to Anyone in my group
		-- Acting as Recipient' we should return an empty  result set:
		If   @bMemberIsCurrentUser = 1
		and  @nMemberOfGroupKey is null
		and  @nMemberOfGroupKeyOperator is not null
		Begin
			Set @sWhereFromReminder = @sWhereFromReminder +char(10)+" join NAME N	on (N.NAMENO = "+CAST(@nNullGroupNameKey  as varchar(11))
								   	      +char(10)+"		and N.FAMILYNO is not null)"								 
		End
		
		If (@nNameKey is not null 
		or @sNameKeys is not null
		or  @nNameKeyOperator between 2 and 6)		
		or (@nMemberOfGroupKey is not null
		or  @nMemberOfGroupKeyOperator between 2 and 6)
		Begin
			Set @sWhereFromReminder = @sWhereFromReminder + @sFromFunctionSecurity + CHAR(10)
			-- If the @nNameKeyOperator has been changed from 1 to 0 by the Events
			-- filtering logic we need to change it back to 1:					
			If @bIsNameOperResetFrom1To0 = 1
			Begin
				Set @nNameKeyOperator = 1
			End
	
			-- If the @nMemberOfGroupKeyOperator has been changed from 1 to 0 by the Events
			-- filtering logic we need to change it back to 1:					
			If @bIsMemberOperResetFrom1To0 = 1
			Begin
				Set @nMemberOfGroupKeyOperator = 1
			End
	
			-- Reset the @nNumberOfBrakets variable as it probably was 
			-- used by the Events filtering logic. 
			Set @nNumberOfBrakets = 0
	
			If @bIsRecipient = 1
			Begin
				-- Ad Hoc date is for the specified name.
				If  @nNameKeyOperator between 2 and 6
				Begin
					Set @nNumberOfBrakets = 1					
				End		
				If @nNameKey is not null
				Begin
					Set @sWhereReminder = @sWhereReminder+char(10)+"and (ERX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
					Set @nNumberOfBrakets = 1														
				End
				If @sNameKeys is not null
				Begin
					Set @sWhereReminder = @sWhereReminder+char(10)+"and (ERX.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
					Set @nNumberOfBrakets = 1
				End		

				-- Ad Hoc date is for any of the names in the Name Group.
				If  @nMemberOfGroupKey is not null 
				or  @nMemberOfGroupKeyOperator between 2 and 6
				Begin				
					Set @sWhereFromReminder = @sWhereFromReminder 
								+char(10)+"left join NAME NX	on (NX.NAMENO = ERX.EMPLOYEENO)"																												
	
					Set @nNumberOfBrakets = 1
					Set @sWhereReminder = @sWhereReminder+char(10)+" and (NX.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
				End			
			End			

			If @bIsEventStaff = 1
			Begin	
				Set @sWhereFromReminder = @sWhereFromReminder
							+char(10)+"left join CASEEVENT CEX		on (CEX.CASEID = ERX.CASEID"
							+char(10)+"					and CEX.EVENTNO = ERX.EVENTNO"
							+char(10)+"					and CEX.CYCLE = ERX.CYCLENO)"

				If (@nMemberOfGroupKey is not null
				or @nMemberOfGroupKeyOperator between 2 and 6)
				-- If the group of the current user is selected as filter criteria
				-- but the current user does not belong to any group the code
				-- above should suppress the result set
				and @nNullGroupNameKey is null
				Begin
					Set @sWhereFromReminder = @sWhereFromReminder+char(10)+"left join NAME NEMP		on (NEMP.NAMENO = CEX.EMPLOYEENO)" 
				   	
					-- If Operator is set to IS NULL then use NOT EXISTS
					If @nMemberOfGroupKeyOperator in (1,6)
					Begin
						If @nNumberOfBrakets = 1
						Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+"and NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)		 						
						End
						Else Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+"and (NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
							Set @nNumberOfBrakets = 1
						End
					End
					Else If @nMemberOfGroupKeyOperator not in (1,6)
					Begin
						If @nNumberOfBrakets = 1 
						Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+"or NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
						End
						Else Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+"and (NEMP.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
							Set @nNumberOfBrakets = 1
						End
					End							
				End
				Else If @nNameKey is not null
				     or @sNameKeys is not null
				     or @nNameKeyOperator between 2 and 6
				Begin
					If @nNameKeyOperator = 1
					Begin
						If @nNumberOfBrakets = 1
						Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+" and "											
						End
						Else  
						Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+" and( "					
							Set @nNumberOfBrakets = 1
						End
					End
					Else If @nNameKeyOperator not in (1)
					Begin
						If @nNumberOfBrakets = 1
						Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+" or "											
						End
						Else  
						Begin
							Set @sWhereReminder=@sWhereReminder+char(10)+" and( "					
							Set @nNumberOfBrakets = 1
						End
					End				

					If @nNameKey is not null
					Begin
						Set @sWhereReminder = @sWhereReminder+char(10)+" CEX.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
					End
					If @sNameKeys is not null
					Begin
						Set @sWhereReminder = @sWhereReminder+char(10)+" CEX.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
					End
					
				End
			End	
						
			If @bHasCase = 1
			and @sNameTypeKeys is not null
			Begin
				-- If Operator is set to IS NULL then use NOT EXISTS
				If @nNameKeyOperator in (1,6)			
				or @nMemberOfGroupKeyOperator in (1,6)
				Begin
					If @nNameKeyOperator = 1
					Begin
						-- Set operator to 0 as we use 'not exists':
						Set @nNameKeyOperator = 0
					End
	
					If @nMemberOfGroupKeyOperator = 1
					Begin
						-- Set operator to 0 as we use 'not exists':
						Set @nMemberOfGroupKeyOperator = 0
					End
								
					Set @sWhereReminder=@sWhereReminder+char(10)+"and not exists"
				End
				Else 
				Begin
					-- If there is an Ad Hoc date is for the specified name or Ad Hoc date 
					-- is for any of the names in the Name Group then use 'or exists':
					If @nNumberOfBrakets = 1
					Begin
						Set @sWhereReminder=@sWhereReminder+char(10)+"or exists"
					End
					Else Begin
						If  @nNameKey is not null
						Begin					
							-- Return only Reminders belonging to the specific user of the reminder group
							-- in case multiple reminders were created for the same case and due date 
							Set @sWhereReminder = @sWhereReminder+char(10)+"and ERX.EMPLOYEENO = "+convert(nvarchar,@nNameKey)													
						End	
						
						If  @nMemberOfGroupKey is not null 
						Begin				
							Set @sWhereFromReminder = @sWhereFromReminder 
										+char(10)+"left join NAME NX	on (NX.NAMENO = ERX.EMPLOYEENO)"																												
							Set @sWhereReminder = @sWhereReminder+char(10)+" and (NX.FAMILYNO = "+convert(nvarchar,@nMemberOfGroupKey)+")"
						End		
						Set @sWhereReminder=@sWhereReminder+char(10)+"and exists"
					End
				End
	
				Set @sWhereReminder = @sWhereReminder+char(10)+"(Select * "  
						     		     +char(10)+" from CASENAME CN"  							     
     								     +char(10)+" join #TempFilteredUserNameTypes FCN"+cast(@nCount as varchar(10))+" on (FCN"+cast(@nCount as nvarchar(20))+".NAMETYPE=CN.NAMETYPE"
						     		     +char(10)+" 		and  CN.NAMETYPE in ("+@sNameTypeKeys+"))"		
				
	
				If (@nMemberOfGroupKey is not null
				or  @nMemberOfGroupKeyOperator between 2 and 6)
				Begin
					If @nMemberOfGroupKeyOperator not in (5,6)
					Begin
						Set @sWhereReminder = @sWhereReminder+char(10)+" join NAME N 	on (N.NAMENO = CN.NAMENO"
									     +char(10)+" 		and N.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)+")"
					End
	 				Else
					Begin
						Set @sWhereReminder = @sWhereReminder+char(10)+" join NAME N 	on (N.NAMENO = CN.NAMENO"
									     +char(10)+" 		and N.FAMILYNO is not null)"
					End					
				End
					
				Set @sWhereReminder = @sWhereReminder+char(10)+" where CN.CASEID = ERX.CASEID"				

				If  @nNameKeyOperator not in (5,6)
				Begin
					If @nNameKey is not null 		
				Begin					
					Set @sWhereReminder = @sWhereReminder+char(10)+" and CN.NAMENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
				End						
				End						
	
				Set @sWhereReminder = @sWhereReminder+char(10)+" and (CN.EXPIRYDATE is NULL or CN.EXPIRYDATE >getdate()))"									
			End
			
			If @nNumberOfBrakets = 1
			Begin
				Set @sWhereReminder = @sWhereReminder + ")"	
			End	
		End					
		
		If @dtDateRangeFrom is not null
		or @dtDateRangeTo is not null
		or @dtClientDateRangeFrom is not null
		Begin
			If  @bUseDueDate = 1
			and @bUseReminderDate = 0
			Begin
				Set @sWhereReminder = @sWhereReminder+char(10)+" and ERX.DUEDATE "+@sDateRangeFilter									
			End
			Else If @bUseDueDate = 0
			and @bUseReminderDate = 1
			Begin
				Set @sWhereReminder = @sWhereReminder+char(10)+" and ERX.REMINDERDATE "+@sDateRangeFilter													
			End
			Else If @bUseDueDate = 1
			and @bUseReminderDate = 1
			Begin
				Set @sWhereReminder = @sWhereReminder+char(10)+" and ((ERX.DUEDATE "+@sDateRangeFilter+")"								
			        				     +char(10)+"  or  (ERX.REMINDERDATE "+@sDateRangeFilter+"))"													
			End			
		End		
	
		If @sReminderMessage is not null
		or @nReminderMessageOperator between 2 and 6
		Begin
			Set @sWhereReminder = @sWhereReminder+char(10)+" and isnull(cast(ERX.LONGMESSAGE as nvarchar(4000)), ERX.SHORTMESSAGE) "+dbo.fn_ConstructOperator(@nReminderMessageOperator,@String,@sReminderMessage, null,0)			
		End		

		If @bIsReminderOnHold is not null
		Begin
			-- Reminders that are on hold are those with a non-null HoldUntilDate.
			If @bIsReminderOnHold = 1
			Begin
				Set @sWhereReminder = @sWhereReminder+char(10)+" and ERX.HOLDUNTILDATE is not null" 	
			End
			Else If @bIsReminderOnHold = 0
			Begin
				Set @sWhereReminder = @sWhereReminder+char(10)+" and ERX.HOLDUNTILDATE is null" 	
			End
					
		End				

		If @bIsReminderRead is not null
		Begin
			Set @sWhereReminder = @sWhereReminder+char(10)+" and CAST(ERX.READFLAG as bit) = " + CAST(@bIsReminderRead as char(1)) 	
		End	
		
	End
End

-- If Filter Criteria where not supplied and neither of the following parameters 
-- were supplied then set them all to 1:
If @nErrorCode = 0
and (datalength(@ptXMLFilterCriteria) = 0
 or  datalength(@ptXMLFilterCriteria) is null)
Begin
	
	If  (@bIsEvent 	 = 0 or @bIsEvent 	is null)
	and (@bIsAdHoc 	 = 0 or @bIsAdHoc 	is null)
	and (@bHasCase   = 0 or @bHasCase 	is null)
	and (@bIsGeneral = 0 or @bIsGeneral 	is null)
	Begin
		Set @bIsEvent 	= 1
		Set @bIsAdHoc 	= 1
		Set @bHasCase 	= 1
		Set @bIsGeneral = 1			
	End 

	-- If the the following parameters were not supplied 
	-- then set them to 0:
	Set @bIsEvent 		= CASE WHEN @bIsEvent 		is null THEN 0 ELSE @bIsEvent END
	Set @bIsAdHoc 		= CASE WHEN @bIsAdHoc 		is null THEN 0 ELSE @bIsAdHoc END
	Set @bHasCase 		= CASE WHEN @bHasCase 		is null THEN 0 ELSE @bHasCase END
	Set @bIsGeneral 	= CASE WHEN @bIsGeneral 	is null THEN 0 ELSE @bIsGeneral END
	Set @bHasReminder 	= CASE WHEN @bHasReminder 	is null THEN 0 ELSE @bHasReminder END	
	Set @bExcludeOccurred	= CASE WHEN @bExcludeOccurred	is null	THEN 0 ELSE @bExcludeOccurred END	
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin   
	-- Default @pnQueryContextKey to 160.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 160)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)	
End

-- Additional columns may be required by the outer SQL. These are added if not already present.
If @nErrorCode=0
and @bHasCase = 1
Begin 
	-- Make sure that the CaseKey is always returned by the csw_ListCase
	-- to be able to join on it.
	If not exists ( Select 1 
			from @tblOutputRequests
			where ID = 'CaseKey'
			and   PROCEDURENAME = 'csw_ListCase')
	Begin
		insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME)
		select isnull(max(ROWNUMBER),0)+1, 'CaseKey', null, null, null, null, null, 'csw_ListCase'
		from @tblOutputRequests
	End

	-- Make sure that the Reference is returned by the csw_ListCase
	-- if the Reference column was requested.
	If exists     ( Select 1 
			from @tblOutputRequests t1
			where t1.ID = 'Reference'
			and   t1.PROCEDURENAME = 'ipw_ListDueDate'
			and not exists (Select 1 
					from @tblOutputRequests t2
					where t2.ID = 'CaseReference'
					and   t2.PROCEDURENAME = 'csw_ListCase'
					and   t2.PUBLISHNAME = 'CaseReference'))
	Begin
		insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME)
		select isnull(max(ROWNUMBER),0)+1,'CaseReference', null, null, null, null, null, 'csw_ListCase'
		from @tblOutputRequests
	End
		
        If exists(Select 1 
			from @tblOutputRequests t1
			where t1.ID in ('EventText', 'EventTextType', 'EventTextModifiedDate')
			and   t1.PROCEDURENAME = 'ipw_ListDueDate')
	Begin
		Set @bHasEventTextColumn = 1
	End
		
End

-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
-- while constructing the "Select" list   
If @nErrorCode=0
Begin
	Set @nOutRequestsRowCount = (Select count(*) from @tblOutputRequests)

	-- Reset the @nCount.
	Set @nCount = 1
End

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @nErrorCode=0
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
		@sProcedureName		= PROCEDURENAME,
		@nDataFormatID		= DATAFORMATID
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If  @nErrorCode=0
	and @sQualifier is null
	Begin
		Set @sCorrelationSuffix=NULL
	End
	Else Begin			
		-------------------------------------
		-- Translate the Qualifier passed for 
		-- the EVENTTEXTTYPE table from its
		-- Description to it internal key
		-------------------------------------
		If @sColumn in ('EventTextOfType',
				'EventTextOfTypeModifiedDate')
		Begin
			Select @sQualifier=cast(EVENTTEXTTYPEID as nvarchar)
			From EVENTTEXTTYPE
			where DESCRIPTION=@sQualifier
			
			Set @nErrorCode=@@ERROR
		End
				
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End

	If @nErrorCode=0	 
	Begin
		If @sProcedureName = 'ipw_ListDueDate'
		Begin
			-- RFC12545 correction
			If @bHasReminder = 1
			Begin				
				If @sColumn in ('CanUpdate', 'CanDelete')
				Begin
					If  charindex('Left Join (Select R.EMPLOYEENO,',@sFromDueDate)=0
					Begin
						Set @sFromDueDate =@sFromDueDate+char(10)+"
							Left Join (Select R.EMPLOYEENO, 
								max(CASE WHEN (F.OWNERNO       IS NULL) THEN '0' ELSE '1' END +    			
								    CASE WHEN (F.ACCESSSTAFFNO IS NULL) THEN '0' ELSE '1' END +	
								    CASE WHEN (F.ACCESSGROUP   IS NULL) THEN '0' ELSE '1' END +
								    convert(varchar(5), F.ACCESSPRIVILEGES) ) as ACCESSPRIVILEGES
								FROM (select distinct EMPLOYEENO from EMPLOYEEREMINDER) R
								JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=2)
								JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
								JOIN NAME N          ON (UI.NAMENO = N.NAMENO)
								WHERE (F.OWNERNO       = R.EMPLOYEENO  OR F.OWNERNO       IS NULL)
								  AND (F.ACCESSSTAFFNO = UI.NAMENO     OR F.ACCESSSTAFFNO IS NULL) 
								  AND (F.ACCESSGROUP   = N.FAMILYNO    OR F.ACCESSGROUP   IS NULL)
								group by R.EMPLOYEENO) FS on (FS.EMPLOYEENO=ER.EMPLOYEENO)"
					End 
					
					If  charindex('Left Join (Select R.EMPLOYEENO,',@sUnionFromDueDate)=0
					Begin
						Set @sUnionFromDueDate =@sUnionFromDueDate+char(10)+"
							Left Join (Select R.EMPLOYEENO, 
								max(CASE WHEN (F.OWNERNO       IS NULL) THEN '0' ELSE '1' END +    			
								    CASE WHEN (F.ACCESSSTAFFNO IS NULL) THEN '0' ELSE '1' END +	
								    CASE WHEN (F.ACCESSGROUP   IS NULL) THEN '0' ELSE '1' END +
								    convert(varchar(5), F.ACCESSPRIVILEGES) ) as ACCESSPRIVILEGES
								FROM (select distinct EMPLOYEENO from EMPLOYEEREMINDER) R
								JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=2)
								JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
								JOIN NAME N          ON (UI.NAMENO = N.NAMENO)
								WHERE (F.OWNERNO       = R.EMPLOYEENO  OR F.OWNERNO       IS NULL)
								  AND (F.ACCESSSTAFFNO = UI.NAMENO     OR F.ACCESSSTAFFNO IS NULL) 
								  AND (F.ACCESSGROUP   = N.FAMILYNO    OR F.ACCESSGROUP   IS NULL)
								group by R.EMPLOYEENO) FS on (FS.EMPLOYEENO=ER.EMPLOYEENO)"
					End 
					
					If @sColumn = 'CanUpdate'
					Begin
						Set @sTableColumn = 'CASE WHEN (convert(bit,(substring(FS.ACCESSPRIVILEGES,4,5)&4))=1 OR ER.EMPLOYEENO = '+convert(varchar,@nCurrentUserNameKey)+') THEN convert(bit,1)
											 ELSE convert(bit,0) END'
					End
					Else If @sColumn = 'CanDelete'
					Begin
						Set @sTableColumn = 'CASE WHEN (convert(bit,(substring(FS.ACCESSPRIVILEGES,4,5)&8))=1 OR ER.EMPLOYEENO = '+convert(varchar,@nCurrentUserNameKey)+') THEN convert(bit,1)
											 ELSE convert(bit,0) END'
					End
				End
			End
			Else Begin
				If @sColumn = 'CanUpdate'
				Begin
					Set @sTableColumn = 'convert(bit,1)'
				End
				If @sColumn = 'CanDelete'
				Begin
					Set @sTableColumn = 'convert(bit,1)'
				End	
			End

			If  @bIsEvent = 1				
			and @bHasCase = 1
			Begin				
				If @sColumn='NULL'		
				Begin
					Set @sTableColumn='NULL'
				End				

				If @sColumn = 'IsEditable'
				Begin
					If @bRowLevelSecurity = 0
					Begin
						------------------------------------
						-- Now check if any other users have 
						-- row level security configured.
						------------------------------------
						If exists (Select 1
							   from IDENTITYROWACCESS U WITH (NOLOCK) 
							   join USERIDENTITY UI WITH (NOLOCK) on (U.IDENTITYID = UI.IDENTITYID)
							   join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
							   where R.RECORDTYPE = 'C' and isnull(UI.ISEXTERNALUSER,0) = 0)
						Begin
							Set @sTableColumn='Cast(0 as bit)'
						End
						Else Begin
							Set @sTableColumn='Cast(1 as bit)'
						End
					End
					Else
					Begin
						-- IsEditable - Update Case access only.  Do not check for Insert/Delete access
						Set @sTableColumn='(CASE WHEN(RS.UPDATEALLOWED=1) THEN convert(bit,1) ELSE convert(bit,0) END)
								    &
								    CASE WHEN convert(bit,(RUC.SECURITYFLAG&(2|4|8)))=1 THEN convert(bit,1) 
									 WHEN RUC.SECURITYFLAG IS NULL THEN 								
										CASE WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & (2|4|8))) = 1 THEN convert(bit,1)
										     ELSE convert(bit,0) 
										END

									 ELSE convert(bit,0) END
								    '
						-- Row Access only becomes effective when there is at least one row access details is assigned to the user.  See RowAccessAgainst
						Set @sFromDueDate=@sFromDueDate+char(10)+"
							
								left join (select UC.CASEID as CASEID,
										(Select ISNULL(US.SECURITYFLAG,"+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+")
										  from USERSTATUS US WITH (NOLOCK)
										  JOIN USERIDENTITY UI ON (UI.LOGINID = US.USERID and US.STATUSCODE = UC.STATUSCODE)
										  WHERE UI.IDENTITYID ="+convert(nvarchar,@pnUserIdentityId)+") as SECURITYFLAG
									   from CASES UC) RUC on (RUC.CASEID=C.CaseKey)"
			
						If @bCaseOffice = 1
						Begin
							Set @sFromDueDate =@sFromDueDate+char(10)+"
								left join fn_CasesRowSecurity("+convert(nvarchar,@pnUserIdentityId)+") RS on (RS.CASEID=C.CaseKey)"
						End
						Else Begin
							Set @sFromDueDate =@sFromDueDate+char(10)+"
								left join fn_CasesRowSecurityMultiOffice("+convert(nvarchar,@pnUserIdentityId)+") RS on (RS.CASEID=C.CaseKey)"
							End
					End
				End
				If @sColumn='DueDateRowKey'
				Begin
					If @bIsAdHoc=0
					Begin
					Set @sTableColumn="'C' + '^'+"
					+char(10)+"cast(C.CaseKey as varchar(11)) + '^' +" 
					+char(10)+"cast(CE.EVENTNO as varchar(11)) + '^' +" 
					+char(10)+"cast(CE.CYCLE as varchar(10))" 	

					-- RFC10227
						-- Do not include a join to EMPLOYEEREMINDER 
					-- when context is Due Date Calendar or Ad Hoc Date related
					If @pnQueryContextKey not in (160,163,164)
					Begin	
						Set @sTableColumn=@sTableColumn + " + '^' +"
						+char(10)+"cast(ER.EMPLOYEENO as varchar(11))" 

						If charindex('left join EMPLOYEEREMINDER ER',@sFromDueDate)=0	
						and (@bHasReminder = 0 or @bHasReminder is null)
						Begin
							Set @sFromDueDate=@sFromDueDate  +char(10)+"left join EMPLOYEEREMINDER ER	on (ER.CASEID = CE.CASEID"
											 +char(10)+"					and ER.EVENTNO = CE.EVENTNO"
											 +char(10)+"					and ER.CYCLENO = CE.CYCLE"
							
							-- RFC9783 When considering due date with 
							-- a reminder that is sent to muiltiple recipients (e.g. SIG, EMP)
							-- and the Acting As filter indicates that it should be for a particular name type only
							If (@bFilterDueDateByReminderRecipient = 1 
								and @sNameTypeKeys is not null)
							Begin
								If  @nNameKey is not null
							Begin
								Set @sFromDueDate = @sFromDueDate+
								+char(10)+"					and ER.EMPLOYEENO "+dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
							End
							
								If  @sNameKeys is not null
								Begin
									Set @sFromDueDate = @sFromDueDate+
									+char(10)+"					and ER.EMPLOYEENO in ("+dbo.fn_WrapQuotes(@sNameKeys,1,0)+")"
								End
								
							End
							
							Set @sFromDueDate = @sFromDueDate+")"				
						End
					End					
				End
					Else If @bIsAdHoc=1
					Begin				
						---RFC9998	Add Checksum to DueDateRowKey	
						If @sAdHocChecksumColumns is null
						Begin
							exec dbo.ip_GetComparableColumns
									@psColumns 	= @sAdHocChecksumColumns output, 
									@psTableName 	= 'ALERT',
									@psAlias 	= 'A'
						End    

						If @bIsEvent=0
						Begin
							Set @sTableColumn="'A' + '^'+"
								+char(10)+"cast(A.EMPLOYEENO as nvarchar(11)) + '^' +" 
								+char(10)+"convert(nvarchar(25),A.ALERTSEQ, 126) + '^' +"
								+char(10)+"convert(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+"))"	
						End
						Else If  @bHasReminder=0
						     and @bIsEvent    =1
						Begin
							Set @sTableColumn="'C' + '^'+"
								+char(10)+"cast(C.CaseKey as varchar(11)) + '^' +" 
								+char(10)+"cast(CE.EVENTNO as varchar(11)) + '^' +" 
								+char(10)+"cast(CE.CYCLE as varchar(10))"
						End
						Else If @bHasReminder=1
						     and @bIsEvent   =1
						Begin
							Set @sTableColumn=
								 char(10)+"CASE WHEN(A.EMPLOYEENO is not null)"
								+char(10)+"	THEN 'A' + '^'+"
								+char(10)+"		cast(A.EMPLOYEENO as nvarchar(11)) + '^' +" 
								+char(10)+"		convert(nvarchar(25),A.ALERTSEQ, 126) + '^' +"
								+char(10)+"		convert(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+"))"
								+char(10)+"	ELSE 'C' + '^'+"
								+char(10)+"		cast(C.CaseKey as varchar(11)) + '^' +" 
								+char(10)+"		cast(CE.EVENTNO as varchar(11)) + '^' +" 
								+char(10)+"		cast(CE.CYCLE as varchar(10))" 	

							Set @sTableColumn=@sTableColumn + char(10)+"END"
							
							-- Do not include a union to EMPLOYEEREMINDER 
						        -- when context is Ad Hoc Date related
						        If @pnQueryContextKey not in (163,164)
						        Begin	
							        Set @sTableColumn=@sTableColumn + " + '^' +"
							        +char(10)+"		cast(ER.EMPLOYEENO as varchar(11))"
						        End
						End
					End				
                                        
                                        If @bHasEventTextColumn = 1
					Begin
						If charindex('left join CASEEVENTTEXT CET',@sFromDueDate)=0	
						Begin
							Set @sFromDueDate=@sFromDueDate+char(10)+'left join CASEEVENTTEXT CET		on (CET.CASEID =CE.CASEID'
										       +char(10)+'                                      and CET.EVENTNO=CE.EVENTNO'
										       +char(10)+'                                      and CET.CYCLE  =CE.CYCLE)'
										       +char(10)+'left join EVENTTEXT ET		on (ET.EVENTTEXTID=CET.EVENTTEXTID)'
						End

						Set @sTableColumn = char(10)+ "CASE WHEN (ET.EVENTTEXTID is not null)" 
									+ char(10) +"	THEN " + @sTableColumn+ "+ '^' + cast(ET.EVENTTEXTID as varchar(11))"
									+char(10)+"	ELSE " + @sTableColumn
									+ char(10) +" END"
					End				
				End
		
				Else If @sColumn='Reference'
				Begin
					Set @sTableColumn='C.CaseReference'
				End

				Else If @sColumn in ('AdHocReference')
				Begin
					If  @bHasReminder=1
					and @bIsAdHoc    =1
						Set @sTableColumn='A.REFERENCE'
					Else
					Set @sTableColumn='NULL'														
				End
		
				Else If @sColumn in ('Description',
						     'EventDescription')
				Begin
					If  @bHasReminder=1
					and @bIsAdHoc    =1
						Set @sTableColumn='coalesce('+
								dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
								dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+
								',A.ALERTMESSAGE)'
					Else
					Set @sTableColumn='isnull('+
							dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
							dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+
							')'
				End		


				Else If @sColumn='DueDate'
				Begin
					--- CE.EVENTDUEDATE are expected to be the same as EMPLOYEEREMINDER.DUEDATE
					--- This redundant data design was intended to cater for the fact that EmployeeReminders can be generated from both a CASEEVENT and an ALERT.
					--- It would not be valid for these Due Dates to be different
					If  @bHasReminder=1
					and @bIsAdHoc    =1
						Set @sTableColumn='isnull(CE.EVENTDUEDATE,A.DUEDATE)'
					Else
					Set @sTableColumn='CE.EVENTDUEDATE'
				End
								

				Else If @sColumn in ('DueDateLatestInGroup', 'DueDescriptionLatestInGroup')
				Begin
					If charindex('group by DD1.CASEID, DDE1.EVENTGROUP) GRP',@sFromDueDate)=0	
					Begin										 
						------------------------------------------------------
						-- Get the latest due date for Events that match the 
						-- Event Group of the main due date being reported on.
						------------------------------------------------------									
						Set @sFromDueDate=@sFromDueDate	+char(10)+'Left Join (select DD1.CASEID, DDE1.EVENTGROUP, max(DD1.EVENTDUEDATE) as EVENTDUEDATE'
										+char(10)+'           from EVENTS DDE1 with (NOLOCK)'
										+char(10)+'           join CASEEVENT DD1 with (NOLOCK) on (DD1.EVENTNO=DDE1.EVENTNO'
										+char(10)+'                                            and DD1.OCCURREDFLAG=0)'
										+char(10)+'           where DDE1.EVENTGROUP  is not null'
										+char(10)+'           and   DD1.EVENTDUEDATE is not null'
										+char(10)+'           group by DD1.CASEID, DDE1.EVENTGROUP) GRP on (GRP.CASEID=CE.CASEID'
										+char(10)+'                                                     and GRP.EVENTGROUP=E.EVENTGROUP)'
										+char(10)+'left join CASEEVENT DD2 with (NOLOCK) on (DD2.CASEID=GRP.CASEID'
										+char(10)+'                                      and DD2.OCCURREDFLAG=0'
										+char(10)+'                                      and DD2.EVENTDUEDATE=GRP.EVENTDUEDATE)'
										+char(10)+'left join EVENTS DDE2 with (NOLOCK)   on (DDE2.EVENTNO=DD2.EVENTNO'
										+char(10)+'                                      and DDE2.EVENTGROUP=GRP.EVENTGROUP)'
										+char(10)+'left join EVENTCONTROL DDEC2 with (NOLOCK) on (DDEC2.CRITERIANO =DD2.CREATEDBYCRITERIA'
										+char(10)+'				                  and DDEC2.EVENTNO=DD2.EVENTNO)'
					End

					If @sColumn='DueDateLatestInGroup'
					Begin
						Set @sTableColumn='DD2.EVENTDUEDATE'
					End

					Else If @sColumn='DueDescriptionLatestInGroup'
					Begin
						Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'DDEC2',@sLookupCulture,@pbCalledFromCentura)
							 	 				  +','+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'DDE2',@sLookupCulture,@pbCalledFromCentura)+')'
					End
				End
		
				If @sColumn='DaysUntilDue'
				Begin
					If  @bHasReminder=1
					and @bIsAdHoc    =1
						Set @sTableColumn='datediff( day, getdate(), coalesce( CE.EVENTDUEDATE, ER.DUEDATE, getdate()))'
					Else
					Set @sTableColumn='datediff( day, getdate(), isnull( CE.EVENTDUEDATE, getdate()))'
				End

				Else If @sColumn='IsCriticalEvent'
				Begin
					If @nCriticalLevel is NULL
					Begin
						Set @sTableColumn="Cast(0 as bit)"
					End
					Else
					Begin
						Set @sTableColumn="convert(bit, CASE WHEN coalesce(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL, 0)>="+cast(@nCriticalLevel as varchar(10))+" THEN 1 ELSE 0 END)"
					End
				End
		
				Else If @sColumn in ('EventCategory',
						     'EventCategoryIconKey')
				Begin
					If @sColumn='EventCategory'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'ECT',@sLookupCulture,@pbCalledFromCentura)
					End
					Else Begin
						Set @sTableColumn='ECT.ICONIMAGEID'
					End
					
					If charindex('left join EVENTCATEGORY ECT',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+'left join EVENTCATEGORY ECT		on (ECT.CATEGORYID=E.CATEGORYID)'
					End	
				End	
		
				Else If @sColumn='EventDefinition'		
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)
				End
		
				Else If @sColumn in ('EventTextOfType',
						     'EventTextOfTypeModifiedDate',
                                                     'EventTextNoType',
						     'EventTextNoTypeModifiedDate')
				Begin
					Set @sTable1='CETT'+@sCorrelationSuffix
					Set @sAddFromString = 'ON ('+@sTable1+'.CASEID'
			
					If CHARINDEX(@sAddFromString, @sFromDueDate)=0
					Begin	
						Set @sFromDueDate=@sFromDueDate	+char(10)+"Left Join (Select CET.CASEID, CET.EVENTNO, CET.CYCLE, ET.EVENTTEXT, ET.LOGDATETIMESTAMP"
										+char(10)+"	      from CASEEVENTTEXT CET with (NOLOCK)"
										+char(10)+"	      join EVENTTEXT ET  with (NOLOCK)on (ET.EVENTTEXTID=CET.EVENTTEXTID"

						-- Check if the EVENTTEXT is being filtered
						If @sQualifier is not null
						Begin
							Set @sFromDueDate=@sFromDueDate+
										+char(10)+"                                                   and ET.EVENTTEXTTYPEID="+@sQualifier+")) "+@sTable1
						End
						Else Begin
							Set @sFromDueDate=@sFromDueDate+
										+char(10)+"                                                   and ET.EVENTTEXTTYPEID is null)) "+@sTable1
						End
						
						Set @sFromDueDate=@sFromDueDate	+char(10)+"			ON ("+@sTable1+".CASEID  = CE.CASEID"
										+char(10)+"			AND "+@sTable1+".EVENTNO = CE.EVENTNO"
										+char(10)+"			AND "+@sTable1+".CYCLE   = CE.CYCLE )"	

					End

					Set @sTableColumn=CASE(@sColumn) WHEN('EventTextOfType')             THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,@sTable1,@sLookupCulture,@pbCalledFromCentura) 
									 WHEN('EventTextOfTypeModifiedDate') THEN @sTable1+'.LOGDATETIMESTAMP'
                                                                         WHEN('EventTextNoType')             THEN dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,@sTable1,@sLookupCulture,@pbCalledFromCentura) 
									 WHEN('EventTextNoTypeModifiedDate') THEN @sTable1+'.LOGDATETIMESTAMP'
							  END
				End				
				Else If @sColumn in ('EventText',
						     'EventTextType',
						     'EventTextModifiedDate')
				Begin
					If charindex('left join CASEEVENTTEXT CET',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+'left join CASEEVENTTEXT CET		on (CET.CASEID =CE.CASEID'
						                               +char(10)+'                                      and CET.EVENTNO=CE.EVENTNO'
						                               +char(10)+'                                      and CET.CYCLE  =CE.CYCLE)'
						                               +char(10)+'left join EVENTTEXT ET		on (ET.EVENTTEXTID=CET.EVENTTEXTID)'
					End
		
					If @sColumn='EventText'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)
					End
			
					Else If @sColumn='EventTextType'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTTEXTTYPE','DESCRIPTION',null,'ETT',@sLookupCulture,@pbCalledFromCentura)
						
						If charindex('left join EVENTTEXTTYPE ETT',@sFromDueDate)=0	
						Begin
							Set @sFromDueDate=@sFromDueDate+char(10)+'left join EVENTTEXTTYPE ETT		on (ETT.EVENTTEXTTYPEID=ET.EVENTTEXTTYPEID)'
						End
					End
			
					Else If @sColumn='EventTextModifiedDate'
					Begin
						Set @sTableColumn='ET.LOGDATETIMESTAMP'
					End				
			
					---------------------------------------
					-- RFC43207
					-- Apply any of the filter restrictions
					-- to the text being returned if the
					-- filter has not already been added.
					---------------------------------------
					If (@nEventNoteTypeKeysOperator is not null and PATINDEX ('%and ET.EVENTTEXT %',       @sWhereFilterEventText)=0)
					or (@nEventNoteTextOperator     is not null and PATINDEX ('%and ET.EVENTTEXTTYPEID %', @sWhereFilterEventText)=0)
					Begin
						If @nEventNoteTextOperator is not null
							Set @sWhereFilterEventText =  "and ET.EVENTTEXT "+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
											   
						If  @nEventNoteTypeKeysOperator is not null
							Set @sWhereFilterEventText =  @sWhereFilterEventText+char(10)+"and ET.EVENTTEXTTYPEID "+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)
					End
				End

				Else If @sColumn='EventProfileKey'
				Begin
					Set @sTableColumn='E.PROFILEREFNO'
				End
		
				Else If @sColumn='IsAdHoc'
				Begin
					If @bHasReminder=1
					and @bIsAdHoc   =1
						Set @sTableColumn='CASE WHEN (A.EMPLOYEENO is not null) THEN cast(1 as bit) ELSE cast(0 as bit) END'
					Else
					Set @sTableColumn='cast(0 as bit)'			
				End						

				Else If @sColumn='NextReminderDate'
				Begin
					If @bHasReminder=1
					and @bIsAdHoc   =1
						Set @sTableColumn='isnull(CE.DATEREMIND,A.ALERTDATE)'
					Else
					Set @sTableColumn='CE.DATEREMIND'								
				End				

				Else If @sColumn='GoverningEventDate'
				Begin
					Set @sTableColumn='isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE)'

					If charindex('left join CASEEVENT CE1',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate  +char(10)+'left join DUEDATECALC DD		on (DD.CRITERIANO=CE.CREATEDBYCRITERIA'
										 +char(10)+'					and DD.EVENTNO   =CE.EVENTNO'
										 +char(10)+'					and DD.FROMEVENT =CE.GOVERNINGEVENTNO'
										 +char(10)+'					and DD.COMPARISON  is null'
										 +char(10)+'                                    and DD.COUNTRYCODE is null'
										 +char(10)+'					and DD.CYCLENUMBER=(select max(DD1.CYCLENUMBER) from DUEDATECALC DD1 where DD1.CRITERIANO=DD.CRITERIANO and DD1.EVENTNO=DD.EVENTNO and DD1.CYCLENUMBER<=CE.CYCLE and DD1.FROMEVENT=DD.FROMEVENT and DD1.COMPARISON is null))'
										 +char(10)+'left join CASEEVENT CE1		on (CE1.CASEID =CE.CASEID'
										 +char(10)+'					and CE1.EVENTNO=CE.GOVERNINGEVENTNO'
										 +char(10)+'					and CE1.CYCLE=CASE(DD.RELATIVECYCLE)'
										 +char(10)+'					                WHEN(0) THEN CE.CYCLE'
										 +char(10)+'					                WHEN(1) THEN CE.CYCLE-1'
										 +char(10)+'					                WHEN(2) THEN CE.CYCLE+1'
										 +char(10)+'					                WHEN(3) THEN 1'
										 +char(10)+'							        ELSE (	select max(CE2.CYCLE)'
										 +char(10)+'									from CASEEVENT CE2'
										 +char(10)+'									where CE2.CASEID=CE.CASEID'
										 +char(10)+'									and CE2.EVENTNO=CE.GOVERNINGEVENTNO)'
										 +char(10)+'					              END)'
					End						
				End

				Else If @sColumn in ('GoverningEventDescription',
						     'GoverningEventDefinition')
				Begin										
					If @sColumn='GoverningEventDescription'
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E1',@sLookupCulture,@pbCalledFromCentura)
					End
					Else Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E1',@sLookupCulture,@pbCalledFromCentura)
					End					
				
					If charindex('left join EVENTS E1',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+'left join EVENTS E1		on (E1.EVENTNO=CE.GOVERNINGEVENTNO)'
					End											
				End						

				Else If @sColumn='IsEnteredDueDate'
				Begin
					If @bHasReminder=1
					and @bIsAdHoc   =1
						Set @sTableColumn='CASE WHEN(A.DUEDATE is not null) THEN cast(1 as bit) ELSE cast(CE.DATEDUESAVED as bit) END'
					Else
					Set @sTableColumn='CAST(CE.DATEDUESAVED as bit)'								
				End					
				
				Else If @sColumn in ('EventImportanceLevel')
				Begin
					Set @sTableColumn='isnull(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL)'
				End		
	
				Else If @sColumn in ('EventImportanceDescription')
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura)							

					If charindex('left join IMPORTANCE IMPC',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+'left join IMPORTANCE IMPC		on (IMPC.IMPORTANCELEVEL = ISNULL(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL))'
					End						
				End	

				Else If @sColumn in ('ImportanceLevel')
				Begin
					If @bIsAdHoc =1
					and charindex('ALERT A',@sFromDueDate)>0	-- RFC49300
					Begin
						Set @sTableColumn='COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL, A.IMPORTANCELEVEL)'
					End
					Else 
					Begin
						Set @sTableColumn='COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL)'
					End
				End		
	
				Else If @sColumn in ('ImportanceDescription')
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura)							

					If charindex('left join IMPORTANCE IMPC',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+'left join IMPORTANCE IMPC	on (IMPC.IMPORTANCELEVEL ='

						If @bIsAdHoc =1
						and charindex('ALERT A',@sFromDueDate)>0	-- RFC49300
						Begin
							Set @sFromDueDate=@sFromDueDate+'COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL, A.IMPORTANCELEVEL))'
						End
						Else 
						Begin
							Set @sFromDueDate=@sFromDueDate+'COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL))'
						End
					End						
				End	

				Else If @sColumn in ('DueEventStaffKey')
				Begin
					Set @sTableColumn='CE.EMPLOYEENO'
				End	

				Else If @sColumn in ('DueEventStaff',
						     'DueEventStaffCode')
				Begin
					If charindex('left join NAME NEMPL',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+'left join NAME NEMPL		on (NEMPL.NAMENO = CE.EMPLOYEENO)'
					End	
				
					If @sColumn in ('DueEventStaff')
					Begin
						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NEMPL.NAMENO, null)'
					End
					Else Begin
						Set @sTableColumn='NEMPL.NAMECODE'
					End
				End					

				Else If @sColumn in ('HasInstructions') --RFC2982
				Begin
					If charindex('left join (select distinct C.CASEID, D.DUEEVENTNO AS EVENTNO',@sFromDueDate)=0	
					Begin
						Set @sFromDueDate=@sFromDueDate+char(10)+
						'left join (select distinct C.CASEID, D.DUEEVENTNO AS EVENTNO'+char(10)+
						'	   From CASES C'+char(10)+
						'	   cross join INSTRUCTIONDEFINITION D'+char(10)+
						'	   left join CASEEVENT P	on (P.CASEID=C.CASEID'+char(10)+
						'					and P.EVENTNO=D.PREREQUISITEEVENTNO)'+char(10)+
							   -- Available for due events
						'	   where D.AVAILABILITYFLAGS&4=4'+char(10)+
						'	   and	 D.DUEEVENTNO IS NOT NULL'+char(10)+
							   -- Either the instruction has no prerequisite event
						 	   -- or the prerequisite event exists
						'	   and 	(D.PREREQUISITEEVENTNO IS NULL OR'+char(10)+
						'	         P.EVENTNO IS NOT NULL'+char(10)+
						'		)'+char(10)+
						'	   ) D			on (D.CASEID=CE.CASEID'+char(10)+
						'				and D.EVENTNO=CE.EVENTNO)'
					End	
				
					Set @sTableColumn='CASE WHEN(D.CASEID IS NOT NULL) then cast(1 as bit) else cast(0 as bit) END'
				End
			 				
				-- Selecting Reminder columns 
				Else If @sColumn in ('ReminderNameKey',
						     'ReminderDisplayName',
						     'ReminderFormalName',
						     'ReminderNameCode',
						     'ReminderReplyEmail',
						     'ReminderDateCreated',
						     'ReminderDate',	
						     'ReminderMessage',
						     'ReminderDateUpdated',
						     'ReminderHoldUntilDate',
						     'ReminderComment',
						     'LastModified',
						     'RowNameKey',
						     'IsRead')
				Begin
					If charindex('left join EMPLOYEEREMINDER ER',@sFromDueDate)=0	
					and (@bHasReminder = 0 or @bHasReminder is null)
					Begin
						Set @sFromDueDate=@sFromDueDate  +char(10)+"left join EMPLOYEEREMINDER ER	on (ER.CASEID = CE.CASEID"
										 +char(10)+"					and ER.EVENTNO = CE.EVENTNO"
										 +char(10)+"					and ER.CYCLENO = CE.CYCLE)"
						
										
					End	

					If @sColumn in ('RowNameKey','ReminderNameKey')
					Begin
						Set @sTableColumn='ER.EMPLOYEENO'						
					End								
					
					If @sColumn='LastModified'
					Begin
						Set @sTableColumn='ER.LOGDATETIMESTAMP'
					End		

					If @sColumn='IsRead'
					Begin
						Set @sTableColumn='CAST(ER.READFLAG as bit)'						
					End		
	
					Else If @sColumn in ('ReminderDisplayName',
							     'ReminderFormalName',
							     'ReminderNameCode',
							     'ReminderReplyEmail')
					Begin
						If charindex('left join NAME ERN',@sFromDueDate)=0	
						Begin
							Set @sFromDueDate=@sFromDueDate+char(10)+'left join NAME ERN		on (ERN.NAMENO=ER.EMPLOYEENO)'
						End		
	
						If @sColumn='ReminderDisplayName'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, NULL)'
						End
						Else If
						@sColumn='ReminderFormalName'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, COALESCE(ERN.NAMESTYLE, ERC.NAMESTYLE, 7101))'	
	
							If charindex('left join COUNTRY ERC',@sFromDueDate)=0
							Begin
								Set @sFromDueDate=@sFromDueDate+char(10)+'left join COUNTRY ERC		on (ERC.COUNTRYCODE=ERN.NATIONALITY)'
							End
						End
						Else If
						@sColumn='ReminderNameCode' 
						Begin
							Set @sTableColumn='ERN.NAMECODE'	
						End									
						Else If @sColumn='ReminderReplyEmail'					
						Begin
							If @bExternalUser = 1
							Begin
								Set @sTableColumn='dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION)'
	
								If charindex('left join CASENAME CN',@sFromDueDate)=0
								Begin
									Set @sFromDueDate=@sFromDueDate  +char(10)+"left join CASENAME CN		on (CN.CASEID = ER.CASEID"
													 +char(10)+"					and CN.NAMETYPE = 'EMP'"
													 +char(10)+"					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
													 +char(10)+"left join NAME NCN			on (NCN.NAMENO = CN.NAMENO)"
													 +char(10)+"					and CN.NAMETYPE = 'EMP'"
													 +char(10)+"left join TELECOMMUNICATION ML  	on (ML.TELECODE = NCN.MAINEMAIL)"																				
								End																				
							End
							Else Begin
								Set @sTableColumn='S.COLCHARACTER'
	
								If charindex('left join SITECONTROL S',@sFromDueDate)=0
								Begin
									Set @sFromDueDate=@sFromDueDate+char(10)+"left join SITECONTROL S	on S.CONTROLID='Reminder Reply Email'"																		
								End								
							End		
						End					
					End			
	
					Else If @sColumn='ReminderDateCreated'
					Begin
						Set @sTableColumn='ER.MESSAGESEQ'	
					End									
	

					Else If @sColumn='ReminderDate'
					Begin
						Set @sTableColumn='ER.REMINDERDATE'
					End	
	
					Else If @sColumn='ReminderMessage'
					Begin
						Set @sTableColumn='cast(isnull('+
								dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','LONGMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+', '+
								dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+
								') as nvarchar(max))'
					End				 
	
					Else If @sColumn='ReminderDateUpdated'
					Begin
						Set @sTableColumn='ER.DATEUPDATED'								
					End
	
					Else If @sColumn='ReminderHoldUntilDate'
					Begin
						Set @sTableColumn='ER.HOLDUNTILDATE'								
					End					
	
					Else If @sColumn='ReminderComment'
					Begin
						Set @sTableColumn='ER.COMMENTS'								
					End				 					 	
				End

				Else If @sColumn='IsPastDue'
				Begin
					If  @bHasReminder=1
					and @bIsAdHoc   =1
						Set @sTableColumn='CASE WHEN(isnull(A.DUEDATE,CE.EVENTDUEDATE)'+dbo.fn_ConstructOperator(8,@Date,convert(nvarchar,getdate(),112), NULL,0)+') THEN 1 ELSE 0 END' 
					Else
					Set @sTableColumn='CASE WHEN(CE.EVENTDUEDATE'+dbo.fn_ConstructOperator(8,@Date,convert(nvarchar,getdate(),112), NULL,0)+') THEN 1 ELSE 0 END' 
				End

				Else If @sColumn in ('AdHocNameKey',
						     'AdHocDateCreated',
						     'AdHocDisplayName',
						     'AdHocNameCode',
						     'AdHocMessage',
						     'AdHocResolvedOn',
						     'AdHocStopOn',
						     'AdHocDeleteOn',
						     'AdHocEmailSubject',
						     'AdHocCheckSum',
						     'NameReferenceKey',
						     'NameReference',
						     'NameReferenceCode')	
				Begin
					If @bHasReminder=0
					or @bIsAdHoc    =0
					Begin
						Set @sTableColumn='NULL'
					End
					Else 
					If @sColumn='AdHocNameKey'		
					Begin
						Set @sTableColumn='A.EMPLOYEENO'
					End	
					
					Else If @sColumn='AdHocDateCreated'
					Begin
						Set @sTableColumn='convert(nvarchar(25),A.ALERTSEQ,126)'
					End

					Else If @sColumn in ('AdHocDisplayName',
							     'AdHocNameCode')		
					Begin
						If charindex('left join NAME NDA',@sFromDueDate)=0
						Begin
							Set @sFromDueDate=@sFromDueDate+char(10)+'left join NAME NDA on (NDA.NAMENO=A.EMPLOYEENO)'
						End		
					
						If @sColumn='AdHocDisplayName'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NDA.NAMENO, NULL)'
						End
						Else Begin
							Set @sTableColumn='NDA.NAMECODE'
						End								
					End	

					Else If @sColumn='AdHocMessage'		
					Begin
						Set @sTableColumn='A.ALERTMESSAGE'
					End	

					Else If @sColumn='AdHocResolvedOn'		
					Begin
						Set @sTableColumn='A.DATEOCCURRED'
					End					

					Else If @sColumn='AdHocStopOn'		
					Begin
						Set @sTableColumn='A.STOPREMINDERSDATE'
					End	
					
					Else If @sColumn='AdHocDeleteOn'		
					Begin
						Set @sTableColumn='A.DELETEDATE'
					End	

					Else If @sColumn='AdHocEmailSubject'		
					Begin
						Set @sTableColumn='A.EMAILSUBJECT'
					End	
					Else If @sColumn='AdHocCheckSum'
					Begin
						-- Get the comma separated list of all comparable colums
						-- of the Alert table
						exec dbo.ip_GetComparableColumns
								@psColumns 	= @sAdHocChecksumColumns output, 
								@psTableName 	= 'ALERT',
								@psAlias 	= 'A'
				
						Set @sTableColumn='CHECKSUM('+@sAdHocChecksumColumns+')'														
			
					End
				
					Else If @sColumn='NameReferenceKey'		
					Begin
						Set @sTableColumn='A.NAMENO'
					End
					
					Else If @sColumn in ('NameReference',
							     'NameReferenceCode')		
					Begin
						If charindex('left join NAME NRA on (NRA.NAMENO=A.NAMENO)',@sFromDueDate)=0
						Begin
							Set @sFromDueDate=@sFromDueDate+char(10)+'left join NAME NRA on (NRA.NAMENO=A.NAMENO)'
						End		
					
						If @sColumn='NameReference'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NRA.NAMENO, NULL)'
						End
						Else Begin
							Set @sTableColumn='NRA.NAMECODE'
						End										
					End
				End


				
				If datalength(@sPublishName)>0
				Begin
					Set @sSelectDueDate=@sSelectDueDate+nullif(',', ',' + @sSelectDueDate)+@sTableColumn+' as ['+@sPublishName+']'					
				End
				Else Begin
					Set @sPublishName=NULL
				End
			End
	
			-- Construction of the Ad Hoc Due Dates 'Select' clause.
			If((@bHasReminder=1 and @bIsAdHoc = 1 and @bIsEvent = 0)
			or (@bHasReminder=1 and @bIsAdHoc = 1 and @bIsEvent = 1 and @bHasCase =0)
			or (@bHasReminder=0 and @bIsAdHoc = 1))
			Begin
				If @sColumn='NULL'		
				Begin
					Set @sTableColumn='NULL'
				End
				If @sColumn='DueDateRowKey'
				Begin					
					---RFC9998	Add Checksum to DueDateRowKey	
					If @sAdHocChecksumColumns is null
					Begin
						exec dbo.ip_GetComparableColumns
								@psColumns 	= @sAdHocChecksumColumns output, 
								@psTableName 	= 'ALERT',
							        @psAlias 	= 'A'
					End    

					If @bIsEvent=0
					or @bHasCase=0
					or @bHasReminder=0
					Begin
						Set @sTableColumn="'A' + '^'+"
							+char(10)+"cast(A.EMPLOYEENO as nvarchar(11)) + '^' +" 
							+char(10)+"convert(nvarchar(25),A.ALERTSEQ, 126) + '^' +"
							+char(10)+"convert(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+"))"	
						
						-- Do not include a union to EMPLOYEEREMINDER 
						-- when context is Ad Hoc Date related
						If @pnQueryContextKey not in (160,163,164) or (@pnQueryContextKey = 160 and @bHasReminder = 1)
						Begin	
							Set @sTableColumn=@sTableColumn + " + '^' +"
							+char(10)+"cast(ER.EMPLOYEENO as varchar(11))"
						End
					End
					Else If  @bHasReminder=1
					     and @bIsEvent    =1
					     and @bIsAdHoc    =1
					Begin
						Set @sTableColumn=
							 char(10)+"CASE WHEN(A.EMPLOYEENO is not null)"
							+char(10)+"	THEN 'A' + '^'+"
							+char(10)+"		cast(A.EMPLOYEENO as nvarchar(11)) + '^' +" 
							+char(10)+"		convert(nvarchar(25),A.ALERTSEQ, 126) + '^' +"
							+char(10)+"		convert(nvarchar(20),CHECKSUM("+@sAdHocChecksumColumns+"))"
							+char(10)+"	ELSE 'C' + '^'+"
							+char(10)+"		cast(C.CaseKey as varchar(11)) + '^' +" 
							+char(10)+"		cast(CE.EVENTNO as varchar(11)) + '^' +" 
							+char(10)+"		cast(CE.CYCLE as varchar(10))" 	

                                                Set @sTableColumn=@sTableColumn + char(10)+"END"
                                                
                                                -- Do not include a union to EMPLOYEEREMINDER 
						-- when context is Ad Hoc Date related
						If @pnQueryContextKey not in (163,164)
						Begin	
							Set @sTableColumn=@sTableColumn + " + '^' +"
							+char(10)+"		cast(ER.EMPLOYEENO as varchar(11))"
						End						
					End
				End
		
				Else If @sColumn='Reference'
				Begin   
				        If charindex('left join NAME NRA on (NRA.NAMENO=A.NAMENO)',@sUnionFromDueDate)=0
					Begin
						Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+'left join NAME NRA on (NRA.NAMENO=A.NAMENO)'
					End
					If @bIsGeneral = 1
					and @bHasCase = 0
					Begin
						Set @sTableColumn='ISNULL(dbo.fn_FormatNameUsingNameNo(NRA.NAMENO, NULL),A.REFERENCE)'						
					End
					Else Begin						
						Set @sTableColumn='isnull(C.CaseReference, ISNULL(dbo.fn_FormatNameUsingNameNo(NRA.NAMENO, NULL),A.REFERENCE))'
					End										
				End
				
				Else If @sColumn='NameReferenceKey'		
				Begin
					Set @sTableColumn='A.NAMENO'
				End
				
				Else If @sColumn in ('NameReference',
						     'NameReferenceCode')		
				Begin
					If charindex('left join NAME NRA on (NRA.NAMENO=A.NAMENO)',@sUnionFromDueDate)=0
					Begin
						Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+'left join NAME NRA on (NRA.NAMENO=A.NAMENO)'
					End		
				
					If @sColumn='NameReference'
					Begin
						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NRA.NAMENO, NULL)'
					End
					Else Begin
						Set @sTableColumn='NRA.NAMECODE'
					End										
				End

				Else If @sColumn='AdHocReference'
				Begin
					Set @sTableColumn='A.REFERENCE'														
				End

				
				Else If @sColumn='AdHocCheckSum'
				Begin
					-- Get the comma separated list of all comparable colums
					-- of the Alert table
					exec dbo.ip_GetComparableColumns
							@psColumns 	= @sAdHocChecksumColumns output, 
							@psTableName 	= 'ALERT',
							@psAlias 	= 'A'
			
					Set @sTableColumn='CHECKSUM('+@sAdHocChecksumColumns+')'														
		
				End
		
				Else If @sColumn='Description'
				Begin
					Set @sTableColumn='A.ALERTMESSAGE'
				End		
		
				Else If @sColumn='DueDate'
				Begin
					Set @sTableColumn='A.DUEDATE'
				End
		
				Else If @sColumn='IsCriticalEvent'
				Begin
					Set @sTableColumn='cast(0 as bit)'
				End
				Else If @sColumn in ('EventTextOfType',
						     'EventTextOfTypeModifiedDate',
						     'EventDescription',
						     'EventCategory',
						     'EventCategoryIconKey',
						     'EventDefinition',
						     'EventText',
						     'EventTextType',
						     'EventTextModifiedDate',
						     'EventProfileKey',
						     'DueDateLatestInGroup',
						     'DueDescriptionLatestInGroup',
                                                     'EventTextNoType',
						     'EventTextNoTypeModifiedDate')
				Begin
					Set @sTableColumn='NULL'
				End

				Else If @sColumn in ('DueEventStaffKey',
						     'DueEventStaff',	
						     'DueEventStaffCode')
				Begin
					Set @sTableColumn='NULL'
				End
		
				Else If @sColumn='IsAdHoc'
				Begin
					Set @sTableColumn='cast(1 as bit)'			
				End		

				Else If @sColumn in ('GoverningEventDate',
						     'GoverningEventDescription',
						     'GoverningEventDefinition',
						     'EventImportanceLevel',
						     'EventImportanceDescription')
				Begin
					Set @sTableColumn='NULL'			
				End					

				Else If @sColumn in ('NextReminderDate')
				Begin
					Set @sTableColumn='A.ALERTDATE'
				End 

				Else If @sColumn in ('ImportanceLevel')
				Begin
					Set @sTableColumn='A.IMPORTANCELEVEL'
				End		
	
				Else If @sColumn in ('ImportanceDescription')
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura)							

					If charindex('left join IMPORTANCE IMPC',@sUnionFromDueDate)=0	
					Begin
						Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+'left join IMPORTANCE IMPC		on (IMPC.IMPORTANCELEVEL = A.IMPORTANCELEVEL)'
					End						
				End	

				Else If @sColumn='IsEnteredDueDate'
				Begin
					Set @sTableColumn='CAST(1 as bit)'			
				End	

				Else If @sColumn='HasInstructions' --RFC2982
				Begin
					Set @sTableColumn='CAST(0 as bit)'			
				End	

				Else If @sColumn='IsPastDue'
					Begin
					Set @sTableColumn='CASE WHEN(A.DUEDATE '+dbo.fn_ConstructOperator(8,@Date,convert(nvarchar,getdate(),112), NULL,0)+') THEN 1 ELSE 0 END'	 
				End

				-- Selecting Reminder columns 
				Else If @sColumn in ('ReminderNameKey',
						     'ReminderDisplayName',
						     'ReminderFormalName',
						     'ReminderNameCode',
						     'ReminderReplyEmail',
						     'ReminderDateCreated',
						     'ReminderDate',	
						     'ReminderMessage',
						     'ReminderDateUpdated',
						     'ReminderHoldUntilDate',
						     'ReminderComment',
						     'DaysUntilDue',
						     'LastModified',
						     'IsRead')
				Begin
					If charindex('left join EMPLOYEEREMINDER ER',@sUnionFromDueDate)=0	
					and (@bHasReminder = 0 or @bHasReminder is null)
					Begin
						Set @sUnionFromDueDate=@sUnionFromDueDate +char(10)+"left join EMPLOYEEREMINDER ER	on (ER.ALERTNAMENO = A.EMPLOYEENO"
											  +char(10)+"					and ER.SEQUENCENO = A.SEQUENCENO"
											  +char(10)+"					AND ER.EVENTNO IS NULL)"
					End	

					If @sColumn='ReminderNameKey'
					Begin
						Set @sTableColumn='ER.EMPLOYEENO'					
					End	

					If @sColumn='LastModified'
					Begin
						Set @sTableColumn='ER.LOGDATETIMESTAMP'
					End		

					If @sColumn='IsRead'
					Begin
						Set @sTableColumn='CAST(ER.READFLAG as bit)'						
					End	
	
					If @sColumn='DaysUntilDue'
					Begin
						Set @sTableColumn='datediff( day, getdate(), isnull( ER.DUEDATE, getdate()))'
					End

					Else If @sColumn in ('ReminderDisplayName',
							     'ReminderFormalName',
							     'ReminderNameCode',
							     'ReminderReplyEmail')
					Begin
						If charindex('left join NAME ERN',@sUnionFromDueDate)=0	
						Begin
							Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+'left join NAME ERN		on (ERN.NAMENO=ER.EMPLOYEENO)'
						End		
	
						If @sColumn='ReminderDisplayName'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, NULL)'			
						End
						Else If
						@sColumn='ReminderFormalName'
						Begin
							Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, COALESCE(ERN.NAMESTYLE, ERC.NAMESTYLE, 7101))'
	
							If charindex('left join COUNTRY ERC',@sUnionFromDueDate)=0
							Begin
								Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+'left join COUNTRY ERC		on (ERC.COUNTRYCODE=ERN.NATIONALITY)'
							End
						End
						Else If
						@sColumn='ReminderNameCode' 
						Begin
							Set @sTableColumn='ERN.NAMECODE'	
						End								
						Else If
						@sColumn='ReminderReplyEmail'					
						Begin
							If @bExternalUser = 1
							Begin
								Set @sTableColumn='dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION)'
	
								If charindex('left join CASENAME CN',@sUnionFromDueDate)=0
								Begin
									Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+"left join CASENAME CN		on (CN.CASEID = ER.CASEID"
													 	 +char(10)+"					and CN.NAMETYPE = 'EMP'"
													 	 +char(10)+"					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
													 	 +char(10)+"left join NAME NCN			on (NCN.NAMENO = CN.NAMENO)"
													 	 +char(10)+"					and CN.NAMETYPE = 'EMP'"
													 	 +char(10)+"left join TELECOMMUNICATION ML  	on (ML.TELECODE = NCN.MAINEMAIL)"																				
								End																				
							End
							Else Begin
								Set @sTableColumn='US.COLCHARACTER'
	
								If charindex('left join SITECONTROL US',@sUnionFromDueDate)=0
								Begin
									Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+"left join SITECONTROL US	on US.CONTROLID='Reminder Reply Email'"																		
								End								
							End		
						End					
					End							
	
					Else If @sColumn='ReminderDateCreated'
					Begin
						Set @sTableColumn='ER.MESSAGESEQ'							
					End	
	
					Else If @sColumn='IsPastDue'
					Begin
							Set @sTableColumn='CASE WHEN(A.DUEDATE '+dbo.fn_ConstructOperator(8,@Date,convert(nvarchar,getdate(),112), NULL,0)+') THEN 1 ELSE 0 END'	 
						End										
	
					Else If @sColumn='ReminderDate'
					Begin
						Set @sTableColumn='ER.REMINDERDATE'					
					End						
	
					Else If @sColumn='ReminderMessage'
					Begin
						Set @sTableColumn='cast(isnull('+
								dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','LONGMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+', '+
								dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+
								') as nvarchar(max))'						
					End	
	
					Else If @sColumn='ReminderDateUpdated'
					Begin
						Set @sTableColumn='ER.DATEUPDATED'							
					End					 
	
					Else If @sColumn='ReminderHoldUntilDate'
					Begin
						Set @sTableColumn='ER.HOLDUNTILDATE'						
					End	
	
					Else If @sColumn='ReminderComment'
					Begin
						Set @sTableColumn='ER.COMMENTS'								
					End				 					
				End							

				Else If @sColumn='AdHocNameKey'		
				Begin
					Set @sTableColumn='A.EMPLOYEENO'
				End	
				
				Else If @sColumn='AdHocDateCreated'
				Begin
					Set @sTableColumn='convert(nvarchar(25),A.ALERTSEQ,126)'
				End

				Else If @sColumn in ('AdHocDisplayName',
						     'AdHocNameCode')		
				Begin
					If charindex('left join NAME NDA',@sUnionFromDueDate)=0
					Begin
						Set @sUnionFromDueDate=@sUnionFromDueDate+char(10)+'left join NAME NDA		on (NDA.NAMENO=A.EMPLOYEENO)'
					End		
				
					If @sColumn='AdHocDisplayName'
					Begin
						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NDA.NAMENO, NULL)'
					End
					Else Begin
						Set @sTableColumn='NDA.NAMECODE'
					End								
				End	

				Else If @sColumn='AdHocMessage'		
				Begin
					Set @sTableColumn='A.ALERTMESSAGE'
				End	

				Else If @sColumn='AdHocResolvedOn'		
				Begin
					Set @sTableColumn='A.DATEOCCURRED'
				End					

				Else If @sColumn='AdHocStopOn'		
				Begin
					Set @sTableColumn='A.STOPREMINDERSDATE'
				End	
				
				Else If @sColumn='AdHocDeleteOn'		
				Begin
					Set @sTableColumn='A.DELETEDATE'
				End	

				Else If @sColumn='AdHocEmailSubject'		
				Begin
					Set @sTableColumn='A.EMAILSUBJECT'
				End	
				
				If @sColumn = 'IsEditable'
				and @bHasCase = 1
				Begin
					If @bRowLevelSecurity = 1
					Begin
						Set @sTableColumn='CASE WHEN(RS.DELETEALLOWED=1) THEN convert(bit,1) 
								        WHEN(RS.INSERTALLOWED=1) THEN convert(bit,1) 
								        WHEN(RS.UPDATEALLOWED=1) THEN convert(bit,1) 
								        WHEN RS.SECURITYFLAG IS NULL THEN convert(bit,1)
									ELSE convert(bit,0)
								   END
								&
								   CASE	WHEN convert(bit,(RUC.SECURITYFLAG&2))=1 THEN convert(bit,1) 
									WHEN convert(bit,(RUC.SECURITYFLAG&4))=1 THEN convert(bit,1) 
									WHEN convert(bit,(RUC.SECURITYFLAG&8))=1 THEN convert(bit,1) 
									WHEN RUC.SECURITYFLAG IS NULL THEN 
										CASE WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 2)) = 1 THEN convert(bit,1)
										     WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 4)) = 1 THEN convert(bit,1)
										     WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 8)) = 1 THEN convert(bit,1)
										     ELSE convert(bit,0)
										END
									ELSE convert(bit,0) 
								   END
'
					End
					If @bRowLevelSecurity = 0
					Begin
						Set @sTableColumn = 'CASE WHEN convert(bit,(RUC.SECURITYFLAG&2))=1 THEN convert(bit,1) 
									  WHEN convert(bit,(RUC.SECURITYFLAG&4))=1 THEN convert(bit,1) 
									  WHEN convert(bit,(RUC.SECURITYFLAG&8))=1 THEN convert(bit,1) 
									  WHEN RUC.SECURITYFLAG IS NULL THEN 
										CASE WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 2)) = 1 THEN convert(bit,1)
										     WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 4)) = 1 THEN convert(bit,1)
										     WHEN (convert(bit,'+convert(nvarchar,Isnull(@nCaseAccessSecurityFlag,15))+' & 8)) = 1 THEN convert(bit,1)
										     ELSE convert(bit,0) 
										END
									  ELSE convert(bit,0) 
								     END'
					End
				End	
				-- If the column is being published then concatenate it to the Select list

				If datalength(@sPublishName)>0
				Begin   
					Set @sUnionSelectDueDate = @sUnionSelectDueDate+nullif(',', ',' + @sUnionSelectDueDate)+@sTableColumn+' as ['+@sPublishName+']'
				End
				Else Begin
					Set @sPublishName=NULL
				End
			End			
				
		End
		-- If Procedure Name is csw_ListCase
		Else 
		If  @sProcedureName = 'csw_ListCase'
		and @bHasCase = 1
		Begin	
			-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
			-- column names to avoide SQL error:
			Set @sTableColumn=CASE WHEN @nDataFormatID = 9107 
					       -- cast text type columns as nvarchar(4000) to avoid SQL error:
					       THEN 'CAST(C.' + dbo.fn_ConvertToAlphanumeric(@sPublishName)+' as nvarchar(4000))'	
					       ELSE 'C.' + dbo.fn_ConvertToAlphanumeric(@sPublishName)
					  END

			-- If the column is being published then concatenate it to the both Select list - 
			-- Event Due Dates Select and Ad Hoc Due Dates Select.

			If datalength(@sPublishName)>0
			Begin
				Set @sSelectDueDate=@sSelectDueDate+nullif(',', ',' + @sSelectDueDate)+@sTableColumn+' as ['+@sPublishName+']'	
				Set @sUnionSelectDueDate = @sUnionSelectDueDate+nullif(',', ',' + @sUnionSelectDueDate)+@sTableColumn+' as ['+@sPublishName+']'
			End
			Else Begin
				Set @sPublishName=NULL
			End

			-- Any case column that is sort only needs to be produced by the inner SQL 
			-- for sorting by the outer SQL.
			If @sPublishName is null
			Begin  
				Set @sPublishName=@sColumn + @sCorrelationSuffix   
				
				-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
				-- publish names to avoide SQL error:
				Set @sPublishName=dbo.fn_ConvertToAlphanumeric(@sPublishName)	
			End	
			
			-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
			-- publish names to avoide SQL error:			
			Set @sPublishNameForXML=dbo.fn_ConvertToAlphanumeric(@sPublishName)		

			Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + 
			'	<Column ID="' + @sColumn + '" ProcedureName="' + @sProcedureName + '" Qualifier="' + @sQualifier + '" PublishName="' + @sPublishNameForXML + '" />'
		End		
		-- RFC8114 management of non case columns when executing a query that is not case related but has case related columns selected in presentation.
		Else If  @sProcedureName = 'csw_ListCase'
		and @bHasCase = 0
		Begin	
			-- Explicitly set the table column to null for case related columns when returning non case related results
			-- This is to cater for the fact that the calling code has already a list of select columns by executing ip_ListSearchRequirements, and expects the list
			-- of columns returned here has same number of columns.
			Set @sTableColumn='NULL'

			-- If the column is being published then concatenate it to the both Select list - 
			-- Event Due Dates Select and Ad Hoc Due Dates Select.

			If datalength(@sPublishName)>0
			Begin
				Set @sSelectDueDate=@sSelectDueDate+nullif(',', ',' + @sSelectDueDate)+@sTableColumn+' as ['+@sPublishName+']'	
				Set @sUnionSelectDueDate = @sUnionSelectDueDate+nullif(',', ',' + @sUnionSelectDueDate)+@sTableColumn+' as ['+@sPublishName+']'
			End
			Else Begin
				Set @sPublishName=NULL
			End

			-- Any case column that is sort only needs to be produced by the inner SQL 
			-- for sorting by the outer SQL.
			If @sPublishName is null
			Begin  
				Set @sPublishName=@sColumn + @sCorrelationSuffix   
				
				-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
				-- publish names to avoide SQL error:
				Set @sPublishName=dbo.fn_ConvertToAlphanumeric(@sPublishName)	
			End	
			
			-- Remove spaces, quotes, dots, and any special characters from the Derived Table 
			-- publish names to avoide SQL error:			
			Set @sPublishNameForXML=dbo.fn_ConvertToAlphanumeric(@sPublishName)		

		End		
		
		-- If the column is to be sorted on then save the name of the table column along
		-- with the sort details so that later the Order By can be constructed in the correct sequence

		If @nOrderPosition>0
		and @nErrorCode=0
		Begin
			-- RFC7674 Only include sort columns related to Cases if those specific
			--         columns have been included in the Select list
			If  @sProcedureName = 'csw_ListCase'
			and @bHasCase = 1
			Begin
				Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
				values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)
			End
			Else If  @sProcedureName <> 'csw_ListCase'
			Begin
				Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
				values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)
			End

			Set @nErrorCode = @@ERROR
			Set @bOrderByDefined=1
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

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
End

-- RFC9104
-- If no ORDER BY column defined
-- then default to first column
If  @nErrorCode=0
and @bOrderByDefined=0
Begin

	Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
	values(1, @sFirstTableColumn, @sFirstPublishName, @nFirstColumnNo, 'A')

	Set @nErrorCode = @@ERROR
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE ORDER BY       ****/
/****                                       ****/
/***********************************************/

If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrderDueDate= 	ISNULL(NULLIF(@sOrderDueDate+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position			

	If @sOrderDueDate is not null
	Begin
		Set @sOrderDueDate = ' Order by ' + @sOrderDueDate
	End

	Set @nErrorCode=@@Error
End

-- Close the <OutputRequest> tag to be able to pass constructed output requests to the List Case procedures.
If @nErrorCode = 0
Begin   
	Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + '	</OutputRequests>'
End

-- Implement validation to ensure that the @sCaseXMLOutputRequests has not not overflown.
If @nErrorCode = 0 
and right(@sCaseXMLOutputRequests, 17) <> '</OutputRequests>'
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP46', 'There are more Case columns selected than the system is able to process. Please reduce the number of columns selected and retry.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

-- The Cases derived table needs only be constructed when the @bHasCase = 1.
If  @nErrorCode = 0
and @bHasCase = 1
Begin
	-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
	-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
	-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
	-- table that may hold the filtered list of cases.

	
	exec @nErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sWhereFilter	  	OUTPUT, 			
						@psTempTableName 	= @sCurrentTable	OUTPUT,	
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= @pbCalledFromCentura			

	
	-- Check to see if any of the required columns are ones that cannot be incorporated into the main SELECT
	-- being constructed.  If not then the additional details will be loaded into a temporary table for later
	-- inclusion into the main SELECT
	
	If @nErrorCode=0
	Begin
		exec @nErrorCode=dbo.csw_GetExtendedCaseDetails	@psWhereFilter		= @sWhereFilter	  	OUTPUT, 			
								@psTempTableName 	= @sCurrentTable	OUTPUT,	
								@pnUserIdentityId	= @pnUserIdentityId,	
								@psCulture		= @psCulture,	
								@pbExternalUser		= @bExternalUser,
								@pnQueryContextKey	= @pnQueryContextKey,
								@ptXMLOutputRequests	= @sCaseXMLOutputRequests,
								@pbCalledFromCentura	= @pbCalledFromCentura
	End
	
	
	-- Construct the "Select", "From" and the "Order by" clauses 
		
	if @nErrorCode=0 
	Begin	
		exec @nErrorCode=dbo.csw_ConstructCaseSelect	@nTableCount	OUTPUT,
								@pnUserIdentityId,
								@psCulture,
								@bExternalUser, 			
								@sCurrentTable,	
								@pnQueryContextKey,
								@sCaseXMLOutputRequests,
								@ptXMLFilterCriteria,
								@pbCalledFromCentura
	End
	
	If @nErrorCode=0 
	Begin 	
		Set @sSQLString="
		Select 	@sSelectList1=S.SavedString, 
			@sFrom       =F.SavedString, 
			@sWhere      =W.SavedString
		from #TempConstructSQL W	
		left join #TempConstructSQL F	on (F.ComponentType='F'
						and F.Position=(select min(F1.Position)
								from #TempConstructSQL F1
								where F1.ComponentType=F.ComponentType))
		left join #TempConstructSQL S	on (S.ComponentType='S'
						and S.Position=(select min(S1.Position)
								from #TempConstructSQL S1
								where S1.ComponentType=S.ComponentType))	
		Where W.ComponentType='W'"				-- there will only be 1 Where row
	
		Exec @nErrorCode=sp_executesql @sSQLString,
						N'@sSelectList1		nvarchar(4000)	OUTPUT,
						  @sFrom		nvarchar(4000)	OUTPUT,
						  @sWhere		nvarchar(4000)	OUTPUT',
						  @sSelectList1=@sSelectList1		OUTPUT,
						  @sFrom       =@sFrom1			OUTPUT,
						  @sWhere      =@sWhereCase		OUTPUT
	
		-- Now get the additial SELECT clause components.  
		-- A fixed number have been provided for at this point however this can 
		-- easily be increased
		
		If  @sSelectList1 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=1"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList2		OUTPUT
	
		End
		
		If  @sSelectList2 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=2"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList3		OUTPUT
		End
		
		If  @sSelectList3 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=3"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList4		OUTPUT
		End
	
		If  @sSelectList4 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=4"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList5		OUTPUT
	
		End
		
		If  @sSelectList5 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=5"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList6		OUTPUT
		End
		
		If  @sSelectList6 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=6"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList7		OUTPUT
		End
	
		If  @sSelectList7 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sSelectList=S.SavedString
			from #TempConstructSQL S
			where S.ComponentType='S'
			and (	select count(*)
				from #TempConstructSQL S1
				where S1.ComponentType=S.ComponentType
				and S1.Position<S.Position)=7"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sSelectList	nvarchar(4000)	OUTPUT',
							  @sSelectList=@sSelectList8		OUTPUT
		End
	
		-- Now get the additial FROM clause components.  
		-- A fixed number have been provided for at this point however this can 
		-- easily be increased
		
		If  @sFrom1 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=1"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom2		OUTPUT
		End
		
		If  @sFrom2 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=2"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom3		OUTPUT
		End
		
		If  @sFrom3 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=3"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom4		OUTPUT
		End
	
		If  @sFrom4 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=4"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom5		OUTPUT
		End
		
		If  @sFrom5 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=5"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom6		OUTPUT
		End
		
		If  @sFrom6 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=6"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom7		OUTPUT
		End
	
		If  @sFrom7 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=7"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom8		OUTPUT
		End
		
		If  @sFrom8 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=8"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom9		OUTPUT
		End
	
		If  @sFrom9 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=9"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom10		OUTPUT
		End
		
		If  @sFrom10 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=10"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom11		OUTPUT
		End
	
		If  @sFrom11 is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString="
			Select @sFrom=F.SavedString
			from #TempConstructSQL F
			where F.ComponentType='F'
			and (	select count(*)
				from #TempConstructSQL F1
				where F1.ComponentType=F.ComponentType
				and F1.Position<F.Position)=11"
	
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@sFrom	nvarchar(4000)	OUTPUT',
							  @sFrom=@sFrom12		OUTPUT
		End	
			
		-- Now drop the temporary table holding the results only if the stored procedure
		-- was not called from Centura
		if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
		and @nErrorCode=0
		Begin
			Set @sSql = "drop table "+@sCurrentTable
		
			exec @nErrorCode=sp_executesql @sSql
		End
	End
	
	if @nErrorCode = 0
	Begin
		-------------------------------------------------
		-- RFC62317
		-- Add a common table expression (CTE) to get the 
		-- minimum sequence for a CASEID and NAMETYPE
		------------------------------------------------- 	
		Set @sCTE_CaseNameSequence=
				'CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)'+CHAR(10)+
				'as (	select CASEID, NAMETYPE, MIN(SEQUENCE)'+CHAR(10)+
				'	from CASENAME with (NOLOCK)'+CHAR(10)+
				'	where EXPIRYDATE is null or EXPIRYDATE>GETDATE()'+CHAR(10)+
				'	group by CASEID, NAMETYPE)'+CHAR(10)
			  
		------------------------------------------------- 
		-- Create a CTE for extracting Cases. 
		-- The closing bracket has not been added
		-- in order to cater for Due Date filters 
		-- that will be applied to this statement 
		-- later.
		------------------------------------------------- 
		Set @sCTE_Cases='CTE_Cases (CASEID)'+CHAR(10)+
				'as ('

		Set @sCTE_CasesSelect=
				'	select C.CASEID'+CHAR(10)+ 
				'	FROM dbo.fn_CasesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') C'+CHAR(10) 
			      + CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1) THEN '	join fn_CasesRowSecurity('           +convert(nvarchar,@pnUserIdentityId)+') RS on (RS.CASEID=C.CASEID and RS.READALLOWED=1)'+CHAR(10)
				     WHEN(@bRowLevelSecurity = 1)                      THEN '	join fn_CasesRowSecurityMultiOffice('+convert(nvarchar,@pnUserIdentityId)+') RS on (RS.CASEID=C.CASEID and RS.READALLOWED=1)'+char(10)
				     WHEN(@bBlockCaseAccess  = 1)		       THEN '	join (select 1 as BlockingRow) RS on (RS.BlockingRow=0)'
				     ELSE ''
				END	
	
		If (@sCaseQuickSearch <> '' and @sCaseQuickSearch is not null)
		Begin
			Set @sCTE_CasesSelect = @sCTE_CasesSelect + '	JOIN dbo.fn_GetMatchingCases('+ dbo.fn_Wrapquotes(@sCaseQuickSearch,0,0) + ', ' + cast(@pnUserIdentityId as nvarchar)+') CQSearch on (CQSearch.CASEID = C.CASEID)'
		End		
				
		Set @sCTE_CasesSelect = @sCTE_CasesSelect +CHAR(10) + @sWhereCase+CHAR(10)
				
		------------------------------------------------- 
		-- Create a CTE for extracting the details. 
		-- required for the Case that will be used in the
		-- final result set.
		------------------------------------------------- 
		Set @sCTE_CaseDetails=
				'CTE_CaseDetails'+char(10)+
				'as ('	+ @sSelectList1 + @sSelectList2 + @sSelectList3 + @sSelectList4 
					+ @sSelectList5 + @sSelectList6 + @sSelectList7 + @sSelectList8 + ', C.CASEID as CASEID' 
					+ @sFrom1 + @sFrom2 + @sFrom3 + @sFrom4 + @sFrom5 + @sFrom6 + @sFrom7 + @sFrom8 
					+ @sFrom9 + @sFrom10 + @sFrom11 + @sFrom12+ CHAR(10) + 
				'		join '+
				CASE WHEN(@bUseTempTables=1) THEN @sCaseIdsTempTable ELSE 'CTE_Cases' END +' CIDS ON (CIDS.CASEID = C.CASEID)'+CHAR(10)
					+ @sWhereCase 
					+ @sWhereFilter
		
		Set @sReminderExists = 'exists (select 1 from EMPLOYEEREMINDER ER WHERE ER.CASEID = C.CASEID'
		Set @sAlertExists    = 'exists (select 1 from ALERT A WHERE A.CASEID = C.CASEID'
		
		if (isnull(@sDateRangeFilter,'') <> '')
		Begin
			if (@bUseDueDate = 1 and @bUseReminderDate = 1)
			Begin
				Set @sReminderExists = @sReminderExists + char(10) + 'and (ER.DUEDATE '    + @sDateRangeFilter
							                + char(10) + 'or ER.REMINDERDATE ' + @sDateRangeFilter + ')'
				Set @sAlertExists    = @sAlertExists    + char(10) + 'and A.DUEDATE '      + @sDateRangeFilter
			End
			Else if (@bUseDueDate = 1)
			Begin
				Set @sReminderExists = @sReminderExists + char(10) + 'and ER.DUEDATE ' + @sDateRangeFilter
				Set @sAlertExists    = @sAlertExists    + char(10) + 'and A.DUEDATE '  + @sDateRangeFilter
			End
			Else if (@bUseReminderDate = 1)
			Begin
				Set @sReminderExists = @sReminderExists + char(10) + 'and ER.REMINDERDATE ' + @sDateRangeFilter
			End
		End

		Set @sReminderExists = @sReminderExists + ')'
		Set @sAlertExists    = @sAlertExists + ')'
		
		If (@bHasReminder = 1 and @bIsAdHoc = 1)
		Begin
			Set @sCTE_CaseDetails = @sCTE_CaseDetails + char(10) + 'and (' + @sReminderExists + ' or ' + @sAlertExists + ')'
		End
		Else If (@bHasReminder = 1)
		Begin
			Set @sCTE_CaseDetails = @sCTE_CaseDetails + char(10) + 'and ' + @sReminderExists
		End
		Else If (@bIsAdHoc = 1 and @bIsEvent = 0)
		Begin
			Set @sCTE_CaseDetails = @sCTE_CaseDetails + char(10) + 'and '+ @sAlertExists
		End	
		
		-- Close the CTE
		Set @sCTE_CaseDetails = @sCTE_CaseDetails +CHAR(10) + ')'
	End
End

-- Now execute the constructed SQL to return the result set
If  @nErrorCode = 0
and (@bHasReminder = 0 or
     @bHasReminder is null)
Begin  	
	-- Event Due Dates only are to be returned.
	If  @bIsEvent 	= 1 
	and @bIsAdHoc 	= 0
	and @bHasCase 	= 1
	Begin	
		Set @sSelectDueDate = 'Select '+@sSelectDueDate	

		-- Embed the Cases as a derived table into the Events sql:
		Set @sSelectDueDate = @sSelectDueDate + char(10) + 'from '
		
		Set @sFromDueDate = ' C'+char(10)+"join CASEEVENT CE		on (CE.CASEID = C.CaseKey)"
				 	 +char(10)+"join EVENTS E		on (E.EVENTNO = CE.EVENTNO)"
					 +char(10)+"left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX"
					 +char(10)+"                            on (OX.CASEID = CE.CASEID"
					 +char(10)+"				and OX.ACTION = E.CONTROLLINGACTION)"
					 +char(10)+"left join EVENTCONTROL EC	on (EC.EVENTNO = CE.EVENTNO"
				  	 +char(10)+"				and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))"
					 +@sFromDueDate
					 +char(10)+'WHERE 1=1'
					 +char(10)+@sWhereFilterEventText

		Set @sWhereFromDueDate  = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromDueDate 
	
		-- Include the Events 'Where' clause into the Cases 'Where' clause 
		-- to improve performance.		 
		Set @sWhereFilterDueDate = @sWhereDueDate+char(10)+"and CEX.CASEID = C.CASEID)"
		
		Set @sWhereDueDate	 = @sWhereDueDate
					  +char(10)+"and (CEX.CASEID = CE.CASEID"
					  +char(10)+"and  CEX.EVENTNO = CE.EVENTNO"
					  +char(10)+"and  CEX.CYCLE = CE.CYCLE))" 				

		-- Embedd CaseEvent filter criteria into the Cases derived table 'Where' clause:		
		Set @sWhereFilter	= replace(@sWhereFilter, 
						  'and XC.CASEID=C.CASEID)', 
						  'and XC.CASEID=C.CASEID')
						  
		Set @sCTE_Cases = @sCTE_Cases        +
				  @sCTE_CasesSelect  + char(10)+
				  @sWhereFromDueDate + char(10)+
				  @sWhereFilterDueDate +')'

		If @bUseTempTables=1
		Begin
			Set @sCTE = ''
			
			Set @sGetCasesOnlySql = ';with '   +char(10)+
						@sCTE_Cases+char(10)+
						'select * into '+@sCaseIdsTempTable+' from CTE_Cases'
						
			Set @sPopulateTempCaseTableSql =
						'SET ANSI_NULLS OFF;'     +char(10)+
						'with '                   +char(10)+
						@sCTE_CaseNameSequence+','+char(10)+
						@sCTE_CaseDetails         +char(10)+
						'select * into '+@sCasesTempTable+' from CTE_CaseDetails'
			if (@pbPrintSQL = 1)
			Begin
				print @sGetCasesOnlySql
				print ''
				print @sPopulateTempCaseTableSql
			End

			-- Populate the temp case table
			exec (@sGetCasesOnlySql)
			exec (@sPopulateTempCaseTableSql)
		End
		Else Begin 
			Set @sCTE =	'with '                   +char(10)+
					@sCTE_CaseNameSequence+','+char(10)+
					@sCTE_Cases           +','+char(10)+
					@sCTE_CaseDetails         +char(10)
		End
	        
		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbPrintSQL = 1
			Begin
				Print 'SET ANSI_NULLS OFF; ' 
				Print @sCTE
				Print @sSelectDueDate
				Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
				Print @sFromDueDate
				Print @sWhereFromDueDate			
				Print @sWhereDueDate
				Print @sOrderDueDate
			End

			If @bUseTempTables=1
			Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate
				+ @sCasesTempTable +
				@sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sOrderDueDate)
				Select 	@nErrorCode =@@ERROR,
					@pnRowCount = @@RowCount
			End
			Else Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate
				+ 'CTE_CaseDetails' +
				@sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sOrderDueDate)
				Select 	@nErrorCode =@@ERROR,
					@pnRowCount = @@RowCount
			End
				
		End
		-- Paging required
		Else Begin
			Set @sTopSelectList1 = replace(@sSelectDueDate,'Select', 'Select TOP 100 PERCENT ')
			
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows from ('  

			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as OutputSorted'+char(10)+
					     ') as OutputWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar)

			If @pbPrintSQL = 1
			and @pbReturnResultSet=1
			Begin
				Print 'SET ANSI_NULLS OFF; ' 
				Print @sCTE
				Print @sOpenWrapper
				Print @sTopSelectList1
				Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
				Print @sFromDueDate
				Print @sWhereFromDueDate			
				Print @sWhereDueDate
				Print @sOrderDueDate
				Print @sCloseWrapper
			End
	
			If @pbReturnResultSet=1
			Begin
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; '
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1
						+ @sCasesTempTable 
						+ @sFromDueDate  + @sWhereFromDueDate 
						+ @sWhereDueDate + @sOrderDueDate
						+ @sCloseWrapper)
					
					Select 	@nErrorCode = @@Error,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; '
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1
						+ 'CTE_CaseDetails' 
						+ @sFromDueDate + @sWhereFromDueDate 
						+ @sWhereDueDate + @sOrderDueDate
						+ @sCloseWrapper)
					
					Select 	@nErrorCode = @@Error,
						@pnRowCount = @@RowCount
				End
			End

			If  @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect 
						+ @sCasesTempTable
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate)

					Set @nErrorCode =@@ERROR
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect 
						+ 'CTE_CaseDetails' 
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate)

					Set @nErrorCode =@@ERROR
				End
			End
		End		
	End
	Else
	-- Ad Hoc Due Dates only are to be returned.
	If  @bIsEvent 	= 0 
	and @bIsAdHoc 	= 1	
	and @bHasCase 	= 1 	 
	Begin	
		Set @sUnionSelectDueDate = 'Select '+@sUnionSelectDueDate 	
	
		-- Embed the Cases as a derived table into the Events sql:
		Set @sUnionFromDueDate = char(10)+'from ALERT A' + @sUnionFromDueDate + char(10) + 'left join ' 		

		-- Include the Ad Hoc 'Where' clause into the Cases 'Where' clause 
		-- to improve performance.		
		Set @sWhereFilter		= replace(@sWhereFilter, 
						  'and XC.CASEID=C.CASEID)', 
						  'and XC.CASEID=C.CASEID')						  					 
		
		Set @sUnionWhereFilterDueDate 	= @sUnionWhereDueDate+char(10)+
					   	CASE WHEN @sWhereFilter IS NULL 
						     THEN "and AX.CASEID = C.CASEID)" 
						     ELSE "and AX.CASEID = C.CASEID)"
					   	END 
		Set @sUnionJoinPredicate = ' C on (A.CASEID = C.CaseKey)'
					   +char(10)+@sFromRowSecurity
					   +char(10)+@sFromCaseSecurity
					   +char(10)+'WHERE 1=1'

		Set @sUnionWhereFromDueDate 	= char(10)+'and exists' 
					  	+char(10)+'(Select 1 '
					  	+@sUnionWhereFromDueDate 

		Set @sUnionWhereDueDate	 =  	@sUnionWhereDueDate
					  	+char(10)+"and (AX.EMPLOYEENO = A.EMPLOYEENO"
					  	+char(10)+"and  AX.ALERTSEQ = A.ALERTSEQ))"	

		-- When @bIsGeneral is set to 1, duedates that are not related to a case are included.
		If @bIsGeneral = 1 and isnull(@sCaseQuickSearch,'') = ''
		Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate + char(10) + "and (A.CASEID = C.CaseKey or A.CASEID is null)"
		End 
		-- Otherwise, exclude General reminders.
		Else Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate + char(10) + "and (A.CASEID = C.CaseKey)"							
		End
						  
		Set @sCTE_Cases = @sCTE_Cases +
				  @sCTE_CasesSelect         + char(10)+
				  @sUnionWhereFromDueDate   + char(10)+
				  @sUnionWhereFilterDueDate +')'			

		If @bUseTempTables=1
		Begin
			Set @sCTE = ''
			
			Set @sGetCasesOnlySql = ';with '   +char(10)+
						@sCTE_Cases+char(10)+
						'select * into '+@sCaseIdsTempTable+' from CTE_Cases'
						
			Set @sPopulateTempCaseTableSql =
						'SET ANSI_NULLS OFF;'     +char(10)+
						'with '                   +char(10)+
						@sCTE_CaseNameSequence+','+char(10)+
						@sCTE_CaseDetails         +char(10)+
						'select * into '+@sCasesTempTable+' from CTE_CaseDetails'
			if (@pbPrintSQL = 1)
			Begin
				print @sGetCasesOnlySql
				print ''
				print @sPopulateTempCaseTableSql
			End

			-- Populate the temp case table
			exec (@sGetCasesOnlySql)
			exec (@sPopulateTempCaseTableSql)
		End
		Else Begin 
			Set @sCTE =	'with '                   +char(10)+
					@sCTE_CaseNameSequence+','+char(10)+
					@sCTE_Cases           +','+char(10)+
					@sCTE_CaseDetails         +char(10)
		End
		
		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbPrintSQL = 1
			Begin
				Print 'SET ANSI_NULLS OFF; ' 
				Print @sCTE
				Print @sUnionSelectDueDate
				Print @sUnionFromDueDate
				Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END 
				Print @sUnionJoinPredicate
				Print @sUnionWhereFromDueDate
				Print @sUnionWhereDueDate
				Print @sOrderDueDate
			End
		
			If @bUseTempTables=1
			Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sUnionSelectDueDate + @sUnionFromDueDate 
					+ @sCasesTempTable + @sUnionJoinPredicate
					+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + @sOrderDueDate)
				
				Select 	@nErrorCode = @@Error,
					@pnRowCount = @@RowCount
			End
			Else Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sUnionSelectDueDate + @sUnionFromDueDate 
					+ 'CTE_CaseDetails'  + @sUnionJoinPredicate
					+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + @sOrderDueDate)
				
				Select 	@nErrorCode = @@Error,
					@pnRowCount = @@RowCount
			End
		End
		-- Paging required
		Else Begin
			Set @sTopSelectList1 = replace(@sUnionSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  
		
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as OutputSorted'+char(10)+
					     ') as OutputWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar) 
		
			If @pbPrintSQL = 1
			and @pbReturnResultSet=1
			Begin
				Print 'SET ANSI_NULLS OFF; '
				Print @sCTE
				Print @sOpenWrapper
				Print @sTopSelectList1
				Print @sUnionFromDueDate
				Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
				Print @sUnionJoinPredicate
				Print @sUnionWhereFromDueDate
				Print @sUnionWhereDueDate
				Print @sOrderDueDate
				Print @sCloseWrapper
			End

			If @pbReturnResultSet=1
			Begin
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; '
					+ @sCTE
					+ @sOpenWrapper
					+ @sTopSelectList1 + @sUnionFromDueDate 
					+ @sCasesTempTable + @sUnionJoinPredicate
					+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + @sOrderDueDate
					+ @sCloseWrapper)
					
					Select 	@nErrorCode = @@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; '
					+ @sCTE
					+ @sOpenWrapper
					+ @sTopSelectList1  + @sUnionFromDueDate 
					+ 'CTE_CaseDetails' + @sUnionJoinPredicate
					+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + @sOrderDueDate
					+ @sCloseWrapper)
					
					Select 	@nErrorCode = @@ERROR,
						@pnRowCount = @@RowCount
				End

				If @pnRowCount<@pnPageEndRow
				and isnull(@pnPageStartRow,1)=1
				and @nErrorCode=0
				Begin
					set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
			
					exec @nErrorCode=sp_executesql @sSQLString,
								N'@pnRowCount	int',
								  @pnRowCount=@pnRowCount
				End
				Else If isnull(@pbGetTotalRowCount,0)=0
				     and @nErrorCode=0
				Begin
					set @sSQLString='select -1 as SearchSetTotalRows'  

					exec @nErrorCode=sp_executesql @sSQLString
				End
				Else If @nErrorCode = 0
				Begin
					If @bUseTempTables=1
					Begin
						Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sUnionFromDueDate 
							+ @sCasesTempTable + @sUnionJoinPredicate
							+ @sUnionWhereFromDueDate + @sUnionWhereDueDate)
			
						Set @nErrorCode =@@ERROR
					End
					Else Begin
						Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sUnionFromDueDate 
							+ 'CTE_CaseDetails'  + @sUnionJoinPredicate
							+ @sUnionWhereFromDueDate + @sUnionWhereDueDate)
			
						Set @nErrorCode =@@ERROR
					End
				End
			End
		End	
	End	
	-- Both Events and Ad Hoc are to be returned.
	Else 
	If @bHasCase = 1
	and @bIsEvent= 1
	and @bIsAdHoc= 1
	Begin 
		-- Embed the Cases as a derived table into the Events sql:
		Set @sSelectDueDate = 'Select ' + @sSelectDueDate + char(10) + 'from ('
		
		Set @sFromDueDate = ') as C'+char(10)+"left join CASEEVENT CE	on (CE.CASEID = C.CaseKey)"
				 	 +char(10)+"left join EVENTS E		on (E.EVENTNO = CE.EVENTNO)"
					 +char(10)+"left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX"
					 +char(10)+"                            on (OX.CASEID=CE.CASEID"
					 +char(10)+"				and OX.ACTION=E.CONTROLLINGACTION)"
					 +char(10)+"left join EVENTCONTROL EC	on (EC.EVENTNO = CE.EVENTNO"
				  	 +char(10)+"				and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))"
					 +@sFromDueDate
					 +char(10)+'WHERE 1=1'
					 +CHAR(10)+@sWhereFilterEventText

		Set @sWhereFromDueDate  = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromDueDate 
	
		-- Include the Events 'Where' clause into the Cases 'Where' clause 
		-- to improve performance.	
		Set @sWhereFilterDueDate = @sWhereDueDate+char(10)+
					   CASE WHEN @sWhereFilter IS NULL 
						THEN "and CEX.CASEID = C.CASEID)" 
						ELSE "and CEX.CASEID = C.CASEID)"
					   END
		Set @sWhereDueDate	 = @sWhereDueDate
					  +char(10)+"and (CEX.CASEID = CE.CASEID"
					  +char(10)+"and  CEX.EVENTNO = CE.EVENTNO"
					  +char(10)+"and  CEX.CYCLE = CE.CYCLE))" 				

		-- Embedd CaseEvent filter criteria into the Cases derived table 'Where' clause:		
		Set @sWhereFilter	= replace(@sWhereFilter, 
						  'and XC.CASEID=C.CASEID)', 
						  'and XC.CASEID=C.CASEID')		

		-- Embed the 'Union' to union Events and Ad Hoc Due Dates:
		-- Note that UNION will also remove any duplicate rows.
		Set @sUnionSelectDueDate = char(10)+'Union'	
					  +char(10)+'Select '+@sUnionSelectDueDate

		Set @sUnionFromDueDate = char(10)+'from ALERT A ' + @sUnionFromDueDate + char(10) + char(10) + 'left join ' 		 
		
		-- Include the Ad Hoc 'Where' clause into the Cases 'Where' clause 
		-- to improve performance.	
		Set @sUnionWhereFilterDueDate 	= @sUnionWhereDueDate+char(10)+
					   	CASE WHEN @sWhereFilter IS NULL 
						     THEN "and AX.CASEID = C.CASEID)" 
						     ELSE "and AX.CASEID = C.CASEID)"
					   	END 
					   	
		Set @sUnionJoinPredicate = ' C on (A.CASEID = C.CaseKey)'
					   +char(10)+@sFromRowSecurity
					   +char(10)+@sFromCaseSecurity
					   +char(10)+'WHERE 1=1'

		Set @sUnionWhereFromDueDate 	= char(10)+'and exists' 
					  	+char(10)+'(Select 1 '
					  	+@sUnionWhereFromDueDate 

		Set @sUnionWhereDueDate	 =  	@sUnionWhereDueDate
					  	+char(10)+"and (AX.EMPLOYEENO = A.EMPLOYEENO"
					  	+char(10)+"and  AX.ALERTSEQ = A.ALERTSEQ))"	

		-- When @bIsGeneral is set to 1, duedates that are not related to a case are included.
		If @bIsGeneral = 1 and isnull(@sCaseQuickSearch,'') = ''
		Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate + char(10) + "and (A.CASEID = C.CaseKey or A.CASEID is null)"							
		End 
		-- Otherwise, exclude General reminders.
		Else Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate + char(10) + "and (A.CASEID = C.CaseKey)"							
		End
	  
		Set @sCTE_Cases = @sCTE_Cases+
				  @sCTE_CasesSelect       + CHAR(10)+
				  @sWhereFromDueDate      + CHAR(10)+
				  @sWhereFilterDueDate    + CHAR(10)+
				  'UNION'                 + CHAR(10)+
				  @sCTE_CasesSelect       + CHAR(10)+ 
				  @sUnionWhereFromDueDate + CHAR(10)+
				  @sUnionWhereFilterDueDate+')'

		If @bUseTempTables=1
		Begin
			Set @sCTE = ''
			
			Set @sGetCasesOnlySql = ';with '   +char(10)+
						@sCTE_Cases+char(10)+
						'select * into '+@sCaseIdsTempTable+' from CTE_Cases'
						
			Set @sPopulateTempCaseTableSql =
						'SET ANSI_NULLS OFF;'     +char(10)+
						'with '                   +char(10)+
						@sCTE_CaseNameSequence+','+char(10)+
						@sCTE_CaseDetails         +char(10)+
						'select * into '+@sCasesTempTable+' from CTE_CaseDetails'

			if (@pbPrintSQL = 1)
			Begin
				print @sGetCasesOnlySql
				print ''
				print @sPopulateTempCaseTableSql
			End

			-- Populate the temp case table
			exec (@sGetCasesOnlySql)
			exec (@sPopulateTempCaseTableSql)
		End
		Else Begin 
			Set @sCTE =	'with '                   +char(10)+
					@sCTE_CaseNameSequence+','+char(10)+
					@sCTE_Cases           +','+char(10)+
					@sCTE_CaseDetails         +char(10)
		End
		
		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; ' 
					Print @sCTE
					Print @sSelectDueDate
					Print 'Select * from ' + CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END + ' C where 1=1 '
					Print @sWhereFromDueDate
					Print @sWhereFilterDueDate
					Print @sFromDueDate
					Print @sWhereFromDueDate			
					Print @sWhereDueDate
					Print @sUnionSelectDueDate
					Print @sUnionFromDueDate
					Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
					Print @sUnionJoinPredicate
					Print @sUnionWhereFromDueDate
					Print @sUnionWhereDueDate
					Print @sOrderDueDate
				End

				If @bUseTempTables=1
				Begin
					Exec   ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate 
						+ 'Select * from ' + @sCasesTempTable
						+ ' C where 1=1 '
						+ @sWhereFromDueDate + @sWhereFilterDueDate 
						+ @sFromDueDate + @sWhereFromDueDate 		
						+ @sWhereDueDate + @sUnionSelectDueDate + @sUnionFromDueDate
						+ @sCasesTempTable + @sUnionJoinPredicate
						+ @sUnionWhereFromDueDate
						+ @sUnionWhereDueDate + @sOrderDueDate)

					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec   ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate 
						+ 'Select * from CTE_CaseDetails C where 1=1 '
						+ @sWhereFromDueDate + @sWhereFilterDueDate 
						+ @sFromDueDate + @sWhereFromDueDate 		
						+ @sWhereDueDate + @sUnionSelectDueDate + @sUnionFromDueDate
						+ 'CTE_CaseDetails' + @sUnionJoinPredicate
						+ @sUnionWhereFromDueDate
						+ @sUnionWhereDueDate + @sOrderDueDate)

					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
			End
		End
		-- Paging required
		Else Begin

			Set @sTopSelectList1 = replace(@sSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			
			If @sUnionSelectDueDate is not null
			Begin
				Set @sTopSelectList1  = replace(@sSelectDueDate,     'Select', 'Select TOP 100 Percent ')
				Set @sTopUnionSelect1 = replace(@sUnionSelectDueDate,'Select ','Select TOP 100 Percent ')
			End
			Else Begin
				Set @sTopSelectList1 = replace(@sSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			End
	
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows from ('  
			
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as OutputSorted'+char(10)+
					     ') as OutputWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar)

			If @pbPrintSQL = 1
			and @pbReturnResultSet=1
			Begin
				Print 'SET ANSI_NULLS OFF; '
				Print @sCTE
				Print @sOpenWrapper
				Print @sTopSelectList1
				Print 'Select * from ' + CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END + ' C where 1=1 '
				Print @sWhereFromDueDate
				Print @sWhereFilterDueDate
				Print @sFromDueDate
				Print @sWhereFromDueDate			
				Print @sWhereDueDate
				Print @sTopUnionSelect1
				Print @sUnionFromDueDate
				Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
				Print @sUnionJoinPredicate
				Print @sUnionWhereFromDueDate
				Print @sUnionWhereDueDate
				Print @sOrderDueDate
				Print @sCloseWrapper
			End
	
			If @pbReturnResultSet=1
			Begin

				If @bUseTempTables=1
				Begin
					Exec   ('SET ANSI_NULLS OFF; ' 
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1 
						
						+ 'Select * from ' + @sCasesTempTable
						+ ' C where 1=1 '
						+ @sWhereFromDueDate + @sWhereFilterDueDate 
					
						+ @sFromDueDate + @sWhereFromDueDate 		
						+ @sWhereDueDate + @sTopUnionSelect1 + @sUnionFromDueDate
					
						+ @sCasesTempTable + @sUnionJoinPredicate
						
						+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + @sOrderDueDate
						+ @sCloseWrapper)
						
					Select 	@nErrorCode = @@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec   ('SET ANSI_NULLS OFF; ' 
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1 
						
						+ 'Select * from CTE_CaseDetails C where 1=1 '
						+ @sWhereFromDueDate + @sWhereFilterDueDate 
					
						+ @sFromDueDate + @sWhereFromDueDate 		
						+ @sWhereDueDate + @sTopUnionSelect1 + @sUnionFromDueDate
					
						+ 'CTE_CaseDetails' + @sUnionJoinPredicate
						
						+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + @sOrderDueDate
						+ @sCloseWrapper)
						
					Select 	@nErrorCode = @@ERROR,
						@pnRowCount = @@RowCount
				End
			End

			If @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin
				If @bUseTempTables=1
				Begin
					Exec   ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sSelectDueDate
						+ 'Select * from ' + @sCasesTempTable
						+ ' C where 1=1 '
						+ @sWhereFromDueDate + @sWhereFilterDueDate 
					
						+ @sFromDueDate + @sWhereFromDueDate 		
						+ @sWhereDueDate + @sUnionSelectDueDate + @sUnionFromDueDate
					
						+ @sCasesTempTable + @sUnionJoinPredicate 
						+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + ' )C ')
					
					Set @nErrorCode =@@ERROR
				End
				Begin
					Exec   ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sSelectDueDate
						+ 'Select * from CTE_CaseDetails C where 1=1 '
						+ @sWhereFromDueDate + @sWhereFilterDueDate 
					
						+ @sFromDueDate + @sWhereFromDueDate 		
						+ @sWhereDueDate + @sUnionSelectDueDate + @sUnionFromDueDate
					
						+ 'CTE_CaseDetails' + @sUnionJoinPredicate 
						+ @sUnionWhereFromDueDate + @sUnionWhereDueDate + ' )C ')
					
					Set @nErrorCode =@@ERROR
				End
			End
		End	
	End	
	Else 
	-- Only General Ad Hoc Reminders are to be selected.
	If @bHasCase = 0
	Begin
		Set @sUnionSelectDueDate = 'Select '+@sUnionSelectDueDate 	

		Set @sUnionFromDueDate = char(10)+'from ALERT A' + @sUnionFromDueDate 

		Set @sUnionWhereFromDueDate 	=char(10)+'WHERE 1=1' 
						+char(10)+'and exists' 
					  	+char(10)+'(Select 1 '
					  	+@sUnionWhereFromDueDate 

		Set @sUnionWhereDueDate 	= @sUnionWhereDueDate  
						+char(10)+"and AX.CASEID is null"
						+char(10)+"and (AX.EMPLOYEENO = A.EMPLOYEENO"
					  	+char(10)+"and  AX.ALERTSEQ = A.ALERTSEQ))"	

		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; ' 
					Print @sUnionSelectDueDate
					Print @sUnionFromDueDate
					Print @sUnionWhereFromDueDate
					Print @sUnionWhereDueDate
					Print @sOrderDueDate
				End		
	
				Exec ('SET ANSI_NULLS OFF; ' + 
					@sUnionSelectDueDate + 
					@sUnionFromDueDate + @sUnionWhereFromDueDate +
					@sUnionWhereDueDate + @sOrderDueDate)
				
				Select 	@nErrorCode = @@ERROR,
					@pnRowCount = @@RowCount
			End		
		End
		-- Paging required
		Else Begin
			Set @sTopSelectList1 = replace(@sUnionSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  
			
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as ResultSorted'+char(10)+
					     ') as ResultWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar)

	
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; '
					Print @sOpenWrapper
					Print @sTopSelectList1
					Print @sUnionFromDueDate
					Print @sUnionWhereFromDueDate
					Print @sUnionWhereDueDate
					Print @sOrderDueDate
					Print @sCloseWrapper
				End
	
				Exec ('SET ANSI_NULLS OFF; ' 
					+ @sOpenWrapper
					+ @sTopSelectList1
					+ @sUnionFromDueDate
					+ @sUnionWhereFromDueDate 
					+ @sUnionWhereDueDate 
					+ @sOrderDueDate 
					+ @sCloseWrapper)
					
				Select 	@nErrorCode = @@ERROR,
					@pnRowCount = @@RowCount
			End

			If @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCountSelect + @sUnionFromDueDate + @sUnionWhereFromDueDate +
				@sUnionWhereDueDate)

				Set @nErrorCode =@@ERROR
			End
		End		
	End	
End
-- If @bHasReminder flag is set to true then assemble the 'From' clause 
-- starting with the EMPLOYEEREMINDER table.
Else If @nErrorCode = 0
and @bHasReminder = 1
Begin
	Set @sUnionFromReminders = 				    char(10) + "from EMPLOYEEREMINDER ER" +
				  CASE WHEN @bExternalUser = 1 THEN char(10) + "join dbo.fn_FilterUserNames("+CAST(@pnUserIdentityId as varchar(11))+", 1) FN"
								   +char(10) + "			on (FN.NAMENO = ER.EMPLOYEENO)"
				  END
				 				   -- Embed the Cases as a derived table into the Events sql:
								   +char(10) + 'left join '

	Set @sFromReminders = 	  				    char(10) + "from EMPLOYEEREMINDER ER" +
			     	  CASE WHEN @bExternalUser = 1 THEN char(10) + "join dbo.fn_FilterUserNames("+CAST(@pnUserIdentityId as varchar(11))+", 1) FN"
								   +char(10) + "			on (FN.NAMENO = ER.EMPLOYEENO)"
				  END
				  
	-- Embed the Cases as a derived table into the Events sql: 
	If  @bIsAdHoc  =1
	and @bIsGeneral=1
		Set @sFromReminders=@sFromReminders+char(10) + 'left join '
	Else
		Set @sFromReminders=@sFromReminders+char(10) + 'join '

	-- Event Due Dates only are to be returned.
	If  @bIsEvent 	= 1 
	and @bIsAdHoc 	= 0
	and @bHasCase 	= 1
	Begin
		Set @sSelectDueDate = 'Select '+@sSelectDueDate	
		
		Set @sFromDueDate =' C	on (C.CaseKey = ER.CASEID)'
				 +char(10)+"left join CASEEVENT CE		on (CE.CASEID = ER.CASEID"
				 +char(10)+"					and CE.EVENTNO = ER.EVENTNO"
				 +char(10)+"					and CE.CYCLE = ER.CYCLENO"
				 +char(10)+"					and CE.CASEID = C.CaseKey)"
			 	 +char(10)+"left join EVENTS E			on (E.EVENTNO = CE.EVENTNO)"
				 +char(10)+"left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX"
				 +char(10)+"                                    on (OX.CASEID = CE.CASEID"
				 +char(10)+"					and OX.ACTION = E.CONTROLLINGACTION)"
				 +char(10)+"left join EVENTCONTROL EC		on (EC.EVENTNO = CE.EVENTNO"
			  	 +char(10)+"					and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))"	 
				 +char(10)+@sFromDueDate 				
				 +char(10)+'WHERE 1=1'
				 +char(10)+@sWhereFilterEventText
				 +char(10)+@sWhereDateRange

		Set @sWhereFromDueDate  = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromDueDate 
	
		-- Include the Events and Reminders 'Where' clauses into the Cases 'Where' clause 
		-- to improve performance.		 
		Set @sWhereFilterDueDate = @sWhereDueDate+char(10)+"and CEX.CASEID = C.CASEID)" 							

		Set @sWhereFilterReminder= @sWhereReminder+char(10)+"and ERX.CASEID = C.CASEID)"						
		
		If charindex('join EMPLOYEEREMINDER ERX',@sWhereFromDueDate)=1
			Set @sWhereDueDate = @sWhereDueDate
					    +char(10)+"and ERX.EMPLOYEENO=ER.EMPLOYEENO"
					    +char(10)+"and ERX.MESSAGESEQ=ER.MESSAGESEQ"
					    
		Set @sWhereDueDate	 = @sWhereDueDate
					  +char(10)+"and (CEX.CASEID = CE.CASEID"
					  +char(10)+"and  CEX.EVENTNO = CE.EVENTNO"
					  +char(10)+"and  CEX.CYCLE = CE.CYCLE))" 				

		-- Embedd CaseEvent filter criteria into the Cases derived table 'Where' clause:		
		Set @sWhereFilter	= replace(@sWhereFilter, 
						  'and XC.CASEID=C.CASEID)', 
						  'and XC.CASEID=C.CASEID')
		
		Set @sWhereFromReminder = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromReminder 

		Set @sWhereReminder 	= @sWhereReminder
					+char(10)+"and (ERX.EMPLOYEENO = ER.EMPLOYEENO"
					+char(10)+"and ERX.MESSAGESEQ = ER.MESSAGESEQ))"   
						  
		Set @sCTE_Cases = @sCTE_Cases           +
				  @sCTE_CasesSelect     + char(10)+
				  @sWhereFromDueDate    + char(10)+
				  @sWhereFilterDueDate  + CHAR(10) +
				  @sWhereFromReminder   + CHAR(10) +
				  @sWhereFilterReminder +')'

		If @bUseTempTables=1
		Begin
			Set @sCTE = ''
			
			Set @sGetCasesOnlySql = ';with '   +char(10)+
						@sCTE_Cases+char(10)+
						'select * into '+@sCaseIdsTempTable+' from CTE_Cases'
						
			Set @sPopulateTempCaseTableSql =
						'SET ANSI_NULLS OFF;'     +char(10)+
						'with '                   +char(10)+
						@sCTE_CaseNameSequence+','+char(10)+
						@sCTE_CaseDetails         +char(10)+
						'select * into '+@sCasesTempTable+' from CTE_CaseDetails'
			if (@pbPrintSQL = 1)
			Begin
				print @sGetCasesOnlySql
				print ''
				print @sPopulateTempCaseTableSql
			End

			-- Populate the temp case table
			exec (@sGetCasesOnlySql)
			exec (@sPopulateTempCaseTableSql)
		End
		Else Begin 
			Set @sCTE =	'with '                   +char(10)+
					@sCTE_CaseNameSequence+','+char(10)+
					@sCTE_Cases           +','+char(10)+
					@sCTE_CaseDetails         +char(10)
		End

		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbPrintSQL = 1
			Begin
				Print 'SET ANSI_NULLS OFF; ' 
				Print @sCTE
				Print @sSelectDueDate
				Print @sFromReminders	
				Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
				Print @sFromDueDate
				Print @sWhereFromDueDate						
				Print @sWhereDueDate
				Print @sWhereFromReminder
				Print @sWhereReminder
				Print @sOrderDueDate
			End

			If @bUseTempTables=1
			Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate + @sFromReminders
					+ @sCasesTempTable
					+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder 
					+ @sWhereReminder + @sOrderDueDate)
				
				Select 	@nErrorCode =@@ERROR,
					@pnRowCount = @@RowCount
			End
			Else Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate + @sFromReminders
					+ 'CTE_CaseDetails'
					+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder 
					+ @sWhereReminder + @sOrderDueDate)
				
				Select 	@nErrorCode =@@ERROR,
					@pnRowCount = @@RowCount
			End
		End
		-- Paging required
		Else Begin
			Set @sTopSelectList1 = replace(@sSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  
	
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as CasesSorted'+char(10)+
					     ') as CasesWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar)

			If @pbReturnResultSet=1
			Begin		
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; '
					Print @sCTE
					Print @sOpenWrapper
					Print @sTopSelectList1
					Print @sFromReminders			
					Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
					Print @sFromDueDate
					Print @sWhereFromDueDate						
					Print @sWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate
					Print @sCloseWrapper
				End

				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' 
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1 + @sFromReminders
						+ @sCasesTempTable
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder 
						+ @sWhereReminder + @sOrderDueDate
						+ @sCloseWrapper)

					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' 
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1 + @sFromReminders
						+ 'CTE_CaseDetails'
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder 
						+ @sWhereReminder + @sOrderDueDate
						+ @sCloseWrapper)

					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
			End

			If @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin	
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sFromReminders
						+ @sCasesTempTable
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder 
						+ @sWhereReminder)

					Set @nErrorCode =@@ERROR
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sFromReminders
						+ 'CTE_CaseDetails'
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder 
						+ @sWhereReminder)

					Set @nErrorCode =@@ERROR
				End
			End
		End	
	End
	Else
	-- Ad Hoc Due Dates only are to be returned.
	If  @bIsEvent 	= 0 
	and @bIsAdHoc 	= 1	
	and @bHasCase 	= 1 	 
	Begin	
		Set @sUnionSelectDueDate = 'Select '+@sUnionSelectDueDate 	

		Set @sUnionFromDueDate =+char(10)+"left join ALERT A	on (A.EMPLOYEENO = ER.ALERTNAMENO"
					+char(10)+"			and A.SEQUENCENO = ER.SEQUENCENO"
					+char(10)+"			and ER.SOURCE    = 1"
					+char(10)+"			and ER.EVENTNO IS NULL"
					+char(10)+"			and (A.CASEID = ER.CASEID"
					+char(10)+"			or (A.REFERENCE = ER.REFERENCE"
					+char(10)+"			and A.CASEID is null"
					+char(10)+"			and ER.CASEID is null)"
					+char(10)+"			or (A.NAMENO = ER.NAMENO)))"
					+char(10)+@sUnionFromDueDate	 
					+char(10)+@sFromRowSecurity	 
					+char(10)+@sFromCaseSecurity	 
					+char(10)+'WHERE 1=1'						  					 
					+char(10)+@sWhereDateRange						  					 
		
		-- Include the Ad Hoc and Reminders 'Where' clauses into the Cases 'Where' clause 
		-- to improve performance.
		Set @sUnionWhereFilterDueDate 	= @sUnionWhereDueDate+char(10)+"and AX.CASEID = C.CASEID)" 	
		
		Set @sWhereFilterReminder= @sWhereReminder+char(10)+"and ERX.CASEID = C.CASEID)"	
		
					   -- Embed the Cases derived table into the 'From' clause.
		Set @sUnionJoinPredicate = ' C on (C.CaseKey = ER.CASEID)'

		Set @sUnionWhereFromDueDate 	= char(10)+'and exists' 
					  	+char(10)+'(Select 1 '
					  	+@sUnionWhereFromDueDate 

		Set @sUnionWhereDueDate	 =  	@sUnionWhereDueDate
					  	+char(10)+"and (AX.EMPLOYEENO = A.EMPLOYEENO"
					  	+char(10)+"and  AX.ALERTSEQ = A.ALERTSEQ))"	
				
		Set @sWhereFilter		= replace(@sWhereFilter, 
						  'and XC.CASEID=C.CASEID)', 
						  'and XC.CASEID=C.CASEID')		

		Set @sWhereFromReminder = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromReminder 

		Set @sWhereReminder 	= @sWhereReminder
					+char(10)+"and (ERX.EMPLOYEENO = ER.EMPLOYEENO"
					+char(10)+"and ERX.MESSAGESEQ = ER.MESSAGESEQ))"   


		-- When @bIsGeneral is set to 1, duedates that are not related to a case are included.
		If @bIsGeneral = 1 and isnull(@sCaseQuickSearch,'') = ''
		Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate + char(10) + "and (A.CASEID = C.CaseKey or (A.CASEID is null and ER.CASEID is null))"				
		End 
		-- Otherwise, exclude General reminders.
		Else Begin
			Set @sUnionWhereDueDate = @sUnionWhereDueDate + char(10) + "and (A.CASEID = C.CaseKey)"							
		End
						  
		Set @sCTE_Cases = @sCTE_Cases               +
				  @sCTE_CasesSelect         + char(10)+
				  @sUnionWhereFromDueDate   + char(10)+
				  @sUnionWhereFilterDueDate + CHAR(10)+
				  @sWhereFromReminder       + CHAR(10)+
				  @sWhereFilterReminder     +')'

		If @bUseTempTables=1
		Begin
			Set @sCTE = ''
			
			Set @sGetCasesOnlySql = ';with '   +char(10)+
						@sCTE_Cases+char(10)+
						'select * into '+@sCaseIdsTempTable+' from CTE_Cases'
						
			Set @sPopulateTempCaseTableSql =
						'SET ANSI_NULLS OFF;'     +char(10)+
						'with '                   +char(10)+
						@sCTE_CaseNameSequence+','+char(10)+
						@sCTE_CaseDetails         +char(10)+
						'select * into '+@sCasesTempTable+' from CTE_CaseDetails'
			if (@pbPrintSQL = 1)
			Begin
				print @sGetCasesOnlySql
				print ''
				print @sPopulateTempCaseTableSql
			End

			-- Populate the temp case table
			exec (@sGetCasesOnlySql)
			exec (@sPopulateTempCaseTableSql)
		End
		Else Begin 
			Set @sCTE =	'with '                   +char(10)+
					@sCTE_CaseNameSequence+','+char(10)+
					@sCTE_Cases           +','+char(10)+
					@sCTE_CaseDetails         +char(10)
		End

		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbReturnResultSet=1
			Begin			
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; ' 
					Print @sCTE
					Print @sUnionSelectDueDate
					Print @sUnionFromReminders
					Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
					Print @sUnionJoinPredicate
					Print @sUnionFromDueDate
					Print @sUnionWhereFromDueDate						
					Print @sUnionWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate			
				End
		
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' 
					+ @sCTE
					+ @sUnionSelectDueDate + @sUnionFromReminders 
					+ @sCasesTempTable + @sUnionJoinPredicate
					+ @sUnionFromDueDate + @sUnionWhereFromDueDate  
					+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder + @sOrderDueDate)
						
					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' 
					+ @sCTE
					+ @sUnionSelectDueDate + @sUnionFromReminders 
					+ 'CTE_CaseDetails'  + @sUnionJoinPredicate
					+ @sUnionFromDueDate + @sUnionWhereFromDueDate  
					+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder + @sOrderDueDate)
						
					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
			End
		End
		-- Paging required
		Else Begin
			Set @sTopSelectList1 = replace(@sUnionSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  

			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as ResultSorted'+char(10)+
					     ') as ResultWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar) 
			
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; '
					Print @sCTE
					Print @sOpenWrapper
					Print @sTopSelectList1
					Print @sUnionFromReminders
					Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
					Print @sUnionJoinPredicate
					Print @sUnionFromDueDate
					Print @sUnionWhereFromDueDate						
					Print @sUnionWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate			
					Print @sCloseWrapper
				End		
		
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' 
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1 + @sUnionFromReminders  
						+ @sCasesTempTable + @sUnionJoinPredicate
						+ @sUnionFromDueDate + @sUnionWhereFromDueDate  
						+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder + @sOrderDueDate
						+ @sCloseWrapper)

					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' 
						+ @sCTE
						+ @sOpenWrapper
						+ @sTopSelectList1  + @sUnionFromReminders  
						+ 'CTE_CaseDetails' + @sUnionJoinPredicate
						+ @sUnionFromDueDate + @sUnionWhereFromDueDate  
						+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder + @sOrderDueDate
						+ @sCloseWrapper)

					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
			End

			If @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin		
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sUnionFromReminders 
						+ @sCasesTempTable + @sUnionJoinPredicate
						+ @sUnionFromDueDate + @sUnionWhereFromDueDate  
						+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder)

					Set @nErrorCode =@@ERROR
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; '  + @sCTE + @sCountSelect + @sUnionFromReminders 
						+ 'CTE_CaseDetails'   + @sUnionJoinPredicate
						+ @sUnionFromDueDate  + @sUnionWhereFromDueDate  
						+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder)

					Set @nErrorCode =@@ERROR
				End		
			End
		End		
	End	
	-- Both Events and Ad Hoc are to be returned.
	Else 
	If @bHasCase  = 1
	and @bIsAdHoc = 1
	and @bIsEvent = 1
	Begin		
		Set @sSelectDueDate = 'Select '+@sSelectDueDate
				  
		Set @sFromDueDate =' C	on (C.CaseKey = ER.CASEID)'
				 +char(10)+"left join CASEEVENT CE		on (CE.CASEID = ER.CASEID"
				 +char(10)+"					and CE.EVENTNO = ER.EVENTNO"
				 +char(10)+"					and CE.CYCLE = ER.CYCLENO"
				 +char(10)+"					and CE.CASEID = C.CaseKey)"
			 	 +char(10)+"left join EVENTS E			on (E.EVENTNO = CE.EVENTNO)"
				 +char(10)+"left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX"
				 +char(10)+"                                    on (OX.CASEID = CE.CASEID"
				 +char(10)+"					and OX.ACTION = E.CONTROLLINGACTION)"
				 +char(10)+"left join EVENTCONTROL EC		on (EC.EVENTNO = CE.EVENTNO"
			  	 +char(10)+"					and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))"
				 +char(10)+"left join ALERT A			on (A.EMPLOYEENO = ER.ALERTNAMENO"
				 +char(10)+"					and A.SEQUENCENO = ER.SEQUENCENO"
				 +char(10)+"					and ER.SOURCE    = 1"
				 +char(10)+"					and ER.EVENTNO IS NULL"
				 +char(10)+"					and (A.CASEID = ER.CASEID"
				 +char(10)+"					or (A.REFERENCE = ER.REFERENCE"
				 +char(10)+"					and A.CASEID is null"
				 +char(10)+"					and ER.CASEID is null)"				 
				 +char(10)+"					or (A.NAMENO = ER.NAMENO)))"				 
				 +char(10)+@sFromDueDate 				
				 +char(10)+'WHERE 1=1'
				 +char(10)+@sWhereFilterEventText
				 +char(10)+@sWhereDateRange

		-- When @bIsGeneral is set to 1, duedates that are not related to a case are included.
		If @bIsGeneral = 1 and isnull(@sCaseQuickSearch,'') = ''
		Begin
			Set @sFromDueDate = @sFromDueDate + char(10) + "and (( A.CASEID = C.CaseKey OR (A.CASEID IS NULL AND C.CaseKey IS NULL)) 
										OR CE.CASEID = C.CaseKey)"							
		End 
		-- Otherwise, exclude General reminders.
		Else Begin
			Set @sFromDueDate = @sFromDueDate + char(10) + "and (A.CASEID = C.CaseKey OR CE.CASEID = C.CaseKey)"							
		End
		
		-- RFC61473
		-- As a result of some code rearrangement the importance level for 
		-- an Alert was no longer being returned.  
		If  CHARINDEX('ALERT A',@sFromDueDate)>0
		and CHARINDEX('left join IMPORTANCE IMPC',@sFromDueDate)>0
		and CHARINDEX('on (IMPC.IMPORTANCELEVEL =COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL))', @sFromDueDate)>0
			Set @sFromDueDate=REPLACE(@sFromDueDate, 'on (IMPC.IMPORTANCELEVEL =COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL))',
			                                         'on (IMPC.IMPORTANCELEVEL =COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL, A.IMPORTANCELEVEL))')
			

		Set @sWhereFromDueDate  = char(10)+"and (CE.EVENTDUEDATE is null"
					 +char(10)+" or (CE.EVENTDUEDATE is not null"
					 +char(10)+'     and exists' 
					 +char(10)+'    (Select 1 '
					 +@sWhereFromDueDate

		Set @sWhereFromReminder = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromReminder 

		Set @sWhereReminder 	= @sWhereReminder
					+char(10)+"and ERX.EMPLOYEENO = ER.EMPLOYEENO"
					+char(10)+"and ERX.MESSAGESEQ = ER.MESSAGESEQ)"

		-- Include the Events and Reminders 'Where' clauses into the Cases 'Where' clause 
		-- to improve performance.		 
		Set @sWhereFilterDueDate = @sWhereDueDate+char(10)+"and CEX.CASEID = C.CASEID)"

		Set @sWhereFilterReminder= @sWhereReminder+char(10)+"and ERX.CASEID = C.CASEID)"
					   
		If charindex('join EMPLOYEEREMINDER ERX',@sWhereFromDueDate)=1
			Set @sWhereDueDate = @sWhereDueDate
					    +char(10)+"and ERX.EMPLOYEENO=ER.EMPLOYEENO"
					    +char(10)+"and ERX.MESSAGESEQ=ER.MESSAGESEQ"													
		
		Set @sWhereDueDate	 = @sWhereDueDate
					  +char(10)+"and (CEX.CASEID = CE.CASEID"
					  +char(10)+"and  CEX.EVENTNO = CE.EVENTNO"
					  +char(10)+"and  CEX.CYCLE = CE.CYCLE))"  +char(10)+") )"

	  
		Set @sCTE_Cases = @sCTE_Cases+
				  @sCTE_CasesSelect + CHAR(10)+
				  @sWhereFilter+')'

		If @bUseTempTables=1
		Begin
			Set @sCTE = ''
			
			Set @sGetCasesOnlySql = ';with '   +char(10)+
						@sCTE_Cases+char(10)+
						'select * into '+@sCaseIdsTempTable+' from CTE_Cases'
						
			Set @sPopulateTempCaseTableSql =
						'SET ANSI_NULLS OFF;'     +char(10)+
						'with '                   +char(10)+
						@sCTE_CaseNameSequence+','+char(10)+
						@sCTE_CaseDetails         +char(10)+
						'select * into '+@sCasesTempTable+' from CTE_CaseDetails'

			if (@pbPrintSQL = 1)
			Begin
				print @sGetCasesOnlySql
				print ''
				print @sPopulateTempCaseTableSql
			End

			-- Populate the temp case table
			exec (@sGetCasesOnlySql)
			exec (@sPopulateTempCaseTableSql)
		End
		Else Begin 
			Set @sCTE =	'with '                   +char(10)+
					@sCTE_CaseNameSequence+','+char(10)+
					@sCTE_Cases           +','+char(10)+
					@sCTE_CaseDetails         +char(10)
		End

		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; ' 
					Print @sCTE
					Print @sSelectDueDate
					Print @sFromReminders		
					Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
					Print @sFromDueDate
					Print @sWhereFromDueDate						
					Print @sWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate
				End


				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate + @sFromReminders
						+ @sCasesTempTable
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder  
						+ @sWhereReminder + @sOrderDueDate)
						
					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sSelectDueDate + @sFromReminders
						+ 'CTE_CaseDetails'
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder  
						+ @sWhereReminder + @sOrderDueDate)
						
					Select 	@nErrorCode =@@ERROR,
						@pnRowCount = @@RowCount
				End
			End
		End
		-- Paging required
		Else Begin

			If @sUnionSelectDueDate is not null
			Begin
				Set @sTopSelectList1  = replace(@sSelectDueDate,     'Select', 'Select TOP 100 Percent ')
				Set @sTopUnionSelect1 = replace(@sUnionSelectDueDate,'Select ','Select TOP 100 Percent ')
			End
			Else Begin
				Set @sTopSelectList1 = replace(@sSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			End
	
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows from ('  
			
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as ResultSorted'+char(10)+
					     ') as ResultWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar)

			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; '
					Print @sCTE
					Print @sOpenWrapper
					Print @sTopSelectList1
					Print @sFromReminders	
					Print CASE WHEN(@bUseTempTables=1) THEN @sCasesTempTable ELSE 'CTE_CaseDetails' END
					Print @sFromDueDate
					Print @sWhereFromDueDate						
					Print @sWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate
					Print @sCloseWrapper
				End

				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; '
						+ @sCTE 
						+ @sOpenWrapper
						+ @sTopSelectList1 + @sFromReminders
						+ @sCasesTempTable
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder  
						+ @sWhereReminder + @sOrderDueDate
						+ @sCloseWrapper)
					
					Select 	@nErrorCode = @@ERROR,
						@pnRowCount = @@RowCount
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; '
						+ @sCTE 
						+ @sOpenWrapper
						+ @sTopSelectList1 + @sFromReminders
						+ 'CTE_CaseDetails'
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder  
						+ @sWhereReminder + @sOrderDueDate
						+ @sCloseWrapper)
					
					Select 	@nErrorCode = @@ERROR,
						@pnRowCount = @@RowCount
				End
			End

			If @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin
				If @bUseTempTables=1
				Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sSelectDueDate + @sFromReminders
						+ @sCasesTempTable
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder  
						+ @sWhereReminder + ' ) C ')

					Set @nErrorCode =@@ERROR
				End
				Else Begin
					Exec ('SET ANSI_NULLS OFF; ' + @sCTE + @sCountSelect + @sSelectDueDate + @sFromReminders
						+ 'CTE_CaseDetails'
						+ @sFromDueDate + @sWhereFromDueDate + @sWhereDueDate + @sWhereFromReminder  
						+ @sWhereReminder + ' ) C ')

					Set @nErrorCode =@@ERROR
				End
			End
		End		
	End	
	Else 
	-- Only General Ad Hoc Due Dates are to be selected.
	If @bHasCase = 0
	Begin
		Set @sUnionSelectDueDate = 'Select '+@sUnionSelectDueDate 	

		Set @sUnionFromReminders = 				    char(10) + "from EMPLOYEEREMINDER ER" +
				  CASE WHEN @bExternalUser = 1 THEN char(10) + "join dbo.fn_FilterUserNames("+CAST(@pnUserIdentityId as varchar(11))+", 1) FN"
								   +char(10) + "			on (FN.NAMENO = ER.EMPLOYEENO)"					 			   								   
				  END	+char(10)+"left join ALERT A	on (A.EMPLOYEENO = ER.ALERTNAMENO"
					+char(10)+"			and A.SEQUENCENO = ER.SEQUENCENO"
					+char(10)+"			and ER.SOURCE    = 1"
					+char(10)+"			and ER.EVENTNO IS NULL"
					+char(10)+"			and (A.CASEID = ER.CASEID"
					+char(10)+"			or (A.REFERENCE = ER.REFERENCE"
					+char(10)+"			and A.CASEID is null"	
					+char(10)+"			and ER.CASEID is null)"					
					+char(10)+"			or (A.NAMENO = ER.NAMENO)))"					
					+char(10)+@sUnionFromDueDate
					+char(10)+'WHERE 1=1'

		Set @sUnionWhereFromDueDate =
					 char(10)+'and exists' 
					+char(10)+'(Select 1 '
					+@sUnionWhereFromDueDate 

		Set @sUnionWhereDueDate	 =  	
					@sUnionWhereDueDate
					+char(10)+"and  AX.CASEID is null and ER.CASEID is null"
					+char(10)+"and (AX.EMPLOYEENO = A.EMPLOYEENO"
					+char(10)+"and  AX.ALERTSEQ = A.ALERTSEQ))"				

		Set @sWhereFromReminder = char(10)+'and exists' 
					 +char(10)+'(Select 1 '
					 +@sWhereFromReminder 

		Set @sWhereReminder 	= @sWhereReminder
					+char(10)+"and (ERX.EMPLOYEENO = ER.EMPLOYEENO"
					+char(10)+"and ERX.MESSAGESEQ = ER.MESSAGESEQ))"   

		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; ' 
					Print @sUnionSelectDueDate
					Print @sUnionFromReminders
					Print @sUnionWhereFromDueDate
					Print @sUnionWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate
				End		
	
				Exec ('SET ANSI_NULLS OFF; ' 
					+ @sUnionSelectDueDate + @sUnionFromReminders + @sUnionWhereFromDueDate
					+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder + @sOrderDueDate)
					
				Select 	@nErrorCode = @@ERROR,
					@pnRowCount = @@RowCount
			End
		End
		-- Paging required
		Else Begin
			Set @sTopSelectList1 = replace(@sUnionSelectDueDate,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
			
			Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  
			
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrderDueDate+') as MainRowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as ResultSorted'+char(10)+
					     ') as ResultWithRow'+char(10)+
					     'where MainRowKey>='+cast(@pnPageStartRow as varchar)+' and MainRowKey<='+cast(@pnPageEndRow as varchar)

			
			If @pbReturnResultSet=1
			Begin
				If @pbPrintSQL = 1
				Begin
					Print 'SET ANSI_NULLS OFF; '
					Print @sOpenWrapper
					Print @sTopSelectList1
					Print @sUnionFromReminders
					Print @sUnionWhereFromDueDate
					Print @sUnionWhereDueDate
					Print @sWhereFromReminder
					Print @sWhereReminder
					Print @sOrderDueDate
					Print @sCloseWrapper
				End

				Exec ('SET ANSI_NULLS OFF; ' 
					+ @sOpenWrapper
					+ @sTopSelectList1 + @sUnionFromReminders + @sUnionWhereFromDueDate 
					+ @sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder + @sOrderDueDate
					+ @sCloseWrapper)
				
				Select 	@nErrorCode = @@ERROR,
					@pnRowCount = @@RowCount
			End
			

			If @pnRowCount<@pnPageEndRow
			and isnull(@pnPageStartRow,1)=1
			and @nErrorCode=0
			Begin
				set @sSQLString='select @pnRowCount as SearchSetTotalRows'  
		
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@pnRowCount	int',
							  @pnRowCount=@pnRowCount
			End
			Else If isnull(@pbGetTotalRowCount,0)=0
			     and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End
			Else If @nErrorCode = 0
			Begin
				Exec ('SET ANSI_NULLS OFF; ' + @sCountSelect + @sUnionFromReminders + @sUnionWhereFromDueDate + 
					@sUnionWhereDueDate + @sWhereFromReminder + @sWhereReminder)
			
				Set @nErrorCode =@@ERROR
			End
		End		
	End
End

if (@bHasCase = 1)
Begin
	if exists (select * from tempdb.dbo.sysobjects where name = @sCaseIdsTempTable)
	Begin
		exec ('drop table ' + @sCaseIdsTempTable)
	End
	
	if exists (select * from tempdb.dbo.sysobjects where name = @sCasesTempTable)
	Begin
		exec ('drop table ' + @sCasesTempTable)
	End
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_ListDueDate  to public
GO
