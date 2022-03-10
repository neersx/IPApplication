exec dbo.csw_FetchCaseEvent
	@pnUserIdentityId = 5,
	@psCulture = N'en-AU',
	@pbCalledFromCentura = default,
	@pnCaseKey = -487

exec dbo.csw_UpdateCaseEvent
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= default,
	@pbCalledFromCentura		= 0,
	@pnCaseKey			= -487,		-- Mandatory
	@pnEventKey			= -23,		-- Mandatory
	@pnEventCycle			= 2,		-- Mandatory
	@pdtEventDate			= '2000-01-01 00:00:00.000', --'2000-01-01 00:00:00.000', --'1997-11-01 00:00:00.000',--'2000-01-01 00:00:00.000',--'1997-11-01 00:00:00.000',--
	@pdtEventDueDate		= '3000-01-01 00:00:00.000', --'3000-01-01 00:00:00.000',
	@ptEventText			= N'Application convention deadline', --N'123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345',
	@psCreatedByActionCode		= N'AL',
	@pnCreatedByCriteriaKey		= null,
	@pnPolicingBatchNo		= 1,
	@pnOldEventKey			= -23,		-- Mandatory
	@pnOldEventCycle		= 2,	-- Mandatory
	@pdtOldEventDate		= '2000-01-01 00:00:00.000',--'2000-01-01 00:00:00.000',--'2000-06-20 00:00:00.000',
	@pdtOldEventDueDate		= '3000-01-01 00:00:00.000',--'2000-01-01 00:00:00.000', --null,
	@ptOldEventText			= null,--N'Application convention deadline', --N'Dummy EventText', --null,
	@psOldCreatedByActionCode	= N'AL',
	@pnOldCreatedByCriteriaKey	= -283,
	@pbIsEventKeyInUse		= 0,
	@pbIsEventCycleInUse		= 1,
	@pbIsEventDateInUse		= 0,
	@pbIsEventDueDateInUse		= 0,
	@pbIsEventTextInUse		= 0,
	@pbIsCreatedByActionCodeInUse	= 0,
	@pbIsCreatedByCriteriaKeyInUse	= 0

exec dbo.csw_FetchCaseEvent
	@pnUserIdentityId = 5,
	@psCulture = N'en-AU',
	@pbCalledFromCentura = default,
	@pnCaseKey = -487