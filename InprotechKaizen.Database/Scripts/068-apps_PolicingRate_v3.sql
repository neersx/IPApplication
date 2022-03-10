-----------------------------------------------------------------------------------------------------------------------------
-- Creation of apps_PolicingRate
-----------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[apps_PolicingRate]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	PRINT '**** Drop Stored Procedure dbo.apps_PolicingRate.'
	DROP PROCEDURE [dbo].apps_PolicingRate
END
PRINT '**** Creating Stored Procedure dbo.apps_PolicingRate...'
PRINT ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.apps_PolicingRate
(
	@interval				INT = 60,
	@count					INT = 12
)
AS
-- PROCEDURE:	apps_PolicingRate
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Stored procedure that performs a colation of data in specified intervals based on interval provided, to get rate of policing

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 07 Mar 2016	SS		RFC10495	1	Procedure created
-- 23 APR 2016	SF		RFC10495	2	Formatting
-- 25 Mar 2020	BS		DR-53173	3	Policing Dashboard has an expensive SQL query

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON

DECLARE @lastTime DATETIME
DECLARE @baseTime DateTime
DECLARE @startDate datetime;

SELECT @lastTime = CURRENT_TIMESTAMP
SELECT @baseTime = DATEADD(HOUR,DATEDIFF(HOUR,0,@lastTime),0)
SET @startDate = DATEADD (mi, -1 * @interval * (@count + 2), GETDATE ());

;WITH timeSlots AS
(
    SELECT DATEADD(MINUTE, @interval, @baseTime) slot, 1 Num
    UNION ALL
    SELECT DATEADD(MINUTE, @interval * -1,slot), Num+1
    FROM timeSlots
    WHERE Num < @count
)

SELECT ts.slot as Slot, ISNULL(data.enterQueue, 0) AS EnterQueue, ISNULL(data.exitQueue, 0) AS ExitQueue
FROM timeSlots ts LEFT OUTER JOIN 
(SELECT timeVal, 
		SUM(CASE WHEN idat.LOGACTION ='I' THEN 1 ELSE 0 END) AS enterQueue, 
		SUM(CASE WHEN idat.LOGACTION ='D' THEN 1 ELSE 0 END) AS exitQueue
  FROM (
	SELECT dateadd(HOUR, DATEDIFF(HOUR, 0, LOGDATETIMESTAMP) + 1, 0) AS timeVal , logaction AS logaction
    FROM POLICING_iLOG (NOLOCK)
	WHERE
        LOGDATETIMESTAMP > @startDate
	) idat
	GROUP BY timeVal) data ON ts.slot = data.timeVal
ORDER BY ts.slot
GO

GRANT EXECUTE ON dbo.apps_PolicingRate TO PUBLIC
