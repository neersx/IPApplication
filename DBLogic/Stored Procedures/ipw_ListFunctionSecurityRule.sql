-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListFunctionSecurityRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFunctionSecurityRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFunctionSecurityRule.'
	Drop procedure [dbo].[ipw_ListFunctionSecurityRule]
End
Print '**** Creating Stored Procedure dbo.ipw_ListFunctionSecurityRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListFunctionSecurityRule
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure.
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)
as
-- PROCEDURE:	ipw_ListFunctionSecurityRule
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the list of  function security rules depending upon filter criteria.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Dec 2009	NG	RFC8631	1	Procedure created
-- 11 Jan 2009	MS	RFC8631	2	Added Access privileges in search filter
-- 07 Jul 2011	DL	R10830	3	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(4000)
Declare @sSelect			nvarchar(4000)
Declare @sLookupCulture			nvarchar(10)
Declare @sFrom				nvarchar(4000)
Declare @sWhere				nvarchar(2000)
Declare @sOrder				nvarchar(1000)	-- the SQL sort order
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sTableColumn			nvarchar(1000)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @idoc 				int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @pnFilterGroupIndex		int
Declare @nCount				int
Declare @nOutRequestsRowCount		int
Declare @nColumnNo			tinyint
declare @sQualifier			nvarchar(50)
declare @sCorrelationSuffix		nvarchar(20)

Declare @pnFunctionType			int
Declare @pnOwnerNo			int
Declare @pnAccessStaffKey		int
Declare @pnAccessGroupKey		int
Declare @nAccessPrivileges		int
Declare @pbIsExactMatch			bit
Declare @pbBestFitOnly			bit
Declare @pbCanRead			bit
Declare @pbCanInsert			bit
Declare @pbCanUpdate			bit
Declare @pbCanDelete			bit
Declare @pbCanPost			bit
Declare @pbCanAdjustValue		bit
Declare @pbCanReverse			bit
Declare @pbCanFinalise			bit
Declare @pbCanCredit			bit
Declare @pbCanConvert			bit

-- Initialise variables
Set @nErrorCode	= 0
Set @sSelect = 'Select '
Set @sWhere	= ' where 1=1 '
Set @sFrom = ' from FUNCTIONSECURITY FS '
Set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @pnFilterGroupIndex = 1
Set @nCount = 1

If @nErrorCode = 0 
and @pbBestFitOnly = 1
Begin
	SELECT @pnAccessStaffKey  = NAMENO FROM USERIDENTITY WHERE IDENTITYID = @pnUserIdentityId

	SELECT @pnAccessGroupKey = FAMILYNO FROM NAME N
						JOIN USERIDENTITY UI on (UI.NAMENO = N.NAMENO)
						WHERE UI.IDENTITYID = @pnUserIdentityId
	Set @sSelect = 'Select top 1'
End

If @nErrorCode = 0
and datalength(@ptXMLFilterCriteria) > 0 
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	
	Set @sSQLString = "Select"+CHAR(10)+
			"@pnFunctionType	= FunctionType,"+CHAR(10)+		
			"@pnOwnerNo		= OwnerNo,"+CHAR(10)+
			"@pnAccessStaffKey	= AccessStaffKey,"+CHAR(10)+
			"@pnAccessGroupKey	= AccessGroupKey,"+CHAR(10)+
			"@pbCanRead		= CanRead,"+CHAR(10)+
			"@pbCanInsert		= CanInsert,"+CHAR(10)+
			"@pbCanUpdate		= CanUpdate,"+CHAR(10)+
			"@pbCanDelete		= CanDelete,"+CHAR(10)+
			"@pbCanPost		= CanPost,"+CHAR(10)+
			"@pbCanAdjustValue	= CanAdjustValue,"+CHAR(10)+
			"@pbCanReverse		= CanReverse,"+CHAR(10)+
			"@pbCanFinalise		= CanFinalise,"+CHAR(10)+
			"@pbCanCredit		= CanCredit,"+CHAR(10)+
			"@pbCanConvert		= CanConvert,"+CHAR(10)+
			"@pbIsExactMatch	= IsExactMatch,"+CHAR(10)+
			"@pbBestFitOnly		= BestFitOnly"+CHAR(10)+
			"from OPENXML(@idoc, '/ipw_ListFunctionSecurityRule/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
			"WITH ("+CHAR(10)+
			"FunctionType		int			'Function/FunctionType/text()',"+CHAR(10)+
			"OwnerNo		int			'Owner/OwnerNo/text()',"+CHAR(10)+
			"AccessStaffKey		int			'AccessStaff/AccessStaffKey/text()',"+CHAR(10)+
			"AccessGroupKey		int			'AccessGroup/AccessGroupKey/text()',"+CHAR(10)+	
			"CanRead		bit			'AccessPrivileges/CanRead/text()',"+CHAR(10)+		
			"CanInsert		bit			'AccessPrivileges/CanInsert/text()',"+CHAR(10)+
			"CanUpdate		bit			'AccessPrivileges/CanUpdate/text()',"+CHAR(10)+	
			"CanDelete		bit			'AccessPrivileges/CanDelete/text()',"+CHAR(10)+	
			"CanPost		bit			'AccessPrivileges/CanPost/text()',"+CHAR(10)+	
			"CanAdjustValue		bit			'AccessPrivileges/CanAdjustValue/text()',"+CHAR(10)+	
			"CanReverse		bit			'AccessPrivileges/CanReverse/text()',"+CHAR(10)+	
			"CanFinalise		bit			'AccessPrivileges/CanFinalise/text()',"+CHAR(10)+	
			"CanCredit		bit			'AccessPrivileges/CanCredit/text()',"+CHAR(10)+	
			"CanConvert		bit			'AccessPrivileges/CanConvert/text()',"+CHAR(10)+			
			"IsExactMatch		bit			'IsExactMatch/text()',"+CHAR(10)+
			"BestFitOnly		bit			'BestFitOnly/text()'"+CHAR(10)+
			"	     )"
			
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@idoc			int,
			@pnFunctionType		int		output,	
			@pnOwnerNo		int		output,		
			@pnAccessStaffKey	int		output,
			@pnAccessGroupKey	int		output,	
			@pbCanRead		int		output,	
		        @pbCanInsert		int		output,	
		        @pbCanUpdate		int		output,	
		        @pbCanDelete		int		output,	
		        @pbCanPost		int		output,	
		        @pbCanAdjustValue	int		output,	
		        @pbCanReverse		int		output,	
		        @pbCanFinalise		int		output,	
		        @pbCanCredit		int		output,	
		        @pbCanConvert		int		output,			
			@pbIsExactMatch		bit		output,
			@pbBestFitOnly		bit		output',
			@idoc			=		@idoc,
			@pnFunctionType		=		@pnFunctionType			output,
			@pnOwnerNo		=		@pnOwnerNo			output,
			@pnAccessStaffKey	=		@pnAccessStaffKey		output,
			@pnAccessGroupKey	=		@pnAccessGroupKey		output,
			@pbCanRead		=		@pbCanRead			output,
			@pbCanInsert		=		@pbCanInsert			output,
			@pbCanUpdate		=		@pbCanUpdate			output,
			@pbCanDelete		=		@pbCanDelete			output,
			@pbCanPost		=		@pbCanPost			output,
			@pbCanAdjustValue	=		@pbCanAdjustValue		output,
			@pbCanReverse		=		@pbCanReverse			output,
			@pbCanFinalise		=		@pbCanFinalise			output,
			@pbCanCredit		=		@pbCanCredit			output,
			@pbCanConvert		=		@pbCanConvert			output,
			@pbIsExactMatch		=		@pbIsExactMatch			output,
			@pbBestFitOnly		=		@pbBestFitOnly			output

	 -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0
Begin
	Set @nAccessPrivileges = 
			CASE WHEN @pbCanRead = 1	THEN 1		ELSE 0	END +
			CASE WHEN @pbCanInsert = 1	THEN 2		ELSE 0	END +
			CASE WHEN @pbCanUpdate = 1	THEN 4		ELSE 0	END +
			CASE WHEN @pbCanDelete = 1	THEN 8		ELSE 0	END +
			CASE WHEN @pbCanPost = 1	THEN 16		ELSE 0	END +
			CASE WHEN @pbCanFinalise = 1	THEN 32		ELSE 0	END +
			CASE WHEN @pbCanReverse = 1	THEN 64		ELSE 0	END +
			CASE WHEN @pbCanCredit = 1	THEN 128	ELSE 0	END +
			CASE WHEN @pbCanAdjustValue = 1 THEN 256	ELSE 0	END +
			CASE WHEN @pbCanConvert = 1	THEN 512	ELSE 0	END

	If @pbIsExactMatch = 1
	Begin
		Set @sWhere = @sWhere + char(10)+ 'and (FS.FUNCTIONTYPE = @pnFunctionType OR  @pnFunctionType is null)
					and   (FS.OWNERNO = @pnOwnerNo OR  @pnOwnerNo is null)
					and   (FS.ACCESSSTAFFNO = @pnAccessStaffKey OR  @pnAccessStaffKey is null)
					and   (FS.ACCESSGROUP = @pnAccessGroupKey OR  @pnAccessGroupKey is null)'					
	End
	Else
	Begin
		Set @sWhere = @sWhere + char(10)+ 'and (FS.FUNCTIONTYPE = @pnFunctionType) 
					AND (FS.ACCESSSTAFFNO = @pnAccessStaffKey OR FS.ACCESSSTAFFNO IS NULL)'	
	End

	If @nAccessPrivileges > 0
	Begin
		Set @sWhere = @sWhere + char(10)+ 'and   (FS.ACCESSPRIVILEGES & @nAccessPrivileges = @nAccessPrivileges)'
	End
End

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
declare @tblOutputRequests table 
			 (	ROWNUMBER	int 		not null,
		    		ID		nvarchar(100)	collate database_default not null,
		    		SORTORDER	tinyint		null,
		    		SORTDIRECTION	nvarchar(1)	collate database_default null,
				PUBLISHNAME	nvarchar(100)	collate database_default null,
				QUALIFIER	nvarchar(100)	collate database_default null,
				DOCITEMKEY	int		null
			  )

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null
			)

If datalength(@ptXMLOutputRequests) = 0
or datalength(@ptXMLOutputRequests) is null
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 720)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, default, null,default,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End
Else
--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,default)
	
	

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @nErrorCode=0
Begin
	-- Get the ColumnID, Name of the column to be published (@sPublishName), Qualifier to be used to get the column 
	-- (@sQualifier)   
	Select	@nColumnNo 		= ROWNUMBER,
		@sColumn   		= ID,
		@sPublishName 		= PUBLISHNAME,
		@nOrderPosition		= SORTORDER,
		@sOrderDirection	= CASE WHEN SORTORDER > 0 THEN SORTDIRECTION
					       ELSE NULL
					  END,
		@sQualifier		= QUALIFIER
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If  @nErrorCode=0
	and @sQualifier is not null
	Begin
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End
	Else 
	Begin
		Set @sCorrelationSuffix=NULL
	End

	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.
	If @nErrorCode=0
	Begin
		If @sColumn='NULL'
		Begin
			Set @sTableColumn='NULL'
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By
		End
		
		Else if @sColumn = 'Owner'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NO.NAMENO,null)'
			Set @sFrom = @sFrom +CHAR(10)+'left join NAME NO on (NO.NAMENO = FS.OWNERNO)'
		End	
		
		Else if @sColumn = 'StaffMember'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NS.NAMENO,null)'
			Set @sFrom = @sFrom +CHAR(10)+'left join NAME NS on (NS.NAMENO = FS.ACCESSSTAFFNO)'
			If @pbIsExactMatch  = 0
			Begin
				Select @sOrderDirection = "D"
			End
		End	
		
		Else if @sColumn = 'StaffGroup'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'NF',@sLookupCulture,@pbCalledFromCentura)
			Set @sFrom = @sFrom +CHAR(10)+'left join NAMEFAMILY NF on (NF.FAMILYNO = FS.ACCESSGROUP)'
		End	
		
		Else if @sColumn = 'CanRead'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 1) as bit)'
		End	
		
		Else if @sColumn = 'CanInsert'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 2) as bit)'
		End	
		
		Else if @sColumn = 'CanUpdate'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 4) as bit)'
		End
		
		Else if @sColumn = 'CanDelete'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 8) as bit)'
		End	
		
		Else if @sColumn = 'CanFinalise'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 32) as bit)'
		End	
		
		Else if @sColumn = 'CanReverse'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 64) as bit)'
		End	
		
		Else if @sColumn = 'CanCredit'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 128) as bit)'
		End	
		
		Else if @sColumn = 'CanConvert'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 512) as bit)'
		End	
		
		Else if @sColumn = 'CanPost'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 16) as bit)'
		End	
		
		Else if @sColumn = 'CanAdjustValue'
		Begin
			Set @sTableColumn='cast((isnull(FS.ACCESSPRIVILEGES, 0) & 256) as bit)'
		End

		Else if @sColumn = 'SequenceNo'
		Begin
			Set @sTableColumn='FS.SEQUENCENO'
		End		
	End

		If datalength(@sPublishName)>0
		Begin  
			Set @sTableColumn=@sTableColumn+' as ['+@sPublishName+']'
	
		End
		Else Begin
			Set @sPublishName=NULL
		End

		If @nOrderPosition>0
		Begin

			Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

			Set @nErrorCode = @@ERROR
		End	



	if @nCount = 1
	Begin
		Set @sSelect = @sSelect +CHAR(10)+@sTableColumn
	End
	Else
	Begin
		Set @sSelect = @sSelect +CHAR(10)+','+ @sTableColumn
	End
	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
	Set @nErrorCode=@@Error
	
End

-- Assemble the "Order By" clause.
If @nErrorCode=0
Begin	
	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrder= 	ISNULL(NULLIF(@sOrder+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position

	If @sOrder is not null
	Begin
		Set @sOrder = ' Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

Set @sSQLString = @sSelect + char(10) + @sFrom + char(10)+ @sWhere + char(10)+ @sOrder

If @nErrorCode = 0
Begin		
		print @sSQLString
		exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnFunctionType	int,
			  @pnOwnerNo		int,
			  @pnAccessStaffKey	int,
			  @pnAccessGroupKey	int,
			  @nAccessPrivileges	int',	
			  @pnFunctionType	= @pnFunctionType,
			  @pnOwnerNo		= @pnOwnerNo,
			  @pnAccessStaffKey	= @pnAccessStaffKey,
			  @pnAccessGroupKey	= @pnAccessGroupKey,
			  @nAccessPrivileges	= @nAccessPrivileges	

		Set @pnRowCount=@@Rowcount 
        
        If @nErrorCode=0
        Begin
	        set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

	        exec @nErrorCode=sp_executesql @sSQLString,
				        N'@pnRowCount	int',
				          @pnRowCount=@pnRowCount
        End
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListFunctionSecurityRule to public
GO
