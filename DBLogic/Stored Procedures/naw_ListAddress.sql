        -----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAddress
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAddress.'
	Drop procedure [dbo].[naw_ListAddress]
End
Print '**** Creating Stored Procedure dbo.naw_ListAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListAddress
(
        @pnRowCount		int             = null  output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar (10)	= null,
	@pnQueryContextKey	int		= 70, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests	ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria	ntext		= null,	-- The filtering to be performed on the result set.	
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	naw_ListAddress
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the requested Address information, for name addresses that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Apr 2006	SW	RFC3301	1	Procedure created
-- 11 Dec 2008	MF	17136		2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 14 Jun 2011  MS      RFC7998 		3       Added @pnRowCount parameter for Silverlight pick list
-- 07 Jul 2011	DL	RFC10830 	4	Specify database collation default to temp table columns of type varchar, nvarchar and char

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables

Declare	@nErrorCode				int
Declare @sSQLString				nvarchar(4000)
Declare @sLookupCulture				nvarchar(10)

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
Declare @nAddressKey 				int		-- The database key of the address.
Declare @nAddressKeyOperator			tinyint	
Declare @nNameKey 				int		-- The database key of the name. 
Declare @nNameKeyOperator			tinyint		

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
set 	@sSelect				="Select "
set 	@sFrom					= char(10)+"from	NAMEADDRESS NA"
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
	-- Default @pnQueryContextKey to 70.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 70)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

-- Construct from clause
Select	@sFrom = @sFrom+char(10)+"join		ADDRESS A on (A.ADDRESSCODE = NA.ADDRESSCODE)"+
			char(10)+"left join	COUNTRY C on (C.COUNTRYCODE = A.COUNTRYCODE)"+
			char(10)+"left join	STATE S	on (S.COUNTRYCODE = A.COUNTRYCODE and S.STATE = A.STATE)"+
			char(10)+"left join	SITECONTROL HC on (HC.CONTROLID = 'HOMECOUNTRY')"
where exists(
	Select	1
	from	@tblOutputRequests
	where	[ID] in ('AddressKey', 'OriginalAddress')
)

Select	@sFrom = @sFrom+char(10)+"left join	SITECONTROL SC on (SC.CONTROLID = "+dbo.fn_WrapQuotes('Address Style ' + @sLookupCulture, 0, 0)+")"
where exists(
	Select	1
	from	@tblOutputRequests
	where	[ID] = 'OriginalAddress'
)


Select	@sFrom = @sFrom+char(10)+"left join	TABLECODES ADDSS on (ADDSS.TABLECODE = NA.ADDRESSSTATUS)"
where exists(
	Select	1
	from	@tblOutputRequests
	where	[ID] = 'AddressStatus'
)

Select	@sFrom = @sFrom+char(10)+"left join	TABLECODES ATYPE on (ATYPE.TABLECODE = NA.ADDRESSTYPE)"
where exists(
	Select	1
	from	@tblOutputRequests
	where	[ID] = 'AddressType'
)

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
		If @sColumn='AddressKey'
		Begin
			Set @sTableColumn = 'NA.ADDRESSCODE'
		End
		Else 
		If @sColumn='OriginalAddress'
		Begin
			-- Literally doing Set @sTableColumn = 'dbo.fn_GetFormattedAddress(NA.ADDRESSCODE, null, null, C.ADDRESSSTYLE, ' + cast(@pbCalledFromCentura as varchar(10)) + ')'	
			Set @sTableColumn = '
				dbo.fn_FormatAddress(
				A.STREET1, 
				A.STREET2, 
				A.CITY, 
				A.STATE, 
				S.STATENAME, 
				A.POSTCODE, 
				-- The country name is included in the formatted address 
				-- if the address in not in the home country
				CASE WHEN HC.COLCHARACTER = C.COUNTRYCODE
				     THEN NULL
				     ELSE C.POSTALNAME END,
				C.POSTCODEFIRST, 
				C.STATEABBREVIATED, 
				C.POSTCODELITERAL, 
				C.ADDRESSSTYLE)'
		End
		Else 
		If @sColumn='Address'
		Begin
			-- Literally doing Set @sTableColumn = 'dbo.fn_GetFormattedAddress(NA.ADDRESSCODE, ' + dbo.fn_WrapQuotes(@psCulture, 0, 0) + ', null, C.ADDRESSSTYLE, ' + cast(@pbCalledFromCentura as varchar(10)) + ')'
			Set @sTableColumn = '
				dbo.fn_FormatAddress(
				dbo.fn_GetTranslation(A.STREET1,null,A.STREET1_TID,'+isnull(dbo.fn_WrapQuotes(@sLookupCulture, 0, 0), 'null')+'),
				A.STREET2, 
				dbo.fn_GetTranslation(A.CITY,null,A.CITY_TID,'+isnull(dbo.fn_WrapQuotes(@sLookupCulture, 0, 0), 'null')+'),
				A.STATE, 
				dbo.fn_GetTranslation(S.STATENAME,null,S.STATENAME_TID,'+isnull(dbo.fn_WrapQuotes(@sLookupCulture, 0, 0), 'null')+'),
				A.POSTCODE, 
				-- The country name is included in the formatted address 
				-- if the address in not in the home country
				CASE WHEN HC.COLCHARACTER = C.COUNTRYCODE
				     THEN NULL
				     ELSE dbo.fn_GetTranslation(C.POSTALNAME,null,C.POSTALNAME_TID,'+isnull(dbo.fn_WrapQuotes(@sLookupCulture, 0, 0), 'null')+') END,
				C.POSTCODEFIRST, 
				C.STATEABBREVIATED, 
				dbo.fn_GetTranslation(C.POSTCODELITERAL,null,C.POSTCODELITERAL_TID,'+isnull(dbo.fn_WrapQuotes(@sLookupCulture, 0, 0), 'null')+'), 
				coalesce(C.ADDRESSSTYLE, SC.COLINTEGER))'
		End
		Else 
		If @sColumn = 'AddressStatus'
		Begin
			Set @sTableColumn='ADDSS.[DESCRIPTION]'
		End
		Else 
		If @sColumn = 'AddressType'
		Begin
			Set @sTableColumn='ATYPE.[DESCRIPTION]'
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

-- Construct Where clause.
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
	"Select @nAddressKey			= AddressKey,"+CHAR(10)+
	"	@nAddressKeyOperator		= AddressKeyOperator,"+CHAR(10)+
	"	@nNameKey			= NameKey,"+CHAR(10)+
	"	@nNameKeyOperator		= NameKeyOperator"+CHAR(10)+	
	"from	OPENXML (@idoc, '/naw_ListAddress/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      AddressKey		int		'AddressKey/text()',"+CHAR(10)+
	"	      AddressKeyOperator	tinyint		'AddressKey/@Operator/text()',"+CHAR(10)+
	"	      NameKey			int		'NameKey/text()',"+CHAR(10)+
 	"	      NameKeyOperator		tinyint		'NameKey/@Operator/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nAddressKey 			int			output,
				  @nAddressKeyOperator		tinyint			output,
				  @nNameKey			int			output,
				  @nNameKeyOperator		tinyint			output',
				  @idoc				= @idoc,
				  @nAddressKey 			= @nAddressKey		output,
				  @nAddressKeyOperator		= @nAddressKeyOperator	output,
				  @nNameKey			= @nNameKey		output,
				  @nNameKeyOperator		= @nNameKeyOperator	output	
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0
	Begin
		If @nAddressKey is not NULL
		or @nAddressKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and NA.ADDRESSCODE " + dbo.fn_ConstructOperator(@nAddressKeyOperator,@Numeric,@nAddressKey, null,0)
		End		

		If @nNameKey is not NULL
		or @nNameKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and NA.NAMENO " + dbo.fn_ConstructOperator(@nNameKeyOperator,@Numeric,@nNameKey, null,0)
		End	
	End
End

If @nErrorCode=0
Begin 
	-- Now execute the constructed SQL to return the result set
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListAddress to public
GO
