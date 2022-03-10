-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ListCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ListCase.'
	drop procedure dbo.cs_ListCase
	print '**** Creating procedure dbo.cs_ListCase...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_ListCase
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbProduceResultSet		bit		= 1,	-- if TRUE, a result set is published; if FALSE the results are held internally awaiting the next of multiple calls to the sp.
	@psBuildOperator		nvarchar(3)	= 'AND',-- may contain any of the values "and", "OR", "NOT"	
	@psColumnIds			nvarchar(4000)	= 'CaseKey^CaseReference', -- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000)	= null,	-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000)	= 'Key^IRN',	-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000)	= '^1',	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000)	= '^A',	-- list that indicates the direction for the sort of each column included in the Order By
	@psAnySearch			nvarchar(20)	= null,	-- a generic search string used to search a number of Case columns
	@pnCaseKey			int		= null,	-- the CaseId of the Case
	@psPickListSearch		nvarchar(50)	= null, -- the text entered by a user in a picklist field to located appropriate entries
	@psCaseReference		nvarchar(30)	= null, -- if partial, a "%" character is present
	@pnCaseReferenceOperator	tinyint		= null,
	@pbWithinFileCover		bit		= 0,	-- if TRUE, select both the @psCaseReference Case, and any Cases where the @psCaseReference case is defined as the FileCover. @psCaseReference is never partial in this context.
	@psOfficialNumber		nvarchar(36)	= null, -- if partial a"%" character is present.  Used in conjunction with @psNumberTypeKey if supplied, but will search for Cases with any number types with this number.
	@pnOfficialNumberOperator	tinyint		= null,
	@psNumberTypeKey		nvarchar(3)	= null,	-- used in conjunction with @psOfficialNumber if supplied, but will search for Cases with any official number of this type.	@psRelatedOfficialNumber 	nvarchar(40)	= null,	-- the official number of a related case.  if partial, a "%" character is present.
	@pnNumberTypeKeyOperator	tinyint		= null,
	@psRelatedOfficialNumber 	nvarchar(36)	= null,	-- the official number of a related case.  if partial, a "%" character is present.
	@pnRelatedOfficialNumberOperator tinyint	= null,
	@psCaseTypeKey			nchar(1)	= null,	-- Include/Exclude based on next parameter
	@pnCaseTypeKeyOperator		tinyint 	= 0,
	@psCountryCodes			nvarchar(1000)	= null,	-- A comma separated list of Country Codes.
	@pnCountryCodesOperator		tinyint		= null,	
	@pbIncludeDesignations		bit		= 0,
	@psPropertyTypeKey		nchar(1)	= null,	-- Include/Exclude based on next parameter
	@pnPropertyTypeKeyOperator	tinyint		= 0,
	@psCategoryKey			nvarchar(2)	= null,	-- Include/Exclude based on next parameter
	@pnCategoryKeyOperator		tinyint		= 0,
	@psSubTypeKey			nvarchar(2)	= null,	-- Include/Exclude based on next parameter
	@pnSubTypeKeyOperator		tinyint		= 0,
	@psClasses			nvarchar(1000)	= null,	-- to be determined later
	@pnClassesOperator		tinyint		= null,
	@psKeyWord			nvarchar(50)	= null,
	@pnKeywordOperator		tinyint		= null,
	@psFamilyKey			nvarchar(20)	= null,
	@pnFamilyKeyOperator		tinyint		= null,
	@psTitle			nvarchar(254)	= null,	-- if partial, a "%" character is present.  The search should be case independent
	@pnTitleOperator		tinyint		= null,
	@pnTypeOfMarkKey		int		= null,	-- Include/Exclude based on next parameter
	@pnTypeOfMarkKeyOperator	tinyint		= null,
	@pnInstructionKey		int		= null,	-- applies only to instructions held against the Case (not inherited from the Case's Names)
	@pnInstructionKeyOperator	tinyint		= null,
	@psInstructorKeys		nvarchar(4000)	= null,	-- A comma separated list of Instructor NameKeys
	@pnInstructorKeysOperator	tinyint		= null,
	@psAttentionNameKeys		nvarchar(4000)	= null,	-- A comma separated list of NameKeys that appear as the correspondence name on any CaseName record for the Case.
	@pnAttentionNameKeysOperator	tinyint		= null,
	@psNameKeys			nvarchar(4000)	= null,	-- A comma separated list of NameKeys. Used in conjunction with @psNameTypeKey if supplied.
	@pnNameKeysOperator		tinyint		= null,
	@psNameTypeKey			nvarchar(3)	= null,	-- Used in conjunction with @psNameKeys if supplied, but will search for Cases where any names exists with the name type otherwise.
	@pnNameTypeKeyOperator		tinyint		= null,
	@psSignatoryNameKeys		nvarchar(4000)	= null,	-- A comma separated list of NameKeys that act as NameType Signatory for the case.
	@pnSignatoryNameKeysOperator	tinyint		= null,
	@psStaffNameKeys		nvarchar(4000)	= null,	-- A comma separated list of NameKeys that act as Name Type Responsible Staff for the case.
	@pnStaffNameKeysOperator	tinyint		= null,
	@psReferenceNo			nvarchar(80)	= null, -- A referenence number associated with a Name/Case
	@pnReferenceNoOperator		tinyint		= null,
	@pnEventKey			int		= null,
	@pbSearchByDueDate		bit		= 0,
	@pbSearchByEventDate		bit		= 0,
	@pnEventDateOperator		tinyint		= null,
	@pdtEventFromDate		datetime	= null,
	@pdtEventToDate			datetime	= null,
	@pnDeadlineEventKey		int		= null,
	@pnDeadlineEventDateOperator	tinyint		= null,
	@pdtDeadlineEventFromDate	datetime	= null,
	@pdtDeadlineEventToDate		datetime	= null,
	@pnStatusKey			int		= null,	-- if supplied, @pbPending, @pbRegistered and @pbDead are ignored.
	@pnStatusKeyOperator		tinyint		= null,
	@pbPending			bit		= 0,	-- if TRUE, any cases with a status that is Live but not registered
	@pbRegistered			bit		= 0,	-- if TRUE, any cases with a status that is both Live and Registered
	@pbDead				bit		= 0,	-- if TRUE, any Cases with a status that is not Live.
	@pbRenewalFlag			bit		= 0,
	@pbLettersOnQueue		bit		= 0,
	@pbChargesOnQueue		bit		= 0,
	@pnAttributeTypeKey1		int		= null,
	@pnAttributeKey1		int		= null,
	@pnAttributeKey1Operator	tinyint		= null,
	@pnAttributeTypeKey2		int		= null,
	@pnAttributeKey2		int		= null,
	@pnAttributeKey2Operator	tinyint		= null,
	@pnAttributeTypeKey3		int		= null,
	@pnAttributeKey3		int		= null,
	@pnAttributeKey3Operator	tinyint		= null,
	@pnAttributeTypeKey4		int		= null,
	@pnAttributeKey4		int		= null,
	@pnAttributeKey4Operator	tinyint		= null,
	@pnAttributeTypeKey5		int		= null,
	@pnAttributeKey5		int		= null,
	@pnAttributeKey5Operator	tinyint		= null,
	@psTextTypeKey1			nvarchar(2)	= null,
	@psText1			nvarchar(4000)	= null,
	@pnText1Operator		tinyint		= null,
	@psTextTypeKey2 		nvarchar(2)	= null,
	@psText2			nvarchar(4000)	= null,
	@pnText2Operator		tinyint		= null,
	@psTextTypeKey3			nvarchar(2)	= null,
	@psText3			nvarchar(4000)	= null,
	@pnText3Operator		tinyint		= null,
	@psTextTypeKey4			nvarchar(2)	= null,
	@psText4			nvarchar(4000)	= null,
	@pnText4Operator		tinyint		= null,
	@psTextTypeKey5			nvarchar(2)	= null,
	@psText5			nvarchar(4000)	= null,
	@pnText5Operator		tinyint		= null,
	@psTextTypeKey6			nvarchar(2)	= null,
	@psText6			nvarchar(4000)	= null,
	@pnText6Operator		tinyint		= null,
	@psTextTypeKey7			nvarchar(2)	= null, -- RFC421
	@psText7			nvarchar(4000)	= null,
	@pnText7Operator		tinyint		= null,
	@pnQuickIndexKey		int		= null,
	@pnQuickIndexKeyOperator	tinyint		= null,
	@pnOfficeKey			int		= null,
	@pnOfficeKeyOperator	        tinyint		= null
)	
-- PROCEDURE :	cs_ListCase
-- VERSION :	31
-- DESCRIPTION:	Lists Cases that match the selection parameters.
-- CALLED BY :	

-- Modifications
-- =============
-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 12/03/2002	SF			Procedure created
-- 09/05/2002	SF			Cater for multiple case search.
-- 20/06/2002	MF			Complete filtering
-- 26/07/2002	MF			Add new parameters to support the CPA.NET interface.
-- 15/08/2002	SF			Add @pnQuickIndexKey to support quick index.
-- 02/09/2002	MF			Add new parameters @psColumnIds, @psColumnQualifiers, @psPublishColumnNames, 
--					@psSortOrderList @psSortDirectionList to control the columns and the order
--					of the rows to be returned.
-- 20/09/2002	MF		0.6	Additional search parameters added
-- 24/09/2002	MF			Provide a default for the list of columns to display
-- 06/11/2002	MF		7	Move the PickListSearch stage search out of the fn_FilterCase so that
--					the search can also use constructed filter.  This cannot be done in the
--					function because dynamically constructed SQL cannot be executed.
-- 19 Nov 2002	JB		19	Moved the comment sectiuon to the top so version number can be detected
-- 11-Apr-2003	JEK	RFC13	20	Changed @sFrom to varchar(8000)
-- 17 Jul 2003	TM	RFC76	21	Case Insensitive searching
-- 12 Aug 2003	TM	RFC224	22	Office level rules. Add @pnOfficeKey and @pnOfficeKeyOperator parameters
--					and pass them to the fn_FilterCases.
-- 20 Aug 2003	TM	RFC40	23      Case List SQL exceeds max size. Replace @sFrom varchar(8000) with the 
--					@sFrom1 nvarchar(4000) and @sFrom2 nvarchar(4000) and pass them to cs_ConstructCaseSelect 
--					instead of the @sFrom varchar(8000). Also replace @sFrom with @sFrom1 and @sFrom2 when 
--					execute the constructed SQL to return the result set and when execute the constructed SQL 
--					to return the combined result set.
-- 15 Sep 2003	TM	RFC421	24	Field Names in Search Screens not consistent. Implement new parameters:@psTextTypeKey7,
--					@psText7 (mapped to 'Title') and @pnText7Operator. Pass these parameters in the fn_FilterCases. 
--  6 Nov 2003	MF	RFC586	25	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 23 Jul 2004	TM	RFC1610	26	Increase the datasize of the @psReferenceNo parameter from nvarchar(50) to nvarchar(80).	
-- 02 Sep 2004	JEK	RFC1377	27	Pass new Centura parameter to fn_WrapQuotes
-- 17 Dec 2004	TM	RFC1674	28	Remove the UPPER function around the IRN to increase performance.
-- 11 Jul 2005	TM	RFC2329	29	Increase the size of all case category parameters and local variables to 2 characters.
-- 07 Sep 2018	AV	74738	30	Set isolation level to read uncommited.
-- 19 May 2020	DL	DR-58943	31	Ability to enter up to 3 characters for Number type code via client server	


AS

	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	declare @ErrorCode		int

	declare @nTableCount		tinyint
	
	declare @sCurrentTable 		nvarchar(50)	
	declare @sCopyTable 		nvarchar(50)	

	declare @bTempTableExists	bit
	declare	@bExternalUser		bit
	declare @pbExists		bit

	declare @sSql			nvarchar(4000)
	declare @sSQLString		nvarchar(4000)
	declare @sSelectList		nvarchar(4000)  -- the SQL list of columns to return
	declare	@sFrom1			nvarchar(4000)	-- the SQL to list tables and joins
	declare	@sFrom2			nvarchar(4000)
	declare @sWhere			nvarchar(4000) 	-- the SQL to filter
	declare @sOrder			nvarchar(1000)	-- the SQL sort order
	declare	@sCaseFilter		nvarchar(4000)	-- the FROM and WHERE for the Case Filter


	set @ErrorCode=0

	set @psPickListSearch = upper(@psPickListSearch) -- Case Insensitive searching

	set @sCurrentTable = '##SEARCHCASE_' + Cast(@@SPID as nvarchar(30))
	set @sCopyTable    = '##COPYCASEID_' + Cast(@@SPID as nvarchar(30))


	-- Determine if the temporary table holding previous results exists

	if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable )
		set @bTempTableExists=1
	else
		set @bTempTableExists=0

	-- Check if the result set is to be returned

	if @pbProduceResultSet = 0
	begin
		-- If no results are being returned at this time then we need to create
		-- a temporary table to store the results if it has not been created already
		-- or we needed to create a second temporary table to hold the previous results
		-- so the main table can be loaded with the new query results
  
		if (@bTempTableExists = 0)
		begin
			-- create the ##SEARCHCASE table
			Set @sSql = 'Create Table ' + @sCurrentTable + ' (CASEID int)'
		end
		else begin
 			-- create the intermediate ##COPYCASEID table
			Set @sSql = 'Create Table ' + @sCopyTable + ' (CASEID int)'
		end

		exec @ErrorCode=sp_executesql @sSql

		-- the statements above will prepare the temptable needed for this query	
		Set @sSelectList = 'Insert into ' + @sCurrentTable + '(CASEID) select XC.CASEID'
	end
	else begin
		exec @ErrorCode=dbo.cs_ConstructCaseSelect	@sSelectList	OUTPUT,
								@sFrom1		OUTPUT,
								@sFrom2		OUTPUT,
								@sWhere		OUTPUT,
								@sOrder		OUTPUT,
								@nTableCount	OUTPUT,
								@psColumnIds,
								@psColumnQualifiers,
								@psPublishColumnNames,
								@psSortOrderList,
								@psSortDirectionList,
								@bExternalUser

	End
	
	-- ACTUAL CASE SEARCH SQL BUILDING BEGINS
	-- now prepair the sql with the available filters specified.

	-- A user defined function is used to construct the FROM and WHERE clauses
	-- used to filter what Cases are to be returned
	if @ErrorCode=0
	begin
		set @sCaseFilter=dbo.fn_FilterCases(
			@pnUserIdentityId,
			@psAnySearch,
			@pnCaseKey,
			@psCaseReference,
			@pnCaseReferenceOperator,
			@pbWithinFileCover,
			@psOfficialNumber,
			@pnOfficialNumberOperator,
			@psNumberTypeKey,
			@pnNumberTypeKeyOperator,
			@psRelatedOfficialNumber,
			@pnRelatedOfficialNumberOperator,
			@psCaseTypeKey,
			@pnCaseTypeKeyOperator,
			@psCountryCodes,
			@pnCountryCodesOperator,
			@pbIncludeDesignations,
			@psPropertyTypeKey,
			@pnPropertyTypeKeyOperator,
			@psCategoryKey,
			@pnCategoryKeyOperator,
			@psSubTypeKey,
			@pnSubTypeKeyOperator,
			@psClasses,
			@pnClassesOperator,
			@psKeyWord,
			@pnKeywordOperator,
			@psFamilyKey,
			@pnFamilyKeyOperator,
			@psTitle,
			@pnTitleOperator,
			@pnTypeOfMarkKey,
			@pnTypeOfMarkKeyOperator,
			@pnInstructionKey,
			@pnInstructionKeyOperator,
			@psInstructorKeys,
			@pnInstructorKeysOperator,
			@psAttentionNameKeys,
			@pnAttentionNameKeysOperator,
			@psNameKeys,
			@pnNameKeysOperator,
			@psNameTypeKey,
			@pnNameTypeKeyOperator,
			@psSignatoryNameKeys,
			@pnSignatoryNameKeysOperator,
			@psStaffNameKeys,
			@pnStaffNameKeysOperator,
			@psReferenceNo,
			@pnReferenceNoOperator,
			@pnEventKey,
			@pbSearchByDueDate,
			@pbSearchByEventDate,
			@pnEventDateOperator,
			@pdtEventFromDate,
			@pdtEventToDate,
			@pnDeadlineEventKey,
			@pnDeadlineEventDateOperator,
			@pdtDeadlineEventFromDate,
			@pdtDeadlineEventToDate,
			@pnStatusKey,
			@pnStatusKeyOperator,
			@pbPending,
			@pbRegistered,
			@pbDead,
			@pbRenewalFlag,
			@pbLettersOnQueue,
			@pbChargesOnQueue,
			@pnAttributeTypeKey1,
			@pnAttributeKey1,
			@pnAttributeKey1Operator,
			@pnAttributeTypeKey2,
			@pnAttributeKey2,
			@pnAttributeKey2Operator,
			@pnAttributeTypeKey3,
			@pnAttributeKey3,
			@pnAttributeKey3Operator,
			@pnAttributeTypeKey4,
			@pnAttributeKey4,
			@pnAttributeKey4Operator,
			@pnAttributeTypeKey5,
			@pnAttributeKey5,
			@pnAttributeKey5Operator,
			@psTextTypeKey1,
			@psText1,
			@pnText1Operator,
			@psTextTypeKey2,
			@psText2,
			@pnText2Operator,
			@psTextTypeKey3,
			@psText3,
			@pnText3Operator,
			@psTextTypeKey4,
			@psText4,
			@pnText4Operator,
			@psTextTypeKey5,
			@psText5,
			@pnText5Operator,
			@psTextTypeKey6,
			@psText6,
			@pnText6Operator,
			@psTextTypeKey7,
			@psText7, 
			@pnText7Operator,
			@pnQuickIndexKey,
			@pnQuickIndexKeyOperator,
			@pnOfficeKey,
			@pnOfficeKeyOperator)
	end

	-- 05/11/2002 MF
	-- If the PickListSearch is being used then the value within the @psPickListSearch parameter
	-- is to be combined with the other filter parameters and a staged search is to be performed.
	-- The staged search is to combine the CaseFilter details and first search on :
	-- 1) an exact IRN match
	-- 2) an inexact IRN starting with the parameter
	-- 3) an exact Official Number
	-- 4) an inexact Official Number starting with the parameter.

	If @psPickListSearch is not null
	Begin
		-- Check for exact match on IRN

		set @pbExists=0
		set @sSQLString="Select @pbExists=1"+char(10)+
				"from CASES C"+char(10)+
				"where C.IRN="+dbo.fn_WrapQuotes(@psPickListSearch,0,0)+char(10)+
				"and exists"+char(10)+
				"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"

		exec sp_executesql @sSQLString,
				N'@pbExists		bit	OUTPUT',
				  @pbExists=@pbExists		OUTPUT

		If @pbExists=1
		Begin
			set @sCaseFilter=@sCaseFilter+char(10)+"	and XC.IRN='"+@psPickListSearch+"'"
		End
		Else Begin
			-- Check for partial match on IRN

			set @sSQLString="Select @pbExists=1"+char(10)+
					"from CASES C"+char(10)+
					"where C.IRN like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)+char(10)+
					"and exists"+char(10)+
					"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"

			exec sp_executesql @sSQLString,
					N'@pbExists		bit	OUTPUT',
					  @pbExists=@pbExists		OUTPUT
	
			If @pbExists=1
			Begin
				set @sCaseFilter=@sCaseFilter+char(10)+"	and XC.IRN like '"+@psPickListSearch+"%'"
			End
			Else Begin
				-- Check for exact match on Official Number

				set @sSQLString="Select @pbExists=1"+char(10)+
						"from CASES C"+char(10)+
						"join OFFICIALNUMBERS O on (O.CASEID=C.CASEID)"+char(10)+
						"where upper(O.OFFICIALNUMBER)="+dbo.fn_WrapQuotes(@psPickListSearch,0,0)+char(10)+
						"and exists"+char(10)+
						"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"

				exec sp_executesql @sSQLString,
						N'@pbExists		bit	OUTPUT',
						  @pbExists=@pbExists		OUTPUT

				set @sCaseFilter=replace(@sCaseFilter,'CASES XC','CASES XC'+char(10)+'	join OFFICIALNUMBERS XO on (XO.CASEID=XC.CASEID)')
		
				If @pbExists=1
				Begin
					set @sCaseFilter=@sCaseFilter+char(10)+"	and upper(XO.OFFICIALNUMBER)="+dbo.fn_WrapQuotes(@psPickListSearch,0,0)
				End
				Else Begin
					set @sCaseFilter=@sCaseFilter+char(10)+"	and upper(XO.OFFICIALNUMBER) like "+dbo.fn_WrapQuotes(@psPickListSearch+"%",0,0)
				End
			End
		End
	End

--select @sCaseFilter
	-- Check if the result set is to be returned

	if @pbProduceResultSet = 1
	and @ErrorCode=0
	begin
		if @bTempTableExists = 0
		begin
			-- No previous results were returned so just combine the filter
			-- details returned to create a simple WHERE EXISTS clause
	
			Set @sWhere =	char(10)+"	Where exists (select *"+
					char(10)+"	"+@sCaseFilter+
					char(10)+"	and XC.CASEID=C.CASEID)"
		end
		else begin
			-- if previous result set details have been returned then they need
			-- to be combined with new query using the boolean operator passed
		 	-- as a parameter
			if upper(@psBuildOperator)='AND'
			begin
				-- insert an additional join to ensure the contents of the 
				-- previous queries also match with the current query

				set @sCaseFilter=replace(@sCaseFilter,'Where 1=1', '     join '+@sCurrentTable+' TC On (TC.CASEID=XC.CASEID)'+char(10)+'	Where 1=1')
				Set @sWhere =	char(10)+"	Where exists (select XC.CASEID"+
						char(10)+"	"+@sCaseFilter+
						char(10)+"	and XC.CASEID=C.CASEID)"
			end
			else if upper(@psBuildOperator)='OR'
			begin
				-- combine the results of the previous queries with the
				-- results of the current query

				Set @sWhere =	char(10)+"	Where exists (select XC.CASEID"+
						char(10)+"	"+@sCaseFilter+
						char(10)+"	and XC.CASEID=C.CASEID"+
						char(10)+"	union"+
						char(10)+"	select TC.CASEID"+
						char(10)+"	from "+@sCurrentTable+" TC"+
						char(10)+"	where TC.CASEID=C.CASEID)"
			end
			else if upper(@psBuildOperator)='NOT'
			begin
				-- We want the Cases from the previous queries that 
				-- do not match with the current query

				Set @sWhere =	char(10)+"	Where exists("+
						char(10)+"	select TC.CASEID"+
						char(10)+"	from "+@sCurrentTable+" TC"+
						char(10)+"	where TC.CASEID=C.CASEID)"+
						char(10)+"	and not exists"+
						char(10)+"	(select XC.CASEID"+
						char(10)+"	"+@sCaseFilter+
						char(10)+"	and XC.CASEID=C.CASEID)"
			end
		end

		-- Now execute the constructed SQL to return the result set
	
		exec (@sSelectList + @sFrom1 + @sFrom2 + @sWhere + @sOrder)
		select 	@ErrorCode =@@Error,
			@pnRowCount=@@Rowcount

		-- Now drop the temporary table holding the results

		if  @bTempTableExists = 1
		and @ErrorCode=0
		begin
			Set @sSql = "drop table "+@sCurrentTable

			exec @ErrorCode=sp_executesql @sSql
		end
	end

	else if @ErrorCode=0
	begin
		-- Results are not being returned so we need to save the results
		-- in a temporary table.  

		if @bTempTableExists = 0
		begin
			-- This is the first search so it needs to be saved into a
			-- temporary table without the need to refer to earlier search results.

			exec (@sSelectList + @sCaseFilter)

			select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
		end	
		else begin
			-- A previous query has already been run and the results saved to a temporary
			-- table. Copy the Cases from the first temporary table to another table

			Set  @sSql = 'Insert into ' + @sCopyTable + '(CASEID) select CASEID from ' + @sCurrentTable

			exec @ErrorCode=sp_executesql @sSql

			-- Now clear out the first temporary table so the Cases returned from the
			-- current query can be loaded in combination with the previous query

			if @ErrorCode=0
			begin
				Set @sSql = 'delete from ' + @sCurrentTable
				exec sp_executesql @sSql
			end

			-- if previous result set details have been returned then they need
			-- to be combined with a new query using the boolean operator passed
		 	-- as a parameter

			if upper(@psBuildOperator)='AND'
			begin
				-- insert an additional join to ensure the contents of the 
				-- previous queries also match with the current query

				set @sCaseFilter=replace(@sCaseFilter,'Where 1=1', '     join '+@sCopyTable+' TC On (TC.CASEID=XC.CASEID)'+char(10)+'	Where 1=1')
				Set @sWhere =	char(10)+"	"+@sCaseFilter
			end
			else if upper(@psBuildOperator)='OR'
			begin
				-- combine the results of the previous queries with the
				-- results of the current query

				Set @sWhere =	char(10)+"	"+@sCaseFilter+
						char(10)+"	union"+
						char(10)+"	select TC.CASEID"+
						char(10)+"	from "+@sCopyTable+" TC"
			end
			else if upper(@psBuildOperator)='NOT'
			begin
				-- We want the Cases from the previous queries that 
				-- do not match with the current query

				Set @sSelectList = 'Insert into ' + @sCurrentTable + '(CASEID) select TC.CASEID'

				Set @sWhere =	char(10)+"	from "+@sCopyTable+" TC"+
						char(10)+"	where not exists (select *"+
						char(10)+"	"+@sCaseFilter+
						char(10)+"	and XC.CASEID=TC.CASEID)"
			end

			-- Now execute the constructed SQL to return the combined result set
			 
			exec (@sSelectList + @sFrom1 + @sFrom2 + @sWhere)
			select 	@ErrorCode =@@Error,
				@pnRowCount=@@Rowcount
		end
	end

	-- Finally drop the copy temporary table if it exists
 	
	if exists(select * from tempdb.dbo.sysobjects where name = @sCopyTable)
	and @ErrorCode=0
	begin
		set @sSql = 'drop table ' + @sCopyTable
		exec @ErrorCode=sp_executesql @sSql			
	end

	RETURN @ErrorCode
go

grant execute on dbo.cs_ListCase  to public
go



