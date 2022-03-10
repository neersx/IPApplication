-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteDocumentDefinitionExportFormat									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteDocumentDefinitionExportFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteDocumentDefinitionExportFormat.'
	Drop procedure [dbo].[ipw_DeleteDocumentDefinitionExportFormat]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteDocumentDefinitionExportFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteDocumentDefinitionExportFormat
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnDocumentDefinitionKey		int,	-- Mandatory
	@pnExportFormatKey		int	-- Mandatory
)
as
-- PROCEDURE:	ipw_DeleteDocumentDefinitionExportFormat
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete DocumentDefinitionExportFormat if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Apr 2007	SF	RFC4710	1	Procedure created
-- 03 Dec 2007	vql	RFC5909	2	Change RoleKey and DocumentDefId from smallint to int.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from VALIDEXPORTFORMAT
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		DOCUMENTDEFID = @pnDocumentDefinitionKey and 
		FORMATID = @pnExportFormatKey
"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnDocumentDefinitionKey		int,
			@pnExportFormatKey		int',
			@pnDocumentDefinitionKey	 = @pnDocumentDefinitionKey,
			@pnExportFormatKey	 = @pnExportFormatKey


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteDocumentDefinitionExportFormat to public
GO