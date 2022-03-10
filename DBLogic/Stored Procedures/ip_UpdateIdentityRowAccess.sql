-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UpdateIdentityRowAccess
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateIdentityRowAccess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateIdentityRowAccess.'
	Drop procedure [dbo].[ip_UpdateIdentityRowAccess]
	Print '**** Creating Stored Procedure dbo.ip_UpdateIdentityRowAccess...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_UpdateIdentityRowAccess
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psIdentityKey		nvarchar(11)	= null,
	@psProfileKey		nvarchar(30)	= null,
	@psProfileName		nvarchar(30)	= null,
	@psOriginalProfileKey	nvarchar(30)	= null,
	@pbProfileKeyModified	bit 		= null,
	@pbProfileNameModified	bit 		= null
)
-- PROCEDURE:	ip_UpdateIdentityRowAccess
-- VERSION :	8
-- DESCRIPTION:	To change a user's to a Row Access Profile.
--		Only Administrator User can perform this operation.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17-OCT-2002  SF	1	Procedure created
-- 30-OCT-2002	SF	2	Change the way error is raised.
-- 13-DEC-2002	SF	5	Where statement was incorrect
-- 10-MAR-2003	JEK	6	RFC82 Localise stored procedure errors.
-- 10-Feb-2012	LP	7	RFC11542 Remove ISADMINISTATOR restriction.
--				This is now superceded by task security in Web version.
-- 15 Apr 2013	DV	8	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sAlertXML nvarchar(400)
Set @nErrorCode = 0

If @nErrorCode = 0
and @pbProfileKeyModified is not null
Begin

	If @psProfileKey is null
	Begin
		
		Exec @nErrorCode = dbo.ip_DeleteIdentityRowAccess 
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@psIdentityKey = @psIdentityKey,
			@psProfileKey = @psOriginalProfileKey

	End
	Else
	Begin

		Update 	IDENTITYROWACCESS 
		Set	ACCESSNAME = @psProfileKey,
			IDENTITYID = Cast(@psIdentityKey as int)
		Where	ACCESSNAME = @psOriginalProfileKey
		and	IDENTITYID = Cast(@psIdentityKey as int)

		Set @nErrorCode = @@ERROR	

	End
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateIdentityRowAccess to public
GO
