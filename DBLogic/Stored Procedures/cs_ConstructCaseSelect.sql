-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ConstructCaseSelect
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ConstructCaseSelect]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ConstructCaseSelect.'
	drop procedure dbo.cs_ConstructCaseSelect
end
print '**** Creating procedure dbo.cs_ConstructCaseSelect...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_ConstructCaseSelect
	@psSelect			nvarchar(4000)  OUTPUT,	-- the SQL list of columns to return
	@psFrom1			nvarchar(4000)	OUTPUT,	-- the SQL to list tables and joins
	@psFrom2			nvarchar(4000)	OUTPUT,
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
-- PROCEDURE :	cs_ConstructCaseSelect
-- VERSION :	36
-- DESCRIPTION:	Receives a list of columns and details of a required sort order and constructs
--		the components of the SELECT statement to meet the requirement
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02/09/2002	MF			Procedure created
-- 12/09/2002	MF			Change the method of constructing the ORDER BY to avoid the NULLs warning message.
-- 17/09/2002	MF			New TrademarkClass column to return the class associated with the Goods/Services
-- 20/02/2003	SF		7	cast IsLocalClient to bit so it can be inferred correctly in the .Net Framework.
-- 12/02/2003	JEK	RFC12	8	Implement new columns EarliestDueEvent and EarliestDueDate.
-- 11-Apr-2003	JEK	RFC13	9	Change @psFrom to varchar(8000) and implement NameKey column ID.
-- 14-Apr-2003	JEK	RFC13	10	Update comments.
-- 14-Apr-2003	JEK	RFC13	11	All charindex(convert(varchar(100),) text also needs to be converted to varchar()
-- 16-Apr-2003	JEK	RFC13	12	Implement Report Ids DisplayNameAny, NameCodeAny, NameKeyAny, NameReferenceAny.
-- 17-Apr-2003	JEK	RFC13	13	Implement NULL Report Id.
-- 12-Aug-2003	TM	RFC224	14	Office level rules. Add CaseOfficeDescription as a selectable column 
-- 20-Aug-2003	TM	RFC40	15	Case List SQL exceeds max size. Replace the @psFrom varchar(8000) parameter with 
--					two parameters @psFrom1 and @psFrom2 nvarchar(4000). Remove all the conversion to varchar 
--					that was necessary when @psFrom was varchar. Then adjust the logic to use fn_ExistsInSplitString
--					to search for the required string and ip_ConcatenateSplitString to concatenate required string 
--					to any existing string supplied in @psString1/@psString2 with the results split across @psString1
--					and @psString2 as necessary. 
--					Returning of the @ErrorCode is not required for ip_ConcatenateSplitString call 
-- 					as ip_ConcatenateSplitString always returns 0 (it does not access the database).   
-- 07 Nov 2003	MF	RFC586	25	Use the fn_WrapQuotes function when constructing SQL with embedded string values
-- 31-Dec-2003	TM	RFC425	26	Concatenate '_' at the end of every correlation suffix so the various joins distinguished 
--					(e.g. the join for Event -1 will be created even though this search is matching on the join already present for -16).
-- 02-Jan-2004	TM	RFC631	27	Display an appropriate description if an Office attribute is chosen.
-- 05-Jan-2004	TM	RFC631	28	Use TABLETYPE.DATABASETABLE = 'OFFICE' instead of the hard coding a specific table type.  
-- 12-May-2004	TM	RFC1246	29	Implement fn_GetCorrelationSuffix function to generate the correlation suffix base on the supplied qualifier.
-- 02 Sep 2004	JEK	RFC1377	30	Pass new Centura parameter to fn_WrapQuotes
-- 29-Sep-2004	TM	RFC1806	31	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.
-- 11 Dec 2008	MF	17136	32	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	16548	33	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 07 Jul 2011	DL	RFC10830 34	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 04 Nov 2015	KR	R53910	35	Adjust formatted names logic (DR-15543)
-- 07 Sep 2018	AV	74738	36	Set isolation level to read uncommited.


-- The following Column Ids have been hardcoded to return specific data from the database
-- NOTE: Update this list if any new columns are added
--	AgeOfCase
-- 	ApplicationBasisDescription
--	AttributeDescription
-- 	CaseCategoryDescription
--	CaseFamilyReference
--	CaseKey
--	CaseOfficeDescription (RFC224)
--	CasePurchaseOrderNo
--	CaseReference
--	CaseStatusSummary
--	CaseTypeDescription
--	Class
--	CountryAdjective
--	CountryName
--	CurrentOfficialNumber
--	DesigCountryCode
--	DesigCountryName
--	DesigCountryStatus
--	DisplayName
--	DisplayNameAny (RFC13)
--	EarliestDueDate (RFC12)
--	EarliestDueEvent (RFC12)
--	EntitySizeDescription
--	EventDate
--	FileLocationDescription
--	ImageData
--	IntClasses
--	IsLocalClient
--	LocalClasses
--	NameAddress
--	NameCode
--	NameCodeAny (RFC13)
--	NameCountry
--	NameKey (RFC13)
--	NameKeyAny (RFC13)
--	NameReference
--	NameReferenceAny (RFC13)
--	NoInSeries
--	NoOfClaims
--	NoOfClasses
--	NULL (RFC13)
--	NumberTypeEventDate
--	OfficialNumber
--	OpenEventOrDueDate
--	OpenRenewalEventOrDue
--	PlaceFirstUsed
--	PropertyTypeDescription
--	ProposedUse
--	RelatedCountryName
--	RelatedOfficialNumber
--	RelationshipEventDate
--	RenewalNotes
--	RenewalStatusDescription
--	ReportToThirdParty
--	ShortTitle
--	StatusDescription
--	SubTypeDescription
--	Text
--	TrademarkClass
--	TypeOfMarkDescription

-- The following table correlation names have been used within this stored procedure
-- Take care when modifying this code to ensure that a previously used correlation name
-- is not used.  
-- Note: Update this list if new correlation names are assigned for any tables
--	A
--	AC
--	AT
--	C
--	CE
--	CI
--	CL
--	CN
--	CNA
--	CR
--	CS
--	CT
--	DC
--	DCN
--	I
--	N
--	NA
--	NE
--	NT
--	O
--	OFAT (RFC631)
--	OFC
--	P
--	RC
--	RCE
--	RCN
--	RCS
--	RS
--	ST
--	STATE
--	TA
--	TL
--	TC
--	TE
--	TM
--	TTP (RFC631)
--	VB
--	VC
--	VP
--	VS



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @ErrorCode		int
declare	@sDelimiter		nchar(1)
declare @sComma			nchar(2)	-- initialised when a column has been added to the Select
declare	@sSQLString		nvarchar(4000)
declare @sBuiltFrom		nvarchar(4000)  -- holds dynamically built string to be appended to the From clause
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
set @psFrom1	= 'From CASES C'

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
		If @sColumn='NULL'		-- RFC13
		Begin
			Set @sTableColumn='NULL'
		End
		Else If @sColumn='CaseFamilyReference'
		Begin
			Set @sTableColumn='C.FAMILY'
		End

		Else If @sColumn='CaseKey'
		Begin
			Set @sTableColumn='C.CASEID'
		End

		Else If @sColumn='CasePurchaseOrderNo'
		Begin
			Set @sTableColumn='C.PURCHASEORDERNO'
		End

		Else If @sColumn='CaseReference'
		Begin
			Set @sTableColumn='C.IRN'
		End

		Else If @sColumn='CurrentOfficialNumber'
		Begin
			Set @sTableColumn='C.CURRENTOFFICIALNO'
		End

		Else If @sColumn='IntClasses'
		Begin
			Set @sTableColumn='C.INTCLASSES'
		End

		Else If @sColumn='IsLocalClient'
		Begin
			Set @sTableColumn='cast(C.LOCALCLIENTFLAG as bit)'
		End

		Else If @sColumn='LocalClasses'
		Begin
			Set @sTableColumn='C.LOCALCLASSES'
		End

		Else If @sColumn='NoInSeries'
		Begin
			Set @sTableColumn='C.NOINSERIES'
		End

		Else If @sColumn='NoOfClasses'
		Begin
			Set @sTableColumn='C.NOOFCLASSES'
		End

		Else If @sColumn='ShortTitle'
		Begin
			Set @sTableColumn='C.TITLE'
		End

		Else If @sColumn='ReportToThirdParty'
		Begin
			Set @sTableColumn='C.REPORTTOTHIRDPARTY'
		End

		Else If @sColumn in ('NoOfClaims', 'PlaceFirstUsed', 'ProposedUse', 'RenewalNotes')
		Begin
			Set @sTableColumn='P.'+upper(@sColumn)

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join PROPERTY P')=0
			Begin
				-- Returning of the @ErrorCode is not required for ip_ConcatenateSplitString call 
				-- as ip_ConcatenateSplitString always returns 0 (it does not access the database).	
						
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join PROPERTY P		on (P.CASEID=C.CASEID)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CountryAdjective'
		Begin
			Set @sTableColumn='CT.COUNTRYADJECTIVE'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Join COUNTRY CT')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CountryName'
		Begin
			Set @sTableColumn='CT.COUNTRY'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Join COUNTRY CT')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)'
				
				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CaseTypeDescription'
		Begin
			Set @sTableColumn='CS.CASETYPEDESC'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Join CASETYPE CS')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Join CASETYPE CS		on (CS.CASETYPE=C.CASETYPE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='ApplicationBasisDescription'
		Begin
			Set @sTableColumn='VB.BASISDESCRIPTION'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join PROPERTY P')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join PROPERTY P		on (P.CASEID=C.CASEID)'

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join VALIDBASIS VB')=0
			Begin
				Set @sBuiltFrom = "Left Join VALIDBASIS VB		on (VB.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                          	and VB.BASIS       =P.BASIS"
				                   +char(10)+"                     		and VB.COUNTRYCODE = (select min(VB1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDBASIS VB1"
				                   +char(10)+"                     	                              where VB1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VB1.BASIS       =P.BASIS"
				                   +char(10)+"                     	                              and   VB1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"
				
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom
				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='CaseOfficeDescription'
		Begin
			Set @sTableColumn='OFC.DESCRIPTION'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join OFFICE OFC')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join OFFICE OFC		on (OFC.OFFICEID=C.OFFICEID)'
				
				Set @pnTableCount=@pnTableCount+1
			End
		End


		Else If @sColumn='CaseCategoryDescription'
		Begin
			Set @sTableColumn='VC.CASECATEGORYDESC'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join VALIDCATEGORY VC')=0
			Begin
				Set @sBuiltFrom = "Left Join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                          	and VC.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	and VC.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                     		and VC.COUNTRYCODE = (select min(VC1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDCATEGORY VC1"
				                   +char(10)+"                     	                              where VC1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VC1.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	                      and   VC1.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                     	                              and   VC1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"
							
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='PropertyTypeDescription'
		Begin
			Set @sTableColumn='VP.PROPERTYNAME'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Join VALIDPROPERTY VP')=0
			Begin
				Set @sBuiltFrom = "Join VALIDPROPERTY VP 		on (VP.PROPERTYTYPE = C.PROPERTYTYPE"
				                   +char(10)+"                     		and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)"
				                   +char(10)+"                     		                      from VALIDPROPERTY VP1"
				                   +char(10)+"                     		                      where VP1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                     		                      and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"

				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='SubTypeDescription'
		Begin
			Set @sTableColumn='VS.SUBTYPEDESC'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join VALIDSUBTYPE VS')=0
			Begin
				Set @sBuiltFrom = "Left Join VALIDSUBTYPE VS		on (VS.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                          	and VS.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	and VS.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                          	and VS.SUBTYPE     =C.SUBTYPE"
				                   +char(10)+"                     		and VS.COUNTRYCODE = (select min(VS1.COUNTRYCODE)"
				                   +char(10)+"                     	                              from VALIDSUBTYPE VS1"
				                   +char(10)+"                     	               	              where VS1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                                  	              and   VS1.CASETYPE    =C.CASETYPE"
				                   +char(10)+"                          	                      and   VS1.CASECATEGORY=C.CASECATEGORY"
				                   +char(10)+"                          	                      and   VS1.SUBTYPE     =C.SUBTYPE"
				                   +char(10)+"                     	                              and   VS1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))" 

				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom
			
				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='RenewalStatusDescription'
		Begin
			If @pbExternalUser=1
				Set @sTableColumn='RS.EXTERNALDESC'
			Else
				Set @sTableColumn='RS.INTERNALDESC'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join PROPERTY P')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join PROPERTY P		on (P.CASEID=C.CASEID)'
				
				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join STATUS RS')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join STATUS RS		on (RS.STATUSCODE=P.RENEWALSTATUS)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='StatusDescription'
		Begin
			If @pbExternalUser=1
				Set @sTableColumn='ST.EXTERNALDESC'
			Else
				Set @sTableColumn='ST.INTERNALDESC'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join STATUS ST')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join STATUS ST		on (ST.STATUSCODE=C.STATUSCODE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='CaseStatusSummary'
		Begin
			Set @sTableColumn='TC.DESCRIPTION'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join PROPERTY P')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join PROPERTY P		on (P.CASEID=C.CASEID)'

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join STATUS RS')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join STATUS RS		on (RS.STATUSCODE=P.RENEWALSTATUS)'

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join STATUS ST')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join STATUS ST		on (ST.STATUSCODE=C.STATUSCODE)'

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join TABLECODES TC')=0
			Begin				 
				Set @sBuiltFrom = 'Left Join TABLECODES TC		on (TC.TABLECODE=CASE WHEN(ST.LIVEFLAG=0 or RS.LIVEFLAG=0) Then 7603'
			                           +char(10)+'                       		                      WHEN(ST.REGISTEREDFLAG=1)            Then 7602'
				                   +char(10)+'                       		                                                           Else 7601'
				                   +char(10)+'                       			                 END)'

				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='TypeOfMarkDescription'
		Begin
			Set @sTableColumn='TM.DESCRIPTION'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join TABLECODES TM')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join TABLECODES TM		on (TM.TABLECODE=C.TYPEOFMARK)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='EntitySizeDescription'
		Begin
			Set @sTableColumn='TE.DESCRIPTION'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join TABLECODES TE')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = 'Left Join TABLECODES TE		on (TE.TABLECODE=C.ENTITYSIZE)'

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn in (	'DisplayName',
					'NameAddress',
					'NameCode',
					'NameCountry',
					'NameKey',
					'NameReference')
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin
			Set @sTable1='CN'+@sCorrelationSuffix

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASENAME '+@sTable1)=0 
			Begin
				Set @sBuiltFrom = "Left Join CASENAME "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                         		and "        +@sTable1+".NAMETYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
						   +char(10)+"                         		and("       +@sTable1+".EXPIRYDATE is null or "+@sTable1+".EXPIRYDATE>getdate() )"
						   +char(10)+"                         		and "        +@sTable1+".SEQUENCE=(select min(SEQUENCE) from CASENAME CN"
						   +char(10)+"                    		                                   where CN.CASEID=C.CASEID"
						   +char(10)+"                     		                                   and CN.NAMETYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
						   +char(10)+"                      		                                   and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())))"

				exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+2
			End
	
			If @sColumn='NameReference'
			Begin
				set @sTableColumn=@sTable1+'.REFERENCENO'
			End
			Else If @sColumn='NameKey'			-- RFC13
			Begin
				Set @sTableColumn=@sTable1+'.NAMENO'
			End
			Else Begin
				Set @sTable2='N'+@sCorrelationSuffix

				If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join NAME ')=0
				Begin
					Set @sBuiltFrom = "Left Join NAME "+@sTable2+"		on ("+@sTable2+".NAMENO="+@sTable1+".NAMENO)"
					
					exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom
	
					Set @pnTableCount=@pnTableCount+1
				End
		
				If @sColumn='DisplayName'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, NULL)'
				End
				Else If @sColumn='NameCode'
				Begin
					Set @sTableColumn=@sTable2+'.NAMECODE'
				End
				
				Else Begin
					Set @sTable3='A'+@sCorrelationSuffix

					If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join ADDRESS '+@sTable3)=0 
					Begin
						Set @sBuiltFrom = "Left Join ADDRESS "+@sTable3+"		on ("+@sTable3+".ADDRESSCODE=isnull("+@sTable1+".ADDRESSCODE,"+@sTable2+".POSTALADDRESS))"
		
						exec dbo.ip_ConcatenateSplitString
							@psString1 = @psFrom1	output,
							@psString2 = @psFrom2	output,
							@psAppendString = @sBuiltFrom	
						
						Set @pnTableCount=@pnTableCount+1
					End

					Set @sTable4='AC'+@sCorrelationSuffix

					If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join COUNTRY '+@sTable4)=0 
					Begin
						Set @sBuiltFrom = "Left Join COUNTRY "+@sTable4+"		on ("+@sTable4+".COUNTRYCODE="+@sTable3+".COUNTRYCODE)"
						
						exec dbo.ip_ConcatenateSplitString
							@psString1 = @psFrom1	output,
							@psString2 = @psFrom2	output,
							@psAppendString = @sBuiltFrom
		
						Set @pnTableCount=@pnTableCount+1
					End

					If @sColumn='NameCountry'
					Begin
						Set @sTableColumn=@sTable4+".COUNTRY"
					End
					Else If @sColumn='NameAddress'
					Begin

						Set @sTable5='STATE'+@sCorrelationSuffix

						If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join STATE '+@sTable5)=0 
						Begin
							Set @sBuiltFrom = "Left Join STATE "+@sTable5+"		on ("+@sTable5+".COUNTRYCODE="+@sTable3+".COUNTRYCODE"
									   +char(10)+"                   			and "+@sTable5+".STATE="+@sTable3+".STATE)"
							 
							exec dbo.ip_ConcatenateSplitString
								@psString1 = @psFrom1	output,
								@psString2 = @psFrom2	output,
								@psAppendString = @sBuiltFrom
			
							Set @pnTableCount=@pnTableCount+1

						End

						Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, '+@sTable4+'.NAMESTYLE)+char(13)+char(10)+'
								  +'dbo.fn_FormatAddress('+@sTable3+'.STREET1, '+@sTable3+'.STREET2, '+@sTable3+'.CITY, '+@sTable3+'.STATE, '+@sTable5+'.STATENAME, '+@sTable3+'.POSTCODE, '+@sTable4+'.POSTALNAME, '+@sTable4+'.POSTCODEFIRST, '+@sTable4+'.STATEABBREVIATED, '+@sTable4+'.POSTCODELITERAL, '+@sTable4+'.ADDRESSSTYLE)'
					End

				End
			End
		End

		-- RFC13 Implement versions of the Report Ids that will return any names, not just the main one
		Else If @sColumn in (	'DisplayNameAny',
					'NameCodeAny',
					'NameKeyAny',
					'NameReferenceAny')
		     and @sQualifier is not NULL	-- A parameter MUST exist 
		Begin
			Set @sTable1='CNA'+@sCorrelationSuffix

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASENAME '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join CASENAME "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                         		and "        +@sTable1+".NAMETYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
						   +char(10)+"                         		and("       +@sTable1+".EXPIRYDATE is null or "+@sTable1+".EXPIRYDATE>getdate() ))"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom		

				Set @pnTableCount=@pnTableCount+1
			End
	
			If @sColumn='NameReferenceAny'
			Begin
				set @sTableColumn=@sTable1+'.REFERENCENO'
			End
			Else If @sColumn='NameKeyAny'
			Begin
				Set @sTableColumn=@sTable1+'.NAMENO'
			End
			Else Begin
				Set @sTable2='NA'+@sCorrelationSuffix

				If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join NAME '+@sTable2)=0 
				Begin
					Set @sBuiltFrom = "Left Join NAME "+@sTable2+"		on ("+@sTable2+".NAMENO="+@sTable1+".NAMENO)"
		
					exec dbo.ip_ConcatenateSplitString
						@psString1 = @psFrom1	output,
						@psString2 = @psFrom2	output,
						@psAppendString = @sBuiltFrom					
	
					Set @pnTableCount=@pnTableCount+1
				End
		
				If @sColumn='DisplayNameAny'
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo('+@sTable2+'.NAMENO, NULL)'
				End
				Else If @sColumn='NameCodeAny'
				Begin
					Set @sTableColumn=@sTable2+'.NAMECODE'
				End
			End
		End

		Else If @sColumn='AttributeDescription'
		Begin
			Set @sTable1='TA'+@sCorrelationSuffix
			Set @sTable2='AT'+@sCorrelationSuffix
			Set @sTable3='OFAT'+@sCorrelationSuffix					
			Set @sTable4='TTP'+@sCorrelationSuffix
			Set @sTableColumn="CASE WHEN UPPER("+@sTable4+".DATABASETABLE) = 'OFFICE' THEN "+@sTable3+".DESCRIPTION ELSE "+@sTable2+".DESCRIPTION END" 

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join TABLEATTRIBUTES '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join TABLEATTRIBUTES "+@sTable1+"	on ("+@sTable1+".GENERICKEY=cast(C.CASEID as varchar)"
						   +char(10)+"                                 	and "+@sTable1+".PARENTTABLE='CASES'"
						   +char(10)+"                                 	and "+@sTable1+".TABLETYPE=" + @sQualifier+")"
						   +char(10)+"Left Join TABLETYPE "+@sTable4+"  		on ("+@sTable4+".TABLETYPE="+@sTable1+".TABLETYPE)"	
						   +char(10)+"Left Join TABLECODES "+@sTable2+"  		on ("+@sTable2+".TABLECODE="+@sTable1+".TABLECODE)"
						   +char(10)+"Left Join OFFICE "+@sTable3+"		on ("+@sTable3+".OFFICEID = "+@sTable1+".TABLECODE)"			   
								
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom	

				Set @pnTableCount=@pnTableCount+4
			End
		End

		-- RFC12 Start
		Else If @sColumn='EarliestDueDate'
		Begin
			Set @sTableColumn=	  "(select min(CE.EVENTDUEDATE)"
					+char(10)+" from OPENACTION O"
					+char(10)+" join EVENTCONTROL EC on (EC.CRITERIANO= O.CRITERIANO)"
					+char(10)+" join CASEEVENT CE	on (CE.CASEID     = C.CASEID"
					+char(10)+"			and CE.EVENTNO    = EC.EVENTNO"
					+char(10)+"			and convert(char(8),CE.EVENTDUEDATE,112)+convert(char(11), CE.EVENTNO)+convert(char(3),CE.CYCLE)"
					+char(10)+"			    = (select min(convert(char(8),CE1.EVENTDUEDATE,112)+convert(char(11), CE1.EVENTNO)+convert(char(3),CE1.CYCLE))"
					+char(10)+"			       from  CASEEVENT CE1"
					+char(10)+"			       where CE1.CASEID =C.CASEID"
					+char(10)+"			       and   CE1.OCCURREDFLAG=0))"
					+char(10)+"  where O.CASEID = C.CASEID"
				   	+char(10)+"  and O.POLICEEVENTS=1)"

		End

		Else If @sColumn='EarliestDueEvent'
		Begin
			Set @sTableColumn=	  "(select min(EC.EVENTDESCRIPTION)"
					+char(10)+" from OPENACTION O"
					+char(10)+" join EVENTCONTROL EC on (EC.CRITERIANO= O.CRITERIANO)"
					+char(10)+" join CASEEVENT CE	on (CE.CASEID     = C.CASEID"
					+char(10)+"			and CE.EVENTNO    = EC.EVENTNO"
					+char(10)+"			and convert(char(8),CE.EVENTDUEDATE,112)+convert(char(11), CE.EVENTNO)+convert(char(3),CE.CYCLE)"
					+char(10)+"			    = (select min(convert(char(8),CE1.EVENTDUEDATE,112)+convert(char(11), CE1.EVENTNO)+convert(char(3),CE1.CYCLE))"
					+char(10)+"			       from  CASEEVENT CE1"
					+char(10)+"			       where CE1.CASEID =C.CASEID"
					+char(10)+"			       and   CE1.OCCURREDFLAG=0))"
					+char(10)+"  where O.CASEID = C.CASEID"
				   	+char(10)+"  and O.POLICEEVENTS=1)"

		End
		-- RFC12 End

		Else If @sColumn='EventDate'
		Begin
			Set @sTable1='CE'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.EVENTDATE'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASEEVENT '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join CASEEVENT "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 			and "+@sTable1+".EVENTNO="+@sQualifier+")"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='OpenEventOrDue'
		Begin
			Set @sTableColumn=	  "(select min(isnull(CE.EVENTDATE,CE.EVENTDUEDATE))"
					+char(10)+" from CASEEVENT CE"
					+char(10)+" join ACTIONS AC	on (AC.ACTION=CE.CREATEDBYACTION)"
					+char(10)+" join OPENACTION O	on (O.CASEID=CE.CASEID"
					+char(10)+" 			and O.ACTION=AC.ACTION"
					+char(10)+" 			and O.CYCLE=CASE WHEN(AC.NUMCYCLESALLOWED=1) THEN 1 ELSE CE.CYCLE END"
					+char(10)+" 			and O.CYCLE=(select min(O1.CYCLE)"
					+char(10)+" 					from OPENACTION O1"
					+char(10)+" 					where O1.CASEID=CE.CASEID"
					+char(10)+" 					and O1.ACTION=O.ACTION"
					+char(10)+" 					and O1.POLICEEVENTS=1))"
					+char(10)+"  where CE.CASEID=C.CASEID"
					+char(10)+"  and CE.EVENTNO="+@sQualifier+")"
		End

		Else If @sColumn='OpenRenewalEventOrDue'
		Begin
			Set @sTableColumn=	  "(select isnull(CE.EVENTDATE,CE.EVENTDUEDATE)"
					+char(10)+" from CASEEVENT CE"
					+char(10)+" join SITECONTROL S	on (S.CONTROLID='Main Renewal Action')"
					+char(10)+" join OPENACTION O	on (O.CASEID=CE.CASEID"
					+char(10)+" 			and O.ACTION=S.COLCHARACTER"
					+char(10)+" 			and O.CYCLE=CE.CYCLE"
					+char(10)+" 			and O.CYCLE=(select min(O1.CYCLE)"
					+char(10)+" 					from OPENACTION O1"
					+char(10)+" 					where O1.CASEID=CE.CASEID"
					+char(10)+" 					and O1.ACTION=O.ACTION"
					+char(10)+" 					and O1.POLICEEVENTS=1))"
					+char(10)+"  where CE.CASEID=C.CASEID"
					+char(10)+"  and CE.EVENTNO="+@sQualifier+")"
		End

		Else If @sColumn='OfficialNumber'
		Begin
			Set @sTable1='O'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.OFFICIALNUMBER'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join OFFICIALNUMBERS '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join OFFICIALNUMBERS "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 			and "+@sTable1+".ISCURRENT=1"
						   +char(10)+"                                 			and "+@sTable1+".NUMBERTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='NumberTypeEventDate'
		Begin
			Set @sTable1='NT'+@sCorrelationSuffix
			Set @sTable2='NE'+@sCorrelationSuffix
			Set @sTableColumn=@sTable2+'.EVENTDATE'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join NUMBERTYPES '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join NUMBERTYPES "+@sTable1+"		on ("+@sTable1+".NUMBERTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"
						   +char(10)+"Left Join CASEEVENT "  +@sTable2+"		on ("+@sTable2+".CASEID=C.CASEID"
						   +char(10)+"                                  	and "+@sTable2+".CYCLE=1"
						   +char(10)+"                 	       		and "+@sTable2+".EVENTNO="+@sTable1+".RELATEDEVENTNO)"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='AgeOfCase'
		Begin
			Set @sTableColumn=	  "(select datediff(yy,CE1.EVENTDATE, isnull(CE.EVENTDUEDATE,CE.EVENTDATE))-isnull(VP.OFFSET,0)"
					+char(10)+" from CASEEVENT CE"
					+char(10)+" join CASEEVENT CE1	on (CE1.CASEID=CE.CASEID"
					+char(10)+"                   	and CE1.EVENTNO=-9"
					+char(10)+"                   	and CE1.CYCLE=1)"
					+char(10)+" join SITECONTROL S	on (S.CONTROLID='Main Renewal Action')"
					+char(10)+" join OPENACTION O	on (O.CASEID=CE.CASEID"
					+char(10)+" 			and O.ACTION=S.COLCHARACTER"
					+char(10)+" 			and O.CYCLE=CE.CYCLE"
					+char(10)+" 			and O.CYCLE=(select min(O1.CYCLE)"
					+char(10)+" 					from OPENACTION O1"
					+char(10)+" 					where O1.CASEID=CE.CASEID"
					+char(10)+" 					and O1.ACTION=O.ACTION"
					+char(10)+" 					and O1.POLICEEVENTS=1))"
					+char(10)+"  where CE.CASEID=C.CASEID"
					+char(10)+"  and CE.EVENTNO=-11)"

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Join VALIDPROPERTY VP')=0
			Begin
				Set @sBuiltFrom = "Join VALIDPROPERTY VP 		on (VP.PROPERTYTYPE = C.PROPERTYTYPE"
				                   +char(10)+"                     		and VP.COUNTRYCODE = (select min(VP1.COUNTRYCODE)"
				                   +char(10)+"                     		                      from VALIDPROPERTY VP1"
				                   +char(10)+"                     		                      where VP1.PROPERTYTYPE=C.PROPERTYTYPE"
				                   +char(10)+"                     		                      and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"
		
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='Text'
		Begin
			Set @sTable1='CT'+@sCorrelationSuffix
			Set @sTableColumn='isnull('+@sTable1+'.SHORTTEXT,'+@sTable1+'.TEXT)'
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASETEXT '+@sTable1)=0    
			Begin
				Set @sBuiltFrom = "Left Join CASETEXT "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".TEXTTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
						   +char(10)+"                               		and "+@sTable1+".MODIFIEDDATE=(select max(CT.MODIFIEDDATE)"
						   +char(10)+"                                				from CASETEXT CT"
						   +char(10)+"                                				where CT.CASEID="+@sTable1+".CASEID"
						   +char(10)+"                                				and CT.TEXTTYPE="+@sTable1+".TEXTTYPE"
						   +char(10)+"                                				and (CT.CLASS="+@sTable1+".CLASS OR (CT.CLASS is null and "+@sTable1+".CLASS is null))))"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='TrademarkClass'
		Begin
			Set @sTable1='CT'+@sCorrelationSuffix
			Set @sTableColumn=@sTable1+'.CLASS'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASETEXT '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join CASETEXT "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".TEXTTYPE="+dbo.fn_WrapQuotes(@sQualifier,0,0)
						   +char(10)+"                               		and "+@sTable1+".MODIFIEDDATE=(select max(CT.MODIFIEDDATE)"
						   +char(10)+"                                				from CASETEXT CT"
						   +char(10)+"                                				where CT.CASEID="+@sTable1+".CASEID"
						   +char(10)+"                                				and CT.TEXTTYPE="+@sTable1+".TEXTTYPE"
						   +char(10)+"                                				and (CT.CLASS="+@sTable1+".CLASS OR (CT.CLASS is null and "+@sTable1+".CLASS is null))))"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='ImageData'
		Begin
			Set @sTable1='CI'+@sCorrelationSuffix
			Set @sTable2='I' +@sCorrelationSuffix
			Set @sTableColumn=@sTable2+'.IMAGEDATA'
			Set @nOrderPosition=NULL	-- Ensure the column will not be used in the Order By

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASEIMAGE '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join CASEIMAGE "+@sTable1+"		on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".IMAGETYPE="+@sQualifier
						   +char(10)+"                               		and "+@sTable1+".IMAGESEQUENCE=(select min(CI.IMAGESEQUENCE)"
						   +char(10)+"                                				from CASEIMAGE CI"
						   +char(10)+"                                				where CI.CASEID="+@sTable1+".CASEID"
						   +char(10)+"                                				and CI.IMAGETYPE="+@sTable1+".IMAGETYPE))"
						   +char(10)+"Left Join IMAGE "+@sTable2+"		on ("+@sTable2+".IMAGEID="+@sTable1+".IMAGEID)"

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+3
			End
		End

		Else If @sColumn='DesigCountryCode'
		Begin
			Set @sTableColumn='DC.COUNTRYCODE'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join RELATEDCASE DC')=0
			Begin
				Set @sBuiltFrom = "Left Join RELATEDCASE DC			on (DC.CASEID=C.CASEID"
						   +char(10)+"                                 		and DC.RELATIONSHIP='DC1')"				

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DesigCountryName'
		Begin
			Set @sTableColumn='DCN.COUNTRY'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join RELATEDCASE DC')=0
			Begin
				Set @sBuiltFrom = "Left Join RELATEDCASE DC			on (DC.CASEID=C.CASEID"
						   +char(10)+"                                 		and DC.RELATIONSHIP='DC1')"

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join COUNTRY DCN')=0
			Begin
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = "Left Join COUNTRY DCN			on (DCN.COUNTRYCODE=DC.COUNTRYCODE)"

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='DesigCountryStatus'
		Begin
			Set @sTableColumn='DCF.FLAGNAME'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join RELATEDCASE DC')=0
			Begin
				Set @sBuiltFrom = "Left Join RELATEDCASE DC			on (DC.CASEID=C.CASEID"
						   +char(10)+"                                 		and DC.RELATIONSHIP='DC1')"		
	
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join COUNTRYFLAGS DCF')=0
			Begin
				Set @sBuiltFrom = "Left Join COUNTRYFLAGS DCF		on (DCF.COUNTRYCODE=C.COUNTRYCODE"
						   +char(10)+"                           		and DCF.FLAGNUMBER =DC.CURRENTSTATUS)"

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='FileLocationDescription'
		Begin
			Set @sTableColumn='TL.DESCRIPTION'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASELOCATION CL')=0
			Begin
				Set @sBuiltFrom = "Left Join CASELOCATION CL			on (CL.CASEID=C.CASEID"
						   +char(10)+"                                 		and CL.WHENMOVED=(select max(WHENMOVED)"
						   +char(10)+"                         						from CASELOCATION CL1"
						   +char(10)+"                          					where CL1.CASEID=CL.CASEID))"
						   +char(10)+"Left Join TABLECODES TL			on (TL.TABLECODE=CL.FILELOCATION)"

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+2
			End
		End

		Else If @sColumn='RelatedCountryName'
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCN'+@sCorrelationSuffix
			Set @sTableColumn=@sTable2+'.COUNTRY'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join RELATEDCASE '+@sTable1)=0
			Begin
				Set @sBuiltFrom =  "Left Join RELATEDCASE "+@sTable1+"	on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".RELATIONSHIP="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join COUNTRY '+@sTable2)=0
			Begin
				Set @sBuiltFrom = "Left Join COUNTRY "+@sTable2+"	on ("+@sTable2+".COUNTRYCODE="+@sTable1+".COUNTRYCODE)"

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='RelationshipEventDate'
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCE'+@sCorrelationSuffix
			set @sTable3='CR' +@sCorrelationSuffix
			Set @sTableColumn='isnull('+@sTable2+'.EVENTDATE, '+@sTable1+'.PRIORITYDATE)'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join RELATEDCASE '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join RELATEDCASE "+@sTable1+"	on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".RELATIONSHIP="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASERELATION '+@sTable3)=0
			Begin
				Set @sBuiltFrom = "Left Join CASERELATION "+@sTable3+"	on ("+@sTable3+".RELATIONSHIP="+@sTable1+".RELATIONSHIP)"
				                   +char(10)+"Left Join CASEEVENT "   +@sTable2+"	on ("+@sTable2+".CASEID=" +@sTable1+".RELATEDCASEID"
						   +char(10)+"                         			and "+@sTable2+".EVENTNO=isnull("+@sTable3+".DISPLAYEVENTNO,"+@sTable3+".FROMEVENTNO)"
						   +char(10)+"                         			and "+@sTable2+".CYCLE=1)"
				 
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End
		End

		Else If @sColumn='RelatedOfficialNumber'
		Begin
			Set @sTable1='RC' +@sCorrelationSuffix
			Set @sTable2='RCS'+@sCorrelationSuffix
			Set @sTableColumn='isnull('+@sTable2+'.CURRENTOFFICIALNO, '+@sTable1+'.OFFICIALNUMBER)'

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join RELATEDCASE '+@sTable1)=0
			Begin
				Set @sBuiltFrom = "Left Join RELATEDCASE "+@sTable1+"	on ("+@sTable1+".CASEID=C.CASEID"
						   +char(10)+"                                 		and "+@sTable1+".RELATIONSHIP="+dbo.fn_WrapQuotes(@sQualifier,0,0)+")"
				
				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

				Set @pnTableCount=@pnTableCount+1
			End

			If dbo.fn_ExistsInSplitString(@psFrom1, @psFrom2, 'Left Join CASES '+@sTable2)=0
			Begin
				Set @sBuiltFrom = "Left Join CASES " +@sTable2+"	on ("+@sTable2+".CASEID=" +@sTable1+".RELATEDCASEID)"

				exec dbo.ip_ConcatenateSplitString
					@psString1 = @psFrom1	output,
					@psString2 = @psFrom2	output,
					@psAppendString = @sBuiltFrom

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

While @nOrderPosition>@nLastPosition
and   @ErrorCode=0
Begin
	Set @psOrder=@psOrder
			+@sComma
			+Case When(charindex('.CLASS',@sTableColumn)>0)
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

grant execute on dbo.cs_ConstructCaseSelect  to public
go
