-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteMarginProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteMarginProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteMarginProfile.'
	Drop procedure [dbo].[naw_DeleteMarginProfile]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteMarginProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteMarginProfile
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnSequence			int,		-- Mandatory	
	@psOldWIPCategoryCode		nvarchar(3)	= null,
	@psOldWIPTypeCode		nvarchar(6)	= null,
	@pnOldMarginProfileKey		int		= null,	
	@pbIsWIPCategoryCodeInUse	bit		= 0,
	@pbIsWIPTypeCodeInUse		bit		= 0,
	@pbIsMarginProfileKeyInUse	bit		= 0
)
as
-- PROCEDURE:	naw_DeleteMarginProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Name Margin Profile from NAMEMARGINPROFILE table.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2010	MS	RFC3298	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from NAMEMARGINPROFILE	 
			where NAMENO = @pnNameKey 
			and NAMEMARGINSEQNO = @pnSequence" 

	Set @sAnd = " and "	
	
	If @pbIsWIPCategoryCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"CATEGORYCODE = @psOldWIPCategoryCode"
	End

	If @pbIsWIPTypeCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"WIPTYPEID = @psOldWIPTypeCode"
	End
	
	If @pbIsMarginProfileKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"MARGINPROFILENO = @pnOldMarginProfileKey"
	End
	
	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
				@pnNameKey			int,
				@pnSequence			int,
				@psOldWIPCategoryCode		nvarchar(3),
				@psOldWIPTypeCode		nvarchar(6),
				@pnOldMarginProfileKey		int',
				@pnNameKey			= @pnNameKey,
				@pnSequence			= @pnSequence,
				@psOldWIPCategoryCode		= @psOldWIPCategoryCode,
				@psOldWIPTypeCode		= @psOldWIPTypeCode,
				@pnOldMarginProfileKey		= @pnOldMarginProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteMarginProfile to public
GO
