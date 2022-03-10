-----------------------------------------------------------------------------------------------------------------------------
-- Creation of api_DeleteActivity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[api_DeleteActivity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.api_DeleteActivity.'
	Drop procedure [dbo].[api_DeleteActivity]
End
Print '**** Creating Stored Procedure dbo.api_DeleteActivity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.api_DeleteActivity
(
	@pnActivityNo		int	-- Mandatory
)
as
-- PROCEDURE :	api_DeleteActivity
-- VERSION :	1
-- DESCRIPTION:	Delete row from ACTIVITY table
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 07/01/2008	LITS			Procedure created
-- 09/01/2008	MF	15817	1	CPASS standards applied

SET NOCOUNT ON

Declare @sSQLString	nvarchar(4000)
Declare @nErrorCode 	int

Set @nErrorCode=0

If @nErrorCode=0
Begin
	Set @sSQLString='DELETE from ACTIVITY where ACTIVITYNO=@pnActivityNo'
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnActivityNo		int',
				  @pnActivityNo=@pnActivityNo
End

RETURN @nErrorCode
GO

Grant execute on dbo.api_DeleteActivity to public
GO
