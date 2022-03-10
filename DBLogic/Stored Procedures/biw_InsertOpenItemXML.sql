-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_InsertOpenItemXML									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_InsertOpenItemXML]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_InsertOpenItemXML.'
	Drop procedure [dbo].[biw_InsertOpenItemXML]
End
Print '**** Creating Stored Procedure dbo.biw_InsertOpenItemXML...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_InsertOpenItemXML
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityKey	int,	-- Mandatory.
	@pnItemTransNo		int,	-- Mandatory.
	@pnXMLType		tinyint = 0,
	@psXMLText		nvarchar(max)
)
as
-- PROCEDURE:	biw_InsertOpenItemXML
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert OpenItemXML for ebilling.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 03 Aug 2010	AT	RFC9556	1	Procedure created.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @nItemType		int

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into OPENITEMXML
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"ITEMENTITYNO,ITEMTRANSNO,XMLTYPE,OPENITEMXML"

	Set @sValuesString = @sValuesString+CHAR(10)+"@pnItemEntityKey,@pnItemTransNo,@pnXMLType,@psXMLText"

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnItemEntityKey	int,
			@pnItemTransNo		int,
			@pnXMLType		tinyint,
			@psXMLText		nvarchar(max)',
			@pnItemEntityKey	= @pnItemEntityKey,
			@pnItemTransNo		= @pnItemTransNo,
			@pnXMLType		= @pnXMLType,
			@psXMLText		= @psXMLText

End

Return @nErrorCode
GO

Grant execute on dbo.biw_InsertOpenItemXML to public
GO