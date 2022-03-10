-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ar_ValidatePeriod
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ar_ValidatePeriod]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_SPNAME.'
	Drop procedure [dbo].[ar_ValidatePeriod]
End
Print '**** Creating Stored Procedure dbo.ar_ValidatePeriod...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ar_ValidatePeriod
(
	@pnUserIdentityId	int 		= null,		
	@psCulture		nvarchar(10) 	= null,	
	@pnErrorType		int		 output,
	@pdtPeriodStart		datetime,
	@pdtPeriodEnd		datetime,
	@pnPeriodId		int
)
as
-- PROCEDURE:	ar_ValidatePeriod
-- VERSION:	2
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Programmer comments here
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited-- MODIFICTIONS :
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 06-NOV-2003  MB	9184	1	Procedure created
-- 16-JUN-2004	MB	11085	2	Validate only the passed period


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int
Declare @INVALID_START_DATE  		int
Declare @INVALID_END_DATE  		int
Declare @INVALID_PERIOD_INCREMENT  	int
Declare @INVALID_YEAR_INCREMENT  	int
Declare @dtPreviousPeriodEndDate	datetime
Declare @dtFollowingPeriodStartDate	datetime
Declare @nPreviousPeriodId		int
Declare @nFollowingPeriodId		int

Set @INVALID_START_DATE 	= 1
Set @INVALID_END_DATE 		= 2
Set @INVALID_PERIOD_INCREMENT 	= 3
Set @INVALID_YEAR_INCREMENT 	= 4
Set @nErrorCode 		= 0
Set @pnErrorType 		= 0


-- Assert previous Period End Date and Period Id
If @nErrorCode = 0
Begin
	select @dtPreviousPeriodEndDate = ENDDATE ,
		@nPreviousPeriodId = PERIODID
	from PERIOD where 
	PERIODID = (SELECT MAX(PERIODID) from PERIOD WHERE PERIODID < @pnPeriodId)
 	If @dtPreviousPeriodEndDate is not null
	Begin
		If @pdtPeriodStart - @dtPreviousPeriodEndDate <> 1 or @dtPreviousPeriodEndDate >= @pdtPeriodStart
			Set @pnErrorType = @INVALID_START_DATE
		If @pnErrorType = 0
		Begin
			If LEFT (CAST ( @nPreviousPeriodId as nvarchar),4) = LEFT (CAST ( @pnPeriodId as nvarchar),4)
			Begin
				If cast (  RIGHT (CAST ( @pnPeriodId as nvarchar),2) as int) - 
				   cast (RIGHT (CAST ( @nPreviousPeriodId as nvarchar),2)as int) <> 1 
					Set @pnErrorType = @INVALID_PERIOD_INCREMENT
			End
			Else
			Begin
				If cast (LEFT (CAST ( @pnPeriodId as nvarchar),4) as int) - cast (LEFT (CAST ( @nPreviousPeriodId as nvarchar),4) as int) <>1 
					Set @pnErrorType = @INVALID_YEAR_INCREMENT
			End
		End

	End	
End

-- Assert following Period Start Date and Period Id
If @nErrorCode = 0 and @pnErrorType = 0
Begin

	Select @dtFollowingPeriodStartDate = STARTDATE,
		@nFollowingPeriodId = PERIODID
	from PERIOD where 
	PERIODID = (SELECT MIN(PERIODID) from PERIOD WHERE PERIODID > @pnPeriodId)
	-- select @dtFollowingPeriodStartDate, @pdtPeriodEnd
	If @dtFollowingPeriodStartDate is not null
	Begin
		If @dtFollowingPeriodStartDate - @pdtPeriodEnd <> 1 
			or @dtFollowingPeriodStartDate <= @pdtPeriodEnd
			Set @pnErrorType	=@INVALID_END_DATE
		If @pnErrorType = 0
		Begin
			If LEFT (CAST ( @nFollowingPeriodId as nvarchar),4) = LEFT (CAST ( @pnPeriodId as nvarchar),4)
			Begin
				If cast (RIGHT (CAST ( @nFollowingPeriodId as nvarchar),2)as int) -
				cast (  RIGHT (CAST ( @pnPeriodId as nvarchar),2) as int)  <> 1 
					Set @pnErrorType = @INVALID_PERIOD_INCREMENT
			End
			Else
			Begin
				If cast (LEFT (CAST ( @nFollowingPeriodId as nvarchar),4) as int) - cast (LEFT (CAST ( @pnPeriodId as nvarchar),4) as int) <>1 
					Set @pnErrorType = @INVALID_YEAR_INCREMENT
			End
		End
	End	

End

Return @nErrorCode
GO

Grant execute on dbo.ar_ValidatePeriod to public
GO
