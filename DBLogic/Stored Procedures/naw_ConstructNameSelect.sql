-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ConstructNameSelect
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[naw_ConstructNameSelect]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.naw_ConstructNameSelect.'
	drop procedure dbo.naw_ConstructNameSelect
	print '**** Creating procedure dbo.naw_ConstructNameSelect...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_ConstructNameSelect
	@pnTableCount			tinyint		OUTPUT,	-- the number of table in the constructed FROM clause	
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psTempTableName		nvarchar(60)	= null, -- Temporary table that may hold extended column details.
	@pnQueryContextKey		int		= null,	-- The key for the context of the query (default output requests).
	@ptXMLOutputRequests		ntext		= null,	-- The columns and sorting required in the result set. 
	@pbCalledFromCentura		bit		= 0,	-- Indicates that Centura called the stored procedure
	@psNameTypeKey			nvarchar(6)	= null,	-- The key for the NameType to restrict result set to.
	@pbAvailableNamesOnly		bit		= 0,	-- Indicates that Names deemed Unavailable should not be returned.
	@pbCurrentNamesOnly		bit		= 0	-- Indicates that Names which ceased should not be returned.

AS

-- PROCEDURE :	naw_ConstructNameSelect
-- VERSION :	66
-- DESCRIPTION:	Receives a list of columns and details of a required sort order and constructs
--		the components of the SELECT statement to meet the requirement
-- CALLED BY :	

-- MODIFICTIONS :
-- Date         Who  	Number	Version  	Change
-- ------------ ---- 	------	-------- 	------------------------------------------- 
-- 02 Oct 2003	JEK		1	New .net version based on v10 of na_ConstructNameSelect.
-- 07 Nov 2003	MF	RFC586	2	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 21 Nov 2003	TM	RFC612	3	Name Quick Search. Implement new fn_GetQueryOutputRequests to return temporary hard coded columns.
--					Modify the data extraction logic to assemble the 'Order by' in one statement. Add new 
--					@pnQueryContextKey, @ptXMLOutputRequests and @ptXMLFilterCriteria parameters. 
-- 21 Nov 2003	TM	RFC612	4	Remove logic in the order by preparation to do with the Class column.  
-- 25 Nov 2003	TM	RFC612	5	Replace the following code: 'If datalength(@ptXMLOutputRequests) = 0' whith the following:
--					'If datalength(@ptXMLOutputRequests) = 0 or datalength(@ptXMLOutputRequests) is null' 
-- 02 Dec 2003	JEK	RFC612	6	Sorting does not cater for sort only columns.
-- 09 Dec 2003	JEK	RFC643	7	Implement default QueryContextKey.
-- 23 Dec 2003 	TM	RFC710	8	XML parameters for name search. Remove the @pbExternalUser parameter. Add new 
--					'NULL' column. Append underscore to the correlation suffix.  	  
-- 30-Dec-2003	TM	RFC638	9	Display an appropriate description if an Office attribute is chosen.
-- 05-Jan-2004	TM	RFC710	10	Correct syntax error occurring when the 'DisplayMainEmail' column is selected.
--					To eliminate duplicated rows when 'DisplayTelecomNumber' is selected combine 
--					'DisplayTelecomNumber' and 'DisplayMainEmail' logic using 'derived table' approach.
-- 05-Jan-2004	TM	RFC638	11	Use TABLETYPE.DATABASETABLE = 'OFFICE' instead of the hard coding a specific table type.  
-- 16-Jan-2004	TM	RFC830	12	Add   - new MainContactNameKey and MainContactNameCode columns.
-- 25 Feb 2004	MF	SQA9662	13	Return DOCITEMKEY from XML
-- 09 Mar 2004	TM	RFC868	14	Separate the logic extracting 'DisplayMainEmail' from the 'DisplayTelecomNumber' logic 
--					and modified to implement new Name.MainEmail column.	
-- 11 Mar 2004	JEK	RCC868	15	Fix syntax error.
-- 13-May-2004	TM	RFC1246	16	Implement fn_GetCorrelationSuffix function to generate the correlation suffix 
--					based on the supplied qualifier.
-- 01-Jul-2004	TM	RFC1536	17	Add DebtorStatusActionKey column.
-- 02 Sep 2004	JEK	RFC1377	18	Pass new Centura parameter to fn_WrapQuotes
-- 07 Sep 2004	TM	RFC1158	19	Add new columns.
-- 21 Sep 2004	TM	RFC886	20	Implement translation.
-- 29 Sep 2004	TM	RFC1806	21	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.		
-- 30 Sep 2004	JEK	RFC1695 22	Implement @pbCalledFromCentura in fn_GetQueryOutputRequests interface
-- 23 Dec 2004	TM	RFC1844	23	Remove @psSelect, @psFrom, @psWhere and @psOrder output parameters and 
--					load parts of an SQL into the #TempConstructSQL temporary table using 
--					ip_LoadConstructSQL stored procedure.
-- 15 Feb 2005	TM	RFC1743	24	Add new columns: OrganisationName, OrganisationCode, OrganisationKey, Position 
--					and IsInstructor columns.
-- 15 May 2005	JEK	RFC2508	25	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 30 May 2005	TM	RFC1933	26	Implement new HasWorkBenchAccess flag.
-- 30 May 2005	TM	RFC1933	27	Need to select external Access Accounts instead of internal for HasWorkBenchAccess column.
--					Improve performance.
-- 06 Jun 2005	TM	RFC2630	28	Pass null as new @psPresentationType parameter in the fn_GetQueryOutputRequests function.
-- 05 Jul 2005	TM	RFC1480	29	Add new columns for the Name report writer.
-- 16 Jan 2006	TM	RFC1659	30	Add the following new columns: NameVariantKey, NameVariant (formatted for display),
--					VariantPropertyType, VariantReason and VariantSequence.
-- 09 Mar 2006	IB	RFC3325 	31	Name Search/List for external users.
-- 17 Jun 2008	LP	RFC4342	32	Add new Unavailable and UnavailableReason columns.
--					Add new @psNameTypeKey parameter
-- 04 Jul 2008	LP	RFC5764	33	Add new IsCRM, LeadOwner, LeadSource, LeadStatus and LeadReferredBy columns.
-- 08 Jul 2008  LP      RFC6537 34      Add new HasOpportunity column.
-- 23 Jul 2008  LP      RFC4342 35      Fix Unrestricted Name Types logic. See SQA16707 for more details.
-- 20 Nov 2008	AT	RFC5771	36	Add new Lead report columns
-- 28 Nov 2008  PS  	RFC3481 37  	Add new NameRestrictionFlag column.   
-- 11 Dec 2008	MF	17136	38	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 12 Jan 2009	SF	RFC7464	39	Add new DebtorStatusKey column (this was not added in RFC7383)
-- 06 Jan 2009  PS  	RFC7383 40      Add new DebtorStatusKey column 
-- 09 Apr 2009  LP      RFC7867 41      Encode Name Type Description when returning as part of PickList result set.
-- 25 May 2009  vql     S17723	42     Conflict Search crashing. Remove the @pbExternalUser parameter, its not being used.
-- 05 Nov 2009	LP	R6712	43	Add new IsEditable data item.
-- 22 Jan 2010	MF	R8834	44	Rework of RFC6712. Improve performance of this row level security code.
-- 01 Feb 2010	LP	R6712	45	Exclude Insert privilege from IsEditable flag calculation.
-- 12 Apr 2010	MF	R9104	46	If no explicit Order By columns have been identified then default to the first column.
-- 11 May 2010	PA	R9097	47	Retrieve the TAXNO from NAME table and remove the geting of VATNO from the ORGANISATION table.
-- 25 May 2010	LP	R100274 48	Fix error when SupplierPaymentMethod is to be returned (missing Left Join keyword).
-- 23 Jun 2010	MS	R7269	49	Add new SeparateMarginFlag column.
-- 06 Jul 2010	MF	R8795	50	Allow Staff Responsible in Available Columns in Advanced Name Search
-- 04 Oct 2010  DV	R7914	51	Add new StandingInstText column
-- 22 Mar 2011  MS	R0492	52	Add CountryCode column
-- 07 Jul 2011	DL	R10830	53	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 11 Apr 2013	DV	R13270	54	Increase the length of nvarchar to 11 when casting or declaring integer
-- 29 Oct 2013	AK	R13789	55	Remove Spaces from PROCEDUREITEMID
-- 23 May 2014	LP	R29589	56	Allow hiding of Names flagged as Unavailable. By default they will be displayed.
-- 02 Sep 2014	MF	R38107	57	Allow the number of Cases & Name Type associated with the Name to be reported. This will 
--					utilise any case filtering that has also been provided.
-- 04 Sep 2014	MF	R38217	58	New supplier related columns to display.
-- 10 Oct 2014	MF	R38436	59	Allow the reporting of details for Associated Names.
-- 19 Jan 2015	MF	R43709	60	Extension of R38436 to add Position and PositionCategory for Associated Names.
-- 17 Apr 2015	MF	46372	61	Revist of 38436. When no Relationship is being used on the Associated Name I had not allowed
--					for the correlation name of the NAME table already being used.
-- 02 Nov 2015	vql	R53910	62	Adjust formatted names logic (DR-15543).
-- 19 Apr 2016  MS      R52206  63      Added wrapquote to avoid sql injection
-- 10 Feb 2017	MF	27718	64	Allow  the reporting of a Standing Instruction of a given instruction type.
-- 17 Jul 2018  AK  R74372  65  included DisplayNameCode in resultset
-- 12 Jul 2019	KT	DR-49980 66	Added @bCurrentNamesOnly for get only ceased records and only available records as per the parameter.

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	AbbreviatedName (RFC1480)
--	AirportName
--	Alias
--	AssociatedNameCode		(RFC38436)
--	AssociatedName			(RFC38436)
--	AssociatedRelationship		(RFC38436)
--	AssociatedNameStreetAddress	(RFC38436)
--	AssociatedNamePostalAddress	(RFC38436)
--	AssociatedNameEmail		(RFC38436)
--	AssociatedNamePhone		(RFC38436)
--	AssociatedNamePostion		(RFC43709)
--	AssociatedNamePostionCategory	(RFC43709)
--	AttributeAll (RFC1480)
--	AttributeDescription
--	BillingCurrencyKey
--	BillingCurrencyDescription
--	BillingFrequencyDescription
--	CapacityToSign (RFC1480)
--	CaseCount (RFC38107)
--	CasualSalutation
--	City
--	CorrespondenceInstructions
--      CountryCode (RFC100492)
--	CountryName
--	DateCeased
--	DateChanged
--	DateEntered
--	DebitNoteCopies
--	DebtorCreditLimit (RFC1158)
--	DebtorStatusKey	(RFC7383,RFC7464)
-- 	DebtorStatusActionKey (RFC1536)
--	DebtorStatusDescription
--	DebtorStatusKey (RFC7383)
--	DebtorTypeDescription
--	DisplayMainEmail
--	DisplayMainFax
--	DisplayMainPhone
--	DisplayName
--	DisplayTelecomNumber
--	GivenNames
--	GroupComments
--	GroupTitle
--	HasMultiCaseBills
--	HasWorkBenchAccess (RFC1933)
--      HasOpportunity (RFC6537)
--	Incorporated
--	IsClient
--      IsCRM (RFC5764)
--	IsEditable (RFC6712)
--	IsFemale
--	IsIndividual
--	IsInstructor (RFC1743)
--	IsLocalClient
--	IsMale
--	IsOrganisation
--	IsStaff
--	LeadOwner (RFC5764)
--	LeadSource (RFC5764)
--	LeadStatus (RFC5764)
--	LeadReferredBy (RFC5764)
-- 	LocalCurrencyCode (RFC1158)
--	MailingAddress
--	MailingLabel
--	MailingName
--	MainContactDisplayName
--	MainContactMailingName
--  	MainContactNameKey (RFC830)
--  	MainContactNameCode (RFC830)
--	NameCategoryDescription
--	NameCode
--	NameKey
--	NameRestrictionFlag (RFC3481)
--	NameType (RFC38107)
--	NationalityDescription
--	NameVariant (RFC1659)
--	NameVariantKey (RFC1659)
-- 	NULL
--	OrganisationNumber
--	OrganisationCode (RFC1743)
--	OrganisationKey (RFC1743)
--	OrganisationName (RFC1743)
--	ParentDisplayName
--	Position (RFC1743)
--	Postcode
--	PurchaseCurrencyCode (RFC1158)
--	PurchaseCurrencyDescription (RFC1158)
--	PurchaseDescription (RFC38217)
--	SearchKey1
--	SearchKey2
--	StaffClassification (RFC1158)
--	StaffProfitCentre (RFC1158)
--	StaffProfitCentreCode (RFC1158)
--	StateName
--	StreetAddress
--	SupplierPaymentMethod (RFC1158)
--	SupplierPaymentTerms (RFC1158)
--	StaffResponsibleCode (RFC8795)
--	StaffResponsibleEmail (RFC8795)
--	StaffResponsibleFax (RFC8795)
--	StaffResponsibleName (RFC8795)
--	StaffResponsiblePhone (RFC8795)
--	StaffResponsibleProperty Type (RFC8795)
--	StaffResponsibleRole (RFC8795)
--	SupplierRestriction (RFC1158)
--	SupplierRestrictionActionKey (RFC1158)
--	SupplierType (RFC1158)
--	TaxNumber
--	TaxTreatment
--	Text
--	TitleDescription
--	Unavailable (RFC4342)
--	UnavailableReason (RFC4342)
--	VariantPropertyType (RFC1659)
--	VariantReason (RFC1659)
--	VariantSequence (RFC1659)
--	YourPurchaseOrderNo
--	SeparateMarginFlag
--      StandingInstrText


-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	AN (RFC38436)
--	AP
--	AT
--	BF
--	CAPSGN (RFC1480)
--	CFBI (RFC1480)
--	CN   (RFC38107)
--	CNX
--	CNI (RFC1743)
--	CP
--	CR (RFC1158)
--	CS
--	CU
--	CUR (RFC1158)
--	DS
--	DT
--	EM (RFC1158)
--   	EMP (RFC1743)
-- 	FBI (RFC1480)
--	FR (RFC1158)
--	FX
--	I
--	INSR (RFC1743)
--	IP
--	LD (RFC5764)
--	LDREF (RFC5764)
--	LDRES (RFC5764)
--	ML (RFC868)
--	N
--	N1
--	N2
--	N3
--	NA
--	NC
--	NEMP (RFC1480)
--	NF
--	NREF (RFC5764)
--	NR   (RFC38436)
--	NRES (RFC5764)
--	NT
--	NT1 (RFC3481)
--	NTCA (RFC5764)
--      NTCU (RFC4342)
--	NTD (RFC4342)
--	NVR (RFC1659)
--	NX  (RFC38107)
--	O
--	OFAT (RFC638)
--      OPP (RFC6537)
--	ORG (RFC1743)
--	PA
--	PC (RFC1158)
--	PH
--	PM (RFC1158)
--	PTV (RFC1659)
--	RS (RFC6712)
--	SA
--	SC (RFC1158)
--	SP (RFC38436)
--	SS
--	ST
--	RES (RFC8795)
--	RST (RFC1158)
--	T
--	TA
--	TC (RFC1158)
--	TCV (RFC16599)
--	TCLSC (RFC5764)
--	TCLST (RFC5764)
--	TR
-- 	TS (RFC1158)
--	TTP (RFC638)
--	TX
--	WBAccess (RFC1933)
--      NI (RFC7914)


set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode		int
declare	@sDelimiter		nchar(1)
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
Declare @sCommaString		nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String
declare	@sSQLString		nvarchar(4000)
declare @nColumnNo		tinyint
declare @nFirstColumnNo		tinyint		 --RFC9104
declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sFirstPublishName	nvarchar(50)	 --RFC9104
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @sFirstTableColumn	nvarchar(1000)	 --RFC9104
declare @nLastPosition		smallint
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)
declare @sTable1		nvarchar(25)
declare @sTable2		nvarchar(25)
declare @sTable3		nvarchar(25)
declare @sTable4		nvarchar(25)
declare @sTable5		nvarchar(25)
declare	@bOrderByDefined	bit		--RFC9104
declare @bOfficeSecurity	bit		--RFC13142
declare	@bNameTypeSecurity	bit		--RFC13142

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 			int 		

declare @nOutRequestsRowCount	int
declare @nCount			int
Declare @sList			nvarchar(4000)	-- variable to prepare a comma separated list of values

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

declare @sAddSelectString	nvarchar(4000)	-- the SELECT string currently being searched for
declare	@sCurrentSelectString	nvarchar(4000)	-- the SELECT string being constructed until it exceeds 4000 characters
declare @sAddFromString		nvarchar(4000)	-- the FROM string currently being searched for
declare	@sCurrentFromString	nvarchar(4000)	-- the FROM string being constructed until it exceeds 4000 characters
declare @sAddWhereString	nvarchar(4000)	-- the WHERE string currently being searched for
declare	@sCurrentWhereString	nvarchar(4000)	-- the WHERE string being constructed until it exceeds 4000 characters
declare @sAddOrderByString	nvarchar(4000)	-- the ORDER BY string currently being searched for
declare	@sCurrentOrderByString	nvarchar(4000)	-- the ORDER BY string being constructed until it exceeds 4000 characters

declare	@sSelect		char(1)
declare	@sFrom			char(1)
declare @sWhere			char(1)
declare	@sOrderBy		char(1)
declare @sReturn		char(1)

Declare @sLookupCulture		nvarchar(10)
Declare @sNameTypeDescription   nvarchar(100)   -- the DESCRIPTION of the NAMETYPE specified by @psNameTypeKey
Declare @sNameTypeRestriction nvarchar(6)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @psNameTypeKey = ISNULL(@psNameTypeKey,'')

-- Initialisation
set @ErrorCode			=0
set @nOutRequestsRowCount	=0
set @bOrderByDefined		=0	--RFC9104
set @nCount			=1
set @sSelect			='S'
set @sFrom			='F'
set @sWhere			='W'
set @sOrderBy			='O'
set @sDelimiter			='^'
set @sReturn			=char(10)
set @sCurrentSelectString	='Select '
set @sCurrentFromString		=' From NAME N'
set @sCurrentWhereString	=' '		-- Make sure that the length of the @sCurrentWhereString is more than 0 so there will always be a row of the 'Where' type in the #TempConstructSQL.
set @sNameTypeRestriction = @psNameTypeKey
set @pnTableCount		=1
set @sCommaString		='CS'

-- Default NameTypeKey
If @ErrorCode = 0
and @psNameTypeKey is not null
Begin
        Set @sSQLString = "select @sNameTypeDescription = "+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,NULL,@sLookupCulture,@pbCalledFromCentura)+" from NAMETYPE where NAMETYPE = @psNameTypeKey"
        Exec @ErrorCode = sp_executesql @sSQLString,
				        N'@sNameTypeDescription nvarchar(100)   OUTPUT,
					@psNameTypeKey		nvarchar(6)',
				        @sNameTypeDescription	= @sNameTypeDescription	OUTPUT,
				        @psNameTypeKey		= @psNameTypeKey
End
		        
If @ErrorCode = 0
and @psNameTypeKey is not null
Begin
	-- If the NameType does not have the "Same Name Type" flag
	-- on then change the NameType used for "Unrestricted Name Type"
	Select @psNameTypeKey='~~~'
	from NAMETYPE
	where NAMETYPE=@psNameTypeKey
	and PICKLISTFLAGS&16=0
End

If datalength(@ptXMLOutputRequests) = 0
or datalength(@ptXMLOutputRequests) is null
Begin
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 10)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, default, null,@pbCalledFromCentura,null)

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
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc,@pbCalledFromCentura,null)
	
	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End

-- Loop through each column in order to construct the components of the SELECT
While @nCount < @nOutRequestsRowCount + 1
and   @ErrorCode=0
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

	If  @ErrorCode=0
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

	If @ErrorCode=0
	Begin
		If @sColumn='NULL'
		Begin
			Set @sTableColumn='NULL'

			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By
		End		

		Else If @sColumn='NameKey'
		Begin
--			Set @sTableColumn='Cast(N.NAMENO as varchar(10))'
			Set @sTableColumn='N.NAMENO'
		End

		Else If @sColumn='CaseCount'
		Begin
			Set @sTableColumn='CN.CASECOUNT'
		End

		Else If @sColumn='NameType'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NX',@sLookupCulture,@pbCalledFromCentura) 
		End

		Else If @sColumn='DateCeased'
		Begin
			Set @sTableColumn='N.DATECEASED'
		End

		Else If @sColumn='DateChanged'
		Begin
			Set @sTableColumn='isnull(N.DATECHANGED,N.DATEENTERED)'
		End

		Else If @sColumn='DateEntered'
		Begin
			Set @sTableColumn='N.DATEENTERED'
		End

		Else If @sColumn='DisplayName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)'
		End

		Else If @sColumn='MailingName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, isnull(N.NAMESTYLE,7101))'
		End

		Else If @sColumn='GivenNames'
		Begin
			Set @sTableColumn='N.FIRSTNAME'
		End

		Else If @sColumn='IsClient'
		Begin
			Set @sTableColumn='CASE WHEN(N.USEDASFLAG&4=4) THEN cast(1 as bit) ELSE cast(0 as bit) END'
		End

		Else If @sColumn='IsIndividual'
		Begin
			Set @sTableColumn='CASE WHEN(N.USEDASFLAG&1=1) THEN cast(1 as bit) ELSE cast(0 as bit) END'
		End

		Else If @sColumn='IsOrganisation'
		Begin
			Set @sTableColumn='CASE WHEN(N.USEDASFLAG&1=0) THEN cast(1 as bit) ELSE cast(0 as bit) END'
		End

		Else If @sColumn='IsStaff'
		Begin
			Set @sTableColumn='CASE WHEN(N.USEDASFLAG&2=2) THEN cast(1 as bit) ELSE cast(0 as bit) END'
		End

		Else If @sColumn='NameCode'
		Begin
			Set @sTableColumn='N.NAMECODE'
		End

		Else If @sColumn='Remarks'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAME','REMARKS',null,'N',@sLookupCulture,@pbCalledFromCentura) 
		End

		Else If @sColumn='SearchKey1'
		Begin
			Set @sTableColumn='N.SEARCHKEY1'
		End

		Else If @sColumn='SearchKey2'
		Begin
			Set @sTableColumn='N.SEARCHKEY2'
		End

		Else If @sColumn='TitleDescription'
		Begin
			Set @sTableColumn='N.TITLE'
		End		
		
                Else If @sColumn='TaxNumber'
		Begin
			Set @sTableColumn='N.TAXNO'
		End

		Else If @sColumn in ('IsMale','IsFemale')
		Begin
			If @sColumn='IsMale'
			Begin
				Set @sTableColumn="CASE WHEN(I.SEX='M') THEN cast(1 as bit) ELSE cast(0 as bit) END"
			End
			Else Begin
				Set @sTableColumn="CASE WHEN(I.SEX='F') THEN cast(1 as bit) ELSE cast(0 as bit) END"
			End

			Set @sAddFromString = 'Left Join INDIVIDUAL I		on (I.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('CasualSalutation','FormalSalutation')
		Begin
			If @sColumn='CasualSalutation'
			Begin
				Set @sTableColumn='I.CASUALSALUTATION'
			End
			Else Begin
				Set @sTableColumn='I.FORMALSALUTATION'
			End
			
			Set @sAddFromString = 'Left Join INDIVIDUAL I		on (I.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('Incorporated','OrganisationNumber')
		Begin
			If @sColumn='Incorporated'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ORGANISATION','INCORPORATED',null,'O',@sLookupCulture,@pbCalledFromCentura) 
			End
			Else 
			If @sColumn='OrganisationNumber'
			Begin
				Set @sTableColumn='O.REGISTRATIONNO'
			End

			Set @sAddFromString = 'Left Join ORGANISATION O		on (O.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('ParentDisplayName')
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N2.NAMENO, null)'

			Set @sAddFromString = 'Left Join ORGANISATION O		on (O.NAMENO=N.NAMENO)'			
				    
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join NAME N2	on (N2.NAMENO=O.PARENT)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('IsLocalClient')
		Begin
			Set @sTableColumn='Cast(IP.LOCALCLIENTFLAG as bit)'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('HasMultiCaseBills', 'HasMultiCaseBillsByOwner')
		Begin
			If @sColumn = 'HasMultiCaseBills'
			Begin
				Set @sTableColumn='CASE WHEN(IP.CONSOLIDATION>0) THEN Cast(1 as bit) ELSE Cast(0 as bit) END'
			End
			Else Begin
				Set @sTableColumn='CASE WHEN(IP.CONSOLIDATION=3) THEN Cast(1 as bit) ELSE Cast(0 as bit) END'
			End

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End
		
		Else If @sColumn in ('SeparateMarginFlag')
		Begin
			Set @sTableColumn='Cast(IP.SEPARATEMARGINFLAG as bit)'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('AirportName')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('AIRPORT','AIRPORTNAME',null,'AP',@sLookupCulture,@pbCalledFromCentura) 
		
			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'			
				    
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End			
			
			Set @sAddFromString = 'Left Join AIRPORT AP		on (AP.AIRPORTCODE=IP.AIRPORTCODE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	
		End

		Else If @sColumn in ('CorrespondenceInstructions')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('IPNAME','CORRESPONDENCE',null,'IP',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('DebitNoteCopies')
		Begin
			Set @sTableColumn='IP.DEBITCOPIES'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('BillingCurrencyKey')
		Begin
			Set @sTableColumn='IP.CURRENCY'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('BillingCurrencyDescription')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CU',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join CURRENCY CU		on (CU.CURRENCY=IP.CURRENCY)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('ReceivableTermsDays')
		Begin
			Set @sTableColumn='IP.TRADINGTERMS'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('YourPurchaseOrderNo')
		Begin
			Set @sTableColumn='IP.PURCHASEORDERNO'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('DebtorStatusKey', 'DebtorStatusDescription',
				     'DebtorStatusActionKey','DebtorStatusKey')
		Begin
			If @sColumn='DebtorStatusDescription'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura) 
			End
			Else If @sColumn='DebtorStatusKey'
			Begin
				Set @sTableColumn='DS.BADDEBTOR'
			End
			Else 
			Begin
				Set @sTableColumn='DS.ACTIONFLAG'
			End			

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join DEBTORSTATUS DS		on (DS.BADDEBTOR=IP.BADDEBTOR)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End
		Else If @sColumn in ('Unavailable', 'UnavailableReason')
		Begin
			If @sColumn in ('Unavailable')
			Begin
				Set @sTableColumn="CASE WHEN (N.DATECEASED IS NOT NULL AND N.DATECEASED <= getdate()) OR ISNULL(NTCU.ALLOW,0) <> 1 THEN 1 ELSE 0 END"
				Set @sAddFromString = "join (select distinct N.NAMENO as [NAMENO], CASE WHEN "+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+"='' THEN 1 ELSE NTC.ALLOW END as [ALLOW]"

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString ="join (select distinct N.NAMENO as [NAMENO], CASE WHEN "+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+"='' THEN 1 ELSE NTC.ALLOW END as [ALLOW]"
								+char(10)+"FROM NAME N"
								+char(10)+"left join NAMETYPECLASSIFICATION NTC2 on (NTC2.NAMENO=N.NAMENO and NTC2.NAMETYPE<>"+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+")"
								+char(10)+"left join NAMETYPECLASSIFICATION NTC ON (NTC.NAMENO=N.NAMENO and NTC.NAMETYPE = "+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+")"
								+char(10)+"where NTC2.ALLOW=1 OR NTC.ALLOW=1 ) NTCU on (NTCU.NAMENO = N.NAMENO"+
								case when @pbAvailableNamesOnly=1 THEN " AND ((N.DATECEASED IS NULL OR N.DATECEASED > getdate()) AND ISNULL(NTCU.ALLOW,0) = 1)" ELSE case when @pbCurrentNamesOnly=0 THEN " AND ISNULL(NTCU.ALLOW,0) = 1" ELSE NULL END END
								+char(10)+")"				
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			Else If @sColumn in ('UnavailableReason')
			Begin
				Set @sTableColumn="CASE WHEN N.DATECEASED <= getdate() THEN 'Ceased' WHEN ISNULL(NTCU.ALLOW,0) <> 1 THEN 'Unavailable:"+ replace(@sNameTypeDescription,"'","''") +"' ELSE NULL END"
				Set @sAddFromString = "join (select distinct N.NAMENO as [NAMENO], CASE WHEN "+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+"='' THEN 1 ELSE NTC.ALLOW END as [ALLOW]"
						  
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString ="join (select distinct N.NAMENO as [NAMENO], CASE WHEN "+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+"='' THEN 1 ELSE NTC.ALLOW END as [ALLOW]"
													+char(10)+"FROM NAME N"
													+char(10)+"left join NAMETYPECLASSIFICATION NTC2 on (NTC2.NAMENO=N.NAMENO and NTC2.NAMETYPE<>"+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+")"
													+char(10)+"left join NAMETYPECLASSIFICATION NTC ON (NTC.NAMENO=N.NAMENO and NTC.NAMETYPE = "+dbo.fn_WrapQuotes(@psNameTypeKey,0,0)+")"
													+char(10)+"where NTC2.ALLOW=1 OR NTC.ALLOW=1 ) NTCU on (NTCU.NAMENO = N.NAMENO)"
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
		End
		Else If @sColumn in ('IsCRM')
		Begin
		        Set @sTableColumn='CASE WHEN NTCA.NAMENO is not null then CAST(1 as bit) ELSE CAST(0 as bit) END'
			Set @sAddFromString = "left join (select DISTINCT NTCA.NAMENO as [NAMENO]" 	
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "left join (select DISTINCT NTC2.NAMENO as [NAMENO]"
				                +char(10)+"from NAMETYPECLASSIFICATION NTC2"
				                +char(10)+"join NAMETYPE NTP on (NTP.NAMETYPE = NTC2.NAMETYPE and NTP.PICKLISTFLAGS&32=32) WHERE NTC2.ALLOW=1) NTCA on (NTCA.NAMENO = N.NAMENO)"
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				Set @pnTableCount=@pnTableCount+1
			End
			
		End
		Else If @sColumn in ('BillingFrequencyDescription')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'BF',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join TABLECODES BF		on (BF.TABLECODE=IP.BILLINGFREQUENCY)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('DebtorTypeDescription')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'DT',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join TABLECODES DT		on (DT.TABLECODE=IP.DEBTORTYPE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('NameCategoryDescription')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'NC',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join TABLECODES NC		on (NC.TABLECODE=IP.CATEGORY)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('TaxTreatment')
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			Set @sAddFromString = 'Left Join TAXRATES TR		on (TR.TAXCODE=IP.TAXCODE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='NationalityDescription'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRYADJECTIVE',null,'CNX',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join COUNTRY CNX		on (CNX.COUNTRYCODE=N.NATIONALITY)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End
	
		Else If @sColumn='MainContactNameKey'
		Begin
			Set @sTableColumn='N1.NAMENO'

			Set @sAddFromString = 'Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End			
		End

		Else If @sColumn='MainContactNameCode'
		Begin
			Set @sTableColumn='N1.NAMECODE'

			Set @sAddFromString = 'Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		
		End
	
		Else If @sColumn='MainContactDisplayName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N1.NAMENO, NULL)'

			Set @sAddFromString = 'Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		
		End

		Else If @sColumn='MainContactMailingName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N1.NAMENO, isnull(N1.NAMESTYLE,7101))'

			Set @sAddFromString = 'Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		
		End

		Else If @sColumn='City'	-- of the Postal Address
		Begin
			Set @sTableColumn='PA.CITY'

			Set @sAddFromString = 'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	
		End

		Else If @sColumn='Postcode'	-- of the Postal Address
		Begin
			Set @sTableColumn='PA.POSTCODE'

			Set @sAddFromString = 'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		
		End
                
                Else If @sColumn in ('CountryName', 'CountryCode')	-- of the Postal Address
		Begin
                        IF @sColumn = 'CountryName'
                        Begin
			        Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CP',@sLookupCulture,@pbCalledFromCentura) 
                        End
                        Else
                        Begin
                                Set @sTableColumn='CP.COUNTRYCODE'
                        End

			Set @sAddFromString = 'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		

			Set @sAddFromString = 'Left Join COUNTRY CP		on (CP.COUNTRYCODE=PA.COUNTRYCODE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	
		End

		Else If @sColumn='StateName'	-- of the Postal Address
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('STATE','STATENAME',null,'ST',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	

			Set @sAddFromString = 'Left Join STATE ST		on (ST.COUNTRYCODE=PA.COUNTRYCODE'
				    +char(10)+'                    		and ST.STATE=PA.STATE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	
		End

		Else If @sColumn='MailingAddress'	-- of the Postal Address
		Begin
			Set @sTableColumn='dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, ST.STATENAME, PA.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)'

			Set @sAddFromString = 'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	

			Set @sAddFromString = 'Left Join COUNTRY CP		on (CP.COUNTRYCODE=PA.COUNTRYCODE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	

			Set @sAddFromString = 'Left Join STATE ST		on (ST.COUNTRYCODE=PA.COUNTRYCODE'
				    +char(10)+'                    		and ST.STATE=PA.STATE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	
		End

		Else If @sColumn='MailingLabel'	-- of the Postal Address
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N1.NAMENO, isnull(N1.NAMESTYLE,7101))'
					+'+CASE WHEN(N1.NAME is not null) THEN char(13)+char(10) END'
					+'+dbo.fn_FormatNameUsingNameNo(N.NAMENO, isnull(N.NAMESTYLE,7101))+char(13)+char(10)'
					+'+dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, ST.STATENAME, PA.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)'

			Set @sAddFromString = 'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	

			Set @sAddFromString = 'Left Join COUNTRY CP		on (CP.COUNTRYCODE=PA.COUNTRYCODE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	

			Set @sAddFromString = 'Left Join STATE ST		on (ST.COUNTRYCODE=PA.COUNTRYCODE'
				    +char(10)+'                    		and ST.STATE=PA.STATE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	

			Set @sAddFromString = 'Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		
		End

		Else If @sColumn='StreetAddress'
		Begin
			Set @sTableColumn='dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, CS.POSTALNAME, CS.POSTCODEFIRST, CS.STATEABBREVIATED, CS.POSTCODELITERAL, CS.ADDRESSSTYLE)'

			Set @sAddFromString = 'Left Join ADDRESS SA		on (SA.ADDRESSCODE=N.STREETADDRESS)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		

			Set @sAddFromString = 'Left Join COUNTRY CS		on (CS.COUNTRYCODE=SA.COUNTRYCODE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End		


			Set @sAddFromString = 'Left Join STATE SS		on (SS.COUNTRYCODE=SA.COUNTRYCODE'
				    +char(10)+'                    		and SS.STATE=SA.STATE)'


			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End	
		End

		Else If @sColumn='GroupTitle'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYTITLE',null,'NF',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join NAMEFAMILY NF		on (NF.FAMILYNO=N.FAMILYNO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='GroupComments'
		Begin
			Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMEFAMILY','FAMILYCOMMENTS',null,'NF',@sLookupCulture,@pbCalledFromCentura) 

			Set @sAddFromString = 'Left Join NAMEFAMILY NF		on (NF.FAMILYNO=N.FAMILYNO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End		

		Else If @sColumn='AttributeDescription'
		Begin
			Set @sTable1='TA'+@sCorrelationSuffix
			Set @sTable2='AT'+@sCorrelationSuffix
			Set @sTable3='OFAT'+@sCorrelationSuffix					
			Set @sTable4='TTP'+@sCorrelationSuffix
			Set @sTableColumn="CASE WHEN UPPER("+@sTable4+".DATABASETABLE) = 'OFFICE' THEN "+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,@sTable3,@sLookupCulture,@pbCalledFromCentura)+
												" ELSE "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,@sTable2,@sLookupCulture,@pbCalledFromCentura)+" END"  
			Set @sAddFromString = 'Left Join TABLEATTRIBUTES '+@sTable1

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join TABLEATTRIBUTES "+@sTable1+"	on ("+@sTable1+".GENERICKEY=cast(N.NAMENO as varchar)"
						   +char(10)+"                                 	and "+@sTable1+".PARENTTABLE='NAME'"
						   +char(10)+"                                 	and "+@sTable1+".TABLETYPE=" + @sQualifier+")"
						   +char(10)+"Left Join TABLETYPE "+@sTable4+"  		on ("+@sTable4+".TABLETYPE="+@sTable1+".TABLETYPE)"	
						   +char(10)+"Left Join TABLECODES "+@sTable2+"  		on ("+@sTable2+".TABLECODE="+@sTable1+".TABLECODE)"
						   +char(10)+"Left Join OFFICE "+@sTable3+"		on ("+@sTable3+".OFFICEID = "+@sTable1+".TABLECODE)"			   												

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+4
			End
		End

		Else If @sColumn='AttributeAll'	
		Begin	
			Set @sTableColumn="dbo.fn_GetConcatenatedAttributes("+cast(@pnUserIdentityId as varchar(11))+", "+case when @sLookupCulture is not null then dbo.fn_WrapQuotes(@sLookupCulture,0,0) else 'null' end+", "+isnull(cast(@pbCalledFromCentura as char(1)),0)+", 'NAME', cast(N.NAMENO as varchar(11)), char(13)+char(10))"
		End	

		Else If @sColumn='Alias'
		Begin
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(ALIASTYPE, 0, @pbCalledFromCentura)
			From dbo.fn_FilterUserAliasTypes(@pnUserIdentityId, null, null, @pbCalledFromCentura)
			If @sList is null
			Begin
				Set @sList = "''"
			End

			Set @sTable1='NA'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.ALIAS'

			Set @sAddFromString = 'Left Join NAMEALIAS '+@sTable1

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join NAMEALIAS "+@sTable1+"		on ("+@sTable1+".NAMENO=N.NAMENO"
				            +char(10)+"                        			and "+@sTable1+".ALIASTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
				            +char(10)+" 					and "+@sTable1+".ALIASTYPE in ("+@sList+"))"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='Text'
		Begin
			Set @sList = null
			Select @sList = @sList + nullif(',', ',' + @sList) + dbo.fn_WrapQuotes(TEXTTYPE, 0, @pbCalledFromCentura)
			From dbo.fn_FilterUserTextTypes(@pnUserIdentityId, null, null, @pbCalledFromCentura)
			If @sList is null
			Begin
				Set @sList = "''"
			End

			Set @sTable1='TX'+@sCorrelationSuffix
			Set @sTableColumn=dbo.fn_SqlTranslationSelect('NAMETEXT',null,'TEXT',@sTable1,@sLookupCulture,@pbCalledFromCentura)

			Set @sAddFromString = 'Left Join NAMETEXT '+@sTable1

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join NAMETEXT "+@sTable1+"		on ("+@sTable1+".NAMENO=N.NAMENO"
					    +char(10)+"                                 	and "+@sTable1+".TEXTTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
				            +char(10)+" 					and "+@sTable1+".TEXTTYPE in ("+@sList+"))"
					    +char(10)+dbo.fn_SqlTranslationFrom('NAMETEXT',null,'TEXT',@sTable1,@sLookupCulture,@pbCalledFromCentura)

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End		

		Else If @sColumn='DisplayTelecomNumber'				     
		Begin	
			Set @sTable1='TBL'+@sCorrelationSuffix
			
			Set @sTableColumn='dbo.fn_FormatTelecom('+@sTable1+'.TELECOMTYPE, '+@sTable1+'.ISD, '+@sTable1+'.AREACODE, '+@sTable1+'.TELECOMNUMBER, '+@sTable1+'.EXTENSION)'
			
			Set @sAddFromString = "where T1.TELECODE=NT.TELECODE))) "+@sTable1+" on "+@sTable1+".NAMENO = N.NAMENO"

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = 	     "left join (Select NT.NAMENO, T.TELECOMTYPE, T.ISD,  T.AREACODE, T.TELECOMNUMBER,T.EXTENSION"
						   +char(10)+"		 from NAMETELECOM NT"
						   +char(10)+"		 join TELECOMMUNICATION T          on (T.TELECODE=NT.TELECODE"
						   +char(10)+"                        			   and T.TELECOMTYPE="+@sQualifier
						   +char(10)+"                        			   and T.TELECOMNUMBER=(select min(T1.TELECOMNUMBER)"
						   +char(10)+"                        		                     		from TELECOMMUNICATION T1"
						   +char(10)+"							     		where T1.TELECODE=NT.TELECODE))) "+@sTable1+" on "+@sTable1+".NAMENO = N.NAMENO"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End		

		Else If @sColumn='DisplayMainFax'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(FX.TELECOMTYPE, FX.ISD, FX.AREACODE, FX.TELECOMNUMBER, FX.EXTENSION)'

			Set @sAddFromString = 'Left Join TELECOMMUNICATION FX		on (FX.TELECODE=N.FAX)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DisplayMainPhone'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(PH.TELECOMTYPE, PH.ISD, PH.AREACODE, PH.TELECOMNUMBER, PH.EXTENSION)'

			Set @sAddFromString = 'Left Join TELECOMMUNICATION PH		on (PH.TELECODE=N.MAINPHONE)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DisplayMainEmail'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(ML.TELECOMTYPE, ML.ISD, ML.AREACODE, ML.TELECOMNUMBER, ML.EXTENSION)'

			Set @sAddFromString = 'Left Join TELECOMMUNICATION ML		on (ML.TELECODE=N.MAINEMAIL)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End		

		Else If @sColumn in ('StaffClassification',
				     'StaffProfitCentre',
				     'StaffProfitCentreCode')
		Begin
			Set @sAddFromString = 'Left Join EMPLOYEE EM			on (EM.EMPLOYEENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='StaffClassification'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura) 

				Set @sAddFromString = 'Left Join TABLECODES TC			on (TC.TABLECODE=EM.STAFFCLASS)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End			
			Else If @sColumn='StaffProfitCentre'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'PC',@sLookupCulture,@pbCalledFromCentura) 

				Set @sAddFromString = 'Left Join PROFITCENTRE PC		on (PC.PROFITCENTRECODE=EM.PROFITCENTRECODE)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End		
			Else Begin
				Set @sTableColumn='EM.PROFITCENTRECODE'						
			End	
		End	

		Else If @sColumn='LocalCurrencyCode'
		Begin
			Set @sTableColumn='SC.COLCHARACTER'

			Set @sAddFromString = "Left Join SITECONTROL SC 			on (SC.CONTROLID = 'CURRENCY')"

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
		End		
		
		Else If @sColumn in ('DebtorCreditLimit')
		Begin
			Set @sTableColumn='IP.CREDITLIMIT'

			Set @sAddFromString = 'Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('SupplierType',
				     'SupplierRestriction',
				     'SupplierRestrictionActionKey',
				     'PurchaseCurrencyCode',
				     'PurchaseCurrencyDescription',
				     'PurchaseDescription',
				     'SupplierPaymentTerms',
				     'SupplierPaymentMethod')
		Begin
			Set @sAddFromString = 'Left Join CREDITOR CR		on (CR.NAMENO=N.NAMENO)'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='SupplierType'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TS',@sLookupCulture,@pbCalledFromCentura) 

				Set @sAddFromString = 'Left Join TABLECODES TS		on (TS.TABLECODE = CR.SUPPLIERTYPE)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End						
			Else If @sColumn in ('SupplierRestriction',
					     'SupplierRestrictionActionKey')
			Begin
				If @sColumn='SupplierRestriction'
				Begin
					Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CRRESTRICTION','CRRESTRICTIONDESC',null,'RST',@sLookupCulture,@pbCalledFromCentura) 
				End
				Else Begin
					Set @sTableColumn='RST.ACTIONFLAG'
				End				

				Set @sAddFromString = 'Left Join CRRESTRICTION RST 	on (RST.CRRESTRICTIONID = CR.RESTRICTIONID)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End				
			End			
			If @sColumn='PurchaseDescription'
			Begin
				Set @sTableColumn='CR.PURCHASEDESC'				
			End		
			If @sColumn='PurchaseCurrencyCode'
			Begin
				Set @sTableColumn='CR.PURCHASECURRENCY'				
			End		
			Else If @sColumn='PurchaseCurrencyDescription'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'CUR',@sLookupCulture,@pbCalledFromCentura) 

				Set @sAddFromString = 'Left Join CURRENCY CUR		on (CUR.CURRENCY = CR.PURCHASECURRENCY)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End		
			End	
			Else If @sColumn='SupplierPaymentTerms'
			Begin				
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('FREQUENCY','DESCRIPTION',null,'FR',@sLookupCulture,@pbCalledFromCentura) 

				Set @sAddFromString = 'Left Join FREQUENCY FR		on (FR.FREQUENCYNO = CR.PAYMENTTERMNO)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End		
			End				
			Else If @sColumn='SupplierPaymentMethod'
			Begin				
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PAYMENTMETHODS','PAYMENTDESCRIPTION',null,'PM',@sLookupCulture,@pbCalledFromCentura) 

				Set @sAddFromString = 'Left Join PAYMENTMETHODS PM	on (PM.PAYMENTMETHOD = CR.PAYMENTMETHOD)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End		
			End	
		End
			
		Else If @sColumn in ('OrganisationName',
				     'OrganisationCode',
				     'OrganisationKey',
				     'Position')
		Begin
			Set @sAddFromString = "left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO"

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString =	"left join ASSOCIATEDNAME EMP	on (EMP.RELATEDNAME = N.NAMENO"
					     +CHAR(10)+ "				and EMP.RELATIONSHIP = 'EMP')"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='OrganisationKey'
			Begin
				Set @sTableColumn='EMP.NAMENO'					
			End			
			Else If @sColumn='Position'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,'EMP',@sLookupCulture,@pbCalledFromCentura)
			End
			Else If @sColumn='OrganisationCode'
			Begin
				Set @sTableColumn='ORG.NAMECODE'					

				Set @sAddFromString = "left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)"

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End		
			Else If @sColumn='OrganisationName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(ORG.NAMENO, null)'

				Set @sAddFromString = "left join NAME ORG		on (ORG.NAMENO = EMP.NAMENO)"

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End	
		End				

		Else If @sColumn='IsInstructor'				     
		Begin	
			Set @sTableColumn='CASE WHEN INSR.NAMENO IS NULL THEN CAST(0 as bit) ELSE CAST(1 as bit) END'
			
			Set @sAddFromString = "left join (Select DISTINCT CNI.NAMENO"

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = 	     "left join (Select DISTINCT CNI.NAMENO"
						   +char(10)+"		 from CASENAME CNI"
						   +char(10)+"		 where CNI.NAMETYPE = 'I'"
						   +char(10)+"           and (CNI.EXPIRYDATE is null or CNI.EXPIRYDATE>getdate())) INSR	on (INSR.NAMENO = N.NAMENO)"
   
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End				

		Else If @sColumn='HasWorkBenchAccess'				     
		Begin	
			Set @sTableColumn='CASE WHEN WBAccess.NameKey is not null then CAST(1 as bit) ELSE CAST(0 as bit) END'

			Set @sAddFromString = "Left Join (Select NWB.NAMENO as 'NameKey'" 			

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join (Select NWB.EMPLOYEENO as 'NameKey'" 
							 +char(10)+"from EMPLOYEE NWB" 
							 +char(10)+"UNION" 
							 +char(10)+"Select UI.NAMENO" 
							 +char(10)+"from USERIDENTITY UI"	
							 +char(10)+"where UI.ISEXTERNALUSER = 1"
							 +char(10)+"UNION"
							 +char(10)+"Select ACN.NAMENO"
							 +char(10)+"from ACCESSACCOUNT ACCT"
							 +char(10)+"join ACCESSACCOUNTNAMES ACN	on (ACN.ACCOUNTID = ACCT.ACCOUNTID)"
							 +char(10)+"where ACCT.ISINTERNAL = 0) WBAccess on (WBAccess.NameKey = N.NAMENO)"			
   
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
		End		

		Else If @sColumn in ('CapacityToSign',
				     'AbbreviatedName',
				     'SignOffName',
				     'SignOffTitle',
				     'StaffEndDate',
				     'StaffStartDate')				     
		Begin			
			Set @sAddFromString = "Left Join EMPLOYEE NEMP" 			

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join EMPLOYEE NEMP		on (NEMP.EMPLOYEENO = N.NAMENO)" 							
   
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='AbbreviatedName'	
			Begin
				Set @sTableColumn='NEMP.ABBREVIATEDNAME'
			End
			Else
			If @sColumn='SignOffName'	
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFNAME',null,'NEMP',@sLookupCulture,@pbCalledFromCentura)
			End
			Else
			If @sColumn='SignOffTitle'	
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('EMPLOYEE','SIGNOFFTITLE',null,'NEMP',@sLookupCulture,@pbCalledFromCentura)
			End
			Else
			If @sColumn='StaffEndDate'	
			Begin
				Set @sTableColumn='NEMP.ENDDATE'
			End
			Else
			If @sColumn='StaffStartDate'	
			Begin
				Set @sTableColumn='NEMP.STARTDATE'
			End
			Else
			If @sColumn='CapacityToSign'	
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'CAPSGN',@sLookupCulture,@pbCalledFromCentura)
				Set @sAddFromString = "Left Join TABLECODES CAPSGN" 			

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join TABLECODES CAPSGN	on (CAPSGN.TABLECODE = NEMP.CAPACITYTOSIGN)" 							
	   
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End
		End		
		
		Else If @sColumn in ('FilesInCountryCodeAny',
				     'FilesInCountryNameAny',
				     'FilesInNotesAny')				     
		Begin			
			Set @sAddFromString = "Left Join FILESIN FBI" 			

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join FILESIN FBI		on (FBI.NAMENO = N.NAMENO)" 							
   
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn='FilesInCountryCodeAny'	
			Begin
				Set @sTableColumn='FBI.COUNTRYCODE'
			End
			Else
			If @sColumn='FilesInNotesAny'	
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('FILESIN','NOTES',null,'FBI',@sLookupCulture,@pbCalledFromCentura)
			End
			Else
			If @sColumn='FilesInCountryNameAny'	
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CFBI',@sLookupCulture,@pbCalledFromCentura)
				Set @sAddFromString = "Left Join COUNTRY CFBI" 			

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join COUNTRY CFBI	on (CFBI.COUNTRYCODE = FBI.COUNTRYCODE)" 							
	   
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End
			End
		End		
		Else If @sColumn in ('NameVariantKey',
				     'NameVariant',
				     'VariantPropertyType',
				     'VariantReason',
				     'VariantSequence')				     
		Begin			
			Set @sAddFromString = "Left Join NAMEVARIANT NVR" 			

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join NAMEVARIANT NVR		on (NVR.NAMENO = N.NAMENO)" 							
   
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End
			If @sColumn='NameVariantKey'	
			Begin
				Set @sTableColumn='NVR.NAMEVARIANTNO'
			End
			If @sColumn='NameVariant'	
			Begin
				Set @sTableColumn='dbo.fn_FormatName(NVR.NAMEVARIANT, NVR.FIRSTNAMEVARIANT, null, null)'
			End
			If @sColumn='VariantPropertyType'	
			Begin
				Set @sAddFromString = "Left Join PROPERTYTYPE PTV" 			

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join PROPERTYTYPE PTV		on (PTV.PROPERTYTYPE = NVR.PROPERTYTYPE)" 							
	   
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PTV',@sLookupCulture,@pbCalledFromCentura)
			End
			If @sColumn='VariantReason'	
			Begin
				Set @sAddFromString = "Left Join TABLECODES TCV" 			

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join TABLECODES TCV		on (TCV.TABLECODE = NVR.VARIANTREASON)" 							
	   
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
	
					Set @pnTableCount=@pnTableCount+1
				End

				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCV',@sLookupCulture,@pbCalledFromCentura)
			End
			If @sColumn='VariantSequence'	
			Begin
				Set @sTableColumn='NVR.DISPLAYSEQUENCENO'
			End
		End		
		Else If @sColumn in ('LeadOwnerName',
				     'LeadOwnerKey',
				     'LeadOwnerNameCode',
				     'LeadSource',
				     'LeadReferredByKey',
				     'LeadReferredByName',
				     'LeadReferredByNameCode',
				     'LeadStatus',
				     'LeadEstimatedRev',
				     'LeadCurrencyCode')				     
		Begin	
			Set @sAddFromString = "Left Join LEADDETAILS LD" 			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "Left Join LEADDETAILS LD		on (LD.NAMENO = N.NAMENO)"
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				Set @pnTableCount=@pnTableCount+1
			End

			If (@sColumn = 'LeadEstimatedRev')
			Begin
				Set @sTableColumn='ISNULL(LD.ESTIMATEDREV,LD.ESTIMATEDREVLOCAL)'
			End

			If (@sColumn = 'LeadCurrencyCode')
			Begin
				Set @sTableColumn='ISNULL(LD.ESTREVCURRENCY, LDCUR.COLCHARACTER)'
				Set @sAddFromString = 'Left Join SITECONTROL LDCUR 	on (LDCUR.CONTROLID = ''CURRENCY'')'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			If (@sColumn = 'LeadStatus')
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCLST',@psCulture,@pbCalledFromCentura)
				Set @sAddFromString = "Left Join LEADSTATUSHISTORY LSH" 			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "left join (	select	NAMENO, 
										MAX( convert(nvarchar(24),LOGDATETIMESTAMP, 21)+cast(LEADSTATUSID as nvarchar(11)) ) as [DATE]
										from LEADSTATUSHISTORY
										group by NAMENO	
										) LASTMODIFIED on (LASTMODIFIED.NAMENO = LD.NAMENO)
								Left Join LEADSTATUSHISTORY LSH on (LSH.NAMENO = LD.NAMENO 
									and ( (convert(nvarchar(24),LSH.LOGDATETIMESTAMP, 21)+cast(LSH.LEADSTATUSID as nvarchar(11))) = LASTMODIFIED.[DATE]
									or LASTMODIFIED.[DATE] is null ))
								left join TABLECODES TCLST 	on (TCLST.TABLECODE = LSH.LEADSTATUS)"
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
			End
			If (@sColumn = 'LeadSource')
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCLSC',@psCulture,@pbCalledFromCentura)
				Set @sAddFromString = "left join TABLECODES TCLSC" 			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "left join TABLECODES TCLSC 	on (TCLSC.TABLECODE 	= LD.LEADSOURCE)"
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
			End
			If (@sColumn in ('LeadOwnerName',
					 'LeadOwnerKey',
					 'LeadOwnerNameCode'))
			Begin		
				Set @sAddFromString = "Left Join ASSOCIATEDNAME LDRES" 
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join ASSOCIATEDNAME LDRES on (LDRES.NAMENO = N.NAMENO"
							+char(10)+"				and LDRES.RELATIONSHIP = 'RES')"
   					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
				Set @sAddFromString = "Left Join NAME NRES" 
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join NAME NRES on (NRES.NAMENO = LDRES.RELATEDNAME)"
   					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
				If @sColumn='LeadOwnerKey'	
				Begin
					Set @sTableColumn='LDRES.RELATEDNAME'
				End
				If @sColumn='LeadOwnerName'	
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NRES.NAMENO, null)'
				End
				If @sColumn='LeadOwnerNameCode'	
				Begin
					Set @sTableColumn='NRES.NAMECODE'
				End	
			End
			If (@sColumn in ('LeadReferredByKey',
					 'LeadReferredByName',
					 'LeadReferredByNameCode'))
			Begin
				Set @sAddFromString = "Left Join ASSOCIATEDNAME LDREF" 
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join ASSOCIATEDNAME LDREF on (LDREF.NAMENO = N.NAMENO"
							+char(10)+"				and LDREF.RELATIONSHIP = 'REF')"
   					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End	
				Set @sAddFromString = "Left Join NAME NREF" 
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = "Left Join NAME NREF on (NREF.NAMENO = LDREF.RELATEDNAME)"
   					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					Set @pnTableCount=@pnTableCount+1
				End
				If @sColumn='LeadReferredByKey'	
				Begin
					Set @sTableColumn='LDREF.RELATEDNAME'
				End
				If @sColumn='LeadReferredByName'	
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(NREF.NAMENO, null)'
				End
				If @sColumn='LeadReferredByNameCode'	
				Begin
					Set @sTableColumn='NREF.NAMECODE'
				End	
			End			
			
		End
		Else If @sColumn='HasOpportunity'				     
		Begin	
			Set @sTableColumn='CASE WHEN OP.NAMENO is not null then CAST(1 as bit) ELSE CAST(0 as bit) END'
			Set @sAddFromString = "left join (select DISTINCT CNO.NAMENO as [NAMENO]" 	
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString = "left join (select DISTINCT CNO.NAMENO as [NAMENO]"
				                +char(10)+"from OPPORTUNITY OPP"
				                +char(10)+"left join CASENAME CNO on (CNO.CASEID = OPP.CASEID)) OP on (OP.NAMENO = N.NAMENO)"
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				Set @pnTableCount=@pnTableCount+1
			End
		End				
		Else If @sColumn='NameRestrictionFlag'  or @sColumn = 'DisplayNameCodeFlag'
		Begin

			Set @sAddFromString = "Left Join NAMETYPE NT1 			on ( NT1.NAMETYPE =" + dbo.fn_WrapQuotes(@sNameTypeRestriction,0,0) + ")"

			If @sColumn='NameRestrictionFlag'
			Begin
				Set @sTableColumn='NT1.NAMERESTRICTFLAG'		
			End
			Else
			Begin
				Set @sTableColumn='ISNULL(NT1.SHOWNAMECODE,0)'	
			End
			
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0
	
				Set @pnTableCount=@pnTableCount+1
			End
		End			
		Else If @sColumn in ('StandingInstructionText', 'StandingInstruction')
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin		
			Set @sTable1='NI'+@sCorrelationSuffix
			Set @sAddFromString = 'Left Join NAMEINSTRUCTIONS '+@sTable1
		
			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin									
				Set @sAddFromString = 'Left Join NAMEINSTRUCTIONS '+@sTable1+'	on ('+@sTable1+'.NAMENO = N.NAMENO and 
				                      '+@sTable1+'.INSTRUCTIONCODE=dbo.fn_StandingInstructionForName(N.NAMENO, '+dbo.fn_WrapQuotes(@sQualifier,0,@pbCalledFromCentura)+' ,null)'

				Set @sAddFromString=@sAddFromString+')'

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom, 
							@psSeparator    =@sReturn,
							@pbForceLoad=0
				
				Set @pnTableCount=@pnTableCount+1
			End
			
			If @sColumn = 'StandingInstruction'
			Begin	
				Set @sTable2='INS'+@sCorrelationSuffix
				Set @sAddFromString = 'Left Join INSTRUCTIONS '+@sTable2
			
				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin									
					Set @sAddFromString = 'Left Join INSTRUCTIONS '+@sTable2+'	on ('+@sTable2+'.INSTRUCTIONCODE = '+@sTable1+'.INSTRUCTIONCODE)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom, 
								@psSeparator    =@sReturn,
								@pbForceLoad=0
					
					Set @pnTableCount=@pnTableCount+1
				End
			End			
			
			Set @sTableColumn= CASE(@sColumn)
						WHEN('StandingInstructionText') THEN dbo.fn_SqlTranslatedColumn('NAMEINSTRUCTIONS','STANDINGINSTRTEXT',null,@sTable1,@sLookupCulture,@pbCalledFromCentura)
						WHEN('StandingInstruction')     THEN dbo.fn_SqlTranslatedColumn('INSTRUCTIONS',    'DESCRIPTION',      null,@sTable2,@sLookupCulture,@pbCalledFromCentura)
					   END
		End
		Else If @sColumn='IsEditable'
		Begin
			--------------------------------------------------------------------
			-- RFC13142
			-- Check what level of Row Access Security has been defined.
			-- This will help tailor the generated SELECT to improve performance
			--------------------------------------------------------------------
			Set @sSQLString = "
			Select	@bOfficeSecurity       =SUM(CASE WHEN(R.OFFICE     IS NOT NULL) THEN 1 ELSE 0 END),
				@bNameTypeSecurity     =SUM(CASE WHEN(R.NAMETYPE   IS NOT NULL) THEN 1 ELSE 0 END)
			from IDENTITYROWACCESS U WITH (NOLOCK) 
			join ROWACCESSDETAIL R WITH (NOLOCK) on (R.ACCESSNAME = U.ACCESSNAME) 
			where R.RECORDTYPE = 'N'
			and U.IDENTITYID = @pnUserIdentityId"
			
			exec @ErrorCode = sp_executesql @sSQLString,
				N'@bOfficeSecurity		bit			output,
				  @bNameTypeSecurity		bit			output,
				  @pnUserIdentityId		int',
				  @bOfficeSecurity		= @bOfficeSecurity	output,
				  @bNameTypeSecurity		= @bNameTypeSecurity	output,
				  @pnUserIdentityId		= @pnUserIdentityId
				  
			Set @sTableColumn='CASE WHEN convert(bit,(RSC.SECURITYFLAG&2))=1 THEN convert(bit,1) 
						WHEN convert(bit,(RSC.SECURITYFLAG&8))=1 THEN convert(bit,1) 
						WHEN RSC.SECURITYFLAG IS NULL THEN convert(bit,1) ELSE convert(bit,0) END'
			Set @sAddFromString="
				left join (select XN.NAMENO as NAMENO,
					   convert(int,
						SUBSTRING(
						(Select MAX(CASE WHEN RAD.OFFICE       is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.NAMETYPE     is NULL THEN '0' ELSE '1' END+
							    CASE WHEN RAD.SECURITYFLAG<10      THEN '0' ELSE ''  END+
							    convert(nvarchar,RAD.SECURITYFLAG))
						  from IDENTITYROWACCESS UA WITH (NOLOCK)
						  join ROWACCESSDETAIL RAD WITH (NOLOCK)
									on (RAD.ACCESSNAME  =UA.ACCESSNAME"

			---------------------------------------------------
			-- RFC13142
			-- Performance improvement step to only restrict to 
			-- OFFICE if row access has been defined for OFFICE
			---------------------------------------------------								
			If @bOfficeSecurity=1
				Set @sAddFromString=@sAddFromString+"
									and(RAD.OFFICE       in (select TA.TABLECODE from TABLEATTRIBUTES TA where TA.PARENTTABLE='NAME' and TA.TABLETYPE=44 and TA.GENERICKEY=convert(nvarchar, XN.NAMENO))
									 or RAD.OFFICE       is NULL)"

			----------------------------------------------------
			-- RFC13142
			-- Performance improvement step to only restrict to 
			-- NAMETYPE if row access has been defined for OFFICE
			-----------------------------------------------------				
			If @bNameTypeSecurity=1
				Set @sAddFromString=@sAddFromString+"
									and(RAD.NAMETYPE     in (select NTC.NAMETYPE from NAMETYPECLASSIFICATION NTC WHERE NTC.ALLOW = 1 and NTC.NAMENO = XN.NAMENO)
									 or RAD.NAMETYPE     is NULL)"

			Set @sAddFromString=@sAddFromString+"
									and RAD.RECORDTYPE  ='N')
						  where UA.IDENTITYID="+convert(nvarchar,@pnUserIdentityId)+"),3,2)) as SECURITYFLAG
					   from NAME XN ) RSC on (RSC.NAMENO=N.NAMENO)"

			exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentFromString	OUTPUT,
					@psAddString	=@sAddFromString,
					@psComponentType=@sFrom,
					@psSeparator    =@sReturn,
					@pbForceLoad=0
			Set @pnTableCount=@pnTableCount+1
		End
		----------------------------
		-- RFC8795
		-- Staff Responsible Columns
		----------------------------
		Else If @sColumn like ('StaffResponsible%')
		Begin
			Set @sAddFromString = 'left join ASSOCIATEDNAME RES on (RES.NAMENO = N.NAMENO'

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString =	"left join ASSOCIATEDNAME RES on (RES.NAMENO = N.NAMENO"
					     +CHAR(10)+ "                             and RES.RELATIONSHIP = 'RES')"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+1
			End

			If @sColumn in ('StaffResponsibleCode',
					'StaffResponsibleEmail',
					'StaffResponsibleFax',
					'StaffResponsibleName',
					'StaffResponsiblePhone')
			Begin
				Set @sAddFromString = 'left join NAME RES_N on (RES_N.NAMENO = RES.RELATEDNAME)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'left join NAME RES_N on (RES_N.NAMENO = RES.RELATEDNAME)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			If @sColumn='StaffResponsibleCode'
			Begin
				Set @sTableColumn='RES_N.NAMECODE'
			End
			Else if @sColumn='StaffResponsibleName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(RES_N.NAMENO, null)'
			End
			Else If @sColumn='StaffResponsibleEmail'
			Begin
				Set @sTableColumn='dbo.fn_FormatTelecom(RES_ML.TELECOMTYPE, RES_ML.ISD, RES_ML.AREACODE, RES_ML.TELECOMNUMBER, RES_ML.EXTENSION)'

				Set @sAddFromString = 'Left Join TELECOMMUNICATION RES_ML on (RES_ML.TELECODE=RES_N.MAINEMAIL)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'Left Join TELECOMMUNICATION RES_ML on (RES_ML.TELECODE=RES_N.MAINEMAIL)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			Else If @sColumn='StaffResponsibleFax'
			Begin
				Set @sTableColumn='dbo.fn_FormatTelecom(RES_FX.TELECOMTYPE, RES_FX.ISD, RES_FX.AREACODE, RES_FX.TELECOMNUMBER, RES_FX.EXTENSION)'

				Set @sAddFromString = 'Left Join TELECOMMUNICATION RES_FX on (RES_FX.TELECODE=RES_N.FAX)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'Left Join TELECOMMUNICATION RES_FX on (RES_FX.TELECODE=RES_N.FAX)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			Else If @sColumn='StaffResponsiblePhone'
			Begin
				Set @sTableColumn='dbo.fn_FormatTelecom(RES_PH.TELECOMTYPE, RES_PH.ISD, RES_PH.AREACODE, RES_PH.TELECOMNUMBER, RES_PH.EXTENSION)'

				Set @sAddFromString = 'Left Join TELECOMMUNICATION RES_PH on (RES_PH.TELECODE=RES_N.MAINPHONE)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'Left Join TELECOMMUNICATION RES_PH on (RES_PH.TELECODE=RES_N.MAINPHONE)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			Else If @sColumn='StaffResponsibleRole'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'RES_TC',@sLookupCulture,@pbCalledFromCentura)

				Set @sAddFromString = 'Left Join TABLECODES RES_TC on (RES_TC.TABLECODE=RES.JOBROLE)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'Left Join TABLECODES RES_TC on (RES_TC.TABLECODE=RES.JOBROLE)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			Else If @sColumn='StaffResponsiblePropertyType'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'RES_P',@sLookupCulture,@pbCalledFromCentura)

				Set @sAddFromString = 'Left Join PROPERTYTYPE RES_P on (RES_P.PROPERTYTYPE=RES.PROPERTYTYPE)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = 'Left Join PROPERTYTYPE RES_P on (RES_P.PROPERTYTYPE=RES.PROPERTYTYPE)'

					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
		End	

		-----------------------------------
		-- RFC38436
		-- Assocatied Name Columns:
		--   AssociatedNameCode
		--   AssociatedName	
		--   AssociatedRelationship	
		--   AssociatedNameStreetAddress
		--   AssociatedNamePostalAddress
		--   AssociatedNameEmail
		--   AssociatedNamePhone
		-- RFC43709
		--   AssociatedNamePosition
		--   AssociatedNamePositionCategory
		-----------------------------------
		Else If @sColumn like ('Associated%')
		Begin
			Set @sTable1='AN'+@sCorrelationSuffix
			Set @sTable2='N3'+@sCorrelationSuffix
			
			Set @sAddFromString = 'left join ASSOCIATEDNAME '+@sTable1

			If not exists(	select 1 from #TempConstructSQL T
					where T.SavedString like '%'+@sAddFromString+'%')
			and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
			Begin
				Set @sAddFromString ="left join ASSOCIATEDNAME "+@sTable1+" on ("+@sTable1+".NAMENO = N.NAMENO"
					   +CHAR(10)+"                                 and "+@sTable1+".CEASEDDATE is NULL"
				
				If @sQualifier is not null
					Set @sAddFromString=@sAddFromString+CHAR(10)+ "                                 and "+@sTable1+".RELATIONSHIP in ("+dbo.fn_WrapQuotes(@sQualifier,1,0)+")"

				Set @sAddFromString=@sAddFromString+')'				
				
				Set @sAddFromString =@sAddFromString+CHAR(10)
				                                    +"left join NAME "+@sTable2+" on ("+@sTable2+".NAMENO = "+@sTable1+".RELATEDNAME)"

				exec @ErrorCode=dbo.ip_LoadConstructSQL
							@psCurrentString=@sCurrentFromString	OUTPUT,
							@psAddString	=@sAddFromString,
							@psComponentType=@sFrom,
							@psSeparator    =@sReturn,
							@pbForceLoad=0

				Set @pnTableCount=@pnTableCount+2
			End
			
			If @sColumn like ('AssociatedRelationship')
			Begin
				Set @sTable3='NR'+@sCorrelationSuffix
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,@sTable3,@sLookupCulture,@pbCalledFromCentura)
				
				Set @sAddFromString = 'left join NAMERELATION '+@sTable3

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString ="left join NAMERELATION "+@sTable3+" on ("+@sTable3+".RELATIONSHIP = "+@sTable1+".RELATIONSHIP)"
					
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			Else If @sColumn='AssociatedNamePostalAddress'
			Begin
				Set @sTable3='PA'+@sCorrelationSuffix
				Set @sTable4='SP'+@sCorrelationSuffix
				Set @sTable5='CP'+@sCorrelationSuffix
				Set @sTableColumn='dbo.fn_FormatAddress('+@sTable3+'.STREET1,'+@sTable3+'.STREET2,'+@sTable3+'.CITY,'+@sTable3+'.STATE,'+@sTable4+'.STATENAME,'+@sTable3+'.POSTCODE,'+@sTable5+'.POSTALNAME,'+@sTable5+'.POSTCODEFIRST,'+@sTable5+'.STATEABBREVIATED,'+@sTable5+'.POSTCODELITERAL,'+@sTable5+'.ADDRESSSTYLE)'

				Set @sAddFromString = 'Left Join ADDRESS '+@sTable3+' on ('+@sTable3+'.ADDRESSCODE='+@sTable2+'.POSTALADDRESS)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = @sAddFromString+CHAR(10)
					                    + 'Left Join COUNTRY '+@sTable5+' on ('+@sTable5+'.COUNTRYCODE='+@sTable3+'.COUNTRYCODE)'+CHAR(10)
					                    + 'Left Join STATE '  +@sTable4+' on ('+@sTable4+'.COUNTRYCODE='+@sTable3+'.COUNTRYCODE'+CHAR(10)
					                    + '                    	      and '+@sTable4+'.STATE='+@sTable3+'.STATE)'
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+3
				End
			End

			Else If @sColumn='AssociatedNameStreetAddress'
			Begin
				Set @sTable3='SA'+@sCorrelationSuffix
				Set @sTable4='SS'+@sCorrelationSuffix
				Set @sTable5='CS'+@sCorrelationSuffix
				Set @sTableColumn='dbo.fn_FormatAddress('+@sTable3+'.STREET1,'+@sTable3+'.STREET2,'+@sTable3+'.CITY,'+@sTable3+'.STATE,'+@sTable4+'.STATENAME,'+@sTable3+'.POSTCODE,'+@sTable5+'.POSTALNAME,'+@sTable5+'.POSTCODEFIRST,'+@sTable5+'.STATEABBREVIATED,'+@sTable5+'.POSTCODELITERAL,'+@sTable5+'.ADDRESSSTYLE)'

				Set @sAddFromString = 'Left Join ADDRESS '+@sTable3+' on ('+@sTable3+'.ADDRESSCODE='+@sTable2+'.STREETADDRESS)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString = @sAddFromString+CHAR(10)
					                    + 'Left Join COUNTRY '+@sTable5+' on ('+@sTable5+'.COUNTRYCODE='+@sTable3+'.COUNTRYCODE)'+CHAR(10)
					                    + 'Left Join STATE '  +@sTable4+' on ('+@sTable4+'.COUNTRYCODE='+@sTable3+'.COUNTRYCODE'+CHAR(10)
					                    + '                    	      and '+@sTable4+'.STATE='+@sTable3+'.STATE)'
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+3
				End
			End
			
			Else If @sColumn='AssociatedNameEmail'
			Begin
				Set @sTable3='ML'+@sCorrelationSuffix
				
				Set @sTableColumn='dbo.fn_FormatTelecom('+@sTable3+'.TELECOMTYPE, '+@sTable3+'.ISD, '+@sTable3+'.AREACODE, '+@sTable3+'.TELECOMNUMBER, '+@sTable3+'.EXTENSION)'

				Set @sAddFromString = 'Left Join TELECOMMUNICATION '+@sTable3+' on ('+@sTable3+'.TELECODE='+@sTable2+'.MAINEMAIL)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
			
			Else If @sColumn='AssociatedNamePhone'
			Begin
				Set @sTable3='PH'+@sCorrelationSuffix
				
				Set @sTableColumn='dbo.fn_FormatTelecom('+@sTable3+'.TELECOMTYPE, '+@sTable3+'.ISD, '+@sTable3+'.AREACODE, '+@sTable3+'.TELECOMNUMBER, '+@sTable3+'.EXTENSION)'

				Set @sAddFromString = 'Left Join TELECOMMUNICATION '+@sTable3+' on ('+@sTable3+'.TELECODE='+@sTable2+'.MAINPHONE)'

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End

			Else If @sColumn='AssociatedNameCode'
			Begin
				Set @sTableColumn=''+@sTable2+'.NAMECODE'
			End
			
			Else if @sColumn='AssociatedName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, 7101)'
			End
			
			Else if @sColumn='AssociatedNamePosition'
			Begin
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,@sTable1,@sLookupCulture,@pbCalledFromCentura) 
			End
			
			If @sColumn like ('AssociatedNamePositionCategory')
			Begin
				Set @sTable3='PC'+@sCorrelationSuffix
				Set @sTableColumn=dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,@sTable3,@sLookupCulture,@pbCalledFromCentura)
				
				Set @sAddFromString = 'left join TABLECODES '+@sTable3

				If not exists(	select 1 from #TempConstructSQL T
						where T.SavedString like '%'+@sAddFromString+'%')
				and CHARINDEX(@sAddFromString, isnull(@sCurrentFromString,''))=0
				Begin
					Set @sAddFromString ="left join TABLECODES "+@sTable3+" on ("+@sTable3+".TABLECODE = "+@sTable1+".POSITIONCATEGORY)"
					
					exec @ErrorCode=dbo.ip_LoadConstructSQL
								@psCurrentString=@sCurrentFromString	OUTPUT,
								@psAddString	=@sAddFromString,
								@psComponentType=@sFrom,
								@psSeparator    =@sReturn,
								@pbForceLoad=0

					Set @pnTableCount=@pnTableCount+1
				End
			End
		End
			
		-- If the column is being published then concatenate it to the Select list

		If datalength(@sPublishName)>0
		Begin  
			Set @sAddSelectString=@sTableColumn+' as ['+@sPublishName+']'

			exec @ErrorCode=dbo.ip_LoadConstructSQL
						@psCurrentString=@sCurrentSelectString	OUTPUT,
						@psAddString	=@sAddSelectString,
						@psComponentType=@sSelect,
						@psSeparator    =@sComma,
						@pbForceLoad=0
			Set @sComma=', ' 	
		End
		Else Begin
			Set @sPublishName=NULL
		End		

		If @nOrderPosition>0
		and @ErrorCode=0
		Begin

			Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, @sOrderDirection)

			Set @ErrorCode = @@ERROR
			Set @bOrderByDefined=1
		End
	
		-- RFC9104
		-- Save the first published column. If there is not explicit Order By
		-- defined then the first column will be used.
		If @sFirstPublishName is null
		and datalength(@sPublishName)>0
		Begin
			Set @sFirstPublishName=@sPublishName
			Set @sFirstTableColumn=@sTableColumn
			Set @nFirstColumnNo   =@nColumnNo
		End
	End

	-- Increment @nCount so it points to the next record in the @tblOutputRequests table 
	Set @nCount = @nCount + 1
	
	Set @ErrorCode=@@Error
End

-- RFC9104
-- If no ORDER BY column defined
-- then default to first column
If  @ErrorCode=0
and @bOrderByDefined=0
Begin
	Insert into @tbOrderBy (Position, ColumnName, PublishName, ColumnNumber, Direction)
	values(1, @sFirstTableColumn, @sFirstPublishName, @nFirstColumnNo, 'A')

	Set @ErrorCode = @@ERROR
End

-- Now construct the Order By clause

If @ErrorCode=0
Begin		
	-- If there is more than one row in the @tbOrderBy then the data from the next row gets concatenated 
	-- to the previous row.
	Select @sAddOrderByString= ISNULL(NULLIF(@sAddOrderByString+',', ','),'')			
				 +CASE WHEN(PublishName is null) 
				       THEN ColumnName
				       ELSE '['+PublishName+']'
				  END
				+CASE WHEN Direction = 'A' THEN ' ASC ' ELSE ' DESC ' END
				from @tbOrderBy
				order by Position			

	Set @ErrorCode=@@Error		

	If @sAddOrderByString is not null
	and @ErrorCode=0
	Begin
		Set @sAddOrderByString = char(10)+'Order by ' + @sAddOrderByString

		exec @ErrorCode=dbo.ip_LoadConstructSQL
					@psCurrentString=@sCurrentOrderByString	OUTPUT,
					@psAddString	=@sAddOrderByString,
					@psComponentType=@sOrderBy,
					@psSeparator    =null,
					@pbForceLoad=1
	End
End

-- Force the current From string to be saved
If datalength(@sCurrentFromString)>0	
and @ErrorCode=0
Begin
	Set @sAddFromString=null

	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentFromString	OUTPUT,
				@psAddString	=@sAddFromString,
				@psComponentType=@sFrom, 
				@psSeparator    =null,
				@pbForceLoad=1
End

-- Force the current Select string to be saved
If datalength(@sCurrentSelectString)>0	
and @ErrorCode=0
Begin
	Set @sAddSelectString=null
	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentSelectString	OUTPUT,
				@psAddString	=@sAddSelectString,
				@psComponentType=@sSelect, 
				@psSeparator    =null,
				@pbForceLoad=1
End

-- Force the current Where string to be saved
If datalength(@sCurrentWhereString)>0	
and @ErrorCode=0
Begin
	Set @sAddWhereString=null
	exec @ErrorCode=dbo.ip_LoadConstructSQL
				@psCurrentString=@sCurrentWhereString	OUTPUT,
				@psAddString	=@sAddWhereString,
				@psComponentType=@sWhere, 
				@psSeparator    =null,
				@pbForceLoad=1
End

RETURN @ErrorCode
go

grant execute on dbo.naw_ConstructNameSelect  to public
go
