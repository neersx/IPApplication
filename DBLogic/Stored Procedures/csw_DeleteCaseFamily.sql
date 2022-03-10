-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCaseFamily
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCaseFamily]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCaseFamily.'
	Drop procedure [dbo].[csw_DeleteCaseFamily]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCaseFamily...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_DeleteCaseFamily
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psFamilyKey		nvarchar(40),
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	csw_DeleteCaseFamily
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 Feb 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)
Declare @sAlertXML	nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 'Delete from CASEFAMILY 
			   Where FAMILY = @psFamilyKey
			   AND (LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)'
	
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@psFamilyKey nvarchar(40),
	@pdtLastModifiedDate	datetime',
	@psFamilyKey = @psFamilyKey,
	@pdtLastModifiedDate = @pdtLastModifiedDate
	
	if (@@ROWCOUNT = 0)
	Begin
		-- BillMapProfile not found
		Set @sAlertXML = dbo.fn_GetAlertXML('CCF1', 'Concurrency error. Case Family has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCaseFamily to public
GO
