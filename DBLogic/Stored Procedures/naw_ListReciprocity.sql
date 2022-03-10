-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListReciprocity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListReciprocity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure  dbo.naw_ListReciprocity.'
	Drop procedure dbo.naw_ListReciprocity
End
Print '**** Creating Stored Procedure dbo.naw_ListReciprocity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListReciprocity
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
-- PROCEDURE :	naw_ListReciprocity
-- VERSION :	16
-- DESCRIPTION:	Searches and return reciprocity statistics.
-- CALLED BY :	WorkBenches

-- MODIFICTIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19 Sep 2008	AT	R5759	1	Procedure created.
-- 04 Feb 2009	AT	R7229	2	Add Name Filtering and allow the return of names with no in/out cases.
-- 26 Mar 2009	AT	R7230 	3	Add Opportunity Remarks(Comments) and Next Step.
-- 06 May 2009	AT	R7970	4	Fixed Period Range filtering.
-- 03 Nov 2009	AT	R8596	5	Default Event No to -13 if Reciprocity Event is null.
-- 04 Feb 2011	PA	R9567	6	Add Contact Activity column in Reciprocity Search Results window.
-- 15 Mar 2011  DV      R9947	7       Add new Marketing Activities column
-- 18 Apr 2011  MS      R9270	8       Join with #CASESTOINCLUDE to include PropertyType in ReciprocitySearch 
-- 07 Jul 2011	DL	R10830	9	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 29 Nov 2012	vql	R12824	10	Value for IN/OUT columns in Web Reciprocity search do not match Client/server results
-- 05 Jul 2013	vql	R13629	11	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 22 Jan 2014	MF	R29826	12	Correction to code that gets the list of Disbursement WIPTYPES to include in the reciprocity results.
-- 02 Nov 2015	vql	R53910	13	Adjust formatted names logic (DR-15543).
-- 05 Jun 2017	MF	71678	14	If no date range supplied for filter, generated query was crashing.  Corrected to handle this condition.
-- 22 May 2018	MF	74067	15	SQL Error occurring when filter is on Staff/Signatory Group
-- 14 Nov 2018  AV  75198/DR-45358	16   Date conversion errors when creating cases and opening names in Chinese DB

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

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

Declare @idoc 				int 	-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @nStartNameFilter 		int	-- the starting position of the name filter
declare @nEndNameFilter 		int	-- the ending position of the name filter

Declare @sSQLString			nvarchar(4000)
Declare @sLookupCulture			nvarchar(10)

Declare @nCount				int		-- Current table row being processed.
Declare @sSelect			nvarchar(4000)
Declare @sFrom				nvarchar(4000)
Declare @sWhere				nvarchar(4000)
Declare @sOrder				nvarchar(4000)

Declare @bPrintSQL			bit -- for debugging sql (set below)
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.

-- Filter Criteria
Declare @sIncomingNameType			nvarchar(3)
Declare @nFilesInOperator			int
Declare @sFilesIn				nvarchar(3)
Declare @bIsRestrictNamesToAgents		bit
Declare @nCaseTypeOperator			int
Declare @sCaseTypeKey				nvarchar(1)
Declare @nPropertyTypeOperator			bit
Declare @sPropertyTypeKey			nvarchar(1)
Declare @nCaseCategoryOperator			int
Declare @sCaseCategoryKey			nvarchar(2)
Declare @nStaffOperator				int
Declare @nStaffKey				int
Declare @nSigntaoryOperator			int
Declare @nSignatoryKey				int
Declare @nStaffSigGroupOperator			int
Declare @nStaffSigGroupKey			int
Declare @nAgentActedForOperator			int
Declare @nAgentActedForKey			int
Declare @dtCaseDateRangeFrom			datetime
Declare @dtCaseDateRangeTo			datetime
Declare @nCaseDateRangeOperator			int
Declare @nCasePeriodFrom			int
Declare @nCasePeriodTo				int
Declare @sCasePeriodType			nvarchar(2)
Declare @nCasePeriodRangeOperator		int
Declare @bIsReciprocityDateFilter		bit -- use Reciprocity date or event date
Declare @dtValueDateRangeFrom			datetime
Declare @dtValueDateRangeTo			datetime
Declare @nValueDateRangeOperator		int
Declare @nValuePeriodFrom			int
Declare @nValuePeriodTo				int
Declare @sValuePeriodType			nvarchar(2)
Declare @nValuePeriodRangeOperator		int
Declare @nNameKey				int

declare @sCaseSelect nvarchar(4000)
declare @sCaseFrom nvarchar(4000)
declare @sCaseWhere nvarchar(4000)
declare @sNameSelect nvarchar(4000)
declare @sNameFrom nvarchar(4000)
declare @sNameWhere nvarchar(4000)
declare @sNameFilterWhere nvarchar(4000)
declare @sNameFilter nvarchar(4000)

declare @nReciprocityEvent int
declare @sDisbursementList			nvarchar(max)
declare @bReverseDates bit

Set	@String 		='S'
Set	@Date   		='DT'
Set	@Numeric		='N'
Set	@Text   		='T'
Set	@CommaString		='CS'

-- Initialise variables
Set 	@nErrorCode 		= 0
Set     @nCount			= 1
Set 	@bPrintSQL 		= 0

set 	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

--  If the @ptXMLOutputRequests have been supplied, the table variable is populated from the XML.
If datalength(@ptXMLOutputRequests) > 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLOutputRequests
	
	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, @ptXMLOutputRequests, @idoc, @pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
	
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
End
-- If the @ptXMLOutputRequests was not supplied, the @pnQueryContextKey is used to obtain the default presentation from the database
Else
Begin
	-- Default @pnQueryContextKey to 18.
	Set @pnQueryContextKey = isnull(@pnQueryContextKey, 18)

	Insert into @tblOutputRequests (ROWNUMBER, ID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY)
	Select ROWNUMBER, COLUMNID, SORTORDER, SORTDIRECTION, PUBLISHNAME, QUALIFIER, DOCITEMKEY 
	from dbo.fn_GetQueryOutputRequests(@pnUserIdentityId, @psCulture, @pnQueryContextKey, null, null,@pbCalledFromCentura,null)

	-- Store the number of rows in the @tblOutputRequests to be able to loop through it 
	-- while constructing the "Select" list   
	Set @nOutRequestsRowCount	= @@ROWCOUNT
End

If (datalength(@ptXMLFilterCriteria) > 0)
	and @nErrorCode = 0
Begin
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	Set @sSQLString = "Select @sIncomingNameType 	= IncomingNameType,"+CHAR(10)+
	"	@nFilesInOperator	= FilesInOperator,"+CHAR(10)+
	"	@sFilesIn 		= FilesIn,"+CHAR(10)+
	"	@bIsRestrictNamesToAgents = IsRestrictNamesToAgents,"+CHAR(10)+
	"	@nCaseTypeOperator	= CaseTypeOperator,"+CHAR(10)+
	"	@sCaseTypeKey		= CaseTypeKey,"+CHAR(10)+
	"	@nPropertyTypeOperator	= PropertyTypeOperator,"+CHAR(10)+
	"	@sPropertyTypeKey	= PropertyTypeKey,"+CHAR(10)+
	"	@nCaseCategoryOperator	= CaseCategoryOperator,"+CHAR(10)+
	"	@sCaseCategoryKey	= CaseCategoryKey,"+CHAR(10)+
	"	@nStaffOperator		= StaffOperator,"+CHAR(10)+
	"	@nStaffKey 		= StaffKey,"+CHAR(10)+
	"	@nSigntaoryOperator	= SigntaoryOperator,"+CHAR(10)+
	"	@nSignatoryKey		= SignatoryKey,"+CHAR(10)+
	"	@nStaffSigGroupOperator	= StaffSigGroupOperator,"+CHAR(10)+
	"	@nStaffSigGroupKey	= StaffSigGroupKey,"+CHAR(10)+
	"	@nAgentActedForOperator	= AgentActedForOperator,"+CHAR(10)+
	"	@nAgentActedForKey	= AgentActedForKey,"+CHAR(10)+
	"	@dtCaseDateRangeFrom 	= CaseDateRangeFrom,"+CHAR(10)+
	"	@dtCaseDateRangeTo	= CaseDateRangeTo,"+CHAR(10)+
	"	@nCaseDateRangeOperator	= CaseDateRangeOperator,"+CHAR(10)+
	"	@nCasePeriodFrom	= CasePeriodFrom,"+CHAR(10)+
	"	@nCasePeriodTo		= CasePeriodTo,"+CHAR(10)+
	"	@sCasePeriodType	= CASE WHEN CasePeriodType = 'D' THEN 'dd'"+CHAR(10)+
	"			     WHEN CasePeriodType = 'W' THEN 'wk'"+CHAR(10)+
	"			     WHEN CasePeriodType = 'M' THEN 'mm'"+CHAR(10)+
	"			     WHEN CasePeriodType = 'Y' THEN 'yy' END,"+CHAR(10)+
	"	@nCasePeriodRangeOperator = CasePeriodRangeOperator,"+CHAR(10)+
	"	@bIsReciprocityDateFilter = IsReciprocityDateFilter,"+CHAR(10)+
	"	@dtValueDateRangeFrom 	= ValueDateRangeFrom,"+CHAR(10)+
	"	@dtValueDateRangeTo	= ValueDateRangeTo,"+CHAR(10)+
	"	@nValueDateRangeOperator = ValueDateRangeOperator,"+CHAR(10)+
	"	@nValuePeriodFrom	= ValuePeriodFrom,"+CHAR(10)+
	"	@nValuePeriodTo		= ValuePeriodTo,"+CHAR(10)+
	"	@sValuePeriodType	= CASE WHEN ValuePeriodType = 'D' THEN 'dd'"+CHAR(10)+
	"			     WHEN ValuePeriodType = 'W' THEN 'wk'"+CHAR(10)+
	"			     WHEN ValuePeriodType = 'M' THEN 'mm'"+CHAR(10)+
	"			     WHEN ValuePeriodType = 'Y' THEN 'yy' END,"+CHAR(10)+
	"	@nValuePeriodRangeOperator = ValuePeriodRangeOperator,"+CHAR(10)+
	"	@nNameKey = NameKey"+CHAR(10)+
	"from	OPENXML (@idoc, '/naw_ListReciprocity/FilterCriteriaGroup/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	IncomingNameType	nvarchar(3)	'IncomingNameType/text()',"+CHAR(10)+
	"	FilesInOperator		int		'FilesIn/@Operator/text()',"+CHAR(10)+
	"	FilesIn			nvarchar(3)	'FilesIn/text()',"+CHAR(10)+
	"	IsRestrictNamesToAgents bit		'FilesIn/@IsRestrictNamesToAgents/text()',"+CHAR(10)+
	"	CaseTypeOperator	int		'CaseType/@Operator/text()',"+CHAR(10)+
	"	CaseTypeKey		nvarchar(1)	'CaseType/text()',"+CHAR(10)+
	"	PropertyTypeOperator	bit		'PropertyType/@Operator/text()',"+CHAR(10)+
	"	PropertyTypeKey		nvarchar(1)	'PropertyType/text()',"+CHAR(10)+
	"	CaseCategoryOperator	int		'CaseCategory/@Operator/text()',"+CHAR(10)+
	"	CaseCategoryKey		nvarchar(2)	'CaseCategory/text()',"+CHAR(10)+
	"	StaffOperator		int		'StaffKey/@Operator/text()',"+CHAR(10)+
	"	StaffKey		int		'StaffKey/text()',"+CHAR(10)+
	"	SigntaoryOperator	int		'SignatoryKey/@Operator/text()',"+CHAR(10)+
	"	SignatoryKey		int		'SignatoryKey/text()',"+CHAR(10)+
	"	StaffSigGroupOperator	int		'StaffSigGroupKey/@Operator/text()',"+CHAR(10)+
	"	StaffSigGroupKey	int		'StaffSigGroupKey/text()',"+CHAR(10)+
	"	AgentActedForOperator	int		'AgentActedForKey/@Operator/text()',"+CHAR(10)+
	"	AgentActedForKey	int		'AgentActedForKey/text()',"+CHAR(10)+
	"	CaseDateRangeFrom	datetime	'CaseDateFilter/DateRange/From/text()',"+CHAR(10)+
	"	CaseDateRangeTo		datetime	'CaseDateFilter/DateRange/To/text()',"+CHAR(10)+
	"	CaseDateRangeOperator	int		'CaseDateFilter/DateRange/@Operator/text()',"+CHAR(10)+
	"	CasePeriodFrom		int		'CaseDateFilter/PeriodRange/From/text()',"+CHAR(10)+
	"	CasePeriodTo		int		'CaseDateFilter/PeriodRange/To/text()',"+CHAR(10)+
	"	CasePeriodType		nvarchar(2)	'CaseDateFilter/PeriodRange/Type/text()',"+CHAR(10)+
	"	CasePeriodRangeOperator int		'CaseDateFilter/PeriodRange/@Operator/text()',"+CHAR(10)+
	"	IsReciprocityDateFilter bit		'CaseDateFilter/@IsReciprocityDateFilter/text()',"+CHAR(10)+
	"	ValueDateRangeFrom	datetime	'ValueDateFilter/DateRange/From/text()',"+CHAR(10)+
	"	ValueDateRangeTo	datetime	'ValueDateFilter/DateRange/To/text()',"+CHAR(10)+
	"	ValueDateRangeOperator 	int		'ValueDateFilter/DateRange/@Operator/text()',"+CHAR(10)+
	"	ValuePeriodFrom		int		'ValueDateFilter/PeriodRange/From/text()',"+CHAR(10)+
	"	ValuePeriodTo		int		'ValueDateFilter/PeriodRange/To/text()',"+CHAR(10)+
	"	ValuePeriodType		nvarchar(2)	'ValueDateFilter/PeriodRange/Type/text()',"+CHAR(10)+
	"	ValuePeriodRangeOperator int		'ValueDateFilter/PeriodRange/@Operator/text()',"+CHAR(10)+
	"	NameKey			int		'NameKey/text()'"+CHAR(10)+
	")"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@idoc				int,
		@sIncomingNameType		nvarchar(3)	output,
		@nFilesInOperator		int		output,
		@sFilesIn			nvarchar(3)	output,
		@bIsRestrictNamesToAgents	bit		output,
		@nCaseTypeOperator		int		output,
		@sCaseTypeKey			nvarchar(1)	output,
		@nPropertyTypeOperator		bit		output,
		@sPropertyTypeKey		nvarchar(1)	output,
		@nCaseCategoryOperator		int		output,
		@sCaseCategoryKey		nvarchar(2)	output,
		@nStaffOperator			int		output,
		@nStaffKey			int		output,
		@nSigntaoryOperator		int		output,
		@nSignatoryKey			int		output,
		@nStaffSigGroupOperator		int		output,
		@nStaffSigGroupKey		int		output,
		@nAgentActedForOperator		int		output,
		@nAgentActedForKey		int		output,
		@dtCaseDateRangeFrom		datetime	output,
		@dtCaseDateRangeTo		datetime	output,
		@nCaseDateRangeOperator		int		output,
		@nCasePeriodFrom		int		output,
		@nCasePeriodTo			int		output,
		@sCasePeriodType		nvarchar(2)	output,
		@nCasePeriodRangeOperator	int		output,
		@bIsReciprocityDateFilter	bit		output,
		@dtValueDateRangeFrom		datetime	output,
		@dtValueDateRangeTo		datetime	output,
		@nValueDateRangeOperator	int		output,
		@nValuePeriodFrom		int		output,
		@nValuePeriodTo			int		output,
		@sValuePeriodType		nvarchar(2)	output,
		@nValuePeriodRangeOperator	int		output,
		@nNameKey			int		output',
		@idoc				= @idoc,
		@sIncomingNameType		= @sIncomingNameType	output,
		@nFilesInOperator		= @nFilesInOperator	output,
		@sFilesIn			= @sFilesIn		output,
		@bIsRestrictNamesToAgents	= @bIsRestrictNamesToAgents output,
		@nCaseTypeOperator		= @nCaseTypeOperator	output,
		@sCaseTypeKey			= @sCaseTypeKey		output,
		@nPropertyTypeOperator		= @nPropertyTypeOperator output,
		@sPropertyTypeKey		= @sPropertyTypeKey	output,
		@nCaseCategoryOperator		= @nCaseCategoryOperator output,
		@sCaseCategoryKey		= @sCaseCategoryKey	output,
		@nStaffOperator			= @nStaffOperator	output,
		@nStaffKey			= @nStaffKey		output,
		@nSigntaoryOperator		= @nSigntaoryOperator	output,
		@nSignatoryKey			= @nSignatoryKey	output,
		@nStaffSigGroupOperator		= @nStaffSigGroupOperator output,
		@nStaffSigGroupKey		= @nStaffSigGroupKey	output,
		@nAgentActedForOperator		= @nAgentActedForOperator output,
		@nAgentActedForKey		= @nAgentActedForKey	output,
		@dtCaseDateRangeFrom		= @dtCaseDateRangeFrom	output,
		@dtCaseDateRangeTo		= @dtCaseDateRangeTo	output,
		@nCaseDateRangeOperator		= @nCaseDateRangeOperator output,
		@nCasePeriodFrom		= @nCasePeriodFrom	output,
		@nCasePeriodTo			= @nCasePeriodTo	output,
		@sCasePeriodType		= @sCasePeriodType	output,
		@nCasePeriodRangeOperator	= @nCasePeriodRangeOperator output,
		@bIsReciprocityDateFilter	= @bIsReciprocityDateFilter output,
		@dtValueDateRangeFrom		= @dtValueDateRangeFrom	output,
		@dtValueDateRangeTo		= @dtValueDateRangeTo	output,
		@nValueDateRangeOperator	= @nValueDateRangeOperator output,
		@nValuePeriodFrom		= @nValuePeriodFrom	output,
		@nValuePeriodTo			= @nValuePeriodTo	output,
		@sValuePeriodType		= @sValuePeriodType	output,
		@nValuePeriodRangeOperator	= @nValuePeriodRangeOperator output,
		@nNameKey			= @nNameKey output

		exec sp_xml_removedocument @idoc

		set @nStartNameFilter = charindex('<naw_ListName>', @ptXMLFilterCriteria, 0)
		set @nEndNameFilter = charindex('</naw_ListName>', @ptXMLFilterCriteria, 0) + 15
		
		Set @sNameFilter = substring(@ptXMLFilterCriteria, @nStartNameFilter, @nEndNameFilter  - @nStartNameFilter)
	
		EXEC dbo.naw_ConstructNameWhere 
			@psReturnClause			= @sNameFilterWhere output,
			@pnUserIdentityId		= @pnUserIdentityId,			
			@psCulture			= @psCulture,
			@pbIsExternalUser		= 0,
			@ptXMLFilterCriteria 		= @sNameFilter,
			@pnFilterGroupIndex		= 1,
			@pbCalledFromCentura		= 0

End

-- Get applicable Reciprocity site controls
If @nErrorCode = 0
Begin
	-- Get the Reciprocity Event and the
	-- list of disbursement codes to be 
	-- considered for the reciprocity
	Set @sSQLString = "
	Select @nReciprocityEvent = isnull(S1.COLINTEGER, -13) ,
	       @sDisbursementList = dbo.fn_WrapQuotes(S2.COLCHARACTER, 1, default)
	From SITECONTROL S1
	left join SITECONTROL S2 on (S2.CONTROLID='Reciprocity Disb')
	Where S1.CONTROLID = 'Reciprocity Event'"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				 N'@nReciprocityEvent	int		   output,
				   @sDisbursementList	nvarchar(max)	   output',
				   @nReciprocityEvent = @nReciprocityEvent output,
				@sDisbursementList = @sDisbursementList output
End

-- Get applicable Cases into a temp table
If @nErrorCode = 0
Begin	
	CREATE TABLE #CASESTOINCLUDE
	(CASEID INT,
	IRN	NVARCHAR(30) collate database_default,
	ISIN	BIT,
	ISOUT	BIT,
	VALUEIN	DECIMAL(12,2),
	VALUEOUT DECIMAL(12,2),
	DATEFILTER BIT
	)

	set @sCaseFrom = "From CASENAME CN
			join CASES C	on (C.CASEID = CN.CASEID)
			join CASETYPE  CTX 	on (CTX.CASETYPE = C.CASETYPE and CTX.ACTUALCASETYPE is null)"
	
	set @sCaseWhere = "Where CN.NAMETYPE in ('A',@sIncomingNameType)
				and CN.NAMENO in (Select DISTINCT N.NAMENO
						From NAME N
						Where (N.DATECEASED is null or N.DATECEASED > GETDATE()))"

	-- build the filter
	if (@sFilesIn is not NULL
		or @nFilesInOperator between 2 and 6)
	Begin
		set @sCaseFrom = @sCaseFrom + char(10) + "join FILESIN FI ON (FI.NAMENO = CN.NAMENO)"
		set @sCaseWhere = @sCaseWhere + char(10) + "and FI.COUNTRYCODE " + dbo.fn_ConstructOperator(@nFilesInOperator,@String,@sFilesIn, null, 0)
	End
	else if (@bIsRestrictNamesToAgents=1)
	Begin
		-- If Files In is specified (above), agents will be automatically filtered
		set @sCaseWhere = @sCaseWhere + char(10) + "and CN.NAMENO in (SELECT DISTINCT NAMENO FROM FILESIN)"
	End

	if (@sCaseTypeKey is not null
		or @nCaseTypeOperator between 2 and 6)
	Begin
		set @sCaseWhere = @sCaseWhere + char(10) + "and CTX.CASETYPE " + dbo.fn_ConstructOperator(@nCaseTypeOperator,@String,@sCaseTypeKey, null, 0)
	End

	if (@sPropertyTypeKey is not null
		or @nPropertyTypeOperator between 2 and 6)
	Begin
		set @sCaseWhere = @sCaseWhere + char(10) + "and C.PROPERTYTYPE " + dbo.fn_ConstructOperator(@nPropertyTypeOperator,@String,@sPropertyTypeKey, null, 0)
	End

	if (@sCaseCategoryKey is not null
		or @nCaseCategoryOperator between 2 and 6)
	Begin
		set @sCaseWhere = @sCaseWhere + char(10) + "and C.CASECATEGORY " + dbo.fn_ConstructOperator(@nCaseCategoryOperator,@String,@sCaseCategoryKey, null, 0)
	End

	if (@nStaffKey is not null
		or @nStaffOperator between 2 and 6)
	Begin
		set @sCaseFrom = @sCaseFrom + char(10) + "left join CASENAME CN_EMP ON (CN_EMP.CASEID = C.CASEID
												AND CN_EMP.NAMETYPE = 'EMP')"
		set @sCaseWhere = @sCaseWhere + char(10) + "and CN_EMP.NAMENO " + dbo.fn_ConstructOperator(@nStaffOperator,@Numeric,@nStaffKey, null, 0)
	End

	if (@nSignatoryKey is not null
		or @nSigntaoryOperator between 2 and 6)
	Begin
		set @sCaseFrom = @sCaseFrom + char(10) + "left join CASENAME CN_SIG ON (CN_SIG.CASEID = C.CASEID
												AND CN_SIG.NAMETYPE = 'SIG')"
		set @sCaseWhere = @sCaseWhere + char(10) + "and CN_SIG.NAMENO " + dbo.fn_ConstructOperator(@nSigntaoryOperator,@Numeric,@nSignatoryKey, null, 0)
	End

	if (@nAgentActedForKey is not null
		or @nAgentActedForOperator between 2 and 6)
	Begin
		set @sCaseFrom = @sCaseFrom + char(10) + "left join CASENAME CN_I ON (CN_I.CASEID = C.CASEID
												AND CN_I.NAMETYPE = 'I')"
		set @sCaseWhere = @sCaseWhere + char(10) + "and CN_I.NAMENO " + dbo.fn_ConstructOperator(@nAgentActedForOperator,@Numeric,@nAgentActedForKey, null, 0)
	End

	if (@nStaffSigGroupKey is not null
		or @nStaffSigGroupOperator between 2 and 6)
	Begin
		If @sCaseFrom not like '%left join CASENAME CN_EMP%'
			set @sCaseFrom = @sCaseFrom + char(10) + "left join CASENAME CN_EMP ON (CN_EMP.CASEID = C.CASEID AND CN_EMP.NAMETYPE = 'EMP')"

		If @sCaseFrom not like '%left join CASENAME CN_SIG%'
			set @sCaseFrom = @sCaseFrom + char(10) + "left join CASENAME CN_SIG ON (CN_SIG.CASEID = C.CASEID AND CN_SIG.NAMETYPE = 'SIG')"

		set @sCaseFrom = @sCaseFrom + char(10) + "left join NAME NGROUP ON ((CN_EMP.NAMENO = NGROUP.NAMENO
											OR CN_SIG.NAMENO = NGROUP.NAMENO))"
		set @sCaseWhere = @sCaseWhere + char(10) + "and NGROUP.FAMILYNO " + dbo.fn_ConstructOperator(@nStaffSigGroupOperator,@Numeric,@nStaffSigGroupKey, null, 0)
	End


	-- A period range is converted to a date range by adding the from/to period to the 
	-- current date.  Returns the due dates within the resulting date range.

	Set @bReverseDates = 0

	-- Case date/period filter
	If   @sCasePeriodType is not null
		and (@nCasePeriodFrom is not null or @nCasePeriodTo is not null)
	Begin
		If @nCasePeriodFrom is not null
		Begin
			Set @sSQLString = "Set @dtCaseDateRangeFrom = dateadd("+@sCasePeriodType+", -@nCasePeriodFrom, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtCaseDateRangeFrom	datetime 		output,
					  @nCasePeriodFrom	smallint',
	  				  @dtCaseDateRangeFrom	= @dtCaseDateRangeFrom 	output,
					  @nCasePeriodFrom	= @nCasePeriodFrom				  
		End
	
		If @nCasePeriodTo is not null
		Begin
			Set @sSQLString = "Set @dtCaseDateRangeTo = dateadd("+@sCasePeriodType+", -@nCasePeriodTo, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtCaseDateRangeTo	datetime 		output,
					  @nCasePeriodTo	smallint',
	  				  @dtCaseDateRangeTo	= @dtCaseDateRangeTo 	output,
					  @nCasePeriodTo	= @nCasePeriodTo				
		End

		Set @bReverseDates = 1
	End

	if (@bIsReciprocityDateFilter=1)
	Begin
		Set @sCaseFrom = @sCaseFrom + char(10) + "left join CASEEVENT CE on (CE.CASEID = C.CASEID
											AND CE.EVENTNO = @nReciprocityEvent )"
		---- filter cases where reciprocity event occurred
		--Set @sCaseWhere = @sCaseWhere + char(10) + "and CE.EVENTDATE IS NOT NULL"
	End
	Else
	Begin
		-- If Date of Entry, don't filter if event hasn't occurred
		Set @sCaseFrom = @sCaseFrom + char(10) + "left join CASEEVENT CE on (CE.CASEID = C.CASEID
												AND CE.EVENTNO = -13)"
	End

	If (@dtCaseDateRangeFrom is not null or @dtCaseDateRangeTo is not null)
	Begin
		declare @dateRange nvarchar(256)
		
		if (@bReverseDates=1)
		Begin
			Set @dateRange = "CE.EVENTDATE "+dbo.fn_ConstructOperator(ISNULL(@nCaseDateRangeOperator, @nCasePeriodRangeOperator),@Date,convert(nvarchar,@dtCaseDateRangeTo,112), convert(nvarchar,@dtCaseDateRangeFrom,112),0)
		End
		Else
		Begin
			Set @dateRange = "CE.EVENTDATE "+dbo.fn_ConstructOperator(ISNULL(@nCaseDateRangeOperator, @nCasePeriodRangeOperator),@Date,convert(nvarchar,@dtCaseDateRangeFrom,112), convert(nvarchar,@dtCaseDateRangeTo,112),0)
		End
	End

	If @nNameKey is not null
	Begin
		Set @sCaseWhere = @sCaseWhere+char(10)+"and CN.NAMENO = @nNameKey"
	End

	If @dateRange is not null
	Begin
		set @sCaseSelect = "INSERT INTO #CASESTOINCLUDE (CASEID, DATEFILTER)
				Select DISTINCT C.CASEID,
				CASE WHEN " + @dateRange + " THEN 1 ELSE 0 END"
	End
	Else Begin
		set @sCaseSelect = "INSERT INTO #CASESTOINCLUDE (CASEID, DATEFILTER)
				Select DISTINCT C.CASEID,1"
	End

	If (@nErrorCode = 0)
	Begin
		-- create a temp table to pre-filter the case data and simplify the aggregation of case counts and case values
		if (@bPrintSQL=1)
		Begin
			print char(10)+char(10)+ @sCaseSelect +char(10)+ @sCaseFrom +char(10)+ @sCaseWhere
		End
	
		set @sSQLString = @sCaseSelect +char(10)+ @sCaseFrom +char(10)+ @sCaseWhere

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@nReciprocityEvent	int,
					@sIncomingNameType	nvarchar(3),
					@nNameKey		int',
					@nReciprocityEvent = @nReciprocityEvent,
					@sIncomingNameType = @sIncomingNameType,
					@nNameKey = @nNameKey

		CREATE INDEX X1CASESTOINCLUDE ON #CASESTOINCLUDE (CASEID)
	End
End

-- flags to indicate certain updates on temp tables have been executed
declare @bLastInOutExecuted bit
declare @bValueInOutExecuted bit
declare @bIsInOutFlagExecuted bit

set @bLastInOutExecuted = 0
set @bValueInOutExecuted = 0
set @bIsInOutFlagExecuted = 0

If (@nNameKey is null)
Begin
	-- Populate the Reciprocity temp table to return name results
	If (@nErrorCode = 0)
	Begin
		-- now filter the names
		CREATE TABLE #RECIPROCITY
			(NAMENO	INT,
			CASESIN INT NULL,
			CASESOUT INT NULL,
			VALUEIN DECIMAL(12,2) NULL,
			VALUEOUT DECIMAL(12,2) NULL,
			LASTIN DATETIME NULL,
			LASTOUT DATETIME NULL,
			MARKETINGACTIVITY INT NULL)

		set @sNameSelect = "INSERT INTO #RECIPROCITY (NAMENO)
				select distinct N.NAMENO"

		set @sNameFrom = "from NAME N"+CHAR(10)
		set @sNameWhere = "WHERE 1=1"+CHAR(10)

		-- FilesIn/Restrict to Agent names filtering
		if (@sFilesIn is not NULL
			or @nFilesInOperator between 2 and 6)
		Begin
			set @sNameFrom = @sNameFrom +char(10)+ "join FILESIN FI ON (FI.NAMENO = N.NAMENO)"
			set @sNameWhere = @sNameWhere +char(10)+ "and FI.COUNTRYCODE " + dbo.fn_ConstructOperator(@nFilesInOperator,@String,@sFilesIn, null, 0)
		End
		else if (@bIsRestrictNamesToAgents=1)
		Begin
			-- If Files In is specified (above), agents will be automatically filtered
			set @sNameWhere = @sNameWhere+char(10)+"and N.NAMENO in (SELECT DISTINCT NAMENO FROM FILESIN)"
		End

		set @sNameWhere = @sNameWhere+char(10)+"and N.NAMENO in (SELECT XN.NAMENO"+char(10)+ @sNameFilterWhere + ")"

                If @sIncomingNameType = 'I'
                Begin
                        set @sNameFrom =@sNameFrom +char(10)+ "JOIN CASENAME CN ON (CN.NAMENO = N.NAMENO AND CN.NAMETYPE in ('A',@sIncomingNameType))" 
                        +CHAR(10)+ "JOIN #CASESTOINCLUDE C ON (C.CASEID = CN.CASEID)"+CHAR(10)
                End

		If (@bPrintSQL=1)
		Begin
			PRINT '@sIncomingNameType is ' + @sIncomingNameType
			print char(10)+char(10)+ @sNameSelect +char(10)+ @sNameFrom +char(10)+ @sNameWhere
		End

		set @sSQLString = @sNameSelect +char(10)+ @sNameFrom +char(10)+ @sNameWhere

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@sIncomingNameType	nvarchar(3)',
					@sIncomingNameType = @sIncomingNameType

		CREATE INDEX X1RECIPROCITY ON #RECIPROCITY (NAMENO)
	End


	-- Get the incoming/outgoing figures
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "update #RECIPROCITY"+char(10)+
				"SET CASESIN = CASECOUNTS.incoming,"+char(10)+
				"CASESOUT = CASECOUNTS.outgoing"+char(10)+
				"FROM #RECIPROCITY"+char(10)+
				"JOIN (SELECT R.NAMENO,"+char(10)+
				"	SUM (CASE WHEN (CN.NAMETYPE = @sIncomingNameType) THEN 1 ELSE 0 END) as 'incoming',"+char(10)+
				"	SUM (CASE WHEN (CN.NAMETYPE = 'A') THEN 1 ELSE 0 END) as 'outgoing'"+char(10)+
				"	from #RECIPROCITY R"+char(10)+
				"	JOIN CASENAME CN ON (CN.NAMENO = R.NAMENO"+char(10)+
				"				AND CN.NAMETYPE IN (@sIncomingNameType, 'A'))"+char(10)+
				"	JOIN #CASESTOINCLUDE C ON (C.CASEID = CN.CASEID)"+char(10)+
				"	WHERE C.DATEFILTER = 1"+char(10)+
				"	group by R.NAMENO) as CASECOUNTS ON (CASECOUNTS.NAMENO = #RECIPROCITY.NAMENO)"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@sIncomingNameType	nvarchar(3)',
					@sIncomingNameType = @sIncomingNameType
	End
	
	-- Get the no.Of Marketing Activities figures
	If (@nErrorCode = 0)
	Begin
		Set @sSQLString = "update #RECIPROCITY"+char(10)+
				"SET MARKETINGACTIVITY = CASECOUNTS.marketingCount"+char(10)+
				"FROM #RECIPROCITY"+char(10)+
				"JOIN (SELECT R.NAMENO,"+char(10)+
				"	SUM (CASE WHEN (CN.NAMETYPE = '~CN') THEN 1 ELSE 0 END) as 'marketingCount'"+char(10)+
				"	from #RECIPROCITY R"+char(10)+
				"	JOIN CASENAME CN ON (CN.NAMENO = R.NAMENO"+char(10)+
				"				AND CN.NAMETYPE IN ('~CN'))"+char(10)+
		               	"	group by R.NAMENO) as CASECOUNTS ON (CASECOUNTS.NAMENO = #RECIPROCITY.NAMENO)"
		exec @nErrorCode = sp_executesql @sSQLString
	End


	set @sSelect = "Select "
	set @sFrom = "From #RECIPROCITY RECIP"+CHAR(10)+
			"join NAME N ON (N.NAMENO = RECIP.NAMENO)"
	set @sWhere = "Where 1=1"
	
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
			If @sColumn in ('DisplayName',
					     'NameCode',
					     'NameKey')
			Begin
				If @sColumn='DisplayName'	
				Begin
					Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, default)'
				End
				If @sColumn='NameCode'	
				Begin
					Set @sTableColumn='N.NAMECODE'
				End
				If @sColumn='NameKey'	
				Begin
					Set @sTableColumn='N.NAMENO'
				End
			End
	
			If @sColumn in ('FilesInCountryCodeAny',
					'FilesInCountryNameAny',
					'FilesInNotesAny')
			Begin
				if (charindex('FILESIN', @sFrom) = 0)
				Begin
					Set @sFrom = @sFrom + char(10) + "left join FILESIN FIN on (FIN.NAMENO = N.NAMENO)"+char(10)+
									"left join COUNTRY CTRY on (CTRY.COUNTRYCODE = FIN.COUNTRYCODE)"
				End
			
				If @sColumn='FilesInCountryCodeAny'
				Begin
					Set @sTableColumn='FIN.COUNTRYCODE'
				End
				If @sColumn='FilesInCountryNameAny'
				Begin
					Set @sTableColumn='CTRY.COUNTRY'
				End
				If @sColumn='FilesInNotesAny'
				Begin
					Set @sTableColumn='FIN.NOTES'
				End
			End
	
			If @sColumn='MainContactMailingName'
			Begin
				Set @sTableColumn="dbo.fn_FormatNameUsingNameNo(N1.NAMENO, isnull(N1.NAMESTYLE,7101))"
				Set @sFrom = @sFrom + char(10) + "left join NAME N1 on (N1.NAMENO=N.MAINCONTACT)"
			End
			
			If @sColumn='MailingName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N.NAMENO, isnull(N.NAMESTYLE,7101))'
			End
	
			If @sColumn='MailingAddress'
			Begin
				Set @sTableColumn="dbo.fn_FormatAddress(PA.STREET1, PA.STREET2, PA.CITY, PA.STATE, ST.STATENAME, PA.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)"
				Set @sFrom = @sFrom + char(10) + "left join ADDRESS PA on (PA.ADDRESSCODE=N.POSTALADDRESS)"+char(10)+
							"left join COUNTRY CP on (CP.COUNTRYCODE=PA.COUNTRYCODE)"+char(10)+
							"left join STATE ST on (ST.COUNTRYCODE=PA.COUNTRYCODE and ST.STATE=PA.STATE)"
			End
	
			If @sColumn='IncomingCases'	
			Begin
				Set @sTableColumn='ISNULL(RECIP.CASESIN,0)'
			End
			If @sColumn='OutgoingCases'	
			Begin
				Set @sTableColumn='ISNULL(RECIP.CASESOUT,0)'
			End
			If @sColumn='MarketingActivities'	
			Begin
				Set @sTableColumn='ISNULL(RECIP.MARKETINGACTIVITY,0)'
			End
	
			-- If LastIncoming/Outgoing is requested:
			If @sColumn in ('LastIn', 'LastOut')
			Begin
				If (@nErrorCode = 0 and @bLastInOutExecuted = 0)
				Begin
					set @sNameWhere = ''
	
					-- filter the case events again			
					if (@bIsReciprocityDateFilter=1)
					Begin
						Set @sNameFrom = "left join CASEEVENT CE on (CE.CASEID = C.CASEID AND CE.EVENTNO = @nReciprocityEvent )"
						-- filter cases where reciprocity event occurred
						Set @sNameWhere = "and CE.EVENTDATE IS NOT NULL"
					End
					Else
					Begin
						-- If Date of Entry, don't filter if event hasn't occurred
						Set @sNameFrom = "left join CASEEVENT CE on (CE.CASEID = C.CASEID AND CE.EVENTNO = -13)"
					End
	
					-- build the update statement with the generated where/from
					Set @sNameSelect = "
						UPDATE #RECIPROCITY
						Set LASTIN = LASTINOUT.LastIncoming,
						LASTOUT = LASTINOUT.LastOutgoing
						FROM
							(select CN.NAMENO, 
								MAX (CASE WHEN (CN.NAMETYPE = @sIncomingNameType) THEN CE.EVENTDATE END) AS 'LastIncoming',
								MAX (CASE WHEN (CN.NAMETYPE = 'A') THEN CE.EVENTDATE END) AS 'LastOutgoing'
							from CASENAME CN
							JOIN #CASESTOINCLUDE C ON (C.CASEID = CN.CASEID)" +char(10)+
							@sNameFrom + char(10) +
							"where CN.NAMETYPE IN (@sIncomingNameType, 'A')" + char(10) +
							@sNameWhere + char(10) +
							"group by CN.NAMENO) AS LASTINOUT
						WHERE #RECIPROCITY.NAMENO = LASTINOUT.NAMENO"
	
					If (@bPrintSQL=1)
					Begin
						print char(10)+char(10)+ @sNameSelect
					End
	
					exec @nErrorCode = sp_executesql @sNameSelect,
								N'@sIncomingNameType	nvarchar(3),
								@nReciprocityEvent	int',
								@sIncomingNameType = @sIncomingNameType,
								@nReciprocityEvent = @nReciprocityEvent
	
					set @bLastInOutExecuted = 1
				End
	
				If @sColumn='LastIn'	
				Begin
					Set @sTableColumn='RECIP.LASTIN'
				End
		
				If @sColumn='LastOut'	
				Begin
					Set @sTableColumn='RECIP.LASTOUT'
				End
			End

			If @sColumn = 'LocalCurrencyCode'
			Begin
				If (charindex('Left Join SITECONTROL SCUR',@sFrom)=0)
				Begin
					Set @sFrom=@sFrom +char(10)+"Left Join SITECONTROL SCUR on (UPPER(SCUR.CONTROLID) = 'CURRENCY')"
				End
				Set @sTableColumn='SCUR.COLCHARACTER'			
			End

			If @sColumn in ('ValueIncoming', 'ValueOutgoing')
			Begin
	
				If (@nErrorCode = 0 and @bValueInOutExecuted = 0)
				Begin
					-- value date/period filter
					-- A period range is converted to a date range by subtracting the from/to period to the 
					-- current date.  Values within the resulting date range.

					Set @bReverseDates = 0

					If   @sValuePeriodType is not null
						and (@nValuePeriodFrom is not null or @nValuePeriodTo is not null)
					Begin
						If @nValuePeriodFrom is not null
						Begin
							Set @sSQLString = "Set @dtValueDateRangeFrom = dateadd("+@sValuePeriodType+", -@nValuePeriodFrom, '" + convert(nvarchar(25),getdate()) + "')"
				
							execute sp_executesql @sSQLString,
									N'@dtValueDateRangeFrom	datetime 		output,
									  @nValuePeriodFrom	smallint',
					  				  @dtValueDateRangeFrom	= @dtValueDateRangeFrom 	output,
									  @nValuePeriodFrom	= @nValuePeriodFrom				  
						End
					
						If @nValuePeriodTo is not null
						Begin
							Set @sSQLString = "Set @dtValueDateRangeTo = dateadd("+@sValuePeriodType+", -@nValuePeriodTo, '" + convert(nvarchar(25),getdate()) + "')"
				
							execute sp_executesql @sSQLString,
									N'@dtValueDateRangeTo	datetime 		output,
									  @nValuePeriodTo	smallint',
					  				  @dtValueDateRangeTo	= @dtValueDateRangeTo output,
									  @nValuePeriodTo	= @nValuePeriodTo				
						End

						Set @bReverseDates = 1
					End
				
					-- Set the default WIP filtering
					Set @sNameWhere = "and WH.STATUS <> 0" +char(10)+
								"and WH.MOVEMENTCLASS = Case when CN.NAMETYPE=@sIncomingNameType then 2 else 1 end"+char(10)+
								"and WT.CATEGORYCODE = Case when CN.NAMETYPE=@sIncomingNameType then 'SC' else 'PD' end"+char(10)
								If @sDisbursementList != ''								
									set @sNameWhere = @sNameWhere + "and (WT.WIPTYPEID in (" + @sDisbursementList + ") or WT.WIPTYPEID in (SELECT WIPTYPEID FROM WIPTYPE WHERE CATEGORYCODE = 'SC'))"
				
					If @dtValueDateRangeFrom is not null
					or @dtValueDateRangeTo is not null
					Begin
						if (@bReverseDates=1)
						Begin
							-- Subtracting the period amount means we have to reverse the to/from for the between filter.
							Set @sNameWhere = @sNameWhere +char(10)+ "and WH.TRANSDATE "+dbo.fn_ConstructOperator(ISNULL(@nValueDateRangeOperator, @nValuePeriodRangeOperator),@Date,convert(nvarchar,@dtValueDateRangeTo,112), convert(nvarchar,@dtValueDateRangeFrom,112),0)
						End
						Else
						Begin
							Set @sNameWhere = @sNameWhere +char(10)+ "and WH.TRANSDATE "+dbo.fn_ConstructOperator(ISNULL(@nValueDateRangeOperator, @nValuePeriodRangeOperator),@Date,convert(nvarchar,@dtValueDateRangeFrom,112), convert(nvarchar,@dtValueDateRangeTo,112),0)
						End
					End
	
					-- If ValueIncoming/Outgoing is requested:
					Set @sNameSelect = "UPDATE #RECIPROCITY
						Set VALUEIN = VALUEINOUT.ValueIncoming,
						VALUEOUT = VALUEINOUT.ValueOutgoing
						FROM
							(select CN.NAMENO, 
								SUM (CASE WHEN (CN.NAMETYPE = @sIncomingNameType) THEN (-1) * LOCALTRANSVALUE ELSE 0 END ) as 'ValueIncoming',
								SUM (CASE WHEN (CN.NAMETYPE = 'A') THEN LOCALCOST ELSE 0 END) as 'ValueOutgoing'
							from CASENAME CN
							JOIN #CASESTOINCLUDE C ON (C.CASEID = CN.CASEID)
							left join WORKHISTORY WH ON	(WH.CASEID = C.CASEID)
							left join WIPTEMPLATE WIPT ON	(WH.WIPCODE = WIPT.WIPCODE) 
							left join WIPTYPE WT ON	(WIPT.WIPTYPEID = WT.WIPTYPEID)
							where CN.NAMETYPE IN (@sIncomingNameType, 'A')" + char(10) +
							@sNameWhere + char(10)+
							"group by CN.NAMENO) AS VALUEINOUT
						WHERE #RECIPROCITY.NAMENO = VALUEINOUT.NAMENO"
	
					If (@bPrintSQL=1)
					Begin
						print char(10)+char(10)+ @sNameSelect
					End
	
					exec @nErrorCode = sp_executesql @sNameSelect,
								N'@sIncomingNameType	nvarchar(3)',
								@sIncomingNameType = @sIncomingNameType
	
					set @bValueInOutExecuted = 1
				End

				If @sColumn='ValueIncoming'	
				Begin
					Set @sTableColumn='Case when RECIP.VALUEIN = 0 then null else RECIP.VALUEIN end'
				End
				If @sColumn='ValueOutgoing'	
				Begin
					Set @sTableColumn='Case when RECIP.VALUEOUT = 0 then null else RECIP.VALUEOUT end'
				End
			End
	
            If @sColumn in ('LastContacted','ContactSummary')
		    Begin
			    If (charindex('Left Join ACTIVITY ACT',@sFrom)=0)
			    Begin
				    Set @sFrom=@sFrom +char(10)+"Left Join ACTIVITY ACT on (ACT.RELATEDNAME = N.NAMENO 
                        and ACT.ACTIVITYDATE = (Select max(AC.ACTIVITYDATE) from ACTIVITY AC where AC.RELATEDNAME = N.NAMENO))"
			    End

			    If @sColumn = 'LastContacted'
			    Begin
				    Set @sTableColumn='ACT.ACTIVITYDATE'
			    End
			    If @sColumn = 'ContactSummary'
			    Begin
				    Set @sTableColumn='ACT.SUMMARY'
				End
			End
	
			If (@sTableColumn is null or @sTableColumn = '')
			Begin
				Set @sTableColumn='1'
			End
	
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
	
			Set @sTableColumn = ''	
		End

		Set @nCount = @nCount + 1

	End -- While
End
Else -- @nNameKey is not null
Begin	
	set @sSelect = "Select "
	set @sFrom = "From #CASESTOINCLUDE CTI"+CHAR(10)+
			"join CASES C ON (C.CASEID = CTI.CASEID)"
	set @sWhere = "Where 1=1"
	
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

		If @sColumn in ('CaseReference',
				     'CaseKey')
		Begin
			If @sColumn='CaseReference'	
			Begin
				Set @sTableColumn='C.IRN'
			End
			If @sColumn='CaseKey'	
			Begin
				Set @sTableColumn='C.CASEID'
			End
		End

		If @sColumn in ('InFlag', 'OutFlag')
		Begin

			If (@bIsInOutFlagExecuted = 0)
			-- If IsIn/Out is requested:
			Set @sCaseSelect = "UPDATE C
				Set ISIN = case when CNIN.NAMENO is not null then 1 else 0 end,
				ISOUT = case when CNOUT.NAMENO is not null then 1 else 0 end
				from #CASESTOINCLUDE C
				left join CASENAME CNIN ON (C.CASEID = CNIN.CASEID
								and CNIN.NAMETYPE = @sIncomingNameType
								and CNIN.NAMENO = @nNameKey)
				left join CASENAME CNOUT ON (C.CASEID = CNOUT.CASEID
								and CNOUT.NAMETYPE = 'A'
								and CNOUT.NAMENO = @nNameKey)"

			If (@bPrintSQL=1)
			Begin
				print char(10)+char(10)+ @sCaseSelect
			End

			exec @nErrorCode = sp_executesql @sCaseSelect,
						N'@sIncomingNameType	nvarchar(3),
						@nNameKey	int',
						@sIncomingNameType = @sIncomingNameType,
						@nNameKey = @nNameKey

			set @bIsInOutFlagExecuted = 1			

			If (@sColumn = 'InFlag')
			Begin
				Set @sTableColumn = 'CTI.ISIN'
			End
			If (@sColumn = 'OutFlag')
			Begin
				Set @sTableColumn = 'CTI.ISOUT'
			End
		End

		If @sColumn = 'ShortTitle'
		Begin
			Set @sTableColumn = 'C.TITLE'
		End

		If @sColumn = 'CaseTypeDescription'
		Begin
			Set @sFrom = @sFrom+char(10)+"join CASETYPE CT ON (C.CASETYPE = CT.CASETYPE)"
			Set @sTableColumn = 'CT.CASETYPEDESC'
		End

		If @sColumn = 'PropertyTypeDescription'
		Begin
			Set @sFrom = @sFrom+char(10)+"join PROPERTYTYPE PT ON (PT.PROPERTYTYPE = C.PROPERTYTYPE)"
			Set @sTableColumn = 'PT.PROPERTYNAME'
		End

		If @sColumn = 'CountryName'
		Begin
			Set @sFrom = @sFrom+char(10)+"join COUNTRY CTRY ON (CTRY.COUNTRYCODE = C.COUNTRYCODE)"
			Set @sTableColumn = 'CTRY.COUNTRY'
		End

		If @sColumn = 'StatusDescription'
		Begin
			Set @sFrom = @sFrom+char(10)+"left join STATUS ST ON (ST.STATUSCODE = C.STATUSCODE)"
			Set @sTableColumn = 'ST.INTERNALDESC'
		End

		If @sColumn in ('StaffDisplayName', 'StaffNameKey')
		Begin
			if (charindex('CN_EMP', @sFrom) = 0)
			Begin
				Set @sFrom = @sFrom+char(10)+"left join CASENAME CN_EMP ON (CN_EMP.CASEID = C.CASEID AND CN_EMP.NAMETYPE = 'EMP')"+char(10)+
									"left join NAME N_EMP ON (N_EMP.NAMENO = CN_EMP.NAMENO)"
			End

			If @sColumn = 'StaffDisplayName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N_EMP.NAMENO, default)'
			End

			If @sColumn = 'StaffNameKey'
			Begin
				Set @sTableColumn='CN_EMP.NAMENO'
			End
		End


		If @sColumn in ('SigDisplayName', 'SigNameKey')
		Begin
			if (charindex('CN_SIG', @sFrom) = 0)
			Begin
				Set @sFrom = @sFrom+char(10)+"left join CASENAME CN_SIG ON (CN_SIG.CASEID = C.CASEID AND CN_SIG.NAMETYPE = 'SIG')"+char(10)+
									"left join NAME N_SIG ON (N_SIG.NAMENO = CN_SIG.NAMENO)"
			End

			If @sColumn = 'SigDisplayName'
			Begin
				Set @sTableColumn='dbo.fn_FormatNameUsingNameNo(N_SIG.NAMENO, default)'
			End

			If @sColumn = 'SigNameKey'
			Begin
				Set @sTableColumn='CN_SIG.NAMENO'
			End
		End

		If @sColumn = 'LocalCurrencyCode'
		Begin
			If (charindex('Left Join SITECONTROL SCUR',@sFrom)=0)
			Begin
				Set @sFrom=@sFrom +char(10)+"Left Join SITECONTROL SCUR on (UPPER(SCUR.CONTROLID) = 'CURRENCY')"
			End
			Set @sTableColumn='SCUR.COLCHARACTER'
		End

		If @sColumn in ('ValueIncoming', 'ValueOutgoing')
		Begin
			If (@nErrorCode = 0 and @bValueInOutExecuted = 0)
			Begin
				-- value date/period filter
				-- A period range is converted to a date range by adding the from/to period to the 
				-- current date.  Returns the due dates within the resulting date range.	
				If   @sValuePeriodType is not null
					and (@nValuePeriodFrom is not null or @nValuePeriodTo is not null)
				Begin
					If (@nValuePeriodFrom is not null)
					Begin
						Set @sSQLString = "Set @dtValueDateRangeFrom = dateadd("+@sValuePeriodType+", @nValuePeriodFrom, '" + convert(nvarchar(25),getdate()) + "')"
			
						execute sp_executesql @sSQLString,
								N'@dtValueDateRangeFrom	datetime 		output,
								  @nValuePeriodFrom	smallint',
				  				  @dtValueDateRangeFrom	= @dtValueDateRangeFrom 	output,
								  @nValuePeriodFrom	= @nValuePeriodFrom				  
					End
				
					If (@nValuePeriodTo is not null)
					Begin
						Set @sSQLString = "Set @dtValueDateRangeTo = dateadd("+@sValuePeriodType+", @nValuePeriodTo, '" + convert(nvarchar(25),getdate()) + "')"
			
						execute sp_executesql @sSQLString,
								N'@dtValueDateRangeTo	datetime 		output,
								  @nValuePeriodTo	smallint',
				  				  @dtValueDateRangeTo	= @dtValueDateRangeTo 	output,
								  @nValuePeriodTo	= @nValuePeriodTo				
					End
				End
			
				-- Set the default WIP filtering
				Set @sCaseWhere = "and WH.STATUS <> 0" +char(10)+
							"and WH.MOVEMENTCLASS = Case when CN.NAMETYPE=@sIncomingNameType then 2 else 1 end"+char(10)+
							"and WT.CATEGORYCODE = Case when CN.NAMETYPE=@sIncomingNameType then 'SC' else 'PD' end"+char(10)
							If @sDisbursementList != ''								
								set @sCaseWhere = @sCaseWhere + "and (WT.WIPTYPEID in (" + @sDisbursementList + ") or WT.WIPTYPEID in (SELECT WIPTYPEID FROM WIPTYPE WHERE CATEGORYCODE = 'SC'))"
			
				If @dtValueDateRangeFrom is not null
				or @dtValueDateRangeTo is not null
				Begin
					Set @sCaseWhere = @sCaseWhere +char(10)+ "and WH.TRANSDATE "+dbo.fn_ConstructOperator(ISNULL(@nValueDateRangeOperator, @nValuePeriodRangeOperator),@Date,convert(nvarchar,@dtValueDateRangeFrom,112), convert(nvarchar,@dtValueDateRangeTo,112),0)
				End
	
				-- If ValueIncoming/Outgoing is requested:
				Set @sCaseSelect = "UPDATE #CASESTOINCLUDE
					Set VALUEIN = VALUEINOUT.ValueIncoming,
					VALUEOUT = VALUEINOUT.ValueOutgoing
					FROM
						(select C.CASEID, 
							SUM (CASE WHEN (CN.NAMETYPE = @sIncomingNameType) THEN (-1) * LOCALTRANSVALUE ELSE 0 END ) as 'ValueIncoming',
							SUM (CASE WHEN (CN.NAMETYPE = 'A') THEN LOCALCOST ELSE 0 END) as 'ValueOutgoing'
						from CASENAME CN
						JOIN #CASESTOINCLUDE C ON (C.CASEID = CN.CASEID)
						left join WORKHISTORY WH ON	(WH.CASEID = C.CASEID)
						left join WIPTEMPLATE WIPT ON	(WH.WIPCODE = WIPT.WIPCODE) 
						left join WIPTYPE WT ON	(WIPT.WIPTYPEID = WT.WIPTYPEID)
						where CN.NAMETYPE IN (@sIncomingNameType, 'A')
						and CN.NAMENO = @nNameKey" + char(10) +
						@sCaseWhere + char(10)+
						"group by C.CASEID) AS VALUEINOUT
					WHERE #CASESTOINCLUDE.CASEID = VALUEINOUT.CASEID"
	
				If (@bPrintSQL=1)
				Begin
					print char(10)+char(10)+ @sCaseSelect
				End
	
				exec @nErrorCode = sp_executesql @sCaseSelect,
							N'@sIncomingNameType	nvarchar(3),
							@nNameKey		int',
							@sIncomingNameType 	= @sIncomingNameType,
							@nNameKey 		= @nNameKey
	
				set @bValueInOutExecuted = 1
			End
	
			If @sColumn='ValueIncoming'	
			Begin
				Set @sTableColumn='Case when CTI.VALUEIN = 0 then null else CTI.VALUEIN end'
			End
			If @sColumn='ValueOutgoing'	
			Begin
				Set @sTableColumn='Case when CTI.VALUEOUT = 0 then null else CTI.VALUEOUT end'
			End
		End

		If @sColumn in ('RecipOppComments','RecipOppNextStep')
		Begin
			If (charindex('Left Join OPPORTUNITY OPP',@sFrom)=0)
			Begin
				Set @sFrom=@sFrom +char(10)+"Left Join OPPORTUNITY OPP on (OPP.CASEID = CTI.CASEID)"
			End

			If @sColumn = 'RecipOppComments'
			Begin
				Set @sTableColumn='OPP.REMARKS'
			End
			If @sColumn = 'RecipOppNextStep'
			Begin
				Set @sTableColumn='OPP.NEXTSTEP'
			End
		End

		If (@sTableColumn is null or @sTableColumn = '')
		Begin
			Set @sTableColumn='1'
		End

		If datalength(@sPublishName)>0
		Begin
			Set @sSelect=@sSelect+@sComma+@sTableColumn+' as ['+@sPublishName+']'
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

		Set @sTableColumn = ''

		Set @nCount = @nCount + 1

	End -- While

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

If (@bPrintSQL=1)
Begin
	print char(10)+char(10)+ @sSelect + @sFrom + @sWhere + @sOrder
End


-- Return the results
-- No paging required
If (@pnPageStartRow is null or @pnPageEndRow is null)
Begin

	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere + char(10) + @sOrder	

	exec @nErrorCode = sp_executesql @sSQLString
	Set @pnRowCount = @@RowCount
End
-- Paging required
Else Begin

	Set @sSelect = replace(@sSelect,'Select', 'Select TOP '+cast(@pnPageEndRow as nvarchar(20))+' ')

	-- Execute the SQL
	Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere + char(10) + @sOrder

	exec @nErrorCode = sp_executesql @sSQLString
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

		Set @sSQLString = @sSelect + char(10) + @sFrom + char(10) + @sWhere

		exec @nErrorCode = sp_executesql @sSQLString

		Set @nErrorCode =@@ERROR
	End
End


if exists(select 1 from tempdb.dbo.sysobjects where name like '#CASESTOINCLUDE%')
Begin
	drop table #CASESTOINCLUDE
End


if exists(select 1 from tempdb.dbo.sysobjects where name like '#RECIPROCITY%')
Begin
	drop table #RECIPROCITY
End

RETURN @nErrorCode
GO

Grant execute on dbo.naw_ListReciprocity  to public
GO



