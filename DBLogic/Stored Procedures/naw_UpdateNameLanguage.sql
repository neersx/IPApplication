-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateNameLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameLanguage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameLanguage.'
	Drop procedure [dbo].[naw_UpdateNameLanguage]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateNameLanguage
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int = null,		-- Mandatory
	@pnSequence			int = null,		-- mandatory
	@pnLanguageCode			int = null,		-- mandatory
	@psPropertyType			nvarchar(2) = null,
	@psActionCode			nvarchar(4) = null

)
as
-- PROCEDURE:	naw_UpdateNameLanguage
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update NameLanguage if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Nov 2011	KR	R9095	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)



-- Initialise variables
Set @nRowCount = 1 -- anything not zero
Set @nErrorCode = 0


If @nErrorCode = 0
Begin

	Set @sSQLString = 
	"Update NAMELANGUAGE 
	set LANGUAGE	   = @pnLanguageCode, 
	    PROPERTYTYPE   = @psPropertyType,
	    ACTION	   = @psActionCode
	where NAMENO  = @pnNameKey 
	and SEQUENCENO  = @pnSequence"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@pnSequence		int,
			@pnLanguageCode		int,
			@psPropertyType		nvarchar(2),
			@psActionCode		nvarchar(4)',
			@pnNameKey	 	= @pnNameKey,
			@pnSequence		= @pnSequence,
			@pnLanguageCode		= @pnLanguageCode,			
			@psPropertyType		= @psPropertyType,
			@psActionCode		= @psActionCode
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameLanguage to public
GO
