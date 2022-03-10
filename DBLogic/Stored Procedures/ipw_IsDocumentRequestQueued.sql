-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_IsDocumentRequestQueued
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_IsDocumentRequestQueued]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_IsDocumentRequestQueued.'
	Drop procedure [dbo].[ipw_IsDocumentRequestQueued]
End
Print '**** Creating Stored Procedure dbo.ipw_IsDocumentRequestQueued...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_IsDocumentRequestQueued
(
	@pbYes						bit		= null output,	
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		 = 0,
	@pnDocumentRequestKey		int		 -- Mandatory
)
as
-- PROCEDURE:	ipw_IsDocumentRequestQueued
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Check to see if Activity Request has already been inserted for the corresponding Document Request

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 MAR 2008	SF	RFC6387	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @pbYes = 0
	Set @sSQLString = "
		Select @pbYes = 1
		from ACTIVITYREQUEST 
		where REQUESTID = @pnDocumentRequestKey"
		
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDocumentRequestKey	int,
				@pbYes					bit output',
				@pnDocumentRequestKey	= @pnDocumentRequestKey,
				@pbYes					= @pbYes output

	
End


If @nErrorCode = 0
and @pbCalledFromCentura = 0
Begin
	-- publish to .net dataaccess
	Select isnull(@pbYes,0)
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_IsDocumentRequestQueued to public
GO
