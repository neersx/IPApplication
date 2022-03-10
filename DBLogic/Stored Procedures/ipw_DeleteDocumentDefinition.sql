-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteDocumentDefinition									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteDocumentDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteDocumentDefinition.'
	Drop procedure [dbo].[ipw_DeleteDocumentDefinition]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteDocumentDefinition...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteDocumentDefinition
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnDocumentDefinitionKey	int,	        -- Mandatory
	@pnOldLetterCode		smallint	= null,
	@psOldName			nvarchar(50)	= null,
	@psOldDescription		nvarchar(254)	= null,
	@pbOldCanFilterCases		bit		= null,
	@pbOldCanFilterEvents		bit		= null,
	@psOldSenderRequestType		nvarchar(50)	= null	
)
as
-- PROCEDURE:	ipw_DeleteDocumentDefinition
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete DocumentDefinition if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Apr 2007	SF	RFC4710	1	Procedure created
-- 03 Dec 2007	vql	RFC5909	2	Change RoleKey and DocumentDefId from smallint to int.
-- 28 Sep 2010	MS	RFC9590	3	Throw an alert message if Document Request Type is already in use.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sDeleteString		nvarchar(4000)
Declare @sAlertXML              nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

-- Are Cases and Names associated with the Image.
If (Select count(*) from DOCUMENTREQUEST where DOCUMENTDEFID = @pnDocumentDefinitionKey) > 0
Begin	
	-- Raise an alert	
	Set @sAlertXML = dbo.fn_GetAlertXML('IP118', 'Document Request Type cannot be deleted as it is used by one or more Document Requests. ',
						'%s', null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1, null)
		Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from DOCUMENTDEFINITION
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		DOCUMENTDEFID	= @pnDocumentDefinitionKey and
		LETTERNO	= @pnOldLetterCode and
		NAME		= @psOldName and
		DESCRIPTION	= @psOldDescription and
		CANFILTERCASES	= @pbOldCanFilterCases and
		CANFILTEREVENTS = @pbOldCanFilterEvents and
		SENDERREQUESTTYPE = @psOldSenderRequestType"

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnDocumentDefinitionKey	int,
			@pnOldLetterCode		smallint,
			@psOldName			nvarchar(50),
			@psOldDescription		nvarchar(254),
			@pbOldCanFilterCases		bit,
			@pbOldCanFilterEvents		bit,
			@psOldSenderRequestType		nvarchar(50)',
			@pnDocumentDefinitionKey	= @pnDocumentDefinitionKey,
			@pnOldLetterCode		= @pnOldLetterCode,
			@psOldName			= @psOldName,
			@psOldDescription		= @psOldDescription,
			@pbOldCanFilterCases		= @pbOldCanFilterCases,
			@pbOldCanFilterEvents		= @pbOldCanFilterEvents,
			@psOldSenderRequestType		= @psOldSenderRequestType
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteDocumentDefinition to public
GO

