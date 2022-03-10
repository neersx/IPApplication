-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_GetNameSearchResultDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_GetNameSearchResultDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_GetNameSearchResultDetail.'
	Drop procedure [dbo].[prw_GetNameSearchResultDetail]
End
Print '**** Creating Stored Procedure dbo.prw_GetNameSearchResultDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_GetNameSearchResultDetail
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_GetNameSearchResultDetail
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Names Prior Art Search Result for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Feb 2011	JC		RFC6563	1	Procedure created

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
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName
	from NAME N
	left join ADDRESS A	on (A.ADDRESSCODE = N.STREETADDRESS)
	left join COUNTRY C	on (C.COUNTRYCODE = A.COUNTRYCODE)
	where N.NAMENO = @pnNameKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'
		@pnUserIdentityId	int,
		@pbCalledFromCentura	bit,
		@pnNameKey		int',
		@pnUserIdentityId	= @pnUserIdentityId,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnNameKey		= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_GetNameSearchResultDetail to public
GO