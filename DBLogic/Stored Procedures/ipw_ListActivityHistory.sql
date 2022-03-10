-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListActivityHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListActivityHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListActivityHistory.'
	Drop procedure [dbo].[ipw_ListActivityHistory]
End
Print '**** Creating Stored Procedure dbo.ipw_ListActivityHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListActivityHistory
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 170, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	ipw_ListActivityHistory
-- VERSION:	7
-- DESCRIPTION:	Returns the requested Activity History information, for history that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Oct 2004	TM	RFC1156	1	Procedure created
-- 29 Nov 2004	TM	RFC1156	2	Remove unnecessary join to the Program table.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 06 Jun 2005	TM	RFC2630	4	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 24 Oct 2005	TM	RFC3024	5	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 07 Jul 2011	DL	R10830	6	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	MF	R54668	7	Return the name associated with LOGIDENTITYID when not called from Centura.

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	CaseReference
--	WhenRequested
--	SqlUser
--	WorkBenchUser
--	ProgramName
--	EventDescription
--	EventDefinition
--	StatusDescription
--	LetterName
--	RateName
--	WhenOccurred
--	SystemMessage

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	A
--	C
--	UI
--	E
--	ST
--	LT
--	RTS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests table 
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
Declare @tbOrderBy table (
				Position	tinyint		not null,
				Direction	nvarchar(5)	collate database_default not null,
				ColumnName	nvarchar(1000)	collate database_default not null,
				PublishName	nvarchar(50)	collate database_default null,
				ColumnNumber	tinyint		not null
			)

Declare @nOutRequestsRowCount			int
Declare @nColumnNo				tinyint
Declare @sColumn				nvarchar(100)
Declare @sPublishName				nvarchar(50)
Declare @sQualifier				nvarchar(50)
Declare @nOrderPosition				tinyint
Declare @sOrderDirection			nvarchar(5)
Declare @sTableColumn				nvarchar(1000)
Declare @sComma					nchar(2)	-- initialised when a column has been added to the Select.

-- Declare Filter Variables
Declare @nCaseKey 				int		-- The primary key of the case.
Declare @nCaseKeyOperator			tinyint		
Declare @bIsLetter				bit		-- Returns activity history rows that have a letter attached.
Declare @bIsCharge				bit		-- Returns activity history rows that have a charge attached.
Declare @bIsStatus				bit		-- Returns activity history rows that have a status attached.

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOR					nchar(2)

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From ACTIVITYHISTORY A"
set 	@sWhere 				= char(10)+"	WHERE 1=1"

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
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
	-- Default @pnQueryContextKey to 170.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 170)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
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
					       ELSE NULL
					  END,
		@sQualifier		= QUALIFIER
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	Set @nErrorCode = @@ERROR
	
	-------------------------------------------
	-- If the procedure called from Web then
	-- change "SqlUser" to "WorkBenchUser".
	-------------------------------------------
	
	If  @sColumn = 'SqlUser'
	and isnull(@pbCalledFromCentura,0)=0
	Begin
		Set @sColumn='WorkBenchUser'
	End

	If @nErrorCode=0
	Begin
		If @sColumn='CaseReference'
		Begin
			If charindex('left join CASES C',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join CASES C	on (C.CASEID = A.CASEID)' 
			End
	
			Set @sTableColumn='C.IRN'
		End
		Else 
		If @sColumn='WhenRequested'
		Begin
			Set @sTableColumn='A.WHENREQUESTED'
		End
		Else 
		If @sColumn = 'SqlUser'
		Begin
			Set @sTableColumn='A.SQLUSER'
		End
		Else 
		If @sColumn = 'WorkBenchUser'
		Begin
			If charindex('left join USERIDENTITY UI',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join USERIDENTITY UI		on (UI.IDENTITYID = A.IDENTITYID)' 
			End
	
			Set @sTableColumn='isnull(UI.LOGINID,A.SQLUSER)'
		End
		Else 
		If @sColumn = 'ProgramName'
		Begin
			Set @sTableColumn='A.PROGRAMID'
		End 
		Else 
		If @sColumn = 'EventDescription'
		Begin
			If charindex('left join EVENTS E',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join EVENTS E		on (E.EVENTNO = A.EVENTNO)' 
			End
	
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'EventDefinition'
		Begin
			If charindex('left join EVENTS E',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join EVENTS E		on (E.EVENTNO = A.EVENTNO)' 
			End
	
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'StatusDescription'
		Begin
			If charindex('left join STATUS ST',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join STATUS ST		on (ST.STATUSCODE = A.STATUSCODE)' 
			End
	
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'LetterName'
		Begin
			If charindex('left join LETTER LT',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join LETTER LT		on (LT.LETTERNO = A.LETTERNO)' 
			End
	
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'LT',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'RateName'
		Begin
			If charindex('left join RATES RTS',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join RATES RTS		on (RTS.RATENO = A.RATENO)' 
			End
	
			Set @sTableColumn='RTS.RATEDESC'
		End
		Else 
		If @sColumn = 'WhenOccurred'
		Begin
			Set @sTableColumn='A.WHENOCCURRED'
		End
		Else 
		If @sColumn = 'SystemMessage'
		Begin
			Set @sTableColumn='A.SYSTEMMESSAGE'
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
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

			Set @nErrorCode = @@ERROR
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
End

-- Now construct the Order By clause

If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sOrder= ISNULL(NULLIF(@sOrder+',', ','),'')			
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

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	Set @sSQLString = 	
	"Select @nCaseKey			= CaseKey,"+CHAR(10)+
	"	@nCaseKeyOperator		= CaseKeyOperator,"+CHAR(10)+
	"	@bIsLetter			= IsLetter,"+CHAR(10)+
	"	@bIsCharge			= IsCharge,"+CHAR(10)+
	"	@bIsStatus			= IsStatus"+CHAR(10)+					
	"from	OPENXML (@idoc, '/ipw_ListActivityHistory/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      CaseKey			int		'CaseKey/text()',"+CHAR(10)+
	"	      CaseKeyOperator		tinyint		'CaseKey/@Operator/text()',"+CHAR(10)+
	"	      IsLetter			bit		'RestrictionFlags/IsLetter',"+CHAR(10)+	
	"	      IsCharge			bit		'RestrictionFlags/IsCharge',"+CHAR(10)+
 	"	      IsStatus			bit		'RestrictionFlags/IsStatus'"+CHAR(10)+
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nCaseKey 			int			output,
				  @nCaseKeyOperator		tinyint			output,
				  @bIsLetter			bit			output,
				  @bIsCharge			bit			output,	
				  @bIsStatus			bit			output',
				  @idoc				= @idoc,
				  @nCaseKey 			= @nCaseKey		output,
				  @nCaseKeyOperator		= @nCaseKeyOperator	output,
				  @bIsLetter			= @bIsLetter		output,
				  @bIsCharge			= @bIsCharge		output,
				  @bIsStatus			= @bIsStatus		output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
		-- Set the RestrictionFlags to 0 if they were not supplied:
		Set @bIsLetter = CASE WHEN @bIsLetter IS NULL THEN 0 ELSE @bIsLetter END
		Set @bIsCharge = CASE WHEN @bIsCharge IS NULL THEN 0 ELSE @bIsCharge END
		Set @bIsStatus = CASE WHEN @bIsStatus IS NULL THEN 0 ELSE @bIsStatus END		
	
		If @nCaseKey is not NULL
		or @nCaseKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and A.CASEID " + dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,@pbCalledFromCentura)
		End				

		If @bIsLetter = 1
		or @bIsCharge = 1
		or @bIsStatus = 1
		Begin
			Set @sOR = null
		
			Set @sWhere = @sWhere+char(10)+"and ("
			
			If @bIsLetter = 1
			Begin		
				Set @sWhere = @sWhere+char(10)+"A.LETTERNO is not null" 
				Set @sOR = 'or'
			End

			If @bIsCharge = 1
			Begin		
				Set @sWhere = @sWhere+char(10)+@sOR+" A.RATENO is not null" 
				Set @sOR = 'or'
			End
	
			If @bIsStatus = 1
			Begin		
				Set @sWhere = @sWhere+char(10)+@sOR+" A.STATUSCODE is not null" 				
			End

			Set @sWhere = @sWhere+char(10)+")"
		End
		
	End
End

If @nErrorCode=0
Begin 	
	-- Now execute the constructed SQL to return the result set
	Exec (@sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListActivityHistory to public
GO
