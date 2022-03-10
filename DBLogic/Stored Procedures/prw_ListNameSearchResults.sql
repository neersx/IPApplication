-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListNameSearchResults
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListNameSearchResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListNameSearchResults.'
	Drop procedure [dbo].[prw_ListNameSearchResults]
End
Print '**** Creating Stored Procedure dbo.prw_ListNameSearchResults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListNameSearchResults
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_ListNameSearchResults
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Names Prior Art Search Result for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	---------------------------------------
-- 28 Feb 2011	JC	RFC6563	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

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
	NS.PRIORARTID		as PriorArtKey,
	NS.NAMENO		as NameKey,
	N.NAMECODE		as NameCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, default) as DisplayName,
	NS.NAMETYPE		as NameTypeCode,
	"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)
		+ " as NameTypeDescription,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName,
	NS.LOGDATETIMESTAMP	as LastModifiedDate
	from NAMESEARCHRESULT NS
	join NAME N		on (N.NAMENO = NS.NAMENO)
	left join NAMETYPE NT	on (NT.NAMETYPE = NS.NAMETYPE)
	left join ADDRESS A	on (A.ADDRESSCODE = N.STREETADDRESS)
	left join COUNTRY C	on (C.COUNTRYCODE = A.COUNTRYCODE)
	where NS.PRIORARTID = @pnPriorArtKey
	order by DisplayName"
	
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

Grant execute on dbo.prw_ListNameSearchResults to public
GO