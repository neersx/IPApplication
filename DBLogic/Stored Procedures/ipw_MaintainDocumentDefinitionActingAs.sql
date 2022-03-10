-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainDocumentDefinitionActingAs									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainDocumentDefinitionActingAs]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainDocumentDefinitionActingAs.'
	Drop procedure [dbo].[ipw_MaintainDocumentDefinitionActingAs]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainDocumentDefinitionActingAs...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_MaintainDocumentDefinitionActingAs
(
	@pnUserIdentityId				int,			-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pbCalledFromCentura			bit				= 0,
	@pnDocumentDefinitionKey		int		= null,
	@psNameTypeKey					nvarchar(3),	-- Mandatory
	@pbIsSelected					bit,			-- Mandatory
	@pbOldIsSelected				bit				-- Mandatory
)
as
-- PROCEDURE:	ipw_MaintainDocumentDefinitionActingAs
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update DocumentDefinitionActingAs if the underlying values are as expected.

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
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("


If @nErrorCode = 0
Begin
	-- Export format no longer valid, remove
	if @pbOldIsSelected=1 and @pbIsSelected=0
	Begin
		exec @nErrorCode = ipw_DeleteDocumentDefinitionActingAs
			@pnUserIdentityId			= @pnUserIdentityId,
			@psCulture					= @psCulture,
			@pnDocumentDefinitionKey	= @pnDocumentDefinitionKey,
			@psNameTypeKey				= @psNameTypeKey
	End
	Else
	Begin 
		Set @sInsertString = "Insert into DOCUMENTDEFINITIONACTINGAS
				("

		Set @sComma = ","
		Set @sInsertString = @sInsertString+CHAR(10)+"
							DOCUMENTDEFID,NAMETYPE
				"

		Set @sValuesString = @sValuesString+CHAR(10)+"
							@pnDocumentDefinitionKey,@psNameTypeKey
				"

		Set @sInsertString = @sInsertString+CHAR(10)+")"
		Set @sValuesString = @sValuesString+CHAR(10)+")"

		Set @sSQLString = @sInsertString + @sValuesString

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@pnDocumentDefinitionKey		int,
				@psNameTypeKey					nvarchar(3)',
				@pnDocumentDefinitionKey		= @pnDocumentDefinitionKey,
				@psNameTypeKey					= @psNameTypeKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainDocumentDefinitionActingAs to public
GO