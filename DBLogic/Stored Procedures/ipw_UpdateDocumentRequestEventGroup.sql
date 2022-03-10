-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateDocumentRequestEventGroup
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateDocumentRequestEventGroup]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateDocumentRequestEventGroup.'
	Drop procedure [dbo].[ipw_UpdateDocumentRequestEventGroup]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateDocumentRequestEventGroup...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_UpdateDocumentRequestEventGroup
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDocumentRequestKey	int,
	@pnEventGroupKey	int,
	@pbIsSelected		bit,
	@pbOldIsSelected	bit
)
as
-- PROCEDURE:	ipw_UpdateDocumentRequestEventGroup
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Maintains Event groups for document request
--				This proc is called in two modes - 
--				1. creating or maintaining an existing document request with event group
--				2. creating a document request which is copied from another document request with event group.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 Apr 2007	PG	RFC3646	1	Procedure created
-- 26 Mar 2008	SF	RFC6285	2	Remove concurrency checking

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @pbIsSelected =1
	and not exists(	select * 
						from DOCUMENTEVENTGROUP 
						where REQUESTID = @pnDocumentRequestKey and EVENTGROUP = @pnEventGroupKey)
	Begin
		Set @sSQLString = "Insert into DOCUMENTEVENTGROUP (REQUESTID,EVENTGROUP)
		Values (@pnDocumentRequestKey,@pnEventGroupKey)"
	End
	Else If @pbIsSelected = 0
	and exists(	select * 
						from DOCUMENTEVENTGROUP 
						where REQUESTID = @pnDocumentRequestKey and EVENTGROUP = @pnEventGroupKey)
	Begin
		Set @sSQLString ="Delete from DOCUMENTEVENTGROUP 
			Where REQUESTID= @pnDocumentRequestKey
			AND   EVENTGROUP=@pnEventGroupKey"
	End
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnDocumentRequestKey	int,
			  @pnEventGroupKey		int',
			@pnDocumentRequestKey	= @pnDocumentRequestKey,
			@pnEventGroupKey		= @pnEventGroupKey	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateDocumentRequestEventGroup to public
GO
