-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListTaxRates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListTaxRates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListTaxRates.'
	Drop procedure [dbo].[acw_ListTaxRates]
End
Print '**** Creating Stored Procedure dbo.acw_ListTaxRates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListTaxRates
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	acw_ListTaxRates
-- VERSION:	2
-- DESCRIPTION:	Return list of Tax Codes from TAXRATES table for maintenance.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 25-Mar-2011	LP		RFC8412		1		Procedure created
-- 14-Aug-2012	AT		RFC12431	2		Added ONEFEEPERDEBTOR column.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(max)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  T.TAXCODE 	as TaxCode, 
	"+dbo.fn_SqlTranslatedColumn('TAXRATES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as Description," + char(10) +
	        "T.WIPCODE as WIPCode,
	        "+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+"
					as 'WIPCodeDescription',
	        T.WIPCATEGORY as WIPCategory,
	        T.NARRATIVENO as NarrativeKey,
	        N.NARRATIVETITLE as NarrativeTitle,
	        N.NARRATIVECODE as NarrativeCode,
	        T.CURRENCYCODE as CurrencyCode,
	        "+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'C',@sLookupCulture,@pbCalledFromCentura)+"
					as 'CurrencyDescription',
	        T.MAXFREEAMOUNT as MaxFreeAmount,
	        T.FEEAMOUNT as FeeAmount,
	        T.FEEPERCENTAGE as FeePercent,
	        CAST(ISNULL(T.HIDEFEEINDRAFT,0) as bit) as HideFeeInDraft,
	        ISNULL(T.ONEFEEPERDEBTOR,0) AS OneFeePerDebtor,
	        T.LOGDATETIMESTAMP as LastUpdatedDate" + char(10) +
	"from TAXRATES T
	left join WIPTEMPLATE W on (W.WIPCODE = T.WIPCODE)
	left join NARRATIVE N on (N.NARRATIVENO = T.NARRATIVENO)
	left join CURRENCY C on (C.CURRENCY = T.CURRENCYCODE)
	order by 2"
		
	exec @nErrorCode = sp_executesql @sSQLString

End


Return @nErrorCode
GO

Grant execute on dbo.acw_ListTaxRates to public
GO
