-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DueDateReport
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DueDateReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_DueDateReport.'
	drop procedure [dbo].[cs_DueDateReport]
end
print '**** Creating Stored Procedure dbo.cs_DueDateReport...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_DueDateReport
(
	@pnUserIdentityId		int		= null,	-- May be null when called from InPro
	@psCulture			nvarchar(10) 	= null,
	@psReportType			nvarchar(2)	= null, -- DD = Due Date, E = Event, N = Name, PT = Property Type, CR = Case Reference, S = Status, C = Country, CT = Case Type
	@psOrderByNameTypeKey1		nvarchar(3)	= null,	-- The type of name the top level sorting is done on.
	@psOrderByNameTypeKey2		nvarchar(3)	= null,	-- The type of name the second level sorting is done on.
	@psShowNameTypeKey1		nvarchar(3)	= null, -- The type of name to printed in position 1 on the report.
	@psShowNameTypeKey2		nvarchar(3)	= null, -- The type of name to printed in position 2 on the report.
	@psShowNameTypeKey3		nvarchar(3)	= null, -- The type of name to printed in position 3 on the report.
	@psShowNameTypeKey4		nvarchar(3)	= null, -- The type of name to printed in position 4 on the report.
	@pbUseExternalStatus		bit		= null, -- Set to 1 if the external status description should be used.
	-- Filter criteria for Cases
	@psGlobalTempTable		nvarchar(32)	= null, -- Used by InPro to provide the name of a temporary table with the CasdIds to be reported.
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
	@pnStatusKey			int		= null,	-- if supplied, @pbPending, @pbRegistered and @pbDead are ignored.
	@pnStatusKeyOperator		tinyint		= null,
	@pbPending			bit		= 0,	-- if TRUE, any cases with a status that is Live but not registered
	@pbRegistered			bit		= 0,	-- if TRUE, any cases with a status that is both Live and Registered
	@pbDead				bit		= 0,	-- if TRUE, any Cases with a status that is not Live.
	-- Filtering for Dates
	@pbShowAdHocReminders		bit		= null,
	@pbShowReminders		bit		= null,
	@pdtFromDate			datetime	= null,
	@pdtToDate			datetime	= null,
	@pnRangeOfDays			int		= null,
	@psImportanceLevel		nvarchar(2)	= null,
	@pbIncludeRenewals		bit		= null,
	@pbExcludeRenewals		bit		= null,
	@pbRenewalsOnly			bit		= null,
	@pnEventKey			int		= null,
	@pbSearchByDueDate 		bit		= 0, 	-- RFC459
	@pbSearchByReminderDate 	bit		= 0, 	-- If @pbShowReminders = 0 then @pbSearchByReminderDate will also be set to 0.
	@pbIncludeClosedActions 	bit		= null
)
as
-- PROCEDURE:	cs_DueDateReport
-- VERSION:	32
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	A report of the outstand events, ad hoc reminders and employee reminders
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11-Apr-2003  JEK		1	RFC13 Review delivered reports
-- 14-Apr-2003	JEK		2	RFC13 Include all columns and change column names to resource IDs.
-- 16-Apr-2003	JEK		3	RFC13 Implement @psOrderByNameTypeKey1, @psOrderByNameTypeKey, @psShowNameTypeKey1-4.
--					Ensure keys are available for break groups.  Use PropertyType description for sorting.
-- 17-Apr-2003	JEK		4	RFC13 Adjust to build sql dynamically based on name type parameters.
--					Implement @psReportType.
--				5	Add filtering parameters.  Implement case filtering.
-- 28-Apr-2003	JEK		6	RFC13 Add more filter parameters. Implement external vs internal status description.
-- 29-Apr-2003	JEK		7	RFC13 Implement most date related filtering
-- 29-Apr-2003	JEK		9	Update version number
-- 30-Apr-2003	JEK		10	RFC13 Implement @pbShowReminders and concatenated reminder names.
-- 30-Apr-2003	JEK		11	RFC13 Debug above.
-- 01-May-2003	JEK		12	RFC13 Range of days not working correctly
-- 12-Aug-2003	TM		13	RFC224 Office level rules. Pass null to fn_FilterCases for the @pnOfficeKey 
--					and @pnOfficeKeyOperator parameters.
-- 15 Sep 2003	TM		14	RFC421 Field Names in Search Screens not consistent. Pass nulls in the new 
--			 		fn_FilterCases parameters: @psTextTypeKey7, @psText7 (mapped to 'Title') and 
--					@pnText7Operator. 
-- 15 Sep 2003	TM		15	RFC459 Due Date Report compatibility. Add new parameters: @pbSearchByDueDate,
--					@pbSearchByReminderDate and @pbIncludeClosedActions. Ensure that choosing events
--					is consistent with InPro.
-- 18 Sep 2003	JEK		16	RFC459 Provide template interface with all parameters and correct columns in
--					result sets.  
-- 18 Sep 2003	TM		17	RFC463 Review Due Date Report contents (SQA9232/SQA9235). The Due Date Report is
--					changed to provide the same information as the changed (SQA9232) InPro Due Date Report.
--					New @pbUseExternalStatus and @psGlobalTempTable were added. ShowNameType column has
--					been added to the first result set. InternalNumber, Case_CountryCode, 
--					CaseName_Instructor_Name, CaseName_Instructor_ReferenceNo, CaseName_Agent_Name,
--					CaseName_Agent_ReferenceNo, OfficialNumber_Application, CaseEvent_Application_Date,  
--					OfficialNumber_Registration and CaseEvent_Registration_Date have been added to the second
--					result set. Case_CaseDescription column was removed. ValidProperty.PropertyName is used
--					if the @psReportType is not 'PT', otherwise the PropertyType.PropertyName is displayed 
--					(as Case_PropertyType). Use new @pbUseExternalStatus parameter to determine if internal 
--					or external status should be displayed. If @psGlobalTempTable is not null then use the 
--					cases provided by this global temporary table.   
-- 24 Sep 2003	TM		18	RFC463 Review Due Date Report contents (SQA9232/SQA9235). Do not produce the first
--					result set (information about configurable behaviour) if the @pnUserIdentityId is null.
--					Execute all relevant "Select" statements only if the @pnUserIdentityId is not null. 
-- 25 Sep 2003	TM		19	RFC463 Review Due Date Report contents (SQA9232/SQA9235). @psGlobalTempTable changed from
--					nvarchar(30) to nvarchar(32).
-- 26 Sep 2003	TM		20	RFC463 Review Due Date Report contents (SQA9232/SQA9235). convert CaseName1,2,3 and 4 to 
--					nvarchar(254) when the @pnUserIdentityId is null.
-- 01 Oct 2003	TM		21	RFC463 Review Due Date Report contents (SQA9232/SQA9235). Remove @pbShowReminders from 
--					the logic filtering rows that match either on Due Date and/or on Reminder Date. 
--					Default @pbSearchByReminderDate and @pbSearchByDueDate to 0. 
-- 30 Oct 2003	TM	RFC575	22	Due Date report expired case names. When extracting case names, expired names will not
--					be selected, e.g. change "and (CN1.EXPIRYDATE IS NULL OR CN1.EXPIRYDATE < getdate()))"
--					to "and (CN1.EXPIRYDATE IS NULL OR CN1.EXPIRYDATE > getdate()))"		
-- 11 Feb 2004	TM	RFC856	23	Use value on EventControl for the @psImportanceLevel filter criteria and default to the 
--					Event if not found.
-- 12 May 2004	TM	RFC1397	24	Allow for a match on the CYCLE from the CASEEVENT to the OPENACTION when determining 
--					if the CaseEvent was associated with a live OpenAction.
-- 29 Sep 2004	MF	RFC1846	25	The due date for the Next Renewal (Eventno -11) should only be considered due
--					if the "Main Renewal Action" site control has been specified and that Action
--					is currently open.
-- 11 Jul 2005	TM	RFC2329	26	Increase the size of all case category parameters and local variables to 2 characters.
-- 11 Dec 2008	MF	17136	27	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 17 Sep 2010	MF	RFC9777	28	Return the EVENTDESCRIPTION identified by the Event's CONTROLLINGACTION if it is available.
-- 20 Apr 2011	MF	RFC10333 29	Join EMPLOYEEREMINDER to ALERT using new ALERTNAMENO column which caters for Reminders that
--					have been sent to names that are different to the originating Alert.
-- 05 Jul 2013	vql	R13629	30	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 04 Nov 2015	KR	R53910	31	Adjust formatted names logic (DR-15543)
-- 14 Nov 2018  AV  75198/DR-45358	32   Date conversion errors when creating cases and opening names in Chinese DB


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sOrderByNameType1 	nvarchar(50)
Declare @sOrderByNameType2 	nvarchar(50)
Declare @sNameType1 		nvarchar(50)
Declare @sNameType2 		nvarchar(50)
Declare @sNameType3 		nvarchar(50)
Declare @sNameType4 		nvarchar(50)
Declare @sShowNumberType	nvarchar(30)    
Declare @sSelectList1		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom1			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere1		nvarchar(4000) 	-- the SQL to filter
Declare @sSelectList2		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom2			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere2		nvarchar(4000) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare @sSql			nvarchar(4000)
Declare	@sCaseFilter		nvarchar(4000)	-- the FROM and WHERE for the Case Filter
Declare @sRenewalAction		nvarchar(2)	-- the Action used in determining the Next Renewal Date
Declare	@dtFromDate		datetime
Declare	@dtToDate		datetime

Set @nErrorCode = 0
Set @sOrderByNameType1 = null
Set @sOrderByNameType2 = null
Set @sNameType1 = null
Set @sNameType2 = null
Set @sNameType3 = null
Set @sNameType4 = null
Set @sShowNumberType = null

If @nErrorCode = 0
and @pnRangeOfDays is not null
begin
	If @pdtFromDate is not null
	begin
		Set @dtFromDate = @pdtFromDate
	end
	Else
	begin
		Set @dtFromDate = GetDate()
	end

	Set @dtToDate = DateAdd(Day,@pnRangeOfDays,@dtFromDate)
end
Else
begin
	Set @dtFromDate = @pdtFromDate
	Set @dtToDate = @pdtToDate
end

-- Get the Action used for determining the Next Renewal Date and save in a variable
If @nErrorCode=0
Begin
	Select @sRenewalAction=S.COLCHARACTER
	from SITECONTROL S
	where CONTROLID='Main Renewal Action'

	Set @nErrorCode=@@ERROR
End

-- If the @pnUserIdentityId is not null then execute all relevant "Select" statements 
-- to extract the required information into the variables. Variables are then used to  
-- populate "information about configurable behaviour" result set.
If @pnUserIdentityId is not null
Begin
	If @nErrorCode = 0
	and @psOrderByNameTypeKey1 is not null
	and @psOrderByNameTypeKey1 != ''
	begin
		Select @sOrderByNameType1 = DESCRIPTION
		From NAMETYPE
		Where NAMETYPE = @psOrderByNameTypeKey1
	
		Set @nErrorCode = @@ERROR
	end
	
	If @nErrorCode = 0
	and @psOrderByNameTypeKey2 is not null
	and @psOrderByNameTypeKey2 != ''
	begin
		Select @sOrderByNameType2 = DESCRIPTION
		From NAMETYPE
		Where NAMETYPE = @psOrderByNameTypeKey2
	
		Set @nErrorCode = @@ERROR
	end
	
	If @nErrorCode = 0
	and @psShowNameTypeKey1 is not null
	and @psShowNameTypeKey1 != ''
	begin
		Select @sNameType1 = DESCRIPTION
		From NAMETYPE
		Where NAMETYPE = @psShowNameTypeKey1
	
		Set @nErrorCode = @@ERROR
	end
	
	If @nErrorCode = 0
	and @psShowNameTypeKey2 is not null
	and @psShowNameTypeKey2 != ''
	begin
		Select @sNameType2 = DESCRIPTION
		From NAMETYPE
		Where NAMETYPE = @psShowNameTypeKey2
	
		Set @nErrorCode = @@ERROR
	end
	
	If @nErrorCode = 0
	and @psShowNameTypeKey3 is not null
	and @psShowNameTypeKey3 != ''
	begin
		Select @sNameType3 = DESCRIPTION
		From NAMETYPE
		Where NAMETYPE = @psShowNameTypeKey3
	
		Set @nErrorCode = @@ERROR
	end
	
	If @nErrorCode = 0
	and @psShowNameTypeKey4 is not null
	and @psShowNameTypeKey4 != ''
	begin
		Select @sNameType4 = DESCRIPTION
		From NAMETYPE
		Where NAMETYPE = @psShowNameTypeKey4
	
		Set @nErrorCode = @@ERROR
	end
	
	If @nErrorCode = 0
	begin
		Select @sShowNumberType = NT.DESCRIPTION
		From NUMBERTYPES NT
		join SITECONTROL SC on CONTROLID = 'Reporting Number Type'
		Where SC.COLCHARACTER = NT.NUMBERTYPE 
	
		Set @nErrorCode = @@ERROR
	end

	-- Publish information about configurable behaviour
	If @nErrorCode = 0
	begin
		Select 	@sOrderByNameType1	as OrderByNameType1,
			@sOrderByNameType2 	as OrderByNameType2,
			@sNameType1		as ShowNameType1,
			@sNameType2		as ShowNameType2,
			@sNameType3		as ShowNameType3,
			@sNameType4		as ShowNameType4,
			@sShowNumberType	as ShowNumberType	
	
		Set @nErrorCode = @@ERROR
	end
End

If @nErrorCode = 0
and @pbUseExternalStatus is null
begin
	Select @pbUseExternalStatus = ISEXTERNALUSER
	From USERIDENTITY
	Where IDENTITYID = @pnUserIdentityId

	Set @nErrorCode = @@ERROR
end

-- A user defined function is used to construct the FROM and WHERE clauses
-- used to filter what Cases are to be returned
if @nErrorCode=0
begin
	set @sCaseFilter=dbo.fn_FilterCases(
		@pnUserIdentityId,
		null,		--@psAnySearch,
		null,		--@pnCaseKey,
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
		null,		--@pnEventKey,
		null,		--@pbSearchByDueDate,
		null,		--@pbSearchByEventDate,
		null,		--@pnEventDateOperator,
		null,		--@pdtEventFromDate,
		null,		--@pdtEventToDate,
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

If @nErrorCode = 0
begin
	-- PropertyType is used for sorting, so extract the description
	-- from the Property table for consistency.
	-- CaseDescription can use the more explicit valid property description

	-- The first statement in the union locates CaseEvents and their Employee reminders.

	Set @sSelectList1 = "Select DISTINCT"

	-- Note that CaseEvent reminders can have multiple recipients
	If @pbShowReminders = 0
	begin
		Set @sSelectList1 = @sSelectList1
		+char(10)+"	CE.EVENTDUEDATE		as 'EmployeeReminder_ReminderDate',"
		+char(10)+"	NULL				as 'EmployeeReminder_Message',"
		+char(10)+"	NULL				as 'EmployeeReminder_ReminderFor',"
	end
	Else
	begin
		Set @sSelectList1 = @sSelectList1
		+char(10)+"	isnull(ER.REMINDERDATE,CE.EVENTDUEDATE)"
		+char(10)+"					as 'EmployeeReminder_ReminderDate',"
		+char(10)+"	convert(nvarchar(4000), isnull(ER.SHORTMESSAGE, ER.LONGMESSAGE))"
		+char(10)+"					as 'EmployeeReminder_Message',"
		+char(10)+"	dbo.fn_GetConcatenatedReminderNames(ER.CASEID, ER.EVENTNO, ER.CYCLENO, '; ', null)"
		+char(10)+"					as 'EmployeeReminder_ReminderFor',"
	end

	Set @sSelectList1 = @sSelectList1
	+char(10)+"	CS.CASETYPEDESC			as 'Case_CaseType',"
	+char(10)+"	CS.CASETYPE			as 'Case_CaseTypeKey',"
	+char(10)+"	CE.EVENTDUEDATE			as 'CaseEvent_EventDueDate',"
	+char(10)+"	isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION)"
	+char(10)+"					as 'CaseEvent_EventDescription',"
	+char(10)+"	E.EVENTNO			as 'CaseEvent_EventKey',"
	+char(10)+"	convert(nvarchar(4000), case when CE.LONGFLAG = 1 then CE.EVENTLONGTEXT else CE.EVENTTEXT end)"
	+char(10)+"					as 'CaseEvent_EventText',"
	+char(10)+"	C.IRN				as 'Case_CaseReference',"
	+char(10)+"	C.TITLE				as 'Case_ShortTitle',"
	+char(10)+"	C.CURRENTOFFICIALNO		as 'Case_CurrentOfficialNumber',"
	
	-- If report is ordered by property type then obtain the Case_PropertyType from the PropertyType table,
	-- otherwise use the ValidPropertyType table
	If @psReportType = 'PT'
	begin
		Set @sSelectList1 = @sSelectList1
		+char(10)+"	PT.PROPERTYNAME			as 'Case_PropertyType',"
	end
	Else
	begin
		Set @sSelectList1 = @sSelectList1
		+char(10)+"	VP.PROPERTYNAME			as 'Case_PropertyType',"
	end
	
	Set @sSelectList1 = @sSelectList1	
	+char(10)+"	C.PROPERTYTYPE			as 'Case_PropertyTypeKey',"
	+char(10)+"	CT.COUNTRY			as 'Case_Country',"
	+char(10)+"	C.COUNTRYCODE			as 'Case_CountryCode',"
	+char(10)+"	C.COUNTRYCODE			as 'Case_CountryKey',"
	+char(10)+"	O.OFFICIALNUMBER		as 'InternalNumber',"			
	+char(10)+"	dbo.fn_FormatNameUsingNameNo(NI.NAMENO, default)"
	+char(10)+"					as 'CaseName_Instructor_Name',"		
	+char(10)+"	CN.REFERENCENO  		as 'CaseName_Instructor_ReferenceNo',"	
	+char(10)+"	dbo.fn_FormatNameUsingNameNo(NA.NAMENO, default)"
	+char(10)+"					as 'CaseName_Agent_Name',"		
	+char(10)+"	CNA.REFERENCENO 		as 'CaseName_Agent_ReferenceNo',"	
	+char(10)+"	OA.OFFICIALNUMBER		as 'OfficialNumber_Application',"	
	+char(10)+"	CEA.EVENTDATE			as 'CaseEvent_Application_Date',"	
	+char(10)+"	RO.OFFICIALNUMBER		as 'OfficialNumber_Registration',"	
	+char(10)+"	CER.EVENTDATE			as 'CaseEvent_Registration_Date',"	
	+char(10)+"	TC.DESCRIPTION 			as 'Case_StatusSummary',"
	+char(10)+"	TC.TABLECODE			as 'Case_StatusSummaryKey',"

	If @pbUseExternalStatus = 1
	begin
		Set @sSelectList1 = @sSelectList1
		+char(10)+"	ST.EXTERNALDESC 		as 'Case_Status',"
		+char(10)+"	C.STATUSCODE			as 'Case_StatusKey',"
	end
	Else
	begin
		Set @sSelectList1 = @sSelectList1
		+char(10)+"	ST.INTERNALDESC 		as 'Case_Status',"
		+char(10)+"	C.STATUSCODE			as 'Case_StatusKey',"
	end

	Set @sFrom1 = 
	char(10)+"From CASEEVENT CE "
	+char(10)+"join EVENTS E			on (E.EVENTNO = CE.EVENTNO)"
	+char(10)+"left join OPENACTION OX		on (OX.CASEID = CE.CASEID"
	+char(10)+"					and OX.ACTION = E.CONTROLLINGACTION)"
	+char(10)+"left join EVENTCONTROL EC		on (EC.EVENTNO    = CE.EVENTNO"
	+char(10)+"					and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA))"

	If @pbShowReminders = 1
	or @pbShowReminders is null
	begin
		Set @sFrom1 = @sFrom1
		+char(10)+"left join EMPLOYEEREMINDER ER 		on (ER.CASEID = CE.CASEID"
		+char(10)+"					AND ER.EVENTNO = CE.EVENTNO"
		+char(10)+"					AND ER.CYCLENO = CE.CYCLE"
		+char(10)+"					AND ER.EMPLOYEENO =(select min(ER1.EMPLOYEENO)"
		+char(10)+"                     		        	              from EMPLOYEEREMINDER ER1"
		+char(10)+"                     		                	      where ER1.CASEID=ER.CASEID"
		+char(10)+"                     			                      and   ER1.EVENTNO=ER.EVENTNO"
		+char(10)+"							      and   ER1.CYCLENO=ER.CYCLENO))"
	end

	Set @sFrom1 = @sFrom1
	+char(10)+"join CASES C				on (C.CASEID = CE.CASEID)"

	-- @psGlobalTempTable is used by InPro to provide the name of a temporary table with the CasdIds 
	-- to be reported. If @psGlobalTempTable is not null then join it to the Cases table.   
	If @psGlobalTempTable is not null
	begin
		Set @sFrom1 = @sFrom1
		+char(10)+"Join " + @psGlobalTempTable + " INPRO " + " on (INPRO.CASEID=C.CASEID)"
	end
		
	Set @sFrom1 = @sFrom1
	+char(10)+"Join CASETYPE CS			on (CS.CASETYPE=C.CASETYPE)"
	+char(10)+"Join COUNTRY CT				on (CT.COUNTRYCODE=C.COUNTRYCODE)"
	+char(10)+"join PROPERTYTYPE PT			on (PT.PROPERTYTYPE = C.PROPERTYTYPE)"
	+char(10)+"Join VALIDPROPERTY VP 			on (VP.PROPERTYTYPE = C.PROPERTYTYPE"
	+char(10)+"                     			and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)"
	+char(10)+"                     		        	              from VALIDPROPERTY VP1"
	+char(10)+"                     		                	      where VP1.PROPERTYTYPE=C.PROPERTYTYPE"
	+char(10)+"                     			                      and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"
	+char(10)+"Left Join PROPERTY P			on (P.CASEID=C.CASEID)"
	+char(10)+"Left Join STATUS RS			on (RS.STATUSCODE=P.RENEWALSTATUS)"
	+char(10)+"Left Join STATUS ST			on (ST.STATUSCODE=C.STATUSCODE)"
	+char(10)+"Left Join TABLECODES TC			on (TC.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) Then 7603"
	+char(10)+"                       		                      WHEN(ST.REGISTEREDFLAG=1)            Then 7602"
	+char(10)+"                       		                                                           Else 7601"
	+char(10)+"                       			                 END)"
	+char(10)+"Left Join SITECONTROL SC 		on SC.CONTROLID = 'Reporting Number Type'"
	+char(10)+"Left join OFFICIALNUMBERS O 		on (O.CASEID = C.CASEID"
	+char(10)+"					and SC.COLCHARACTER = O.NUMBERTYPE"
	+char(10)+" 					and O.ISCURRENT = 1)"
	+char(10)+"Left Join CASENAME CN 		on (CN.CASEID = C.CASEID"
	+char(10)+"					and CN.NAMETYPE = 'I'"
	+char(10)+"					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()))"
	+char(10)+"Left Join NAME NI			on (NI.NAMENO = CN.NAMENO)"
	+char(10)+"Left Join CASENAME CNA 		on (CNA.CASEID = C.CASEID"
	+char(10)+"					and CNA.NAMETYPE = 'A'"
	+char(10)+"					and (CNA.EXPIRYDATE is null or CNA.EXPIRYDATE > getdate()))"
	+char(10)+"Left Join NAME NA			on (NA.NAMENO = CNA.NAMENO)"
	+char(10)+"Left Join NUMBERTYPES NTA 		on (NTA.NUMBERTYPE = 'A')"
	+char(10)+"Left Join OFFICIALNUMBERS OA		on (OA.CASEID    = C.CASEID"
	+char(10)+"					and OA.NUMBERTYPE = NTA.NUMBERTYPE"
	+char(10)+"					and OA.ISCURRENT = 1)"
	+char(10)+"Left Join CASEEVENT CEA     		on (CEA.CASEID   = C.CASEID"
	+char(10)+"					and CEA.EVENTNO  = NTA.RELATEDEVENTNO"
	+char(10)+"					and CEA.CYCLE = 1)"
	+char(10)+"Left Join NUMBERTYPES NTR 		on (NTR.NUMBERTYPE = 'R')"
	+char(10)+"Left Join OFFICIALNUMBERS RO		on (RO.CASEID    = C.CASEID"
	+char(10)+"					and RO.NUMBERTYPE = NTR.NUMBERTYPE"
	+char(10)+"					and RO.ISCURRENT = 1)"
	+char(10)+"Left Join CASEEVENT CER     		on (CER.CASEID   = C.CASEID"
	+char(10)+"					and CER.EVENTNO  = NTR.RELATEDEVENTNO"
	+char(10)+"					and CER.CYCLE = 1)"
		
	Set @sWhere1 = 
	char(10)+"where	(CE.OCCURREDFLAG = 0 OR CE.OCCURREDFLAG IS NULL)"
	+char(10)+"and	(CE.EVENTDATE IS NULL AND CE.EVENTDUEDATE IS NOT NULL)"
	
	If @pbIncludeClosedActions = 0
	or @pbIncludeClosedActions is null
	or @pbExcludeRenewals = 1
	or @pbRenewalsOnly = 1 
	begin

		Set @sWhere1 = @sWhere1
		+char(10)+"	and exists"
		+char(10)+"		(select 1	"
		+char(10)+"		from OPENACTION OA1"
		+char(10)+"		join EVENTCONTROL OEC	on (OEC.EVENTNO = CE.EVENTNO"
		+char(10)+"					and OEC.CRITERIANO = OA1.CRITERIANO)"
		+char(10)+"		join ACTIONS A		on (A.ACTION = OA1.ACTION)"		

		Set @sWhere1 = @sWhere1
		+char(10)+"		where OA.CASEID = CE.CASEID"

		If @pbIncludeClosedActions = 0
		or @pbIncludeClosedActions is null
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"		and	OA1.POLICEEVENTS = 1"	
			+char(10)+"		and   	OA1.CYCLE = CASE WHEN(A.NUMCYCLESALLOWED>1) THEN CE.CYCLE ELSE 1 END"	

			-- If Renewal Actions have not been excluded then we need to ensure that the Next Renewal
			-- Due Date is only considered if the appropriate Action is opened.
			If @sRenewalAction is not NULL
			and isnull(@pbExcludeRenewals,0)=0
			Begin
				Set @sWhere1 = @sWhere1
				+char(10)+"		and   	((OA1.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR CE.EVENTNO<>-11)"
			End
		end		

		If @pbExcludeRenewals = 1
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"				and	A.ACTIONTYPEFLAG <> 1"
		end
		Else
		If @pbRenewalsOnly = 1
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"				and	A.ACTIONTYPEFLAG = 1"
		end

		Set @sWhere1 = @sWhere1+char(10)+"		)"
	end
		
	If @dtFromDate is not null
	begin
		-- If @pbShowReminders = 0 then @pbSearchByReminderDate will also be set to 0.   
		If @pbSearchByReminderDate = 0  
		and @pbSearchByDueDate = 1  
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"	and CE.EVENTDUEDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"
		end
		Else If @pbSearchByReminderDate = 1 
		and @pbSearchByDueDate = 0     
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"	and ER.REMINDERDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"
		end
		-- If both @pbSearchByReminderDate and @pbSearchByDueDate are selected, rows that match
		-- either on Due Date or on Reminder Date are returned.  
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 1   
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"	and (CE.EVENTDUEDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"	
			+char(10)+"	 or ER.REMINDERDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"+")"
		end
	end

	If @dtToDate is not null
	begin
		If @pbSearchByReminderDate = 0 
		and @pbSearchByDueDate = 1  
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"	and CE.EVENTDUEDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"
		end
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 0  
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"	and ER.REMINDERDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"
		end
		-- If both @pbSearchByReminderDate and @pbSearchByDueDate are selected, rows that match
		-- either on Due Date or on Reminder Date are returned.  
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 1   
		begin
			Set @sWhere1 = @sWhere1
			+char(10)+"	and (CE.EVENTDUEDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"
			+char(10)+"	 or ER.REMINDERDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"+")"
		end
	end

	If @psImportanceLevel is not null
	begin
		Set @sWhere1 = @sWhere1
		+char(10)+"	and ISNULL(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL) >= '"+@psImportanceLevel+"'"
	end


	If @pnEventKey is not null
	begin
		Set @sWhere1 = @sWhere1
		+char(10)+"	and CE.EVENTNO = "+cast(@pnEventKey as nvarchar)
	end


	Set @sWhere1 = @sWhere1
	+char(10)+"and exists (select *"
	+char(10)+"	"+@sCaseFilter+
	+char(10)+"	and XC.CASEID=C.CASEID)"

	-- The second statement in the union locates Ad Hoc Reminders and their Employee reminders.

	Set @sSelectList2 = char(10)+"union all"

	-- Note that Ad Hoc reminders can only be sent to a single employee,
	-- so the EmployeeReminder_ReminderFor can be easily populated.
	If @pbShowReminders = 0
	begin
		Set @sSelectList2 = @sSelectList2
		+char(10)+"Select AL.DUEDATE		as 'EmployeeReminder_ReminderDate',"
		+char(10)+"	NULL				as 'EmployeeReminder_Message',"
		+char(10)+"	NULL				as 'EmployeeReminder_ReminderFor',"
	end
	Else
	begin
		Set @sSelectList2 = @sSelectList2
		+char(10)+"Select isnull(ER.REMINDERDATE,AL.DUEDATE)"
		+char(10)+"					as 'EmployeeReminder_ReminderDate',"
		+char(10)+"	convert(nvarchar(4000), isnull(ER.SHORTMESSAGE, ER.LONGMESSAGE))"
		+char(10)+"					as 'EmployeeReminder_Message',"
		+char(10)+"	dbo.fn_FormatNameUsingNameNo(EN.NAMENO, default)"
		+char(10)+"					as 'EmployeeReminder_ReminderFor',"
	end

	Set @sSelectList2 = @sSelectList2
	+char(10)+"	CS.CASETYPEDESC			as 'Case_CaseType',"
	+char(10)+"	CS.CASETYPE			as 'Case_CaseTypeKey',"
	+char(10)+"	AL.DUEDATE			as 'CaseEvent_EventDueDate',"
	+char(10)+"	AL.ALERTMESSAGE			as 'CaseEvent_EventDescription',"
	+char(10)+"	NULL				as 'CaseEvent_EventKey',"
	+char(10)+"	NULL				as 'CaseEvent_EventText',"
	+char(10)+"	C.IRN				as 'Case_CaseReference',"
	+char(10)+"	C.TITLE				as 'Case_ShortTitle',"
	+char(10)+"	C.CURRENTOFFICIALNO		as 'Case_CurrentOfficialNumber',"

	-- If report is ordered by property type then obtain the Case_PropertyType from the PropertyType table,
	-- otherwise use the ValidPropertyType table
	If @psReportType = 'PT'
	begin
		Set @sSelectList2 = @sSelectList2
		+char(10)+"	PT.PROPERTYNAME			as 'Case_PropertyType',"
	end
	Else
	begin
		Set @sSelectList2 = @sSelectList2
		+char(10)+"	VP.PROPERTYNAME			as 'Case_PropertyType',"
	end
	
	Set @sSelectList2 = @sSelectList2	
	+char(10)+"	C.PROPERTYTYPE			as 'Case_PropertyTypeKey',"
	+char(10)+"	CT.COUNTRY			as 'Case_Country',"
	+char(10)+"	C.COUNTRYCODE			as 'Case_CountryCode',"
	+char(10)+"	C.COUNTRYCODE			as 'Case_CountryKey',"
	+char(10)+"	O.OFFICIALNUMBER		as 'InternalNumber',"			
	+char(10)+"	dbo.fn_FormatNameUsingNameNo(NI.NAMENO, default)"
	+char(10)+"					as 'CaseName_Instructor_Name',"		
	+char(10)+"	CN.REFERENCENO  		as 'CaseName_Instructor_ReferenceNo',"	
	+char(10)+"	dbo.fn_FormatNameUsingNameNo(NA.NAMENO, default)"
	+char(10)+"					as 'CaseName_Agent_Name',"		
	+char(10)+"	CNA.REFERENCENO			as 'CaseName_Agent_ReferenceNo',"	
	+char(10)+"	OA.OFFICIALNUMBER		as 'OfficialNumber_Application',"	
	+char(10)+"	CEA.EVENTDATE			as 'CaseEvent_Application_Date',"	
	+char(10)+"	RO.OFFICIALNUMBER		as 'OfficialNumber_Registration',"	
	+char(10)+"	CER.EVENTDATE			as 'CaseEvent_Registration_Date',"	
	+char(10)+"	TC.DESCRIPTION 			as 'Case_StatusSummary',"
	+char(10)+"	TC.TABLECODE			as 'Case_StatusSummaryKey',"

	If @pbUseExternalStatus = 1
	begin
		Set @sSelectList2 = @sSelectList2
		+char(10)+"	ST.EXTERNALDESC 		as 'Case_Status',"
		+char(10)+"	C.STATUSCODE			as 'Case_StatusKey',"
	end
	Else
	begin
		Set @sSelectList2 = @sSelectList2
		+char(10)+"	ST.INTERNALDESC 		as 'Case_Status',"
		+char(10)+"	C.STATUSCODE			as 'Case_StatusKey',"
	end

	Set @sFrom2 = 	char(10)+"from ALERT AL"

	If @pbShowReminders = 1
	or @pbShowReminders is null
	begin
		Set @sFrom2 = @sFrom2
		+char(10)+"left join EMPLOYEEREMINDER ER	on (AL.EMPLOYEENO = ER.ALERTNAMENO"
		+char(10)+"				and AL.CASEID = ER.CASEID"
		+char(10)+"				and AL.SEQUENCENO = ER.SEQUENCENO"
		+char(10)+"				AND ER.EVENTNO IS NULL)"
		+char(10)+"left join NAME EN		on (EN.NAMENO = ER.EMPLOYEENO)"
	end

	Set @sFrom2 = @sFrom2
	+char(10)+"join CASES C			on (C.CASEID = AL.CASEID)"

	-- @psGlobalTempTable is used by InPro to provide the name of a temporary table with the CasdIds 
	-- to be reported. If @psGlobalTempTable is not null then join it to the Cases table.   
	If @psGlobalTempTable is not null
	begin
		Set @sFrom2 = @sFrom2
		+char(10)+"Join " + @psGlobalTempTable + " INPRO " + " on (INPRO.CASEID=C.CASEID)"
	end
	
	Set @sFrom2 = @sFrom2
	+char(10)+"Join CASETYPE CS		on (CS.CASETYPE=C.CASETYPE)"
	+char(10)+"Join COUNTRY CT			on (CT.COUNTRYCODE=C.COUNTRYCODE)"
	+char(10)+"join PROPERTYTYPE PT		on (PT.PROPERTYTYPE = C.PROPERTYTYPE)"
	+char(10)+"Join VALIDPROPERTY VP 		on (VP.PROPERTYTYPE = C.PROPERTYTYPE"
	+char(10)+"                     		and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)"
	+char(10)+"                     		                      from VALIDPROPERTY VP1"
	+char(10)+"                     		                      where VP1.PROPERTYTYPE=C.PROPERTYTYPE"
	+char(10)+"                     		                      and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"
	+char(10)+"Left Join PROPERTY P		on (P.CASEID=C.CASEID)"
	+char(10)+"Left Join STATUS RS		on (RS.STATUSCODE=P.RENEWALSTATUS)"
	+char(10)+"Left Join STATUS ST		on (ST.STATUSCODE=C.STATUSCODE)"
	+char(10)+"Left Join TABLECODES TC		on (TC.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) Then 7603"
	+char(10)+"                       		                      WHEN(ST.REGISTEREDFLAG=1)            Then 7602"
	+char(10)+"                       		                                                           Else 7601"
	+char(10)+"                       			                 END)"
	+char(10)+"Left Join SITECONTROL SC 		on SC.CONTROLID = 'Reporting Number Type'"
	+char(10)+"Left join OFFICIALNUMBERS O 		on (O.CASEID = C.CASEID"
	+char(10)+"					and SC.COLCHARACTER = O.NUMBERTYPE"
	+char(10)+" 					and O.ISCURRENT = 1)"
	+char(10)+"Left Join CASENAME CN 		on (CN.CASEID = C.CASEID"
	+char(10)+"					and CN.NAMETYPE = 'I'"
	+char(10)+"					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()))"
	+char(10)+"Left Join NAME NI			on (NI.NAMENO = CN.NAMENO)"
	+char(10)+"Left Join CASENAME CNA 		on (CNA.CASEID = C.CASEID"
	+char(10)+"					and CNA.NAMETYPE = 'A'"
	+char(10)+"					and (CNA.EXPIRYDATE is null or CNA.EXPIRYDATE > getdate()))"
	+char(10)+"Left Join NAME NA			on (NA.NAMENO = CNA.NAMENO)"
	+char(10)+"Left Join NUMBERTYPES NTA 		on (NTA.NUMBERTYPE = 'A')"
	+char(10)+"Left Join OFFICIALNUMBERS OA		on (OA.CASEID    = C.CASEID"
	+char(10)+"					and OA.NUMBERTYPE = NTA.NUMBERTYPE"
	+char(10)+"					and OA.ISCURRENT = 1)"
	+char(10)+"Left Join CASEEVENT CEA     		on (CEA.CASEID   = C.CASEID"
	+char(10)+"					and CEA.EVENTNO  = NTA.RELATEDEVENTNO"
	+char(10)+"					and CEA.CYCLE = 1)"
	+char(10)+"Left Join NUMBERTYPES NTR 		on (NTR.NUMBERTYPE = 'R')"
	+char(10)+"Left Join OFFICIALNUMBERS RO		on (RO.CASEID    = C.CASEID"
	+char(10)+"					and RO.NUMBERTYPE = NTR.NUMBERTYPE"
	+char(10)+"					and RO.ISCURRENT = 1)"
	+char(10)+"Left Join CASEEVENT CER     		on (CER.CASEID   = C.CASEID"
	+char(10)+"					and CER.EVENTNO  = NTR.RELATEDEVENTNO"
	+char(10)+"					and CER.CYCLE = 1)"
	
	Set @sWhere2 = 
	char(10)+"where	AL.CASEID IS NOT NULL"
	+char(10)+"and (AL.OCCURREDFLAG = 0 OR AL.OCCURREDFLAG IS NULL)"
	+char(10)+"and	AL.DATEOCCURRED IS NULL"
	+char(10)+"and	AL.DUEDATE IS NOT NULL"

	If @dtFromDate is not null
	begin
		-- If @pbShowReminders = 0 then @pbSearchByReminderDate will also be set to 0.   
		If @pbSearchByReminderDate = 0 
		and @pbSearchByDueDate = 1 
		begin
			Set @sWhere2 = @sWhere2
			+char(10)+"and AL.DUEDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"
		end
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 0    
		begin
			Set @sWhere2 = @sWhere2
			+char(10)+"and ER.REMINDERDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"
		end
		-- If both @pbSearchByReminderDate and @pbSearchByDueDate are selected, rows that match
		-- either on Due Date or on Reminder Date are returned. 
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 1   
		begin
			Set @sWhere2 = @sWhere2
			+char(10)+"and (AL.DUEDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"	
			+char(10)+" or ER.REMINDERDATE >= '"+convert(nvarchar,@dtFromDate,112)+"'"+")"		
		end
	end

	If @dtToDate is not null
	begin
		If @pbSearchByReminderDate = 0 
		and @pbSearchByDueDate = 1 
		begin
			Set @sWhere2 = @sWhere2
			+char(10)+"and AL.DUEDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"
		end
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 0 
		begin
			Set @sWhere2 = @sWhere2
			+char(10)+"and ER.REMINDERDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"
		end
		Else If @pbSearchByReminderDate = 1
		and @pbSearchByDueDate = 1   
		begin
			Set @sWhere2 = @sWhere2
			+char(10)+"and (AL.DUEDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"
			+char(10)+" or ER.REMINDERDATE <= '"+convert(nvarchar,@dtToDate,112)+"'"+")"
		end
	end

	Set @sWhere2 = @sWhere2
	+char(10)+"and exists (select *"
	+char(10)+"	"+@sCaseFilter+char(10)+
	+char(10)+"	and XC.CASEID=C.CASEID)"

	If @psReportType = 'E'
	begin
		Set @sOrder =
		char(10)+"CaseEvent_EventDescription, CaseEvent_EventKey, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate"
	end
	Else If @psReportType = 'N'
	begin
		Set @sOrder =
		char(10)+"CaseName_Name2, CaseName_NameCode2, CaseName_NameKey2, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end
	Else If @psReportType = 'PT'
	begin
		Set @sOrder =
		char(10)+"Case_PropertyType, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end
	Else If @psReportType = 'CR'
	begin
		Set @sOrder =
		char(10)+"Case_CaseReference, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end
	Else If @psReportType = 'S'
	begin
		Set @sOrder =
		char(10)+"Case_StatusSummary, Case_Status, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end
	Else If @psReportType = 'C'
	begin
		Set @sOrder =
		char(10)+"Case_Country, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end
	Else If @psReportType = 'CT'
	begin
		Set @sOrder =
		char(10)+"Case_CaseType, EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end
	Else
	begin	-- Default to Due Date
		Set @sOrder =
		char(10)+"EmployeeReminder_ReminderDate, CaseEvent_EventDueDate, CaseEvent_EventDescription, CaseEvent_EventKey"
	end

	If @psOrderByNameTypeKey1 is null
	begin
		Set @sSql =
		char(10)+"	NULL				as 'CaseName_Name1',"
		+char(10)+"	NULL				as 'CaseName_NameCode1',"
		+char(10)+"	NULL				as 'CaseName_NameKey1',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end
	Else
	begin
		Set @sSql =
		char(10)+"	dbo.fn_FormatNameUsingNameNo(N1.NAMENO, default)"
		+char(10)+"					as 'CaseName_Name1',"
		+char(10)+"	N1.NAMECODE			as 'CaseName_NameCode1',"
		+char(10)+"	N1.NAMENO			as 'CaseName_NameKey1',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql

		Set @sSql =
		char(10)+"left join CASENAME CN1			on (CN1.CASEID = C.CASEID"
		+char(10)+"					and CN1.NAMETYPE = '"+@psOrderByNameTypeKey1+"'"
		+char(10)+"					and (CN1.EXPIRYDATE IS NULL OR CN1.EXPIRYDATE > getdate()))"
		+char(10)+"left join NAME N1 			on (N1.NAMENO = CN1.NAMENO)"

		Set @sFrom1 = @sFrom1+@sSql
		Set @sFrom2 = @sFrom2+@sSql

		Set @sOrder = char(10)+"CaseName_Name1, CaseName_NameCode1, CaseName_NameKey1, " + @sOrder
	end

	If @psOrderByNameTypeKey2 is null
	begin
		Set @sSql =
		char(10)+"	NULL				as 'CaseName_Name2',"
		+char(10)+"	NULL				as 'CaseName_NameCode2',"
		+char(10)+"	NULL				as 'CaseName_NameKey2',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end
	Else
	begin
		Set @sSql =
		char(10)+"	dbo.fn_FormatNameUsingNameNo(N2.NAMENO, default)"
		+char(10)+"					as 'CaseName_Name2',"
		+char(10)+"	N2.NAMECODE			as 'CaseName_NameCode2',"
		+char(10)+"	N2.NAMENO			as 'CaseName_NameKey2',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql

		Set @sSql =
		char(10)+"left join CASENAME CN2			on (CN2.CASEID = C.CASEID"
		+char(10)+"					and CN2.NAMETYPE = '"+@psOrderByNameTypeKey2+"'"
		+char(10)+"					and (CN2.EXPIRYDATE IS NULL OR CN2.EXPIRYDATE > getdate()))"
		+char(10)+"left join NAME N2 			on (N2.NAMENO = CN2.NAMENO)"

		Set @sFrom1 = @sFrom1+@sSql
		Set @sFrom2 = @sFrom2+@sSql
	end

	If @psShowNameTypeKey1 is null
	begin
		Set @sSql =
		char(10)+"	NULL				as 'CaseName1',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end
	Else
	begin
		If @pnUserIdentityId is null
		Begin
			Set @sSql =
			char(10)+"	convert(nvarchar(254), dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey1+"', '; ', getdate(), null))"
			+char(10)+"					as 'CaseName1',"
		End
		else
		Begin
			Set @sSql =
			char(10)+"	dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey1+"', '; ', getdate(), null)"
			+char(10)+"					as 'CaseName1',"
		End

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end

	If @psShowNameTypeKey2 is null
	begin
		Set @sSql =
		char(10)+"	NULL				as 'CaseName2',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end
	Else
	begin
		If @pnUserIdentityId is null
		Begin
			Set @sSql =
			char(10)+"	convert(nvarchar(254), dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey2+"', '; ', getdate(), null))"
			+char(10)+"					as 'CaseName2',"
		End
		Else
		Begin
			Set @sSql =
			char(10)+"	dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey2+"', '; ', getdate(), null)"
			+char(10)+"					as 'CaseName2',"
		End		

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end

	If @psShowNameTypeKey3 is null
	begin
		Set @sSql =
		char(10)+"	NULL				as 'CaseName3',"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end
	Else
	begin
		If @pnUserIdentityId is null
		Begin
			Set @sSql =
			char(10)+"	convert(nvarchar(254), dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey3+"', '; ', getdate(), null))"
			+char(10)+"					as 'CaseName3',"
		End
		Else
		Begin
			Set @sSql =
			char(10)+"	dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey3+"', '; ', getdate(), null)"
			+char(10)+"					as 'CaseName3',"
		End
		
		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end

	If @psShowNameTypeKey4 is null
	begin
		Set @sSql =
		char(10)+"	NULL				as 'CaseName4'"

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end
	Else
	begin
		If @pnUserIdentityId is null
		Begin
			Set @sSql =
			char(10)+"	convert(nvarchar(254), dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey4+"', '; ', getdate(), null))"
			+char(10)+"					as 'CaseName4'"
		End
		Else
		Begin
			Set @sSql =
			char(10)+"	dbo.fn_GetConcatenatedNames(C.CASEID, '"+@psShowNameTypeKey4+"', '; ', getdate(), null)"
			+char(10)+"					as 'CaseName4'"

		End

		Set @sSelectList1 = @sSelectList1+@sSql
		Set @sSelectList2 = @sSelectList2+@sSql
	end

	Set @sOrder = char(10)+ 'Order by ' + @sOrder

--	print @sSelectList1
--	print @sFrom1
--	print @sWhere1
--	print @sSelectList2
--	print @sFrom2
--	print @sWhere2
--	print @sOrder

	If @pbShowAdHocReminders = 0
	begin	
		Exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sOrder)
		Set @nErrorCode = @@ERROR
	end
	Else
	begin
		Exec (@sSelectList1 + @sFrom1 + @sWhere1 + @sSelectList2 + @sFrom2 + @sWhere2 + @sOrder)
		Set @nErrorCode = @@ERROR
	end

end

Return @nErrorCode
GO

Grant execute on dbo.cs_DueDateReport to public
GO
