-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteDocumentRequestEmail									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteDocumentRequestEmail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteDocumentRequestEmail.'
	Drop procedure [dbo].[ipw_DeleteDocumentRequestEmail]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteDocumentRequestEmail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteDocumentRequestEmail
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestEmailKey	int,
	@pnOldDocumentRequestKey	int,
	@pbOldIsMain			bit,
	@psOldEmail			nvarchar(50)	= null
	
)
as
-- PROCEDURE:	ipw_DeleteDocumentRequestEmail
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete DocumentRequest Email

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 12 Mar 2007	PG	RFC3646	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		Set @sSQLString ="
		Delete from	DOCUMENTREQUESTEMAIL 
		Where	DOCUMENTEMAILID		= @pnDocumentRequestEmailKey
		and	REQUESTID		= @pnOldDocumentRequestKey
		and	ISMAIN 			= @pbOldIsMain
		and 	EMAIL			= @psOldEmail"
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDocumentRequestEmailKey	int,
				@pnOldDocumentRequestKey	int,
				@pbOldIsMain			bit,
				@psOldEmail			nvarchar(50)',
				@pnDocumentRequestEmailKey	= @pnDocumentRequestEmailKey,
				@pnOldDocumentRequestKey	= @pnOldDocumentRequestKey,
				@pbOldIsMain	 		= @pbOldIsMain,
				@psOldEmail			= @psOldEmail

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteDocumentRequestEmail to public
GO

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO