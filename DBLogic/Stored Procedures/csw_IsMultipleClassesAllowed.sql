-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_IsMultipleClassesAllowed
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_IsMultipleClassesAllowed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_IsMultipleClassesAllowed.'
	Drop procedure [dbo].[csw_IsMultipleClassesAllowed]
End
Print '**** Creating Stored Procedure dbo.csw_IsMultipleClassesAllowed...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_IsMultipleClassesAllowed
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int
)
as
-- PROCEDURE:	csw_IsMultipleClassesAllowed
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Multiple class allowed value for the case

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Nov 2012	MS	R12752	1	Procedure created
-- 07 Oct 2016	MF	R69122	2	Only apply this check for Case Type = "A". All other cases types
--					are to allow multiple classes.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	        int
declare @sSQLString             nvarchar(4000)
declare @bIsMultiClassAllowed   bit

-- Initialise variables
Set @nErrorCode = 0
Set @bIsMultiClassAllowed = 0

If @nErrorCode=0
Begin
	--------------------------------------------------
	-- If the Case is not a Property case (CaseType=A)
	-- then by default we will allow multiple classes.
	--------------------------------------------------
        Set @sSQLString = "
		Select @bIsMultiClassAllowed=1
		from CASES
		where CASEID = @pnCaseKey
		and CASETYPE<>'A'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsMultiClassAllowed bit     output,
			@pnCaseKey	        int',
			@bIsMultiClassAllowed   = @bIsMultiClassAllowed output,
			@pnCaseKey	        = @pnCaseKey
End

If  @nErrorCode = 0
and @bIsMultiClassAllowed = 0
Begin
        Set @sSQLString = "
		SELECT @bIsMultiClassAllowed = 1
		FROM TABLEATTRIBUTES TA
		JOIN CASES C on (TA.GENERICKEY = C.COUNTRYCODE)
		WHERE TA.PARENTTABLE = 'COUNTRY'		
		AND TA.TABLECODE = 5001
		AND C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsMultiClassAllowed bit     output,
			@pnCaseKey	        int',
			@bIsMultiClassAllowed   = @bIsMultiClassAllowed output,
			@pnCaseKey	        = @pnCaseKey

End

If @nErrorCode = 0 
and @bIsMultiClassAllowed = 0
Begin
        Select @sSQLString = "
	Select @bIsMultiClassAllowed = ISNULL(MULTICLASSPROPERTYAPP,0)
	from VALIDCATEGORY VC
	join CASES C on (C.COUNTRYCODE = VC.COUNTRYCODE
	                and C.CASETYPE = VC.CASETYPE 
	                and C.PROPERTYTYPE = VC.PROPERTYTYPE
	                and C.CASECATEGORY = VC.CASECATEGORY)
	where C.CASEID = @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsMultiClassAllowed bit     output,
			@pnCaseKey	        int',
			@bIsMultiClassAllowed   = @bIsMultiClassAllowed output,
			@pnCaseKey	        = @pnCaseKey
End

If @nErrorCode = 0
Begin
        Select @bIsMultiClassAllowed
End

Return @nErrorCode
GO

Grant execute on dbo.csw_IsMultipleClassesAllowed to public
GO
