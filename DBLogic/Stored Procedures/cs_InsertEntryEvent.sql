-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertEntryEvent
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertEntryEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertEntryEvent.'
	drop procedure [dbo].[cs_InsertEntryEvent]
	print '**** Creating Stored Procedure dbo.cs_InsertEntryEvent...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_InsertEntryEvent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaKey		int		= null,
	@pnEntryNumber	 	smallint	= null,
	@psActionKey		nvarchar(2),
	@psCaseKey		nvarchar(11),
	@psEventKey		nvarchar(11)	= null,
	@pnEventCycle		smallint	= null,
	@psEventDescription	nvarchar(254)	= null,	-- Used for Alerts only
	@pdtEventDueDate	datetime	= null,
	@pdtEventDate		datetime	= null,
	@pbIsStopPolicing	bit		= null,
	@pnPeriod		smallint	= null,
	@psPeriodTypeKey	nchar(1)	= null,
	@psEventText		ntext		= null

)
-- PROCEDURE:	cs_InsertEntryEvent
-- VERSION:	3
-- SCOPE:	CPA.net
-- DESCRIPTION:	Apply new events within an entry to the database (ad hoc reminders).

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 27-MAR-2003  JEK	1	Procedure created.  RFC03 Case Workflow.
-- 24-APR-2003	SF	2	Change @pnEventKey to @psEventKey
-- 15-APR-2013	DV	3	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nCaseKey int

Set @nErrorCode = 0
Set @nCaseKey = cast(@psCaseKey as int)

If @nErrorCode = 0
and @psActionKey = '__'	-- Ad Hoc Reminder
Begin

	exec @nErrorCode = ip_InsertAlert
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnEmployeeKey		= null,
		@pnCaseKey		= @nCaseKey,
		@psAlertMessage		= @psEventDescription,
		@pdtDueDate		= @pdtEventDueDate,
		@pdtDateOccurred	= @pdtEventDate
End

Return @nErrorCode
GO

Grant execute on dbo.cs_InsertEntryEvent to public
GO
