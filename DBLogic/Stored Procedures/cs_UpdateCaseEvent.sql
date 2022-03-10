-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_UpdateCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_UpdateCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_UpdateCaseEvent.'
	drop procedure [dbo].[cs_UpdateCaseEvent]
	print '**** Creating Stored Procedure dbo.cs_UpdateCaseEvent...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.cs_UpdateCaseEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	-- the language in which output is to be expressed
	@pnCaseKey			int, 		-- Mandatory
	@pnEventKey			int,		-- Mandatory
	@pnCycle			int, 		-- Mandatory
	@pdtEventDueDate		datetime	= null,
	@pdtEventDate			datetime	= null,
	@pbIsStopPolicing		bit		= null,
	@pnPeriod			smallint	= null,
	@psPeriodTypeKey		nchar(1)	= null,
	@psEventText			ntext		= null,
	@psCreatedByActionKey		nvarchar(2) 	= null,
	@pnCreatedByCriteriaKey		int 		= null,

	@pnPolicingBatchNo		int 		= null,
	@pbIsPolicedEvent 		bit 		= 1,	-- Some events (e.g. date last changed) are not policed


	@pbEventDueDateModified		bit 		= null,
	@pbEventDateModified		bit	 	= null,
	@pbIsStopPolicingModified	bit		= null,
	@pbPeriodModified		bit		= null,
	@pbPeriodTypeKeyModified	bit		= null,
	@pbEventTextModified		bit		= null

)

-- PROCEDURE :	cs_UpdateCaseEvent
-- VERSION :	8
-- DESCRIPTION:	updates a row 

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 17/07/2002	SF	Stub Created
-- 24/07/2002	SF	Procedure Created
-- 28/07/2002	SF	SQLUser
-- 02/08/2002	SF	Date Due Saved and Occurred Flag was incorrectly set.
-- 07/08/2002	SF	Type of Request is incorrect.
-- 27-MAR-2003	JEK	8	Rewritten as generic InPro procedure for use by RFC03 Case workflow

as
begin

declare @nErrorCode int
declare @nTypeOfRequest int
declare	@sCreatedByActionKey nvarchar(2)
declare	@nCreatedByCriteriaKey int
declare @nOccurredFlag dec(1,0)
declare @nDateDueSaved dec(1,0)
declare @bLongFlag bit

set @nErrorCode = @@error
set @nOccurredFlag = null
set @nDateDueSaved = null

if @nErrorCode = 0
begin

	If @pbIsStopPolicingModified = 1
	or @pbEventDateModified = 1
	begin
		If @pbIsStopPolicingModified = 1
		and @pbIsStopPolicing = 1
		begin
			Set @nOccurredFlag = 1
		end
		Else
		begin
			Set @nOccurredFlag = case when @pdtEventDate is null then 0 else 1 end
		end
	end

	If @pbEventDueDateModified = 1
	begin
		Set @nDateDueSaved = case when @pdtEventDueDate is null then 0 else 1 end
	end

	If @pbEventTextModified = 1
	begin
		if (len(cast(@psEventText as nvarchar(300))) <= 254)
		or (@psEventText is null)
			set @bLongFlag = 0
		else
			set @bLongFlag = 1
	end

	update 	CASEEVENT
	set	EVENTDUEDATE = case when @pbEventDueDateModified = 1 then @pdtEventDueDate else EVENTDUEDATE end,
		EVENTDATE = case when @pbEventDateModified = 1 then @pdtEventDate else EVENTDATE end,
		DATEDUESAVED = case when @nDateDueSaved is not null then @nDateDueSaved	else DATEDUESAVED end,
		OCCURREDFLAG = case when @nOccurredFlag is not null then @nOccurredFlag	else OCCURREDFLAG end,
		ENTEREDDEADLINE = case when @pbPeriodModified = 1 then @pnPeriod else ENTEREDDEADLINE end,
		PERIODTYPE = case when @pbPeriodTypeKeyModified = 1 then @psPeriodTypeKey else PERIODTYPE end,
		EVENTTEXT = case when @pbEventTextModified = 1 
			then case when @bLongFlag = 1 then null else cast(@psEventText as nvarchar(254)) end
			else EVENTTEXT end,
		EVENTLONGTEXT = case when @pbEventTextModified = 1 
			then case when @bLongFlag = 0 then null else @psEventText end
			else EVENTLONGTEXT end,
		LONGFLAG = case when @pbEventTextModified = 1 then @bLongFlag else LONGFLAG end
	where 	CASEID = @pnCaseKey
	and	EVENTNO = @pnEventKey
	and	CYCLE = @pnCycle

	set @nErrorCode = @@error								
end

if @nErrorCode = 0
and @pbIsPolicedEvent = 1
and (@nOccurredFlag is not null
    or @nDateDueSaved is not null
    or @pbPeriodModified = 1
    or @pbPeriodTypeKeyModified = 1)
begin
	-- If CreatedBy action & event not provided, look them up.
	if @nErrorCode = 0
	and ( @psCreatedByActionKey is null or
		@pnCreatedByCriteriaKey is null)
	begin
		Select 	@sCreatedByActionKey = CREATEDBYACTION,
			@nCreatedByCriteriaKey = CREATEDBYCRITERIA
		from	CASEEVENT
		where	CASEID = @pnCaseKey
		and	EVENTNO = @pnEventKey
		and	CYCLE = @pnCycle
	
		set @nErrorCode = @@error
	end
	Else
	begin
		set @sCreatedByActionKey = @psCreatedByActionKey
		set @nCreatedByCriteriaKey = @pnCreatedByCriteriaKey
	end

	if @nErrorCode = 0
	begin
		-- If both dates are cleared or both are provided
		-- police as an occurred event
		If 	(@nDateDueSaved = 1
			or @pbPeriodModified = 1
			or @pbPeriodTypeKeyModified = 1)
		and 	(@nOccurredFlag = 0 or @nOccurredFlag is null)
		begin
			Set @nTypeOfRequest = 2 -- Police Due Event
		end
		Else
		begin
			Set @nTypeOfRequest = 3 -- Police Occurred Event
		end
	
		exec @nErrorCode = ip_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@psCaseKey 		= @pnCaseKey,
			@psEventKey		= @pnEventKey,
			@pnCycle		= @pnCycle,
			@psAction		= @sCreatedByActionKey,
			@pnCriteriaNo		= @nCreatedByCriteriaKey,
			@pnTypeOfRequest	= @nTypeOfRequest,
			@pnPolicingBatchNo	= @pnPolicingBatchNo
	end
end


return @nErrorCode

end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_UpdateCaseEvent to public
GO
