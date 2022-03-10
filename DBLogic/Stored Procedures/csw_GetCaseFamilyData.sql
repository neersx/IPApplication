-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCaseFamilyData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCaseFamilyData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCaseFamilyData.'
	Drop procedure [dbo].[csw_GetCaseFamilyData]
End
Print '**** Creating Stored Procedure dbo.csw_GetCaseFamilyData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetCaseFamilyData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psFamilyKey			nvarchar(40)	
)
as
-- PROCEDURE:	csw_GetCaseFamilyData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Retrieve data to be used for setting up a Case Family

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 FEB 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Select  F.FAMILY 	as FamilyKey, 
			F.FAMILYTITLE	as FamilyTitle,
	"+dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null, 'F',@sLookupCulture,@pbCalledFromCentura)
				+ " as DisplayLiteral,
			F.LOGDATETIMESTAMP as LastModifiedDate
			from CASEFAMILY F
		where F.FAMILY = @psFamilyKey"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@psFamilyKey	nvarchar(40)',
			@psFamilyKey = @psFamilyKey
End


Return @nErrorCode
GO

Grant execute on dbo.csw_GetCaseFamilyData to public
GO
