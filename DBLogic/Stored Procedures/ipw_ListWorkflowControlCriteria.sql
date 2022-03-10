-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListWorkflowControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListWorkflowControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListWorkflowControlCriteria.'
	Drop procedure [dbo].[ipw_ListWorkflowControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_ListWorkflowControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListWorkflowControlCriteria
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
-- PROCEDURE:	ipw_ListWorkflowControlCriteria
-- VERSION:	12
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the Events & Entries Criteria records on the basis of Filter Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Aug 2011	SF	R9317	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sSelect		nvarchar(max)
declare @sFrom			nvarchar(max)
Declare @sOrder			nvarchar(max)	-- the SQL sort order
Declare @sLookupCulture		nvarchar(10)
Declare @nCount			int
Declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sQualifier		nvarchar(50)
declare @sCorrelationSuffix	nvarchar(20)
declare @sPublishName		nvarchar(50)
declare @sTableColumn		nvarchar(max)
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument

declare	@pnCaseOfficeID		int
declare	@psCaseType		nchar(1)
declare	@psPropertyType		nchar(1)
declare	@psCountryCode		nvarchar(3)
declare @pnCountryCodeOperator	tinyint
declare	@psCaseCategory		nvarchar(2)
declare @psAction		nvarchar(2)
declare	@psSubType		nvarchar(2)
declare	@psBasis		nvarchar(2)
declare	@pnRuleInUse		decimal(1,0)
declare	@pnLocalClientFlag	decimal(1,0)
declare	@psRegisteredUsers	nchar(2)
declare	@pbExactMatch		bit
declare	@pnUseCaseKey		int
declare	@pnBestCriteriaOnly     decimal(1,0)
declare	@pbHasCRMLicense	bit
declare @nOutRequestsRowCount	int
declare @pnCriteriaNo		int

-- Initialise variables
Set @nErrorCode			= 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nCount = 1
Set @pbHasCRMLicense = dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, 25, getdate())

If (datalength(@ptXMLFilterCriteria) = 0
or datalength(@ptXMLFilterCriteria) is null)
and @nErrorCode = 0
Begin
	Set		@pnCaseOfficeID		=	null	
	Set		@psCaseType		=	null
	Set		@psPropertyType		=	null
	Set		@psCountryCode		=	null
	Set		@pnCountryCodeOperator	=	0
	Set		@psCaseCategory		=	null
	Set		@psAction		=	null
	Set		@psSubType		=	null
	Set		@psBasis		=	null
	Set		@pnRuleInUse		=	null
	Set		@pnLocalClientFlag	=	null
	Set		@psRegisteredUsers	=	null
	Set		@pbExactMatch		=	1
End
Else
-- If there are some @ptXMLFilterCriteria passed then begin:
If @nErrorCode = 0
and datalength(@ptXMLFilterCriteria) > 0 
Begin

	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	-- 1) Retrieve the FilterCriteria elements using element-centric mapping   
	Set @sSQLString = 
		"Select @pnCaseOfficeID		=	CaseOfficeKey,"+CHAR(10)+	
		"	@psCaseType		=	CaseTypeKey,"+CHAR(10)+	
		"	@psCountryCode		=	CountryCode,"+CHAR(10)+	
		"	@pnCountryCodeOperator	=	CountryCodeOperator,"+CHAR(10)+
		"	@psPropertyType		=	PropertyTypeKey,"+CHAR(10)+
		"	@psCaseCategory		=	CaseCategoryKey,"+CHAR(10)+	
		"	@psAction		=	ActionKey,"+CHAR(10)+
		"	@psSubType		=	SubTypeKey,"+CHAR(10)+	
		"	@psBasis		=	ApplicationBasisKey,"+CHAR(10)+	
		"	@pbExactMatch		=	IsExactMatch,"+CHAR(10)+
		"	@pnUseCaseKey		=	UseCaseKey,"+CHAR(10)+
		"	@pnRuleInUse		=	RuleInUse,"+CHAR(10)+
		"	@pnLocalClientFlag	=	LocalClientFlag,"+CHAR(10)+
		"	@psRegisteredUsers	=	RegisteredUsers,"+CHAR(10)+
		"	@pnBestCriteriaOnly	=	BestCriteriaOnly,"+CHAR(10)+
		"	@pnCriteriaNo		=	CriteriaNo"+CHAR(10)+
		"from OPENXML(@idoc, '/ipw_ListWorkflowControlCriteria/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"	CaseOfficeKey		int			'CaseOffice/text()',"+CHAR(10)+
		"	CaseTypeKey		nvarchar(1)		'CaseTypeKey/text()',"+CHAR(10)+
		"	CountryCode		nvarchar(3)		'CountryCode/text()',"+CHAR(10)+
		"	CountryCodeOperator	tinyint			'CountryCode/@Operator/text()',"+CHAR(10)+
		"	PropertyTypeKey		nvarchar(1)		'PropertyTypeKey/text()',"+CHAR(10)+
		"	CaseCategoryKey		nvarchar(2)		'CaseCategoryKey/text()',"+CHAR(10)+
		"	ActionKey		nvarchar(2)		'ActionKey/text()',"+CHAR(10)+
		"	SubTypeKey		nvarchar(2)		'SubTypeKey/text()',"+CHAR(10)+
		"	ApplicationBasisKey	nvarchar(2)		'Basis/text()',"+CHAR(10)+
		"	IsExactMatch		bit			'SearchType/@ExactMatch/text()',"+CHAR(10)+
		"	BestCriteriaOnly	decimal(1,0)		'SearchType/@BestCriteriaOnly/text()',"+CHAR(10)+
		"	RuleInUse		decimal(1,0)		'SearchType/@IsRuleInUse/text()',"+CHAR(10)+
		"	UseCaseKey		int			'SearchType/UseCase/text()',"+CHAR(10)+
		"	LocalClientFlag		decimal(1,0)		'LocalClientFlag/text()',"+CHAR(10)+
		"	RegisteredUsers		nchar(2)		'RegisteredUsers/text()',"+CHAR(10)+
		"	CriteriaNo		int			'CriteriaNo/text()'"+CHAR(10)+
		"	     )"

		exec @nErrorCode = sp_executesql @sSQLString,
			 N' @idoc				int,
				@pnCaseOfficeID			int		output,
				@psCaseType			nvarchar(1)	output,
				@psCountryCode			nvarchar(3)	output,
				@pnCountryCodeOperator		tinyint		output,
				@psPropertyType			nvarchar(1)	output,
				@psCaseCategory			nvarchar(2)	output,
				@psAction			nvarchar(2)	output,
				@psSubType			nvarchar(2)	output,
				@psBasis			nvarchar(2)	output,
				@pbExactMatch			bit		output,
				@pnUseCaseKey			int		output,
				@pnRuleInUse			bit		output,
				@pnLocalClientFlag		decimal(1,0)	output,
				@psRegisteredUsers		nchar(2)	output,
				@pnBestCriteriaOnly		bit		output,
				@pnCriteriaNo			int		output',
				@idoc				= @idoc,
				@pnCaseOfficeID			= @pnCaseOfficeID		output,
				@psCaseType			= @psCaseType			output,
				@psCountryCode			= @psCountryCode		output,
				@pnCountryCodeOperator		= @pnCountryCodeOperator	output,
				@psPropertyType			= @psPropertyType		output,
				@psCaseCategory			= @psCaseCategory		output,
				@psAction			= @psAction			output,
				@psSubType			= @psSubType			output,
				@psBasis			= @psBasis			output,
				@pbExactMatch			= @pbExactMatch			output,
				@pnUseCaseKey			= @pnUseCaseKey			output,
				@pnRuleInUse			= @pnRuleInUse			output,
				@pnLocalClientFlag		= @pnLocalClientFlag		output,
				@psRegisteredUsers		= @psRegisteredUsers		output,
				@pnBestCriteriaOnly		= @pnBestCriteriaOnly		output,
				@pnCriteriaNo			= @pnCriteriaNo			output

        -- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0 
Begin	
	If @pnCriteriaNo is not null
	Begin	
		Set @sFrom = " from CRITERIA T"
	End
	Else 
	Begin
		Set @sFrom = "from dbo.fn_GetCriteriaRows"+char(10)+
                "('E',"+char(10)+
                "@pnCaseOfficeID,"+char(10)+
                "@psCaseType,"+char(10)+
	        "@psAction,"+char(10)+		 -- @psAction
	        "DEFAULT,"+char(10)+		 -- @pnCheckListType
	        "DEFAULT,"+char(10)+		 -- @psProgramID
	        "DEFAULT,"+char(10)+		 -- @pnRateNo
	        "@psPropertyType,"+char(10)+
	        "@psCountryCode,"+char(10)+
	        "@psCaseCategory,"+char(10)+
	        "@psSubType,"+char(10)+
	        "@psBasis,"+char(10)+
	        "@psRegisteredUsers,"+char(10)+	 -- @psRegisteredUsers
	        "DEFAULT,"+char(10)+		 -- @pnTypeOfMark
	        "@pnLocalClientFlag,"+char(10)+	 -- @pnLocalClientFlag
	        "DEFAULT, -- @pnTableCode"+char(10)+		
	        "DEFAULT, -- @pdtDateOfAct"+char(10)+		
	        "@pnRuleInUse,"+char(10)+
	        "DEFAULT,"+char(10)+		-- @pnPropertyUnknown
	        "DEFAULT,"+char(10)+		-- @pnCountryUnknown
	        "DEFAULT,"+char(10)+		-- @pnCategoryUnknown
	        "DEFAULT,"+char(10)+		-- @pnSubTypeUnknown
	        "DEFAULT,"+char(10)+		-- @psNewCaseType
	        "DEFAULT,"+char(10)+		-- @psNewPropertyType
	        "DEFAULT,"+char(10)+		-- @psNewCountryCode
	        "DEFAULT,"+char(10)+		-- @psNewCaseCategory
	        "DEFAULT,"+char(10)+		-- @pnRuleType
	        "DEFAULT,"+char(10)+		-- @psRequestType
	        "DEFAULT,"+char(10)+		-- @pnDataSourceType
	        "DEFAULT,"+char(10)+		-- @pnDataSourceNameNo
	        "DEFAULT,"+char(10)+		-- @pnRenewalStatus
	        "DEFAULT,"+char(10)+		-- @pnStatusCode
	        "@pbExactMatch,"+char(10)+
	        "DEFAULT"+char(10)+		-- @pnProfileKey
	        ") T"
	End	
End


If @nErrorCode=0
and @pnBestCriteriaOnly = 1
Begin
	Set @sSelect = 'Select  TOP 1 '
End
Else
Begin
	Set @sSelect = 'Select '
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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 700)

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
	Else Begin
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

		Else if @sColumn = 'CriteriaNo'
		Begin
			Set @sTableColumn='T.CRITERIANO'
		End
		
		Else if @sColumn = 'CriteriaName'
		Begin
			Set @sTableColumn='CR.DESCRIPTION'
			Set @sFrom = @sFrom +CHAR(10)+'join CRITERIA CR on (CR.CRITERIANO = T.CRITERIANO)'
		End
		
		Else if @sColumn = 'ParentCriteria'
		Begin
			Set @sTableColumn='T.PARENTCRITERIA'			
		End
		
		Else If @sColumn = 'CaseOffice'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join OFFICE O on (O.OFFICEID=T.CASEOFFICEID)'
		End

		Else If @sColumn = 'CaseType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join CASETYPE CT on (CT.CASETYPE=T.CASETYPE)'
		End

		Else If @sColumn = 'Country'
		Begin
			Set @sTableColumn='C.COUNTRY'
			Set @sFrom = @sFrom +CHAR(10)+'left join COUNTRY C on (C.COUNTRYCODE=T.COUNTRYCODE)'
		End

		Else If @sColumn = 'PropertyType'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDPROPERTY','PROPERTYNAME',null,'VP',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('PROPERTY','PROPERTYNAME',null,'P',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDPROPERTY VP on (VP.PROPERTYTYPE=T.PROPERTYTYPE'
					+CHAR(10)+'and VP.COUNTRYCODE =(select min(VP1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDPROPERTY VP1'
					+CHAR(10)+'where VP1.COUNTRYCODE in ("ZZZ",T.COUNTRYCODE)))'   
					+CHAR(10)+'left join PROPERTYTYPE P	on (P.PROPERTYTYPE=T.PROPERTYTYPE)'
		End

		Else If @sColumn = 'CaseCategory'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDCATEGORY','CASECATEGORYDESC',null,'VC',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDCATEGORY VC on (VC.PROPERTYTYPE=T.PROPERTYTYPE'
					+CHAR(10)+'and VC.CASETYPE = T.CASETYPE'
					+CHAR(10)+'and VC.CASECATEGORY = T.CASECATEGORY'
					+CHAR(10)+'and VC.COUNTRYCODE =( select min(VC1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDCATEGORY VC1'
					+CHAR(10)+'where VC1.CASETYPE = T.CASETYPE'
					+CHAR(10)+'and VC1.PROPERTYTYPE = T.PROPERTYTYPE'
					+CHAR(10)+'and VC1.COUNTRYCODE in ("ZZZ",T.COUNTRYCODE)))'
					+CHAR(10)+'left join CASECATEGORY CC on (CC.CASETYPE=T.CASETYPE'
					+CHAR(10)+'and CC.CASECATEGORY = T.CASECATEGORY)'
		End

		Else If @sColumn = 'Action'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDACTION','ACTIONNAME',null,'VA',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDACTION VA on (VA.PROPERTYTYPE=T.PROPERTYTYPE'
					+CHAR(10)+'and VA.[ACTION] = T.[ACTION]'
					+CHAR(10)+'and VA.CASETYPE = T.CASETYPE'
					+CHAR(10)+'and VA.COUNTRYCODE =( select min(VA1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDACTION VA1'
					+CHAR(10)+'where VA1.CASETYPE = T.CASETYPE'
					+CHAR(10)+'and VA1.[ACTION] = T.[ACTION]'
					+CHAR(10)+'and VA1.PROPERTYTYPE = T.PROPERTYTYPE'
					+CHAR(10)+'and VA1.COUNTRYCODE in ("ZZZ",T.COUNTRYCODE)))'
					+CHAR(10)+'left join ACTIONS A on (A.[ACTION]=T.[ACTION])'
		End
		
		Else If @sColumn = 'SubType'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDSUBTYPE','SUBTYPEDESC',null,'VS',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDSUBTYPE VS on (VS.PROPERTYTYPE=T.PROPERTYTYPE'
					+CHAR(10)+'and VS.CASETYPE = T.CASETYPE'
					+CHAR(10)+'and VS.CASECATEGORY = T.CASECATEGORY'
					+CHAR(10)+'and VS.SUBTYPE = T.SUBTYPE'
					+CHAR(10)+'and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDSUBTYPE VS1'
					+CHAR(10)+'where VS1.CASETYPE = T.CASETYPE'
					+CHAR(10)+'and VS1.PROPERTYTYPE = T.PROPERTYTYPE'
					+CHAR(10)+'and VS1.CASECATEGORY = T.CASECATEGORY'
					+CHAR(10)+'and VS1.COUNTRYCODE in ("ZZZ",T.COUNTRYCODE)))'
	                                +CHAR(10)+'left join SUBTYPE S on (S.SUBTYPE=T.SUBTYPE)'
		End

		Else If @sColumn = 'Basis'
		Begin
			Set @sTableColumn='isnull('+dbo.fn_SqlTranslatedColumn('VALIDBASIS','BASISDESCRIPTION',null,'VB',@sLookupCulture,0) +','
				    +dbo.fn_SqlTranslatedColumn('APPLICATIONBASIS','BASISDESCRIPTION',null,'B',@sLookupCulture,0) +')'
			Set @sFrom = @sFrom +CHAR(10)+'left join VALIDBASIS VB on (VB.PROPERTYTYPE=T.PROPERTYTYPE'
					+CHAR(10)+'and VB.BASIS=T.BASIS'
					+CHAR(10)+'and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)'
					+CHAR(10)+'from VALIDBASIS VB1'
					+CHAR(10)+'where VB1.PROPERTYTYPE = T.PROPERTYTYPE'
					+CHAR(10)+'and VB1.COUNTRYCODE in ("ZZZ",T.COUNTRYCODE)))'
	                                +CHAR(10)+'left join APPLICATIONBASIS B	on (B.BASIS=T.BASIS)'
		End

		Else If @sColumn = 'DateOfAct'
		Begin
			Set @sTableColumn='T.DATEOFACT'
		End
		
		Else If @sColumn = 'IsBelongsToGroup'
		Begin
			Set @sTableColumn='cast(T.BELONGSTOGROUP as bit)'
		End
		
		Else If @sColumn = 'IsUsedByOwners'
		Begin
			Set @sTableColumn='CASE WHEN T.REGISTEREDUSERS in ("Y", "B") THEN Cast(1 as bit) ELSE Cast(0 as bit) END'
		End
		
		Else If @sColumn = 'IsUsedByOthers'
		Begin
			Set @sTableColumn='CASE WHEN T.REGISTEREDUSERS in ("N", "B") THEN Cast(1 as bit) ELSE Cast(0 as bit) END'
		End
		
		Else If @sColumn = 'RuleInUse'
		Begin
			Set @sTableColumn='Cast(T.RULEINUSE as bit)'
		End

		Else If @sColumn = 'IsLocalClient'
		Begin
			Set @sTableColumn='Cast(T.LOCALCLIENTFLAG as bit)'
		End
		
		Else If @sColumn = 'ExamAttribute'
		Begin
			If charindex('left join TABLECODES TCE',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join TABLECODES TCE on (TCE.TABLECODE = T.TABLECODE and TCE.TABLETYPE = 8)'
			End
			
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCE',@sLookupCulture,@pbCalledFromCentura)
		End
		
		Else If @sColumn = 'RenewalAttribute'
		Begin
			If charindex('left join TABLECODES TCR',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join TABLECODES TCR on (TCR.TABLECODE = T.TABLECODE and TCR.TABLETYPE = 17)'
			End
			
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCR',@sLookupCulture,@pbCalledFromCentura)
		End
		
		Else If @sColumn = 'IsCPASSRules'
		Begin
			Set @sTableColumn = 'Cast(CASE WHEN T.USERDEFINEDRULE = 0 THEN 1 ELSE 0 END as bit)'
		End
		
		Else IF @sColumn = 'HasChildren'
		Begin
		        Set @sTableColumn = 'CAST((CASE WHEN (select COUNT(*) from INHERITS I where I.FROMCRITERIA=T.CRITERIANO)=0 THEN 0 ELSE 1 END) as bit)'
		End
                
                Else if @sColumn = 'CriteriaName'
		Begin
			Set @sTableColumn='T.DESCRIPTION'
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

-- When Criteria No is entered
If @pnCriteriaNo is not null
Begin
	set @sSQLString = @sSelect +CHAR(10)+ @sFrom + CHAR(10)+ 
				" where T.CRITERIANO = @pnCriteriaNo"	
End
Else -- When other search criteria is entered
Begin
	
	set @sSQLString = @sSelect +CHAR(10)+ @sFrom + CHAR(10)+ 
				" order by T.BESTFIT DESC"
End

if @nErrorCode = 0
begin
	print @sSQLString
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseOfficeID	int		OUTPUT,
			@psCaseType		nchar(1)	OUTPUT,
			@psPropertyType		nchar(1)	OUTPUT,
			@psCountryCode		nvarchar(3)	OUTPUT,
			@psCaseCategory		nvarchar(2)	OUTPUT,
			@psAction		nvarchar(2)	OUTPUT,
			@psSubType		nvarchar(2)	OUTPUT,
			@psBasis		nvarchar(2)	OUTPUT,
			@pnRuleInUse		decimal(1,0)	OUTPUT,
			@pnLocalClientFlag	decimal(1,0)	OUTPUT,
			@psRegisteredUsers	nchar(2)	OUTPUT,
			@pbExactMatch		bit             OUTPUT,
			@pnCriteriaNo		int',
			@pnCaseOfficeID		=	@pnCaseOfficeID		OUTPUT,
			@psCaseType		=	@psCaseType		OUTPUT,
			@psPropertyType		=	@psPropertyType		OUTPUT,
			@psCountryCode		=	@psCountryCode		OUTPUT,
			@psCaseCategory		=	@psCaseCategory		OUTPUT,
			@psAction		=	@psAction		OUTPUT,
			@psSubType		=	@psSubType		OUTPUT,
			@psBasis		=	@psBasis		OUTPUT,
			@pnRuleInUse		=	@pnRuleInUse		OUTPUT,
			@pnLocalClientFlag	=	@pnLocalClientFlag	OUTPUT,
			@psRegisteredUsers	=	@psRegisteredUsers	OUTPUT,
			@pbExactMatch		=	@pbExactMatch		OUTPUT,
			@pnCriteriaNo		=	@pnCriteriaNo	
                
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

Grant execute on dbo.ipw_ListWorkflowControlCriteria to public
GO


