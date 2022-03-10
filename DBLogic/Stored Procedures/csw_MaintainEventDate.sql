-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_MaintainEventDate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_MaintainEventDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_MaintainEventDate.'
	Drop procedure [dbo].[csw_MaintainEventDate]
End
Print '**** Creating Stored Procedure dbo.csw_MaintainEventDate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_MaintainEventDate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar (10)	= null,		-- The language in which output is to be expressed.
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory
	@pnEventKey		int,		-- Mandatory
	@pnCycle		smallint,	-- Mandatory
	@pdtEventDate		datetime,	-- Mandatory
	@psCreatedByActionKey	nvarchar(2)	= null,		-- The action that created the event.
	@pnCreatedByCriteriaKey	int		= null,		-- The criteria under which the event was created.
	@pnPolicingBatchNo	int		= null,		-- The batch number to attach any policing request to.
	@pbIsPolicedEvent	bit		= 1,		-- Indicates whether the event needs to be policed. 
	@pbOnHold		bit		= null		-- When not null, indicates that the policing request is to be placed on hold. If null, the On Hold status is determined from the @pnPolicingBatchNo.
)
as
-- PROCEDURE:	csw_MaintainEventDate
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure allows the event date of a case event to be updated if it exists,
--		or created if it does not. No concurrency checking is performed.  
--		A policing request is submitted if required.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Dec 2005	TM	RFC3200	1	Procedure created
-- 14 Jun 2006	IB	RFC3720	2	Modify logic not to update the event, or submit 
--					a policing request, if the event date has not changed. 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @nRowCount	int
Declare @sAction	nvarchar(2)
Declare @nCriteriaNo	int	

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0

If @nErrorCode = 0
Begin
	-- If an event already exists for a case and its date is different 
	-- compare to @pdtEventDate or is null, then update the event date.
	Set @sSQLString = "
	Update  CASEEVENT 
	set     EVENTDATE 	= @pdtEventDate
	where   CASEID 		= @pnCaseKey
	and     EVENTNO 	= @pnEventKey
	and     CYCLE 		= @pnCycle
	and 	(EVENTDATE 	<> @pdtEventDate 
		or EVENTDATE is null)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pdtEventDate		datetime,
				  @pnCaseKey		int,
				  @pnEventKey		int,
				  @pnCycle		int',
				  @pdtEventDate		= @pdtEventDate,
				  @pnCaseKey		= @pnCaseKey,
				  @pnEventKey		= @pnEventKey,
				  @pnCycle		= @pnCycle

	Set @nRowCount = @@RowCount
	
	-- If event existed and updated then police it if required
	If  @nErrorCode = 0
	and @nRowCount > 0
	and @pbIsPolicedEvent = 1
	Begin
		-- Get an action event is attached to
		Set @sSQLString = "
		Select  @sAction 	= CE.CREATEDBYACTION,
			@nCriteriaNo	= CE.CREATEDBYCRITERIA
		from    CASEEVENT CE
		where   CE.CASEID 	= @pnCaseKey
		and     CE.EVENTNO 	= @pnEventKey
		and     CE.CYCLE 	= @pnCycle"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@sAction	nvarchar(2)	OUTPUT,
				  @nCriteriaNo	int		OUTPUT,
				  @pnCaseKey	int,
				  @pnEventKey	int,
				  @pnCycle	int',
				  @sAction	= @sAction	OUTPUT,
				  @nCriteriaNo	= @nCriteriaNo	OUTPUT,
				  @pnCaseKey	= @pnCaseKey,
				  @pnEventKey	= @pnEventKey,
				  @pnCycle	= @pnCycle

		-- Police Event
		If  @nErrorCode = 0
		Begin	
			exec @nErrorCode = ipw_InsertPolicing
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture 		= @psCulture,
				@pnCaseKey 		= @pnCaseKey,
				@pnEventKey		= @pnEventKey,
				@pnCycle		= @pnCycle,
				@psAction		= @sAction,
				@pnCriteriaNo		= @nCriteriaNo,
				@pnTypeOfRequest	= 3, -- Police occurred event
				@pnPolicingBatchNo	= @pnPolicingBatchNo,
				@pbOnHold		= @pbOnHold
		End
	End
End
-- If event does not exist for a case then create it
If  @nErrorCode = 0
and not exists (Select 0
		from  CASEEVENT CE
		where CE.CASEID 	= @pnCaseKey
		and   CE.EVENTNO 	= @pnEventKey
		and   CE.CYCLE 		= @pnCycle)
Begin
	exec @nErrorCode = dbo.csw_InsertCaseEvent
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,	
				@pnCaseKey		= @pnCaseKey,			
				@pnEventKey		= @pnEventKey,		
				@pnCycle		= @pnCycle,
				@pdtEventDate		= @pdtEventDate,
				@psCreatedByActionKey	= @psCreatedByActionKey,
				@pnCreatedByCriteriaKey	= @pnCreatedByCriteriaKey,
				@pnPolicingBatchNo	= @pnPolicingBatchNo,
				@pbIsPolicedEvent 	= @pbIsPolicedEvent,
				@pbOnHold		= @pbOnHold
End

Return @nErrorCode
GO

Grant execute on dbo.csw_MaintainEventDate to public
GO
