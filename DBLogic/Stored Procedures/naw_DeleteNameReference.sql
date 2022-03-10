-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteNameReference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteNameReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteNameReference.'
	Drop procedure [dbo].[naw_DeleteNameReference]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteNameReference...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_DeleteNameReference
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int = null,		-- Mandatory
	@psAlias			nvarchar(30), -- Mandatory
	@psAliasTypeKey		nvarchar(2),  -- Mandatory
	@psOldAlias			nvarchar(30) = null, -- Mandatory
	@psOldAliasTypeKey		nvarchar(2) = null  -- Mandatory
)
as
-- PROCEDURE:	naw_DeleteNameReference
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Name Reference(Name Alias from NameAlias table).
-- MODIFICATIONS :
-- Date		    Who	    Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Oct 2008	PS	    RFC6461	1	    Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from NAMEALIAS where NAMENO = @pnNameKey and ALIASTYPE = @psAliasTypeKey and ALIAS = @psAlias"

	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnNameKey			int,
			@psAliasTypeKey		nvarchar(2),
			@psAlias			nvarchar(30),
			@psOldAliasTypeKey	nvarchar(2),
			@psOldAlias			nvarchar(30)',
			@pnNameKey	 		= @pnNameKey,
			@psAliasTypeKey	 	= @psAliasTypeKey,
			@psAlias	 		= @psAlias,
			@psOldAliasTypeKey	= @psOldAliasTypeKey,
			@psOldAlias	 		= @psOldAlias
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteNameReference to public
GO
