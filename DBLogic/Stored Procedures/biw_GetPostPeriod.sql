-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GetPostPeriod									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GetPostPeriod]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GetPostPeriod.'
	Drop procedure [dbo].[biw_GetPostPeriod]
End
Print '**** Creating Stored Procedure dbo.biw_GetPostPeriod...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_GetPostPeriod
(
	@pnPostPeriod	int	= null	output, -- Post Period id to be returned to the caller
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pdtItemDate	dateTime = null
)
as
-- PROCEDURE:	biw_GetPostPeriod
-- VERSION:		1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns Post period for the particular transaction.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		-------	-----------------------------------------------
-- 02 Mar 2010	KR		RFC8299		1		Procedure created.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @bDebug			bit

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @sReasonCode	nvarchar(2)
Declare @nPostPeriod	int
Declare @dtPostDate		datetime




Declare @sAlertXML nvarchar(2000)

Set @bDebug = 0

set @dtPostDate = dbo.fn_DateOnly(getdate())

-- Initialise variables
Set @nErrorCode = 0



--Use the period that is currently open period 
	-- the entered item date must be earlier than the period close date 
	-- and the period must not be closed for the accounting subsystem

If (@nErrorCode = 0)
Begin
	-- Set the period to the currently open period
	Set @sSQLString = "Select @nPostPeriod = OP.PERIODID
		From (Select TOP 1 PERIODID, ENDDATE, CLOSEDFOR
			From PERIOD 
			Where @dtPostDate > POSTINGCOMMENCED -- Currently open period
			and POSTINGCOMMENCED IS NOT NULL
			Order by POSTINGCOMMENCED DESC) AS OP
		WHERE dbo.fn_DateOnly(@pdtItemDate) <= OP.ENDDATE -- item date is within the period
		and (OP.CLOSEDFOR & 2 != 2 OR OP.CLOSEDFOR is null) -- and the period is not closed for Time/Billing"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @dtPostDate datetime,
				  @nPostPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @dtPostDate = @dtPostDate,
				  @nPostPeriod = @nPostPeriod OUTPUT
End

If (@nErrorCode = 0 and @nPostPeriod is null)
Begin
	-- if the current period could not be used, use the transaction period instead.
	Set @sSQLString = "Select @nPostPeriod = PERIODID
		FROM PERIOD
		WHERE dbo.fn_DateOnly(@pdtItemDate) between STARTDATE AND ENDDATE
		and (CLOSEDFOR & 2 != 2 or CLOSEDFOR is null) -- Not closed for the period"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @nPostPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @nPostPeriod = @nPostPeriod OUTPUT
End

If (@nErrorCode = 0 and @nPostPeriod is null)
Begin
	-- if the period of the transaction could not be used, use the next open period.
	Set @sSQLString = "Select @nPostPeriod = PERIODID
		FROM (SELECT MIN(P.PERIODID) AS PERIODID
			FROM (SELECT PERIODID FROM PERIOD
				WHERE dbo.fn_DateOnly(@pdtItemDate) between STARTDATE AND ENDDATE) AS TRANSPERIOD
			JOIN PERIOD P ON (P.PERIODID > TRANSPERIOD.PERIODID)
			WHERE (P.CLOSEDFOR & 2 != 2 or P.CLOSEDFOR is null)
			) AS MINPERIOD"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @nPostPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @nPostPeriod = @nPostPeriod OUTPUT
End

If (@bDebug = 1)
Begin
	Print 'Post Period = ' + cast(@nPostPeriod as nvarchar(12))
End

If (@nErrorCode = 0 and @nPostPeriod is null)
	Begin
		-- Could not determine the post period
		Set @sAlertXML = dbo.fn_GetAlertXML('AC2', 'An accounting period could not be determined for the given date. Please check the period definitions and try again.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
Else
	Begin
		Set @pnPostPeriod = @nPostPeriod
	End



Return @nErrorCode
GO

Grant execute on dbo.biw_GetPostPeriod to public
GO