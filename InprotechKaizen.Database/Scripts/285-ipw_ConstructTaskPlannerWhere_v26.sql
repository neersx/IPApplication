-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ConstructTaskPlannerWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_ConstructTaskPlannerWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ipw_ConstructTaskPlannerWhere.'
	drop procedure dbo.ipw_ConstructTaskPlannerWhere
End
print '**** Creating procedure dbo.ipw_ConstructTaskPlannerWhere...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE PROCEDURE dbo.ipw_ConstructTaskPlannerWhere
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed		
	@ptXMLFilterCriteria		ntext		= null,		-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0,
	@pnQueryContextKey			int	,	
    @psCTE_CasesFrom				nvarchar(max) = null output,
    @psCTE_CasesWhere				nvarchar(max) = null output,
    @psCTE_CasesSelect				nvarchar(max) = null output,    
	@psCTE_CaseDetailsFrom		nvarchar(max)= null output,
	@psCTE_CaseDetailsWhere		nvarchar(max)= null output,	
	@psCTE_CaseDetailsSelect	nvarchar(max)= null output,
	@psRemindersFrom			nvarchar(max) = null output,
	@psRemindersWhere			nvarchar(max) = null output,
	@psDueDatesFrom				nvarchar(max) = null output,
	@psDueDatesWhere			nvarchar(max) = null output,
	@psAdHocDatesFrom			nvarchar(max) = null output,
	@psAdHocDatesWhere			nvarchar(max) = null output,
	@psCTE_CaseEventSelect nvarchar(max) = null output,
	@psCTE_CaseEventWhere nvarchar(max) = null output
)	
AS
-- PROCEDURE :	ipw_ConstructTaskPlannerWhere
-- VERSION :	26
-- DESCRIPTION:	RETURNS WHERE STRING FOR TASK PLANNER
-- MODIFICATIONS :
-- Date		Who	Number	Version		Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 22 Oct 2020  AK		DR-62511	1		Procedure created 
-- 26 Oct 2020  AK		DR-65386	2		Applied check for 'Reminder For'
-- 28 Oct 2020  AK		DR-65385	3		modified to consider name groups
-- 12 Nov 2020  AK		DR-64178	4		Included Importance lavel and LastWorkingDay criteria
-- 23 Nov 2020  AK		DR-64832	5		Included criteria for Cases topics from task planner search builders.
-- 22 Jan 2021	AK      DR-67298	6		Included criteria for Events and Actions topics and Reminder topic
-- 29 Jan 2021  AK		DR-67611	7		Include criteria for Ad Hoc Date Characteristics
-- 08 Feb 2021	LS		DR-68237	8		Included CTE for accessing case names 
-- 09 Feb 2021	AK		DR-65778	9		removed logic to include events from Law Update Service
-- 26 Mar 2021	AK		DR-69476	10		Corrected the Due Date Responsible Staff Member check for Adhoc dates
-- 10 Jun 2021	AK		DR-62197	11		Performance optimization
-- 16 Jun 2021	LS		DR-71170	12		Fixed CASEEVENT join issue 
-- 05 Ju1 2021	SW		DR-69085	13		Excluded occured events
-- 20 Jul 2021	AK		DR-73394	14		Validate Performance of Task Planner against Client DB  - phase 2
-- 27 Jul 2021	LS		DR-73590	15		Fixed CASENAME JOIN issue
-- 18 Aug 2021	AK		DR-68731	16		Changes made to consider IncludeFinalizedAdHocDates flag
-- 01 Sep 2021  AK		DR-75037	18		Changes made to return specific Adhoc reminders  
-- 27 Sep 2021  AK		DR-72657	19		Changes made to apply check based on @nNullGroupNameKey along with NameType
-- 30 Sep 2021	AK		DR-75577	20		Changes made to return AdHoc Date after deleting associated reminder
-- 30 Sep 2021	AK		DR-76940	21		Applied check for DueDateResponsibilityNameKeys and ImportanceLevelKeys
-- 10 Nov 2021	AK		DR-76103	22		Applied check eventno for Adhoc dates
-- 06 Dec 2021	AK		DR-77389	23		Corrected the alias from caseevent table
-- 04 Jan 2022	LS		DR-78679	24		Corrected conditions for belonging to
-- 10 Jan 2022	AK		DR-78794	25		Added logic for InstructorKeys and StatusKeys
-- 22 Feb 2022	AK		DR-79372	26		Added logic ShortTitle


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode			int = 0

-- Declare Filter Variables	
Declare @sCaseKeys			    nvarchar(max)	
Declare @nCaseKeysOperator		tinyint		

Declare @sCountryKeys			    nvarchar(max)	
Declare @nCountryKeysOperator		tinyint		
Declare @sPropertyTypeKeys			    nvarchar(max)	
Declare @nPropertyTypeKeysOperator		tinyint		
Declare @sCaseTypeKeys			    nvarchar(max)	
Declare @nCaseTypeKeysOperator		tinyint	
Declare @sStaffMemberKeys			    nvarchar(max)	
Declare @nStaffMemberKeysOperator		tinyint	
Declare @sSignatoryKeys			    nvarchar(max)	
Declare @nSignatoryKeysOperator		tinyint	
Declare @sOwnerKeys			    nvarchar(max)	
Declare @nOwnerKeysOperator		tinyint	
Declare @idoc 				int	
Declare @sCaseQuickSearch		nvarchar(max) 
Declare @bIsReminders			bit	
Declare @bIsDueDates			bit		
Declare @bIsAdHocDates			bit	
Declare @nNameKey			int		
Declare @sNameKeys			nvarchar(max)	-- A comma-separated list of recipients' name keys
Declare @nNameKeyOperator		tinyint		
Declare @bIsCurrentUser			bit		
Declare @nMemberOfGroupKey		smallint	
Declare @nMemberOfGroupKeyOperator 	tinyint		 
Declare @sMemberOfGroupKeys		nvarchar(max)	
Declare @nMemberOfGroupKeysOperator 	tinyint	
Declare @bMemberIsCurrentUser		bit		
Declare @nNullGroupNameKey		int		
Declare @bIsReminderRecipient			bit		
Declare @bIsResponsibleStaff	bit
Declare @sNameTypeKeys			nvarchar(4000)	-- The string that contains a list of passed Name Type Keys separated by a comma.
Declare @nDateRangeOperator		tinyint
Declare @dtDateRangeFrom		datetime	-- Return due dates between these dates.  From and/or To value must be provided.
Declare @dtDateRangeTo			datetime		
Declare @nPeriodRangeOperator		tinyint
Declare @sPeriodRangeType		nvarchar(2)	-- D - Days, W � Weeks, M � Months, Y - Years.
Declare @nPeriodRangeFrom		smallint	-- May be positive or negative.  Always supplied in conjunction with Type.
Declare @nPeriodRangeTo			smallint	
Declare @nImportanceLevelOperator	tinyint
Declare @sImportanceLevelFrom		nvarchar(2)	-- Return event related due dates with an importance level between these values. 
Declare @sImportanceLevelTo		nvarchar(2)	-- From and/or To value must be provided.		
Declare @bUseDueDate			bit
Declare @bUseReminderDate		bit
Declare @bSinceLastWorkingDay		bit		-- Indicates that the From value should be set to the day after the working day before todayâ€™s date.
Declare @dtTodaysDate			datetime
Declare @sReminderForNameKeys	nvarchar(max)
Declare @nReminderForNameKeysOperator		tinyint

Declare	@nCriticalLevel			int
Declare @nClientDueDates		int 		-- This holds the number of days prior to the current date for which due dates should be shown to external (client) users. 
Declare	@bExternalUser			bit

Declare @sDateRangeFilter		nvarchar(200)	-- the Date Range Filter for the 'Where' clauses
Declare @sSQLString			nvarchar(max)
Declare	@sCaseReference 			nvarchar(max)
Declare	@nCaseReferenceOperator			tinyint
Declare @sOutputString				nvarchar(max)
Declare	@bMultipleCaseRefs			bit
Declare @sCaseReferenceWhere			nvarchar(max)
Declare @or					nvarchar(5)
Declare	@sOfficialNumber 			nvarchar(36)
Declare	@nOfficialNumberOperator 		tinyint
Declare	@sNumberTypeKey				nvarchar(3)	
Declare	@bUseRelatedCase			bit 	-- When turned on, the search is conducted on any official numbers stored as related Cases.  Any NumberType values are ignored.
Declare	@bUseNumericSearch 			bit		-- When turned on, any non-numeric characters are removed from Number and this is compared to the numeric characters in the official numbers on the database.
Declare @bUseCurrent				bit	
Declare @sNumericOfficialNumber			nvarchar(36)	-- Number with any non-numeric characters removed from it
Declare	@sFamilyKeyList	 			nvarchar(max)
Declare	@nFamilyKeyListOperator			tinyint
Declare	@nCaseListKeyOperator			tinyint
Declare	@nCaseListKey				int
Declare	@sOfficeKeys				nvarchar(4000)
Declare	@nOfficeKeyOperator	        	tinyint
Declare	@sCategoryKey				nvarchar(200)	
Declare	@nCategoryKeyOperator			tinyint
Declare	@sSubTypeKey				nvarchar(200)	
Declare @nSubTypeKeyOperator			tinyint
Declare @sBasisKey				nvarchar(200)
Declare @nBasisKeyOperator			tinyint
Declare @sInstructorKeys			    nvarchar(max)	
Declare @nInstructorKeysOperator		tinyint	
Declare @sOtherNameTypeKeys			    nvarchar(max)	
Declare @nOtherNameTypeKeysOperator		tinyint	
Declare @sOtherNameType	nvarchar(100)

Declare	@sStatusKey	 			nvarchar(4000)	
Declare	@nStatusKeyOperator			tinyint
Declare	@sStatusKeys	 			nvarchar(max)	
Declare	@nStatusKeysOperator			tinyint

Declare @sRenewalStatusKeys			nvarchar(3500)									
Declare @nRenewalStatusKeyOperator		tinyint
Declare	@bIsPending				bit		-- if TRUE, any cases with a status that is Live but not registered
Declare	@bIsRegistered				bit		-- if TRUE, any cases with a status that is both Live and Registered
Declare	@bIsDead				bit		-- if TRUE, any Cases with a status that is not Live.

Declare @sEventKeys			    nvarchar(max)	
Declare @nEventKeysOperator		tinyint	

Declare @sEventCategoryKeys		nvarchar(max)	
Declare @nEventCategoryKeysOperator	tinyint
Declare @sEventGroupKeys		nvarchar(max)	
Declare @nEventGroupKeysOperator	tinyint	
Declare	@nEventNoteTypeKeysOperator	tinyint
Declare	@sEventNoteTypeKeys		nvarchar(4000)
Declare	@nEventNoteTextOperator		tinyint
Declare	@sEventNoteText			nvarchar(max)
Declare @bIsRenewalsOnly		bit		
Declare @bIsNonRenewalsOnly		bit		
Declare @bIncludeClosed			bit		
Declare @sActionKeys			nvarchar(1000)	
Declare @nActionKeysOperator		tinyint

Declare @sShortTitleText		    nvarchar(max)	
Declare @nShortTitleOperator		tinyint	

Declare @sReminderMessage		nvarchar(254)	-- Return reminders for the specified message.
Declare @nReminderMessageOperator	tinyint
Declare @bIsReminderOnHold		bit		-- Returns reminders that are, or are not, on hold as requested. If absent, then all reminders are returned.
Declare @bIsReminderRead		bit		-- Returns reminders that are, or are not, read as requested.  If absent, then all reminders are returned.

Declare @bHasCase			bit		
Declare @bIsGeneral			bit		
Declare @bHasName			bit		
Declare @bIncludeFinalizedAdHocDates	bit		
Declare @sAdHocReference		nvarchar(20)	
Declare @nAdHocReferenceOperator	tinyint	
Declare @sNameReferenceKeys		nvarchar(max)	       
Declare @nNameReferenceKeysOperator	tinyint	
Declare @sAdHocMessage			nvarchar(254)	
Declare @nAdHocMessageOperator		tinyint
Declare @sAdHocEmailSubject		nvarchar(100)	
Declare @nAdHocEmailSubjectOperator	tinyint		

Declare @sRenewalAction			nvarchar(2)

Declare @sReminderExists		nvarchar(4000)
Declare @sReminderExistsWhere		nvarchar(4000)
Declare @sAlertExists			nvarchar(4000)
Declare @sAlertExistsWhere			nvarchar(4000)
Declare @sCaseEventExits nvarchar(4000)
Declare @sCaseEventExitsWhere nvarchar(4000)
Declare @sCE_ResponsibleStaff nvarchar(1000)
Declare @sCE_ResponsibleStaffWhere nvarchar(1000)
Declare @sCE_ResponsibleStaffFamily nvarchar(1000)
Declare @sCE_ResponsibleStaffFamilyWhere nvarchar(1000)

Declare @sReminderCaseName nvarchar(1000)
Declare @sReminderCaseNameWhere nvarchar(1000)

Declare @sReminderRecipientFamily nvarchar(1000)
Declare @sReminderRecipientFamilyWhere nvarchar(1000)

Declare @sAlertCaseName nvarchar(1000)
Declare @sAlertCaseNameWhere nvarchar(1000)

Declare @sAlertFamily nvarchar(1000)
Declare @sAlertFamilyWhere nvarchar(1000)

Declare @sCE_Name nvarchar(4000)
Declare @sCE_NameWhere nvarchar(4000)

Declare @sImportanceLevelKeys		nvarchar(max)	       
Declare @nImportanceLevelKeysOperator	tinyint	
Declare @sDueDateResponsibilityNameKeys		nvarchar(max)	       
Declare @nDueDateResponsibilityNameKeysOperator	tinyint	

-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @SemiColon				nchar(1)
Declare	@sNPrefix				nchar(1)

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'
Set	@SemiColon				=';'

Declare @sList					nvarchar(4000)	-- RFC1717 variable to prepare a comma separated list of values

declare	@bBlockCaseAccess		bit
declare @sFunctionSecurity		nvarchar(max)

set @bBlockCaseAccess = 0

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

-- Initialise --- 

Set @sFunctionSecurity = char(10)+"
		Join (Select R.EMPLOYEENO 
			FROM (select distinct EMPLOYEENO from EMPLOYEEREMINDER) R
			JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
			JOIN NAME N          ON (UI.NAMENO = N.NAMENO)			
			LEFT JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=2)						
			WHERE (F.ACCESSPRIVILEGES&1 = 1 or R.EMPLOYEENO = UI.NAMENO)
			AND (F.OWNERNO       = R.EMPLOYEENO or R.EMPLOYEENO = UI.NAMENO OR F.OWNERNO IS NULL)
			AND (F.ACCESSSTAFFNO = UI.NAMENO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSSTAFFNO IS NULL) 
			AND (F.ACCESSGROUP   = N.FAMILYNO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSGROUP IS NULL)			  
			group by R.EMPLOYEENO) FS on (FS.EMPLOYEENO=ER.EMPLOYEENO)"

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	
	
-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = 	
	"Select @sCaseQuickSearch		= CaseQuickSearch, "+CHAR(10)+	
	"	@bIsReminders			= IsReminders,"+CHAR(10)+
	"	@bIsDueDates			= IsDueDates,"+CHAR(10)+
	"	@bIsAdHocDates			= IsAdHocDates,"+CHAR(10)+	
	"	@nNameKey			= NameKey,"+CHAR(10)+				
	"	@sNameKeys			= NameKeys,"+CHAR(10)+				
	"	@nNameKeyOperator		= NameKeyOperator,"+CHAR(10)+	
	"	@bIsCurrentUser			= IsCurrentUser,"+CHAR(10)+
	"	@nMemberOfGroupKey		= MemberOfGroupKey,"+CHAR(10)+
	"	@nMemberOfGroupKeyOperator	= MemberOfGroupKeyOperator,"+CHAR(10)+
	"	@sMemberOfGroupKeys		= MemberOfGroupKeys,"+CHAR(10)+
	"	@nMemberOfGroupKeysOperator	= MemberOfGroupKeysOperator,"+CHAR(10)+
	"	@bMemberIsCurrentUser		= MemberIsCurrentUser,"+CHAR(10)+
	"	@bIsReminderRecipient			= IsReminderRecipient,"+CHAR(10)+
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
	"	@bIsResponsibleStaff			= IsResponsibleStaff,"+CHAR(10)+
	"	@bHasCase			= HasCase,"+CHAR(10)+
	"	@bHasName			= HasName,"+CHAR(10)+
	"   @bIncludeFinalizedAdHocDates = IncludeFinalizedAdHocDates,"+CHAR(10) +
	"	@bIsGeneral			= IsGeneral,"+CHAR(10)+
	"	@sAdHocReference		= AdHocReference,"+CHAR(10)+
	"	@nAdHocReferenceOperator	= AdHocReferenceOperator,"+CHAR(10)+
	"	@sNameReferenceKeys		= NameReferenceKeys,"+CHAR(10)+
	"	@nNameReferenceKeysOperator	= NameReferenceKeysOperator,"+CHAR(10)+			
	"	@sAdHocMessage			= AdHocMessage,"+CHAR(10)+
	"	@nAdHocMessageOperator		= AdHocMessageOperator,"+CHAR(10)+
	"	@sAdHocEmailSubject		= AdHocEmailSubject,"+CHAR(10)+
	"	@nAdHocEmailSubjectOperator	= AdHocEmailSubjectOperator,"+CHAR(10)+		
	"	@bSinceLastWorkingDay		= SinceLastWorkingDay,"+CHAR(10)+
	"	@nImportanceLevelOperator	= ImportanceLevelOperator,"+CHAR(10)+
	"	@sImportanceLevelFrom		= ImportanceLevelFrom,"+CHAR(10)+
	"	@sImportanceLevelTo		= ImportanceLevelTo"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseQuickSearch		nvarchar(max)	'CaseQuickSearch/text()',"+CHAR(10)+
	"	      IsReminders			bit		'Include/IsReminders',"+CHAR(10)+
	"	      IsDueDates			bit		'Include/IsDueDates',"+CHAR(10)+
	"	      IsAdHocDates			bit		'Include/IsAdHocDates',"+CHAR(10)+
	"	      NameKey			int			'BelongsTo/NameKey/text()',"+CHAR(10)+	
 	"	      NameKeys			nvarchar(max)					'BelongsTo/NameKeys/text()',"+CHAR(10)+	
	"	      NameKeyOperator		tinyint						'BelongsTo/NameKey/@Operator/text()',"+CHAR(10)+	
	"	      IsCurrentUser		bit		'BelongsTo/NameKey/@IsCurrentUser',"+CHAR(10)+	
	"		  IsAnyone			bit		'BelongsTo/NameKey/@IsAnyone',"+CHAR(10)+	
	"	      MemberOfGroupKey		smallint		'BelongsTo/MemberOfGroupKey/text()',"+CHAR(10)+	
	"	      MemberOfGroupKeyOperator	tinyint		'BelongsTo/MemberOfGroupKey/@Operator/text()',"+CHAR(10)+
	"	      MemberOfGroupKeys		nvarchar(max)		'BelongsTo/MemberOfGroupKeys/text()',"+CHAR(10)+	
	"	      MemberOfGroupKeysOperator	tinyint		'BelongsTo/MemberOfGroupKeys/@Operator/text()',"+CHAR(10)+
	"	      MemberIsCurrentUser	bit			'BelongsTo/MemberOfGroupKey/@IsCurrentUser',"+CHAR(10)+	
	"	      IsReminderRecipient		bit		'BelongsTo/ActingAs/@IsReminderRecipient',"+CHAR(10)+
	"	      UseDueDate		bit			'Dates/@UseDueDate/text()',"+CHAR(10)+	
	"	      UseReminderDate		bit		'Dates/@UseReminderDate/text()',"+CHAR(10)+	
	"		  IsResponsibleStaff	bit		'BelongsTo/ActingAs/@IsResponsibleStaff',"+CHAR(10)+
	"	      DateRangeOperator		tinyint	'Dates/DateRange/@Operator/text()',"+CHAR(10)+		
	"	      DateRangeFrom		datetime	'Dates/DateRange/From/text()',"+CHAR(10)+	
	"	      DateRangeTo		datetime	'Dates/DateRange/To/text()',"+CHAR(10)+
	"	      PeriodRangeOperator	tinyint		'Dates/PeriodRange/@Operator/text()',"+CHAR(10)+		
	"	      PeriodRangeType		nvarchar(2)	'Dates/PeriodRange/Type/text()',"+CHAR(10)+
	"	      PeriodRangeFrom		smallint	'Dates/PeriodRange/From/text()',"+CHAR(10)+
	"	      PeriodRangeTo		smallint	'Dates/PeriodRange/To/text()',"+CHAR(10)+	
	"	      HasCase			bit		'Include/HasCase',"+CHAR(10)+	
	"	      HasName			bit		'Include/HasName',"+CHAR(10)+	
	"	      IncludeFinalizedAdHocDates			bit		'Include/IncludeFinalizedAdHocDates',"+CHAR(10)+	
	"	      IsGeneral			bit		'Include/IsGeneral',"+CHAR(10)+
	"	      AdHocReference		nvarchar(20)	'AdHocReference/text()',"+CHAR(10)+
	"	      AdHocReferenceOperator	tinyint		'AdHocReference/@Operator/text()',"+CHAR(10)+
	"		  NameReferenceKeys	nvarchar(max)        'NameReferenceKeys/text()',"+CHAR(10)+
	"         NameReferenceKeysOperator	tinyint		'NameReferenceKeys/@Operator/text()',"+CHAR(10)+
	"	      AdHocMessage		nvarchar(254)	'AdHocMessage/text()',"+CHAR(10)+		
	"	      AdHocMessageOperator	tinyint		'AdHocMessage/@Operator/text()',"+CHAR(10)+	
	"	      AdHocEmailSubject		nvarchar(100)	'AdHocEmailSubject/text()',"+CHAR(10)+	
	"	      AdHocEmailSubjectOperator tinyint		'AdHocEmailSubject/@Operator/text()',"+CHAR(10)+	
	"	      SinceLastWorkingDay	bit		'Dates/@SinceLastWorkingDay/text()',"+CHAR(10)+	
	"	      ImportanceLevelOperator	tinyint		'ImportanceLevel/@Operator/text()',"+CHAR(10)+
	"	      ImportanceLevelFrom	nvarchar(2)	'ImportanceLevel/From/text()',"+CHAR(10)+	
	"	      ImportanceLevelTo		nvarchar(2)	'ImportanceLevel/To/text()'"+CHAR(10)+	
    "     		)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sCaseQuickSearch		nvarchar(max)	output,				
				  @bIsReminders			bit			output,
				  @bIsDueDates			bit			output,
				  @bIsAdHocDates				bit			output,				 
				  @nNameKey				int			output,				
				  @sNameKeys			nvarchar(max)		output,				
				  @nNameKeyOperator		tinyint			output,				 
				  @bIsCurrentUser				bit			output,		
				  @nMemberOfGroupKey			smallint		output,		
				  @nMemberOfGroupKeyOperator	tinyint			output,		
				  @sMemberOfGroupKeys			nvarchar(max)		output,		
				  @nMemberOfGroupKeysOperator	tinyint			output,
				  @bMemberIsCurrentUser			bit			output,					  
				  @bIsReminderRecipient			bit			output,
				   @bUseDueDate					bit			output,
				  @bUseReminderDate				bit			output,
				  @nDateRangeOperator			tinyint			output,
				  @dtDateRangeFrom		datetime		output,
				  @dtDateRangeTo		datetime		output,
				  @nPeriodRangeOperator	tinyint			output,
				  @sPeriodRangeType		nvarchar(2)		output,
				  @nPeriodRangeFrom		smallint		output,
				  @nPeriodRangeTo		smallint		output,
				  @bIsResponsibleStaff		bit			output,
				  @bHasCase			bit					output,
				  @bHasName			bit					output,
				  @bIncludeFinalizedAdHocDates			bit					output,
				  @bIsGeneral			bit				output,	
				  @sAdHocReference		nvarchar(20)		output,
				  @nAdHocReferenceOperator	tinyint			output,				  
				  @sNameReferenceKeys		nvarchar(max)     		output,
				  @nNameReferenceKeysOperator	tinyint			output,
				  @sAdHocMessage		nvarchar(254)		output,
				  @nAdHocMessageOperator	tinyint			output,
				  @sAdHocEmailSubject		nvarchar(100)		output,
				  @nAdHocEmailSubjectOperator	tinyint			output,
				  @bSinceLastWorkingDay		bit			output,
				  @nImportanceLevelOperator	tinyint			output,					  
				  @sImportanceLevelFrom		nvarchar(2)		output,
				  @sImportanceLevelTo		nvarchar(2)		output',
				  @idoc				= @idoc,
				  @sCaseQuickSearch		= @sCaseQuickSearch	output,
				  @bIsReminders				=  @bIsReminders	output,
				  @bIsDueDates			=  @bIsDueDates			output,
				  @bIsAdHocDates				=  @bIsAdHocDates			output,				 
				  @nNameKey			= @nNameKey		output,				
				  @sNameKeys			= @sNameKeys		output,			
				  @nNameKeyOperator		= @nNameKeyOperator	output,				 
				  @bIsCurrentUser 		= @bIsCurrentUser	output,
				  @nMemberOfGroupKey		= @nMemberOfGroupKey	output,
				  @nMemberOfGroupKeyOperator	= @nMemberOfGroupKeyOperator output,
				  @sMemberOfGroupKeys		= @sMemberOfGroupKeys	output,
				  @nMemberOfGroupKeysOperator	= @nMemberOfGroupKeysOperator output,
				  @bMemberIsCurrentUser		= @bMemberIsCurrentUser output,
				  @bIsReminderRecipient			= @bIsReminderRecipient		output,		
				  @bUseDueDate			= @bUseDueDate		output,
				  @bUseReminderDate		= @bUseReminderDate 	output,
				  @nDateRangeOperator		= @nDateRangeOperator	output,
				  @dtDateRangeFrom		= @dtDateRangeFrom	output,
				  @dtDateRangeTo		= @dtDateRangeTo 	output,
				  @nPeriodRangeOperator		= @nPeriodRangeOperator output,
				  @sPeriodRangeType		= @sPeriodRangeType 	output,
				  @nPeriodRangeFrom		= @nPeriodRangeFrom 	output,
				  @nPeriodRangeTo		= @nPeriodRangeTo	output,				 
				  @bIsResponsibleStaff		= @bIsResponsibleStaff	output,
				  @bHasCase			= @bHasCase		output,
				  @bHasName 		= @bHasName		output,
				  @bIncludeFinalizedAdHocDates 		= @bIncludeFinalizedAdHocDates		output,
				  @bIsGeneral			= @bIsGeneral		output,
				  @sAdHocReference		= @sAdHocReference	output,
				  @nAdHocReferenceOperator	= @nAdHocReferenceOperator output,
				  @sNameReferenceKeys		= @sNameReferenceKeys	output,
				  @nNameReferenceKeysOperator	= @nNameReferenceKeysOperator output,
				  @sAdHocMessage		= @sAdHocMessage	output,
				  @nAdHocMessageOperator	= @nAdHocMessageOperator output,
				  @sAdHocEmailSubject		= @sAdHocEmailSubject output,
				  @nAdHocEmailSubjectOperator	= @nAdHocEmailSubjectOperator output,				  
				  @bSinceLastWorkingDay		= @bSinceLastWorkingDay output,
				  @nImportanceLevelOperator	= @nImportanceLevelOperator output,
				  @sImportanceLevelFrom		= @sImportanceLevelFrom output,
				  @sImportanceLevelTo 		= @sImportanceLevelTo	output



	if @nErrorCode = 0
	Begin
		Set @sSQLString = 	
	"Select @sCaseQuickSearch		= CaseQuickSearch, "+CHAR(10)+		
	"	@sCaseKeys				=	  CaseKeys,"+CHAR(10)+				
	"	@nCaseKeysOperator		= CaseKeysOperator,"+CHAR(10)+
	"	@sCaseReference 			=	  CaseReference ,"+CHAR(10)+				
	"	@nCaseReferenceOperator 		= CaseReferenceOperator,"+CHAR(10)+
	"	@sOfficialNumber	= OfficialNumber,"+CHAR(10)+
	"	@nOfficialNumberOperator= OfficialNumberOperator,"+CHAR(10)+
	"	@sNumberTypeKey	= NumberTypeKey,"+CHAR(10)+
	"	@bUseRelatedCase	= UseRelatedCase,"+CHAR(10)+
	"	@bUseNumericSearch	= UseNumericSearch,"+CHAR(10)+
	"	@bUseCurrent		= UseCurrent,"+CHAR(10)+
	"	@nFamilyKeyListOperator		= FamilyKeyListOperator,"+CHAR(10)+
	"	@nCaseListKeyOperator	= CaseListKeyOperator,"+CHAR(10)+
	"	@nCaseListKey		= CaseListKey,"+CHAR(10)+
	"	@sOfficeKeys		= OfficeKeys,"+CHAR(10)+
	"	@nOfficeKeyOperator	= OfficeKeyOperator,"+CHAR(10)+
	"	@sReminderForNameKeys	=	  ReminderForNameKeys,"+CHAR(10)+				
	"	@nReminderForNameKeysOperator		= ReminderForNameKeysOperator,"+CHAR(10)+
	"	@sCountryKeys			    =	  CountryKeys,"+CHAR(10)+	
	"	@nCountryKeysOperator		=	  CountryKeysOperator,"+CHAR(10)+	
	"	@sPropertyTypeKeys			    =	  PropertyTypeKeys,"+CHAR(10)+	
	"	@nPropertyTypeKeysOperator			=	  PropertyTypeKeysOperator,"+CHAR(10)+	
	"	@sCaseTypeKeys			    =	  CaseTypeKeys,"+CHAR(10)+	
	"	@nCaseTypeKeysOperator			=	  CaseTypeKeysOperator,"+CHAR(10)+
	"	@sCategoryKey			= CategoryKey,"+CHAR(10)+
	"	@nCategoryKeyOperator		= CategoryKeyOperator,"+CHAR(10)+
	"	@sSubTypeKey			= SubTypeKey,"+CHAR(10)+
	"	@nSubTypeKeyOperator		= SubTypeKeyOperator,"+CHAR(10)+
	"	@sBasisKey			= BasisKey,"+CHAR(10)+
	"	@nBasisKeyOperator		= BasisKeyOperator,"+CHAR(10)+
	"	@sStaffMemberKeys			    	=	  StaffMemberKeys,"+CHAR(10)+	
	"	@nStaffMemberKeysOperator			=	  StaffMemberKeysOperator,"+CHAR(10)+	
	"	@sSignatoryKeys			    =	  SignatoryKeys	,"+CHAR(10)+	
	"	@nSignatoryKeysOperator			=	  SignatoryKeysOperator	,"+CHAR(10)+	
	"	@sOwnerKeys			    =	  OwnerKeys	,"+CHAR(10)+	
	"	@nOwnerKeysOperator			=	  OwnerKeysOperator,"+CHAR(10)+	
	"	@sInstructorKeys			    =	  InstructorKeys,"+CHAR(10)+	
	"	@nInstructorKeysOperator			=	  InstructorKeysOperator,"+CHAR(10)+	
	"	@sOtherNameTypeKeys			    =	  OtherNameTypeKeys,"+CHAR(10)+	
	"	@nOtherNameTypeKeysOperator			=	  OtherNameTypeKeysOperator,"+CHAR(10)+	
	"	@sOtherNameType		    =	  OtherNameType,"+CHAR(10)+
	"	@sStatusKey		= StatusKey,"+CHAR(10)+
	"	@nStatusKeyOperator	= StatusKeyOperator,"+CHAR(10)+
	"	@sRenewalStatusKeys	= RenewalStatusKey,"+CHAR(10)+
	"	@nRenewalStatusKeyOperator= RenewalStatusKeyOperator,"+CHAR(10)+
	"	@bIsPending		= IsPending,"+CHAR(10)+
	"	@bIsRegistered		= IsRegistered,"+CHAR(10)+
	"	@bIsDead		= IsDead,"+CHAR(10)+
	"	@sReminderMessage		= ReminderMessage,"+CHAR(10)+
	"	@nReminderMessageOperator	= ReminderMessageOperator,"+CHAR(10)+
	"	@bIsReminderOnHold		= IsReminderOnHold,"+CHAR(10)+		
	"	@bIsReminderRead		= IsReminderRead,"+CHAR(10)+
	"	@sEventCategoryKeys		= EventCategoryKeys,"+CHAR(10)+	
	"	@nEventCategoryKeysOperator	= EventCategoryKeysOperator,"+CHAR(10)+	
	"	@sEventGroupKeys		= EventGroupKeys,"+CHAR(10)+	
	"	@nEventGroupKeysOperator	= EventGroupKeysOperator,"+CHAR(10)+	
	"	@sEventNoteTypeKeys		= EventNoteTypeKeys,"+CHAR(10)+
	"	@nEventNoteTypeKeysOperator	= EventNoteTypeKeysOperator,"+CHAR(10)+
	"	@sEventNoteText			= EventNoteText,"+CHAR(10)+
	"	@nEventNoteTextOperator		= EventNoteTextOperator,"+CHAR(10)+
	"	@bIsRenewalsOnly		= IsRenewalsOnly,"+CHAR(10)+
	"	@bIsNonRenewalsOnly		= IsNonRenewalsOnly,"+CHAR(10)+
	"	@bIncludeClosed			= IncludeClosed,"+CHAR(10)+
	"	@nActionKeysOperator		= ActionKeysOperator,"+CHAR(10)+
	"	@sActionKeys			= ActionKeys,"+CHAR(10)+	
	"	@sImportanceLevelKeys			    =	  ImportanceLevelKeys,"+CHAR(10)+	
	"	@nImportanceLevelKeysOperator			=	  ImportanceLevelKeysOperator,"+CHAR(10)+	
	"	@sDueDateResponsibilityNameKeys			    =	  DueDateResponsibilityNameKeys,"+CHAR(10)+	
	"	@nDueDateResponsibilityNameKeysOperator			=	  DueDateResponsibilityNameKeysOperator,"+CHAR(10)+	
	"	@sEventKeys			    	=	  EventKeys	,"+CHAR(10)+	
	"	@nEventKeysOperator=	  EventKeysOperator"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseQuickSearch		nvarchar(max)	'CaseQuickSearch/text()',"+CHAR(10)+	
	"	      CaseKeys			    nvarchar(max)			'CaseKeys/text()',"+CHAR(10)+	
	"	      CaseKeysOperator		tinyint					'CaseKeys/@Operator/text()',"+CHAR(10)+	
	"	      CaseReference			    nvarchar(max)		'CaseReference/text()',"+CHAR(10)+	
	"	      CaseReferenceOperator			tinyint			'CaseReference/@Operator/text()',"+CHAR(10)+	
	"		  OfficialNumber		nvarchar(36)	'OfficialNumber/Number/text()',"+CHAR(10)+
	"		  OfficialNumberOperator	tinyint		'OfficialNumber/@Operator/text()',"+CHAR(10)+
	"		  NumberTypeKey		nvarchar(3)	'OfficialNumber/TypeKey/text()',"+CHAR(10)+
	"		  UseRelatedCase		bit		'OfficialNumber/@UseRelatedCase',"+CHAR(10)+
	"		  UseNumericSearch	bit		'OfficialNumber/Number/@UseNumericSearch',"+CHAR(10)+
	"		  UseCurrent		nvarchar(36)	'OfficialNumber/@UseCurrent',"+CHAR(10)+
	"		  FamilyKeyListOperator		tinyint		'FamilyKeyList/@Operator/text()',"+CHAR(10)+
	"		  CaseListKeyOperator	tinyint		'CaseList/@Operator/text()',"+CHAR(10)+
	"		  CaseListKey		int		'CaseList/text()',"+CHAR(10)+
	"		  OfficeKeys		nvarchar(4000)	'OfficeKeys/text()',"+CHAR(10)+
	"         OfficeKeyOperator	tinyint		'OfficeKeys/@Operator/text()',"+CHAR(10)+
	"	      CountryKeys			    nvarchar(max)		'CountryKeys/text()',"+CHAR(10)+	
	"	      CountryKeysOperator		tinyint				'CountryKeys/@Operator/text()',"+CHAR(10)+	
	"	      PropertyTypeKeys			    nvarchar(max)	'PropertyTypeKeys/text()',"+CHAR(10)+	
	"	      PropertyTypeKeysOperator		tinyint			'PropertyTypeKeys/@Operator/text()',"+CHAR(10)+	
	"	      CaseTypeKeys			    nvarchar(max)	'CaseTypeKeys/text()',"+CHAR(10)+	
	"	      CaseTypeKeysOperator		tinyint			'CaseTypeKeys/@Operator/text()',"+CHAR(10)+	
	"	      CategoryKey		nvarchar(200)	'CategoryKey/text()',"+CHAR(10)+
	"	      CategoryKeyOperator	tinyint		'CategoryKey/@Operator/text()',"+CHAR(10)+
	"	      SubTypeKey		nvarchar(200)	'SubTypeKey/text()',"+CHAR(10)+
	"	      SubTypeKeyOperator	tinyint		'SubTypeKey/@Operator/text()',"+CHAR(10)+
	"	      BasisKey			nvarchar(200)	'BasisKey/text()',"+CHAR(10)+
	"	      BasisKeyOperator		tinyint		'BasisKey/@Operator/text()',"+CHAR(10)+
	"	      StaffMemberKeys			    nvarchar(max)	'StaffMemberKeys/text()',"+CHAR(10)+	
	"	      StaffMemberKeysOperator		tinyint			'StaffMemberKeys/@Operator/text()',"+CHAR(10)+	
	"	      ReminderForNameKeys			    nvarchar(max)	'ReminderForNameKeys/text()',"+CHAR(10)+	
	"	      ReminderForNameKeysOperator		tinyint			'ReminderForNameKeys/@Operator/text()',"+CHAR(10)+	
	"	      SignatoryKeys			    nvarchar(max)	'SignatoryKeys/text()',"+CHAR(10)+	
	"	      SignatoryKeysOperator		tinyint			'SignatoryKeys/@Operator/text()',"+CHAR(10)+	
	"	      OwnerKeys			    nvarchar(max)		'OwnerKeys/text()',"+CHAR(10)+	
	"	      OwnerKeysOperator		tinyint				'OwnerKeys/@Operator/text()',"+CHAR(10)+
	"	      InstructorKeys			    nvarchar(max)		'InstructorKeys/text()',"+CHAR(10)+	
	"	      InstructorKeysOperator		tinyint				'InstructorKeys/@Operator/text()',"+CHAR(10)+	
	"	      OtherNameTypeKeys			    nvarchar(max)		'OtherNameTypeKeys/text()',"+CHAR(10)+	
	"	      OtherNameTypeKeysOperator		tinyint				'OtherNameTypeKeys/@Operator/text()',"+CHAR(10)+
	"	      OtherNameType			    nvarchar(100)		'OtherNameTypeKeys/@Type/text()',"+CHAR(10)+
	"		  StatusKey		nvarchar(4000)	'StatusKey/text()',"+CHAR(10)+
	"		  StatusKeyOperator	tinyint		'StatusKey/@Operator/text()',"+CHAR(10)+
	"		  RenewalStatusKey	nvarchar(3500)	'RenewalStatusKey/text()',"+CHAR(10)+
	"		  RenewalStatusKeyOperator tinyint		'RenewalStatusKey/@Operator/text()',"+CHAR(10)+
	"		  IsPending		bit		'StatusFlags/IsPending',"+CHAR(10)+
	"		  IsRegistered		bit		'StatusFlags/IsRegistered',"+CHAR(10)+
	"		  IsDead			bit		'StatusFlags/IsDead',"+CHAR(10)+
	"	      ReminderMessage		nvarchar(254)	'ReminderMessage/text()',"+CHAR(10)+	
	"	      ReminderMessageOperator	tinyint		'ReminderMessage/@Operator/text()',"+CHAR(10)+	
	"	      IsReminderOnHold		bit		'IsReminderOnHold/text()',"+CHAR(10)+		
	"	      IsReminderRead		bit		'IsReminderRead/text()',"+CHAR(10)+	
	"	      EventCategoryKeys		nvarchar(max)	'EventCategoryKeys/text()',"+CHAR(10)+	
	"	      EventCategoryKeysOperator	tinyint		'EventCategoryKeys/@Operator/text()',"+CHAR(10)+	
	"		  EventGroupKeys	nvarchar(max)  'EventGroupKeys/text()',"+CHAR(10)+	
	"		  EventGroupKeysOperator tinyint 'EventGroupKeys/@Operator/text()',"+CHAR(10)+	
	"	      EventNoteTypeKeys		nvarchar(4000)	'EventNoteTypeKeys/text()',"+CHAR(10)+
	"	      EventNoteTypeKeysOperator	tinyint		'EventNoteTypeKeys/@Operator/text()',"+CHAR(10)+ 
	"	      EventNoteText		nvarchar(max)	'EventNoteText/text()',"+CHAR(10)+
	"	      EventNoteTextOperator	tinyint		'EventNoteText/@Operator/text()',"+CHAR(10)+  
	"	      IsRenewalsOnly		bit		'Actions/@IsRenewalsOnly',"+CHAR(10)+
	"	      IsNonRenewalsOnly		bit		'Actions/@IsNonRenewalsOnly',"+CHAR(10)+
	"	      IncludeClosed		bit		'Actions/@IncludeClosed',"+CHAR(10)+	
	"	      ActionKeysOperator	tinyint		'Actions/ActionKeys/@Operator/text()',"+CHAR(10)+
	"	      ActionKeys		nvarchar(1000)	'Actions/ActionKeys/text()',"+CHAR(10)+
	"	      ImportanceLevelKeys		nvarchar(max)	'ImportanceLevelKeys/text()',"+CHAR(10)+	
	"	      ImportanceLevelKeysOperator	tinyint		'ImportanceLevelKeys/@Operator/text()',"+CHAR(10)+	
	"	      DueDateResponsibilityNameKeys		nvarchar(max)	'DueDateResponsibilityNameKeys/text()',"+CHAR(10)+	
	"	      DueDateResponsibilityNameKeysOperator	tinyint		'DueDateResponsibilityNameKeys/@Operator/text()',"+CHAR(10)+	
	"	      EventKeys			    nvarchar(max)		'EventKeys/text()',"+CHAR(10)+	
	"	      EventKeysOperator		tinyint				'EventKeys/@Operator/text()'"+CHAR(10)+	
    "     		)"
	
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sCaseQuickSearch		nvarchar(max)	output,
				  @sCaseKeys			nvarchar(max)		output,				
				  @nCaseKeysOperator	tinyint			output,
				  @sCaseReference 			nvarchar(max) output,
				  @sOfficialNumber			nvarchar(36)			output,
				  @nOfficialNumberOperator		tinyint				output,
				  @sNumberTypeKey			nvarchar(3)			output,
				  @bUseRelatedCase			bit				output,
				  @bUseNumericSearch			bit				output,
				  @bUseCurrent				bit				output,
				  @nFamilyKeyListOperator		tinyint				output,
				  @nCaseListKeyOperator			tinyint				output,
				  @nCaseListKey				    int				output,
				  @sOfficeKeys				nvarchar(4000)			output,
				  @nOfficeKeyOperator			tinyint				output,
				  @nCaseReferenceOperator			tinyint output,
				  @sCountryKeys			nvarchar(max)		output,
				  @nCountryKeysOperator	tinyint			output,
			      @sPropertyTypeKeys		nvarchar(max)		output,
				  @nPropertyTypeKeysOperator		tinyint			output,
				  @sCaseTypeKeys		nvarchar(max)		output,
				  @nCaseTypeKeysOperator		tinyint			output,
				  @sCategoryKey			nvarchar(200)			output,
				  @sSubTypeKey			nvarchar(200)			output,
				  @nSubTypeKeyOperator		tinyint				output,
				  @sBasisKey			nvarchar(200)			output,
				  @nBasisKeyOperator		tinyint				output,
				  @nCategoryKeyOperator		tinyint				output,
				  @sStaffMemberKeys			    nvarchar(max)		output,
				  @nStaffMemberKeysOperator		tinyint		output,
				  @sSignatoryKeys					nvarchar(max)		output,
				  @nSignatoryKeysOperator			tinyint		output,
				  @sReminderForNameKeys					nvarchar(max)		output,
				  @nReminderForNameKeysOperator			tinyint		output,
				  @sOwnerKeys						nvarchar(max)		output,
				  @nOwnerKeysOperator				tinyint		output, 
				  @sInstructorKeys						nvarchar(max)		output,
				  @nInstructorKeysOperator				tinyint		output, 					  
				  @sOtherNameTypeKeys						nvarchar(max)		output,
				  @nOtherNameTypeKeysOperator				tinyint		output, 
				  @sOtherNameType						nvarchar(100)		output,
				  @sStatusKey				nvarchar(4000)			output,
				  @nStatusKeyOperator			tinyint				output,
				  @sRenewalStatusKeys			nvarchar(3500)			output,
				  @nRenewalStatusKeyOperator		tinyint				output,
				  @bIsPending				bit				output,
				  @bIsRegistered			bit				output,
				  @bIsDead				bit				output,
				  @sReminderMessage		nvarchar(254)		output,
				  @nReminderMessageOperator	tinyint			output,
				  @bIsReminderOnHold		bit			output,
				  @bIsReminderRead		bit			output,
				  @sEventCategoryKeys		nvarchar(max)		output,
				  @nEventCategoryKeysOperator	tinyint			output,
				  @sEventGroupKeys		nvarchar(max)		output,
				  @nEventGroupKeysOperator		tinyint		output,
				  @sEventNoteTypeKeys		nvarchar(4000)		output,
				  @nEventNoteTypeKeysOperator	tinyint			output,
				  @sEventNoteText		nvarchar(max)		output,
				  @nEventNoteTextOperator	tinyint			output,
				  @bIsRenewalsOnly 		bit			output,
				  @bIsNonRenewalsOnly		bit			output,
				  @bIncludeClosed		bit			output,
				  @nActionKeysOperator		tinyint			output,
				  @sActionKeys            	nvarchar(1000)		output,	
				  @sImportanceLevelKeys		nvarchar(max)		output,
				  @nImportanceLevelKeysOperator	tinyint			output,
				  @sDueDateResponsibilityNameKeys		nvarchar(max)		output,
				  @nDueDateResponsibilityNameKeysOperator	tinyint			output,
				  @sEventKeys						nvarchar(max)		output,
				  @nEventKeysOperator				tinyint		output',
				  @idoc				= @idoc,
				  @sCaseQuickSearch		= @sCaseQuickSearch	output,				 
				  @sCaseKeys			= @sCaseKeys		output,				
				  @nCaseKeysOperator	=  @nCaseKeysOperator			output,
				  @sCaseReference 		=	@sCaseReference  output,
				  @nCaseReferenceOperator	= @nCaseReferenceOperator output,
				  @sOfficialNumber			= @sOfficialNumber		output,
				  @nOfficialNumberOperator		= @nOfficialNumberOperator	output,
				  @sNumberTypeKey			= @sNumberTypeKey		output,
				  @bUseRelatedCase			= @bUseRelatedCase		output,
				  @bUseNumericSearch			= @bUseNumericSearch		output,
				  @bUseCurrent				= @bUseCurrent			output,
				  @nFamilyKeyListOperator		= @nFamilyKeyListOperator		output,
				  @nCaseListKeyOperator			= @nCaseListKeyOperator		output,
				  @nCaseListKey				= @nCaseListKey			output,
				  @sOfficeKeys				= @sOfficeKeys			output,
				  @nOfficeKeyOperator			= @nOfficeKeyOperator		output,
				  @sCountryKeys			    =  @sCountryKeys			output,
				  @nCountryKeysOperator		=  @nCountryKeysOperator			output,
				  @sPropertyTypeKeys			  =  @sPropertyTypeKeys			output,  
				  @nPropertyTypeKeysOperator		=  @nPropertyTypeKeysOperator			output,
				  @sCaseTypeKeys			  =  @sCaseTypeKeys			output,  
				  @nCaseTypeKeysOperator		=  @nCaseTypeKeysOperator			output,
				  @sCategoryKey			= @sCategoryKey			output,
				  @nCategoryKeyOperator		= @nCategoryKeyOperator		output,
				  @sSubTypeKey			= @sSubTypeKey			output,
				  @nSubTypeKeyOperator		= @nSubTypeKeyOperator		output,
				  @sBasisKey			= @sBasisKey			output,
				  @nBasisKeyOperator		= @nBasisKeyOperator		output,
				  @sStaffMemberKeys			    =  @sStaffMemberKeys			output,	
				  @nStaffMemberKeysOperator		=  @nStaffMemberKeysOperator			output,	
				  @sSignatoryKeys			    =  @sSignatoryKeys			output,
				  @nSignatoryKeysOperator			=  @nSignatoryKeysOperator			output,
				  @sReminderForNameKeys				    =  @sReminderForNameKeys				output,
				  @nReminderForNameKeysOperator				=  @nReminderForNameKeysOperator				output,
				  @sOwnerKeys			    =  @sOwnerKeys			output,
				  @nOwnerKeysOperator			=  @nOwnerKeysOperator	output,
				  @sInstructorKeys			    =  @sInstructorKeys			output,
				  @nInstructorKeysOperator			=  @nInstructorKeysOperator	output,				  				 
				  @sOtherNameTypeKeys			    =  @sOtherNameTypeKeys			output,
				  @nOtherNameTypeKeysOperator			=  @nOtherNameTypeKeysOperator	output,
				  @sOtherNameType	= @sOtherNameType	output,
				  @sStatusKey				= @sStatusKey			output,
				  @nStatusKeyOperator			= @nStatusKeyOperator		output,
				  @sRenewalStatusKeys			= @sRenewalStatusKeys		output,
				  @nRenewalStatusKeyOperator		= @nRenewalStatusKeyOperator	output,
				  @bIsPending				= @bIsPending			output,
				  @bIsRegistered			= @bIsRegistered		output,
				  @bIsDead				= @bIsDead			output,
				  @sReminderMessage		= @sReminderMessage	output,
				  @nReminderMessageOperator	= @nReminderMessageOperator output,
				  @bIsReminderOnHold		= @bIsReminderOnHold	output,
				  @bIsReminderRead		= @bIsReminderRead	output,
				  @sEventCategoryKeys		= @sEventCategoryKeys	output,
				  @nEventCategoryKeysOperator	= @nEventCategoryKeysOperator output,
				  @sEventGroupKeys			    	=  @sEventGroupKeys		output,
				  @nEventGroupKeysOperator		=  @nEventGroupKeysOperator	output,
				  @sEventNoteTypeKeys		= @sEventNoteTypeKeys	output,
				  @nEventNoteTypeKeysOperator	= @nEventNoteTypeKeysOperator output,
				  @sEventNoteText		= @sEventNoteText	output,
				  @nEventNoteTextOperator	= @nEventNoteTextOperator output,	
				  @bIsRenewalsOnly 		= @bIsRenewalsOnly	output,
				  @bIsNonRenewalsOnly		= @bIsNonRenewalsOnly	output,
				  @bIncludeClosed		= @bIncludeClosed	output,
				  @nActionKeysOperator		= @nActionKeysOperator	output,	
			      @sActionKeys             	= @sActionKeys 		output,	
				  @sImportanceLevelKeys		= @sImportanceLevelKeys	output,
				  @nImportanceLevelKeysOperator	= @nImportanceLevelKeysOperator output,
				  @sDueDateResponsibilityNameKeys		= @sDueDateResponsibilityNameKeys	output,
				  @nDueDateResponsibilityNameKeysOperator	= @nDueDateResponsibilityNameKeysOperator output,
				  @sEventKeys			    	=  @sEventKeys		output,
				  @nEventKeysOperator	=  @nEventKeysOperator		output		

	End

	if @nErrorCode = 0
	Begin
		Set @sSQLString = 	
		        "Select  @sStatusKeys =	  StatusKeys,"+CHAR(10)+	
				"@nStatusKeysOperator =	  StatusKeysOperator,"+CHAR(10)+	
				"@sShortTitleText =	  ShortTitleText,"+CHAR(10)+	
				"@nShortTitleOperator =	  ShortTitleOperator"+CHAR(10)+	
				"from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria',2)"+CHAR(10)+
				"	WITH ("+CHAR(10)+	
				"	      StatusKeys		    nvarchar(max)		'StatusKeys/text()',"+CHAR(10)+	
				"	      StatusKeysOperator    tinyint				'StatusKeys/@Operator/text()',"+CHAR(10)+
				"	      ShortTitleText		    nvarchar(max)		'ShortTitles/text()',"+CHAR(10)+	
				"	      ShortTitleOperator    tinyint				'ShortTitles/@Operator/text()'"+CHAR(10)+	
				"     		)"
		
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,				  
				  @sStatusKeys		    nvarchar(max)	output,
				  @nStatusKeysOperator	tinyint		output,
				  @sShortTitleText		    nvarchar(max)	output,
				  @nShortTitleOperator	tinyint		output' ,
				  @idoc				= @idoc,
				  @sStatusKeys = @sStatusKeys output,
				  @nStatusKeysOperator = @nStatusKeysOperator output,
				  @sShortTitleText = @sShortTitleText output,
				  @nShortTitleOperator = @nShortTitleOperator output
	End
	 
	If @nErrorCode = 0
	Begin
		Select @sNameTypeKeys = @sNameTypeKeys + nullif(',', ',' + @sNameTypeKeys) + dbo.fn_WrapQuotes(NameTypeKey,0,0) 
		from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria/BelongsTo/ActingAs/NameTypeKey', 2)
		WITH (
				NameTypeKey	nvarchar(3)	'text()'
				)
		where NameTypeKey is not null
		Set @nErrorCode=@@Error
	End		
	
	If @nErrorCode = 0
	Begin
	-- Retrieve the Families filter criteria using
		-- element-centric mapping
		Select @sFamilyKeyList = @sFamilyKeyList + nullif(',', ',' + @sFamilyKeyList) + dbo.fn_WrapQuotes(FamilyKey,0,0) 
		from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria/FamilyKeyList/FamilyKey', 2)
		WITH (
				FamilyKey	nvarchar(1000)	'text()'
				)
		where FamilyKey is not null

		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc	

	Set @nErrorCode=@@Error
	End	

	If @nErrorCode = 0
	Begin
		-- If the following parameters were not supplied 
		-- then set them to 0:
		Set @bIsReminders 		= isnull(@bIsReminders,0)
		Set @bIsDueDates 		= isnull(@bIsDueDates,0)
		Set @bIsAdHocDates 		= isnull(@bIsAdHocDates,0)
		Set @bIsReminderRecipient 	= isnull(@bIsReminderRecipient,0)
		Set @bIsCurrentUser 	= isnull(@bIsCurrentUser,0)
		Set @bIsResponsibleStaff	= isnull(@bIsResponsibleStaff,0)
		set @bIncludeFinalizedAdHocDates = isNull(@bIncludeFinalizedAdHocDates, 0)
		
		-- If none of the following parameters were supplied 
		-- then set them all to 1:
		If  (@bIsReminders=0
			and @bIsDueDates=0
			and @bIsAdHocDates=0)
		Begin
			Set @bIsReminders 	= 1
			Set @bIsDueDates 	= 1
			Set @bIsAdHocDates 	= 1	
		End 				
	End
	
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
End

-- If SinceLastWorkingDay is true then the From Date value should be set to 
	-- the day after the working day before todayâ€™s date.
	If @bSinceLastWorkingDay = 1
	Begin
		Set @dtTodaysDate = getdate()

		Exec @nErrorCode = ipr_GetOneAfterPrevWorkDay
					@pdtStartDate		= @dtTodaysDate,
					@pbCalledFromCentura	= 0,
					@pdtResultDate		= @dtDateRangeFrom output
		
		Set @nDateRangeOperator = 7 
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
		join NAME N WITH (NOLOCK) on (N.NAMENO = U.NAMENO)
		left join SITECONTROL SC  WITH (NOLOCK) on (SC.CONTROLID  = 'CRITICAL LEVEL')
		left join SITECONTROL SC1 WITH (NOLOCK) on (SC1.CONTROLID = 'Client Due Dates: Overdue Days')
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
set @sCaseEventExits = ' select distinct CE.CASEID, EMPLOYEENO from CASEEVENT CE WITH (NOLOCK) '
set @sCaseEventExitsWhere = ' WHERE (CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0) '
set @sCE_ResponsibleStaff = ' select  CECN.CASEID from CASENAME CECN WITH (NOLOCK) '
set @sCE_ResponsibleStaffWhere  = ' where 1=1 '
set @sCE_ResponsibleStaffFamily = ' select CEN.NAMENO from NAME CEN WITH (NOLOCK) '
set @sCE_ResponsibleStaffFamilyWhere  = ' where 1=1 '

set @sCE_Name = ' select CEN.NAMENO from NAME CEN WITH (NOLOCK) '
set @sCE_NameWhere = ' where 1=1 '

Set @sReminderExists = ' select ER.CASEID, ER.EMPLOYEENO from EMPLOYEEREMINDER ER WITH (NOLOCK)'
set @sReminderExistsWhere = ' WHERE 1=1 '

set @sReminderRecipientFamily  = ' select RN.NAMENO from NAME RN WITH (NOLOCK) '
set @sReminderRecipientFamilyWhere  = ' where 1=1 '

set @sReminderCaseName =' SELECT CASEID FROM CASENAME RCN WITH (NOLOCK) '
set @sReminderCaseNameWhere = ' WHERE 1=1 '

Set @sAlertExists    = ' select A.CASEID, A.EMPLOYEENO from ALERT A WITH (NOLOCK) ' 
set @sAlertExistsWhere = ' WHERE (A.DUEDATE IS NOT NULL OR A.TRIGGEREVENTNO IS NOT NULL) '

Set @sAlertCaseName = ' SELECT CASEID FROM CASENAME ACN  WITH (NOLOCK) '
Set @sAlertCaseNameWhere  = ' where 1=1 '
 
set @sAlertFamily  = ' select AN.NAMENO from NAME AN WITH (NOLOCK) '
set @sAlertFamilyWhere = ' where 1=1 '

/****    CONSTRUCTION OF THE WHERE  clause  ****/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin		
		
	if @sPropertyTypeKeys is not null 
		and @nPropertyTypeKeysOperator not in (5,6)
	begin

		if charindex('Join VALIDPROPERTY VP', @psCTE_CaseDetailsFrom) = 0
		begin
			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + ' Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE
                        and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)
                                            from VALIDPROPERTY VP1 with (NOLOCK)
                                            where VP1.PROPERTYTYPE=C.PROPERTYTYPE
                                            and   VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ''))) ' + CHAR(10)
		end
		set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND VP.PROPERTYTYPE ' +  dbo.fn_ConstructOperator(@nPropertyTypeKeysOperator,@Numeric,@sPropertyTypeKeys, null,0) + CHAR(10)
				
		if (CHARINDEX('VP.PROPERTYTYPE', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', VP.PROPERTYTYPE as PropertyTypeKey '
		end

		set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.PropertyTypeKey ' +  dbo.fn_ConstructOperator(@nPropertyTypeKeysOperator,@Numeric,@sPropertyTypeKeys, null,0) + CHAR(10)			
		set	@psRemindersWhere = @psRemindersWhere +' and C.PropertyTypeKey ' +  dbo.fn_ConstructOperator(@nPropertyTypeKeysOperator,@Numeric,@sPropertyTypeKeys, null,0) + CHAR(10)
	end

	if @sCaseTypeKeys is not null 
		and @nCaseTypeKeysOperator not in (5,6)
	begin
		set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND C.CASETYPE ' +  dbo.fn_ConstructOperator(@nCaseTypeKeysOperator,@Numeric,@sCaseTypeKeys, null,0) + CHAR(10)
				
		if (CHARINDEX('CTX.CASETYPE', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', C.CASETYPE as CaseTypeKey '
		end
		set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.CaseTypeKey ' +  dbo.fn_ConstructOperator(@nCaseTypeKeysOperator,@Numeric,@sCaseTypeKeys, null,0) + CHAR(10)		
		set	@psRemindersWhere = @psRemindersWhere +' and C.CaseTypeKey ' +  dbo.fn_ConstructOperator(@nCaseTypeKeysOperator,@Numeric,@sCaseTypeKeys, null,0) + CHAR(10)			
	end
	
	if @sCaseKeys is not null 
		and @nCaseKeysOperator between 0 and 1
	begin
		set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND C.CASEID ' +  dbo.fn_ConstructOperator(@nCaseKeysOperator,@Numeric,@sCaseKeys, null,0) + CHAR(10)	
		set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.CASEID ' +  dbo.fn_ConstructOperator(@nCaseKeysOperator,@Numeric,@sCaseKeys, null,0) + CHAR(10)	
		set	@psRemindersWhere = @psRemindersWhere +' and C.CASEID ' +  dbo.fn_ConstructOperator(@nCaseKeysOperator,@Numeric,@sCaseKeys, null,0) + CHAR(10)	
	end

	if @sCaseReference is not null 
		or @nCaseReferenceOperator between 2 and 6
	begin

			if (CHARINDEX('C.IRN', @psCTE_CaseDetailsSelect)) = 0
			begin
				set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', C.IRN as CaseReference'
			end

			If  PATINDEX('%;%',@sCaseReference)>0
				Set @bMultipleCaseRefs=1
			Else
				Set @bMultipleCaseRefs=0
								
			If  @bMultipleCaseRefs=1 and @nCaseReferenceOperator=2 and PATINDEX('%[%]%',@sCaseReference)=0
				Set @nCaseReferenceOperator=0

			If  @bMultipleCaseRefs=1
			and @nCaseReferenceOperator in (0,1)
			Begin				
				Set @sNPrefix = 'N'
				
				-- Any occurrence of a single Quote is to be replaced with two single Quotes
				Set @sCaseReference=Replace(@sCaseReference, char(39), char(39)+char(39) )

				Select @sOutputString=ISNULL(NULLIF(@sOutputString + ',', ','),'')  +@sNPrefix+char(39)+t.Parameter+char(39)
				from dbo.fn_Tokenise(@sCaseReference, @SemiColon) t
			

				If @nCaseReferenceOperator=0
				Begin					
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' and C.IRN in (' + @sOutputString + ')'
					set @psAdHocDatesWhere = @psAdHocDatesWhere +  ' and C.CaseReference in (' + @sOutputString + ')'
					set	@psRemindersWhere = @psRemindersWhere +  ' and C.CaseReference in (' + @sOutputString + ')'
				End
				Else 
				Begin
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' and C.IRN not in (' + @sOutputString + ')'
					set @psAdHocDatesWhere = @psAdHocDatesWhere +  ' and C.CaseReference not in (' + @sOutputString + ')'		
					set	@psRemindersWhere = @psRemindersWhere +  ' and C.CaseReference not in (' + @sOutputString + ')'
				End
			End
			Else 
			Begin
				
				Set @sCaseReferenceWhere = ''
				Set @or = ''
				select @sCaseReferenceWhere = @sCaseReferenceWhere +				
						@or + 'C.IRN' + dbo.fn_ConstructOperator(@nCaseReferenceOperator, @String, RTRIM(LTRIM(t.Parameter)), null, @pbCalledFromCentura),
				@or = ' or '
				from dbo.fn_Tokenise(@sCaseReference, @SemiColon) t
				where t.Parameter <> ''
				and t.Parameter is not null

			    If (@sCaseReferenceWhere <> '')
			    Begin
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' and (' + @sCaseReferenceWhere + ')'
					Set @sCaseReferenceWhere=Replace(@sCaseReferenceWhere, 'C.IRN', ' C.CaseReference ')
					set @psAdHocDatesWhere = @psAdHocDatesWhere + ' and (' + @sCaseReferenceWhere + ')'

					set	@psRemindersWhere = @psRemindersWhere + ' and (' + @sCaseReferenceWhere + ')'
				End				
			End	
				
	end
	   
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

					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom +char(10)+"	     join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID = C.CASEID"
					                   +char(10)+"                                  and XCI.GENERICINDEX="+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
					   		   +char(10)+"                                  and XCI.SOURCE =5)"

					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+" and	dbo.fn_StripNonNumerics(C.CURRENTOFFICIALNO)"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
				End
				Else
				Begin

					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom +char(10)+"	     join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID = C.CASEID"
					                   +char(10)+"                                  and XCI.GENERICINDEX="+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
					   		   +char(10)+"                                  and XCI.SOURCE =5)"
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+" and	C.CURRENTOFFICIALNO"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
				End
			End
			Else If @bUseRelatedCase = 1
			and (@sOfficialNumber is not NULL
			or @nOfficialNumberOperator between 2 and 6)
			Begin
				Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	     join RELATEDCASE XRC WITH (NOLOCK) on (XRC.CASEID = C.CASEID)"
					   	+char(10)+"          join CASERELATION XCR WITH (NOLOCK) on (XCR.RELATIONSHIP=XRC.RELATIONSHIP"
					   	+char(10)+"                             	and XCR.SHOWFLAG=1)"
					   	+char(10)+"     left join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID = XRC.RELATEDCASEID"
					   	+char(10)+"                                     and XCI.SOURCE =5)"

				-- When @bUseCurrent is turned on, the search is conducted on the current official number for
				-- the case. Any NumberType values are ignored.

				If @bUseNumericSearch = 1
				Begin
					Set @sNumericOfficialNumber = dbo.fn_StripNonNumerics(@sOfficialNumber)

					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	isnull(XCI.GENERICINDEX,dbo.fn_StripNonNumerics(XRC.OFFICIALNUMBER))"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
				End
				Else
				Begin
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	isnull(XCI.GENERICINDEX,XRC.OFFICIALNUMBER)"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
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
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	left join OFFICIALNUMBERS XO WITH (NOLOCK) on(XO.CASEID    = C.CASEID"
				End
				Else If @sOfficialNumber is not NULL
				Begin
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	     join CASEINDEXES XCI WITH (NOLOCK) on (XCI.CASEID   = C.CASEID"
							   +char(10)+"					and XCI.GENERICINDEX"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,isnull(@sNumericOfficialNumber,@sOfficialNumber), null,@pbCalledFromCentura)
							   +char(10)+"					and XCI.SOURCE   =5)"
					                   +char(10)+"	     join OFFICIALNUMBERS XO WITH (NOLOCK) on (XO.CASEID    = C.CASEID"
				End
				Else Begin
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	     join OFFICIALNUMBERS XO WITH (NOLOCK) on (XO.CASEID    = C.CASEID"
				End
								
				Set @sList = null
				Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NUMBERTYPE,0,0)
				From dbo.fn_FilterUserNumberTypes(@pnUserIdentityId,null, 0,0)

				If  @nOfficialNumberOperator in (5,6)
				Begin
					If @sNumberTypeKey is not NULL
						Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	                               and XO.NUMBERTYPE="+dbo.fn_WrapQuotes(@sNumberTypeKey,0,@pbCalledFromCentura)

					If @sList is not null
						Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	                               and XO.NUMBERTYPE IN ("+@sList+")"

					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+")"
				End
				Else Begin
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+")"

					If  @sList is not null
						Set @psCTE_CaseDetailsFrom= @psCTE_CaseDetailsFrom+char(10)+"	and	XO.NUMBERTYPE IN ("+@sList+")"
				End


				If @nOfficialNumberOperator=6
				Begin
					Set @psCTE_CaseDetailsFrom= @psCTE_CaseDetailsFrom+char(10)+"	and	XO.CASEID is null"
				End
				Else If @nOfficialNumberOperator<>5
				     and @sNumberTypeKey is not NULL
				Begin
					Set @psCTE_CaseDetailsFrom= @psCTE_CaseDetailsFrom+char(10)+"	and	XO.NUMBERTYPE = "+dbo.fn_WrapQuotes(@sNumberTypeKey,0,@pbCalledFromCentura)
				End

				If @sOfficialNumber is not NULL
				and @nOfficialNumberOperator not in (5,6)
				Begin
					If @bUseNumericSearch = 1
					Begin
						Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	and	dbo.fn_StripNonNumerics(XO.OFFICIALNUMBER)"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sNumericOfficialNumber, null,@pbCalledFromCentura)
					End
					Else
					Begin
						Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	and	XO.OFFICIALNUMBER"+dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,@sOfficialNumber, null,@pbCalledFromCentura)
					End
				End
			End
		End

	If @sFamilyKeyList is not NULL
		or @nFamilyKeyListOperator between 2 and 6
		Begin
			Set @psCTE_CaseDetailsWhere = case 
				when @sFamilyKeyList is not null and @nFamilyKeyListOperator = 0 then @psCTE_CaseDetailsWhere+char(10)+"	and	C.FAMILY in (" + @sFamilyKeyList + ")"
				when @sFamilyKeyList is not null and @nFamilyKeyListOperator = 1 then @psCTE_CaseDetailsWhere+char(10)+"	and	C.FAMILY not in (" + @sFamilyKeyList + ")"
				when @nFamilyKeyListOperator = 5 then @psCTE_CaseDetailsWhere+char(10)+"	and	C.FAMILY is not null"
				when @nFamilyKeyListOperator = 6 then @psCTE_CaseDetailsWhere+char(10)+"	and	C.FAMILY is null"
				else ''
			End
		End

	If @nCaseListKey is not NULL		
		or @nCaseListKeyOperator in (0,1,5,6)
		Begin
			-- If Operator is set to NOT EQUAL or IS NULL then use LEFT JOIN
			If @nCaseListKeyOperator in (1,6)
			Begin
				set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	Left Join (select distinct CASEID from CASELISTMEMBER with (NOLOCK)"
						   +char(10)+"	      where 1=1"
			End
			Else
			Begin
				Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	Join (select distinct CASEID from CASELISTMEMBER with (NOLOCK)"
						   +char(10)+"	      where 1=1"
			End

			If @nCaseListKey is not null
				Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	      and CASELISTNO="+convert(varchar,@nCaseListKey)		

			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+") XCLM on (XCLM.CASEID=C.CASEID)"

			If @nCaseListKeyOperator in (1,6)
				Set @psCTE_CaseDetailsWhere=@psCTE_CaseDetailsWhere+char(10)+"and XCLM.CASEID is NULL"
		End

	if @sOfficeKeys is not null or  @nOfficeKeyOperator in (5,6)
	Begin
		If @nOfficeKeyOperator between 0 and 1
			Begin
				Set @psCTE_CasesWhere =@psCTE_CasesWhere +char(10)+"	and	( C.OFFICEID " + dbo.fn_ConstructOperator(@nOfficeKeyOperator,@CommaString,@sOfficeKeys, null,@pbCalledFromCentura) + ") " +char(10)
			End
		Else
			Begin
				Set @psCTE_CasesWhere=@psCTE_CasesWhere+char(10)+"	and	( C.OFFICEID "+ dbo.fn_ConstructOperator(@nOfficeKeyOperator,@String,@sOfficeKeys, null,@pbCalledFromCentura) + ") " +char(10)
			End
	End		

	if @sOwnerKeys is not null 
		or @nOwnerKeysOperator in (5,6)
	begin
				
		if CHARINDEX('LEFT JOIN CASENAME CNO', @psCTE_CaseDetailsFrom) = 0
		begin			
			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CASENAME CNO WITH (NOLOCK) ON (CNO.CASEID = C.CASEID AND CNO.NAMETYPE = ''O'') ' + CHAR(10) 
		end

		if (CHARINDEX('CNO.NAMENO', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', CNO.NAMENO as OwnerKey '
		end

		if @nOwnerKeysOperator between 0 and 1 
		Begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND CNO.NAMENO ' +  dbo.fn_ConstructOperator(@nOwnerKeysOperator,@Numeric,@sOwnerKeys, null,0) + CHAR(10)
			set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.OwnerKey ' +  dbo.fn_ConstructOperator(@nOwnerKeysOperator,@Numeric,@sOwnerKeys, null,0) + CHAR(10)	
			set	@psRemindersWhere = @psRemindersWhere +' and C.OwnerKey ' +  dbo.fn_ConstructOperator(@nOwnerKeysOperator,@Numeric,@sOwnerKeys, null,0) + CHAR(10)
		end
		else
		begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND dbo.fn_FormatNameUsingNameNo(CNO.NAMENO, null) ' +  dbo.fn_ConstructOperator(@nOwnerKeysOperator,@String,@sOwnerKeys, null,0) + CHAR(10)
			set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and dbo.fn_FormatNameUsingNameNo(C.OwnerKey, null) ' +  dbo.fn_ConstructOperator(@nOwnerKeysOperator,@String,@sOwnerKeys, null,0) + CHAR(10)	
			set	@psRemindersWhere = @psRemindersWhere +' and dbo.fn_FormatNameUsingNameNo(C.OwnerKey, null) ' +  dbo.fn_ConstructOperator(@nOwnerKeysOperator,@String,@sOwnerKeys, null,0) + CHAR(10)	
		end
	end

	if @sInstructorKeys is not null 
		or @nInstructorKeysOperator in (5,6)
	begin
				
		if CHARINDEX('LEFT JOIN CASENAME CNI', @psCTE_CaseDetailsFrom) = 0
		begin
			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CASENAME CNI WITH (NOLOCK) ON (CNI.CASEID = C.CASEID AND CNI.NAMETYPE = ''I'') ' + CHAR(10) 
		end
				
		if (CHARINDEX('CNI.NAMENO', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', CNI.NAMENO as InstructorKey '
		end

		if @nInstructorKeysOperator between 0 and 1 
		Begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND CNI.NAMENO ' +  dbo.fn_ConstructOperator(@nInstructorKeysOperator,@Numeric,@sInstructorKeys, null,0) + CHAR(10)		
			set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.InstructorKey ' +  dbo.fn_ConstructOperator(@nInstructorKeysOperator,@Numeric,@sInstructorKeys, null,0) + CHAR(10)		
			set	@psRemindersWhere = @psRemindersWhere +' and C.InstructorKey ' +  dbo.fn_ConstructOperator(@nInstructorKeysOperator,@Numeric,@sInstructorKeys, null,0) + CHAR(10)
		end
		else
		begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND dbo.fn_FormatNameUsingNameNo(CNI.NAMENO, null) ' +  dbo.fn_ConstructOperator(@nInstructorKeysOperator,@String,@sInstructorKeys, null,0) + CHAR(10)
			set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and dbo.fn_FormatNameUsingNameNo(C.InstructorKey, null) ' +  dbo.fn_ConstructOperator(@nInstructorKeysOperator,@Numeric,@sInstructorKeys, null,0) + CHAR(10)	
			set	@psRemindersWhere = @psRemindersWhere +' and dbo.fn_FormatNameUsingNameNo(C.InstructorKey, null) ' +  dbo.fn_ConstructOperator(@nInstructorKeysOperator,@Numeric,@sInstructorKeys, null,0) + CHAR(10)	
		end
	end
	
	if @sStatusKeys is not null 
		or @nStatusKeysOperator in (0,1)
	begin				
		
		if (CHARINDEX('C.STATUSCODE', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', C.STATUSCODE as StatusKey '
		end

		if @nStatusKeysOperator between 0 and 1 
		Begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND C.STATUSCODE ' +  dbo.fn_ConstructOperator(@nStatusKeysOperator,@Numeric,@sStatusKeys, null,0) + CHAR(10)		
			set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.StatusKey ' +  dbo.fn_ConstructOperator(@nStatusKeysOperator,@Numeric,@sStatusKeys, null,0) + CHAR(10)		
			set	@psRemindersWhere = @psRemindersWhere +' and C.StatusKey ' +  dbo.fn_ConstructOperator(@nStatusKeysOperator,@Numeric,@sStatusKeys, null,0) + CHAR(10)
		end		
	end

	if @sOtherNameTypeKeys is not null 
		or @nOtherNameTypeKeysOperator in (5,6)
	begin
				
		if CHARINDEX('LEFT JOIN CASENAME CNXX', @psCTE_CaseDetailsFrom) = 0
		begin
			if @sOtherNameType is null
			begin
				Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CASENAME CNXX WITH (NOLOCK) ON (CNXX.CASEID = C.CASEID ) ' + CHAR(10) 
			end
			else
			begin
				Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CASENAME CNXX WITH (NOLOCK) ON (CNXX.CASEID = C.CASEID AND CNXX.NAMETYPE = '''+@sOtherNameType+''' 
																					) ' + CHAR(10) 
			end
		end
				
		if @nOwnerKeysOperator between 0 and 1 
		Begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND CNXX.NAMENO ' +  dbo.fn_ConstructOperator(@nOtherNameTypeKeysOperator,@Numeric,@sOtherNameTypeKeys, null,0) + CHAR(10)			
		end
		else
		begin
			set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND dbo.fn_FormatNameUsingNameNo(CNXX.NAMENO, null) ' +  dbo.fn_ConstructOperator(@nOtherNameTypeKeysOperator,@String,@sOtherNameTypeKeys, null,0) + CHAR(10)			
		end
	end
	
	if @sSignatoryKeys is not null 
		or @nSignatoryKeysOperator in (5,6)
	begin
		if CHARINDEX('LEFT JOIN CASENAME CNS ', @psCTE_CaseDetailsFrom) = 0
		begin
				Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CASENAME CNS WITH (NOLOCK)  ON (CNS.CASEID = C.CASEID AND CNS.NAMETYPE = ''SIG'') ' + CHAR(10) 
		end
		set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND CNS.NAMENO ' +  dbo.fn_ConstructOperator(@nSignatoryKeysOperator,@Numeric,@sSignatoryKeys, null,0) + CHAR(10)
				
		if (CHARINDEX('CNS.NAMENO', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', CNS.NAMENO as SignatoryKey '
		end

		set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.SignatoryKey ' +  dbo.fn_ConstructOperator(@nSignatoryKeysOperator,@Numeric,@sSignatoryKeys, null,0) + CHAR(10)			
		set	@psRemindersWhere = @psRemindersWhere +' and C.SignatoryKey ' +  dbo.fn_ConstructOperator(@nSignatoryKeysOperator,@Numeric,@sSignatoryKeys, null,0) + CHAR(10)		
	end

	if @sStaffMemberKeys is not null 
		or @nStaffMemberKeysOperator in (5,6)
	begin

		if CHARINDEX('LEFT JOIN CASENAME CNSM', @psCTE_CaseDetailsFrom) = 0
		begin
			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CASENAME CNSM  WITH (NOLOCK)  ON (CNSM.CASEID = C.CASEID AND CNSM.NAMETYPE = ''EMP''	) ' + CHAR(10) 
		end

		set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND CNSM.NAMENO ' +  dbo.fn_ConstructOperator(@nStaffMemberKeysOperator,@Numeric,@sStaffMemberKeys, null,0) + CHAR(10)
				
		if (CHARINDEX('CNSM.NAMENO', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', CNSM.NAMENO as StaffMemberKey '
		end
		set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.StaffMemberKey ' +  dbo.fn_ConstructOperator(@nStaffMemberKeysOperator,@Numeric,@sStaffMemberKeys, null,0) + CHAR(10)		
		set	@psRemindersWhere = @psRemindersWhere +' and C.StaffMemberKey ' +  dbo.fn_ConstructOperator(@nStaffMemberKeysOperator,@Numeric,@sStaffMemberKeys, null,0) + CHAR(10)
	end
			
	if @sCountryKeys is not null 
		or @nCountryKeysOperator in (5,6)
	begin
		set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + ' AND C.COUNTRYCODE ' +  dbo.fn_ConstructOperator(@nCountryKeysOperator,@CommaString,@sCountryKeys, null,0) + CHAR(10)
				
		if (CHARINDEX('COUNTRYCODE ', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', C.COUNTRYCODE as CountryKey '
		end
		set	@psAdHocDatesWhere = @psAdHocDatesWhere +' and C.CountryKey ' +  dbo.fn_ConstructOperator(@nCountryKeysOperator,@CommaString,@sCountryKeys, null,0) + CHAR(10)	
		set	@psRemindersWhere = @psRemindersWhere +' and C.CountryKey ' +  dbo.fn_ConstructOperator(@nCountryKeysOperator,@CommaString,@sCountryKeys, null,0) + CHAR(10)	
	end

	If @sCategoryKey is not NULL
		or @nCategoryKeyOperator between 2 and 6
		Begin
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere +char(10)+"	and	C.CASECATEGORY"+dbo.fn_ConstructOperator(@nCategoryKeyOperator,@CommaString,@sCategoryKey, null,@pbCalledFromCentura)
		End

	If @sSubTypeKey is not NULL
		or @nSubTypeKeyOperator between 2 and 6
	Begin
		Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	C.SUBTYPE"+dbo.fn_ConstructOperator(@nSubTypeKeyOperator,@CommaString,@sSubTypeKey, null,@pbCalledFromCentura)
	End

	If @sShortTitleText is not NULL
		or @nShortTitleOperator between 0 and 1
	Begin
		if (CHARINDEX('C.TITLE ', @psCTE_CaseDetailsSelect)) = 0
		begin
			set @psCTE_CaseDetailsSelect = @psCTE_CaseDetailsSelect + ', C.Title as ShortTitle '
		end

		Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	C.Title"+dbo.fn_ConstructOperator(@nShortTitleOperator,@CommaString,@sShortTitleText, null,@pbCalledFromCentura)
	End

	If @sBasisKey is not NULL
	or @nBasisKeyOperator between 2 and 6
	Begin
		If @nBasisKeyOperator=6
			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	left join PROPERTY XPB WITH (NOLOCK) on (XPB.CASEID=C.CASEID)"
		Else
			Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom+char(10)+"	join PROPERTY XPB WITH (NOLOCK) on (XPB.CASEID=C.CASEID)"

		Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XPB.BASIS"+dbo.fn_ConstructOperator(@nBasisKeyOperator,@CommaString,@sBasisKey, null,@pbCalledFromCentura)

	End

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
					Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join PROPERTY XP WITH (NOLOCK) on (XP.CASEID      = C.CASEID)"
							 +char(10)+"	left join STATUS XRS WITH (NOLOCK) on (XRS.STATUSCODE = XP.RENEWALSTATUS)"

					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XRS.STATUSCODE"+dbo.fn_ConstructOperator(@nStatusKeyOperator,@CommaString,@sStatusKey, null,@pbCalledFromCentura)

					Set @nErrorCode = @@Error
				End
				Else
				Begin
					Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join STATUS XST WITH (NOLOCK) on (XST.STATUSCODE = C.STATUSCODE)"

					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XST.STATUSCODE"+dbo.fn_ConstructOperator(@nStatusKeyOperator,@CommaString,@sStatusKey, null,@pbCalledFromCentura)
				End
			End

			If @sRenewalStatusKeys is not NULL
			or @nRenewalStatusKeyOperator between 2 and 6
			Begin
				If @psCTE_CaseDetailsFrom NOT LIKE '%PROPERTY XP%'
					Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join PROPERTY XP WITH (NOLOCK) on (XP.CASEID      = C.CASEID)"

				If @psCTE_CaseDetailsFrom like '%PROPERTY XPB%'
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XPB.RENEWALSTATUS"+dbo.fn_ConstructOperator(@nRenewalStatusKeyOperator,@Numeric,@sRenewalStatusKeys, null,@pbCalledFromCentura)
				Else
				If @psCTE_CaseDetailsFrom like '%PROPERTY XPD%'
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XPD.RENEWALSTATUS"+dbo.fn_ConstructOperator(@nRenewalStatusKeyOperator,@Numeric,@sRenewalStatusKeys, null,@pbCalledFromCentura)
				Else
					Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XP.RENEWALSTATUS"+dbo.fn_ConstructOperator(@nRenewalStatusKeyOperator,@Numeric,@sRenewalStatusKeys, null,@pbCalledFromCentura)
			End
		End

		If @bIsDead      =1
		or @bIsRegistered =1
		or @bIsPending    =1
		Begin
			If @psCTE_CaseDetailsFrom NOT LIKE '%PROPERTY XP%'
				Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join PROPERTY XP WITH (NOLOCK) on (XP.CASEID      = C.CASEID)"

			If @psCTE_CaseDetailsFrom NOT LIKE '%STATUS XRS%'
			Begin				
				If @psCTE_CaseDetailsFrom like '%PROPERTY XPB%'
					Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join STATUS XRS WITH (NOLOCK)  on (XRS.STATUSCODE = XPB.RENEWALSTATUS)"
				Else
				If @psCTE_CaseDetailsFrom like '%PROPERTY XPD%'
					Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join STATUS XRS WITH (NOLOCK)  on (XRS.STATUSCODE = XPD.RENEWALSTATUS)"
				Else
					Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join STATUS XRS WITH (NOLOCK)  on (XRS.STATUSCODE = XP.RENEWALSTATUS)"
			End

			If @psCTE_CaseDetailsFrom NOT LIKE '%STATUS XST%'
				Set @psCTE_CaseDetailsFrom=@psCTE_CaseDetailsFrom+char(10)+"	left join STATUS XST WITH (NOLOCK) on (XST.STATUSCODE = C.STATUSCODE)"
		End
		
		-- Dead cases only
		If   @bIsDead      =1
		and (@bIsRegistered=0 or @bIsRegistered is null)
		and (@bIsPending   =0 or @bIsPending    is null)
		Begin
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and    (XST.LIVEFLAG=0 OR XRS.LIVEFLAG=0)"
		End

		-- Registered cases only
		Else
		If  (@bIsDead      =0 or @bIsDead       is null)
		and (@bIsRegistered=1)
		and (@bIsPending   =0 or @bIsPending    is null)
		Begin
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and	XST.LIVEFLAG=1"
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
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=0) OR XST.STATUSCODE is null)"
				    	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
		End

		-- Pending cases or Registed cases only (not dead)
		Else
		If  (@bIsDead      =0 or @bIsDead       is null)
		and (@bIsRegistered=1)
		and (@bIsPending   =1)
		Begin
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and    (XST.LIVEFLAG=1 or XST.STATUSCODE is null)"
				     	     +char(10)+"	and    (XRS.LIVEFLAG=1 or XRS.STATUSCODE is null)"
		End

		-- Registered cases or Dead cases
		Else
		If  (@bIsDead      =1)
		and (@bIsRegistered=1)
		and (@bIsPending   =0 or @bIsPending is null)
		Begin
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=1) OR XST.LIVEFLAG =0 OR XRS.LIVEFLAG=0)"
		End

		-- Pending cases or Dead cases
		Else
		If  (@bIsDead      =1)
		and (@bIsRegistered=0 or @bIsRegistered is null)
		and (@bIsPending   =1)
		Begin
			Set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere+char(10)+"	and   ((XST.LIVEFLAG=1 and XST.REGISTEREDFLAG=0) OR XST.STATUSCODE is null OR XST.LIVEFLAG =0 OR XRS.LIVEFLAG=0)"

		End
		
	Set @sDateRangeFilter = dbo.fn_ConstructOperator(ISNULL(@nDateRangeOperator, @nPeriodRangeOperator),@Date,convert(nvarchar, @dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),0)
	
	-- Get the Action used for Renewals
	Select @sRenewalAction=S.COLCHARACTER
	from SITECONTROL S
	where CONTROLID='Main Renewal Action'


	if (isnull(@sDateRangeFilter,'') <> '')
	Begin
		if (@bUseDueDate = 1 and @bUseReminderDate = 1)
		Begin
			Set @sReminderExistsWhere  = @sReminderExistsWhere  + 'and (ER.DUEDATE '    + @sDateRangeFilter
										+ 'or ER.REMINDERDATE ' + @sDateRangeFilter + ')'
			Set @sAlertExistsWhere     = @sAlertExistsWhere     + 'and A.DUEDATE '      + @sDateRangeFilter
			set @sCaseEventExitsWhere  = @sCaseEventExitsWhere   + ' and CE.EVENTDUEDATE ' + @sDateRangeFilter	
		End
		Else if (@bUseDueDate = 1)
		Begin
			Set @sReminderExistsWhere  = @sReminderExistsWhere  + 'and ER.DUEDATE ' + @sDateRangeFilter
			Set @sAlertExistsWhere     = @sAlertExistsWhere     + 'and A.DUEDATE '  + @sDateRangeFilter
			set @sCaseEventExitsWhere  = @sCaseEventExitsWhere  + ' and CE.EVENTDUEDATE ' + @sDateRangeFilter
		End
		Else if (@bUseReminderDate = 1)
		Begin
			Set @sReminderExistsWhere  = @sReminderExistsWhere  + 'and ER.REMINDERDATE ' + @sDateRangeFilter
		End
	End

	-- when reminder is selected
	if(@bIsReminders = 1)
	Begin		
		
		If (@nNameKey is not null
			or @sNameKeys is not null
			or @nMemberOfGroupKey is not null
			or @sMemberOfGroupKeys is not null
			or @nNullGroupNameKey is not null)
			and (@bIsReminderRecipient = 1 or @bIsResponsibleStaff = 1 or @sNameTypeKeys is not null)
		Begin	
			
			set @psRemindersFrom =  @psRemindersFrom +  @sFunctionSecurity + char(10)
			Set @psRemindersWhere = @psRemindersWhere+char(10)+'and ( '
				
			if @bIsReminderRecipient = 1
			begin
				if(@nNameKey is not null)
				begin
					set @sReminderExistsWhere =  @sReminderExistsWhere + ' and ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
					set @psRemindersWhere =  @psRemindersWhere + ' ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
				end
					
				if(@sNameKeys is not null)
				begin
					set @sReminderExistsWhere =  @sReminderExistsWhere + ' and ER.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' 
					set @psRemindersWhere =  @psRemindersWhere + ' ER.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
				end
					
				if @nMemberOfGroupKey is not null
				   or @sMemberOfGroupKeys is not null
				begin	
					set @psRemindersFrom = @psRemindersFrom +	'LEFT JOIN NAME NEMP WITH (NOLOCK) on (NEMP.NAMENO = ER.EMPLOYEENO) ' + char(10)
					if @nMemberOfGroupKey is not null
					begin					
					    set @sReminderRecipientFamilyWhere = @sReminderRecipientFamilyWhere + ' and RN.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
						set @psRemindersWhere =  @psRemindersWhere + ' NEMP.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
					end
					else
					begin				
						set @sReminderRecipientFamilyWhere = @sReminderRecipientFamilyWhere + ' and RN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' 
						set @psRemindersWhere =  @psRemindersWhere + ' NEMP.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10) 
					end							
				end				
					  					
				if @nNullGroupNameKey is not null 
				and (@nMemberOfGroupKey is null and @sMemberOfGroupKeys is null)
				Begin
					set @sReminderExistsWhere =  @sReminderExistsWhere + ' and ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)
					set @psRemindersWhere =  @psRemindersWhere + ' ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)
				End

			end
			
			if @bIsResponsibleStaff = 1 
			begin
				if @bIsReminderRecipient = 1 
					and (@nNameKey is not null or @nMemberOfGroupKey is not null or @sNameKeys is not null or @sMemberOfGroupKeys is not null)
					begin
						set @psRemindersWhere =  @psRemindersWhere + ' or ' 					
					end
					
				if(@nNameKey is not null)
				begin				
					set @psRemindersWhere =  @psRemindersWhere + ' CE.EMPLOYEENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
				end
							
				if(@sNameKeys is not null)
				begin				
					set @psRemindersWhere =  @psRemindersWhere + ' CE.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
				end
				
				if @nMemberOfGroupKey is not null
					or @sMemberOfGroupKeys is not null
				begin									
				set @psRemindersFrom = @psRemindersFrom +	'LEFT JOIN NAME N WITH (NOLOCK) on (N.NAMENO = CE.EMPLOYEENO) ' + char(10)
					
					if @nMemberOfGroupKey is not null
					begin				
							set @psRemindersWhere =  @psRemindersWhere + ' N.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
					end
					else
					begin				
						  set @psRemindersWhere =  @psRemindersWhere + ' N.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10)  
					end
				end		
			end
									   
			if @sNameTypeKeys is not null 
			begin
				
				if CHARINDEX('LEFT JOIN CASENAME CN ON (CN.CASEID = C.CASEID)', @psRemindersFrom) = 0
				begin					
					Set @psRemindersFrom = @psRemindersFrom + '  LEFT JOIN CASENAME CN ON (CN.CASEID = C.CASEID) ' + CHAR(10) 
				end

				if(@bIsResponsibleStaff = 1 or @bIsReminderRecipient = 1)
				begin				
					set @psRemindersWhere =  @psRemindersWhere + ' or '
				end

				set @sReminderCaseNameWhere =  @sReminderCaseNameWhere + ' and RCN.NAMETYPE in (' +@sNameTypeKeys+ ')'
				set @psRemindersWhere =  @psRemindersWhere + ' ( CN.NAMETYPE in (' +@sNameTypeKeys+ ')'
					
				if(@nNameKey is not null)
				begin
					set @sReminderCaseNameWhere =  @sReminderCaseNameWhere + ' AND RCN.NAMENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
					set @psRemindersWhere =  @psRemindersWhere + 'AND CN.NAMENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
				end
							
				if(@sNameKeys is not null)
				begin
					set @sReminderCaseNameWhere =  @sReminderCaseNameWhere + ' AND RCN.NAMENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
					set @psRemindersWhere =  @psRemindersWhere + ' AND CN.NAMENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
				end	
				
				if @nMemberOfGroupKey is not null
                    or @sMemberOfGroupKeys is not null
                begin  
                        set @psRemindersFrom = @psRemindersFrom +       'LEFT JOIN NAME ERNTYPE WITH (NOLOCK) on (ERNTYPE.NAMENO = CN.NAMENO) ' + char(10)
						set @sReminderCaseName = @sReminderCaseName +       'LEFT JOIN NAME RCNTYPE WITH (NOLOCK) on (RCNTYPE.NAMENO = RCN.NAMENO) ' + char(10)

                        if @nMemberOfGroupKey is not null
                        begin                            
							set @sReminderCaseNameWhere =  @sReminderCaseNameWhere + ' AND RCNTYPE.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)  + char(10)
                            set @psRemindersWhere =  @psRemindersWhere + ' AND ERNTYPE.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
                        end
                        else
                        begin                      
							set @sReminderCaseNameWhere =  @sReminderCaseNameWhere + ' AND RCNTYPE.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10) 
                            set @psRemindersWhere =  @psRemindersWhere + ' AND ERNTYPE.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10) 
                        end                                            
                end    

				if(@nNullGroupNameKey is not null)
				begin
					set @sReminderCaseNameWhere =  @sReminderCaseNameWhere + ' AND RCN.NAMENO in ('+dbo.fn_WrapQuotes(@nNullGroupNameKey,1,0)+')' + char(10)
					set @psRemindersWhere =  @psRemindersWhere + ' AND CN.NAMENO in ('+dbo.fn_WrapQuotes(@nNullGroupNameKey,1,0)+')' + char(10)
				end	
				
				set @psRemindersWhere = @psRemindersWhere + ')'
					
			end		
			Set @psRemindersWhere = @psRemindersWhere+char(10)+') '
		End
		
			
		If (@bUseDueDate = 1 or @bUseReminderDate = 1) and 
			(@dtDateRangeFrom is not null
			or @dtDateRangeTo is not null)
		Begin

			Set @psRemindersWhere = @psRemindersWhere+char(10)+'and ( '

				if @bUseDueDate = 1
				begin
					set	@psRemindersWhere = @psRemindersWhere +" ER.DUEDATE "+@sDateRangeFilter	
					set	@psRemindersWhere = @psRemindersWhere +" or A.DUEDATE "+@sDateRangeFilter	
				end
					 
				if @bUseReminderDate = 1
				begin
						if @bUseDueDate = 1
						begin
							set	@psRemindersWhere = @psRemindersWhere +" or "
						end
					set	@psRemindersWhere = @psRemindersWhere +" ER.REMINDERDATE "+@sDateRangeFilter	
				end

				Set @psRemindersWhere = @psRemindersWhere+char(10)+') '
		End				
				
		if (@sEventKeys is not null 
		or @nEventKeysOperator in (5,6))
		begin 			

			if CHARINDEX('join EVENTCONTROL EC', @psRemindersFrom) = 0
			begin
			Set @psRemindersFrom = @psRemindersFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			set @psRemindersWhere =  @psRemindersWhere +  " and ( EC.EVENTNO " + dbo.fn_ConstructOperator(@nEventKeysOperator,@CommaString,@sEventKeys, null,0) +  
																" or E.EVENTNO " + dbo.fn_ConstructOperator(@nEventKeysOperator,@CommaString,@sEventKeys, null,0)  +
															+ CHAR(10)	
																
			set @psRemindersWhere =  @psRemindersWhere +  " or A.EVENTNO " + dbo.fn_ConstructOperator(@nEventKeysOperator,@CommaString,@sEventKeys, null,0) + ')  ' + CHAR(10)	
		end
			   	
		if (@sEventGroupKeys is not null or @nEventGroupKeysOperator in (5,6)) 
		or (@sEventCategoryKeys is not null or @nEventCategoryKeysOperator in (5,6))
		begin 
		
			if CHARINDEX('join EVENTCONTROL EC', @psRemindersFrom) = 0
			begin
			Set @psRemindersFrom = @psRemindersFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			
			if (@sEventGroupKeys is not null or @nEventGroupKeysOperator in (5,6)) 
			begin
				set @psRemindersWhere =  @psRemindersWhere +  ' and ( E.EVENTGROUP ' + dbo.fn_ConstructOperator(@nEventGroupKeysOperator,@CommaString,@sEventGroupKeys, null,0) +  ')'  
			end
			
			If @sEventCategoryKeys is not null or @nEventCategoryKeysOperator in (5,6)
			Begin			
				Set @psRemindersWhere = @psRemindersWhere+char(10)+" and E.CATEGORYID "+dbo.fn_ConstructOperator(@nEventCategoryKeysOperator,@Numeric,@sEventCategoryKeys, null,0)			
			End	
		end

		if @sReminderForNameKeys is not null 
			and @nReminderForNameKeysOperator is not null
		Begin
			if CHARINDEX('left join NAME ERN', @psRemindersFrom) = 0
			begin
				set @psRemindersFrom = @psRemindersFrom  + ' left join NAME ERN WITH (NOLOCK)	on (ERN.NAMENO=ER.EMPLOYEENO) ' + char(10)
			end

			set @psRemindersWhere = @psRemindersWhere + ' and  ERN.NAMENO ' + dbo.fn_ConstructOperator(@nReminderForNameKeysOperator,@Numeric,@sReminderForNameKeys, null,0) 
		End		

		If @nImportanceLevelOperator is not null
		and (@sImportanceLevelFrom is not null
		 or  @sImportanceLevelTo is not null)
		Begin
			
			if CHARINDEX('join EVENTCONTROL EC', @psRemindersFrom) = 0
			begin
			Set @psRemindersFrom = @psRemindersFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			Set @psRemindersWhere = @psRemindersWhere +char(10)+"	and coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0) "+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0)	
		End
				
		if @sImportanceLevelKeys is not null and @nImportanceLevelKeysOperator is not null
		begin
			if CHARINDEX('join EVENTCONTROL EC', @psRemindersFrom) = 0
			begin
			Set @psRemindersFrom = @psRemindersFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			Set @psRemindersWhere = @psRemindersWhere +char(10)+"	and (coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0) "+ dbo.fn_ConstructOperator(@nImportanceLevelKeysOperator,@CommaString,@sImportanceLevelKeys, NULL,@pbCalledFromCentura)	
			Set @psRemindersWhere = @psRemindersWhere +char(10)+" or A.IMPORTANCELEVEL " + dbo.fn_ConstructOperator(@nImportanceLevelKeysOperator,@CommaString,@sImportanceLevelKeys, NULL,@pbCalledFromCentura)	+ ') ' + CHAR(10)

		end

		If @nEventNoteTypeKeysOperator is not null
		or @nEventNoteTextOperator     is not null
		Begin		
			
			if CHARINDEX(' CASEEVENTTEXT ', @psRemindersFrom) = 0
			begin
				Set @psRemindersFrom= @psRemindersFrom
					   +char(10)+"left join CASEEVENTTEXT CET WITH (NOLOCK) on (CET.CASEID =CE.CASEID"
					   +char(10)+"                                           and CET.EVENTNO=CE.EVENTNO"
					   +char(10)+"                                           and CET.CYCLE  =CE.CYCLE)"
					   +char(10)+"left join EVENTTEXT ET WITH (NOLOCK)      on (ET.EVENTTEXTID=CET.EVENTTEXTID)"
			end

			If @nEventNoteTypeKeysOperator is not null
			begin
				Set @psRemindersWhere =  @psRemindersWhere+char(10)+"	and ET.EVENTTEXTTYPEID"+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)
			end

			If @nEventNoteTextOperator is not null
			begin
				Set @psRemindersWhere =  @psRemindersWhere +char(10)+"	and ET.EVENTTEXT"+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
			end
		End	
		
		If @bIsRenewalsOnly = 1
		or @bIsNonRenewalsOnly = 1
		or @bIncludeClosed = 0	
		or @sActionKeys is not null
		or @nActionKeysOperator between 2 and 6
		Begin
					
			Set @psRemindersWhere=@psRemindersWhere+char(10)+ " and (CE.EVENTDUEDATE is null " + char(10) +
														      " or (CE.EVENTDUEDATE is not null "
			Set @psRemindersWhere=@psRemindersWhere+char(10)+"and exists"
			
			Set @psRemindersWhere = @psRemindersWhere
			+char(10)+"    (select 1"
			+char(10)+"	from OPENACTION OA"
			+char(10)+"	join EVENTS OE		on (OE.EVENTNO  = CE.EVENTNO"
			
			If @sActionKeys is null
			or @nActionKeysOperator>0
				Set @psRemindersWhere = @psRemindersWhere
				+char(10)+"				and OA.ACTION   = isnull(OE.CONTROLLINGACTION,OA.ACTION)"
				
			Set @psRemindersWhere = @psRemindersWhere +")"
			+char(10)+"	join EVENTCONTROL OEC	on (OEC.EVENTNO = CE.EVENTNO"
			+char(10)+"				and OEC.CRITERIANO = OA.CRITERIANO)"
			+char(10)+"	join EVENTS E  on (E.EVENTNO=CE.EVENTNO)"
			+char(10)+"	join ACTIONS A		on (A.ACTION = OA.ACTION)"		
			+char(10)+"	where OA.CASEID = CE.CASEID"
			
			If @sActionKeys is null
			or @nActionKeysOperator>0
				Set @psRemindersWhere = @psRemindersWhere
				+char(10)+"	and OA.ACTION=isnull(E.CONTROLLINGACTION, OA.ACTION)"
			
			If @sActionKeys is not null or @nActionKeysOperator between 2 and 6
			Begin
				Set @psRemindersWhere = @psRemindersWhere +char(10)+"	and OA.ACTION"+dbo.fn_ConstructOperator(@nActionKeysOperator,@CommaString,@sActionKeys, null,@pbCalledFromCentura) 
			End
			
			
			If @bIncludeClosed <> 1			
			Begin
				Set @psRemindersWhere = @psRemindersWhere
				+char(10)+"		and	OA.POLICEEVENTS = 1"	
				+char(10)+"		and   ((A.NUMCYCLESALLOWED > 1 and OA.CYCLE = CE.CYCLE)"
		 		+char(10)+"		or      A.NUMCYCLESALLOWED = 1)"	
				
			End		
	
			If @sRenewalAction is not NULL
				and isnull(@bIsNonRenewalsOnly,0)=0
			Begin
				Set @psRemindersWhere = @psRemindersWhere
				+char(10)+"		and   ((OA.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR CE.EVENTNO<>-11)"
			End
			
			If @bIsNonRenewalsOnly <> @bIsRenewalsOnly
			Begin
				If @bIsNonRenewalsOnly = 1
				Begin
					Set @psRemindersWhere = @psRemindersWhere
					+char(10)+"				and	A.ACTIONTYPEFLAG <> 1"
				End
				Else
				If @bIsRenewalsOnly = 1
				Begin
					Set @psRemindersWhere = @psRemindersWhere
					+char(10)+"				and	A.ACTIONTYPEFLAG = 1"
				End
			End
			
			Set @psRemindersWhere = @psRemindersWhere+char(10)+")))"
				
			End
		
		If @sReminderMessage is not null
		or @nReminderMessageOperator between 2 and 6
		Begin
			Set @psRemindersWhere = @psRemindersWhere+char(10)+" and isnull(cast(ER.LONGMESSAGE as nvarchar(4000)), ER.SHORTMESSAGE) "+dbo.fn_ConstructOperator(@nReminderMessageOperator,@String,@sReminderMessage, null,0)			
		End		
				
		-- Reminders that are on hold are those with a non-null HoldUntilDate.
		If @bIsReminderOnHold = 1
		Begin
			Set @psRemindersWhere = @psRemindersWhere+char(10)+" and ER.HOLDUNTILDATE is not null" 	
		End
		Else If @bIsReminderOnHold = 0
		Begin
			Set @psRemindersWhere = @psRemindersWhere+char(10)+" and ER.HOLDUNTILDATE is null" 	
		End		

		If @bIsReminderRead is not null
		Begin
			Set @psRemindersWhere = @psRemindersWhere+char(10)+" and CAST(ER.READFLAG as bit) = " + CAST(@bIsReminderRead as char(1)) 	
		End	
		
		if @sDueDateResponsibilityNameKeys is not null and @nDueDateResponsibilityNameKeysOperator is not null
		begin
			if CHARINDEX('left join NAME RSTAFF', @psRemindersFrom) = 0
			begin
				set @psRemindersFrom = @psRemindersFrom  + ' left join NAME RSTAFF WITH (NOLOCK) on (RSTAFF.NAMENO = CE.EMPLOYEENO) ' + char(10)
			end			
			Set @psRemindersWhere = @psRemindersWhere+char(10)+" and RSTAFF.NAMENO " + dbo.fn_ConstructOperator(@nDueDateResponsibilityNameKeysOperator,@CommaString,@sDueDateResponsibilityNameKeys, NULL,@pbCalledFromCentura)
		end

		If @sShortTitleText is not NULL
		or @nShortTitleOperator between 0 and 1
		Begin
			Set @psRemindersWhere = @psRemindersWhere+char(10)+"	and	C.ShortTitle "+dbo.fn_ConstructOperator(@nShortTitleOperator,@CommaString,@sShortTitleText, null,@pbCalledFromCentura)
		End

	End
				
	-- when Due Date is selected
	if(@bIsDueDates = 1)
	Begin

		If  (@nNameKey is not null
			or @sNameKeys is not null
			or @nMemberOfGroupKey is not null
			or @sMemberOfGroupKeys is not null
			or @nNullGroupNameKey is not null)
			and (@bIsReminderRecipient = 1 or @bIsResponsibleStaff = 1 or @sNameTypeKeys is not null)
		Begin	
			--  Set @psDueDatesFrom =  @psDueDatesFrom +  @sFunctionSecurity + char(10)
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+'and ( '
			--set @sCaseEventExitsWhere =  @sCaseEventExitsWhere + ' and ('	

			if @bIsReminderRecipient = 1
			begin
				if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
				begin
					Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
				end
				
				if(@nNameKey is not null )
				begin					
					set @psDueDatesWhere =  @psDueDatesWhere + ' ER.EMPLOYEENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
				end

				if(@sNameKeys is not null)
				begin					   
						set @psDueDatesWhere =  @psDueDatesWhere + ' ER.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
				end
					
				if @nMemberOfGroupKey is not null
				 or @sMemberOfGroupKeys is not null
				begin						
				set @psDueDatesFrom = @psDueDatesFrom +	'LEFT JOIN NAME NEMP WITH (NOLOCK) on (NEMP.NAMENO = ER.EMPLOYEENO) ' + char(10)				

					if @nMemberOfGroupKey is not null
					begin						 
						set @psDueDatesWhere =  @psDueDatesWhere + ' NEMP.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)						
					end
					else
					begin						
						set @psDueDatesWhere =  @psDueDatesWhere + ' NEMP.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10) 
					end
				end

				if @nNullGroupNameKey is not null 
				and (@nMemberOfGroupKey is null and @sMemberOfGroupKeys is null)
				Begin				
				--	set @sCaseEventExitsWhere =  @sCaseEventExitsWhere + ' ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)
					set @psDueDatesWhere =  @psDueDatesWhere + ' ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)					
				End

			end

			if @bIsResponsibleStaff = 1 
			begin					
				if @bIsReminderRecipient = 1 
					and (@nNameKey is not null 
						or @nMemberOfGroupKey is not null 
						or @sNameKeys is not null 
						or @sMemberOfGroupKeys is not null)
				begin
					set @psDueDatesWhere =  @psDueDatesWhere + ' or ' 					
				end
					
				if @nNameKey is not null 
				begin
					set @sCaseEventExitsWhere =  @sCaseEventExitsWhere + ' and CE.EMPLOYEENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
					set @psDueDatesWhere =  @psDueDatesWhere + '  CE.EMPLOYEENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
				end
							
				if(@sNameKeys is not null)
				begin
					set @sCaseEventExitsWhere =  @sCaseEventExitsWhere + ' and CE.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' 
					set @psDueDatesWhere =  @psDueDatesWhere + ' CE.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
				end

				if @nMemberOfGroupKey is not null
				or @sMemberOfGroupKeys is not null
				begin						
					set @psDueDatesFrom = @psDueDatesFrom +	'LEFT JOIN NAME N WITH (NOLOCK) on (N.NAMENO = CE.EMPLOYEENO) ' + char(10)					

					if @nMemberOfGroupKey is not null
					begin
						set @sCE_ResponsibleStaffFamilyWhere   =  @sCE_ResponsibleStaffFamilyWhere   + ' and CEN .FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
						set @psDueDatesWhere =  @psDueDatesWhere + ' N.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
					end
					else
					begin
						set @sCE_ResponsibleStaffFamilyWhere =  @sCE_ResponsibleStaffFamilyWhere + ' and CEN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' 
						set @psDueDatesWhere =  @psDueDatesWhere + ' N.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10)  
					end
				end
			end

			if @sNameTypeKeys is not null 
			begin				
				if CHARINDEX('LEFT JOIN CASENAME CN ON (CN.CASEID = C.CASEID)', @psDueDatesFrom) = 0
				begin					
					Set @psDueDatesFrom = @psDueDatesFrom + '  LEFT JOIN CASENAME CN ON (CN.CASEID = C.CASEID) ' + CHAR(10) 
				end

				if(@bIsResponsibleStaff = 1 or @bIsReminderRecipient = 1)
				begin
					set @psDueDatesWhere =  @psDueDatesWhere + ' or '				
				end
											    
				set @psDueDatesWhere =  @psDueDatesWhere + ' (CN.NAMETYPE in (' +@sNameTypeKeys+ ')'				
				set @sCE_ResponsibleStaffWhere  =  @sCE_ResponsibleStaffWhere  + '  AND CECN.NAMETYPE in (' +@sNameTypeKeys+ ') '
				if(@nNameKey is not null)
				begin
					set @sCE_ResponsibleStaffWhere =  @sCE_ResponsibleStaffWhere + ' AND CECN.NAMENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
					set @psDueDatesWhere =  @psDueDatesWhere + 'AND CN.NAMENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
				end
							
				if(@sNameKeys is not null)
				begin
					set @sCE_ResponsibleStaffWhere =  @sCE_ResponsibleStaffWhere + ' AND CECN.NAMENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' 
					set @psDueDatesWhere =  @psDueDatesWhere + ' AND CN.NAMENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
				end			

				if @nMemberOfGroupKey is not null
				or @sMemberOfGroupKeys is not null
				begin						
					set @psDueDatesFrom = @psDueDatesFrom +	'LEFT JOIN NAME DN WITH (NOLOCK) on (DN.NAMENO = CN.NAMENO) ' + char(10)		
					set @sCE_ResponsibleStaff = @sCE_ResponsibleStaff +	'LEFT JOIN NAME CEEN WITH (NOLOCK) on (CEEN.NAMENO = CECN.NAMENO) ' + char(10)					

					if @nMemberOfGroupKey is not null
					begin
						set @sCE_ResponsibleStaffWhere   =  @sCE_ResponsibleStaffWhere   + ' and CEEN .FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
						set @psDueDatesWhere =  @psDueDatesWhere + ' AND DN.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
					end
					else
					begin
						set @sCE_ResponsibleStaffWhere =  @sCE_ResponsibleStaffWhere + ' and CEEN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' 
						set @psDueDatesWhere =  @psDueDatesWhere + ' AND DN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10)  
					end
				end

				if(@nNullGroupNameKey is not null)
				begin
					set @sCE_ResponsibleStaffWhere =  @sCE_ResponsibleStaffWhere + ' AND CECN.NAMENO in ('+dbo.fn_WrapQuotes(@nNullGroupNameKey,1,0)+')' 
					set @psDueDatesWhere =  @psDueDatesWhere + ' AND CN.NAMENO in ('+dbo.fn_WrapQuotes(@nNullGroupNameKey,1,0)+')' + char(10)
				end		
				
				set @psDueDatesWhere = @psDueDatesWhere + ')'
					
			end			
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+') '
		End
		
		If ( @bUseDueDate = 1  or @bUseReminderDate = 1) and 
			(@dtDateRangeFrom is not null
			or @dtDateRangeTo is not null)				
		Begin
				Set @psDueDatesWhere = @psDueDatesWhere+char(10)+'and ( '

				if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
					begin
						Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
					end


				if @bUseDueDate = 1
				begin				
					
					set	@psDueDatesWhere = @psDueDatesWhere +" CE.EVENTDUEDATE "+@sDateRangeFilter	
					set	@psDueDatesWhere = @psDueDatesWhere +" or ER.DUEDATE "+@sDateRangeFilter
				end					 
				
				if @bUseReminderDate = 1
				begin					
					if @bUseDueDate = 1
					begin
						set	@psDueDatesWhere = @psDueDatesWhere +" or "
					end
					set	@psDueDatesWhere = @psDueDatesWhere +" ER.REMINDERDATE "+@sDateRangeFilter	
				end

				Set @psDueDatesWhere = @psDueDatesWhere+char(10)+') '
		End

		if(@sEventKeys is not null 
		or @nEventKeysOperator in (5,6))
		begin 

			if CHARINDEX('join CASEEVENT CE', @psDueDatesFrom) = 0
			begin
			set @psDueDatesFrom = @psDueDatesFrom + ' join CASEEVENT CE  WITH (NOLOCK) ON (CE.CASEID = ER.CASEID
														and CE.EVENTNO = ER.EVENTNO
														and CE.CYCLE = ER.CYCLENO)'
			end

			if CHARINDEX('join EVENTCONTROL EC', @psDueDatesFrom) = 0
			begin
			Set @psDueDatesFrom = @psDueDatesFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			set @psDueDatesWhere =  @psDueDatesWhere +  " and ( EC.EVENTNO " + dbo.fn_ConstructOperator(@nEventKeysOperator,@CommaString,@sEventKeys, null,0) +  
																" or E.EVENTNO " + dbo.fn_ConstructOperator(@nEventKeysOperator,@CommaString,@sEventKeys, null,0)  +
															') '+ CHAR(10)							
		end
		
		if (@sEventGroupKeys is not null or @nEventGroupKeysOperator in (5,6))
		or (@sEventCategoryKeys is not null or @nEventCategoryKeysOperator in (5,6))
		begin 

			if CHARINDEX('left join EVENTS E', @psDueDatesFrom) = 0
			begin
			Set @psDueDatesFrom = @psDueDatesFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
														left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																							on (OX.CASEID = CE.CASEID
																			and OX.ACTION = E.CONTROLLINGACTION)
														left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																			and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
				   
			end

			if (@sEventGroupKeys is not null or @nEventGroupKeysOperator in (5,6))
			begin
				set @psDueDatesWhere =  @psDueDatesWhere +  ' and ( E.EVENTGROUP ' + dbo.fn_ConstructOperator(@nEventGroupKeysOperator,@CommaString,@sEventGroupKeys, null,0) +  ')'  
			end
			
			If @sEventCategoryKeys is not null	or @nEventCategoryKeysOperator in (5,6)
			Begin					
				Set @psDueDatesWhere = @psDueDatesWhere+char(10)+" and E.CATEGORYID "+dbo.fn_ConstructOperator(@nEventCategoryKeysOperator,@Numeric,@sEventCategoryKeys, null,0)
			End	
		end
		
		if @sReminderForNameKeys is not null 
			and @nReminderForNameKeysOperator is not null
		Begin
			if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
			begin
				Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER  WITH (NOLOCK) ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
			end

			set @psDueDatesWhere = @psDueDatesWhere + ' and  ER.NAMENO ' + dbo.fn_ConstructOperator(@nReminderForNameKeysOperator,@Numeric,@sReminderForNameKeys, null,0) 
		End
			
		If   @nImportanceLevelOperator is not null
		and (@sImportanceLevelFrom is not null
		 or  @sImportanceLevelTo is not null)
		Begin
			
			if CHARINDEX('join EVENTCONTROL EC', @psDueDatesFrom) = 0
			begin
			Set @psDueDatesFrom = @psDueDatesFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			Set @psDueDatesWhere = @psDueDatesWhere +char(10)+"	and coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0) "+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0)	
		End

		if @sImportanceLevelKeys is not null and @nImportanceLevelKeysOperator is not null
		begin
			if CHARINDEX('join EVENTCONTROL EC', @psDueDatesFrom) = 0
			begin
			Set @psDueDatesFrom = @psDueDatesFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
													left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																						on (OX.CASEID = CE.CASEID
																		and OX.ACTION = E.CONTROLLINGACTION)
													left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																		and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
			end
			Set @psDueDatesWhere = @psDueDatesWhere +char(10)+"	and coalesce(EC.IMPORTANCELEVEL,E.IMPORTANCELEVEL,0) "+ dbo.fn_ConstructOperator(@nImportanceLevelKeysOperator,@CommaString,@sImportanceLevelKeys, NULL,@pbCalledFromCentura)	
			
		end

		If @nEventNoteTypeKeysOperator is not null
		or @nEventNoteTextOperator     is not null
		Begin		
			if CHARINDEX('join CASEEVENT CE', @psDueDatesFrom) = 0
			begin
			set @psDueDatesFrom = @psDueDatesFrom + ' join CASEEVENT CE  WITH (NOLOCK) ON (CE.CASEID = ER.CASEID
														and CE.EVENTNO = ER.EVENTNO
														and CE.CYCLE = ER.CYCLENO)'
			end

			if CHARINDEX(' CASEEVENTTEXT ', @psDueDatesFrom) = 0
			begin
				Set @psDueDatesFrom= @psDueDatesFrom
					   +char(10)+"left join CASEEVENTTEXT CET WITH (NOLOCK) on (CET.CASEID =CE.CASEID"
					   +char(10)+"                                           and CET.EVENTNO=CE.EVENTNO"
					   +char(10)+"                                           and CET.CYCLE  =CE.CYCLE)"
					   +char(10)+"left join EVENTTEXT ET WITH (NOLOCK)      on (ET.EVENTTEXTID=CET.EVENTTEXTID)"
			end

			If @nEventNoteTypeKeysOperator is not null
			begin
				Set @psDueDatesWhere =  @psDueDatesWhere+char(10)+"	and ET.EVENTTEXTTYPEID"+dbo.fn_ConstructOperator(@nEventNoteTypeKeysOperator,@CommaString,@sEventNoteTypeKeys, NULL,@pbCalledFromCentura)
			end

			If @nEventNoteTextOperator is not null
			begin
				Set @psDueDatesWhere =  @psDueDatesWhere +char(10)+"	and ET.EVENTTEXT"+dbo.fn_ConstructOperator(@nEventNoteTextOperator,@String,@sEventNoteText, NULL,@pbCalledFromCentura)
			end
		End	
		
		If @bIsRenewalsOnly = 1
		or @bIsNonRenewalsOnly = 1
		or @bIncludeClosed = 0	
		or @sActionKeys is not null
		or @nActionKeysOperator between 2 and 6
		Begin
		
			if CHARINDEX('join CASEEVENT CE', @psDueDatesFrom) = 0
			begin
				set @psDueDatesFrom = @psDueDatesFrom + ' join CASEEVENT CE  WITH (NOLOCK) ON (CE.CASEID = ER.CASEID
															and CE.EVENTNO = ER.EVENTNO
															and CE.CYCLE = ER.CYCLENO)'
			end
		    Set @psDueDatesWhere=@psDueDatesWhere+char(10)+"and exists"
	
			Set @psDueDatesWhere = @psDueDatesWhere
			+char(10)+"    (select 1"
			+char(10)+"	from OPENACTION OA"
			+char(10)+"	join EVENTS OE		on (OE.EVENTNO  = CE.EVENTNO"
			
			If @sActionKeys is null
			or @nActionKeysOperator>0
				Set @psDueDatesWhere = @psDueDatesWhere
				+char(10)+"				and OA.ACTION   = isnull(OE.CONTROLLINGACTION,OA.ACTION)"
				
			Set @psDueDatesWhere = @psDueDatesWhere +")"
			+char(10)+"	join EVENTCONTROL OEC	on (OEC.EVENTNO = CE.EVENTNO"
			+char(10)+"				and OEC.CRITERIANO = OA.CRITERIANO)"
			+char(10)+"	join EVENTS E  on (E.EVENTNO=CE.EVENTNO)"
			+char(10)+"	join ACTIONS A		on (A.ACTION = OA.ACTION)"		
			+char(10)+"	where OA.CASEID = CE.CASEID"
			
			If @sActionKeys is null
			or @nActionKeysOperator>0
				Set @psDueDatesWhere = @psDueDatesWhere
				+char(10)+"	and OA.ACTION=isnull(E.CONTROLLINGACTION, OA.ACTION)"
			
			If @sActionKeys is not null or @nActionKeysOperator between 2 and 6
			Begin
				Set @psDueDatesWhere = @psDueDatesWhere +char(10)+"	and OA.ACTION"+dbo.fn_ConstructOperator(@nActionKeysOperator,@CommaString,@sActionKeys, null,@pbCalledFromCentura) 
			End
			
			
			If @bIncludeClosed <> 1			
			Begin
				Set @psDueDatesWhere = @psDueDatesWhere
				+char(10)+"		and	OA.POLICEEVENTS = 1"	
				+char(10)+"		and   ((A.NUMCYCLESALLOWED > 1 and OA.CYCLE = CE.CYCLE)"
		 		+char(10)+"		or      A.NUMCYCLESALLOWED = 1)"	
				
			End		
				
			If @sRenewalAction is not NULL
				and isnull(@bIsNonRenewalsOnly,0)=0
			Begin
				Set @psDueDatesWhere = @psDueDatesWhere
				+char(10)+"		and   ((OA.ACTION='"+@sRenewalAction+"' and CE.EVENTNO=-11) OR CE.EVENTNO<>-11)"
			End

			If @bIsNonRenewalsOnly <> @bIsRenewalsOnly
			Begin
				If @bIsNonRenewalsOnly = 1
				Begin
					Set @psDueDatesWhere = @psDueDatesWhere
					+char(10)+"				and	A.ACTIONTYPEFLAG <> 1"
				End
				Else
				If @bIsRenewalsOnly = 1
				Begin
					Set @psDueDatesWhere = @psDueDatesWhere
					+char(10)+"				and	A.ACTIONTYPEFLAG = 1"
				End
			End
			
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+")"
		End

		If @sReminderMessage is not null
		or @nReminderMessageOperator between 2 and 6
		Begin
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+" and isnull(cast(ER.LONGMESSAGE as nvarchar(4000)), ER.SHORTMESSAGE) "+dbo.fn_ConstructOperator(@nReminderMessageOperator,@String,@sReminderMessage, null,0)			
		End		
			
		If @bIsReminderOnHold = 1
		Begin
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+" and ER.HOLDUNTILDATE is not null" 	
		End
		Else If @bIsReminderOnHold = 0
		Begin
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+" and ER.HOLDUNTILDATE is null" 	
		End						

		If @bIsReminderRead is not null
		Begin
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+" and CAST(ER.READFLAG as bit) = " + CAST(@bIsReminderRead as char(1)) 	
		End	

		if @sDueDateResponsibilityNameKeys is not null and @nDueDateResponsibilityNameKeysOperator is not null
		begin
			if CHARINDEX('left join NAME RSTAFF', @psDueDatesFrom) = 0
			begin
				set @psDueDatesFrom = @psDueDatesFrom  + ' left join NAME RSTAFF WITH (NOLOCK) on (RSTAFF.NAMENO = CE.EMPLOYEENO) ' + char(10)
			end		
			Set @psDueDatesWhere = @psDueDatesWhere+char(10)+" and RSTAFF.NAMENO " + dbo.fn_ConstructOperator(@nDueDateResponsibilityNameKeysOperator,@CommaString,@sDueDateResponsibilityNameKeys, NULL,@pbCalledFromCentura)
		end

		If @sShortTitleText is not NULL
		or @nShortTitleOperator between 0 and 1
		Begin
			Set @psDueDatesWhere = @psDueDatesWhere + char(10)+"	and	C.ShortTitle "+dbo.fn_ConstructOperator(@nShortTitleOperator,@CommaString,@sShortTitleText, null,@pbCalledFromCentura)
		End

	End		
			
	-- when Adhoc Date is selected
	if(@bIsAdHocDates = 1)
	Begin

		If  (@nNameKey is not null
			or @sNameKeys is not null
			or @nMemberOfGroupKey is not null
			or @sMemberOfGroupKeys is not null
			or @nNullGroupNameKey is not null)
			and (@bIsReminderRecipient = 1 or @sNameTypeKeys is not null)
		Begin					
				Set @psAdHocDatesFrom =  @psAdHocDatesFrom +  char(10)+"
				Join (Select R.EMPLOYEENO 
					FROM (select distinct EMPLOYEENO from EMPLOYEEREMINDER) R
					JOIN USERIDENTITY UI ON (UI.IDENTITYID = "+convert(varchar,@pnUserIdentityId)+")
					JOIN NAME N          ON (UI.NAMENO = N.NAMENO)			
					LEFT JOIN FUNCTIONSECURITY F ON (F.FUNCTIONTYPE=2)						
					WHERE (F.ACCESSPRIVILEGES&1 = 1 or R.EMPLOYEENO = UI.NAMENO)
					AND (F.OWNERNO       = R.EMPLOYEENO or R.EMPLOYEENO = UI.NAMENO OR F.OWNERNO IS NULL)
					AND (F.ACCESSSTAFFNO = UI.NAMENO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSSTAFFNO IS NULL) 
					AND (F.ACCESSGROUP   = N.FAMILYNO or R.EMPLOYEENO = UI.NAMENO OR F.ACCESSGROUP IS NULL)			  
					group by R.EMPLOYEENO) FS on (FS.EMPLOYEENO=AX.EMPLOYEENO)"

				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+'and ( '
				
				if @bIsReminderRecipient = 1
				begin
					if @nNameKey is not null 
					begin
						set @sAlertExistsWhere = @sAlertExistsWhere + ' AND A.EMPLOYEENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AX.EMPLOYEENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
						if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
						Begin
							set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' or ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0) 
						End
					end

					if(@sNameKeys is not null)
					begin
						set @sAlertExistsWhere = @sAlertExistsWhere + ' AND A.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')'
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AX.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
						if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
						Begin
							set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' or ER.EMPLOYEENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' 
						End
					end

					if @nMemberOfGroupKey is not null
						or @sMemberOfGroupKeys is not null
					begin						
						set @psAdHocDatesFrom = @psAdHocDatesFrom +	'LEFT JOIN NAME NEMP WITH (NOLOCK) on (NEMP.NAMENO = AX.EMPLOYEENO) ' + char(10)
						if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
						Begin							
							set @psAdHocDatesFrom = @psAdHocDatesFrom +	'LEFT JOIN NAME NEMPA WITH (NOLOCK) on (NEMPA.NAMENO = ER.EMPLOYEENO) ' + char(10)
						End
						if @nMemberOfGroupKey is not null
							begin
								set @sAlertFamilyWhere  = @sAlertFamilyWhere + ' AND AN.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
								set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' NEMP.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)  
								if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
								Begin									
									set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' or NEMPA.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0) 
								End
							end
						else 
							begin
								if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
								Begin									
									set @psAdHocDatesWhere =  @psAdHocDatesWhere + '(' + char(10) 
								End

								set @sAlertFamilyWhere  = @sAlertFamilyWhere + ' AND AN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10)  
								set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' NEMP.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10)  
								if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
								Begin									
									set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' or NEMPA.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+'))' + char(10) 
								End
							end
					end
					  					  
					if @nNullGroupNameKey is not null 
					and (@nMemberOfGroupKey is null and @sMemberOfGroupKeys is null)
					Begin							
						set @sAlertExistsWhere = @sAlertExistsWhere + ' AND A.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AX.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)
						if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) <> 0
						Begin								
							set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' or ER.EMPLOYEENO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nNullGroupNameKey, null,0)
						End					
					End
				end
					
				if @sNameTypeKeys is not null 
				begin

					if CHARINDEX('LEFT JOIN CASENAME CN  WITH (NOLOCK) ON (CN.CASEID = C.CASEID)', @psAdHocDatesFrom) = 0
					begin					
						Set @psAdHocDatesFrom = @psAdHocDatesFrom + '  LEFT JOIN CASENAME CN  WITH (NOLOCK) ON (CN.CASEID = C.CASEID) ' + CHAR(10) 
					end

					if(@bIsReminderRecipient = 1)
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' or '						 
					    
					set @sAlertCaseNameWhere  = @sAlertCaseNameWhere   + ' and ACN.NAMETYPE in (' +@sNameTypeKeys+ ')'
					set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' (CN.NAMETYPE in (' +@sNameTypeKeys+ ')'					
					
					if @nNameKey is not null 
					begin
						set @sAlertCaseNameWhere =  @sAlertCaseNameWhere + ' AND  ACN.NAMENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AND  CN.NAMENO ' +dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
					end
							
					if(@sNameKeys is not null)
					begin
						set @sAlertCaseNameWhere =  @sAlertCaseNameWhere + ' AND ACN.NAMENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' 
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AND CN.NAMENO in ('+dbo.fn_WrapQuotes(@sNameKeys,1,0)+')' + char(10)
					end

					if @nMemberOfGroupKey is not null
						or @sMemberOfGroupKeys is not null
					begin						
						set @psAdHocDatesFrom = @psAdHocDatesFrom +	'LEFT JOIN NAME ADN WITH (NOLOCK) on (ADN.NAMENO = CN.NAMENO) ' + char(10)
						set @sAlertCaseName = @sAlertCaseName +	'LEFT JOIN NAME ADCN WITH (NOLOCK) on (ADCN.NAMENO = ACN.NAMENO) ' + char(10)
						
						if @nMemberOfGroupKey is not null
							begin
								set @sAlertCaseNameWhere  = @sAlertCaseNameWhere + ' AND ADCN.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)
								set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AND ADN.FAMILYNO ' + dbo.fn_ConstructOperator(@nMemberOfGroupKeyOperator,@Numeric,@nMemberOfGroupKey, null,0)  								
							end
						else 
							begin
								
								set @sAlertCaseNameWhere  = @sAlertCaseNameWhere + ' AND ADCN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10)  
								set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AND ADN.FAMILYNO in ('+dbo.fn_WrapQuotes(@sMemberOfGroupKeys,1,0)+')' + char(10) 								
							end
					end

					if(@nNullGroupNameKey is not null)
					begin
						set @sAlertCaseNameWhere =  @sAlertCaseNameWhere + ' AND ACN.NAMENO in ('+dbo.fn_WrapQuotes(@nNullGroupNameKey,1,0)+')' 
						set @psAdHocDatesWhere =  @psAdHocDatesWhere + ' AND CN.NAMENO in ('+dbo.fn_WrapQuotes(@nNullGroupNameKey,1,0)+')' + char(10)
					end

					set @psAdHocDatesWhere =  @psAdHocDatesWhere + ')' + CHAR(10)				
				end						

				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+') '			
		End

		If ( @bUseDueDate = 1  or @bUseReminderDate = 1) and 
			(@dtDateRangeFrom is not null
			or @dtDateRangeTo is not null)
		Begin					
			Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+'and ( '

				if @bUseDueDate = 1
				begin							
					set	@psAdHocDatesWhere = @psAdHocDatesWhere +" AX.DUEDATE "+@sDateRangeFilter		
				end

				if @bUseReminderDate = 1
				begin						
					if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) = 0
					Begin

					set @psAdHocDatesFrom = @psAdHocDatesFrom  + ' left join EMPLOYEEREMINDER ER WITH (NOLOCK) on 
																			(AX.EMPLOYEENO = ER.ALERTNAMENO
																			and AX.SEQUENCENO = ER.SEQUENCENO
																			and ER.SOURCE    = 1
																			and ER.EVENTNO IS NULL
																			and (AX.CASEID = ER.CASEID
																			or (AX.REFERENCE = ER.REFERENCE
																			and AX.CASEID is null
																			and ER.CASEID is null)
																			or (AX.NAMENO = ER.NAMENO)))' + char(10)

					 End

					if @bUseDueDate = 1
					begin
						set	@psAdHocDatesWhere = @psAdHocDatesWhere +" or "
					end
					set	@psAdHocDatesWhere = @psAdHocDatesWhere +" ER.REMINDERDATE "+@sDateRangeFilter	
				end

				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+') '
		End			

		if(@sEventKeys is not null 
		or @nEventKeysOperator in (5,6))
		begin 					
			set @psAdHocDatesWhere =  @psAdHocDatesWhere +  " and ( AX.EVENTNO " + dbo.fn_ConstructOperator(@nEventKeysOperator,@CommaString,@sEventKeys, null,0) +  ') '+ CHAR(10)		
		end
				

	    If @nImportanceLevelOperator is not null
		and (@sImportanceLevelFrom is not null
		 or  @sImportanceLevelTo is not null)
		Begin
			Set @psAdHocDatesWhere = @psAdHocDatesWhere +char(10)+"and (AX.IMPORTANCELEVEL "+dbo.fn_ConstructOperator(@nImportanceLevelOperator,@String,@sImportanceLevelFrom, @sImportanceLevelTo,0) + ")"	
		End
		
		if @sImportanceLevelKeys is not null and @nImportanceLevelKeysOperator is not null
		begin
			Set @psAdHocDatesWhere = @psAdHocDatesWhere +char(10)+"and (AX.IMPORTANCELEVEL "++ dbo.fn_ConstructOperator(@nImportanceLevelKeysOperator,@CommaString,@sImportanceLevelKeys, NULL,@pbCalledFromCentura) + ")"	
		end

		if @sReminderForNameKeys is not null 
			and @nReminderForNameKeysOperator is not null
		Begin			
				if CHARINDEX('left join NAME ERN WITH (NOLOCK)', @psAdHocDatesFrom) = 0
				Begin	
					set @psAdHocDatesFrom = @psAdHocDatesFrom  + ' left join NAME ERN WITH (NOLOCK)	on (ERN.NAMENO=AX.EMPLOYEENO) ' + char(10)					
				End					 

				set @psAdHocDatesWhere = @psAdHocDatesWhere + ' and  ERN.NAMENO ' + dbo.fn_ConstructOperator(@nReminderForNameKeysOperator,@Numeric,@sReminderForNameKeys, null,0) 
		End		
				
		if @sReminderMessage is not null
		or @nReminderMessageOperator between 2 and 6
		or  @bIsReminderOnHold = 1
		or @bIsReminderOnHold = 0
		or @bIsReminderRead is not null
		or @bIncludeFinalizedAdHocDates = 0
		begin

			if CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) = 0
			Begin

				set @psAdHocDatesFrom = @psAdHocDatesFrom  + ' left join EMPLOYEEREMINDER ER WITH (NOLOCK) on 
																	(AX.EMPLOYEENO = ER.ALERTNAMENO
																	and AX.SEQUENCENO = ER.SEQUENCENO
																	and ER.SOURCE    = 1
																	and ER.EVENTNO IS NULL
																	and (AX.CASEID = ER.CASEID
																	or (AX.REFERENCE = ER.REFERENCE
																	and AX.CASEID is null
																	and ER.CASEID is null)
																	or (AX.NAMENO = ER.NAMENO)))' + char(10)

			End
		
			If @sReminderMessage is not null
			or @nReminderMessageOperator between 2 and 6
			Begin
				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and isnull(cast(ER.LONGMESSAGE as nvarchar(4000)), ER.SHORTMESSAGE) "+dbo.fn_ConstructOperator(@nReminderMessageOperator,@String,@sReminderMessage, null,0)			
			End		
			
			If @bIsReminderOnHold = 1
			Begin
				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and ER.HOLDUNTILDATE is not null" 	
			End
			Else If @bIsReminderOnHold = 0
			Begin
				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and ER.HOLDUNTILDATE is null" 	
			End		

			If @bIsReminderRead is not null
			Begin
				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and CAST(ER.READFLAG as bit) = " + CAST(@bIsReminderRead as char(1)) 	
			End	
								
			if @bIncludeFinalizedAdHocDates = 0
			Begin
				Set @psAdHocDatesWhere = @psAdHocDatesWhere +char(10)+" and (AX.DATEOCCURRED is null and (isnull(AX.OCCURREDFLAG,0)=0) )"
			End
		end

		If  @sAdHocReference is not null
		or  @nAdHocReferenceOperator between 2 and 6
		Begin					
			Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+ " and 	AX.REFERENCE "+dbo.fn_ConstructOperator(@nAdHocReferenceOperator,@String,@sAdHocReference, null,0)
		End		

		If  @sNameReferenceKeys is not null
	        and @nNameReferenceKeysOperator < 2
		Begin	
		        Set @psAdHocDatesWhere = @psAdHocDatesWhere + " and AX.NAMENO "+dbo.fn_ConstructOperator(@nNameReferenceKeysOperator,@CommaString,@sNameReferenceKeys, null,0)
		End			

		If  @sAdHocMessage is not null
		or  @nAdHocMessageOperator between 2 and 6
		Begin					
			Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and 	AX.ALERTMESSAGE "+dbo.fn_ConstructOperator(@nAdHocMessageOperator,@String,@sAdHocMessage, null,0)
		End	

		If  @sAdHocEmailSubject is not null
		or  @nAdHocEmailSubjectOperator between 2 and 6
		Begin					
			Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and 	AX.EMAILSUBJECT "+dbo.fn_ConstructOperator(@nAdHocEmailSubjectOperator,@String,@sAdHocEmailSubject, null,0)
		End	
					
		if @bHasCase = 1 or @bHasName = 1 or @bIsGeneral = 1
		begin
			Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" and 	( " 
			
			if @bHasCase = 1
			begin
				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" AX.CASEID is not null "
			end

			if @bHasName = 1
			begin
				if @bHasCase = 1
				begin
					Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" or "
				end				
				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" AX.NAMENO is not null "
			end
		
			if @bIsGeneral = 1
			begin
				if @bHasCase = 1  or @bHasName = 1
				begin
					Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" or "
				end				

				Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" AX.REFERENCE is not null "
			end

			Set @psAdHocDatesWhere = @psAdHocDatesWhere+char(10)+" ) " 
		end		
		
		If @sShortTitleText is not NULL
		or @nShortTitleOperator between 0 and 1
		Begin
			Set @psAdHocDatesWhere = @psAdHocDatesWhere + char(10)+"	and	C.ShortTitle "+dbo.fn_ConstructOperator(@nShortTitleOperator,@CommaString,@sShortTitleText, null,@pbCalledFromCentura)
		End
	End		
		
	set @sCaseEventExits = @sCaseEventExits + @sCaseEventExitsWhere 
	set @sCE_ResponsibleStaff =    @sCE_ResponsibleStaff  + @sCE_ResponsibleStaffWhere
	set @sCE_ResponsibleStaffFamily = @sCE_ResponsibleStaffFamily  + @sCE_ResponsibleStaffFamilyWhere  
	
	Set @sReminderExists = @sReminderExists + @sReminderExistsWhere 
	set @sReminderRecipientFamily  = @sReminderRecipientFamily + @sReminderRecipientFamilyWhere  
	set @sReminderCaseName  = @sReminderCaseName  + @sReminderCaseNameWhere
	
	Set @sAlertExists    = @sAlertExists +  @sAlertExistsWhere 
	set @sAlertCaseName = @sAlertCaseName + @sAlertCaseNameWhere
	set @sAlertFamily  = @sAlertFamily + @sAlertFamilyWhere

	set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere + ''	
	Declare @sCaseEventWhare	nvarchar(max)

	set @sCaseEventWhare = char(10) + ' WHERE 1=1 ' + char(10)

	if @bIsDueDates = 1
	begin
		set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere  + char(10) + ' LEFT JOIN ( ' + @sCaseEventExits + ' ) CE ON (CE.CASEID = D.CASEID ) ' 
		set @sCaseEventWhare = @sCaseEventWhare + ' and (CE.CASEID is not null ' 
		
		if @sNameTypeKeys is not null and @sNameTypeKeys <> ''
		begin
			set @psCTE_CaseEventWhere  = @psCTE_CaseEventWhere   + char(10) +' LEFT JOIN ( ' + @sCE_ResponsibleStaff + ' ) CECN ON (D.CASEID = CECN.CASEID ) ' 
			set @sCaseEventWhare = @sCaseEventWhare + ' or CECN.CASEID is not null '
		end

		if @bIsResponsibleStaff = 1  and (@nMemberOfGroupKey is not null or @sMemberOfGroupKeys is not null)
		begin					
			set @psCTE_CaseEventWhere  = @psCTE_CaseEventWhere   + char(10) +' LEFT JOIN ( ' + @sCE_ResponsibleStaffFamily + ' ) CEN ON (CE.EMPLOYEENO = CEN.NAMENO ) ' 
			set @sCaseEventWhare = @sCaseEventWhare + ' or CEN.NAMENO is not null '
		end				
	end

	if @bIsReminders = 1
	begin
		set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere  + char(10) + ' LEFT JOIN ( ' + @sReminderExists + ' ) ER ON (ER.CASEID = D.CASEID ) ' 		
		set @sCaseEventWhare = @sCaseEventWhare + case when @bIsDueDates = 1 then  ' or ER.CASEID is not null '  else ' and (ER.CASEID is not null ' end 

		if @bIsReminderRecipient = 1 and ( @nMemberOfGroupKey is not null or @sMemberOfGroupKeys is not null)
		begin
			set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere  + char(10) + ' LEFT JOIN ( ' + @sReminderRecipientFamily + ' ) RN on (RN.NAMENO = ER.EMPLOYEENO)  ' 
			set @sCaseEventWhare = @sCaseEventWhare + ' or RN.NAMENO is not null '
		end

		if @sNameTypeKeys is not null and @sNameTypeKeys <> ''
		begin
			set @psCTE_CaseEventWhere  = @psCTE_CaseEventWhere   + char(10) +' LEFT JOIN ( ' + @sReminderCaseName + ' ) RCN ON (RCN.CASEID =D.CASEID) ' 
			set @sCaseEventWhare = @sCaseEventWhare + ' or RCN.CASEID is not null '
		end
	end

	if @bIsAdHocDates = 1
	begin
		set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere  + char(10) + ' LEFT JOIN ( ' + @sAlertExists + ' ) A ON (A.CASEID = D.CASEID ) '			
		set @sCaseEventWhare = @sCaseEventWhare + case when @bIsDueDates = 1 or @bIsReminders = 1 then  ' or A.CASEID is not null '  else ' and (A.CASEID is not null ' end 

		if @sNameTypeKeys is not null and @sNameTypeKeys <> ''
		begin
			set @psCTE_CaseEventWhere  = @psCTE_CaseEventWhere   + char(10) +' LEFT JOIN ( ' + @sAlertCaseName + ' ) ACN ON (ACN.CASEID = D.CASEID)  ' 
			set @sCaseEventWhare = @sCaseEventWhare + ' or ACN.CASEID is not null '
		end

		if @bIsReminderRecipient = 1 and ( @nMemberOfGroupKey is not null or @sMemberOfGroupKeys is not null)
		begin
			set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere  + char(10) + ' LEFT JOIN ( ' + @sAlertFamily + ' ) AN on (AN.NAMENO = A.EMPLOYEENO)  ' 
			set @sCaseEventWhare = @sCaseEventWhare + ' or AN.NAMENO is not null '
		end
	end
	
	set @sCaseEventWhare = @sCaseEventWhare + case when @bIsDueDates = 1 or @bIsReminders = 1 or @bIsAdHocDates = 1 then ')' else '' end 
	set @sCaseEventWhare = @sCaseEventWhare + char(10) + ' and D.CASEID = C.CASEID ' + char(10)
	set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere + ' ' + @sCaseEventWhare + ' ) ' + char(10)
	
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_ConstructTaskPlannerWhere  to public
GO