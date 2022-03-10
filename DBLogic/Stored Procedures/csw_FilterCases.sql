-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FilterCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_FilterCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_FilterCases.' 
	drop procedure dbo.csw_FilterCases
	print '**** Creating procedure dbo.csw_FilterCases...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.csw_FilterCases
(
	@pnRowCount			int		= null output,
	@psReturnClause			nvarchar(max)   = null output, 
	@psTempTableName		nvarchar(50)	= null output, -- is the name of the the global temporary table that may hold the filtered list of cases.
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser		bit		= null,
	@ptXMLFilterCriteria		nvarchar(max)	= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@pnFilterId			int		= null 	-- Filter ID to retrieve filter directly from QUERYFILTER table.
)		
-- PROCEDURE :	csw_FilterCases
-- VERSION :	22
-- DESCRIPTION:	csw_FilterCases is responsible for the management of the multiple occurrences of the filter criteria 
--		and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where 
--		clause for each separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the 
--		name of the the global temporary table that may hold the filtered list of cases.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date			Who	Number		Version	Details
-- ----			---	-------		-------	-------------------------------------
-- 24 Nov 2003	TM	RFC509		1		Procedure created
-- 29 Dec 2003	TM	RFC781		2		Correct the XML path to count the FilterCriteria instead of the FilterCriteriaGroup.
-- 05 Feb 2004	MF	SQA9661		3		Changes to allow the @psTempTableName to be passed as a parameter
-- 09 Feb 2004	MF	SQA9661		4		Failed test.  Need to initialise @bTempTableExists to 0.
-- 19 Feb 2004	TM	RFC976		5		Add @pbCalledFromCentura bit parameter and pass it to the csw_ConstructCaseWhere.
-- 03 Mar 2004	MF	SQA9689		6		Allow for additional Cases to be added or removed from result and also
--										for Cases within the result set to be included or excluded.
-- 17 Mar 2004	MF	SQA9689		7		Tighten up code after @ErrorCode has been set.
-- 02 Apr 2004	MF	SQA9664		8		Reference to @sFrom1 and @sFrom2 removed as they were not being used.
-- 25 Apr 2004	MF	RFC1334		9		Allow additional filter on the selected columns.
-- 07 Jul 2004	TM	RFC1230		10		Ensure that the procedures only process the contents of the <csw_ListCase>  
--										node and that the node is processed whether it is the root node for the 
--										@ptXMLFilterCriteria or not.
-- 02 Sep 2004	JEK	RFC1377		11		Pass new Centura parameter to fn_WrapQuotes
-- 17 Dec 2004	TM	RFC1674		12		Remove the UPPER function around the IRN to improve performance.
-- 09 May 2007	AT	SQA12330	13		Added optional parameter to get a filter directly from QUERYFILTER table.
-- 16 Feb 2009	MF	SQA17463	14		Allow an explicit list of Cases to be excluded;
--										Allow an explicit list of partial Case References to be included if the IRN is like any in the list;
--										Allow an explicit list of partial Case References to filter out Cases where IRN is like any in the list.
-- 10 Sep 2009	MF	RFC8441		15		WITH (NOLOCK) option has been added against CASES to reduce locking and needs to be considered when 
--										using a REPLACE to modify the code.
-- 17 Dec 2009	MF	R100153		16		Fix bug introduced by RFC8441
-- 08 Feb 2014	MF	R30800		17		Picklist Search to drop through and search by TITLE if nothing is found for IRN and Official No search.
-- 07 Mar 2014	MF	R31402		18		When the pikclist search drops though to search by TITLE then check if search string occurs anywhere within the TITLE.
-- 17 Apr 2015	MS	R46603		19		Set size of some variables to nvarchar(max)
-- 15 Aug 2016	MF	R65367		20		Introduction of the Ethical Wall restrictions resulted in a picklist search fail, depending on the data in the database.
-- 07 Sep 2018	AV	74738		21		Set isolation level to read uncommited.
-- 05 Mar 2020	BS	DR-49738	22		Added Case picklist search by Name Reference

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare @ErrorCode		int

Declare @nTableCount		tinyint

Declare @nFilterGroupCount	tinyint		-- The number of FilterCriteriaGroups contained in the @ptXMLFilterCriteria parameter 
Declare @nFilterGroupIndex	tinyint		-- The FilterCriteriaGroup node number.		
Declare @sRowPattern		nvarchar(100)	-- Is used to dynamically build the XPath to use with OPENXML depending on the FilterCriteriaGroup node number.
Declare @sRowPattern1		nvarchar(100)
Declare @sRowPattern2		nvarchar(100)
Declare @sRowPattern3		nvarchar(100)
Declare @sRowPattern4		nvarchar(100)

Declare @sBuildOperator		nvarchar(3)	-- may contain any of the values "and", "OR", "NOT"

Declare @sCurrentTable 		nvarchar(50)	
Declare @sCopyTable 		nvarchar(50)	

Declare @bTempTableExists	bit
Declare @pbExists		bit
Declare @bAddedCases		bit
Declare	@bTickedCases		bit
Declare @bExcludeCases		bit
Declare @bAddedLikeCases	bit
Declare	@bExcludeLikeCases	bit
Declare @bOperator		bit

Declare @nCaseCount		int

Declare	@sPickListSearch	nvarchar(50)	-- the text entered by a user in a picklist field to located appropriate entries
	
Declare @sSql			nvarchar(max)
Declare @sSQLString		nvarchar(max)
Declare @sSelectList		nvarchar(max)  -- the SQL list of columns to return
Declare @sNotExists		nvarchar(100)	
Declare @sWhere			nvarchar(max) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare	@sCaseFilter		nvarchar(max)	-- the FROM and WHERE for the Case Filter

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @idoc 			int 	

-- Intialise Variables
Set @ErrorCode=0 
Set @bTempTableExists=0
Set @nCaseCount=0

-- If retreiving directly from QUERYFILTER
If @ErrorCode = 0 
and (datalength(@ptXMLFilterCriteria) = 0
	or datalength(@ptXMLFilterCriteria) is null) 
and @pnFilterId is not null
Begin
	Set @sSQLString="
		Select @ptXMLFilterCriteria = XMLFILTERCRITERIA
		from QUERYFILTER
		WHERE FILTERID = @pnFilterId"

	exec @ErrorCode = sp_executesql @sSQLString,
		N'@ptXMLFilterCriteria ntext OUTPUT,
		@pnFilterId int',
		@ptXMLFilterCriteria = @ptXMLFilterCriteria OUTPUT,
		@pnFilterId = @pnFilterId
End

-- If there is no FilterCriteria passed then construct the @psReturnClause output (the "Where" clause) as the following:

If @ErrorCode = 0
and (datalength(@ptXMLFilterCriteria) = 0
 or  datalength(@ptXMLFilterCriteria) is null)
Begin
	exec @ErrorCode = dbo.csw_ConstructCaseWhere
			        @psReturnClause			= @sCaseFilter		output,
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pbIsExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria		= @ptXMLFilterCriteria,
				@pnFilterGroupIndex		= @nFilterGroupIndex,
				@pbCalledFromCentura		= @pbCalledFromCentura
	
	Set @sWhere =	char(10)+"	and exists (select *"+
					char(10)+"	"+@sCaseFilter+
					char(10)+"	and XC.CASEID=C.CASEID)"

	Set @psReturnClause = @sWhere
End
Else Begin
	If @ErrorCode = 0
	Begin
		-- Create an XML document in memory and then retrieve the information 
		-- from the rowset using OPENXML
			
		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
		-- Find out how many times FilterCriterisGroup repeats in the @ptXMLFilterCriteria parameter 
	
		Select	@nFilterGroupCount = count(*)
			from	OPENXML (@idoc, '//csw_ListCase/FilterCriteriaGroup/FilterCriteria',2)
			WITH (
			      id int '@mp:id'		   
			     )		

		-- Set @nFilterGroupIndex to 1 so it points to the first FilterCriteriaGroup	
		Set @nFilterGroupIndex = 1
		
		Set @ErrorCode=@@Error
	End

	-- Get the name of the temporary table passed in as a parameter and derive a Copy Table name 
	If @ErrorCode=0
	Begin
		If @psTempTableName is null
		Begin
			Set @sCurrentTable = '##SEARCHCASE_' + Cast(@@SPID as varchar(10))
			Set @sCopyTable    = @sCurrentTable+'_COPY'
		End
		Else Begin		
			Set @sCurrentTable=@psTempTableName
			Set @sCopyTable   =@psTempTableName+'_COPY'
		End
	End
		
	-- Loop through each major group of Filter criteria	
	While @nFilterGroupIndex <= @nFilterGroupCount
	and @ErrorCode = 0
	Begin
		Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]"
	
		Select	@sBuildOperator	   = BooleanOperator
		from	OPENXML (@idoc, @sRowPattern,2)
			WITH (
			      BooleanOperator	nvarchar(3)	'@BooleanOperator/text()'
			     )		

		If @nFilterGroupCount > 1	
		Begin

			-- Determine if the temporary table holding previous results exists
			if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable )
			Begin
				-- If CASES have already been saved in a temporary table then
				-- we need to create a Copy table to hold these results so they
				-- can be combined with the next query
				Set @bTempTableExists=1
				Set @sSql = 'Create Table ' + @sCopyTable + ' (CASEID int)'
			End
			Else Begin  
				-- If there are more than one FilterGriteria group then we need to create
				-- a temporary table to store the results if it has not been created already
				Set @bTempTableExists=0
				Set @sSql = 'Create Table ' + @sCurrentTable + ' (CASEID int)'
			End
		
			exec @ErrorCode=sp_executesql @sSql
	
			-- the statements above will prepare the temptable needed for this query	
			Set @sSelectList = 'Insert into ' + @sCurrentTable + '(CASEID) select XC.CASEID'
		End
		
		-- Construct the "Select", "From" and the "Order by" clauses if the result set is to be returned
		-- (if @nFilterGroupIndex = @nFilterGroupCount)	
		
		-- ACTUAL CASE SEARCH SQL BUILDING BEGINS
		-- now prepair the sql with the available filters specified.
		
		-- Construct the FROM and WHERE clauses used to filter which Cases are to be returned
		if @ErrorCode=0
		begin
			exec @ErrorCode = dbo.csw_ConstructCaseWhere
			        @psReturnClause			= @sCaseFilter		output,
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pbIsExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria		= @ptXMLFilterCriteria,
				@pnFilterGroupIndex		= @nFilterGroupIndex,
				@pbCalledFromCentura		= @pbCalledFromCentura
		end
	
		-- If the PickListSearch is being used then the value within the @sPickListSearch parameter
		-- is to be combined with the other filter parameters and a staged search is to be performed.
		-- The staged search is to combine the CaseFilter details and first search on :
		-- 1) an exact IRN match
		-- 2) an inexact IRN starting with the parameter
		-- 3) an exact Official Number
		-- 4) an inexact Official Number starting with the parameter.
		-- 5) an exact Title
		-- 6) an inexact Title matching with the parameter in any position.
		-- 7) an exact Reference Number
		-- 8) an inexact Reference Number starting with the parameter.
		-- If still no match then nothing is returned. This is done by including the last search in the query built.

		-- Retrieve the PickListSearch element using element-centric mapping (implement 
		-- Case Insensitive searching)   
	
		If @ErrorCode=0
		Begin
			Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]"
				
			Select  @sPickListSearch = PickListSearch
				from	OPENXML (@idoc, @sRowPattern,2)
				WITH (
				      PickListSearch	nvarchar(50)	'PickListSearch/text()'
				     )
		End
	
		If @sPickListSearch is not null
		and @ErrorCode=0
		Begin
			-- Check for exact match on IRN

			set @pbExists=0
			set @sSQLString="Select @pbExists=1"+char(10)+
					"from CASES C"+char(10)+
					"where C.IRN="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)+char(10)+   
					"and exists"+char(10)+
					"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pbExists		bit	OUTPUT,
						  @sPickListSearch	nvarchar(50)',
						  @pbExists		=@pbExists OUTPUT,
						  @sPickListSearch	=@sPickListSearch
			If @ErrorCode=0
			Begin
				If @pbExists=1
				Begin
					set @sCaseFilter=@sCaseFilter+char(10)+"	and XC.IRN="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)
				End
				Else Begin
					-- Check for partial match on IRN
			
					set @sSQLString="Select @pbExists=1"+char(10)+
							"from CASES C"+char(10)+
							"where C.IRN like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,@pbCalledFromCentura)+char(10)+ 
							"and exists"+char(10)+
							"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"
			
					exec @ErrorCode=sp_executesql @sSQLString,
								N'@pbExists		bit	OUTPUT,
								  @sPickListSearch	nvarchar(50)',
								  @pbExists		=@pbExists OUTPUT,
								  @sPickListSearch	=@sPickListSearch
			
					If @pbExists=1
					and @ErrorCode=0
					Begin
						set @sCaseFilter=@sCaseFilter+char(10)+"	and XC.IRN like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,@pbCalledFromCentura)
					End
					Else If @ErrorCode=0
					Begin
						-- Check for exact match on Official Number
			
						set @sSQLString="Select @pbExists=1"+char(10)+
								"from CASES C"+char(10)+
								"join OFFICIALNUMBERS O on (O.CASEID=C.CASEID)"+char(10)+
								"where O.OFFICIALNUMBER="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)+char(10)+
								"and exists"+char(10)+
								"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"
			
						exec @ErrorCode=sp_executesql @sSQLString,
									N'@pbExists		bit	OUTPUT,
									  @sPickListSearch	nvarchar(50)',
									  @pbExists		=@pbExists OUTPUT,
									  @sPickListSearch	=@sPickListSearch
			
						If @ErrorCode=0
						Begin
							If @pbExists=1
							Begin				
								set @sCaseFilter=replace(@sCaseFilter,') XC ',') XC '+char(10)+'	join OFFICIALNUMBERS XO WITH (NOLOCK) on (XO.CASEID=XC.CASEID)')
										+char(10)+"	and XO.OFFICIALNUMBER="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)
							End
							Else Begin
								-- Check for partial match on Official Number	
								set @sSQLString="Select @pbExists=1"+char(10)+
										"from CASES C"+char(10)+
										"join OFFICIALNUMBERS O on (O.CASEID=C.CASEID)"+char(10)+
										"where O.OFFICIALNUMBER like "+dbo.fn_WrapQuotes(@sPickListSearch+'%',0,@pbCalledFromCentura)+char(10)+
										"and exists"+char(10)+
										"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"
						
								exec @ErrorCode=sp_executesql @sSQLString,
											N'@pbExists		bit	OUTPUT,
											  @sPickListSearch	nvarchar(50)',
											  @pbExists		=@pbExists OUTPUT,
											  @sPickListSearch	=@sPickListSearch
						
								If @pbExists=1
								and @ErrorCode=0
								Begin			
									set @sCaseFilter=replace(@sCaseFilter,') XC ',') XC '+char(10)+'	join OFFICIALNUMBERS XO WITH (NOLOCK) on (XO.CASEID=XC.CASEID)')
											+char(10)+"	and XO.OFFICIALNUMBER like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,@pbCalledFromCentura)
								End
								Else If @ErrorCode=0
								Begin
									-- Check for exact match on Title
			
									set @sSQLString="Select @pbExists=1"+char(10)+
											"from CASES C"+char(10)+
											"where C.TITLE="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)+char(10)+   
											"and exists"+char(10)+
											"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"
			
									exec @ErrorCode=sp_executesql @sSQLString,
												N'@pbExists		bit	OUTPUT,
												  @sPickListSearch	nvarchar(50)',
												  @pbExists		=@pbExists OUTPUT,
												  @sPickListSearch	=@sPickListSearch
			
									If @ErrorCode=0
									Begin
										If @pbExists=1
										Begin				
												set @sCaseFilter=@sCaseFilter+char(10)+"	and XC.TITLE="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)
										End
										Else Begin
											-- Check for partial match on Title
											set @sSQLString="Select @pbExists=1"+char(10)+
													"from CASES C"+char(10)+
													"where C.TITLE like "+dbo.fn_WrapQuotes(@sPickListSearch+'%',0,@pbCalledFromCentura)+char(10)+
													"and exists"+char(10)+
													"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"
						
											exec @ErrorCode=sp_executesql @sSQLString,
														N'@pbExists		bit	OUTPUT,
														  @sPickListSearch	nvarchar(50)',
														  @pbExists		=@pbExists OUTPUT,
														  @sPickListSearch	=@sPickListSearch
						
											If @pbExists=1
											and @ErrorCode=0
											Begin			
												set @sCaseFilter=@sCaseFilter+char(10)+"	and XC.TITLE like "+dbo.fn_WrapQuotes('%'+@sPickListSearch+'%',0,@pbCalledFromCentura)
											End
											Else If @ErrorCode=0
											Begin
												-- Check for exact match on Reference No.
			
												set @sSQLString="Select @pbExists=1"+char(10)+
														"from CASES C"+char(10)+
														"join CASENAME CN on (CN.CASEID=C.CASEID)"+char(10)+
														"where CN.REFERENCENO="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)+char(10)+
														"and exists"+char(10)+
														"(select *"+ char(10)+"	"+@sCaseFilter+char(10)+" and XC.CASEID=C.CASEID)"
			
												exec @ErrorCode=sp_executesql @sSQLString,
															N'@pbExists		bit	OUTPUT,
															  @sPickListSearch	nvarchar(50)',
															  @pbExists		=@pbExists OUTPUT,
															  @sPickListSearch	=@sPickListSearch
			
												If @ErrorCode=0
												Begin
													If @pbExists=1
													Begin				
														set @sCaseFilter=replace(@sCaseFilter,') XC ',') XC '+char(10)+'	join CASENAME XCN WITH (NOLOCK) on (XCN.CASEID=XC.CASEID)')
																+char(10)+"	and XCN.REFERENCENO="+dbo.fn_WrapQuotes(@sPickListSearch,0,@pbCalledFromCentura)
													End
													Else Begin
															set @sCaseFilter=replace(@sCaseFilter,') XC ',') XC '+char(10)+'	join CASENAME XCN WITH (NOLOCK) on (XCN.CASEID=XC.CASEID)')
																	+char(10)+"	and XCN.REFERENCENO like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,@pbCalledFromCentura)
													End
												End
											End
										End
									End
								End
							End
						End
					End
				End
			End
		End
		
		-- select @sCaseFilter
		-- Check if the result set is to be returned

		if @nFilterGroupIndex = @nFilterGroupCount 
		and @ErrorCode=0
		begin   
			if @bTempTableExists = 0
			begin 
				-- No previous results were returned so just combine the filter
				-- details returned to create a simple WHERE EXISTS clause
		
				Set @sWhere =	char(10)+"	and exists (select *"+
						char(10)+"	"+@sCaseFilter+
						char(10)+"	and XC.CASEID=C.CASEID)" 			
			end
			else begin
				-- if previous result set details have been returned then they need
				-- to be combined with new query using the boolean operator passed
			 	-- as a parameter
				if @sBuildOperator='AND'
				begin
					-- insert an additional join to ensure the contents of the 
					-- previous queries also match with the current query
		
					set @sCaseFilter=replace(@sCaseFilter,'WHERE 1=1', '     join '+@sCurrentTable+' TC On (TC.CASEID=XC.CASEID)'+char(10)+'	Where 1=1')
					Set @sWhere =	char(10)+"	and exists (select XC.CASEID"+
							char(10)+"	"+@sCaseFilter+
							char(10)+"	and XC.CASEID=C.CASEID)"
				end
				else if @sBuildOperator='OR'
				begin
					-- combine the results of the previous queries with the
					-- results of the current query
		
					Set @sWhere =	char(10)+"	and exists (select XC.CASEID"+
							char(10)+"	"+@sCaseFilter+
							char(10)+"	and XC.CASEID=C.CASEID"+
							char(10)+"	union"+
							char(10)+"	select TC.CASEID"+
							char(10)+"	from "+@sCurrentTable+" TC"+
							char(10)+"	where TC.CASEID=C.CASEID)"
				end
				else if @sBuildOperator='NOT'
				begin
					-- We want the Cases from the previous queries that 
					-- do not match with the current query
		
					Set @sWhere =	char(10)+"	and exists("+
							char(10)+"	select TC.CASEID"+
							char(10)+"	from "+@sCurrentTable+" TC"+
							char(10)+"	where TC.CASEID=C.CASEID)"+
							char(10)+"	and not exists"+
							char(10)+"	(select XC.CASEID"+
							char(10)+"	"+@sCaseFilter+
							char(10)+"	and XC.CASEID=C.CASEID)"
				end
			end		

			-- Finally set the @psReturnClause (the constructed 'Where' clause) and the @psTempTableName 
			-- to output them to the calling stored procedure
			
			Set @psReturnClause = @sWhere
			
			Set @psTempTableName = @sCurrentTable 
		end
		
		else if @ErrorCode=0
		     and @nFilterGroupIndex < @nFilterGroupCount 
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
					exec @ErrorCode=sp_executesql @sSql
				end
		
				-- if previous result set details have been returned then they need
				-- to be combined with a new query using the boolean operator passed
			 	-- as a parameter
		
				if @sBuildOperator='AND'
				and @ErrorCode=0
				begin
					-- insert an additional join to ensure the contents of the 
					-- previous queries also match with the current query
		
					set @sCaseFilter=replace(@sCaseFilter,'WHERE 1=1', '     join '+@sCopyTable+' TC On (TC.CASEID=XC.CASEID)'+char(10)+'	Where 1=1')
					Set @sWhere =	char(10)+"	"+@sCaseFilter
				end
				else if @sBuildOperator='OR'
				     and @ErrorCode=0
				begin
					-- combine the results of the previous queries with the
					-- results of the current query
		
					Set @sWhere =	char(10)+"	"+@sCaseFilter+
							char(10)+"	union"+
							char(10)+"	select TC.CASEID"+
							char(10)+"	from "+@sCopyTable+" TC"
				end
				else if @sBuildOperator='NOT'
				     and @ErrorCode=0
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
				If @ErrorCode=0
				Begin
					exec (@sSelectList + @sWhere)
					select 	@ErrorCode =@@Error,
						@pnRowCount=@@Rowcount
				End
			end
		end

		-- Drop the copy temporary table if it exists
			
		if exists(select * from tempdb.dbo.sysobjects where name = @sCopyTable)
		and @ErrorCode=0
		begin
			set @sSql = 'drop table ' + @sCopyTable
			exec @ErrorCode=sp_executesql @sSql			
		end

		-- SQA9689
		-- Check to see if there are any manually entered Cases

		If @ErrorCode=0
		Begin
			Set @sRowPattern = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/AddedCasesGroup/CaseKey"
			Set @bAddedCases = 0
	
			Set @sSql="
			Select @bAddedCases=1
			from	OPENXML (@idoc, @sRowPattern, 2)
			WITH (CaseKey	int	'text()')
			Where CaseKey is not null"
	
			exec @ErrorCode=sp_executesql @sSql,
						N'@bAddedCases		bit	Output,
						  @idoc			int,
						  @sRowPattern		varchar(100)',
						  @bAddedCases=@bAddedCases	Output,
						  @idoc=@idoc,
						  @sRowPattern=@sRowPattern
		End

		-- Check to see if there are any ticked Cases

		If @ErrorCode=0
		Begin
			Set @sRowPattern1 = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/SelectedCasesGroup"
			Set @bTickedCases = 0

			Set @sSql="
			Select	@bOperator	= Operator,
				@bTickedCases	= 1
			from	OPENXML (@idoc, @sRowPattern1,2)
				WITH (
				      Operator	bit	'@Operator/text()'
				     )
			Where Operator in (1,0)"
	
			exec @ErrorCode=sp_executesql @sSql,
						N'@bOperator		bit	Output,
						  @bTickedCases		bit	Output,
						  @idoc			int,
						  @sRowPattern1		varchar(100)',
						  @bOperator=@bOperator		Output,
						  @bTickedCases=@bTickedCases	Output,
						  @idoc=@idoc,
						  @sRowPattern1=@sRowPattern1
		End

		-- SQA17463
		-- Check to see if there are any manually entered Cases that are to be excluded
		If @ErrorCode=0
		Begin
			Set @sRowPattern2 = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/ExcludeCasesGroup/CaseKey"
			Set @bExcludeCases = 0
	
			Set @sSql="
			Select @bExcludeCases=1
			from	OPENXML (@idoc, @sRowPattern2, 2)
			WITH (CaseKey	int	'text()')
			Where CaseKey is not null"
	
			exec @ErrorCode=sp_executesql @sSql,
						N'@bExcludeCases		bit	Output,
						  @idoc				int,
						  @sRowPattern2			varchar(100)',
						  @bExcludeCases=@bExcludeCases	Output,
						  @idoc=@idoc,
						  @sRowPattern2=@sRowPattern2
		End
		
		-- Check to see if there are any manually entered IRNs that are to have Cases added that are LIKE it.
		If @ErrorCode=0
		Begin
			Set @sRowPattern3 = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/AddedCasesLikeGroup/CaseReference"
			Set @bAddedLikeCases = 0
	
			Set @sSql="
			Select @bAddedLikeCases=1
			from	OPENXML (@idoc, @sRowPattern3, 2)
			WITH (CaseReference	nvarchar(30)	'text()')
			Where CaseReference is not null"
	
			exec @ErrorCode=sp_executesql @sSql,
						N'@bAddedLikeCases		bit	Output,
						  @idoc				int,
						  @sRowPattern3			varchar(100)',
						  @bAddedLikeCases=@bAddedLikeCases	Output,
						  @idoc=@idoc,
						  @sRowPattern3=@sRowPattern3
		End
		
		-- Check to see if there are any manually entered IRNs that are to have Cases excluded that are LIKE it.
		If @ErrorCode=0
		Begin
			Set @sRowPattern4 = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/ExcludeCasesLikeGroup/CaseReference"
			Set @bExcludeLikeCases = 0
	
			Set @sSql="
			Select @bExcludeLikeCases=1
			from	OPENXML (@idoc, @sRowPattern4, 2)
			WITH (CaseReference	nvarchar(30)	'text()')
			Where CaseReference is not null"
	
			exec @ErrorCode=sp_executesql @sSql,
						N'@bExcludeLikeCases		bit	Output,
						  @idoc				int,
						  @sRowPattern4			varchar(100)',
						  @bExcludeLikeCases=@bExcludeLikeCases	Output,
						  @idoc=@idoc,
						  @sRowPattern4=@sRowPattern4
		End

		If @ErrorCode=0
		and (@bAddedCases=1 or @bTickedCases=1 or @bExcludeCases=1 or @bAddedLikeCases=1 or @bExcludeLikeCases=1)
		Begin
			-- If only 1 Filter Group then create a temporary table to hold
			-- the results of the filter before adding the manually added Cases.
			If @nFilterGroupCount=1
			Begin
				Set @sSql = 'Create Table ' + @sCurrentTable + ' (CASEID int)'
				exec @ErrorCode=sp_executesql @sSql

				Set @sSelectList = 'Insert into ' + @sCurrentTable + '(CASEID) select XC.CASEID'

				exec (@sSelectList + @sCaseFilter)
		
				set @ErrorCode =@@Error
			End
			-- If the final Filter Group has been processed and there were more than one
			-- Filter Group then create another temporary table to load the final result into
			Else If @nFilterGroupIndex=@nFilterGroupCount
			Begin
				Set @sSql = 'Create Table ' + @sCopyTable + ' (CASEID int)'
				exec @ErrorCode=sp_executesql @sSql

				Set @sSelectList = 'Insert into ' + @sCopyTable + '(CASEID) select C.CASEID From CASES C WHERE 1=1'

				exec (@sSelectList + @sWhere)
		
				select 	@ErrorCode =@@Error

				-- Drop the CurrentTable as it is going to be replaced with
				-- another table.
				If @ErrorCode=0
				Begin
					set @sSql = 'drop table ' + @sCurrentTable
					exec @ErrorCode=sp_executesql @sSql	
				End

				Set @sCurrentTable=@sCopyTable
			End

			-- Add the manually entered Cases to the temporary table
			If  @ErrorCode=0
			and @bAddedCases=1
			Begin
				Set @sSql="Insert into "+@sCurrentTable +"(CASEID)"+char(10)+
					  "Select CaseKey"+char(10)+
					  "from	OPENXML (@idoc, @sRowPattern, 2)"+char(10)+
					  "WITH (CaseKey	int	'text()')"+char(10)+
					  "Where CaseKey is not null"+char(10)+
					  "and not exists(select * from "+@sCurrentTable+" where CASEID=CaseKey)"
	
				exec @ErrorCode=sp_executesql @sSql,
								N'@idoc		int,
								  @sRowPattern	varchar(100)',
								  @idoc=@idoc,
								  @sRowPattern=@sRowPattern
			End

			-- Add the manually entered Cases to the temporary table
			If  @ErrorCode=0
			and @bAddedLikeCases=1
			Begin
				Set @sSql="Insert into "+@sCurrentTable +"(CASEID)
					   select C.CASEID
					   from  (	Select CaseReference
							from	OPENXML (@idoc, @sRowPattern3, 2)
							WITH (CaseReference	nvarchar(30)	'text()')
							Where CaseReference is not null) X
					   join CASES C	on (C.IRN like X.CaseReference)"
	
				exec @ErrorCode=sp_executesql @sSql,
								N'@idoc		int,
								  @sRowPattern3	varchar(100)',
								  @idoc=@idoc,
								  @sRowPattern3=@sRowPattern3
			End

			-- If there are ticked then remove the Cases in the temporary table 
			-- that match the ticked Cases when Operator=1 or that do not match
			-- the ticked Cases when Operator=0

			If  @ErrorCode=0
			and @bTickedCases=1
			Begin
				Set @sRowPattern1 = "//csw_ListCase/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/SelectedCasesGroup/CaseKey"
		
				If @bOperator=0
				Begin
					Set @sSql="Delete "+@sCurrentTable+char(10)+
						  "from "  +@sCurrentTable+" X"+char(10)+
						  "left join (	select CaseKey"+char(10)+
						  "		from	OPENXML (@idoc, @sRowPattern1, 2)"+char(10)+
						  "		WITH (CaseKey	int	'text()')"+char(10)+
						  "		Where CaseKey is not null) C on (C.CaseKey=X.CASEID)"+char(10)+
						  "where C.CaseKey is null"
				End
				Else Begin
					Set @sSql="Delete "+@sCurrentTable+char(10)+
						  "from "  +@sCurrentTable+" X"+char(10)+
						  "join (	select CaseKey"+char(10)+
						  "		from	OPENXML (@idoc, @sRowPattern1, 2)"+char(10)+
						  "		WITH (CaseKey	int	'text()')"+char(10)+
						  "		Where CaseKey is not null) C on (C.CaseKey=X.CASEID)"
				End

				exec @ErrorCode=sp_executesql @sSql,
							N'@idoc			int,
							  @sRowPattern1		varchar(100)',
							  @idoc=@idoc,
							  @sRowPattern1=@sRowPattern1
			End

			-- Remove the manually entered Cases to be excluded from the temporary table
			If  @ErrorCode=0
			and @bExcludeCases=1
			Begin
				Set @sSql="Delete "+@sCurrentTable+char(10)+
					  "from "  +@sCurrentTable+" X"+char(10)+
					  "join (	select CaseKey"+char(10)+
					  "		from	OPENXML (@idoc, @sRowPattern2, 2)"+char(10)+
					  "		WITH (CaseKey	int	'text()')"+char(10)+
					  "		Where CaseKey is not null) C on (C.CaseKey=X.CASEID)"
	
				exec @ErrorCode=sp_executesql @sSql,
								N'@idoc		int,
								  @sRowPattern2	varchar(100)',
								  @idoc=@idoc,
								  @sRowPattern2=@sRowPattern2
			End

			-- Remove the manually entered Cases to be excluded from the temporary table
			If  @ErrorCode=0
			and @bExcludeLikeCases=1
			Begin
				Set @sSql="Delete X
					   from "+@sCurrentTable+" X
					   join CASES CS on (CS.CASEID=X.CASEID)
					   join (	select CaseReference
					   		from	OPENXML (@idoc, @sRowPattern4, 2)
					   		WITH (CaseReference	nvarchar(30)	'text()')
					  		Where CaseReference is not null) C on (CS.IRN  like C.CaseReference)"
	
				exec @ErrorCode=sp_executesql @sSql,
								N'@idoc		int,
								  @sRowPattern4	varchar(100)',
								  @idoc=@idoc,
								  @sRowPattern4=@sRowPattern4
			End

			-- The current Where clause can now be modified to just return the Cases 
			-- in the temporary table.
			Set @psReturnClause =	char(10)+"	and exists (select XC.CASEID from "+@sCurrentTable+" XC"+
						char(10)+"	where XC.CASEID=C.CASEID)"
		End

		-- Set @nFilterGroupIndex to point to the next FilterCriteriaGroup	
		Set @nFilterGroupIndex = @nFilterGroupIndex + 1


	End -- End of the "While" loop
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

RETURN @ErrorCode
go

grant execute on dbo.csw_FilterCases  to public
go



