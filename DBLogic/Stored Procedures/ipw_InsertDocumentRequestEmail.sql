-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertDocumentRequestEmail									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertDocumentRequestEmail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertDocumentRequestEmail.'
	Drop procedure [dbo].[ipw_InsertDocumentRequestEmail]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertDocumentRequestEmail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertDocumentRequestEmail
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestEmailKey	int		= null output,
	@pnDocumentRequestKey		int		= null,
	@pbIsMain			bit,		--Mandatory
	@psEmail			nvarchar(50)	= null
)
as
-- PROCEDURE:	ipw_InsertDocumentRequestEmail
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert DocumentRequest Email

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Mar 2007	PG	RFC3646	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sInsertString 		nvarchar(4000)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		Set @sInsertString ="Insert into DOCUMENTREQUESTEMAIL(
			REQUESTID,
			ISMAIN,
			EMAIL
			)
			values (
			@pnDocumentRequestKey,
			@pbIsMain,
			@psEmail
			)
			Set @pnDocumentRequestEmailKey = SCOPE_IDENTITY()"
			
			exec @nErrorCode=sp_executesql @sInsertString,
				N'@pnDocumentRequestEmailKey	int output,
				@pnDocumentRequestKey		int,
				@pbIsMain			bit,
				@psEmail			nvarchar(50)',
				@pnDocumentRequestEmailKey	= @pnDocumentRequestEmailKey,
				@pnDocumentRequestKey	 	= @pnDocumentRequestKey,
				@pbIsMain	 		= @pbIsMain,
				@psEmail			= @psEmail

	-- Publish the generated key to update the data adapter
	Select @pnDocumentRequestEmailKey as DocumentRequestEmailKey

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertDocumentRequestEmail to public
GO