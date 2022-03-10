-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListNameVariants
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameVariants]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameVariants.'
	Drop procedure [dbo].[naw_ListNameVariants]
	Print '**** Creating Stored Procedure dbo.naw_ListNameVariants...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_ListNameVariants
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey 		int,		-- Mandatory
	@psPropertyTypeCode 	nchar(1) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_ListNameVariants
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of name variants.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2005  TM	RFC3144	1	Procedure created

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
	Select 	NAMEVARIANTNO	as NameVariantKey, 
		NAMEVARIANT 	as NameVariant
	from NAMEVARIANT  
	where NAMENO = @pnNameKey"+
	CASE	WHEN @psPropertyTypeCode is not null
		THEN char(10)+"and PROPERTYTYPE  = @psPropertyTypeCode"
	END+char(10)+	 
	"Order by DISPLAYSEQUENCENO"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psPropertyTypeCode	nchar(1)',
					  @pnNameKey		= @pnNameKey,
					  @psPropertyTypeCode	= @psPropertyTypeCode
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameVariants to public
GO
