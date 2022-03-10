-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListPostPeriods   
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListPostPeriods]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListPostPeriods.'
	Drop procedure [dbo].[ac_ListPostPeriods   ]
End
Print '**** Creating Stored Procedure dbo.ac_ListPostPeriods...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_ListPostPeriods   
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ac_ListPostPeriods   
-- VERSION:	2
-- DESCRIPTION:	Lists post periods.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05-May-2010	LP	RFC9257	1	Procedure created
-- 29-Oct-2010	LP	RFC9820	2	Return IsDefault column.


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
	Set @sSQLString ="
	select	PERIODID as PostPeriodKey,  	
	"+dbo.fn_SqlTranslatedColumn('PERIOD','LABEL',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as PostPeriodDescription,  					
	STARTDATE as StartDate,  	
	ENDDATE as EndDate,
	CASE WHEN POSTINGCOMMENCED = (SELECT  MAX(POSTINGCOMMENCED) from PERIOD) THEN 1 ELSE 0 END as IsDefault 
	from	PERIOD P 
	ORDER BY PERIODID"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ListPostPeriods to public
GO
