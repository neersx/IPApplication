-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_RWCalculateForecastData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_RWCalculateForecastData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_RWCalculateForecastData.'
	Drop procedure [dbo].[gl_RWCalculateForecastData]
End
Print '**** Creating Stored Procedure dbo.gl_RWCalculateForecastData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.gl_RWCalculateForecastData
(
	@psTempTableName 	nvarchar(128),	-- A temporary table that stores the ledger accounts and profit centres to be queried.
	@psTempRelatedTable 	nvarchar(128),	-- A temporary table that stores the ledger accounts to be queried and their corresponding children.
	@psColumnName 		nvarchar(128),	-- A column name in @psTempTableName, which will stores the sum of forecast movements.
	@pnPeriodFrom 		int,		-- Indicates from which period the forecast data will be returned.
	@pnPeriodTo 		int		-- Indicates to which period the forecast data will be returned.
)
as
-- PROCEDURE:	gl_RWCalculateForecastData
-- VERSION:	4
-- SCOPE:	InPro
-- DESCRIPTION:	Calculates forecast related data

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Mar 2004	MB	8809	1	Procedure created
-- 02 Sep 2004	JEK	RFC1377	2	Pass new Centura parameter to fn_WrapQuotes and fn_ConstructOperator
-- 22 May 2006	AT	12563	3	Added isnulls to cater for NULL Forecast Amounts.
-- 12 Dec 2006	AT	13909	4	Fixed joins in traverse account table.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSql nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
		 Set @sSql = 'Update ' + @psTempTableName + ' 
		set ' + @psColumnName + ' = (
		select  
			SUM (isnull(FRCSTAMOUNT, 0)) 
		from  	BUDGET B,  
			PROFITCENTRE PC, ' + 
			@psTempRelatedTable + ' RA 
		where
			PC.PROFITCENTRECODE = B.PROFITCENTRECODE
		and 	PC.ENTITYNO= TMP.ENTITYNO
		and 	B.LEDGERACCOUNTID= RA.CHILDID 
		and	B.PROFITCENTRECODE = TMP.PROFITCENTRECODE
		and	B.PERIODID ' + dbo.fn_ConstructOperator(7 ,'N' ,cast ( @pnPeriodFrom as varchar),cast ( @pnPeriodTo as varchar) ,0) +
	' 	and 	RA.PARENTID = TMP.ACCOUNTID) 
		from ' + @psTempTableName + ' TMP join LEDGERACCOUNT LA 
			on (TMP.ACCOUNTID = LA.ACCOUNTID )
		where LA.BUDGETMOVEMENT = 1 '

	 exec @nErrorCode=sp_executesql @sSql
End

-- update budget movement where the BUDGETMOVEMENT flag is set to 0
If @nErrorCode = 0
Begin
		 Set @sSql = 'Update ' + @psTempTableName + ' 
		set ' + @psColumnName + ' = (
		select 
			SUM (isnull(FORECASTAMOUNT, 0)) 
		from  	(select A.ENTITYNO,  A.LEDGERACCOUNTID,A.PROFITCENTRECODE, A.PERIODID, A.FRCSTAMOUNT AS FORECASTAMOUNT
			from BUDGET A join LEDGERACCOUNT LA on (A.LEDGERACCOUNTID = LA.ACCOUNTID )
			where NOT EXISTS (SELECT 1 
			from BUDGET B 
			where 	A.LEDGERACCOUNTID = B.LEDGERACCOUNTID
			and 	A.PROFITCENTRECODE = B.PROFITCENTRECODE 
			and 	A.PERIODID > B.PERIODID 
			and 	B.BUDGETAMOUNT IS NOT NULL) 
			and 	LA.BUDGETMOVEMENT = 0 
			and 	A.FRCSTAMOUNT IS NOT NULL
			UNION ALL
			select A.ENTITYNO, A.LEDGERACCOUNTID,A.PROFITCENTRECODE, A.PERIODID,  A.FRCSTAMOUNT - B.FRCSTAMOUNT AS FORECASTAMOUNT
			from  BUDGET A join  BUDGET B 
			on (A.LEDGERACCOUNTID = B.LEDGERACCOUNTID
				and A.PROFITCENTRECODE = B.PROFITCENTRECODE)
			join LEDGERACCOUNT LA on (A.LEDGERACCOUNTID = LA.ACCOUNTID )
			where 	LA.BUDGETMOVEMENT = 0 
			and 	A.FRCSTAMOUNT IS NOT NULL
			and 	B.FRCSTAMOUNT IS NOT NULL
			and 	A.PERIODID > B.PERIODID
			and 	B.PERIODID = (SELECT MAX(PERIODID)  FROM BUDGET C
			where 	C.LEDGERACCOUNTID = A.LEDGERACCOUNTID
			and C.PROFITCENTRECODE = A.PROFITCENTRECODE 
			and C.PERIODID < A.PERIODID 
			and C.FRCSTAMOUNT IS NOT NULL))  B,  ' + 
			@psTempRelatedTable + ' RA 
		where 	B.ENTITYNO= TMP.ENTITYNO
		and 	B.LEDGERACCOUNTID= RA.CHILDID 
		and	B.PROFITCENTRECODE = TMP.PROFITCENTRECODE
		and	B.PERIODID ' + dbo.fn_ConstructOperator(7 ,'N' ,cast ( @pnPeriodFrom as varchar),cast ( @pnPeriodTo as varchar) ,0) +
	' 	and 	RA.PARENTID = TMP.ACCOUNTID) 
		from ' + @psTempTableName + ' TMP join LEDGERACCOUNT LA 
			on (TMP.ACCOUNTID = LA.ACCOUNTID )
		where LA.BUDGETMOVEMENT = 0 '

	 exec @nErrorCode=sp_executesql @sSql
End

Return @nErrorCode
GO

Grant execute on dbo.gl_RWCalculateForecastData to public
GO
