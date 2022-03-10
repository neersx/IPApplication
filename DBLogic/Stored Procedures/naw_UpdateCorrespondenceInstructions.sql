-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateCorrespondenceInstructions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateCorrespondenceInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateCorrespondenceInstructions.'
	Drop procedure [dbo].[naw_UpdateCorrespondenceInstructions]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateCorrespondenceInstructions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_UpdateCorrespondenceInstructions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@psTextTypeKey		nvarchar(2),	-- Mandatory	
	@ptText			ntext		= null,
	@pdtLastModified	datetime	= null	
)
as
-- PROCEDURE:	naw_UpdateCorrespondenceInstructions
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Correspondence Instructions if the underlying values are as expected.


-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Aug 2009	MS	RFC8288	1	Procedure created
-- 12 Sep 2013  MS      DR913   2       Check LogDateTimeStamp rather than old text

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
	
-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @psTextTypeKey = "-1"
	Begin
		Set @sSQLString = " 
		Update IPNAME
		SET CORRESPONDENCE = @ptText
		Where NAMENO	 = @pnNameKey
		and (LOGDATETIMESTAMP = @pdtLastModified or (LOGDATETIMESTAMP is null and @pdtLastModified is null))"
	End
	Else 
	Begin	
		If exists (Select 1 from NAMETEXT where NAMENO	 = @pnNameKey and TEXTTYPE = @psTextTypeKey)
		Begin
			Set @sSQLString = " 
			Update 	NAMETEXT
			Set	TEXT 	 = @ptText
			Where	NAMENO	 = @pnNameKey
			and	TEXTTYPE = @psTextTypeKey	
			and (LOGDATETIMESTAMP = @pdtLastModified or (LOGDATETIMESTAMP is null and @pdtLastModified is null))"
		End	
		Else 
		begin
			Set @sSQLString = " Insert into NAMETEXT (NAMENO, TEXTTYPE, TEXT)
			values (@pnNameKey, @psTextTypeKey, @ptText)"			
		End		
	End

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey		int,
			  @psTextTypeKey	nvarchar(2),
			  @ptText		ntext,					 
			  @pdtLastModified 	datetime',
			  @pnNameKey		= @pnNameKey,
			  @psTextTypeKey	= @psTextTypeKey,
			  @ptText		= @ptText,					
			  @pdtLastModified	= @pdtLastModified
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateCorrespondenceInstructions to public
GO
