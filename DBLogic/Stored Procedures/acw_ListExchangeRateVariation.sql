-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListExchangeRateVariation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListExchangeRateVariation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListExchangeRateVariation.'
	Drop procedure [dbo].[acw_ListExchangeRateVariation]
	Print '**** Creating Stored Procedure dbo.acw_ListExchangeRateVariation...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListExchangeRateVariation
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 830, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	[acw_ListExchangeRateVariation]
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the Exchange Rate Variation records on the basis of Filter Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version		Description
-- -----------	-------	------	----------	----------------------------------------------- 
-- 25 Jun 2010	DV	RFC7350		1	Procedure created
-- 11 Jul 2011	DL	RFC19795	2	Specify Collation Database Default for temp table.
-- 24 Oct 2017	AK	R72645	        3	Make compatible with case sensitive server with case insensitive database.

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
declare	@pnExchScheduleID	int
declare @psCurrencyCode		nvarchar(3)
declare	@psCaseType			nchar(1)
declare	@psCaseCategory		nvarchar(2)
declare	@psPropertyType		nchar(1)
declare	@psCountryCode		nvarchar(3)
declare	@psSubType			nvarchar(2)
declare	@pbExactMatch		bit

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
Set	@CommaString			='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+"From EXCHRATEVARIATION E"
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
	-- Default @pnQueryContextKey to 830.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 830)

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
		If @sColumn='ExchVariationKey'
		Begin
			Set @sTableColumn='E.EXCHVARIATIONID'
		End
		 
		Else If @sColumn = 'Currency'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CU',@sLookupCulture,@pbCalledFromCentura) 
			Set @sFrom = @sFrom +CHAR(10)+'left join CURRENCY CU on (CU.CURRENCY=E.CURRENCYCODE)'
		End
		 
		Else If @sColumn = 'ExchRateSchedule'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'ES',@sLookupCulture,@pbCalledFromCentura) 
			Set @sFrom = @sFrom +CHAR(10)+'left join EXCHRATESCHEDULE ES on (ES.EXCHSCHEDULEID=E.EXCHSCHEDULEID)'
		End
		 
		Else If @sColumn='BuyFactor'
		Begin
			Set @sTableColumn='E.BUYFACTOR'
		End
		
		Else If @sColumn='SellFactor'
		Begin
			Set @sTableColumn='E.SELLFACTOR'
		End
		
		Else If @sColumn='BuyRate'
		Begin
			Set @sTableColumn='E.BUYRATE'
		End
		
		Else If @sColumn='SellRate'
		Begin
			Set @sTableColumn='E.SELLRATE'
		End
		
		Else If @sColumn='CaseType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join CASETYPE CT on (CT.CASETYPE=E.CASETYPE)'
		End
		 
		Else If @sColumn='CaseType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join CASETYPE CT on (CT.CASETYPE=E.CASETYPE)'
		End
		 
		Else If @sColumn = 'PropertyType'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=E.PROPERTYTYPE'
					+CHAR(10)+'and VP.COUNTRYCODE =(select min(VP1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDPROPERTY VP1'
					+CHAR(10)+'where VP1.COUNTRYCODE in ("ZZZ",E.COUNTRYCODE)))'   
					+CHAR(10)+'left join PROPERTYTYPE P	on (P.PROPERTYTYPE=E.PROPERTYTYPE)'
		End

		Else If @sColumn = 'Country'
		Begin
			Set @sTableColumn='C.COUNTRY'
			Set @sFrom = @sFrom +CHAR(10)+'left join COUNTRY C on (C.COUNTRYCODE=E.COUNTRYCODE)'
		End

		Else If @sColumn = 'Category'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=E.PROPERTYTYPE'
					+CHAR(10)+'and VC.CASETYPE = E.CASETYPE'
					+CHAR(10)+'and VC.CASECATEGORY = E.CASECATEGORY'
					+CHAR(10)+'and VC.COUNTRYCODE =( select min(VC1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDCATEGORY VC1'
					+CHAR(10)+'where VC1.CASETYPE = E.CASETYPE'
					+CHAR(10)+'and VC1.PROPERTYTYPE = E.PROPERTYTYPE'
					+CHAR(10)+'and VC1.COUNTRYCODE in ("ZZZ",E.COUNTRYCODE)))'
					+CHAR(10)+'left join CASECATEGORY CC on (CC.CASETYPE=E.CASETYPE'
					+CHAR(10)+'and CC.CASECATEGORY = E.CASECATEGORY)'
		End

		Else If @sColumn = 'SubType'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE=E.PROPERTYTYPE'
					+CHAR(10)+'and VS.CASETYPE = E.CASETYPE'
					+CHAR(10)+'and VS.CASECATEGORY = E.CASECATEGORY'
					+CHAR(10)+'and VS.SUBTYPE = E.CASESUBTYPE'
					+CHAR(10)+'and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDSUBTYPE VS1'
					+CHAR(10)+'where VS1.CASETYPE = E.CASETYPE'
					+CHAR(10)+'and VS1.PROPERTYTYPE = E.PROPERTYTYPE'
					+CHAR(10)+'and VS1.CASECATEGORY = E.CASECATEGORY'
					+CHAR(10)+'and VS1.COUNTRYCODE in ("ZZZ",E.COUNTRYCODE)))'
	                                +CHAR(10)+'left join SUBTYPE S on (S.SUBTYPE=E.CASESUBTYPE)'
		End
								
		If @sColumn='EffectiveDate'
		Begin
			Set @sTableColumn='E.EFFECTIVEDATE'
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
	-- 1) Retrieve the FilterCriteria elements using element-centric mapping   
	Set @sSQLString = 
		"Select @pnExchScheduleID	=	ExchScheduleID,"+CHAR(10)+	
		"		@psCurrencyCode		=	CurrencyCode,"+CHAR(10)+	
		"		@psCaseType			=	CaseTypeCode,"+CHAR(10)+	
		"		@psCaseCategory		=	CaseCategoryCode,"+CHAR(10)+	
		"		@psPropertyType		=	PropertyTypeCode,"+CHAR(10)+
		"		@psCountryCode		=	CountryCode,"+CHAR(10)+	
		"		@psSubType			=	SubTypeCode,"+CHAR(10)+	
		"		@pbExactMatch		=	IsExactMatch"+CHAR(10)+
		"from OPENXML(@idoc, '/acw_ListExchangeRateVariation/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	ExchScheduleID			int				'ExchScheduleID/text()',"+CHAR(10)+
		"	CurrencyCode			nvarchar(3)		'CurrencyCode/text()',"+CHAR(10)+
		"	CaseTypeCode			nvarchar(1)		'CaseTypeCode/text()',"+CHAR(10)+
		"	CaseCategoryCode		nvarchar(2)		'CaseCategoryCode/text()',"+CHAR(10)+
		"	PropertyTypeCode		nvarchar(1)		'PropertyTypeCode/text()',"+CHAR(10)+
		"	CountryCode				nvarchar(3)		'CountryCode/text()',"+CHAR(10)+
		"	SubTypeCode				nvarchar(2)		'SubTypeCode/text()',"+CHAR(10)+
		"	IsExactMatch			bit				'IsExactMatch/text()'"+CHAR(10)+
		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
			 N' @idoc					int,
				@pnExchScheduleID		int				output,
				@psCurrencyCode			nvarchar(3)		output,
				@psCaseType				nvarchar(1)		output,
				@psCaseCategory			nvarchar(2)		output,
				@psPropertyType			nvarchar(1)		output,
				@psCountryCode			nvarchar(3)		output,
				@psSubType				nvarchar(2)		output,
				@pbExactMatch			bit				output	',
				@idoc					= @idoc,
				@pnExchScheduleID		=	@pnExchScheduleID		output,
				@psCurrencyCode			=	@psCurrencyCode		output,
				@psCaseType				=	@psCaseType			output,
				@psCaseCategory			=	@psCaseCategory		output,
				@psPropertyType			=	@psPropertyType	output,
				@psCountryCode			=	@psCountryCode		output,
				@psSubType				=	@psSubType	output,
				@pbExactMatch			=	@pbExactMatch			output

        -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
print @pbExactMatch
	If @nErrorCode = 0 and @pbExactMatch = 1
	Begin	
		Set @sWhere=@sWhere+char(10)+"and (E.EXCHSCHEDULEID = @pnExchScheduleID or @pnExchScheduleID is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CURRENCYCODE = @psCurrencyCode or @psCurrencyCode is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CASETYPE = @psCaseType or @psCaseType is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CASECATEGORY = @psCaseCategory or @psCaseCategory is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.PROPERTYTYPE = @psPropertyType or @psPropertyType is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.COUNTRYCODE = @psCountryCode or @psCountryCode is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CASESUBTYPE = @psSubType or @psSubType is null)"	
	End 
	Else if @nErrorCode = 0
	Begin
		Set @sWhere=@sWhere+char(10)+"and (E.EXCHSCHEDULEID = @pnExchScheduleID or E.EXCHSCHEDULEID is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CURRENCYCODE = @psCurrencyCode or E.CURRENCYCODE is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CASETYPE =  @psCaseType or E.CASETYPE is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CASECATEGORY = @psCaseCategory  or E.CASECATEGORY is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.PROPERTYTYPE = @psPropertyType or E.PROPERTYTYPE is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.COUNTRYCODE = @psCountryCode  or E.COUNTRYCODE is null)"
		Set @sWhere=@sWhere+char(10)+"and (E.CASESUBTYPE = @psSubType or E.CASESUBTYPE  is null)"		
	End
End

If @nErrorCode=0
Begin  
	
	-- Now execute the constructed SQL to return the result set
	Set @sSQLString = @sSelect + @sFrom + @sWhere + @sOrder
	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnExchScheduleID	int,
					  @psCurrencyCode	nvarchar(3),
					  @psCaseType	nvarchar(1),
					  @psCaseCategory	nvarchar(2),
					  @psPropertyType	nvarchar(1),
					  @psCountryCode	nvarchar(3),
					  @psSubType		nvarchar(2)',
					  @pnExchScheduleID	= @pnExchScheduleID,
					  @psCurrencyCode	=@psCurrencyCode,
					  @psCaseType	= @psCaseType,
					  @psCaseCategory	=@psCaseCategory,
					  @psPropertyType	= @psPropertyType,
					  @psCountryCode = @psCountryCode,
					  @psSubType	=@psSubType
						
	Select 	 @pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
go

Grant exec on dbo.acw_ListExchangeRateVariation to Public
go