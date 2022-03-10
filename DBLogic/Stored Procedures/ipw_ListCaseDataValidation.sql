-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCaseDataValidation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCaseDataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCaseDataValidation.'
	Drop procedure [dbo].[ipw_ListCaseDataValidation]
	Print '**** Creating Stored Procedure dbo.ipw_ListCaseDataValidation...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [dbo].[ipw_ListCaseDataValidation]
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 840, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	[ipw_ListCaseDataValidation]
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the Case Data Validation records on the basis of Filter Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Sep 2010	DV	RFC9387	1	Procedure created
-- 17 May 2011  DV	R10157	2       Add conditions to filter rules on the basis of NOT flag 
-- 12 Jul 2011	DL	SQA19795 3	Specify collate database default for temp table.
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).
-- 24 Oct 2017	AK	R72645	5	Make compatible with case sensitive server with case insensitive database.
-- 07 Sep 2018	AV	74738	6	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode			int

Declare @sSQLString			nvarchar(max)

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
declare @psCurrencyCode		nvarchar(3)
declare	@psCaseType		nchar(1)
declare	@psCaseCategory		nvarchar(2)
declare	@psPropertyType		nchar(1)
declare	@psSubType		nvarchar(2)
declare	@psBasis		nvarchar(2)
declare	@pnStatus		smallint
declare	@pnEventDateFlag	smallint
declare	@pnEventNo		int
declare	@pbInUseFlag		bit
declare	@pbDeferredFlag		bit
declare	@pnColumnName		int
declare	@pnOfficeID		int
declare	@pbLocalClientFlag	bit
declare	@pnFamilyNo		smallint
declare	@pnNameNo		int
declare	@psNameType		nvarchar(3)
declare	@psInstructionType	nvarchar(3)
declare	@pnFlagNo		smallint
declare @psCountryCode		nvarchar(3)
declare	@pbWarningFlag		bit
declare	@pnRoleID		int
declare	@pnItemID		int
declare	@psDisplayMessage	nvarchar(max)
declare	@psNotes		nvarchar(max)
declare	@psRuleDescription      nvarchar(254)
declare @pbNotCaseType          bit
declare @pbNotPropertyType      bit
declare @pbNotCountryCode       bit
declare @pbNotCaseCategory      bit
declare @pbNotBasis             bit
declare @pbNotSubType           bit

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(max)
Declare @sFrom					nvarchar(max)
Declare @sWhere					nvarchar(max)
Declare @sOrder					nvarchar(max)

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
Set	@CommaString			        ='CS'

-- Initialise variables
Set 	@nErrorCode = 0
Set     @nCount					= 1
set 	@sSelect				='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom					= char(10)+" from DATAVALIDATION D"
set 	@sWhere 				= char(10)+"	WHERE D.FUNCTIONALAREA = 'C'"


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
	-- Default @pnQueryContextKey to 840.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 840)

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
		If @sColumn='DataValidationKey'
		Begin
			Set @sTableColumn='D.VALIDATIONID'
		End
		
		Else If @sColumn='CaseType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join CASETYPE CT on (CT.CASETYPE=D.CASETYPE)'
		End
		 
		Else If @sColumn = 'PropertyType'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=D.PROPERTYTYPE'
					+CHAR(10)+'and VP.COUNTRYCODE =(select min(VP1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDPROPERTY VP1'
					+CHAR(10)+'where VP1.COUNTRYCODE in ("ZZZ",D.COUNTRYCODE)))'   
					+CHAR(10)+'left join PROPERTYTYPE P	on (P.PROPERTYTYPE=D.PROPERTYTYPE)'
		End

		Else If @sColumn = 'Country'
		Begin
			Set @sTableColumn='C.COUNTRY'
			Set @sFrom = @sFrom +CHAR(10)+'left join COUNTRY C on (C.COUNTRYCODE=D.COUNTRYCODE)'
		End

		Else If @sColumn = 'Category'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=D.PROPERTYTYPE'
					+CHAR(10)+'and VC.CASETYPE = D.CASETYPE'
					+CHAR(10)+'and VC.CASECATEGORY = D.CASECATEGORY'
					+CHAR(10)+'and VC.COUNTRYCODE =( select min(VC1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDCATEGORY VC1'
					+CHAR(10)+'where VC1.CASETYPE = D.CASETYPE'
					+CHAR(10)+'and VC1.PROPERTYTYPE = D.PROPERTYTYPE'
					+CHAR(10)+'and VC1.COUNTRYCODE in ("ZZZ",D.COUNTRYCODE)))'
					+CHAR(10)+'left join CASECATEGORY CC on (CC.CASETYPE=D.CASETYPE'
					+CHAR(10)+'and CC.CASECATEGORY = D.CASECATEGORY)'
		End

		Else If @sColumn = 'Basis'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','BASISDESCRIPTION',null,'VB',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDBASIS VB		on (VB.PROPERTYTYPE=D.PROPERTYTYPE'
					+CHAR(10)+'and VB.BASIS=D.BASIS'
					+CHAR(10)+'and VB.COUNTRYCODE =(	select min(VB1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDBASIS VB1'
					+CHAR(10)+'where VB1.PROPERTYTYPE=D.PROPERTYTYPE'
					+CHAR(10)+'and VB1.COUNTRYCODE in (D.COUNTRYCODE,"ZZZ")))'
					+CHAR(10)+'left join APPLICATIONBASIS B	on (B.BASIS=D.BASIS)'
		End

		Else If @sColumn = 'SubType'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDBASIS','SUBTYPEDESC',null,'VS',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE=D.PROPERTYTYPE'
					+CHAR(10)+'and VS.CASETYPE = D.CASETYPE'
					+CHAR(10)+'and VS.CASECATEGORY = D.CASECATEGORY'
					+CHAR(10)+'and VS.SUBTYPE = D.SUBTYPE'
					+CHAR(10)+'and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDSUBTYPE VS1'
					+CHAR(10)+'where VS1.CASETYPE = D.CASETYPE'
					+CHAR(10)+'and VS1.PROPERTYTYPE = D.PROPERTYTYPE'
					+CHAR(10)+'and VS1.CASECATEGORY = D.CASECATEGORY'
					+CHAR(10)+'and VS1.COUNTRYCODE in ("ZZZ",D.COUNTRYCODE)))'
	                +CHAR(10)+'left join SUBTYPE S on (S.SUBTYPE=D.SUBTYPE)'
		End
								
		If @sColumn='Pending'
		Begin
			Set @sTableColumn='CASE WHEN D.STATUSFLAG&1 = 1 THEN cast(1 as bit) ELSE cast(0 as bit) END'								
		End
		
		If @sColumn='Registered'
		Begin
			Set @sTableColumn='CASE WHEN D.STATUSFLAG&2 = 2 THEN cast(1 as bit) ELSE cast(0 as bit) END'								
		End
		
		If @sColumn='Dead'
		Begin
			Set @sTableColumn='CASE WHEN D.STATUSFLAG = 0 THEN cast(1 as bit)'								
								+CHAR(10)+'ELSE cast(0 as bit) END'
		End
		If @sColumn='Event'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'EV',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join EVENTS EV on (EV.EVENTNO=D.EVENTNO)'
		End

		If @sColumn='EventDue'
		Begin
			Set @sTableColumn='CASE D.EVENTDATEFLAG'
								+CHAR(10)+'WHEN 1	THEN "Occurred On"'
								+CHAR(10)+'WHEN 2	THEN "Due On"'
								+CHAR(10)+'WHEN 3	THEN "Occurred and Due On"  END'
		End
		
		If @sColumn='TableColumn'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join TABLECODES TC on (TC.TABLECODE=D.COLUMNNAME)'
		End

		If @sColumn='CaseOffice'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'OC',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join OFFICE OC on (OC.OFFICEID=D.OFFICEID)'
		End
		If @sColumn='InUse'
		Begin
			Set @sTableColumn='D.INUSEFLAG'
		End

		If @sColumn='Deferred'
		Begin
			Set @sTableColumn='D.DEFERREDFLAG'
		End

		If @sColumn='NameGroup'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'NF',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join NAMEFAMILY NF on (NF.FAMILYNO=D.FAMILYNO)'
		End

		If @sColumn='Name'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)'
			Set @sFrom = @sFrom +CHAR(10)+'left join NAME N on (N.NAMENO=D.NAMENO)'
		End

		If @sColumn='NameType'
		Begin
			Set @sTableColumn='NT.DESCRIPTION'
			Set @sFrom = @sFrom +CHAR(10)+'left join NAMETYPE NT on (NT.NAMETYPE=D.NAMETYPE)'
		End

		If @sColumn='LocalClient'
		Begin
			Set @sTableColumn='D.LOCALCLIENTFLAG'
		End

		If @sColumn='InstructionType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('INSTRUCTIONTYPE','INSTRTYPEDESC',null,'IT',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join INSTRUCTIONTYPE IT on (IT.INSTRUCTIONTYPE=D.INSTRUCTIONTYPE)'
		End

		If @sColumn='RequiredFlag'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('INSTRUCTIONLABEL','FLAGLITERAL',null,'IL',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join INSTRUCTIONLABEL IL on (IL.FLAGNUMBER=D.FLAGNUMBER)'
		End

		If @sColumn='DisplayMessage'
		Begin
			Set @sTableColumn='D.DISPLAYMESSAGE'
		End
		
		If @sColumn='Informational'
		Begin
			Set @sTableColumn='D.WARNINGFLAG'
		End		

		If @sColumn='RoleID'
		Begin
			Set @sTableColumn='D.ROLEID'
		End

		If @sColumn='ValidationSQL'
		Begin			
			Set @sTableColumn='D.ITEM_ID'
		End

		If @sColumn='Notes'
		Begin			
			Set @sTableColumn='D.NOTES'
		End

		If @sColumn='RuleDescription'
		Begin			
			Set @sTableColumn='D.RULEDESCRIPTION'
		End
		
		If @sColumn='LastUpdatedDate'
		Begin			
			Set @sTableColumn='D.LOGDATETIMESTAMP'
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
		"Select @psCaseType			=	CaseTypeCode,"+CHAR(10)+	
		"		@psCaseCategory		=	CaseCategoryCode,"+CHAR(10)+	
		"		@psPropertyType		=	PropertyTypeCode,"+CHAR(10)+
		"		@psCountryCode		=	CountryCode,"+CHAR(10)+	
		"		@psSubType		=	SubTypeCode,"+CHAR(10)+	
		"		@psBasis		=	BasisCode,"+CHAR(10)+
		"		@pnStatus		=	StatusCode,"+CHAR(10)+
		"		@pnEventDateFlag	=	EventStatusCode,"+CHAR(10)+
		"		@pnEventNo		=	EventCode,"+CHAR(10)+
		"		@pbInUseFlag		=	InUse,"+CHAR(10)+
		"		@pbDeferredFlag		=	Deferred,"+CHAR(10)+
		"		@pnColumnName		=	TableColumnCode,"+CHAR(10)+
		"		@pnOfficeID		=	CaseOfficeCode,"+CHAR(10)+
		"		@pbLocalClientFlag	=	LocalClientCode,"+CHAR(10)+
		"		@pnFamilyNo		=	NameGroupCode,"+CHAR(10)+
		"		@pnNameNo		=	NameCode,"+CHAR(10)+
		"		@psNameType		=	NameTypeCode,"+CHAR(10)+
		"		@psInstructionType	=	InstructionTypeCode,"+CHAR(10)+
		"		@pnFlagNo		=	StandingInstructionCode,"+CHAR(10)+
		"		@pbWarningFlag		=	Warning,"+CHAR(10)+
		"		@pnRoleID		=	RoleCode,"+CHAR(10)+
		"		@pnItemID		=	ItemCode,"+CHAR(10)+
		"		@psDisplayMessage	=	Message,"+CHAR(10)+
		"		@psNotes		=	Notes,"+CHAR(10)+
		"		@psRuleDescription	=	RuleDescription,"+CHAR(10)+
		"		@pbNotCaseType  	=	NotCaseType,"+CHAR(10)+
		"		@pbNotPropertyType	=	NotPropertyType,"+CHAR(10)+
		"		@pbNotCountryCode	=	NotCountryCode,"+CHAR(10)+
		"		@pbNotCaseCategory	=	NotCaseCategory,"+CHAR(10)+
		"		@pbNotBasis     	=	NotBasis,"+CHAR(10)+
		"		@pbNotSubType   	=	NotSubType"+CHAR(10)+					
		"from OPENXML(@idoc, '/ipw_ListCaseDataValidation/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	CaseTypeCode	        nvarchar(1)	'CaseTypeCode/text()',"+CHAR(10)+
		"	CaseCategoryCode	nvarchar(2)	'CaseCategoryCode/text()',"+CHAR(10)+
		"	PropertyTypeCode	nvarchar(1)	'PropertyTypeCode/text()',"+CHAR(10)+
		"	CountryCode		nvarchar(3)	'CountryCode/text()',"+CHAR(10)+
		"	SubTypeCode		nvarchar(2)	'SubTypeCode/text()',"+CHAR(10)+
		"	BasisCode		nvarchar(2)	'BasisCode/text()',"+CHAR(10)+
		"	StatusCode		smallint	'StatusCode/text()',"+CHAR(10)+
		"	EventStatusCode		smallint	'EventStatusCode/text()',"+CHAR(10)+
		"       EventCode		int		'EventCode/text()',"+CHAR(10)+
		"	InUse			bit		'InUse/text()',"+CHAR(10)+
		"	Deferred		bit		'Deferred/text()',"+CHAR(10)+
		"	TableColumnCode		int		'TableColumnCode/text()',"+CHAR(10)+
		"	CaseOfficeCode		int		'CaseOfficeCode/text()',"+CHAR(10)+
		"	LocalClientCode		bit		'LocalClientCode/text()',"+CHAR(10)+
		"	NameGroupCode		smallint	'NameGroupCode/text()',"+CHAR(10)+
		"	NameCode		int		'NameCode/text()',"+CHAR(10)+
		"	NameTypeCode		nvarchar(3)	'NameTypeCode/text()',"+CHAR(10)+
		"	InstructionTypeCode	nvarchar(3)	'InstructionTypeCode/text()',"+CHAR(10)+ 
		"	StandingInstructionCode	smallint	'StandingInstructionCode/text()',"+CHAR(10)+
		"	Warning			bit		'Warning/text()',"+CHAR(10)+
		"	RoleCode		int		'RoleCode/text()',"+CHAR(10)+
		"       ItemCode		int		'ItemCode/text()',"+CHAR(10)+
		"	Message			nvarchar(max)	'Message/text()',"+CHAR(10)+
		"	Notes			nvarchar(max)	'Notes/text()',"+CHAR(10)+
		"	RuleDescription		nvarchar(254)	'RuleDescription/text()',"+CHAR(10)+
		"	NotCaseType		bit     	'NotCaseType/text()',"+CHAR(10)+
		"	NotPropertyType		bit     	'NotPropertyType/text()',"+CHAR(10)+
		"	NotCountryCode		bit     	'NotCountryCode/text()',"+CHAR(10)+
		"	NotCaseCategory		bit     	'NotCaseCategory/text()',"+CHAR(10)+
		"	NotBasis		bit     	'NotBasis/text()',"+CHAR(10)+
		"	NotSubType		bit     	'NotSubType/text()'"+CHAR(10)+
		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
			 N' @idoc				int,
				@psCaseType			nvarchar(1)	output,
				@psCaseCategory			nvarchar(2)	output,
				@psPropertyType			nvarchar(1)	output,
				@psCountryCode			nvarchar(3)	output,
				@psSubType			nvarchar(2)	output,
				@psBasis     			nvarchar(2)	output,	
				@pnStatus     			smallint	output,
				@pnEventDateFlag		smallint	output,
				@pnEventNo			int		output,
				@pbInUseFlag			bit		output,
				@pbDeferredFlag			bit		output,
				@pnColumnName			int		output,
				@pnOfficeID			int		output,
				@pbLocalClientFlag		bit		output,
				@pnFamilyNo			smallint	output,
				@pnNameNo			int		output,
				@psNameType			nvarchar(3)	output,
				@psInstructionType		nvarchar(3)	output,
				@pnFlagNo			smallint	output,
				@pbWarningFlag			bit		output,
				@pnRoleID			int		output,
				@pnItemID			int		output,
				@psDisplayMessage		nvarchar(max)	output,
				@psNotes			nvarchar(max)	output,
				@psRuleDescription		nvarchar(254)   output,
				@pbNotCaseType                  bit             output,
				@pbNotPropertyType              bit             output,
				@pbNotCountryCode               bit             output,
				@pbNotCaseCategory              bit             output,
				@pbNotBasis                     bit             output,
				@pbNotSubType                   bit             output',
				@idoc				= @idoc,
				@psCaseType			= @psCaseType		output,
				@psCaseCategory			= @psCaseCategory	output,
				@psPropertyType			= @psPropertyType	output,
				@psCountryCode			= @psCountryCode	output,
				@psSubType			= @psSubType	        output,
				@psBasis			= @psBasis		output,
				@pnStatus			= @pnStatus             output,
				@pnEventDateFlag		= @pnEventDateFlag	output,
				@pnEventNo			= @pnEventNo	        output,
				@pbInUseFlag			= @pbInUseFlag	        output,
				@pbDeferredFlag			= @pbDeferredFlag	output,
				@pnColumnName			= @pnColumnName	        output,
				@pnOfficeID			= @pnOfficeID	        output,
				@pbLocalClientFlag		= @pbLocalClientFlag	output,
				@pnFamilyNo			= @pnFamilyNo	        output,
				@pnNameNo			= @pnNameNo	        output,
				@psNameType			= @psNameType	        output,
				@psInstructionType		= @psInstructionType	output,
				@pnFlagNo			= @pnFlagNo	        output,
				@pbWarningFlag			= @pbWarningFlag	output,
				@pnRoleID			= @pnRoleID	        output,
				@pnItemID			= @pnItemID		output,
			        @psDisplayMessage		= @psDisplayMessage	output,
				@psNotes			= @psNotes	        output,
				@psRuleDescription		= @psRuleDescription	output,
				@pbNotCaseType 		        = @pbNotCaseType 	output,
				@pbNotPropertyType		= @pbNotPropertyType	output,
				@pbNotCountryCode		= @pbNotCountryCode	output,
				@pbNotCaseCategory		= @pbNotCaseCategory	output,
				@pbNotBasis  		        = @pbNotBasis  	        output,				
				@pbNotSubType		        = @pbNotSubType	        output

        -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0 
	Begin	
		Set @sWhere=@sWhere+char(10)+"and (D.CASETYPE = @psCaseType or @psCaseType is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.CASECATEGORY = @psCaseCategory or @psCaseCategory is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.PROPERTYTYPE = @psPropertyType or @psPropertyType is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.COUNTRYCODE = @psCountryCode or @psCountryCode is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.SUBTYPE = @psSubType or @psSubType is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.BASIS = @psBasis or @psBasis is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.STATUSFLAG = @pnStatus or @pnStatus is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.EVENTDATEFLAG = @pnEventDateFlag or @pnEventDateFlag is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.EVENTNO = @pnEventNo or @pnEventNo is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.INUSEFLAG = @pbInUseFlag or @pbInUseFlag is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.DEFERREDFLAG = @pbDeferredFlag or @pbDeferredFlag is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.COLUMNNAME = @pnColumnName or @pnColumnName is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.OFFICEID = @pnOfficeID or @pnOfficeID is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.LOCALCLIENTFLAG = @pbLocalClientFlag or @pbLocalClientFlag is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.FAMILYNO = @pnFamilyNo or @pnFamilyNo is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.NAMENO = @pnNameNo or @pnNameNo is null)"		
		Set @sWhere=@sWhere+char(10)+"and (D.NAMETYPE = @psNameType or @psNameType is null)"
		Set @sWhere=@sWhere+char(10)+"and (D.INSTRUCTIONTYPE = @psInstructionType or @psInstructionType is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.FLAGNUMBER = @pnFlagNo or @pnFlagNo is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.WARNINGFLAG = @pbWarningFlag or @pbWarningFlag is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.ROLEID = @pnRoleID or @pnRoleID is null)"	
		Set @sWhere=@sWhere+char(10)+"and (D.ITEM_ID = @pnItemID or @pnItemID is null)"	
		If  @psCaseType is not null 
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and (D.NOTCASETYPE = @pbNotCaseType or (@pbNotCaseType = 0 and D.NOTCASETYPE is null))"	
		END
		If  @psCaseCategory is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and (D.NOTCASECATEGORY = @pbNotCaseCategory or (@pbNotCaseCategory = 0 and D.NOTCASECATEGORY is null))"	
		END
		If  @psPropertyType is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and (D.NOTPROPERTYTYPE = @pbNotPropertyType or (@pbNotPropertyType = 0 and D.NOTPROPERTYTYPE is null))"	
		END
		If  @psCountryCode is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and (D.NOTCOUNTRYCODE = @pbNotCountryCode or (@pbNotCountryCode = 0 and D.NOTCOUNTRYCODE is null))"	
		END
		If  @psBasis is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and (D.NOTBASIS = @pbNotBasis or (@pbNotBasis = 0 and D.NOTBASIS is null))"	
		END
		If  @psSubType is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and (D.NOTSUBTYPE = @pbNotSubType or (@pbNotSubType = 0 and D.NOTSUBTYPE is null))"	
		END
		If @psDisplayMessage is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','DISPLAYMESSAGE',null,'D',@sLookupCulture,@pbCalledFromCentura)+") like "+ dbo.fn_WrapQuotes(@psDisplayMessage  + '%',0,0)
		END	
		If @psNotes is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','NOTES',null,'D',@sLookupCulture,@pbCalledFromCentura)+") like "+ dbo.fn_WrapQuotes(@psNotes + '%',0,0)
		END			
		If @psRuleDescription is not null
		BEGIN
		  Set @sWhere=@sWhere+char(10)+"and upper("+dbo.fn_SqlTranslatedColumn('DATAVALIDATION','RULEDESCRIPTION',null,'D',@sLookupCulture,@pbCalledFromCentura)+") like "+ dbo.fn_WrapQuotes(@psRuleDescription + '%',0,0)
		END
	End 
	
End

If @nErrorCode=0
Begin  
	
	-- Now execute the constructed SQL to return the result set
	Set @sSQLString = @sSelect + @sFrom + @sWhere + @sOrder
	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@psCaseType			nvarchar(1),
					  @psCaseCategory		nvarchar(2),
					  @psPropertyType		nvarchar(1),
					  @psCountryCode		nvarchar(3),
					  @psSubType			nvarchar(2),
					  @psBasis			nvarchar(2),
					  @pnStatus     		smallint,
					  @pnEventDateFlag		smallint,
					  @pnEventNo			int,
					  @pbInUseFlag			bit,
					  @pbDeferredFlag		bit,
					  @pnColumnName			int,
					  @pnOfficeID			int,
					  @pbLocalClientFlag	        bit,
					  @pnFamilyNo			smallint,
					  @pnNameNo			int,
					  @psNameType			nvarchar(3),
					  @psInstructionType	        nvarchar(3),
					  @pnFlagNo			smallint,
					  @pbWarningFlag                bit,
					  @pnRoleID			int,
				          @pnItemID			int,
				          @psDisplayMessage		nvarchar(max),
				          @psNotes			nvarchar(max),
				          @psRuleDescription		nvarchar(254),
				          @pbNotCaseType                bit,
				          @pbNotPropertyType            bit,
				          @pbNotCountryCode             bit,
				          @pbNotCaseCategory            bit,
				          @pbNotBasis                   bit,
				          @pbNotSubType                 bit',					  
					  @psCaseType	        = @psCaseType,
					  @psCaseCategory	= @psCaseCategory,
					  @psPropertyType	= @psPropertyType,
					  @psCountryCode        = @psCountryCode,
					  @psSubType	        = @psSubType,
					  @psBasis              = @psBasis,
					  @pnStatus		= @pnStatus,
					  @pnEventDateFlag      = @pnEventDateFlag,
					  @pnEventNo		= @pnEventNo,
					  @pbInUseFlag	        = @pbInUseFlag,
				          @pbDeferredFlag	= @pbDeferredFlag,
				          @pnColumnName		= @pnColumnName,
					  @pnOfficeID		= @pnOfficeID,
					  @pbLocalClientFlag    = @pbLocalClientFlag,
					  @pnFamilyNo		= @pnFamilyNo,
					  @pnNameNo		= @pnNameNo,
					  @psNameType		= @psNameType,
					  @psInstructionType    = @psInstructionType,
					  @pnFlagNo		= @pnFlagNo,
					  @pbWarningFlag        = @pbWarningFlag,
					  @pnRoleID		= @pnRoleID,
				          @pnItemID		= @pnItemID,
				          @psDisplayMessage	= @psDisplayMessage,
				          @psNotes		= @psNotes,
				          @psRuleDescription	= @psRuleDescription,
				          @pbNotCaseType        = @pbNotCaseType,
				          @pbNotPropertyType    = @pbNotPropertyType,
				          @pbNotCountryCode     = @pbNotCountryCode,
				          @pbNotCaseCategory    = @pbNotCaseCategory,
				          @pbNotBasis           = @pbNotBasis,
				          @pbNotSubType         = @pbNotSubType
						
	Select 	 @pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
go

Grant exec on dbo.ipw_ListCaseDataValidation to Public
go