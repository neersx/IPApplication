-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_UpdateKeys
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_UpdateKeys]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_UpdateKeys.'
	Drop procedure [dbo].[ede_UpdateKeys]
End
Print '**** Creating Stored Procedure dbo.ede_UpdateKeys...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_UpdateKeys
(
	@psUserName	nvarchar(40),
	@pnBatchNo	int OUTPUT
)
as
-- PROCEDURE:	ede_UpdateKeys
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates the keys of the EDE holding tables with a generated key.
--		NOTE: If adding/removing EDE tables, you must also remove the references
--		to these tables from stored proc ede_ClearCorruptBatch.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10/05/2006	AT	12296	1	Procedure Created
-- 28/06/2006	AT	12296	2	Modified table structures.
-- 07/09/2006	AT	13219	3	Modified status to use TableCodes.
-- 06/10/2006	AT	13451	4	Updated for changes in Attention Of group element.
-- 23/10/2006	AT	13451	5	Updated for new Patent Term Adjustment element.
-- 20/02/2009	AT	17420	6	Added transcation processing.
-- 20/08/2014	AT	R37920	7	Wrap assignment of batch no into another stored procedure.
 
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
 
Declare	@nErrorCode 	int
Declare	@sUserName	nvarchar(40)
Declare @nNextImport int
Declare @nBatchNo int
Declare @sSql nvarchar(1000)
Declare @TransactionCountStart 	int

-- Initialize variables
Set @nErrorCode = 0

-- Get the Import number from the temporary table.
if @nErrorCode = 0
Begin
	Set @sSql = "SELECT @nNextImport = NUMERICID FROM ##PROCESS1" + @psUserName

	Exec sp_executesql @sSql, N'@nNextImport int OUTPUT',
					@nNextImport		OUTPUT
End

If @nNextImport is null
Begin
	-- Fail safe. If the temp table row has failed, get the number from the table directly.
	-- This caters for rows in the queue and rows being processed immediately.
	SET @sSql = "(SELECT @nNextImport = MIN(IMPORTQUEUENO)
				FROM IMPORTQUEUE 
				WHERE (ONHOLDFLAG IN (0,2)
				AND PROCESSEDFLAG is null
				AND WHENPROCESSED IS NULL)
				or
				(ONHOLDFLAG=0 
				AND PROCESSEDFLAG = 0)
				HAVING MIN(IMPORTQUEUENO) IS NOT NULL)"

	Exec sp_executesql @sSql, N'@nNextImport int OUTPUT',
					@nNextImport		OUTPUT

End

-- Commence the transaction
Set @TransactionCountStart = @@TranCount
BEGIN TRANSACTION

If @nNextImport is not null
Begin
	UPDATE EDETRANSACTIONHEADER
	SET IMPORTQUEUENO=@nNextImport,
	BATCHSTATUS=1280
	WHERE EDETRANSACTIONHEADER.IMPORTQUEUENO IS NULL
	and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Exec @nErrorCode = ede_AssignBatchNumber
				@pnBatchNo = @nBatchNo output
End

	
If @@TranCount > @TransactionCountStart
Begin
	If @nErrorCode = 0
	Begin
		COMMIT TRANSACTION
	End
	Else
	Begin
		ROLLBACK TRANSACTION
	End
End

-- Return the output
Set @pnBatchNo = @nBatchNo

Return @nErrorCode
GO

Grant execute on dbo.ede_UpdateKeys to public
GO
