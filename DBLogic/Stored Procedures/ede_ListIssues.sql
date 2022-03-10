-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ListIssues
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ede_ListIssues]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ede_ListIssues.'
	drop procedure dbo.ede_ListIssues
end
print '**** Creating procedure dbo.ede_ListIssues...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF
GO

CREATE  PROCEDURE dbo.ede_ListIssues
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 999,	-- The key for the context of the query (default output requests).	
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit		= 0,
	@pnCallingLevel			smallint	= null,	-- Optional number that acknowledges multiple calls of 
								-- the stored procedure from the one connection and
								-- ensures there is not temporary table conflict
	@pbGenerateReportCriteria 	bit 		= 0	-- When set to 1, the report criteria is to be generated based on the input filter criteria. 

)	
AS
-- PROCEDURE :	ede_ListIssues
-- VERSION :	15
-- DESCRIPTION:	Returns the requested information, for EDE issues that matches the filter criteria provided.  
--		
-- Date		Who	Number		Version	Change
-- ------------	-------	--------	-------	-------------------------------------------------------
-- 26 Sep 2006  IB	SQA12300	1	Procedure created
-- 26 Oct 2006  IB	SQA12300	2	Added Next Renewal Date and Transaction Status columns. 
-- 02 Nov 2006  IB	SQA12300	3	Added ETB.BATCHNO = ECM.BATCHNO join condition.
-- 04 Dec 2006  IB	SQA13285	4	Allowed searching for live cases with issues.
--						Added Transaction Identifier and Session Number columns.
--			SQA13908		Changed how the Data Instructor is retrieved.
-- 01 Feb 2007  IB	SQA13285	5	Removed Session Number column.
--						Added Session Id and Session Date columns.
-- 28 Feb 2007	PY	SQA14425 	6 	Reserved word [cycle]
-- 19 Mar 2007  IB	SQA14553	7	Modified the statement that returns Data Instructor to ensure
--						that only one Data Instructor per case is returned.
-- 24 Apr 2007	KR	SQA14201	8	Added supervisor date and status columns to the select statement
--						fixed bug with the batchid.
-- 14 Jun 2007  IB	SQA14866	9	Restrict selecting draft case to a particular batch if one is specified.
-- 30 Aug 2007	DL	SQA15294	10	Bug fix to handle subselect returns multiple rows.
-- 12 Jun 2008	KR	SQA16528	11	Bug fix to display correct batch identifier.
-- 11 Dec 2008	MF	17136		12	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 05 Aug 2009	MF	SQA17917	13	Improve performance and lower locking level.
-- 13 Jul 2011	DL	RFC10830	14	Specify collation default in temp table.
-- 02 Nov 2015	vql	R53910		15	Adjust formatted names logic (DR-15543).


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	CaseKey

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added

--	CaseKey
--	CaseReference
--	CountryName
--	DisplayName
--	IssueCount
--	MatchLevel
-- 	MatchLevelKey
--	PropertyTypeDescription
--	NextRenewalDate
--	BatchIdentifier
--	TransactionIdentifier
--	TransactionStatus
--	SessionId
--	SessionDate
--	Approved Date
--	Approval Status

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	C
--	CE
--	CN
--	CO
--	ECM
--	ESD
--	ERT
--	ETB
--	N
--	OA
--	S
--	TCML
--	TCTS
--	VP

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

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

Declare	@nErrorCode		int
Declare @sAlertXML	 	nvarchar(400)

Declare @sSql			nvarchar(4000)
Declare @sSQLString		nvarchar(4000)

Declare @nCount			int	 	-- Current table row being processed.
Declare @sIssuesSelect		nvarchar(4000)
Declare @sIssuesFrom		nvarchar(4000)
Declare @sIssuesWhereFilter	nvarchar(4000)	
Declare @sIssuesWhere		nvarchar(4000)
Declare @sIssuesOrderBy		nvarchar(4000)

Declare @sGroupBy		nvarchar(4000)	
Declare @sUnionSelect		nvarchar(4000) 
Declare @sUnionFrom		nvarchar(4000) 
Declare @sUnionWhere		nvarchar(4000)  
Declare @sUnionFilter		nvarchar(4000) 
Declare @sUnionGroupBy		nvarchar(4000) 
Declare @sReportCriteria	nvarchar(4000)

declare @sNameTableAlias	nvarchar(25)
declare @sCaseNameTableAlias	nvarchar(25)

Declare @sCurrentCaseTable 		nvarchar(60)	

Declare @nOutRequestsRowCount		int
Declare @sCaseXMLOutputRequests		nvarchar(4000)	-- The XML Output Requests prepared for the case search procedure.

Declare @nTableCount			tinyint
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sPublishNameForXML		nvarchar(50)	-- Publish name with such characters as '.' and ' ' removed.
Declare @sQualifier			nvarchar(50)
Declare @sProcedureName			nvarchar(50)
Declare @sCorrelationSuffix		nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @nDataFormatID			int
Declare @sTableColumn			nvarchar(1000)
Declare @sNameType			nvarchar(200)
Declare @sAction			nvarchar(3)
Declare	@bExternalUser			bit

Declare @sLookupCulture			nvarchar(10)
Declare @sBatchKey 			nvarchar(254)		

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
	
Set 	@nErrorCode			= 0
Set     @nCount				= 1
Set     @sCaseXMLOutputRequests 	= '<?xml version="1.0"?>'
				  	+char(10)+'	<OutputRequests>'

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Retrieve BatchKey if it is provided
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria
Set @nErrorCode = @@ERROR

If @nErrorCode = 0 
Begin	
	-- Retrieve the BatchKey element using element-centric mapping
	Set @sSQLString = 	
	"Select @sBatchKey	= BatchKey"+CHAR(10)+
	"from	OPENXML (@idoc, '/ede_ListIssues/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      BatchKey 	nvarchar(254)	'Batch/BatchKey/text()'"+CHAR(10)+
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc		int,
				  @sBatchKey 	nvarchar(254)	output',
				  @idoc		= @idoc,
				  @sBatchKey 	= @sBatchKey	output		

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc		  
End
	
If @nErrorCode = 0 
Begin					
	-- Initialise the 'From' clause
	If @sBatchKey != null
	Begin
		Set     @sIssuesFrom	= +char(10)+'from CASES C (NOLOCK)'
					  +char(10)+'left join EDECASEMATCH ECM (NOLOCK) on (ECM.DRAFTCASEID = C.CASEID'
					  +char(10)+'		and ECM.BATCHNO in (Select ESD.BATCHNO'
					  +char(10)+'				   from EDESENDERDETAILS ESD (NOLOCK)'
					  +char(10)+'				   where ESD.SENDERREQUESTIDENTIFIER = ' + "'" + @sBatchKey + "'" + '))'
	End
	Else
	Begin
		Set     @sIssuesFrom	= +char(10)+'from CASES C (NOLOCK)'
					  +char(10)+'left join EDECASEMATCH ECM (NOLOCK) on (ECM.DRAFTCASEID = C.CASEID)'
	End
End

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
/****    				    ****/
/****                                       ****/
/***********************************************/

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID
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

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY, PROCEDURENAME, DATAFORMATID 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)	
End

-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
-- while constructing the "Select" list   
If @nErrorCode=0
Begin
	Set @nOutRequestsRowCount = (Select count(*) from @tblOutputRequests)

	-- Reset the @nCount.
	Set @nCount = 1
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
		If @sProcedureName in ('ede_ListIssues', 'ede_ListIssues')
		Begin
			--Initialise variable
			Set @sTableColumn='NULL'

			If @sColumn='NULL'		
			Begin
				Set @sTableColumn='NULL'
			End
			
			Else If @sColumn='CaseKey'
			Begin
				Set @sTableColumn='C.CASEID'

				/*If charindex('join CASES C',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'join CASES C on (C.CASEID = ECM.DRAFTCASEID)'
				End*/			
			End

			Else If @sColumn='MatchLevelKey'
			Begin
				Set @sTableColumn='ECM.MATCHLEVEL'
			End	
	
			Else If @sColumn='CaseReference'
			Begin
				Set @sTableColumn='C.IRN'
			End
	
			Else If @sColumn='IssueCount'
			Begin
				Set @sTableColumn='(Select Count(0) from EDEOUTSTANDINGISSUES EOI where EOI.CASEID = C.CASEID)'
			End
	
			Else If @sColumn='MatchLevel'
			Begin
				Set @sTableColumn='TCML.[DESCRIPTION]'

				If charindex('left join TABLECODES TCML (NOLOCK)',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join TABLECODES TCML (NOLOCK) on (TCML.TABLECODE = ECM.MATCHLEVEL and TCML.TABLETYPE = 132)'
				End				
			End
	
			Else If @sColumn='PropertyTypeDescription'
			Begin
				Set @sTableColumn='VP.PROPERTYNAME'

				If charindex('join VALIDPROPERTY VP',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+
						'join VALIDPROPERTY VP (NOLOCK) on (VP.PROPERTYTYPE = C.PROPERTYTYPE'+char(10)+
						'                               and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)'+char(10)+
						'                                                     from VALIDPROPERTY VP1 (NOLOCK)'+char(10)+
						'                                                     where VP1.PROPERTYTYPE=C.PROPERTYTYPE'+char(10)+
						'                                                     and   VP1.COUNTRYCODE in (C.COUNTRYCODE, ''ZZZ'')))'
				End				
			End
	
			Else If @sColumn='CountryName'
			Begin
				Set @sTableColumn='CO.COUNTRY'

				If charindex('join COUNTRY CO (NOLOCK)',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'join COUNTRY CO on (CO.COUNTRYCODE = C.COUNTRYCODE)'
				End				
			End
	
			Else If @sColumn='DisplayName' 
		     		and upper(@sQualifier) <> 'DI'
		     		and @sQualifier is not NULL
			Begin
				Set @sNameTableAlias 		= 'N' + @sCorrelationSuffix
				Set @sCaseNameTableAlias 	= 'CN' + @sCorrelationSuffix
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sNameTableAlias+'.NAMENO, NULL)'

				If charindex('left join CASENAME ' + @sCaseNameTableAlias,@sIssuesFrom)=0	
				Begin
					-- Check if the user is allowed access to the NameType passed as a parameter					
					Set @sSQLString="
					select @sNameType=NAMETYPE
					from dbo.fn_FilterUserNameTypes(@pnUserIdentityId,default,@bExternalUser,default)
					where NAMETYPE=@sQualifier"
					
					exec @nErrorCode=sp_executesql @sSQLString,
								N'@sNameType		nvarchar(200)	OUTPUT,
								  @sQualifier		nvarchar(50),
								  @pnUserIdentityId	int,
								  @bExternalUser	bit',
								  @sNameType		=@sNameType	OUTPUT,
								  @sQualifier		=@sQualifier,
								  @pnUserIdentityId	=@pnUserIdentityId,
								  @bExternalUser	=@bExternalUser
										
					If @sNameType is not NULL
						Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join CASENAME '+@sCaseNameTableAlias + ' (NOLOCK) on (' + @sCaseNameTableAlias + '.CASEID = C.CASEID '
						+char(10)+'			and '+@sCaseNameTableAlias+'.NAMETYPE = ' + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura) + 
						+char(10)+'			and('+@sCaseNameTableAlias+'.EXPIRYDATE is null or ' + @sCaseNameTableAlias + '.EXPIRYDATE>getdate())'
						+char(10)+'			and '+@sCaseNameTableAlias+'.SEQUENCE=(select min(SEQUENCE) from CASENAME CN (NOLOCK)'
						+char(10)+'			                    where CN.CASEID=C.CASEID'
						+char(10)+'			                    and CN.NAMETYPE=' + dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)
						+char(10)+'			                    and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))'
					Else
						Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join CASENAME '+@sCaseNameTableAlias + ' (NOLOCK) on (1=0)'	-- User does not have access to the Name Type
						
					Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join NAME ' + @sNameTableAlias + ' (NOLOCK) on (' + @sNameTableAlias + '.NAMENO = ' + @sCaseNameTableAlias + '.NAMENO)'
				End		

			End
	
			Else If @sColumn='DisplayName' 
		     		and upper(@sQualifier) = 'DI'
			Begin
				Set @sNameTableAlias 		= 'N' + @sCorrelationSuffix
				Set @sCaseNameTableAlias 	= 'CN' + @sCorrelationSuffix
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sNameTableAlias+'.NAMENO, NULL)'

				If charindex('left join EDESENDERDETAILS ESD',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join EDESENDERDETAILS ESD (NOLOCK) on (ESD.BATCHNO = ECM.BATCHNO)'
				End

				If charindex('left join EDEREQUESTTYPE ERT',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join EDEREQUESTTYPE ERT (NOLOCK) on ' + 
						'(ERT.REQUESTTYPECODE = isnull(ESD.SENDERREQUESTTYPE, ' + dbo.fn_WrapQuotes('Data Input',0,@pbCalledFromCentura) +'))'
				End
	
				If charindex('left join CASENAME ' + @sCaseNameTableAlias,@sIssuesFrom)=0	
				Begin
					-- Check if the user is allowed access to the NameType passed as a parameter					
					Set @sSQLString="
					select @sNameType=NAMETYPE
					from dbo.fn_FilterUserNameTypes(@pnUserIdentityId,default,@bExternalUser,default)
					where NAMETYPE=@sQualifier"
					
					exec @nErrorCode=sp_executesql @sSQLString,
								N'@sNameType		nvarchar(200)	OUTPUT,
								  @sQualifier		nvarchar(50),
								  @pnUserIdentityId	int,
								  @bExternalUser	bit',
								  @sNameType		=@sNameType	OUTPUT,
								  @sQualifier		=@sQualifier,
								  @pnUserIdentityId	=@pnUserIdentityId,
								  @bExternalUser	=@bExternalUser
			/*****************							
					If @sNameType is not NULL
						Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join CASENAME '+@sCaseNameTableAlias + ' (NOLOCK) on (' + @sCaseNameTableAlias + '.CASEID = C.CASEID '
						+char(10)+'			and '+@sCaseNameTableAlias+'.NAMETYPE = ERT.REQUESTORNAMETYPE' + 
						+char(10)+'			and('+@sCaseNameTableAlias+'.EXPIRYDATE is null or ' + @sCaseNameTableAlias + '.EXPIRYDATE>getdate())'
						+char(10)+'                     and '+@sCaseNameTableAlias+'.NAMENO=convert(int,substring('
						+char(10)+'							(select min(convert(char(11),CN.SEQUENCE)'
						+char(10)+'								+convert(char(11),CN.NAMENO))'  
						+char(10)+'							 from CASENAME CN (NOLOCK)'
						+char(10)+'                    		                         where CN.CASEID=C.CASEID'
						+char(10)+'             					 and CN.NAMETYPE=ERT.REQUESTORNAMETYPE'
						+char(10)+'               					 and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())),12,11)))'
			*****************/							
					If @sNameType is not NULL
						Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join CASENAME '+@sCaseNameTableAlias + ' (NOLOCK) on (' + @sCaseNameTableAlias + '.CASEID = C.CASEID '
						+char(10)+'			and '+@sCaseNameTableAlias+'.NAMETYPE = ERT.REQUESTORNAMETYPE' + 
						+char(10)+'			and('+@sCaseNameTableAlias+'.EXPIRYDATE is null or ' + @sCaseNameTableAlias + '.EXPIRYDATE>getdate())'
						+char(10)+'			and '+@sCaseNameTableAlias+'.SEQUENCE='
						+char(10)+'					(select min(CN.SEQUENCE)' 
						+char(10)+'					 from CASENAME CN (NOLOCK)'
						+char(10)+'					 where CN.CASEID=C.CASEID'
						+char(10)+'					 and CN.NAMETYPE=ERT.REQUESTORNAMETYPE'
						+char(10)+'					 and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))'
					Else
						Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join CASENAME '+@sCaseNameTableAlias + ' (NOLOCK) on (1=0)' -- User does not have access to NameType
						
					Set @sIssuesFrom=@sIssuesFrom 
						+char(10)+'left join NAME ' + @sNameTableAlias + ' (NOLOCK) on (' + @sNameTableAlias + '.NAMENO = ' + @sCaseNameTableAlias + '.NAMENO)'
				/*
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join CASENAME ' + @sCaseNameTableAlias + ' on ' +
						'(' + @sCaseNameTableAlias + '.CASEID = C.CASEID and 
						' + @sCaseNameTableAlias + '.NAMETYPE = ERT.REQUESTORNAMETYPE)'
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join NAME ' + @sNameTableAlias + ' on ' +
						'(' + @sNameTableAlias + '.NAMENO = ' + @sCaseNameTableAlias + '.NAMENO)'*/
				End		
			End
	
			Else If @sColumn='BatchIdentifier'
			/*Begin
				Set @sTableColumn='ECM.BATCHNO'
			End */
			Begin
				Set @sTableColumn='ESD.SENDERREQUESTIDENTIFIER'

				If charindex('left join EDESENDERDETAILS ESD',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join EDESENDERDETAILS ESD (NOLOCK) on (ESD.BATCHNO = ECM.BATCHNO)'
				End	
			End
	
			Else If @sColumn='TransactionIdentifier'
			Begin
				Set @sTableColumn='ECM.TRANSACTIONIDENTIFIER'
			End
	
			Else If @sColumn='SessionId'
			Begin
				Set @sTableColumn='S.SESSIONIDENTIFIER'

				If charindex('left join SESSION S',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join SESSION S (NOLOCK) on (S.SESSIONNO = ECM.SESSIONNO)'
				End	
			End
	
			Else If @sColumn='SessionDate'
			Begin
				Set @sTableColumn='S.STARTDATE'

				If charindex('left join SESSION S',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join SESSION S (NOLOCK) on (S.SESSIONNO = ECM.SESSIONNO)'
				End	
			End

			Else If @sColumn='NextRenewalDate'
			Begin
				Set @sTableColumn='isnull(CE.EVENTDATE, CE.EVENTDUEDATE)'

				If charindex('left join (select min(O.CYCLE) as [CYCLE], O.CASEID',@sIssuesFrom)=0	
				Begin
					Set @sSQLString="
					Select @sAction=COLCHARACTER
					from SITECONTROL
					where CONTROLID='Main Renewal Action'"
					
					exec @nErrorCode=sp_executesql @sSQLString,
								N'@sAction	nvarchar(3)	OUTPUT',
								  @sAction	=@sAction	OUTPUT
					If @sAction is not NULL
						Set @sIssuesFrom=@sIssuesFrom +char(10)+
						"left join (select min(O.CYCLE) as [CYCLE], O.CASEID"+char(10)+
						"           from OPENACTION O (NOLOCK)"+char(10)+
						"           where O.ACTION='"+@sAction+"'"+char(10)+
						"           and O.POLICEEVENTS=1"+char(10)+
						"           group by O.CASEID) OA on (OA.CASEID=C.CASEID)"+char(10)+
						"left join CASEEVENT CE (NOLOCK) on (CE.CASEID = OA.CASEID"+char(10)+
						"                                and CE.EVENTNO = -11"+char(10)+
						"                                and CE.CYCLE=OA.CYCLE)"
					Else
						Set  @sIssuesFrom=@sIssuesFrom +char(10)+
						"left join CASEEVENT CE (NOLOCK) on (1=0)"  -- No Action to identify Next Renewal Date cycle
				End	
			End
	
			Else If @sColumn='TransactionStatus'
			Begin
				Set @sTableColumn='TCTS.[DESCRIPTION]'

				If charindex('left join EDETRANSACTIONBODY ETB',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join EDETRANSACTIONBODY ETB (NOLOCK) on (ETB.BATCHNO = ECM.BATCHNO'
								      +char(10)+'			          and ETB.TRANSACTIONIDENTIFIER = ECM.TRANSACTIONIDENTIFIER)'
				End	

				If charindex('left join TABLECODES TCTS',@sIssuesFrom)=0	
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+'left join TABLECODES TCTS (NOLOCK) on (TCTS.TABLECODE = ETB.TRANSSTATUSCODE)'
				End	
			End
			
			Else If @sColumn='ApprovedDate'
			Begin
				Set @sTableColumn='ECM.SUPERVISORDATE'	
			End

			Else If @sColumn='ApprovalStatus'
			Begin
				Set @sTableColumn="CASE WHEN DATEDIFF(Hour,ECM.SUPERVISORDATE,getdate())> SC1.COLINTEGER THEN 'Overdue' END"
				
				If charindex('join SITECONTROL SC1',@sIssuesFrom)=0
				Begin
					Set @sIssuesFrom=@sIssuesFrom +char(10)+
						"join SITECONTROL SC1 (NOLOCK) on (SC1.CONTROLID='Supervisor Approval Overdue')"
				End
			End

			-- If the column is being published then concatenate it to the Select list
			If datalength(@sPublishName)>0 and @sTableColumn!='NULL'
			Begin
				Set @sIssuesSelect=@sIssuesSelect+nullif(',', ',' + @sIssuesSelect)+@sTableColumn+' as ['+@sPublishName+']'					
			End
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

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

If   @nErrorCode=0
and (datalength(@ptXMLFilterCriteria) <> 0
or   datalength(@ptXMLFilterCriteria) is not null)
Begin
	exec @nErrorCode=dbo.ede_ConstructIssuesWhere
				@psIssuesWhere		= @sIssuesWhere	  	OUTPUT, 
				@psCurrentCaseTable	= @sCurrentCaseTable 	OUTPUT,	
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,		
				@pbIsExternalUser	= @bExternalUser,	
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,	
				@pbCalledFromCentura	= @pbCalledFromCentura	
	
	If @sIssuesWhere is not null
	Begin
		Set @sIssuesWhere = char(10) + 'where exists (Select C2.CASEID' + char(10) +
					@sIssuesWhere	+ char(10) + 'and C2.CASEID = C.CASEID)'
	End
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
	Select @sIssuesOrderBy= 	ISNULL(NULLIF(@sIssuesOrderBy+',', ','),'')			
			  	+CASE WHEN(PublishName is null) 
			       	      THEN ColumnName
			       	      ELSE '['+PublishName+']'
			  	END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position			

	If @sIssuesOrderBy is not null
	Begin
		Set @sIssuesOrderBy = char(10) + 'Order by ' + @sIssuesOrderBy
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
	Set @sAlertXML = dbo.fn_GetAlertXML('IP46', 'There are more columns selected than the system is able to process. Please reduce the number of columns selected and retry.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

-- Now get the constructed SQL to return the result set
If @pbCalledFromCentura=1
and @nErrorCode=0
Begin
	-- Now return values to the calling program
	If @nErrorCode=0
	Begin
		Set	@sIssuesSelect		= 'Select ' + @sIssuesSelect
		
		-- SQA11472 Added ReportCriteria
		Select 	@sIssuesSelect  	as [SelectList], 
			@sIssuesFrom 		as [FromClause], 
			@sIssuesWhere 		as [WhereClause], 
			@sIssuesWhereFilter 	as [WhereFilter], 
			@sGroupBy 		as [GroupBy], 
			@sIssuesOrderBy 	as [OrderBy],
		       	@sUnionSelect 		as [UnionSelect], 
			@sUnionFrom 		as [UnionFrom], 
			@sUnionWhere 		as [UnionWhere],  
			@sUnionFilter 		as [UnionFilter], 
			@sUnionGroupBy 		as [UnionGroupBy], 
			@sReportCriteria 	as [ReportCriteria]

		Select	@nErrorCode=@@Error,
			@pnRowCount=@@RowCount
	End
End

-- Now drop the temporary table holding Cases :
If @pbCalledFromCentura=0
and exists(select * from tempdb.dbo.sysobjects where name = @sCurrentCaseTable)
and @nErrorCode=0
Begin
	Set @sSql = "drop table "+@sCurrentCaseTable

	exec @nErrorCode=sp_executesql @sSql
End

RETURN @nErrorCode
go

grant execute on dbo.ede_ListIssues  to public
go

