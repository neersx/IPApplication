-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListDesignatedCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].csw_ListDesignatedCases') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_ListDesignatedCases.'
	drop procedure [dbo].csw_ListDesignatedCases
end
print '**** Creating Stored Procedure dbo.csw_ListDesignatedCases...'
print ''
go

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_ListDesignatedCases
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCaseKeys		nvarchar(max)	= null,
	@pnParentCaseKey	int		= null
)
as
-- PROCEDURE:	csw_ListDesignatedCases
-- VERSION:	7
-- DESCRIPTION:	Return a list of cases that have been created as a result of 
--		a case entering National Phase status in designated countries
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11-Jan-2008  LP		1	Procedure created
-- 24 Oct 2011	ASH	R11460  2	Cast integer columns as nvarchar(11) data type.
-- 10-Apr-2014	AT	R31003	3	Added Classes and Property Type.
-- 14-Apr-2014	AT	R31003	4	Add Parent case key parameter to return relationship.
-- 24-Sep-2015	MF	R53406	5	Cases that entered National Phase from PCT are showing duplicated if there
--					are multiple relationships back to the Parent Case.
-- 27-DEC-2016	AK	R54033	6	Add 'Instructor Reference' and 'Agent Reference' columns in resultset
-- 28 Sep 2018	MF	74987	7	CaseKeys parameter changed to nvarchar(max) from nvarchar(1000) to avoid trunction of list of CaseKeys.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(2000)

Set @nErrorCode = 0

If @nErrorCode=0
Begin
	Set @sSQLString = "
	SELECT DISTINCT 
	CAST(S.CASEID as nvarchar(11))+'^'+CI.NAMETYPE as RowKey,
	S.CASEID as CaseKey,    
	S.COUNTRYCODE as CountryCode,
	C.COUNTRY as CountryName, 
	S.IRN as CaseReference,  
	S.TITLE as Title,
	NI.NAMENO as InstructorNameKey,
	NI.NAME as InstructorName,
	NI.NAMECODE as InstructorNameCode,
	NA.NAMENO as AgentNameKey,
	NA.NAME as AgentName,
	NA.NAMECODE as AgentNameCode,
	NT.NAMENO as TranslatorNameKey,
	NT.NAME as TranslatorName,
	NT.NAMECODE as TranslatorNameCode,
	S.PROPERTYTYPE as PropertyTypeKey,
	S.LOCALCLASSES AS LocalClasses,
	S.INTCLASSES as IntClasses,
	@pnParentCaseKey as ParentCaseKey,
	CR.RELATIONSHIP as ParentRelationshipCode,
	CR.RELATIONSHIPDESC as ParentRelationshipDescription,
	CI.REFERENCENO as InstructorReference,
	CA.REFERENCENO as AgentReference
	FROM    CASES S
	JOIN dbo.fn_Tokenise(@psCaseKeys, ',') TAB on (TAB.[Parameter] = S.CASEID)
	JOIN CASETYPE T on (T.CASETYPE    = S.CASETYPE)
	JOIN COUNTRY C  on (C.COUNTRYCODE = S.COUNTRYCODE)
	LEFT JOIN CASENAME CA	on (CA.NAMETYPE = 'A'
				AND CA.CASEID   = S.CASEID)
	LEFT JOIN NAME NA	on (NA.NAMENO   = CA.NAMENO)
	LEFT JOIN CASENAME CI	on (CI.NAMETYPE = 'I'
				AND CI.CASEID   = S.CASEID)
	LEFT JOIN NAME NI	on (NI.NAMENO   = CI.NAMENO)
	LEFT JOIN CASENAME CT	on (CT.NAMETYPE = 'TRN'
				AND CT.CASEID   = S.CASEID)
	LEFT JOIN NAME NT	on (NT.NAMENO   = CT.NAMENO)
	LEFT JOIN RELATEDCASE RC  ON (RC.CASEID = S.CASEID
				  AND RC.RELATEDCASEID = @pnParentCaseKey)
	LEFT JOIN CASERELATION CR ON (CR.RELATIONSHIP  = RC.RELATIONSHIP)
	WHERE   S.COUNTRYCODE = C.COUNTRYCODE
	AND   (CR.RELATIONSHIP is null OR CR.POINTERTOPARENT=1)
	ORDER BY S.COUNTRYCODE"

    exec @nErrorCode=sp_executesql @sSQLString,
		    N'@psCaseKeys	nvarchar(max),
		    @pnParentCaseKey	int',
		    @psCaseKeys		= @psCaseKeys,
		    @pnParentCaseKey	 = @pnParentCaseKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListDesignatedCases to public
GO