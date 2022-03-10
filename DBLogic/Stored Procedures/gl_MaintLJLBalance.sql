-----------------------------------------------------------------------------------------------------------------------------
-- Creation of gl_MaintLJLBalance
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[gl_MaintLJLBalance]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.gl_MaintLJLBalance.'
	Drop procedure [dbo].[gl_MaintLJLBalance]
End
Print '**** Creating Stored Procedure dbo.gl_MaintLJLBalance...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.gl_MaintLJLBalance
(
	@pnUserIdentityId	int		= null,
	@psCulture		nvarchar(5) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbDebug		bit		= 0,
	@pnEntityNo		int,
	@pnTransNo		int
)
as
-- PROCEDURE:	gl_MaintLJLBalance
-- VERSION:	1
-- SCOPE:	called both from Centura code and the fi_PostToGL stored procedure
-- DESCRIPTION:	The LOCALAMOUNT on the on the LEDGERJOURNALLINEs of the current journal 
--		will be inserted or added to the data in the LEDGERJOURNALLINEBALANCE table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 SEP 2005	CR	11735	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sOfficeCulture	nvarchar(5)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @pbDebug = 1
	Begin
		Print 'Update the existing rows in LEDGERJOURNALLINEBALANCE table that match details of the 
			current journal FIRST'
	End

	Update LEDGERJOURNALLINEBALANCE
	SET LOCALAMOUNTBALANCE =LJLB.LOCALAMOUNTBALANCE
					+
					(SELECT ISNULL(SUM(LJL.LOCALAMOUNT), 0)
					FROM LEDGERJOURNALLINE LJL
					WHERE LJL.TRANSNO = TR.TRANSNO 
					and LJL.ENTITYNO = TR.ENTITYNO
					and LJL.PROFITCENTRECODE = LJLB.PROFITCENTRECODE
					AND LJL.ACCOUNTID = LJLB.ACCOUNTID)
	FROM LEDGERJOURNALLINEBALANCE LJLB
	join TRANSACTIONHEADER TR	on (TR.TRANPOSTPERIOD = LJLB.TRANPOSTPERIOD)
	where TR.TRANSTATUS = 1
	and TR.ENTITYNO = @pnEntityNo
	and TR.TRANSNO = @pnTransNo


	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	If @pbDebug = 1
	Begin
		Print 'Insert rows for details that are not already in the BALANCE table'
	End
	
	Insert into LEDGERJOURNALLINEBALANCE ( ACCTENTITYNO,
	PROFITCENTRECODE, ACCOUNTID, TRANPOSTPERIOD, LOCALAMOUNTBALANCE)
	select LJL.ACCTENTITYNO, LJL.PROFITCENTRECODE, LJL.ACCOUNTID,
	TR.TRANPOSTPERIOD, SUM(LJL.LOCALAMOUNT)
	from TRANSACTIONHEADER TR
	inner join  LEDGERJOURNALLINE LJL	on (LJL.TRANSNO = TR.TRANSNO 
	                      			and LJL.ENTITYNO = TR.ENTITYNO)
	where TR.TRANSTATUS = 1
	and TR.ENTITYNO = @pnEntityNo
	and TR.TRANSNO = @pnTransNo
	and not exists (select * 
			from LEDGERJOURNALLINEBALANCE LJLB
			where LJLB.ACCTENTITYNO = LJL.ACCTENTITYNO
			AND   LJLB.PROFITCENTRECODE = LJL.PROFITCENTRECODE
			AND   LJLB.ACCOUNTID = LJL.ACCOUNTID
			AND   LJLB.TRANPOSTPERIOD = TR.TRANPOSTPERIOD)
	group by ACCTENTITYNO, PROFITCENTRECODE, ACCOUNTID, TRANPOSTPERIOD
	ORDER BY 1, 2, 3, 4

	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0 AND @pbDebug = 1
Begin
	select LJL.ACCTENTITYNO, LJL.PROFITCENTRECODE, LJL.ACCOUNTID,
	TR.TRANPOSTPERIOD, SUM(LJL.LOCALAMOUNT), LJLB.LOCALAMOUNTBALANCE
	from TRANSACTIONHEADER TR
	inner join  LEDGERJOURNALLINE LJL	on (LJL.TRANSNO = TR.TRANSNO 
	                      			and LJL.ENTITYNO = TR.ENTITYNO)
	JOIN LEDGERJOURNALLINEBALANCE LJLB	ON (LJL.ACCTENTITYNO = LJLB.ACCTENTITYNO
						AND   LJL.PROFITCENTRECODE = LJLB.PROFITCENTRECODE
						AND   LJL.ACCOUNTID = LJLB.ACCOUNTID
						AND   TR.TRANPOSTPERIOD = LJLB.TRANPOSTPERIOD)
	where TR.TRANSTATUS = 1
	group by LJL.ACCTENTITYNO, LJL.PROFITCENTRECODE, LJL.ACCOUNTID, TR.TRANPOSTPERIOD, LJLB.LOCALAMOUNTBALANCE
	ORDER BY 1, 2, 3, 4	
End

Return @nErrorCode
GO

Grant execute on dbo.gl_MaintLJLBalance to public
GO
