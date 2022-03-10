-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteNameText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteNameText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteNameText.'
	Drop procedure [dbo].[naw_DeleteNameText]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteNameText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteNameText
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@psTextTypeKey		nvarchar(2),	-- Mandatory
	@pdtLastModified	datetime	= null
)
as
-- PROCEDURE:	naw_DeleteNameText
-- VERSION:	3
-- DESCRIPTION:	Delete a NameText if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Oct 2004	TM	RFC1811	1	Procedure created
-- 02 Sep 2009	NG	RFC7465	2	Update EXTENDEDNAMEFLAG when Name Text of text type Extended Name is deleted.
-- 12 Sep 2013  MS      DR913   3       Check LogDateTimeStamp rather than old text

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
	delete NAMETEXT
	where	NAMENO	 = @pnNameKey
	and	TEXTTYPE = @psTextTypeKey	
	and     (LOGDATETIMESTAMP = @pdtLastModified or (LOGDATETIMESTAMP is null and @pdtLastModified is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @psTextTypeKey	nvarchar(2),
					  @pdtLastModified 	datetime',
					  @pnNameKey		= @pnNameKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @pdtLastModified	= @pdtLastModified
End

If @nErrorCode = 0 and @psTextTypeKey = 'N'
Begin
	If exists (select * from NAME N where N.NAMENO = @pnNameKey and N.EXTENDEDNAMEFLAG = 1)
	Begin
		Update NAME
		Set NAME.EXTENDEDNAMEFLAG = 0
		where NAME.NAMENO = @pnNameKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteNameText to public
GO
