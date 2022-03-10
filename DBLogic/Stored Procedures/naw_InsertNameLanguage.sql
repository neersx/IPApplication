-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertNameLanguage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameLanguage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameLanguage.'
	Drop procedure [dbo].[naw_InsertNameLanguage]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameLanguage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertNameLanguage
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int = null,		-- Mandatory
	@pnSequence		int,			-- Mandatory
	@pnLanguageCode		int,			-- Mandatory
	@psPropertyType		nvarchar(2)	= null,	-- the Property Type the Alias applies to
	@psActionCode		nvarchar(4)	= null
)
as
-- PROCEDURE:	naw_InsertNameLanguage
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Name Language

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------  
-- 17 Nov 2011	KR	R9095	1	Procedure created
-- 23 Feb 2017	MF	70708	2	If no rows exist in NAMELANGUAGE then the SEQUENCENO is not being set.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0


If @nErrorCode = 0
Begin
		if @pnSequence is null
			Select @pnSequence = max(SEQUENCENO) + 1 from NAMELANGUAGE where NAMENO=@pnNameKey
			
		Set @sSQLString = "Insert into NAMELANGUAGE ( NAMENO, SEQUENCENO, LANGUAGE, PROPERTYTYPE, ACTION) 
				   values (@pnNameKey, isnull(@pnSequence,1), @pnLanguageCode,@psPropertyType, @psActionCode)" 
	
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

Grant execute on dbo.naw_InsertNameLanguage to public
GO
