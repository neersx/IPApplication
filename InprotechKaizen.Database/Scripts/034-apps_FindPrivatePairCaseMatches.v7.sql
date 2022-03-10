
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of apps_FindPrivatePairCaseMatches
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[apps_FindPrivatePairCaseMatches]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.apps_FindPrivatePairCaseMatches.'
	Drop procedure [dbo].[apps_FindPrivatePairCaseMatches]
End
Print '**** Creating Stored Procedure dbo.apps_FindPrivatePairCaseMatches...'
Print ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[apps_FindPrivatePairCaseMatches]
(
	@psSystemCode nvarchar(50),
	@pbExactMatch bit = 0,
	@pxPrivatePairCases XML
)
as
-- PROCEDURE:	apps_FindPrivatePairCaseMatches
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given an xml list of official numbers, return a filtered list of matching cases with a valid Data-Extract best-fit criteria.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11/02/2015	AT		R42537	1	Procedure created.
-- 13/03/2015	SF		R42537	2	Join on numbers with alpha numeric stripped
-- 21/05/2015	SF		R47866	3	Join on CASEINDEXES as it is already populated the numbers 
--                                  stripped of non-alpha-numerics, resolves massive performance issue.
-- 22/05/2015	SF		R47866	4	Limit to current numbers only
-- 18/04/2016	SS		R59882	5	Set Correlation Id only if single matched case found
-- 05/05/2017	SF		DR-28343 6	Column name returned are CaseKey and ApplicationNumber now	
-- 24/10/2017	AK	        R72645	7	Make compatible with case sensitive server with case insensitive database.
-- 26/06/2020	SF		SDR-29432 8	Cater for hyphens as PCT number separator and ensure PCT numbers are matched regardless of it being 14 digit or 17 digits.

	Declare @sSQLString 	nvarchar(max)
	Declare @tbCases table
	(
		ID INT,
		APPLICATIONNUMBER NVARCHAR(50) COLLATE DATABASE_DEFAULT,
		MATCHINGCASEID INT NULL
	)

	Declare @tbEligibleCases table
	(
		CASEID INT,
		APPLICATIONNUMBER nvarchar(50) COLLATE DATABASE_DEFAULT
	)

	INSERT INTO @tbCases (ID, APPLICATIONNUMBER)
	SELECT  N.value(N'PrivatePairCaseId[1]',N'int') as PrivatePairCaseId,
		Replace(N.value(N'ApplicationNumber[1]',N'nvarchar(30)'), '-', '/') as ApplicationNumber
	FROM @pxPrivatePairCases.nodes(N'/PrivatePair/Case') CN(N)

	INSERT INTO @tbEligibleCases (CASEID, APPLICATIONNUMBER)
	SELECT CaseKey, ApplicationNumber
	FROM fn_appsFilterEligibleCasesForComparison(@psSystemCode)
	
	DELETE @tbEligibleCases
	FROM @tbEligibleCases AS EC
	JOIN (SELECT COUNT(1) AS CNT, APPLICATIONNUMBER 
		FROM @tbEligibleCases
		GROUP BY APPLICATIONNUMBER
		)EC1 ON EC.APPLICATIONNUMBER = EC1.APPLICATIONNUMBER AND EC1.CNT > 1

	UPDATE T
	SET MATCHINGCASEID = EC.CASEID
	FROM @tbCases T
	JOIN CASEINDEXES CI on (CI.SOURCE = 5 AND CI.GENERICINDEX = T.APPLICATIONNUMBER)
	JOIN @tbEligibleCases EC on (CI.CASEID = EC.CASEID)
	WHERE EXISTS (
		SELECT 1 
		FROM OFFICIALNUMBERS O
		WHERE O.NUMBERTYPE = 'A'
		AND O.CASEID = CI.CASEID
		AND O.ISCURRENT = 1
		AND (O.OFFICIALNUMBER = T.APPLICATIONNUMBER OR 
			 T.APPLICATIONNUMBER = dbo.fn_StripNonAlphaNumerics(O.OFFICIALNUMBER) OR
			 T.APPLICATIONNUMBER = dbo.fn_ConvertToPctShortFormat(O.OFFICIALNUMBER)
	))

	
	SELECT 
		CN.ID				as PrivatePairCaseKey,
		CN.MATCHINGCASEID	as CaseKey
	FROM @tbCases CN
	WHERE CN.MATCHINGCASEID IS NOT NULL

Return 0
GO

Grant execute on dbo.apps_FindPrivatePairCaseMatches to public
GO