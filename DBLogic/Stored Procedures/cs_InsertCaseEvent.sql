-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_InsertCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_InsertCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_InsertCaseEvent.'
	drop procedure [dbo].[cs_InsertCaseEvent]
	print '**** Creating Stored Procedure dbo.cs_InsertCaseEvent...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure dbo.cs_InsertCaseEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,  	-- the language in which output is to be expressed
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
	@pbIsPolicedEvent 		bit 		= 1	-- Some events (e.g. date last changed) are not policed

)

-- PROCEDURE :	cs_InsertCaseEvent
-- VERSION :	16
-- DESCRIPTION:	See CaseData.doc

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 14 JUL 2002	JB		Function created
-- 17 JUL 2002	SF		@psEventKey should not have been an output param
-- 24 JUL 2002	SF		The POLICINGSEQNO was not generated correctly.
-- 25 JUL 2002	SF		Cater for policing immediate functionality.
-- 25 JUL 2002	JB		Now using ip_InsertPolicing
-- 28 JUL 2002	SF		1. Fix up some typos.
--				2. added @pnOpenActionCriteriaKey
--				3. Fix SQLUser
-- 31 JUL 2002	JB		Added @pbAddPolicingRow
-- 08 AUG 2002	SF		wrong policing request type.
-- 12 AUG 2002	SF		use ip_Policing
-- 25 FEB 2003	SF	14	RFC37 Add @pnPolicingBatchNo
-- 17 MAR 2003	SF	15	RFC84 comment out ip_InsertPolicing call.
-- 28-MAR-2003	JEK	16	Rewritten as generic InPro procedure for use by RFC03 Case workflow

AS
begin

declare @nErrorCode int
declare @nTypeOfRequest int
declare	@sCreatedByActionKey nvarchar(2)
declare	@nCreatedByCriteriaKey int
declare @nOccurredFlag dec(1,0)
declare @nDateDueSaved dec(1,0)
declare @bLongFlag bit

set @nErrorCode = @@error

if @nErrorCode = 0
begin
	If @pbIsStopPolicing = 1
	begin
		Set @nOccurredFlag = 1
	end
	Else
	begin
		Set @nOccurredFlag = case when @pdtEventDate is null then 0 else 1 end
	end

	Set @nDateDueSaved = case when @pdtEventDueDate is null then 0 else 1 end

	if @psEventText is not null
	begin
		if len(cast(@psEventText as nvarchar(300))) <= 254
			set @bLongFlag = 0
		else
			set @bLongFlag = 1
	end
	else
	begin
		set @bLongFlag = 0
	end

	insert 	CASEEVENT
		(CASEID,
		EVENTNO,
		CYCLE,
		EVENTDATE,
		EVENTDUEDATE,
		DATEDUESAVED,
		OCCURREDFLAG,
		CREATEDBYACTION,
		CREATEDBYCRITERIA,
		ENTEREDDEADLINE,
		PERIODTYPE,
		EVENTTEXT,
		EVENTLONGTEXT,
		LONGFLAG
		)
	values	(@pnCaseKey,
		@pnEventKey,
		@pnCycle,
		@pdtEventDate,
		@pdtEventDueDate,
		@nDateDueSaved,
		@nOccurredFlag,
		@psCreatedByActionKey,
		@pnCreatedByCriteriaKey,
		@pnPeriod,
		@psPeriodTypeKey,
		case when @bLongFlag = 1 then null else cast(@psEventText as nvarchar(254)) end,
		case when @bLongFlag = 0 then null else @psEventText end,
		@bLongFlag
		)

	set @nErrorCode = @@error								
end

if @nErrorCode = 0
and @pbIsPolicedEvent = 1
begin
	-- If both dates are provided
	-- police as an occurred event
	If 	(@nDateDueSaved = 1
		or @pnPeriod is not null
		or @psPeriodTypeKey is not null)
	and 	(@nOccurredFlag = 0)
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
		@psAction		= @psCreatedByActionKey,
		@pnCriteriaNo		= @pnCreatedByCriteriaKey,
		@pnTypeOfRequest	= @nTypeOfRequest,
		@pnPolicingBatchNo	= @pnPolicingBatchNo

end


return @nErrorCode

end
go

grant execute on dbo.cs_InsertCaseEvent to public
go
