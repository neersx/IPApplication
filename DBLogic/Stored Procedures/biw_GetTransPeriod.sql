-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GetTransPeriod									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GetTransPeriod]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GetTransPeriod.'
	Drop procedure [dbo].[biw_GetTransPeriod]
End
Print '**** Creating Stored Procedure dbo.biw_GetTransPeriod...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_GetTransPeriod
(
	@pnTransPeriod	int	= null	output, -- Trans Period id to be returned to the caller
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pdtItemDate	dateTime		-- mandatory
)
as
-- PROCEDURE:	biw_GetTransPeriod
-- VERSION:		1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns Post and Transaction period for the particular transaction.

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
Declare @nTransPeriod	int
Declare @dtPostDate		datetime

Declare @sAlertXML nvarchar(2000)

Set @bDebug = 0

set @dtPostDate = dbo.fn_DateOnly(getdate())

-- Initialise variables
Set @nErrorCode = 0


-- get transction period
If (@nErrorCode = 0)
Begin
	-- Set the period to the currently open period
	Set @sSQLString = "Select @nTransPeriod = OP.PERIODID
		From (Select TOP 1 PERIODID, STARTDATE, ENDDATE, CLOSEDFOR
			From PERIOD 			
			WHERE dbo.fn_DateOnly(@pdtItemDate) >= STARTDATE
			and dbo.fn_DateOnly(@pdtItemDate) <= ENDDATE  -- item date is within the period
			Order by STARTDATE ASC) AS OP
		Where (OP.CLOSEDFOR & 2 != 2 OR OP.CLOSEDFOR is null) -- and the period is not closed for Time/Billing"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @nTransPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @nTransPeriod = @nTransPeriod OUTPUT
End

If (@nErrorCode = 0 and @nTransPeriod is null)
Begin
	-- if the current period could not be used, use the transaction period instead.
	Set @sSQLString = "Select @nTransPeriod = PERIODID
		FROM PERIOD
		WHERE dbo.fn_DateOnly(@pdtItemDate) between STARTDATE AND ENDDATE
		and (CLOSEDFOR & 2 != 2 or CLOSEDFOR is null) -- Not closed for the period"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @nTransPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @nTransPeriod = @nTransPeriod OUTPUT
End

If (@nErrorCode = 0 and @nTransPeriod is null)
Begin
	-- if the period of the transaction could not be used, use the next open period.
	Set @sSQLString = "Select @nTransPeriod = PERIODID
		FROM (SELECT MIN(P.PERIODID) AS PERIODID
			FROM (SELECT PERIODID FROM PERIOD
				WHERE dbo.fn_DateOnly(@pdtItemDate) between STARTDATE AND ENDDATE) AS TRANSPERIOD
			JOIN PERIOD P ON (P.PERIODID > TRANSPERIOD.PERIODID)
			WHERE (P.CLOSEDFOR & 2 != 2 or P.CLOSEDFOR is null)
			) AS MINPERIOD"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pdtItemDate datetime,
				  @nTransPeriod		int OUTPUT',
				  @pdtItemDate = @pdtItemDate,
				  @nTransPeriod = @nTransPeriod OUTPUT
End

If (@bDebug = 1)
Begin
	Print 'Trans Period = ' + cast(@nTransPeriod as nvarchar(12))
End

If (@nErrorCode = 0 and @nTransPeriod is null)
	Begin
		-- Could not determine the post period
		Set @sAlertXML = dbo.fn_GetAlertXML('AC2', 'An accounting period could not be determined for the given date. Please check the period definitions and try again.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
Else
	Begin
		Set @pnTransPeriod = @nTransPeriod
	End



Return @nErrorCode
GO

Grant execute on dbo.biw_GetTransPeriod to public
GO