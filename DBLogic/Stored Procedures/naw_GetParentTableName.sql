-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_GetParentTableName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_GetParentTableName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_GetParentTableName.'
	Drop procedure [dbo].[naw_GetParentTableName]
	Print '**** Creating Stored Procedure dbo.naw_GetParentTableName...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_GetParentTableName
(	
	@psParentTableName		nvarchar(50)		OUTPUT,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int		-- Mandatory
)
AS
-- PROCEDURE:	naw_GetParentTableName
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns ParentTableName on the basis of Namekey. Used in case there are no Attribute list 
-- returned on the Attribute Maintenance window
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02-Dec-2009	DV		RFC100088	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(500)

Set	@nErrorCode      = 0

If (@nErrorCode = 0)
Begin
	-- Return attributes for the case
	Set @sSQLString = "Select @psParentTableName = CASE 	when exists(Select 1 from NAME N
				join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO = N.NAMENO and NTC.NAMETYPE = '~LD')
				where N.NAMENO = @pnNameKey
				AND NTC.ALLOW = 1) then 'NAME/LEAD'
				WHEN N.USEDASFLAG&2=2 THEN 'EMPLOYEE'
		        WHEN N.USEDASFLAG&1=1 THEN 'INDIVIDUAL'
		        ELSE 'ORGANISATION'
      	END 
	    from NAME N where N.NAMENO = @pnNameKey"


	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@psParentTableName	nvarchar(101) OUTPUT,
						@pnNameKey	int',
						@psParentTableName	= @psParentTableName OUTPUT,
						@pnNameKey	= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.naw_GetParentTableName to public
GO
