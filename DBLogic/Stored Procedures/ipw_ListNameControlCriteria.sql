-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListNameControlCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListNameControlCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListNameControlCriteria.'
	Drop procedure [dbo].[ipw_ListNameControlCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_ListNameControlCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListNameControlCriteria
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
-- PROCEDURE:	ipw_ListNameCriteria
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Used to get the search results for Name Criteria based on the
--		filter criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Jun 2009	MS	RFC7085	1	Procedure created
-- 06 Aug 2009	MS	RFC7085	2	Added changes for Organization, Individual and Data Unknown checkboxes
-- 27 Aug 2009  LP      RFC7580 3       Return ParentCriteria, HasChildren and CriteriaName columns.
-- 10 Sep 2009	LP	RFC8047	4	Add ProfileKey filter criteria.
-- 08 Feb 2010	MS	RFC7329	5	Search based on CriteriaNo.
-- 07 Jul 2011	DL	RFC10830 6	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Dec 2014	LP	R41737	7	Check for logical name programs that belong to parent Name programs

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sSelect		nvarchar(max)
declare @sWhere			nvarchar(4000)
declare @sFrom			nvarchar(4000)
declare @sFromInd		nvarchar(4000)
declare @sFromOrg		nvarchar(4000)
declare @sFromUnknown		nvarchar(4000)
Declare @sOrder			nvarchar(1000)	-- the SQL sort order
Declare @sLookupCulture		nvarchar(10)
Declare @nCount			int
Declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sQualifier		nvarchar(50)
declare @sCorrelationSuffix	nvarchar(20)
declare @sPublishName		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
Declare @idoc 			int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
Declare @pnFilterGroupIndex	int
Declare @sComma			nchar(2)	-- initialised when a column has been added to the Select.

declare @psProgramID		nvarchar(8)
declare @psCountryCode		nvarchar(3)
declare @pnCategoryCode		int
declare @psNameTypeKey		nvarchar(3)
declare @psRelationshipKey	nvarchar(3)
declare @pbIsOrganisation	bit
declare @pbIsIndividual		bit
declare @pbDataUnknown		bit
declare @pbIsClient		bit
declare @pbIsSupplier		bit
declare @pbIsStaff		bit
declare @pbIsLocalClient	bit
declare @pbRuleInUse		bit
declare @pbExactMatch		bit
declare @pbBestCriteriaOnly	bit
declare @pbIsCRMOnly		bit
declare @pbIsProtectedRules	bit
declare	@pbHasCRMLicense	bit
declare @pnUsedAsFlagInd	smallint
declare @pnUsedAsFlagOrg	smallint
declare @pnProfileKey		int
declare @nOutRequestsRowCount	int
declare @pnCriteriaNo		int

-- Initialise variables
Set @nErrorCode		= 0
set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nCount		= 1
Set @pnFilterGroupIndex = 1
Set @pbHasCRMLicense	= dbo.fn_IsModuleLicensedToUser(@pnUserIdentityId, 25, getdate())

If (datalength(@ptXMLFilterCriteria) = 0 or datalength(@ptXMLFilterCriteria) is null)
and @nErrorCode = 0
Begin
	Set @psProgramID	=	null	
	Set @psCountryCode	=	null
	Set @pnCategoryCode	=	null
	Set @psNameTypeKey	=	null
	Set @psRelationshipKey	=	null
	Set @pbIsOrganisation	=	null
	Set @pbIsIndividual	=	null
	Set @pbDataUnknown	=	null
	Set @pbIsClient		=	null
	Set @pbIsSupplier	=	null
	Set @pbIsStaff		=	null	
	Set @pbIsLocalClient	=	null
	Set @pbRuleInUse	=	null
	Set @pbExactMatch	=	1
	Set @pbIsCRMOnly	=	0
	Set @pbIsProtectedRules	=	0
	Set @pnProfileKey	=	null
	Set @pnCriteriaNo	=	null
End
Else
-- If there are some @ptXMLFilterCriteria passed then begin
If @nErrorCode = 0
and datalength(@ptXMLFilterCriteria) > 0 
Begin
	Exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
	-- 1) Retrieve the FilterCriteria elements using element-centric mapping
	Set @sSQLString = 
		"Select @psProgramID		=	ProgramID,"+CHAR(10)+	
		"	@psCountryCode		=	CountryCode,"+CHAR(10)+
		"	@pnCategoryCode		=	CategoryCode,"+CHAR(10)+
		"	@psNameTypeKey		=	NameTypeKey,"+CHAR(10)+
		"	@psRelationshipKey	=	RelationshipKey,"+CHAR(10)+
		"	@pbIsOrganisation	=	IsOrganisation,"+CHAR(10)+
		"	@pbIsIndividual		=	IsIndividual,"+CHAR(10)+
		"	@pbDataUnknown		=	DataUnknown,"+CHAR(10)+
		"	@pbIsClient		=	IsClient,"+CHAR(10)+
		"	@pbIsSupplier		=	IsSupplier,"+CHAR(10)+
		"	@pbIsStaff		=	IsStaff,"+CHAR(10)+		
		"	@pbIsLocalClient	=	IsLocalClient,"+CHAR(10)+
		"	@pbRuleInUse		=	RuleInUse,"+CHAR(10)+
		"	@pbIsCRMOnly		=	IsCRMOnly,"+CHAR(10)+
		"	@pbIsProtectedRules	=	IsProtectedRules,"+CHAR(10)+
		"	@pbExactMatch		=	IsExactMatch,"+CHAR(10)+
		"	@pbBestCriteriaOnly	=	BestCriteriaOnly,"+CHAR(10)+
		"	@pnProfileKey		=	ProfileID,"+CHAR(10)+
		"	@pnCriteriaNo		=	CriteriaNo"+CHAR(10)+
		"from OPENXML(@idoc, '/ipw_ListNameControlCriteria/FilterCriteriaGroup/FilterCriteria["+convert(nvarchar(3), @pnFilterGroupIndex)+"]',2)"+CHAR(10)+
		"with ("+CHAR(10)+
		"	ProgramID		nvarchar(8)	'Program/ProgramID/text()',"+CHAR(10)+
		"	CountryCode		nvarchar(3)	'Country/CountryCode/text()',"+CHAR(10)+
		"	CategoryCode		int		'Category/CategoryCode/text()',"+CHAR(10)+
		"	NameTypeKey		nvarchar(3)	'NameType/NameTypeKey/text()',"+CHAR(10)+
		"	RelationshipKey		nvarchar(3)	'Relationship/RelationshipKey/text()',"+CHAR(10)+
		"	IsOrganisation		bit		'TypeOfEntity/IsOrganisation/text()',"+CHAR(10)+
		"	IsIndividual		bit		'TypeOfEntity/IsIndividual/text()',"+CHAR(10)+
		"	DataUnknown		bit		'TypeOfEntity/DataUnknown/text()',"+CHAR(10)+
		"	IsClient		bit		'UsedAs/IsClient/text()',"+CHAR(10)+
		"	IsSupplier		bit		'UsedAs/IsSupplier/text()',"+CHAR(10)+
		"	IsStaff			bit		'UsedAs/IsStaff/text()',"+CHAR(10)+		
		"	IsLocalClient		bit		'IsLocalClient/text()',"+CHAR(10)+
		"	RuleInUse		bit		'RuleInUse/text()',"+CHAR(10)+
		"	IsCRMOnly		bit		'IsCRMOnly/text()',"+CHAR(10)+
		"	IsProtectedRules	bit		'IsProtectedRules/text()',"+CHAR(10)+
		"	IsExactMatch		bit		'IsExactMatch/text()',"+CHAR(10)+
		"	BestCriteriaOnly	bit		'BestCriteriaOnly/text()',"+CHAR(10)+
		"	ProfileID		int		'Profile/ProfileID/text()',"+CHAR(10)+
		"	CriteriaNo		int		'CriteriaNo/text()'"+CHAR(10)+
		")"

		Exec @nErrorCode = sp_executesql @sSQLString,
			N' @idoc		int,
			@psProgramID		nvarchar(8)	output,
			@psCountryCode		nvarchar(3)	output,
			@pnCategoryCode		int		output,
			@psNameTypeKey		nvarchar(3)	output,
			@psRelationshipKey	nvarchar(3)	output,
			@pbIsOrganisation	bit		output,
			@pbIsIndividual		bit		output,
			@pbDataUnknown		bit		output,
			@pbIsClient		bit		output,
			@pbIsSupplier		bit		output,
			@pbIsStaff		bit		output,			
			@pbIsLocalClient	bit		output,
			@pbRuleInUse		bit		output,
			@pbIsCRMOnly		bit		output,
			@pbIsProtectedRules	bit		output,
			@pbExactMatch		bit		output,
			@pbBestCriteriaOnly	bit		output,
			@pnProfileKey		int		output,
			@pnCriteriaNo		int		output',
			@idoc			= @idoc,
			@psProgramID		= @psProgramID		output,
			@psCountryCode		= @psCountryCode	output,
			@pnCategoryCode		= @pnCategoryCode	output,
			@psNameTypeKey		= @psNameTypeKey	output,
			@psRelationshipKey	= @psRelationshipKey	output,
			@pbIsOrganisation	= @pbIsOrganisation	output,
			@pbIsIndividual		= @pbIsIndividual	output,
			@pbDataUnknown		= @pbDataUnknown	output,
			@pbIsClient		= @pbIsClient		output,
			@pbIsSupplier		= @pbIsSupplier		output,
			@pbIsStaff		= @pbIsStaff		output,
			@pbIsLocalClient	= @pbIsLocalClient	output,
			@pbRuleInUse		= @pbRuleInUse		output,
			@pbIsCRMOnly		= @pbIsCRMOnly		output,
			@pbIsProtectedRules	= @pbIsProtectedRules	output,
			@pbExactMatch		= @pbExactMatch		output,
			@pbBestCriteriaOnly	= @pbBestCriteriaOnly	output,
			@pnProfileKey		= @pnProfileKey		output,
			@pnCriteriaNo		= @pnCriteriaNo		output

		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc
		
		Set @nErrorCode=@@Error

End

If @pnCriteriaNo is not null
Begin
	Set @sFrom = " from NAMECRITERIA N"
	
End
Else 
Begin
	-- For CRM Only licence
	If @nErrorCode = 0 and @pbIsCRMOnly = 1
	Begin
		Set @sSQLString = "Select @psProgramID = COLCHARACTER 
					From SITECONTROL 
					Where CONTROLID = 'CRM Name Screen Program'"
		Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psProgramID	nvarchar(8)	output',
				@psProgramID	= @psProgramID	output
			
	End

	If @nErrorCode = 0
	Begin
		-- Set for Individual
		Set @pnUsedAsFlagInd = 1 * 1 | isnull(@pbIsStaff, 0) * 2 | isnull(@pbIsClient, 0) * 4
		Set @sFromInd = "From dbo.fn_GetCriteriaNameRows"+char(10)+
			"("+char(10)+
			"	'W',"+char(10)+
			"	@psProgramID,"+char(10)+
			"	null,	---  Name No."+char(10)+
			"	@pnUsedAsFlagInd,"+char(10)+
			"	@pbIsSupplier,"+char(10)+
			"	@psCountryCode,"+char(10)+
			"	@pbIsLocalClient,"+char(10)+
			"	@pnCategoryCode,"+char(10)+		
			"	@psNameTypeKey,"+char(10)+		
			"	@psRelationshipKey,"+char(10)+				
			"	@pbRuleInUse,"+char(10)+
			"	0,"+char(10)+	
			"	@pbExactMatch,"+char(10)+	
			"	@pnProfileKey"+char(10)+
			") N"	

		-- Set for Organization
		Set @pnUsedAsFlagOrg = 0 * 1 | isnull(@pbIsStaff, 0) * 2 | isnull(@pbIsClient, 0) * 4
		Set @sFromOrg = "From dbo.fn_GetCriteriaNameRows"+char(10)+
			"("+char(10)+
			"	'W',"+char(10)+
			"	@psProgramID,"+char(10)+
			"	null,	---  Name No."+char(10)+
			"	@pnUsedAsFlagOrg,"+char(10)+
			"	@pbIsSupplier,"+char(10)+
			"	@psCountryCode,"+char(10)+
			"	@pbIsLocalClient,"+char(10)+
			"	@pnCategoryCode,"+char(10)+		
			"	@psNameTypeKey,"+char(10)+		
			"	@psRelationshipKey,"+char(10)+				
			"	@pbRuleInUse,"+char(10)+
			"	0,"+char(10)+	
			"	@pbExactMatch,"+char(10)+	
			"	@pnProfileKey"+char(10)+
			") N"

		-- Set for Data Unknown
		Set @sFromUnknown = "From dbo.fn_GetCriteriaNameRows"+char(10)+
			"("+char(10)+
			"	'W',"+char(10)+
			"	@psProgramID,"+char(10)+
			"	null,	---  Name No."+char(10)+
			"	null,"+char(10)+
			"	@pbIsSupplier,"+char(10)+
			"	@psCountryCode,"+char(10)+
			"	@pbIsLocalClient,"+char(10)+
			"	@pnCategoryCode,"+char(10)+		
			"	@psNameTypeKey,"+char(10)+		
			"	@psRelationshipKey,"+char(10)+				
			"	@pbRuleInUse,"+char(10)+
			"	1,"+char(10)+	
			"	@pbExactMatch,"+char(10)+	
			"	@pnProfileKey"+char(10)+
			") N"
	End
End

If @nErrorCode=0
and @pbBestCriteriaOnly = 1
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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 710)

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
		
		Else if @sColumn = 'NameCriteriaNo'
		Begin
			Set @sTableColumn='N.NAMECRITERIANO'
			If @pbIsProtectedRules = 0
			Begin
				Set @sOrderDirection = 'D'
			End
		End

		Else if @sColumn = 'Program'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROGRAM','PROGRAMNAME',null,'P',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join PROGRAM P on (P.PROGRAMID=N.PROGRAMID)'
		End

		Else if @sColumn = 'NameType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join NAMETYPE NT on (NT.NAMETYPE=N.NAMETYPE)'
		End
		Else if @sColumn = 'Relationship'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join NAMERELATION NR on (NR.RELATIONSHIP=N.RELATIONSHIP)'
		End

		Else if @sColumn = 'Organization'
		Begin
			 
			Set @sTableColumn='CASE when N.USEDASFLAG is not null then ~cast((N.USEDASFLAG & 1) as bit) else cast(0 as bit) end'
		End
		
		Else if @sColumn = 'Individual'
		Begin
			Set @sTableColumn='cast((isnull(N.USEDASFLAG, 0) & 1) as bit)'
		End

		Else if @sColumn = 'Staff'
		Begin
			Set @sTableColumn='cast((isnull(N.USEDASFLAG, 0) & 2) as bit)'
		End

		Else if @sColumn = 'Client'
		Begin
			Set @sTableColumn='cast((isnull(N.USEDASFLAG, 0) & 4) as bit)'
		End

		Else If @sColumn = 'IsProtectedRule'
		Begin
			Set @sTableColumn = 'CASE WHEN N.USERDEFINEDRULE = 0 THEN 1 ELSE 0 END'
		End

		Else if @sColumn = 'Supplier'
		Begin
			Set @sTableColumn='Cast(N.SUPPLIERFLAG as bit)'
		End

		Else if @sColumn = 'Country'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join COUNTRY C on (C.COUNTRYCODE=N.COUNTRYCODE)'
		End

		Else if @sColumn = 'LocalClient'
		Begin
			Set @sTableColumn='N.LOCALCLIENTFLAG'
		End

		Else if @sColumn = 'Category'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join TABLECODES TC on (TC.TABLECODE=N.CATEGORY)'
		End

		Else if @sColumn = 'RuleInUse'
		Begin
			Set @sTableColumn='N.RULEINUSE'
		End
		
		Else if @sColumn = 'CriteriaName'
		Begin
		        Set @sTableColumn='N.DESCRIPTION'
		End
		
		Else if @sColumn = 'ParentCriteria'
		Begin
		        If @pnCriteriaNo is null
			Begin
				Set @sTableColumn='N.PARENTCRITERIA'
			End
			Else
			Begin
				Set @sTableColumn='NI.FROMNAMECRITERIANO'
				Set @sFrom = @sFrom +CHAR(10)+'left join NAMECRITERIAINHERITS NI on (NI.NAMECRITERIANO = N.NAMECRITERIANO)'
			End
		End
		Else IF @sColumn = 'HasChildren'
		Begin
		        Set @sTableColumn = 'CAST((CASE WHEN (select COUNT(*) from NAMECRITERIAINHERITS I where I.FROMNAMECRITERIANO=N.NAMECRITERIANO)=0 THEN 0 ELSE 1 END) as bit)'
		End
		
		Else if @sColumn = 'ProfileName'
		Begin
		        Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROFILES','PROFILENAME',null,'PR',@sLookupCulture,0)
			Set @sFrom = @sFrom +CHAR(10)+'left join PROFILES PR on (PR.PROFILEID=N.PROFILEID)'
		End

		If datalength(@sPublishName)>0
		Begin
			Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
			Set @sComma=', '
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

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
	Set @nErrorCode=@@Error

End

-- When Criteria No is entered
If @pnCriteriaNo is not null
Begin
	Set @sSQLString = @sSelect + CHAR(10)+ @sFrom + CHAR(10)+
			"where N.NAMECRITERIANO = @pnCriteriaNo"
End
Else -- When other search criteria is entered
Begin
	-- Assemble the "Order By" clause.
	If @nErrorCode=0
	Begin	
		Set @sSelect=@sSelect+@sComma+ 'N.BESTFIT' 
		
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
			Set @sOrder = 'Order by N.BESTFIT desc, ' + @sOrder 
		End
		Else 
		Begin
			Set @sOrder = 'Order by N.BESTFIT desc' 
		End

		Set @nErrorCode=@@Error
	End


	Set @sWhere = @sFrom + CHAR(10)+ 
			"where N.PROGRAMID in 
				(select PX.PROGRAMID 
				 from PROGRAM PX 
				 left join PROGRAM PP on (PX.PROGRAMID = PP.PARENTPROGRAM
								and PP.PROGRAMGROUP = 'N')
				 where PX.PROGRAMGROUP = 'N' or PX.PROGRAMGROUP IS NULL)"
			+char(10)+  
			CASE 					
				WHEN @pbIsCRMOnly=1 THEN  -- CRM ONly Name Types are selected
					" and (N.NAMETYPE in (Select NAMETYPE from NAMETYPE where PICKLISTFLAGS & 32 = 32)" +char(10)+
					" or N.NAMETYPE is null)" 					
				WHEN @pbHasCRMLicense=0 THEN -- Name Types not related to CRM are selected 
					" and (N.NAMETYPE in (Select NAMETYPE from NAMETYPE where PICKLISTFLAGS & 32 != 32)" +char(10)+
					" or N.NAMETYPE is null)" 
				END

	-- Cases for checkboxes Organization, Individual and Data Unknown
	-- Case 1: When Data Unknown is checked
	If @pbDataUnknown = 1
	Begin 
		Set @sSQLString = @sSelect + CHAR(10)+ @sFromUnknown + CHAR(10)+  @sWhere
	End
	Else 
	Begin
		-- Case 2: When Individual is checked rest others unchecked
		If  @pbIsIndividual = 1 and @pbIsOrganisation = 0
		Begin
			Set @sSQLString = @sSelect +CHAR(10)+ @sFromInd + CHAR(10)+ @sWhere  
		End
		-- Case 3: When Organization is checked rest others unchecked
		Else If @pbIsOrganisation = 1 and @pbIsIndividual = 0
		Begin
			Set @sSQLString = @sSelect +CHAR(10)+ @sFromOrg + CHAR(10)+ @sWhere      
		End	
		-- Case 4: When Organization and Individual both are not checked (Default Case)
		Else If @pbIsOrganisation = 0 and @pbIsIndividual = 0  
		Begin		
			If @pbExactMatch = 1
			Begin
			Set @sSQLString = @sSelect +CHAR(10)+ @sFromInd + CHAR(10)+ @sWhere +char(10)+ 
				"UNION" +char(10)+
				@sSelect + CHAR(10)+ @sFromOrg + CHAR(10)+  @sWhere  
				-- If Client is not checked then display the records for Unknown
				If @pbIsClient = 0 
				Begin
					Set @sSQLString = @sSQLString + " UNION" +char(10)+
					@sSelect + CHAR(10)+ @sFromUnknown + CHAR(10)+  @sWhere 
				End
			End
			Else
			Begin
				Set @pnUsedAsFlagInd = null 
				Set @sSQLString = @sSelect +CHAR(10)+ @sFromInd + CHAR(10)+ @sWhere 
			End
		End
	End

	Set @sSQLString = @sSQLString +char(10)+ @sOrder
End

If @nErrorCode = 0
Begin
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@psProgramID		nvarchar(8),		
				@pnUsedAsFlagInd	smallint,
				@pnUsedAsFlagOrg	smallint,
				@pbIsSupplier		bit,
				@psCountryCode		nvarchar(3),	
				@pbDataUnknown		bit,
				@pbIsLocalClient	bit,
				@pnCategoryCode		int,
				@psNameTypeKey		nvarchar(3),
				@psRelationshipKey	nvarchar(3),
				@pbRuleInUse		bit,			
				@pbExactMatch		bit,
				@pnProfileKey		int,
				@pnCriteriaNo		int',
				@psProgramID		= @psProgramID,	
				@pnUsedAsFlagInd	= @pnUsedAsFlagInd,
				@pnUsedAsFlagOrg	= @pnUsedAsFlagOrg,
				@pbIsSupplier		= @pbIsSupplier,
				@psCountryCode		= @psCountryCode,
				@pbDataUnknown		= @pbDataUnknown,
				@pbIsLocalClient	= @pbIsLocalClient,
				@pnCategoryCode		= @pnCategoryCode,
				@psNameTypeKey		= @psNameTypeKey,
				@psRelationshipKey	= @psRelationshipKey,
				@pbRuleInUse		= @pbRuleInUse,			
				@pbExactMatch		= @pbExactMatch,
				@pnProfileKey		= @pnProfileKey,
				@pnCriteriaNo		= @pnCriteriaNo	

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

Grant execute on dbo.ipw_ListNameControlCriteria to public
GO
