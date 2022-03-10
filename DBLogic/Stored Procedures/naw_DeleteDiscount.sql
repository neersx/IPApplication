-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_DeleteDiscount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_DeleteDiscount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_DeleteDiscount.'
	Drop procedure [dbo].[naw_DeleteDiscount]
End
Print '**** Creating Stored Procedure dbo.naw_DeleteDiscount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_DeleteDiscount
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnDiscountId			int,		-- Mandatory
	@pdtLogDateTimeStamp		datetime	= null
)
as
-- PROCEDURE:	naw_DeleteDiscount
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Name Disocunt from DISCOUNT table.
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 16 Feb 2010	MS	RFC8607		1	Procedure created
-- 14 Jun 2012	KR	RFC12005	2	added CASETYPE and WIPCODE to the delete logic
-- 01 Jun 2015	MS	R35907	        3	used logDateTimeStamp instead of old parameters

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
	Set @sDeleteString = "Delete from DISCOUNT 
			where NAMENO = @pnNameKey 
			and DISCOUNTID = @pnDiscountId
                        and (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP is null and @pdtLogDateTimeStamp is null))" 
	
	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
				@pnNameKey			int,
				@pnDiscountId			int,
				@pdtLogDateTimeStamp            datetime',
				@pnNameKey			= @pnNameKey,
				@pnDiscountId			= @pnDiscountId,
				@pdtLogDateTimeStamp            = @pdtLogDateTimeStamp
End

Return @nErrorCode
GO

Grant execute on dbo.naw_DeleteDiscount to public
GO
