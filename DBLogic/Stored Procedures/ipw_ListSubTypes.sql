-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListSubTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListSubTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListSubTypes.'
	Drop procedure [dbo].[ipw_ListSubTypes]
	Print '**** Creating Stored Procedure dbo.ipw_ListSubTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListSubTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListSubTypes
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of SubTypes.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 08 Oct 2003  TM	1	Procedure created
-- 15 Sep 2004	JEK	2	RFC886	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	S.SUBTYPE 	as 'SubTypeKey',
		"+dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'SubTypeDescription'
	from	SUBTYPE S
	order by SubTypeDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListSubTypes to public
GO
