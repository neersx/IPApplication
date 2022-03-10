-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateMarginProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateMarginProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateMarginProfile.'
	Drop procedure [dbo].[naw_UpdateMarginProfile]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateMarginProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateMarginProfile
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory	
	@pnSequence			int,		-- Mandatory	
	@psWIPCategoryCode		nvarchar(3)	= null,
	@psWIPTypeCode			nvarchar(6)	= null,	
	@pnMarginProfileKey		int		= null,	
	@psOldWIPCategoryCode		nvarchar(3)	= null,
	@psOldWIPTypeCode		nvarchar(6)	= null,	
	@pnOldMarginProfileKey		int		= null,	
	@pbIsWIPCategoryCodeInUse	bit		= 0,
	@pbIsWIPTypeCodeInUse		bit		= 0,
	@pbIsMarginProfileKeyInUse	bit		= 0
)
as
-- PROCEDURE:	naw_UpdateMarginProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Name Margin Profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2010	MS	RFC3298	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @nRowCount		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin

	Set @sUpdateString = "Update NAMEMARGINPROFILE set "
	
	Set @sWhereString = @sWhereString+CHAR(10)+"
		NAMENO = @pnNameKey
		and NAMEMARGINSEQNO = @pnSequence"
		
	Set @sAnd = " and "	
	
	If @pbIsWIPCategoryCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"CATEGORYCODE = @psWIPCategoryCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"CATEGORYCODE = @psOldWIPCategoryCode"
		Set @sComma = ","
	End

	If @pbIsWIPTypeCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"WIPTYPEID = @psWIPTypeCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"WIPTYPEID = @psOldWIPTypeCode"
		Set @sComma = ","
	End
	
	If @pbIsMarginProfileKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"MARGINPROFILENO = @pnMarginProfileKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"MARGINPROFILENO = @pnOldMarginProfileKey"
	End
	
	Set @sSQLString = @sUpdateString + @sWhereString	
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnNameKey			int,
				@pnSequence			int,
				@psWIPCategoryCode		nvarchar(3),
				@psWIPTypeCode			nvarchar(6),
				@pnMarginProfileKey		int,				
				@psOldWIPCategoryCode		nvarchar(3),
				@psOldWIPTypeCode		nvarchar(6),
				@pnOldMarginProfileKey		int',
				@pnNameKey	 		= @pnNameKey,
				@pnSequence	 		= @pnSequence,				
				@psWIPCategoryCode		= @psWIPCategoryCode,
				@psWIPTypeCode			= @psWIPTypeCode,
				@pnMarginProfileKey		= @pnMarginProfileKey,
				@psOldWIPCategoryCode		= @psOldWIPCategoryCode,
				@psOldWIPTypeCode		= @psOldWIPTypeCode,
				@pnOldMarginProfileKey		= @pnOldMarginProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateMarginProfile to public
GO
