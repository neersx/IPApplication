-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListDisbursementError
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListDisbursementError]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListDisbursementError.'
	Drop procedure [dbo].[wp_ListDisbursementError]
End
Print '**** Creating Stored Procedure dbo.wp_ListDisbursementError...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ListDisbursementError
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psAssociateNo		int		= null,
	@psInvoiceNumber	nvarchar(20)	= null,
        @pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	wp_ListDisbursementError
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Checks whether the same invoice number has been entered for the Associate Name.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2008	MS	RFC6478	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare Variables
Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)
Declare @nExist		int
declare @sAlertXML	nvarchar(400)

-- Initialise variables
Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "Select @nExist = count(*) FROM WORKHISTORY WHERE 
			INVOICENUMBER = @psInvoiceNumber
			AND ASSOCIATENO = @psAssociateNo"	

	

	exec @nErrorCode=sp_executesql @sSQLString, 
			N'@nExist int output,
			@psInvoiceNumber nvarchar(20),
			@psAssociateNo int',
			@nExist		= @nExist output,
			@psInvoiceNumber = @psInvoiceNumber,
			@psAssociateNo	 = @psAssociateNo
		
End

If @nErrorCode = 0 and @nExist > 0
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('AC20', 'The entered Invoice Number has already been used for the chosen Associate.',
    		null, null, null, null, null)
  		RAISERROR(@sAlertXML, 12, 1)
  		Set @nErrorCode = @@ERROR

End	

Return @nErrorCode
GO

Grant execute on dbo.wp_ListDisbursementError to public
GO




