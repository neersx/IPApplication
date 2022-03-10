SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteAlert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteAlert.'
	Drop procedure [dbo].[ip_DeleteAlert]
End
Print '**** Creating Stored Procedure dbo.ip_DeleteAlert...'
Print ''
GO

CREATE PROCEDURE dbo.ip_DeleteAlert
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int,
	@pdtAlertDateCreated	datetime

)
-- PROCEDURE:	ip_DeleteAlert
-- VERSION:	1
-- SCOPE:	CPA.net
-- DESCRIPTION:	Delete an ad hoc reminder.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 27-MAR-2003  JEK	1	Procedure created.  RFC03 Case Workflow.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Delete from ALERT
	where 	EMPLOYEENO = @pnEmployeeKey
	and	ALERTSEQ = @pdtAlertDateCreated

	set @nErrorCode = @@error
End

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteAlert to public
GO

