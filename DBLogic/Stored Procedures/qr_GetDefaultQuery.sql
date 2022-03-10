-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.qr_GetDefaultQuery 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_GetDefaultQuery ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_GetDefaultQuery.'
	Drop procedure [dbo].[qr_GetDefaultQuery ]
	Print '**** Creating Stored Procedure dbo.qr_GetDefaultQuery ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.qr_GetDefaultQuery 
(
	@pnQueryKey		int		output,
	@psCulture		nvarchar(10) 	= null,
	@pnUserIdentityId	int,		-- Mandatory	
	@pnQueryContextKey	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	qr_GetDefaultQuery 
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	InPro.net
-- DESCRIPTION:	Locates the best default query for the user and the context provided.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 09 Mar 2004  TM	RFC1250	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)

Declare @nErrorCode		int

Set 	@nErrorCode 		= 0

-- Populating the dataset

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select @pnQueryKey =   
	-- 'IsDefault' column is 1 for the query that is the best default for the user. 	
	SUBSTRING(
	MAX(
	-- For preference choose the QueryDefault row with the matching ContextID and UserIdentityID.
	CASE WHEN (QD.IDENTITYID = @pnUserIdentityId) THEN '10' END + 
	-- Otherwise, choose the row with the matching ContextID and null UserIdentityID.
	CASE WHEN (QD.IDENTITYID IS NULL) 		 THEN '01' END +   
	CAST (QD.QUERYID as varchar(11))),3,10) 
	from QUERYDEFAULT QD 	
	WHERE QD.CONTEXTID = @pnQueryContextKey
	and  (QD.IDENTITYID = @pnUserIdentityId or
	      QD.IDENTITYID is null)"	

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryKey		int			OUTPUT,
					  @pnQueryContextKey	int,
					  @pnUserIdentityId	int',
					  @pnQueryKey		= @pnQueryKey		OUTPUT,					
					  @pnQueryContextKey	= @pnQueryContextKey,
					  @pnUserIdentityId	= @pnUserIdentityId
					 
End


Return @nErrorCode
GO

Grant execute on dbo.qr_GetDefaultQuery  to public
GO


