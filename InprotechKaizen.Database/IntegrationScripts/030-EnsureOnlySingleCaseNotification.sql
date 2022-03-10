PRINT '**** R48028 Ensure single notification per case'           	

-- Group by case id and ordered by date, the latest one comes first
;WITH cte AS
(SELECT Id, rownum = ROW_NUMBER() OVER (PARTITION BY CaseId ORDER BY UpdatedOn DESC) FROM CaseNotifications)
SELECT Id
INTO #ToBeDeleted
FROM cte
WHERE rownum > 1

DELETE FROM CaseNotifications
WHERE Id IN (SELECT Id FROM #ToBeDeleted)

DROP TABLE #ToBeDeleted