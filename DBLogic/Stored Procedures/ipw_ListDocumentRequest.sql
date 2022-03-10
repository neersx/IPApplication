-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListDocumentRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListDocumentRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListDocumentRequest.'
	Drop procedure [dbo].[ipw_ListDocumentRequest]
End
Print '**** Creating Stored Procedure dbo.ipw_ListDocumentRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListDocumentRequest
(
	@pnRowCount		int 		= null		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar (10)	= null,		-- the language in which output is to be expressed
	@pbIsExternalUser	bit		= null,		
	@pnQueryContextKey	int		= 360,		-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests	ntext		= null,		-- The columns and sorting required in the result set
	@ptXMLFilterCriteria	ntext		= null,		-- The filtering to be performed on the result set
	@pbCalledFromCentura	bit		= 0,		-- Indicates that Centura called the stored procedure.
	@pnPageStartRow		int		= null,		-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow		int		= null,
	@pbPrintSQL		bit		= null	-- When set to 1, the executed SQL statement is printed out.
)
as
-- PROCEDURE:	ipw_ListDocumentRequest
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Search stored procedure on document request

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Mar 2007	SW	RFC3646	1	Procedure created
-- 22 Feb 2008	SF	RFC6228	2	Return formatted name for recipient and return translated data where appropriate.
-- 06 May 2009	AT	RFC7970	3	Fixed Period Range filtering
-- 07 Jan 2010	ASH	RFC8353	4	Introduce variable @pbPrintSQL.
-- 07 Jul 2011	DL	RFC10830 5	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 05 Jul 2013	vql	R13629	6	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	7	Adjust formatted names logic (DR-15543).
-- 14 Nov 2018  AV  75198/DR-45358	8   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture			nvarchar(10)

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
Declare @nRequestKey 				int	-- The primary key of the document request.
Declare @nRequestKeyOperator			tinyint
Declare @sRequestDescription			nvarchar(254)
Declare @nRequestDescriptionOperator		tinyint
Declare @sPickListSearch			nvarchar(254)
Declare @nRecipientKey 				int
Declare @nRecipientKeyOperator			tinyint
Declare @nDocumentTypeKey 			int
Declare @nDocumentTypeKeyOperator 		tinyint

Declare @nNextGenerateDateDateRangeOperator	tinyint
Declare @dtNextGenerateDateDateRangeFrom	datetime
Declare @dtNextGenerateDateDateRangeTo		datetime
Declare @nNextGenerateDatePeriodRangeOperator	tinyint
Declare @sNextGenerateDatePeriodRangeType	nvarchar(2)
Declare @nNextGenerateDatePeriodRangeFrom	smallint
Declare @nNextGenerateDatePeriodRangeTo		smallint

Declare @nLastGenerateDateDateRangeOperator	tinyint
Declare @dtLastGenerateDateDateRangeFrom	datetime
Declare @dtLastGenerateDateDateRangeTo		datetime
Declare @nLastGenerateDatePeriodRangeOperator	tinyint
Declare @sLastGenerateDatePeriodRangeType	nvarchar(2)
Declare @nLastGenerateDatePeriodRangeFrom	smallint
Declare @nLastGenerateDatePeriodRangeTo		smallint


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

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+" From DOCUMENTREQUEST DR"
set 	@sWhere 				= char(10)+" WHERE 1=1"

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
	-- Default @pnQueryContextKey to 360.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 360)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

-- Extract the @pbIsExternalUser from UserIdentity if it has not been supplied.
If @nErrorCode=0
and @pbIsExternalUser is null
Begin		
	Set @sSQLString='
	Select @pbIsExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@pbIsExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @pbIsExternalUser	=@pbIsExternalUser	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode=0
and @pbIsExternalUser = 1
Begin
	Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + "join dbo.fn_FilterUserNames(" + cast(@pnUserIdentityId as nvarchar(50)) + ", 1) EXT on (EXT.NAMENO = DR.RECIPIENT)"
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

		If @sColumn='RequestKey'
		Begin
			Set @sTableColumn='DR.REQUESTID'
		End

		Else If @sColumn='RequestDescription'
		Begin
			Set @sTableColumn='DR.[DESCRIPTION]'
		End

		Else If @sColumn='RecipientNameKey'
		Begin
			Set @sTableColumn='DR.RECIPIENT'
		End

		Else If @sColumn='RecipientNameCode'
		Begin
			Set @sTableColumn='N.NAMECODE'

			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + "left join NAME N on (N.NAMENO = DR.RECIPIENT)"
			End
		End

		Else If @sColumn='RecipientName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)'

			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + "left join NAME N on (N.NAMENO = DR.RECIPIENT)"
			End
		End

		Else If @sColumn='DocumentType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('DOCUMENTDEFINITION','[NAME]',null,'DD',@sLookupCulture,@pbCalledFromCentura)

			If charindex('left join DOCUMENTDEFINITION DD',@sFrom)=0
			Begin
				Set @sFrom = CHAR(10) + @sFrom + CHAR(10) + "left join DOCUMENTDEFINITION DD on (DD.DOCUMENTDEFID = DR.DOCUMENTDEFID)"
			End
		End

		Else If @sColumn='NextGenerate'
		Begin
			Set @sTableColumn='DR.NEXTGENERATE'
		End

		Else If @sColumn='LastGenerated'
		Begin
			Set @sTableColumn='DR.LASTGENERATED'
		End

		Else If @sColumn='Frequency'
		Begin
			Set @sTableColumn='DR.FREQUENCY'
		End

		Else If @sColumn='Period'
		Begin
			Set @sTableColumn='DR.PERIODTYPE'
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

	-- 1) Retrieve the filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching)   

	Set @sSQLString = 	
	"Select @nRequestKey				= RequestKey,"+CHAR(10)+
	"	@nRequestKeyOperator			= RequestKeyOperator,"+CHAR(10)+
	"	@sRequestDescription			= RequestDescription,"+CHAR(10)+
	"	@nRequestDescriptionOperator		= RequestDescriptionOperator,"+CHAR(10)+
	"	@sPickListSearch			= PickListSearch,"+CHAR(10)+
	"	@nRecipientKey				= RecipientKey,"+CHAR(10)+
	"	@nRecipientKeyOperator			= RecipientKeyOperator,"+CHAR(10)+
	"	@nDocumentTypeKey			= DocumentTypeKey,"+CHAR(10)+
	"	@nDocumentTypeKeyOperator		= DocumentTypeKeyOperator,"+CHAR(10)+

	"	@nNextGenerateDateDateRangeOperator	= NextGenerateDateDateRangeOperator,"+CHAR(10)+
	"	@dtNextGenerateDateDateRangeFrom	= NextGenerateDateDateRangeFrom,"+CHAR(10)+
	"	@dtNextGenerateDateDateRangeTo		= NextGenerateDateDateRangeTo,"+CHAR(10)+
	"	@nNextGenerateDatePeriodRangeOperator	= NextGenerateDatePeriodRangeOperator,"+CHAR(10)+
	"	@sNextGenerateDatePeriodRangeType	= CASE WHEN NextGenerateDatePeriodRangeType = 'D' THEN 'dd'"+CHAR(10)+
	"			     			WHEN NextGenerateDatePeriodRangeType = 'W' THEN 'wk'"+CHAR(10)+
	"			     			WHEN NextGenerateDatePeriodRangeType = 'M' THEN 'mm'"+CHAR(10)+
	"			     			WHEN NextGenerateDatePeriodRangeType = 'Y' THEN 'yy' end,"+CHAR(10)+
	"	@nNextGenerateDatePeriodRangeFrom	= NextGenerateDatePeriodRangeFrom,"+CHAR(10)+
	"	@nNextGenerateDatePeriodRangeTo		= NextGenerateDatePeriodRangeTo,"+CHAR(10)+

	"	@nLastGenerateDateDateRangeOperator	= LastGenerateDateDateRangeOperator,"+CHAR(10)+
	"	@dtLastGenerateDateDateRangeFrom	= LastGenerateDateDateRangeFrom,"+CHAR(10)+
	"	@dtLastGenerateDateDateRangeTo		= LastGenerateDateDateRangeTo,"+CHAR(10)+
	"	@nLastGenerateDatePeriodRangeOperator	= LastGenerateDatePeriodRangeOperator,"+CHAR(10)+
	"	@sLastGenerateDatePeriodRangeType	= CASE WHEN LastGenerateDatePeriodRangeType = 'D' THEN 'dd'"+CHAR(10)+
	"			     			WHEN LastGenerateDatePeriodRangeType = 'W' THEN 'wk'"+CHAR(10)+
	"			     			WHEN LastGenerateDatePeriodRangeType = 'M' THEN 'mm'"+CHAR(10)+
	"			     			WHEN LastGenerateDatePeriodRangeType = 'Y' THEN 'yy' end,"+CHAR(10)+
	"	@nLastGenerateDatePeriodRangeFrom	= LastGenerateDatePeriodRangeFrom,"+CHAR(10)+
	"	@nLastGenerateDatePeriodRangeTo		= LastGenerateDatePeriodRangeTo"+CHAR(10)+

	"from	OPENXML (@idoc, '/ipw_ListDocumentRequest/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      RequestKey			int		'RequestKey/text()',"+CHAR(10)+
	"	      RequestKeyOperator		tinyint		'RequestKey/@Operator/text()',"+CHAR(10)+
	"	      RequestDescription		nvarchar(254)	'RequestDescription/text()',"+CHAR(10)+
	"	      RequestDescriptionOperator	tinyint		'RequestDescription/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch			nvarchar(254)	'PickListSearch/text()',"+CHAR(10)+
	"	      RecipientKey			int		'RecipientKey/text()',"+CHAR(10)+
	"	      RecipientKeyOperator		tinyint		'RecipientKey/@Operator/text()',"+CHAR(10)+
	"	      DocumentTypeKey			int		'DocumentTypeKey/text()',"+CHAR(10)+
	"	      DocumentTypeKeyOperator		tinyint		'DocumentTypeKey/@Operator/text()',"+CHAR(10)+

	"	      NextGenerateDateDateRangeOperator	tinyint		'NextGenerateDate/DateRange/@Operator/text()',"+CHAR(10)+
	"	      NextGenerateDateDateRangeFrom	datetime	'NextGenerateDate/DateRange/From/text()',"+CHAR(10)+
	"	      NextGenerateDateDateRangeTo	datetime	'NextGenerateDate/DateRange/To/text()',"+CHAR(10)+
	"	      NextGenerateDatePeriodRangeOperator tinyint	'NextGenerateDate/PeriodRange/@Operator/text()',"+CHAR(10)+
	"	      NextGenerateDatePeriodRangeType	nvarchar(2)	'NextGenerateDate/PeriodRange/Type/text()',"+CHAR(10)+
	"	      NextGenerateDatePeriodRangeFrom	smallint	'NextGenerateDate/PeriodRange/From/text()',"+CHAR(10)+
	"	      NextGenerateDatePeriodRangeTo	smallint	'NextGenerateDate/PeriodRange/To/text()',"+CHAR(10)+

	"	      LastGenerateDateDateRangeOperator	tinyint		'LastGeneratedDate/DateRange/@Operator/text()',"+CHAR(10)+
	"	      LastGenerateDateDateRangeFrom	datetime	'LastGeneratedDate/DateRange/From/text()',"+CHAR(10)+
	"	      LastGenerateDateDateRangeTo	datetime	'LastGeneratedDate/DateRange/To/text()',"+CHAR(10)+
	"	      LastGenerateDatePeriodRangeOperator tinyint	'LastGeneratedDate/PeriodRange/@Operator/text()',"+CHAR(10)+
	"	      LastGenerateDatePeriodRangeType	nvarchar(2)	'LastGeneratedDate/PeriodRange/Type/text()',"+CHAR(10)+
	"	      LastGenerateDatePeriodRangeFrom	smallint	'LastGeneratedDate/PeriodRange/From/text()',"+CHAR(10)+
	"	      LastGenerateDatePeriodRangeTo	smallint	'LastGeneratedDate/PeriodRange/To/text()'"+CHAR(10)+
     	"		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nRequestKey 			int			output,
				  @nRequestKeyOperator		tinyint			output,
				  @sRequestDescription		nvarchar(254)		output,
				  @nRequestDescriptionOperator	tinyint			output,
				  @sPickListSearch		nvarchar(254)		output,
				  @nRecipientKey		int			output,
				  @nRecipientKeyOperator	tinyint			output,
				  @nDocumentTypeKey		int			output,
				  @nDocumentTypeKeyOperator	tinyint			output,

				  @nNextGenerateDateDateRangeOperator	tinyint		output,
				  @dtNextGenerateDateDateRangeFrom	datetime	output,
				  @dtNextGenerateDateDateRangeTo	datetime	output,
				  @nNextGenerateDatePeriodRangeOperator	tinyint		output,
				  @sNextGenerateDatePeriodRangeType	nvarchar(2)	output,
				  @nNextGenerateDatePeriodRangeFrom	smallint	output,
				  @nNextGenerateDatePeriodRangeTo	smallint	output,

				  @nLastGenerateDateDateRangeOperator	tinyint		output,
				  @dtLastGenerateDateDateRangeFrom	datetime	output,
				  @dtLastGenerateDateDateRangeTo	datetime	output,
				  @nLastGenerateDatePeriodRangeOperator	tinyint		output,
				  @sLastGenerateDatePeriodRangeType	nvarchar(2)	output,
				  @nLastGenerateDatePeriodRangeFrom	smallint	output,
				  @nLastGenerateDatePeriodRangeTo	smallint	output',

				  @idoc				= @idoc,
				  @nRequestKey 			= @nRequestKey		output,
				  @nRequestKeyOperator		= @nRequestKeyOperator	output,
				  @sRequestDescription		= @sRequestDescription	output,
				  @nRequestDescriptionOperator	= @nRequestDescriptionOperator	output,
				  @sPickListSearch		= @sPickListSearch	output,
				  @nRecipientKey		= @nRecipientKey	output,
				  @nRecipientKeyOperator	= @nRecipientKeyOperator	output,
				  @nDocumentTypeKey		= @nDocumentTypeKey	output,
				  @nDocumentTypeKeyOperator	= @nDocumentTypeKeyOperator	output,

				  @nNextGenerateDateDateRangeOperator	= @nNextGenerateDateDateRangeOperator	output,
				  @dtNextGenerateDateDateRangeFrom	= @dtNextGenerateDateDateRangeFrom	output,
				  @dtNextGenerateDateDateRangeTo	= @dtNextGenerateDateDateRangeTo	output,
				  @nNextGenerateDatePeriodRangeOperator	= @nNextGenerateDatePeriodRangeOperator	output,
				  @sNextGenerateDatePeriodRangeType	= @sNextGenerateDatePeriodRangeType	output,
				  @nNextGenerateDatePeriodRangeFrom	= @nNextGenerateDatePeriodRangeFrom	output,
				  @nNextGenerateDatePeriodRangeTo	= @nNextGenerateDatePeriodRangeTo	output,

				  @nLastGenerateDateDateRangeOperator	= @nLastGenerateDateDateRangeOperator	output,
				  @dtLastGenerateDateDateRangeFrom	= @dtLastGenerateDateDateRangeFrom	output,
				  @dtLastGenerateDateDateRangeTo	= @dtLastGenerateDateDateRangeTo	output,
				  @nLastGenerateDatePeriodRangeOperator	= @nLastGenerateDatePeriodRangeOperator	output,
				  @sLastGenerateDatePeriodRangeType	= @sLastGenerateDatePeriodRangeType	output,
				  @nLastGenerateDatePeriodRangeFrom	= @nLastGenerateDatePeriodRangeFrom	output,
				  @nLastGenerateDatePeriodRangeTo	= @nLastGenerateDatePeriodRangeTo	output

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin	
		If @nRequestKey is not NULL
		or @nRequestKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and DR.REQUESTID " + dbo.fn_ConstructOperator(@nRequestKeyOperator,@Numeric,@nRequestKey, null, 0)
		End

		If @sRequestDescription is not NULL
		or @nRequestDescriptionOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(DR.[DESCRIPTION]) " + dbo.fn_ConstructOperator(@nRequestDescriptionOperator,@String,upper(@sRequestDescription), null, 0)
		End

		If @sPickListSearch is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+"and upper(DR.[DESCRIPTION]) like "+ dbo.fn_WrapQuotes(upper(@sPickListSearch) + '%',0,0)
		End

		If @nRecipientKey is not NULL
		or @nRecipientKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and DR.RECIPIENT " + dbo.fn_ConstructOperator(@nRecipientKeyOperator,@Numeric,@nRecipientKey, null, 0)
		End	

		If @nDocumentTypeKey is not NULL
		or @nDocumentTypeKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and DR.DOCUMENTDEFID " + dbo.fn_ConstructOperator(@nDocumentTypeKeyOperator,@Numeric,@nDocumentTypeKey, null, 0)
		End


		-- The dates are calculated by adding the period and type to the current date.  
		If (@nNextGenerateDatePeriodRangeFrom is not NULL
			or  @nNextGenerateDatePeriodRangeTo is not NULL)
			and @sNextGenerateDatePeriodRangeType is not NULL
			and @nNextGenerateDatePeriodRangeOperator is not NULL
		Begin
			If @nNextGenerateDatePeriodRangeFrom is not null
			Begin
				Set @sSQLString = "Set @dtNextGenerateDateDateRangeFrom = dateadd("+@sNextGenerateDatePeriodRangeType+", @nNextGenerateDatePeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

				execute sp_executesql @sSQLString,
						N'@dtNextGenerateDateDateRangeFrom	datetime 				output,
 						  @sNextGenerateDatePeriodRangeType	nvarchar(2),
						  @nNextGenerateDatePeriodRangeFrom	smallint',
  						  @dtNextGenerateDateDateRangeFrom	= @dtNextGenerateDateDateRangeFrom 	output,
						  @sNextGenerateDatePeriodRangeType	= @sNextGenerateDatePeriodRangeType,
						  @nNextGenerateDatePeriodRangeFrom	= @nNextGenerateDatePeriodRangeFrom				  
			End

			If @nNextGenerateDatePeriodRangeTo is not null
			Begin
				Set @sSQLString = "Set @dtNextGenerateDateDateRangeTo = dateadd("+@sNextGenerateDatePeriodRangeType+", @nNextGenerateDatePeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

				execute sp_executesql @sSQLString,
						N'@dtNextGenerateDateDateRangeTo	datetime 				output,
 						  @sNextGenerateDatePeriodRangeType	nvarchar(2),
						  @nNextGenerateDatePeriodRangeTo	smallint',
  						  @dtNextGenerateDateDateRangeTo	= @dtNextGenerateDateDateRangeTo 	output,
						  @sNextGenerateDatePeriodRangeType	= @sNextGenerateDatePeriodRangeType,
						  @nNextGenerateDatePeriodRangeTo	= @nNextGenerateDatePeriodRangeTo				
			End	

			-- For the PeriodRange filtering swap around DateRangeFrom and DateRangeTo:
			Set @sWhere = @sWhere+char(10)+" and DR.NEXTGENERATE "+dbo.fn_ConstructOperator(@nNextGenerateDatePeriodRangeOperator,@Date,convert(nvarchar,@dtNextGenerateDateDateRangeFrom,112), convert(nvarchar,@dtNextGenerateDateDateRangeTo,112),0)
		End
		Else If  @nNextGenerateDateDateRangeOperator is not null
			and (@dtNextGenerateDateDateRangeFrom is not null
			or   @dtNextGenerateDateDateRangeTo is not null)
		Begin
			Set @sWhere = @sWhere+char(10)+" and DR.NEXTGENERATE "+dbo.fn_ConstructOperator(@nNextGenerateDateDateRangeOperator,@Date,convert(nvarchar,@dtNextGenerateDateDateRangeFrom,112), convert(nvarchar,@dtNextGenerateDateDateRangeTo,112),0)
		End	

		-- The dates are calculated by adding the period and type to the current date.  
		If (@nLastGenerateDatePeriodRangeFrom is not NULL
			or  @nLastGenerateDatePeriodRangeTo is not NULL)
			and @sLastGenerateDatePeriodRangeType is not NULL
			and @nLastGenerateDatePeriodRangeOperator is not NULL
		Begin
			If @nLastGenerateDatePeriodRangeFrom is not null
			Begin
				Set @sSQLString = "Set @dtLastGenerateDateDateRangeFrom = dateadd("+@sLastGenerateDatePeriodRangeType+", -@nLastGenerateDatePeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

				execute sp_executesql @sSQLString,
						N'@dtLastGenerateDateDateRangeFrom	datetime 				output,
 						  @sLastGenerateDatePeriodRangeType	nvarchar(2),
						  @nLastGenerateDatePeriodRangeFrom	smallint',
  						  @dtLastGenerateDateDateRangeFrom	= @dtLastGenerateDateDateRangeFrom 	output,
						  @sLastGenerateDatePeriodRangeType	= @sLastGenerateDatePeriodRangeType,
						  @nLastGenerateDatePeriodRangeFrom	= @nLastGenerateDatePeriodRangeFrom				  
			End
		
			If @nLastGenerateDatePeriodRangeTo is not null
			Begin
				Set @sSQLString = "Set @dtLastGenerateDateDateRangeTo = dateadd("+@sLastGenerateDatePeriodRangeType+", -@nLastGenerateDatePeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

				execute sp_executesql @sSQLString,
						N'@dtLastGenerateDateDateRangeTo	datetime 				output,
 						  @sLastGenerateDatePeriodRangeType	nvarchar(2),
						  @nLastGenerateDatePeriodRangeTo	smallint',
  						  @dtLastGenerateDateDateRangeTo	= @dtLastGenerateDateDateRangeTo 	output,
						  @sLastGenerateDatePeriodRangeType	= @sLastGenerateDatePeriodRangeType,
						  @nLastGenerateDatePeriodRangeTo	= @nLastGenerateDatePeriodRangeTo				
			End	

			-- For the PeriodRange filtering swap around DateRangeFrom and DateRangeTo:
			Set @sWhere = @sWhere+char(10)+" and DR.LASTGENERATED "+dbo.fn_ConstructOperator(@nLastGenerateDatePeriodRangeOperator,@Date,convert(nvarchar,@dtLastGenerateDateDateRangeTo,112), convert(nvarchar,@dtLastGenerateDateDateRangeFrom,112),0)									

		End
		Else If  @nLastGenerateDateDateRangeOperator is not null
			and (@dtLastGenerateDateDateRangeFrom is not null
			or   @dtLastGenerateDateDateRangeTo is not null)
		Begin
			Set @sWhere = @sWhere+char(10)+" and DR.LASTGENERATED "+dbo.fn_ConstructOperator(@nLastGenerateDateDateRangeOperator,@Date,convert(nvarchar,@dtLastGenerateDateDateRangeFrom,112), convert(nvarchar,@dtLastGenerateDateDateRangeTo,112),0)									
		End

	End
End

If @nErrorCode=0
Begin  
	-- Now execute the constructed SQL to return the result set
	If @pbPrintSQL = 1
	Begin	
	 print (@sSelect + @sFrom + @sWhere + @sOrder)		
	End
	 Exec (@sSelect + @sFrom + @sWhere + @sOrder)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListDocumentRequest to public
GO
