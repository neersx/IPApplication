-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListNameInternalDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameInternalDetails ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameInternalDetails .'
	Drop procedure [dbo].[naw_ListNameInternalDetails]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameInternalDetails ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.naw_ListNameInternalDetails 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int		-- Mandatory
)
AS
-- PROCEDURE:	naw_ListNameInternalDetails
-- VERSION:	1
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Lists the internal details of the Name.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17-Mar-2010 ASH RFC5632 1   New Procedure	

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString			nvarchar(4000)
Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = " Select	NAMENO		as 'NameKey',
		DATEENTERED		as 'DateEntered',
		DATECHANGED		as 'DateChanged',
		[SOUNDEX]       as 'Soundex'
		FROM [NAME]
    WHERE NAMENO=@pnNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int',
					 @pnNameKey			= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameInternalDetails  to public
GO
