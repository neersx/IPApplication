-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainDocumentDefinitionExportFormat									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainDocumentDefinitionExportFormat]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainDocumentDefinitionExportFormat.'
	Drop procedure [dbo].[ipw_MaintainDocumentDefinitionExportFormat]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainDocumentDefinitionExportFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_MaintainDocumentDefinitionExportFormat
(
	@pnUserIdentityId				int,		-- Mandatory
	@psCulture						nvarchar(10) 	= null,
	@pbCalledFromCentura			bit			= 0,
	@pnDocumentDefinitionKey		int	= null,	
	@pnExportFormatKey				int,		-- Mandatory
	@pbIsSelected					bit,		-- Mandatory
	@pbOldIsSelected				bit,		-- Mandatory
	@pbIsDefault					bit			= 0,	
	@pbOldIsDefault					bit			= 0
)
as
-- PROCEDURE:	ipw_MaintainDocumentDefinitionExportFormat
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update DocumentDefinitionExportFormat if the underlying values are as expected.

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

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma				nchar(1)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sAnd				nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "


If @nErrorCode = 0
Begin	
	-- Export format no longer valid, remove
	if @pbOldIsSelected=1 and @pbIsSelected=0
	Begin
		exec @nErrorCode = ipw_DeleteDocumentDefinitionExportFormat
			@pnUserIdentityId			= @pnUserIdentityId,
			@psCulture					= @psCulture,
			@pnDocumentDefinitionKey	= @pnDocumentDefinitionKey,
			@pnExportFormatKey			= @pnExportFormatKey
	End
	-- Export format remains valid, default export format changed.
	Else if	(@pbOldIsSelected=1 and @pbIsSelected=1)
	Begin
		Set @sUpdateString = "Update VALIDEXPORTFORMAT
			   set ISDEFAULT = @pbIsDefault"

		Set @sWhereString = @sWhereString+CHAR(10)+"
			DOCUMENTDEFID = @pnDocumentDefinitionKey and
			FORMATID = @pnExportFormatKey and
			ISDEFAULT = @pbOldIsDefault
		"
		
		Set @sSQLString = @sUpdateString + @sWhereString

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@pnDocumentDefinitionKey	int,
				@pnExportFormatKey			int,
				@pbOldIsDefault				bit,
				@pbIsDefault				bit',
				@pnDocumentDefinitionKey	= @pnDocumentDefinitionKey,
				@pnExportFormatKey			= @pnExportFormatKey,
				@pbOldIsDefault				= @pbOldIsDefault,
				@pbIsDefault				= @pbIsDefault
	End
	Else
	-- Export format has become valid
	Begin
		Set @sInsertString = "Insert into VALIDEXPORTFORMAT
				("
		Set @sComma = ","
		Set @sInsertString = @sInsertString+CHAR(10)+"
							DOCUMENTDEFID,FORMATID,ISDEFAULT
				"

		Set @sValuesString = @sValuesString+CHAR(10)+"
							@pnDocumentDefinitionKey,@pnExportFormatKey,@pbIsDefault
				"

		Set @sInsertString = @sInsertString+CHAR(10)+")"
		Set @sValuesString = @sValuesString+CHAR(10)+")"

		Set @sSQLString = @sInsertString + @sValuesString

		exec @nErrorCode=sp_executesql @sSQLString,
			      		N'
				@pnDocumentDefinitionKey		int,
				@pnExportFormatKey		int,
				@pbIsDefault			bit',
				@pnDocumentDefinitionKey	 = @pnDocumentDefinitionKey,
				@pnExportFormatKey	 = @pnExportFormatKey,
				@pbIsDefault = @pbIsDefault
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainDocumentDefinitionExportFormat to public
GO
