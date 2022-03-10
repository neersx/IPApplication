-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_XMLToLedgerAcctTempTable
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_XMLToLedgerAcctTempTable]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_XMLToLedgerAcctTempTable.'
	Drop procedure [dbo].[gl_XMLToLedgerAcctTempTable]
End
Print '**** Creating Stored Procedure dbo.gl_XMLToLedgerAcctTempTable...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.gl_XMLToLedgerAcctTempTable
(
	@pnUserIdentityId	int		= null, -- Mandatory
	@psCulture		nvarchar(5) 	= null,
	@psLedgerAccountIds	ntext,
	@psTempTableName	nvarchar(254)
)
as
-- PROCEDURE:	gl_XMLToLedgerAcctTempTable
-- VERSION:	2
-- SCOPE:	Inprotech
-- DESCRIPTION:	Receives an XML Document and insert the values in the XML document 
-- 		into a temporary table specified in the @psTempTableName parameter.

-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 31-Jan-2005  CR	10821	1	Procedure created
-- 27-Nov-2006	MF	13919	2	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode

Begin
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	Declare @nErrorCode 	int
	Declare @hDoc 		int
	Declare @sSql		nvarchar(1000)

	Set @nErrorCode = 0
	
	Exec @nErrorCode = sp_xml_preparedocument @hDoc OUTPUT, @psLedgerAccountIds
	
	If @nErrorCode = 0
	Begin
		Set @sSql = 'Insert Into ' +  @psTempTableName +
			    ' Select * 
			      From OPENXML( @phDoc, ''/Filter//Row'', 2 )
			      With (colnAccountId int ''colnAccountId/text()'')'
--		      	      WITH  ' + @psTempTableName


		Exec @nErrorCode = sp_executesql @sSql, N'@phDoc Int', @hDoc
	End
	
	Exec sp_xml_removedocument @hDoc

	Return @nErrorCode
End
GO

Grant execute on dbo.gl_XMLToLedgerAcctTempTable to public
GO
