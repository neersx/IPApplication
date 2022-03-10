-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertMarginProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertMarginProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertMarginProfile.'
	Drop procedure [dbo].[naw_InsertMarginProfile]
End
Print '**** Creating Stored Procedure dbo.naw_InsertMarginProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_InsertMarginProfile
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory	
	@psWIPCategoryCode		nvarchar(3),	-- Mandatory	
	@psWIPTypeCode			nvarchar(6)	= null,
	@pnMarginProfileKey		int		= null
)
as
-- PROCEDURE:	naw_InsertMarginProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Name Margin Profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2010	MS	RFC3298	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @nSequence		smallint

-- Initialise variables
Set @nErrorCode = 0
Set @nSequence	= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nSequence = MAX(NAMEMARGINSEQNO) + 1 
			from NAMEMARGINPROFILE
			where NAMENO = @pnNameKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nSequence	int		output,
				@pnNameKey	int',
				@nSequence	= @nSequence	output,
				@pnNameKey	= @pnNameKey
End


If @nErrorCode = 0
Begin
		Set @sSQLString = "Insert into NAMEMARGINPROFILE (
					NAMENO,
					NAMEMARGINSEQNO, 
					CATEGORYCODE,
					WIPTYPEID, 
					MARGINPROFILENO) 
				   values (									
					@pnNameKey,
					ISNULL(@nSequence,0),
					@psWIPCategoryCode,
					@psWIPTypeCode,
					@pnMarginProfileKey
					)" 
	
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int,				
				@nSequence		smallint,
				@psWIPCategoryCode	nvarchar(3),
				@psWIPTypeCode		nvarchar(6),
				@pnMarginProfileKey	int',
				@pnNameKey	 	= @pnNameKey,
				@nSequence		= @nSequence,
				@psWIPCategoryCode	= @psWIPCategoryCode,
				@psWIPTypeCode		= @psWIPTypeCode,
				@pnMarginProfileKey	= @pnMarginProfileKey
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertMarginProfile to public
GO
