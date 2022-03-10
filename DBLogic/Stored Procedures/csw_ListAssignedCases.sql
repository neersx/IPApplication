-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListAssignedCases
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListAssignedCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListAssignedCases.'
	Drop procedure [dbo].[csw_ListAssignedCases]
End
Print '**** Creating Stored Procedure dbo.csw_ListAssignedCases...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListAssignedCases
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int				= null,
	@pbCalledFromCentura	bit			= 0
)
as
-- PROCEDURE:	csw_ListAssignedCases
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List All Cases for a particular Prior Art Key

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 15 Jun 2011	KR	RFC7904	1	Procedure created
-- 04 Nov 2011	ASH	R11460  2	Cast integer columns as nvarchar(11) data type. 
-- 15 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer
-- 19 Sep 2017  AK      R61417  4       Added 'Country' in result set

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin

	Set @sSQLString ="
	SELECT	
	CAST(R.CASEID as nvarchar(11))+'^'+CAST(R.RELATIONSHIPNO as nvarchar(11)) as RowKey,
	R.CASEID as CaseKey,
	C1.IRN as CaseReference,
	R.RELATIONSHIPNO as RelationshipKey,
	R.RELATIONSHIP as Relationship,
	"+dbo.fn_SqlTranslatedColumn('RELATIONSHIPDESC','RELATIONSHIPDESC',null,'CR',@sLookupCulture,@pbCalledFromCentura)
		+ " as RelationshipDescription,
	R.RELATEDCASEID as RelatedCaseKey,
	C.IRN	as RelatedCaseReference,
	CASE WHEN ( R.RELATEDCASEID is null ) THEN R.OFFICIALNUMBER ELSE C.CURRENTOFFICIALNO END as OfficialNumber,
	CASE WHEN ( R.RECORDALFLAGS  is null OR R.RECORDALFLAGS = 0 ) THEN 0 ELSE 1 END as IsAssigned,
	C.TITLE as Title,
	R.LOGDATETIMESTAMP			as LastModifiedDate,
        ISNULL(CO.COUNTRY, CO2.COUNTRY)         as CountryName,
        ISNULL(CO.COUNTRYCODE,CO2.COUNTRYCODE)      as CountryCode
	FROM RELATEDCASE R     
	Join CASERELATION CR on (CR.RELATIONSHIP = R.RELATIONSHIP)        
	LEFT  JOIN CASES C ON (R.RELATEDCASEID = C.CASEID)        
        LEFT JOIN COUNTRY CO ON (C.COUNTRYCODE = CO.COUNTRYCODE)
        LEFT JOIN COUNTRY CO2 ON (R.COUNTRYCODE = CO2.COUNTRYCODE)
        LEFT JOIN CASES C1 ON R.CASEID = C1.CASEID
	WHERE R.CASEID = @pnCaseKey
	AND R.RELATIONSHIP = 'ASG'        
	ORDER BY  C.IRN"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnUserIdentityId	int,
			@pbCalledFromCentura bit,
			@pnCaseKey		int',
			@pnUserIdentityId   = @pnUserIdentityId,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pnCaseKey		= @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListAssignedCases to public
GO