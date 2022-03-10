-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseNames
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseNames.'
	Drop procedure [dbo].[csw_ListCaseNames]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseNames...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListCaseNames
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 160, 	-- The key for the context of the query (default output requests).	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL			bit		= null,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0,
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)
as
-- PROCEDURE:	csw_ListCaseNames
-- VERSION:	10
-- DESCRIPTION:	Returns the case name information, for case names that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Aug 2008	SF	RFC5715	1	Procedure created
-- 24 Sep 2008	SF	RFC5715	2	Format name using name style / nationality name style.
-- 10 Nov 2008  LP      RFC7112 3       Return IsStaff column
-- 05 Jan 2009	SF	RFC7450 4	When IsCorrespondenceSent is 0, implicitly return those which are null.
-- 07 Jul 2011	DL	RFC10830 5	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 24 Oct 2011	ASH	R11460  6	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270	7	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	8	Adjust formatted names logic (DR-15543).
-- 09 Oct 2017  MS      R72471  9       Show most recent AssociatedName
-- 16 Oct 2017  AK      R72474  10      changes made to include FullName

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
-- 	CaseKey
--	NameKey
--	NameCode
--	DisplayName
--      FullName
--	OrganisationNameKey
-- 	OrganisationNameCode
--	OrganisationDisplayName
--	DisplayMainEmail
-- 	DisplayMainPhone
--	IsCorrespondenceSent
--	CorrespondenceReceived
-- 	SequenceKey
--	NameTypeKey
--	NameTypeDescription
-- 	IsLead
--  IsStaff

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	CN
-- 	N (Name)
--	AN (Associated Name, to locate EMP)
--	ORG (Name's Organisation)
--	NT (NameType)
--  NAT (Country - Name's nationality)
--  ORGNAT (Country - Organisation Name's nationality)
--	TC (TableCodes for Correspondence received)
--  PH (Telecommunication)
--  EM (Telecommunication)
--  LEAD

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int

Declare @sSQLString		nvarchar(4000)

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
Declare @sCaseKey							nvarchar(11)    -- the CaseId of the Case
Declare @sTypeKey							nvarchar(6)    -- the CaseId of the Case
Declare @sCaseNameKeys							nvarchar(4000)	-- A comma separated list of NameNos.
Declare @sCaseNameName						nvarchar(254)	-- Name used for direct search (without look up of NameNo)
Declare @nCaseNameOperator					tinyint
Declare @sCaseNameOrgNameKeys				nvarchar(4000)	-- A comma separated list of NameNos.
Declare @sCaseNameOrgName					nvarchar(254)	-- Name used for direct search (without look up of NameNo)
Declare @nCaseNameOrgNameOperator			tinyint
Declare @bIsCorrespondenceSent				bit				
Declare @nCorrespondenceReceivedKey			int
Declare @nCorrespondenceReceivedKeyOperator	tinyint

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)
Declare @sCorrelationName		nvarchar(20)
Declare @sList					nvarchar(4000)	-- variable to prepare a comma separated list of values
Declare @sCountSelect			nvarchar(4000)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set

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
set 	@sSelect				='Select '
set 	@sFrom					= char(10)+'From CASENAME CN'
set 	@sWhere 				= char(10)+'	WHERE 1=1'

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
	-- Default @pnQueryContextKey to 600.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 600)

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
		If @sColumn='CaseKey'
		Begin
			Set @sTableColumn='CN.CASEID'
		End
		Else
		If @sColumn in ('SequenceKey')
		Begin
			Set @sTableColumn='CN.SEQUENCE'
		End
		Else
		If @sColumn in ('CaseNameKey')
		Begin
			Set @sTableColumn='Cast(CN.CASEID as nvarchar(11))+ ''^''+Cast(CN.NAMENO as nvarchar(11)) + ''^'' + Cast(CN.SEQUENCE as nvarchar(10))'
		End
		Else
		If @sColumn in ('NameTypeKey')
		Begin
			Set @sTableColumn='CN.NAMETYPE'
		End
		Else 
		If @sColumn='NameKey'
		Begin
			Set @sTableColumn='CN.NAMENO'
		End
		Else
		If @sColumn in ('NameTypeDescription')
		Begin
			If charindex('left join NAMETYPE NT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAMETYPE NT on (NT.NAMETYPE = CN.NAMETYPE)'
			End
			
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
		End		
		Else 
		If @sColumn in ('NameCode', 'DisplayName', 'FullName')
		Begin
			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME N on (N.NAMENO = CN.NAMENO)'
			End
			
			If charindex('left join COUNTRY NAT', @sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join COUNTRY NAT		on (NAT.COUNTRYCODE=N.NATIONALITY)'
			End

			Set @sTableColumn = Case 
				when @sColumn = 'NameCode' then 'N.NAMECODE'
				when @sColumn = 'DisplayName' then 'dbo.fn_FormatNameUsingNameNo(N.NAMENO, coalesce(N.NAMESTYLE,NAT.NAMESTYLE,7101))'
                                when @sColumn = 'FullName'    then 'dbo.fn_FormatName(N.NAME, N.FIRSTNAME, NULL, coalesce(N.NAMESTYLE,NAT.NAMESTYLE,7101))'
			End
		End		
		Else 
		If @sColumn in ('OrganisationNameKey', 'OrganisationNameCode', 'OrganisationDisplayName')
		Begin
			If charindex('left join ASSOCIATEDNAME AN',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + '
					left join ASSOCIATEDNAME AN on (AN.RELATEDNAME=CN.NAMENO and AN.RELATIONSHIP='+dbo.fn_WrapQuotes('EMP',0,@pbCalledFromCentura)+' 
                                                                        and (AN.CEASEDDATE is null or AN.CEASEDDATE >'''+convert(nvarchar(25),getdate(),120)+''')
                                                                        and (convert(nvarchar(23),ISNULL(AN.LOGDATETIMESTAMP,0),21)) =
					                                    (select max(convert(nvarchar(23),ISNULL(AN2.LOGDATETIMESTAMP,0),21))
					                                     from ASSOCIATEDNAME AN2
					                                     where AN2.RELATEDNAME=AN.RELATEDNAME
					                                      and AN2.RELATIONSHIP=AN.RELATIONSHIP
					                                     and (AN2.CEASEDDATE is null or AN2.CEASEDDATE >'''+convert(nvarchar(25),getdate(),120)+''')))
					left join NAME ORG on (ORG.NAMENO = AN.NAMENO)'
			End

			If charindex('left join COUNTRY ORGNAT', @sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join COUNTRY ORGNAT		on (ORGNAT.COUNTRYCODE=ORG.NATIONALITY)'
			End
			
			Set @sTableColumn = Case 
				when @sColumn = 'OrganisationNameKey' then 'ORG.NAMENO'
				when @sColumn = 'OrganisationNameCode' then 'ORG.NAMECODE'
				when @sColumn = 'OrganisationDisplayName' then 'dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, coalesce(ORG.NAMESTYLE,ORGNAT.NAMESTYLE,7101))'
			End
		End		
		Else
		If @sColumn in ('DisplayMainEmail', 'DisplayMainPhone')
		Begin
			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME N on (N.NAMENO = CN.NAMENO)'
			End
			
			If @sColumn in ('DisplayMainEmail')
			Begin
				If charindex('left join TELECOMMUNICATION ML',@sFrom)=0
				Begin
					Set @sFrom = @sFrom + char(10) + 'left join TELECOMMUNICATION ML on (N.MAINEMAIL = ML.TELECODE)'
				End

				Set @sTableColumn='dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION)'
			End
			Else
			Begin
				If charindex('left join TELECOMMUNICATION PH',@sFrom)=0
				Begin
					Set @sFrom = @sFrom + char(10) + 'left join TELECOMMUNICATION PH on (N.MAINPHONE = PH.TELECODE)'
				End

				Set @sTableColumn='dbo.fn_FormatTelecom(PH.TELECOMTYPE, PH.ISD, PH.AREACODE, PH.TELECOMNUMBER, PH.EXTENSION)'
			End
		End
		Else
		If @sColumn in ('IsCorrespondenceSent')
		Begin
			Set @sTableColumn='Cast(CN.CORRESPSENT as bit)'
		End		
		Else
		If @sColumn in ('CorrespondenceReceived')
		Begin
			If charindex('left join TABLECODES TC',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join TABLECODES TC on (TC.TABLETYPE = 153 and TC.TABLECODE = CN.CORRESPRECEIVED)'
			End
			
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
		End	
		Else
		If @sColumn in ('IsLead')
		Begin
			Set @sFrom = @sFrom + char(10) + 'left join (select DISTINCT NTC.NAMENO as [NAMENO]'
				                +char(10)+'from NAMETYPECLASSIFICATION NTC'
				                +char(10)+'WHERE NTC.NAMETYPE='+dbo.fn_WrapQuotes('~LD',0,@pbCalledFromCentura)+' and NTC.ALLOW=1) LEAD on (LEAD.NAMENO = CN.NAMENO)'			
			Set @sTableColumn='CASE WHEN LEAD.NAMENO is not null then CAST(1 as bit) ELSE CAST(0 as bit) END'			
		End
		Else If @sColumn='IsStaff'
		Begin
			Set @sTableColumn='CASE WHEN(N.USEDASFLAG&2=2) THEN cast(1 as bit) ELSE cast(0 as bit) END'
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

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @sCaseKey						= CaseKey,"+CHAR(10)+
	"	@sTypeKey						= TypeKey,"+CHAR(10)+
	"	@sCaseNameKeys							= NameKeys,"+CHAR(10)+
	"	@sCaseNameName						= [Name],"+CHAR(10)+
	"	@nCaseNameOperator					= NamesOperator,"+CHAR(10)+
	"	@sCaseNameOrgNameKeys				= OrganisationNameKeys,"+CHAR(10)+
	"	@sCaseNameOrgName					= OrganisationName,"+CHAR(10)+
	"	@nCaseNameOrgNameOperator			= OrganisationNamesOperator,"+CHAR(10)+
	"	@bIsCorrespondenceSent				= IsCorrespondenceSent,"+CHAR(10)+
	"	@nCorrespondenceReceivedKey			= CorrespondenceReceivedKey,"+CHAR(10)+
	"	@nCorrespondenceReceivedKeyOperator	= CorrespondenceReceivedKeyOperator"+CHAR(10)+
	"from	OPENXML (@idoc, '//csw_ListCaseName/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"			CaseKey							nvarchar(11)		'CaseKey/text()',"+CHAR(10)+
	"			TypeKey							nvarchar(6)			'TypeKey/text()',"+CHAR(10)+
	"			NameKeys						nvarchar(4000)		'Names/NameKeys/text()',"+CHAR(10)+
	"		 	[Name]							nvarchar(254)		'Names/Name/text()',"+CHAR(10)+
	"	      	NamesOperator					tinyint				'Names/@Operator/text()',"+CHAR(10)+
	"			OrganisationNameKeys			nvarchar(4000)		'OrganisationNames/NameKeys/text()',"+CHAR(10)+
	"		 	OrganisationName				nvarchar(254)		'OrganisationNames/Name/text()',"+CHAR(10)+
	"	      	OrganisationNamesOperator		tinyint				'OrganisationNames/@Operator/text()',"+CHAR(10)+
	"	      	IsCorrespondenceSent				bit					'IsCorrespondenceSent/text()',"+CHAR(10)+
	"	      	CorrespondenceReceivedKey			int					'CorrespondenceReceivedKey/text()',"+CHAR(10)+
	"	      	CorrespondenceReceivedKeyOperator	tinyint				'CorrespondenceReceivedKey/@Operator/text()'"+CHAR(10)+		
    "     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
					@sCaseKey							nvarchar(11)    output,
					@sTypeKey							nvarchar(6)		output,					
					@sCaseNameKeys							nvarchar(4000)	output,
					@sCaseNameName						nvarchar(254)	output,
					@nCaseNameOperator					tinyint			output,
					@sCaseNameOrgNameKeys				nvarchar(4000)	output,
					@sCaseNameOrgName					nvarchar(254)	output,
					@nCaseNameOrgNameOperator			tinyint			output,
					@bIsCorrespondenceSent				bit				output,
					@nCorrespondenceReceivedKey			int				output,
					@nCorrespondenceReceivedKeyOperator	tinyint			output',
					@idoc								= @idoc,
					@sCaseKey							= @sCaseKey 						output,
					@sTypeKey							= @sTypeKey							output,					
					@sCaseNameKeys							= @sCaseNameKeys 						output,
					@sCaseNameName						= @sCaseNameName 					output,
					@nCaseNameOperator					= @nCaseNameOperator 				output,
					@sCaseNameOrgNameKeys				= @sCaseNameOrgNameKeys			output,
					@sCaseNameOrgName					= @sCaseNameOrgName 				output,
					@nCaseNameOrgNameOperator			= @nCaseNameOrgNameOperator 		output,
					@bIsCorrespondenceSent				= @bIsCorrespondenceSent 				output,
					@nCorrespondenceReceivedKey			= @nCorrespondenceReceivedKey 			output,
					@nCorrespondenceReceivedKeyOperator	= @nCorrespondenceReceivedKeyOperator 	output		
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
	If @nErrorCode = 0
	Begin
		
		If @sCaseKey is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"	and	CN.CASEID="+@sCaseKey
		End
		
		If @sTypeKey is not null
		Begin
			Set @sWhere=@sWhere+char(10)+"	and	CN.NAMETYPE="+dbo.fn_WrapQuotes(@sTypeKey,0,@pbCalledFromCentura)
		End
		
		If @bIsCorrespondenceSent = 1
		Begin
			Set @sWhere = @sWhere+char(10)+" and CN.CORRESPSENT = 1"
		End		
		Else If @bIsCorrespondenceSent = 0
		Begin
			Set @sWhere = @sWhere+char(10)+" and (CN.CORRESPSENT = 0 or CN.CORRESPSENT is null)"			
		End	
		
		If @nCorrespondenceReceivedKey is not NULL
		or @nCorrespondenceReceivedKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+" and	CN.CORRESPRECEIVED"+dbo.fn_ConstructOperator(@nCorrespondenceReceivedKeyOperator,@Numeric,@nCorrespondenceReceivedKey, null,@pbCalledFromCentura)			
		End			
		
		If @sCaseNameKeys is not null
		and @nCaseNameOperator not in (5,6)
		Begin
			Set @sWhere = @sWhere+char(10)+" and CN.NAMENO"+dbo.fn_ConstructOperator(@nCaseNameOperator,@Numeric,@sCaseNameKeys, null,@pbCalledFromCentura)
		End

		If @sCaseNameName is not null		
		Begin
			If charindex('left join NAME N',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + 'left join NAME N on (N.NAMENO = CN.NAMENO)'
			End	
			Set @sWhere=@sWhere+char(10)+"and	upper(N.NAME)"+dbo.fn_ConstructOperator(@nCaseNameOperator,@String,upper(@sCaseNameName), null,0)			
		End	

		If @sCaseNameOrgName is not null 
		or (@sCaseNameOrgNameKeys is not null
		and @nCaseNameOrgNameOperator not in (5,6))
		Begin
			If charindex('left join ASSOCIATEDNAME AN',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + char(10) + '
					left join ASSOCIATEDNAME AN on (AN.RELATEDNAME=CN.NAMENO and AN.RELATIONSHIP='+dbo.fn_WrapQuotes('EMP',0,@pbCalledFromCentura)+')
					left join NAME ORG on (ORG.NAMENO = AN.NAMENO)'
			End
			
			If @sCaseNameOrgName is not null 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper(ORG.NAME)"+dbo.fn_ConstructOperator(@nCaseNameOrgNameOperator,@String,upper(@sCaseNameOrgName), null,0)			
			End
			Else
			Begin
				Set @sWhere = @sWhere+char(10)+"and ORG.NAMENO"+dbo.fn_ConstructOperator(@nCaseNameOrgNameOperator,@Numeric,@sCaseNameOrgNameKeys, null,@pbCalledFromCentura)
			End
		End
		
		Set @sList = null
		Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(NAMETYPE,0,@pbCalledFromCentura)
		From dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null,0,@pbCalledFromCentura)

		Set @sWhere= @sWhere+char(10)+"	and	CN.NAMETYPE IN ("+@sList+")"					
	End
End

-- Paging required
-- Assemble and execute the constructed SQL to return the result set
If  @nErrorCode = 0
-- No paging required
and (@pnPageStartRow is null or
     @pnPageEndRow is null)
Begin  		
	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:			
		Print 'SET ANSI_NULLS OFF ' 
		Print @sSelect
		Print @sFrom
		Print @sWhere
		Print @sOrder	
	End

	-- execute the constructed SQL:
	exec (	'SET ANSI_NULLS OFF ' +  @sSelect + @sFrom + @sWhere + @sOrder)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End
-- Paging required
Else If @nErrorCode = 0
Begin 
	Set @sSelect = replace(@sSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
	Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  		

	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:			
		Print 'SET ANSI_NULLS OFF ' 
		Print @sSelect
		Print @sFrom
		Print @sWhere
		Print @sOrder
	End

	-- execute the constructed SQL:
	exec (	'SET ANSI_NULLS OFF ' +  @sSelect + @sFrom + @sWhere + @sOrder)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

	If @pnRowCount<@pnPageEndRow
	and @nErrorCode=0
	Begin
		set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRowCount	int',
					  @pnRowCount=@pnRowCount
	End
	Else If @nErrorCode=0
	Begin
		If @pbPrintSQL = 1
		Begin
			-- Print out the executed SQL statement:			
			Print 'SET ANSI_NULLS OFF ' 
			Print @sCountSelect
			Print @sFrom
			Print @sWhere			
		End
		exec (	'SET ANSI_NULLS OFF ' +  @sCountSelect + @sFrom + @sWhere)
		
		Set @nErrorCode =@@ERROR
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseNames to public
GO
