-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCaseList 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCaseList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCaseList.'
	Drop procedure [dbo].[csw_DeleteCaseList]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCaseList...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_DeleteCaseList
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnListKey		int,
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	csw_DeleteCaseList
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 MAR 2011	KR		RFC6563	1		Procedure created
-- 27 APR 2011	KR		RFC100511	2	Delete prime case when the case list is deleted

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)
Declare @sAlertXML	nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = 'Delete from CASELISTMEMBER 
			   Where CASELISTNO = @pnListKey
			   AND PRIMECASE = 1'
	
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@pnListKey int',
	@pnListKey = @pnListKey
	
	If @nErrorCode = 0
	Begin

		Set @sSQLString = 'Delete from CASELIST 
				   Where CASELISTNO = @pnListKey
				   AND (LOGDATETIMESTAMP is null or LOGDATETIMESTAMP = @pdtLastModifiedDate)'
		
		exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnListKey int,
		@pdtLastModifiedDate	datetime',
		@pnListKey = @pnListKey,
		@pdtLastModifiedDate = @pdtLastModifiedDate
	End
	
	if (@@ROWCOUNT = 0)
	Begin
		-- Case List not found
		Set @sAlertXML = dbo.fn_GetAlertXML('CCF1', 'Concurrency error. Case List has been changed or deleted. Please reload and try again.',
							null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = 1
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCaseList to public
GO
