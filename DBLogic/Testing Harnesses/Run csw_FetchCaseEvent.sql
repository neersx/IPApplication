exec dbo.csw_FetchCaseEvent
	@pnUserIdentityId = 5,
	@psCulture = N'pt-BR',
	@pbCalledFromCentura = default,
	@pnCaseKey = -487

SELECT *
FROM CASEEVENT