-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListExchangeSchedule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListExchangeSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListExchangeSchedule.'
	Drop procedure [dbo].[ipw_ListExchangeSchedule]
End
Print '**** Creating Stored Procedure dbo.ipw_ListExchangeSchedule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListExchangeSchedule 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListExchangeSchedule
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Exchange Rate Schedule

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 AUG 2009	MS	RFC8288	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString	nvarchar(500)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = " Select E.EXCHSCHEDULEID as 'Key', 
	E.EXCHSCHEDULECODE as 'Code',"+char(10)
	+ dbo.fn_SqlTranslatedColumn('EXCHRATESCHEDULE','DESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description' 
	from 	EXCHRATESCHEDULE E 
	order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
				
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListExchangeSchedule to public
GO
