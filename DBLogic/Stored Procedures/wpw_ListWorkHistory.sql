-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wpw_ListWorkHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[wpw_ListWorkHistory]') 
and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop Stored Procedure  dbo.wpw_ListWorkHistory.'
	drop procedure dbo.wpw_ListWorkHistory
End
print '**** Creating Stored Procedure dbo.wpw_ListWorkHistory...'
print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wpw_ListWorkHistory
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
-- PROCEDURE :	wpw_ListWorkHistory
-- VERSION :	13
-- DESCRIPTION:	Search for and return Work History.
-- CALLED BY :	WorkBenches

-- MODIFICTIONS :
-- Date		Who	Number		Version	Change
-- ------------	-------	------		-------	----------------------------------------------- 
-- 01 Apr 2008	AT	RFC7440		1	Procedure created.
-- 25 May 2008	AT	RFC7440		2	Fixed join on generated where clause.
-- 04 May 2011  DV      RFC10564	3	Fixed issue where Narrative text was not showing.
-- 07 Jul 2011	DL	RFC10830	4	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 18 Oct 2011	AT	RFC9012		5	Add TransKey and WIPSeqKey implied columns
-- 22 Oct 2013	vql	R26273		6	Return allocated debtor details
-- 16 Mar 2015	vql	R28901		7	Return Timesheet Notes
-- 23 Apr 2015	MS	R46603	        8	Set size of variables for case filter to nvarchar(max)
-- 02 Nov 2015	vql	R53910		9	Adjust formatted names logic (DR-15543).
-- 24 May 2016	LP	R59710		10	Display Hours as negative is Work History has been adjusted down.
-- 18 Jul 2016	MF	27719		11	Add new reportable columns WIPCode, Invoice No
-- 24 Jan 2018	vql	R73158		12	Reason not being displayed for adjustment row associated with edited posted time (DR-37510).
-- 25 Jan 2018	vql	R72091		13	Chargeable time discounts are not displayed in Work History search results (DR-33438).

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

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
Declare @tbOrderBy table (
				Position	tinyint		not null,
				Direction	nvarchar(5)	collate database_default not null,
				ColumnName	nvarchar(1000)	collate database_default not null,
				PublishName	nvarchar(50)	collate database_default null,
				ColumnNumber	tinyint		not null
			)

Declare @nOutRequestsRowCount		int
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sQualifier			nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @sTableColumn			nvarchar(1000)
Declare @sComma				nchar(2)	-- initialised when a column has been added to the Select.

Declare @idoc 				int 	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument

Declare @sSQLString			nvarchar(max)
Declare @sLookupCulture			nvarchar(10)
Declare @sProcedureName			nvarchar(50)
Declare @bIsAggregate			bit
Declare @sCorrelationSuffix		nvarchar(50)
Declare @nDataFormatID			int

Declare @sCurrentCaseTable		nvarchar(60)

Declare @nCount				int		-- Current table row being processed.
Declare @sSelect			nvarchar(max)
Declare @sFrom				nvarchar(max)
Declare @sWhere				nvarchar(max)
Declare @sOrder				nvarchar(4000)

-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

-- Additional Variables
Declare @sLocalCurrencyCode		nvarchar(3)
Declare	@bExternalUser			bit
Declare @bIsWIPSearch			bit

Set	@String 		='S'
Set	@Date   		='DT'
Set	@Numeric		='N'
Set	@Text   		='T'
Set	@CommaString		='CS'

-- Initialise variables
Set 	@nErrorCode 		= 0
Set     @nCount			= 1

set 	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

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

If @nErrorCode = 0
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	Set @sSQLString = 
		"Select @bIsWIPSearch		= IsWIPSearch"+CHAR(10)+
		"from	OPENXML (@idoc, '/wpw_ListWorkHistory/FilterCriteria',2)"+CHAR(10)+
		"	WITH ("+CHAR(10)+
		"IsWIPSearch		bit		'IsWIPSearch/text()'"+char(10)+
	     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				@bIsWIPSearch			bit output',
				@idoc				= @idoc,
				@bIsWIPSearch			= @bIsWIPSearch output

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End


If @nErrorCode = 0
Begin
	-- Initialise the WHERE clause with a test that will always be true and will have no performance
	-- impact.  This way we can simplify our coding knowing that there is always a WHERE clause.

	Set @sSelect = "Select "	
	--Set @sWhere = char(10)+"	WHERE 1=1"

	If (@bIsWIPSearch = 1)
	Begin
		Set @sFrom  = char(10)+"	FROM      WORKINPROGRESS W"
	End
	Else
	Begin
		Set @sFrom  = char(10)+"	FROM      WORKHISTORY W"
	End
End

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
		If @sProcedureName = 'wpw_ListWorkHistory'
		Begin

			If @sColumn='NULL'
			Begin
				Set @sTableColumn='NULL'
			End
			Else If @sColumn='EntityKey'
			Begin
				Set @sTableColumn='W.ENTITYNO'
			End
			Else If @sColumn='WIPEntityKey'
			Begin
				Set @sTableColumn='W.ENTITYNO'
			End
			Else If @sColumn='WIPTransKey'
			Begin
				Set @sTableColumn='W.TRANSNO'
			End
			Else If @sColumn='WIPSeqKey'
			Begin
				Set @sTableColumn='W.WIPSEQNO'
			End
			Else If @sColumn='WIPStatus'
			Begin
				If (@bIsWIPSearch =1)
				Begin
					Set @sTableColumn = 'W.STATUS'
				End
				Else
				Begin
					-- if not WIP, we can't finalise.
					Set @sTableColumn = '0'
				End
			End
			Else If @sColumn in (	'EntityName',
						'EntityCode')
			Begin
				If charindex('join NAME NE',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+'join NAME NE		on (NE.NAMENO = W.ENTITYNO)'
				End
	
				If @sColumn='EntityName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NE.NAMENO, null)'
				End
				Else If @sColumn='EntityCode'
				Begin
					Set @sTableColumn='NE.NAMECODE'
				End
			End

			Else If @sColumn in (	'Name',
						'NameKey',
						'DisplayName',
						'NameCode')
			Begin
				If charindex('left join CASENAME CNI',@sFrom)=0
				Begin					
					Set @sFrom=@sFrom +char(10)+"left join CASENAME CNI	on  (CNI.CASEID = W.CASEID"
						+char(10)+"				and  CNI.NAMETYPE = 'I'"
						+char(10)+"				and (CNI.EXPIRYDATE is null or CNI.EXPIRYDATE>getdate()))"
						+char(10)+"left join NAME NI		on (NI.NAMENO = ISNULL(CNI.NAMENO, W.ACCTCLIENTNO))"

				End

				If @sColumn='NameKey'
				Begin
					Set @sTableColumn='NI.NAMENO'
				End
				Else If @sColumn='DisplayName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NI.NAMENO, null)'
				End
				Else If @sColumn='NameCode'
				Begin
					Set @sTableColumn='NI.NAMECODE'
				End
				Else If @sColumn='Name'
				Begin
					Set @sTableColumn='NI.NAME'
				End
			End

			Else If @sColumn in (	'ResponsibleStaff',
						'ResponsibleStaffKey',
						'ResponsibleStaffName',
						'ResponsibleStaffCode')
			Begin
				If charindex('left join (select CNEMP.CASEID, CNEMP.NAMENO from CASENAME CNEMP',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+
						"left join (select CNEMP.CASEID, CNEMP.NAMENO from CASENAME CNEMP"+CHAR(10)+
						"	join"+CHAR(10)+
						"	(select CASEID, min(SEQUENCE) SEQUENCE from CASENAME where NAMETYPE = 'EMP'"+CHAR(10)+
						"	group by CASEID) as CNEMP1 on (CNEMP1.CASEID = CNEMP.CASEID"+CHAR(10)+
						"					and CNEMP1.SEQUENCE=CNEMP.SEQUENCE"+CHAR(10)+
						"					and CNEMP.NAMETYPE = 'EMP'))"+CHAR(10)+
						"	as CNEMP on (CNEMP.CASEID = W.CASEID)"+CHAR(10)+
						"left join NAME NEMP on (NEMP.NAMENO = CNEMP.NAMENO)"
				End


				If @sColumn='ResponsibleStaffNameKey'
				Begin
					Set @sTableColumn='NEMP.NAMENO'
				End
				Else If @sColumn='ResponsibleStaffName'
				Begin
					Set @sTableColumn='NEMP.NAME'
				End
				Else If @sColumn='ResponsibleStaffCode'
				Begin
					Set @sTableColumn='NEMP.NAMECODE'
				End
				Else If @sColumn='ResponsibleStaff'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NEMP.NAMENO, null)'
				End
			End

			Else If @sColumn in (	'AllocatedDebtor',
						'AllocatedNameCode',
						'AllocatedNameKey')
			Begin
				If charindex('left join NAME NALLOC on (NALLOC.NAMENO = W.ACCTCLIENTNO)',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+
						"left join NAME NALLOC on (NALLOC.NAMENO = W.ACCTCLIENTNO)"
				End


				If @sColumn='AllocatedNameKey'
				Begin
					Set @sTableColumn='NALLOC.NAMENO'
				End
				Else If @sColumn='AllocatedNameCode'
				Begin
					Set @sTableColumn='NALLOC.NAMECODE'
				End
				Else If @sColumn='AllocatedDebtor'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NALLOC.NAMENO, null)'
				End
			End

			Else If @sColumn in (	'Signatory',
						'SignatoryKey',
						'SignatoryName',
						'SignatoryCode')
			Begin
				If charindex('left join CASENAME CNS',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join CASENAME CNS	on  (CNS.CASEID = W.CASEID"
								+char(10)+"				and  CNS.NAMETYPE = 'SIG'"
								+char(10)+"				and (CNS.EXPIRYDATE is null or CNS.EXPIRYDATE>getdate()))"
								+char(10)+"left join NAME NS		on (NS.NAMENO = CNS.NAMENO)"
				End

				If @sColumn='SignatoryKey'
				Begin
					Set @sTableColumn='NS.NAMENO'
				End
				Else If @sColumn='SignatoryName'
				Begin
					Set @sTableColumn='NS.NAME'
				End
				Else If @sColumn='SignatoryCode'
				Begin
					Set @sTableColumn='NS.NAMECODE'
				End
				Else If @sColumn='Signatory'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NS.NAMENO, null)'
				End
			End

			Else If @sColumn='CaseKey'
			Begin
				Set @sTableColumn='W.CASEID'
			End

			Else If @sColumn='CaseReference'
			Begin
				If charindex('left join CASES C',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join CASES C	on  (C.CASEID = W.CASEID)"
				End
				Set @sTableColumn='C.IRN'
			End

			Else If @sColumn='CaseTitle'
			Begin
				If charindex('left join CASES C',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join CASES C	on  (C.CASEID = W.CASEID)"
				End
				Set @sTableColumn='C.TITLE'
			End

			Else If @sColumn='TransactionDate'
			Begin
				Set @sTableColumn='W.TRANSDATE'
			End

			Else If @sColumn='PostDate'
			Begin
				Set @sTableColumn='W.POSTDATE'
			End

			Else If @sColumn='PostPeriod'
			Begin
				If (@bIsWIPSearch =1)
				Begin
					Set @sTableColumn = 'null'
				End
				Else
				Begin
					Set @sTableColumn = 'W.POSTPERIOD'
				End
			End

			Else If @sColumn='ItemReference'
			Begin				
				If charindex('left join WIPTEMPLATE WT',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join WIPTEMPLATE WT	on  (W.WIPCODE = WT.WIPCODE)"
				End

				Set @sTableColumn = 'WT.DESCRIPTION'
			End

			Else If @sColumn='WIPCode'
			Begin		

				Set @sTableColumn = 'WT.WIPCODE'
			End

			Else If @sColumn='InvoiceNo'
			Begin
				If charindex('left join OPENITEM O',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join OPENITEM O on (O.ITEMENTITYNO=W.REFENTITYNO"
							  +char(10)+"and O.ITEMTRANSNO =W.REFTRANSNO"
							  +char(10)+"and O.OPENITEMNO  =(SELECT min(O1.OPENITEMNO)"
							  +char(10)+"                    from OPENITEM O1"
							  +char(10)+"                    where O1.ITEMENTITYNO=O.ITEMENTITYNO"
							  +char(10)+"                    and   O1.ITEMTRANSNO =O.ITEMTRANSNO))"
				End
				Set @sTableColumn='O.OPENITEMNO'
			End

			Else If @sColumn in (	'WIPStaff',
						'WIPStaffKey',
						'WIPStaffName',
						'WIPStaffCode')
			Begin
				If charindex('left join NAME NWS',@sFrom)=0
				Begin					
					Set @sFrom=@sFrom+char(10)+"left join NAME NWS		on (NWS.NAMENO = W.EMPLOYEENO)"
				End

				If @sColumn='WIPStaffKey'
				Begin
					Set @sTableColumn='NWS.NAMENO'
				End
				Else If @sColumn='WIPStaffName'
				Begin
					Set @sTableColumn='NWS.NAME'
				End
				Else If @sColumn='WIPStaffCode'
				Begin
					Set @sTableColumn='NWS.NAMECODE'
				End
				Else If @sColumn='WIPStaff'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NWS.NAMENO, null)'
				End
			End

			Else If @sColumn in (	'WIPAgent',
						'WIPAgentKey',
						'WIPAgentName',
						'WIPAgentCode')
			Begin
				If charindex('left join NAME NWA',@sFrom)=0
				Begin					
					Set @sFrom=@sFrom+char(10)+"left join NAME NWA		on (NWA.NAMENO = W.ASSOCIATENO)"
				End

				If @sColumn='WIPAgentKey'
				Begin
					Set @sTableColumn='NWA.NAMENO'
				End
				Else If @sColumn='WIPAgentName'
				Begin
					Set @sTableColumn='NWA.NAME'
				End
				Else If @sColumn='WIPAgentCode'
				Begin
					Set @sTableColumn='NWA.NAMECODE'
				End
				Else If @sColumn='WIPAgent'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NWA.NAMENO, null)'
				End
			End

			Else If @sColumn='SupplierInvoiceNo'
			Begin
				Set @sTableColumn = 'W.INVOICENUMBER'
			End

			Else If @sColumn='Hours'
			Begin
				if @bIsWIPSearch = 0
				Begin
					Set @sTableColumn = 'Case when W.TOTALTIME is null then null 
						else (isnull(DATEPART(HOUR,W.TOTALTIME),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0)) 
							* case when W.TRANSTYPE = 1001 then -1 else 1 end
						end'
				End
				Else Begin
					Set @sTableColumn = 'Case when W.TOTALTIME is null then null else isnull(DATEPART(HOUR,W.TOTALTIME),0)*60 + isnull(DATEPART(MINUTE, W.TOTALTIME),0) end'
				End
			End

			Else If @sColumn='Status'
			Begin
				If (@bIsWIPSearch =1)
				Begin
					Set @sTableColumn = 'CASE W.STATUS when 0 then ''Draft'' when 1 then ''Active'' when 2 then ''Locked'' when 9 then ''Reversed'' end'
				End
				Else
				Begin
					If charindex('left join WORKINPROGRESS WIP',@sFrom)=0
					Begin					
						Set @sFrom=@sFrom+char(10)+"left join WORKINPROGRESS WIP on (WIP.TRANSNO = W.TRANSNO and WIP.ENTITYNO = W.ENTITYNO and WIP.WIPSEQNO = W.WIPSEQNO)"
					End
					Set @sTableColumn = 'WIP.STATUS, W.STATUS, CASE when WIP.STATUS=0 then ''Draft'' when W.STATUS=9 then ''Reversed'' when WIP.STATUS=2 then ''Locked'' when W.STATUS=1 and WIP.TRANSNO IS NULL then ''Billed'' when W.STATUS=1 and WIP.TRANSNO is not null then ''Active'' end'
				End
			End

			Else If @sColumn='Quantity'
			Begin
				Set @sTableColumn = 'W.ENTEREDQUANTITY'
			End

			Else If @sColumn='Narration'
			Begin
				Set @sTableColumn = dbo.fn_SqlTranslatedColumn('WORKHISTORY','SHORTNARRATIVE','LONGNARRATIVE','W',@sLookupCulture,@pbCalledFromCentura)
			End

			Else If @sColumn='Category'
			Begin
				If charindex('left join WIPTEMPLATE WT',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join WIPTEMPLATE WT	on  (W.WIPCODE = WT.WIPCODE)"
				End
				If charindex('left join WIPTYPE WTYPE',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join WIPTYPE WTYPE	on  (WT.WIPTYPEID = WTYPE.WIPTYPEID)"
				End
				If charindex('left join WIPCATEGORY WCAT',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join WIPCATEGORY WCAT	on  (WCAT.CATEGORYCODE = WTYPE.CATEGORYCODE)"
				End

				Set @sTableColumn = dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',NULL,'WCAT',@sLookupCulture,@pbCalledFromCentura)
			End

			Else If @sColumn='Transaction'
			Begin
				If (@bIsWIPSearch =1)
				Begin
					If charindex('left join TRANSACTIONHEADER TH',@sFrom)=0
					Begin
						Set @sFrom=@sFrom +char(10)+"left join TRANSACTIONHEADER TH on (TH.TRANSNO = W.TRANSNO and TH.ENTITYNO = W.ENTITYNO)"+CHAR(10)+
									"left join ACCT_TRANS_TYPE ATT on (ATT.TRANS_TYPE_ID = TH.TRANSTYPE)"
					End
				End
				Else
				Begin
					If charindex('left join ACCT_TRANS_TYPE ATT',@sFrom)=0
					Begin
						Set @sFrom=@sFrom +char(10)+"left join ACCT_TRANS_TYPE ATT on (ATT.TRANS_TYPE_ID = W.TRANSTYPE)"
					End
				End
				Set @sTableColumn = dbo.fn_SqlTranslatedColumn('ACCT_TRANS_TYPE','DESCRIPTION',NULL,'ATT',@sLookupCulture,@pbCalledFromCentura)
			End

			Else If @sColumn='Reason'
			Begin
				If (@bIsWIPSearch=0)
				Begin
					If charindex('left join REASON RE',@sFrom)=0
					Begin
						Set @sFrom=@sFrom +char(10)+"left join REASON RE on (RE.REASONCODE = W.REASONCODE)"
					End
					Set @sTableColumn = 'RE.DESCRIPTION'
				End
				Else
				Begin
					Set @sTableColumn = 'null'
				End
			End

			Else If @sColumn='Movement' or @sColumn='MovementSequence'
			Begin
				If (@bIsWIPSearch=0)
				Begin
					If charindex('left join MOVEMENTLABEL ML',@sFrom)=0
					Begin
						Set @sFrom=@sFrom +char(10)+"left join MOVEMENTLABEL ML on (ML.MOVEMENTCLASS = W.MOVEMENTCLASS"+ CHAR(10)+
									    "			    and ML.LEDGERID = 1)"
					End
				End
				Else
				Begin
					If charindex('join WORKHISTORY WH',@sFrom)=0
					Begin
						Set @sFrom=@sFrom +char(10)+"join WORKHISTORY WH on (WH.ENTITYNO = W.ENTITYNO"+CHAR(10)+
									    "			    and WH.TRANSNO = W.TRANSNO"+CHAR(10)+
									    "			    and WH.WIPSEQNO = W.WIPSEQNO"+CHAR(10)+
									    "			    and WH.HISTORYLINENO = (select min(WH2.HISTORYLINENO) from WORKHISTORY WH2 where WH2.ENTITYNO = W.ENTITYNO and WH2.TRANSNO = W.TRANSNO and WH2.WIPSEQNO = W.WIPSEQNO))"
					End
					If charindex('left join MOVEMENTLABEL ML',@sFrom)=0
					Begin
						Set @sFrom=@sFrom +char(10)+"left join MOVEMENTLABEL ML on (ML.MOVEMENTCLASS = WH.MOVEMENTCLASS"+ CHAR(10)+
									    "			    and ML.LEDGERID = 1)"
					End
				End
				If @sColumn='Movement'
				Begin
					Set @sTableColumn = 'ML.LABEL'
				End

				If @sColumn='MovementSequence'
				Begin
					Set @sTableColumn = 'ML.SORTSEQUENCE'
				End
			End

			Else If @sColumn='LocalCurrencyCode'
			Begin
				If (@sLocalCurrencyCode is null)
				Begin
				    Select @sLocalCurrencyCode = COLCHARACTER
				    From SITECONTROL where CONTROLID = 'CURRENCY'
				End
				Set @sTableColumn = "'" + @sLocalCurrencyCode + "'"
			End

			Else If @sColumn='LocalValue'
			Begin
				If (@bIsWIPSearch=1)
				Begin
				    Set @sTableColumn = 'W.LOCALVALUE'
				End
				Else
				Begin
				    Set @sTableColumn = 'W.LOCALTRANSVALUE'
				End
			End

			Else If @sColumn='LocalCost'
			Begin
			    Set @sTableColumn = 'W.LOCALCOST'
			End

			Else If @sColumn='LocalBalance'
			Begin
				If (@bIsWIPSearch=1)
				Begin
				    Set @sTableColumn = 'W.BALANCE'
				End
				Else
				Begin
					If charindex('left join WORKINPROGRESS WIP',@sFrom)=0
					Begin					
						Set @sFrom=@sFrom+char(10)+"left join WORKINPROGRESS WIP on (WIP.TRANSNO = W.TRANSNO and WIP.ENTITYNO = W.ENTITYNO and WIP.WIPSEQNO = W.WIPSEQNO)"
					End
					Set @sTableColumn = 'WIP.BALANCE'
				End
			End

			Else If @sColumn='ForeignCurrencyCode'
			Begin
				Set @sTableColumn = 'W.FOREIGNCURRENCY'
			End

			Else If @sColumn='ForeignValue'
			Begin
				If (@bIsWIPSearch=1)
				Begin
				    Set @sTableColumn = 'W.FOREIGNVALUE'
				End
				Else
				Begin
				    Set @sTableColumn = 'W.FOREIGNTRANVALUE'
				End
			End

			Else If @sColumn='ForeignCost'
			Begin
			    Set @sTableColumn = 'W.FOREIGNCOST'
			End

			Else If @sColumn='ForeignBalance'
			Begin
				If (@bIsWIPSearch=1)
				Begin
				    Set @sTableColumn = 'W.FOREIGNBALANCE'
				End
				Else
				Begin
					If charindex('left join WORKINPROGRESS WIP',@sFrom)=0
					Begin					
						Set @sFrom=@sFrom+char(10)+"left join WORKINPROGRESS WIP on (WIP.TRANSNO = W.TRANSNO and WIP.ENTITYNO = W.ENTITYNO and WIP.WIPSEQNO = W.WIPSEQNO)"
					End
					Set @sTableColumn = 'WIP.FOREIGNBALANCE'
				End
			End

			Else If @sColumn in ('BilledValue', 'BilledCost', 'BilledBalance', 'BilledCurrencyCode')
			Begin
				If charindex('left join (SELECT CNDIN.CASEID',@sFrom)=0
				Begin
					Set @sFrom=@sFrom +char(10)+"left join (SELECT CNDIN.CASEID, CNDIN.NAMETYPE, CNDIN.NAMENO, min(CNDIN.SEQUENCE) as SEQUENCE FROM CASENAME CNDIN"+CHAR(10)+
					"	where CNDIN.NAMETYPE = 'D'"+CHAR(10)+
					"	and (CNDIN.EXPIRYDATE is null or CNDIN.EXPIRYDATE>getdate()) group by CNDIN.CASEID, CNDIN.NAMETYPE, CNDIN.NAMENO) as CND on (CND.CASEID = W.CASEID)"
				End
	    			If charindex('left join IPNAME IPND',@sFrom)=0
				Begin					
					Set @sFrom=@sFrom+char(10)+"left join IPNAME IPND on (IPND.NAMENO = isnull(W.ACCTCLIENTNO, CND.NAMENO))"+CHAR(10)+
								    "left join CURRENCY BC on (BC.CURRENCY = IPND.CURRENCY)"
				End
			    
				If @sColumn='BilledValue'
				Begin
					If (@bIsWIPSearch=1)
					Begin
					    Set @sTableColumn = 'Case when W.FOREIGNCURRENCY = BC.CURRENCY and W.FOREIGNVALUE is not null then W.FOREIGNVALUE else (W.LOCALVALUE * BC.SELLRATE) end'
					End
					Else
					Begin
					    Set @sTableColumn = 'Case when W.FOREIGNCURRENCY = BC.CURRENCY and W.FOREIGNTRANVALUE is not null then W.FOREIGNTRANVALUE else (W.LOCALTRANSVALUE * BC.SELLRATE) end'
					End
				End

				Else If @sColumn='BilledCost'
				Begin
				    Set @sTableColumn = 'Case when W.FOREIGNCURRENCY = BC.CURRENCY and W.FOREIGNCOST is not null then W.FOREIGNCOST else (W.LOCALCOST * BC.SELLRATE) end'
				End

				Else If @sColumn='BilledBalance'
				Begin
					If (@bIsWIPSearch=1)
					Begin
					    Set @sTableColumn = 'Case when W.FOREIGNCURRENCY = BC.CURRENCY and W.FOREIGNBALANCE is not null then W.FOREIGNBALANCE else (W.BALANCE * BC.SELLRATE) end'
					End
					Else
					Begin
						If charindex('left join WORKINPROGRESS WIP',@sFrom)=0
						Begin					
							Set @sFrom=@sFrom+char(10)+"left join WORKINPROGRESS WIP on (WIP.TRANSNO = W.TRANSNO and WIP.ENTITYNO = W.ENTITYNO and WIP.WIPSEQNO = W.WIPSEQNO)"
						End
						Set @sTableColumn = 'Case when WIP.FOREIGNCURRENCY = BC.CURRENCY and WIP.FOREIGNBALANCE is not null then WIP.FOREIGNBALANCE else (WIP.BALANCE * BC.SELLRATE) end'
					End
				End

				Else If @sColumn='BilledCurrencyCode'
				Begin
					Set @sTableColumn = 'BC.CURRENCY'
				End
			End
			Else If @sColumn='TimesheetNotes'
			Begin
				Set @sFrom=@sFrom+char(10)+'left join DIARY D on (D.TRANSNO = W.TRANSNO and D.WIPENTITYNO = W.ENTITYNO)'
				Set @sTableColumn='D.NOTES'
			End			
		End

		If (@sTableColumn is null or @sTableColumn = '')
		Begin
			Set @sTableColumn='1'
		End

		If datalength(@sPublishName)>0
		Begin
			Set @sSelect=@sSelect+@sComma+char(10)+@sTableColumn+' as ['+@sPublishName+']'
			Set @sComma=', '
		End
		Else
		Begin
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

	Set @sTableColumn = ''

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
End


If @nErrorCode=0
Begin		
	-- Assemble the "Order By" clause.

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
		Set @sOrder = 'Order by ' + @sOrder
	End

	Set @nErrorCode=@@Error
End

-- Use wp_ConstructWipWhere to get the Where clause and put it into an exists.
If @nErrorCode = 0
Begin
	exec @nErrorCode=dbo.wp_ConstructWipWhere	
				@psWIPWhere		= @sWhere	  	OUTPUT, 			
				@psCurrentCaseTable	= @sCurrentCaseTable	OUTPUT,
				@pnUserIdentityId	= @pnUserIdentityId,	
				@psCulture		= @psCulture,	
				@pbExternalUser		= @bExternalUser,
				@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
				@pbCalledFromCentura	= @pbCalledFromCentura

	Set @sWhere = char(10)+"where exists (select 1" + @sWhere + "and XW.ENTITYNO = W.ENTITYNO AND XW.TRANSNO = W.TRANSNO AND XW.WIPSEQNO = W.WIPSEQNO"

	if @bIsWIPSearch = 0
	Begin
		Set @sWhere = @sWhere + " AND XW.HISTORYLINENO = W.HISTORYLINENO"
	End

	Set @sWhere = @sWhere + ")"
End

-- 	print char(10)+char(10)
-- 	PRINT @sSelect 
-- 	PRINT @sFrom 
-- 	PRINT @sWhere 
-- 	PRINT @sOrder

-- Return the results
-- No paging required
If (@pnPageStartRow is null or @pnPageEndRow is null)
Begin

	exec (@sSelect + @sFrom + @sWhere + @sOrder)

	Set @pnRowCount = @@RowCount
End
-- Paging required
Else Begin

	Set @sSelect = replace(@sSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')

	-- Execute the SQL
	exec (@sSelect + @sFrom + @sWhere + @sOrder)

	Set @pnRowCount = @@RowCount

	If @pnRowCount<@pnPageEndRow
	and @nErrorCode=0
	Begin
		-- results fit on 1 page
		set @sSQLString='select @pnRowCount as SearchSetTotalRows'  

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnRowCount	int',
					  @pnRowCount=@pnRowCount
	End
	Else If @nErrorCode = 0
	Begin
		Set @sSelect = ' Select count(*) as SearchSetTotalRows '
		exec (@sSelect + @sFrom + @sWhere)
		Set @nErrorCode =@@ERROR
	End
End

RETURN @nErrorCode
GO

Grant execute on dbo.wpw_ListWorkHistory  to public
GO
