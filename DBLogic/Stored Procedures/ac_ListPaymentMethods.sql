-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListPaymentMethods    
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListPaymentMethods]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListPaymentMethods.'
	Drop procedure [dbo].[ac_ListPaymentMethods    ]
End
Print '**** Creating Stored Procedure dbo.ac_ListPaymentMethods...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_ListPaymentMethods    
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnUsedByFlags 		smallint 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ac_ListPaymentMethods    
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists payment methods.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07-Sep-2004	TM	RFC1158	1	Procedure created
-- 13-Sep-2004	TM	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  P.PAYMENTMETHOD		as PaymentKey,
	"+dbo.fn_SqlTranslatedColumn('PAYMENTMETHODS','PAYMENTDESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as PaymentDescription
	from PAYMENTMETHODS P
	where P.USEDBY&@pnUsedByFlags>0
	order by PaymentDescription"  
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUsedByFlags smallint',
					  @pnUsedByFlags = @pnUsedByFlags
	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ListPaymentMethods to public
GO
