-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pr_ConstructPriorArtWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[pr_ConstructPriorArtWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	print '**** Drop procedure dbo.pr_ConstructPriorArtWhere.'
	drop procedure dbo.pr_ConstructPriorArtWhere
End
print '**** Creating procedure dbo.pr_ConstructPriorArtWhere...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.pr_ConstructPriorArtWhere
(
	@psPriorArtWhere			nvarchar(max)	= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbExternalUser			bit,			-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@pnQueryContextKey		int		= null, -- The key for the context of the query (default output requests).
	@ptXMLFilterCriteria		ntext		= null,	-- Contains filtering to be applied to the selected columns
	@pbCalledFromCentura		bit		= 0	-- Indicates that Centura called the stored procedure
)	
AS
-- PROCEDURE :	pr_ConstructPriorArtWhere
-- VERSION :	10
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Work In Progress 
--		and constructs a Where clause.  
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 2 Feb 2011	KR	RFC6563	1	Procedure created.
-- 10 Mar 2011	KR	RFC6563	2	Fixed issues in the FAMILY where clause
-- 28 Mar 2011	KR	RFC6563 3	Fixed issue with Source Key in the where clause
-- 05 Jul 2013	vql	R13629	4	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 03 Feb 2015	MF	R44500	5	Correction to filtering on Case Reference and Family.
-- 12 Feb 2015	MF	R44500	6	Further work to handle Case Exists and Family Not Exists
-- 06 Jul 2018	MF	74486	7	When searching by characteristics held with the Source Document, also return any cited prior art that is
--					linked to the Source Document found.
-- 31 Oct 2018	DL	DR-45102	8	Replace control character (word hyphen) with normal sql editor hyphen
-- 14 Nov 2018  AV  75198/DR-45358	9   Date conversion errors when creating cases and opening names in Chinese DB
-- 13 May 2020	DL	DR-58943	10	Ability to enter up to 3 characters for Number type code via client server	

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int
Declare @sAlertXML	 			nvarchar(400)

Declare @sSQLString				nvarchar(max)

Declare @sFrom					nvarchar(max)
Declare @sAcctClientNoWhere		nvarchar(4000)	-- The part of the 'Where' clause used for the WIP recorded against the Name.
Declare @sCaseWhere				nvarchar(4000)	-- The part of the 'Where' clause used for the WIP recorded against the Case.
Declare @sOfficeWhere			nvarchar(4000)	-- The part of the 'Where' clause used for the WIP recorded against the Office.
Declare @sWhere					nvarchar(max)	-- General filter criteria.

-- Filter Criteria

Declare @sStoredProcedure			nvarchar(max)

Declare @sCitation					nvarchar(254)
Declare @nCitationOperator			tinyint
Declare @sOfficialNumber			nvarchar(36)
Declare @nOfficialNumberOperator	tinyint
Declare	@sNumberTypeKey				nvarchar(3)	-- By default, the search is conducted on the OfficialNumbers for the case.  The TypeKey may optionally be used to filter the results to a specific Number Type.
Declare	@bUseRelatedCase			bit 		-- When turned on, the search is conducted on any official numbers stored as related Cases.  Any NumberType values are ignored.
Declare	@bUseNumericSearch 			bit		-- When turned on, any non-numeric characters are removed from Number and this is compared to the numeric characters in the official numbers on the database.			
Declare @bUseCurrent				bit		-- When turned on, the search is conducted on the current official number for the case.  Any NumberType values are ignored.Either UseCurrent or UseRelatedCase may be turned on, but not both.

Declare	@sCountryCodes				nvarchar(1000)	-- A comma separated list of Country Codes.
Declare	@nCountryCodesOperator		tinyint	
Declare	@bIncludeDesignations		bit	

Declare @sKindCode					nvarchar(254)
Declare @nKindCodeOperator			tinyint

Declare @sTitle						nvarchar(254)
Declare @nTitleOperator				tinyint

Declare	@sName						nvarchar(254)
Declare @nNameOperator				tinyint

Declare @nSourceDocumentKey				int
Declare @nSourceDocumentKeyOperator		tinyint

declare @sDescription				nvarchar(254)
declare	@nDescriptionOperator		tinyint

declare @sPublication				nvarchar(254)
declare	@nPublicationOperator		tinyint

Declare	@sIssuingCountryCodes		nvarchar(1000)	-- A comma separated list of Country Codes.
Declare	@nIssuingCountryCodesOperator tinyint	
Declare	@bIssuingIncludeDesignations bit	

declare @sClasses					nvarchar(254)
declare	@nClassesOperator			tinyint

declare @sSubClasses				nvarchar(254)
declare	@nSubClassesOperator		tinyint

declare @bIPDocument				bit
declare	@bNonIPDocument				bit

Declare	@nCaseKey 			int
Declare @sCaseReference		nvarchar(60)
Declare	@nCaseReferenceOperator		tinyint

Declare	@sFamilyKey	 				nvarchar(20)	
Declare	@nFamilyKeyOperator			tinyint	

Declare @nReportIssuedDateRangeOperator		tinyint
Declare @dtReportIssuedDateRangeFrom		datetime	-- Return WIP with item dates between these dates. From and/or To value must be provided.
Declare @dtReportIssuedDateRangeTo			datetime
Declare @nReportIssuedPeriodRangeOperator	tinyint		-- A period range is converted to a date range by subtracting the from/to period from the current date. Returns the WIP with dates in the past over the resulting date range.
Declare @sReportIssuedPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @nReportIssuedPeriodRangeFrom		smallint	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @nReportIssuedPeriodRangeTo			smallint

Declare @nReportReceivedDateRangeOperator	tinyint
Declare @dtReportReceivedDateRangeFrom		datetime	-- Return WIP with item dates between these dates. From and/or To value must be provided.
Declare @dtReportReceivedDateRangeTo		datetime
Declare @nReportReceivedPeriodRangeOperator	tinyint		-- A period range is converted to a date range by subtracting the from/to period from the current date. Returns the WIP with dates in the past over the resulting date range.
Declare @sReportReceivedPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @nReportReceivedPeriodRangeFrom		smallint	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @nReportReceivedPeriodRangeTo		smallint


Declare @nPublishedDateRangeOperator	tinyint
Declare @sPublishedPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @dtPublishedDateRangeFrom		datetime	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @dtPublishedDateRangeTo		datetime

Declare @nPriorityDateRangeOperator		tinyint
Declare @sPriorityPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @dtPriorityDateRangeFrom		datetime	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @dtPriorityDateRangeTo		datetime

Declare @nGrantedDateRangeOperator	tinyint
Declare @sGrantedPeriodRangeType		nvarchar(2)	-- Type: D-Days, W-Weeks, M-Months, Y-Years 
Declare @dtGrantedDateRangeFrom		datetime	-- Must be zero or above. Always supplied in conjunction with Type.		
Declare @dtGrantedDateRangeTo			datetime

Declare	@bExternalUser			bit

Declare @idoc 				int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String				nchar(1)
Declare @Date				nchar(2)
Declare @Numeric			nchar(1)
Declare @Text				nchar(1)
Declare @CommaString			nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr				nvarchar(10)

Declare @sComma				nvarchar(1)

Set	@String 			= 'S'
Set	@Date   			= 'DT'
Set	@Numeric			= 'N'
Set	@Text   			= 'T'
Set	@CommaString			= 'CS'

Set 	@nErrorCode			= 0
					
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE CLAUSE   ****/
/****                                       ****/
/***********************************************/

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML

exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria


if exists(Select 1 from OPENXML (@idoc, '//pr_ListPriorArt', 2))
Begin
	Set @sStoredProcedure = 'pr_ListPriorArt'
End

If @nErrorCode = 0 
Begin
	Set @sWhere = '1 = 1'

-- Retrieve the Filter elements using element-centric mapping
	Set @sSQLString = "Select @sCitation		= Citation,  	
	 @nCitationOperator	= CitationOperator,  
	 @sOfficialNumber	= OfficialNumber,  
	 @nOfficialNumberOperator= OfficialNumberOperator,  
	 @sCountryCodes			= CountryCodes,  
	 @nCountryCodesOperator		= CountryCodesOperator,  
	 @sKindCode					= KindCode,  
	 @nKindCodeOperator			= KindCodeOperator,  
	 @sTitle					= Title,  
	 @nTitleOperator				= TitleOperator,  
	 @sName						= Name,  
	 @nNameOperator				= NameOperator,  
	 @nSourceDocumentKey			= SourceDocumentKey,  
	 @nSourceDocumentKeyOperator	= SourceDocumentKeyOperator,  
	 @sDescription				= Description,  
	 @nDescriptionOperator		= DescriptionOperator,  
	 @sPublication				= Publication,  
	 @nPublicationOperator		= PublicationOperator,  
	 @sIssuingCountryCodes			= IssuingCountryCodes,  
	 @nIssuingCountryCodesOperator	= IssuingCountryCodesOperator,  
	 @sClasses				= Classes,  
	 @nClassesOperator		= ClassesOperator,  
	 @sSubClasses				= SubClasses,  
	 @nSubClassesOperator		= SubClassesOperator,  	
	 @bIPDocument				= IPDocument,  
	 @bNonIPDocument			= NonIPDocument,  
	 @sCaseReference		= CaseReference,
	 @nCaseReferenceOperator		= CaseReferenceOperator,  
	 @sFamilyKey			= upper(FamilyKey),  
	 @nFamilyKeyOperator		= FamilyKeyOperator,  
	 @nReportIssuedDateRangeOperator	= ReportIssuedDateRangeOperator,  	
	 @dtReportIssuedDateRangeFrom	= ReportIssuedDateRangeFrom,  
	 @dtReportIssuedDateRangeTo		= ReportIssuedDateRangeTo,  
	 @nReportIssuedPeriodRangeOperator	= ReportIssuedPeriodRangeOperator,  
	 @sReportIssuedPeriodRangeType	= CASE WHEN ReportIssuedPeriodRangeType = 'D' THEN 'dd'  
	 			       WHEN ReportIssuedPeriodRangeType = 'W' THEN 'wk'  
	 			       WHEN ReportIssuedPeriodRangeType = 'M' THEN 'mm'  
	 			       WHEN ReportIssuedPeriodRangeType = 'Y' THEN 'yy'  
	 			  END,
	@nReportIssuedPeriodRangeFrom	= ReportIssuedPeriodRangeFrom,  
	 @nReportIssuedPeriodRangeTo		= ReportIssuedPeriodRangeTo,
	 @nReportReceivedDateRangeOperator	= ReportReceivedDateRangeOperator,  	
	 @dtReportReceivedDateRangeFrom	= ReportReceivedDateRangeFrom,  
	 @dtReportReceivedDateRangeTo		= ReportReceivedDateRangeTo,  
	 @nReportReceivedPeriodRangeOperator	= ReportReceivedPeriodRangeOperator,  
	 @sReportReceivedPeriodRangeType	= CASE WHEN ReportReceivedPeriodRangeType = 'D' THEN 'dd'  
	 			       WHEN ReportReceivedPeriodRangeType = 'W' THEN 'wk'  
	 			       WHEN ReportReceivedPeriodRangeType = 'M' THEN 'mm'  
	 			       WHEN ReportReceivedPeriodRangeType = 'Y' THEN 'yy'  
	 			  END,  
	 @nReportReceivedPeriodRangeFrom	= ReportReceivedPeriodRangeFrom,  
	 @nReportReceivedPeriodRangeTo		= ReportReceivedPeriodRangeTo,
	 @nPublishedDateRangeOperator	= PublishedDateRangeOperator,  	
	 @dtPublishedDateRangeFrom	= PublishedDateRangeFrom,  
	 @dtPublishedDateRangeTo		= PublishedDateRangeTo,  

	 @nPriorityDateRangeOperator	= PriorityDateRangeOperator,  	
	 @dtPriorityDateRangeFrom	= PriorityDateRangeFrom,  
	 @dtPriorityDateRangeTo		= PriorityDateRangeTo,  	
	
	 @nGrantedDateRangeOperator	= GrantedDateRangeOperator,  	
	 @dtGrantedDateRangeFrom		= GrantedDateRangeFrom,  
	 @dtGrantedDateRangeTo	= GrantedDateRangeTo
	from	OPENXML (@idoc, '/" + @sStoredProcedure + "/FilterCriteria',2)  
	WITH (  
	Citation			nvarchar(254)	'Citation/text()', 
	CitationOperator		tinyint		'Citation/@Operator/text()', 
	OfficialNumber		nvarchar(36)	'OfficialNumber/text()',  	
	OfficialNumberOperator	tinyint		'OfficialNumber/@Operator/text()',  	
	CountryCodes		nvarchar(1000)	'CountryCodes/text()',  
	CountryCodesOperator	tinyint		'CountryCodes/@Operator/text()',  	
	KindCode			nvarchar(254)	'KindCode/text()',  
	KindCodeOperator		tinyint		'KindCode/@Operator/text()',  
	Title			nvarchar(254)	'Title/text()',  
	TitleOperator		tinyint		'Title/@Operator/text()',  
	Name			nvarchar(254)	'Name/text()',  
	NameOperator		tinyint		'Name/@Operator/text()',  
	SourceDocumentKey	int			'SourceKey/text()',  
	SourceDocumentKeyOperator		tinyint		'SourceKey/@Operator/text()',  
	Description			nvarchar(254)	'Description/text()',  
	DescriptionOperator		tinyint		'Description/@Operator/text()',  
	Publication			nvarchar(254)	'Publication/text()',  
	PublicationOperator		tinyint		'Publication/@Operator/text()',  
	IssuingCountryCodes		nvarchar(1000)	'IssuingCountryCodes/text()',  
	IssuingCountryCodesOperator	tinyint		'IssuingCountryCodes/@Operator/text()',  
	Classes			nvarchar(254)	'Classes/text()',  
	ClassesOperator		tinyint		'Classes/@Operator/text()',  	
	SubClasses			nvarchar(254)	'SubClasses/text()',  
	SubClassesOperator		tinyint		'SubClasses/@Operator/text()' , 
	IPDocument			bit				'IPDocument/text()',  
	NonIPDocument		bit				'NonIPDocument/text()',  
	CaseReference		nvarchar(60)		'Associatedwith/Case/text()',  	
	CaseReferenceOperator	tinyint		'Associatedwith/Case/@Operator/text()',  		
	FamilyKey			nvarchar(20)	'Associatedwith/Family/text()',  
	FamilyKeyOperator		tinyint		'Associatedwith/Family/@Operator/text()',  	
	ReportIssuedDateRangeOperator		tinyint	'Dates/ReportIssued/DateRange/@Operator/text()',  
	ReportIssuedDateRangeFrom		datetime	'Dates/ReportIssued/DateRange/From/text()',  
	ReportIssuedDateRangeTo		datetime	'Dates/ReportIssued/DateRange/To/text()',  
	ReportIssuedPeriodRangeOperator	tinyint		'Dates/ReportIssued/PeriodRange/@Operator/text()',
	ReportIssuedPeriodRangeType		nvarchar(2) 'Dates/ReportIssued/PeriodRange/Type/text()',
	ReportIssuedPeriodRangeFrom		smallint	'Dates/ReportIssued/PeriodRange/From/text()',
	ReportIssuedPeriodRangeTo		smallint	'Dates/ReportIssued/PeriodRange/To/text()',
	ReportReceivedDateRangeOperator		tinyint	'Dates/ReportReceived/DateRange/@Operator/text()',  
	ReportReceivedDateRangeFrom		datetime	'Dates/ReportReceived/DateRange/From/text()',  
	ReportReceivedDateRangeTo		datetime	'Dates/ReportReceived/DateRange/To/text()',  
	ReportReceivedPeriodRangeOperator	tinyint		'Dates/ReportReceived/PeriodRange/@Operator/text()',  
	ReportReceivedPeriodRangeFrom		smallint	'Dates/ReportReceived/PeriodRange/From/text()',  
	ReportReceivedPeriodRangeTo		smallint	'Dates/ReportReceived/PeriodRange/To/text()',  
	ReportReceivedPeriodRangeType		nvarchar(2)	'Dates/ReportReceived/PeriodRange/Type/text()',  
	PublishedDateRangeOperator	tinyint	'Dates/Published/DateRange/@Operator/text()',  
	PublishedDateRangeFrom		datetime	'Dates/Published/DateRange/From/text()',  
	PublishedDateRangeTo		datetime	'Dates/Published/DateRange/To/text()',  
	
	PriorityDateRangeOperator		tinyint	'Dates/Priority/DateRange/@Operator/text()',  
	PriorityDateRangeFrom		datetime	'Dates/Priority/DateRange/From/text()',  
	PriorityDateRangeTo		datetime	'Dates/Priority/DateRange/To/text()',  
	GrantedDateRangeOperator		tinyint	'Dates/Granted/DateRange/@Operator/text()',  
	GrantedDateRangeFrom		datetime	'Dates/Granted/DateRange/From/text()',  
	GrantedDateRangeTo		datetime	'Dates/Granted/DateRange/To/text()'  
         	     )"
         	     
        	     
    --Set @sSQLString = @sSQLString1 +@sStoredProcedure + @sSQLString2
    

	--print @sSQLString
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc					int,
				  @sCitation				nvarchar(254)		output,
				  @nCitationOperator			tinyint			output,
				  @sOfficialNumber			nvarchar(36)		output,
				  @nOfficialNumberOperator		tinyint			output,
				  @sCountryCodes			nvarchar(1000)		output,
				  @nCountryCodesOperator		tinyint			output,
				  @sKindCode				nvarchar(254)		output,
				  @nKindCodeOperator			tinyint			output,
				  @sTitle				nvarchar(254)		output,
				  @nTitleOperator			tinyint			output,				  
				  @sName				nvarchar(254)		output,
				  @nNameOperator			tinyint			output,
				  @nSourceDocumentKey			int			output,
				  @nSourceDocumentKeyOperator		tinyint			output,
				  @sDescription				nvarchar(254)		output,
				  @nDescriptionOperator			tinyint			output,
				  @sPublication				nvarchar(254)		output,
				  @nPublicationOperator			tinyint			output,
				  @sIssuingCountryCodes			nvarchar(1000)		output,
				  @nIssuingCountryCodesOperator		tinyint			output,
				  @sClasses				nvarchar(254)		output,
				  @nClassesOperator			tinyint			output,
				  @sSubClasses				nvarchar(254)		output,
				  @nSubClassesOperator			tinyint			output,
				  @bIPDocument				bit			output,
				  @bNonIPDocument			bit			output,
				  @sCaseReference			nvarchar(60)		output,
				  @nCaseReferenceOperator		tinyint			output,	
				  @sFamilyKey				nvarchar(20)		output,
				  @nFamilyKeyOperator			tinyint			output,	
				  @nReportIssuedDateRangeOperator	tinyint			output,
				  @dtReportIssuedDateRangeFrom		datetime		output,
				  @dtReportIssuedDateRangeTo 		datetime		output,
				  @nReportIssuedPeriodRangeOperator	tinyint			output,
				  @sReportIssuedPeriodRangeType		nvarchar(2)		output,
				  @nReportIssuedPeriodRangeFrom		smallint		output,
				  @nReportIssuedPeriodRangeTo		smallint		output,
				  @nReportReceivedDateRangeOperator	tinyint			output,
				  @dtReportReceivedDateRangeFrom	datetime		output,
				  @dtReportReceivedDateRangeTo 		datetime		output,
				  @nReportReceivedPeriodRangeOperator	tinyint			output,
				  @sReportReceivedPeriodRangeType	nvarchar(2)		output,
				  @nReportReceivedPeriodRangeFrom	smallint		output,
				  @nReportReceivedPeriodRangeTo		smallint		output,
				  @nPublishedDateRangeOperator		tinyint			output,
				  @dtPublishedDateRangeFrom		datetime		output,
				  @dtPublishedDateRangeTo 		datetime		output,
				  @nPriorityDateRangeOperator		tinyint			output,
				  @dtPriorityDateRangeFrom		datetime		output,
				  @dtPriorityDateRangeTo 		datetime		output,
				  @nGrantedDateRangeOperator		tinyint			output,
				  @dtGrantedDateRangeFrom		datetime		output,
				  @dtGrantedDateRangeTo 		datetime		output',
				  @idoc					= @idoc, 
				  @sCitation				= @sCitation				output,
				  @nCitationOperator			= @nCitationOperator			output,
				  @sOfficialNumber			= @sOfficialNumber			output,
				  @nOfficialNumberOperator		= @nOfficialNumberOperator		output,
				  @sCountryCodes			= @sCountryCodes			output,
				  @nCountryCodesOperator		= @nCountryCodesOperator		output,
				  @sKindCode				= @sKindCode				output,
				  @nKindCodeOperator			= @nKindCodeOperator			output,
				  @sTitle				= @sTitle				output,
				  @nTitleOperator			= @nTitleOperator			output,				  
				  @sName				= @sName				output,
				  @nNameOperator			= @nNameOperator			output,
				  @nSourceDocumentKey			= @nSourceDocumentKey 			output,
				  @nSourceDocumentKeyOperator		= @nSourceDocumentKeyOperator		output,
				  @sDescription				= @sDescription				output,
				  @nDescriptionOperator			= @nDescriptionOperator			output,
				  @sPublication				= @sPublication				output,
				  @nPublicationOperator			= @nPublicationOperator			output,
				  @sIssuingCountryCodes			= @sIssuingCountryCodes			output,
				  @nIssuingCountryCodesOperator		= @nIssuingCountryCodesOperator		output,
				  @sClasses				= @sClasses				output,
				  @nClassesOperator			= @nClassesOperator			output,
				  @sSubClasses				= @sSubClasses				output,
				  @nSubClassesOperator			= @nSubClassesOperator			output,
				  @bIPDocument				= @bIPDocument				output,
				  @bNonIPDocument			= @bNonIPDocument			output,
				  @sCaseReference			= @sCaseReference			output,
				  @nCaseReferenceOperator		= @nCaseReferenceOperator		output,	
				  @sFamilyKey				= @sFamilyKey				output,
				  @nFamilyKeyOperator			= @nFamilyKeyOperator			output,	
				  @nReportIssuedDateRangeOperator	= @nReportIssuedDateRangeOperator	output,
				  @dtReportIssuedDateRangeFrom		= @dtReportIssuedDateRangeFrom		output,
				  @dtReportIssuedDateRangeTo		= @dtReportIssuedDateRangeTo		output,
				  @nReportIssuedPeriodRangeOperator	= @nReportIssuedPeriodRangeOperator	output,
				  @sReportIssuedPeriodRangeType		= @sReportIssuedPeriodRangeType		output,
				  @nReportIssuedPeriodRangeFrom		= @nReportIssuedPeriodRangeFrom		output,
				  @nReportIssuedPeriodRangeTo		= @nReportIssuedPeriodRangeTo		output,
				  @nReportReceivedDateRangeOperator	= @nReportReceivedDateRangeOperator	output,
				  @dtReportReceivedDateRangeFrom	= @dtReportReceivedDateRangeFrom	output,
				  @dtReportReceivedDateRangeTo 		= @dtReportReceivedDateRangeTo		output,
				  @nReportReceivedPeriodRangeOperator	= @nReportReceivedPeriodRangeOperator	output,
				  @sReportReceivedPeriodRangeType	= @sReportReceivedPeriodRangeType	output,
				  @nReportReceivedPeriodRangeFrom	= @nReportReceivedPeriodRangeFrom	output,
				  @nReportReceivedPeriodRangeTo		= @nReportReceivedPeriodRangeTo		output,
				  @nPublishedDateRangeOperator		= @nPublishedDateRangeOperator		output,
				  @dtPublishedDateRangeFrom		= @dtPublishedDateRangeFrom		output,
				  @dtPublishedDateRangeTo 		= @dtPublishedDateRangeTo		output,
				  @nPriorityDateRangeOperator		= @nPriorityDateRangeOperator		output,
				  @dtPriorityDateRangeFrom		= @dtPriorityDateRangeFrom		output,
				  @dtPriorityDateRangeTo 		= @dtPriorityDateRangeTo		output,
				  @nGrantedDateRangeOperator		= @nGrantedDateRangeOperator		output,
				  @dtGrantedDateRangeFrom		= @dtGrantedDateRangeFrom		output,
				  @dtGrantedDateRangeTo			= @dtGrantedDateRangeTo			output
				   
	If @nErrorCode = 0
	Begin		
	If (@sCitation is not null or @nCitationOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.CITATION"+
			dbo.fn_ConstructOperator(@nCitationOperator,@String,
			@sCitation,null,@pbCalledFromCentura)
	End
	
	
	If (@sOfficialNumber is not null or @nOfficialNumberOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.OFFICIALNO"+
			dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,
			@sOfficialNumber,null,@pbCalledFromCentura)
	End
	
	If (@sCountryCodes is not null or @nCountryCodesOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.COUNTRYCODE"+
			dbo.fn_ConstructOperator(@nCountryCodesOperator,@String,
			@sCountryCodes,null,@pbCalledFromCentura)
	End
	
	
	If (@sKindCode is not null or @nKindCodeOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.KINDCODE"+
			dbo.fn_ConstructOperator(@nKindCodeOperator,@String,
			@sKindCode,null,@pbCalledFromCentura)
	End
	
	If (@sTitle is not null or @nTitleOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.TITLE"+
			dbo.fn_ConstructOperator(@nTitleOperator,@String,
			@sTitle,null,@pbCalledFromCentura)
	End
	
	If (@sName is not null or @nNameOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.INVENTORNAME"+
			dbo.fn_ConstructOperator(@nNameOperator,@String,
			@sName,null,@pbCalledFromCentura)
	End
	
	If (@nSourceDocumentKey is not null or @nSourceDocumentKeyOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and SD.SOURCE"+
			dbo.fn_ConstructOperator(@nSourceDocumentKeyOperator,@Numeric,
			@nSourceDocumentKey,null,@pbCalledFromCentura)
	End
	
	If (@sDescription is not null or @nDescriptionOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.DESCRIPTION"+
			dbo.fn_ConstructOperator(@nDescriptionOperator,@String,
			@sDescription,null,@pbCalledFromCentura)
	End
	
	If (@sPublication is not null or @nPublicationOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and SD.PUBLICATION"+
			dbo.fn_ConstructOperator(@nPublicationOperator,@String,
			@sPublication,null,@pbCalledFromCentura)
	End
	
	If (@sIssuingCountryCodes is not null or @nIssuingCountryCodesOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and SD.ISSUINGCOUNTRY"+
			dbo.fn_ConstructOperator(@nIssuingCountryCodesOperator,@String,
			@sIssuingCountryCodes,null,@pbCalledFromCentura)
	End
	
	If (@sClasses is not null or @nClassesOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and SD.CLASS"+
			dbo.fn_ConstructOperator(@nClassesOperator,@String,
			@sClasses,null,@pbCalledFromCentura)
	End

	If (@sSubClasses is not null or @nSubClassesOperator in (5,6))
	Begin
		Set @sWhere = @sWhere+char(10)+"	and SD.SUBCLASS"+
			dbo.fn_ConstructOperator(@nSubClassesOperator,@String,
			@sSubClasses,null,@pbCalledFromCentura)
	End
	
	If (@bIPDocument = 1 and @bNonIPDocument = 0)
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.PATENTRELATED = 1"
	End	
	Else If (@bIPDocument = 0 and @bNonIPDocument = 1)
	Begin
		Set @sWhere = @sWhere+char(10)+"	and S.PATENTRELATED = 0 or S.PATENTRELATED is null"
	End	
	
	
	-- If Period Range and Period Type are supplied, these are used to calculate WIP From date
	-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
	-- current date.  	

	If   @sReportIssuedPeriodRangeType is not null
	and (@nReportIssuedPeriodRangeFrom is not null
	 or  @nReportIssuedPeriodRangeTo   is not null)
	Begin		
		If @nReportIssuedPeriodRangeFrom is not null
		Begin
			Set @sSQLString = "Set @dtReportIssuedDateRangeFrom = dateadd("+@sReportIssuedPeriodRangeType+", "+"-"+"@nReportIssuedPeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtReportIssuedDateRangeFrom	datetime 		output,
	 				  @sReportIssuedPeriodRangeType	nvarchar(2),
					  @nReportIssuedPeriodRangeFrom	smallint',
	  				  @dtReportIssuedDateRangeFrom	= @dtReportIssuedDateRangeFrom 	output,
					  @sReportIssuedPeriodRangeType	= @sReportIssuedPeriodRangeType,
					  @nReportIssuedPeriodRangeFrom	= @nReportIssuedPeriodRangeFrom				  
		End
	
		If @nReportIssuedPeriodRangeTo is not null
		Begin
			Set @sSQLString = "Set @dtReportIssuedDateRangeTo = dateadd("+@sReportIssuedPeriodRangeType+", "+"-"+"@nReportIssuedPeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtReportIssuedDateRangeTo	datetime 		output,
	 				  @sReportIssuedPeriodRangeType	nvarchar(2),
					  @nReportIssuedPeriodRangeTo	smallint',
	  				  @dtReportIssuedDateRangeTo	= @dtReportIssuedDateRangeTo 	output,
					  @sReportIssuedPeriodRangeType	= @sReportIssuedPeriodRangeType,
					  @nReportIssuedPeriodRangeTo	= @nReportIssuedPeriodRangeTo				
		End				  
	End	
	
	--select @sWhere	

	If  (@nReportIssuedDateRangeOperator is not null
	 or  @nReportIssuedPeriodRangeOperator is not null)
	and (@dtReportIssuedDateRangeFrom is not null
	or   @dtReportIssuedDateRangeTo is not null)
	Begin
		If @sReportIssuedPeriodRangeType is not null
		If (@sCitation is not null or @nCitationOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.CITATION"+
				dbo.fn_ConstructOperator(@nCitationOperator,@String,
				@sCitation,null,@pbCalledFromCentura)
		End
		
		
		If (@sOfficialNumber is not null or @nOfficialNumberOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.OFFICIALNO"+
				dbo.fn_ConstructOperator(@nOfficialNumberOperator,@String,
				@sOfficialNumber,null,@pbCalledFromCentura)
		End
		
		If (@sCountryCodes is not null or @nCountryCodesOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.COUNTRYCODE"+
				dbo.fn_ConstructOperator(@nCountryCodesOperator,@String,
				@sCountryCodes,null,@pbCalledFromCentura)
		End
		
		
		If (@sKindCode is not null or @nKindCodeOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.KINDCODE"+
				dbo.fn_ConstructOperator(@nKindCodeOperator,@String,
				@sKindCode,null,@pbCalledFromCentura)
		End
		
		If (@sTitle is not null or @nTitleOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.TITLE"+
				dbo.fn_ConstructOperator(@nTitleOperator,@String,
				@sTitle,null,@pbCalledFromCentura)
		End
		
		If (@sName is not null or @nNameOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.INVENTORNAME"+
				dbo.fn_ConstructOperator(@nNameOperator,@String,
				@sName,null,@pbCalledFromCentura)
		End
		
		If (@nSourceDocumentKey is not null or @nSourceDocumentKeyOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and SD.SOURCE"+
				dbo.fn_ConstructOperator(@nSourceDocumentKeyOperator,@Numeric,
				@nSourceDocumentKey,null,@pbCalledFromCentura)
		End
		
		If (@sDescription is not null or @nDescriptionOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and isnull(S.DESCRIPTION,SD.DESCRIPTION)"+
				dbo.fn_ConstructOperator(@nDescriptionOperator,@String,
				@sDescription,null,@pbCalledFromCentura)
		End
		
		If (@sPublication is not null or @nPublicationOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and SD.PUBLICATION"+
				dbo.fn_ConstructOperator(@nPublicationOperator,@String,
				@sPublication,null,@pbCalledFromCentura)
		End
		
		If (@sIssuingCountryCodes is not null or @nIssuingCountryCodesOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and SD.ISSUINGCOUNTRY"+
				dbo.fn_ConstructOperator(@nIssuingCountryCodesOperator,@String,
				@sIssuingCountryCodes,null,@pbCalledFromCentura)
		End
		
		If (@sClasses is not null or @nClassesOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and SD.CLASS"+
				dbo.fn_ConstructOperator(@nClassesOperator,@String,
				@sClasses,null,@pbCalledFromCentura)
		End

		If (@sSubClasses is not null or @nSubClassesOperator in (5,6))
		Begin
			Set @sWhere = @sWhere+char(10)+"	and SD.SUBCLASS"+
				dbo.fn_ConstructOperator(@nSubClassesOperator,@String,
				@sSubClasses,null,@pbCalledFromCentura)
		End
		
		If (@bIPDocument = 1 and @bNonIPDocument = 0)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.PATENTRELATED = 1"
		End	
		Else If (@bIPDocument = 0 and @bNonIPDocument = 1)
		Begin
			Set @sWhere = @sWhere+char(10)+"	and S.PATENTRELATED = 0 or S.PATENTRELATED is null"
		End	
		
		
		-- If Period Range and Period Type are supplied, these are used to calculate WIP From date
		-- and To date before proceeding.  The dates are calculated by adding the period and type to the 
		-- current date.  	

		If   @sReportIssuedPeriodRangeType is not null
		and (@nReportIssuedPeriodRangeFrom is not null
		or  @nReportIssuedPeriodRangeTo   is not null)
		Begin		
			-- For the PeriodRange filtering swap around @dtDateRangeFrom and @dtDateRangeTo:
			Set @sWhere = @sWhere+char(10)+" and SD.ISSUEDDATE "+dbo.fn_ConstructOperator(@nReportIssuedPeriodRangeOperator,@Date,convert(nvarchar,@dtReportIssuedDateRangeTo,112), convert(nvarchar,@dtReportIssuedDateRangeFrom,112),0)									
		End
		Else Begin
			Set @sWhere = @sWhere+char(10)+" and SD.ISSUEDDATE "+dbo.fn_ConstructOperator(@nReportIssuedDateRangeOperator,@Date,convert(nvarchar,@dtReportIssuedDateRangeFrom,112), convert(nvarchar,@dtReportIssuedDateRangeTo,112),0)									
		End
	End	
	
	
	If   @sReportReceivedPeriodRangeType is not null
	and (@nReportReceivedPeriodRangeFrom is not null
	 or  @nReportReceivedPeriodRangeTo   is not null)
	Begin		
		If @nReportReceivedPeriodRangeFrom is not null
		Begin
			Set @sSQLString = "Set @dtReportReceivedDateRangeFrom = dateadd("+@sReportReceivedPeriodRangeType+", "+"-"+"@nReportReceivedPeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtReportReceivedDateRangeFrom	datetime 		output,
	 				  @sReportReceivedPeriodRangeType	nvarchar(2),
					  @nReportReceivedPeriodRangeFrom	smallint',
	  				  @dtReportReceivedDateRangeFrom	= @dtReportReceivedDateRangeFrom 	output,
					  @sReportReceivedPeriodRangeType	= @sReportReceivedPeriodRangeType,
					  @nReportReceivedPeriodRangeFrom	= @nReportReceivedPeriodRangeFrom				  
		End
	
		If @nReportReceivedPeriodRangeTo is not null
		Begin
			Set @sSQLString = "Set @dtReportReceivedDateRangeTo = dateadd("+@sReportReceivedPeriodRangeType+", "+"-"+"@nReportReceivedPeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"

			execute sp_executesql @sSQLString,
					N'@dtReportReceivedDateRangeTo	datetime 		output,
	 				  @sReportReceivedPeriodRangeType	nvarchar(2),
					  @nReportReceivedPeriodRangeTo	smallint',
	  				  @dtReportReceivedDateRangeTo	= @dtReportReceivedDateRangeTo 	output,
					  @sReportReceivedPeriodRangeType	= @sReportReceivedPeriodRangeType,
					  @nReportReceivedPeriodRangeTo	= @nReportReceivedPeriodRangeTo				
		End				  
	End	

	If  (@nReportReceivedDateRangeOperator is not null
	 or  @nReportReceivedPeriodRangeOperator is not null)
	and (@dtReportReceivedDateRangeFrom is not null
	or   @dtReportReceivedDateRangeTo is not null)
	Begin
		If @sReportReceivedPeriodRangeType is not null
		and (@nReportReceivedPeriodRangeFrom is not null
		or  @nReportReceivedPeriodRangeTo   is not null)
		Begin		
			-- For the PeriodRange filtering swap around @dtDateRangeFrom and @dtDateRangeTo:
			Set @sWhere = @sWhere+char(10)+" and SD.RECEIVEDDATE "+dbo.fn_ConstructOperator(@nReportReceivedPeriodRangeOperator,@Date,convert(nvarchar,@dtReportReceivedDateRangeTo,112), convert(nvarchar,@dtReportReceivedDateRangeFrom,112),0)									
		End
		Else Begin
			Set @sWhere = @sWhere+char(10)+" and SD.RECEIVEDDATE "+dbo.fn_ConstructOperator(@nReportReceivedDateRangeOperator,@Date,convert(nvarchar,@dtReportReceivedDateRangeFrom,112), convert(nvarchar,@dtReportReceivedDateRangeTo,112),0)									
		End
	End	
	
	If  (@dtPublishedDateRangeFrom is not null
	or   @dtPublishedDateRangeTo is not null)
	Begin
		Begin
			Set @sWhere = @sWhere+char(10)+" and S.PUBLICATIONDATE "+dbo.fn_ConstructOperator(@nPublishedDateRangeOperator,@Date,convert(nvarchar,@dtPublishedDateRangeFrom,112), convert(nvarchar,@dtPublishedDateRangeTo,112),0)									
		End
	End
	
	If  (@dtPriorityDateRangeFrom is not null
	or   @dtPriorityDateRangeTo is not null)
	Begin
		Begin
			Set @sWhere = @sWhere+char(10)+" and S.PRIORITYDATE "+dbo.fn_ConstructOperator(@nPriorityDateRangeOperator,@Date,convert(nvarchar,@dtPriorityDateRangeFrom,112), convert(nvarchar,@dtPriorityDateRangeTo,112),0)									
		End
	End
	
	If  (@dtGrantedDateRangeFrom is not null
	or   @dtGrantedDateRangeTo is not null)
	Begin
		Begin
			Set @sWhere = @sWhere+char(10)+" and S.GRANTEDDATE "+dbo.fn_ConstructOperator(@nGrantedDateRangeOperator,@Date,convert(nvarchar,@dtGrantedDateRangeFrom,112), convert(nvarchar,@dtGrantedDateRangeTo,112),0)									
		End
	End
	
		If @nCaseReferenceOperator=6
		or @nFamilyKeyOperator    =6
		Begin
			-- Case or Family does not exist
			Set @sFrom = " Left Join CASESEARCHRESULT CS on ( CS.PRIORARTID = S.PRIORARTID)"+CHAR(10)+
			             " Left Join CASES CS1           on ( CS1.CASEID = CS.CASEID)"
			             
			If @nCaseReferenceOperator is not null
				Set @sWhere = @sWhere + CHAR(10) + " and CS1.IRN " + dbo.fn_ConstructOperator(@nCaseReferenceOperator,@String, @sCaseReference,null,@pbCalledFromCentura)
				
			If @nFamilyKeyOperator is not null
				Set @sWhere = @sWhere + CHAR(10) + " and CS1.FAMILY" +dbo.fn_ConstructOperator(@nFamilyKeyOperator,@String,@sFamilyKey,null,@pbCalledFromCentura)
		End
		Else If @sCaseReference is not null
		     or @sFamilyKey     is not null
		     or @nCaseReferenceOperator=5
		     or @nFamilyKeyOperator    =5
		Begin
			Set @sFrom = " Join CASESEARCHRESULT CS on (CS.PRIORARTID = S.PRIORARTID)"+CHAR(10)+
				     " Join CASES CS1           on (CS1.CASEID    = CS.CASEID)"
				
			If @nCaseReferenceOperator is not null
				Set @sWhere = @sWhere + CHAR(10) + " and CS1.IRN " + dbo.fn_ConstructOperator(@nCaseReferenceOperator,@String, @sCaseReference,null,@pbCalledFromCentura)
				
			If @nFamilyKeyOperator is not null
				Set @sWhere = @sWhere + CHAR(10) + " and CS1.FAMILY" +dbo.fn_ConstructOperator(@nFamilyKeyOperator,@String,@sFamilyKey,null,@pbCalledFromCentura)
		End
	
	Set @sWhere = @sFrom + CHAR(10) + ' Where ' 	+@sWhere
End
End

If @nErrorCode = 0
	Set @psPriorArtWhere = @sWhere

RETURN @nErrorCode
GO

Grant execute on dbo.pr_ConstructPriorArtWhere  to public
GO

