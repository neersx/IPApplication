-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_GetExchangeRateSchedule
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_GetExchangeRateSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)

begin
	Print '**** Drop Stored Procedure dbo.acw_GetExchangeRateSchedule'
	Drop procedure [dbo].[acw_GetExchangeRateSchedule]
end
Print '**** Creating Stored Procedure dbo.acw_GetExchangeRateSchedule...'
Print ''
GO



SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.acw_GetExchangeRateSchedule 
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnExchangeRateCode		int   -- Mandatory
AS
-- PROCEDURE :	acw_GetExchangeRateSchedule
-- VERSION :	1
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a Exchange Rate
-- MODIFICATIONS :
-- Date			Who		Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23 Jun 2010  DV		RFC7350		1	Procedure created


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
	Select 	E.EXCHSCHEDULEID   as ExchangeScheduleKey,
			E.EXCHSCHEDULECODE as ExchangeScheduleCode,
			"+dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as Description,
			E.LOGDATETIMESTAMP as LastUpdatedDate
	from 	EXCHRATESCHEDULE E
	where E.EXCHSCHEDULEID = @pnExchangeRateCode
	order by 2"		

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnExchangeRateCode int',
				@pnExchangeRateCode	= @pnExchangeRateCode
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


grant execute on dbo.acw_GetExchangeRateSchedule to public
GO

