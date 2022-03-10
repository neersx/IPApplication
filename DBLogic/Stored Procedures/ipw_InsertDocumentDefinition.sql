-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertDocumentDefinition									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertDocumentDefinition]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertDocumentDefinition.'
	Drop procedure [dbo].[ipw_InsertDocumentDefinition]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertDocumentDefinition...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertDocumentDefinition
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit				= 0,
	@pnDocumentDefinitionKey	int		= null,	
	@pnLetterCode				smallint		= null,
	@psName						nvarchar(50)	= null,
	@psDescription				nvarchar(254)	= null,
	@pbCanFilterCases			bit				= null,
	@pbCanFilterEvents			bit				= null,
	@psSenderRequestType		nvarchar(50)	= null
)
as
-- PROCEDURE:	ipw_InsertDocumentDefinition
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert DocumentDefinition.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Apr 2007	SF	RFC4710	1	Procedure created
-- 03 Dec 2007	vql	RFC5909	2	Change RoleKey and DocumentDefId from smallint to int.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into DOCUMENTDEFINITION
				(LETTERNO, [NAME], [DESCRIPTION], CANFILTERCASES, CANFILTEREVENTS, SENDERREQUESTTYPE)
		"
	Set @sValuesString = @sValuesString+CHAR(10)+ 
		"@pnLetterCode, @psName, @psDescription, @pbCanFilterCases, @pbCanFilterEvents, @psSenderRequestType)"

	Set @sSQLString = @sInsertString + @sValuesString

	Set @sSQLString = @sSQLString + CHAR(10)
		+ "Set @pnDocumentDefinitionKey = SCOPE_IDENTITY()"
		
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnDocumentDefinitionKey		int output,
			@pnLetterCode		smallint,
			@psName		nvarchar(50),
			@psDescription		nvarchar(254),
			@pbCanFilterCases		bit,
			@pbCanFilterEvents		bit,
			@psSenderRequestType		nvarchar(50)',
			@pnDocumentDefinitionKey	 = @pnDocumentDefinitionKey OUTPUT,
			@pnLetterCode	 = @pnLetterCode,
			@psName	 = @psName,
			@psDescription	 = @psDescription,
			@pbCanFilterCases	 = @pbCanFilterCases,
			@pbCanFilterEvents	 = @pbCanFilterEvents,
			@psSenderRequestType	 = @psSenderRequestType

	-- Publish the generated key to update the data adapter
	Select @pnDocumentDefinitionKey as DocumentDefinitionKey

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertDocumentDefinition to public
GO