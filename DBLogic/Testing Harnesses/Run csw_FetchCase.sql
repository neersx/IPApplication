exec dbo.csw_FetchCase @pnUserIdentityId = 5, @psCulture = default, @pbCalledFromCentura = default, @pnCaseKey = -487, @psCaseTypeCode = default, @pbNewRow = 1

SELECT *
FROM CASES C
WHERE C.CASEID = -487