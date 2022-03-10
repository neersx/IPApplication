DECLARE @pdtNow datetime
SELECT @pdtNow = GETDATE()

exec dbo.csw_InsertCaseEventB
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= N'pt-BR',
	@pbCalledFromCentura			= default,
	@pnCaseKey				= -487,		-- Mandatory.
	@pnEventKey				= -7,		-- Mandatory.
	@pnEventCycle				= 2,		-- Mandatory.
	@pdtEventDate				= @pdtNow, -- null
	@pdtEventDueDate			= '3000-01-01 00:00:00.000', --null
	@ptEventText				= N'Dummy EventText', -- N'123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345678991234567899123456789912345', --N'Dummy EventText', --(255chars)
	@psCreatedByActionCode			= N'AL',
	@pnCreatedByCriteriaKey			= -292,
	@pnPolicingBatchNo			= 777,
	@pbIsEventKeyInUse			= 1,
	@pbIsEventCycleInUse			= 1,
	@pbIsEventDateInUse			= 1, --0
	@pbIsEventDueDateInUse			= 1, --0
	@pbIsEventTextInUse			= 1,
	@pbIsCreatedByActionCodeInUse		= 1,
	@pbIsCreatedByCriteriaKeyInUse		= 1

/*
exec dbo.csw_FetchCaseEvent
	@pnUserIdentityId = 26,
	@psCulture = N'pt-BR',
	@pbCalledFromCentura = default,
	@pnCaseKey = -487
*/