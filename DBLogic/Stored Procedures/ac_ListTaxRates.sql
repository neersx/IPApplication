-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListTaxRates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListTaxRates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListTaxRates.'
	Drop procedure [dbo].[ac_ListTaxRates]
End
Print '**** Creating Stored Procedure dbo.ac_ListTaxRates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_ListTaxRates
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ac_ListTaxRates
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Return TaxRateKey, TaxRateDescription from TaxRates table.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
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
	Select  T.TAXCODE 	as TaxRateKey, 
	"+dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as TaxRateDescription
	from TAXRATES T
	order by TaxRateDescription"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ListTaxRates to public
GO
