-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_GetCaseSearchResultDetail
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_GetCaseSearchResultDetail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_GetCaseSearchResultDetail.'
	Drop procedure [dbo].[prw_GetCaseSearchResultDetail]
End
Print '**** Creating Stored Procedure dbo.prw_GetCaseSearchResultDetail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.prw_GetCaseSearchResultDetail
(
	@pnUserIdentityId	int,	-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	prw_GetCaseSearchResultDetail
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get the detail about a Case

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 01 Mar 2011	JC		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	C.IRN			as CaseReference,
	C.CURRENTOFFICIALNO	as CurrentOfficialNumber,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'CT',@sLookupCulture,@pbCalledFromCentura)
		+ " as CountryName
	from CASES C
	left join COUNTRY CT	on (CT.COUNTRYCODE = C.COUNTRYCODE)
	where C.CASEID = @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura	bit,
			@pnCaseKey		int',
			@pnUserIdentityId	= @pnUserIdentityId,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnCaseKey		= @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.prw_GetCaseSearchResultDetail to public
GO