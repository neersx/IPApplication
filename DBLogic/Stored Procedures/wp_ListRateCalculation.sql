-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_ListRateCalculation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_ListRateCalculation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_ListRateCalculation.'
	Drop procedure [dbo].[wp_ListRateCalculation]
End
Print '**** Creating Stored Procedure dbo.wp_ListRateCalculation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.wp_ListRateCalculation 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
        @pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	wp_ListRateCalculation
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the requested Rate information, for fees calculation that match the filter criteria provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2008	MS	RFC6478	1	Procedure created
-- 01 Feb 2018  MS      R72864  2       Added RateNoSort in result set

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare Variables
Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	R.RATENO	as 'RateCalculationKey',                
                "+ dbo.fn_SqlTranslatedColumn('RATENO','RATEDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as RateCalculationDescription,
                "+ dbo.fn_SqlTranslatedColumn('RATENO','CALCLABEL1',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as Calculation1Label,
                "+ dbo.fn_SqlTranslatedColumn('RATENO','CALCLABEL2',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as Calculation2Label,
                R.RATENOSORT    as 'RateNoSort'
	from 	RATES R
                LEFT JOIN ACTIONS ON (ACTIONS.ACTION = R.ACTION)
                LEFT JOIN NAMETYPE ON (NAMETYPE.NAMETYPE = R.AGENTNAMETYPE)  
        ORDER BY  RATEDESC"	

	exec @nErrorCode=sp_executesql @sSQLString				

	Set @pnRowCount = @@Rowcount	
End

Return @nErrorCode
GO

Grant execute on dbo.wp_ListRateCalculation to public
GO
