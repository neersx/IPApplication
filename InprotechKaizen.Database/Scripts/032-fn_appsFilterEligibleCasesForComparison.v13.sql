-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_appsFilterEligibleCasesForComparison
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_appsFilterEligibleCasesForComparison') and xtype in ('IF', 'TF'))
Begin
	Print '**** Drop Function dbo.fn_appsFilterEligibleCasesForComparison'
	Drop function [dbo].fn_appsFilterEligibleCasesForComparison
End
Print '**** Creating Function dbo.fn_appsFilterEligibleCasesForComparison...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_appsFilterEligibleCasesForComparison
(
	@psExternalSystemCodes nvarchar(max)
) 
RETURNS Table 
AS
-- Function :	fn_appsFilterEligibleCasesForComparison
-- VERSION :	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	return a filtered list of cases with a valid Data-Extract best-fit criteria.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 09/02/2015	AT/SF	R42537		1		Procedure created.
-- 13/03/2015	SF		R42537		2		Return numbers with Alpha numeric stripped.
-- 30/03/2015	SF		R42537		3		Reverted.  
-- 05/05/2017	SF		DR-28343	4		Return Proper Casing, and Dates
-- 12/05/2017	SF		DR-28343	5		De-duplicate current numbers when invalid data exist
-- 12/05/2017	SF		DR-28343	6		Caters for LOGDATETIMESTAMP being null
-- 24/05/2017	SF		DR-27307	7		Change to use dtMin
-- 24/05/2017	SS		DR-30268	8		Modified to single line return statement
-- 10/07/2017	SF		DR-32728	9		Dont return dates
-- 10/08/2017	SF		DR-33425	10		Dont return alternate country code
-- 14/08/2017	SF		DR-33348	11		Consider Case Category in ALL FIT
-- 07/08/2020	SF		SDR-29542	12		Return IsLiveCase Flag
-- 18/08/2021	SW		DR-74107	13		Return PropertyType of Case
RETURN
	   (WITH CTE_OfficialNumber (CASEID, NUMBERTYPE, COFFICIALNUMBER) AS 
	   (SELECT O.CASEID, O.NUMBERTYPE, substring (MAX (CONVERT(CHAR(24), isnull(O.LOGDATETIMESTAMP, cast('1753-01-01' as datetime)), 21) + OFFICIALNUMBER)  , 25,36) as COFFICIALNUMBER
		 FROM OFFICIALNUMBERS O
		 WHERE ISCURRENT = 1 
		 GROUP BY CASEID, NUMBERTYPE)
		 SELECT	C.CASEID as CaseKey,
			VES.DATAEXTRACTID as SystemId,
			VES.SYSTEMCODE as SystemCode,
			APP.COFFICIALNUMBER as 'ApplicationNumber',
			REG.COFFICIALNUMBER as 'RegistrationNumber',
			PUB.COFFICIALNUMBER as 'PublicationNumber',
			C.COUNTRYCODE as CountryCode,
			cast(CASE WHEN TC.TABLECODE = 7603 THEN 0 ELSE 1 END as bit) as IsLiveCase,
			C.PROPERTYTYPE as PropertyType
		FROM CASES C
		LEFT JOIN PROPERTY P ON ( P.CASEID = C.CASEID )
		LEFT JOIN STATUS RS ON ( RS.STATUSCODE = P.RENEWALSTATUS )
		LEFT JOIN STATUS ST ON ( ST.STATUSCODE = C.STATUSCODE )
		LEFT JOIN TABLECODES TC ON ( TC.TABLECODE = CASE
						WHEN( ST.LIVEFLAG = 0
							OR RS.LIVEFLAG = 0 ) THEN 7603
						WHEN( ST.REGISTEREDFLAG = 1 ) THEN 7602
						ELSE 7601
						END )
		JOIN CRITERIA CRIT ON CRIT.RULEINUSE		= 1
				and CRIT.PURPOSECODE = 'D'
				AND (	CRIT.CASEOFFICEID 	= C.OFFICEID		OR CRIT.CASEOFFICEID 	IS NULL )
				AND (	CRIT.CASETYPE		= C.CASETYPE		OR CRIT.CASETYPE	is NULL )
				AND (	CRIT.PROPERTYTYPE 	= C.PROPERTYTYPE	OR CRIT.PROPERTYTYPE 	IS NULL ) 
				AND (	CRIT.COUNTRYCODE 	= C.COUNTRYCODE		OR CRIT.COUNTRYCODE 	IS NULL ) 
				AND (	CRIT.CASECATEGORY 	= C.CASECATEGORY	OR CRIT.CASECATEGORY 	IS NULL ) 
				AND (	CRIT.TABLECODE 		= TC.TABLECODE		OR CRIT.TABLECODE	IS NULL )
		JOIN (select DEM.DATAEXTRACTID, ES.SYSTEMCODE
		FROM DATAEXTRACTMODULE DEM
		JOIN EXTERNALSYSTEM ES ON ES.SYSTEMID = DEM.SYSTEMID
		JOIN dbo.fn_Tokenise(@psExternalSystemCodes, ',') ESC ON ESC.Parameter = ES.SYSTEMCODE) VES ON (VES.DATAEXTRACTID = CRIT.DATAEXTRACTID)
		
		-- Find latest current application number for the case.  There should only be one, but evidence of invalid data is all over the place.
		LEFT JOIN CTE_OfficialNumber APP on (APP.CASEID = C.CASEID AND APP.NUMBERTYPE = 'A')

		-- Find latest current publication number for the case.  There should only be one, but evidence of invalid data is all over the place.
		LEFT JOIN CTE_OfficialNumber PUB on (PUB.CASEID = C.CASEID AND PUB.NUMBERTYPE = 'P')

		-- Find latest current registration number for the case.  There should only be one, but evidence of invalid data is all over the place.
		LEFT JOIN CTE_OfficialNumber REG on (REG.CASEID = C.CASEID AND REG.NUMBERTYPE = 'R')
		)
GO

grant references, select on dbo.fn_appsFilterEligibleCasesForComparison to public
go
