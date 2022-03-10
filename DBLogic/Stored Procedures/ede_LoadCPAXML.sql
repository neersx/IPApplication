-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_LoadCPAXML
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_LoadCPAXML]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_LoadCPAXML.'
	Drop procedure [dbo].[ede_LoadCPAXML]
End
Print '**** Creating Stored Procedure dbo.ede_LoadCPAXML...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_LoadCPAXML
(
			@pnRowCount	int=0	OUTPUT,
			@psUserName	nvarchar(40),
			@pnMode		int=2			-- 1 = cleanup, 2 = process (2)
)
as
-- PROCEDURE:	ede_LoadCPAXML
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the EDE CPA-XML holding tables with the contents of the XML.
--		NOTE: If adding/removing EDE tables, you must also remove the references
--		to these tables from stored procs ede_ClearCorruptBatch and ede_UpdateKeys.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10/05/2006	AT	12296	1	Procedure Created
-- 04/10/2006	VL	12995	2	Data and name mapping
-- 02/01/2006	AT	13997	3	Added pre-import error checking
-- 14/04/2008	PK	16219	4	Change call to ede_MapData to asnynchronous processing
-- 06/03/2012	NML	20412	5	Add in call to unmap procedure for CPA mapping solution
-- 08/01/2013	NML	21484	6	Only look at mapping table control not inbound

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
 
Declare	@nErrorCode 	int
Declare	@sUserName	nvarchar(40)
Declare @nNextImport	int
Declare @nBatchNo	int
Declare @nProcessId	int
declare @sSQLString 	nvarchar(1000)

-- Initialize variables
Set @nErrorCode = 0

-- @pnMode = 1 is run before data is imported.
If @nErrorCode = 0 and @pnMode = 1
Begin
	Set @sUserName = user
	Exec @nErrorCode = ede_ClearCorruptBatch @sUserName
End

-- @pnMode = 2 is run after data is imported.
If @nErrorCode = 0 and @pnMode = 2
Begin
	Exec @nErrorCode = ede_UpdateKeys @psUserName, @nBatchNo OUTPUT
	
	If @nErrorCode = 0
	Begin
		Exec @nErrorCode = ede_ValidateBatchHeader @nBatchNo
	End

	--Map receiver case identifier from external ID to internal ID.
	--Applicable for CPA TM1 only.
	IF @nErrorCode = 0	AND 
		(isnull((SELECT colboolean FROM sitecontrol WHERE controlid = 'Mapping Table Control'), 0) = 1
		)
	BEGIN
		--EXEC @nErrorCode = dbo.usp_UnmapEDEBatch @nBatchNo
		SET @sSQLString = 'exec @nErrorCode = dbo.usp_UnmapEDEBatch ' + cast(@nBatchNo AS NVARCHAR)
		EXEC sp_executesql @sSQLString, N'@nErrorCode int OUTPUT', @nErrorCode OUTPUT
	END

	IF @nErrorCode = 0
	BEGIN
		SET @sUserName = user

		Insert into PROCESSREQUEST (BATCHNO, CASEID, REQUESTDATE, CONTEXT, SQLUSER, REQUESTTYPE, REQUESTDESCRIPTION, STATUSCODE)
		values (@nBatchNo, null, getdate(), 'EDE', @sUserName, 'EDE Resubmit Batch', 'Resubmit EDE batch for data maping and update live data', 14020)

		Set @nProcessId = scope_identity()
		Set @nErrorCode = @@error
	End

	If @nErrorCode = 0
	Begin
		Set @sSQLString = 'exec ede_MapData null, null, ' + cast(@nBatchNo as varchar(10)) + ', ' + cast(@nProcessId as varchar(10))
		Exec @nErrorCode = ede_AsynchMapData @nProcessId, @sSQLString
	End

End

Return @nErrorCode
GO

grant execute on dbo.ede_LoadCPAXML to public
go
