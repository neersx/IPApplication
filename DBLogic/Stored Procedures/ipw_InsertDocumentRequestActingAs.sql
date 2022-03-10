-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertDocumentRequestActingAs									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertDocumentRequestActingAs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertDocumentRequestActingAs.'
	Drop procedure [dbo].[ipw_InsertDocumentRequestActingAs]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertDocumentRequestActingAs...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertDocumentRequestActingAs
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestKey		int,
	@psNameType			nvarchar(3)	
)
as
-- PROCEDURE:	ipw_InsertDocumentRequestActingAs
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Acting As Name Types for Document Request.

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
		Set @sInsertString ="Insert into DOCUMENTREQUESTACTINGAS(
			REQUESTID,
			NAMETYPE
			)
			values (
			@pnDocumentRequestKey,
			@psNameType
			)"
			
			exec @nErrorCode=sp_executesql @sInsertString,
				N'@pnDocumentRequestKey		int,
				@psNameType 		nvarchar(3)',
				@pnDocumentRequestKey	 	= @pnDocumentRequestKey,
				@psNameType			= @psNameType

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertDocumentRequestActingAs to public
GO