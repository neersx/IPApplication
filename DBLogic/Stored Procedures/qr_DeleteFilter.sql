-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_DeleteFilter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_DeleteFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_DeleteFilter.'
	Drop procedure [dbo].[qr_DeleteFilter]
End
Print '**** Creating Stored Procedure dbo.qr_DeleteFilter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_DeleteFilter
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnFilterKey			int		-- Mandatory
)
as
-- PROCEDURE:	qr_DeleteFilter
-- VERSION:	1
-- DESCRIPTION:	Deletes the filter if it is not in use on any Queries.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC398	1	Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @bIsInUse		bit

-- Initialise variables
Set @nErrorCode 		= 0
Set @bIsInUse			= 0

-- Is the presentation in use?
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	select	@bIsInUse=1
	from	QUERY Q
	where	Q.FILTERID = @pnFilterKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@bIsInUse	int	output,
					  @pnFilterKey	int',
					  @bIsInUse	= @bIsInUse	output,
					  @pnFilterKey	= @pnFilterKey
End

If @nErrorCode = 0
and @bIsInUse = 0
Begin
	Set @sSQLString = " 
	delete	QUERYFILTER
	where	FILTERID = @pnFilterKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnFilterKey	int',
					  @pnFilterKey	= @pnFilterKey
End

Return @nErrorCode
GO

Grant execute on dbo.qr_DeleteFilter to public
GO
