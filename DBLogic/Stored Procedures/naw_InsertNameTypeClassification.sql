If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameTypeClassification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameTypeClassification.'
	Drop procedure [dbo].[naw_InsertNameTypeClassification]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameTypeClassification...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_InsertNameTypeClassification
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,	-- Mandatory.
	@psNameTypeKey		nvarchar(3),	-- Mandatory.
	@pbIsSelected		bit			= 1
)
as
-- PROCEDURE:	naw_InsertNameTypeClassification
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert NameTypeClassification.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 10 Jun 2008	LP	RFC4342	1	Procedure created
-- 07 Jan 2010  PA	RFC100103   Updated for the Lead name type.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
if exists (SELECT * FROM NAMETYPECLASSIFICATION WHERE NAMENO = @pnNameKey and NAMETYPE = @psNameTypeKey)
	Begin
	 DELETE FROM NAMETYPECLASSIFICATION WHERE NAMENO = @pnNameKey and NAMETYPE = @psNameTypeKey
	End
	Set @sInsertString = "Insert into NAMETYPECLASSIFICATION("
	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"NAMENO,NAMETYPE,ALLOW"
	Set @sValuesString = @sValuesString+CHAR(10)+"@pnNameKey,@psNameTypeKey,@pbIsSelected"
	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"
	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey		int,
			@psNameTypeKey		nvarchar(3),
			@pbIsSelected		bit',
			@pnNameKey	 = @pnNameKey,
			@psNameTypeKey	 = @psNameTypeKey,
			@pbIsSelected	= @pbIsSelected
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertNameTypeClassification to public
GO