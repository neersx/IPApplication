-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateDocumentDefinition									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateDocumentDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateDocumentDefinition.'
	Drop procedure [dbo].[ipw_UpdateDocumentDefinition]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateDocumentDefinition...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateDocumentDefinition
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit				= 0,
	@pnDocumentDefinitionKey	int,	-- Mandatory
	@pnLetterCode				smallint		= null,
	@psName						nvarchar(50)	= null,
	@psDescription				nvarchar(254)	= null,
	@pbCanFilterCases			bit				= null,
	@pbCanFilterEvents			bit				= null,
	@psSenderRequestType		nvarchar(50)	= null,
	@pnOldLetterCode			smallint		= null,
	@psOldName					nvarchar(50)	= null,
	@psOldDescription			nvarchar(254)	= null,
	@pbOldCanFilterCases		bit				= null,
	@pbOldCanFilterEvents		bit				= null,
	@psOldSenderRequestType		nvarchar(50)	= null
)
as
-- PROCEDURE:	ipw_UpdateDocumentDefinition
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update DocumentDefinition if the underlying values are as expected.

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
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update DOCUMENTDEFINITION
			   set	LETTERNO = @pnLetterCode,
					[NAME] = @psName,
					[DESCRIPTION] = @psDescription,
					CANFILTERCASES = @pbCanFilterCases,
					CANFILTEREVENTS = @pbCanFilterEvents,
					SENDERREQUESTTYPE = @psSenderRequestType"

	Set @sWhereString = @sWhereString+CHAR(10)+"
		DOCUMENTDEFID = @pnDocumentDefinitionKey
	and LETTERNO = @pnOldLetterCode
	and [NAME] = @psOldName
	and [DESCRIPTION] = @psOldDescription
	and CANFILTERCASES = @pbOldCanFilterCases
	and CANFILTEREVENTS = @pbOldCanFilterEvents 
	and SENDERREQUESTTYPE = @psOldSenderRequestType
"

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnDocumentDefinitionKey		int,
			@pnLetterCode		smallint,
			@psName		nvarchar(50),
			@psDescription		nvarchar(254),
			@pbCanFilterCases		bit,
			@pbCanFilterEvents		bit,
			@psSenderRequestType		nvarchar(50),
			@pnOldLetterCode		smallint,
			@psOldName		nvarchar(50),
			@psOldDescription		nvarchar(254),
			@pbOldCanFilterCases		bit,
			@pbOldCanFilterEvents		bit,
			@psOldSenderRequestType		nvarchar(50)',
			@pnDocumentDefinitionKey	 = @pnDocumentDefinitionKey,
			@pnLetterCode	 = @pnLetterCode,
			@psName	 = @psName,
			@psDescription	 = @psDescription,
			@pbCanFilterCases	 = @pbCanFilterCases,
			@pbCanFilterEvents	 = @pbCanFilterEvents,
			@psSenderRequestType	 = @psSenderRequestType,
			@pnOldLetterCode	 = @pnOldLetterCode,
			@psOldName	 = @psOldName,
			@psOldDescription	 = @psOldDescription,
			@pbOldCanFilterCases	 = @pbOldCanFilterCases,
			@pbOldCanFilterEvents	 = @pbOldCanFilterEvents,
			@psOldSenderRequestType	 = @psOldSenderRequestType


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateDocumentDefinition to public
GO