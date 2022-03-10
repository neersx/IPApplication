-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameDataValidation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameDataValidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameDataValidation.'
	Drop procedure [dbo].[naw_ListNameDataValidation]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameDataValidation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameDataValidation
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 940, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	naw_ListNameDataValidation
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert DocumentRequest.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 06 Jun 2012  ASH	RFC9757	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).
-- 24 Oct 2017	AK	R72645	5	Make compatible with case sensitive server with case insensitive database.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

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
declare	@psNameCategory		int
declare	@pnUsedAs		smallint
declare	@pbInUseFlag		bit
declare	@pbDeferredFlag		bit
declare	@pnColumnName		int
declare	@pbLocalClientFlag	bit
declare	@pnFamilyNo		smallint
declare	@pnNameNo		int
declare	@psInstructionType	nvarchar(3)
declare	@pnFlagNo		smallint
declare @psCountryCode		nvarchar(3)
declare	@pbWarningFlag		bit
declare	@pnRoleID		int
declare	@pnItemID		int
declare	@psDisplayMessage	nvarchar(max)
declare	@psNotes		nvarchar(max)
declare	@psRuleDescription      nvarchar(254)

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
set 	@sWhere 				= char(10)+"	WHERE D.FUNCTIONALAREA = 'N'"


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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 940)

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
		Else If @sColumn = 'Country'
		Begin
			Set @sTableColumn='C.COUNTRY'
			Set @sFrom = @sFrom +CHAR(10)+'left join COUNTRY C on (C.COUNTRYCODE=D.COUNTRYCODE)'
		End
		
		Else If @sColumn = 'Category'
		Begin
		Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join TABLECODES TCC on (TCC.TABLECODE=D.CATEGORY)'
		End

		Else if @sColumn = 'Organisation'
		Begin
			Set @sTableColumn='CASE when D.USEDASFLAG is not null then ~cast((D.USEDASFLAG & 1) as bit) else cast(0 as bit) end'
		End
		
		Else if @sColumn = 'Individual'
		Begin
			Set @sTableColumn='cast((isnull(D.USEDASFLAG, 0) & 1) as bit)'
		End

		Else if @sColumn = 'Staff'
		Begin
			Set @sTableColumn='cast((isnull(D.USEDASFLAG, 0) & 2) as bit)'
		End

		Else if @sColumn = 'Client'
		Begin
			Set @sTableColumn='cast((isnull(D.USEDASFLAG, 0) & 4) as bit)'
		End

		Else if @sColumn = 'Supplier'
		Begin
			Set @sTableColumn='Cast(D.SUPPLIERFLAG as bit)'
		End
		
		If @sColumn='TableColumn'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join TABLECODES TC on (TC.TABLECODE=D.COLUMNNAME)'
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

		If @sColumn='LocalClient'
		Begin
			Set @sTableColumn='Cast(isnull(D.LOCALCLIENTFLAG,0) as bit)'
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
	
	--select FROM OPENXML(@idoc, '/ipw_GetNameDataValidation/FilterCriteria',2)
	
	-- 1) Retrieve the FilterCriteria elements using element-centric mapping   
	Set @sSQLString = 
		"Select @psNameCategory			=	NameCategoryCode,"+CHAR(10)+		
		"		@psCountryCode		=	CountryCode,"+CHAR(10)+	
		"		@pbInUseFlag		=	InUse,"+CHAR(10)+
		"		@pbDeferredFlag		=	Deferred,"+CHAR(10)+
		"		@pnColumnName		=	TableColumnCode,"+CHAR(10)+
		"		@pbLocalClientFlag	=	LocalClientCode,"+CHAR(10)+
		"		@pnFamilyNo		=	NameGroupCode,"+CHAR(10)+
		"		@pnNameNo		=	NameCode,"+CHAR(10)+
		"       @pnUsedAs       =   UsedAsCode,"+CHAR(10)+
		"		@psInstructionType	= InstructionTypeCode,"+CHAR(10)+
		"		@pnFlagNo		=	StandingInstructionCode,"+CHAR(10)+
		"		@pbWarningFlag		=	Warning,"+CHAR(10)+
		"		@pnRoleID		=	RoleCode,"+CHAR(10)+
		"		@pnItemID		=	ItemCode,"+CHAR(10)+
		"		@psDisplayMessage	=	Message,"+CHAR(10)+
		"		@psNotes		=	Notes,"+CHAR(10)+
		"		@psRuleDescription	=	RuleDescription"+CHAR(10)+					
		"from OPENXML(@idoc, '/naw_ListNameDataValidation/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	NameCategoryCode	int	'NameCategoryCode/text()',"+CHAR(10)+
		"	CountryCode		nvarchar(3)	'CountryCode/text()',"+CHAR(10)+
		"	InUse			bit		'InUse/text()',"+CHAR(10)+
		"	Deferred		bit		'Deferred/text()',"+CHAR(10)+
		"	TableColumnCode		int		'TableColumnCode/text()',"+CHAR(10)+
		"	LocalClientCode		bit		'LocalClientCode/text()',"+CHAR(10)+
		"	NameGroupCode		smallint	'NameGroupCode/text()',"+CHAR(10)+
		"	NameCode		int		'NameCode/text()',"+CHAR(10)+
		"	UsedAsCode		smallint		'UsedAsCode/text()',"+CHAR(10)+
		"	InstructionTypeCode	nvarchar(3)	'InstructionTypeCode/text()',"+CHAR(10)+ 
		"	StandingInstructionCode	smallint	'StandingInstructionCode/text()',"+CHAR(10)+
		"	Warning			bit		'Warning/text()',"+CHAR(10)+
		"	RoleCode		int		'RoleCode/text()',"+CHAR(10)+
		"   ItemCode		int		'ItemCode/text()',"+CHAR(10)+
		"	Message			nvarchar(max)	'Message/text()',"+CHAR(10)+
		"	Notes			nvarchar(max)	'Notes/text()',"+CHAR(10)+
		"	RuleDescription		nvarchar(254)	'RuleDescription/text()'"+CHAR(10)+
		"	     )"
print @sSQLString
		exec @nErrorCode = sp_executesql @sSQLString,
			 N' @idoc				int,
				@psNameCategory			int	output,
				@psCountryCode			nvarchar(3)	output,	
				@pnUsedAs     			smallint	output,
				@pbInUseFlag			bit		output,
				@pbDeferredFlag			bit		output,
				@pnColumnName			int		output,
				@pbLocalClientFlag		bit		output,
				@pnFamilyNo			smallint	output,
				@pnNameNo			int		output,
				@psInstructionType		nvarchar(3)	output,
				@pnFlagNo			smallint	output,
				@pbWarningFlag			bit		output,
				@pnRoleID			int		output,
				@pnItemID			int		output,
				@psDisplayMessage		nvarchar(max)	output,
				@psNotes			nvarchar(max)	output,
				@psRuleDescription		nvarchar(254)   output',
				@idoc				= @idoc,
				@psNameCategory			= @psNameCategory	output,
				@psCountryCode			= @psCountryCode	output,
				@pnUsedAs			= @pnUsedAs             output,
				@pbInUseFlag			= @pbInUseFlag	        output,
				@pbDeferredFlag			= @pbDeferredFlag	output,
				@pnColumnName			= @pnColumnName	        output,
				@pbLocalClientFlag		= @pbLocalClientFlag	output,
				@pnFamilyNo			= @pnFamilyNo	        output,
				@pnNameNo			= @pnNameNo	        output,
				@psInstructionType		= @psInstructionType	output,
				@pnFlagNo			= @pnFlagNo	        output,
				@pbWarningFlag			= @pbWarningFlag	output,
				@pnRoleID			= @pnRoleID	        output,
				@pnItemID			= @pnItemID		output,
			    @psDisplayMessage		= @psDisplayMessage	output,
				@psNotes			= @psNotes	        output,
				@psRuleDescription		= @psRuleDescription	output
print @pnNameNo
        -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	If @nErrorCode = 0 
	Begin	
		If @psNameCategory is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.CATEGORY = @psNameCategory)"
		End
	   If @psCountryCode is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.COUNTRYCODE = @psCountryCode)"
		End
		If @pnUsedAs is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.USEDASFLAG = @pnUsedAs)"	
		End
		If @pbInUseFlag is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.INUSEFLAG = @pbInUseFlag)"		
		End
		If @pbDeferredFlag is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.DEFERREDFLAG = @pbDeferredFlag)"		
		End
		If @pnColumnName is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.COLUMNNAME = @pnColumnName)"		
		End
		If @pbLocalClientFlag is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.LOCALCLIENTFLAG = @pbLocalClientFlag )"		
		End
		If @pnFamilyNo is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.FAMILYNO = @pnFamilyNo )"		
		End
		If @pnNameNo is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.NAMENO = @pnNameNo )"		
		End
		If @psInstructionType is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.INSTRUCTIONTYPE =  @psInstructionType )"		
		End
		If @pnFlagNo is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.FLAGNUMBER =  @pnFlagNo )"		
		End
		If @pbWarningFlag is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.WARNINGFLAG =  @pbWarningFlag )"		
		End
		If @pnRoleID is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.ROLEID =  @pnRoleID )"		
		End
		If @pnItemID is not null
		BEGIN
			Set @sWhere=@sWhere+char(10)+"and (D.ITEM_ID =  @pnItemID )"		
		End
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
					N'@psNameCategory		int,
					  @psCountryCode		nvarchar(3),
					  @pnUsedAs    		smallint,
					  @pbInUseFlag			bit,
					  @pbDeferredFlag		bit,
					  @pnColumnName			int,
					  @pbLocalClientFlag	 bit,
					  @pnFamilyNo			smallint,
					  @pnNameNo			int,
					  @psInstructionType	        nvarchar(3),
					  @pnFlagNo			smallint,
					  @pbWarningFlag                bit,
					  @pnRoleID			int,
				      @pnItemID			int,
				      @psDisplayMessage		nvarchar(max),
				      @psNotes			nvarchar(max),
				      @psRuleDescription		nvarchar(254)',					  
					  @psNameCategory	= @psNameCategory,
					  @psCountryCode        = @psCountryCode,
					  @pnUsedAs		=	@pnUsedAs,
					  @pbInUseFlag	        = @pbInUseFlag,
				      @pbDeferredFlag	= @pbDeferredFlag,
				      @pnColumnName		= @pnColumnName,
					  @pbLocalClientFlag    = @pbLocalClientFlag,
					  @pnFamilyNo		= @pnFamilyNo,
					  @pnNameNo		= @pnNameNo,
					  @psInstructionType    = @psInstructionType,
					  @pnFlagNo		= @pnFlagNo,
					  @pbWarningFlag        = @pbWarningFlag,
					  @pnRoleID		= @pnRoleID,
				      @pnItemID		= @pnItemID,
				      @psDisplayMessage	= @psDisplayMessage,
				      @psNotes		= @psNotes,
				      @psRuleDescription	= @psRuleDescription
						
	Select 	 @pnRowCount=@@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameDataValidation to public
GO