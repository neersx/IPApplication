-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListActions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListActions.'
	Drop procedure [dbo].[acw_ListActions]
	Print '**** Creating Stored Procedure dbo.acw_ListActions...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListActions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psCountryCode	nvarchar(3) = null, -- these three need to be passed together to get valid actions.
	@psPropertyType nvarchar(1) = null,
	@psCaseType		nvarchar(1) = null
)
AS
-- PROCEDURE:	acw_ListActions
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available actions or valid actions.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26-10-2009	AT	RFC3605	1	Procedure created.
-- 03-May-2010	AT	RFC9092	2	Use translated column.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
--Set 	@pnRowCount	 = 0


If (@nErrorCode = 0 and (@psCountryCode is null or @psPropertyType is null or @psCaseType is null))
Begin
	Set @sSQLString = "
		SELECT
		ACTION as 'ActionKey',
		" + dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,null,@sLookupCulture,@pbCalledFromCentura) + " as 'ActionName'
		from ACTIONS"

	exec @nErrorCode = sp_executesql @sSQLString

End
Else If (@nErrorCode = 0)
Begin

	Set @sSQLString = "
			SELECT
			VA.ACTION as 'ActionKey',
			" + dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'VA',@sLookupCulture,@pbCalledFromCentura) + " as 'ActionName'
			from VALIDACTION VA
			where VA.COUNTRYCODE = @psCountryCode
			and VA.PROPERTYTYPE = @psPropertyType
			and VA.CASETYPE = @psCaseType"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@psCountryCode nvarchar(3),
						@psPropertyType nvarchar(1),
						@psCaseType nvarchar(1)',
						@psCountryCode=@psCountryCode,
						@psPropertyType=@psPropertyType,
						@psCaseType=@psCaseType
End


Return @nErrorCode
GO

Grant execute on dbo.acw_ListActions to public
GO