-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_TaskPlanner
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_TaskPlanner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ipw_TaskPlanner.'
	drop procedure dbo.ipw_TaskPlanner
End
print '**** Creating procedure dbo.ipw_TaskPlanner...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE PROCEDURE dbo.ipw_TaskPlanner
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 970, 	-- The key for the context of the query (default output requests).	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0,
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)	
AS
-- PROCEDURE :	ipw_TaskPlanner
-- VERSION :	9
-- DESCRIPTION:	Returns the requested information, for task planner that match the filter criteria provided.  
--		Due Dates may be related to case events, or to ad hoc reminders or to staff reminders. 
-- MODIFICATIONS :
-- Date		Who	Number	Version		Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 10 Sep 2020  AK		DR-62511	1		Procedure created 
-- 22 Oct 2020  AK		DR-64541	2		Used ipw_ConstructTaskPlannerSelect and ipw_ConstructTaskPlannerWhere
-- 25 Nov 2020  AK		DR-65413	3		updated to include @psCTE_Cases,@psCTE_CasesFrom and @psCTE_CasesWhere
-- 10 Jan 2021  SW		DR-65753	4		Implemented export Tasks based on selected/deselected rowkeys
-- 22 Jan 2021  AK		DR-67293	5		fixed trucate of print statement
-- 08 Feb 2021	LS		DR-68237	6		Included CTE for accessing case names 
-- 10 Jun 2021	AK		DR-62197	7		Performance optimization
-- 21 Jun 2021	AK		DR-72547	8		Validate Performance of Task Planner against Client DB 
-- 20 Jul 2021	AK		DR-73394	9		Validate Performance of Task Planner against Client DB  - phase 2

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode			int = 0

-- Declare some constants
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

-- Declare Filter Variables	


Declare @idoc 				int	
Declare @bIsReminders			bit	
Declare @bIsDueDates			bit		
Declare @bIsAdHocDates			bit

Declare @sSQLString				nvarchar(max)
Declare @sRemindersSelect		nvarchar(max)
Declare @sRemindersFrom			nvarchar(max)
Declare @sRemindersWhere		nvarchar(max)	

Declare @sDueDatesSelect		nvarchar(max)
Declare @sDueDatesFrom			nvarchar(max)
Declare @sDueDatesWhere			nvarchar(max)	

Declare @sAdHocDatesSelect		nvarchar(max)
Declare @sAdHocDatesFrom		nvarchar(max)
Declare @sAdHocDatesWhere		nvarchar(max)

Declare @sTaskPlannerRemindersSql nvarchar(max)
Declare @sTaskPlannerRemindersSql1 nvarchar(max)
Declare @sTaskPlannerDueDatesSql nvarchar(max)
Declare @sTaskPlannerDueDatesSql1 nvarchar(max)
Declare @sTaskPlannerAdhocDatesSql nvarchar(max)
Declare @sTaskPlannerAdhocDatesSql1 nvarchar(max)
Declare @sTaskPlannerOrderBy       nvarchar(max)

Declare	@sOpenWrapper			nvarchar(1000)
Declare @sCloseWrapper			nvarchar(max)
Declare @sCountSelect			nvarchar(1000)

declare @sCTE_Cases nvarchar(max)
declare @sCTE_CasesFrom nvarchar(max)
declare @sCTE_CasesWhere nvarchar(max)
declare @sCTE_CasesSelect nvarchar(max)

declare @sCTE_CaseEvent nvarchar(max)
declare @sCTE_CaseEventSelect nvarchar(max)
declare @sCTE_CaseEventWhere nvarchar(max)

declare @sCTE_CaseName nvarchar(max)
declare @sCTE_CaseNameFrom nvarchar(max)
declare @sCTE_CaseNameWhere nvarchar(max)
declare @sCTE_CaseNameSelect nvarchar(max)
declare @sCTE_CaseNameGroup nvarchar(max)

declare @sCTE_CaseDetails nvarchar(max)
declare @sCTE_CaseDetailsFrom nvarchar(max)
declare @sCTE_CaseDetailsWhere nvarchar(max)
declare @sCTE_CaseDetailsSelect nvarchar(max)

declare @bUseTempTables bit
declare @sPopulateTempCaseTableSql nvarchar(max)
declare @sPopulateTempCaseIdTableSql nvarchar(max)

declare @sRowKeys		varchar(max)
declare @nRowKeysOperator		tinyint

declare @idocRowKeys		int

Set	@CommaString			= 'CS'

exec sp_xml_preparedocument	@idocRowKeys OUTPUT, @ptXMLFilterCriteria

If @nErrorCode = 0 
Begin

	-- Retrieve the rowkeys elements using element-centric mapping
	Set @sSQLString = "Select @sRowKeys		= RowKeys,"+CHAR(10)+	
	"	@nRowKeysOperator					= RowKeysOperator"+CHAR(10)+
	"	from	OPENXML (@idocRowKeys, '/ipw_TaskPlanner/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      RowKeys			varchar(max)		'RowKeys/text()',"+CHAR(10)+
	"	      RowKeysOperator		tinyint		'RowKeys/@Operator/text()'"+CHAR(10)+
    "     	)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idocRowKeys				int,
				  @sRowKeys			varchar(max)			output,
				  @nRowKeysOperator		tinyint			output',
				  @idocRowKeys				= @idocRowKeys,
				  @sRowKeys			= @sRowKeys		output,
				  @nRowKeysOperator		= @nRowKeysOperator	output
	
End

	-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = "Select " + char(10) +
	"	@bIsReminders			= IsReminders,"+CHAR(10)+
	"	@bIsDueDates			= IsDueDates,"+CHAR(10)+
	"	@bIsAdHocDates			= IsAdHocDates"+CHAR(10)+	
	"from	OPENXML (@idoc, '/ipw_TaskPlanner/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+	
	"	      IsReminders			bit		'Include/IsReminders',"+CHAR(10)+
	"	      IsDueDates			bit		'Include/IsDueDates',"+CHAR(10)+
	"	      IsAdHocDates			bit		'Include/IsAdHocDates'"+CHAR(10)+	
    "     		)"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,				 			
				  @bIsReminders			bit			output,
				  @bIsDueDates			bit			output,
				  @bIsAdHocDates				bit			output',
				  @idoc				= @idoc,				 
				  @bIsReminders				=  @bIsReminders	output,
				  @bIsDueDates			=  @bIsDueDates			output,
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
	End
End

/****    CONSTRUCTION OF SELECT AND ORDER BY   ****/

	If @nErrorCode = 0
	Begin
		Exec @nErrorCode = ipw_ConstructTaskPlannerSelect
			@pnUserIdentityId=@pnUserIdentityId,
			@psCulture= @psCulture, 
			@ptXMLOutputRequests=@ptXMLOutputRequests, 
			@ptXMLFilterCriteria=@ptXMLFilterCriteria,	
			@pbCalledFromCentura=@pbCalledFromCentura,
			@pnQueryContextKey=@pnQueryContextKey,	
			@psCTE_Cases =@sCTE_Cases output,
			@psCTE_CasesFrom =@sCTE_CasesFrom output,
			@psCTE_CasesWhere= @sCTE_CasesWhere output,
			@psCTE_CasesSelect = @sCTE_CasesSelect output,
			@psCTE_CaseName =@sCTE_CaseName output,
			@psCTE_CaseNameFrom =@sCTE_CaseNameFrom output,
			@psCTE_CaseNameWhere= @sCTE_CaseNameWhere output,
			@psCTE_CaseNameSelect = @sCTE_CaseNameSelect output,
			@psCTE_CaseNameGroup = @sCTE_CaseNameGroup output,
			@psCTE_CaseDetails= @sCTE_CaseDetails output,
			@psCTE_CaseDetailsFrom=@sCTE_CaseDetailsFrom output,
			@psCTE_CaseDetailsWhere= @sCTE_CaseDetailsWhere output,
			@psCTE_CaseDetailsSelect=@sCTE_CaseDetailsSelect output,
			@psRemindersSelect=@sRemindersSelect output,
			@psRemindersFrom=@sRemindersFrom output,
			@psRemindersWhere=@sRemindersWhere output,
			@psDueDatesSelect=@sDueDatesSelect output,
			@psDueDatesFrom=@sDueDatesFrom output,
			@psDueDatesWhere=@sDueDatesWhere output,
			@psAdHocDatesSelect=@sAdHocDatesSelect output,
			@psAdHocDatesFrom=@sAdHocDatesFrom output,
			@psAdHocDatesWhere=@sAdHocDatesWhere output,
			@psTaskPlannerOrderBy=@sTaskPlannerOrderBy output,
			@psPopulateTempCaseTableSql=@sPopulateTempCaseTableSql  output,
			@psPopulateTempCaseIdTableSql=@sPopulateTempCaseIdTableSql output,
			@pbUseTempTables = @bUseTempTables output,
			@psCTE_CaseEventSelect = @sCTE_CaseEventSelect output,
			@psCTE_CaseEventWhere = @sCTE_CaseEventWhere output
    End
	
/****    CONSTRUCTION OF THE WHERE  clause  ****/

If   @nErrorCode=0
Begin
	Exec @nErrorCode = ipw_ConstructTaskPlannerWhere
			@pnUserIdentityId=@pnUserIdentityId,
			@psCulture= @psCulture, 			
			@ptXMLFilterCriteria=@ptXMLFilterCriteria,	
			@pbCalledFromCentura=@pbCalledFromCentura,
			@pnQueryContextKey=@pnQueryContextKey,			
			@psCTE_CasesFrom =@sCTE_CasesFrom output,
			@psCTE_CasesWhere= @sCTE_CasesWhere output,
			@psCTE_CasesSelect = @sCTE_CasesSelect output,			
			@psCTE_CaseDetailsFrom=@sCTE_CaseDetailsFrom output,
			@psCTE_CaseDetailsWhere= @sCTE_CaseDetailsWhere output,
			@psCTE_CaseDetailsSelect=@sCTE_CaseDetailsSelect output,			
			@psRemindersFrom=@sRemindersFrom output,
			@psRemindersWhere=@sRemindersWhere output,			
			@psDueDatesFrom=@sDueDatesFrom output,
			@psDueDatesWhere=@sDueDatesWhere output,			
			@psAdHocDatesFrom=@sAdHocDatesFrom output,
			@psAdHocDatesWhere=@sAdHocDatesWhere output,
			@psCTE_CaseEventSelect = @sCTE_CaseEventSelect output,
			@psCTE_CaseEventWhere = @sCTE_CaseEventWhere output
End

If  @nErrorCode = 0
Begin
	-- Assemble the constructed SQL clauses:	
	set @sCTE_CaseDetailsSelect = 'select distinct '  + char(10)  + @sCTE_CaseDetailsSelect
	set @sRemindersSelect 		= 'Select distinct ' 	+ @sRemindersSelect
	set @sDueDatesSelect 		= 'Select distinct ' 	+ @sDueDatesSelect
	set @sAdHocDatesSelect 		= 'Select distinct ' 	+ @sAdHocDatesSelect
	set @sCTE_CaseEvent = ''

	set @sCTE_Cases = @sCTE_Cases + 
					  @sCTE_CasesSelect +
					  @sCTE_CasesFrom + 
					  @sCTE_CasesWhere + 
					  ')'
	
	set @sCTE_CaseName = @sCTE_CaseName + 
					  @sCTE_CaseNameSelect +
					  @sCTE_CaseNameFrom + 
					  @sCTE_CaseNameWhere + 
					  @sCTE_CaseNameGroup + 
					  ')'

	set @sCTE_CaseEvent = @sCTE_CaseEvent + 
						  @sCTE_CaseEventSelect +
						  @sCTE_CaseEventWhere +
						  ')'

	set @sCTE_CaseDetails = @sCTE_CaseDetails + 
							@sCTE_CaseDetailsSelect +
							@sCTE_CaseDetailsFrom +
							@sCTE_CaseDetailsWhere +
							') ' + char(10)
		
		set @sTaskPlannerRemindersSql = ''
		set @sTaskPlannerRemindersSql1 = ''
		set @sTaskPlannerDueDatesSql = ''
		set @sTaskPlannerDueDatesSql1 = ''
		set @sTaskPlannerAdhocDatesSql = ''
		set @sTaskPlannerAdhocDatesSql1 = ''

		if(@bIsReminders = 1)
		Begin	
			set @sTaskPlannerRemindersSql = @sTaskPlannerRemindersSql + @sRemindersSelect
			set @sTaskPlannerRemindersSql = @sTaskPlannerRemindersSql +  @sRemindersFrom			
			set @sTaskPlannerRemindersSql1 = @sTaskPlannerRemindersSql1 +  @sRemindersWhere
			
		End		
		if(@bIsDueDates = 1)
		Begin
			if(@bIsReminders = 1)
			Begin
			  set @sTaskPlannerDueDatesSql = @sTaskPlannerDueDatesSql +   ' UNION ' +  CHAR(10)
			End
			set @sTaskPlannerDueDatesSql = @sTaskPlannerDueDatesSql +   @sDueDatesSelect
			set @sTaskPlannerDueDatesSql = @sTaskPlannerDueDatesSql +   @sDueDatesFrom
			set @sTaskPlannerDueDatesSql1 = @sTaskPlannerDueDatesSql1 +   @sDueDatesWhere
		End

		if(@bIsAdHocDates = 1)
		Begin
		    if(@bIsReminders = 1 or @bIsDueDates = 1)
			Begin			
			  set @sTaskPlannerAdhocDatesSql = @sTaskPlannerAdhocDatesSql +   ' UNION ' +  CHAR(10)
			End
			set @sTaskPlannerAdhocDatesSql = @sTaskPlannerAdhocDatesSql + @sAdHocDatesSelect
			set @sTaskPlannerAdhocDatesSql = @sTaskPlannerAdhocDatesSql + @sAdHocDatesFrom
			set @sTaskPlannerAdhocDatesSql1 = @sTaskPlannerAdhocDatesSql1 + @sAdHocDatesWhere	
		End			
				
End

-- Assemble and execute the constructed SQL to return the result set
If  @nErrorCode = 0
-- No paging required
and (@pnPageStartRow is null or
     @pnPageEndRow is null)
Begin								
		
		If @pbPrintSQL = 1
		Begin			
				Print 'SET ANSI_NULLS OFF; ' 	
				print @sCTE_Cases
				print @sPopulateTempCaseIdTableSql
				print @sCTE_CaseEvent						
				print @sCTE_CaseName				
				print cast(@sCTE_CaseDetails as ntext)
			if @bUseTempTables = 1
			begin				
				print @sPopulateTempCaseTableSql
				print 'SET ANSI_NULLS OFF; ' 
			end
				print @sTaskPlannerRemindersSql
				print @sTaskPlannerRemindersSql1
				print @sTaskPlannerDueDatesSql
				print @sTaskPlannerDueDatesSql1
				print @sTaskPlannerAdhocDatesSql
				print @sTaskPlannerAdhocDatesSql1
				print @sTaskPlannerOrderBy
		End

	-- execute the constructed SQL:
	if @bUseTempTables = 1
		begin
		 		exec (	'SET ANSI_NULLS OFF; ' 
									   + @sCTE_Cases 									   
									   + @sPopulateTempCaseIdTableSql
									   + @sCTE_CaseEvent
									   + @sCTE_CaseName 
									   + @sCTE_CaseDetails 									   
									   + @sPopulateTempCaseTableSql			
										+ 'SET ANSI_NULLS OFF;'
									   + @sTaskPlannerRemindersSql 
									   + @sTaskPlannerRemindersSql1 
									   + @sTaskPlannerDueDatesSql 
									   + @sTaskPlannerDueDatesSql1
									   + @sTaskPlannerAdhocDatesSql
									   + @sTaskPlannerAdhocDatesSql1
									   + @sTaskPlannerOrderBy)
		end
	else
		begin
		 		exec (	'SET ANSI_NULLS OFF; ' + @sCTE_Cases 	
									   + @sPopulateTempCaseIdTableSql
									   + @sCTE_CaseEvent 
									   + @sCTE_CaseName 
									   + @sCTE_CaseDetails
									   + @sTaskPlannerRemindersSql 
									   + @sTaskPlannerRemindersSql1 
									   + @sTaskPlannerDueDatesSql 
									   + @sTaskPlannerDueDatesSql1
									   + @sTaskPlannerAdhocDatesSql
									   + @sTaskPlannerAdhocDatesSql1
									   + @sTaskPlannerOrderBy)
		end
	
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End
-- Paging required
Else If @nErrorCode = 0
Begin 

			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sTaskPlannerOrderBy+') as RowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as ResultSorted'+char(10)+
					     ') as ResultWithRow'+char(10)
					     --'where RowKey>='+cast(@pnPageStartRow as varchar)+' and RowKey<='+cast(@pnPageEndRow as varchar)

			IF ISNULL(@sRowKeys,'') = ''
				BEGIN
					Set @sCloseWrapper = @sCloseWrapper + 'where RowKey>='+cast(@pnPageStartRow as varchar)+' and RowKey<='+cast(@pnPageEndRow as varchar)
				END
			ELSE
				BEGIN
					Set @sCloseWrapper = @sCloseWrapper + 'where RowKey '+ dbo.fn_ConstructOperator(@nRowKeysOperator,@CommaString, @sRowKeys, null, @pbCalledFromCentura)
				END

	Set @sCountSelect = ' Select count(1) as SearchSetTotalRows'  		

	If @pbPrintSQL = 1
	Begin
			-- Print out the executed SQL statement:			
			Print 'SET ANSI_NULLS OFF; ' 
			print @sCTE_Cases
			print @sPopulateTempCaseIdTableSql
			print @sCTE_CaseEvent				
			print @sCTE_CaseName			
			print cast(@sCTE_CaseDetails as ntext)
		if @bUseTempTables = 1
			begin				
				print @sPopulateTempCaseTableSql
				print 'SET ANSI_NULLS OFF; ' 
			end
			print @sOpenWrapper
			print @sTaskPlannerRemindersSql
			print @sTaskPlannerRemindersSql1
			print @sTaskPlannerDueDatesSql
			print @sTaskPlannerDueDatesSql1
			print @sTaskPlannerAdhocDatesSql
			print @sTaskPlannerAdhocDatesSql1
			print @sCloseWrapper

	End

	-- execute the constructed SQL:
	if @bUseTempTables = 1
		begin
		 		exec (	'SET ANSI_NULLS OFF; ' + 
							@sCTE_Cases + 
							@sPopulateTempCaseIdTableSql +
							@sCTE_CaseEvent +							
							@sCTE_CaseName + 
							@sCTE_CaseDetails +
							@sPopulateTempCaseTableSql +
							'SET ANSI_NULLS OFF; ' +
							@sOpenWrapper +
							@sTaskPlannerRemindersSql + 
							@sTaskPlannerRemindersSql1 + 
							@sTaskPlannerDueDatesSql + 
							@sTaskPlannerDueDatesSql1 +
							@sTaskPlannerAdhocDatesSql +
							@sTaskPlannerAdhocDatesSql1 +
							@sCloseWrapper
						)
		end
	else
		begin
		 			exec (	'SET ANSI_NULLS OFF; ' + 
							@sCTE_Cases + 
							@sPopulateTempCaseIdTableSql +
							@sCTE_CaseEvent + 
							@sCTE_CaseName + 
							@sCTE_CaseDetails +
							@sOpenWrapper +
							@sTaskPlannerRemindersSql + 
							@sTaskPlannerRemindersSql1 + 
							@sTaskPlannerDueDatesSql + 
							@sTaskPlannerDueDatesSql1 +
							@sTaskPlannerAdhocDatesSql +
							@sTaskPlannerAdhocDatesSql1 +
							@sCloseWrapper
						)
		end
		
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT
			   
	 If @nErrorCode = 0
		Begin

			If @pbPrintSQL = 1
			Begin
				Print 'SET ANSI_NULLS OFF; ' 						
				print @sCTE_CaseName
				if @bUseTempTables = 0
				begin
					--print SUBSTRING(@sCTE_CaseDetails, 1, 4000) 
					--print SUBSTRING(@sCTE_CaseDetails, 4001, len(@sCTE_CaseDetails))
					print cast(@sCTE_CaseDetails as ntext)
				end
				Print @sCountSelect	+ ' from ( ' 	
				print @sTaskPlannerRemindersSql
				print @sTaskPlannerRemindersSql1
				print @sTaskPlannerDueDatesSql
				print @sTaskPlannerDueDatesSql1
				print @sTaskPlannerAdhocDatesSql
				print @sTaskPlannerAdhocDatesSql1
				print ') Records'
			End

			if @bUseTempTables = 1
			begin
		 			exec (	'SET ANSI_NULLS OFF; ' + 						
							@sCTE_CaseName + 						
							@sCountSelect + ' from (' +
							@sTaskPlannerRemindersSql + 
							@sTaskPlannerRemindersSql1 + 
							@sTaskPlannerDueDatesSql + 
							@sTaskPlannerDueDatesSql1 + 
							@sTaskPlannerAdhocDatesSql +
							@sTaskPlannerAdhocDatesSql1 +
							') Records'
				)
			end
		else
			begin
		 				exec (	'SET ANSI_NULLS OFF; ' + 													
							@sCTE_CaseName + 
							@sCTE_CaseDetails +							
							@sCountSelect + ' from (' +
							@sTaskPlannerRemindersSql + 
							@sTaskPlannerRemindersSql1 + 
							@sTaskPlannerDueDatesSql + 
							@sTaskPlannerDueDatesSql1 + 
							@sTaskPlannerAdhocDatesSql +
							@sTaskPlannerAdhocDatesSql1 +
							') Records'
				)
			end
			
			Select 	@nErrorCode =@@ERROR
		End
	
End

RETURN @nErrorCode
GO

Grant execute on dbo.ipw_TaskPlanner  to public
GO