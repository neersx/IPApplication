-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_GetDocRequestEmails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_GetDocRequestEmails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_GetDocRequestEmails.'
	Drop procedure [dbo].[ede_GetDocRequestEmails]
End
Print '**** Creating Stored Procedure dbo.ede_GetDocRequestEmails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_GetDocRequestEmails
		@pnActivityId	int
AS
-- PROCEDURE :	ede_GetDocRequestEmails
-- VERSION :	3
-- DESCRIPTION:	Get the main and copies to e-mails stored against a Document Request given an ActivityRequest row.
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change Description
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 08/05/2007	AT	12330	1	Procedure created
-- 24/05/2007	AT	12330	2	Modified retrieval of Main e-mail
-- 10/09/2008	DL	16894	3	Retrieve e-mail address of the sender of ede batch if exist BATCHNO

DECLARE @nErrorCode int,
	@nRequestId int,
	@nBatchNo int,
	@sMainEmail nvarchar(50),
	@sCopiesTo nvarchar(4000),
	@sSQLStatement nvarchar(1000)

Set @nErrorCode = 0

If @nErrorCode = 0 
Begin
	Set @sSQLStatement = "select @nRequestId = REQUESTID, 
			@nBatchNo = BATCHNO 
			from ACTIVITYREQUEST 
			WHERE ACTIVITYID = @pnActivityId"

	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@nRequestId int OUTPUT,
			@nBatchNo int OUTPUT,
			@pnActivityId int',
			@nRequestId = @nRequestId OUTPUT,
			@nBatchNo = @nBatchNo OUTPUT,
			@pnActivityId = @pnActivityId
End

If @nRequestId is null and @nBatchNo is null
Begin
	Set @nErrorCode = 1
End

If @nErrorCode = 0 and @nRequestId is not null
Begin
	-- Get the main e-mail
	Set @sSQLStatement = "
			SELECT @sMainEmail = RTRIM(ISNULL(DRE.EMAIL, T.TELECOMNUMBER))
			FROM DOCUMENTREQUEST D
			Left Join DOCUMENTREQUESTEMAIL DRE ON (DRE.REQUESTID = D.REQUESTID 
													AND DRE.ISMAIN = 1)
			Join NAME N ON (D.RECIPIENT = N.NAMENO)
			Left Join TELECOMMUNICATION T ON (N.MAINEMAIL = T.TELECODE)
			WHERE D.REQUESTID = @nRequestId
			"
	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@sMainEmail nvarchar(50) OUTPUT,
			@nRequestId int',
			@sMainEmail = @sMainEmail OUTPUT,
			@nRequestId = @nRequestId

	If @nErrorCode = 0
	Begin
		-- Get the copies to e-mails
		Set @sSQLStatement = "select @sCopiesTo = Case when @sCopiesTo is null
								then RTRIM(EMAIL)
								else @sCopiesTo + ', ' + RTRIM(EMAIL)
								end
								FROM DOCUMENTREQUESTEMAIL 
								Where REQUESTID = @nRequestId
								and ISMAIN != 1"
		exec @nErrorCode = sp_executesql @sSQLStatement,
				N'@sCopiesTo nvarchar(4000) OUTPUT,
				@nRequestId int',
				@sCopiesTo = @sCopiesTo OUTPUT,
				@nRequestId = @nRequestId
	End
End



-- Get main e-mail address of the batch sender 
If @nErrorCode = 0 and @nRequestId is null and @nBatchNo is not null
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
		@sMainEmail as [eMailAddresses!1!Main!element],
		@sCopiesTo as [eMailAddresses!1!CC!element]
		for xml explicit"

	exec @nErrorCode = sp_executesql @sSQLStatement,
			N'@sMainEmail nvarchar(50),
			@sCopiesTo nvarchar(4000)',
			@sMainEmail = @sMainEmail,
			@sCopiesTo = @sCopiesTo
End

Return @nErrorCode
GO

Grant execute on dbo.ede_GetDocRequestEmails to public
GO
