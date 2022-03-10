-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateDocumentRequestEmail									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateDocumentRequestEmail]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateDocumentRequestEmail.'
	Drop procedure [dbo].[ipw_UpdateDocumentRequestEmail]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateDocumentRequestEmail...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateDocumentRequestEmail
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentRequestEmailKey	int,		--Mandatory
	@pnDocumentRequestKey		int		= null,
	@pbIsMain			bit				= 0,
	@psEmail			nvarchar(50)	= null,
	@pbOldIsMain			bit			= null,
	@psOldEmail			nvarchar(50)	= null
	
)
as
-- PROCEDURE:	ipw_UpdateDocumentRequestEmail
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update DocumentRequest.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------		-------	------		-------		-----------------------------------------------
-- 12 Mar 2007	PG	RFC3646	1		Procedure created
-- 04 Apr 2007	LP	RFC3646	2		Assign correct values to @pbIsMain and @psEmail

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
		Update 	DOCUMENTREQUESTEMAIL 
		Set	ISMAIN 			= @pbIsMain,
			EMAIL			= @psEmail
		Where	DOCUMENTEMAILID	= @pnDocumentRequestEmailKey
		and	ISMAIN 			= @pbOldIsMain
		and 	EMAIL			= @psOldEmail"
			
		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnDocumentRequestEmailKey	int,
				@pbIsMain			bit,
				@psEmail			nvarchar(50),
				@pbOldIsMain		bit,
				@psOldEmail			nvarchar(50)',
				@pnDocumentRequestEmailKey	= @pnDocumentRequestEmailKey,
				@pbIsMain	 		= @pbIsMain,
				@pbOldIsMain		= @pbOldIsMain,
				@psEmail			= @psEmail,
				@psOldEmail			= @psOldEmail
			

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateDocumentRequestEmail to public
GO