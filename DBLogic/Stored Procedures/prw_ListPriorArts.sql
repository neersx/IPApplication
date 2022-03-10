-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListPriorArts
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListPriorArts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListPriorArts.'
	Drop procedure [dbo].[prw_ListPriorArts]
End
Print '**** Creating Stored Procedure dbo.prw_ListPriorArts...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListPriorArts
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_ListPriorArts
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Prior Arts for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------		------	-------	-----------------------------------------------
-- 01 Mar 2011	JC	RFC6563	1	Procedure created
-- 17 Sep 2012	KR	R11988	2	return KindCode as well.
-- 26 Sep 2012	SF	R11988	3	return discover source id
-- 02 Jun 2015  SW      R45551  4       Remove DiscoverSourceId  

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
	RC.CITEDPRIORARTID			as CitedPriorArtKey,
	RC.SEARCHREPORTID			as SearchReportKey,
	ltrim(S.COUNTRYCODE + ' '+ coalesce(" +
	dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','TITLE',null,'S',@sLookupCulture,@pbCalledFromCentura) + "," +
	dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','CITATION',null,'S',@sLookupCulture,@pbCalledFromCentura) + "," +
	dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'S',@sLookupCulture,@pbCalledFromCentura) + ")) as DisplayDescription," +
	dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','DESCRIPTION',null,'S',@sLookupCulture,@pbCalledFromCentura)	
			 +" as Description,			
	"+dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','CITATION',null,'S',@sLookupCulture,@pbCalledFromCentura)	
			 +" as Citation,			
	cast(isnull(S.PATENTRELATED,0) as bit)	as IsIPDocument,
	S.OFFICIALNO				as OfficialNumber,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName,
	"+dbo.fn_SqlTranslatedColumn('SEARCHRESULTS','TITLE',null,'S',@sLookupCulture,@pbCalledFromCentura)	
			 +" as Title,
	cast(isnull(S.ISSOURCEDOCUMENT,0) as bit)	as IsSourceDocument,
	RC.LOGDATETIMESTAMP			as LastModifiedDate
	from REPORTCITATIONS RC
	join SEARCHRESULTS S		on (S.PRIORARTID = RC.CITEDPRIORARTID)
	left join COUNTRY C			on (C.COUNTRYCODE = S.COUNTRYCODE)
	where RC.SEARCHREPORTID = @pnPriorArtKey
	order by Description, Citation, OfficialNumber"
	
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

Grant execute on dbo.prw_ListPriorArts to public
GO