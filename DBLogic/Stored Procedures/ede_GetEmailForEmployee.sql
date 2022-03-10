-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_GetEmailForEmployee
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_GetEmailForEmployee]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_GetEmailForEmployee.'
	Drop procedure [dbo].[ede_GetEmailForEmployee]
End
Print '**** Creating Stored Procedure dbo.ede_GetEmailForEmployee...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_GetEmailForEmployee
		@pnActivityId	int
AS
-- PROCEDURE :	ede_GetEmailForEmployee
-- VERSION :	1
-- DESCRIPTION:	Get the Employee main email given an ActivityRequest row.
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change Description
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 06/06/2007	vql	12302	1	Procedure created

DECLARE @nErrorCode int,
	@sMainEmail nvarchar(50),
	@sSQLStatement nvarchar(1000),
	@nEmployeeNo int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLStatement = "select @nEmployeeNo = EMPLOYEENO from ACTIVITYREQUEST WHERE ACTIVITYID = @pnActivityId"

	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@nEmployeeNo int OUTPUT,
			@pnActivityId int',
			@nEmployeeNo = @nEmployeeNo OUTPUT,
			@pnActivityId = @pnActivityId
End

If @nEmployeeNo is null
Begin
	Set @nErrorCode = 1
End

If @nErrorCode = 0
Begin
	Set @sSQLStatement = "
			Select @sMainEmail = rtrim(T.TELECOMNUMBER)
			from NAME N
			left join TELECOMMUNICATION T ON (N.MAINEMAIL = T.TELECODE)
			where N.NAMENO = @nEmployeeNo
			"
	
	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@sMainEmail nvarchar(50) OUTPUT,
			@nEmployeeNo int',
			@sMainEmail = @sMainEmail OUTPUT,
			@nEmployeeNo = @nEmployeeNo
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

Grant execute on dbo.ede_GetEmailForEmployee to public
GO
