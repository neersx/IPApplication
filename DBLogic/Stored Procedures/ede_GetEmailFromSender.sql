-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_GetEmailFromSender
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_GetEmailFromSender]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_GetEmailFromSender.'
	Drop procedure [dbo].[ede_GetEmailFromSender]
End
Print '**** Creating Stored Procedure dbo.ede_GetEmailFromSender...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_GetEmailFromSender
		@pnActivityId	int
AS
-- PROCEDURE :	ede_GetEmailFromSender
-- VERSION :	1
-- DESCRIPTION:	Get the Sender main email against a Document Request given an ActivityRequest row.
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change Description
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 24/05/2007	vql	12302	1	Procedure created

DECLARE @nErrorCode int,
	@sMainEmail nvarchar(50),
	@sSQLStatement nvarchar(1000),
	@nBatchNo int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLStatement = "select @nBatchNo = BATCHNO from ACTIVITYREQUEST WHERE ACTIVITYID = @pnActivityId"

	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@nBatchNo int OUTPUT,
			@pnActivityId int',
			@nBatchNo = @nBatchNo OUTPUT,
			@pnActivityId = @pnActivityId
End

If @nBatchNo is null
Begin
	Set @nErrorCode = 1
End

If @nErrorCode = 0
Begin
	Set @sSQLStatement = "
			Select @sMainEmail = rtrim(T.TELECOMNUMBER)
			from EDESENDERDETAILS E
			join NAME N on (E.SENDERNAMENO = N.NAMENO)
			left join TELECOMMUNICATION T ON (N.MAINEMAIL = T.TELECODE)
			where E.BATCHNO = @nBatchNo
			"
	
	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@sMainEmail nvarchar(50) OUTPUT,
			@nBatchNo int',
			@sMainEmail = @sMainEmail OUTPUT,
			@nBatchNo = @nBatchNo
End

If @nErrorCode = 0
Begin
	-- Return the results
	Set @sSQLStatement = "
		select  1 as TAG, 0 as PARENT,
		NULL AS [eMailAddresses!1!element],
		@sMainEmail as [eMailAddresses!1!Main!element]
		for xml explicit"

	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@sMainEmail nvarchar(50)',
			@sMainEmail = @sMainEmail
End

Return @nErrorCode
GO

Grant execute on dbo.ede_GetEmailFromSender to public
GO
