-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ac_ListRates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListRates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListRates.'
	Drop procedure [dbo].[ac_ListRates]
	Print '**** Creating Stored Procedure dbo.ac_ListRates...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ac_ListRates
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnRateTypeKey 		int		= null,		
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ac_ListRates
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of rates.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created

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
	select  RATENO		as RateKey,
		RATEDESC 	as RateDescription
	from	RATES
	"+
	CASE	WHEN @pnRateTypeKey is not null
		THEN char(10)+"where RATETYPE  = @pnRateTypeKey"
	END+char(10)+	 
	"order by RateDescription"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnRateTypeKey	int',
					  @pnRateTypeKey	= @pnRateTypeKey
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ac_ListRates to public
GO
