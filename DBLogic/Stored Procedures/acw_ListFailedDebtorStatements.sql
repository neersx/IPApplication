-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListFailedDebtorStatements
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListFailedDebtorStatements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListFailedDebtorStatements.'
	Drop procedure [dbo].[acw_ListFailedDebtorStatements]
End
Print '**** Creating Stored Procedure dbo.acw_ListFailedDebtorStatements...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListFailedDebtorStatements
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,	
	@pbCalledFromCentura			bit		= 0,		
	@pnProcessID				int	        -- Mandatory
)
as
-- PROCEDURE:	acw_ListFailedDebtorStatements
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to list all the debtor statements which failed along with the failure reasons
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	-------	-------	--------------------------------------- 
-- 16 Jun 2014  DV	R35246	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)

Set @nErrorCode         = 0

If @nErrorCode = 0
Begin
        Set @sSQLString = "
        SELECT  SF.ID as RowKey,
                SF.PERIOD as PostPeriod,
                SF.ENTITYNO as EntityKey,
                SF.SORTBY as DebtorSortByNameCode,
                SF.PRINTPOSITIVEBAL as PrintPositiveBalance,
                SF.PRINTNEGATIVEBAL as PrintNegativeBalance,
                SF.PRINTZEROBAL as PrintZeroWithActivity,
                SF.PRINTZEROBALWOACT as PrintZeroWithoutActivity
        FROM STATEMENTFILTER SF
        WHERE SF.PROCESSID = @pnProcessID"

        exec @nErrorCode = sp_executesql @sSQLString,
			    N'@pnProcessID      int',
			      @pnProcessID      = @pnProcessID
End

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	SELECT  SFR.ID as RowKey,
	        SFR.DEBTORNO as DebtorNo, 
		N.NAMECODE as DebtorNameCode,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO,NULL) as DebtorName,
		SFR.FAILUREREASON	as FailureReason
	FROM STATEMENTFAILUREREASON SFR 
	JOIN NAME N ON (N.NAMENO = SFR.DEBTORNO)
	JOIN STATEMENTFILTER SF on (SF.ID = SFR.FILTERID)
        WHERE SF.PROCESSID = @pnProcessID
	ORDER BY DebtorNameCode"
		
	exec @nErrorCode = sp_executesql @sSQLString,
			    N'@pnProcessID      int',
			      @pnProcessID      = @pnProcessID
End


Return @nErrorCode
go

Grant exec on dbo.acw_ListFailedDebtorStatements to Public
go