-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CaseSummaryReport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_CaseSummaryReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_CaseSummaryReport.'
	Drop procedure [dbo].[cs_CaseSummaryReport]
End
Print '**** Creating Stored Procedure dbo.cs_CaseSummaryReport...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_CaseSummaryReport
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psReportType			nchar(1)	= null,	-- C = Case Reference, F = Family, N = Name
	@psOrderByNameTypeKey		nvarchar(3)	= null,	-- The type of name the report is to be sorted by for @psReportType = N
	@psShowNameTypeKeys		nvarchar(4000)	= null,	-- A caret(^) separated list of the NameTypeKeys for the names to be shown on the report.
	-- Case Filter Criteria
	@psCaseTypeKey			nchar(1)	= null,	-- Include/Exclude based on next parameter
	@pnCaseTypeKeyOperator		tinyint 	= 0,
	@psCountryCodes			nvarchar(1000)	= null,	-- A comma separated list of Country Codes.
	@pnCountryCodesOperator		tinyint		= null,	
	@psPropertyTypeKey		nchar(1)	= null,	-- Include/Exclude based on next parameter
	@pnPropertyTypeKeyOperator	tinyint		= 0,
	@psCategoryKey			nvarchar(2)	= null,	-- Include/Exclude based on next parameter
	@pnCategoryKeyOperator		tinyint		= 0,
	@psFamilyKey			nvarchar(20)	= null,
	@pnFamilyKeyOperator		tinyint		= null,
	@psInstructorKeys		nvarchar(4000)	= null,	-- A comma separated list of Instructor NameKeys
	@pnInstructorKeysOperator	tinyint		= null,
	@psNameKeys			nvarchar(4000)	= null,	-- A comma separated list of NameKeys. Used in conjunction with @psNameTypeKey if supplied.
	@pnNameKeysOperator		tinyint		= null,
	@psNameTypeKey			nvarchar(3)	= null,	-- Used in conjunction with @psNameKeys if supplied, but will search for Cases where any names exists with the name type otherwise.
	@pnNameTypeKeyOperator		tinyint		= null,
	@psSignatoryNameKeys		nvarchar(4000)	= null,	-- A comma separated list of NameKeys that act as NameType Signatory for the case.
	@pnSignatoryNameKeysOperator	tinyint		= null,
	@psStaffNameKeys		nvarchar(4000)	= null,	-- A comma separated list of NameKeys that act as Name Type Responsible Staff for the case.
	@pnStaffNameKeysOperator	tinyint		= null,
	@pnEventKey			int		= null,
	@pbSearchByDueDate		bit		= 0,
	@pbSearchByEventDate		bit		= 0,
	@pnEventDateOperator		tinyint		= null,
	@pdtEventFromDate		datetime	= null,
	@pdtEventToDate			datetime	= null,
	@pnEventDaysRange		int		= null,
	@pnStatusKey			int		= null,	-- if supplied, @pbPending, @pbRegistered and @pbDead are ignored.
	@pnStatusKeyOperator		tinyint		= null,
	@pbPending			bit		= 0,	-- if TRUE, any cases with a status that is Live but not registered
	@pbRegistered			bit		= 0,	-- if TRUE, any cases with a status that is both Live and Registered
	@pbDead				bit		= 0,	-- if TRUE, any Cases with a status that is not Live.
	-- Dates filter criteria
	@psImportanceLevel		nvarchar(2)	= null,
	@pbIsComplete			bit		= 1,
	@pbIsDue			bit		= 1,
	@pbShowAdHocReminders		bit		= 1,
	@pnCaseKey			int		= null	-- the CaseId of the Case
)
as
-- PROCEDURE:	cs_CaseSummaryReport
-- VERSION:	22
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	A report of the current status of the case, including case events.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11-Apr-2003  JEK	RFC13	1	Review delivered reports
-- 14-Apr-2003	JEK	RFC13	2	Include all possible columns for Cases,
--					and use resource names for columns.
-- 16-Apr-2003	JEK	RFC13	3	Implement @psOrderByNameTypeKey.
-- 16-Apr-2003	JEK	RFC13	5	Get 'Any' version of name information.
--					Implement Abandoned Event site control.
--					Implement @psReportType
-- 17-Apr-2003	JEK		6	Updated header section to match new template.
--					Select NULL for columns if there is no Order by Name Type or Abandoned Event.
-- 30-Apr-2003	JEK		7	Implement filter criteria
-- 01-May-2003	JEK		8	Ensure there is always a dates result set.
-- 02-May-2003	JEK		9	Adjust sorting of dates.
-- 28-May-2003	JEK	RFC197	10	Don't default to all names.  Case sql being truncated.
-- 12-Aug-2003	TM	RFC224	11	Office level rules. Pass null to fn_FilterCases for @pnOfficeKey and @pnOfficeKeyOperator.
-- 20-Aug-2003	TM	RFC40	12	Case List SQL exceeds max size. Replace @sFrom varchar(8000) variable with the new 
--					@sConstructedFrom1 nvarchar(4000) and @sConstructedFrom2 nvarchar(4000) and pass them to 
--					cs_ConstructCaseSelect. Also replace @sFrom variable with the new @sConstructedFrom1 and 
--					@sConstructedFrom2 when executing the constructed SQL to return the result set.
-- 12-Sep-2003	TM	RFC419	13	Add Case Reference to Case Summary Report as filter criteria.
--					Add new @psCaseReference and @pnCaseReferenceOperator parameters.
--					Pass @psCaseReference and @pnCaseReferenceOperator to the fn_FilterCases.  
-- 15 Sep 2003	TM	RFC421	14	Field Names in Search Screens not consistent. Pass nulls in the new  fn_FilterCases parameters: 
--					@psTextTypeKey7, @psText7 (mapped to 'Title') and @pnText7Operator. 
-- 17 Sep 2003	TM	RFC466	15	Add Goods and Services to the Case Summary Report. Add a new result 
--					set for goods and services text to the end of the procedure.  
-- 18 Sep 2003	TM	RFC419	16	Run Case Summary Report by entering Case Reference Number.
--					Replace @psCaseReference with the new @pnCaseKey parameter (hence remove 
--					@pnCaseReferenceOperator parameter). Accordingly pass @pnCaseKey to the fn_FilterCases
--					instead of the @psCaseReference and @pnCaseReferenceOperator.    
-- 07 Nov 2003	MF	RFC586	17	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 02 Sep 2004	JEK	RFC1377	18	Pass new Centura parameter to fn_WrapQuotes
-- 11 Jul 2005	TM	RFC2329	19	Increase the size of all case category parameters and local variables to 2 characters.
-- 11 Dec 2008	MF	17136	20	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Sep 2010	MF	RFC9777	21	Return the EVENTDESCRIPTION identified by the Controlloing Action
--					if it is available.
-- 04 Nov 2015	KR	R53910	22	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nRowCount int
Declare @sColumnIds nvarchar(4000)
Declare @sColumnQualifiers nvarchar(1000)
Declare @sPublishColumnNames nvarchar(4000)
Declare @sSortOrderList nvarchar(1000)
Declare @sSortDirectionList nvarchar(1000)
Declare @nAbandonedEvent int
Declare @sSelectList1		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom1			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere1		nvarchar(4000) 	-- the SQL to filter
Declare @sSelectList2		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom2			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere2		nvarchar(4000) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare @sSql			nvarchar(4000)
Declare @sConstructedFrom1	varchar(4000)	-- Extended from clause for use with cs_ConstructCaseSelect
Declare @sConstructedFrom2	varchar(4000)
Declare	@sCaseFilter		nvarchar(4000)	-- the FROM and WHERE for the Case Filter
Declare	@bExternalUser		bit
Declare @nTableCount		tinyint
Declare	@dtEventFromDate	datetime
Declare	@dtEventToDate		datetime

Set @nErrorCode = 0

-- Prepare From and To date range
If @nErrorCode = 0
and @pnEventDaysRange is not null
begin
	If @pdtEventFromDate is not null
	begin
		Set @dtEventFromDate = @pdtEventFromDate
	end
	Else
	begin
		Set @dtEventFromDate = GetDate()
	end

	Set @dtEventToDate = DateAdd(Day,@pnEventDaysRange,@dtEventFromDate)
end
Else
begin
	Set @dtEventFromDate = @pdtEventFromDate
	Set @dtEventToDate = @pdtEventToDate
end

-- Locate Abandoned Event
If @nErrorCode = 0
begin
	Select @nAbandonedEvent = COLINTEGER
	from SITECONTROL
	where CONTROLID = 'Abandoned Event'

	Set @nErrorCode = @@ERROR
end

-- Establish whether user is external
If @nErrorCode = 0
begin
	Select @bExternalUser = ISEXTERNALUSER
	From USERIDENTITY
	Where IDENTITYID = @pnUserIdentityId

	Set @nErrorCode = @@ERROR
end

-- Determine Case result set contents and sorting
If @nErrorCode = 0
begin
	Set @sColumnIds = case when @psOrderByNameTypeKey is null then 'NULL^NULL^NULL' else 'NameCodeAny^DisplayNameAny^NameKeyAny' end + 
		'^CaseKey^CaseReference^ShortTitle^CaseFamilyReference^StatusDescription^CaseTypeDescription^CountryName^PropertyTypeDescription^CaseCategoryDescription^SubTypeDescription^OfficialNumber^NumberTypeEventDate^' + 
		case when @nAbandonedEvent is null then 'NULL' else 'EventDate' end + 
		'^OfficialNumber^NumberTypeEventDate^NumberTypeEventDate^OfficialNumber^NumberTypeEventDate'
	Set @sColumnQualifiers = @psOrderByNameTypeKey + '^' +
				@psOrderByNameTypeKey + '^' +
				@psOrderByNameTypeKey + '^^^^^^^^^^^A^A^' +
				cast(@nAbandonedEvent as nvarchar) + '^R^R^P^I^I'
	Set @sPublishColumnNames = 'CaseName_NameCode^CaseName_Name^CaseName_NameKey^Case_CaseKey^Case_CaseReference^Case_ShortTitle^Case_CaseFamilyReference^Case_Status^Case_CaseType^Case_Country^Case_PropertyType^Case_CaseCategory^Case_SubType^OfficialNumber_Application^CaseEvent_Application_Date^CaseEvent_Abandonded_Date^OfficialNumber_Registration^CaseEvent_Registration_Date^CaseEvent_Publication_Date^OfficialNumber_InternationalApplication^CaseEvent_InternationalApplication_Date'

	If @psReportType = 'F'
	begin	-- Family, Case Reference
		Set @sSortOrderList = '^^^^2^^1^^^^^^^^^^^^^^'
		Set @sSortDirectionList = '^^^^A^^A^^^^^^^^^^^^^^'
	end
	Else If @psReportType = 'N'
	begin	-- Name, NameCode, NameKey, Case Reference
		Set @sSortOrderList = '2^1^3^^4^^^^^^^^^^^^^^^^'
		Set @sSortDirectionList = 'A^A^A^^A^^^^^^^^^^^^^^^^'
	end
	Else	
	begin	-- By Case Reference as default
		Set @sSortOrderList = '^^^^1^^^^^^^^^^^^^^^^'
		Set @sSortDirectionList = '^^^^A^^^^^^^^^^^^^^^^'
	end
end

-- Publish configurable information
If @nErrorCode = 0
begin
	Select DESCRIPTION as OrderByNameType
	from NAMETYPE
	where NAMETYPE = @psOrderByNameTypeKey

	Set @nErrorCode = @@ERROR
end

-- Prepare cases select statement
If @nErrorCode = 0
begin

	exec @nErrorCode=dbo.cs_ConstructCaseSelect	@sSelectList1		OUTPUT,
							@sConstructedFrom1	OUTPUT,
							@sConstructedFrom2	OUTPUT,
							@sWhere1		OUTPUT,
							@sOrder			OUTPUT,
							@nTableCount		OUTPUT,
							@sColumnIds,
							@sColumnQualifiers,
							@sPublishColumnNames,
							@sSortOrderList,
							@sSortDirectionList,
							@bExternalUser
end

-- A user defined function is used to construct the WHERE clause
-- used to filter what Cases are to be returned
if @nErrorCode=0
begin
	set @sCaseFilter=dbo.fn_FilterCases(
		@pnUserIdentityId,
		null,		--@psAnySearch,
		@pnCaseKey,		
		null,		--@psCaseReference, 
		null,		--@pnCaseReferenceOperator, 
		null,		--@pbWithinFileCover,
		null,		--@psOfficialNumber,
		null,		--@pnOfficialNumberOperator,
		null,		--@psNumberTypeKey,
		null,		--@pnNumberTypeKeyOperator,
		null,		--@psRelatedOfficialNumber,
		null,		--@pnRelatedOfficialNumberOperator,
		@psCaseTypeKey,
		@pnCaseTypeKeyOperator,
		@psCountryCodes,
		@pnCountryCodesOperator,
		null,		--@pbIncludeDesignations,
		@psPropertyTypeKey,
		@pnPropertyTypeKeyOperator,
		@psCategoryKey,
		@pnCategoryKeyOperator,
		null,		--@psSubTypeKey,
		null,		--@pnSubTypeKeyOperator,
		null,		--@psClasses,
		null,		--@pnClassesOperator,
		null,		--@psKeyWord,
		null,		--@pnKeywordOperator,
		@psFamilyKey,
		@pnFamilyKeyOperator,
		null,		--@psTitle,
		null,		--@pnTitleOperator,
		null,		--@pnTypeOfMarkKey,
		null,		--@pnTypeOfMarkKeyOperator,
		null,		--@pnInstructionKey,
		null,		--@pnInstructionKeyOperator,
		@psInstructorKeys,
		@pnInstructorKeysOperator,
		null,		--@psAttentionNameKeys,
		null,		--@pnAttentionNameKeysOperator,
		@psNameKeys,
		@pnNameKeysOperator,
		@psNameTypeKey,
		@pnNameTypeKeyOperator,
		@psSignatoryNameKeys,
		@pnSignatoryNameKeysOperator,
		@psStaffNameKeys,
		@pnStaffNameKeysOperator,
		null,		--@psReferenceNo,
		null,		--@pnReferenceNoOperator,
		@pnEventKey,
		@pbSearchByDueDate,
		@pbSearchByEventDate,
		@pnEventDateOperator,
		@dtEventFromDate,
		@dtEventToDate,
		null,		--@pnDeadlineEventKey,
		null,		--@pnDeadlineEventDateOperator,
		null,		--@pdtDeadlineEventFromDate,
		null,		--@pdtDeadlineEventToDate,
		@pnStatusKey,
		@pnStatusKeyOperator,
		@pbPending,
		@pbRegistered,
		@pbDead,
		null,		--@pbRenewalFlag,
		null,		--@pbLettersOnQueue,
		null,		--@pbChargesOnQueue,
		null,		--@pnAttributeTypeKey1,
		null,		--@pnAttributeKey1,
		null,		--@pnAttributeKey1Operator,
		null,		--@pnAttributeTypeKey2,
		null,		--@pnAttributeKey2,
		null,		--@pnAttributeKey2Operator,
		null,		--@pnAttributeTypeKey3,
		null,		--@pnAttributeKey3,
		null,		--@pnAttributeKey3Operator,
		null,		--@pnAttributeTypeKey4,
		null,		--@pnAttributeKey4,
		null,		--@pnAttributeKey4Operator,
		null,		--@pnAttributeTypeKey5,
		null,		--@pnAttributeKey5,
		null,		--@pnAttributeKey5Operator,
		null,		--@psTextTypeKey1,
		null,		--@psText1,
		null,		--@pnText1Operator,
		null,		--@psTextTypeKey2,
		null,		--@psText2,
		null,		--@pnText2Operator,
		null,		--@psTextTypeKey3,
		null,		--@psText3,
		null,		--@pnText3Operator,
		null,		--@psTextTypeKey4,
		null,		--@psText4,
		null,		--@pnText4Operator,
		null,		--@psTextTypeKey5,
		null,		--@psText5,
		null,		--@pnText5Operator,
		null,		--@psTextTypeKey6,
		null,		--@psText6,
		null,		--@pnText6Operator,
		null,		--@psTextTypeKey7			 
		null,		--@psText7			
		null,		--@pnText7Operator	
		null,		--@pnQuickIndexKey,
		null,		--@pnQuickIndexKeyOperator
		null,		--@pnOfficeKey
		null		--@pnOfficeKeyOperator
		)
end

-- Publish Case table
If @nErrorCode = 0
begin
	Set @sWhere1 =	char(10)+"	Where exists (select *"+
			char(10)+"	"+@sCaseFilter+
			char(10)+"	and XC.CASEID=C.CASEID)"

	-- Now execute the constructed SQL to return the result set
	exec (@sSelectList1 + @sConstructedFrom1 + @sConstructedFrom2 + @sWhere1 + @sOrder)

	Set @nErrorCode = @@Error

end

-- Publish CaseName table
If @nErrorCode = 0
begin

	Set @sSelectList1 = "Select "
	+char(10)+" 	CN.CASEID 	as Case_CaseKey,"
	+char(10)+"	T.DESCRIPTION	as CaseName_NameType,"
	+char(10)+"	dbo.fn_FormatNameUsingNameNo(N.NAMENO, default) as CaseName_Name"

	Set @sFrom1 = char(10)+"From CASENAME CN"
	+char(10)+"JOIN NAME N ON (N.NAMENO = CN.NAMENO)"
	+char(10)+"JOIN NAMETYPE T ON (T.NAMETYPE = CN.NAMETYPE)"

	Set @sWhere1 = 
	char(10)+"where (CN.EXPIRYDATE IS NULL OR CN.EXPIRYDATE > getDate())"

	Set @sWhere1 = @sWhere1
	+char(10)+"and CN.NAMETYPE in (select Parameter from dbo.fn_Tokenise("+dbo.fn_WrapQuotes(@psShowNameTypeKeys,0,0)+", '^'))"

	Set @sWhere1 = @sWhere1
	+char(10)+"and exists (select *"
	+char(10)+"	"+@sCaseFilter
	+char(10)+"	and XC.CASEID=CN.CASEID)"

	Set @sOrder = 
	char(10)+"Order by 	CN.CASEID,"
	+char(10)+"		case	CN.NAMETYPE "		
	+char(10)+"		  when	'I'	then 0	"	/* Instructor */
	+char(10)+"		  when 	'A'	then 1	"	/* Agent */
	+char(10)+"		  when 	'O'	then 2	"	/* Owner */
	+char(10)+"		  when	'EMP'	then 3	"	/* Staff member */
	+char(10)+"		  when	'SIG'	then 4	"	/* Signatory */
	+char(10)+"		else 5			"	/* others, order by description */
	+char(10)+"		end,"
	+char(10)+"		T.DESCRIPTION,"
	+char(10)+"		CaseName_Name,"
	+char(10)+"		N.NAMENO"

	exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sOrder)

	Set @nErrorCode = @@ERROR
end

-- Publish RelatedCases table
If @nErrorCode = 0
begin
	Set @sSelectList1 = "Select "
	+char(10)+" 	RC.CASEID		as Case_CaseKey,"
	+char(10)+"	R.RELATIONSHIPDESC	as RelatedCase_Relationship,"
	+char(10)+"	C.IRN			as RelatedCase_CaseReference,"
	+char(10)+"	CTY.COUNTRY		as RelatedCase_Country,"
	+char(10)+"	RC.OFFICIALNUMBER	as RelatedCase_OfficialNumber"

	Set @sFrom1 = char(10)+"from RELATEDCASE RC"
	+char(10)+"join CASERELATION R	on (R.RELATIONSHIP = RC.RELATIONSHIP)"
	+char(10)+"left join CASES C	on (C.CASEID = RC.RELATEDCASEID)"
	+char(10)+"left join COUNTRY CTY	on (CTY.COUNTRYCODE = RC.COUNTRYCODE)"

	Set @sWhere1 = 	char(10)+"where exists (select *"
	+char(10)+"	"+@sCaseFilter
	+char(10)+"	and XC.CASEID=RC.CASEID)"

	Set @sOrder = char(10)+"order by RC.CASEID, R.RELATIONSHIPDESC"


	exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sOrder)

	Set @nErrorCode = @@ERROR
end

-- Publish Dates table
If @nErrorCode = 0
begin
	Set @sSelectList1 = "Select DISTINCT"
	+char(10)+" 	CE.CASEID			as 'Case_CaseKey',"
	+char(10)+"	isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION)"
	+char(10)+"					as 'CaseEvent_EventDescription',"
	+char(10)+"	CE.CYCLE			as 'CaseEvent_EventCycle',"	
	+char(10)+"	CE.EVENTDUEDATE			as 'CaseEvent_EventDueDate',"
	+char(10)+"	CE.EVENTDATE			as 'CaseEvent_EventDate',"
	+char(10)+"	CE.DATEREMIND			as 'CaseEvent_NextPoliceDate',"
	+char(10)+"	convert(nvarchar(4000), case when CE.LONGFLAG = 1 then CE.EVENTLONGTEXT else CE.EVENTTEXT end)"
	+char(10)+"					as 'CaseEvent_EventText'"

	Set @sFrom1 = char(10)+"from CASES C"
	+char(10)+"join CASEEVENT CE		on (CE.CASEID = C.CASEID)"
	+char(10)+"join EVENTS E           	on (E.EVENTNO=CE.EVENTNO)"
	+char(10)+"left join OPENACTION OA	on (OA.CASEID=CE.CASEID"
	+char(10)+"				and OA.ACTION=E.CONTROLLINGACTION)"
	+char(10)+"left join EVENTCONTROL EC	on (EC.EVENTNO = CE.EVENTNO"
	+char(10)+"				and EC.CRITERIANO = isnull(OA.CRITERIANO,CE.CREATEDBYCRITERIA))"

	If @pbIsDue = 0
	and @pbIsComplete = 0
	begin	-- No dates
		-- Force an empty result set as required by the report
		Set @sWhere1 = char(10)+"where 1 <> 1"
	end
	Else
	begin
		Set @sWhere1 = 	char(10)+"where	(CE.OCCURREDFLAG < 9 OR CE.OCCURREDFLAG IS NULL)"
	
		If @psImportanceLevel is not null
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"and	E.IMPORTANCELEVEL >= "+dbo.fn_WrapQuotes(@psImportanceLevel,0,0)
		end
	
		If (@pbIsComplete = 1 or @pbIsComplete is null)
		and @pbIsDue = 0
		begin	-- Completed only
			Set @sWhere1 = @sWhere1
			+char(10)+"and	CE.EVENTDATE IS NOT NULL"
		end
		Else If (@pbIsDue = 1 or @pbIsDue is null)
		and @pbIsComplete = 0
		begin	-- Due only
			Set @sWhere1 = @sWhere1
			+char(10)+"and	CE.EVENTDATE IS NULL"
			+char(10)+"and	CE.EVENTDUEDATE IS NOT NULL"
			+char(10)+"and	exists"
			+char(10)+"	(select 1"
			+char(10)+"	from OPENACTION OA"
			+char(10)+"	join EVENTCONTROL OEC	on (OEC.EVENTNO = CE.EVENTNO"
			+char(10)+"				and OEC.CRITERIANO = OA.CRITERIANO)"
			+char(10)+"	where OA.CASEID = CE.CASEID"
			+char(10)+"	and	OA.POLICEEVENTS = 1) "
		end
		Else
		begin	-- Both completed and Due
			Set @sWhere1 = @sWhere1
			+char(10)+"and	((CE.EVENTDATE IS NOT NULL)"
			+char(10)+"	or"
			+char(10)+"	(exists"
			+char(10)+"		(select 1"
			+char(10)+"		from OPENACTION OA"
			+char(10)+"		join EVENTCONTROL OEC	on (OEC.EVENTNO = CE.EVENTNO"
			+char(10)+"					and OEC.CRITERIANO = OA.CRITERIANO)"
			+char(10)+"		where OA.CASEID = CE.CASEID"
			+char(10)+"		and	OA.POLICEEVENTS = 1) "
			+char(10)+"	and CE.EVENTDUEDATE IS NOT NULL)"
			+char(10)+"	)"
		end
	
		Set @sWhere1 = @sWhere1
		+char(10)+"and exists (select *"
		+char(10)+"	"+@sCaseFilter
		+char(10)+"	and XC.CASEID=CE.CASEID)"
	end

	Set @sSelectList2 = "union all"
	+char(10)+"select  AL.CASEID			as 'Case_CaseKey',"
	+char(10)+"	AL.ALERTMESSAGE			as 'CaseEvent_EventDescription',"
	+char(10)+"	NULL   				as 'CaseEvent_EventCycle',"
	+char(10)+"	AL.DUEDATE			as 'CaseEvent_EventDueDate',"
	+char(10)+"	AL.DATEOCCURRED			as 'CaseEvent_EventDate',"
	+char(10)+"	null				as 'CaseEvent_NextPoliceDate',"
	+char(10)+"	null				as 'CaseEvent_EventText'"

	Set @sFrom2 = char(10)+"from ALERT AL"
	+char(10)+"join SITECONTROL SC		on (SC.CONTROLID = 'HOMENAMENO')"

	Set @sWhere2 = 	char(10)+"where AL.EMPLOYEENO = SC.COLINTEGER"

	If (@pbIsComplete = 1 or @pbIsComplete is null)
	and @pbIsDue = 0
	begin	-- Completed only
		Set @sWhere2 = @sWhere2
		+char(10)+"and	AL.DATEOCCURRED IS NOT NULL"
	end
	Else If (@pbIsDue = 1 or @pbIsDue is null)
	and @pbIsComplete = 0
	begin	-- Due only
		Set @sWhere2 = @sWhere2
		+char(10)+"and	AL.DATEOCCURRED IS NULL"
	end

	Set @sWhere2 = @sWhere2
	+char(10)+"and exists (select *"
	+char(10)+"	"+@sCaseFilter
	+char(10)+"	and XC.CASEID=AL.CASEID)"

	Set @sOrder = char(10)+"order by Case_CaseKey, CaseEvent_EventDate, CaseEvent_EventDueDate, CaseEvent_EventDescription"

	If @pbShowAdHocReminders = 0
	or (@pbIsDue = 0 and @pbIsComplete = 0)
	begin
--		print @sSelectList1
--		print @sFrom1
--		print @sWhere1
--		print @sOrder

		Exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sOrder)
		Set @nErrorCode = @@ERROR
	end
	Else
	begin
--		print @sSelectList1
--		print @sFrom1
--		print @sWhere1
--		print @sSelectList2
--		print @sFrom2
--		print @sWhere2
--		print @sOrder

		Exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sSelectList2 + @sFrom2 + @sWhere2 + @sOrder)
		Set @nErrorCode = @@ERROR
	end

end

-- Publish Goods and Services  table
If @nErrorCode = 0
begin
	Set @sSelectList1 = "Select "
	+char(10)+" 	CT.CASEID			as Case_CaseKey,"
	+char(10)+"	ISNULL(CT.CLASS,CL.CLASS) 	as CaseClasses_TrademarkClass,"
	+char(10)+"	isnull(CT.SHORTTEXT,CT.TEXT)	"
	+char(10)+"					as CaseClasses_TrademarkClassText,"
	+char(10)+"	CL.FIRSTUSE			as TrademarkClass_FirstUse,"
	+char(10)+"	CL.FIRSTUSEINCOMMERCE		as FirstUseInCommerce"

	Set @sFrom1 = char(10)+"from CASES C"
	+char(10)+"join CASETEXT CT 		on (CT.CASEID = C.CASEID"
	+char(10)+"				and CT.TEXTTYPE = 'G'"
	+char(10)+"				and CT.CLASS IS NOT NULL"
	+char(10)+"				and CT.LANGUAGE is null)"
	+char(10)+"left join CLASSFIRSTUSE CL 	on (CL.CASEID = CT.CASEID"
	+char(10)+"				and CL.CLASS  = CT.CLASS)"
	
	Set @sWhere1 = 	char(10)+"where exists (select *"
	+char(10)+"	"+@sCaseFilter
	+char(10)+"	and XC.CASEID=C.CASEID)"
	-- Select version with the highest modified date and text no
	+char(10)+"	and  (  convert(nvarchar(24),CT.MODIFIEDDATE, 21)+cast(CT.TEXTNO as nvarchar(6)) ) "
	+char(10)+"	="
	+char(10)+"	( select max(convert(nvarchar(24), CT2.MODIFIEDDATE, 21)+cast(CT2.TEXTNO as nvarchar(6)) )"
	+char(10)+"	from CASETEXT CT2"
	+char(10)+"	where CT2.CASEID=CT.CASEID"
	+char(10)+"	and   CT2.TEXTTYPE=CT.TEXTTYPE"
	+char(10)+"	and   CT2.CLASS=CT.CLASS"
	+char(10)+"	and   CT2.LANGUAGE is null"
	+char(10)+"	)"
	
	-- Use union to retrieve classes that are not in the CaseText table (classes without
	-- text)
	Set @sSelectList2 = 
	+char(10)+"UNION "
	+char(10)+"Select "
	+char(10)+" 	C.CASEID			as Case_CaseKey,"
	+char(10)+"	CL.CLASS		 	as CaseClasses_TrademarkClass,"
	+char(10)+"	null				as CaseClasses_TrademarkClassText,"
	+char(10)+"	CL.FIRSTUSE			as TrademarkClass_FirstUse,"
	+char(10)+"	CL.FIRSTUSEINCOMMERCE		as FirstUseInCommerce"
	
	Set @sFrom2 = char(10)+"from CASES C"
	+char(10)+"join CLASSFIRSTUSE CL 	on (CL.CASEID = C.CASEID)"
	
						       
	Set @sWhere2 = 	char(10)+"where exists (select *"
	+char(10)+"	"+@sCaseFilter
	+char(10)+"	and XC.CASEID=C.CASEID)"
	+char(10)+"and not exists(select *"	
	+char(10)+"		  from CASETEXT CT"
	+char(10)+"		  where CT.CLASS = CL.CLASS"	
	+char(10)+"		  and CT.CASEID = CL.CASEID"
	+char(10)+"		  and CT.TEXTTYPE = 'G'"
	+char(10)+"		  and CT.LANGUAGE is null)"	
			
	Set @sOrder = char(10)+"order by CaseClasses_TrademarkClass"

	exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sSelectList2 + @sFrom2 + @sWhere2 + @sOrder)

	Set @nErrorCode = @@ERROR
end

Return @nErrorCode
GO

Grant execute on dbo.cs_CaseSummaryReport to public
GO
