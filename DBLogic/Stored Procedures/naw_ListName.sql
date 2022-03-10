-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[naw_ListName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.naw_ListName.'
	drop procedure dbo.naw_ListName
	print '**** Creating procedure dbo.naw_ListName...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_ListName
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure.
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null,
	@pnCallingLevel			smallint	= null,	-- Optional number that acknowledges multiple calls of 
								-- the stored procedure from the one connection and
								-- ensures there is no temporary table conflict
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out.
	@pbReturnResultSet		bit		= 1,	-- Allows explicit control of whether the Case result list should be returned.
	@pbGetTotalNameCount		bit		= 1	-- Allows explicit control of execution of Count against constructed SQL.
)		
-- PROCEDURE :	naw_ListName
-- VERSION :	29
-- DESCRIPTION:	Searches and return matching names as a result set.
-- CALLED BY :	

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02 Oct 2003	JEK		1	New .net version based on v25 of na_ListName.	
-- 28 Oct 2003	TM	RFC537	2	Change filter functions to stored procedures. 
--					Call new naw_FilterNames stored procedure instead of 
--					the fnw_FilterNames function.
-- 07 Nov 2003	MF	RFC586	3	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 20 Nov 2003	TM	RFC612	4	Implement Name Quick Search. Add new @pnQueryContextKey, @ptXMLOutputRequests and 
--					@ptXMLFilterCriteria parameters. Modify call to the naw_ConstructNameSelect and
--					naw_FilterNames to pass new parameters. 
-- 29 Nov 2003	JEK	RFC612	5	Remove parameters that were replaced by @ptXMLOutputRequests.
-- 09 Dec 2003	JEK	RFC643	6	Change type of QueryContextKey.
-- 11 Dec 2003	JEK	RFC603	7	Temporary implementation of pick list parameters as XML.
-- 16 Dec 2003	JEK	RFC408	8	Additional pick list filter criteria - IsStaff and IsIndividual
-- 19 Dec 2003	JEK	RFC408	9	Extract IsOrganisation from XML.
-- 22 Dec 2003	TM	RFC710	10	Adjust to call naw_FilterNames using the new interfaces.
-- 08 Nov 2004	TM	RFC1980	11	Save the fn_GetLookupCulture in @psCulture to improve performance.
-- 23 Dec 2004	TM	RFC1844	12 	Create a new temporary table #TempConstructSQL and implement four nvarchar(4000) 
--					variables for each 'Select' and 'From' clause similar to the csw_ListCase when 
--					it is called form the WorkBenches.
-- 15 May 2005	JEK	RFC2508	13	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 24 Oct 2005	TM	RFC3024	14	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 09 Mar 2006	TM	RFC3465 15	Add three new parameters @pnPageStartRow, @pnPageEndRow and implement
--					SQL Server Paging.
-- 13 Dec 2006	MF	14002	16	Paging should not do a separate count() on the database if the rows returned
--					are less than the maximum allowed for.
-- 26 Jun 2008	LP	RFC4342	17	Pass new @psNameTypeKey parameter to naw_ConstructNameSelect.	
-- 11 Sep 2008  LP      RFC5729 18      Create new temporary table for storing specific NameKeys.
-- 14 Jan 2008	MF	RFC7483	19	Extend name searching to allow complex boolean searches of multiple Name queries
-- 25 May 2009  vql     SQA17723  20     Conflict Search crashing. Remove the @pbExternalUser parameter, when calling naw_ConstructNameSelect.
-- 21 Jul 2009	MF	17748	21	Reduce locking level to ensure other activities are not blocked.
-- 01 Dec 2009	MF	RFC6208	22	Improve performance by allowing control of whether the count for the entire result set should be executed and
--					also introduce a new paging mechanism now available from SQLServer 2005.
-- 06 May 2011	MF	RFC10544 23	As a result of RFC6208 we need to reverse the change introduced as 14002. This is because the new
--					paging mechanism no longer returns the entire result RowCount.
-- 24 Sep 2012  DV      R100762	24	Convert @sWhereFilter to nvarchar(max)
-- 18 Apr 2013	MF	R13142	25	While working on this issue, change the way constructed SQL was printed so that it would not be truncated.
-- 23 May 2014	LP	R29589	26	Allow hiding of Names flagged as Unavailable. By default they will be displayed.
-- 02 Sep 2014	MF	R38107	27	Process Case Filters used to help determine the Names to be reported.
-- 16 Sep 2014  AK	R38107	28	Changed xml path for casenamefilter criteria.
-- 14 Aug 2017	MF	72127	29	When @pbGetTotalNameCount indicates row count is to be returned then count the distinct set of N.NAMENO values.
-- 12 Jul 2019	KT	DR-49980 30	Added @bCurrentNamesOnly for naw_ConstructNameSelect to get only ceased records not unavailable records too.
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF	

-- Create a temporary table to be used in the construction of the SELECT.
Create table #TempConstructSQL (Position	smallint	identity(1,1),
				ComponentType	char(1) collate database_default,
				SavedString	nvarchar(4000) collate database_default
				)
				
CREATE TABLE #TEMPNAMELIST (	NAMENOID	smallint	identity(1,1),
				NAMENO	        int             null
				)


Declare @nErrorCode		int

Declare @nTableCount		tinyint

Declare @sCurrentTable 		nvarchar(60)	
Declare @sCurrentCaseTable 	nvarchar(60)
Declare @sResultTable		nvarchar(60)
Declare @sCopyTable		nvarchar(60)
Declare @sOldTable		nvarchar(60)

Declare @bTempTableExists	bit
Declare	@bExternalUser		bit
Declare @pbExists		bit
Declare	@bCaseCountRequired	bit
Declare	@bNameTypeRequired	bit
Declare @sNameTypeKey		nvarchar(6)	-- NameTypeKey to restrict results by
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
Declare @bAvailableNamesOnly	bit		-- Parameter to indicate that Unavailable names should be hidden; defaulted to 0.
Declare @bCurrentNamesOnly	bit		-- Parameter to indicate that ceased names should be hidden; defaulted to 0.
Declare	@sNameTypeKeys		nvarchar(100)	-- NameTypeKeys to restrict Names used by a Cases by
Declare	@nNameTypeKeysOperator	tinyint		
Declare	@nNumberOfCases		int		-- Number of Cases for a Name & Name Type combination to restrict Names returned by
Declare	@nNumberOfCasesOperator	tinyint		
	
Declare @sSQLString		nvarchar(max)
Declare	@sSelectList1		nvarchar(max)	-- the SQL list of columns to return
Declare	@sSelectList2		nvarchar(max)
Declare	@sSelectList3		nvarchar(max)
Declare	@sSelectList4		nvarchar(max)
Declare	@sFrom1			nvarchar(max)	-- the SQL to list tables and joins
Declare	@sFrom2			nvarchar(max)
Declare	@sFrom3			nvarchar(max)
Declare	@sFrom4			nvarchar(max)
Declare @sWhere			nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructNameSelect)
Declare @sWhereFilter		nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the naw_FilterNames)
Declare @sCaseWhereFilter	nvarchar(max) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseWhere)
Declare	@sCaseNameFrom		nvarchar(max)
Declare	@sCaseNameWhere		nvarchar(max)
Declare @sOrder			nvarchar(max)	-- the SQL sort order
Declare @sCountSelect		nvarchar(max)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare	@sTopSelectList1	nvarchar(max)	-- the SQL list of columns to return modified for paging
Declare	@sOpenWrapper		nvarchar(max)
Declare @sCloseWrapper		nvarchar(max)

Declare @Numeric		nchar(1)
Declare @CommaString		nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String

Set @Numeric			='N'
Set @CommaString		='CS'

Set @nErrorCode			= 0
Set @bAvailableNamesOnly	= 0
Set @bCurrentNamesOnly		= 0
Set @bCaseCountRequired		= 0
Set @bNameTypeRequired		= 0

Declare @sLookupCulture		nvarchar(10)

-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString='
	Select	@bExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser=@bExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End

-- Construct the name of the temporary table used to hold Names for complex searches.

Set @sCurrentTable = '##SEARCHNAME_' + Cast(@@SPID as varchar(10))+'_' + Cast(@pnQueryContextKey as varchar(15))
				     + CASE WHEN(@pnCallingLevel is not null) THEN '_'+Cast(@pnCallingLevel as varchar(6)) END
Set @sResultTable  = @sCurrentTable+'_RESULT'
Set @sCopyTable    = @sCurrentTable+'_COPY'

-- Now drop the temporary table holding the results.  
-- This is because the temporary table must persist after the completion of the stored procedure
-- to allow for scrolling.
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
and @nErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sCurrentTable

	exec @nErrorCode=sp_executesql @sSQLString
End

-- The temporary table name may have changed when additional Names have been 
-- added or ticked Names used.
If exists(select * from tempdb.dbo.sysobjects where name = @sCopyTable)
and @nErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sCopyTable

	exec @nErrorCode=sp_executesql @sSQLString
End

-- The temporary table name may have changed when extended column details were requested
-- in the previous execution.
If exists(select * from tempdb.dbo.sysobjects where name = @sResultTable)
and @nErrorCode=0
Begin
	Set @sSQLString = "drop table "+@sResultTable

	exec @nErrorCode=sp_executesql @sSQLString
End

-- Call the naw_FilterNames that is responsible for the management of the multiple occurrences of the filter criteria 
-- and the production of an appropriate result set. It calls csw_ConstructNameWhere to obtain the where clause for each
-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
-- table that may hold the filtered list of names.

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.naw_FilterNames	@psReturnClause 	= @sWhereFilter	  	OUTPUT, 			
						@psTempTableName 	= @sCurrentTable	OUTPUT,
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria	
End

-- The Cases derived table needs only to be constructed when the XMLFilterCriteria includes "csw_ListCase" filtering.
If  @nErrorCode = 0
and @ptXMLFilterCriteria like '%<csw_ListCase>%'
Begin
	-- Call the csw_FilterCases that is responsible for the management of the multiple occurrences of the filter criteria 
	-- and the production of an appropriate result set. It calls csw_ConstructCaseWhere to obtain the where clause for each
	-- separate occurrence of FilterCriteria.  The @psTempTableName output parameter is the name of the the global temporary
	-- table that may hold the filtered list of cases.

	
	exec @nErrorCode = dbo.csw_FilterCases	@psReturnClause 	= @sCaseWhereFilter  	OUTPUT, 			
						@psTempTableName 	= @sCurrentCaseTable	OUTPUT,	
						@pnUserIdentityId	= @pnUserIdentityId,	
						@psCulture		= @psCulture,	
						@pbIsExternalUser	= @bExternalUser,
						@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
					    	@pbCalledFromCentura	= 0
End

-- Retrieve NameTypeKey if requested from calling code
-- Set flag to hide or display names flagged as Unavailable
If @nErrorCode = 0
and (datalength(@ptXMLFilterCriteria) > 0)
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = "
		Select	@sNameTypeKey = SuitableForNameTypeKey,
			@bAvailableNamesOnly = IsAvailable,
			@bCurrentNamesOnly = IsCurrent 
			from	OPENXML (@idoc, '/naw_ListName/FilterCriteriaGroup/FilterCriteria',2)
			WITH (
			       SuitableForNameTypeKey	nvarchar(6)	'SuitableForNameTypeKey/text()',
			       IsAvailable		bit		'IsAvailable/text()',
			       IsCurrent		bit		'IsCurrent/text()'
			     )"		

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @sNameTypeKey 		nvarchar(6)		output,
				  @bAvailableNamesOnly		bit			output,
				  @bCurrentNamesOnly		bit			output',	
				  @idoc				= @idoc,
				  @sNameTypeKey 		= @sNameTypeKey		output,
				  @bAvailableNamesOnly		= @bAvailableNamesOnly	output,
				  @bCurrentNamesOnly		= @bCurrentNamesOnly	output
End

-- Construct the "Select", "From" and the "Order by" clauses 
if @nErrorCode=0 
Begin
	exec @nErrorCode=dbo.naw_ConstructNameSelect	@pnTableCount		= @nTableCount	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@psTempTableName	= @sCurrentTable,
							@pnQueryContextKey	= @pnQueryContextKey,
							@ptXMLOutputRequests	= @ptXMLOutputRequests,
							@pbCalledFromCentura	= @pbCalledFromCentura,
							@psNameTypeKey		= @sNameTypeKey,
							@pbAvailableNamesOnly	= @bAvailableNamesOnly,
							@pbCurrentNamesOnly	= @bCurrentNamesOnly
End
		
	
-- Now execute the constructed SQL to return the result set

If @nErrorCode=0 
Begin 	
	Set @sSQLString="
	Select 	@sSelectList1=S.SavedString, 
		@sFrom       =F.SavedString, 
		@sWhere      =W.SavedString,  		
		@sOrder      =O.SavedString
	from #TempConstructSQL W	
	left join #TempConstructSQL F	on (F.ComponentType='F'
					and F.Position=(select min(F1.Position)
							from #TempConstructSQL F1
							where F1.ComponentType=F.ComponentType))
	left join #TempConstructSQL S	on (S.ComponentType='S'
					and S.Position=(select min(S1.Position)
							from #TempConstructSQL S1
							where S1.ComponentType=S.ComponentType))	
	left join #TempConstructSQL O	on (O.ComponentType='O')	-- there will only be 1 OrderBy row	
	Where W.ComponentType='W'"				-- there will only be 1 Select row

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@sSelectList1		nvarchar(4000)	OUTPUT,
					  @sFrom		nvarchar(4000)	OUTPUT,
					  @sWhere		nvarchar(4000)	OUTPUT,
					  @sOrder		nvarchar(4000)	OUTPUT',
					  @sSelectList1=@sSelectList1		OUTPUT,
					  @sFrom       =@sFrom1			OUTPUT,
					  @sWhere      =@sWhere			OUTPUT,
					  @sOrder      =@sOrder			OUTPUT

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
	
	-------------------------------------------------
	-- Extract the possible filters that will require
	-- CaseNames to be considered.  These include the
	-- nametype(s) and case count.
	-------------------------------------------------
	If @nErrorCode = 0
	and (datalength(@ptXMLFilterCriteria) > 0)
	Begin
		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
		
		Set @sSQLString = "
			Select	@sNameTypeKeys          = NameTypeKeys,
				@nNameTypeKeysOperator  = NameTypeKeysOperator,
				@nNumberOfCases         = NumberOfCases,
				@nNumberOfCasesOperator = NumberOfCasesOperator
				from	OPENXML (@idoc, '/naw_ListName/ColumnFilterCriteria/CaseNameFilter',2)
				WITH (
				       NameTypeKeys		nvarchar(100)	'NameTypeKeys/text()',
				       NameTypeKeysOperator	tinyint		'NameTypeKeys/@Operator/text()',
				       NumberOfCases		int		'NumberOfCases/text()',
				       NumberOfCasesOperator	tinyint		'NumberOfCases/@Operator/text()'
				     )"		

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @sNameTypeKeys		nvarchar(100)		output,
					  @nNameTypeKeysOperator	tinyint			output,
					  @nNumberOfCases		int			output,
					  @nNumberOfCasesOperator	tinyint			output',	
					  @idoc				= @idoc,
					  @sNameTypeKeys		= @sNameTypeKeys	  output,
					  @nNameTypeKeysOperator	= @nNameTypeKeysOperator  output,
					  @nNumberOfCases		= @nNumberOfCases	  output,
					  @nNumberOfCasesOperator	= @nNumberOfCasesOperator output
	End
		
	
	-------------------------------------------------
	-- Check if any columns associated with the Case
	-- Name count are being reported on.
	-------------------------------------------------
	If @nErrorCode = 0
	Begin
		-- Create an XML document in memory and then retrieve the information 
		-- from the rowset using OPENXML		
		exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
		
		Select @bCaseCountRequired=1
		from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)
		where COLUMNID in ('CaseCount')
		
		Select @bNameTypeRequired=1
		from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)
		where COLUMNID in ('NameType')
	End
	---------------------------------------
	-- Construct any filtering required for
	-- Names being referenced by Cases
	---------------------------------------
	If @sCaseWhereFilter is not null
	or @sNameTypeKeys    is not null
	or @nNameTypeKeysOperator in (5,6)
	or @nNumberOfCases   is not null
	or @nNumberOfCasesOperator in (5,6)
	or @bCaseCountRequired = 1
	or @bNameTypeRequired  = 1
	Begin
		Set @sCaseNameFrom =  "Left Join (select C.NAMENO, C.NAMETYPE, count(*) as CASECOUNT"+CHAR(10)+
				      "           from CASENAME C"+CHAR(10)+
				      "           where C.EXPIRYDATE IS NULL"+CHAR(10)
				      
		If @sCaseWhereFilter is not null
			Set @sCaseNameFrom=@sCaseNameFrom+@sCaseWhereFilter+CHAR(10)
			
		Set @sCaseNameFrom = @sCaseNameFrom+
				      "           group by C.NAMENO, C.NAMETYPE) CN on (CN.NAMENO=N.NAMENO)"+CHAR(10)	
				      
		If @bNameTypeRequired = 1
			Set @sCaseNameFrom =  @sCaseNameFrom+
				      "Left Join NAMETYPE NX on (NX.NAMETYPE=CN.NAMETYPE)"+CHAR(10)
				      
		If @sNameTypeKeys is not null
		or @nNameTypeKeysOperator in (5,6)
			Set @sCaseNameWhere='and CN.NAMETYPE'+dbo.fn_ConstructOperator(@nNameTypeKeysOperator,@CommaString,@sNameTypeKeys, null,0)
			
		If @nNumberOfCases is not null
		or @nNumberOfCasesOperator in (5,6)
			Set @sCaseNameWhere=isnull(@sCaseNameWhere,'')+char(10)+
			                    'and CN.CASECOUNT'+dbo.fn_ConstructOperator(@nNumberOfCasesOperator,@Numeric,@nNumberOfCases, null,0)
			                    
		--------------------------------------------
		-- If Case Filter is active and the CaseName
		-- Where clause has not yet been set then
		-- force the existence of Cases for the Name
		--------------------------------------------
		If  @sCaseNameWhere is null
		and @sCaseWhereFilter is not null
			Set @sCaseNameWhere='and CN.CASECOUNT>0'
			
		--------------------------------------
		-- The result set requires DISTINCT if 
		-- the Name may appear multiple times
		-- in the derived CASENAME.
		--------------------------------------
		Set @sSelectList1 = REPLACE(@sSelectList1, 'Select ', 'Select DISTINCT ')
	End

	If @nErrorCode=0 
	Begin 	
		-- No paging required
		If (@pnPageStartRow is null or
		    @pnPageEndRow is null)
		Begin
			Set @sSQLString=cast('SET ANSI_NULLS OFF ' as nvarchar(max))
			      +CHAR(10)+@sSelectList1 
			      +CHAR(10)+@sSelectList2 
			      +CHAR(10)+@sSelectList3 
			      +CHAR(10)+@sSelectList4 
			      +CHAR(10)+@sFrom1 
			      +CHAR(10)+@sFrom2 
			      +CHAR(10)+@sFrom3 
			      +CHAR(10)+@sFrom4 
			      +CHAR(10)+@sCaseNameFrom
			      +CHAR(10)+@sWhere 
			      +CHAR(10)+@sWhereFilter 
			      +CHAR(10)+@sCaseNameWhere
			      +CHAR(10)+@sOrder

			If @pbPrintSQL=1
				Print @sSQLString
			
			Exec @nErrorCode=sp_executesql @sSQLString
						
			Set @pnRowCount=@@Rowcount
		End
		-- Paging required
		Else Begin
			If @sSelectList1 like 'Select DISTINCT%'
				Set @sTopSelectList1 = replace(@sSelectList1,'Select DISTINCT', 'Select DISTINCT TOP 100 percent ')
			Else
				Set @sTopSelectList1 = replace(@sSelectList1,'Select', 'Select TOP 100 percent')
				
			Set @sCountSelect = ' Select count(distinct N.NAMENO) as SearchSetTotalRows '  
			
			Set @sOpenWrapper = char(10)+
					    'select *'+char(10)+
					    'from ('+char(10)+
					    'select *, ROW_NUMBER() OVER ('+@sOrder+') as RowKey'+char(10)+
					    'FROM ('+char(10)
					 
			Set @sCloseWrapper = ') as NamesSorted'+char(10)+
					     ') as NamesWithRow'+char(10)+
					     'where RowKey>='+cast(@pnPageStartRow as varchar)+' and RowKey<='+cast(@pnPageEndRow as varchar)

			If @pbReturnResultSet=1
			Begin
				Set @sSQLString=cast('SET ANSI_NULLS OFF ' as nvarchar(max))
				      +CHAR(10)+@sOpenWrapper
				      +CHAR(10)+@sTopSelectList1 
				      +CHAR(10)+@sSelectList2 
				      +CHAR(10)+@sSelectList3 
				      +CHAR(10)+@sSelectList4 
				      +CHAR(10)+@sFrom1 
				      +CHAR(10)+@sFrom2 
				      +CHAR(10)+@sFrom3 
				      +CHAR(10)+@sFrom4 
				      +CHAR(10)+@sCaseNameFrom
				      +CHAR(10)+@sWhere 
				      +CHAR(10)+@sWhereFilter 
				      +CHAR(10)+@sCaseNameWhere
				      +CHAR(10)+@sOrder
				      +CHAR(10)+@sCloseWrapper

				If @pbPrintSQL=1
					Print @sSQLString
				
				Exec @nErrorCode=sp_executesql @sSQLString
							
				Set @pnRowCount=@@Rowcount
			End
						
			If isnull(@pbGetTotalNameCount,0)=0
			and @nErrorCode=0
			Begin
				set @sSQLString='select -1 as SearchSetTotalRows'  

				exec @nErrorCode=sp_executesql @sSQLString
			End	
			Else If @nErrorCode=0 
			Begin
				Set @sSQLString=CAST('SET ANSI_NULLS OFF ' as nvarchar(max))
				      +CHAR(10)+@sCountSelect
				      +CHAR(10)+@sFrom1 
				      +CHAR(10)+@sFrom2 
				      +CHAR(10)+@sFrom3 
				      +CHAR(10)+@sFrom4 
				      +CHAR(10)+@sCaseNameFrom
				      +CHAR(10)+@sWhere 
				      +CHAR(10)+@sWhereFilter 
				      +CHAR(10)+@sCaseNameWhere
				      
				If @pbPrintSQL = 1
					Print @sSQLString
					
				exec @nErrorCode=sp_executesql @sSQLString
			End		
		End
				
		-- Now drop the temporary table holding the results
		
		if exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
		and @nErrorCode=0
		Begin
			Set @sSQLString = "drop table "+@sCurrentTable
		
			exec @nErrorCode=sp_executesql @sSQLString
		End
	End	
End


RETURN @nErrorCode
GO

Grant execute on dbo.naw_ListName  to public
GO



