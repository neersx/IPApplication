-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListSourceDocuments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListSourceDocuments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListSourceDocuments.'
	Drop procedure [dbo].[prw_ListSourceDocuments]
End
Print '**** Creating Stored Procedure dbo.prw_ListSourceDocuments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListSourceDocuments
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_ListSourceDocuments
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Source Documents for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 MAr 2011	JC	RFC6563	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	RC.CITEDPRIORARTID		as CitedPriorArtKey,
	RC.SEARCHREPORTID		as SearchReportKey,
	ltrim(S.ISSUINGCOUNTRY + ' ' + coalesce(" +
	dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'S',@sLookupCulture,@pbCalledFromCentura) +",S.PUBLICATION)) as DisplayDescription,
	S.DESCRIPTION			as Description,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
			 +" as SourceDescription,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
		+ " as IssuingCountryName,
	S.PUBLICATION			as PublicationNumber,
	S.ISSUEDDATE			as ReportIssuedDate,
	S.RECEIVEDDATE			as ReportReceivedDate,
	cast(isnull(S.ISSOURCEDOCUMENT,0) as bit)	as IsSourceDocument,
	RC.LOGDATETIMESTAMP		as LastModifiedDate
	from REPORTCITATIONS RC
	join SEARCHRESULTS S		on (S.PRIORARTID = RC.SEARCHREPORTID)
	left join TABLECODES TC		on (TC.TABLECODE = S.SOURCE)
	left join COUNTRY C		on (C.COUNTRYCODE = S.ISSUINGCOUNTRY)
	where RC.CITEDPRIORARTID = @pnPriorArtKey
	order by Description,SourceDescription,IssuingCountryName,PublicationNumber"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura bit,
			@pnPriorArtKey		int',
			@pnUserIdentityId   = @pnUserIdentityId,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnPriorArtKey		= @pnPriorArtKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_ListSourceDocuments to public
GO