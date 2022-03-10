-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListImage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListImage.'
	Drop procedure [dbo].[ipw_ListImage]
End
Print '**** Creating Stored Procedure dbo.ipw_ListImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListImage
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 290, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	ipw_ListImage
-- VERSION:	3
-- DESCRIPTION:	Returns the requested Image information, for images that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Feb 2006	IB	RFC3388	1	Procedure created
-- 16 Mar 2010	PS	RFC6391	2	Add ImageTimeStamp and ImageDateTimeStamp columns. (for concurrency check) 
-- 07 Jul 2011	DL	RFC10830 3	Specify database collation default to temp table columns of type varchar, nvarchar and char

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	ImageKey
--	ImageDescription
--	ImageStatusKey
--	ImageStatus
--	IsScanned
--	NetworkLocation


-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	I
--	ID
--	TC

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture				nvarchar(10)

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
Declare @nImageKey 				int		-- The database key (primary key) of the image. 
Declare @nImageKeyOperator			tinyint		
Declare @sPickListSearch 			nvarchar(254)	-- The text entered by a user in a pick list field to locate appropriate entries.  
Declare @bExists				bit		-- If @bExists = 1 then rows are located for a @sPickListSearch criterion.
Declare	@sImageDescription 		 	nvarchar(254)
Declare @nImageDescriptionOperator		tinyint		
Declare	@nImageStatusKey 		 	int		-- The unique identifier of the image status.  
Declare @nImageStatusKeyOperator		tinyint		
Declare	@nCaseKey	 		 	int		-- The database key of the case the image belongs to.
								-- Either CaseKey or NameKey can be supplied. 
Declare @nCaseKeyOperator			tinyint		
Declare	@nNameKey 			 	int		-- The database key of the name the image belongs to.
Declare @nNameKeyOperator			tinyint		

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sFromWhere				nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sFilterCriteria			nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				="Select "
set 	@sFrom					= char(10)+"From IMAGE I"
set     @sFromWhere				= char(10)+"From IMAGE XI"
set 	@sWhere 				= char(10)+"	WHERE 1=1"
set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

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
	-- Default @pnQueryContextKey to 290.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 290)

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

	If @nErrorCode=0
	Begin
		If @sColumn='ImageKey'
		Begin
			Set @sTableColumn='I.IMAGEID'
		End
		Else 
		If @sColumn='ImageTimeStamp'
		Begin
			Set @sTableColumn='I.LOGDATETIMESTAMP'
		End
		Else 
		If @sColumn='ImageDetailTimeStamp'
		Begin
			If charindex('left join IMAGEDETAIL ID',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join IMAGEDETAIL ID	on (ID.IMAGEID = I.IMAGEID)' 
			End
			Set @sTableColumn= 'ID.LOGDATETIMESTAMP'
		End
		Else 
		If @sColumn='ImageDescription'
		Begin
			If charindex('left join IMAGEDETAIL ID',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join IMAGEDETAIL ID	on (ID.IMAGEID = I.IMAGEID)' 
			End
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IMAGEDETAIL','IMAGEDESC',null,'ID',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'ImageStatusKey'
		Begin
			If charindex('left join IMAGEDETAIL ID',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join IMAGEDETAIL ID	on (ID.IMAGEID = I.IMAGEID)' 
			End
			Set @sTableColumn='ID.IMAGESTATUS'
		End
		Else 
		If @sColumn = 'ImageStatus'
		Begin
			If charindex('left join IMAGEDETAIL ID',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join IMAGEDETAIL ID	on (ID.IMAGEID = I.IMAGEID)' 
			End

			If charindex('left join TABLECODES TC',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join TABLECODES TC	on (TC.TABLECODE = ID.IMAGESTATUS and
														TC.TABLETYPE = 11)' 
			End	
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) 
		End
		Else 
		If @sColumn = 'IsScanned'
		Begin
			If charindex('left join IMAGEDETAIL ID',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join IMAGEDETAIL ID	on (ID.IMAGEID = I.IMAGEID)' 
			End
			Set @sTableColumn='ID.SCANNEDFLAG' 
		End
		Else 
		If @sColumn = 'NetworkLocation'
		Begin
			If charindex('left join IMAGEDETAIL ID',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + 'left join IMAGEDETAIL ID	on (ID.IMAGEID = I.IMAGEID)' 
			End
			Set @sTableColumn='ID.FILELOCATION' 
		End
						
		-- If the column is being published then concatenate it to the Select list

		If datalength(@sPublishName)>0
		Begin
			Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
			Set @sComma=', '
		End
		Else 
		Begin
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

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching) 
  
	Set @sSQLString = 	
	"Select @nImageKey			= ImageKey,"+CHAR(10)+
	"	@nImageKeyOperator		= ImageKeyOperator,"+CHAR(10)+
	"	@sPickListSearch		= upper(PickListSearch),"+CHAR(10)+
	"	@sImageDescription		= upper(ImageDescription),"+CHAR(10)+
	"	@nImageDescriptionOperator	= ImageDescriptionOperator,"+CHAR(10)+				
	"	@nImageStatusKey		= ImageStatusKey,"+CHAR(10)+
	"	@nImageStatusKeyOperator	= ImageStatusKeyOperator,"+CHAR(10)+
	"	@nCaseKey			= CaseKey,"+CHAR(10)+
	"	@nCaseKeyOperator		= CaseKeyOperator,"+CHAR(10)+
	"	@nNameKey			= NameKey,"+CHAR(10)+
	"	@nNameKeyOperator		= NameKeyOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '/ipw_ListImage/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      ImageKey			int		'ImageKey/text()',"+CHAR(10)+
	"	      ImageKeyOperator		tinyint		'ImageKey/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+	
	"	      ImageDescription		nvarchar(254)	'ImageDescription/text()',"+CHAR(10)+
 	"	      ImageDescriptionOperator	tinyint		'ImageDescription/@Operator/text()',"+CHAR(10)+	
	"	      ImageStatusKey		int		'ImageStatusKey/text()',"+CHAR(10)+	
	"	      ImageStatusKeyOperator	tinyint		'ImageStatusKey/@Operator/text()',"+CHAR(10)+	
	"	      CaseKey			int		'CaseKey/text()',"+CHAR(10)+	
	"	      CaseKeyOperator		tinyint		'CaseKey/@Operator/text()',"+CHAR(10)+	
	"	      NameKey			int		'NameKey/text()',"+CHAR(10)+	
	"	      NameKeyOperator		tinyint		'NameKey/@Operator/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nImageKey			int				output,
				  @nImageKeyOperator		tinyint				output,
				  @sPickListSearch		nvarchar(254)			output,
				  @sImageDescription		nvarchar(254)			output,	
				  @nImageDescriptionOperator	tinyint				output,				
				  @nImageStatusKey		int				output,
				  @nImageStatusKeyOperator	tinyint				output,		
				  @nCaseKey			int				output,		
				  @nCaseKeyOperator		tinyint				output,		
				  @nNameKey			int				output,		
				  @nNameKeyOperator		tinyint				output',
				  @idoc				= @idoc,
				  @nImageKey 			= @nImageKey			output,
				  @nImageKeyOperator		= @nImageKeyOperator		output,
				  @sPickListSearch		= @sPickListSearch		output,
				  @sImageDescription		= @sImageDescription		output,
				  @nImageDescriptionOperator	= @nImageDescriptionOperator	output,				
				  @nImageStatusKey		= @nImageStatusKey		output,
				  @nImageStatusKeyOperator	= @nImageStatusKeyOperator	output,
				  @nCaseKey			= @nCaseKey			output,
				  @nCaseKeyOperator		= @nCaseKeyOperator		output,
				  @nNameKey			= @nNameKey			output,
				  @nNameKeyOperator		= @nNameKeyOperator		output				
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
	
		If @nImageKey is not NULL
		or @nImageKeyOperator between 5 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XI.IMAGEID " + dbo.fn_ConstructOperator(@nImageKeyOperator,@Numeric,@nImageKey, null,0)
		End		

		If @sImageDescription is not NULL
		or @nImageDescriptionOperator between 2 and 6
		Begin			
			If charindex('left join IMAGEDETAIL XID',@sFromWhere)=0
			Begin
				Set @sFromWhere = CHAR(10) + @sFromWhere + CHAR(10) + 'left join IMAGEDETAIL XID	on (XID.IMAGEID = XI.IMAGEID)' 
			End
	
			Set @sWhere = @sWhere+char(10)+"and upper("+ 
				dbo.fn_SqlTranslatedColumn('IMAGEDETAIL','IMAGEDESC',null,'XID',@sLookupCulture,@pbCalledFromCentura)+") " + 
				dbo.fn_ConstructOperator(@nImageDescriptionOperator,@String,@sImageDescription, null,0)
		End	

		If @nImageStatusKey is not NULL
		or @nImageStatusKeyOperator between 5 and 6
		Begin		
			If charindex('left join IMAGEDETAIL XID',@sFromWhere)=0
			Begin
				Set @sFromWhere = CHAR(10) + @sFromWhere + CHAR(10) + 'left join IMAGEDETAIL XID	on (XID.IMAGEID = XI.IMAGEID)' 
			End

			Set @sWhere = @sWhere+char(10)+"and upper("+ 
				dbo.fn_SqlTranslatedColumn('IMAGEDETAIL','IMAGESTATUS',null,'XID',@sLookupCulture,@pbCalledFromCentura)+") " + 
				dbo.fn_ConstructOperator(@nImageStatusKeyOperator,@Numeric,@nImageStatusKey, null,0)
		End			

		If @nCaseKey is not NULL
		or @nCaseKeyOperator between 5 and 6
		Begin
			If charindex('left join CASEIMAGE XCI',@sFromWhere)=0
			Begin
				Set @sFromWhere = CHAR(10) + @sFromWhere + CHAR(10) + 'left join CASEIMAGE XCI	on (XCI.IMAGEID = XI.IMAGEID)' 
			End
			Set @sWhere = @sWhere+char(10)+"and XCI.CASEID " + dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)
		End		
	
		If @nNameKey is not NULL
		or @nNameKeyOperator between 5 and 6
		Begin
			If charindex('left join NAMEIMAGE XNI',@sFromWhere)=0
			Begin
				Set @sFromWhere = CHAR(10) + @sFromWhere + CHAR(10) + 'left join NAMEIMAGE XNI	on (XNI.IMAGEID = XI.IMAGEID)' 
			End
			Set @sWhere = @sWhere+char(10)+"and XNI.NAMENO " + dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
		End	

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced.  The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If PickListSearch can be converted to a numeric value search IMAGEIDs
			
			If isnumeric(@sPickListSearch) = 1
			Begin
				Set @bExists = 0
				-- Check if IMAGEID Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  "from IMAGE I"+char(10)+
						  "where"+char(10)+
						  "exists (Select 1 "+char(10)+
						  	   @sFromWhere+char(10)+
						           @sWhere+char(10)+
							   "and XI.IMAGEID = I.IMAGEID)"+char(10)+
						  "and cast(I.IMAGEID as nvarchar(11))=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)

				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(254)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch

				If @bExists=1
				Begin 
					Set @sWhere=@sWhere + char(10) + "and (I.IMAGEID=" + @sPickListSearch + ")"
				End
				Else
				Begin 
					If charindex('left join IMAGEDETAIL XID',@sFromWhere)=0
					Begin
						Set @sFromWhere = CHAR(10) + @sFromWhere + CHAR(10) + 'left join IMAGEDETAIL XID	on (XID.IMAGEID = XI.IMAGEID)' 
					End

					Set @sWhere=@sWhere+char(10)+"and upper("+
						dbo.fn_SqlTranslatedColumn('IMAGEDETAIL','IMAGEDESC',null,'XID',@sLookupCulture,@pbCalledFromCentura)+
						") like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
				End
			End
			Else 
			Begin
				If charindex('left join IMAGEDETAIL XID',@sFromWhere)=0
				Begin
					Set @sFromWhere = CHAR(10) + @sFromWhere + CHAR(10) + 'left join IMAGEDETAIL XID	on (XID.IMAGEID = XI.IMAGEID)' 
				End
			
				Set @sWhere=@sWhere+char(10)+"and upper("+
					dbo.fn_SqlTranslatedColumn('IMAGEDETAIL','IMAGEDESC',null,'XID',@sLookupCulture,@pbCalledFromCentura)+
					") like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End
	
	End
End

If @nErrorCode=0
Begin  
	Set @sFilterCriteria = " where exists (Select 1 "+char(10)+
		  	   	@sFromWhere+char(10)+
		           	@sWhere+char(10)+
			  	"and XI.IMAGEID = I.IMAGEID)"+char(10)

	-- Now execute the constructed SQL to return the result set
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sFilterCriteria + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListImage to public
GO
