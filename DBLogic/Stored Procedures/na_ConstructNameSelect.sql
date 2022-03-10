-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ConstructNameSelect
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ConstructNameSelect]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ConstructNameSelect.'
	drop procedure dbo.na_ConstructNameSelect
	print '**** Creating procedure dbo.na_ConstructNameSelect...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.na_ConstructNameSelect
	@psSelect			nvarchar(4000)  OUTPUT,	-- the SQL list of columns to return
	@psFrom				nvarchar(4000)	OUTPUT,	-- the SQL to list tables and joins
	@psWhere			nvarchar(4000) 	OUTPUT,	-- the SQL to filter
	@psOrder			nvarchar(1000)	OUTPUT,	-- the SQL sort order
	@pnTableCount			tinyint		OUTPUT,	-- the number of table in the constructed FROM clause
	@psColumnIds			nvarchar(4000)	= null, -- list of the columns (delimited by ^) required either as ouput or for sorting
	@psColumnQualifiers		nvarchar(1000)	= null,	-- list of qualifiers  (delimited by ^) that further define the data to be selected
	@psPublishColumnNames		nvarchar(4000)	= null,	-- list of columne names (delimited by ^) to be published as the output name
	@psSortOrderList		nvarchar(1000)	= null,	-- list of numbers (delimited by ^) to indicate the precedence of the matching column in the Order By clause
	@psSortDirectionList		nvarchar(1000)	= null,	-- list that indicates the direction for the sort of each column included in the Order By
	@pbExternalUser			bit		= 1	-- flag to indicate if user is external.  Default on as this is the lowest security level
AS

-- PROCEDURE :	na_ConstructNameSelect
-- VERSION :	21
-- DESCRIPTION:	Receives a list of columns and details of a required sort order and constructs
--		the components of the SELECT statement to meet the requirement
-- CALLED BY :	

-- MODIFICTION HISTORY:
-- Date         Who  	Number	Version	Change
-- ------------ ---- 	------	-------	------------------------------------------- 
-- 11 Sep 2002	MF		1	Procedure created
-- 30 Sep 2002	JB		2	Bug: N.Remarks should have been N.REMARKS
-- 09 Oct 2002	JG		3	NameNo should be retrieved as Varchar
-- 10 Oct 2002	SF		4	Rollback to use int for NameNo.
-- 24 Oct 2002	JEK		5	When UsedAsFlag = 0, IsIndividual, IsClient and IsStaff incorrectly return 1.
-- 04 Dec 2002	JB		9	Rolled back translations (version 8)
-- 09 Sep 2003  TM		10	RFC436 Main email returns multiple rows. For the 'DisplayMainEmail' column
--					substitute left join with derived table approach to avoid  returning
--					the multiple rows instead of the single row.
-- 27 Nov 2003	MF	RFC586	11	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 31-Dec-2003	TM	RFC425	12	Concatenate '_' at the end of every correlation suffix so the various joins distinguished
--					(e.g. the join for Alias 'A' will be created even though this search is matching on the join 
--					already present for 'AA').		
-- 02-Jan-2004	TM	RFC631	13	Display an appropriate description if an Office attribute is chosen.
-- 05-Jan-2004	TM	RFC631	14	Use TABLETYPE.DATABASETABLE = 'OFFICE' instead of the hard coding a specific table type.  
-- 25-Feb-2004	TM	RFC867	15	Modify the logic extracting the 'DisplayMainEmail' column to use new Name.MainEmail column.
-- 12-May-2004	TM	RFC1246	16	Implement fn_GetCorrelationSuffix function to generate the correlation suffix based
--					on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	17	Pass new Centura parameter to fn_WrapQuotes
-- 29-Sep-2004	TM	RFC1806	18	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.	
-- 15 Jan 2008	Dw	9782	19	Tax No moved from Organisation to Name table.
-- 07 Jul 2011	DL	R10830	20	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 02 Nov 2015	vql	R53910	21	Adjust formatted names logic (DR-15543).

-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	AirportName
--	Alias
--	AttributeDescription
--	BillingCurrencyKey
--	BillingCurrencyDescription
--	BillingFrequencyDescription
--	CasualSalutation
--	City
--	CorrespondenceInstructions
--	CountryName
--	DateCeased
--	DateChanged
--	DateEntered
--	DebitNoteCopies
--	DebtorStatusDescription
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
--	Incorporated
--	IsClient
--	IsFemale
--	IsIndividual
--	IsLocalClient
--	IsMale
--	IsOrganisation
--	IsStaff
--	MailingAddress
--	MailingLabel
--	MailingName
--	MainContactDisplayName
--	MainContactMailingName
--	NameCategoryDescription
--	NameCode
--	NameKey
--	NationalityDescription
--	OrganisationNumber
--	ParentDisplayName
--	Postcode
--	SearchKey1
--	SearchKey2
--	StateName
--	StreetAddress
--	TaxNumber
--	TaxTreatment
--	Text
--	TitleDescription
--	YourPurchaseOrderNo

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	AP
--	AT
--	BF
--	CN
--	CP
--	CS
--	CU
--	DS
--	DT
--	EM (RFC867)
--	FX
--	I
--	IP
--	N
--	N1
--	NA
--	NC
--	NF
--	NT
--	O
--	OFAT (RFC631)
--	PA
--	PH
--	SA
--	SS
--	ST
--	T
--	TA
--	TR
--	TTP (RFC631)
--	TX


set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode		int
declare	@sDelimiter		nchar(1)
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
declare	@sSQLString		nvarchar(4000)
declare @nColumnNo		tinyint
declare @sColumn		nvarchar(100)
declare @sPublishName		nvarchar(50)
declare @sQualifier		nvarchar(50)
declare @sTableColumn		nvarchar(1000)
declare @nLastPosition		smallint
declare @nOrderPosition		tinyint
declare @sOrderDirection	nvarchar(5)
declare @sCorrelationSuffix	nvarchar(20)
declare @sTable1		nvarchar(25)
declare @sTable2		nvarchar(25)
declare @sTable3		nvarchar(25)
declare @sTable4		nvarchar(25)
declare @sTable5		nvarchar(25)

-- A table variable to build up the columns to be used in the Order By.
-- Required so the columns can be combined in the correct order of precedence
declare @tbOrderBy table (
	Position		tinyint		not null,
	Direction		nvarchar(5)	collate database_default not null,
	ColumnName		nvarchar(1000)	collate database_default not null,
	PublishName		nvarchar(50)	collate database_default null,
	ColumnNumber		tinyint		not null
			)

-- Initialisation
set @ErrorCode	=0
set @sDelimiter	='^'
set @psSelect	='Select '
set @psFrom	='From NAME N'
set @pnTableCount=1

-- Split the list of columns required into each of the separate columns (tokenise) and then loop through
-- each column in order to construct the components of the SELECT
-- Using the "min" function as this returns NULL if nothing is found

set @sSQLString="
Select	@nColumnNo=min(InsertOrder),
	@sColumn  =min(Parameter)
From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
Where	InsertOrder=1"

exec @ErrorCode=sp_executesql @sSQLString,
				N'@nColumnNo	tinyint		OUTPUT,
				  @sColumn	nvarchar(50)	OUTPUT,
				  @psColumnIds  nvarchar(4000),
				  @sDelimiter   nchar(1)',
				  @nColumnNo  =@nColumnNo	OUTPUT,
				  @sColumn    =@sColumn		OUTPUT,
				  @psColumnIds=@psColumnIds,
				  @sDelimiter =@sDelimiter

While @nColumnNo is not NULL
and   @ErrorCode=0
Begin
	-- Get the Name of the column to be published
	set @sSQLString="
	Select	@sPublishName=min(Parameter)
	From	dbo.fn_Tokenise(@psPublishColumnNames, @sDelimiter)
	Where	InsertOrder=@nColumnNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@sPublishName		nvarchar(50)	OUTPUT,
				  @nColumnNo		tinyint,
				  @psPublishColumnNames nvarchar(4000),
				  @sDelimiter   	nchar(1)',
				  @sPublishName		=@sPublishName	OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psPublishColumnNames	=@psPublishColumnNames,
				  @sDelimiter		=@sDelimiter

	-- Get any Qualifier to be used to get the column
	If @ErrorCode=0
	Begin
		set @sSQLString="
		Select	@sQualifier=min(Parameter)
		From	dbo.fn_Tokenise(@psColumnQualifiers, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@sQualifier		nvarchar(50)	OUTPUT,
				  @nColumnNo		tinyint,
				  @psColumnQualifiers	nvarchar(4000),
				  @sDelimiter   	nchar(1)',
				  @sQualifier		=@sQualifier	OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psColumnQualifiers	=@psColumnQualifiers,
				  @sDelimiter		=@sDelimiter

		-- If a Qualifier exists then generate a value from it that can be used
		-- to create a unique Correlation name for the table

		If  @ErrorCode=0
		and @sQualifier is not null
			Set @sCorrelationSuffix=dbo.fn_GetCorrelationSuffix(@sQualifier)			
		Else
			Set @sCorrelationSuffix=NULL
	End

	-- Get the position of the Column in the Order By clause
	If @ErrorCode=0
	Begin
		set @sSQLString="
		Select	@nOrderPosition=min(cast(Parameter as tinyint))
		From	dbo.fn_Tokenise(@psSortOrderList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@nOrderPosition	tinyint	OUTPUT,
				  @nColumnNo		tinyint,
				  @psSortOrderList	nvarchar(1000),
				  @sDelimiter   	nchar(1)',
				  @nOrderPosition	=@nOrderPosition OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psSortOrderList	=@psSortOrderList,
				  @sDelimiter		=@sDelimiter
	End

	-- If the column is to be included in the Order by then get the direction of the sort
	If  @ErrorCode=0
	and @nOrderPosition>0
	Begin
		set @sSQLString="
		Select	@sOrderDirection=Parameter
		From	dbo.fn_Tokenise(@psSortDirectionList, @sDelimiter)
		Where	InsertOrder=@nColumnNo"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@sOrderDirection	nchar(1) OUTPUT,
				  @nColumnNo		tinyint,
				  @psSortDirectionList	nvarchar(1000),
				  @sDelimiter   	nchar(1)',
				  @sOrderDirection	=@sOrderDirection OUTPUT,
				  @nColumnNo		=@nColumnNo,
				  @psSortDirectionList	=@psSortDirectionList,
				  @sDelimiter		=@sDelimiter
	End	

	-- Now test the value of the Column to determine what table and column is required
	-- in the Select.  Note that if the PublishName is null then the column will not be
	-- returned in the result set however it is probably required for sorting.

	If @ErrorCode=0
	Begin
		If @sColumn='NameKey'
		Begin
--			Set @sTableColumn='Cast(N.NAMENO as varchar(10))'
			Set @sTableColumn='N.NAMENO'
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
			Set @sTableColumn='N.REMARKS'
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
				Set @sTableColumn="CASE WHEN(I.SEX='M') THEN cast(1 as bit) ELSE cast(0 as bit) END"
			Else
				Set @sTableColumn="CASE WHEN(I.SEX='F') THEN cast(1 as bit) ELSE cast(0 as bit) END"

			If charindex('Left Join INDIVIDUAL I',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join INDIVIDUAL I		on (I.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('CasualSalutation','FormalSalutation')
		Begin
			If @sColumn='CasualSalutation'
				Set @sTableColumn='I.CASUALSALUTATION'
			Else
				Set @sTableColumn='I.FORMALSALUTATION'

			If charindex('Left Join INDIVIDUAL I',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join INDIVIDUAL I		on (I.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('Incorporated','OrganisationNumber')
		Begin
			If @sColumn='Incorporated'
				Set @sTableColumn='O.INCORPORATED'
			Else
				Set @sTableColumn='O.REGISTRATIONNO'

			If charindex('Left Join ORGANISATION O',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join ORGANISATION O		on (O.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('ParentDisplayName')
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N2.NAMENO, null)'

			If charindex('Left Join ORGANISATION O',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join ORGANISATION O		on (O.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join NAME N2',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAME N2		on (N2.NAMENO=O.PARENT)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('IsLocalClient')
		Begin
			Set @sTableColumn='Cast(IP.LOCALCLIENTFLAG as bit)'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('HasMultiCaseBills', 'HasMultiCaseBillsByOwner')
		Begin
			If @sColumn = 'HasMultiCaseBills'
				Set @sTableColumn='CASE WHEN(IP.CONSOLIDATION>0) THEN Cast(1 as bit) ELSE Cast(0 as bit) END'
			Else
				Set @sTableColumn='CASE WHEN(IP.CONSOLIDATION=3) THEN Cast(1 as bit) ELSE Cast(0 as bit) END'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('AirportName')
		Begin
			Set @sTableColumn='AP.AIRPORTNAME'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join AIRPORT AP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join AIRPORT AP		on (AP.AIRPORTCODE=IP.AIRPORTCODE)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('CorrespondenceInstructions')
		Begin
			Set @sTableColumn='IP.CORRESPONDENCE'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('DebitNoteCopies')
		Begin
			Set @sTableColumn='IP.DEBITCOPIES'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('BillingCurrencyKey')
		Begin
			Set @sTableColumn='IP.CURRENCY'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('BillingCurrencyDescription')
		Begin
			Set @sTableColumn='CU.DESCRIPTION'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join CURRENCY CU',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join CURRENCY CU		on (CU.CURRENCY=IP.CURRENCY)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('ReceivableTermsDays')
		Begin
			Set @sTableColumn='IP.TRADINGTERMS'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('YourPurchaseOrderNo')
		Begin
			Set @sTableColumn='IP.PURCHASEORDERNO'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('DebtorStatusDescription')
		Begin
			Set @sTableColumn='DS.DEBTORSTATUS'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join DEBTORSTATUS DS',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join DEBTORSTATUS DS		on (DS.BADDEBTOR=IP.BADDEBTOR)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('BillingFrequencyDescription')
		Begin
			Set @sTableColumn='BF.DESCRIPTION'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join TABLECODES BF',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TABLECODES BF		on (BF.TABLECODE=IP.BILLINGFREQUENCY)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('DebtorTypeDescription')
		Begin
			Set @sTableColumn='DT.DESCRIPTION'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join TABLECODES DT',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TABLECODES DT		on (DT.TABLECODE=IP.DEBTORTYPE)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('NameCategoryDescription')
		Begin
			Set @sTableColumn='NC.DESCRIPTION'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join TABLECODES NC',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TABLECODES NC		on (NC.TABLECODE=IP.CATEGORY)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in ('TaxTreatment')
		Begin
			Set @sTableColumn='TR.DESCRIPTION'

			If charindex('Left Join IPNAME IP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join IPNAME IP		on (IP.NAMENO=N.NAMENO)"

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join TAXRATES TR',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TAXRATES TR		on (TR.TAXCODE=IP.TAXCODE)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='NationalityDescription'
		Begin
			Set @sTableColumn='CN.COUNTRYADJECTIVE'

			If charindex('Left Join COUNTRY CN',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join COUNTRY CN		on (CN.COUNTRYCODE=N.NATIONALITY)'

				Set @pnTableCount=@pnTableCount+1
			End
		End


		Else If @sColumn='MainContactDisplayName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N1.NAMENO, NULL)'

			If charindex('Left Join NAME N1',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='MainContactMailingName'
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N1.NAMENO, isnull(N1.NAMESTYLE,7101))'

			If charindex('Left Join NAME N1',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='City'	-- of the Postal Address
		Begin
			Set @sTableColumn='PA.CITY'

			If charindex('Left Join ADDRESS PA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='Postcode'	-- of the Postal Address
		Begin
			Set @sTableColumn='PA.POSTCODE'

			If charindex('Left Join ADDRESS PA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CountryName'	-- of the Postal Address
		Begin
			Set @sTableColumn='CP.COUNTRY'

			If charindex('Left Join ADDRESS PA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join COUNTRY CP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join COUNTRY CP		on (CP.COUNTRYCODE=PA.COUNTRYCODE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='StateName'	-- of the Postal Address
		Begin
			Set @sTableColumn='ST.STATENAME'

			If charindex('Left Join ADDRESS PA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join STATE ST',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join STATE ST		on (ST.COUNTRYCODE=PA.COUNTRYCODE'
						   +char(10)+'                    		and ST.STATE=PA.STATE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='MailingAddress'	-- of the Postal Address
		Begin
			Set @sTableColumn='dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, ST.STATENAME, PA.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)'

			If charindex('Left Join ADDRESS PA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join COUNTRY CP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join COUNTRY CP		on (CP.COUNTRYCODE=PA.COUNTRYCODE)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join STATE ST',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join STATE ST		on (ST.COUNTRYCODE=PA.COUNTRYCODE'
						   +char(10)+'                    		and ST.STATE=PA.STATE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='MailingLabel'	-- of the Postal Address
		Begin
			Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N1.NAMENO, isnull(N1.NAMESTYLE,7101))'
					+'+CASE WHEN(N1.NAME is not null) THEN char(13)+char(10) END'
					+'+dbo.fn_FormatNameUsingNameNo(N.NAMENO, isnull(N.NAMESTYLE,7101))+char(13)+char(10)'
					+'+dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, ST.STATENAME, PA.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)'

			If charindex('Left Join ADDRESS PA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS PA		on (PA.ADDRESSCODE=N.POSTALADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join COUNTRY CP',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join COUNTRY CP		on (CP.COUNTRYCODE=PA.COUNTRYCODE)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join STATE ST',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join STATE ST		on (ST.COUNTRYCODE=PA.COUNTRYCODE'
						   +char(10)+'                    		and ST.STATE=PA.STATE)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join NAME N1',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAME N1		on (N1.NAMENO=N.MAINCONTACT)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='StreetAddress'
		Begin
			Set @sTableColumn='dbo.fn_FormatAddress(SA.STREET1, SA.STREET2, SA.CITY, SA.STATE, SS.STATENAME, SA.POSTCODE, CS.POSTALNAME, CS.POSTCODEFIRST, CS.STATEABBREVIATED, CS.POSTCODELITERAL, CS.ADDRESSSTYLE)'

			If charindex('Left Join ADDRESS SA',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join ADDRESS SA		on (SA.ADDRESSCODE=N.STREETADDRESS)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join COUNTRY CS',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join COUNTRY CS		on (CS.COUNTRYCODE=SA.COUNTRYCODE)'

				Set @pnTableCount=@pnTableCount+1
			End

			If charindex('Left Join STATE SS',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join STATE SS		on (SS.COUNTRYCODE=SA.COUNTRYCODE'
						   +char(10)+'                    		and SS.STATE=SA.STATE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='GroupTitle'
		Begin
			Set @sTableColumn='NF.FAMILYTITLE'

			If charindex('Left Join NAMEFAMILY NF',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join NAMEFAMILY NF		on (NF.FAMILYNO=N.FAMILYNO)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='GroupComments'
		Begin
			Set @sTableColumn='NF.FAMILYCOMMENTS'

			If charindex('Left Join NAMEFAMILY NF',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+'Left Join NAMEFAMILY NF		on (NF.FAMILYNO=N.FAMILYNO)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='AttributeDescription'
		Begin
			Set @sTable1='TA'+@sCorrelationSuffix
			Set @sTable2='AT'+@sCorrelationSuffix
			Set @sTable3='OFAT'+@sCorrelationSuffix					
			Set @sTable4='TTP'+@sCorrelationSuffix
			Set @sTableColumn="CASE WHEN UPPER("+@sTable4+".DATABASETABLE) = 'OFFICE' THEN "+@sTable3+".DESCRIPTION ELSE "+@sTable2+".DESCRIPTION END" 

			If charindex(@psFrom, 'Left Join TABLEATTRIBUTES '+@sTable1)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TABLEATTRIBUTES "+@sTable1+"	on ("+@sTable1+".GENERICKEY=cast(N.NAMENO as varchar)"
						   +char(10)+"                                 	and "+@sTable1+".PARENTTABLE='NAME'"
						   +char(10)+"                                 	and "+@sTable1+".TABLETYPE=" + @sQualifier+")"
						   +char(10)+"Left Join TABLETYPE "+@sTable4+"  		on ("+@sTable4+".TABLETYPE="+@sTable1+".TABLETYPE)"	
						   +char(10)+"Left Join TABLECODES "+@sTable2+"  		on ("+@sTable2+".TABLECODE="+@sTable1+".TABLECODE)"
						   +char(10)+"Left Join OFFICE "+@sTable3+"		on ("+@sTable3+".OFFICEID = "+@sTable1+".TABLECODE)"			   												

				Set @pnTableCount=@pnTableCount+4
			End
		End

		Else If @sColumn='Alias'
		Begin
			Set @sTable1='NA'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.ALIAS'

			If charindex('Left Join NAMEALIAS '+@sTable1,@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAMEALIAS "+@sTable1+"		on ("+@sTable1+".NAMENO=N.NAMENO"
						   +char(10)+"                                 			and "+@sTable1+".ALIASTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='Text'
		Begin
			Set @sTable1='TX'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.TEXT'

			If charindex('Left Join NAMETEXT '+@sTable1,@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAMETEXT "+@sTable1+"		on ("+@sTable1+".NAMENO=N.NAMENO"
						   +char(10)+"                                 			and "+@sTable1+".TEXTTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"

				Set @pnTableCount=@pnTableCount+1
			End
		
			Set @nOrderPosition=null
		End

		Else If @sColumn='DisplayTelecomNumber'
		Begin
			Set @sTable1='NT'+@sCorrelationSuffix
			Set @sTable2='T' +@sCorrelationSuffix
			Set @sTableColumn='dbo.fn_FormatTelecom('+@sTable2+'.TELECOMTYPE, '+@sTable2+'.ISD, '+@sTable2+'.AREACODE, '+@sTable2+'.TELECOMNUMBER, '+@sTable2+'.EXTENSION)'

			If charindex('Left Join NAMETELECOM '+@sTable1,@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join NAMETELECOM "+@sTable1+"		on ("+@sTable1+".NAMENO=N.NAMENO)"
						   +char(10)+"Left Join TELECOMMUNICATION "+@sTable2+"		on ("+@sTable2+".TELECODE="+@sTable1+".TELECODE"
						   +char(10)+"                               		and "+@sTable2+".TELECOMTYPE="+@sQualifier
						   +char(10)+"                        			and "+@sTable2+".TELECOMNUMBER=(select min(T.TELECOMNUMBER)"
						   +char(10)+"                        		                      from TELECOMMUNICATION T"
						   +char(10)+"                        		                      where T.TELECODE="+@sTable1+".TELECODE))"

				Set @pnTableCount=@pnTableCount+3
			End
		End

		Else If @sColumn='DisplayMainEmail'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(EM.TELECOMTYPE, EM.ISD, EM.AREACODE, EM.TELECOMNUMBER, EM.EXTENSION)'

			If charindex('Left Join TELECOMMUNICATION EM',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TELECOMMUNICATION EM		on (EM.TELECODE=N.MAINEMAIL)"

				Set @pnTableCount=@pnTableCount+1
			End
		End		

		Else If @sColumn='DisplayMainFax'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(FX.TELECOMTYPE, FX.ISD, FX.AREACODE, FX.TELECOMNUMBER, FX.EXTENSION)'

			If charindex('Left Join TELECOMMUNICATION FX',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TELECOMMUNICATION FX		on (FX.TELECODE=N.FAX)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DisplayMainPhone'
		Begin
			Set @sTableColumn='dbo.fn_FormatTelecom(PH.TELECOMTYPE, PH.ISD, PH.AREACODE, PH.TELECOMNUMBER, PH.EXTENSION)'

			If charindex('Left Join TELECOMMUNICATION PH',@psFrom)=0
			Begin
				Set @psFrom=@psFrom+char(10)+"Left Join TELECOMMUNICATION PH		on (PH.TELECODE=N.MAINPHONE)"

				Set @pnTableCount=@pnTableCount+1
			End
		End


		-- If the column is being published then concatenate it to the Select list

		If datalength(@sPublishName)>0
		Begin
			Set @psSelect=@psSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
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
			values(@nOrderPosition, @sTableColumn, @sPublishName, @nColumnNo, 
			       Case When(@sOrderDirection='D') Then ' DESC' ELSE ' ASC' End)
		End
	End

	-- Get the next Column
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Select	@nColumnNoOUT=min(InsertOrder),
			@sColumnOUT  =min(Parameter)
		From	dbo.fn_Tokenise(@psColumnIds, @sDelimiter)
		Where	InsertOrder=@nColumnNo+1"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@nColumnNoOUT	tinyint		OUTPUT,
				  @sColumnOUT	nvarchar(255)	OUTPUT,
				  @nColumnNo	tinyint,
				  @psColumnIds  nvarchar(4000),
				  @sDelimiter   nchar(1)',
				  @nColumnNoOUT=@nColumnNo	OUTPUT,
				  @sColumnOUT  =@sColumn	OUTPUT,
				  @nColumnNo   =@nColumnNo,
				  @psColumnIds =@psColumnIds,
				  @sDelimiter  =@sDelimiter
	End
End

-- Now construct the Order By clause

If @ErrorCode=0
Begin
	Set @nLastPosition=-1

	Select	@sTableColumn   =ColumnName,
		@sPublishName	=PublishName,
		@sOrderDirection=Direction,
		@nOrderPosition =Position,
		@nColumnNo      =ColumnNumber
	From 	@tbOrderBy
	Where	Position=(	Select min(Position)
				from @tbOrderBy)

	Set @ErrorCode=@@Error

	If @nOrderPosition is not null
	Begin
		set @psOrder='Order By '
		Set @sComma =NULL
	End
End
-- Loop through each column to sort on.
-- If the CLASS column is to be sorted on then also include an extra sort on the numeric 
-- equivalent of the class.
--select * from @tbOrderBy

While @nOrderPosition>@nLastPosition
and   @ErrorCode=0
Begin
	Set @psOrder=@psOrder
			+@sComma
			+Case When(Charindex('.CLASS',@sTableColumn)>0)
				Then 'Case WHEN(isnumeric('+@sTableColumn+')=1) THEN cast('+@sTableColumn+' as numeric) END'
				     +Case WHEN(@sPublishName is not null)
					Then @sOrderDirection+',['+@sPublishName+']'
				      End
			      When(@sPublishName is null) 
				Then @sTableColumn
				Else '['+@sPublishName+']'
			 End
			+@sOrderDirection
	Set @sComma=','
	Set @nLastPosition=@nOrderPosition

	Select	@sTableColumn   =ColumnName,
		@sPublishName	=PublishName,
		@sOrderDirection=Direction,
		@nOrderPosition =Position,
		@nColumnNo      =ColumnNumber
	From 	@tbOrderBy
	Where	Position=(	Select min(Position)
				from @tbOrderBy
				Where Position>@nOrderPosition)


	Set @ErrorCode=@@Error
End

RETURN @ErrorCode
go

grant execute on dbo.na_ConstructNameSelect  to public
go
