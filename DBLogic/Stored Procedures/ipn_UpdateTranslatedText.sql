-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_UpdateTranslatedText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_UpdateTranslatedText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_UpdateTranslatedText.'
	Drop procedure [dbo].[ipn_UpdateTranslatedText]
End
Print '**** Creating Stored Procedure dbo.ipn_UpdateTranslatedText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipn_UpdateTranslatedText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(5), 	-- the language of the text to be saved
	@psTableName		nvarchar(100),	-- Mandatory
	@psTIDColumnName	nvarchar(100),	-- Mandatory
	@psText			ntext		= null,
	@pnTID			int 		= null 	output
)
as
-- PROCEDURE:	ipn_UpdateTranslatedText
-- VERSION:	2
-- SCOPE:	WorkBenches
-- DESCRIPTION:	Updates translated text. 
--		If no TID or TRANSLATEDTEXT does not exist, a new translation will be inserted.
--		Assumes appropriate concurrency checking is already done by calling code.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 May 2008	AT	RFC5438	1	Procedure created
-- 30 OCT 2010	ASH	RFC9788 2       Update LONGTEXT column if datalength of @psText is greater than 508.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(2000)

-- Initialise variables
Set @nErrorCode = 0

If (@nErrorCode = 0)
Begin
	If @pnTID is not null and exists(Select 1 From TRANSLATEDTEXT Where TID = @pnTID and CULTURE = @psCulture)
	Begin
		-- update the row
		If (datalength(@psText) <= 508)
		Begin
			Update TRANSLATEDTEXT
			Set SHORTTEXT = @psText,
			LONGTEXT = null
			Where TID = @pnTID
			and CULTURE = @psCulture
		End
		Else
		Begin
			Update TRANSLATEDTEXT
			Set LONGTEXT = @psText,
			SHORTTEXT = null
			Where TID = @pnTID
			and CULTURE = @psCulture
		End
	End
	Else
	Begin
		-- insert a new row for the specified culture.
		exec @nErrorCode = ipn_InsertTranslatedText	@pnUserIdentityId=@pnUserIdentityId,
								@psCulture=@psCulture,
								@psTableName=@psTableName,
								@psTIDColumnName=@psTIDColumnName,
								@psText=@psText,
								@pnTID=@pnTID output
	End
End

Set @nErrorCode = @@ERROR

Return @nErrorCode
GO

Grant execute on dbo.ipn_UpdateTranslatedText to public
GO
