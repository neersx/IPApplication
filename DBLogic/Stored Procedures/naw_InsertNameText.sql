-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertNameText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameText.'
	Drop procedure [dbo].[naw_InsertNameText]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameText...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_InsertNameText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@psTextTypeKey		nvarchar(2),	-- Mandatory
	@ptText			ntext		= null
)
as
-- PROCEDURE:	naw_InsertNameText
-- VERSION:	2
-- DESCRIPTION:	Insert a new NameText.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Oct 2004	TM	RFC1811	1	Procedure created
-- 02 Sep 2009	NG	RFC7465	2	Update EXTENDEDNAMEFLAG when name text of text type Extended Name is saved.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into NAMETEXT
		(NAMENO, 
		 TEXTTYPE, 		 
		 TEXT)
	values	(@pnNameKey,
		 @psTextTypeKey, 		
		 @ptText)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psTextTypeKey	nvarchar(2),					 
					  @ptText		ntext',
					  @pnNameKey		= @pnNameKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @ptText		= @ptText	

End

If @nErrorCode = 0 and @psTextTypeKey = 'N' and @ptText is not null
Begin
	If exists (select * from NAME N where N.NAMENO = @pnNameKey and 
				(N.EXTENDEDNAMEFLAG is null or N.EXTENDEDNAMEFLAG = 0))
	Begin
		Update NAME
		Set EXTENDEDNAMEFLAG = 1 
		where NAMENO = @pnNameKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertNameText to public
GO