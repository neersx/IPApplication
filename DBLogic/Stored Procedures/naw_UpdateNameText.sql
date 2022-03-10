-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateNameText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameText.'
	Drop procedure [dbo].[naw_UpdateNameText]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateNameText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@psTextTypeKey		nvarchar(2),	-- Mandatory
	@ptText			ntext		= null,
	@ptOldText		ntext		= null	
)
as
-- PROCEDURE:	naw_UpdateNameText
-- VERSION:	4
-- DESCRIPTION:	Update a NameText if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Oct 2004	TM	RFC1811	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	update 	NAMETEXT
	set	TEXT 	 = @ptText
	where	NAMENO	 = @pnNameKey
	and	TEXTTYPE = @psTextTypeKey	
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and 	dbo.fn_IsNtextEqual(TEXT, @ptOldText) = 1"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psTextTypeKey	nvarchar(2),
					  @ptText		ntext,					 
					  @ptOldText 		ntext',
					  @pnNameKey		= @pnNameKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @ptText		= @ptText,					
					  @ptOldText		= @ptOldText
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameText to public
GO
