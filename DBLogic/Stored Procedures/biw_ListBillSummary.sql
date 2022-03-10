-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillSummary.'
	Drop procedure [dbo].[biw_ListBillSummary]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillSummary
(
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnQueryContextKey		int		= 451, 	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null, -- The columns and sorting required in the result set.
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.
	@pbPrintSQL			bit		= 0,		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	biw_ListBillSummary
-- VERSION:	21
-- DESCRIPTION:	Returns the requested information about bills that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 04 Feb 2010	LP	RFC8289	1	Procedure created
-- 16 Mar 2010	KR	RFC8299	2	added ACCTENTITYNO to the select
-- 22 Mar 2010	MS	RFC8301	3	Added Rtrim for ItemType
-- 12 Apr 2010  LP      RFC8289	4       Fixed to retrieve CaseKey filter criteria from correct XML node.
-- 27 May 2010	LP	RFC9386	5	Fixed to retrieve PaidPercent from 
-- 18 Jun 2010	LP	RFC9399	6	Exclude reversed bills from result set
-- 04 Aug 2010	KR	RFC9086	7	Added ItemTypeKey and ClosedForBilling
-- 24 Mar 2011  KR	R7956	8	Made DebtorKey a nvarachar instead of an int to allow for multi select pick list
-- 18 May 2011	AT	R10666	9	Modified exists query for draft wip search to match OPENITEM to BILLEDITEM.
-- 23 May 2011	AT	R10666	10	Fixed generation of exists query for associated names.
-- 07 Jul 2011	DL	R10830 	11	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 17 Dec 2013	MS	R28045	12	Added HasRestrictedCases to the select
-- 02 Nov 2015	vql	R53910	13	Adjust formatted names logic (DR-15543).
-- 17 Dec 2015	MF	R56300	14	Allow Finalised bills to be searched by draft item number if OPENITEM table is being logged.
-- 21 Mar 2016  MS  	R57079  15  	Added BillReversalNotAllowed column
-- 26 Apr 2017	MF	71303	16	Duplicate row occurring where multiple entities have referenced the same ASSOCOPENITEMNO.
-- 30 May 2017	MF	R71553	17	Ethical Walls rules applied for logged on user.
-- 24 Oct 2017	AK	R72645	18	Make compatible with case sensitive server with case insensitive database.
-- 01 Oct 2018  MS      DR42309 19      Added CaseRef, Country and Title for raised bills 
-- 14 Nov 2018  AV  75198/DR-45358	20   Date conversion errors when creating cases and opening names in Chinese DB   
-- 15 Apr 2019  MS      DR46962 21      Fix count error when associated name filter is used

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added

--	AcctEntityNo
---	BillPercent
--	BillStatus
---	DebtorKey
---	DebtorCode
---	DebtorName
--	ExchangeRate
--	ForeignBalance
--	ForeignCurrencyCode
--	ForeignValue
--	IsPrinted
--	ItemDate
--	ItemNo
--	ItemTransNo
--	ItemTypeKey
-- 	ItemType
--	ClosedForBilling
--	LocalBalance
--	LocalCurrencyCode
--	LocalValue
--	PaidPercent
--	RelatedItemNo
--	StaffKey
--	StaffCode
--	StaffName
--      BillReversalNotAllowed
--      CaseRef
--      Country
--      Title

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	N1	- Staff
--	N2	- Debtor
--	O	- OPENITEM

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(max)
Declare	@sSql					nvarchar(max)

Declare @sLookupCulture				nvarchar(10)

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

Declare @nOutRequestsRowCount		int
Declare @nColumnNo			tinyint
Declare @sColumn			nvarchar(100)
Declare @sPublishName			nvarchar(50)
Declare @sQualifier			nvarchar(50)
Declare @nOrderPosition			tinyint
Declare @sOrderDirection		nvarchar(5)
Declare @sTableColumn			nvarchar(1000)
Declare @sComma				nchar(2)	-- initialised when a column has been added to the Select.

Declare @nCount				int		-- Current table row being processed.
Declare @sSelect			nvarchar(max)
Declare @sFrom				nvarchar(max)
Declare @sWhere				nvarchar(max)
Declare @sOrder				nvarchar(max)
Declare @sFromExists			nvarchar(max)
Declare @sWhereExists			nvarchar(max)
Declare @sRowPattern			nvarchar(1000)
Declare @sCorrelationName		nvarchar(50)

Declare @idoc 				int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr				nchar(4)
Declare	@CommaNumeric			nchar(2)

Set	@String 			='S'
Set	@Date   			='DT'
Set	@Numeric			='N'
Set	@Text   			='T'
Set	@CommaString			='CS'
Set	@CommaNumeric			= 'CN'

-- Declare variables for Where Clause
declare	@nEntityKey			int		
declare	@nEntityKeyOperator		tinyint		
declare	@sItemNo			nvarchar(254)	
declare	@nItemNoOperator		tinyint		
declare	@dtDateRangeFrom		datetime	
declare	@dtDateRangeTo			datetime
declare	@nDateRangeOperator		tinyint		
declare	@nItemType			int		
declare	@nItemTypeOperator		tinyint		
declare	@nStaffKey			int		
declare	@nStaffKeyOperator		tinyint		
declare	@nDebtorKey			nvarchar(1000)		
declare	@nDebtorKeyOperator		tinyint		
declare	@sDebtorCountry			nvarchar(10)	
declare	@nDebtorCountryOperator		tinyint	
declare	@sCurrencyCode			nvarchar(10)		
declare	@nCurrencyCodeOperator		tinyint	
declare	@nCaseKey			int		
declare	@nCaseKeyOperator		tinyint		
declare	@nOfficeKey			int		
declare	@nOfficeKeyOperator		tinyint		
declare	@nRegionCode			int		
declare	@nRegionCodeOperator		tinyint		
declare	@nMinLocalBalance		decimal		
declare	@nMaxLocalBalance		decimal	
declare @sAssociatedNameKeys		nvarchar(max)
declare @nAssociatedNameKeyOperator	tinyint
declare	@sNameTypeKey			nvarchar(10)		
declare	@bIsBooleanOr			bit		
declare	@bIsFinalised			bit		
declare	@bIsPrinted			bit
declare @bFilterWIP			bit		-- indicates if we are filtering against WIP Name and Case
declare	@bSearchDraft			bit		-- indicates that Finalised bills are also being searched by their draft number
Declare @bFIStopsBillReversal           bit

declare @tblAssociateNameGroup table	(AssociateNameIdentity	int IDENTITY,
					AssociateNameKeys	nvarchar(4000) collate database_default,
		      	 		AssociateNameOperator	tinyint,
		      	 		AssociateNameTypeKey	nvarchar(10) collate database_default,
		      	 		AssociateNameIsBooleanOr	bit)	
declare @nAssociateNameRowCount		int		-- Number of rows in the @tblAssociateNameGroup table  

-- Initialise variables
Set	@nErrorCode	= 0
Set     @nCount		= 1
set 	@sSelect	='SET ANSI_NULLS OFF' + char(10)+ 'Select '
set 	@sFrom		= char(10)+"From OPENITEM O"
set 	@sWhere 	= char(10)+"WHERE 1=1 and O.STATUS <> 9 "

If @nErrorCode = 0
Begin
	---------------------------------
	-- Check to see if Ethical Walls
	-- for Names are in use.
	---------------------------------
	If exists (select 1
			from NAMERELATION NR
			join ASSOCIATEDNAME AN on (AN.RELATIONSHIP=NR.RELATIONSHIP)
			where NR.ETHICALWALL>0)
	Begin
		Set @sFrom  = @sFrom  + char(10)+"left join dbo.fn_NamesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") EWN on (EWN.NAMENO=O.ACCTDEBTORNO)"

		Set @sWhere = @sWhere + char(10)+"and (EWN.NAMENO is not null OR O.ACCTDEBTORNO is null)"
	End
	---------------------------------
	-- Check to see if Ethical Walls
	-- for Cases are in use.
	---------------------------------
	If exists (select 1 
			from NAMETYPE NT
			join CASENAME CN on (CN.NAMETYPE=NT.NAMETYPE)
			where NT.ETHICALWALL>0)
	Begin
		-----------------------------------------------
		-- The number of Cases associated with the BILL
		-- must match the number of cases the user is 
		-- allowed to see on that Bill.
		-----------------------------------------------
		Set @sFrom  = @sFrom  + char(10)+"left join (select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, count(*) as CASECOUNT"
		                      + char(10)+"           from OPENITEMCASE"
				      + char(10)+"           group by ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) CC1 on (CC1.ITEMENTITYNO=O.ITEMENTITYNO"
				      + char(10)+"                                                                               and CC1.ITEMTRANSNO =O.ITEMTRANSNO"
				      + char(10)+"                                                                               and CC1.ACCTENTITYNO=O.ACCTENTITYNO"
				      + char(10)+"                                                                               and CC1.ACCTDEBTORNO=O.ACCTDEBTORNO)"
				      + char(10)+"left join (select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, count(*) as CASECOUNT"
		                      + char(10)+"           from OPENITEMCASE OIC"
				      + char(10)+"           left join dbo.fn_CasesEthicalWall("+cast(@pnUserIdentityId as nvarchar)+") EWC on (EWC.CASEID=OIC.CASEID)"
				      + char(10)+"           group by ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) CC2 on (CC2.ITEMENTITYNO=O.ITEMENTITYNO"
				      + char(10)+"                                                                               and CC2.ITEMTRANSNO =O.ITEMTRANSNO"
				      + char(10)+"                                                                               and CC2.ACCTENTITYNO=O.ACCTENTITYNO"
				      + char(10)+"                                                                               and CC2.ACCTDEBTORNO=O.ACCTDEBTORNO)"

		Set @sWhere = @sWhere + char(10)+"and (CC1.CASECOUNT=CC2.CASECOUNT OR CC1.CASECOUNT is null)"
	End

        Set @sSQLString = "Select @bFIStopsBillReversal = SC.COLBOOLEAN
        FROM SITECONTROL SC
        WHERE SC.CONTROLID = 'FIStopsBillReversal'"

        exec @nErrorCode = sp_executesql @sSQLString,
                N'@bFIStopsBillReversal bit output',
                @bFIStopsBillReversal = @bFIStopsBillReversal output
End

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
	-- Default @pnQueryContextKey to 451.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 451)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End


/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/

-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the Filter Criteria using element-centric mapping (implement 
	--    Case Insensitive searching where required)   
	Set @sSQLString = 	
	"Select @nEntityKey			= EntityKey,"		+CHAR(10)+
	"	@nEntityKeyOperator		= EntityKeyOperator,"	+CHAR(10)+
	"	@sItemNo			= upper(ItemNumber),"	+CHAR(10)+
	"	@nItemNoOperator		= ItemNumberOperator,"	+CHAR(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"	+CHAR(10)+	
	"	@dtDateRangeTo			= DateRangeTo,"		+CHAR(10)+	
	"	@nDateRangeOperator		= DateRangeOperator,"	+CHAR(10)+	
	"	@nItemType			= ItemType,"		+CHAR(10)+	
	"	@nItemTypeOperator		= ItemTypeOperator,"	+CHAR(10)+	
	"	@nStaffKey			= StaffKey,"		+CHAR(10)+	
	"	@nStaffKeyOperator		= StaffKeyOperator,"	+CHAR(10)+	
	"	@nDebtorKey			= DebtorKey,"		+CHAR(10)+	
	"	@nDebtorKeyOperator		= DebtorKeyOperator,"	+CHAR(10)+	
	"	@sDebtorCountry			= DebtorCountry,"	+CHAR(10)+	
	"	@nDebtorCountryOperator		= DebtorCountryOperator,"+CHAR(10)+	
	"	@sCurrencyCode			= CurrencyCode,"	+CHAR(10)+	
	"	@nCurrencyCodeOperator		= CurrencyCodeOperator,"+CHAR(10)+	
	"	@nCaseKey			= CaseKey,"		+CHAR(10)+	
	"	@nCaseKeyOperator		= CaseKeyOperator,"	+CHAR(10)+	
	"	@nOfficeKey			= OfficeKey,"		+CHAR(10)+	
	"	@nOfficeKeyOperator		= OfficeKeyOperator,"	+CHAR(10)+	
	"	@nRegionCode			= RegionCode,"		+CHAR(10)+	
	"	@nRegionCodeOperator		= RegionCodeOperator,"	+CHAR(10)+	
	"	@nMinLocalBalance		= MinLocalBalance,"	+CHAR(10)+	
	"	@nMaxLocalBalance		= MaxLocalBalance,"	+CHAR(10)+
	"	@bIsFinalised			= IsFinalised,"		+CHAR(10)+	
	"	@bIsPrinted			= IsPrinted"		+CHAR(10)+	
	"from	OPENXML (@idoc, '//biw_ListBillSummary/FilterCriteria/OpenItem',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	EntityKey		int		 'EntityKey/text()',"		+CHAR(10)+
	"	EntityKeyOperator	tinyint		 'EntityKey/@Operator/text()',"	+CHAR(10)+
	"	ItemNumber		nvarchar(254)	 'ItemNo/text()',"		+CHAR(10)+
	"	ItemNumberOperator	tinyint		 'ItemNo/@Operator/text()',"	+CHAR(10)+
	"	DateRangeFrom 		datetime	 'ItemDate/DateRange/From/text()',"	+CHAR(10)+
	"	DateRangeTo		datetime	 'ItemDate/DateRange/To/text()',"		+CHAR(10)+
	"	DateRangeOperator	tinyint		 'ItemDate/DateRange/@Operator/text()',"	+CHAR(10)+
	"	ItemType		int		 'ItemType/text()',"		+CHAR(10)+
	"	ItemTypeOperator	tinyint		 'ItemType/@Operator/text()',"	+CHAR(10)+
	"	StaffKey		int		 'Staff/Key/text()',"		+CHAR(10)+
	"	StaffKeyOperator	tinyint		 'Staff/@Operator/text()',"	+CHAR(10)+
	"	DebtorKey		nvarchar(1000)		 'Debtor/Key/text()',"		+CHAR(10)+
	"	DebtorKeyOperator	tinyint		 'Debtor/Key/@Operator/text()',"	+CHAR(10)+
	"	DebtorCountry		nvarchar(10)	 'Debtor/CountryKey/text()',"	+CHAR(10)+
	"	DebtorCountryOperator	tinyint		 'Debtor/CountryKey/@Operator/text()',"+CHAR(10)+
	"	CurrencyCode		nvarchar(10)	 'CurrencyCode/text()',"	+CHAR(10)+
	"	CurrencyCodeOperator	tinyint		 'CurrencyCode/@Operator/text()',"+CHAR(10)+
	"	CaseKey			int		 'CaseKey/text()',"		+CHAR(10)+
	"	CaseKeyOperator		tinyint		 'CaseKey/@Operator/text()',"	+CHAR(10)+
	"	OfficeKey		int		 'OfficeKey/text()',"		+CHAR(10)+
	"	OfficeKeyOperator	tinyint		 'OfficeKey/@Operator/text()',"	+CHAR(10)+
	"	RegionCode		int		 'RegionCode/text()',"		+CHAR(10)+
	"	RegionCodeOperator	tinyint		 'RegionCode/@Operator/text()',"+CHAR(10)+
	"	MinLocalBalance		decimal		 'MinLocalBalance/text()',"	+CHAR(10)+
	"	MaxLocalBalance		decimal		 'MaxLocalBalance/text()',"	+CHAR(10)+
	"	IsFinalised		bit		 '@IsFinalised/text()',"	+CHAR(10)+
	"	IsPrinted		bit		 '@IsPrinted/text()'"		+CHAR(10)+	
	")"
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				@nEntityKey			int		output,
				@nEntityKeyOperator		tinyint		output,
				@sItemNo			nvarchar(254)	output,
				@nItemNoOperator		tinyint		output,
				@dtDateRangeFrom		datetime	output,
				@dtDateRangeTo			datetime	output,
				@nDateRangeOperator		tinyint		output,
				@nItemType			int		output,
				@nItemTypeOperator		tinyint		output,
				@nStaffKey			int		output,
				@nStaffKeyOperator		tinyint		output,
				@nDebtorKey			nvarchar(1000)		output,
				@nDebtorKeyOperator		tinyint		output,
				@sDebtorCountry			nvarchar(10)	output,
				@nDebtorCountryOperator		tinyint		output,
				@sCurrencyCode			nvarchar(10)	output,
				@nCurrencyCodeOperator		tinyint		output,
				@nCaseKey			int		output,
				@nCaseKeyOperator		tinyint		output,
				@nOfficeKey			int		output,
				@nOfficeKeyOperator		tinyint		output,
				@nRegionCode			int		output,
				@nRegionCodeOperator		tinyint		output,
				@nMinLocalBalance		decimal		output,
				@nMaxLocalBalance		decimal		output,
				@bIsFinalised			bit		output,
				@bIsPrinted			bit		output',
				@idoc				= @idoc,
				@nEntityKey			=@nEntityKey		output,		
				@nEntityKeyOperator		=@nEntityKeyOperator	output,	
				@sItemNo			=@sItemNo		output,		
				@nItemNoOperator		=@nItemNoOperator	output,	
				@dtDateRangeFrom		=@dtDateRangeFrom	output,	
				@dtDateRangeTo			=@dtDateRangeTo		output,	
				@nDateRangeOperator		=@nDateRangeOperator	output,	
				@nItemType			=@nItemType		output,		
				@nItemTypeOperator		=@nItemTypeOperator	output,	
				@nStaffKey			=@nStaffKey		output,		
				@nStaffKeyOperator		=@nStaffKeyOperator	output,	
				@nDebtorKey			=@nDebtorKey		output,		
				@nDebtorKeyOperator		=@nDebtorKeyOperator	output,	
				@sDebtorCountry			=@sDebtorCountry	output,		
				@nDebtorCountryOperator	=@nDebtorCountryOperator	output,
				@sCurrencyCode		=@sCurrencyCode			output,
				@nCurrencyCodeOperator	=@nCurrencyCodeOperator	output,
				@nCaseKey		=@nCaseKey		output,		
				@nCaseKeyOperator	=@nCaseKeyOperator	output,	
				@nOfficeKey		=@nOfficeKey		output,		
				@nOfficeKeyOperator	=@nOfficeKeyOperator	output,	
				@nRegionCode		=@nRegionCode		output,	
				@nRegionCodeOperator	=@nRegionCodeOperator	output,
				@nMinLocalBalance	=@nMinLocalBalance	output,	
				@nMaxLocalBalance	=@nMaxLocalBalance	output,
				@bIsFinalised		=@bIsFinalised		output,	
				@bIsPrinted		=@bIsPrinted		output						  				  	

	-- Populate specific names
	Set @sRowPattern = "//biw_ListBillSummary/FilterCriteria/OpenItem/AssociatedNames/AssociatedName"
		
	Insert into @tblAssociateNameGroup
	Select	*
	from	OPENXML (@idoc, @sRowPattern, 2)
	WITH (
		AssociateNameKeys			nvarchar(4000)	'NameKey/text()',
		AssociateNameOperator			tinyint		'@Operator/text()',
		AssociateNameTypeKey			nvarchar(10)	'NameTypeKey/text()',
		AssociateNameBooleanOr			bit		'IsBooleanOr/text()'
	     )
	Set @nAssociateNameRowCount = @@RowCount
	
	-- Do we have filters that check against WORKHISTORY/WORKINPROGRESS?
	If @nErrorCode = 0
	and ((@nCaseKey is not NULL or @nCaseKeyOperator between 2 and 6)
	or (@sDebtorCountry is not NULL or @nDebtorCountryOperator between 2 and 6)
	or (@nOfficeKey is not NULL or @nOfficeKeyOperator between 2 and 6)
	or (@nRegionCode is not NULL or @nRegionCodeOperator between 2 and 6)
	or (@nAssociateNameRowCount > 0)
	)
	Begin
		Set @bFilterWIP = 1
	End
	
	If @nErrorCode = 0
	Begin
		If @bFilterWIP = 1
		Begin
			If @bIsFinalised = 0
			Begin
				Set @sFromExists = @sFromExists + " from WORKINPROGRESS WSUB"+char(10)
								+"join BILLEDITEM BISUB on (BISUB.WIPENTITYNO = WSUB.ENTITYNO"    		     
											+" AND BISUB.WIPTRANSNO = WSUB.TRANSNO"
											+" AND BISUB.WIPSEQNO = WSUB.WIPSEQNO)"
				Set @sWhereExists = " where BISUB.ITEMENTITYNO = O.ITEMENTITYNO"+char(10)    
							+"AND   BISUB.ITEMTRANSNO = O.ITEMTRANSNO"
			End
			Else
			Begin
				Set @sFromExists = @sFromExists + " from WORKHISTORY WSUB"	
				
				Set @sWhereExists = " where WSUB.REFENTITYNO = O.ITEMENTITYNO"+char(10)    
							+"AND WSUB.REFTRANSNO =  O.ITEMTRANSNO"+char(10)    
							+"AND   WSUB.MOVEMENTCLASS = 2"     
			End
			
			If @sDebtorCountry is not null
			or @nDebtorCountryOperator between 2 and 6
			Begin
				If charindex('join NAME DTSUB',@sFromExists)=0
				Begin
					Set @sFromExists = @sFromExists + CHAR(10) + 
						"join NAME DTSUB on (DTSUB.NAMENO = O.ACCTDEBTORNO)" + CHAR(10) +    
						"join ADDRESS ADSUB on (ADSUB.ADDRESSCODE = DTSUB.POSTALADDRESS)"					
				End
				
				Set @sWhereExists = @sWhereExists+char(10)+" and ADSUB.COUNTRYCODE " + dbo.fn_ConstructOperator(@nDebtorCountryOperator,@String,@sDebtorCountry, null,0)  				
			End
			
			If @nCaseKey is not null
			or @nCaseKeyOperator between 2 and 6
			Begin
				If charindex('join CASES CSUB',@sFromExists)=0
				Begin
					Set @sFromExists = @sFromExists 
						+ CHAR(10) + "join CASES CSUB on (CSUB.CASEID = WSUB.CASEID)  "   				
				End	
				
				Set @sWhereExists = @sWhereExists+char(10)+"and CSUB.CASEID " + dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)  							
			End
			
			If @nOfficeKey is not null
			or @nOfficeKeyOperator between 2 and 6
			Begin
				If charindex('join CASES CSUB',@sFromExists)=0
				Begin
					Set @sFromExists = @sFromExists 
						+ CHAR(10) + "join CASES CSUB on (CSUB.CASEID = WSUB.CASEID)  "   				
				End
				If charindex('join OFFICE OSUB',@sFromExists)=0
				Begin
					Set @sFromExists = @sFromExists 
						+ CHAR(10) + "join OFFICE OSUB on (OSUB.OFFICEID = CSUB.OFFICEID)"   				
				End	
				
				Set @sWhereExists = @sWhereExists+char(10)+"and CSUB.OFFICEID " + dbo.fn_ConstructOperator(@nOfficeKeyOperator,@Numeric,@nOfficeKey, null,0)  										
			End
			
			If @nRegionCode is not null
			or @nRegionCodeOperator between 2 and 6
			Begin
				If charindex('join CASES CSUB',@sFromExists)=0
				Begin
					Set @sFromExists = @sFromExists 
						+ CHAR(10) + "join CASES CSUB on (CSUB.CASEID = WSUB.CASEID)  "   				
				End		
				If charindex('join OFFICE OSUB',@sFromExists)=0
				Begin
					Set @sFromExists = @sFromExists 
						+ CHAR(10) + "join OFFICE OSUB on (OSUB.OFFICEID = CSUB.OFFICEID)"   				
				End		
				
				Set @sWhereExists = @sWhereExists+char(10)+"and OSUB.REGION " + dbo.fn_ConstructOperator(@nRegionCodeOperator,@Numeric,@nRegionCode, null,0)  										
			End
			
			Set @nCount = 1

			-- @nAssociateNameRowCount is the number of rows in the @tblAssociateNameGroup table, which is used to loop the Associated Names while constructing the 'From' and the 'Where' clause
			
			if (@nAssociateNameRowCount > 0)
			Begin
				Set @sWhereExists = @sWhereExists + char(10) + "AND ("
				
				While @nCount <= @nAssociateNameRowCount
				begin
					Set  @sCorrelationName = 'CNSUB' + cast(@nCount as nvarchar(20))
					
					Select  @sAssociatedNameKeys		= AssociateNameKeys,
						@nAssociatedNameKeyOperator	= AssociateNameOperator,
						@sNameTypeKey			= AssociateNameTypeKey,				
						@bIsBooleanOr			= AssociateNameIsBooleanOr
					from	@tblAssociateNameGroup
					where   AssociateNameIdentity = @nCount 
					
					If @nCount != 1
					Begin 
						Set @sWhereExists = @sWhereExists + CASE WHEN @bIsBooleanOr = 1 THEN " OR " ELSE " AND " END
					End
					
					If @sNameTypeKey is not null
					or @sAssociatedNameKeys is not null
					or @nAssociatedNameKeyOperator between 2 and 6
					Begin
						If charindex('left join CASENAME '+@sCorrelationName, @sFromExists)=0
						Begin
						Set @sFromExists = @sFromExists 
							+ CHAR(10) + "left join CASENAME "+@sCorrelationName+" on (" + @sCorrelationName + ".CASEID = WSUB.CASEID"
										+char(10)+"and "+@sCorrelationName+".NAMETYPE = '" + @sNameTypeKey + "'"									
										+char(10)+"and "+@sCorrelationName+".EXPIRYDATE is null"   
						
						If @nAssociatedNameKeyOperator not in (5,6)
						Begin
							Set @sFromExists = @sFromExists
								+char(10)+
								"and "+@sCorrelationName+".NAMENO"+dbo.fn_ConstructOperator(@nAssociatedNameKeyOperator,@Numeric,@sAssociatedNameKeys, null,0) 				
						End
						
						Set @sFromExists = @sFromExists + ")"				
						
						End
						
						Set @sWhereExists = @sWhereExists + "(" + @sCorrelationName + ".CASEID is not null)"
						
						
					End

					set @nCount = @nCount + 1					
				End
				
				Set @sWhereExists = @sWhereExists + ")"
			End				
		End
		
		If @nEntityKey is not NULL
		or @nEntityKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.ITEMENTITYNO " + dbo.fn_ConstructOperator(@nEntityKeyOperator,@Numeric,@nEntityKey, null,0)  
		End
		
		---------------------------------------------------------
		-- If Finalised Bills are to be included in the search,
		-- and the Open Item is to in the search, then determine
		-- the prefix that is used for draft Open Items.  If the
		-- search is using a draft number then the query will
		-- also search the OPENITEM_iLOG table which will hold
		-- what the OPENITEMNO value was before it was finalised.
		---------------------------------------------------------
		If ISNULL(@bIsFinalised,1)=1
		and @sItemNo is not null
		and @nItemNoOperator in (0,2) -- equal to or starts with
		Begin
			-------------------------------
			-- Check OPENITEM logging is on
			-------------------------------
			If exists(select 1 from INFORMATION_SCHEMA.TABLES 
				  where TABLE_NAME ='OPENITEM_iLOG')
			Begin
				---------------------------------
				-- Now check if the search ItemNo
				-- is using the draft prefix.
				---------------------------------
				Set @sSQLString="
					Select @bSearchDraft=1
					From SITECONTROL
					Where CONTROLID='DRAFTPREFIX'
					and @sItemNo like COLCHARACTER+'%'"
					
				exec @nErrorCode=sp_executesql @sSQLString,
							N'@bSearchDraft		bit		output,
							  @sItemNo		nvarchar(254)',
							  @bSearchDraft=@bSearchDraft		output,
							  @sItemNo     =@sItemNo
			End
		End
		
		If @sItemNo is not NULL
		or @nItemNoOperator between 2 and 6
		Begin
			If @bSearchDraft=1
				-------------------------------------------------------
				-- When finalised bills are being searched by an item 
				-- number that matches the formatting of a draft number
				-- then the OPENITEM_iLOG will be used to search using
				-- the draft number.
				-------------------------------------------------------
				Set @sWhere = @sWhere+char(10)+" and(O.OPENITEMNO " + dbo.fn_ConstructOperator(@nItemNoOperator,@String,@sItemNo, null,0)
				                     +CHAR(10)+"  OR EXISTS (SELECT 1"
				                     +CHAR(10)+"             from OPENITEM_iLOG O1"
				                     +CHAR(10)+"             where O1.ITEMENTITYNO=O.ITEMENTITYNO"
				                     +CHAR(10)+"             and   O1.ITEMTRANSNO =O.ITEMTRANSNO"
				                     +CHAR(10)+"             and   O1.ACCTENTITYNO=O.ACCTENTITYNO"
				                     +CHAR(10)+"             and   O1.ACCTDEBTORNO=O.ACCTDEBTORNO"
				                     +CHAR(10)+"             and   O1.OPENITEMNO " + dbo.fn_ConstructOperator(@nItemNoOperator,@String,@sItemNo, null,0)+"))"
			Else
				Set @sWhere = @sWhere+char(10)+" and O.OPENITEMNO " + dbo.fn_ConstructOperator(@nItemNoOperator,@String,@sItemNo, null,0)  
		End		

		If @bIsFinalised is not null
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.STATUS = " + CAST(@bIsFinalised as nchar(1)) 	  				   
		End
		
		If @nItemType is not NULL
		or @nItemTypeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.ITEMTYPE " + dbo.fn_ConstructOperator(@nItemTypeOperator,@Numeric,@nItemType, null,0)  
		End	
		
		If @nStaffKey is not NULL
		or @nStaffKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.EMPLOYEENO " + dbo.fn_ConstructOperator(@nStaffKeyOperator,@Numeric,@nStaffKey, null,0)  
		End	
		
		If @nDebtorKey is not NULL
		or @nDebtorKeyOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.ACCTDEBTORNO " + dbo.fn_ConstructOperator(@nDebtorKeyOperator,@CommaNumeric,@nDebtorKey, null,0)  
		End
		
		If @sCurrencyCode is not NULL
		or @nCurrencyCodeOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.CURRENCY" + dbo.fn_ConstructOperator(@nCurrencyCodeOperator,@String,@sCurrencyCode, null,0)  
		End	
		
		If @nMinLocalBalance is not NULL
		or @nMaxLocalBalance is not NULL
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.LOCALBALANCE "+dbo.fn_ConstructOperator(7,@Numeric,@nMinLocalBalance, @nMaxLocalBalance,@pbCalledFromCentura)
		End
		
		If  (@nDateRangeOperator is not null)
		and (@dtDateRangeFrom is not null
		or   @dtDateRangeTo is not null)
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.ITEMDATE "+dbo.fn_ConstructOperator(@nDateRangeOperator,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
		End
		
		If @bIsPrinted is not null
		Begin
			Set @sWhere = @sWhere+char(10)+" and O.BILLPRINTEDFLAG = " + CAST(@bIsPrinted as nchar(1)) 	  				   
		End
		
	End
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

Set @nCount = 1

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
		If @sColumn='StaffKey'
		Begin
			Set @sTableColumn='O.EMPLOYEENO'
		End
		Else 
		If @sColumn='StaffName'
		Begin
			Set @sTableColumn='dbo.fn_FormatName(N1.NAME, N1.FIRSTNAME, N1.TITLE, null)'

			If charindex('left join NAME N1',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join NAME N1	on (N1.NAMENO = O.EMPLOYEENO)' 
			End
		End
		Else 
		If @sColumn = 'StaffCode'
		Begin
			Set @sTableColumn='N1.NAMECODE'

			If charindex('left join NAME N1',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join NAME N1	on (N1.NAMENO = O.EMPLOYEENO)' 
			End
		End
		Else 
		If @sColumn = 'ItemNo'
		Begin
			Set @sTableColumn='O.OPENITEMNO'
		End
		Else 
		If @sColumn = 'ItemDate'
		Begin
			Set @sTableColumn='convert(datetime, convert(char(10),convert(datetime,O.ITEMDATE,120),120), 120)'
		End
		Else
		If @sColumn = 'DebtorKey'
		Begin
			Set @sTableColumn='O.ACCTDEBTORNO'
		End
		Else 
		If @sColumn='DebtorName'
		Begin
			Set @sTableColumn='dbo.fn_FormatName(N2.NAME, N2.FIRSTNAME, N2.TITLE, null)'

			If charindex('left join NAME N2',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join NAME N2	on (N2.NAMENO = O.ACCTDEBTORNO)' 
			End
		End
		Else
		If @sColumn='DebtorCode'
		Begin
			Set @sTableColumn='N2.NAMECODE'

			If charindex('left join NAME N2',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join NAME N2	on (N2.NAMENO = O.ACCTDEBTORNO)' 
			End
		End
		Else
		If @sColumn='IsPrinted'
		Begin
			Set @sTableColumn='CAST (ISNULL(O.BILLPRINTEDFLAG,0) as bit)'
		End
		Else
		If @sColumn='ItemTypeKey'
		Begin
			Set @sTableColumn='DIT.ITEM_TYPE_ID'
			If charindex('left join DEBTOR_ITEM_TYPE DIT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join DEBTOR_ITEM_TYPE DIT	on (DIT.ITEM_TYPE_ID = O.ITEMTYPE)' 
			End
		End		
		Else
		If @sColumn='ItemType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('DEBTOR_ITEM_TYPE','DESCRIPTION',null,'DIT',@sLookupCulture,@pbCalledFromCentura) 
			--Set @sTableColumn='RTRIM(DIT.DESCRIPTION)'
			If charindex('left join DEBTOR_ITEM_TYPE DIT',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join DEBTOR_ITEM_TYPE DIT	on (DIT.ITEM_TYPE_ID = O.ITEMTYPE)' 
			End
		End		
		Else
		If @sColumn='ClosedForBilling'
		Begin
			Set @sTableColumn='cast((isnull(CLOSEDFOR, 0) & 2) as bit)'
			If charindex('left join PERIOD P',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join PERIOD P	on (P.PERIODID = (select PERIODID from PERIOD where O.ITEMDATE between STARTDATE and ENDDATE))' 
			End
		End		
		Else
		If @sColumn='ItemTransNo'
		Begin
			Set @sTableColumn='O.ITEMTRANSNO'
		End
		Else
		If @sColumn='ItemEntityNo'
		Begin
			Set @sTableColumn='O.ITEMENTITYNO'
		End
		Else
		If @sColumn='BillPercent'
		Begin
			Set @sTableColumn='CAST (ISNULL(O.BILLPERCENTAGE,0) as decimal)'
		End
		Else
		If @sColumn='PaidPercent'
		Begin
			Set @sTableColumn='CASE WHEN (ISNULL(O.LOCALVALUE,0) <> 0 ) THEN cast(( O.LOCALVALUE - O.LOCALBALANCE ) / O.LOCALVALUE * 100 as decimal) ELSE cast(0 as decimal) END'
		End
		Else
		If @sColumn='RelatedItemNo'
		Begin
			Set @sTableColumn='O.ASSOCOPENITEMNO'
		End
		Else
		If @sColumn='RelatedItemTypeKey'
		Begin
			Set @sTableColumn='DIT1.ITEM_TYPE_ID'
			If charindex('left join DEBTOR_ITEM_TYPE DIT1',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 
				'left join OPENITEM O1 on (O1.OPENITEMNO = O.ASSOCOPENITEMNO'+char(10)+
				'                      and O1.ITEMENTITYNO=O.ITEMENTITYNO)'+char(10)+
				'left join DEBTOR_ITEM_TYPE DIT1 on (DIT1.ITEM_TYPE_ID = O1.ITEMTYPE)' 
			End
		End
		Else
		If @sColumn='BillStatus'
		Begin
			Set @sTableColumn='CASE WHEN (ISNULL(O.STATUS,0)=0) THEN ''DRAFT'' ELSE '''' END'
		End
		Else
		If @sColumn='ExchangeRate'
		Begin
			Set @sTableColumn='O.EXCHRATE'
		End
		Else
		If @sColumn='ForeignBalance'
		Begin
			Set @sTableColumn='O.FOREIGNBALANCE'
		End		
		Else
		If @sColumn='ForeignCurrencyCode'
		Begin
			Set @sTableColumn='O.CURRENCY'
		End
		Else
		If @sColumn='ForeignValue'
		Begin
			Set @sTableColumn='O.FOREIGNVALUE'
		End
		Else
		If @sColumn='LocalBalance'
		Begin
			Set @sTableColumn='O.LOCALBALANCE'
		End		
		Else
		If @sColumn='LocalCurrencyCode'
		Begin
			Set @sTableColumn='SLC.COLCHARACTER'

			If charindex('left join SITECONTROL SLC',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join SITECONTROL SLC	on (SLC.CONTROLID = ''CURRENCY'')' 
			End
		End
		Else
		If @sColumn='LocalValue'
		Begin
			Set @sTableColumn='O.LOCALVALUE'
		End
		Else
		If @sColumn='TotalAmount'
		Begin
			Set @sTableColumn='O.ITEMPRETAXVALUE'
		End
		Else
		If @sColumn = 'AcctEntityNo'
		Begin
			Set @sTableColumn='O.ACCTENTITYNO'
		End
		ELSE 
                If @sColumn = 'HasRestrictedCases'
		Begin
			Set @sTableColumn= 'dbo.fn_IsAnyCaseRestrictedInBill(O.ITEMTRANSNO, O.ITEMENTITYNO)'
		End
		Else
		If @sColumn='BillReversalNotAllowed'
		Begin
			Set @sTableColumn='case when ' + convert(varchar,@bFIStopsBillReversal) + ' = 1 then cast(ISNULL(TH.GLSTATUS,0) as bit) else cast(0 as bit) end'
			If charindex('left join TRANSACTIONHEADER TH',@sFrom)=0
			Begin
				Set @sFrom = @sFrom + CHAR(10) + 'left join TRANSACTIONHEADER TH on (TH.ENTITYNO = O.ITEMENTITYNO and TH.TRANSNO = O.ITEMTRANSNO)' 
			End
		End
                ELSE 
                If @sColumn in ('CaseRef', 'Country' , 'Title', 'CaseKey') 
                Begin

                        If charindex('left join CASES C',@sFrom)=0
			Begin
                                If @nCaseKeyOperator = 0 and @nCaseKey is not null
                                Begin
                                        Set @sFrom = @sFrom + CHAR(10) + 'left join CASES C on (C.CASEID = 
                                                                        (Select BC.CASEID 
                                                                        FROM dbo.fn_GetBillCases(O.ITEMTRANSNO, O.ITEMENTITYNO) BC'
                                        Set @sFrom = @sFrom + CHAR(10) + 'where BC.CASEID ' + dbo.fn_ConstructOperator(@nCaseKeyOperator,@Numeric,@nCaseKey, null,0)
                                        Set @sFrom = @sFrom + CHAR(10) + '))'
                                End
                                ELSE BEGIN
                                        Set @sFrom = @sFrom + CHAR(10) + 'left join CASES C on (C.CASEID = (
                                                                                Select top 1 ISNULL(MC.CASEID, BC.CASEID) 
                                                                                FROM dbo.fn_GetBillCases(O.ITEMTRANSNO, O.ITEMENTITYNO) BC
                                                                                left join dbo.fn_GetBillCases(O.ITEMTRANSNO, O.ITEMENTITYNO) MC on (MC.CASEID = O.MAINCASEID)
                                                                                join CASES CS on (ISNULL(MC.CASEID, BC.CASEID) = CS.CASEID)
                                                                                order by CS.IRN))'
                                End                                
			End

                        If @sColumn = 'CaseRef'
                        Begin
                                Set @sTableColumn='C.IRN'
                        End
                        ELSE If @sColumn = 'CaseKey'
                        Begin
                                Set @sTableColumn='C.CASEID'
                        End
                        Else If @sColumn = 'Country'
                        Begin
                                Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CN',@sLookupCulture,@pbCalledFromCentura)

                                Set @sFrom = @sFrom + CHAR(10) + 'left join COUNTRY CN on (CN.COUNTRYCODE = C.COUNTRYCODE)'
                        End
                        Else
                        Begin
                                Set @sTableColumn='C.TITLE'
                                Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)
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

	If @bFilterWIP = 1
	Begin
		Set @sWhere = @sWhere + char(10) + 
			"AND EXISTS (SELECT 1 " + char(10) +
			@sFromExists		+ char(10) +
			@sWhereExists		+ char(10) +
			")"
	End
	
	If @pbPrintSQL = 1
	Begin
		Print @sSelect + @sFrom + @sWhere + @sOrder
	End
	
	Exec ('SET ANSI_NULLS OFF ' + @sSelect + @sFrom + @sWhere + @sOrder)
	
	Select 	@nErrorCode =@@ERROR,
		@pnRowCount=@@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillSummary to public
GO
