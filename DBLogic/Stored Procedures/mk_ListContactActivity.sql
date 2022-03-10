-----------------------------------------------------------------------------------------------------------------------------
-- Creation of mk_ListContactActivity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[mk_ListContactActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.mk_ListContactActivity.'
	drop procedure dbo.mk_ListContactActivity
	print '**** Creating procedure dbo.mk_ListContactActivity...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.mk_ListContactActivity
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 190, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)	
AS

-- PROCEDURE :	mk_ListContactActivity
-- VERSION :	36
-- DESCRIPTION:	Returns the requested contact Activity and Attachment information, for activities that match 
--		the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 Dec 2004  TM	RFC2048	1	Procedure created 
-- 16 Dec 2004	TM	RFC2048	2	Make filtering on Reference and Word case insensitive. Do not translate 
--					the following columns: AttachmentName, AttachmentDescription, 
--					ActivitySummary, ActivityNotes
-- 16 Dec 2004	TM	RFC2048	3	Add a new <ContactKey Operator=""></ContactKey> filter criteria.
-- 07 Jan 2005	TM	RFC1838	4	Populate ActivityCategory and ActivityType drop downs.
-- 31 Jan 2005	TM	RFC1838	5	Change CallDirection to Direction and add operator to Direction and CallStatus.	
-- 15 Feb 2005	TM	RFC1743	6	Add ActivityCheckSum column. Use Activity.LongNotes column if the LongFlag = 1 and
--					Activity.Notes otherwise to extract the 'Notes' column. 
-- 03 Mar 2005	TM	RFC2320	7	Cater for the data item id 'NULL'.
-- 04 Apr 2005	TM	RFC2490	8	Change the RegardingNameKey column name to be RegardingKey.
-- 15 May 2005	JEK	RFC2508	9	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 27 May 2005	TM	RFC2623	10	Correct the syntax for filtering on the PUBLICFLAG.
-- 02 Jun 2005	TM	RFC2507	11	Make any positive period range (From and To) values negative. 
-- 03 Jun 2005	TM	RFC2567	12	Add new HasAttachments filter criteria.
-- 03 Jun 2005	TM	RFC2651	13	Ensure that the attachment key returned is correct for the activity. 
--					Improve the performance of the attachments count logic.
-- 06 Jun 2005	TM	RFC2630	14	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 30 Jun 2005	TM	RFC2545	15	When setting the @nNullGroupNameKey variable correct the datatype from smallint
--					to an integer. Cast @nNullGroupNameKey as varchar(10) instead of the varchar(5).
-- 08 Jul 2005	TM	RFC2833	16	Make a 'Where' clause independent for m 'From' and 'Select' clauses.
-- 24 Oct 2005	TM	RFC3024	17	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 09 Mar 2006	TM	RFC3465 18	Add three new parameters @pnPageStartRow, @pnPageEndRow and implement
--					SQL Server Paging.
-- 22 May 2006	SW	RFC2985	19	Implement new filter criteria ContactPersonKey/IsMyself, ContactAccountKey, Summary, Client Reference.
-- 07 Jun 2006	SW	RFC2985	20	Allow typekey filtering for quick search
-- 15 Jun 2006	SW	RFC3967	21	If an external user is performing a search for attachments (HasAttchment=1),
--					do not filter the search results according to the access account.
-- 20 Jun 2006	SW	RFC4001	22	Case insensitive search on Summary, General Reference and Client Reference
-- 13 Dec 2006	MF	14002	23	Paging should not do a separate count() on the database if the rows returned
--					are less than the maximum allowed for.
-- 03 Apr 2008	AT	RFC6340	24	Fixed Contact Person 'Not Equal' to search.
-- 25 Sep 2008	SF	RFC5745 25	Add AttachmentSequenceKey
-- 27 Mar 2009	JV	RFC7539 26	Fixed issue with ACTIVITYDATE when PeriodRangeTo is null
-- 07 Jul 2011	DL	RFC10830 27	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 19 Oct 2011	LP	RFC6896 28	Allow filtering by Event and Cycle.
--					Return EventDescription and EventCycle columns.
-- 02 Feb 2012	vql	RFC7336 29	Can't view an Attachment when there is not Attachment Name.
-- 05 Jul 2013	vql	R13629	30	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 24 Jul 2014	MF	R37694	31	If Case (but not Event) is being requested then also return attachments associated with Prior Art linked to the Case.
-- 27 May 2015  MS      R47576  32       Increased size of @sSummary from 100 to 254
-- 02 Nov 2015	vql	R53910	33	Adjust formatted names logic (DR-15543).
-- 15 Apr 2016	MF	R60396	34	Attachments against Case Events need to join on CYCLE as well to avoid the document appearing multiple times for each
--					cycle of the same Event.
-- 31 Oct 2018	DL	DR-45102	35	Replace control character (word hyphen) with normal sql editor hyphen
-- 14 Nov 2018  AV  75198/DR-45358	36   Date conversion errors when creating cases and opening names in Chinese DB


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	ActivityCategory
--	ActivityCheckSum (RFC1743)
--	ActivityDate
--	ActivityKey
--	ActivityTime
--	ActivityType
--	AttachmentCount
--	AttachmentSequenceKey (RFC5745)
--	CallerKey
--	CallerName
--	CallerNameCode
--	CallStatus (RFC1838)
--	CaseKey
--	CaseReference
--	ClientReference
--	ContactKey
--	ContactName
--	ContactNameCode
--	EventCycle (6896)
--	EventDescription (6896)
--	FirstAttachmentFilePath
--	IsIncomingCall
--  	IsIncomplete
--	IsOutgoingCall
--	Notes
--	Reference
--	ReferredToKey
--	ReferredToName
--	ReferredToNameCode
--	RegardingKey
--	RegardingName
--	RegardingNameCode
--	RowCount
--	StaffKey
--	StaffName
--	StaffNameCode
--	Summary
--	AttachmentName
--	AttachmentType
--	AttachmentDescription
--	FilePath
--	IsPublic
--	Language
--	PageCount

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	A
--	AA
--	AT
--	ATCH
--	C
--	NC1
--	NC2
--	NC3
--	NC4
--	NULF
--	TC
--	TC2
--	TC3
--	TC4

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @bIsExternalUser			bit
Declare @nUserAccountKey			int

Declare @sSQLString				nvarchar(max)
Declare @sList					nvarchar(max)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		    		ID		nvarchar(100)	collate database_default not null,
		    		SORTORDER	tinyint		null,
		    		SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,				
				DOCITEMKEY	int		null
			  )

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy table (
				Position	tinyint		not null,
				Direction	nvarchar(5)	collate database_default not null,
				ColumnName	nvarchar(1000)	collate database_default not null,
				PublishName	nvarchar(50)	collate database_default null,
				ColumnNumber	tinyint		not null
			)

Declare @nOutRequestsRowCount			int
Declare @nColumnNo				tinyint
Declare @sColumn				nvarchar(100)
Declare @sPublishName				nvarchar(50)
Declare @sQualifier				nvarchar(50)
Declare @nOrderPosition				tinyint
Declare @sOrderDirection			nvarchar(5)
Declare @sTableColumn				nvarchar(1000)
Declare @sComma					nchar(2)	-- initialised when a column has been added to the Select.

-- Declare Filter Variables	
Declare	@nActivityKey				int		-- The key of the activity.	
Declare	@nActivityKeyOperator			tinyint		
Declare	@nContactPersonKey 			int		-- The key of an individual involved in a contact. May be either the Contact or the Name.
Declare	@nContactPersonKeyOperator		tinyint		
Declare	@bIsContact				bit		-- When set to 1, activities are returned where the person was acting as the Contact.	
Declare	@bIsName				bit		-- When set to 1, activities are returned where the person was acting as the Name.
Declare @bIsMyself				bit		-- When set to 1, indicates that the search should be conducted for the user currently logged on
Declare @nContactNameKey			int		-- The key of a name involved in a contact.
Declare @nContactNameKeyOperator		tinyint
Declare @nContactKey				int		-- The key of the contact.
Declare @nContactKeyOperator			tinyint
Declare @nContactAccountKey			int		-- External access account key.
Declare @nContactAccountKeyOperator		tinyint
Declare @nStaffKey				int		-- The key of the staff member responsible for the activity.
Declare @nStaffKeyOperator			tinyint
Declare	@nCallerKey				int		-- The key of the staff member who made the call.
Declare @nCallerKeyOperator			tinyint
Declare @nCaseKey 				int		-- The key of the case the activity relates to.
Declare @nCaseKeyOperator			tinyint
Declare @nEventKey				int		-- The key of the case event the activity relates to. (RFC6896)
Declare @nEventCycle				smallint	-- The cycle of the case event the activity relates to. (RFC6896)
Declare @nReferredToKey 			int		-- The key of the staff member the activity has been referred to.
Declare @nReferredToKeyOperator			tinyint
Declare @sReference 				nvarchar(20)	-- The reference for the activity.
Declare	@nReferenceOperator			tinyint
Declare @nCategoryKey 				int		-- The category of activity.
Declare @nCategoryKeyOperator			tinyint
Declare @nTypeKey 				int		-- The type of activity.
Declare	@nTypeKeyOperator			tinyint
Declare @nDateRangeOperator			tinyint		-- Return activity dates between these dates. From and/or To value must be provided.
Declare @dtDateRangeFrom			datetime	
Declare @dtDateRangeTo				datetime		
Declare @nPeriodRangeOperator			tinyint		-- A period range is converted to a date range by subtracting the from/to period to the current date. Returns the activity dates within the resulting date range.
Declare @sPeriodRangeType			nvarchar(2)	-- D - Days; W - Weeks; M - Months; Y - Years
Declare @nPeriodRangeFrom			smallint	
Declare @nPeriodRangeTo				smallint		
Declare @sWord					nvarchar(100)	-- Search for a word. Case insensitive search.
Declare @nWordOperator				tinyint
Declare @bUseSummary				bit		-- Indicates that the search should be conducted in the Summary.
Declare @bUseNotes				bit		-- Indicates that the search should be conducted in the Notes.
Declare @nDirectionOperator			tinyint
Declare @bIsIncoming				bit		-- When true, activities are returned that involve incoming calls (CallType = 0).
Declare @bIsOutgoing				bit		-- When true, activities are returned that involve outgoing calls (CallType = 1).
Declare @nCallStatusOperator			tinyint
Declare @bIsContacted				bit		-- When true, activities are returned where the person called has been contacted. (CallStatus = 0).
Declare @bIsLeftMessage				bit		-- When true, activities are returned where a message has been left for the contact. (CallStatus = 2).
Declare @bIsNoAnswer				bit		-- When true, activities are returned where a call has been made without an answer. (CallStatus = 1),
Declare @bIsBusy				bit		-- When true, activities are returned where the line was busy. (CallStatus = 3).
Declare @bIsComplete				bit		-- When true, activities are returned that have been completed.
Declare @bIsIncomplete				bit		-- When true, activities are returned that have not been completed.
Declare @nTopRowCount				int		-- Return this many rows from the top of the search results.
Declare @sQuickSearch				nvarchar(154)	-- A generic search string used to search for appropriate activities based on a variety of criteria. Case insensitive search.If provided, all other filter parameters are ignored.
Declare @sNameXMLFilterCriteria			nvarchar(500)	-- Filter criteria XML for a naw_ConstractNameWhere.
Declare @sNameFilter				nvarchar(4000)
Declare @nBelongsToNameKey 			int		-- The key of the name the activities belong to.
Declare @nBelongsToNameKeyOperator		tinyint	
Declare @bIsCurrentNameUser			bit		-- Indicates that the NameKey of the current user should be used as the NameKey value.
Declare @nMemberOfGroupKey			smallint	-- The key of a name group (family). Activities belonging to any of the names that are members of the group are returned.
Declare @nMemberOfGroupKeyOperator		tinyint
Declare @nNullGroupNameKey			int		-- If the user does not belong to a group and 'MemberOfGroupKey for a current user' is selected use @nNullGroupNameKey to join to the Name table.
Declare @bIsCurrentMemberOfGroupUser		bit		-- Indicates that the Name.FamilyNo of the current user should be used as the MemberOfGroupKey value.
Declare @bIsCaller				bit		-- If true return activities where the name(s) appear as caller.
Declare @bIsStaff				bit		-- If true return activities where the name(s) appear as staff.
Declare @bIsReferredTo				bit		-- If true return activities where the name(s) appear as referred to.
Declare	@bHasAttachments			bit		-- When set to true then only Attachments information is required. If there are any Activity columns selected, only activities that have attachments will be returned.
Declare @sSummary				nvarchar(254)	-- The summary for the activity
Declare @nSummaryOperator			tinyint	
Declare @sClientReference			nvarchar(50)	-- The client reference for the activity
Declare @nClientReferenceOperator		tinyint	

Declare @sActivityChecksumColumns		nvarchar(max)	-- A comma separated list of all columns of the Activity table.

Declare @nCount					int	 	-- Current table row being processed.
Declare @sSelect				nvarchar(max)
Declare @sFrom					nvarchar(max)
Declare @sWhereFrom				nvarchar(max)
Declare @sWhere					nvarchar(max)
Declare @sOrder					nvarchar(max)
Declare @sCountSelect				nvarchar(max)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare	@sTopSelectList1			nvarchar(max)	-- the SQL list of columns to return modified for paging

Declare @idoc 					int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr					nvarchar(10)

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set 	@nErrorCode				=0
Set     @nCount					= 1
Set 	@sFrom					='From ACTIVITY A'

-- Initialise the WHERE clause with a test that will always be true and will have no performance
-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
Set 	@sWhere 				= char(10)+"WHERE 1=1"
Set     @sWhereFrom				= char(10)+"From ACTIVITY XA"

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

-- Extract the filter criteria first as they may affect the Select statement,
-- i.e. 'Select Top x' may be required.

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
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
	--    Case Insensitive searching where required)   

	-- If the Quick Search filter criteria are not null then ignore all the other filter criteria except TypeKey:  
	Set @sSQLString = 	
	"Select @nTypeKey=TypeKey,"+CHAR(10)+
	"@nTypeKeyOperator=TypeKeyOperator,"+CHAR(10)+	
	"@sQuickSearch=upper(QuickSearch)"+CHAR(10)+
	"from	OPENXML (@idoc, '/mk_ListContactActivity/FilterCriteria',2)"+CHAR(10)+
		"WITH ("+CHAR(10)+
		      "TypeKey			int			'TypeKey/text()',"+CHAR(10)+	
		      "TypeKeyOperator		tinyint			'TypeKey/@Operator/text()',"+CHAR(10)+
		      "QuickSearch		nvarchar(254)		'QuickSearch/text()'"+CHAR(10)+
		      ")"	

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sQuickSearch 		nvarchar(254)		output,
				  @nTypeKey			int			output,
				  @nTypeKeyOperator		tinyint			output',
				  @idoc				= @idoc,
				  @sQuickSearch 		= @sQuickSearch		output,
				  @nTypeKey			= @nTypeKey		output,
				  @nTypeKeyOperator		= @nTypeKeyOperator	output

	If @sQuickSearch is not null
	and @nErrorCode = 0
	Begin	
		-- RFC2985 For external users, this is a case insensitive search that will return activities where 
		-- either the Summary or the Client Reference begins with the entered text.
		If @bIsExternalUser = 1
		Begin
			Set @sWhere = @sWhere + char(10) + "and	(UPPER(A.SUMMARY) like " + dbo.fn_WrapQuotes(UPPER(@sQuickSearch) + '%', 0, @pbCalledFromCentura)
			                      + char(10) + "	 or UPPER(A.CLIENTREFERENCE) like " + dbo.fn_WrapQuotes(UPPER(@sQuickSearch) + '%', 0, @pbCalledFromCentura) + ")"
		End
		Else
		Begin
			-- Prepare XML Filter Criteria for the Name Search stored procedure:
			Set @sNameXMLFilterCriteria = N'<?xml version="1.0" ?> 
							  <naw_ListName>
							   	<FilterCriteriaGroup>		
								  <FilterCriteria BooleanOperator="">			
									<AnySearch>'+@sQuickSearch+'</AnySearch>
								   </FilterCriteria>	
								</FilterCriteriaGroup>														
							  </naw_ListName>'
	
			-- Obtain the filter criteria from the Name Search:
			exec @nErrorCode = dbo.naw_ConstructNameWhere
				        @psReturnClause			= @sNameFilter		output,
					@pnUserIdentityId		= @pnUserIdentityId,
					@psCulture			= @psCulture,
					@ptXMLFilterCriteria		= @sNameXMLFilterCriteria,
					@pnFilterGroupIndex		= 1
	
			Set @sWhere = @sWhere	+char(10)+"and exists (Select 1"
						+char(10)+ @sNameFilter
						-- return activities where either the contact name or the related name 
						--  match the quick search criteria.  
						+char(10)+ "and (XN.NAMENO = A.NAMENO or XN.NAMENO = A.RELATEDNAME))"
		End

		If @nTypeKey is not NULL
		or @nTypeKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and A.ACTIVITYTYPE"+dbo.fn_ConstructOperator(@nTypeKeyOperator,@Numeric,@nTypeKey, null,0)
		End
	End
	Else
	If @nErrorCode = 0	
	Begin	
		Set @sSQLString = 	
		"Select @nActivityKey=ActivityKey,"+CHAR(10)+
			"@nActivityKeyOperator=ActivityKeyOperator,"+CHAR(10)+
			"@nContactPersonKey=ContactPersonKey,"+CHAR(10)+
			"@nContactPersonKeyOperator=ContactPersonKeyOperator,"+CHAR(10)+
			"@bIsContact=IsContact,"+CHAR(10)+				
			"@bIsName=IsName,"+CHAR(10)+	
			"@bIsMyself=IsMyself,"+CHAR(10)+	
			"@nContactNameKey=ContactNameKey,"+CHAR(10)+
			"@nContactNameKeyOperator=ContactNameKeyOperator,"+CHAR(10)+
			"@nContactKey=ContactKey,"+CHAR(10)+
			"@nContactKeyOperator=ContactKeyOperator,"+CHAR(10)+
			"@nContactAccountKey=ContactAccountKey,"+CHAR(10)+
			"@nContactAccountKeyOperator=ContactAccountKeyOperator,"+CHAR(10)+
			"@nStaffKey=StaffKey,"+CHAR(10)+
			"@nStaffKeyOperator=StaffKeyOperator,"+CHAR(10)+
			"@nCallerKey=CallerKey,"+CHAR(10)+
			"@nCallerKeyOperator=CallerKeyOperator,"+CHAR(10)+
			"@nCaseKey=CaseKey,"+CHAR(10)+
			"@nCaseKeyOperator=CaseKeyOperator,"+CHAR(10)+
			"@nEventKey=EventKey,"+CHAR(10)+
			"@nEventCycle=EventCycle,"+CHAR(10)+
			"@nReferredToKey=ReferredToKey,"+CHAR(10)+
			"@nReferredToKeyOperator=ReferredToKeyOperator,"+CHAR(10)+
			"@sReference=Reference,"+CHAR(10)+	
			"@nReferenceOperator=ReferenceOperator,"+CHAR(10)+	
			"@nCategoryKey=CategoryKey,"+CHAR(10)+
			"@nCategoryKeyOperator=CategoryKeyOperator,"+CHAR(10)+
			"@nDateRangeOperator=DateRangeOperator,"+CHAR(10)+
			"@dtDateRangeFrom=DateRangeFrom,"+CHAR(10)+
			"@dtDateRangeTo=DateRangeTo,"+CHAR(10)+
			"@nPeriodRangeOperator=PeriodRangeOperator,"+CHAR(10)+
			"@sPeriodRangeType=CASE WHEN PeriodRangeType='D' THEN 'dd'"+CHAR(10)+
					       "WHEN PeriodRangeType='W' THEN 'wk'"+CHAR(10)+
					       "WHEN PeriodRangeType='M' THEN 'mm'"+CHAR(10)+
					       "WHEN PeriodRangeType='Y' THEN 'yy'"+CHAR(10)+
				          "END,"+CHAR(10)+
			"@nPeriodRangeFrom=-PeriodRangeFrom,"+CHAR(10)+
			"@nPeriodRangeTo=-PeriodRangeTo"+CHAR(10)+
		"from	OPENXML (@idoc, '/mk_ListContactActivity/FilterCriteria',2)"+CHAR(10)+
			"WITH ("+CHAR(10)+
			      "ActivityKey		int	'ActivityKey/text()',"+CHAR(10)+
			      "ActivityKeyOperator	tinyint	'ActivityKey/@Operator/text()',"+CHAR(10)+
			      "ContactPersonKey		int	'ContactParty/ContactPersonKey/text()',"+CHAR(10)+	
			      "ContactPersonKeyOperator	tinyint	'ContactParty/ContactPersonKey/@Operator/text()',"+CHAR(10)+
	 		      "IsContact		bit	'ContactParty/ContactPersonKey/@IsContact/text()',"+CHAR(10)+	
			      "IsName			bit	'ContactParty/ContactPersonKey/@IsName/text()',"+CHAR(10)+	
			      "IsMyself			bit	'ContactParty/ContactPersonKey/@IsMyself/text()',"+CHAR(10)+	
			      "ContactNameKey		int	'ContactParty/ContactNameKey/text()',"+CHAR(10)+	
			      "ContactNameKeyOperator	tinyint	'ContactParty/ContactNameKey/@Operator/text()',"+CHAR(10)+	
			      "ContactKey		int	'ContactKey/text()',"+CHAR(10)+
			      "ContactKeyOperator	tinyint	'ContactKey/@Operator/text()',"+CHAR(10)+
			      "ContactAccountKey	int	'ContactAccountKey/text()',"+CHAR(10)+
			      "ContactAccountKeyOperator tinyint 'ContactAccountKey/@Operator/text()',"+CHAR(10)+
			      "StaffKey			int	'StaffKey/text()',"+CHAR(10)+	
			      "StaffKeyOperator		tinyint	'StaffKey/@Operator/text()',"+CHAR(10)+	
			      "CallerKey		int	'CallerKey/text()',"+CHAR(10)+	
			      "CallerKeyOperator	tinyint	'CallerKey/@Operator/text()',"+CHAR(10)+	
			      "CaseKey			int	'CaseKey/text()',"+CHAR(10)+	
			      "CaseKeyOperator		tinyint	'CaseKey/@Operator/text()',"+CHAR(10)+	
			      "EventKey			int	'CaseKey/@EventKey/text()',"+CHAR(10)+
			      "EventCycle		smallint 'CaseKey/@Cycle/text()',"+CHAR(10)+
			      "ReferredToKey		int	'ReferredToKey/text()',"+CHAR(10)+	
			      "ReferredToKeyOperator	tinyint	'ReferredToKey/@Operator/text()',"+CHAR(10)+	
			      "Reference		nvarchar(20)'Reference/text()',"+CHAR(10)+	
			      "ReferenceOperator	tinyint	'Reference/@Operator/text()',"+CHAR(10)+			
			      "CategoryKey		int	'CategoryKey/text()',"+CHAR(10)+
			      "CategoryKeyOperator	tinyint	'CategoryKey/@Operator/text()',"+CHAR(10)+
	 		      "DateRangeOperator	tinyint	'ActivityDate/DateRange/@Operator/text()',"+CHAR(10)+	
			      "DateRangeFrom		datetime 'ActivityDate/DateRange/From/text()',"+CHAR(10)+	
			      "DateRangeTo		datetime 'ActivityDate/DateRange/To/text()',"+CHAR(10)+	
			      "PeriodRangeOperator	tinyint	'ActivityDate/PeriodRange/@Operator/text()',"+CHAR(10)+	
			      "PeriodRangeType		nvarchar(2) 'ActivityDate/PeriodRange/Type/text()',"+CHAR(10)+	
			      "PeriodRangeFrom		smallint 'ActivityDate/PeriodRange/From/text()',"+CHAR(10)+	
			      "PeriodRangeTo		smallint 'ActivityDate/PeriodRange/To/text()'"+CHAR(10)+	
			      ")"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @nActivityKey 		int			output,
					  @nActivityKeyOperator		tinyint			output,
					  @nContactPersonKey		int			output,
					  @nContactPersonKeyOperator	tinyint			output,	
					  @bIsContact			bit			output,				
					  @bIsName			bit			output,	
					  @bIsMyself			bit			output,
					  @nContactNameKey		int			output,		
					  @nContactNameKeyOperator	tinyint			output,		
					  @nContactKey			int			output,
					  @nContactKeyOperator		tinyint			output,
					  @nContactAccountKey		int			output,
					  @nContactAccountKeyOperator	tinyint			output,
					  @nStaffKey			int			output,		
					  @nStaffKeyOperator		tinyint			output,		
					  @nCallerKey			int			output,
					  @nCallerKeyOperator		tinyint			output,
					  @nCaseKey			int			output,
					  @nCaseKeyOperator		tinyint			output,
					  @nEventKey			int			output,
					  @nEventCycle			smallint		output,
					  @nReferredToKey		int			output,
					  @nReferredToKeyOperator	tinyint			output,
					  @sReference			nvarchar(20)		output,
					  @nReferenceOperator		tinyint			output,
					  @nCategoryKey			int			output,
					  @nCategoryKeyOperator		tinyint			output,
					  @nDateRangeOperator		tinyint			output,
					  @dtDateRangeFrom		datetime		output,
					  @dtDateRangeTo		datetime		output,
					  @nPeriodRangeOperator		tinyint			output,
					  @sPeriodRangeType		nvarchar(2)		output,
					  @nPeriodRangeFrom		smallint		output,
					  @nPeriodRangeTo		smallint		output',
					  @idoc				= @idoc,
					  @nActivityKey 		= @nActivityKey		output,
					  @nActivityKeyOperator		= @nActivityKeyOperator	output,
					  @nContactPersonKey		= @nContactPersonKey	output,
					  @nContactPersonKeyOperator	= @nContactPersonKeyOperator output,
					  @bIsContact			= @bIsContact		output,				
					  @bIsName			= @bIsName		output,		
					  @bIsMyself			= @bIsMyself		output,
					  @nContactNameKey 		= @nContactNameKey	output,
					  @nContactNameKeyOperator	= @nContactNameKeyOperator output,
					  @nContactKey			= @nContactKey		output,
					  @nContactKeyOperator		= @nContactKeyOperator	output,
					  @nContactAccountKey		= @nContactAccountKey	output,
					  @nContactAccountKeyOperator	= @nContactAccountKeyOperator output,
					  @nStaffKey			= @nStaffKey		output,
					  @nStaffKeyOperator		= @nStaffKeyOperator 	output,
					  @nCallerKey			= @nCallerKey		output,
					  @nCallerKeyOperator		= @nCallerKeyOperator 	output,
					  @nCaseKey			= @nCaseKey		output,
					  @nCaseKeyOperator		= @nCaseKeyOperator 	output,
					  @nEventKey			= @nEventKey		output,
					  @nEventCycle			= @nEventCycle		output,
					  @nReferredToKey		= @nReferredToKey 	output,
					  @nReferredToKeyOperator	= @nReferredToKeyOperator output,
					  @sReference			= @sReference		output,
					  @nReferenceOperator		= @nReferenceOperator	output,
					  @nCategoryKey			= @nCategoryKey		output,
					  @nCategoryKeyOperator		= @nCategoryKeyOperator output,		
					  @nDateRangeOperator		= @nDateRangeOperator	output,
					  @dtDateRangeFrom		= @dtDateRangeFrom	output,
				 	  @dtDateRangeTo		= @dtDateRangeTo	output,
					  @nPeriodRangeOperator		= @nPeriodRangeOperator output,
					  @sPeriodRangeType		= @sPeriodRangeType 	output,
					  @nPeriodRangeFrom		= @nPeriodRangeFrom	output,
					  @nPeriodRangeTo		= @nPeriodRangeTo	output
					  
		Set @sSQLString = 	
		"Select  @sWord=upper(Word),"+CHAR(10)+
			"@nWordOperator=WordOperator,"+CHAR(10)+
			"@bUseSummary=UseSummary,"+CHAR(10)+
			"@bUseNotes=UseNotes,"+CHAR(10)+			
			"@nCallStatusOperator=CallStatusOperator,"+CHAR(10)+
			"@bIsContacted=IsContacted,"+CHAR(10)+
			"@bIsLeftMessage=IsLeftMessage,"+CHAR(10)+
			"@bIsNoAnswer=IsNoAnswer,"+CHAR(10)+
			"@bIsBusy=IsBusy,"+CHAR(10)+
			"@bIsComplete=IsComplete,"+CHAR(10)+
			"@bIsIncomplete=IsIncomplete,"+CHAR(10)+	
			"@nTopRowCount=TopRowCount,"+CHAR(10)+		
			"@bHasAttachments=HasAttachments,"+CHAR(10)+
			"@sSummary=Summary,"+CHAR(10)+
			"@nSummaryOperator=SummaryOperator,"+CHAR(10)+
			"@sClientReference=ClientReference,"+CHAR(10)+
			"@nClientReferenceOperator=ClientReferenceOperator"+CHAR(10)+
		"from	OPENXML (@idoc, '/mk_ListContactActivity/FilterCriteria',2)"+CHAR(10)+
			"WITH ("+CHAR(10)+
			      "Word			nvarchar(100)	'Word/text()',"+CHAR(10)+	
			      "WordOperator		tinyint		'Word/@Operator/text()',"+CHAR(10)+	
			      "UseSummary		bit		'Word/@UseSummary/text()',"+CHAR(10)+	
			      "UseNotes			bit		'Word/@UseNotes/text()',"+CHAR(10)+	
			      "CallStatusOperator	tinyint		'CallStatus/@Operator/text()',"+CHAR(10)+	
			      "IsContacted		bit		'CallStatus/IsContacted/text()',"+CHAR(10)+	
			      "IsLeftMessage		bit		'CallStatus/IsLeftMessage/text()',"+CHAR(10)+	
			      "IsNoAnswer		bit		'CallStatus/IsNoAnswer/text()',"+CHAR(10)+	
			      "IsBusy			bit		'CallStatus/IsBusy/text()',"+CHAR(10)+	
			      "IsComplete		bit		'ActivityStatus/IsComplete/text()',"+CHAR(10)+	
			      "IsIncomplete		bit		'ActivityStatus/IsIncomplete/text()',"+CHAR(10)+	
			      "TopRowCount		int		'TopRowCount/text()',"+CHAR(10)+
			      "HasAttachments		bit		'HasAttachments/text()',"+CHAR(10)+
			      "Summary			nvarchar(100) 	'Summary/text()',"+CHAR(10)+
			      "SummaryOperator	 	tinyint 	'Summary/@Operator/text()',"+CHAR(10)+
			      "ClientReference		nvarchar(50)	'ClientReference/text()',"+CHAR(10)+
			      "ClientReferenceOperator	tinyint 	'ClientReference/@Operator/text()'"+CHAR(10)+
			      ")"
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @sWord			nvarchar(100)		output,
					  @nWordOperator		tinyint			output,
					  @bUseSummary			bit			output,
					  @bUseNotes			bit			output,
				 	  @nCallStatusOperator		tinyint			output,
					  @bIsContacted			bit			output,
					  @bIsLeftMessage		bit			output,
					  @bIsNoAnswer			bit			output,
					  @bIsBusy			bit			output,
					  @bIsComplete			bit			output,
					  @bIsIncomplete		bit			output,
					  @nTopRowCount			int			output,
					  @bHasAttachments		bit			output,
					  @sSummary			nvarchar(254)		output,
					  @nSummaryOperator		tinyint			output,
					  @sClientReference		nvarchar(50)		output,
					  @nClientReferenceOperator	tinyint			output',
					  @idoc				= @idoc,
					  @sWord			= @sWord		output,
					  @nWordOperator		= @nWordOperator	output,
					  @bUseSummary			= @bUseSummary		output,
					  @bUseNotes			= @bUseNotes		output,
					  @nCallStatusOperator		= @nCallStatusOperator	output,
					  @bIsContacted			= @bIsContacted		output,
					  @bIsLeftMessage		= @bIsLeftMessage	output,
					  @bIsNoAnswer			= @bIsNoAnswer		output,
					  @bIsBusy			= @bIsBusy		output,
					  @bIsComplete			= @bIsComplete		output,
					  @bIsIncomplete		= @bIsIncomplete	output,
					  @nTopRowCount			= @nTopRowCount		output,
					  @bHasAttachments		= @bHasAttachments	output,
					  @sSummary			= @sSummary		output,
					  @nSummaryOperator		= @nSummaryOperator	output,
					  @sClientReference		= @sClientReference	output,
					  @nClientReferenceOperator	= @nClientReferenceOperator output  


		-- Extracting the Belongs To and Acting As Filter Criteria:
		Set @sSQLString = 	
		"Select  @nBelongsToNameKey		= BelongsToNameKey,"+CHAR(10)+
			"@nBelongsToNameKeyOperator	= BelongsToNameKeyOperator,"+CHAR(10)+
			"@bIsCurrentNameUser		= IsCurrentNameUser,"+CHAR(10)+
			"@nMemberOfGroupKey		= MemberOfGroupKey,"+CHAR(10)+
			"@nMemberOfGroupKeyOperator	= MemberOfGroupKeyOperator,"+CHAR(10)+				
			"@bIsCurrentMemberOfGroupUser	= IsCurrentMemberOfGroupUser,"+CHAR(10)+
			"@bIsCaller			= IsCaller,"+CHAR(10)+
			"@bIsStaff			= IsStaff,"+CHAR(10)+
			"@bIsReferredTo			= IsReferredTo"+CHAR(10)+
		"from	OPENXML (@idoc, '/mk_ListContactActivity/FilterCriteria/BelongsTo',2)"+CHAR(10)+
			"WITH ("+CHAR(10)+
			      "BelongsToNameKey		int		'NameKey/text()',"+CHAR(10)+
			      "BelongsToNameKeyOperator	tinyint		'NameKey/@Operator/text()',"+CHAR(10)+
			      "IsCurrentNameUser	bit		'NameKey/@IsCurrentUser/text()',"+CHAR(10)+	
			      "MemberOfGroupKey		smallint	'MemberOfGroupKey/text()',"+CHAR(10)+
	 		      "MemberOfGroupKeyOperator	tinyint		'MemberOfGroupKey/@Operator/text()',"+CHAR(10)+	
			      "IsCurrentMemberOfGroupUser bit		'MemberOfGroupKey/@IsCurrentUser/text()',"+CHAR(10)+	
			      "IsCaller			bit		'ActingAs/IsCaller/text()',"+CHAR(10)+	
			      "IsStaff			bit		'ActingAs/IsStaff/text()',"+CHAR(10)+	
			      "IsReferredTo		bit		'ActingAs/IsReferredTo/text()'"+CHAR(10)+
			      ")"
	
			exec @nErrorCode = sp_executesql @sSQLString,
						N'@idoc				int,
						  @nBelongsToNameKey 		int				output,
						  @nBelongsToNameKeyOperator	tinyint				output,
						  @bIsCurrentNameUser		bit				output,
						  @nMemberOfGroupKey		smallint			output,	
						  @nMemberOfGroupKeyOperator	tinyint				output,				
						  @bIsCurrentMemberOfGroupUser	bit				output,
						  @bIsCaller			bit				output,		
						  @bIsStaff			bit				output,		
						  @bIsReferredTo		bit				output',
						  @idoc				= @idoc,
						  @nBelongsToNameKey 		= @nBelongsToNameKey		output,
						  @nBelongsToNameKeyOperator	= @nBelongsToNameKeyOperator	output,
						  @bIsCurrentNameUser		= @bIsCurrentNameUser		output,
						  @nMemberOfGroupKey		= @nMemberOfGroupKey 		output,
						  @nMemberOfGroupKeyOperator	= @nMemberOfGroupKeyOperator	output,				
						  @bIsCurrentMemberOfGroupUser	= @bIsCurrentMemberOfGroupUser	output,
						  @bIsCaller 			= @bIsCaller			output,
						  @bIsStaff			= @bIsStaff 			output,
						  @bIsReferredTo		= @bIsReferredTo		output

		-- Extracting the Direction Filter Criteria:
		Set @sSQLString = 	
		"Select  @nDirectionOperator		= DirectionOperator,"+CHAR(10)+
			"@bIsIncoming			= IsIncoming,"+CHAR(10)+
			"@bIsOutgoing			= IsOutgoing"+CHAR(10)+
		"from	OPENXML (@idoc, '/mk_ListContactActivity/FilterCriteria',2)"+CHAR(10)+
			"WITH ("+CHAR(10)+
			      "DirectionOperator	tinyint		'Direction/@Operator/text()',"+CHAR(10)+	
			      "IsIncoming		bit		'Direction/IsIncoming/text()',"+CHAR(10)+	
			      "IsOutgoing		bit		'Direction/IsOutgoing/text()'"+CHAR(10)+	
			      ")"
		
		
			exec @nErrorCode = sp_executesql @sSQLString,
						N'@idoc				int,
						  @nDirectionOperator		tinyint				output,
						  @bIsIncoming			bit				output,
						  @bIsOutgoing			bit				output',
						  @idoc				= @idoc,
						  @nDirectionOperator		= @nDirectionOperator		output,
						  @bIsIncoming			= @bIsIncoming			output,
						  @bIsOutgoing			= @bIsOutgoing			output
					
		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc			
		
		If @nActivityKey is not NULL
		or @nActivityKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XA.ACTIVITYNO"+dbo.fn_ConstructOperator(@nActivityKeyOperator,@Numeric,@nActivityKey, null,0)
		End
	
		If ((@nContactPersonKey is not NULL
		or   @nContactPersonKeyOperator between 2 and 6
		or   @bIsMyself = 1)
		and (@bIsContact = 1
		 or  @bIsName = 1))
		OR  (@nContactNameKey is not null
		 or  @nContactNameKeyOperator between 2 and 6) 			
		Begin
	
			Set @sWhere = @sWhere+char(10)+"and ("
			Set @sOr    = NULL

			-- if IsMyself = 1, set @nContactPersonKey = USERIDENTITY.NAMENO
			If @bIsMyself = 1
			and @nErrorCode = 0
			Begin
				Set @sSQLString = '
					Select 	@nContactPersonKey = NAMENO
					from	USERIDENTITY
					where	IDENTITYID = @pnUserIdentityId
				'

				Exec @nErrorCode = sp_executesql @sSQLString,
							N'@nContactPersonKey	int			OUTPUT,
							  @pnUserIdentityId	int',
							  @nContactPersonKey	= @nContactPersonKey	OUTPUT,
							  @pnUserIdentityId	= @pnUserIdentityId
			End

			If @bIsContact = 1
			Begin
				Set @sWhere = @sWhere+char(10)+"XA.NAMENO"+dbo.fn_ConstructOperator(@nContactPersonKeyOperator,@Numeric,@nContactPersonKey, null,0)
	
				Set @sOr    =' OR '
			End
	
			If @bIsName = 1
			Begin
				If (@bIsContact = 1 and @nContactPersonKeyOperator = 1)
				Begin
					Set @sWhere = @sWhere+' and '+char(10)+"XA.RELATEDNAME"+dbo.fn_ConstructOperator(@nContactPersonKeyOperator,@Numeric,@nContactPersonKey, null,0)
				End
				Else
				Begin
					Set @sWhere = @sWhere+@sOr+char(10)+"XA.RELATEDNAME"+dbo.fn_ConstructOperator(@nContactPersonKeyOperator,@Numeric,@nContactPersonKey, null,0)
					Set @sOr    =' OR '
				End
			End

			If @nContactNameKey is not null
			or @nContactNameKeyOperator between 2 and 6
			Begin
				Set @sWhere = @sWhere+@sOr+char(10)+"XA.RELATEDNAME"+dbo.fn_ConstructOperator(@nContactNameKeyOperator,@Numeric,@nContactNameKey, null,0)
			End
		
			Set @sWhere = @sWhere+")"		
		End
	
		If @nContactKey is not NULL
		or @nContactKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XA.NAMENO"+dbo.fn_ConstructOperator(@nContactKeyOperator,@Numeric,@nContactKey, null,0)
		End

		-- RFC2985 Searches for activities where the contact name is a member of the selected access account
		If @nContactAccountKey is not NULL
		or @nContactAccountKeyOperator between 2 and 6
		Begin
			-- If Operator is set to IS NULL then use NOT EXISTS
			If @nContactAccountKeyOperator = 6
			Begin
				set @sWhere =@sWhere+char(10)+"and not exists"
			End
			Else 
			Begin
				Set @sWhere =@sWhere+char(10)+"and exists"
			End
		
			If @nContactAccountKeyOperator in (5,6) 
			Begin
				Set @sWhere = @sWhere+char(10)+"(	Select	1"
				                     +char(10)+"	from	USERIDENTITY XUI"
				                     +char(10)+"	where	XUI.NAMENO = XA.NAMENO)"
			End
			Else 
			Begin
				Set @sWhere = @sWhere+char(10)+"(	Select	1"
				                     +char(10)+"	from	USERIDENTITY XUI"
				                     +char(10)+"	where	XUI.ACCOUNTID "+dbo.fn_ConstructOperator(@nContactAccountKeyOperator,@String,@nContactAccountKey,null,@pbCalledFromCentura) 
				                     +char(10)+"	and	XUI.NAMENO = XA.NAMENO)"
			End
		End


		If @nStaffKey is not NULL
		or @nStaffKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XA.EMPLOYEENO"+dbo.fn_ConstructOperator(@nStaffKeyOperator,@Numeric,@nStaffKey, null,0)
		End
	
		If @nCallerKey is not NULL
		or @nCallerKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XA.CALLER"+dbo.fn_ConstructOperator(@nCallerKeyOperator,@Numeric,@nCallerKey, null,0)
		End
	
		If @nCaseKey is not NULL
		or @nCaseKeyOperator between 2 and 6
		Begin
			If @nEventKey is NULL
			Begin
				-- RFC37694
				-- If Case (but not Event) is being requested then also return 
				-- attachments associated with Prior Art linked to he Case.
				Set @sWhereFrom=@sWhereFrom+CHAR(10)+"left join CASESEARCHRESULT CS on (CS.CASEID"+dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)+")"
				
				Set @sWhere = @sWhere+char(10)+"and (XA.CASEID"+dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)+" OR XA.PRIORARTID=CS.PRIORARTID)"
			End
			Else Begin
				Set @sWhere = @sWhere+char(10)+"and XA.CASEID"+dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)
				
				/*** RFC6896: Filter by EVENTNO and CYCLE ***/
				If @nEventKey is not NULL
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.EVENTNO"+dbo.fn_ConstructOperator(0,@Numeric,@nEventKey, null,0)
				End
				
				If @nEventCycle is not NULL
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.CYCLE"+dbo.fn_ConstructOperator(0,@Numeric,@nEventCycle, null,0)
				End
			End
		End
	
		If @nReferredToKey is not NULL
		or @nReferredToKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XA.REFERREDTO"+dbo.fn_ConstructOperator(@nReferredToKeyOperator,@Numeric,@nReferredToKey, null,0)
		End
	
		If @sReference is not NULL
		or @nReferenceOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and UPPER(XA.REFERENCENO)"+dbo.fn_ConstructOperator(@nReferenceOperator,@String,UPPER(@sReference), null,0)
		End

		If @nCategoryKey is not NULL
		or @nCategoryKeyOperator between 2 and 6
		Begin
			-- For external user, limit rows by look up matching ACTIVITYCATEGORY in SITECONTROL ID 'Client Activity Categories'
			If @bIsExternalUser = 1
			Begin
				Set @sList = null

				Select 	@sList = @sList + nullif(',', ',' + @sList) + TABLECODE
				From 	dbo.fn_FilterUserTableCodes(@pnUserIdentityId, 59, 'Client Activity Categories', 0)

				If @sList is not NULL
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.ACTIVITYCATEGORY in ("+@sList+")"
				End
			End

			Set @sWhere = @sWhere+char(10)+"and XA.ACTIVITYCATEGORY"+dbo.fn_ConstructOperator(@nCategoryKeyOperator,@Numeric,@nCategoryKey, null,0)
		End
		
		If @nTypeKey is not NULL
		or @nTypeKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XA.ACTIVITYTYPE"+dbo.fn_ConstructOperator(@nTypeKeyOperator,@Numeric,@nTypeKey, null,0)
		End

		If @sSummary is not NULL
		or @nSummaryOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and UPPER(XA.SUMMARY)"+dbo.fn_ConstructOperator(@nSummaryOperator,@String,UPPER(@sSummary), null,0)
		End

		If @sClientReference is not NULL
		or @nClientReferenceOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and UPPER(XA.CLIENTREFERENCE)"+dbo.fn_ConstructOperator(@nClientReferenceOperator,@String,UPPER(@sClientReference), null,0)
		End

		-- A period range is converted to a date range by adding the from/to period to the 
		-- current date. Returns the due dates within the resulting date range.	
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
				
				if @nPeriodRangeTo is null
				Begin
					Set @dtDateRangeTo = getdate();
					Set @nDateRangeOperator = 7 -- Between
				End
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

				if @nPeriodRangeFrom is null
				Begin
					Set @dtDateRangeFrom = getdate();
					Set @nDateRangeOperator = 7 -- Between
				End
			End	
		End		
		If @dtDateRangeFrom is not null
		or @dtDateRangeTo   is not null
		Begin
			Set @sWhere =  @sWhere+char(10)+"and XA.ACTIVITYDATE"+dbo.fn_ConstructOperator(ISNULL(@nDateRangeOperator, @nPeriodRangeOperator),@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
		End
	
		If  @sWord is not null
		and @nWordOperator between 2 and 6
		Begin
			-- Reset the 'Or' string as it may have been used earlier.
			Set @sOr = null
	
			Set @sWhere = @sWhere+char(10)+"and ("
	
			If @bUseSummary = 1
			Begin
				Set @sWhere = @sWhere+char(10)+"upper(XA.SUMMARY)"+dbo.fn_ConstructOperator(@nWordOperator,@String,@sWord, null,0)
	
				Set @sOr    =' OR '
			End
	
			If @bUseNotes = 1
			Begin
				Set @sWhere = @sWhere+char(10)+@sOr+"upper(XA.NOTES)"+dbo.fn_ConstructOperator(@nWordOperator,@String,@sWord, null,0)
			End		
	
			Set @sWhere = @sWhere+")"
		End

		If @bIsIncoming = 1
		or @bIsOutgoing = 1
		or @nDirectionOperator between 2 and 6
		Begin
			-- Reset the 'Or' string as it may have been used earlier.
			Set @sOr = null

			If @nDirectionOperator in (5,6)
			Begin
				If @nDirectionOperator = 5
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.CALLTYPE is not null"
				End Else
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.CALLTYPE is null"
				End
			End
			Else Begin
			
				Set @sWhere = @sWhere+char(10)+"and ("
		
				If @bIsIncoming = 1
				Begin
					If  @nDirectionOperator = 0
					Begin
						Set @sWhere = @sWhere+char(10)+"XA.CALLTYPE = 0"

						Set @sOr    =' OR '
					End
					Else 
					If  @nDirectionOperator = 1
					Begin
						Set @sWhere = @sWhere+char(10)+"XA.CALLTYPE <> 0"

						Set @sOr    =' AND '
					End					
				End
		
				If @bIsOutgoing = 1
				Begin
					If  @nDirectionOperator = 0					
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLTYPE = 1"
					End 
					Else 
					If  @nDirectionOperator = 1
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLTYPE <> 1"
					End
	
					
				End		
		
				Set @sWhere = @sWhere+")"		
			End
		End
	
		If @bIsContacted = 1
		or @bIsLeftMessage = 1
		or @bIsNoAnswer = 1
		or @bIsBusy = 1
		or @nCallStatusOperator between 2 and 6
		Begin
			-- Reset the 'Or' string as it may have been used earlier.
			Set @sOr = null

			If @nCallStatusOperator in (5,6)
			Begin
				If @nCallStatusOperator = 5
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.CALLSTATUS is not null"
				End Else
				Begin
					Set @sWhere = @sWhere+char(10)+"and XA.CALLSTATUS is null"
				End
			End
			Else Begin
	
				Set @sWhere = @sWhere+char(10)+"and ("
		
				If @bIsContacted = 1
				Begin
					If @nCallStatusOperator = 0
					Begin
						Set @sWhere = @sWhere+char(10)+"XA.CALLSTATUS = 0"

						Set @sOr    =' OR '
					End
					Else 
					If @nCallStatusOperator = 1
					Begin
						Set @sWhere = @sWhere+char(10)+"XA.CALLSTATUS <> 0"

						Set @sOr    =' AND '
					End					
				End
		
				If @bIsLeftMessage = 1
				Begin
					If @nCallStatusOperator = 0
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLSTATUS = 2"
		
						Set @sOr    =' OR '
					End
					Else 
					If @nCallStatusOperator = 1
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLSTATUS <> 2"

						Set @sOr    =' AND '
					End					
				End		
		
				If @bIsNoAnswer = 1
				Begin
					If @nCallStatusOperator = 0
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLSTATUS = 1"

						Set @sOr    =' OR '
					End
					Else
					If @nCallStatusOperator = 1
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLSTATUS <> 1"
	
						Set @sOr    =' AND '
					End					
				End	
		
				If @bIsBusy = 1
				Begin
					If @nCallStatusOperator = 0
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLSTATUS = 3"

						Set @sOr    =' OR '						
					End
					Else
					If @nCallStatusOperator = 1
					Begin
						Set @sWhere = @sWhere+char(10)+@sOr+"XA.CALLSTATUS <> 3"

						Set @sOr    =' AND '
					End					
				End	
		
				Set @sWhere = @sWhere+")"		
			End
		End
	
		If @bIsComplete = 1
		or @bIsIncomplete = 1
		Begin
			-- Reset the 'Or' string as it may have been used earlier.
			Set @sOr = null
	
			Set @sWhere = @sWhere+char(10)+"and ("
	
			If @bIsComplete = 1
			Begin
				Set @sWhere = @sWhere+char(10)+"XA.INCOMPLETE = 0"
	
				Set @sOr    =' OR '
			End
	
			If @bIsIncomplete = 1
			Begin
				Set @sWhere = @sWhere+char(10)+@sOr+"XA.INCOMPLETE = 1"
			End		
	
			Set @sWhere = @sWhere+")"		
		End

		If @nBelongsToNameKey is not null
		or @bIsCurrentNameUser = 1
		or @nMemberOfGroupKey is not null
		or @bIsCurrentMemberOfGroupUser = 1
		Begin
			-- Reduce the number of joins in the main statement.
		
			Set @sSQLString = "
			Select  @nBelongsToNameKey = 	CASE 	WHEN @bIsCurrentNameUser = 1
						 		THEN U.NAMENO ELSE @nBelongsToNameKey END, 
				@nMemberOfGroupKey = 	CASE 	WHEN @bIsCurrentMemberOfGroupUser = 1 
							  	THEN N.FAMILYNO ELSE @nMemberOfGroupKey END, 
				@nNullGroupNameKey = 	CASE 	WHEN @bIsCurrentMemberOfGroupUser = 1 and N.FAMILYNO is null
							  	THEN U.NAMENO END
			from USERIDENTITY U
			join NAME N on (N.NAMENO = U.NAMENO)
			where IDENTITYID = @pnUserIdentityId"
		
			exec @nErrorCode=sp_executesql @sSQLString,
							      N'@nBelongsToNameKey		int			OUTPUT,
								@nMemberOfGroupKey		smallint		OUTPUT,
								@nNullGroupNameKey		int			OUTPUT,
								@pnUserIdentityId		int,
								@bIsCurrentNameUser		bit,
								@bIsCurrentMemberOfGroupUser	bit',
								@nBelongsToNameKey 		= @nBelongsToNameKey 	OUTPUT,
								@nMemberOfGroupKey		= @nMemberOfGroupKey 	OUTPUT,
								@nNullGroupNameKey		= @nNullGroupNameKey	OUTPUT,
								@pnUserIdentityId		= @pnUserIdentityId,
								@bIsCurrentNameUser		= @bIsCurrentNameUser,
								@bIsCurrentMemberOfGroupUser	= @bIsCurrentMemberOfGroupUser								
		End
							
			

		-- If the user does not belong to a group and 'Belonging to Anyone in my group
		-- Acting as Recipient' we should return an empty  result set:
		If   @bIsCurrentMemberOfGroupUser = 1
		and  @nMemberOfGroupKey is null
		and  @nMemberOfGroupKeyOperator is not null
		Begin
			Set @sWhereFrom = @sWhereFrom   +char(10)+" join NAME NULF	on (NULF.NAMENO = "+CAST(@nNullGroupNameKey  as varchar(10))
					      		+char(10)+"		 	and NULF.FAMILYNO is not null)"								 
		End

		If  (@nBelongsToNameKey is not null 
		or   @nBelongsToNameKeyOperator between 2 and 6)		
		or  (@nMemberOfGroupKey is not null
		or   @nMemberOfGroupKeyOperator between 2 and 6)	
		Begin	
			If @nBelongsToNameKey is not null
			or @nBelongsToNameKeyOperator between 2 and 6
			Begin
				-- Reset the 'Or' string as it may have been used earlier.
				Set @sOr = null
		
				Set @sWhere = @sWhere+char(10)+"and ("
		
				If @bIsCaller = 1
				Begin
					Set @sWhere = @sWhere+char(10)+"XA.CALLER "+dbo.fn_ConstructOperator(@nBelongsToNameKeyOperator,@Numeric,@nBelongsToNameKey, null,0)
		
					Set @sOr    =' OR '
				End
		
				If @bIsStaff = 1
				Begin
					Set @sWhere = @sWhere+char(10)+@sOr+"XA.EMPLOYEENO "+dbo.fn_ConstructOperator(@nBelongsToNameKeyOperator,@Numeric,@nBelongsToNameKey, null,0)
		
					Set @sOr    =' OR '
				End		
		
				If @bIsReferredTo = 1
				Begin
					Set @sWhere = @sWhere+char(10)+@sOr+"XA.REFERREDTO "+dbo.fn_ConstructOperator(@nBelongsToNameKeyOperator,@Numeric,@nBelongsToNameKey, null,0)
		
					Set @sOr    =' OR '
				End	
		
				Set @sWhere = @sWhere+")"					
			End

			If  @nMemberOfGroupKey is not null 
			or  @nMemberOfGroupKeyOperator between 2 and 6 
			Begin	

				-- Reset the 'Or' string as it may have been used earlier.
				Set @sOr = null
		
				Set @sWhere = @sWhere+char(10)+"and ("
	
				If @bIsCaller = 1
				Begin
					If charindex('join NAME XNC1 ',@sWhereFrom)=0
					Begin
						Set @sWhereFrom = @sWhereFrom + char(10) + 'left join NAME XNC1 on (XNC1.NAMENO = XA.CALLER)'
					End

					Set @sWhere = @sWhere+char(10)+"XNC1.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
		
					Set @sOr    =' OR '
				End
		
				If @bIsStaff = 1
				Begin
					If charindex('join NAME XNC5 ',@sWhereFrom)=0
					Begin
						Set @sWhereFrom = @sWhereFrom + char(10) + 'left join NAME XNC5 on (XNC5.NAMENO = XA.EMPLOYEENO)'
					End

					Set @sWhere = @sWhere+char(10)+@sOr+"XNC5.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
		
					Set @sOr    =' OR '
				End		
		
				If @bIsReferredTo = 1
				Begin
					If charindex('join NAME XNC3 ',@sWhereFrom)=0
					Begin
						Set @sWhereFrom = @sWhereFrom + char(10) + 'left join NAME XNC3 on (XNC3.NAMENO = XA.REFERREDTO)'
					End

					Set @sWhere = @sWhere+char(10)+@sOr+"XNC3.FAMILYNO "+dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
		
					Set @sOr    =' OR '
				End	
		
				Set @sWhere = @sWhere+")"					
			End
		End
	End
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

If @nTopRowCount is not null
Begin
	Set @sSelect = 'Select Top '+CAST(@nTopRowCount as varchar(10))+char(10)
End
Else Begin
	Set @sSelect = 'Select '
End

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
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
	-- Default @pnQueryContextKey to 190.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 190)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
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
		@sQualifier		= QUALIFIER
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR

	If @nErrorCode=0
	Begin
		If @sColumn='NULL'		
		Begin
			Set @sTableColumn='NULL'
		End

		If @sColumn='ActivityCategory'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)			

			If charindex('left join TABLECODES TC ',@sFrom)=0
			Begin
				Set @sFrom=@sFrom + char(10) + "left join TABLECODES TC		on (TC.TABLECODE = A.ACTIVITYCATEGORY)"
			End				
		End

		-- ActivityTime - Date ONLY
		Else If @sColumn='ActivityDate'
		Begin
			Set @sTableColumn='left(convert(nvarchar(50), A.ACTIVITYDATE, 126), 10)'

		End

		Else If @sColumn='ActivityKey'
		Begin
			Set @sTableColumn='A.ACTIVITYNO'
		End		

		-- ActivityTime - Time ONLY
		Else If @sColumn='ActivityTime'
		Begin
			Set @sTableColumn='SUBSTRING(CONVERT(nvarchar(50), A.ACTIVITYDATE, 126), CHARINDEX(''T'', CONVERT(nvarchar(50), A.ACTIVITYDATE, 126))+ 1, 12)'
		End

		Else If @sColumn='ActivityType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)			

			If charindex('left join TABLECODES TC2 ',@sFrom)=0
			Begin
				Set @sFrom=@sFrom + char(10) + "left join TABLECODES TC2	on (TC2.TABLECODE = A.ACTIVITYTYPE)"
			End	
		End

		Else If @sColumn='AttachmentCount'
		Begin
			Set @sTableColumn='ATCH.AttachmentCount'

			If @bHasAttachments = 1
			Begin
				If charindex('join (Select ACT.ACTIVITYNO, count(*) as AttachmentCount',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "join (Select ACT.ACTIVITYNO, count(*) as AttachmentCount" 
							  + char(10) + "      from ACTIVITYATTACHMENT ACT"
							  + char(10) + "      join ACTIVITY A	on (A.ACTIVITYNO = ACT.ACTIVITYNO)"
							  -- Improve performance by avoiding the scan of the entire 
							  -- ActivityAttachment index. 
							  + char(10) + "      where exists(Select 1"
							  + char(10) +        @sWhereFrom
							  + char(10) + 	      @sWhere +     	
							  + char(10) + "      and XA.ACTIVITYNO=A.ACTIVITYNO)"		      
							  + char(10) + "      group by ACT.ACTIVITYNO) ATCH 	on (ATCH.ACTIVITYNO = A.ACTIVITYNO)" 
				End
			End
			Else Begin
				If charindex('left join (Select ACT.ACTIVITYNO, count(*) as AttachmentCount',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "left join (Select ACT.ACTIVITYNO, count(*) as AttachmentCount" 
							  + char(10) + "	   from ACTIVITYATTACHMENT ACT"
							  + char(10) + "      	   join ACTIVITY A	on (A.ACTIVITYNO = ACT.ACTIVITYNO)"
							  -- Improve performance by avoiding the scan of the entire 
							  -- ActivityAttachment index. 
							  + char(10) + "      where exists(Select 1"
							  + char(10) +        @sWhereFrom
							  + char(10) + 	      @sWhere +     	
							  + char(10) + "      and XA.ACTIVITYNO=A.ACTIVITYNO)"		  	
							  + char(10) + "      group by ACT.ACTIVITYNO) ATCH 	on (ATCH.ACTIVITYNO = A.ACTIVITYNO)" 
				End	
			End

			
		End		

		Else If @sColumn='CallerKey'		
		Begin
			Set @sTableColumn='A.CALLER'
		End

		Else If @sColumn in ('CallerName',
				     'CallerNameCode')		
		Begin
			If charindex('left join NAME NC1 ',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME NC1 on (NC1.NAMENO = A.CALLER)'
			End
			
			If @sColumn='CallerName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NC1.NAMENO, null)' 
			End

			If @sColumn='CallerNameCode'
			Begin
				Set @sTableColumn='NC1.NAMECODE'
			End			
		End			

		Else If @sColumn='CallStatus'		
		Begin
			-- A code indicating the status of the call:
			-- 0 - Contacted; 1 - No Answer; 2 - Left Message; 3 - Busy.
			Set @sTableColumn='A.CALLSTATUS'
		End

		Else If @sColumn='CaseKey'		
		Begin
			Set @sTableColumn='A.CASEID'
		End

		Else If @sColumn='CaseReference'		
		Begin
			Set @sTableColumn='C.IRN'

			If charindex('left join CASES C ',@sFrom)=0
			Begin
				Set @sFrom=@sFrom + char(10) + "left join CASES C	on (C.CASEID = A.CASEID)"
			End	
		End

		Else If @sColumn='ClientReference'		
		Begin
			Set @sTableColumn='A.CLIENTREFERENCE'
		End

		Else If @sColumn='ContactKey'		
		Begin
			Set @sTableColumn='A.NAMENO'
		End

		Else If @sColumn in ('ContactName',
				     'ContactNameCode')		
		Begin
			If charindex('left join NAME NC2 ',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME NC2 on (NC2.NAMENO = A.NAMENO)'
			End
			
			If @sColumn='ContactName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NC2.NAMENO, null)'
			End

			If @sColumn='ContactNameCode'
			Begin
				Set @sTableColumn='NC2.NAMECODE'
			End			
		End		

		Else If @sColumn='FirstAttachmentFilePath'		
		Begin
			Set @sTableColumn='AA.FILENAME'

			If @bHasAttachments = 1
			Begin
				If charindex('join ACTIVITYATTACHMENT AA ',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "join ACTIVITYATTACHMENT AA 	on (AA.ACTIVITYNO = A.ACTIVITYNO"
		  					  + char(10) + "				and AA.SEQUENCENO = (Select min(AA2.SEQUENCENO)"							  
					  		  + char(10) + "    			                             from ACTIVITYATTACHMENT AA2" 
							  + char(10) + "     						     where AA2.ACTIVITYNO = AA.ACTIVITYNO))"
				End					
			End
			Else Begin
				If charindex('left join ACTIVITYATTACHMENT AA ',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "left join ACTIVITYATTACHMENT AA on (AA.ACTIVITYNO = A.ACTIVITYNO"
		  					  + char(10) + "				and AA.SEQUENCENO = (Select min(AA2.SEQUENCENO)"
							  + char(10) + "    			                             from ACTIVITYATTACHMENT AA2" 
							  + char(10) + "     						     where AA2.ACTIVITYNO = AA.ACTIVITYNO))"
				End	
			End			
		End

		Else If @sColumn='IsIncomingCall'
		Begin
			Set @sTableColumn='CASE WHEN A.CALLTYPE = 0 THEN cast(1 as bit) WHEN A.CALLTYPE = 1 THEN cast(0 as bit) ELSE NULL END'
		End

		Else If @sColumn='IsIncomplete'
		Begin
			Set @sTableColumn='cast(A.INCOMPLETE as bit)'
		End

		Else If @sColumn='IsOutgoingCall'
		Begin
			Set @sTableColumn='CASE WHEN A.CALLTYPE is not null THEN cast(A.CALLTYPE as bit) ELSE NULL END'
		End

		Else If @sColumn='Notes'
		Begin
			Set @sTableColumn='ISNULL(A.LONGNOTES, A.NOTES)'			
		End

		Else If @sColumn='Reference'
		Begin
			Set @sTableColumn='A.REFERENCENO'
		End

		Else If @sColumn='ReferredToKey'
		Begin
			Set @sTableColumn='A.REFERREDTO'
		End
		
		Else If @sColumn in ('ReferredToName',
				     'ReferredToNameCode')		
		Begin
			If charindex('left join NAME NC3 ',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME NC3 on (NC3.NAMENO = A.REFERREDTO)'
			End
			
			If @sColumn='ReferredToName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NC3.NAMENO, null)' 
			End

			If @sColumn='ReferredToNameCode'
			Begin
				Set @sTableColumn='NC3.NAMECODE'
			End			
		End		

		Else If @sColumn='RegardingKey'
		Begin
			Set @sTableColumn='A.RELATEDNAME'
		End
		
		Else If @sColumn in ('RegardingName',
				     'RegardingNameCode')		
		Begin
			If charindex('left join NAME NC4 ',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME NC4 on (NC4.NAMENO = A.RELATEDNAME)'
			End
			
			If @sColumn='RegardingName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NC4.NAMENO, null)'
			End

			If @sColumn='RegardingNameCode'
			Begin
				Set @sTableColumn='NC4.NAMECODE'
			End			
		End		

		Else If @sColumn='RowCount'
		Begin
			Set @sTableColumn='count(*)'
		End

		Else If @sColumn='StaffKey'
		Begin
			Set @sTableColumn='A.EMPLOYEENO'
		End
		
		Else If @sColumn in ('StaffName',
				     'StaffNameCode')		
		Begin
			If charindex('left join NAME NC5 ',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME NC5 on (NC5.NAMENO = A.EMPLOYEENO)'
			End
			
			If @sColumn='StaffName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NC5.NAMENO, null)'
			End

			If @sColumn='StaffNameCode'
			Begin
				Set @sTableColumn='NC5.NAMECODE'
			End			
		End			

		Else If @sColumn='Summary'
		Begin
			Set @sTableColumn='A.SUMMARY'
		End		

		Else If @sColumn in ('AttachmentName',
				     'AttachmentType',	
					 'AttachmentSequenceKey',
				     'AttachmentDescription',
				     'FilePath',
				     'IsPublic',	
				     'Language',
				     'PageCount')
		Begin
			If @bHasAttachments = 1
			Begin
				If charindex('join ACTIVITYATTACHMENT AT ',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "join ACTIVITYATTACHMENT AT on (AT.ACTIVITYNO = A.ACTIVITYNO)"	  					 
							  + char(10) + -- For external users only Public Attachments will be returned.
								       CASE WHEN @bIsExternalUser = 1
									    THEN "and AT.PUBLICFLAG = 1"	
								       END
				End	
			End
			Else Begin
				If charindex('left join ACTIVITYATTACHMENT AT ',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "left join ACTIVITYATTACHMENT AT on (AT.ACTIVITYNO = A.ACTIVITYNO)"	  					 
							  + char(10) + -- For external users only Public Attachments will be returned.
								       CASE WHEN @bIsExternalUser = 1
									    THEN "and AT.PUBLICFLAG = 1"	
								       END
				End	
			End			
			
			If @sColumn='AttachmentName'
			Begin
				Set @sTableColumn='case 
						   when DATALENGTH(AT.ATTACHMENTNAME) = 0 then REVERSE(SUBSTRING(REVERSE(AT.FILENAME), 0, CHARINDEX(''\'', REVERSE(AT.FILENAME), 1)))
						   when DATALENGTH(AT.ATTACHMENTNAME) is null then REVERSE(SUBSTRING(REVERSE(AT.FILENAME), 0, CHARINDEX(''\'', REVERSE(AT.FILENAME), 1)))
						   else AT.ATTACHMENTNAME
						   end'			
			End
			Else			
			If @sColumn='AttachmentType'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC3',@sLookupCulture,@pbCalledFromCentura)			

				If charindex('left join TABLECODES TC3 ',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "left join TABLECODES TC3	on (TC3.TABLECODE = AT.ATTACHMENTTYPE)"
				End					
			End
			Else
			If @sColumn='AttachmentDescription'
			Begin
				Set @sTableColumn='AT.ATTACHMENTDESC'			
			End
			Else
			If @sColumn='AttachmentSequenceKey'
			Begin
				Set @sTableColumn='AT.SEQUENCENO'			
			End
			Else
			If @sColumn='FilePath'
			Begin
				Set @sTableColumn='AT.FILENAME'
			End
			Else
			If @sColumn='IsPublic'
			Begin
				Set @sTableColumn='cast(AT.PUBLICFLAG as bit)'
			End	
			Else
			If @sColumn='Language'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC4',@sLookupCulture,@pbCalledFromCentura)			
		
				If charindex('left join TABLECODES TC4 ',@sFrom)=0
				Begin
					Set @sFrom=@sFrom + char(10) + "left join TABLECODES TC4	on (TC4.TABLECODE = AT.LANGUAGENO)"
				End	
			End				
			Else
			If @sColumn='PageCount'
			Begin
				Set @sTableColumn='AT.PAGECOUNT'
			End	
		End

		If @sColumn='ActivityCheckSum'
		Begin
			-- Get the comma separated list of all comparable colums
			-- of the EmployeeRemider table
			exec dbo.ip_GetComparableColumns
					@psColumns 	= @sActivityChecksumColumns output, 
					@psTableName 	= 'ACTIVITY',
					@psAlias 	= 'A'
	
			Set @sTableColumn='CHECKSUM('+@sActivityChecksumColumns+')'						
		End	
		
		Else If @sColumn='EventDescription'		
		Begin
			Set @sTableColumn='isnull('+
						dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
						dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+
						')'

			If charindex('left join CASEEVENT CE ',@sFrom)=0
			Begin
			Set @sFrom=@sFrom+char(10)+"left join CASEEVENT CE	on (CE.CASEID = A.CASEID and CE.EVENTNO = A.EVENTNO and CE.CYCLE=A.CYCLE)"
				 	 +char(10)+"left join EVENTS E		on (E.EVENTNO = CE.EVENTNO)"
					 +char(10)+"left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX"
					 +char(10)+"                            on (OX.CASEID = A.CASEID"
					 +char(10)+"				and OX.ACTION = E.CONTROLLINGACTION)"
					 +char(10)+"left join EVENTCONTROL EC	on (EC.EVENTNO = E.EVENTNO"
				  	 +char(10)+"				and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))"
			End
		End	
		Else If @sColumn='EventCycle'		
		Begin
			Set @sTableColumn='A.CYCLE'
		End

		-- If the column is being published then concatenate it to the Select list

		If datalength(@sPublishName)>0
		Begin
			Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
			Set @sComma=', '
		End
		Else Begin
			Set @sPublishName=NULL
		End

		-- If the column is to be sorted on then save the name of the table column along
		-- with the sort details so that later the Order By can be constructed in the correct sequence

		If @nOrderPosition>0
		Begin
			Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

			Set @nErrorCode = @@ERROR
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
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
	Select @sOrder= ISNULL(NULLIF(@sOrder+',', ','),'')			
			 +CASE WHEN(PublishName is null) 
			       THEN ColumnName
			       ELSE '['+PublishName+']'
			  END
			+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
			from @tbOrderBy
			order by Position			

	If @sOrder is not null
	Begin
		Set @sOrder = ' Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

If @nErrorCode=0
Begin		

	-- RFC2985 eliminate rows of activities that do not belong to the external user account.
	If  ( @bIsExternalUser = 1
	and  (@bHasAttachments = 0 or @bHasAttachments is null)
	and   @nErrorCode=0)
	Begin
		Set @sSQLString = '
			Select 	@nUserAccountKey = ACCOUNTID
			from	USERIDENTITY
			where	IDENTITYID = @pnUserIdentityId'
	
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@nUserAccountKey	int			OUTPUT,
					  @pnUserIdentityId	int',
					  @nUserAccountKey	= @nUserAccountKey	OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId
	
		Set @sWhere = @sWhere + char(10) + "and exists (select	2"
		                      + char(10) + "            from	USERIDENTITY UI"
		                      + char(10) + "            where	UI.ACCOUNTID = " + cast(@nUserAccountKey as varchar(50))
		                      + char(10) + 
					CASE WHEN @sQuickSearch is null
					     THEN "            and	UI.NAMENO = XA.NAMENO)"
					     ELSE "            and	UI.NAMENO = A.NAMENO)"
					END
	
	End
	
	If @sQuickSearch is null
	Begin
		Set @sWhere	= + char(10) 	+ 'WHERE exists (Select 1' 
			 	  + char(10) 	+ ltrim(rtrim(@sWhereFrom+char(10)+@sWhere))
			  	  + char(10)	+ 'and XA.ACTIVITYNO=A.ACTIVITYNO)'
	End

	-- No paging required
	If (@pnPageStartRow is null or
	    @pnPageEndRow is null)
	Begin 
		-- Now execute the constructed SQL to return the result set
		Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)
		Select 	@nErrorCode =@@ERROR,
			@pnRowCount=@@ROWCOUNT
		End
	-- Paging required
	Else Begin
		Set @sTopSelectList1 = replace(@sSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
		Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  

		exec ('SET ANSI_NULLS OFF ' + @sTopSelectList1 + @sFrom + @sWhere + @sOrder)
	
		Select 	@nErrorCode =@@Error,
			@pnRowCount=@@Rowcount

		If @pnRowCount<@pnPageEndRow
		and @nErrorCode=0
		Begin
			set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

			exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnRowCount	int',
						  @pnRowCount=@pnRowCount
		End
		Else If @nErrorCode=0 
		Begin
			exec ('SET ANSI_NULLS OFF ' + @sCountSelect + @sFrom + @sWhere)
			Set @nErrorCode =@@Error
		End		
	End
End

RETURN @nErrorCode
GO

Grant execute on dbo.mk_ListContactActivity  to public
GO
