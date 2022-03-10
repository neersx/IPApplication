-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fi_CreateTempWorkHistory									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fi_CreateTempWorkHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.fi_CreateTempWorkHistory.'
	Drop procedure [dbo].[fi_CreateTempWorkHistory]
End
Print '**** Creating Stored Procedure dbo.fi_CreateTempWorkHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS off
GO


CREATE PROCEDURE dbo.fi_CreateTempWorkHistory
(
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnRefEntityNo			int		= null,		
	@pnRefTransNo			int		= null		 
)
as
-- PROCEDURE:	fi_CreateTempWorkHistory
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Extract Workhistory data, included on bills that are being paid, into a temp table for a given transaction (e.g remittance/credit allocation).  
--		The purpose is to improve performance by referencing this temp table instead of the WH as there may be large number of bills being paid at the same time.
--		Apply to cash accounting only.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Apr 2014	DL	46647	 1	Procedure created.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode int

-- Note: Client server issue - This temp table is required to be created outside of this stored procedure and from Centura so that it will be visible in other stored procedure (i.e. fi_CreateWipPayment)

--CREATE TABLE #TEMP_WORKHISTORY_WP(
--	[ENTITYNO] [int], 
--	[TRANSNO] [int],
--	[WIPSEQNO] [smallint],
--	[HISTORYLINENO] [smallint],
--	[TRANSTYPE] [smallint] ,
--	[WIPCODE] [nvarchar](6) collate database_default,
--	[CASEID] [int],
--	[LOCALTRANSVALUE] [decimal](11, 2),
--	[FOREIGNTRANVALUE] [decimal](11, 2),
--	[STATUS] [smallint],
--	[MOVEMENTCLASS] [smallint],
--	[MARGINFLAG] [bit],
--	[DISCOUNTFLAG] [decimal](1, 0),
--	[REFENTITYNO] [int],
--	[REFTRANSNO] [int]
--) 


set @nErrorCode = 0



If @nErrorCode = 0 and OBJECT_ID('tempdb..#GLMAPPING') is not null
Begin
	Insert into #TEMP_WORKHISTORY_WP(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, TRANSTYPE, WIPCODE, CASEID, LOCALTRANSVALUE, FOREIGNTRANVALUE, STATUS, MOVEMENTCLASS, MARGINFLAG, DISCOUNTFLAG, REFENTITYNO, REFTRANSNO)
	Select distinct WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.HISTORYLINENO, WH.TRANSTYPE, WH.WIPCODE, WH.CASEID, WH.LOCALTRANSVALUE, WH.FOREIGNTRANVALUE,  WH.STATUS, WH.MOVEMENTCLASS, WH.MARGINFLAG, WH.DISCOUNTFLAG,  WH.REFENTITYNO, WH.REFTRANSNO 
	from #GLMAPPING TEMP
	join WORKHISTORY WH ON WH.REFENTITYNO = TEMP.KeyField3 
				AND WH.REFTRANSNO = TEMP.KeyField4 
	where TEMP.LEDGER = 2
	and WH.MOVEMENTCLASS = 2

	Set @nErrorCode = @@error
End
Else If @nErrorCode = 0 and @pnRefEntityNo is not null and @pnRefTransNo is not null 
Begin
	Insert into  #TEMP_WORKHISTORY_WP(ENTITYNO, TRANSNO, WIPSEQNO, HISTORYLINENO, TRANSTYPE, WIPCODE, CASEID, LOCALTRANSVALUE, FOREIGNTRANVALUE, STATUS, MOVEMENTCLASS, MARGINFLAG, DISCOUNTFLAG, REFENTITYNO, REFTRANSNO)
	Select distinct WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, WH.HISTORYLINENO, WH.TRANSTYPE, WH.WIPCODE, WH.CASEID, WH.LOCALTRANSVALUE, WH.FOREIGNTRANVALUE,  WH.STATUS, WH.MOVEMENTCLASS, WH.MARGINFLAG, WH.DISCOUNTFLAG,  WH.REFENTITYNO, WH.REFTRANSNO 
	from WORKHISTORY WH 
	where WH.REFENTITYNO = @pnRefEntityNo
	AND WH.REFTRANSNO = @pnRefTransNo 
	and WH.MOVEMENTCLASS = 2

	Set @nErrorCode = @@error
End


Return @nErrorCode
GO

Grant execute on dbo.fi_CreateTempWorkHistory to public
GO

