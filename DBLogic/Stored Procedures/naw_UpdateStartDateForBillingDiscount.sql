-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateStartDateForBillingDiscount
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateStartDateForBillingDiscount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateStartDateForBillingDiscount.'
	Drop procedure [dbo].[naw_UpdateStartDateForBillingDiscount]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateStartDateForBillingDiscount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[naw_UpdateStartDateForBillingDiscount]
(
	@pnUserIdentityId		int,		    -- Mandatory
	@psCulture		        nvarchar(10) 	= null,		
	@pbCalledFromCentura	bit		        = 0,
	@pnNameKey		        int,		    -- Mandatory
	@pdtStartDate     		datetime    	= null  output	
)
as
-- PROCEDURE:	naw_UpdateStartDateForBillingDiscount
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Calculates the Billing Discount based on invoice and
--		number of filings.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26 Jul 2010	MS	RFC7275	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		    int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @nPeriod		    tinyint
Declare @sPeriodType		nchar(1)
Declare @dtActualDate		datetime

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select	
	@pdtStartDate	= STARTDATE,
	@nPeriod	    = PERIOD,
	@sPeriodType	= PERIODTYPE
	from DISCOUNTBASEDONINVOICE D
	where D.NAMENO = @pnNameKey"			

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pdtStartDate		datetime		output,
			@nPeriod		    tinyint			output,
			@sPeriodType		nchar(1)		output,			
			@pnNameKey		    int',
			@pdtStartDate		= @pdtStartDate	output,
			@nPeriod		    = @nPeriod		output,
			@sPeriodType		= @sPeriodType	output,			
			@pnNameKey		    = @pnNameKey
END

If @nErrorCode = 0
Begin
	SET @dtActualDate = case when @sPeriodType = 'D' then DATEADD(d,@nPeriod, @pdtStartDate)
			when @sPeriodType = 'W' then DATEADD(ww,@nPeriod, @pdtStartDate)
			when @sPeriodType = 'M' then DATEADD(mm,@nPeriod, @pdtStartDate)
			when @sPeriodType= 'Y' then DATEADD(yy,@nPeriod, @pdtStartDate)
			end
						
	If @dtActualDate < getDate()
	Begin
		WHILE (@dtActualDate < getDate())
		BEGIN	
			SET @pdtStartDate = @dtActualDate
						
			SET @dtActualDate = case when @sPeriodType = 'D' then DATEADD(d,@nPeriod, @dtActualDate)
				when @sPeriodType = 'W' then DATEADD(ww,@nPeriod, @dtActualDate)
				when @sPeriodType = 'M' then DATEADD(mm,@nPeriod, @dtActualDate)
				when @sPeriodType= 'Y' then DATEADD(yy,@nPeriod, @dtActualDate)
				end
		END	
		
		If @dtActualDate >= getDate()
	    Begin
		    Set @sSQLString = "
			    Update DISCOUNTBASEDONINVOICE
			    SET STARTDATE = @pdtStartDate
			    where NAMENO = @pnNameKey"			 

			    exec @nErrorCode=sp_executesql @sSQLString,
					    N'@pdtStartDate		datetime,
					      @pnNameKey		int',
					      @pdtStartDate		= @pdtStartDate,
					      @pnNameKey		= @pnNameKey
	    End			
	End 
End

Return @nErrorCode
GO
Grant execute on dbo.naw_UpdateStartDateForBillingDiscount to public
GO