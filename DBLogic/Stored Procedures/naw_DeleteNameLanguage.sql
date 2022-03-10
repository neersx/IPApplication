-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteNameLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteNameLanguage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteNameLanguage.'
	Drop procedure [dbo].[naw_DeleteNameLanguage]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteNameLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_DeleteNameLanguage
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int = null,		-- Mandatory
	@pnSequence			int = null
)
as
-- PROCEDURE:	naw_DeleteNameLanguage
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Name Language
-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Nov 2011	KR	R9095	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from NAMELANGUAGE where NAMENO = @pnNameKey and SEQUENCENO = @pnSequence"

	exec @nErrorCode=sp_executesql @sDeleteString,
			N'
			@pnNameKey			int,
			@pnSequence			int',
			@pnNameKey	 		= @pnNameKey,
			@pnSequence	 		= @pnSequence
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteNameLanguage to public
GO
