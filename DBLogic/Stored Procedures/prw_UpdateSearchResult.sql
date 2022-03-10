-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_UpdateSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_UpdateSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_UpdateSearchResult.'
	Drop procedure [dbo].[prw_UpdateSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_UpdateSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.prw_UpdateSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int,
	@pbIsSourceDocument	bit		= 0,	
	@psCitation		nvarchar(254)	= null,
	@pbIsIPDocument		bit		= 0,	
	@psDescription		nvarchar(max)	= null,
	@psOfficialNumber	nvarchar(36)	= null,
	@psCountryCode		nvarchar(3)	= null,
	@psKindCode		nvarchar(254)	= null,
	@psTitle		nvarchar(254)	= null,
	@psAbstract		nvarchar(max)	= null,
	@psName			nvarchar(254)	= null,
	@psRefDocParts		nvarchar(254)	= null,
	@pnTranslationKey	int		= null,
	@pnSourceKey		int		= null,
	@psIssuingCountryCode	nvarchar(3)	= null,
	@psPublicationNumber	nvarchar(254)	= null,
	@psClasses		nvarchar(254)	= null,
	@psSubClasses		nvarchar(254)	= null,
	@pdtReportIssuedDate	datetime	= null,
	@pdtReportReceivedDate	datetime	= null,
	@pdtPublishedDate	datetime	= null,
	@pdtPriorityDate	datetime	= null,
	@pdtGrantedDate		datetime	= null,
	@pdtPTOCitedDate	datetime	= null,
	@pdtAppFiledDate	datetime	= null,	
	@psComments             nvarchar(254)   = null,
	@pdtLastModifiedDate	datetime	= null output
)
as
-- PROCEDURE:	prw_UpdateSearchResult
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update a Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 7	Dec 2010	JC	RFC9624		1	Procedure created
-- 10	Apr 2013	AK	RFC13277	2	Added Abstract Column to update
-- 04   Jul 2014        SW      R35971          3       Added Comments Column to update
-- 13   Aug 2014        vql     R35971          4       Dont update with empty strings
-- 09   Sep 2014        SW      R38937          5       Increased length of Description to nvarchar(max) 


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so the next procedure gets the default
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @bOldIsSourceDocument	bit

-- Initialise variables
Set @nErrorCode = 0
Set @bOldIsSourceDocument = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select	@bOldIsSourceDocument = isnull(ISSOURCEDOCUMENT,0)
		from	SEARCHRESULTS
		where	PRIORARTID = @pnPriorArtKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
	    @bOldIsSourceDocument	bit output,  		
		@pnPriorArtKey		int',
		@bOldIsSourceDocument	= @bOldIsSourceDocument OUTPUT,
		@pnPriorArtKey		= @pnPriorArtKey

End

If @nErrorCode = 0
Begin
	
	if (@bOldIsSourceDocument != @pbIsSourceDocument)
	Begin
		if @pbIsSourceDocument = 0
		Begin
			set @pnSourceKey		= null
			set @psIssuingCountryCode	= null
			set @psPublicationNumber	= null
			set @psClasses			= null
			set @psSubClasses		= null
			set @pdtReportIssuedDate	= null
			set @pdtReportReceivedDate	= null
		End
		Else
		Begin
			set @psCitation			= null
			set @pbIsIPDocument		= 0	
			set @psOfficialNumber		= null
			set @psCountryCode		= null
			set @psKindCode			= null
			set @psTitle			= null
			set @psAbstract			= null
			set @psName			= null
			set @psRefDocParts		= null
			set @pnTranslationKey		= null
		End
	End				

	Set @sSQLString = "Update SEARCHRESULTS
		set	ISSOURCEDOCUMENT	= @pbIsSourceDocument,
			CITATION		= nullif(@psCitation, ''),
			PATENTRELATED		= @pbIsIPDocument,
			DESCRIPTION		= nullif(@psDescription, ''),
			OFFICIALNO		= nullif(@psOfficialNumber, ''),
			COUNTRYCODE		= @psCountryCode,
			KINDCODE		= nullif(@psKindCode, ''),
			TITLE			= nullif(@psTitle,''),
			ABSTRACT		= nullif(@psAbstract, ''),
			INVENTORNAME		= nullif(@psName, ''),
			REFPAGES		= nullif(@psRefDocParts, ''),
			TRANSLATION		= @pnTranslationKey,
			SOURCE			= @pnSourceKey,
			ISSUINGCOUNTRY		= @psIssuingCountryCode,
			PUBLICATION		= nullif(@psPublicationNumber, ''),
			CLASS			= nullif(@psClasses, ''),
			SUBCLASS		= nullif(@psSubClasses, ''),
			ISSUEDDATE		= @pdtReportIssuedDate,
			RECEIVEDDATE		= @pdtReportReceivedDate,
			PUBLICATIONDATE		= @pdtPublishedDate,
			PRIORITYDATE		= @pdtPriorityDate,
			GRANTEDDATE		= @pdtGrantedDate,
			PTOCITEDDATE		= @pdtPTOCitedDate,
			APPFILEDDATE		= @pdtAppFiledDate,
			COMMENTS                = nullif(@psComments, '')
		where
			PRIORARTID		= @pnPriorArtKey
		and	LOGDATETIMESTAMP	= @pdtLastModifiedDate
		
		Select	@pdtLastModifiedDate	= LOGDATETIMESTAMP
		from	SEARCHRESULTS
		where	PRIORARTID		= @pnPriorArtKey"

	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey		int,
		@pbIsSourceDocument	bit,
		@psCitation		nvarchar(254),
		@pbIsIPDocument		bit,
		@psDescription		nvarchar(max),
		@psOfficialNumber	nvarchar(36),
		@psCountryCode		nvarchar(3),
		@psKindCode		nvarchar(254),
		@psTitle		nvarchar(254),
		@psAbstract		nvarchar(max),
		@psName			nvarchar(254),
		@psRefDocParts		nvarchar(254),
		@pnTranslationKey	int,
		@pnSourceKey		int,
		@psIssuingCountryCode	nvarchar(3),
		@psPublicationNumber	nvarchar(254),
		@psClasses		nvarchar(254),
		@psSubClasses		nvarchar(254),
		@pdtReportIssuedDate	datetime,
		@pdtReportReceivedDate	datetime,
		@pdtPublishedDate	datetime,
		@pdtPriorityDate	datetime,
		@pdtGrantedDate		datetime,
		@pdtPTOCitedDate	datetime,
		@pdtAppFiledDate	datetime,
		@psComments             nvarchar(254),
		@pdtLastModifiedDate	datetime output',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pbIsSourceDocument	= @pbIsSourceDocument,
		@psCitation		= @psCitation,
		@pbIsIPDocument		= @pbIsIPDocument,
		@psDescription		= @psDescription,
		@psOfficialNumber	= @psOfficialNumber,
		@psCountryCode		= @psCountryCode,
		@psKindCode		= @psKindCode,
		@psTitle		= @psTitle,
		@psAbstract		=@psAbstract,
		@psName			= @psName,
		@psRefDocParts		= @psRefDocParts,
		@pnTranslationKey	= @pnTranslationKey,
		@pnSourceKey		= @pnSourceKey,
		@psIssuingCountryCode	= @psIssuingCountryCode,
		@psPublicationNumber	= @psPublicationNumber,
		@psClasses		= @psClasses,
		@psSubClasses		= @psSubClasses,
		@pdtReportIssuedDate	= @pdtReportIssuedDate,
		@pdtReportReceivedDate	= @pdtReportReceivedDate,
		@pdtPublishedDate	= @pdtPublishedDate,
		@pdtPriorityDate	= @pdtPriorityDate,
		@pdtGrantedDate		= @pdtGrantedDate,
		@pdtPTOCitedDate	= @pdtPTOCitedDate,
		@pdtAppFiledDate	= @pdtAppFiledDate,
		@psComments             = @psComments,
		@pdtLastModifiedDate	= @pdtLastModifiedDate OUTPUT

	Select	@pdtLastModifiedDate as LastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.prw_UpdateSearchResult to public
GO