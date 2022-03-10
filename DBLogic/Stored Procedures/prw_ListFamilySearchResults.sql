-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_ListFamilySearchResults
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_ListFamilySearchResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_ListFamilySearchResults.'
	Drop procedure [dbo].[prw_ListFamilySearchResults]
End
Print '**** Creating Stored Procedure dbo.prw_ListFamilySearchResults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_ListFamilySearchResults
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnPriorArtKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_ListFamilySearchResults
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Family Prior Art Search Result for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Feb 2011	JC		RFC6563	1	Procedure created

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
	FS.PRIORARTID			as PriorArtKey,
	FS.FAMILY			as FamilyCode,
	"+dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null,'CF',@sLookupCulture,@pbCalledFromCentura)
		+ " as FamilyTitle,
	FS.LOGDATETIMESTAMP		as LastModifiedDate
	from FAMILYSEARCHRESULT FS
	join CASEFAMILY CF		on (CF.FAMILY = FS.FAMILY)
	where FS.PRIORARTID = @pnPriorArtKey
	order by FS.FAMILY"
	
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

Grant execute on dbo.prw_ListFamilySearchResults to public
GO