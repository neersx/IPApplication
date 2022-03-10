-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteDocumentRequestActingAs									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteDocumentRequestActingAs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteDocumentRequestActingAs.'
	Drop procedure [dbo].[ipw_DeleteDocumentRequestActingAs]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteDocumentRequestActingAs...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteDocumentRequestActingAs
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestKey		int,
	@psNameType			nvarchar(3)
	
)
as
-- PROCEDURE:	ipw_DeleteDocumentRequestActingAs
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Acting As Name Type for Document Request.

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
		Delete from	DOCUMENTREQUESTACTINGAS 
		Where	REQUESTID		= @pnDocumentRequestKey and
			NAMETYPE		= @psNameType"
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDocumentRequestKey		int,
				@psNameType			nvarchar(3)',
				@pnDocumentRequestKey		= @pnDocumentRequestKey,
				@psNameType			= @psNameType

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteDocumentRequestActingAs to public
GO

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO