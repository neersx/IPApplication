If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameTypeClassification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameTypeClassification.'
	Drop procedure [dbo].naw_UpdateNameTypeClassification
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameTypeClassification...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateNameTypeClassification
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@psNameTypeKey		nvarchar(3),	-- Mandatory
	@pbIsSelected		bit,		-- Mandatory
	@pbOldIsSelected	bit,		-- Mandatory
	@pbIsIsSelectedInUse	bit	 = 0
)
as
-- PROCEDURE:	naw_UpdateNameTypeClassification
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update NameType if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 13 Jun 2008	LP	RFC4342	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)
Declare @nRowCount		int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "
set @sValuesString = "Values("
Set @nRowCount = 0

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update NAMETYPECLASSIFICATION
			   set "
	Set @sWhereString = @sWhereString + "ISNULL(NAMENO,0) = @pnNameKey AND NAMETYPE = @psNameTypeKey"

	If @pbIsIsSelectedInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+"ALLOW = @pbIsSelected"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ISNULL(ALLOW,0) = @pbOldIsSelected"
	End

	Set @sSQLString = @sUpdateString + @sWhereString
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey		int,
			@psNameTypeKey		nvarchar(3),
			@pbIsSelected		int,
			@pbOldIsSelected	int',
			@pnNameKey	 = @pnNameKey,
			@psNameTypeKey	 = @psNameTypeKey,
			@pbIsSelected	 = @pbIsSelected,
			@pbOldIsSelected = @pbOldIsSelected
			
	Set @nRowCount = @@RowCount
	
	If @nErrorCode = 0 and @nRowCount = 0
	Begin
			Set @sSQLString = "Insert into NAMETYPECLASSIFICATION(NAMENO,NAMETYPE,ALLOW)"	+char(10)+
					"Select @pnNameKey, @psNameTypeKey, @pbIsSelected"	+char(10)+
					"from NAMETYPECLASSIFICATION"				+char(10)+
					"where NAMENO = @pnNameKey"				+char(10)+
					"and NAMETYPE = @psNameTypeKey"			+char(10)+
					"having Count(*) = 0"
			
			
			exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
					@pnNameKey		int,
					@psNameTypeKey		nvarchar(3),
					@pbIsSelected		bit',
					@pnNameKey	= @pnNameKey,
					@psNameTypeKey	= @psNameTypeKey,
					@pbIsSelected	= @pbIsSelected
	End		
			

End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameTypeClassification to public
GO