-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ConstructTaskPlannerSelect
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_ConstructTaskPlannerSelect]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ipw_ConstructTaskPlannerSelect.'
	drop procedure dbo.ipw_ConstructTaskPlannerSelect
End
print '**** Creating procedure dbo.ipw_ConstructTaskPlannerSelect...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE PROCEDURE dbo.ipw_ConstructTaskPlannerSelect
(	
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.		
	@ptXMLFilterCriteria		ntext		= null,		-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0,
	@pnQueryContextKey			int	,
	@psCTE_Cases				nvarchar(max) = null output,
    @psCTE_CasesFrom				nvarchar(max) = null output,
    @psCTE_CasesWhere				nvarchar(max) = null output,
    @psCTE_CasesSelect				nvarchar(max) = null output,
	@psCTE_CaseName				nvarchar(max) = null output,
    @psCTE_CaseNameFrom				nvarchar(max) = null output,
    @psCTE_CaseNameWhere				nvarchar(max) = null output,
    @psCTE_CaseNameSelect				nvarchar(max) = null output,
    @psCTE_CaseNameGroup				nvarchar(max) = null output,
	@psCTE_CaseDetails			nvarchar(max)= null output,
	@psCTE_CaseDetailsFrom		nvarchar(max)= null output,
	@psCTE_CaseDetailsWhere		nvarchar(max)= null output,
	@psCTE_CaseDetailsSelect	nvarchar(max)= null output,
	@psRemindersSelect		    nvarchar(max) = null output,
    @psRemindersFrom			nvarchar(max) = null output,
	@psRemindersWhere			nvarchar(max) = null output,
	@psDueDatesSelect			nvarchar(max) = null output,
	@psDueDatesFrom				nvarchar(max) = null output,
	@psDueDatesWhere			nvarchar(max) = null output,
	@psAdHocDatesSelect			nvarchar(max) = null output,
	@psAdHocDatesFrom			nvarchar(max) = null output,
	@psAdHocDatesWhere			nvarchar(max) = null output,
	@psTaskPlannerOrderBy		nvarchar(max) = null output,
	@psPopulateTempCaseTableSql	nvarchar(max) = null output,
	@psPopulateTempCaseIdTableSql	nvarchar(max) = null output,
	@pbUseTempTables	bit = null output,
	@psCTE_CaseEventSelect nvarchar(max) = null output,
	@psCTE_CaseEventWhere nvarchar(max) = null output
)	
AS
-- PROCEDURE :	ipw_ConstructTaskPlannerSelect
-- VERSION :	36
-- DESCRIPTION:	Create select query string for task planner
-- MODIFICATIONS :
-- Date			Who		Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 22 Oct 2020  AK		DR-64541	1		Procedure created 
-- 26 Oct 2020  AK		DR-65386	2		Made "Reminder For" column filterable. 
-- 19 Nov 2020	MS		DR-66389	3		Added TaskPlannerRowKey column
-- 25 Nov 2020  AK		DR-65413	4		updated to include @psCTE_Cases,@psCTE_CasesFrom and @psCTE_CasesWhere .
-- 01 Dec 2020	DV		DR-63493	5		Added Additional columns for task planner
-- 2  DEC 2020  KT		DR-64447	6		Added LastUpdatedEventNoteTimeStamp column.
-- 12 Dec 2020	DV		DR-63493	7		Added EventCategory, EventCategoryIcon, EventGroup, EventNo, Status, JurisdictionCode,
--											TypeOfMark, OfficialNumber and Importance column.
-- 16 Dec 2020	LS		DR-65855	8		Used caseid instead of casekey
-- 16 Dec 2020  SW		DR-66853    9		Added ShowReminderComments Column value in Select clause
--											Corrected TaskPlannerRowKey and ReminderFor Columns logic for AdhocReminders
-- 18 Dec 2020  KT		DR-64452    10		Corrected LastUpdatedEventNoteTimeStamp logic for icon time display
-- 22 Dec 2020	LS		DR-67334	11		Used caseid instead of casekey
-- 11 Jan 2021	SW		DR-65753	12		Add logic for select of IsDueDateToday and IsDueDatePast
-- 08 Feb 2021	LS		DR-68237	13		Included CTE for accessing case names 
-- 09 Feb 2021	AK		DR-65778	14		removed logic to include events from Law Update Service
-- 09 Feb 2021	SW		DR-64528	15  	Corrected LastUpdatedEventNoteTimeStamp column retrieval logic
-- 07 Apr 2021	LS		DR-68298	16  	Applied ISNULL on EmployeeNo for TaskPlannerRowKey
-- 29 Apr 2021	AK		DR-68342	17  	Added IsRead Implied Column
-- 11 Mar 2021	LS		DR-68344	18  	Added ID in TaskPlannerRowKey
-- 07 Jun 2021	DV		DR-72192	19		Return ID column from ALERT table for AdHoc reminders
-- 10 Jun 2021	AK		DR-62197	20		Performance optimization
-- 16 Jun 2021	LS		DR-71170	21		Fixed dueDate where clause for SOURCE
-- 21 Jun 2021	AK		DR-72547	22		Validate Performance of Task Planner against Client DB 
-- 07 Jul 2021	LS		DR-73154	23  	Added CASEEVENT.ID in TaskPlannerRowKey
-- 20 Jul 2021	AK		DR-73394	24		Validate Performance of Task Planner against Client DB  - phase 2
-- 20 Jul 2021	LS		DR-73590	25 		Simplify TaskPlannerRowKey
-- 16 Aug 2021	SW		DR-73645	26 		Added AdHocDateFor column
-- 18 Aug 2021  AZ		DR-72653	27		Add AttachmentCount column
-- 24 Aug 2021  SS		DR-72663	28		Add EventCycle and ActionKey columns
-- 31 Aug 2021  AK		DR-75037	29		Added logic to return forwarded ad hoc reminders 
-- 14 Sep 2021  SR		DR-74036	30		Added LastUpdatedReminderComment column 
-- 19 Oct 2021  AK		DR-76940	31		Added ImportanceLevelKey column
-- 15 Nov 2021  AK		DR-76655	32		Added HasInstructions column
-- 26 Nov 2021  SR		DR-77458	33		Modified LastUpdatedReminderComment logic for adhoc
-- 10 Jan 2022  AK		DR-78794	34		Added StatusKey column
-- 07 Feb 2022  AK		DR-79715	35		removed logic to look set of cases
-- 22 Feb 2022  AK		DR-79372	36		Added ShortTitle column

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode			int = 0

Declare @bIsReminders			bit	
Declare @bIsDueDates			bit		
Declare @bIsAdHocDates			bit

Declare @nDateRangeOperator		tinyint
Declare @dtDateRangeFrom		datetime	-- Return due dates between these dates.  From and/or To value must be provided.
Declare @dtDateRangeTo			datetime		
Declare @nPeriodRangeOperator		tinyint
Declare @sPeriodRangeType		nvarchar(2)	-- D - Days, W � Weeks, M � Months, Y - Years.
Declare @nPeriodRangeFrom		smallint	-- May be positive or negative.  Always supplied in conjunction with Type.
Declare @nPeriodRangeTo			smallint	
Declare @bUseDueDate			bit
Declare @bUseReminderDate		bit
Declare @bSinceLastWorkingDay		bit		-- Indicates that the From value should be set to the day after the working day before todayâ€™s date.
Declare @sDateRangeFilter		nvarchar(200)	-- the Date Range Filter for the 'Where' clauses
Declare @dtTodaysDate			datetime

Declare @sSQLString			nvarchar(max)
Declare @idoc 				int	

declare @sCasesTempTable		nvarchar(128)
declare @sCaseIdsTempTable		nvarchar(128)
Declare @sFullFormattedNameString nvarchar(1000)
declare @sCaseEventTempTable	nvarchar(128)

Declare @sLookupCulture		nvarchar(10)

Declare @Date				nchar(2)
Set	@Date   			= 'DT'



Set @sFullFormattedNameString='ltrim(rtrim(
										NULLIF    ( isnull(IIF(ONAME.Suffix is not null, rtrim(ltrim(ONAME.Name+'' ''+ONAME.Suffix)),  ONAME.Name)
															,''''
														)+CASE WHEN(IIF( ONAME.MiddleName is not null,     rtrim(ltrim(isnull(ONAME.FirstName, '''')+'' ''+ONAME.MiddleName)),      ONAME.FirstName) is not null)
															THEN '', ''+ IIF( ONAME.MiddleName is not null,     rtrim(ltrim(isnull(ONAME.FirstName, '''')+'' ''+ONAME.MiddleName)),      ONAME.FirstName)
															ELSE ''''
															END       
												, ''''
												)
											)
										)' 


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

Declare @nOutRequestsRowCount		int
Declare @nCount				int =  1
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sQualifier			nvarchar(50)
Declare @sProcedureName			nvarchar(50)
Declare @sCorrelationSuffix		nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @sTableColumn			nvarchar(1000)

declare @bRowLevelSecurity		bit
declare	@bBlockCaseAccess		bit
declare @bCaseOffice			bit
Declare @sAdHocChecksumColumns	nvarchar(4000)


set  @bRowLevelSecurity = 0
set @bBlockCaseAccess = 0
set @bCaseOffice = 0

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
	   
-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = 	
	"Select " + char(10) +
	"	@bIsReminders			= IsReminders,"+CHAR(10)+
	"	@bIsDueDates			= IsDueDates,"+CHAR(10)+
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
	"	@bIsAdHocDates			= IsAdHocDates"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+	
	"	      IsReminders			bit		'Include/IsReminders',"+CHAR(10)+
	"	      IsDueDates			bit		'Include/IsDueDates',"+CHAR(10)+
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
	"	      SinceLastWorkingDay	bit		'Dates/@SinceLastWorkingDay/text()',"+CHAR(10)+	
	"	      IsAdHocDates			bit		'Include/IsAdHocDates'"+CHAR(10)+	
    "     		)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,				 			
				  @bIsReminders			bit			output,
				  @bIsDueDates			bit			output,
				  @bUseDueDate					bit			output,
				  @bUseReminderDate				bit			output,
				  @nDateRangeOperator			tinyint			output,
				  @dtDateRangeFrom		datetime		output,
				  @dtDateRangeTo		datetime		output,
				  @nPeriodRangeOperator	tinyint			output,
				  @sPeriodRangeType		nvarchar(2)		output,
				  @nPeriodRangeFrom		smallint		output,
				  @nPeriodRangeTo		smallint		output,
				  @bSinceLastWorkingDay		bit			output,
				  @bIsAdHocDates				bit			output',
				  @idoc				= @idoc,				 
				  @bIsReminders				=  @bIsReminders	output,
				  @bIsDueDates			=  @bIsDueDates			output,
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
				  @bIsAdHocDates				=  @bIsAdHocDates			output		
				  
		If @nErrorCode = 0
	Begin
		-- If the following parameters were not supplied 
		-- then set them to 0:
		Set @bIsReminders 		= isnull(@bIsReminders,0)
		Set @bIsDueDates 		= isnull(@bIsDueDates,0)
		Set @bIsAdHocDates 		= isnull(@bIsAdHocDates,0)
		
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


	End	
End

	Set @sDateRangeFilter = dbo.fn_ConstructOperator(ISNULL(@nDateRangeOperator, @nPeriodRangeOperator),@Date,convert(nvarchar, @dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),0)


set @pbUseTempTables = ISNULL(@pbUseTempTables, 0)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If exists (select 1
	   from SITECONTROL S
	   where S.CONTROLID='Due Date Event Threshold for Task Planner'
	   and S.COLINTEGER<(select count(*) from EVENTS))
Begin
	Set @pbUseTempTables        = 1
	Set @sCasesTempTable	   = '##LISTDUEDATE' + REPLACE(CAST(NEWID() as nvarchar(50)), '-','')
	
	if exists (select * from tempdb.dbo.sysobjects where name = @sCasesTempTable)
	Begin
		exec ('drop table ' + @sCasesTempTable)
	End
End


set @sCaseEventTempTable = '##CASEEVENTCASES' + REPLACE(CAST(NEWID() as nvarchar(50)), '-','')
Set @sCaseIdsTempTable   = '##LISTDUEDATE' + REPLACE(CAST(NEWID() as nvarchar(50)), '-','')

if exists (select * from tempdb.dbo.sysobjects where name = @sCaseIdsTempTable)
Begin
	exec ('drop table ' + @sCaseIdsTempTable)
End

if exists (select * from tempdb.dbo.sysobjects where name = @sCaseEventTempTable)
Begin
	exec ('drop table ' + @sCaseEventTempTable)
End

-- Initialise --- 

set @psCTE_Cases =  @psCTE_Cases + 'with CTE_Cases (CASEID) as (' + CHAR(10) 

set @psCTE_CasesSelect =  @psCTE_CasesSelect + '	select C.CASEID '+CHAR(10) 
set @psCTE_CasesFrom =  @psCTE_CasesFrom +'	FROM dbo.fn_CasesEthicalWall('+cast(@pnUserIdentityId as nvarchar)+') C'+ CHAR(10) 
								+ CASE WHEN(@bRowLevelSecurity = 1 AND @bCaseOffice = 1) THEN '	join fn_CasesRowSecurity('           +convert(nvarchar,@pnUserIdentityId)+') RS on (RS.CASEID=C.CASEID and RS.READALLOWED=1)'+ CHAR(10) 
								WHEN(@bRowLevelSecurity = 1)                      THEN '	join fn_CasesRowSecurityMultiOffice('+convert(nvarchar,@pnUserIdentityId)+') RS on (RS.CASEID=C.CASEID and RS.READALLOWED=1)'+ CHAR(10) 
								WHEN(@bBlockCaseAccess  = 1)		       THEN '	join (select 1 as BlockingRow) RS on (RS.BlockingRow=0)' + CHAR(10) 
								ELSE '' 
								END
set @psCTE_CasesWhere = @psCTE_CasesWhere + ' where 1=1 ' 

Set @psPopulateTempCaseIdTableSql = 'select * into '+@sCaseIdsTempTable+' from CTE_Cases;'


set @psCTE_CaseEventSelect =  @psCTE_CaseEventSelect +  ' select C.CASEID into '+ @sCaseEventTempTable +  char(10)  +
								' from ' +  @sCaseIdsTempTable  + ' C ' +  char(10)  
								
set @psCTE_CaseEventWhere = @psCTE_CaseEventWhere + ' where ' + char(10) +
												  + ' ( ' + char(10) +
												  + ' exists (select * from '+ @sCaseIdsTempTable +' D ' + char(10)
												  

set @psCTE_CaseName  = @psCTE_CaseName + '; With CTE_CaseName (CASEID, NAMETYPE, SEQUENCE)' +  char(10) + 
									         ' as (   ' 

set @psCTE_CaseNameSelect = @psCTE_CaseNameSelect + ' select CN.CASEID, CN.NAMETYPE, MIN(CN.SEQUENCE)'  + char(10)    
set @psCTE_CaseNameFrom = @psCTE_CaseNameFrom + 'from CASENAME CN with (NOLOCK)'  + char(10) 													
set @psCTE_CaseNameWhere =  @psCTE_CaseNameWhere + 'where (EXPIRYDATE is null or EXPIRYDATE>GETDATE()) ' + char(10)	+
													+ ' AND EXISTS ( SELECT 1 FROM '+ @sCaseEventTempTable +' VCE WITH (NOLOCK)  WHERE CN.CASEID = VCE.CASEID) ' + char(10)
													
set @psCTE_CaseNameGroup =  @psCTE_CaseNameGroup + 'group by CN.CASEID, CN.NAMETYPE' + char(10)
						
set @psCTE_CaseDetails = @psCTE_CaseDetails + ', CTE_CaseDetails as (' + char(10)
set @psCTE_CaseDetailsSelect = ' C.CASEID as CASEID '
set @psCTE_CaseDetailsFrom = ' FROM CASES C WITH (NOLOCK) ' + char(10) +
							'  JOIN ' + @sCaseEventTempTable +'  CTEC WITH (NOLOCK)  ON (CTEC.CASEID = C.CASEID) '  + char(10) 
							 

set @psCTE_CaseDetailsWhere = ' WHERE 1=1 ' + char(10)

--set @psCTE_CaseDetailsWhere = @psCTE_CaseDetailsWhere + char(10) + ' AND EXISTS ( SELECT 1 FROM '+ @sCaseEventTempTable +' VCE WHERE C.CASEID = VCE.CASEID) '

If @pbUseTempTables = 1
Begin	
	Set @psPopulateTempCaseTableSql = 'select * into '+@sCasesTempTable+' from CTE_CaseDetails;'			
End

set @psRemindersFrom		= ' FROM EMPLOYEEREMINDER ER WITH (NOLOCK) 
							   LEFT JOIN  '+ case when @pbUseTempTables = 1 then @sCasesTempTable else '  CTE_CaseDetails ' end	+'  C WITH (NOLOCK) on (C.CASEID = ER.CASEID) ' +char(10)

set @psRemindersFrom = @psRemindersFrom + CHAR(10) +
						'left join ALERT A	on (A.EMPLOYEENO = ER.ALERTNAMENO
						and A.SEQUENCENO = ER.SEQUENCENO
						and ER.SOURCE    = 1
						and ER.EVENTNO IS NULL
						and (A.CASEID = ER.CASEID
						or (A.REFERENCE = ER.REFERENCE
						and A.CASEID is null
						and ER.CASEID is null)
						or (A.NAMENO = ER.NAMENO)))' + CHAR(10)

set @psRemindersFrom = @psRemindersFrom + CHAR(10) +
						' left join CASEEVENT CE  WITH (NOLOCK) ON (CE.CASEID = ER.CASEID
															and CE.EVENTNO = ER.EVENTNO
															and CE.CYCLE = ER.CYCLENO)' + CHAR(10)


set @psRemindersWhere	= ' WHERE 1=1 '	+char(10)



set @psDueDatesFrom		= ' FROM '+ case when @pbUseTempTables = 1 then @sCasesTempTable else '  CTE_CaseDetails ' end	+' C WITH (NOLOCK)  
							JOIN CASEEVENT CE WITH (NOLOCK) ON (CE.CASEID=C.CASEID ' + 
							Case when @bIsDueDates = 1 and  @sDateRangeFilter is not null then  ' and CE.EVENTDUEDATE ' + @sDateRangeFilter	
							else '' end 
							+' ) ' + char(10)


set @psDueDatesWhere		=  @psRemindersWhere


set @psAdHocDatesFrom	= ' FROM ALERT AX WITH (NOLOCK)				
							LEFT JOIN '+ case when @pbUseTempTables = 1 then @sCasesTempTable else '  CTE_CaseDetails ' end	+' C WITH (NOLOCK) ON (AX.CASEID = C.CASEID)' 
set @psAdHocDatesWhere	= ' where (AX.DUEDATE IS NOT NULL OR AX.TRIGGEREVENTNO IS NOT NULL) ' +char(10)

/****    CONSTRUCTION OF THE SELECT LIST    ****/

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
	-- Default @pnQueryContextKey to 970.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 970)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)	
End

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
							  ELSE NULL END,
		@sQualifier		= QUALIFIER,
		@sProcedureName		= PROCEDURENAME
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
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End

	If @nErrorCode=0	 
	Begin
		If @sProcedureName = 'ipw_TaskPlanner'
		Begin
			-- prepare select for CTE_CaseDetails
			if @sColumn in 
			(
			'PropertyTypeDescription',
			'CaseReference',
			'CaseTypeDescription',
			'CaseTypeKey',
			'PropertyTypeKey',
			'CountryKey',
			'CountryCode',
			'StatusDescription',
			'StatusKey',
			'CurrentOfficialNumber',
			'CountryName',
			'TypeOfMarkDescription',
			'CaseKey',
			'Owner',
			'OwnerKey',
			'StaffMember',
			'StaffMemberKey',
			'Signatory',
			'SignatoryKey',
			'Instructor',
			'InstructorKey',
			'Owners',
			'ShortTitle'
			)
			begin
				if  @sColumn = 'CaseReference'
				 Begin
					Set @sTableColumn=' C.IRN ' 
				 End

				if @sColumn =  'PropertyTypeDescription'
				begin 
					
					Set @sTableColumn=' VP.PROPERTYNAME ' 
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + ' Join VALIDPROPERTY VP with (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE
                             and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)
                                                   from VALIDPROPERTY VP1 with (NOLOCK)
                                                   where VP1.PROPERTYTYPE=C.PROPERTYTYPE
                                                   and   VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ''))) ' + CHAR(10)
					
				end

				if @sColumn = 'CaseTypeDescription'
				 begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CTX',@sLookupCulture,@pbCalledFromCentura) 
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + ' JOIN CASETYPE CTX  WITH (NOLOCK) on (CTX.CASETYPE = C.CASETYPE) ' + CHAR(10)
				 end
				 
				 if @sColumn = 'CaseTypeKey'
				 begin
					Set @sTableColumn= 'CTX.CASETYPE'					
				 end

				 if @sColumn = 'PropertyTypeKey'
				 begin
					Set @sTableColumn= 'VP.PROPERTYTYPE'					
				 end

				 if @sColumn in ('CountryKey', 'CountryCode')
				 begin
					Set @sTableColumn= 'CO.COUNTRYCODE'					
				 end				 

				if @sColumn = 'CountryName' 
				 begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CO',@sLookupCulture,@pbCalledFromCentura)
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + ' JOIN COUNTRY CO  WITH (NOLOCK) on (CO.COUNTRYCODE = C.COUNTRYCODE) ' + CHAR(10)
				 end

				 if @sColumn = 'StatusDescription'
				 begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + ' Left Join STATUS ST with (NOLOCK) on (ST.STATUSCODE=C.STATUSCODE) '
				 end

				 if @sColumn = 'StatusKey'
				 begin
					Set @sTableColumn='C.STATUSCODE'					
				 end
				 
				 if @sColumn = 'CurrentOfficialNumber'
				 begin
					Set @sTableColumn='C.CURRENTOFFICIALNO'
				 end

				 if @sColumn = 'TypeOfMarkDescription'
				 begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TTM',@sLookupCulture,@pbCalledFromCentura)
					if charindex('left join TABLECODES TTM',@psRemindersFrom)=0	
					Begin
						Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + char(10) + 'left join TABLECODES TTM with (NOLOCK) on (TTM.TABLECODE=C.TYPEOFMARK)'
					End					
				 end

				if @sColumn = 'CaseKey'
				Begin
					Set @sTableColumn='C.CASEID' 
				End
												
				if @sColumn = 'ShortTitle'
				Begin
					Set @sTableColumn='C.TITLE' 
				End

				if @sColumn = 'Owner'
				begin					
					Set @sTableColumn=@sFullFormattedNameString
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CTE_CaseName CTCNO ON (CTCNO.CASEID = C.CASEID and CTCNO.NAMETYPE= ''O'')
																			LEFT JOIN CASENAME CNO WITH (NOLOCK) ON (CNO.CASEID = C.CASEID AND CNO.NAMETYPE =''O'' and CNO.SEQUENCE =CTCNO.SEQUENCE)
																			LEFT JOIN NAME ONAME ON (CNO.NAMENO=ONAME.NAMENO) ' + CHAR(10)			
					
				end

				if @sColumn = 'OwnerKey'
				begin
					Set @sTableColumn=' CNO.NAMENO ' 					
				end
								
				if @sColumn = 'StaffMember'
				begin					 
					Set @sTableColumn= REPLACE(@sFullFormattedNameString, 'ONAME.', 'NSM.')
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CTE_CaseName CTCNSM ON (CTCNSM.CASEID = C.CASEID and CTCNSM.NAMETYPE= ''EMP'')
																			LEFT JOIN CASENAME CNSM WITH (NOLOCK) ON (CNSM.CASEID = C.CASEID AND CNSM.NAMETYPE =''EMP'' and CNSM.SEQUENCE =CTCNSM.SEQUENCE)
																			LEFT JOIN NAME NSM ON (NSM.NAMENO=CNSM.NAMENO) ' + CHAR(10)		
					
				end

				if @sColumn = 'StaffMemberKey'
				begin
					Set @sTableColumn=' CNSM.NAMENO ' 	
				end

				if @sColumn = 'Signatory'
				begin					 
					Set @sTableColumn=REPLACE(@sFullFormattedNameString, 'ONAME.', 'NS.')
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CTE_CaseName CTCNS ON (CTCNS.CASEID = C.CASEID and CTCNS.NAMETYPE= ''SIG'')
																			LEFT JOIN CASENAME CNS WITH (NOLOCK) ON (CNS.CASEID = C.CASEID AND CNS.NAMETYPE =''SIG'' and CNS.SEQUENCE =CTCNS.SEQUENCE)
																			LEFT JOIN NAME NS ON (CNS.NAMENO=NS.NAMENO) ' + CHAR(10)		
				end

				if @sColumn = 'SignatoryKey'
				begin
					Set @sTableColumn=' CNS.NAMENO ' 	
				end				

				if @sColumn = 'Instructor'
				begin
					Set @sTableColumn=REPLACE(@sFullFormattedNameString, 'ONAME.', 'NI.')
					Set @psCTE_CaseDetailsFrom = @psCTE_CaseDetailsFrom + '  LEFT JOIN CTE_CaseName CTCNI ON (CTCNI.CASEID = C.CASEID and CTCNI.NAMETYPE= ''I'')
																	LEFT JOIN CASENAME CNI WITH (NOLOCK) ON (CNI.CASEID = C.CASEID AND CNI.NAMETYPE =''I'' and CNI.SEQUENCE =CTCNI.SEQUENCE)
																	LEFT JOIN NAME NI ON (CNI.NAMENO=NI.NAMENO) ' + CHAR(10)	
					
				end

				if @sColumn = 'InstructorKey'
				begin
					Set @sTableColumn=' CNI.NAMENO ' 	
				end		
				
				if @sColumn = 'Owners'
				begin
					Set @sTableColumn='dbo.fn_GetConcatenatedNames(C.CASEID, ''O'', ''; '', getdate(), null)' 					
				end

				If datalength(@sPublishName)>0
				Begin
					Set @psCTE_CaseDetailsSelect=@psCTE_CaseDetailsSelect+nullif(',', ',' + @psCTE_CaseDetailsSelect)+@sTableColumn+' as ['+@sColumn+']' + char(10)							
				End
				Else 
				Begin
					Set @sPublishName=NULL
				End

			end			
			-- when reminder is selected
			Set @sTableColumn=  'null'		   
			
			if(@bIsReminders = 1)
			Begin

			If @sColumn = 'TaskPlannerRowKey'
			Begin				
				Set @sTableColumn="case 
									when CE.ID is not null then 'C^' + ISNULL(cast(CE.ID as varchar(25)),'')  
									else 'A^' + ISNULL(cast(A.ID as varchar(25)),'') 
									end + '^' + "	+ CHAR(10) 
									+char(10)+"ISNULL(cast(ER.ID as varchar(25)),'')"
			End

			If @sColumn = 'IsRead'
			Begin
				Set @sTableColumn= "CAST(IsNull(ER.READFLAG, 0) as bit)"
			End
			
			if @sColumn = 'ShowReminderComments'
			Begin
				Set @sTableColumn= 'cast(1 as bit)'
			End
			
			If @sColumn = 'LastUpdatedEventNoteTimeStamp'
			Begin
				Set @sTableColumn="(Select Top 1 ET.LOGDATETIMESTAMP from CASEEVENTTEXT CET
									left join EVENTTEXT ET on CET.EVENTTEXTID=ET.EVENTTEXTID WHERE CASEID=C.CaseId AND EVENTNO=CE.EVENTNO and CYCLE = CE.CYCLE ORDER BY ET.LOGDATETIMESTAMP DESC)"
													
			End

			IF @sColumn = 'LastUpdatedReminderComment'
			BEGIN
				Set @sTableColumn="CASE WHEN ER.COMMENTS IS NOT NULL THEN ER.LOGDATETIMESTAMP ELSE NULL END"
			End

			If @sColumn = 'AttachmentCount'
			Begin
				Set @sTableColumn="(Select count(1) from Activity act WHERE act.EVENTNO=CE.EVENTNO AND act.CASEID=CE.CASEID AND act.CYCLE=CE.CYCLE)"					
			End
			
			If @sColumn='ReminderMessage'
			Begin
				Set @sTableColumn='cast(isnull('+
						dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','LONGMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+', '+
						dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+
						') as nvarchar(max))'
			End				 
	
			if @sColumn = 'PropertyTypeDescription'
			 begin
				Set @sTableColumn=' C.PropertyTypeDescription '
			 end
			 		
			if @sColumn = 'Owner'
			begin
				Set @sTableColumn='C.Owner' 									
			end

			if @sColumn = 'OwnerKey'
			begin
				Set @sTableColumn=' C.OwnerKey ' 					
			end

			if @sColumn = 'StaffMember'
			begin
				Set @sTableColumn='C.StaffMember' 						
			end

			if @sColumn = 'Signatory'
			begin
				Set @sTableColumn='C.Signatory' 
			end

			if @sColumn = 'Instructor'
			begin
				Set @sTableColumn='C.Instructor' 
			end

			if @sColumn = 'InstructorKey'
			begin
				Set @sTableColumn='C.InstructorKey' 
			end

			if @sColumn = 'AdHocDateFor'
			begin			
				Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(A.EMPLOYEENO, null)'						
			end

			if @sColumn = 'Owners'
			begin
				Set @sTableColumn='C.Owners' 
			end
			
			if @sColumn = 'StaffMemberKey'
			begin
				Set @sTableColumn='C.StaffMemberKey' 						
			end

			if @sColumn = 'SignatoryKey'
			begin
				Set @sTableColumn='C.SignatoryKey' 
			end

			if @sColumn = 'NextReminderDate'
			Begin			
				 
				Set @sTableColumn='IsNull(CE.DATEREMIND, A.ALERTDATE)' 				
			End

			if @sColumn = 'IsAdHoc'
			Begin
				Set @sTableColumn='cast(case when A.EMPLOYEENO is not null then 1 else 0 end as bit)' 
			End

			if @sColumn = 'CaseTypeDescription'
			 begin
				Set @sTableColumn=' C.CaseTypeDescription ' 				
			 end

			if @sColumn = 'CountryName'
			 begin
				Set @sTableColumn=' C.CountryName ' 				
			 end

			if @sColumn = 'StatusDescription'
			begin
				Set @sTableColumn=' C.StatusDescription ' 
			end

			if @sColumn = 'StatusKey'
			begin
			Set @sTableColumn='C.STATUSKEY'					
			end

			if @sColumn = 'CurrentOfficialNumber'
			begin
				Set @sTableColumn=' C.CurrentOfficialNumber ' 
			end		
			
			if @sColumn = 'TypeOfMarkDescription'
			begin
				Set @sTableColumn=' C.TypeOfMarkDescription ' 
			end
			 
			if  @sColumn = 'CaseReference'
			 Begin
				Set @sTableColumn=' C.CaseReference ' 
			 End

			if @sColumn = 'ReminderDate'
			 Begin
			  	Set @sTableColumn=' ER.REMINDERDATE ' 
			 End

			if @sColumn = 'CaseKey'
			Begin
				Set @sTableColumn='C.CaseKey' 
			End

			if @sColumn = 'ShortTitle'
			Begin
				Set @sTableColumn='C.ShortTitle' 
			End

			if @sColumn = 'DueDate'
			  Begin
					Set @sTableColumn='ER.DUEDATE' 
			  End

			if @sColumn = 'IsDueDateToday'
			  Begin
					Set @sTableColumn = 'CASE WHEN (Convert(date, CAST(ER.DUEDATE as Date)) = Convert(date, GETDATE())) THEN cast(1 as bit) ELSE cast(0 as bit) END'
			  End

            if @sColumn = 'IsDueDatePast'
			  Begin
					Set @sTableColumn = 'CASE WHEN (Convert(date, CAST(ER.DUEDATE as Date)) < Convert(date, GETDATE())) THEN cast(1 as bit) ELSE cast(0 as bit) END'
			  End

     		if @sColumn in ('EventDescription',
							'EventKey', 
							'EventNumber',
							'EventCategory',
							'EventCategoryIconKey',
							'EventCategoryIcon',
							'EventGroup',
							'ImportanceDescription', 
							'ImportanceLevelKey',
							'EventCycle', 
							'ActionKey')
			Begin
				if CHARINDEX('left join EVENTS E', @psRemindersFrom) = 0
				begin
				Set @psRemindersFrom = @psRemindersFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
															left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																							on (OX.CASEID = CE.CASEID
																			and OX.ACTION = E.CONTROLLINGACTION)
															left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																			and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
				end
				if CHARINDEX('and ((CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0 and ER.SOURCE=0) or (A.DUEDATE is not null and isnull(A.OCCURREDFLAG,0)=0))', @psRemindersWhere) = 0
				begin
				Set @psRemindersWhere = @psRemindersWhere + ' and ((CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0 and ER.SOURCE=0) or (A.DUEDATE is not null and isnull(A.OCCURREDFLAG,0)=0)) '
				end
				
				if @sColumn = 'EventDescription'
				begin
				Set @sTableColumn='CASE WHEN CE.ID IS NOT NULL THEN isnull('+
								dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
								dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+
								') 
								ELSE ' 
									+  dbo.fn_SqlTranslatedColumn('ALERT','ALERTMESSAGE',null,'A',@sLookupCulture,@pbCalledFromCentura)
								+ ' END ' 

				end

				if @sColumn in ('EventKey', 'EventNumber')
				Begin					
					Set @sTableColumn= ' isnull(EC.EVENTNO, E.EVENTNO) '
				End	
				if @sColumn = 'EventCycle'
				Begin					
					Set @sTableColumn= ' CE.CYCLE'
				End	
				if @sColumn = 'ActionKey'
				Begin					
					Set @sTableColumn= ' CE.CREATEDBYACTION'
				End	
				if @sColumn in ('EventCategory',
						     'EventCategoryIconKey',
							 'EventCategoryIcon')
				Begin
					if @sColumn in ('EventCategory', 'EventCategoryIcon')
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'ECT',@sLookupCulture,@pbCalledFromCentura)
					End
					Else Begin
						Set @sTableColumn='ECT.ICONIMAGEID'
					End
					
					if charindex('left join EVENTCATEGORY ECT',@psRemindersFrom)=0	
					Begin
						Set @psRemindersFrom = @psRemindersFrom + char(10) + 'left join EVENTCATEGORY ECT with (NOLOCK) on (ECT.CATEGORYID=E.CATEGORYID)'
					End	
				End
				if @sColumn = 'EventGroup'
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TEC',@sLookupCulture,@pbCalledFromCentura)
					if charindex('left join TABLECODES TEC',@psRemindersFrom)=0	
					Begin
						Set @psRemindersFrom = @psRemindersFrom + char(10) + 'left join TABLECODES TEC with (NOLOCK) on (TEC.TABLECODE=E.EVENTGROUP)'
					End	
				End

				 If @sColumn in ('ImportanceDescription')
				 Begin
					  Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura)
					  If charindex('left join IMPORTANCE IMPC',@psAdHocDatesFrom)=0	
					  Begin
						Set @psAdHocDatesFrom = @psAdHocDatesFrom+char(10)+'left join IMPORTANCE IMPC	with (NOLOCK) on (IMPC.IMPORTANCELEVEL = AX.IMPORTANCELEVEL)'
					  End						
				 End
				  				
				

				If @sColumn = 'ImportanceDescription'
				Begin
					Set @sTableColumn="case when A.EMPLOYEENO is not null then "+ dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPCA',@sLookupCulture,@pbCalledFromCentura)  +" else "+ dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura) +" end " 
					If charindex('left join IMPORTANCE IMPC',@psRemindersFrom)=0 and charindex('left join IMPORTANCE IMPCA',@psRemindersFrom)=0
					Begin
						Set @psRemindersFrom = @psRemindersFrom + char(10) + 'left join IMPORTANCE IMPC	with (NOLOCK) on (IMPC.IMPORTANCELEVEL = COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL))'
						Set @psRemindersFrom = @psRemindersFrom + char(10) + 'left join IMPORTANCE IMPCA	with (NOLOCK) on (IMPCA.IMPORTANCELEVEL = A.IMPORTANCELEVEL)'
					End	
				End

				If @sColumn = 'ImportanceLevelKey'
				Begin
					Set @sTableColumn="case when A.EMPLOYEENO is not null then IMPCA.IMPORTANCELEVEL else IMPC.IMPORTANCELEVEL end" 
				End
				
			End

			if @sColumn = 'CaseTypeKey'
			begin
			Set @sTableColumn= 'C.CaseTypeKey'					
			end

			if @sColumn = 'PropertyTypeKey'
			begin
			Set @sTableColumn= 'C.PropertyTypeKey'					
			end

			if @sColumn in ('CountryKey', 'CountryCode')
			begin
			Set @sTableColumn= 'C.CountryKey'					
			end

			if @sColumn = 'DueDateResponsibility'
			begin
				Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(RSTAFF.NAMENO, null)'	
				
				set @psRemindersFrom = @psRemindersFrom  + ' left join NAME RSTAFF WITH (NOLOCK) on (RSTAFF.NAMENO = CE.EMPLOYEENO) ' + char(10)
			end

			if @sColumn = 'DueDateResponsibilityNameKey'
			begin
				Set @sTableColumn= 'RSTAFF.NAMENO'					
			end

			if @sColumn = 'ReminderFor'
			begin
				Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, null)'	
				
				if CHARINDEX('left join NAME ERN', @psRemindersFrom) = 0
				begin
					set @psRemindersFrom = @psRemindersFrom  + ' left join NAME ERN WITH (NOLOCK)	on (ERN.NAMENO=ER.EMPLOYEENO) ' + char(10)
				end
			end

			if @sColumn = 'HasInstructions'
				begin
					if CHARINDEX('cross join INSTRUCTIONDEFINITION D', @psRemindersFrom) = 0
					begin
						Set @psRemindersFrom = @psRemindersFrom + ' left join (select distinct C.CASEID, D.DUEEVENTNO AS EVENTNO
																	From CASES C
																	cross join INSTRUCTIONDEFINITION D
																	left join CASEEVENT P	on (P.CASEID=C.CASEID
																			and P.EVENTNO=D.PREREQUISITEEVENTNO)
																	 where D.AVAILABILITYFLAGS&4=4
																	 and	 D.DUEEVENTNO IS NOT NULL
																	 and 	(D.PREREQUISITEEVENTNO IS NULL OR
																		 P.EVENTNO IS NOT NULL
																	)
																) D			on (D.CASEID=CE.CASEID and D.EVENTNO=CE.EVENTNO) ' + CHAR(10)
					end

					Set @sTableColumn= 'CASE WHEN A.EMPLOYEENO is not null 
											 THEN  cast(0 as bit)
											 ELSE CASE WHEN (D.CASEID IS NOT NULL) 
														THEN cast(1 as bit) 
														ELSE cast(0 as bit) 
													   END 
										     END'	
				end

			if @sColumn = 'ReminderForNameKey'
			begin
				Set @sTableColumn= 'ERN.NAMENO'	
			end
			
			If datalength(@sPublishName)>0
				Begin
					Set @psRemindersSelect=@psRemindersSelect+nullif(',', ',' + @psRemindersSelect)+@sTableColumn+' as ['+@sPublishName+']'							
				End
			Else 
				Begin
					Set @sPublishName=NULL
				End

			End			
			
			Set @sTableColumn=  'null'
			-- when Due Date is selected
			if(@bIsDueDates = 1)
			Begin

				If @sColumn = 'TaskPlannerRowKey'
				Begin
				Set @sTableColumn="'C' + '^'+"					
					+char(10)+"ISNULL(cast(CE.ID as varchar(25)),'') + '^' +"
					+char(10)+"ISNULL(cast(ER.ID as varchar(25)),'')"

					if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
					begin
						Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER  WITH (NOLOCK) ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
					end
				End

				If @sColumn = 'IsRead'
				Begin
					Set @sTableColumn= "CAST(IsNull(ER.READFLAG, 1) as bit)"
				End

				If @sColumn = 'ShowReminderComments'
				Begin
					Set @sTableColumn= 'CASE WHEN ER.EMPLOYEENO is null then cast(0 as bit) else cast(1 as bit) end'
				End	

				If @sColumn = 'LastUpdatedEventNoteTimeStamp'
				Begin
					Set @sTableColumn="(Select Top 1 ET.LOGDATETIMESTAMP from CASEEVENTTEXT CET
										left join EVENTTEXT ET on CET.EVENTTEXTID=ET.EVENTTEXTID WHERE CASEID=C.CaseId AND EVENTNO=CE.EVENTNO and CYCLE = CE.CYCLE ORDER BY ET.LOGDATETIMESTAMP DESC)"
				End

				IF @sColumn = 'LastUpdatedReminderComment'
				BEGIN
					Set @sTableColumn= "null"
				END

				If @sColumn = 'AttachmentCount'
				Begin
						Set @sTableColumn="(Select count(1) from Activity act WHERE act.EVENTNO=CE.EVENTNO AND act.CASEID=C.CASEID AND act.CYCLE=CE.CYCLE)"	
				End

				If @sColumn='ReminderMessage'
				Begin
					Set @sTableColumn='cast(isnull('+
							dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','LONGMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+', '+
							dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','SHORTMESSAGE',null,'ER',@sLookupCulture,@pbCalledFromCentura)+
							') as nvarchar(max))'

			    		if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
						begin
							Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER  WITH (NOLOCK) ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
						end
				 End		
					
				
				 if @sColumn = 'PropertyTypeDescription'
				 begin
					Set @sTableColumn=' C.PropertyTypeDescription ' 
				 end

				if @sColumn = 'OwnerKey'
				begin
					Set @sTableColumn=' C.OwnerKey ' 					
				end

				if @sColumn = 'Owner'
				begin
					Set @sTableColumn=' C.Owner ' 					
				end
				if @sColumn = 'StaffMember'
				begin
					Set @sTableColumn=' C.StaffMember ' 		
				end
				if @sColumn = 'Signatory'
				begin
					Set @sTableColumn=' C.Signatory ' 
				end

				if @sColumn = 'Instructor'
				begin
					Set @sTableColumn=' C.Instructor ' 
				end

				if @sColumn = 'InstructorKey'
				begin
					Set @sTableColumn=' C.InstructorKey' 
				end

				if @sColumn = 'Owners'
				begin
					Set @sTableColumn=' C.Owners' 
				end

				if @sColumn = 'StaffMemberKey'
				begin
					Set @sTableColumn='C.StaffMemberKey' 						
				end

				if @sColumn = 'SignatoryKey'
				begin
					Set @sTableColumn='C.SignatoryKey' 
				end

				if @sColumn = 'NextReminderDate'
				Begin
					Set @sTableColumn='CE.DATEREMIND' 					
				End

				 if @sColumn = 'IsAdHoc'
				 Begin
					Set @sTableColumn='cast(0 as bit)' 
				 End

			     if  @sColumn = 'CaseReference'
				 Begin
					Set @sTableColumn=' C.CaseReference ' 
				 End

				if @sColumn = 'CaseKey'
				Begin
					Set @sTableColumn='C.CaseKey' 
				End
								
				if @sColumn = 'ShortTitle'
				Begin
					Set @sTableColumn='C.ShortTitle' 
				End
			   
				 if @sColumn = 'CaseTypeDescription'
				 begin
					Set @sTableColumn=' C.CaseTypeDescription '
				 end

				 if @sColumn = 'CountryName'
				 begin
					Set @sTableColumn=' C.CountryName ' 
				 end

				 if @sColumn = 'StatusDescription'
				 begin
					Set @sTableColumn=' C.StatusDescription ' 
				 end

				if @sColumn = 'StatusKey'
				begin
				Set @sTableColumn='C.STATUSKEY'					
				end

				 if @sColumn = 'CurrentOfficialNumber'
				 begin
					Set @sTableColumn=' C.CurrentOfficialNumber ' 
				 end

				 if @sColumn = 'TypeOfMarkDescription'
				 begin
					Set @sTableColumn=' C.TypeOfMarkDescription ' 
				 end

				 if @sColumn = 'DueDate'
				 Begin
					Set @sTableColumn='CE.EVENTDUEDATE' 
				 End
				 
				 if @sColumn = 'IsDueDateToday'
				  Begin
					Set @sTableColumn = 'CASE WHEN (Convert(date, CAST(CE.EVENTDUEDATE as Date)) = Convert(date, GETDATE())) THEN cast(1 as bit) ELSE cast(0 as bit) END'
				  End

				if @sColumn = 'IsDueDatePast'
				Begin
					Set @sTableColumn = 'CASE WHEN (Convert(date, CAST(CE.EVENTDUEDATE as Date)) < Convert(date, GETDATE())) THEN cast(1 as bit) ELSE cast(0 as bit) END'
				End
			 
				 if @sColumn = 'ReminderDate'
				 Begin
					if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
					begin
						Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER  WITH (NOLOCK) ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
					end
			  		Set @sTableColumn=' ER.REMINDERDATE ' 
				 End

				if @sColumn in ('EventDescription',
								'EventKey', 
								'EventNumber',
								'EventCategory',
								'EventCategoryIconKey',
								'EventCategoryIcon',
								'EventGroup',
								'ImportanceDescription',
								'ImportanceLevelKey',
								'EventCycle', 
								'ActionKey')
				Begin				
				if CHARINDEX('left join EVENTS E', @psDueDatesFrom) = 0
				begin
				Set @psDueDatesFrom = @psDueDatesFrom + ' left join EVENTS E WITH (NOLOCK) on (E.EVENTNO = CE.EVENTNO)
															left join (select distinct CASEID, ACTION, CRITERIANO from OPENACTION) OX
																								on (OX.CASEID = CE.CASEID
																				and OX.ACTION = E.CONTROLLINGACTION)
															left join EVENTCONTROL EC  WITH (NOLOCK) on (EC.EVENTNO = CE.EVENTNO
																				and EC.CRITERIANO = isnull(OX.CRITERIANO,CE.CREATEDBYCRITERIA)) ' + CHAR(10)
				   
				end				
				if CHARINDEX('(CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0)', @psDueDatesWhere) = 0
                begin
                    Set @psDueDatesWhere = @psDueDatesWhere + ' and (CE.EVENTDUEDATE is not null and CE.OCCURREDFLAG=0) '
                end
				
				if @sColumn = 'EventDescription'
				begin
				Set @sTableColumn='isnull('+
									dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+', '+
									dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+
									')'

				end
				if @sColumn in ('EventKey', 'EventNumber')
				Begin					
					Set @sTableColumn= ' isnull(EC.EVENTNO, E.EVENTNO) '
				End
				if @sColumn = 'EventCycle'
				Begin					
					Set @sTableColumn= ' CE.CYCLE'
				End	
				if @sColumn = 'ActionKey'
				Begin					
					Set @sTableColumn= ' CE.CREATEDBYACTION'
				End		
				if @sColumn in ('EventCategory',
						     'EventCategoryIconKey',
							 'EventCategoryIcon')
				Begin
					if @sColumn in ('EventCategory', 'EventCategoryIcon')
					Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'ECT',@sLookupCulture,@pbCalledFromCentura)
					End
					Else Begin
						Set @sTableColumn='ECT.ICONIMAGEID'
					End
					
					if charindex('left join EVENTCATEGORY ECT',@psDueDatesFrom)=0	
					Begin
						Set @psDueDatesFrom = @psDueDatesFrom + char(10) + 'left join EVENTCATEGORY ECT	with (NOLOCK) on (ECT.CATEGORYID=E.CATEGORYID)'
					End	
				End
				if @sColumn = 'EventGroup'
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TEC',@sLookupCulture,@pbCalledFromCentura)
					if charindex('left join TABLECODES TEC',@psDueDatesFrom)=0	
					Begin
						Set @psDueDatesFrom = @psDueDatesFrom + char(10) + 'left join TABLECODES TEC with (NOLOCK) on (TEC.TABLECODE=E.EVENTGROUP)'
					End	
				End
				If @sColumn = 'ImportanceDescription'
				Begin
					Set @sTableColumn = dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura)
					If charindex('left join IMPORTANCE IMPC',@psDueDatesFrom)=0	
					Begin
						Set @psDueDatesFrom = @psDueDatesFrom + char(10) + 'left join IMPORTANCE IMPC with (NOLOCK)	on (IMPC.IMPORTANCELEVEL = COALESCE(EC.IMPORTANCELEVEL, E.IMPORTANCELEVEL))'
					End	
				End
				If @sColumn = 'ImportanceLevelKey'
				Begin
					Set @sTableColumn="IMPC.IMPORTANCELEVEL"					
				End

				End				
				if @sColumn = 'CaseTypeKey'
				begin
				Set @sTableColumn= 'C.CaseTypeKey'					
				end

				if @sColumn = 'PropertyTypeKey'
				begin
				Set @sTableColumn= 'C.PropertyTypeKey'					
				end

				if @sColumn in ('CountryKey', 'CountryCode')
				begin
				Set @sTableColumn= 'C.CountryKey'					
				end

				if @sColumn = 'DueDateResponsibility'
				begin
					Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(RSTAFF.NAMENO, null)'	
					set @psDueDatesFrom = @psDueDatesFrom  + ' left join NAME RSTAFF WITH (NOLOCK)  on (RSTAFF.NAMENO = CE.EMPLOYEENO) ' + char(10)
				end

				if @sColumn = 'DueDateResponsibilityNameKey'
				begin
					Set @sTableColumn= 'RSTAFF.NAMENO'					
				end

				if @sColumn = 'ReminderFor'
				begin
					Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, null)'	
					if CHARINDEX('LEFT JOIN EMPLOYEEREMINDER ER', @psDueDatesFrom) = 0
					begin
						Set @psDueDatesFrom = @psDueDatesFrom + ' LEFT JOIN EMPLOYEEREMINDER ER  WITH (NOLOCK) ON ( ER.CASEID = CE.CASEID AND ER.EVENTNO = CE.EVENTNO AND ER.CYCLENO = CE.CYCLE) ' + CHAR(10)
					end
					set @psDueDatesFrom = @psDueDatesFrom  + ' left join NAME ERN WITH (NOLOCK)	on (ERN.NAMENO=ER.EMPLOYEENO) ' + char(10)							
				end

				if @sColumn = 'ReminderForNameKey'
				begin
					Set @sTableColumn= 'ERN.NAMENO'	
				end

				if @sColumn = 'HasInstructions'
				begin
					if CHARINDEX('cross join INSTRUCTIONDEFINITION D', @psDueDatesFrom) = 0
					begin
						Set @psDueDatesFrom = @psDueDatesFrom + ' left join (select distinct C.CASEID, D.DUEEVENTNO AS EVENTNO
																	From CASES C
																	cross join INSTRUCTIONDEFINITION D
																	left join CASEEVENT P	on (P.CASEID=C.CASEID
																			and P.EVENTNO=D.PREREQUISITEEVENTNO)
																	 where D.AVAILABILITYFLAGS&4=4
																	 and	 D.DUEEVENTNO IS NOT NULL
																	 and 	(D.PREREQUISITEEVENTNO IS NULL OR
																		 P.EVENTNO IS NOT NULL
																	)
																) D			on (D.CASEID=CE.CASEID and D.EVENTNO=CE.EVENTNO) ' + CHAR(10)
					end

					Set @sTableColumn= 'CASE WHEN(D.CASEID IS NOT NULL) then cast(1 as bit) else cast(0 as bit) END'	
				end

			    If datalength(@sPublishName)>0
				  Begin
						Set @psDueDatesSelect=@psDueDatesSelect+nullif(',', ',' + @psDueDatesSelect)+@sTableColumn+' as ['+@sPublishName+']'					
				  End
			  Else 
				  Begin
						Set @sPublishName=NULL
				  End
			End			
			
			-- when Adhoc Date is selected
			Set @sTableColumn=  'null'		
			if(@bIsAdHocDates = 1)
			Begin		

				If @sAdHocChecksumColumns is null
				Begin
					exec dbo.ip_GetComparableColumns
									@psColumns 	= @sAdHocChecksumColumns output, 
									@psTableName 	= 'ALERT',
									@psAlias 	= 'AX'
				End				

				If @sColumn = 'LastUpdatedEventNoteTimeStamp'
				Begin
					Set @sTableColumn="null"
				End

				If @sColumn = 'LastUpdatedReminderComment'
				Begin
					Set @sTableColumn="CASE WHEN ER.COMMENTS IS NOT NULL THEN ER.LOGDATETIMESTAMP ELSE NULL END"
				End

				If @sColumn = 'AttachmentCount'
				Begin
					Set @sTableColumn="(Select count(1) from Activity act WHERE act.EVENTNO=AX.EVENTNO AND act.CASEID=AX.CASEID AND act.CYCLE=AX.CYCLE)"						
				End
			  
			    If @sColumn='ReminderMessage'
				Begin
					Set @sTableColumn=' AX.ALERTMESSAGE '
				End
				
				if @sColumn = 'AdHocDateFor'
				begin			
					Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(AX.EMPLOYEENO, null)'						
				end

				if @sColumn = 'CaseKey'
				Begin
					Set @sTableColumn='C.CaseKey' 
				End

				if @sColumn = 'ShortTitle'
				Begin
					Set @sTableColumn='C.ShortTitle' 
				End

				if @sColumn =  'CaseReference'
					Set @sTableColumn=' C.CaseReference ' 
				
				if @sColumn = 'NextReminderDate'
					Set @sTableColumn='AX.ALERTDATE'					
				 
				 if @sColumn = 'PropertyTypeDescription'
				 begin
					Set @sTableColumn=' C.PropertyTypeDescription '
				 end

				  if @sColumn = 'CaseTypeDescription'
				 begin
					Set @sTableColumn=' C.CaseTypeDescription '
				 end
				 			
				 if @sColumn = 'CountryName'
				 begin
					Set @sTableColumn=' C.CountryName '
				 end

				 if @sColumn = 'StatusDescription'
				 begin
					Set @sTableColumn=' C.StatusDescription ' 
				 end

				if @sColumn = 'StatusKey'
				begin
				Set @sTableColumn='C.STATUSKEY'					
				end

				  if @sColumn = 'CurrentOfficialNumber'
			      begin
					 Set @sTableColumn=' C.CurrentOfficialNumber ' 
				  end

				  if @sColumn = 'TypeOfMarkDescription'
				  begin
					Set @sTableColumn=' C.TypeOfMarkDescription ' 
				  end
				 
				  If @sColumn='IsAdHoc'
				  Begin					
						Set @sTableColumn=' CASE WHEN (AX.EMPLOYEENO is not null) THEN cast(1 as bit) ELSE cast(0 as bit) END '
				  End		

				  if @sColumn = 'DueDate'
				  Begin
						Set @sTableColumn='AX.DUEDATE' 
				  End
				  
				  if @sColumn = 'IsDueDateToday'
				  Begin
						Set @sTableColumn = 'CASE WHEN (Convert(date, CAST(AX.DUEDATE as Date)) = Convert(date, GETDATE())) THEN cast(1 as bit) ELSE cast(0 as bit) END'
				  End

   				  if @sColumn = 'IsDueDatePast'
				  Begin
						Set @sTableColumn = 'CASE WHEN (Convert(date, CAST(AX.DUEDATE as Date)) < Convert(date, GETDATE())) THEN cast(1 as bit) ELSE cast(0 as bit) END'
				  End
			  
				  if @sColumn = 'Owner'
					begin
						Set @sTableColumn=' C.Owner ' 
					end
					if @sColumn = 'OwnerKey'
					begin
						Set @sTableColumn=' C.OwnerKey ' 					
					end

					if @sColumn = 'StaffMember'
					begin
						Set @sTableColumn = ' C.StaffMember '						
					end

					if @sColumn = 'Signatory'
					begin
						Set @sTableColumn = ' C.Signatory '
					end

					if @sColumn = 'Instructor'
					begin
						Set @sTableColumn = ' C.Instructor '
					end

					if @sColumn = 'InstructorKey'
					begin
						Set @sTableColumn = ' C.InstructorKey '
					end

					if @sColumn = 'Owners'
					begin
						Set @sTableColumn = ' C.Owners '
					end

					if @sColumn = 'StaffMemberKey'
					begin
						Set @sTableColumn='C.StaffMemberKey' 						
					end

					if @sColumn = 'SignatoryKey'
					begin
						Set @sTableColumn='C.SignatoryKey' 
					end

					
					if @sColumn = 'CaseTypeKey'
					begin
					Set @sTableColumn= 'C.CaseTypeKey'					
					end

					if @sColumn = 'PropertyTypeKey'
					begin
					Set @sTableColumn= 'C.PropertyTypeKey'					
					end

					if @sColumn in ('CountryKey', 'CountryCode')
					begin
					Set @sTableColumn= 'C.CountryKey'					
					end

				  if @sColumn = 'EventDescription'
				  Begin
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ALERT','ALERTMESSAGE',null,'AX',@sLookupCulture,@pbCalledFromCentura)						
				  End	
				  
				  If @sColumn in ('ImportanceDescription')
				  Begin
					  Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'IMPC',@sLookupCulture,@pbCalledFromCentura)
					  If charindex('left join IMPORTANCE IMPC',@psAdHocDatesFrom)=0	
					  Begin
						Set @psAdHocDatesFrom = @psAdHocDatesFrom+char(10)+'left join IMPORTANCE IMPC	with (NOLOCK) on (IMPC.IMPORTANCELEVEL = AX.IMPORTANCELEVEL)'
					  End						
				  End
				  
				 If @sColumn = 'ImportanceLevelKey'
				 Begin
					Set @sTableColumn="IMPC.IMPORTANCELEVEL"					
				 End
				  
				if @sColumn in ('ReminderDate', 'TaskPlannerRowKey', 'ShowReminderComments', 'IsRead')
				 Begin					
			  		If @sColumn = 'ReminderDate'
					 Begin
			  			Set @sTableColumn=' ER.REMINDERDATE ' 
					 End

					If @sColumn = 'TaskPlannerRowKey'
					Begin
						Set @sTableColumn="'A' + '^'+"									
									+char(10)+"ISNULL(cast(AX.ID as varchar(25)),'') + '^' +"
									+char(10)+"ISNULL(cast(ER.ID as varchar(25)),'')"
					End

					If @sColumn = 'IsRead'
					Begin
						Set @sTableColumn= "CAST(ISNULL(ER.READFLAG, 1) as bit)"
					End

					If @sColumn = 'ShowReminderComments'
					Begin					
			  			Set @sTableColumn=' case when ER.EMPLOYEENO is null then cast(0 as bit) else cast(1 as bit) end '
					End

					If CHARINDEX('EMPLOYEEREMINDER ER', @psAdHocDatesFrom) = 0
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

				 End	
		

				if @sColumn = 'ReminderFor'
				begin
									
					Set @sTableColumn= 'dbo.fn_FormatNameUsingNameNo(ERN.NAMENO, null)'	

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
									
					set @psAdHocDatesFrom = @psAdHocDatesFrom  + ' left join NAME ERN WITH (NOLOCK)	on (ERN.NAMENO=ER.EMPLOYEENO) ' + char(10)	
				end

				if @sColumn = 'ReminderForNameKey'
				begin
					Set @sTableColumn= 'ERN.NAMENO'	
				end

				if @sColumn = 'HasInstructions'
				begin					
					Set @sTableColumn= 'cast(0 as bit)'	
				end
				  If datalength(@sPublishName)>0
					Begin
							Set @psAdHocDatesSelect=@psAdHocDatesSelect+nullif(',', ',' + @psAdHocDatesSelect)+@sTableColumn+' as ['+@sPublishName+']'					
					End
				  Else 
					Begin
						Set @sPublishName=NULL
					End
			 End
		End
		
		If @nOrderPosition>0
		Begin
			Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, isnull(@sOrderDirection, 'A'))

			Set @nErrorCode = @@ERROR
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1	
End

if @nErrorCode = 0 and 
	Not Exists( Select 1 from @tbOrderBy)
Begin
	Select	@nColumnNo 		= ROWNUMBER,
		@sColumn   		= ID,
		@sPublishName 		= PUBLISHNAME,		
		@sOrderDirection	= CASE WHEN SORTORDER > 0 THEN SORTDIRECTION
							  ELSE NULL END,
		@sQualifier		= QUALIFIER,
		@sProcedureName		= PROCEDURENAME
	from	@tblOutputRequests
	where	ROWNUMBER = 1

	If @sColumn is not null
	Begin
		Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
				values(1, @sTableColumn, @sPublishName, @nColumnNo, isnull(@sOrderDirection, 'A'))
	End

	Set @nErrorCode = @@ERROR
End

/****    CONSTRUCTION OF THE ORDER BY       ****/

If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @psTaskPlannerOrderBy = 	ISNULL(NULLIF(@psTaskPlannerOrderBy+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position			

		If @psTaskPlannerOrderBy is not null
		Begin
			Set @psTaskPlannerOrderBy = ' Order by ' + @psTaskPlannerOrderBy
		End				

	Set @nErrorCode=@@Error
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_ConstructTaskPlannerSelect  to public
GO