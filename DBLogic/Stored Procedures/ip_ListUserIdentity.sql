-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ListUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.ip_ListUserIdentity.'
	drop procedure dbo.ip_ListUserIdentity
	print '**** Creating procedure dbo.ip_ListUserIdentity...'
	print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ip_ListUserIdentity
	@pnRowCount			int 		= null output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, 		-- the language in which output is to be expressed
	@psColumnIds			nvarchar(4000)	= 'IdentityKey^LoginID', 	-- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000)	= null,			-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000)	= 'Identity Key^Login ID',	-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000)	= null,	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000)	= null,	-- list that indicates the direction for the sort of each column included in the Order By
	-- Filter Parameters
	@pnIdentityKey			nvarchar(20)	= null,	
	@pnIdentityKeyOperator		tinyint		= 0, 
	@psLoginID			nvarchar(50)	= null,
	@pnLoginIDOperator		tinyint		= 0,
	@pnNameKey			nvarchar (60)	= null,
	@pnNameKeyOperator		tinyint		= 0,
	@pbIsExternalUser		bit		= null, -- Returns countries where the date commenced (if any) is prior to today, and the date ceased (if any) is after today.
	@pbIsAdministrator		bit		= null, -- Returns countries that may be used in an address (where RecordType = 0).
	@psEmailAddress			nvarchar(50)	= null,
	@pnEmailAddressOperator		tinyint		= null,
	@pnAccessAccountKey		int		= null,
	@pnAccessAccountOperator	tinyint		= null,
	@pnRoleKey			int	= null,
	@pnRoleOperator			tinyint 	= null,
	@pbIsIncompleteWorkBench	bit		= null, -- True returns users that are not fully configured for use with the WorkBench products.
	@pbIsIncompleteInprostart	bit		= null	-- True returns users that are not fully configured for use with CPA Inprostart.
AS

-- PROCEDURE :	ip_ListUserIdentity
-- VERSION :	13
-- DESCRIPTION:	Returns the User Identity information requested, that matches the filter criteria provided.


-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17-OCT-2002  JB		1	Procedure created 
-- 17 Jul 2003	TM		4	RFC76 - Case Insensitive searching
-- 02 Oct 2003	TM		5	RFC408 Manage Client Users (Firm). Change @psLoginID datatype to nvarchar(50).
--					Add new Filter Parameters: @psEmailAddress, @pnEmailAddressOperator, 
--					@pnAccessAccountKey, @pnAccessAccountOperator, @pnRoleKey and @pnRoleOperator.     
--					Add new columns: AccessAccountKey, AccessAccountName and RoleName
-- 03 Dec 2003	JEK		6	RFC408 Implement DisplayEmail
-- 01 Mar 2004	TM	RFC622	7	Extend to allow searching on and display of incomplete users.
-- 09 Mar 2004	TM	RFC868	8	Modify the logic extracting the 'DisplayEmail' column to use new Name.MainEmail column.
-- 13-May-2004	TM	RFC1246	9	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	10	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperatorl
-- 03 Dec 2007	vql	RFC5909	11	Change RoleKey from smallint to int.
-- 07 Jul 2011	DL	R10830	12	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	vql	R53910	13	Adjust formatted names logic (DR-15543).

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- VARIABLES
Declare @nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sSelect		nvarchar(4000)  -- the SQL list of columns to return
Declare	@sFrom			nvarchar(4000)	-- the SQL to list tables and joins
Declare @sWhere			nvarchar(4000) 	-- the SQL to filter
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare	@sDelimiter		nchar(1)
Declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
Declare @nColumnNo		tinyint
Declare @sColumn		nvarchar(100)
Declare @sPublishName		nvarchar(50)
Declare @sQualifier		nvarchar(50)
Declare @sTableColumn		nvarchar(1000)
Declare @nLastPosition		smallint
Declare @nOrderPosition		tinyint
Declare @sOrderDirection	nvarchar(5)
Declare @sCorrelationSuffix	nvarchar(20)
Declare @sTable1		nvarchar(25)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null)

-- CONSTANTS

Declare @String			nchar(1),
	@Date			nchar(2),
	@Numeric		nchar(1),
	@Text			nchar(1)

-- Initialisation
Set @String	='S'
Set @Date	='DT'
Set @Numeric	='N'
Set @Text	='T'

-- Case Insensitive searching

Set @psLoginID 		= upper(@psLoginID)
Set @psEmailAddress	= upper(@psEmailAddress)


Set @nErrorCode	=0
Set @sDelimiter	='^'
Set @sSelect	='Select '
Set @sFrom	='From USERIDENTITY UID'

-- Join to NAME required?
If CHARINDEX('DisplayName', @psColumnIds ) > 0 
or CHARINDEX('NameCode', @psColumnIds ) > 0 
or CHARINDEX('DisplayEmail', @psColumnIds ) > 0
Begin
	Set @sFrom = @sFrom + char(10) + 'left join NAME N on N.NAMENO = UID.NAMENO '
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****                                       ****/
/***********************************************/

-- Split the list of columns required into each of the separate columns (tokenise) and then loop through
-- each column in order to construct the components of the SELECT
-- Using the "min" function as this returns NULL if nothing is found

Set @sSQLString="
Select	@nColumnNo=min(InsertOrder),
	@sColumn  =min(Parameter)
From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
Where	InsertOrder=1"

exec @nErrorCode=sp_executesql @sSQLString,
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
	Set @sSQLString="
	Select	@sPublishName=min(Parameter)
	From	dbo.fn_Tokenise(@psPublishColumnNames, @sDelimiter)
	Where	InsertOrder=@nColumnNo"

	exec @nErrorCode=sp_executesql @sSQLString,
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
		Set @sSQLString="
		Select	@sQualifier=min(Parameter)
		From	dbo.fn_Tokenise(@psColumnQualifiers, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @nErrorCode=sp_executesql @sSQLString,
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
		Set @sSQLString="
		Select	@nOrderPosition=min(cast(Parameter as tinyint))
		from	dbo.fn_Tokenise(@psSortOrderList, @sDelimiter)
		where	InsertOrder=@nColumnNo"

		Exec @nErrorCode=sp_executesql @sSQLString,
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
		Set @sSQLString="
		Select	@sOrderDirection=Parameter
		From	dbo.fn_Tokenise(@psSortDirectionList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @nErrorCode=sp_executesql @sSQLString,
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
		If @sColumn='IdentityKey'
		Begin
			Set @sTableColumn='UID.IDENTITYID'
		End

		Else If @sColumn='LoginID'
		Begin
			Set @sTableColumn='UID.LOGINID'
		End

		Else If @sColumn='IdentityNameKey'
		Begin
			Set @sTableColumn='UID.NAMENO'
		End

		Else If @sColumn='DisplayName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)' 
		End

		Else If @sColumn='NameCode'
		Begin
			Set @sTableColumn='N.NAMECODE'
		End

		Else If @sColumn='DisplayEmail'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(T.TELECOMTYPE, T.ISD, T.AREACODE, T.TELECOMNUMBER, T.EXTENSION) '				
			
			Set @sFrom = @sFrom + char(10) + 'left join TELECOMMUNICATION T on (T.TELECODE = N.MAINEMAIL) '
		End

		Else If @sColumn='IsInternalUser'
		Begin
			Set @sTableColumn='CASE when UID.ISEXTERNALUSER = 1 then 0 else 1 end'
		End

		Else If @sColumn='IsExternalUser'
		Begin
			Set @sTableColumn='UID.ISEXTERNALUSER'
		End

		Else If @sColumn='IsAdministrator'
		-- True when the date commenced (if any) is prior to today, and the date ceased (if any) is after today.
		Begin
			Set @sTableColumn='UID.ISADMINISTRATOR'
		End

		Else If @sColumn='AccessAccountKey'
		Begin
			Set @sTableColumn='UID.ACCOUNTID'
		End

		Else If @sColumn='AccessAccountName'
		Begin
			Set @sTableColumn='ACN.ACCOUNTNAME'
			
			Set @sFrom = @sFrom + char(10) + 'left join ACCESSACCOUNT ACN	on (ACN.ACCOUNTID = UID.ACCOUNTID)'
		End

		Else If @sColumn='RoleName'
		Begin
			Set @sTableColumn='RL.ROLENAME'
			
			Set @sFrom=@sFrom + char(10) + "left join IDENTITYROLES IDR	on (IDR.IDENTITYID = UID.IDENTITYID)"
				     	  + char(10) + "left join ROLE RL		on (RL.ROLEID	   = IDR.ROLEID)"
		End
		
		Else If @sColumn='IsIncompleteWorkBench'
		Begin
			Set @sTableColumn='CASE WHEN UID.ISVALIDWORKBENCH=1 THEN cast(0 as bit) ELSE cast(1 as bit) END'			
		End		

		Else If @sColumn='IsIncompleteInprostart'
		Begin
			Set @sTableColumn='CASE WHEN UID.ISVALIDINPROSTART=1 THEN cast(0 as bit) ELSE cast(1 as bit) END'			
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
		Set @sSQLString="
		Select	@nColumnNoOUT=min(InsertOrder),
			@sColumnOUT  =min(Parameter)
		From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
		Where	InsertOrder=@nColumnNo+1"

		exec @nErrorCode=sp_executesql @sSQLString,
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

If @nErrorCode=0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.
	Set @sWhere = char(10)+"WHERE 1=1"

	If @pnIdentityKey is not NULL
	or @pnIdentityKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.IDENTITYID"+dbo.fn_ConstructOperator(@pnIdentityKeyOperator,@String,@pnIdentityKey, null,0)
	End

	If @psLoginID is not NULL
	or @pnLoginIDOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and upper(UID.LOGINID)"+dbo.fn_ConstructOperator(@pnLoginIDOperator,@String,@psLoginID, null,0)
	End

	If @pnNameKey is not NULL
	or @pnNameKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.NAMENO"+dbo.fn_ConstructOperator(@pnNameKeyOperator,@Numeric,@pnNameKey, null,0)
	End

	If @pbIsExternalUser is not NULL
		Set @sWhere = @sWhere+char(10)+"and UID.ISEXTERNALUSER = " + CAST(@pbIsExternalUser as nchar(1))

	If @pbIsAdministrator is not NULL
		Set @sWhere = @sWhere+char(10)+"and UID.ISADMINISTRATOR = " + + CAST(@pbIsAdministrator as nchar(1))

	If @psEmailAddress is not NULL
	or @pnEmailAddressOperator between 2 and 6
	Begin
		Set @sFrom = @sFrom + char(10) + "join NAMETELECOM NT		on (NT.NAMENO = UID.NAMENO)"
				    + char(10) + "join TELECOMMUNICATION T     	on (T.TELECODE=NT.TELECODE"
				    + char(10) + "				and T.TELECOMTYPE=1903)"
		   	  		    
		Set @sWhere = @sWhere+char(10)+"and upper(T.TELECOMNUMBER)"+dbo.fn_ConstructOperator(@pnEmailAddressOperator,@String,@psEmailAddress, null,0)
	End

	If @pnAccessAccountKey is not NULL
	or @pnAccessAccountOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.ACCOUNTID"+dbo.fn_ConstructOperator(@pnAccessAccountOperator,@Numeric,@pnAccessAccountKey, null,0)
	End

	If @pnRoleKey is not NULL
	or @pnRoleOperator between 2 and 6
	Begin
		If charindex('left join IDENTITYROLES IDR',@sFrom)=0
		Begin
			Set @sFrom = @sFrom + char(10) + 'join IDENTITYROLES IDR	on (IDR.IDENTITYID = UID.IDENTITYID)'
		End
				     	  		    
		Set @sWhere = @sWhere+char(10)+"and IDR.ROLEID"+dbo.fn_ConstructOperator(@pnRoleOperator,@Numeric,@pnRoleKey, null,0)
	End
	
	If @pbIsIncompleteWorkBench is not NULL	
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.ISVALIDWORKBENCH <> "+CAST(@pbIsIncompleteWorkBench as nchar(1))

	End

	If @pbIsIncompleteInprostart is not NULL	
	Begin
		Set @sWhere = @sWhere+char(10)+"and UID.ISVALIDINPROSTART <> "+CAST(@pbIsIncompleteInprostart as nchar(1))
	End

End

if @nErrorCode=0
begin
	-- Now execute the constructed SQL to return the result set

	--Print (@sSelect + @sFrom + @sWhere + @sOrder)
	Exec (@sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

end

RETURN @nErrorCode
GO

Grant execute on dbo.ip_ListUserIdentity  to public
GO
