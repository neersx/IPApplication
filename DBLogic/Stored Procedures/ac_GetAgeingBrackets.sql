-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_GetAgeingBrackets
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_GetAgeingBrackets]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_GetAgeingBrackets.'
	Drop procedure [dbo].[ac_GetAgeingBrackets]
End
Print '**** Creating Stored Procedure dbo.ac_GetAgeingBrackets...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ac_GetAgeingBrackets
(
	@pdtBaseDate		datetime	= null output, -- The date that all items to be aged must be compared to
	@pnBracket0Days		int		= null output,
	@pnBracket1Days		int		= null output,
	@pnBracket2Days		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
as
-- PROCEDURE:	ac_GetAgeingBrackets
-- VERSION:	4
-- DESCRIPTION:	Returns the number of days in each ageing bracket, and the base date for calculation.
-- COPYRIGHT:Copyright 1993 - 2016 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 14 Nov 2003	JEK	RFC621	1	Procedure created
-- 01 Feb 2012  DV	R100679	2	Include only the Date without the time in the comparision
-- 03 Jul 2013  vql	R13615	3	Error when running the financial summary report
-- 01 Apr 2016	KR	R58755	4	Compare date part when comparing the dates in the PERIOD table as it contains date only and not datetime.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

-- Determine the ageing periods to be used for the OutstandingBalance
-- Selects the period where today is between the start and end dates (Period 0)
-- Sets the AgeBaseDate to the end date of Period 0
-- Sets the Bracket 0 days (current) to AgeBaseDate - start date of Period 0 + 1
-- Selects the previous period by descending PeriodId (Period 1)
-- Sets the Bracket 0-1 days to AgeBaseDate - start date of Period 1 + 1 
-- Selects the previous period by descending PeriodId (Period 2)
-- Sets the Bracket 0-2 days to AgeBaseDate - start date of Period 2 + 1 

	Set @sSQLString="
	select 	@pnBracket0Days=datediff(day, P0.STARTDATE, P0.ENDDATE)+1,
		@pnBracket1Days=datediff(day, P1.STARTDATE, P0.ENDDATE)+1,
		@pnBracket2Days=datediff(day, P2.STARTDATE, P0.ENDDATE)+1,
		@pdtBaseDate=P0.ENDDATE
	from PERIOD P0
	left join PERIOD P1	on (P1.PERIODID=(select max(P1X.PERIODID)
						 from PERIOD P1X
						 where P1X.PERIODID<P0.PERIODID))
	left join PERIOD P2	on (P2.PERIODID=(select max(P2X.PERIODID)
						 from PERIOD P2X
						 where P2X.PERIODID<P1.PERIODID))
	where CONVERT(date, getdate()) between P0.STARTDATE and P0.ENDDATE"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBracket0Days	smallint	OUTPUT,
					  @pnBracket1Days	smallint	OUTPUT,
					  @pnBracket2Days	smallint	OUTPUT,
					  @pdtBaseDate		datetime	OUTPUT',
					  @pnBracket0Days=@pnBracket0Days	OUTPUT,
					  @pnBracket1Days=@pnBracket1Days	OUTPUT,
					  @pnBracket2Days=@pnBracket2Days	OUTPUT,
					  @pdtBaseDate=@pdtBaseDate		OUTPUT

	-- if there aren't enough ageing periods set (e.g. the client has just started using the system 
	-- and only has the current period defined, the approximate the missing ageing brackets by assuming 
	-- that they will have the same number of days as in the last defined bracket; i.e.

	Select @pnBracket0Days=isnull(@pnBracket0Days,30)
	Select @pnBracket1Days=isnull(@pnBracket1Days, @pnBracket0Days*2)
	Select @pnBracket2Days=isnull(@pnBracket2Days, @pnBracket1Days+@pnBracket1Days-@pnBracket0Days)

End

Return @nErrorCode
GO

Grant execute on dbo.ac_GetAgeingBrackets to public
GO
