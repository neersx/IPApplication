-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FilterNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[naw_FilterNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.naw_FilterNames.'
	drop procedure dbo.naw_FilterNames
end
print '**** Creating procedure dbo.naw_FilterNames...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_FilterNames
(
	@psReturnClause		nvarchar(max)  = null output, 
	@psTempTableName	nvarchar(50)	= null output, -- is the name of the the global temporary table that may hold the filtered list of names.
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbIsExternalUser	bit		= null,
	@ptXMLFilterCriteria	nvarchar(max)	= null,	-- The filtering to be performed on the result set.
	@pnFilterId		int		= null 	-- Filter ID to retrieve filter directly from QUERYFILTER table.		
)	

-- PROCEDURE :	naw_FilterNames
-- VERSION :	15
-- DESCRIPTION:	naw_FilterNames is responsible for the management of the multiple occurrences of the filter criteria 
--		and the production of an appropriate result set. It calls naw_ConstructNameWhere to obtain the where 
--		clause for each separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the 
--		name of the the global temporary table that may hold the filtered list of names.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Dec 2003	TM	RFC710	1	Procedure created based on the Version 9 of the naw_ListName	
-- 02 Sep 2004	JEK	RFC1377	2	Pass new Centura parameter to fn_WrapQuotes
-- 17 Dec 2004	TM	RFC1674	3	Remove the UPPER function around the SearchKey1 and SearchKey2 to improve
--					performance.
-- 30 Jun 2005	TM	RFC2239 4	Implement Name search with both keys site control in pick list search.
-- 30 Jan 2007	PY	S12521	5	Replace function call Soundex with fn_SoundsLike
-- 10 Apr 2008	MF	RFC6334	6	Use the NAME.SOUNDEX column instead of dynamically determining with function.
-- 11 Dec 2008	MF	17136	7	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Apr 2011	ASH	10281	8	Use SearchKey1 in where condition when SEARCHSOUNDEXFLAG sitecontrol is set to 'False'.
-- 12 Jul 2011	MF	10968	9	Perform improvement by correcting the table SEARCHKEY2 is being compared from.
-- 12 Aug 2011	MF	11122	10	Restrict the SEARCHKEY to only use the first 20 characters entered
-- 26 Aug 2010  MS      R10939  11	Restrict the SEARCHKEY to only use the first 20 characters entered
-- 24 Sep 2012  DV      R100762 12	Convert @psReturnClause to nvarchar(max)
-- 19 Apr 2016	MF	58257	13	If picklist is being requested for a particular NameType, then need to check if there is 
--					an exact match on NameCode where that Name is allowed to be used as that NameType.  If not
--					then drop back to a non-exact match search.
-- 23 Aug 2019  MS      DR45456 14      Added check for NameTypeClassification.IsAllow for searching on name code only when IsAvailable is false
-- 12 Sep 2019  SR      DR46029 15      Applied LTRIM and RTRIM on @sPickListSearch
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sCurrentTable 		nvarchar(50)	
Declare @sCopyTable 		nvarchar(50)	

Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument

Declare @bTempTableExists	bit
Declare	@bExternalUser		bit
Declare @bAddedNames		bit
Declare	@bTickedNames		bit
Declare @bOperator		bit

Declare @sSQLString		nvarchar(4000)
Declare @sSelectList		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere			nvarchar(max) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare	@sNameFilter		nvarchar(max)	-- the FROM and WHERE for the Case Filter
Declare	@sNameSearch		nvarchar(254)	-- an inexact SEARCHKEY1 starting with the parameter up to the first comma.

Declare @nFilterGroupCount	tinyint		-- The number of FilterCriterisGroupe contained in the @ptXMLFilterCriteria parameter 
Declare @nFilterGroupIndex	tinyint		-- The FilterCriteriaGroup node number.		
Declare @sRowPattern		nvarchar(100)	-- Is used to dynamically build the XPath to use with OPENXML depending on the FilterCriteriaGroup node number.
Declare @sRowPattern1		nvarchar(100)	
Declare @sBuildOperator		nvarchar(3)	-- may contain any of the values "and", "OR", "NOT"

Declare	@sPickListSearch	nvarchar(254)	-- the text entered by a user in a picklist field to located appropriate entries
Declare	@sUsedAsFlag		nvarchar(20)
Declare @sSuitableForNameType	nvarchar(3)	-- Name Type that the name being search for is to be used as
Declare	@nPickListFlags		smallint
Declare @pbExists		bit		-- @pbExists is set to 1 as soon as rows are located for a criterion.
Declare @bSearchBothKeys	bit		
Declare	@bIsIndividual		bit
Declare @bIsOrganisation	bit
Declare	@bIsStaff		bit
Declare	@bIsClient		bit
Declare @bAvailableNamesOnly    bit

Set @nErrorCode=0
Set @bTempTableExists=0

-- If retreiving directly from QUERYFILTER
If @nErrorCode = 0 
and (datalength(@ptXMLFilterCriteria) = 0
 or  datalength(@ptXMLFilterCriteria) is null) 
and @pnFilterId is not null
Begin
	Set @sSQLString="
		Select @ptXMLFilterCriteria = XMLFILTERCRITERIA
		from QUERYFILTER
		WHERE FILTERID = @pnFilterId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@ptXMLFilterCriteria	ntext	OUTPUT,
				  @pnFilterId		int',
				  @ptXMLFilterCriteria	= @ptXMLFilterCriteria OUTPUT,
				  @pnFilterId		= @pnFilterId
End


-- If there is no FilterCriteria passed then construct the @psReturnClause output (the "Where" clause) as the following:

If @nErrorCode = 0
and (datalength(@ptXMLFilterCriteria) = 0
 or datalength(@ptXMLFilterCriteria) is null)
Begin
	exec @nErrorCode = dbo.naw_ConstructNameWhere
			        @psReturnClause			= @sNameFilter		output,
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pbIsExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria		= @ptXMLFilterCriteria,
				@pnFilterGroupIndex		= @nFilterGroupIndex
	
	Set @sWhere =	char(10)+"	Where exists (select *"+
					char(10)+"	"+@sNameFilter+
					char(10)+"	and XN.NAMENO=N.NAMENO)"

	Set @psReturnClause = @sWhere
			 
End
Else Begin
	If @nErrorCode = 0
	Begin
		-- Create an XML document in memory and then retrieve the information 
		-- from the rowset using OPENXML
			
		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
		-- Find out how many times FilterCriteriaGroup repeats in the @ptXMLFilterCriteria parameter
	
		Select	@nFilterGroupCount = count(*)
			from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria',2)
			WITH (
			      id int '@mp:id'		   
			     )			  
				          
		-- Set @nFilterGroupIndex to 1 so it points to the first FilterCriteriaGroup	
		Set @nFilterGroupIndex = 1
		
		Set @nErrorCode=@@Error
	End

	-- Get the name of the temporary table passed in as a parameter and derive a Copy Table name 
	If @nErrorCode=0
	Begin
		If @psTempTableName is null
		Begin
			Set @sCurrentTable = '##SEARCHNAME_' + Cast(@@SPID as varchar(10))
			Set @sCopyTable    = @sCurrentTable+'_COPY'
		End
		Else Begin		
			Set @sCurrentTable=@psTempTableName
			Set @sCopyTable   =@psTempTableName+'_COPY'
		End
	End
		
	-- Loop through each major group of Filter criteria
	While @nFilterGroupIndex <= @nFilterGroupCount
	and @nErrorCode = 0
	Begin
		Set @sRowPattern = "//naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]"
		-- 1) Retrieve the PickListSearch and the BooleanOperator elements using element-centric mapping (implement 
		--    case insensitive searching for the PickListSearch)   
		Select	@sBuildOperator	     = BooleanOperator,
		        @sPickListSearch     = upper(PickListSearch),			
			@sSuitableForNameType= SuitableForNameType,
                        @bAvailableNamesOnly = IsAvailable
		from	OPENXML (@idoc, @sRowPattern,2)
			WITH (
			      BooleanOperator		nvarchar(3)	'@BooleanOperator/text()',
			      PickListSearch		nvarchar(254)	'PickListSearch/text()',
			      SuitableForNameType	nvarchar(3)	'SuitableForNameTypeKey/text()',
                              IsAvailable		bit		'IsAvailable/text()'
			     )			

		If @nFilterGroupCount > 1	
		Begin

			-- Determine if the temporary table holding previous results exists
			if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable )
			Begin
				-- If NAMES have already been saved in a temporary table then
				-- we need to create a Copy table to hold these results so they
				-- can be combined with the next query
				Set @bTempTableExists=1
				Set @sSQLString = 'Create Table ' + @sCopyTable + ' (NAMENO int)'
			End
			Else Begin  
				-- If there are more than one FilterGriteria group then we need to create
				-- a temporary table to store the results if it has not been created already
				Set @bTempTableExists=0
				Set @sSQLString = 'Create Table ' + @sCurrentTable + ' (NAMENO int)'
			End
		
			exec @nErrorCode=sp_executesql @sSQLString
	
			-- the statements above will prepare the temptable needed for this query	
			Set @sSelectList = 'Insert into ' + @sCurrentTable + '(NAMENO) select XN.NAMENO'
		End
		
		-- Construct the "Select", "From" and the "Order by" clauses if the result set is to be returned
		-- (if @nFilterGroupIndex = @nFilterGroupCount)	
		
		-- ACTUAL NAME SEARCH SQL BUILDING BEGINS
		-- now prepair the sql with the available filters specified.
		
		-- Construct the FROM and WHERE clauses used to filter which Names are to be returned
		if @nErrorCode=0
		begin
			exec @nErrorCode = dbo.naw_ConstructNameWhere
			        @psReturnClause			= @sNameFilter		output,
				@pnUserIdentityId		= @pnUserIdentityId,
				@psCulture			= @psCulture,
				@pbIsExternalUser		= @pbIsExternalUser,
				@ptXMLFilterCriteria		= @ptXMLFilterCriteria,
				@pnFilterGroupIndex		= @nFilterGroupIndex
		end
		
		-- This search is performed in stages. As soon as rows are located for a criterion, 
		-- a result set is produced. The search only continues to the next criterion if no 
		-- rows were located.
		-- The PickListSearch field is tokenised on comma, and the first token given special 
		-- treatment as follows:
		-- 1)	Name Code Equal To first token. Note this search should be performed in the same manner
		--	as for NameCode including padding out the name code with leading zeroes as necessary.
		-- 2)	If Name search with both keys site control is on
		--		then Search Key1 or Search Key 2 Starts With @psPickListSearch
		--	Else
		--		Search Key1 Starts With PickListSearch
		-- 3)	If Name search with both keys site control is on
		--		then Search Key1 or Search Key 2 Starts With first token
		--	Else
		--		Search Key1 Starts With first token
		--	(intention is to search on surname if the name was entered as Surname, Given Names)
		-- 4)	Search Key2 Starts With PickListSearch OR the soundex of the first token is the same 
		--	as the soundex of the Name.Name. Note the soundex search is only performed if the 
		-- 	SEARCHSOUNDEXFLAG site control option is on.
	
		If @sPickListSearch is not null
		and @nErrorCode = 0
		Begin
			--------------------------------------------------------
			-- If @sSuitableForNameType is provided, filter criteria 
			-- needs to be obtained from the NameType rules.
			--------------------------------------------------------

			if @sSuitableForNameType is not null
			begin
				----------------------------------------------------------------
				-- If the NameType does not have the "Same Name Type" flag
				-- on then change the NameType used for "Unrestricted Name Type"
				----------------------------------------------------------------
				Set @sSQLString="
				Select @sSuitableForNameType='~~~'
				from NAMETYPE
				where NAMETYPE=@sSuitableForNameType
				and PICKLISTFLAGS&16=0"

				exec @nErrorCode = sp_executesql @sSQLString,
							N'@sSuitableForNameType	nvarchar(3)			output',
							  @sSuitableForNameType		= @sSuitableForNameType	output
			end
			

			-- If there is a comma in the field then only use the data up to the comma.
	
			Select	@sNameSearch=rtrim(Parameter)
			From	dbo.fn_Tokenise(@sPickListSearch, ',')
			Where	InsertOrder=1
	
			-- If the @sNameSearch is numeric then pad it with zeros to the 
			-- predefined length
	
			If isnumeric(@sNameSearch)=1
			Begin
				Select @sNameSearch=Replicate('0',S.COLINTEGER-len(@sNameSearch))+@sNameSearch 
				From SITECONTROL S
				Where S.CONTROLID='NAMECODELENGTH'
			End
	
			-- Check for exact match on NAMECODE

			set @pbExists=0
			set @sSQLString="Select @pbExists=1"+char(10)+
					"from NAME N"
					
			If @sSuitableForNameType is null
			Begin
				set @sSQLString=@sSQLString+char(10)+
					"where N.NAMECODE="+dbo.fn_WrapQuotes(@sNameSearch,0,0)
			End
			Else Begin
				set @sSQLString=@sSQLString+char(10)+
					"join (select distinct N1.NAMENO, NTC1.ALLOW"+char(10)+
					"      from NAME N1"+char(10)+
					"      left join NAMETYPECLASSIFICATION NTC2 on (NTC2.NAMENO=N1.NAMENO and NTC2.NAMETYPE<>'"+@sSuitableForNameType+"')"+char(10)+
					"      left join NAMETYPECLASSIFICATION NTC1 on (NTC1.NAMENO=N1.NAMENO and NTC1.NAMETYPE= '"+@sSuitableForNameType+"')"+char(10)+
					"      Where(NTC1.ALLOW=1 or NTC2.ALLOW=1) ) NTCU on (NTCU.NAMENO = N.NAMENO)"+char(10)+
					"where N.NAMECODE="+dbo.fn_WrapQuotes(@sNameSearch,0,0)

                                        If @bAvailableNamesOnly = 1
                                        Begin
                                                set @sSQLString=@sSQLString+char(10)+ "and NTCU.ALLOW=1"
                                        End
			End
											
					
			set @sSQLString=@sSQLString+char(10)+
					"and exists"+char(10)+
					"(select *"+ char(10)+"	"+@sNameFilter+char(10)+" and XN.NAMENO=N.NAMENO)"
	
			exec sp_executesql @sSQLString,
					N'@pbExists		bit	OUTPUT',
					  @pbExists=@pbExists 		OUTPUT
	
			If @pbExists=1
			Begin
				set @sNameFilter=@sNameFilter+char(10)+"	and XN.NAMECODE="+dbo.fn_WrapQuotes(@sNameSearch,0,0)
			End
			Else Begin

				-- If Name search with both keys site control is on 
				-- Search Key 1 or Search Key 2 begins with entered text
	
				set @sSQLString="Select @bSearchBothKeys=1"+char(10)+
						"from SITECONTROL"+char(10)+
						"where CONTROLID = 'Name search with both keys'"+char(10)+
						"and   COLBOOLEAN=1"
	
				exec sp_executesql @sSQLString,
						N'@bSearchBothKeys	bit		OUTPUT',
						  @bSearchBothKeys=@bSearchBothKeys 	OUTPUT
			
				-- Check for partial match on SEARCHKEY1 (or SEARCHKEY2) with the full PickListSearch

				set @sSQLString="Select @pbExists=1"+char(10)+
						"from NAME N"+char(10)+
						"where (N.SEARCHKEY1 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)+char(10)+
						CASE 	WHEN @bSearchBothKeys=1 
							THEN "or N.SEARCHKEY2 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)
						END+")"+
						"and exists"+char(10)+
						"(select *"+ char(10)+"	"+@sNameFilter+char(10)+" and XN.NAMENO=N.NAMENO)"
	
				exec sp_executesql @sSQLString,
						N'@pbExists		bit	OUTPUT',
						  @pbExists=@pbExists 		OUTPUT							
				
				If @pbExists=1
				Begin
					set @sNameFilter=@sNameFilter+char(10)+"	and (XN.SEARCHKEY1 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)+char(10)+
										CASE 	WHEN @bSearchBothKeys=1 
											THEN "or XN.SEARCHKEY2 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)
										END+")"
				End						
				Else Begin
					
					-- Check for partial match on SEARCHKEY1 (or SEARCHKEY2) for the first part of the PickListSearch
	
					set @sSQLString="Select @pbExists=1"+char(10)+
							"from NAME N"+char(10)+
							"where (N.SEARCHKEY1 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)+char(10)+				
							CASE 	WHEN @bSearchBothKeys=1 
								THEN "or N.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)
							END+")"+				
							"and exists"+char(10)+
							"(select *"+ char(10)+"	"+@sNameFilter+char(10)+" and XN.NAMENO=N.NAMENO)"
		
					exec sp_executesql @sSQLString,
							N'@pbExists		bit	OUTPUT',
							  @pbExists=@pbExists 		OUTPUT
			
					If @pbExists=1
					Begin
						set @sNameFilter=@sNameFilter+char(10)+"	and (XN.SEARCHKEY1 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)+char(10)+
											CASE 	WHEN @bSearchBothKeys=1 
												THEN "or XN.SEARCHKEY2 like "+dbo.fn_WrapQuotes(@sNameSearch+"%",0,0)
											END+")"
					End	
					-- If the Sitecontrol for searching by Sound Alike is on then search
					-- on Searchkey2 or the Sound alike 
					Else If exists (select * from SITECONTROL SC
							where SC.CONTROLID='SEARCHSOUNDEXFLAG'
							and SC.COLBOOLEAN=1)
					Begin
						set @sNameFilter=@sNameFilter+char(10)+"	and (XN.SEARCHKEY2 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)+" OR XN.SOUNDEX=dbo.fn_SoundsLike("+dbo.fn_WrapQuotes(@sPickListSearch,0,0)+"))"

						set @nErrorCode = @@Error 
					End
					-- Otherwise just search on Searchkey2
					Else Begin
						set @sNameFilter=@sNameFilter+char(10)+"	and (  UPPER(XN.NAME) like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
						set @sNameFilter=@sNameFilter+char(10)+"	or  UPPER(XN.NAMECODE) like "+dbo.fn_WrapQuotes(@sPickListSearch+"%",0,0)
						set @sNameFilter=@sNameFilter+char(10)+"	or XN.SEARCHKEY1 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)
						set @sNameFilter=@sNameFilter+char(10)+"	or XN.SEARCHKEY2 like "+dbo.fn_WrapQuotes(RTRIM(LTRIM(left(@sPickListSearch,20)))+"%",0,0)
						set @sNameFilter=@sNameFilter+char(10)+"	)"
					End
				End
			End
		End

		-- Check if the result set is to be returned

		if @nFilterGroupIndex = @nFilterGroupCount 
		and @nErrorCode=0
		begin
			if @bTempTableExists = 0
			begin
				-- No previous results were returned so just combine the filter
				-- details returned to create a simple WHERE EXISTS clause
			
				Set @sWhere =	char(10)+"	Where exists (select *"+
						char(10)+"	"+@sNameFilter+
						char(10)+"	and XN.NAMENO=N.NAMENO)"
			end
			else begin
				-- if previous result set details have been returned then they need
				-- to be combined with new query using the boolean operator passed
				-- as a parameter
				if upper(@sBuildOperator)='AND'
				begin
					-- insert an additional join to ensure the contents of the 
					-- previous queries also match with the current query
		
					set @sNameFilter=replace(@sNameFilter,'WHERE 1=1', '     join '+@sCurrentTable+' TC On (TC.NAMENO=XN.NAMENO)'+char(10)+'	WHERE 1=1')
					Set @sWhere =	char(10)+"	Where exists (select XN.NAMENO"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=N.NAMENO)"
				end
				else if upper(@sBuildOperator)='OR'
				begin
					-- combine the results of the previous queries with the
					-- results of the current query
		
					Set @sWhere =	char(10)+"	where exists (select XN.NAMENO"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=N.NAMENO"+
							char(10)+"	union all"+
							char(10)+"	select TC.NAMENO"+
							char(10)+"	from "+@sCurrentTable+" TC"+
							char(10)+"	where TC.NAMENO=N.NAMENO)"
				end
				else if upper(@sBuildOperator)='NOT'
				begin
					-- We want the Names from the previous queries that 
					-- do not match with the current query
		
					Set @sWhere =	char(10)+"	where exists("+
							char(10)+"	select TC.NAMENO"+
							char(10)+"	from "+@sCurrentTable+" TC"+
							char(10)+"	where TC.NAMENO=N.NAMENO)"+
							char(10)+"	and not exists"+
							char(10)+"	(select XN.NAMENO"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=N.NAMENO)"
				end
			end
				
			-- Finally set the @psReturnClause (the constructed 'Where' clause) and the @psTempTableName 
			-- to output them to the calling stored procedure
			
			set @psReturnClause = @sWhere
			
			set @psTempTableName = @sCurrentTable
			
		end	
		else if @nErrorCode=0
		     and @nFilterGroupIndex < @nFilterGroupCount 
		begin
			-- Results are not being returned so we need to save the results
			-- in a temporary table.  
			
			if @bTempTableExists = 0
			begin
				-- This is the first search so it needs to be saved into a
				-- temporary table without the need to refer to earlier search results.
	
				exec (@sSelectList + @sNameFilter)
	
				select 	@nErrorCode =@@Error
			end	
			else begin
				-- A previous query has already been run and the results saved to a temporary
				-- table. Copy the Names from the first temporary table to another table
	
				Set  @sSQLString = 'Insert into ' + @sCopyTable + '(NAMENO) select NAMENO from ' + @sCurrentTable
	
				exec @nErrorCode=sp_executesql @sSQLString
	
				-- Now clear out the first temporary table so the Names returned from the
				-- current query can be loaded in combination with the previous query
	
				if @nErrorCode=0
				begin
					Set @sSQLString = 'delete from ' + @sCurrentTable
					exec sp_executesql @sSQLString
				end
	
				-- if previous result set details have been returned then they need
				-- to be combined with a new query using the boolean operator passed
			 	-- as a parameter
	
				if upper(@sBuildOperator)='AND'
				and @nErrorCode=0
				begin
					-- insert an additional join to ensure the contents of the 
					-- previous queries also match with the current query
	
					set @sNameFilter=replace(@sNameFilter,'WHERE 1=1', '     join '+@sCopyTable+' TC On (TC.NAMENO=XN.NAMENO)'+char(10)+'	WHERE 1=1')
					Set @sWhere =	char(10)+"	"+@sNameFilter
				end
				else if upper(@sBuildOperator)='OR'
				     and @nErrorCode=0
				begin
					-- combine the results of the previous queries with the
					-- results of the current query
	
					Set @sWhere =	char(10)+"	"+@sNameFilter+
							char(10)+"	union"+
							char(10)+"	select TC.NAMENO"+
							char(10)+"	from "+@sCopyTable+" TC"
				end
				else if upper(@sBuildOperator)='NOT'
				     and @nErrorCode=0
				begin
					-- We want the Names from the previous queries that 
					-- do not match with the current query
	
					Set @sSelectList = 'Insert into ' + @sCurrentTable + '(NAMENO) select TC.NAMENO'
	
					Set @sWhere =	char(10)+"	from "+@sCopyTable+" TC"+
							char(10)+"	where not exists (select *"+
							char(10)+"	"+@sNameFilter+
							char(10)+"	and XN.NAMENO=TC.NAMENO)"
				end
	
				-- Now execute the constructed SQL to return the combined result 
				If @nErrorCode=0
				Begin
					exec (@sSelectList + @sFrom + @sWhere)
					select 	@nErrorCode =@@Error
				End
					
			end
		end

		-- Drop the copy temporary table if it exists
				
		if exists(select * from tempdb.dbo.sysobjects where name = @sCopyTable)
		and @nErrorCode=0
		begin
			set @sSQLString = 'drop table ' + @sCopyTable
			exec @nErrorCode=sp_executesql @sSQLString			
		end

		-- SQA9689
		-- Check to see if there are any manually entered Names

		If @nErrorCode=0
		Begin
			Set @sRowPattern = "//naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/AddedNamesGroup/NameKey"
			Set @bAddedNames = 0
	
			Set @sSQLString="
			Select @bAddedNames=1
			from	OPENXML (@idoc, @sRowPattern, 2)
			WITH (CaseKey	int	'text()')
			Where CaseKey is not null"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@bAddedNames		bit	Output,
						  @idoc			int,
						  @sRowPattern		varchar(100)',
						  @bAddedNames=@bAddedNames	Output,
						  @idoc=@idoc,
						  @sRowPattern=@sRowPattern
		End

		-- Check to see if there are any ticked Names

		If @nErrorCode=0
		Begin
			Set @sRowPattern1 = "//naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/SelectedNamesGroup"
			Set @bTickedNames = 0

			Set @sSQLString="
			Select	@bOperator	= Operator,
				@bTickedNames	= 1
			from	OPENXML (@idoc, @sRowPattern1,2)
				WITH (
				      Operator	bit	'@Operator/text()'
				     )
			Where Operator in (1,0)"
	
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@bOperator		bit	Output,
						  @bTickedNames		bit	Output,
						  @idoc			int,
						  @sRowPattern1		varchar(100)',
						  @bOperator=@bOperator		Output,
						  @bTickedNames=@bTickedNames	Output,
						  @idoc=@idoc,
						  @sRowPattern1=@sRowPattern1
		End

		If @nErrorCode=0
		and (@bAddedNames=1 or @bTickedNames=1)
		Begin
			-- If only 1 Filter Group then create a temporary table to hold
			-- the results of the filter before adding the manually added Names.
			If @nFilterGroupCount=1
			Begin
				Set @sSQLString = 'Create Table ' + @sCurrentTable + ' (NAMENO int)'
				exec @nErrorCode=sp_executesql @sSQLString

				Set @sSelectList = 'Insert into ' + @sCurrentTable + '(NAMENO) select XN.NAMENO'

				exec (@sSelectList + @sNameFilter)
		
				set @nErrorCode =@@Error
			End
			-- If the final Filter Group has been processed and there were more than one
			-- Filter Group then create another temporary table to load the final result into
			Else If @nFilterGroupIndex=@nFilterGroupCount
			Begin
				Set @sSQLString = 'Create Table ' + @sCopyTable + ' (NAMENO int)'
				exec @nErrorCode=sp_executesql @sSQLString

				Set @sSelectList = 'Insert into ' + @sCopyTable + '(NAMENO) select N.NAMENO From NAME N WHERE 1=1'

				exec (@sSelectList + @sWhere)
		
				select 	@nErrorCode =@@Error

				-- Drop the CurrentTable as it is going to be replaced with
				-- another table.
				If @nErrorCode=0
				Begin
					set @sSQLString = 'drop table ' + @sCurrentTable
					exec @nErrorCode=sp_executesql @sSQLString	
				End

				Set @sCurrentTable=@sCopyTable
			End

			-- Add the manually entered Names to the temporary table
			If  @nErrorCode=0
			and @bAddedNames=1
			Begin
				Set @sSQLString="Insert into "+@sCurrentTable +"(NAMENO)"+char(10)+
					  "Select NameKey"+char(10)+
					  "from	OPENXML (@idoc, @sRowPattern, 2)"+char(10)+
					  "WITH (NameKey	int	'text()')"+char(10)+
					  "Where NameKey is not null"+char(10)+
					  "and not exists(select * from "+@sCurrentTable+" where NAMENO=NameKey)"
	
				exec @nErrorCode=sp_executesql @sSQLString,
								N'@idoc		int,
								  @sRowPattern	varchar(100)',
								  @idoc=@idoc,
								  @sRowPattern=@sRowPattern
			End

			-- If there are ticked Names then remove the Names in the temporary table 
			-- that match the ticked Names when Operator=1 or that do not match
			-- the ticked Names when Operator=0

			If  @nErrorCode=0
			and @bTickedNames=1
			Begin
				Set @sRowPattern1 = "//naw_ListName/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @nFilterGroupIndex)+"]/SelectedNamesGroup/NameKey"
		
				If @bOperator=0
				Begin
					Set @sSQLString="Delete "+@sCurrentTable+char(10)+
						  "from "  +@sCurrentTable+" X"+char(10)+
						  "left join (	select NameKey"+char(10)+
						  "		from	OPENXML (@idoc, @sRowPattern1, 2)"+char(10)+
						  "		WITH (NameKey	int	'text()')"+char(10)+
						  "		Where NameKey is not null) N on (N.NameKey=X.NAMENO)"+char(10)+
						  "where N.NameKey is null"
				End
				Else Begin
					Set @sSQLString="Delete "+@sCurrentTable+char(10)+
						  "from "  +@sCurrentTable+" X"+char(10)+
						  "join (	select NameKey"+char(10)+
						  "		from	OPENXML (@idoc, @sRowPattern1, 2)"+char(10)+
						  "		WITH (NameKey	int	'text()')"+char(10)+
						  "		Where NameKey is not null) N on (N.NameKey=X.NAMENO)"
				End

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@idoc			int,
							  @sRowPattern1		varchar(100)',
							  @idoc=@idoc,
							  @sRowPattern1=@sRowPattern1
			End
		
			-- The current Where clause can now be modified to just return the Cases 
			-- in the temporary table.
			Set @psReturnClause =	char(10)+"	and exists (select XN.NAMENO from "+@sCurrentTable+" XN"+
						char(10)+"	where XN.NAMENO=N.NAMENO)"
		End
		
		-- Set @nFilterGroupIndex to point to the next FilterCriteriaGroup	
		Set @nFilterGroupIndex = @nFilterGroupIndex + 1			
		
	End -- End of the "While" loop
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

End

RETURN @nErrorCode
GO

Grant execute on dbo.naw_FilterNames  to public
GO





