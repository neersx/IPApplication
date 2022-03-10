-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertSearchResult.'
	Drop procedure [dbo].[prw_InsertSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_InsertSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertSearchResult
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null	OUTPUT,
	@pdtLastModifiedDate	datetime	= null	OUTPUT,
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
	@pbCheckIfExists	bit		= 0,
	@psComments             nvarchar(254)   = null
)
as
-- PROCEDURE:	prw_InsertSearchResult
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Search Result

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Mar 2011	JC	R6563	1	Procedure created
-- 05 Oct 2011	MF	R11350	2	Check for the pre-existence of matching prior art and if it exists return
--					the PriorArtKey rather than insert another entry.
-- 10 Apr 2013	AK	R13277	3	Added Abstract Column to insert
-- 22 May 2014  SW      R33877  4       Corrected sql syntax.
-- 04 Jul 2014  SW      R35971  5       Added Comments Column to insert 
-- 09 Sep 2014  SW      R38937  6       Increased length of Description field to nvarchar(max) 

-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

----------------------------------------------
-- If the details provided are for prior art
-- as opposed to a source document then check
-- to see if the Prior Art has previously been
-- loaded
----------------------------------------------
If  @nErrorCode = 0
and @pbIsSourceDocument = 0
and @pbCheckIfExists = 1
Begin
	Set @sSQLString="
	Select @pnPriorArtKey      =PRIORARTID,
	       @pdtLastModifiedDate=LOGDATETIMESTAMP
	from SEARCHRESULTS
	where ISSOURCEDOCUMENT=0
	and (CITATION       =@psCitation       or (CITATION        is null and @psCitation       is null))
	and (PATENTRELATED  =@pbIsIPDocument   or (PATENTRELATED   is null and @pbIsIPDocument   is null))
	and (DESCRIPTION    =@psDescription    or (DESCRIPTION     is null and @psDescription    is null))
	and (COMMENTS       =@psComments       or (COMMENTS        is null and @psComments       is null))	
	and (OFFICIALNO     =@psOfficialNumber or (OFFICIALNO      is null and @psOfficialNumber is null))
	and (COUNTRYCODE    =@psCountryCode    or (COUNTRYCODE     is null and @psCountryCode    is null))
	and (KINDCODE       =@psKindCode       or (KINDCODE        is null and @psKindCode       is null))
	and (TITLE          =@psTitle          or (TITLE           is null and @psTitle          is null))
	and (ABSTRACT		=@psAbstract	   or (ABSTRACT		   is null and @psAbstract       is null))
	and (INVENTORNAME   =@psName           or (INVENTORNAME    is null and @psName           is null))
	and (REFPAGES       =@psRefDocParts    or (REFPAGES        is null and @psRefDocParts    is null))
	and (PUBLICATIONDATE=@pdtPublishedDate or (PUBLICATIONDATE is null and @pdtPublishedDate is null))
	and (PRIORITYDATE   =@pdtPriorityDate  or (PRIORITYDATE    is null and @pdtPriorityDate  is null))
	and (GRANTEDDATE    =@pdtGrantedDate   or (GRANTEDDATE     is null and @pdtGrantedDate   is null))
	and (PTOCITEDDATE   =@pdtPTOCitedDate  or (PTOCITEDDATE    is null and @pdtPTOCitedDate  is null))
	and (APPFILEDDATE   =@pdtAppFiledDate  or (APPFILEDDATE    is null and @pdtAppFiledDate  is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnPriorArtKey		int			OUTPUT,
				@pdtLastModifiedDate	datetime		OUTPUT,
				@psCitation		nvarchar(254),
				@pbIsIPDocument		bit,
				@psDescription		nvarchar(max),
				@psOfficialNumber	nvarchar(36),
				@psCountryCode		nvarchar(3),
				@psKindCode		nvarchar(254),
				@psTitle		nvarchar(254),
				@psAbstract     nvarchar(max),
				@psName			nvarchar(254),
				@psRefDocParts		nvarchar(254),
				@pdtPublishedDate	datetime,
				@pdtPriorityDate	datetime,
				@pdtGrantedDate		datetime,
				@pdtPTOCitedDate	datetime,
				@pdtAppFiledDate	datetime,
				@psComments             nvarchar(254)',
				@pnPriorArtKey		= @pnPriorArtKey	OUTPUT,
				@pdtLastModifiedDate	= @pdtLastModifiedDate	OUTPUT,
				@psCitation		= @psCitation,
				@pbIsIPDocument		= @pbIsIPDocument,
				@psDescription		= @psDescription,
				@psOfficialNumber	= @psOfficialNumber,
				@psCountryCode		= @psCountryCode,
				@psKindCode		= @psKindCode,
				@psTitle		= @psTitle,
				@psAbstract     =@psAbstract,
				@psName			= @psName,
				@psRefDocParts		= @psRefDocParts,
				@pdtPublishedDate	= @pdtPublishedDate,
				@pdtPriorityDate	= @pdtPriorityDate,
				@pdtGrantedDate		= @pdtGrantedDate,
				@pdtPTOCitedDate	= @pdtPTOCitedDate,
				@pdtAppFiledDate	= @pdtAppFiledDate,
				@psComments             = @psComments


End

If  @nErrorCode = 0
and @pnPriorArtKey is null
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
		set @psAbstract			=null
		set @psName			= null
		set @psRefDocParts		= null
		set @pnTranslationKey		= null
	End

	Set @sSQLString = "
	Insert into SEARCHRESULTS
		(ISSOURCEDOCUMENT,
		 CITATION,
		 PATENTRELATED,
		 DESCRIPTION,
		 OFFICIALNO,
		 COUNTRYCODE,
		 KINDCODE,
		 TITLE,
		 ABSTRACT,
		 INVENTORNAME,
		 REFPAGES,
		 TRANSLATION,
		 SOURCE,
		 ISSUINGCOUNTRY,
		 PUBLICATION,
		 CLASS,
		 SUBCLASS,
		 ISSUEDDATE,
		 RECEIVEDDATE,
		 PUBLICATIONDATE,
		 PRIORITYDATE,
		 GRANTEDDATE,
		 PTOCITEDDATE,
		 APPFILEDDATE,
		 COMMENTS)
	values (
		@pbIsSourceDocument,
		@psCitation,
		@pbIsIPDocument,
		@psDescription,
		@psOfficialNumber,
		@psCountryCode,
		@psKindCode,
		@psTitle,
		@psAbstract,
		@psName,
		@psRefDocParts,
		@pnTranslationKey,
		@pnSourceKey,
		@psIssuingCountryCode,
		@psPublicationNumber,
		@psClasses,
		@psSubClasses,
		@pdtReportIssuedDate,
		@pdtReportReceivedDate,
		@pdtPublishedDate,
		@pdtPriorityDate,
		@pdtGrantedDate,
		@pdtPTOCitedDate,
		@pdtAppFiledDate,
		@psComments)

	Set @pnPriorArtKey = SCOPE_IDENTITY()
	
	Select	@pdtLastModifiedDate = LOGDATETIMESTAMP
	from	SEARCHRESULTS
	where	PRIORARTID	= @pnPriorArtKey
	"

	exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnPriorArtKey		int output,
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
				@pnPriorArtKey		= @pnPriorArtKey OUTPUT,
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
End

If @nErrorCode=0
Begin
	Select	@pnPriorArtKey       as PriorArtKey,
		@pdtLastModifiedDate as LastModifiedDate
End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertSearchResult to public
GO