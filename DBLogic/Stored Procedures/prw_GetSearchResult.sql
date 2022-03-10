-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_GetSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_GetSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_GetSearchResult.'
	Drop procedure [dbo].[prw_GetSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_GetSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_GetSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_GetSearchResult
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get a Prior Art Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 30 Sep 2010	JCLG	RFC9304	1	Procedure created
-- 26 Sep 2012	SF      R11988	2	ImportedFrom and CorrelationId
-- 10 Apr 2013	AK	R13277	3	added Abstract in result set
-- 04 Jul 2014  SW      R35971  4       Added Comments in result set

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	S.PRIORARTID			as PriorArtKey,
	cast(isnull(S.ISSOURCEDOCUMENT,0) as bit)	as IsSourceDocument,
	"+dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','CITATION',null,'S',@sLookupCulture,@pbCalledFromCentura)	
			 +" as Citation,			
	cast(isnull(S.PATENTRELATED,0) as bit)	as IsIPDocument,
	"+dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'S',@sLookupCulture,@pbCalledFromCentura)	
			 +" as Description,
	S.COMMENTS                      as Comments,			
	S.OFFICIALNO			as OfficialNumber,
	S.COUNTRYCODE			as CountryCode,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName,
	S.KINDCODE			as KindCode,
	"+dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','TITLE',null,'S',@sLookupCulture,@pbCalledFromCentura)	
			 +" as Title,			
	S.INVENTORNAME			as Name,
	S.REFPAGES			as RefDocParts,
	S.TRANSLATION			as TranslationKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC1',@sLookupCulture,@pbCalledFromCentura)
			 +" as TranslationDescription,
	S.SOURCE			as SourceKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC2',@sLookupCulture,@pbCalledFromCentura)
			 +" as SourceDescription,
	S.ISSUINGCOUNTRY		as IssuingCountryCode,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'IC',@sLookupCulture,@pbCalledFromCentura)
		+ " as IssuingCountryName,
	S.PUBLICATION			as PublicationNumber,
	S.CLASS				as Classes,
	S.SUBCLASS			as SubClasses,
	S.ISSUEDDATE			as ReportIssuedDate,
	S.RECEIVEDDATE			as ReportReceivedDate,
	S.PUBLICATIONDATE		as PublishedDate,
	S.PRIORITYDATE			as PriorityDate,
	S.GRANTEDDATE			as GrantedDate,
	S.PTOCITEDDATE			as PTOCitedDate,
	S.APPFILEDDATE			as AppFiledDate,
	S.IMPORTEDFROM			as ImportedFrom,
	S.CORRELATIONID			as CorrelationId,	
	S.LOGDATETIMESTAMP		as LastModifiedDate,
	S.ABSTRACT				as Abstract
	from SEARCHRESULTS S
	left join COUNTRY C		on (C.COUNTRYCODE = S.COUNTRYCODE)
	left join COUNTRY IC		on (IC.COUNTRYCODE = S.ISSUINGCOUNTRY)
	left join TABLECODES TC1	on (TC1.TABLECODE = S.TRANSLATION)
	left join TABLECODES TC2	on (TC2.TABLECODE = S.SOURCE)
	where S.PRIORARTID = @pnPriorArtKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@pnPriorArtKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_GetSearchResult to public
GO