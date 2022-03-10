-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateActionEvent
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateActionEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_UpdateActionEvent.'
	Drop procedure [dbo].[cs_UpdateActionEvent]
	Print '**** Creating Stored Procedure dbo.cs_UpdateActionEvent...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_UpdateActionEvent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaKey		int		= null,
	@psActionKey		nvarchar(2),
	@psCaseKey		nvarchar(11),
	@psEventKey		nvarchar(11)	= null,
	@pnEventCycle		smallint	= null,
	@psEventDescription	nvarchar(254)	= null,	-- Used for Alerts only
	@pdtEventDueDate	datetime	= null,
	@pdtEventDate		datetime	= null,
	@psEventText		ntext		= null,
	@pbIsNew		bit		= null,
	@pnAlertEmployeeKey	int		= null,
	@pdtAlertDateCreated	datetime	= null,

	@pnPolicingBatchNo	int 		= null,

	@pbEventDescriptionModified	bit	= null,
	@pbEventDueDateModified		bit	= null,
	@pbEventDateModified		bit	= null,
	@pbEventTextModified		bit	= null
)
-- PROCEDURE:	cs_UpdateActionEvent
-- VERSION:	2
-- SCOPE:	CPA.net
-- DESCRIPTION:	Maintain events against an action, or update an existing ad hoc reminder.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 27-MAR-2003  JEK	1	Procedure created.  RFC03 Case Workflow.
-- 15 Apr 2013	DV	2	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nCaseKey int
Declare @nEventKey int

Set @nErrorCode = 0
Set @nCaseKey = cast(@psCaseKey as int)
Set @nEventKey = cast(@psEventKey as int)

If @nErrorCode = 0
and @psActionKey = '__'
begin
	exec @nErrorCode = ip_UpdateAlert
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnEmployeeKey		= @pnAlertEmployeeKey,
		@pdtAlertDateCreated	= @pdtAlertDateCreated,
		@psAlertMessage		= @psEventDescription,
		@pdtDueDate		= @pdtEventDueDate,
		@pdtDateOccurred	= @pdtEventDate,
		@pbAlertMessageModified	= @pbEventDescriptionModified,
		@pbDueDateModified	= @pbEventDueDateModified,
		@pbDateOccurredModified	= @pbEventDateModified
end

If @nErrorCode = 0
and @psActionKey != '__'
begin
	If @pbIsNew = 1
	begin
		exec @nErrorCode = cs_InsertCaseEvent
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pnCaseKey			= @nCaseKey,
			@pnEventKey			= @nEventKey,
			@pnCycle			= @pnEventCycle,
			@pdtEventDueDate		= @pdtEventDueDate,
			@pdtEventDate			= @pdtEventDate,
			@psEventText			= @psEventText,
			@psCreatedByActionKey		= @psActionKey,
			@pnCreatedByCriteriaKey		= @pnCriteriaKey,
			@pnPolicingBatchNo		= @pnPolicingBatchNo

	end
	Else
	begin
		exec @nErrorCode = cs_UpdateCaseEvent
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pnCaseKey			= @nCaseKey,
			@pnEventKey			= @nEventKey,
			@pnCycle			= @pnEventCycle,
			@pdtEventDueDate		= @pdtEventDueDate,
			@pdtEventDate			= @pdtEventDate,
			@psEventText			= @psEventText,
			@pnPolicingBatchNo		= @pnPolicingBatchNo,
			@pbEventDueDateModified		= @pbEventDueDateModified,
			@pbEventDateModified		= @pbEventDateModified,
			@pbEventTextModified		= @pbEventTextModified
	end
end

Return @nErrorCode
GO

Grant execute on dbo.cs_UpdateActionEvent to public
GO
