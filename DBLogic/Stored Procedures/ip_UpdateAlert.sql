SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateAlert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateAlert.'
	Drop procedure [dbo].[ip_UpdateAlert]
End
Print '**** Creating Stored Procedure dbo.ip_UpdateAlert...'
Print ''
GO

CREATE PROCEDURE dbo.ip_UpdateAlert
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int,
	@pdtAlertDateCreated	datetime,
	@psAlertMessage		nvarchar(254)	= null,
	@pdtDueDate		datetime	= null,
	@pdtDateOccurred	datetime	= null,

	@pbAlertMessageModified	bit		= null,
	@pbDueDateModified	bit		= null,
	@pbDateOccurredModified	bit		= null

)
-- PROCEDURE:	ip_UpdateAlert
-- VERSION:	1
-- SCOPE:	CPA.net
-- DESCRIPTION:	Create a new Alert.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 27-MAR-2003  JEK	1	Procedure created.  RFC03 Case Workflow.

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nEmployeeKey int
Declare @nSequenceNo int

Set @nErrorCode = 0

If @nErrorCode = 0
and (@pbDueDateModified = 1 or @pbDateOccurredModified = 1)
and @pdtDueDate is null
and @pdtDateOccurred is null
Begin
	-- Clearing the dates indicates that a delete is required
	exec @nErrorCode = ip_DeleteAlert
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnEmployeeKey		= @pnEmployeeKey,
		@pdtAlertDateCreated	= @pdtAlertDateCreated

	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
and @pdtDueDate is not null
Begin
	Update 	ALERT
	set 	ALERTMESSAGE = case when @pbAlertMessageModified = 1 then @psAlertMessage else ALERTMESSAGE end,
		DUEDATE = case when @pbDueDateModified = 1 then @pdtDueDate else DUEDATE end,			
		DATEOCCURRED = case when @pbDateOccurredModified = 1 then @pdtDateOccurred else DATEOCCURRED end,
		OCCURREDFLAG = case when @pbDateOccurredModified = 1 
			then case when @pdtDateOccurred is null then 0 else 3 end  
			else OCCURREDFLAG end
	where 	EMPLOYEENO = @pnEmployeeKey
	and	ALERTSEQ = @pdtAlertDateCreated

	set @nErrorCode = @@error
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateAlert to public
GO

