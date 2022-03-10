-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCaseListCase 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCaseListCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCaseListCase.'
	Drop procedure [dbo].[csw_DeleteCaseListCase]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCaseListCase...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_DeleteCaseListCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnListKey		int,
	@pnCaseKey		int,
	@pdtLastModifiedDate	datetime
)
as
-- PROCEDURE:	csw_DeleteCaseListCase
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Deletes cases list members

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 MAR 2011	KR		RFC6563	1		Procedure created
-- 15 APR 2011	KR		RFC100511 2		Fixed bug with the null date check

SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare	@sSQLString	nvarchar(2000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = 'Delete from CASELISTMEMBER 
			   Where CASELISTNO = @pnListKey
			   AND	CASEID = @pnCaseKey
			   AND (LOGDATETIMESTAMP = @pdtLastModifiedDate or LOGDATETIMESTAMP is null)'
	
	exec @nErrorCode=sp_executesql @sSQLString,
	N'@pnListKey int,
	@pnCaseKey int,
	@pdtLastModifiedDate	datetime',
	@pnListKey = @pnListKey,
	@pnCaseKey = @pnCaseKey,
	@pdtLastModifiedDate = @pdtLastModifiedDate
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCaseListCase to public
GO
