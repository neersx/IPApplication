-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_ListToLedgerAcctTempTable
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_ListToLedgerAcctTempTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_ListToLedgerAcctTempTable.'
	Drop procedure [dbo].[gl_ListToLedgerAcctTempTable]
End
Print '**** Creating Stored Procedure dbo.gl_ListToLedgerAcctTempTable...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_ListToLedgerAcctTempTable
(
	@pnUserIdentityId	int		= null, -- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psXMLAttribute		nvarchar(254)	= null,
	@psLedgerAccountIds	nvarchar(3000),
	@psTempTableName	nvarchar(254)
)
as
-- PROCEDURE:	gl_ListToLedgerAcctTempTable
-- VERSION:	4
-- SCOPE:	InProma
-- DESCRIPTION:	Generate an XML document from a list of delimited values, 
--		and insert the values in the XML document into a temporary table 
--		specified in the @psTempTableName parameter.

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 09-Jan-2003  SFOO	9445	1	Procedure created
-- 12-Aug-2004	CR	9910	2	Added new optional parameter to be used when 
--					converting the list to XML. The name of this 
--					attribute needs to match the column in the 
--					temporary table used.
-- 18-Mar-2005	MB	11113	3	Remove dtemp table from WITH clause
-- 27-Nov-2006	MF	13919	4	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode
Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode 	int
	Declare @hDoc 		int
	Declare @sSql		nvarchar(1000)
	Declare @sXml		nvarchar(4000)

	Set @nErrorCode = 0

	Set @sXml = dbo.fn_ListToXML( @psXMLAttribute, @psLedgerAccountIds, N',', 0 )
	
	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @sXml
	
	If @nErrorCode = 0
	Begin
		Set @sSql = 'Insert Into ' +  @psTempTableName +
			    ' Select * 
			      From OPENXML( @phDoc, ''/ROOT/Worktable'', 1 )
			      WITH (Value int ''@Value/text()'')'	
--		      	      WITH  ' + @psTempTableName

		Exec @nErrorCode = sp_executesql @sSql, N'@phDoc Int', @hDoc
	End
	
	Exec sp_xml_removedocument @hDoc

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_ListToLedgerAcctTempTable to public
GO
