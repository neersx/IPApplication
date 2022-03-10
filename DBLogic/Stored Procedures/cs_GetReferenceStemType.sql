-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetReferenceStemType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetReferenceStemType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetReferenceStemType.'
	Drop procedure [dbo].[cs_GetReferenceStemType]
End
Print '**** Creating Stored Procedure dbo.cs_GetReferenceStemType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GetReferenceStemType
(
	@pnStemTypeCode		nchar(1)	= null output,	-- type of stem: NULL none, 'T' text (1462), 'N' numeric (1457)
	@pnUserIdentityId	int,				-- Mandatory
	@pnCaseKey		int		= null,		-- must supply following params if null
	@pnCaseOfficeKey	int		= null,
	@psCaseTypeCode		nchar(1)	= null,
	@psCountryCode		nvarchar(3)	= null,
	@psPropertyTypeCode	nchar(1)	= null,
	@psCaseCategoryCode	nvarchar(2)	= null,
	@psApplicationBasisCode	nvarchar(2)	= null
)
as
-- PROCEDURE:	cs_GetReferenceStemType
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure examines the case reference generation rules to 
--		determine whether a Stem component needs to be collected from the user. 
--		If so, it determines the type of stem required (text or numeric).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jul 2006	SW	RFC3248	1	Procedure created
-- 21 Sep 2009  LP      RFC8047 2       Pass ProfileKey parameter to fn_GetCriteriaNo

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @nCriteriaNo	int
Declare @nProfileKey int

-- Initialise variables
Set @nErrorCode = 0

-- Get ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        
        Set @nErrorCode = @@ERROR
End        
-- Find out CriteriaNo
If @nErrorCode = 0
Begin
	If @pnCaseKey is not null
	Begin
		Set @nCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'R', null, null, @nProfileKey)
	End
	Else
	Begin
		-- Return CriteriaNo by the top best fit scoring
		Set @sSQLString = "
			SELECT 
			@nCriteriaNo =
			convert(int,
			substring(
			max (
			CASE WHEN (C.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.CASETYPE IS NULL)		THEN '0' ELSE '1' END +  
			CASE WHEN (C.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +    			
			CASE WHEN (C.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (C.BASIS IS NULL)		THEN '0' ELSE '1' END +
			convert(varchar,C.CRITERIANO)), 7,20))
			FROM CRITERIA C 
			WHERE	C.RULEINUSE		= 1  	
			AND	C.PURPOSECODE		= 'R'
			AND (	C.CASEOFFICEID 		= @pnCaseOfficeKey		OR C.CASEOFFICEID 	IS NULL )
			AND (	C.CASETYPE		= @psCaseTypeCode		or C.CASETYPE		is NULL )
			AND (	C.PROPERTYTYPE 		= @psPropertyTypeCode 		OR C.PROPERTYTYPE 	IS NULL ) 
			AND (	C.COUNTRYCODE 		= @psCountryCode		OR C.COUNTRYCODE 	IS NULL ) 
			AND (	C.CASECATEGORY 		= @psCaseCategoryCode 		OR C.CASECATEGORY 	IS NULL ) 
			AND (	C.BASIS 		= @psApplicationBasisCode	OR C.BASIS	 	IS NULL ) 
		"

		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@nCriteriaNo			int			OUTPUT,
					  @pnCaseOfficeKey		int,
					  @psCaseTypeCode		nchar(1),
					  @psPropertyTypeCode		nchar(1),
					  @psCountryCode		nvarchar(3),
					  @psCaseCategoryCode		nvarchar(2),
					  @psApplicationBasisCode	nvarchar(2)',
					  @nCriteriaNo			= @nCriteriaNo		OUTPUT,
					  @pnCaseOfficeKey		= @pnCaseOfficeKey,
					  @psCaseTypeCode		= @psCaseTypeCode,
					  @psPropertyTypeCode		= @psPropertyTypeCode,
					  @psCountryCode		= @psCountryCode,
					  @psCaseCategoryCode		= @psCaseCategoryCode,
					  @psApplicationBasisCode	= @psApplicationBasisCode
	End
End

-- Check IRFORMAT rules
If @nErrorCode = 0
Begin
	
 	set @sSQLString="
 	select  @pnStemTypeCode = 
		CASE
			WHEN SEGMENT1CODE = 1457
			  or SEGMENT2CODE = 1457
			  or SEGMENT3CODE = 1457
			  or SEGMENT4CODE = 1457
			  or SEGMENT5CODE = 1457
			  or SEGMENT6CODE = 1457
			  or SEGMENT7CODE = 1457
			  or SEGMENT8CODE = 1457
			  or SEGMENT9CODE = 1457
			THEN 'N'
			WHEN SEGMENT1CODE = 1462
			  or SEGMENT2CODE = 1462
			  or SEGMENT3CODE = 1462
			  or SEGMENT4CODE = 1462
			  or SEGMENT5CODE = 1462
			  or SEGMENT6CODE = 1462
			  or SEGMENT7CODE = 1462
			  or SEGMENT8CODE = 1462
			  or SEGMENT9CODE = 1462
			THEN 'T'
			ELSE NULL
		END
	from IRFORMAT
 	where CRITERIANO=@nCriteriaNo"
 
 	exec @nErrorCode=sp_executesql @sSQLString, 
		      		N'@pnStemTypeCode	nchar(1)		OUTPUT,
     		        	  @nCriteriaNo  	int',
      				  @pnStemTypeCode       =@pnStemTypeCode	OUTPUT,
	            		  @nCriteriaNo          =@nCriteriaNo
End

Return @nErrorCode
GO

Grant execute on dbo.cs_GetReferenceStemType to public
GO
