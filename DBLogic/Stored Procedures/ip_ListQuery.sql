-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListQuery
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ListQuery]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop procedure dbo.ip_ListQuery.'
	Drop procedure dbo.ip_ListQuery
	Print '**** Creating procedure dbo.ip_ListQuery...'
	Print ''
End
go

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.ip_ListQuery
	@pnRowCount			int 		= 0 output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psColumnIds			nvarchar(4000)	= 'QueryKey^QueryDescription', -- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000)	= null,	-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000)	= 'Search ID^Description',	-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000)	= null,	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000)	= null,	-- list that indicates the direction for the sort of each column included in the Order By
	-- Filter Parameters
	@pnQueryKey			int 		= null,	
	@pnQueryKeyOperator		tinyint		= null, 
	@psPickListSearch		nvarchar(254)	= null,
	@pnIdentityId			int		= null, -- the user who saved the search
	@pnIdentityIdOperator		tinyint		= 0,	-- default is EQUALS
	@psDescription			nvarchar(256)	= null, 
	@pnDescriptionOperator		tinyint		= 0,	-- default is EQUALS
	@pbIsDefault			bit		= null,
	@pnIsDefaultOperator		tinyint		= 0,	-- default is EQUALS
	@psCategory			nvarchar(50)	= null,
	@pnCategoryOperator		tinyint		= 0,	-- default is EQUALS
	@pnOrigin			smallint	= null,
	@pnOriginOperator		tinyint		= 0	-- default is EQUALS

AS

-- PROCEDURE :	ip_ListQuery
-- VERSION :	8
-- DESCRIPTION:	Returns information requested about saved queries from the SEARCHES table, that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10-OCT-2002  JB		1	Procedure created
-- 06 DEC 2002	JB		4	Replaced @sSQLString with @sSqlString
-- 17 Jul 2003	TM		5	RFC76 - Case Insensitive searching
-- 13 May 2004	TM	RFC1246	6	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.	
-- 02 Sep 2004	JEK	RFC1377	7	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 07 Jul 2011	DL	RFC10830 8	Specify database collation default to temp table columns of type varchar, nvarchar and char

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- VARIABLES

declare @nErrorCode		int
declare @sSqlString		nvarchar(4000)
declare @sSelect		nvarchar(4000)  -- the SQL list of columns to return
declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(4000) 	-- the SQL to filter
declare @sOrder			nvarchar(1000)	-- the SQL sort order
declare	@sDelimiter		nchar(1)
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nLastPosition		smallint
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)
declare @sTable1		nvarchar(25)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null)

-- CONSTANTS

declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1)

-- Initialisation
set @String	='S'
set @Date	='DT'
set @Numeric	='N'
set @Text	='T'

-- Case Insensitive searching

set @psPickListSearch	= upper(@psPickListSearch)
set @psDescription	= upper(@psDescription)

set @nErrorCode	=0
set @sDelimiter	='^'
set @sSelect	='Select '
set @sFrom	='From SEARCHES S'

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

-- Split the list of columns required into each of the separate columns (tokenise) and then loop through
-- each column in order to construct the components of the SELECT
-- Using the "min" function as this returns NULL if nothing is found

set @sSqlString="
Select	@nColumnNo=min(InsertOrder),
	@sColumn  =min(Parameter)
From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
Where	InsertOrder=1"

exec @nErrorCode=sp_executesql @sSqlString,
				N'@nColumnNo	tinyint		OUTPUT,
				  @sColumn	nvarchar(50)	OUTPUT,
				  @psColumnIds  nvarchar(4000),
				  @sDelimiter   nchar(1)',
				  @nColumnNo  =@nColumnNo	OUTPUT,
				  @sColumn    =@sColumn		OUTPUT,
				  @psColumnIds=@psColumnIds,
				  @sDelimiter =@sDelimiter

While @nColumnNo is not NULL
and   @nErrorCode=0
Begin
	-- Get the Name of the column to be published
	set @sSqlString="
	Select	@sPublishName=min(Parameter)
	From	dbo.fn_Tokenise(@psPublishColumnNames, @sDelimiter)
	Where	InsertOrder=@nColumnNo"

	exec @nErrorCode=sp_executesql @sSqlString,
				N'@sPublishName		nvarchar(50)	OUTPUT,
				  @nColumnNo		tinyint,
				  @psPublishColumnNames nvarchar(4000),
				  @sDelimiter   	nchar(1)',
				  @sPublishName		=@sPublishName	OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psPublishColumnNames	=@psPublishColumnNames,
				  @sDelimiter		=@sDelimiter

	-- Get any Qualifier to be used to get the column
	If @nErrorCode=0
	Begin
		set @sSqlString="
		Select	@sQualifier=min(Parameter)
		From	dbo.fn_Tokenise(@psColumnQualifiers, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @nErrorCode=sp_executesql @sSqlString,
				N'@sQualifier		nvarchar(50)	OUTPUT,
				  @nColumnNo		tinyint,
				  @psColumnQualifiers	nvarchar(4000),
				  @sDelimiter   	nchar(1)',
				  @sQualifier		=@sQualifier	OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psColumnQualifiers	=@psColumnQualifiers,
				  @sDelimiter		=@sDelimiter

		-- If a Qualifier exists then generate a value from it that can be used
		-- to create a unique Correlation name for the table

		If  @nErrorCode=0
		and @sQualifier is not null
		Begin
			Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
		End
		Else Begin
			Set @sCorrelationSuffix=NULL
		End
	End

	-- Get the position of the Column in the Order By clause
	If @nErrorCode=0
	Begin
		set @sSqlString="
		Select	@nOrderPosition=min(cast(Parameter as tinyint))
		From	dbo.fn_Tokenise(@psSortOrderList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @nErrorCode=sp_executesql @sSqlString,
				N'@nOrderPosition	tinyint	OUTPUT,
				  @nColumnNo		tinyint,
				  @psSortOrderList	nvarchar(1000),
				  @sDelimiter   	nchar(1)',
				  @nOrderPosition	=@nOrderPosition OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psSortOrderList	=@psSortOrderList,
				  @sDelimiter		=@sDelimiter
	End

	-- If the column is to be included in the Order by then get the direction of the sort
	If  @nErrorCode=0
	and @nOrderPosition>0
	Begin
		set @sSqlString="
		Select	@sOrderDirection=Parameter
		From	dbo.fn_Tokenise(@psSortDirectionList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @nErrorCode=sp_executesql @sSqlString,
				N'@sOrderDirection	nchar(1) OUTPUT,
				  @nColumnNo		tinyint,
				  @psSortDirectionList	nvarchar(1000),
				  @sDelimiter   	nchar(1)',
				  @sOrderDirection	=@sOrderDirection OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psSortDirectionList	=@psSortDirectionList,
				  @sDelimiter		=@sDelimiter
	End	

	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.

	If @nErrorCode=0
	Begin
		If @sColumn='QueryKey'
		Begin
			Set @sTableColumn='S.SEARCHID'
		End

		Else If @sColumn='QueryDescription'
		Begin
			Set @sTableColumn='S.DESCRIPTION'
		End

		Else If @sColumn='IsDefaultQuery'
		Begin
			Set @sTableColumn='S.USEASDEFAULT'
		End

		Else If @sColumn='QueryCategory'
		Begin
			Set @sTableColumn='S.CATEGORY'
		End

		Else If @sColumn='QueryOrigin'
		Begin
			Set @sTableColumn='S.ORIGIN'
		End

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
		values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, 
		       Case When(@sOrderDirection='D') Then ' DESC' ELSE ' ASC' End)
	End

	-- Get the next Column
	If @nErrorCode=0
	Begin
		Set @sSqlString="
		Select	@nColumnNoOUT=min(InsertOrder),
			@sColumnOUT  =min(Parameter)
		From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
		Where	InsertOrder=@nColumnNo+1"

		exec @nErrorCode=sp_executesql @sSqlString,
				N'@nColumnNoOUT	tinyint		OUTPUT,
				  @sColumnOUT	nvarchar(255)	OUTPUT,
				  @nColumnNo	tinyint,
				  @psColumnIds  nvarchar(4000),
				  @sDelimiter   nchar(1)',
				  @nColumnNoOUT=@nColumnNo	OUTPUT,
				  @sColumnOUT  =@sColumn	OUTPUT,
				  @nColumnNo   =@nColumnNo,
				  @psColumnIds =@psColumnIds,
				  @sDelimiter  =@sDelimiter
	End
End


/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE ORDER BY       ****/
/****                                       ****/
/***********************************************/

If @nErrorCode=0
Begin
	Set @nLastPosition=-1

	Select	@sTableColumn   =ColumnName,
		@sPublishName	=PublishName,
		@sOrderDirection=Direction,
		@nOrderPosition =Position,
		@nColumnNo      =ColumnNumber
	From 	@tbOrderBy
	Where	Position=(	Select min(Position)
				from @tbOrderBy)

	Set @nErrorCode=@@Error

	If @nOrderPosition is not null
	Begin
		set @sOrder='Order By '
		Set @sComma =NULL
	End
End
-- Loop through each column to sort on.
-- If the CLASS column is to be sorted on then also include an extra sort on the numeric 
-- equivalent of the class.

While @nOrderPosition>@nLastPosition
and   @nErrorCode=0
Begin
	Set @sOrder=@sOrder
			+@sComma
			+Case When(Charindex('.CLASS',@sTableColumn)>0)
				Then 'Case WHEN(isnumeric('+@sTableColumn+')=1) THEN cast('+@sTableColumn+' as numeric) END'
				     +Case WHEN(@sPublishName is not null)
					Then @sOrderDirection+',['+@sPublishName+']'
				      End
			      When(@sPublishName is null) 
				Then @sTableColumn
				Else '['+@sPublishName+']'
			 End
			+@sOrderDirection
	Set @sComma=','
	Set @nLastPosition=@nOrderPosition

	Select	@sTableColumn   =ColumnName,
		@sPublishName	=PublishName,
		@sOrderDirection=Direction,
		@nOrderPosition =Position,
		@nColumnNo      =ColumnNumber
	From 	@tbOrderBy
	Where	Position=(	Select min(Position)
				from @tbOrderBy
				Where Position>@nOrderPosition)

	Set @nErrorCode=@@Error
End


/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/

if @nErrorCode=0
begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	set @sWhere = char(10)+"WHERE 1=1"

	If @psPickListSearch is not null
	Begin
		Set @sWhere=@sWhere+char(10)+"and upper(S.[DESCRIPTION]) Like '"+@psPickListSearch+"%'"
	End
	
	Else Begin

		if @pnQueryKey is not NULL 
		or @pnQueryKeyOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and S.SEARCHID"+dbo.fn_ConstructOperator(@pnQueryKeyOperator,@String,@pnQueryKey, null,0)
		end
	
		if @pnIdentityId is not NULL
		or @pnIdentityIdOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and S.IDENTITYID"+dbo.fn_ConstructOperator(@pnIdentityIdOperator,@String,@pnIdentityId, null,0)
		end

		if @psDescription is not NULL
		or @pnDescriptionOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and upper(S.DESCRIPTION)"+dbo.fn_ConstructOperator(@pnDescriptionOperator,@String,@psDescription, null,0)
		end

		if @pbIsDefault is not NULL
		or @pnIsDefaultOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and S.USEASDEFAULT"+dbo.fn_ConstructOperator(@pnIsDefaultOperator,@String,@pbIsDefault, null,0)
		end

		if @psCategory is not NULL
		or @pnCategoryOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and S.CATEGORY"+dbo.fn_ConstructOperator(@pnCategoryOperator,@String,@psCategory, null,0)
		end

		if @pnOrigin is not NULL
		or @pnOriginOperator between 2 and 6
		begin
			set @sWhere = @sWhere+char(10)+"and S.ORIGIN"+dbo.fn_ConstructOperator(@pnOriginOperator,@String,@pnOrigin, null,0)
		end

	End
End

if @nErrorCode=0
begin
	-- Now execute the constructed SQL to return the result set

	exec (@sSelect + @sFrom + @sWhere + @sOrder)
	select 	@nErrorCode =@@Error,
		@pnRowCount=@@Rowcount

end

RETURN @nErrorCode
GO

Grant execute on dbo.ip_ListQuery  to public
GO
