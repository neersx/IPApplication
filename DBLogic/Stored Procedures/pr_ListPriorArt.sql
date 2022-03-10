-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pr_ListPriorArt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[pr_ListPriorArt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.pr_ListPriorArt.'
	drop procedure dbo.pr_ListPriorArt
End
print '**** Creating procedure dbo.pr_ListPriorArt...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.pr_ListPriorArt
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 200,	-- The key for the context of the query (default output requests).	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbPrintSQL			bit		= 1,	-- When set to 1, the executed SQL statement is printed out. 
	@pbCalledFromCentura		bit		= 0,
	@pnPageStartRow			int		= null,	-- The row number of the first record requested. Null if no paging required. 
	@pnPageEndRow			int		= null
)	
AS
-- PROCEDURE :	pr_ListPriorArt
-- VERSION :	10
-- DESCRIPTION:	Returns the requested information, for Prior Art that matches the filter criteria provided.  
--		Caters for aggregate columns, group by and having clauses.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02 Feb 2011  KR	R6563	1	Procedure created
-- 13 Jul 2011	DL	S19795	2	Specify collate database default for temp table.
-- 13 Jul 2011	DL	R10830	3	Specify collation default in temp table.
-- 26 Sep 2012	SF	R11988	4	Return discover source id
-- 05 May 2014	MF	R33895	5	New columns for Abstract and ReferencedPages
-- 04 Jul 2014  SW      R35971  6       New column for Comments
-- 20 Nov 2014	MF	R38472	7	New columns for Case related information
-- 03 Feb 2015	MF	R44500	8	When Case related information is being reported, it should also have any entered Case filters applied.
-- 12 Feb 2015	MF	R44500	9	Further work to handle Case Exists and Family Not Exists
-- 06 Jul 2018	MF	74486	10	When searching by characteristics held with the Source Document, also return any cited prior art that is
--					linked to the Source Document found.

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	Abstract
--	CaseCountry
--	CaseFamily
--	CaseOfficialNumber
--	CasePriorArtStatus
--	CaseReference
--	CaseStatusDesciption
--	CaseStatusSummary
--	CaseStatusExternal
--	Citation
--	Classes
--	Country
--	CountryCode
--	Decription
--	DiscoverSourceId
--	GrantedDate
--	IsIPDocument
--	IsSourceDocument
--	IssuedDate
--	IssuingCountry
--	IssuingCountryCode
--	KindCode
--	Name
--	OfficialNo
--	PriorArtKey
--	PriorityDate
--	Publication
--	PublicationDate
--	ReceivedDate
--	ReferencedPagest
--	SourceDescription
--	SubClasses
--	Title
--      Comments

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	CN
-- 	CNI
-- 	CND
--	CS
--	CSR
--	CSX
--	CT
--	NE
--	NI
--	NW
--	R
--	S
--	SD
--	SCUR
--	ST
--	TC

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sAlertXML	 		nvarchar(400)

-- The SQL used by the csw_ListCase stored procedure
Declare @sSql				nvarchar(max)
Declare @sSQLString			nvarchar(max)
Declare	@sSelectList1			nvarchar(max)	-- the SQL list of columns to return
Declare	@sSelectList2			nvarchar(max)
Declare	@sSelectList3			nvarchar(max)
Declare	@sSelectList4			nvarchar(max)
Declare	@sSelectList5			nvarchar(max)	-- the SQL list of columns to return
Declare	@sSelectList6			nvarchar(max)
Declare	@sSelectList7			nvarchar(max)
Declare	@sSelectList8			nvarchar(max)
Declare	@sFrom1				nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom2				nvarchar(4000)
Declare	@sFrom3				nvarchar(4000)
Declare	@sFrom4				nvarchar(4000)
Declare	@sFrom5				nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom6				nvarchar(4000)
Declare	@sFrom7				nvarchar(4000)
Declare	@sFrom8				nvarchar(4000)
Declare	@sFrom9				nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom10			nvarchar(4000)
Declare	@sFrom11			nvarchar(4000)
Declare	@sFrom12			nvarchar(4000)
Declare @sWhereFilter			nvarchar(4000) 	-- the SQL to filter (To store the output "Where" )

-- The SQL used by the pr_ListPriorArt stored procedure
Declare @nCount				int	 	-- Current table row being processed.
Declare @sPriorArtSelect		nvarchar(max)
Declare @sPriorArtFrom			nvarchar(max)
--Declare @sWIPCaseWhere		nvarchar(4000)	-- Used for the Case derived table.
Declare @sPriorArtWhere			nvarchar(max)	-- Used for the outer Select statment.
Declare @sPriorArtGroupBy		nvarchar(4000)
Declare @sPriorArtHaving		nvarchar(4000)
Declare @sPriorArtOrderBy		nvarchar(4000)

Declare @sCountSelect			nvarchar(4000)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare	@sTopSelectList1		nvarchar(4000)	-- the SQL list of columns to return modified for paging

-- @tblOutputRequests table variable is used to load the OutputRequests parameters 
Declare @tblOutputRequests 	table 
			 	(	ROWNUMBER	int 		not null,
		    			ID		nvarchar(100)	collate database_default not null,
		    			SORTORDER	tinyint		null,
		    			SORTDIRECTION	nvarchar(1)	collate database_default null,
					PUBLISHNAME	nvarchar(100)	collate database_default null,
					QUALIFIER	nvarchar(100)	collate database_default null,				
					DOCITEMKEY	int		null,
					PROCEDURENAME	nvarchar(50)	collate database_default null,
					ISAGGREGATE	bit		null,
					DATAFORMATID    int 		null
			 	)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
Declare @tbOrderBy 	table (
					Position	tinyint		not null,
					Direction	nvarchar(5)	collate database_default not null,
					ColumnName	nvarchar(1000)	collate database_default not null,
					PublishName	nvarchar(50)	collate database_default null,
					ColumnNumber	tinyint		not null
				)
-- SQA9664
-- Create a temporary table to be used in the construction of the SELECT.
Create table #TempConstructSQL 	       
				(
					Position	smallint	identity(1,1),
					ComponentType	char(1)		collate database_default,
					SavedString	nvarchar(4000) 	collate database_default 
				 )
Declare @sCurrentCaseTable 		nvarchar(60)	
Declare @sCurrentPriorArtTable		nvarchar(60)
Declare @sStoredProcedure		nvarchar(max)

Declare @nOutRequestsRowCount		int
Declare @sCaseXMLOutputRequests		nvarchar(4000)	-- The XML Output Requests prepared for the case search procedure.

Declare @nTableCount			tinyint
Declare @nNumberOfBrakets		tinyint
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sPublishNameForXML		nvarchar(50)	-- Publish name with such characters as '.' and ' ' removed.
Declare @sQualifier			nvarchar(50)
Declare @sProcedureName			nvarchar(50)
Declare @sCorrelationSuffix		nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @bIsAggregate			bit
Declare @nDataFormatID			int
Declare @sTableColumn			nvarchar(1000)
Declare	@bExternalUser			bit
Declare @bNeedGroupBy			bit		-- Set to 1 when the 'group by' clause is required

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.	

-- Some filters that will also impact
-- the data returned in the result
Declare @sCaseReference			nvarchar(60)
Declare	@nCaseReferenceOperator		tinyint
Declare	@sFamilyKey	 		nvarchar(20)	
Declare	@nFamilyKeyOperator		tinyint		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

Set 	@nErrorCode			= 0
Set     @nCount				= 1
Set	@nNumberOfBrakets		= 0
Set     @bNeedGroupBy			= 0
Set	@sWhereFilter			= 'Where 1=1'
Set     @sCaseXMLOutputRequests 	= '<?xml version="1.0"?>'
				  	+char(10)+'	<OutputRequests>'
					
-- Initialise the 'From' and the 'Where' clauses
Set     @sPriorArtFrom			= 'from SEARCHRESULTS S'+char(10)+
					  'left join REPORTCITATIONS R on (R.CITEDPRIORARTID=S.PRIORARTID'+char(10)+
					  '                            and S.ISSOURCEDOCUMENT=0)'+char(10)+
					  'join SEARCHRESULTS SD       on (SD.PRIORARTID=isnull(R.SEARCHREPORTID, S.PRIORARTID))'

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString='
	Select	@bExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId'

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bExternalUser	bit	OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser=@bExternalUser	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId
End
/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE SELECT LIST    ****/
/****    AND GROUP BY CLAUSE		    ****/
/****                                       ****/
/***********************************************/

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID
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
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, null)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE, DATAFORMATID 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)	
End

-- Is 'group by' clause required?  
If  @nErrorCode=0
and (PATINDEX ('%<AggregateFilterCriteria>%', @ptXMLFilterCriteria)>0
 or  exists(Select 1 from @tblOutputRequests where ISAGGREGATE = 1))
Begin
	Set @bNeedGroupBy = 1
End

-- Is COUNT(*) coumn required to avoide an SQL error?
If  @nErrorCode=0
and @bNeedGroupBy = 1
and not exists(Select 1 from @tblOutputRequests where ISAGGREGATE = 1)
Begin
	insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, ISAGGREGATE)
	select isnull(max(ROWNUMBER),0)+1, 'Count', null, null, 'Count', null, null, 'pr_ListPriorArt', 1
	from @tblOutputRequests
End

-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
-- while constructing the "Select" list   
If @nErrorCode=0
Begin
	Set @nOutRequestsRowCount = (Select count(*) from @tblOutputRequests)

	-- Reset the @nCount.
	Set @nCount = 1
End

-------------------------------------------------------
-- If there are any Case related columns to be reported
-- then check the provided filter to see if the Cases 
-- to actually be returned are also to be filtered.
-------------------------------------------------------

If @nErrorCode=0
and exists(	Select	1
		from	@tblOutputRequests
		where	ID in ( 'CaseFamily',
				'CaseCountry',
				'CaseOfficialNumber',
				'CasePriorArtStatus',
				'CaseReference',
				'CaseStatusDescription',
				'CaseStatusSummary',
				'CaseStatusExternal') )
Begin
	-----------------------------------------------------
	-- Create an XML document in memory and then retrieve 
	-- the information  from the rowset using OPENXML
	-----------------------------------------------------
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	if exists(Select 1 from OPENXML (@idoc, '//pr_ListPriorArt', 2))
	Begin
		Set @sStoredProcedure = 'pr_ListPriorArt'
	End


	If @nErrorCode = 0 
	Begin
		-- Retrieve the Filter elements using element-centric mapping
		Set @sSQLString = 
		       "Select @sCaseReference	= CaseReference,
			@nCaseReferenceOperator	= CaseReferenceOperator,  
			@sFamilyKey		= upper(FamilyKey),  
			@nFamilyKeyOperator	= FamilyKeyOperator
		 
			from	OPENXML (@idoc, '/" + @sStoredProcedure + "/FilterCriteria',2)  
			WITH (  
			CaseReference		nvarchar(60)	'Associatedwith/Case/text()',  	
			CaseReferenceOperator	tinyint		'Associatedwith/Case/@Operator/text()',  		
			FamilyKey		nvarchar(20)	'Associatedwith/Family/text()',  
			FamilyKeyOperator	tinyint		'Associatedwith/Family/@Operator/text()'
				     )"
		
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@idoc				int,
					  @sCaseReference		nvarchar(60)			output,
					  @nCaseReferenceOperator	tinyint				output,	
					  @sFamilyKey			nvarchar(20)			output,
					  @nFamilyKeyOperator		tinyint				output',
					  @idoc				= @idoc, 
					  @sCaseReference		= @sCaseReference		output,
					  @nCaseReferenceOperator	= @nCaseReferenceOperator	output,	
					  @sFamilyKey			= @sFamilyKey			output,
					  @nFamilyKeyOperator		= @nFamilyKeyOperator		output
		
		-- deallocate the xml document handle when finished.
		exec sp_xml_removedocument @idoc
		
		If  @nCaseReferenceOperator in (5,6)
		and @sCaseReference is not null
			Set @sCaseReference=null
		
		If  @nFamilyKeyOperator in (5,6)
		and @sFamilyKey is not null
			Set @sFamilyKey=null
	End
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
		@sQualifier		= QUALIFIER,
		@sProcedureName		= PROCEDURENAME,
		@bIsAggregate		= ISAGGREGATE,
		@nDataFormatID		= DATAFORMATID
	from	@tblOutputRequests
	where	ROWNUMBER = @nCount

	-- If a Qualifier exists then generate a value from it that can be used
	-- to create a unique Correlation name for the table

	If  @nErrorCode=0
	and @sQualifier is null
	Begin
		Set @sCorrelationSuffix=NULL
	End
	Else Begin			
		Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)
	End

	If @nErrorCode=0	 
	Begin
		If @sProcedureName = 'pr_ListPriorArt'
		Begin
			----------------------------------
			-- RFC38472 
			-- Report details of Cases related
			-- to the prior art:
			--	CaseFamily
			--	CaseCountry
			--	CaseOfficialNumber
			--	CasePriorArtStatus
			--	CaseReference
			--	CaseStatusDescription
			--	CaseStatusSummary
			--	CaseStatusExternal
			----------------------------------
			If @sColumn in ('CaseFamily',
					'CaseCountry',
					'CaseOfficialNumber',
					'CasePriorArtStatus',
					'CaseReference',
					'CaseStatusDescription',
					'CaseStatusSummary',
					'CaseStatusExternal')
			Begin				
				If charindex('join CASESEARCHRESULT CS',@sPriorArtFrom)=0	
				Begin
					Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join CASESEARCHRESULT CSR on (CSR.PRIORARTID = S.PRIORARTID'
									  +char(10)+'                               and CSR.CASEPRIORARTID=(select min(CSR1.CASEPRIORARTID)'
									  +char(10)+'                                                       from CASESEARCHRESULT CSR1'
									  +char(10)+'                                                       where CSR1.PRIORARTID=CSR.PRIORARTID'
									  +char(10)+'                                                       and   CSR1.CASEID=CSR.CASEID))'
									  +char(10)+'left join CASES CSX            on (CSX.CASEID      = CSR.CASEID)'
						
					If  @nCaseReferenceOperator is not null
						Set @sWhereFilter=@sWhereFilter +char(10)+'and CSX.IRN '+ dbo.fn_ConstructOperator(@nCaseReferenceOperator,@String, @sCaseReference,null,@pbCalledFromCentura)
									  
					If  @nFamilyKeyOperator is not null
						Set @sWhereFilter=@sWhereFilter +char(10)+'and CSX.FAMILY '+ dbo.fn_ConstructOperator(@nFamilyKeyOperator,@String, @sFamilyKey,null,@pbCalledFromCentura)
				End	
				
				If @sColumn = 'CaseFamily'
				Begin
					Set @sTableColumn='CSX.FAMILY' 
				End
				Else If @sColumn = 'CaseOfficialNumber'
				Begin
					Set @sTableColumn='CSX.CURRENTOFFICIALNO'
				End
				Else If @sColumn = 'CaseReference'
				Begin
					Set @sTableColumn='CSX.IRN'
				End
				Else If @sColumn = 'CasePriorArtStatus'
				Begin			
					If charindex('left join TABLECODES TC',@sPriorArtFrom)=0	
					Begin
						Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join TABLECODES TC on (TC.TABLECODE = CSR.STATUS)'
					End	
					
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
				End
				Else If @sColumn = 'CaseCountry'
				Begin			
					If charindex('left join COUNTRY CN',@sPriorArtFrom)=0	
					Begin
						Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join COUNTRY CN on (CN.COUNTRYCODE = CSX.COUNTRYCODE)'
					End	
					
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CN',@sLookupCulture,@pbCalledFromCentura)
				End
				Else If @sColumn in ('CaseStatusDescription','CaseStatusExternal')
				Begin			
					If charindex('left join STATUS ST',@sPriorArtFrom)=0	
					Begin
						Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join STATUS ST on (ST.STATUSCODE = CSX.STATUSCODE)'
					End	
					
					If @bExternalUser=1
					or @sColumn='CaseStatusExternal'
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) 
					Else
						Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) 	
				End
				Else If @sColumn in ('CaseStatusSummary')
				Begin			
					If charindex('left join STATUS ST',@sPriorArtFrom)=0	
					Begin
						Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join STATUS ST on (ST.STATUSCODE = CSX.STATUSCODE)'
					End
						
					If charindex('left join PROPERTY P',@sPriorArtFrom)=0	
					Begin
						Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join PROPERTY P     on (P.CASEID = CSX.CASEID)'
										  +char(10)+'left join STATUS RS      on (RS.STATUSCODE=P.RENEWALSTATUS)'
										  +char(10)+'left join TABLECODES TC1 on (TC1.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) Then 7603'
										  +char(10)+'                       		             WHEN(ST.REGISTEREDFLAG=1)            Then 7602'
										  +char(10)+'                       		                                                  Else 7601'
										  +char(10)+'                                           END)'
					End		
					
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura) 
				End
			End
			
			Else If @sColumn='NULL'		
			Begin
				Set @sTableColumn='NULL'
			End

			If @sColumn='Count'		
			Begin
				Set @sTableColumn='COUNT(*)'
			End

			Else If @sColumn='PriorArtKey'
			Begin
				Set @sTableColumn='S.PRIORARTID'
			End

			Else If @sColumn='Abstract'
			Begin
				Set @sTableColumn='S.ABSTRACT'														
			End

			Else If @sColumn='Citation'
			Begin
				Set @sTableColumn='S.CITATION'														
			End
			
			Else If @sColumn='OfficialNo'
			Begin
				Set @sTableColumn='S.OFFICIALNO'														
			End
			
			Else If @sColumn='CountryCode'
			Begin
				Set @sTableColumn='S.COUNTRYCODE'														
			End
			
			Else If @sColumn = 'Country'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)				
				
				If charindex('left join COUNTRY CT',@sPriorArtFrom)=0	
				Begin
					Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join COUNTRY CT on (CT.COUNTRYCODE = isnull(S.COUNTRYCODE,SD.COUNTRYCODE))'
				End	
				
			End
			
			Else If @sColumn='KindCode'
			Begin
				Set @sTableColumn='S.KINDCODE'														
			End
			
			Else If @sColumn='Title'
			Begin
				Set @sTableColumn='S.TITLE'														
			End		
			
			Else If @sColumn='Name'
			Begin
				Set @sTableColumn='S.INVENTORNAME'														
			End
			
			Else If @sColumn='Source'
			Begin
				Set @sTableColumn='isnull(S.SOURCE,SD.SOURCE)'														
			End	
			
			Else If @sColumn='SourceDescription'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TS',@sLookupCulture,@pbCalledFromCentura)	
				If charindex('left join TABLECODES TS',@sPriorArtFrom)=0	
				Begin
					Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join TABLECODES TS on (TS.TABLECODE = isnull(S.SOURCE,SD.SOURCE))'
				End													
			End	
			
			Else If @sColumn='Decription'
			Begin
				Set @sTableColumn='S.DESCRIPTION'														
			End
			
			Else If @sColumn='Comments'
			Begin
				Set @sTableColumn='S.COMMENTS'														
			End	
			
			Else If @sColumn='Publication'
			Begin
				Set @sTableColumn='isnull(S.PUBLICATION,SD.PUBLICATION)'														
			End
			
			Else If @sColumn='IssuingCountryCode'
			Begin
				Set @sTableColumn='isnull(S.ISSUINGCOUNTRY,SD.ISSUINGCOUNTRY)'													
			End
			
			Else If @sColumn = 'IssuingCountry'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C1',@sLookupCulture,@pbCalledFromCentura)				
				
				If charindex('left join COUNTRY C1',@sPriorArtFrom)=0	
				Begin
					Set @sPriorArtFrom=@sPriorArtFrom +char(10)+'left join COUNTRY C1 on (C1.COUNTRYCODE=isnull(S.ISSUINGCOUNTRY,SD.ISSUINGCOUNTRY))'
				End	
				
			End
			
			Else If @sColumn='Classes'
			Begin
				Set @sTableColumn='isnull(S.CLASS,SD.CLASS)'													
			End
			
			Else If @sColumn='SubClasses'
			Begin
				Set @sTableColumn='isnull(S.SUBCLASS,SD.SUBCLASS)'													
			End
			
			Else If @sColumn='IsIPDocument'
			Begin
				Set @sTableColumn='S.PATENTRELATED'													
			End
			
			Else If @sColumn='IssuedDate'
			Begin
				Set @sTableColumn='isnull(S.ISSUEDDATE,SD.ISSUEDDATE)'													
			End
			
			Else If @sColumn='ReceivedDate'
			Begin
				Set @sTableColumn='isnull(S.RECEIVEDDATE,SD.RECEIVEDDATE)'													
			End
			
			Else If @sColumn='ReferencedPages'
			Begin
				Set @sTableColumn='S.REFPAGES'													
			End
			
			Else If @sColumn='PublicationDate'
			Begin
				Set @sTableColumn='S.PUBLICATIONDATE'													
			End
			
			Else If @sColumn='PriorityDate'
			Begin
				Set @sTableColumn='S.PRIORITYDATE'													
			End
			
			Else If @sColumn='GrantedDate'
			Begin
				Set @sTableColumn='S.GRANTEDDATE'													
			End
			
			Else If @sColumn='IsSourceDocument'
			Begin
				Set @sTableColumn='isnull(S.ISSOURCEDOCUMENT,SD.ISSOURCEDOCUMENT)'													
			End

			Else If @sColumn='DiscoverSourceId'
			Begin
				Set @sTableColumn='case when S.IMPORTEDFROM = "DiscoverEvidenceFinder" THEN S.CORRELATIONID ELSE null END'													
			End

			If datalength(@sPublishName)>0
			Begin
				-- Cast the text type columns as nvarchar(4000) if they are used in the 
				-- 'group by' clause:
				If  @nDataFormatID = 9107 
				and @bNeedGroupBy = 1
				Begin
					Set @sTableColumn = 'CAST('+@sTableColumn+' as nvarchar(max))'
				End

				Set @sPriorArtSelect=@sPriorArtSelect+nullif(',', ',' + @sPriorArtSelect)+@sTableColumn+' as ['+@sPublishName+']'					
			End
			Else Begin
				Set @sPublishName=NULL
			End
			

			-- Contruct the 'Group by' clause:
			If  @bIsAggregate <> 1 
			and @sTableColumn <> 'NULL'
			and @bNeedGroupBy = 1
			Begin
				Set @sPriorArtGroupBy=@sPriorArtGroupBy+nullif(',', ',' + @sPriorArtGroupBy)+@sTableColumn				
			End
		End	
		
		--select @sPriorArtGroupBy
		--select 	 @sPriorArtSelect
		
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

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.pr_FilterPriorArt
				@psReturnClause		= @sPriorArtWhere	  	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@pbIsExternalUser	= @bExternalUser,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE ORDER BY       ****/
/****                                       ****/
/***********************************************/

If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sPriorArtOrderBy = 	ISNULL(NULLIF(@sPriorArtOrderBy+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position			

	If @sPriorArtOrderBy is not null
	Begin
		Set @sPriorArtOrderBy = ' Order by ' + @sPriorArtOrderBy
	End

	Set @nErrorCode=@@Error
End

-- Close the <OutputRequest> tag to be able to pass constructed output requests to the List Case procedures.
If @nErrorCode = 0
Begin   
	Set @sCaseXMLOutputRequests = @sCaseXMLOutputRequests + char(10) + '	</OutputRequests>'
End

-- Implement validation to ensure that the @sCaseXMLOutputRequests has not overflown.
If @nErrorCode = 0 
and right(@sCaseXMLOutputRequests, 17) <> '</OutputRequests>'
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP46', 'There are more Case columns selected than the system is able to process. Please reduce the number of columns selected and retry.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End



If  @nErrorCode = 0
Begin
	-- Assemble the constructed SQL clauses:
	Set @sPriorArtSelect 		= 'Select ' 	+ @sPriorArtSelect

	If @sPriorArtGroupBy is not null
	Begin
		Set @sPriorArtGroupBy	= 'Group by ' 	+ @sPriorArtGroupBy
	End
	
	If @sPriorArtWhere is null
	Begin
		Set @sPriorArtWhere	=  char(10)+@sWhereFilter
	End
	Else Begin
		Set @sPriorArtWhere	=  char(10)+@sWhereFilter+char(10)+
					   'and exists'+char(10)+
					   '(Select 1'+char(10)+
					   ' from (SELECT ''1'' AS Dummy) X'+char(10)+
					   @sPriorArtWhere+char(10)+')'
	End
End

-- Assemble and execute the constructed SQL to return the result set
If  @nErrorCode = 0
-- No paging required
and (@pnPageStartRow is null or
     @pnPageEndRow is null or
     @sPriorArtGroupBy is not null)
Begin  		
	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:			
		Print 'SET ANSI_NULLS OFF ' 
		Print @sPriorArtSelect
		Print @sPriorArtFrom
		Print @sPriorArtWhere	
		Print @sPriorArtGroupBy	
		Print @sPriorArtHaving
		Print @sPriorArtOrderBy		
	End

	-- execute the constructed SQL:
	exec (	'SET ANSI_NULLS OFF ' + @sPriorArtSelect + @sPriorArtFrom + @sPriorArtWhere +
		@sPriorArtGroupBy + @sPriorArtHaving + @sPriorArtOrderBy)

	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT

End
-- Paging required
Else If @nErrorCode = 0
Begin 
	Set @sTopSelectList1 = replace(@sPriorArtSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')
	Set @sCountSelect = ' Select count(*) as SearchSetTotalRows '  		

	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:			
		Print 'SET ANSI_NULLS OFF ' 
		Print @sTopSelectList1
		Print @sPriorArtFrom
		Print @sPriorArtWhere	
		Print @sPriorArtGroupBy	
		Print @sPriorArtHaving
		Print @sPriorArtOrderBy		

		Print 'SET ANSI_NULLS OFF ' +  @sCountSelect+
		@sPriorArtFrom + @sPriorArtWhere +		
		@sPriorArtGroupBy + @sPriorArtHaving
	End

	-- execute the constructed SQL:
	exec (	'SET ANSI_NULLS OFF ' + @sTopSelectList1 + @sPriorArtFrom + @sPriorArtWhere +			
		@sPriorArtGroupBy + @sPriorArtHaving + @sPriorArtOrderBy)

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
		exec (	'SET ANSI_NULLS OFF ' +  @sCountSelect+
		@sPriorArtFrom + @sPriorArtWhere +	
		@sPriorArtGroupBy + @sPriorArtHaving )
		
		Set @nErrorCode =@@ERROR
	End
End

-- Now drop the temporary table holding Cases :
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentCaseTable)
and @nErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentCaseTable

	exec @nErrorCode=sp_executesql @sSql
End

-- Now drop the temporary table holding the Prior Art results:
If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentPriorArtTable)
and @nErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentPriorArtTable
		
	exec @nErrorCode=sp_executesql @sSql
End

RETURN @nErrorCode
GO

Grant execute on dbo.pr_ListPriorArt  to public
GO

