-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetDefaultCopyProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetDefaultCopyProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetDefaultCopyProfile.'
	Drop procedure [dbo].[csw_GetDefaultCopyProfile]
End
Print '**** Creating Stored Procedure dbo.csw_GetDefaultCopyProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_GetDefaultCopyProfile
(
	@psDefaultProfile		nvarchar(50) = null output,
	@pnUserIdentityId		int,					-- Mandatory
	@psCulture				nvarchar(10) = null,  	-- the language in which output is to be expressed	
	@pnCaseKey				nvarchar(11),			-- Mandatory 
	@psCaseTypeKey			nvarchar(3)	= null,
	@psCountryCode			nvarchar(3)	= null,
	@psPropertyTypeKey		nvarchar(3)	= null,
	@psCaseCategoryKey		nvarchar(3)	= null,
	@psSubTypeKey			nvarchar(2) = null
)
as
-- PROCEDURE:	csw_GetDefaultCopyProfile
-- VERSION:		3
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the default copy profile based on criteria of the case being copied
--				and the new case being created.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	------- -----------	-------	---------------------------------------------- 
-- 03 Jun 2011	LP		RFC10530	1		Procedure created
-- 15 Apr 2013	DV		R13270		2		Increase the length of nvarchar to 11 when casting or declaring integer
-- 31 Jul 2013	AT		DR499		3		Add Sub-Type and New Case Sub-Type to best fit criteria check.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString	 nvarchar (max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	SELECT @psDefaultProfile = BESTFIT.CopyProfileName	
	from (
		SELECT TOP 1
			CASE WHEN CR.CASETYPE IS NULL THEN 0 ELSE 1 END			* 10000000000 +
			CASE WHEN CR.COUNTRYCODE IS NULL THEN 0 ELSE 1 END		* 1000000000 +
			CASE WHEN CR.PROPERTYTYPE IS NULL THEN 0 ELSE 1 END		* 100000000 +
			CASE WHEN CR.CASECATEGORY IS NULL THEN 0 ELSE 1 END		* 10000000 +
			CASE WHEN CR.SUBTYPE IS NULL THEN 0 ELSE 1 END			* 1000000 +
			CASE WHEN CR.NEWCASETYPE IS NULL THEN 0 ELSE 1 END		* 100000 +
			CASE WHEN CR.NEWCOUNTRYCODE IS NULL THEN 0 ELSE 1 END	* 10000 +
			CASE WHEN CR.NEWPROPERTYTYPE IS NULL THEN 0 ELSE 1 END	* 1000 +
			CASE WHEN CR.NEWCASECATEGORY IS NULL THEN 0 ELSE 1 END	* 100 +
			CASE WHEN CR.NEWSUBTYPE IS NULL THEN 0 ELSE 1 END		* 10 AS BESTFITSCORE,
			CR.PROFILENAME AS [CopyProfileName]
		FROM CRITERIA CR
		join CASES C on (C.CASEID = @pnCaseKey)
		join COPYPROFILE CPX on (CPX.PROFILENAME = CR.PROFILENAME)
		WHERE PURPOSECODE = 'P'
		AND (CR.CASETYPE = C.CASETYPE OR CR.CASETYPE IS NULL)
		AND (CR.COUNTRYCODE = C.COUNTRYCODE OR CR.COUNTRYCODE IS NULL)
		AND (CR.PROPERTYTYPE = C.PROPERTYTYPE OR CR.PROPERTYTYPE IS NULL)
		AND (CR.CASECATEGORY = C.CASECATEGORY OR CR.CASECATEGORY IS NULL)
		AND (CR.SUBTYPE = C.SUBTYPE OR CR.SUBTYPE IS NULL)
		AND (CR.NEWCASETYPE = @psCaseTypeKey or CR.NEWCASETYPE IS NULL)
		AND (CR.NEWCOUNTRYCODE = @psCountryCode or CR.NEWCOUNTRYCODE IS NULL)
		AND (CR.NEWPROPERTYTYPE = @psPropertyTypeKey or CR.NEWPROPERTYTYPE IS NULL)
		AND (CR.NEWCASECATEGORY = @psCaseCategoryKey or CR.NEWCASECATEGORY IS NULL)
		AND (CR.NEWSUBTYPE = @psSubTypeKey or CR.NEWSUBTYPE IS NULL)
		ORDER BY BESTFITSCORE DESC) as BESTFIT"
	
	Exec @nErrorCode = sp_executesql @sSQLString,
	    N'@psDefaultProfile	nvarchar(50) output,
	    @pnCaseKey    int,
	    @psCaseTypeKey nvarchar(3),
	    @psCountryCode nvarchar(3),
	    @psPropertyTypeKey nvarchar(3),
	    @psCaseCategoryKey nvarchar(3),
	    @psSubTypeKey nvarchar(2)',
	    @pnCaseKey	    = @pnCaseKey,
	    @psDefaultProfile = @psDefaultProfile output,
	    @psCaseTypeKey	= @psCaseTypeKey,
	    @psCountryCode	= @psCountryCode,
	    @psPropertyTypeKey	= @psPropertyTypeKey,
	    @psCaseCategoryKey	= @psCaseCategoryKey,
	    @psSubTypeKey = @psSubTypeKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetDefaultCopyProfile to public
GO
