-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_GetLocalCurrencyDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_GetLocalCurrencyDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_GetLocalCurrencyDetails.'
	Drop procedure [dbo].[ac_GetLocalCurrencyDetails]
End
Print '**** Creating Stored Procedure dbo.ac_GetLocalCurrencyDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ac_GetLocalCurrencyDetails
(
	@psCurrencyCode		nvarchar(3)	output,	-- The local currency
	@pnDecimalPlaces	tinyint		output, -- Calculated decimal places
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ac_GetLocalCurrencyDetails
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the local currency and its corresponding decimal places

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Jun 2005	JEK	RFC2739	1	Procedure created
-- 09 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select  @pnDecimalPlaces = case when W.COLBOOLEAN = 1 then 0 else isnull(CY.DECIMALPLACES,2) end,
		@psCurrencyCode = C.COLCHARACTER
	from	SITECONTROL C
	left join SITECONTROL W on (W.CONTROLID = 'Currency Whole Units')
	left join CURRENCY CY	on (CY.CURRENCY = C.COLCHARACTER
				-- Decimal places implemented in Centura
				and isnull(@pbCalledFromCentura,0) = 0 )
	WHERE 	C.CONTROLID = 'CURRENCY'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pbCalledFromCentura	bit,
			  @pnDecimalPlaces	tinyint			OUTPUT,
			  @psCurrencyCode	nvarchar(3)		OUTPUT',
			  @pbCalledFromCentura 	= @pbCalledFromCentura,
			  @pnDecimalPlaces	= @pnDecimalPlaces	OUTPUT,
			  @psCurrencyCode	= @psCurrencyCode	OUTPUT
End

Return @nErrorCode
GO

Grant execute on dbo.ac_GetLocalCurrencyDetails to public
GO
