-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_DeleteTaxRate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_DeleteTaxRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_DeleteTaxRate.'
	Drop procedure [dbo].[acw_DeleteTaxRate]
End
Print '**** Creating Stored Procedure dbo.acw_DeleteTaxRate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.acw_DeleteTaxRate
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@psTaxCode              nvarchar(3),
	@pdtLastUpdatedDate	datetime        = null,
	@pbCalledFromCentura	bit		= 0
	
)
as
-- PROCEDURE:	acw_DeleteTaxRate
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Remove a Tax Code from the system

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Mar 2011	LP	RFC8412 1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString     nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If not exists (Select 1 from TAXRATES 
			   where TAXCODE = @psTaxCode and LOGDATETIMESTAMP = @pdtLastUpdatedDate)
	Begin
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Delete command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin
		Set @sSQLString = "DELETE FROM TAXRATES 
							Where TAXCODE = @psTaxCode
							and LOGDATETIMESTAMP = @pdtLastUpdatedDate"

		exec @nErrorCode=sp_executesql @sSQLString,
				        N'@psTaxCode		nvarchar(3),
					@pdtLastUpdatedDate	datetime',
					@psTaxCode	 	= @psTaxCode,
					@pdtLastUpdatedDate	= @pdtLastUpdatedDate
	End	
End

Return @nErrorCode
GO

Grant execute on dbo.acw_DeleteTaxRate to public
GO
