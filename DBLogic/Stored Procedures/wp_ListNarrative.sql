-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListNarrative
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListNarrative]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListNarrative.'
	Drop procedure [dbo].[wp_ListNarrative]
End
Print '**** Creating Stored Procedure dbo.wp_ListNarrative...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ListNarrative
(
	@pnRowCount			int		= null output,	
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 220, -- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null	-- The filtering to be performed on the result set.			
)
as
-- PROCEDURE:	wp_ListNarrative
-- VERSION:	10
-- DESCRIPTION:	Returns the requested Narrative information that matches the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jun 2005	TM	RFC2575	1	Procedure created
-- 15 Jun 2005	TM	RFC2575	2	Remove the function dbo.fn_WrapQuotes from the filtering on @nStaffKey.
-- 24 Oct 2005	TM	RFC3024	3	Set 'ANSI_NULLS' to 'OFF' while executing the constructed SQL.
-- 15 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26 Nov 2009	PS	RFC8400	5	Add new column IsAssociated in the result set. Column value will be 1 for the narratives which are associated with the passed WIPTemplateKey in NARRATIVERULE table.
-- 11 Mar 2010	MS	RFC7279	6	Add Debtor in the best fit logic for selecting Narrative Rule.
-- 04 Apr 2010	AT	RFC3605	7	Removed stub.
-- 07 Jul 2011	DL	RFC10830 8	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 13 Sep 2011	ASH	R11175 9	Maintain Narrative Text in foreign languages.
-- 31 Oct 2018	DL	DR-45102	10	Replace control character (word hyphen) with normal sql editor hyphen

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	NarrativeKey
--	NarrativeCode
--	NarrativeTitle
--	NarrativeText
--	BestFitScore
--  IsAssociated

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--  AN
--	N
--	NRL
--  NRL1
--	NTR

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int

Declare @sSQLString		nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

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
Declare @nNarrativeKey 				smallint	-- The primary key of the Narrative.
Declare @nNarrativeKeyOperator			tinyint		
Declare @sPickListSearch			nvarchar(50)	-- The text entered by a user in a pick list field to locate appropriate entries. Case insensitive search.
Declare @bExists				bit
Declare @bIsTranslateNarrative			bit		-- If the Narrative Translate site control is on, the text is obtained in the language in which the bill will be raised. 
Declare @nLanguageKey				int		-- The language in which a bill is to be prepared.

-- Information about the context in which the information is being used.
Declare @nStaffKey				int		-- The key of the staff member being recorded on the WIP.
Declare @nNameKey				int		-- The key of the name the WIP is being recorded against. Either NameKey or CaseKey should be provided - not both.
Declare @nCaseKey				int		-- The key of the case the WIP is being recorded against. Either NameKey or CaseKey should be provided - not both.
Declare @sWipTemplateKey			nvarchar(6)	-- The key of the WIP Template being recorded on the WIP.
Declare	@nDebtorKey				int		-- The key of the name which is debtor of the case the WIP is being recorded against.

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
set 	@sFrom					= char(10)+"From NARRATIVE N"
set 	@sWhere 				= char(10)+"	WHERE 1=1"
set 	@sLookupCulture 			= dbo.fn_GetLookupCulture(@psCulture, null, 0)
set	@nLanguageKey				= null

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the filter criteria using element-centric mapping (implement 
	--    Case Insensitive searching were required)   

	Set @sSQLString = 	
	"Select @nNarrativeKey		= NarrativeKey,"+CHAR(10)+
	"	@nNarrativeKeyOperator	= NarrativeKeyOperator,"+CHAR(10)+
	"	@sPickListSearch	= upper(PickListSearch),"+CHAR(10)+
	"	@nStaffKey		= StaffKey,"+CHAR(10)+
	"	@nNameKey		= NameKey,"+CHAR(10)+				
	"	@nCaseKey		= CaseKey,"+CHAR(10)+
	"	@sWipTemplateKey	= WipTemplateKey"+CHAR(10)+
	"from	OPENXML (@idoc, '//wp_ListNarrative',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      NarrativeKey		smallint	'FilterCriteria/NarrativeKey/text()',"+CHAR(10)+
	"	      NarrativeKeyOperator	tinyint		'FilterCriteria/NarrativeKey/@Operator/text()',"+CHAR(10)+
	"	      PickListSearch		nvarchar(50)	'FilterCriteria/PickListSearch/text()',"+CHAR(10)+	
	"	      StaffKey			int		'ContextCriteria/StaffKey/text()',"+CHAR(10)+
 	"	      NameKey			int		'ContextCriteria/NameKey/text()',"+CHAR(10)+	
	"	      CaseKey			int		'ContextCriteria/CaseKey/text()',"+CHAR(10)+	
	"	      WipTemplateKey		nvarchar(6)	'ContextCriteria/WipTemplateKey/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nNarrativeKey 		smallint		output,
				  @nNarrativeKeyOperator	tinyint			output,
				  @sPickListSearch		nvarchar(50)		output,
				  @nStaffKey			int			output,	
				  @nNameKey			int			output,				
				  @nCaseKey			int			output,
				  @sWipTemplateKey		nvarchar(6)		output',
				  @idoc				= @idoc,
				  @nNarrativeKey 		= @nNarrativeKey	output,
				  @nNarrativeKeyOperator	= @nNarrativeKeyOperator output,
				  @sPickListSearch		= @sPickListSearch	output,
				  @nStaffKey			= @nStaffKey		output,
				  @nNameKey			= @nNameKey		output,				
				  @nCaseKey			= @nCaseKey		output,
				  @sWipTemplateKey		= @sWipTemplateKey	output			
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error
	
	-- Deriving DebtorKey. The main debtor for the CaseKey is used. This is the 
	-- CaseName for the Name Type = 'D' with the minimum sequence number.
	If @nErrorCode =0 and @nCaseKey is not null
	Begin
		Set @sSQLString = 
		"Select @nDebtorKey = CN.NAMENO
		 from CASENAME CN
		 where CN.CASEID = @nCaseKey
		 and   CN.NAMETYPE = 'D'
		 and  (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
		 and   CN.SEQUENCE = (select min(SEQUENCE) from CASENAME CN
				      where CN.CASEID = @nCaseKey
				      and CN.NAMETYPE = 'D'
				      and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
		
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @nDebtorKey			int			output,
					  @nCaseKey			int',
					  @idoc				= @idoc,	
					  @nDebtorKey			= @nDebtorKey		output,
					  @nCaseKey			= @nCaseKey
					 		
	End

	If @nErrorCode = 0
	Begin
	
		If @nNarrativeKey is not NULL
		or @nNarrativeKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and N.NARRATIVENO " + dbo.fn_ConstructOperator(@nNarrativeKeyOperator,@Numeric,@nNarrativeKey, null,0)
		End		

		-- The Pick List Search is performed in stages. As soon as rows are located for a criterion, a result set 
		-- is produced. The search only continues to the next criterion if no rows were located.
			
		If @sPickListSearch is not null
		Begin
			-- If the length of PickListSearch does not exceed the maximum length of the Code
			
			If LEN(@sPickListSearch) <= 6
			Begin
				Set @bExists = 0
				-- Check if Code Equals To PickListSearch
				Set @sSQLString = "Select @bExists=1"+char(10)+
						  "from NARRATIVE N"+char(10)+
						  @sWhere+
						  "and (N.NARRATIVECODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
			
				exec @nErrorCode =  sp_executesql @sSQLString,
							N'@bExists		bit		OUTPUT,
							  @sPickListSearch	nvarchar(50)',
							  @bExists		= @bExists 	OUTPUT,
							  @sPickListSearch	= @sPickListSearch
			
				If @bExists=1
				Begin
					Set @sWhere=@sWhere+char(10)+"and (N.NARRATIVECODE=" + dbo.fn_WrapQuotes(@sPickListSearch,0,0)+")"
				End
				Else
				Begin
					Set @sWhere=@sWhere+char(10)+"and (N.NARRATIVECODE like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+ 
								     " or upper(N.NARRATIVETITLE) like " + dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)+")"
				End
			End
			Else 
			Begin
				Set @sWhere=@sWhere+char(10)+"and upper(N.NARRATIVETITLE) like "+ dbo.fn_WrapQuotes(@sPickListSearch + '%',0,0)
			End
		End	
	End
End

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,0,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	-- Default @pnQueryContextKey to 220.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 220)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,0,null)

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
		If @sColumn='NULL'		
		Begin
			Set @sTableColumn='NULL'
		End
		Else
		If @sColumn='NarrativeKey'
		Begin
			Set @sTableColumn='N.NARRATIVENO'
		End
		Else 
		If @sColumn='NarrativeCode'
		Begin
			Set @sTableColumn='N.NARRATIVECODE'
		End
		Else 
		If @sColumn = 'NarrativeTitle'
		Begin
			Set @sTableColumn= dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',null,'N',@sLookupCulture,0)
		End
		Else 
		If @sColumn = 'NarrativeText'
		Begin
			Set @sSQLString = "
			Select @bIsTranslateNarrative = COLBOOLEAN
			from SITECONTROL where CONTROLID = 'Narrative Translate'"

			exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsTranslateNarrative	bit			 OUTPUT',
				  @bIsTranslateNarrative	= @bIsTranslateNarrative OUTPUT

			If   @bIsTranslateNarrative = 1
			and (@nNameKey is not null
			 or  @nCaseKey is not null)
			Begin
				exec @nErrorCode=dbo.bi_GetBillingLanguage
					@pnLanguageKey		= @nLanguageKey output,	
					@pnUserIdentityId	= @pnUserIdentityId,
					@pnDebtorKey		= @nNameKey,	
					@pnCaseKey		= @nCaseKey, 
					@pbDeriveAction		= 1					
			End			

			If @nLanguageKey is null
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETEXT',null,'N',@sLookupCulture,0)
			End
			Else Begin

				Set @sTableColumn='ISNULL(NTR.TRANSLATEDTEXT,'+
							dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETEXT',null,'N',@sLookupCulture,0)+
							')'
				If charindex('left join NARRATIVETRANSLATE NTR',@sFrom)=0
				Begin
					Set @sFrom = @sFrom + char(10) + 'left join NARRATIVETRANSLATE NTR	on (NTR.NARRATIVENO = N.NARRATIVENO' 
							    + char(10) + '					and NTR.LANGUAGE = ' + CAST(@nLanguageKey as varchar(10)) + ')'
				End				
			End
		End
		Else
		If @sColumn = 'BestFitScore'
		Begin
			If @sWipTemplateKey is not null
			Begin					
				Set @sTableColumn='BestFit.BestFitScore'
	
				If charindex('left join (	Select  NRL.NARRATIVENO as NarrativeNo,',@sFrom)=0
				Begin
					Set @sFrom = @sFrom + char(10) + 
					"left join (	Select  NRL.NARRATIVENO as NarrativeNo,"+char(10)+
								"convert(int,"+char(10)+
								"max ("+char(10)+								
								"CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
								"CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    
								"CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+    			
								"CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"CASE WHEN (NRL.SUBTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
								"CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END)) as BestFitScore"+char(10)+
							"from NARRATIVERULE NRL"+char(10)+
							"left join CASES C on " + char(10)+ 
								CASE WHEN @nCaseKey is null THEN "(C.CASEID is null)" ELSE "(C.CASEID = "+CAST(@nCaseKey as varchar(11))+")" END +char(10)+							
							"where NRL.WIPCODE		= "+dbo.fn_WrapQuotes(@sWipTemplateKey,0,0)+char(10)+	
							CASE WHEN @nNameKey is null and @nDebtorKey is null THEN "AND NRL.DEBTORNO IS NULL "
								ELSE "AND ( NRL.DEBTORNO = "+ISNULL(CAST(@nNameKey as varchar(11)), CAST(@nDebtorKey as varchar(11)))+ " OR NRL.DEBTORNO IS NULL )" END +char(10)+
							CASE WHEN @nStaffKey is null THEN "AND NRL.EMPLOYEENO IS NULL "
								ELSE "AND ( NRL.EMPLOYEENO = "+CAST(@nStaffKey as varchar(11))+" OR NRL.EMPLOYEENO IS NULL )" END +char(10)+
							"AND (	NRL.CASETYPE		= C.CASETYPE		OR NRL.CASETYPE		is NULL )"+char(10)+
							"AND (	NRL.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR NRL.PROPERTYTYPE 	IS NULL )"+char(10)+
							"AND (	NRL.CASECATEGORY 	= C.CASECATEGORY 	OR NRL.CASECATEGORY 	IS NULL )"+char(10)+
							"AND (	NRL.SUBTYPE 		= C.SUBTYPE 		OR NRL.SUBTYPE	 	IS NULL )"+char(10)+
							"AND (	NRL.TYPEOFMARK		= C.TYPEOFMARK		OR NRL.TYPEOFMARK	IS NULL )"+char(10)+
							"group by NRL.NARRATIVENO) BestFit	on (BestFit.NarrativeNo = N.NARRATIVENO)"	
				End											
			End
			Else Begin
				Set @sTableColumn='NULL'
			End
		End	
		Else 
		If @sColumn = 'IsAssociated'
		Begin
			If @sWipTemplateKey is not null
			Begin				
				Set @sTableColumn='AN.IsAssociated'
				Begin
					Set @sFrom = @sFrom + char(10) + 
					"left join (	Select  NRL1.NARRATIVENO as NarrativeNo,"+char(10)+
					"cast(1 as bit) as IsAssociated"+char(10)+
					"from NARRATIVERULE NRL1 where NRL1.WIPCODE = " + cast(dbo.fn_WrapQuotes(@sWipTemplateKey,0,0) as nvarchar(10)) + "  group by NRL1.NARRATIVENO) AN on (AN.NarrativeNo = N.NARRATIVENO)"	
				End											
			End
			Else Begin
				Set @sTableColumn='NULL'
			End
			
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

If @nErrorCode=0
Begin 	
	-- Now execute the constructed SQL to return the result set
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End

Return @nErrorCode
GO

Grant execute on dbo.wp_ListNarrative to public
GO
